; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmacrofolder__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitMacroFolder
;
; PURPOSE:
;   This file implements the IDLitMacroFolder class.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitMacroFolder::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitMacroFolder::Init
;
; INTERFACES:
; IIDLProperty
;-

;----------------------------------------------------------------------------
; IDLitMacroFolder::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitMacroFolder::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitMacroFolder::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'DISPLAY_STEPS', /BOOLEAN, $
            Name='Display intermediate steps', $
            Description='Display intermediate steps during macro execution'

    endif

    ; register properties added in IDL 6.2
    if (registerAll || (updateFromVersion lt 620)) then begin

        self->RegisterProperty, 'STEP_DELAY', /FLOAT, $
            Name='Step delay (seconds)', $
            Description='Step delay between macro steps (in seconds)', $
            VALID_RANGE=[0.D, 60.D, 0.01D]

    endif

end


;----------------------------------------------------------------------------
; IDLitMacroFolder::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitMacroFolder::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitContainer::Restore

    ; Register new properties.
    self->IDLitMacroFolder::_RegisterProperties, $
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
;; IDLitMacroFolder::Init
;;
;; Purpose:
;; The constructor of the IDLitMacroFolder object.
;;
;; Parameter

function IDLitMacroFolder::Init, _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    if(self->IDLitContainer::Init(_EXTRA=_extra) eq 0)then $
        return, 0

    ; Register all properties.
    self->IDLitMacroFolder::_RegisterProperties

    return, 1
end


;-------------------------------------------------------------------------
; IDLitMacroFolder::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitMacroFolder::GetProperty,        $
    DISPLAY_STEPS=displaySteps,   $
    STEP_DELAY=stepDelay,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(displaySteps)) then $
        displaySteps = self._displaySteps

    if (arg_present(stepDelay)) then $
        stepDelay = self._stepDelay

    if (n_elements(_extra) gt 0) then $
        self->IDLitContainer::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitMacroFolder::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitMacroFolder::SetProperty,      $
    DISPLAY_STEPS=displaySteps,   $
    STEP_DELAY=stepDelay,   $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(displaySteps) ne 0) then $
        self._displaySteps = displaySteps

    if (N_ELEMENTS(stepDelay) ne 0) then $
        self._stepDelay = stepDelay

    if (n_elements(_extra) gt 0) then $
        self->IDLitContainer::SetProperty, _EXTRA=_extra
end


;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitMacroFolder__Define
;;
;; Purpose:
;; Class definition of the object
;;
pro IDLitMacroFolder__Define
   ;; Pragmas
   compile_opt idl2, hidden

   void = {IDLitMacroFolder,          $
           inherits   IDLitContainer, $
           _displaySteps: 0b,         $
           _stepDelay: 0.0D           $
          }

end



