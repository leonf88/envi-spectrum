; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitclipboarditem__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitClipBoardItem
;
; PURPOSE:
;   This object is used to record and maintain the state of an item
;   that is placed on the clipboard. The object is a sub-class of the
;   object descriptor class, which performs a majority of the items
;   needed for the system (repliction of objects).
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitObjDesc
;
; SUBCLASSES:
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitClibBoardItem::Init
;;
;; Purpose:
;; The constructor of the IDLitClibBoardItem object.
;;
;; Parameters:
;; NONE
;;
;; Keywords
;;   LAYER   - Used  to set the layer that this item is a part of.
;;
function IDLitClipBoardItem::Init, $
                           LAYER=LAYER, _EXTRA=_extra

  ;; Pragmas
  compile_opt idl2, hidden

  if(self->IDL_Container::Init() eq 0)then $
    return, 0

  if (~self->IDLitObjDescVis::Init(_EXTRA=_EXTRA)) then begin
      self->IDL_Container::Cleanup
      return, 0
  endif

  self._pDataList = ptr_new(/allocate)

  if(keyword_set(LAYER))then $
    self._strLayer = LAYER

  self._pParentType = ptr_new('')

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::Cleanup
;;
;; Purpose:
;;   Destructor for the object.
;;
;;
pro IDLitClipBoardItem::Cleanup

  compile_opt idl2, hidden
  ;; cleanup any data values
  if( n_elements(*self._pDataList) gt 0)then $
    obj_destroy, (*self._pDataList).oData

  ptr_free, self._pDataList, self._pParentType

  self->IDLitObjDescVis::Cleanup
  self->IDL_Container::Cleanup
end
;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::_SetParentTypes
;;
;; Purpose:
;;    Used to set the parent types for this item. This is the types of
;;    items that this can be pasted to.
;;
;; Parameter:
;;   types     - The types that this item can be pasted to.

pro IDLitClipBoardItem::_SetParentTypes, types
    compile_opt hidden, idl2

    *self._pParentType = strupcase(types)
end
;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::GetParentTypes
;;
;; Purpose:
;;   Used to get the list of parent types for this item.
;;
;;
function IDLitClipBoardItem::GetParentTypes
   compile_opt hidden, idl2

   return, *self._pParentType
end
;;---------------------------------------------------------------------------
;; IDLitClipboardItem::AddDataParameter
;;
;; Purpose:
;;   Add a parameter to the internal data list for this clipboard
;;   entry. The parameter name, data object copy and id of the source
;;   data is provided.
;;
;; Parameters
;;    strName  - Parameter name for the data.
;;
;;    oData    - The data object copy
;;
;;    idData   - ID of the original data.
;;
;; Keywords:
;;    BY_VALUE - Set if this is a by value parameter. If this is set,
;;               the data identifier is always ignored.

pro IDLitClipBoardItem::AddDataParameter, strName, oData, idData, $
                      BY_VALUE=BY_VALUE

  compile_opt idl2, hidden

  ;; Make our record

  recNew ={_IDLitClipBoardDataRec_t}

  recNew.by_value = keyword_set(BY_VALUE)
  recNew.strName = strupcase(strName)
  recNew.idData = idData
  recNew.oData=oData

  nItems = n_elements(*self._pDataList)
  if(nItems gt 0)then begin
      dex = where((*self._pDataList).strName eq recNew.strName, nMatch)
      if(nMatch gt 0)then begin ;; remove the old item, if conflict
          obj_destroy, ((*self._pDataList)[dex]).oData
          (*self._pDataList)[dex[0]] = recNew
      endif else $
        *self._pDataList = [*self._pDataList, temporary(recNew)]

  endif else $
    *self._pDataList = temporary(recNew)

end
;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::GetParameterCount
;;
;; Purpose:
;;   Returns the # of parameters this item contains.

function IDLitClipBoardItem::GetParameterCount
   compile_opt hidden, idl2

   return,n_elements(*self._pDataList)

end
;;---------------------------------------------------------------------------
;; IDLItClipBoardItem::GetPararamter
;;
;; Purpose:
;;   Used to get the value and name of a stored parameter in this
;;   clipboard item. Normally the data is returned as a copy of what
;;   is contained, but if the get_identifier keyword is set, the id is
;;   returned.
;;
;; Parameters:
;;    nParam [in]   - The parameter number to return.
;;
;;    NAME   [out]  - The name of the parameter
;;
;;    Data   [out]  - The data for this prameter. By default this is a
;;                    copy of the item on the clipboard. If
;;                    GET_IDENTIFIER is specified, this is the id of
;;                    the original data.
;;
;; Keywords:
;;   GET_IDENTIFIER - If set, data is returned as an identifier to the
;;                    target or orignal data.
;;
;;   BY_VALUE       - Returns the by value for this data. If a data
;;                    item is by value, the data object copy is always
;;                    returned.
;;
;; Return Value
;;    1 -Success
;;    0 -Error
;;
;;
function IDLitClipBoardItem::GetParameter,nParam,  NAME, Data, $
                           BY_VALUE=BY_VALUE, $
                           GET_IDENTIFIER=GET_IDENTIFIER

    compile_opt idl2, hidden

    nItems = n_elements(*self._pDataList)
    if(nItems-1 lt nParam or nParam lt 0)then return, 0 ;; bad

    NAME = (*self._pDataList)[nParam].strName
    by_value = (*self._pDataList)[nParam].by_value
    Data = (keyword_set(GET_IDENTIFIER) ? $
            (*self._pDataList)[nParam].idData : $
            (*self._pDataList)[nParam].oData->Copy());;note: copy of data
    return, 1
end
;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::ContainsByValue
;;
;; Purpose:
;;   Returns True if this item contains any by value values.
;;
;; Keywords:
;;   IS_ALL - Returns true if all the contents of this item are
;;            by value.
;;
function IDLitClipBoardItem::ContainsByValue, IS_ALL=IS_ALL
    compile_opt hidden, idl2

    by_value=0
    nItems = n_elements(*self._pDataList)
    if(nItems gt 0)then $
      void = where((*self._pDataList).by_value ne 0, by_value)

    IS_ALL = (by_value eq nItems)
    return, (by_value gt 0)
end
;;---------------------------------------------------------------------------
;; IDLitClibBoardItem::GetProperty
;;
;; Purpose:
;;   Return property values for this object
;;
;; Keywords:
;;  LAYER   - The layer that this object was recorded from.
;;
;;  All other keywords are passed to it's super class.

pro IDLitClipBoardItem::GetProperty, LAYER=LAYER, _ref_extra=_extra
  compile_opt hidden, idl2

   if(arg_present(layer))then $
       LAYER=self._strLayer

   if(n_elements(_extra) gt 0)then $
     self->IDLitObjDescVis::GetProperty, _extra=_extra

end
;;---------------------------------------------------------------------------
;; IDLitClipboardItem::SetProperty
;;
;; Purpose:
;;   Allows for property setting on this item.
;;
;; Parameters;
;;   None.
;;
;; Keyword:
;;   LAYER - The target layer for this item
pro IDLitClipBoardItem::SetProperty, LAYER=LAYER, _extra=_extra

   compile_opt idl2, hidden

   if(n_elements(LAYER) gt 0)then $
       self._strLayer = LAYER

   if(n_elements(_extra) gt 0)then $
     self->IDLitObjDescVis::SetProperty, _extra=_extra
end

;;---------------------------------------------------------------------------
;; IDLitopClipCopy::_CopyItemData
;;
;; Purpose:
;;   This method will copy the data or data reference information of
;;   the target item and place it in the given clipboard item.
;;
;; Parameters:
;;  oTarget   - The item to copy
;;
;;  oCBItem   - The clipboard item/record
;;
PRO IDLitClipBoardItem::_CopyItemData, oTarget

  compile_opt hidden, idl2

  parameters = oTarget->QueryParameter(COUNT=nparam)

  if (~nparam) then $
    return

  for i=0, nparam-1 do begin
      oTarget->GetParameterAttribute, parameters[i], $
        NAME=name, BY_VALUE=by_value
      ;; Get the data.
      oDataObj = oTarget->GetParameter(name)
      if(obj_valid(oDataObj))then begin
          self->AddDataParameter, name, oDataObj->Copy(), $
               oDataObj->GetFullIdentifier(), by_value=by_value
      endif
  endfor
end


;;---------------------------------------------------------------------------
PRO IDLitClipboardItem::CopyItem, oTarget

   compile_opt idl2, hidden

   if(not obj_isa(oTarget, "IDLitVisualization"))then $
     return ;; can only copy visualizations
   strClass = obj_class(oTarget)
   oTarget->GetProperty, name=name, ICON=icon, PRIVATE=private
   self.isManipulatorTarget = oTarget->IsManipulatorTarget()
   self->SetProperty, classname=strClass, NAME=name, $
    ICON=icon, PRIVATE=private

   ;; This is a special case for ROIs
   if(obj_isa(oTarget, "IDLitVisROI"))then $
     self->_SetParentTypes, ["IDLIMAGE", "IDLSURFACE"]

   ;; This is a special case for Image Planes
   if(obj_isa(oTarget, "IDLitVisImagePlane"))then $
     self->_SetParentTypes, ["IDLVOLUME"]

   ;; This is a special case for Legend Items
   if(obj_isa(oTarget, "IDLitVisLegendItem"))then $
     self->_SetParentTypes, ["IDLLEGEND", "IDLLEGENDITEM"]

   ;; Record the current property settings for this object.
   ;; This is used to prevent the object descriptor
   ;; from trying to produce a new object instance during the call to
   ;; query props.
   self._bPropsInited=1b
   self->RecordProperties, oTarget
   self->_CopyItemData, oTarget
   
   ;; This is a special case for annotations
   if (OBJ_ISA(oTarget, 'IDLitVisPolygon') || $
       OBJ_ISA(oTarget, 'IDLitVisPolyline') || $
       OBJ_ISA(oTarget, 'IDLitVisText')) then begin
     ;; Record data needed to copy/paste between layers
     if (oTarget->DoPreCopy(oParmSet)) then $
       self->AddDataParameter, '__COPY_DATA', oParmSet, $
         oParmSet->GetFullIdentifier()
   endif

   ;; Do we have any valid vis children?
   oChildren = oTarget->Get(/all, count=nChild, $
                            ISA="IDLitVisualization")
   for i=0, nChild-1 do begin
       ;; We assume that all private items are created in the init
       ;; method of the object being copied.
       oChildren[i]->GetProperty, _CREATED_IN_INIT=inInit
       if(~inInit)then begin
           oChildItem = obj_new("IDLitClipBoardItem")
           oChildItem->CopyItem, oChildren[i]
           self->Add, oChildItem
       endif
   endfor

end


;;---------------------------------------------------------------------------
;; IDLitClipBoardItem::PasteItem
;;
;; Purpose:
;;   This routine is used to paste the vis item represented by this
;;   object to the tool.


function IDLitClipBoardItem::PasteItem, oTool, oCreate, $
                           oCmdSet, DESTINATION=DESTINATION, $
                           PASTE_SPECIAL=PASTE_SPECIAL

   compile_opt idl2, hidden

   ; Reset the tool property on myself to the target tool.
   self->_SetTool, oTool

   self->GetProperty, layer=layer
   ;; Okay, build up a parameter set. Do we have anything?
   nParms = self->GetParameterCount()

   if(nParms gt 0)then begin
       oParmSet = obj_new("IDLitParameterSet", NAME="Clipboard Copy")
       for i=0, nParms-1 do begin
           ;; Get the data.
           if(self->GetParameter(i, name, oData, $
                                 get_identifier=paste_special, $
                                 by_value=by_value))then begin
               ;; Special case for annotation device_data
               if (name eq '__COPY_DATA') then begin
                 ;; Copy/paste data does not need to be added to the 
                 ;; parameter set; just note that it exists and move on
                 oCopyData = oData
                 hasCopyData = 1b
                 continue
               endif

               ;; The value of oData will be an object if we are not doing a
               ;; paste special or if the data stored is by value and we are
               ;; doing a paste specail
               if(keyword_set(paste_special))then $
                 oData = oTool->GetByIdentifier(oData) $ ;use the link
               else if(not obj_valid(oData))then begin
                   oTool->ErrorMessage, $
		     IDLitLangCatQuery('Error:Framework:NoAccess'), $
                     title=IDLitLangCatQuery('Error:InternalError:Title'), severity=1
                   ;; Nuke the parameter set. This will destroy all data
                   ;; copies that were also create.
                   obj_destroy, oParmSet
                   return, 0
               endif
               oParmSet->Add, oData, parameter_name=name, $
                              preserve_location=keyword_set(paste_special)
           endif
       endfor
       if(oParmSet->Count() eq 0 and nParms gt 0)then begin
           obj_destroy, oParmSet
           return, 0
       end
       ;; Okay, lets create this visualization.
       IF ~keyword_set(paste_special) THEN $
         oTool->AddByIdentifier, "/Data Manager", oParmSet
   endif
   ;; If this item has a target type, then set destination ID (if not
   ;; already set.
   parTypes = self->GetParentTypes()
   if(~keyword_set(DESTINATION) && keyword_set(parTypes[0]))then begin
       oSel = oTool->getselecteditems(count=nSel)
       if(nSel gt 0)then $
           DESTINATION=oSel->getfullidentifier()
   endif

   ;; Annotations might go into the annotation layer
   if (N_ELEMENTS(hasCopyData) ne 0) then begin
     ;; Assume layer is data space
     layer = ''
     ;; Determine which layer is selected
     oSel = oTool->getselecteditems(count=nSel)
     ;; Nothing selected might mean the annotation layer is selected
     if (nSel eq 0) then begin
       oWin = oTool->GetCurrentWindow()
       oView = oWin->GetCurrentView()
       oAnnoLayer = oView->Get(/ALL, ISA='IDLitgrAnnotateLayer')
       if (oAnnoLayer->IsSelected()) then $
         layer = 'ANNOTATION'
     endif else begin
       ;; Check parent of first item
       oSel[0]->GetProperty, _PARENT=oParent
       if (OBJ_ISA(oParent, 'IDLitgrAnnotateLayer')) then $
         layer = 'ANNOTATION'
     endelse
   endif
   
   oSet = oCreate->_Create(self, oParmSet, $
                           DESTINATION=DESTINATION, $
                           ID_VISUALIZATION=idDest, $
                           BY_VALUE=by_value, $
                           LAYER=layer, $
                           MANIPULATOR_TARGET=self.isManipulatorTarget)

   ;; Annotations might need to have their data values converted if the
   ;; layer has changed from the copied original
   if (N_ELEMENTS(hasCopyData) ne 0) then begin
     oObj = oTool->GetByIdentifier(idDest)
     if (OBJ_VALID(oObj)) then begin
       if (~oObj->DoPostPaste(oCopyData)) then begin
         ;; If object could not be created then destroy it and the resulting
         ;; command set
         oObj->GetProperty, _PARENT=oParent
         oParent->Remove, oObj
         OBJ_DESTROY, [oObj, oSet]
       endif
     endif
   endif

   if (OBJ_VALID(oSet[0])) then $
     oCmdSet->Add, oSet


   IF keyword_set(paste_special) THEN BEGIN
     oParmSet->Remove,/ALL
     obj_destroy,oParmSet
   ENDIF

   ;; Do we have any valid vis children?
   oChildren = self->Get(/all, count=nChild)
   for i=0, nChild-1 do begin
       status = oChildren[i]->PasteItem(oTool, oCreate, $
                                        oCmdSet, $
                                        DESTINATION=idDest, $
                                        PASTE_SPECIAL=PASTE_SPECIAL)
       if(status ne 1)then $
         return, 0
   endfor

   return, 1
end
;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; IDLitClipboardItem__Define
;;
;; Purpose:
;; Class definition for the IDLitClipboardItem class
;;

pro IDLitClipboardItem__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitClipBoardItem, $
          inherits   IDLitObjDescVis,    $
          inherits   IDL_Container,   $
          _pParentType : ptr_new(), $
          _strLayer: '', $ ;; Layer name...for annotations.
          _pDataList: ptr_new(), $ ;; Point to manage data/parameters
          isManipulatorTarget: 0b $  ; is our copied item a manip target?
         }

   ;; Define our internal dictionary structure
   void = {_IDLitClipBoardDataRec_t, $
           strName : "", $
           idData  : "", $ ;; for by ref
           by_value: 0b, $ ;; a by_value item
           oData   : obj_new() } ;; by value

end
