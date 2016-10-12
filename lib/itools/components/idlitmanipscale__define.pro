; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipscale__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipScale
;
; PURPOSE:
;   The scale manipulator.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulator
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipScale::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipScale::Init
;   IDLitManipScale::Cleanup
;   IDLitManipScale::
;
; INTERFACES:
; IIDLProperty
; IIDLWindowEvent
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipScale::Init
;
; PURPOSE:
;       The IDLitManipScale::Init function method initializes the
;       ScaleManipulator component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipScale', <manipulator type>)
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipScale::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;  strType     - The type of the manipulator. This is immutable.
;

function IDLitManipScale::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init(_EXTRA=_extra, $
                                  VISUAL_TYPE ='Select', $
                                  IDENTIFIER="SCALE", $
                                  OPERATION_IDENTIFIER="SET_PROPERTY", $
                                  PARAMETER_IDENTIFIER="TRANSFORM", $
                                  /SKIP_MACROHISTORY, $
                                  NAME='Scale')
    if (iStatus eq 0) then $
        return, 0

    ; Initially, transforms are not constrained about a particular axis.
    self.scaleConstraint = [1, 1, 1]
    self.cornerConstraint = [-1, -1, -1]

    self->IDLitManipScale::SetProperty, _EXTRA=_extra

    self->IDLitManipScale::_DoRegisterCursor

    return, 1
end
;--------------------------------------------------------------------------
; IDLitManipScale::Cleanup
;
; Purpose:
;  The destructor of the component.
;

;pro IDLitManipScale::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipScale::_ScaleCenter
;
; Purpose:
;  Return the scaling center, depending upon the cornerConstraint.
;
function IDLitManipScale::_ScaleCenter, oVis, KeyMods

    compile_opt idl2, hidden

    ; By default use the center of rotation of the viz.
    success = 0
    oVis->GetProperty, CENTER_OF_ROTATION=scaleCenter

    ; If the <Ctrl> key is down, scale about the center.
    cornerConstraint = ((KeyMods and 2) ne 0) ? $
        [-1, -1, -1] : self.cornerConstraint

    ; We are scaling about the corners/edges instead of the center.
    ; Retrieve the ranges for the selected visualization.
    if not ARRAY_EQUAL(cornerConstraint, [-1, -1, -1]) then begin
        success = oVis->GetXYZRange(xRange, yRange, zRange, $
            /NO_TRANSFORM)
    endif

    if (success) then begin
        ; If we are constrained, use either the range min or max.
        ; If we aren't constrained, we'll use the center from above.
        if (cornerConstraint[0] ge 0) then $
            scaleCenter[0] = xRange[self.cornerConstraint[0]]
        if (cornerConstraint[1] ge 0) then $
            scaleCenter[1] = yRange[self.cornerConstraint[1]]
        if (cornerConstraint[2] ge 0) then $
            scaleCenter[2] = zRange[self.cornerConstraint[2]]
    endif

    return, scaleCenter
end



;--------------------------------------------------------------------------
pro IDLitManipScale::_CaptureMacroHistory, $
    scaleFactors, $
    MOUSE_MOTION=mouseMotion

    compile_opt idl2, hidden

    oTool = self->GetTool()
    oSrvMacro = oTool->GetService('MACROS')
    if obj_valid(oSrvMacro) then begin
        oSrvMacro->GetProperty, $
            RECORDING=recording, $
            MANIPULATOR_STEPS=manipulatorSteps
        skipMacro = 0
        skipHistory = 0
        if recording && manipulatorSteps then begin
            if keyword_set(mouseMotion) then begin
                ; add each individual manipulation to macro
                ; don't add individual manipulation to history
                skipHistory = 1
            endif else skipMacro = 1    ; overall added to history but not macro
        endif else begin
            ; add overall manipulation to both macro and history
            ; skip the individual manipulations
            if keyword_set(mouseMotion) then return
        endelse

        idSrc = "/Registry/MacroTools/Scale"
        oDesc = oTool->GetByIdentifier(idSrc)
        if obj_valid(oDesc) then begin
            oDesc->SetProperty, $
                X=scaleFactors[0], $
                Y=scaleFactors[1], $
                Z=scaleFactors[2], $
                TYPE=self._initialType, $
                KEYMODS=self._initialKeyMods
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            oSrvMacro->PasteMacroOperation, oDesc, currentName, $
                SKIP_MACRO=skipMacro, $
                SKIP_HISTORY=skipHistory
        endif
    endif
end

;--------------------------------------------------------------------------
pro IDLitManipScale::_Scale, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    ; If we havn't moved then return.
    if ((x eq self.prevXY[0]) && (y eq self.prevXY[1])) then $
        RETURN

    if (OBJ_VALID(self._oTarget)) then begin
      oVis = self._oTarget
    endif else begin
      oVis = (*self.pSelectionList)[0]
    endelse

    ; Find the scaling center. We need to do this each time, in case
    ; the KeyMods has changed.
    centerXYZ = self->_ScaleCenter(oVis, KeyMods)

    ; Maintain aspect ratio?
    keepAspect = oVis->IsIsotropic() || (KeyMods and 1) || self.is3D
    
    ; Shift key forces uniform scaling.
    if (keepAspect) then begin

        ; Convert center from viz coords to window coords.
        oVis->_IDLitVisualization::VisToWindow, $
            centerXYZ, screenCenter
        screenCenter = screenCenter[0:1]

        ; Calculate the uniform scale factor using the difference
        ; in screen coordinates between location and scale center.
        rStart = SQRT(TOTAL(ABS(self.prevXY - screenCenter)^2d))
        rCurrent = SQRT(TOTAL(ABS([x,y] - screenCenter)^2d))
        scaleFactor = (rStart gt 0) ? (finite(rCurrent/rStart) ?  $
                                      rCurrent/rStart : 1) : 1

        scaleX = (self.scaleConstraint[0]) ? scaleFactor : 1
        scaleY = (self.scaleConstraint[1]) ? scaleFactor : 1

        ; Only use the Z scale factor if we are scaling a 3D viz.
        scaleZ = (self.is3D && self.scaleConstraint[2]) ? scaleFactor : 1

    endif else begin

        ; Do computations in viz coords, so we can include rotations.
        oVis->_IDLitVisualization::WindowToVis, $
            [[x, y], [self.prevXY]], xyVis
        xVis = xyVis[0,0]
        yVis = xyVis[1,0]
        startXYvis = xyVis[*,1]

        ; Scaling is the current delta divided by starting delta.

        ; X scale factor.
        if (self.scaleConstraint[0]) then begin
            xstart = (startXYvis[0] - centerXYZ[0])
            if (xstart eq 0) then $
                return
            scaleX = (xVis - centerXYZ[0])/xstart
            ; Don't allow negative scaling.
            if (scaleX le 0) then $
                return
        endif else $
            scaleX = 1

        ; Y scale factor.
        if (self.scaleConstraint[1]) then begin
            ystart = (startXYvis[1] - centerXYZ[1])
            if (ystart eq 0) then $
                return
            scaleY = (yVis - centerXYZ[1])/ystart
            ; Don't allow negative scaling.
            if (scaleY le 0) then $
                return
        endif else $
            scaleY = 1

        scaleZ = 1   ; no Z scaling

    endelse


    ; Update the overall scale factor.
    self.scaleFactors *= [scaleX, scaleY, scaleZ]

    ; Update the status bar with mouse location and scaling.
    ; First round off to nearest small fraction.
    scaleFactors = LONG(self.scaleFactors[0:1+self.is3D]*100)/100d
    msg = STRING(x, y, scaleFactors, FORMAT='(%"[%d,%d]   ' + $
        (self.is3D ? '%g, %g, %g")' : '%g, %g")'))
    self->ProbeStatusMessage, msg


    ; Loop through all selected visualizations.
    for i=0, self.nSelectionList-1 do begin
        oVis = (*self.pSelectionList)[i]
        ; Compute the scale center separately for each viz.
        centerXYZ = self->_ScaleCenter(oVis, KeyMods)
        oVis->Scale, scaleX, scaleY, scaleZ, /PREMULTIPLY, $
            CENTER_OF_ROTATION=centerXYZ
    endfor  ; selected vis loop

    self->_CaptureMacroHistory, $
        [scaleX, scaleY, scaleZ], $
        /MOUSE_MOTION

    ;; Bump up the initial xy points for the next application
    ;; of the algorithm.
    self.prevXY = [x, y]

end


;--------------------------------------------------------------------------
; IIDLScaleManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
; TODO: How does the current Visualization...etc fit into these
;       method calls?
;--------------------------------------------------------------------------
; IDLitManipScale::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitManipScale::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect, TARGET=oTarget

    self.is3D = 0b
    self._initialKeyMods = KeyMods
    if (OBJ_VALID(oTarget)) then $ 
      self._oTarget = oTarget

    if (self.nSelectionList gt 0) then begin

        ; See if any of the selected viz are 3d.
        ; Assume that we only need to check this on a mouse down.
        for i=0,self.nSelectionList-1 do begin
            if (*self.pSelectionList)[i]->Is3D() then begin
                self.is3D = 1b
                break   ; no need to continue checking.
            endif
        endfor

        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()

        self.startXY = [x,y]
        self.prevXY = self.startXY
        self.scaleFactors = [1d, 1d, 1d]

        ; Change status msg depending upon whether we can use
        ; <Shift> and <Ctrl> constraints.
        self->StatusMessage, IDLitLangCatQuery('Status:Manip:' + $
            ((MAX(self.cornerConstraint) ge 0) ? $
            (~self.is3D ? 'ScaleShiftCtrl' : 'ScaleCtrl') : 'Scale'))

    endif

end
;--------------------------------------------------------------------------
; IDLitManipScale::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button released

pro IDLitManipScale::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    ; Reset the axis constraint to be off.
    self.cornerConstraint = [-1, -1, -1]

    if(self.nSelectionList gt 0)then begin
        ;; Commit this transaction
        iStatus = self->CommitUndoValues( $
            UNCOMMIT=ARRAY_EQUAL(self.startXY, [x,y]))
    endif

    self->_CaptureMacroHistory, $
        self.scaleFactors

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    ; Restore status message.
    statusMsg = self->GetStatusMessage('', KeyMods, /FOR_SELECTION)
    self->StatusMessage, statusMsg
end

;--------------------------------------------------------------------------
; IDLitManipScale::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipScale::OnMouseMotion, oWin, x, y, KeyMods
   ; pragmas
   compile_opt idl2, hidden

   if (self.nSelectionList gt 0) then begin

       oVis = (*self.pSelectionList)[0]

       self->_Scale, oWin, x[0], y[0], KeyMods

       ; Update the graphics hierarchy.
       (self->GetTool())->RefreshCurrentWindow

   endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; IDLitManipScale::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitManipScale::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    switch strupcase(typeIn) of

         '+X':
         '-X': begin & currCur = 'SIZE_EW' & break & end

     '+X_ROT':
     '-X_ROT': begin & currCur = 'SIZE_NS' & break & end    

         '+Y':
         '-Y':
         '+Z':
         '-Z': begin & currCur = 'SIZE_NS' & break & end

     '+Y_ROT':
     '-Y_ROT': begin & currCur = 'SIZE_EW' & break & end

       '+X+Y':
       '-X-Y': begin
            currCur = ((KeyMods and 1) ne 0) ? 'SIZE_NE' : 'Scale2D'
            break
            end

   '+X+Y_ROT':
   '-X-Y_ROT': begin
            currCur = ((KeyMods and 1) ne 0) ? 'SIZE_SE' : 'Scale2D'
            break
            end

       '-X+Y':
       '+X-Y': begin
            currCur = ((KeyMods and 1) ne 0) ? 'SIZE_SE' : 'Scale2D'
            break
            end

   '-X+Y_ROT':
   '+X-Y_ROT': begin
            currCur = ((KeyMods and 1) ne 0) ? 'SIZE_NE' : 'Scale2D'
            break
            end

         'XY':
         'XZ':
         'YZ': begin & currCur = 'Scale2D' & break & end

         'XYZ': begin & currCur = 'Scale3D' & break & end

         else: currCur = ''
    endswitch

    return, currCur
end


;--------------------------------------------------------------------------
; IDLitManipScale::GetStatusMesssage
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
function IDLitManipScale::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    return, IDLitLangCatQuery('Status:Manip:Scale')
end


;---------------------------------------------------------------------------
; IDLitManipScale::SetCurrentManipulaotr
;
; Purpose:
;    Used to set the active type for the IDLitManipulator.
PRO IDLitManipScale::SetCurrentManipulator, type, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Assume all scaling constraints.
    self.scaleConstraint  = [0, 0, 0]

    ; Assume no corner constraints.
    self.cornerConstraint = [-1, -1, -1]

    if (N_ELEMENTS(type) gt 0) then begin
        if (STRPOS(type, 'X') ge 0) then self.scaleConstraint[0] = 1
        if (STRPOS(type, 'Y') ge 0) then self.scaleConstraint[1] = 1
        if (STRPOS(type, 'Z') ge 0) then self.scaleConstraint[2] = 1
        if (STRPOS(type, '+X') ge 0) then self.cornerConstraint[0] = 0
        if (STRPOS(type, '-X') ge 0) then self.cornerConstraint[0] = 1
        if (STRPOS(type, '+Y') ge 0) then self.cornerConstraint[1] = 0
        if (STRPOS(type, '-Y') ge 0) then self.cornerConstraint[1] = 1
        if (STRPOS(type, '+Z') ge 0) then self.cornerConstraint[2] = 0
        if (STRPOS(type, '-Z') ge 0) then self.cornerConstraint[2] = 1
        self._initialType = type
    endif


    ; Call our superclass.
    self->IDLitManipulator::SetCurrentManipulator, type, _EXTRA=_extra
end


;--------------------------------------------------------------------------
pro IDLitManipScale::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '                ', $
        '  .....   ..... ', $
        '  .###.   .###. ', $
        '  .##.     .##. ', $
        '  .#.#.   .#.#. ', $
        '  .. .#. .#. .. ', $
        '      .#.#.     ', $
        '       .$.      ', $
        '      .#.#.     ', $
        '  .. .#. .#. .. ', $
        '  .#.#.   .#.#. ', $
        '  .##.     .##. ', $
        '  .###.   .###. ', $
        '  .....   ..... ', $
        '                ', $
        '                ']
    self->RegisterCursor, strArray, 'Scale2D'

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#####.     ', $
        '     ..#..      ', $
        '      .#.   .   ', $
        '      .#.  .#.  ', $
        '      .#....##. ', $
        '      .$#######.', $
        ' ..  .#.....##. ', $
        ' .#..#.    .#.  ', $
        ' .##..      .   ', $
        ' .###.          ', $
        ' .####.         ', $
        ' ......         ', $
        '                ']
    self->RegisterCursor, strArray, 'Scale3D'

end


;---------------------------------------------------------------------------
; IDLitManipScale::Define
;
; Purpose:
;   Define the base object for the manipulator
;

pro IDLitManipScale__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitManipScale, $
           INHERITS IDLitManipulator,       $ ; I AM A COMPONENT
           _initialType: '', $
           _initialKeymods: 0L, $
           _oTarget: OBJ_NEW(), $
           startXY: [0d, 0d], $
           prevXY: [0d, 0d], $
           scaleFactors: [0d, 0d, 0d], $
           scaleConstraint: [0, 0, 0], $
           cornerConstraint: [0, 0, 0], $
           is3D: 0b $
      }
end
