; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitreader__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitReader
;
; PURPOSE:
;   This file implements the IDLitReader class. This class is an abstract
;   class for other file readers.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;   IDLitIMessaging
;   _IDLitFileIOAttrs
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitReader::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitReader::Init
;;
;; Purpose:
;; The constructor of the IDLitReader object.
;;
;; Parameters:
;;   Extensions   - A string scalar or array of the file extensions
;;                  associated with this file type.
;; Keywords:
;;   All are passed to it's superclass.
;;

function IDLitReader::Init, Extensions, _REF_EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

    if (~self->IDLitComponent::Init(_EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitFileIOAttrs::Init(Extensions, _EXTRA=_extra)) then begin
        self->IDLitComponent::Cleanup
        return, 0
    endif

    self->SetPropertyAttribute, 'NAME', SENSITIVE=0
    self->SetPropertyAttribute, 'DESCRIPTION', SENSITIVE=0, /HIDE

    ;; Set the rest.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitReader::SetProperty, _EXTRA=_extra

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitReader::Cleanup
;;
;; Purpose:
;;   Standard cleanup method for object lifecycle. This just passes
;;   control to superclasses.
;;
pro IDLitReader::Cleanup
    compile_opt hidden, idl2

    self->_IDLitFileIOAttrs::Cleanup
    self->IDLitComponent::Cleanup
end


;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; Provided by subclass, these are stubs
;;---------------------------------------------------------------------------
;; IDLitReader::Isa
;;
;; Purpose:
;;  Called to determine if the give file is the correct type.
;;  Normally the implementor of a subclass would provide the logic to
;;  do this operation. The default functionaity provided here will use
;;  the file extension.
;;
;; Parameters:
;;   strFilename    - The file to check
;;
;; Keywords:
;;   None.
;;
;; Return Value:
;;   1 - The file is of this type
;;
;;   0 - The file is not of this type
function IDLitReader::IsA, strFilename
   compile_opt hidden, idl2

   ;; Are any file extensions registered?
   ext = self->GetFileExtensions(count=cnt)
   if(cnt eq 0)then return, 0

   ;; Grab the extension off the filename.
   iDot = STRPOS(strFilename, '.', /REVERSE_SEARCH)
   if(iDot gt 0)then begin
       fileSuffix = STRUPCASE(STRMID(strFilename, iDot + 1))
       dex = where(fileSuffix eq strupcase(ext), nMatch)
       return, (nMatch gt 0)
   endif
   return, 0
end

;;---------------------------------------------------------------------------
;; IDLitReader::GetData
;;
;; Purpose:
;;   This routine is called to get the data from the file. It is the
;;   resonsiblity of the subclass to implement the logic of this this
;;   routine so it can read or access the file of the particular type.
;;
;; Parameters:
;;   oData [out]   - This routine will create this data object and
;;                   place the results of the read operation in it.
;;
;; Keywords:
;;   None.
;;
;; Return Value:
;;    1 - Successful Read
;;
;;    0 - Failure reading from the file.
;;
function IDLitReader::GetData, oData
   compile_opt hidden, idl2
   return, 0
end

;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitReader__Define
;;
;; Purpose:
;; Class definition for the IDLitReader class
;;

pro IDLitReader__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReader, $
          inherits         IDLitComponent,    $
          inherits         _IDLitFileIOAttrs   $
         }
end
