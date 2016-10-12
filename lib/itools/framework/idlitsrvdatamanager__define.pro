; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvdatamanager__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; IDLitsrvDataManager
;;
;; Purpose:
;;  This file contains the implementation of the IDLitsrvDataManager.
;;  This service implements operations that are performed on the data manager.
;;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvDataManager::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvDataManager object.
;;
;;-------------------------------------------------------------------------
function IDLitsrvDataManager::Init, _extra=_extra
    compile_opt idl2, hidden

    ;; just call our super-class
    return, self->IDLitOperation::Init(_extra=_extra)
end
;;---------------------------------------------------------------------------
;; IDLitsrvDataManager::CopyData
;;
;; Purpose:
;;   This method is called to copy an item in the data manager.
;;
;; Parameters:
;;   idData   - The data item to be copied
;;
;; Keywords:
;;   name - The new name for the data item. If not provided, a unique
;;          name is generated
;;
;;   parent - the locatoin to add the data to. If not set, _parent is used.
;;
;; Return Value:
;;   1 - Succeeded
;;   0 - Failure
;;
function IDLitsrvDataManager::CopyData, idData, parent=idparent, name=name
   compile_opt hidden, idl2

   oTool = self->GetTool()

   oData = oTool->GetbyIdentifier(idData)

   ;; no data, no dice
   if(~obj_isa(oData, "IDLitData"))then return, 0

   ;; Get the parent of this data item:
   if(keyword_set(idparent))then $
     oParent = oTool->GetByIdentifier(idParent) $
   else $
     oData->GetProperty, _PARENT=oparent
   if(~obj_valid(oparent))then $
     return, 0

   ;; Get a copy and set the name on the new data
   oCopy = oData->Copy()
   if(not keyword_set(name))then begin
       oCopy->GetProperty, name=name
       ;; make the name unique for all items in the parent
       ;; container. Get a list of the items in the container.
       oItems = oParent->Get(/all, count=count)
       strItems = strarr(count)
       for i=0, count-1 do begin
           oItems[i]->GetProperty, name=itemName
           strItems[i]=itemName
       endfor
       oCopy->SetProperty, name=IDLitGetUniqueName(strItems, name)
   endif else $
       oCopy->SetProperty, name=name
   oTool->AddByIdentifier,"/DATA MANAGER",oCopy
   return,1

end
;;---------------------------------------------------------------------------
;; IDLitsrvDataManager::DeleteData
;;
;; Purpose:
;;   This method is called to delete an item in the data manager.
;;
;; Parameters:
;;   idData   - The data item to delete
;;
;; Return Value:
;;   1 - Succeeded
;;   0 - Failure
;;
function IDLitsrvDataManager::DeleteData, idData
   compile_opt hidden, idl2

   oTool = self->GetTool()

   oData = oTool->GetbyIdentifier(idData)

   ;; no data, no dice
   if(~obj_isa(oData, "IDLitData"))then return, 0

   ;; Get the parent of this data item:
   oData->GetProperty, _PARENT=oparent
   if(obj_valid(oparent))then $
       oParent->Remove, oData

   obj_destroy, oData

   return,1

end
;;-------------------------------------------------------------------------
pro IDLitsrvDataManager__define

    compile_opt idl2, hidden
    struc = {IDLitsrvDataManager, $
             inherits IDLitOperation}
end

