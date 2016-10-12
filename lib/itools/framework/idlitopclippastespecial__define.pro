; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopclippastespecial__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopClipPasteSpecial
;
; PURPOSE:
;   Implements the local clipboard paste special operation. This
;   operation differs from paste in that it tries to use the original
;   data reference and not a copy.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopClipPasteSpecial::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopClipPasteSpecial::Init
;
; Purpose:
; The constructor of the IDLitopClipPasteSpecial object.
;
; Parameters:
; None.
;
function IDLitopClipPasteSpecial::Init,  _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitopClipPaste::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; IDLitopClipPasteSpecial::DoAction
;
; Purpose:
;   Will paste the contents of the clipboard to this tool. This
;   will not use a copy of the data on the clipboard, but the
;   identifier of the original data.
;
;
function IDLitopClipPasteSpecial::DoAction, oTool

   compile_opt idl2, hidden

    return, self->IDLitopClipPaste::DoAction(oTool, /PASTE_SPECIAL)
end


;---------------------------------------------------------------------------
pro IDLitopClipPasteSpecial__define

    compile_opt idl2, hidden

    struc = {IDLitopClipPasteSpecial, $
             inherits IDLitopClipPaste}

end

