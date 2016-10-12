; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfloatingtoolbar__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This class represents an operation that (de)activates a toolbar.
;
; Written by: CT, RSI, April 2003
;

;---------------------------------------------------------------------------
; Lifecycle Methods
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Purpose:
;   This function method initializes the component object.
;
; Result:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
; Arguments:
;   None.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
function IDLitopFloatingToolbar::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass.
    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Operation methods
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Purpose:
;   This function method shows/hides the floating toolbar.
;
; Arguments:
;   oTool:  A reference to an IDLitTool object that is
;     requesting the action to take place.
;
; Keywords:
;   None.
;
function IDLitopFloatingToolbar::DoAction, oTool

    compile_opt idl2, hidden

    ; Ask the UI service to present the toolbar to the user.
    ; This assumes that our NAME has been set to the toolbar name.
    success = oTool->DoUIService('FloatingToolbar', self)

    ; Cannot "undo".
    return, OBJ_NEW()
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitopFloatingToolbar object.
;
pro IDLitopFloatingToolbar__define

    compile_opt idl2, hidden
    struc = {IDLitopFloatingToolbar,  $
        inherits IDLitOperation $
    }
end

