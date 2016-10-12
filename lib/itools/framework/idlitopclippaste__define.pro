; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopclippaste__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopClipPaste
;
; PURPOSE:
;   Implements the local clipboard paste operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopClipPaste::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopClipPaste::Init
;
; Purpose:
; The constructor of the IDLitopClipPaste object.
;
; Parameters:
; None.
;
function IDLitopClipPaste::Init,  _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; IDLitopClipPaste::DoAction
;
; Purpose:
;   Will paste the contents of the clipboard to this tool.
;
;
function IDLitopClipPaste::DoAction, oTool, PASTE_SPECIAL=pasteSpecial

   compile_opt idl2, hidden

   ; Make sure we have a tool.
   if (~obj_valid(oTool)) then $
      return, obj_new()

   ; Get the system so that the clipboard can be retrieved
   oSystem = oTool->_GetSystem()
   oClip = oSystem->GetByIdentifier("/CLIPBOARD")

   ; Get the items on the clipboard.
   oItems = oClip->Get(/all, count=nItems)

   if (~nItems) then $
        return, obj_new() ;empty...leave

   ; Get the create vis operation from the tool and pass the desired
   ; information to the create method. It is important to note that
   ; the object descriptor used to create a vis object is that
   ; contained in the clipboard, not an item in the tool. This is
   ; accomplished by using the full identifier.
   oCreate = oTool->GetService("CREATE_VISUALIZATION")
   if(not obj_valid(oCreate))then begin
       self->ErrorMessage, $
	IDLitLangCatQuery('Error:Framework:CannotCreateVizService'), $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
    endif

    ; Make a fake command set to bundle everything up.
    oCmdSet = obj_new("IDLitCommandSet")

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    for i=0, nItems-1 do begin
        status = oItems[i]->PasteItem( oTool, oCreate, oCmdSet, $
            PASTE_SPECIAL=pasteSpecial)
        if(status ne 1 )then begin
            self->ErrorMessage, /use_last_error
            break
        endif
    endfor

    IF (~previouslyDisabled) THEN $
      oTool->EnableUpdates

    ; Remove all the commands and destroy temporary container.
    oCmds = oCmdSet->Get(/ALL, COUNT=count)
    oCmdSet->Remove, /ALL
    OBJ_DESTROY, oCmdSet

    if (~count) then $
        return, OBJ_NEW()

    oCmds[count-1]->SetProperty, NAME=KEYWORD_SET(pasteSpecial) ? $
        'Paste Special' : 'Paste'

    return, oCmds

end


;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
; IDLitopClipPaste__define
;
; Purpose:
;    Defines the clipboard paste operation.
;
pro IDLitopClipPaste__define

    compile_opt idl2, hidden

    struc = {IDLitopClipPaste,       $
             inherits IDLitOperation}
end

