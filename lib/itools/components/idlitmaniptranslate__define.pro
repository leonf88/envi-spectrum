; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniptranslate__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipTranslate
;
; PURPOSE:
;   Translate manipulator.
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
;   See IDLitManipTranslate::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipTranslate::Init
;   IDLitManipTranslate::Cleanup
;   IDLitManipTranslate::
;
; INTERFACES:
; IIDLProperty
; IIDLWindowEvent
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipTranslate::Init
;
; PURPOSE:
;       The IDLitManipTranslate::Init function method initializes the
;       Translate Manipulator component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipTranslate', <manipulator type>)
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
; IDLitManipTranslate::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;  strType     - The type of the manipulator. This is immutable.
;

function IDLitManipTranslate::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init(IDENTIFIER="TRANSLATE",$
        VISUAL_TYPE ='Select', $
        DESCRIPTION='Click & drag or use arrow keys to translate', $
        OPERATION_IDENTIFIER="SET_PROPERTY", $
        PARAMETER_IDENTIFIER="TRANSFORM", $
        /SKIP_MACROHISTORY, $
        NAME="Translate", _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    self->IDLitManipTranslate::_DoRegisterCursor

    self->IDLitManipTranslate::SetProperty, _EXTRA=_extra

    self.pTransInfo = PTR_NEW(/allocate_heap)
    return, 1
end
;--------------------------------------------------------------------------
; IDLitManipTranslate::Cleanup
;
; Purpose:
;  The destructor of the component.
;

pro IDLitManipTranslate::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    if(ptr_Valid(self.pTransInfo))then $
      ptr_free, self.pTransInfo

    self->IDLitManipulator::Cleanup
end

;--------------------------------------------------------------------------
pro IDLitManipTranslate::_CaptureMacroHistory, $
    dx, dy, $
    KEYMODS=keymods, $
    KEYVALUE=KeyValue, $
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

        idSrc = "/Registry/MacroTools/Translate"
        oDesc = oTool->GetByIdentifier(idSrc)
        if obj_valid(oDesc) then begin
            oDesc->SetProperty, X=dx, Y=dy, $
                KEYMODS=keymods, KEYVALUE=KeyValue
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            oSrvMacro->PasteMacroOperation, oDesc, currentName, $
                SKIP_MACRO=skipMacro, $
                SKIP_HISTORY=skipHistory
        endif
    endif
end


;--------------------------------------------------------------------------
function IDLitManipTranslate::_FindManipulatorTargets, oVisIn, $
    MERGE=MERGE

    compile_opt idl2, hidden

    ; Allow the superclass to find the targets for consideration.
    oTargets = self->_IDLitManipulator::_FindManipulatorTargets(oVisIn, $
        MERGE=MERGE)
    nTargets = N_ELEMENTS(oTargets)

    ; Determine how many of the targets are axes, and how many are not.
    isAxis = WHERE(OBJ_ISA(oTargets, 'IDLitVisAxis'), nAxis, $
        COMPLEMENT=isNotAxis, NCOMPLEMENT=nNotAxis)

    ; If we have an axis selected, and *anything* else selected,
    ; then translate the axis' dataspaceroot instead.
    if (nAxis gt 0 && nTargets gt 1) then begin
        for i=0,nAxis-1 do begin
            ; Make sure this axis is indeed a manip target.
            if (~oTargets[isAxis[i]]->IsManipulatorTarget()) then begin
                oTargets[isAxis[i]] = OBJ_NEW()
                break
            endif
            oDS = oTargets[isAxis[i]]->GetDataSpace()
;            oDSRoot = OBJ_VALID(oDS) ? oDS->GetDataSpaceRoot() : OBJ_NEW()
            oTargets[isAxis[i]] = oDS
        endfor
        ; Remove duplicate dataspaceroots.
        ; Otherwise we get double the translation.
        oTargets = oTargets[UNIQ(oTargets, SORT(oTargets))]
    endif

    return, oTargets

end


;--------------------------------------------------------------------------
pro IDLitManipTranslate::_Translate, oWin, x, y, KeyMods, KeyValue

    compile_opt idl2, hidden

    ; Default message, unless overridden by the vis ::Translate
    ; method. See IDLitVisAxis for an example of overriding.
    probeMsg = STRING(x, y, [x, y] - self.startXY, $
        FORMAT='(%"[%d,%d]   %d,%d")')

    ; Find distance the mouse moved.
    dx = x - self.prevXY[0]
    dy = y - self.prevXY[1]

    ;; Loop through all selected visualizations.
    for i=0, self.nSelectionList - 1 do begin
        oVis = (*self.pSelectionList)[i]
        isAxis = OBJ_ISA(oVis, 'IDLitVisAxis')

        ; Ignore <Shift> key for axes (they're already constrained).
        if (~isAxis) then begin
            ; Check for <Shift> key.
            if ((KeyMods and 1) ne 0) then begin
                ; See if we need to initialize the constraint.
                ; The biggest delta (x or y) wins, until <Shift> is released.
                if (self.xyConstrain eq 0) then $
                    self.xyConstrain = (ABS(dx) gt ABS(dy)) ? 1 : 2
                ; Apply the constraint.
                if (self.xyConstrain eq 1) then $
                    dy = 0 $
                else $
                    dx = 0
            endif else $
                self.xyConstrain = 0   ; turn off constraint
        endif

        ;; The translation in data space equals the screen space delta
        ;; multiplied by the unit data space vectors.
        dVec =  ( dx * (*self.pTransInfo)[i].dxVec) $
                     + (dy * (*self.pTransInfo)[i].dyVec)

        ;; Translate to the new coordinates.
        if (isAxis) then begin
            ; Special code for axes, since we need to pass in Keymods,
            ; and retrieve the probe message.
            oVis->Translate, dVec[0], dVec[1], dVec[2], $
                KEYMODS=keymods, KEYVALUE=KeyValue, $
                PROBE_MESSAGE=probeMsg
        endif else begin
            oVis->Translate, dVec[0], dVec[1], dVec[2], /PREMULTIPLY
        endelse
    endfor  ; selected vis loop

    self->_CaptureMacroHistory, dx, dy, $
        KEYMODS=keymods, KEYVALUE=KeyValue, $
        /MOUSE_MOTION

    self.prevXY = [x,y]

    self->ProbeStatusMessage, probeMsg

end


;--------------------------------------------------------------------------
pro IDLitManipTranslate::_OnMouseDown, oWin, x, y, $
    NO_STATUS=noStatus

    ; pragmas
    compile_opt idl2, hidden

    if (self.nSelectionList gt 0) then begin

        sTransInfo = replicate({        $
                           initialTrans: DBLARR(3),   $
                           dxVec: DBLARR(3), $
                           dyVec: DBLARR(3)  $
                         }, self.nSelectionList)

        ;; Loop through all selected visualizations.
        for i=0, self.nSelectionList-1 do begin
            oVis = (*self.pSelectionList)[i]

            ;; Grab the current CTM.
            oVis->IDLgrModel::GetProperty, TRANSFORM=tm
            sTransInfo[i].initialTrans = tm[3, 0:2]

            ;; Transform data space origin to screen space.
            oVis->VisToWindow, [0.0d, 0.0d, 0.0d], scrOrig

            ;; Add one pixel in X to the screen origin, and revert back to
            ;; screen space.
            oVis->WindowToVis, scrOrig + [1.,0.,0.], dataPt
            sTransInfo[i].dxVec = dataPt

            ;; Add one pixel in Y to the screen origin, and revert back to
            ;; screen space.
            oVis->WindowToVis, scrOrig + [0.,1.,0.], dataPt
            sTransInfo[i].dyVec = dataPt

            if (~KEYWORD_SET(noStatus) && OBJ_ISA(oVis, 'IDLitVisAxis')) then begin
                ; For axes, print out a special status, indicating how
                ; to switch directions.
                oDataSpace = oVis->GetDataspace()
                msg = IDLitLangCatQuery('Status:Manip:Translate')
                if oDataSpace->Is3D() then $
                    msg += ',' + IDLitLangCatQuery('Status:Manip:Translate3D')
                self->StatusMessage, msg
            endif

        endfor
        *self.pTransInfo = temporary(sTransInfo)
        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()
        self.startXY = [x,y]
        self.prevXY = [x,y]
    endif

end


;--------------------------------------------------------------------------
; IDLitManipTranslate Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
; TODO: How does the current Visualization...etc fit into these
;       method calls?
;--------------------------------------------------------------------------
; IDLitManipTranslate::OnMouseDown
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

pro IDLitManipTranslate::OnMouseDown, oWin, x, y, $
    iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    self->StatusMessage, $
        IDLitLangCatQuery('Status:Manip:Translate') + ',' + $
        IDLitLangCatQuery('Status:Manip:ShiftConstrains')

    ; Call our internal method.
    self->_OnMouseDown, oWin, x, y

end


;--------------------------------------------------------------------------
; IDLitManipTranslate::OnMouseUp
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

pro IDLitManipTranslate::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    bWasPressed = (self.ButtonPress ne 0)

    ; Free any translation information structures.
    if( n_elements(*self.pTransInfo) gt 0)then $
        void = temporary(*self.pTransInfo)

    if(self.nSelectionList gt 0)then $
        ;; Commit this transaction
        iStatus = self->CommitUndoValues( $
            UNCOMMIT=ARRAY_EQUAL(self.startXY, [x,y]))

    if ~ARRAY_EQUAL(self.startXY, [x,y]) then $
        self->_CaptureMacroHistory, x-self.startXY[0], y-self.startXY[1]


    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    if (bWasPressed) then begin
        ; Restore status message.
        ;
        ; Only perform this step if mouse button was previously
        ; pressed.  Otherwise, this is getting called from the
        ; ::OnKeyboard handler, and in this case, the status message
        ; should not flash.
        statusMsg = self->GetStatusMessage('', KeyMods, /FOR_SELECTION)
        self->StatusMessage, statusMsg
    endif

end

;--------------------------------------------------------------------------
; IDLitManipTranslate::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipTranslate::OnMouseMotion, oWin, x, y, KeyMods
   ; pragmas
   compile_opt idl2, hidden


    if (self.nSelectionList gt 0) then begin

        self->_Translate, oWin, x[0], y[0], KeyMods, 0

        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow

    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
end


;;--------------------------------------------------------------------------
;; IDLitManipTranslate::OnKeyBoard
;;
;; Purpose:
;;   Implements the OnKeyBoard method.
;;
;; Parameters
;;      oWin        - Event Window Component
;;      IsAlpha     - The the value a character or ASCII value?
;;      Character   - The ASCII character of the key pressed.
;;      KeyValue    - The value of the key pressed.
;;                    1 - BS, 2 - Tab, 3 - Return

pro IDLitManipTranslate::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ;; pragmas
   compile_opt idl2, hidden
   ;; Abstract method.

    if (not IsASCII) then begin
        if ((KeyValue ge 5) and (KeyValue le 8)) then begin
            if (Press) then begin

                case KeyMods of
                    1: offset = 40
                    2: offset = 1
                    else: offset = 5
                endcase

                ; Retrieve the list of selected items, and the associated
                ; manipulator targets.
                oSelected = oWin->GetSelectedItems()
                oSelected = self->_FindManipulatorTargets(oSelected)

                *self.pSelectionList = oSelected
                self.nSelectionList = OBJ_VALID(oSelected[0]) ? $
                    N_ELEMENTS(oSelected) : 0

                if (self.nSelectionList eq 0) then $
                    return

                ; Call our internal method.
                self->_OnMouseDown, oWin, x, y, /NO_STATUS

                ; Do the translation.
                case KeyValue of
                    5: x = x - offset
                    6: x = x + offset
                    7: y = y + offset
                    8: y = y - offset
                endcase

                self->StatusMessage, $
                    IDLitLangCatQuery('Status:Manip:Rotate3D1')

                ; Perform the motion, then reset everything.
                self->_Translate, oWin, x[0], y[0], 0, KeyValue
                oTool = self->GetTool()
                if (OBJ_VALID(oTool)) then $
                    oTool->RefreshCurrentWindow
                self->OnMouseUp, oWin, x, y, 1
            endif

            ; Note: to avoid message flashing, the status message should
            ; not be restored on a key release.

        endif ; appropriate keys
    endif ; not ASCII

end


;--------------------------------------------------------------------------
pro IDLitManipTranslate::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#####.     ', $
        '   ....#....    ', $
        '  .#. .#. .#.   ', $
        ' .##...#...##.  ', $
        '.######$######. ', $
        ' .##...#...##.  ', $
        '  .#. .#. .#.   ', $
        '   ....#....    ', $
        '    .#####.     ', $
        '     .###.      ', $
        '      .#.       ', $
        '       .        ', $
        '                ']

    self->RegisterCursor, strArray, 'Translate', /DEFAULT
end

;---------------------------------------------------------------------------
; IDLitManipTranslate::Define
;
; Purpose:
;   Define the base object for the manipulator
;

pro IDLitManipTranslate__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitManipTranslate, $
           INHERITS IDLitManipulator,       $ ; I AM A COMPONENT
           startXY: [0d, 0d], $
           prevXY: [0d, 0d], $
           xyConstrain: 0b, $   ; am I constrained in the X or Y dir?
           pTransInfo: PTR_NEW() $
      }
end
