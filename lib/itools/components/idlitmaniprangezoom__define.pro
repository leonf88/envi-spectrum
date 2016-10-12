; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprangezoom__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipRangeZoom
;
; PURPOSE:
;   The IDLitManipRangeBox class represents a manipulator used to modify
;   the XYZ range of one or more target dataspace objects.  The dataspace
;   range modification occurs by clicking a visual that indicates either
;   a zoom in or a zoom out.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipRangeZoom::Init
;
; PURPOSE:
;   The IDLitManipRangeZoom::Init function method initializes the
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   oManipulator = OBJ_NEW('IDLitManipRangeZoom')
;
;-
function IDLitManipRangeZoom::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Range", $
        OPERATION_IDENTIFIER="SET_XYZRANGE", $
        NAME="Range Zoom", $
        /SKIP_MACROHISTORY, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Register the default cursor for this manipulator.
    self->IDLitManipRangeZoom::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipRangeZoom::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipRangeZoom::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipRangeZoom::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipRangeZoom::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., dataspaces) to be manipulated by this manipulator
;   (based upon the given list of visualizations current selected).
;
; Keywords:
;   MERGE
;     Note: this keyword is ignored for this manipulator because
;     we only want dataspaces to be considered manipulator targets.
;
function IDLitManipRangeZoom::_FindManipulatorTargets, oVisIn, $
    MERGE=merge

    compile_opt idl2, hidden

    nVis = N_ELEMENTS(oVisIn)
    if (nVis eq 0) then return, OBJ_NEW()
    if (OBJ_VALID(oVisIn[0]) eq 0) then $
        return, OBJ_NEW()

    oLayer = oVisIn[0]->_GetLayer()
    if (OBJ_VALID(oLayer) eq 0) then $
        return, OBJ_NEW()
    if (OBJ_ISA(oLayer, 'IDLitGrAnnotateLayer')) then $
       return, OBJ_NEW()

    oTool = self->GetTool()
    oWin = OBJ_VALID(oTool) ? oTool->GetCurrentWindow() : OBJ_NEW()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()
    oWorld = OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW()
    oDataSpaces = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW()

    return, oDataSpaces
end

;--------------------------------------------------------------------------
;+
; IDLitManipRangeZoom::_DisableAutoUpdates
;
; Purpose:
;   This procedure method disables auto-updates of the XYZ Ranges
;   for each target dataspace.
;-
pro IDLitManipRangeZoom::_DisableAutoUpdates

    compile_opt idl2, hidden

    nDS = self.nSelectionList

    if (nDS gt 0) then begin
        for i=0,nDS-1 do begin
            oDS = (*self.pSelectionList)[i]
            oDS->SetProperty, $
                X_AUTO_UPDATE=0, $
                Y_AUTO_UPDATE=0, $
                Z_AUTO_UPDATE=0
        endfor
    endif
end

;--------------------------------------------------------------------------
; IDLitManipRangeZoom::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
pro IDLitManipRangeZoom::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    nDS = self.nSelectionList

    ; Disable window updates until a mouse up.
    oTool = oWin->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->DisableUpdates

    if (nDS gt 0) then $
        iStatus = self->RecordUndoValues()
end


;--------------------------------------------------------------------------
; IDLitManipRangeZoom::_Zoom
;
; Purpose:
;   Zooms the selected dataspace(s).
;
; Parameters
;   Direction   The direction in which the zoom is to occur.
;       Negative values zoom out.
;       Positive values zoom in.
;
; Keywords
;   AXIS    The axis along which the zoom is to occur.
;       0=X, 1=Y, 2=Z
pro IDLitManipRangeZoom::_Zoom, Direction, AXIS=inAxis
    ; pragmas
    compile_opt idl2, hidden

    axis = (N_ELEMENTS(inAxis) ne 0) ? inAxis : 0

    ; The range will zoom in by a factor of (1 - 2*fraction).
    ; If fraction=0.25, then the range will be 1/2.
    fraction = 0.25

    ; If we are zooming out, convert the fraction so that
    ; the zoom out factor will exactly cancel out the zoom in.
    ; If fraction=0.25, then this means the range will double.
    if (direction lt 0) then $
        fraction = -fraction/(1 - 2*fraction)

    ; Preserve the axis range by not zooming in any farther
    ; than the value eps.
    eps = 1e-12

    ; Only operate on selected dataspace
    oTool = self->GetTool()
    oSel = oTool->GetSelectedItems()
    oDataSpace = oSel[0]->GetDataSpace()
    
    oDataSpace->GetProperty, $
        X_MINIMUM=xMin, X_MAXIMUM=xMax, $
        Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
        Z_MINIMUM=zMin, Z_MAXIMUM=zMax, $
        XLOG=xLog, YLOG=yLog, ZLOG=zLog

    nAxis = N_ELEMENTS(axis)

    for j=0,nAxis-1 do begin

        ; Copy appropriate data to temp vars.
        case axis[j] of
        0: begin
            type = 'X'
            minn = xMin
            maxx = xMax
            isLog = xLog
           end
        1: begin
            type = 'Y'
            minn = yMin
            maxx = yMax
            isLog = yLog
           end
        2: begin
            type = 'Z'
            minn = zMin
            maxx = zMax
            isLog = zLog
           end
        endcase

        ; Convert back from data coords to logarithmic coords.
        if (isLog) then begin
            minn = ALOG10(minn)
            maxx = ALOG10(maxx)
        endif

        axisLen = maxx - minn
        zoomOffset = axisLen * fraction

        ; See if our range is too tiny.
        ; Only check when zooming in.
        if (direction gt 0) then begin
            delta = ABS(zoomOffset)
            absMax = ABS(maxx > minn)
            if (absMax ne 0) then delta /= absMax
            if (delta lt eps) then begin
                self->ErrorMessage, $
                    IDLitLangCatQuery('Error:RangeZoom:Max' + type + 'ScaleReached'), $
                    severity=1, $
                    TITLE=IDLitLangCatQuery('Error:RangeZoom:Title')
                ; Don't want to scale any of the axes for this dataspace.
                ; Otherwise the scale factors can get out of sync.
                continue
            endif
        endif

        newMin = minn + zoomOffset
        newMax = maxx - zoomOffset

        ; Convert from logarithmic coords back to data coords.
        if (isLog) then begin
            newMin = 10.^newMin
            newMax = 10.^newMax
        endif

        ; Copy from temp vars back to appropriate keywords.
        case axis[j] of
        0: begin
            xNewMin = newMin
            xNewMax = newMax
           end
        1: begin
            yNewMin = newMin
            yNewMax = newMax
           end
        2: begin
            zNewMin = newMin
            zNewMax = newMax
           end
        endcase

    endfor


    ; Set the new ranges all at once to avoid multiple
    ; updates.
    oDataSpace->SetProperty, $
        X_MINIMUM=xNewMin, X_MAXIMUM=xNewMax, $
        Y_MINIMUM=yNewMin, Y_MAXIMUM=yNewMax, $
        Z_MINIMUM=zNewMin, Z_MAXIMUM=zNewMax

    oSrvMacro = oTool->GetService('MACROS')
    idSrc = "/Registry/MacroTools/Range Change"
    oDescRangeChange = oTool->GetByIdentifier(idSrc)
    if obj_valid(oSrvMacro) && $
            obj_valid(oDescRangeChange) then begin
        ; All values need to be defined so that we don't use the
        ; old values in oDescRangeChange from a prior invocation
        ; Need to get the initial value even if we didn't modify
        ; the value for a particular axis.
        if n_elements(xNewMin) eq 0 then xNewMin = xMin
        if n_elements(xNewMax) eq 0 then xNewMax = xMax
        if n_elements(yNewMin) eq 0 then yNewMin = yMin
        if n_elements(yNewMax) eq 0 then yNewMax = yMax
        if n_elements(zNewMin) eq 0 then zNewMin = zMin
        if n_elements(zNewMax) eq 0 then zNewMax = zMax
        oDescRangeChange->SetProperty, $
            X_MINIMUM=xNewMin, X_MAXIMUM=xNewMax, $
            Y_MINIMUM=yNewMin, Y_MAXIMUM=yNewMax, $
            Z_MINIMUM=zNewMin, Z_MAXIMUM=zNewMax
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, oDescRangeChange, currentName
    endif

end

;--------------------------------------------------------------------------
; IDLitManipRangeZoom::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipRangeZoom::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    self.ButtonPress = 0  ; button is up

    if (self.nSelectionList gt 0) then begin
        self->_DisableAutoUpdates

        case self._subType of
            'Out X': self->_Zoom,  -1, AXIS=0
            'In X': self->_Zoom,   1, AXIS=0
            'Out Y': self->_Zoom,  -1, AXIS=1
            'In Y': self->_Zoom,   1, AXIS=1
            'Out Z': self->_Zoom,  -1, AXIS=2
            'In Z': self->_Zoom,   1, AXIS=2
            'In XY': self->_Zoom,  1, AXIS=[0,1]
            'Out XY': self->_Zoom, -1, AXIS=[0,1]
            else : return
        endcase

        iStatus = self->CommitUndoValues()
    endif

    ; Re-enable window updates.
    oTool = oWin->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->EnableUpdates

end


;;--------------------------------------------------------------------------
;; IDLitManipRangeZoom::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipRangeZoom::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '     .....      ', $
        '    .#####.     ', $
        '   .#.....#.    ', $
        '  .#.     .#.   ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        ' .#.   $   .#.  ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        '  .#..... .##.  ', $
        '   .#.....####. ', $
        '    .######..##.', $
        '     .... .#..#.', $
        '           .##. ', $
        '            ..  ', $
        '                ']

    self->RegisterCursor, strArray, 'Range_zoom', /DEFAULT

end


;--------------------------------------------------------------------------
; IDLitManipRangeZoom::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitManipRangeZoom::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    switch STRUPCASE(typeIn) of
        'OUT X':
        'IN X':
        'OUT Y':
        'IN Y':
        'OUT Z':
        'IN Z':
        'OUT XY':
        'IN XY': begin
            currCur = 'RANGE_ZOOM'
            break
            end
        else: currCur = ''
    endswitch

    return, currCur
end

;--------------------------------------------------------------------------
; IDLitManipRangeZoom::GetStatusMesssage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given type.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   typeIn <Optional> - String representing the current type.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
function IDLitManipRangeZoom::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    case typeIn of
        'Out X': statusMsg = IDLitLangCatQuery('Status:RangeZoom:OutX')
        'In X': statusMsg = IDLitLangCatQuery('Status:RangeZoom:InX')
        'Out Y': statusMsg = IDLitLangCatQuery('Status:RangeZoom:OutY')
        'In Y': statusMsg = IDLitLangCatQuery('Status:RangeZoom:InY')
        'Out Z': statusMsg = IDLitLangCatQuery('Status:RangeZoom:OutZ')
        'In Z': statusMsg = IDLitLangCatQuery('Status:RangeZoom:InZ')
        'Out XY': statusMsg = IDLitLangCatQuery('Status:RangeZoom:OutXY')
        'In XY':  statusMsg = IDLitLangCatQuery('Status:RangeZoom:InXY')
        else: statusMsg = ' '
    endcase

    return, statusMsg
end


;---------------------------------------------------------------------------
; IDLitManipRangeZoom::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipRangeZoom__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipRangeZoom,        $
            inherits IDLitManipulator  $ ; Superclass
    }
end
