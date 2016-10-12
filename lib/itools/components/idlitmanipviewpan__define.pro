; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipviewpan__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Class Name:
;   IDLitManipViewPan
;
; Purpose:
;   This class represents a manipulator used to pan within views.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
; IDLitManipViewPan::Init
;
; Purpose:
;   This function method initializes the object.
;
; Return Value:
;   This method returns a 1 on success, or 0 on failure.
;
; Keywords:
;   This method accepts all keywords suppored by the ::Init method
;   of this object's superclass.
;
function IDLitManipViewPan::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize our superclass.
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Select", $
        TYPES="_VISUALIZATION", $
        IDENTIFIER="VIEWPAN", $
        OPERATION_IDENTIFIER="SET_SUBVIEW", $
        NAME="ViewPan", $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Register the default cursor for this manipulator.
    self->IDLitManipViewPan::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipViewPan::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipViewPan::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitManipViewPan::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end

;---------------------------------------------------------------------------
; Manipulator Interface
;---------------------------------------------------------------------------


;--------------------------------------------------------------------------
; IDLitManipViewPan::OnMouseDown
;
; Purpose:
;   This procedure method handles notification of a mouse down.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
pro IDLitManipViewPan::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    _EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
        KeyMods, nClicks

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return
    oDesc = oTool->GetByIdentifier('/Registry/MacroTools/ViewPan')
    if (~OBJ_VALID(oDesc)) then $
        return
    oPan = oDesc->GetObjectInstance()

    success = oPan->StartPan(oWin, x, y)

    self._startXY = [x, y]
    self._currentXY = [x, y]

    self->StatusMessage, IDLitLangCatQuery('Status:Framework:Pan')

    oWin->SetCurrentCursor, success ? 'Grab' : 'NoGrab'

end


;--------------------------------------------------------------------------
pro IDLitManipViewPan::_CaptureMacroHistory, dx, dy, $
    MOUSE_MOTION=mouseMotion

    compile_opt idl2, hidden

    if (dx eq 0 && dy eq 0) then $
        return

    oTool = self->GetTool()
    oSrvMacro = oTool->GetService('MACROS')
    if ~obj_valid(oSrvMacro) then $
        return

    oSrvMacro->GetProperty, $
        RECORDING=recording, $
        MANIPULATOR_STEPS=manipulatorSteps

    if recording && manipulatorSteps then begin
        if keyword_set(mouseMotion) then begin
            ; add each individual manipulation to macro
            ; don't add individual manipulation to history
            skipMacro = 0
            skipHistory = 1
        endif else begin
            ; overall added to history but not macro
            skipMacro = 1
            skipHistory = 0
        endelse
    endif else begin
        ; skip the individual manipulations
        if keyword_set(mouseMotion) then return
        ; add overall manipulation to both macro and history
        skipMacro = 0
        skipHistory = 0
    endelse

    idSrc = "/Registry/MacroTools/ViewPan"
    oDesc = oTool->GetByIdentifier(idSrc)
    if obj_valid(oDesc) then begin
        oDesc->SetProperty, $
            X=dx, $
            Y=dy
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, oDesc, currentName, $
            SKIP_MACRO=skipMacro, $
            SKIP_HISTORY=skipHistory
    endif
end


;--------------------------------------------------------------------------
; IDLitManipViewPan::OnMouseUp
;
; Purpose:
;   This procedure method handles notification of a mouse up.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipViewPan::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    self.ButtonPress = 0  ; button is up

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return
    oDesc = oTool->GetByIdentifier('/Registry/MacroTools/ViewPan')
    if (~OBJ_VALID(oDesc)) then $
        return
    oPan = oDesc->GetObjectInstance()

    oCmdSet = oPan->EndPan(oWin, x, y)

    if OBJ_VALID(oCmdSet[0]) then $
        oTool->_TransactCommand, oCmdSet

    self->_CaptureMacroHistory, x - self._startXY[0], y - self._startXY[1]

    oWin->SetCurrentCursor, 'ViewPan'

end


;--------------------------------------------------------------------------
; IDLitManipViewPan::OnMouseMotion
;
; Purpose:
;   This procedure method handles notification of a mouse motion.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button
;
pro IDLitManipViewPan::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    if (self.ButtonPress eq 0) then begin
        ; Simply pass control to superclass.
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
        return
    endif

    deltaX = x - self._currentXY[0]
    deltaY = y - self._currentXY[1]

    ; Check for <Shift> key.
    if ((KeyMods and 1) ne 0) then begin
        ; See if we need to initialize the constraint.
        ; The biggest delta (x or y) wins, until <Shift> is released.
        if (~self._xyConstrain) then $
            self._xyConstrain = (ABS(deltaX) gt ABS(deltaY)) ? 1 : 2
        ; Apply the constraint.
        if (self._xyConstrain eq 1) then $
            deltaY = 0 $
        else $
            deltaX = 0
    endif else begin
        self._xyConstrain = 0   ; turn off constraint
    endelse

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return
    oDesc = oTool->GetByIdentifier('/Registry/MacroTools/ViewPan')
    if (~OBJ_VALID(oDesc)) then $
        return
    oPan = oDesc->GetObjectInstance()

    panStr = oPan->DoPan(oWin, deltaX, deltaY)

    if (panStr) then $
        self->ProbeStatusMessage, panStr

    self->_CaptureMacroHistory, deltaX, deltaY, /MOUSE_MOTION

    self._currentXY = [x, y]

end


;--------------------------------------------------------------------------
; IDLitManipViewPan::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Parameters
;      oWin        - Event Window Component
;      IsASCII     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
;
pro IDLitManipViewPan::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

    compile_opt idl2, hidden

    if (IsASCII) then $
        return

    if (KeyValue lt 5 || KeyValue gt 8) then $
        return

    if (Press) then begin
        oTool = self->GetTool()
        if (~OBJ_VALID(oTool)) then $
            return
        oDesc = oTool->GetByIdentifier('/Registry/MacroTools/ViewPan')
        if (~OBJ_VALID(oDesc)) then $
            return
        oPan = oDesc->GetObjectInstance()

        success = oPan->StartPan(oWin, x, y)

        if (~success) then $
            return

        case KeyMods of
            1: offset = 40
            2: offset = 2
            else: offset = 10
        endcase

        deltaX = 0
        deltaY = 0

        ; Do the translation.
        case KeyValue of
            5: deltaX = offset
            6: deltaX = -offset
            7: deltaY = -offset
            8: deltaY = offset
        endcase

        ; Call our internal method.
        panStr = oPan->DoPan(oWin, deltaX, deltaY)

        if (panStr) then $
            self->ProbeStatusMessage, panStr

        oCmdSet = oPan->EndPan(oWin, x + deltaX, y + deltaY)

        if OBJ_VALID(oCmdSet[0]) then $
            oTool->_TransactCommand, oCmdSet

        ; First press event.
        if (~self._keyDown) then begin
            self._keyDown = 1b
            self._startXY = [x, y]
            self._currentXY = [x, y]
            self->StatusMessage, IDLitLangCatQuery('Status:Manip:Rotate3D1')
        endif

        self._currentXY += [deltaX, deltaY]

    endif else begin

        ; When key is released, consider the delta to be from the current
        ; XY all the way back to the start.
        self._keyDown = 0b
        deltaX = self._currentXY[0] - self._startXY[0]
        deltaY = self._currentXY[1] - self._startXY[1]

    endelse

    self->_CaptureMacroHistory, deltaX, deltaY, MOUSE_MOTION=Press

end


;--------------------------------------------------------------------------
; IDLitManipViewPan::_DoRegisterCursor
;
; Purpose:
;   This procedure method registers the cursors used by this manipulator.
;
pro IDLitManipViewPan::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '       ##       ', $
        '   ## #..###    ', $
        '  #..##..#..#   ', $
        '  #..##..#..# # ', $
        '   #..#..#..##.#', $
        '   #..#..#..#..#', $
        ' ## #.......#..#', $
        '#..##..........#', $
        '#...#.........# ', $
        ' #............# ', $
        '  #...........# ', $
        '  #..........#  ', $
        '   #.........#  ', $
        '    #.......#   ', $
        '     #......#   ', $
        '                ']
    self->RegisterCursor, strArray, 'ViewPan', /DEFAULT

    strArray = [ $
        '       ##       ', $
        '   ##.#..###    ', $
        '  #..##..#..#   ', $
        '  #..##..#..#.# ', $
        '   #..#..#..##.#', $
        '   #..#..#..#..#', $
        ' ##.#.......#..#', $
        '#..##..###.....#', $
        '#...#.#...#...# ', $
        '.#...#...#.#..# ', $
        '  #..#..#..#..# ', $
        '  #..#.#...#.#  ', $
        '   #..#...#..#  ', $
        '    #..###..#   ', $
        '     #......#   ', $
        '                ']
    self->RegisterCursor, strArray, 'NoGrab'

    strArray = [ $
        '                ', $
        '                ', $
        '       ###      ', $
        '    ###..###    ', $
        '   #..#..#..##  ', $
        '   #..#..#..#.# ', $
        '   ##.......#..#', $
        '   ##..........#', $
        '  #.#.........# ', $
        ' #............# ', $
        '  #...........# ', $
        '  #..........#  ', $
        '   #.........#  ', $
        '    #.......#   ', $
        '     #......#   ', $
        '                ']
    self->RegisterCursor, strArray, 'Grab'

end

;-------------------------------------------------------------------------
; IDLitManipViewPan::QueryAvailability
;
; Purpose:
;   This function method determines whether this manipulator is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if this manipulator is applicable for the
;   selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None.
;
function IDLitManipViewPan::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; This manipulator is only available when the virtual dimensions
    ; for the current view are greater than the visible dimensions, or
    ; if the viewport does not fit completely within the visible portion
    ; of the canvas.
    oWin = oTool->GetCurrentWindow()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    if (OBJ_VALID(oView)) then begin
        oWin->GetProperty, CURRENT_ZOOM=canvasZoom
        virtualDims = oView->GetVirtualViewport()
        vwDims = oView->GetViewport(oWin, /VIRTUAL, LOCATION=vwLoc)
        visViewDims = vwDims / canvasZoom
        bVirtualLarger = (visViewDims[0] lt virtualDims[0]) || $
            (visViewDims[1] lt virtualDims[1])

        if (bVirtualLarger) then $
            bNewDisable = 0 $
        else begin
            winVisDims = oWin->GetDimensions(VISIBLE_LOCATION=winVisLoc)
            ; Check if any portion of the viewport falls outside of
            ; the visible portion of the canvas.
            if ((vwLoc[0] lt winVisLoc[0]) || $
                ((vwLoc[0]+vwDims[0]-1) gt $
                 (winVisLoc[0]+winVisDims[0]-1)) || $
                (vwLoc[1] lt winVisLoc[1]) || $
                ((vwLoc[1]+vwDims[1]-1) gt $
                 (winVisLoc[1]+winVisDims[1]-1))) then $
                bNewDisable = 0 $
            else $
                bNewDisable = 1
        endelse
    endif else $
        bNewDisable = 1

    return, ~bNewDisable

end

;---------------------------------------------------------------------------
; IDLitManipViewPan__Define
;
; Purpose:
;   Define the object structure for the IDLitManipViewPan class.
;
pro IDLitManipViewPan__Define

    compile_opt idl2, hidden

    void = {IDLitManipViewPan,       $
        inherits IDLitManipulator,   $ ; Superclass
        _startXY: DBLARR(2),         $ ; Initial window location.
        _currentXY: DBLARR(2), $
        _xyConstrain: 0b, $
        _keyDown: 0b $
    }
end
