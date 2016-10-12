; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgetitemsize.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
;;---------------------------------------------------------------------------
;; _IDLitGetItemSize_struct
;;
;; Purpose:
;;   Internal routine that is used to get the size of a struct. This
;;   includes travering pointers and objects.
;;
;; Return Value
;;  Size in bytes of a structure and it's contents.

function _IDLitGetItemSize_struct, Item
   compile_opt hidden, idl2

   szItem = size(Item)
   if(szItem[szItem[0]+1] ne 8)then return, 0 ;; not a struct

   ;; Get struct size
   nBytes =   n_tags(Item,/length)*szItem[szItem[0]+2]
  ;; Now check for pointers
   nTags = n_Tags(Item)
   iRef = intarr(nTags)
   for i =0, nTags-1 do begin
       sz=size(Item[0].(i),/type)
       iRef[i] = (sz eq 10 or sz eq 11);; ptr or obj?
   endfor
   iDex = where(iRef, nRef)     ;what fields are a heap var
   if(nRef gt 0)then begin
       for i=0, n_elements(Item)-1 do begin ;for the array
            ;; size of each item. We subtract 4 so we don't double-count,
            ;; since IDLitGetItemSize() will include the ptr/obj size.
           for j=0, nRef-1 do $
             nBytes += IDLitGetItemSize(Item[i].(iDex[j])) - 4
       endfor
   end
   return, nBytes
end
;;---------------------------------------------------------------------------
;;IDLitGetItemSize
;;
;; Purpose:
;;   This is an internal routine that will calculate the size (bytes)
;;   of a given IDL variable. This routine will walk pointers, but
;;   can only handle IDLitData objects. The return value is approximate.
;;
;; Parameter:
;;   Item  - The item to get the size of
;;
;; Return Value
;;    The size of the item:
function IDLitGetItemSize, Item
    compile_opt idl2, hidden

  ;; The plan is to do the following:
  ;;   (size of data type) * n_elements()

  szItem = size(Item,/l64)
  nBytes=0
  case szItem[szItem[0]+1] of
    0:   nBytes =   0 ; undefined
    1:   nBytes =   szItem[szItem[0]+2]     ;byte
    2:   nBytes =   2ULL*szItem[szItem[0]+2]     ;int
    3:   nBytes =   4ULL*szItem[szItem[0]+2]     ;long
    4:   nBytes =   4ULL*szItem[szItem[0]+2]     ;float
    5:   nBytes =   8ULL*szItem[szItem[0]+2]     ;double
    6:   nBytes =   8ULL*szItem[szItem[0]+2]     ;complex
    7:   nBytes =   ulong64(total(strlen(Item))) ;string
    8:   nBytes =   _IDLitGetItemSize_struct(Item); struct
    9:   nBytes =   16ULL*szItem[szItem[0]+2]    ;double complex
    10:  begin
          for i=0, szItem[szItem[0]+2]-1 do begin ;; contents + HVID size
            nBytes +=  ptr_valid(Item[i]) ? IDLitGetItemSize(*Item[i])+4 : 4
          endfor
        end
    11:  begin
           isData = obj_isa(Item, "IDLitData")
           for i=0, szItem[szItem[0]+2]-1 do $ ;; contents
                nBytes += isData[i]  ? Item[i]->GetSize() : 4ULL
         end
    12:  nBytes =   2ULL*szItem[szItem[0]+2]     ;unsigned int
    13:  nBytes =   4ULL*szItem[szItem[0]+2]     ;unsigned long
    14:  nBytes =   8ULL*szItem[szItem[0]+2]     ;64 bit int
    15:  nBytes =   8ULL*szItem[szItem[0]+2]     ;unsigned 64 bit int
    else: message, "SYSTEM ERROR: Unknow IDL data type"
  endcase

  return, nBytes
end
