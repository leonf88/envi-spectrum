; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitoprunmacro__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRunMacro
;
; PURPOSE:
;   This file implements the run macro operation for the IDL Tool system
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopRunMacro::Init
;   IDLitopRunMacro::DoAction
;
; INTERFACES:
; IIDLProperty
;-

;----------------------------------------------------------------------------
; IDLitopRunMacro::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitopRunMacro::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitopRunMacro::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'DISPLAY_STEPS', /BOOLEAN, $
            Name='Display intermediate steps', $
            Description='Display intermediate steps during macro execution'

        self->RegisterProperty, 'MACRO_NAME', /STRING, $
            DESCRIPTION='Macro name', $
            NAME='Macro name'

    endif

    ; register properties added in IDL 6.2
    if (registerAll || (updateFromVersion lt 620)) then begin

        ; note that since the UI for this operation uses a simple text
        ; field, we have to clip the values to the valid range in the
        ; setproperty routine, below.
        self->RegisterProperty, 'STEP_DELAY', /FLOAT, $
            Name='Step delay (seconds)', $
            Description='Step delay between macro steps (in seconds)', $
            VALID_RANGE=[0.D, 60.D, 0.01D]

    endif

end


;----------------------------------------------------------------------------
; IDLitopRunMacro::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitopRunMacro::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitOperation::Restore

    ; Register new properties.
    self->IDLitopRunMacro::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.1 to 6.2 or above:
    if (self.idlitcomponentversion lt 620) then begin
        self._stepDelay = 0         ; Default: Delay is zero
    endif
end



;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopRunMacro::Init
;;
;; Purpose:
;; The constructor of the IDLitopRunMacro object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopRunMacro::Init, _REF_EXTRA=_extra
   compile_opt idl2, hidden

    success = self->IDLitOperation::Init(_EXTRA=_extra);

    if (not success) then $
        return, 0

    ; Register all properties.
    self->IDLitopRunMacro::_RegisterProperties

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1

end

;-------------------------------------------------------------------------
;; IDLitopRunMacro::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopRunMacro object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopRunMacro::Cleanup
;   self->IDLitComponent::Cleanup
;end

;-------------------------------------------------------------------------
;; IDLitopRunMacro::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopRunMacro::GetProperty, $
    DISPLAY_STEPS=displaySteps,   $
    MACRO_NAME=macroName, $
    STEP_DELAY=stepDelay, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(displaySteps)) then $
        displaySteps = self._displaySteps

    if (ARG_PRESENT(macroName))then $
        macroName =  self._macroName

    if (ARG_PRESENT(stepDelay)) then $
        stepDelay = self._stepDelay

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end

;-------------------------------------------------------------------------
;; IDLitopRunMacro::SetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopRunMacro::SetProperty, $
    DISPLAY_STEPS=displaySteps,   $
    MACRO_NAME=macroName, $
    STEP_DELAY=stepDelay, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(displaySteps) gt 0) then $
        self._displaySteps = KEYWORD_SET(displaySteps)

    if (N_ELEMENTS(macroName) gt 0)then $
        self._macroName = macroName

    if (N_ELEMENTS(stepDelay) ne 0) then begin
        ; clip to valid range since using simple text entry field
        self._stepDelay = (stepDelay > 0.0) < 60.0
    endif

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
END


;---------------------------------------------------------------------------
; IDLitopRunMacro::DoAction
;
; Purpose:
;
; Parameters:
;   Tool: Object reference to the calling tool.
;
; Keywords:
;   HIDE_CONTROLS: If this keyword is set then do not show the
;       macro controls dialog when running the macro.
;
function IDLitopRunMacro::DoAction, oTool, HIDE_CONTROLS=hideControls

    compile_opt idl2, hidden

    oSrvMacro = oTool->GetService('MACROS')
    if (~OBJ_VALID(oSrvMacro)) then $
        return, obj_new()

    self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI
    if (showExecutionUI) then begin
        self._macroName = ''
        ; Ask the UI service to present the dialog to the user.
        ; This just allows user to select a macro name
        success = oTool->DoUIService('RunMacro', self)
        if strlen(self._macroName) eq 0 then return, obj_new()
    endif else begin
        if strlen(self._macroName) eq 0 then return, obj_new()
        ; If we are programmatically running the macro, retrieve
        ; the macro folder properties and set them on ourself.
        oMacro = oSrvMacro->GetMacroByName(self._macroName)
        if (~OBJ_VALID(oMacro)) then $
            return, obj_new()
        oSrvMacro->GetProperty, NESTING_LEVEL=nestingLevel
        ; if nested, use the existing props from the opRunMacro item
        ; and don't copy the folder props to opRunMacro
        ; if this is the initial invocation, nesting level == 0,
        ; copy the folder props to the operation.
        if nestingLevel eq 0 then begin
            oMacro->GetProperty, DISPLAY_STEPS=displaySteps, $
                STEP_DELAY=stepDelay
            self._displaySteps = displaySteps
            self._stepDelay = stepDelay
        endif
    endelse


    oSrvMacro->SetProperty, $
        DISPLAY_STEPS=self._displaySteps, $
        STEP_DELAY=self._stepDelay

    oCmd = oSrvMacro->RunMacro(self._macroName, HIDE_CONTROLS=hideControls)

    return, oCmd

end


;-------------------------------------------------------------------------
; Purpose:
;   Override our superclass method, because we don't key off types.
;
; Return Value:
;   This function returns a 1 if the object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function IDLitopRunMacro::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Call a helper method in our superclass.
    return, self->IDLitOperation::_CurrentAvailability(oTool)

end


;-------------------------------------------------------------------------
pro IDLitopRunMacro__define

    compile_opt idl2, hidden

    struc = {IDLitopRunMacro, $
        inherits IDLitOperation, $
        _displaySteps: 0b, $
        _macroName: '', $
        _stepDelay:0.0D $
        }

end

