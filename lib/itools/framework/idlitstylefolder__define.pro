; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitstylefolder__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitStyleFolder
;
; PURPOSE:
;   This file implements the IDLitStyleFolder class.
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
;   See IDLitStyleFolder::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitStyleFolder::Init
;
; Purpose:
; The constructor of the IDLitStyleFolder object.
;
; Parameter

function IDLitStyleFolder::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitContainer::Init(_EXTRA=_extra)) then $
        return, 0

    return, 1
end

;-------------------------------------------------------------------------
function IDLitStyleFolder::_VerifyName, name

    compile_opt idl2, hidden

    ; Don't allow null strings or just spaces.
    if (STRLEN(STRCOMPRESS(name, /REMOVE)) eq 0) then $
        return, ''

    ; Replace / with underscores, since this name will be
    ; used for the identifier when styles are re-loaded.
    newname = STRJOIN(STRSPLIT(name, '/', /EXTRACT), '_')


    ; Now look for name conflicts with other styles.

    oSys = _IDLitSys_GetSystem(/NO_CREATE)
    if (~OBJ_VALID(oSys)) then $
        return, newname
    oService = oSys->GetService('STYLES')
    if (~OBJ_VALID(oService)) then $
        return, newname

    ; Use style service to determine if we have a name conflict.
    if (oService->_NewStyleName(newname) ne newname) then $
        return, ''

    ; If we reach here, then the new name is okay.
    return, newname
end


;-------------------------------------------------------------------------
pro IDLitStyleFolder::SetProperty, $
    NAME=name, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(name) ne 0) then begin
        self->IDLitContainer::GetProperty, NAME=oldname
        myname = self->_VerifyName(name)
        if (myname ne '') then $
            self->IDLitContainer::SetProperty, NAME=myname
        ; Notify observers like the tree in the style editor.
        oSys = _IDLitSys_GetSystem()
        if (OBJ_VALID(oSys)) then begin
            oSys->DoOnNotify, self->GetFullIdentifier(), $
                'SETPROPERTY', 'NAME'
        endif
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitContainer::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitStyleFolder__Define
;
; Purpose:
; Class definition of the object
;
pro IDLitStyleFolder__Define

   compile_opt idl2, hidden

   void = {IDLitStyleFolder, $
           inherits   IDLitContainer $
          }

end



