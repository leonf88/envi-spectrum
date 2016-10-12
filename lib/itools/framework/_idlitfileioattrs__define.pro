; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitfileioattrs__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitFileIOAttrs
;
; PURPOSE:
;   This file implements the _IDLitFileIOAttrs class. This class is an abstract
;   class for other file readers and is used to manage file
;   extensions. Pretty simple.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:

; SUBCLASSES:
;
; CREATION:
;   See _IDLitFileIOAttrs::Init
;
; METHODS:
;   This class has the following methods:
;
;   _IDLitFileIOAttrs::Init
;   _IDLitFileIOAttrs::Cleanup
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; _IDLitFileIOAttrs::Init
;;
;; Purpose:
;; The constructor of the _IDLitFileIOAttrs object.
;;
;; Parameters:
;;
;; Properties:
;;

function _IDLitFileIOAttrs::Init, Extensions, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitiMessaging::Init(_EXTRA=_extra)) then $
        return, 0

    n = N_ELEMENTS(Extensions)
    if ((n gt 0) && (n ne 1 || Extensions[0] ne '')) then $
        self._pExtensions = ptr_new(Extensions)

    return, 1
end

;;---------------------------------------------------------------------------
;; _IDLitFileIOAttrs::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro _IDLitFileIOAttrs::Cleanup

    compile_opt idl2, hidden

    ptr_free, self._pExtensions

end


;---------------------------------------------------------------------------
; Purpose:
;   Boiler plate routine is provided to allow the user the opporunity
;   to grab any temporary resources.
;
; Return Value:
;   1  - On success
;   0  - On failure
;
function _IDLitFileIOAttrs::Create
    compile_opt idl2, hidden
    return, 1
end


;---------------------------------------------------------------------------
;  Purpose:
;   Boiler plate routine is used to provide the ability for the user
;   to free any temporary resources.
;
pro _IDLitFileIOAttrs::Shutdown
    compile_opt idl2, hidden
end


;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; _IDLitFileIOAttrs::GetFileExtensions
;;
;; Purpose:
;;   Returns the file extenions that are supported by this file.
;;
;; Keywords:
;;  COUNT   = The number of items returned.
;;
;; Return Value
;;  An array of strings that are the file extensions stored for this
;;  class. If nothing is contained, count is set to 0 and '' is returned.

function _IDLitFileIOAttrs::GetFileExtensions, count=count

    compile_opt idl2, hidden

    if (~PTR_VALID(self._pExtensions)) then begin
        count = 0
        return, ''
    endif

    count = N_ELEMENTS(*self._pExtensions)

    return, *self._pExtensions

end


;---------------------------------------------------------------------------
; Purpose:
;   Retrieve the filename.
;
function _IDLitFileIOAttrs::GetFilename
   compile_opt idl2, hidden
   return, self._strFilename
end


;---------------------------------------------------------------------------
; Purpose:
;   Set the filename.
;
pro _IDLitFileIOAttrs::SetFilename, strFilename
   compile_opt idl2, hidden
   self._strFilename = strFilename
end


;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; _IDLitFileIOAttrs__Define
;;
;; Purpose:
;; Class definition for the _IDLitFileIOAttrs class
;;

pro _IDLitFileIOAttrs__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {_IDLitFileIOAttrs, $
          inherits         IDLitIMessaging, $
          _strFilename     : '', $ ; the stored filename.
          _pExtensions     : ptr_new()}


end
