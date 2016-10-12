; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopcommandlinefocus__define.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
;+
; :Description:
;    Init method.
;
;
;
; :Keywords:
;    _EXTRA:
;      This method accepts all keywords supported by the ::Init method
;      of this object's superclass.
;
; :Author: chris
;-
function IDLitopCommandLineFocus::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(NAME="IDL Command Line Focus", $
        DESCRIPTION='Show the IDL Command Line', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
;+
; :Description:
;    Perform the action to give focus to the IDL Command Line.
;
; :Params:
;    oTool
;
;
;
; :Author: chris
;-
function IDLitopCommandLineFocus::DoAction, oTool

    compile_opt idl2, hidden

  void = IDLNotify('IDLWorkbenchFocus','org.eclipse.ui.console.ConsoleView')
  return, OBJ_NEW() ; not undoable

end

;---------------------------------------------------------------------------
;+
; :Description:
;    Implement the Command Line Focus operation.
;
;
;
;
;
; :Author: chris
;-
pro IDLitopCommandLineFocus__define

    compile_opt idl2, hidden

    struc = {IDLitopCommandLineFocus,    $
        inherits IDLitOperation   $
    }

end

