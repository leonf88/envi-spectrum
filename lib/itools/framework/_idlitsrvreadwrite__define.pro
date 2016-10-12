; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitsrvreadwrite__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the generic IDL Tool object neede for file I/O.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the _IDLitsrvReadWrite object.
;
; Arguments:
;   None.
;
;-------------------------------------------------------------------------
function _IDLitsrvReadWrite::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_SUPER)
end


;-------------------------------------------------------------------------
; _IDLitsrvReadWrite::Cleanup
;
; Purpose:
; The destructor of the _IDLitsrvReadWrite object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
pro _IDLitsrvReadWrite::Cleanup
    compile_opt idl2, hidden

    self->IDLitOperation::Cleanup
end

;;---------------------------------------------------------------------------
;; _IDLitsrvReadWrite::BuildExtensions
;;
;; Purpose:
;;   Routine used to build a list of extensions from a set of read/write
;;   descriptors.
;;
;; Parameters:
;;   oDesc - list of descriptors
;;
;;   sExtensions[out] - Out array of extensions.
;;
;;   sFilterList[out] - Out array of filters
;;
;;   sID[out]         - IDs of the items.
;;
PRO _IDLitsrvReadWrite::BuildExtensions, oDesc, sExtensions, $
                      sFilterlist, sID, WRITERS=writers

   compile_opt hidden, idl2

   sExtensions=''
   sFilterList=''
   sID=''
   count=0
   for i=0, N_ELEMENTS(oDesc)-1 do begin

       ;; Loop through each reader/writer and get its list of
       ;; extensions.
       oReaderWriter = oDesc[i]->GetObjectInstance()
       oReaderWriter->GetProperty, NAME=name
       tmpExt = oReaderWriter->GetFileExtensions(count=nEXT)
       oDesc[i]->ReturnObjectInstance, oReaderWriter

       ; If no extensions then skip this reader/writer.
       if (~nExt) then $
            continue

       ;; create a matching list of reader/writer ids
       tmpID = replicate(oDesc[i]->GetFullIdentifier(), nEXT)

       ; Replace empty strings with '*'
       tmpFilterList = tmpExt
       miss = WHERE(STRCOMPRESS(tmpFilterList,/REMOVE_ALL) eq '', nmiss)
       if (nmiss gt 0) then $
            tmpFilterList[miss] = '*'

       ; Prepend '*.' onto filters (except ones that are already '*')
       notall = WHERE(STRMID(tmpFilterList, 0, 1) ne '*', nNotall)
       if (nNotall gt 0) then $
            tmpFilterList[notall] = '*.' + tmpFilterList[notall]

       if Keyword_Set(writers) then tmpFilterList = tmpFilterList[0]
       
       ; Concat the filters, and add the name.
       tmpFilterList = $
            [[STRING(tmpFilterList, FORMAT='(32767(A,:,"; "))')], [name]]

       ;; Build up our list.
       if(count eq 0)then begin
           sExtensions = tmpExt
           sFilterList = tmpFilterList
           sID = tmpID
       endif else begin
           sExtensions = [sExtensions, tmpExt]
           sFilterList = [sFilterList, tmpFilterList]
           sID = [sID, tmpID]
       endelse

       count += nExt
   endfor
end


;-------------------------------------------------------------------------
; Purpose:
;  Return a (2xN) array of all filter names and extensions that this tool
;  supports.
;
; Result:
;    String array of extensions
;
; Keywords:
;   COUNT   - The number of extensions returned.
;
;
function _IDLitsrvReadWrite::GetFilterList, COUNT=count, SYSTEM=SYSTEM, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    oDesc = self->_GetDescriptors(count=nDesc, system=system)
    self->BuildExtensions, oDesc, sExtensions, filters, sID, _EXTRA=_extra

    format = '(32767(A,:,"; "))'
    n = N_ELEMENTS(filters)/2
    firstFewFilters = STRING(filters[0:2<(n-1),0], FORMAT=format)
    allFilters = STRING(filters[*,0], FORMAT=format)

    filters = [ [[allFilters], ['All iTools files ('+firstFewFilters+', ...)']], $
        filters, $
        [['*'],['All files']] ]
    filters[1:*,1] += ' (' + filters[1:*,0] + ')'

    count = N_ELEMENTS(filters)/2

    return, filters

end


;-------------------------------------------------------------------------
pro _IDLitsrvReadWrite__define

    compile_opt idl2, hidden

    struc = {_IDLitsrvReadWrite,           $
             inherits IDLitOperation}


end

