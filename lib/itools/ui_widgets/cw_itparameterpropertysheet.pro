;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itparameterpropertysheet.pro#1 $
;;
;; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;
;; PURPOSE:
;;   This widget displays the parameters of an IDLitParameter object
;;   in a propertysheet setting.
;;
;; MODIFICATION HISTORY:
;;   Created by:  AGEH, April 2004
;;

;;;;;;;;;;;;;;; IDLitParamProp  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; PURPOSE:
;;   This object is used to display parameters in a property sheet in
;;   the parameter editor and insert visualization modes of the data
;;   manager.  It is intended to be used only by the
;;   cw_itParameterPropertySheet widget.
;;
;; PARAMETERS:
;;   STRUCT - A structure with the following definition:
;;            {vistype : string(s) - name(s) of visualization(s),
;;             vistypenum : integer - index of vistype to set
;;             var_names : string(s) - internal name of properties to
;;                                     be registered,
;;             names : string(s) - external names of properties to be
;;                                 registered,
;;             values : data - These values are what is returned via
;;                             GetProperty
;;             required : byte - set if the parameter is required
;;            }
;;   Note: the number of elements of var_names, names, values, and
;;         required should all be the same.
;;
FUNCTION IDLitParamProp::Init, struct
  compile_opt idl2, hidden

  ;; init super class
  IF ~self->IDLitComponent::Init() THEN return,0

  ;; hide name and description
  self->SetPropertyAttribute,['NAME','DESCRIPTION'],/HIDE

  ;; if a single string was passed in it is the name of a
  ;; visualization with no input parameters
  IF (size(struct,/type) EQ 7) THEN BEGIN
    str = (struct NE '') ? struct : 'Selected item'
    str += ' has no input parameters'
    self->IDLitComponent::SetProperty,NAME=str
    return,1
  ENDIF

  IF (n_elements(struct) EQ 0) THEN BEGIN
    self->IDLitComponent::SetProperty, $
      NAME='Selected item'+' has no input parameters'
    return,1
  ENDIF

  ;; if one vis type was passed in then add a vis_type parameter
  IF (n_elements(struct.vistype) EQ 1) THEN BEGIN
    self->IDLitComponent::SetProperty,NAME=struct.vistype+' Parameters'
  ENDIF ELSE BEGIN
    self->RegisterProperty, 'VIS_TYPE', NAME='Select a visualization', $
      ENUMLIST=struct.vistype
    self->IDLitComponent::SetProperty,NAME='Parameters'
    ;; set current vis type
    self._vistype = struct.vistypenum
  ENDELSE

  ;; register the properties
  FOR i=0,n_elements(struct.var_names)-1 DO $
    self->RegisterProperty,struct.var_names[i], $
    NAME=struct.names[i]+(struct.required[i] ? ' *' : ''),/STRING

  ;; save member data
  self._struct = ptr_new(struct)

  return,1

END

;;-------------------------------------------------------------------------
;; IDLitParamProp::Cleanup
;;
;; PURPOSE:
;;   Cleanup routine
;;
PRO IDLitParamProp::Cleanup
  compile_opt idl2, hidden

  self->IDLitComponent::Cleanup
  ptr_free,self._struct

END

;;-------------------------------------------------------------------------
;; IDLitParamProp::SetProperty
;;
;; PURPOSE:
;;   Sets any of the defined properties.
;;
PRO IDLitParamProp::SetProperty, _REF_EXTRA=_extra

  compile_opt idl2, hidden

  ; Use strict keyword matching in case we have a name
  ; conflict between one of our superclass properties and a parameter name.
  ; An example would be "NAME" and a parameter called "N".
  if (MAX(_extra eq 'NAME') eq 1) then $
      self->IDLitComponent::SetProperty, _EXTRA='NAME'
  if (MAX(_extra eq 'DESCRIPTION') eq 1) then $
      self->IDLitComponent::SetProperty, _EXTRA='DESCRIPTION'

  ;; vis type
  idx = (WHERE(_extra eq 'VIS_TYPE'))[0]
  if (idx ge 0) then begin
    self._vistype = (Scope_Varfetch(_extra[idx],/REF_EXTRA))
  endif

  if (~PTR_VALID(self._struct)) then $
    return

  ;; all other properties that were created on the fly
  FOR i=0,n_elements(_extra)-1 DO BEGIN
    ind = where(strupcase(_extra[i]) EQ strupcase((*self._struct).var_names))
    IF (ind NE -1) THEN $
      (*self._struct).values[ind] = Scope_Varfetch(_extra[i],/REF_EXTRA)
  ENDFOR

END

;;-------------------------------------------------------------------------
;; IDLitParamProp::GetProperty
;;
;; PURPOSE:
;;   Retrieves any of the defined properties
;;
PRO IDLitParamProp::GetProperty, _REF_EXTRA=_extra

  compile_opt idl2, hidden

  ; Get superclass properties.
  ; Use strict keyword matching in case we have a name
  ; conflict between one of our superclass properties and a parameter name.
  ; An example would be "NAME" and a parameter called "N".
  if (MAX(_extra eq 'NAME') eq 1) then $
      self->IDLitComponent::GetProperty, _EXTRA='NAME'
  if (MAX(_extra eq 'DESCRIPTION') eq 1) then $
      self->IDLitComponent::GetProperty, _EXTRA='DESCRIPTION'

  ;; vis type
  idx = (WHERE(_extra eq 'VIS_TYPE'))[0]
  if (idx ge 0) then begin
    (Scope_Varfetch(_extra[idx],/REF_EXTRA)) = self._vistype
  endif

  if (~PTR_VALID(self._struct)) then $
    return

  ;; all other properties that were created on the fly
  FOR i=0,n_elements(_extra)-1 DO BEGIN
    index = (where(_extra[i] EQ strupcase((*self._struct).var_names)))[0]
    IF (index NE -1) THEN $
      (Scope_Varfetch(_extra[i],/REF_EXTRA)) = (*self._struct).values[index]
  ENDFOR

END

;;-------------------------------------------------------------------------
;; IDLitParamProp
;;
;; PURPOSE:
;;   Definition
;;
PRO IDLitParamProp__define
  compile_opt idl2, hidden

  void = {IDLitParamProp, $
          inherits IDLitComponent, $
          _vistype: 0, $
          _struct: ptr_new() }

END


;;;;;;;;;;;;;;; cw_itParameterPropertysheet;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; PURPOSE:
;;   This is the widget portion of the code
;;

;;-----------------------------------------------------------------------------
;; cw_itParameterPropertysheet_GetVisDesc
;;
;; Purpose:
;;    Returns the ID of the vis type selected in the droplist
;;
;; Parameters:
;;   id             - The id of this widget
;;
FUNCTION cw_itParameterPropertysheet_GetVisDesc, id
  compile_opt hidden, idl2

  WIDGET_CONTROL, widget_info(id, /child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return, ''

  ;; Get the value of the property
  (*pState)._oParamProp->GetProperty,VIS_TYPE=value
  ;; get ID of current vis descriptor
  visID = (*(*pState).visID)[value]

  return, visID

END

;;-----------------------------------------------------------------------------
;; cw_itParameterPropertysheet_GetParameters
;;
;; Purpose:
;;    Returns the names and associated data ids from the table
;;
;; Parameters:
;;   ID             - The id of this widget
;;
;;   PARMNAMES[out] - The names of the parameters
;;
;;   PARMIDS[out]   - The identifiers of data associated with the
;;                    parameters.
;;
;; Keywords:
;;   COUNT  - Set to the number of items in parmNames and parmIDs
;;
PRO cw_itParameterPropertysheet_GetParameters, id, parmNames, parmIDs, $
                                               COUNT=COUNT
  compile_opt hidden, idl2

  WIDGET_CONTROL, widget_info(id, /child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return

  parmNames = *(*pState).paramName
  parmIDs = *(*pState).paramDataID
  void = where(parmNames NE '',count)

END

;;-----------------------------------------------------------------------------
;; cw_itParameterPropertysheet_IsRequiredFullfilled
;;
;; Purpose:
;;   This function will return true if all required parameters have a
;;   value associated with them.
;;
;; Return Value:
;;   1 - Yes
;;   0 - No
;;
FUNCTION cw_itParameterPropertysheet_IsRequiredFullfilled, wID
  compile_opt hidden, idl2

  WIDGET_CONTROL, widget_info(wID, /child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return, 0

  ;; return 0 if nothing valid is currently in the propertysheet
  IF ~ptr_valid((*pState).required) THEN $
    return,0

  req = where(*(*pState).required)
  IF (req[0] EQ -1) THEN BEGIN
    ;; if nothing is required ensure that something has data
    wh = (where(*(*pState).paramData NE ''))[0]
    wh NE= -1
  ENDIF ELSE BEGIN
    wh = (where((*(*pState).paramData)[req] EQ ''))[0]
    wh EQ= -1
  ENDELSE
  return, wh

END

;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet_LockList
;;
;; Purpose:
;;    Notifies that the user wants to use this list choice
;;
;; Parameters:
;;    ID - the widget ID
;;
;;    RESET - if set, resets the value of the lock to zero
;;
PRO cw_itParameterPropertysheet_LockList, ID, RESET=reset, LOCKED=locked
  compile_opt idl2, hidden

  widget_control, widget_info(id,/child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return

  IF arg_present(locked) THEN BEGIN
    locked = (*pState).lockList
    return
  ENDIF

  (*pState).lockList = ~keyword_set(reset)

END

;;---------------------------------------------------------------------------
;; _cw_itParameterPropertySheet_GetVisualizations
;;
;; Purpose:
;;   Gets the needed values for displaying the vis list.  A
;;   visualization must have parameters that are marked as INPUT and
;;   OPTARGET in order to make the list.
;;
;; Parameters:
;;   OUI - Our UI object
;;
;;   STRNAMES [out] - the names of the vis returned.
;;
;;   IDVIS [out] - IDs of the vis descriptors
;;
;;   TYPEVIS [out] - itools types of the vis
;;
;; Keywords:
;;   COUNT - Returns the number of items returned.
;;
PRO _cw_itParameterPropertySheet_GetVisualizations, strNames, idVis, $
  typeVis, classVis, COUNT=count
  compile_opt hidden, idl2

  void = iGetCurrent(tool=oTool)
  oVisDesc = oTool->GetVisualization(count=nVis,/all)
  count=0

  FOR i=0,nVis-1 DO BEGIN

    ;; Use internal _InstantiateObject so we skip the PropertyBag.
    oObj = oVisDesc[i]->_InstantiateObject()

    ;; Check if vis has any parms at all
    IF ~OBJ_ISA(oObj, 'IDLitParameter') THEN BEGIN
      OBJ_DESTROY, oObj
      CONTINUE
    ENDIF

    ;; Get all parm descriptors
    parameters = oObj->QueryParameter(COUNT=nparam)
    if (nparam eq 0) then begin
        OBJ_DESTROY, oObj
        continue
    endif

    ;; Look for INPUT and OPTARGET
    for d=0, nparam-1 do begin
        oObj->GetParameterAttribute, parameters[d], $
            INPUT=input, OPTARGET=optarget
        if (input && optarget) then break
    endfor
    oObj->GetProperty,TYPE=type
    class = obj_class(oObj)
    OBJ_DESTROY, oObj

    ;; Didn't find it
    if d eq nparam then continue

    ;; get name
    oVisDesc[i]->GetProperty,NAME=name

    ;; Got one - add name and id to return list
    IF (count EQ 0) THEN BEGIN
      strNames = name
      idVis = oVisDesc[i]->GetFullIdentifier()
      typeVis = type
      classVis = class
    ENDIF ELSE BEGIN
      strNames = [strNames,name]
      idVis = [idVis,oVisDesc[i]->GetFullIdentifier()]
      typeVis = [typeVis,type]
      classVis = [classVis,class]
    ENDELSE

    count++

  ENDFOR

END

;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet_GetDataName
;;
;; Purpose:
;;    Creates a long path style name for the data item
;;
;; Parameters:
;;    oData - an IDLitData object in the data manager
;;
FUNCTION cw_itParameterPropertysheet_GetDataName, oData
  compile_opt idl2, hidden

  IF ~obj_valid(oData) THEN $
    return,''

  oData->GetProperty,NAME=dataName,_PARENT=oParent
  IF ~dataName THEN $
    dataName = obj_class(oData)
  ;; crawl up the ladder and prepend the name of each parent
  WHILE obj_valid(oParent) DO BEGIN
    oParent->GetProperty,NAME=parName
    IF (parName NE 'Data Manager') THEN BEGIN
      dataName = parName + '/' + dataName
      oParent->GetProperty,_PARENT=oParent
    ENDIF ELSE BEGIN
      oParent = obj_new()
    ENDELSE
  ENDWHILE
  obj_destroy,oParent

  return, dataName

END

;;---------------------------------------------------------------------------
;; cw_itParameterPropertysheet_UpdateSensitivity
;;
;; PURPOSE:
;;   Updates the sensitivity of the parameter property sheet and/or
;;   the add and remove buttons
;;
;; PARAMETERS:
;;   PSTATE - The state structure pointer
;;
;; KEYWORDS:
;;   WID - the widget id
;;
;;   PARAMS_EXIST - If set ensure that all data in the propertysheet
;;                  still exists
;;
;;   ADD - If set update the Add button
;;
;;   REMOVE - If set update the Remove button
;;
;;   PARAMETERS - If set update the sensitivity of each parameter in
;;                the propertysheet
;;
;;   PARAM_DATA - If set make sure all the displayed names of the
;;                data items are up to date.
;;
PRO cw_itParameterPropertysheet_UpdateSensitivity, pState, $
                                                   WID=wID, $
                                                   PARAMS_EXIST=pExist, $
                                                   ADD=add, $
                                                   REMOVE=remove, $
                                                   PARAMETERS=params, $
                                                   PARAM_DATA=pData
  compile_opt hidden, idl2

  IF keyword_set(wID) THEN $
    widget_control, widget_info(wID,/child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return

  ;; get name of current selected property
  propID = widget_info((*pState).wProp,/propertysheet_selected)

  ;; if the data object no longer exists then remove it from our lists
  IF keyword_set(pExist) && ptr_valid((*pState).paramDataID) THEN BEGIN

    oSystem = _IDLitSys_GetSystem()
    FOR i=0,n_elements(*(*pState).paramDataID)-1 DO BEGIN
      oData = oSystem->GetByIdentifier((*(*pState).paramDataID)[i])
      IF ~obj_valid(oData) THEN BEGIN
        (*pState)._oParamProp->SetPropertyByIdentifier, $
          (*(*pState).paramID)[i],''
        (*(*pState).paramData)[i] = ''
        (*(*pState).paramDataID)[i] = ''
      ENDIF
    ENDFOR

  ENDIF

  ;; Add button
  IF keyword_set(add) THEN BEGIN

    sens = 0
    CASE propID OF
      '' : BEGIN
        ;; no parameter selected, nothing can be added
      END

      'VIS_TYPE' : BEGIN
        ;; if any of the data types of the selected item or items in
        ;; the selected data container match any of the data types
        ;; supported by any of the parameters of the vis, then the ADD
        ;; button is sensitized.

        ;; dataTypes is either the type of the data item or the types
        ;; of the data items in the container.
        dataTypes = (*pState).dataPset ? *(*pState).dataPsetTypes : $
                    (*pState).dataType
        FOR i=0,n_elements(dataTypes)-1 DO BEGIN
          wh = where(dataTypes[i] EQ *(*pState).visParamListShort)
          IF (wh[0] NE -1) THEN BEGIN
            sens = 1
            BREAK
          ENDIF
        ENDFOR
      END

      ELSE : BEGIN
        ;; this is a single parameter.  Sensitize button if any match
        ;; occurs between the data types the parameter accepts and the
        ;; types of the data or the data contained in the container.
        index = (where(propID EQ *(*pState).paramID))[0]
        IF (index NE -1) THEN BEGIN
          ;; dataTypes is either the type of the data item or the
          ;; types of the data items in the container.
          dataTypes = (*pState).dataPset ? *(*pState).dataPsetTypes : $
                      (*pState).dataType
          FOR i=0,n_elements(dataTypes)-1 DO BEGIN
            wh = where(dataTypes[i] EQ *((*(*pState).paramTypes)[index]))
            IF (wh[0] NE -1) THEN BEGIN
              sens = 1
              BREAK
            ENDIF
          ENDFOR
        ENDIF
      END

    ENDCASE

    widget_control,(*pState).wAdd,sensitive=sens
    widget_control,(*pState).wConAdd,sensitive=sens
  ENDIF

  ;; Remove button
  IF keyword_set(remove) THEN BEGIN
    value = ''
    propID = widget_info((*pState).wProp,/propertysheet_selected)
    ;; if anything is currently in the propertysheet then it can be
    ;; removed
    IF ((propID NE '') && (propID NE 'VIS_TYPE')) THEN $
      value = widget_info((*pState).wProp,property_value=propID)
    widget_control,(*pState).wRemove,sensitive=(value NE '')
    widget_control,(*pState).wConRemove,sensitive=(value NE '')
  ENDIF

  ;; RemoveAll context menu
  IF (keyword_set(add) || keyword_set(remove)) THEN BEGIN
    ;; if anything has a data item associated with it then it can be
    ;; removed
    hasData = PTR_VALID((*pState).paramData) && $
        (MAX(*(*pState).paramData NE '') eq 1)
    widget_control,(*pState).wConRemoveAll,sensitive=hasData
  ENDIF

  ;; sensitivity of each parameter
  IF keyword_set(params) && ptr_valid((*pState).paramID) THEN BEGIN

    CASE propID OF
      'VIS_TYPE' : BEGIN
        ;; dataTypes is either the type of the data item or the
        ;; types of the data items in the container.
        dataTypes = (*pState).dataPset ? *(*pState).dataPsetTypes : $
                    (*pState).dataType
        FOR i=0,n_elements(*(*pState).paramID)-1 DO BEGIN
          sens = 0
          FOR j=0,n_elements(dataTypes)-1 DO BEGIN
            ;; find where a parameter has accepts data of the type
            ;; found in the parameterset
            wh = where(*(*(*pState).paramTypes)[i] EQ dataTypes[j])
            IF (wh[0] NE -1) THEN BEGIN
              ;; mark data item as taken so that only the proper
              ;; number of items can be sensitized.
              dataTypes[j] = '__TAKEN'
              sens = 1
              BREAK
            ENDIF
          ENDFOR

          ;; set sensitivity of the parameter
          (*pState)._oParamProp->SetPropertyAttribute, $
            (*(*pState).paramID)[i],sensitive=sens
        ENDFOR
      END

      ELSE : BEGIN
        ;; case if a single parameter is selected
        IF (*pState).dataPset THEN BEGIN
          dataTypes = *(*pState).dataPsetTypes
          FOR i=0,n_elements(*(*pState).paramID)-1 DO BEGIN
            ;; assume no match
            sens = 0
            FOR j=0,n_elements(dataTypes)-1 DO BEGIN
              wh = where(*(*(*pState).paramTypes)[i] EQ dataTypes[j])
              IF (wh[0] NE -1) THEN BEGIN
                ;; if anything matches, mark as sensitive
                sens = 1
                BREAK
              ENDIF
            ENDFOR
            ;; update the propertysheet
            (*pState)._oParamProp->SetPropertyAttribute, $
              (*(*pState).paramID)[i],sensitive=sens
          ENDFOR
        ENDIF ELSE BEGIN
          ;; loop through each parameter and set sensitivity based on
          ;; data type match
          FOR i=0,n_elements(*(*pState).paramID)-1 DO BEGIN
            sens=where((*pState).dataType EQ *(*(*pState).paramTypes)[i]) NE -1
            (*pState)._oParamProp->SetPropertyAttribute, $
              (*(*pState).paramID)[i],sensitive=sens
          ENDFOR
        ENDELSE
      END

    ENDCASE

  ENDIF

  ;; data names of the parameteres
  IF keyword_set(pData) && ptr_valid((*pState).paramID) THEN BEGIN
    oSys = _IDLitSys_GetSystem()
    FOR i=0,n_elements(*(*pState).paramID)-1 DO BEGIN
      ;; if we have any data, update its name
      IF ((*(*pState).paramDataID)[i] NE '') THEN BEGIN
        ;; get data object
        oData = oSys->GetByIdentifier((*(*pState).paramDataID)[i])
        dataName = ''
        IF obj_valid(oData) THEN BEGIN
          dataName = cw_itParameterPropertysheet_GetDataName(oData)
          ;; update propertysheet and data item information
          (*pState)._oParamProp->SetPropertyByIdentifier, $
            (*(*pState).paramID)[i],dataName
          (*(*pState).paramData)[i] = dataName
          ;; save data name
          (*pState).dataName = dataName
        ENDIF
      ENDIF
    ENDFOR
  ENDIF

  widget_control,(*pState).wProp, /refresh

END

;;---------------------------------------------------------------------------
;; cw_itParameterPropertysheet_AddData
;;
;; PURPOSE:
;;   Adds the data from the DM to the selected parameter
;;
;; PARAMETERS:
;;   WID - The widget ID
;;
FUNCTION cw_itParameterPropertysheet_AddData, wID
  compile_opt hidden, idl2

  widget_control, widget_info(wID,/child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return, 0

  ;; this only should happen in the button has been sensitized.  This
  ;; is needed to ensure that events that come down via doubleclicks
  ;; in the data manager do not do something that should not happen.
  IF ~widget_info((*pState).wAdd,/sensitive) THEN $
    return,0

  propID = widget_info((*pState).wProp,/propertysheet_selected)

  IF (propID EQ 'VIS_TYPE') THEN BEGIN
    IF (*pState).dataPset THEN BEGIN
      ;; data is a parameter set.  Strip apart and best guess where to
      ;; put things
      oSystem = _IDLitSys_GetSystem()
      oPset = oSystem->GetByIdentifier((*pState).dataID)
      ;; get all the children of the container
      oChildren = oPset->Get(/ALL)
      ;; save a list of parameter positions that have already been
      ;; filled
      filled = [-1]
      FOR i=0,n_elements(oChildren)-1 DO BEGIN
        oChildren[i]->GetProperty,TYPE=dataType
        FOR j=0,n_elements(*(*pState).paramTypes)-1 DO BEGIN
          wh = (where(dataType EQ *(*(*pState).paramTypes)[j]))[0]
          ;; if a data type matches an unfilled parameter break out of
          ;; the loop
          IF (wh NE -1) && ((where(filled EQ j))[0] EQ -1) THEN BREAK
        ENDFOR
        IF (j NE n_elements(*(*pState).paramTypes)) THEN BEGIN
          ;; add the current item to the filled list
          filled = [filled,j]
          dataName = cw_itParameterPropertysheet_GetDataName(oChildren[i])
          ;; update propertysheet and data item information
          (*pState)._oParamProp->SetPropertyByIdentifier, $
            (*(*pState).paramID)[j],dataName
          widget_control,(*pState).wProp, $
                         refresh_property=(*(*pState).paramID)[j]
          (*(*pState).paramData)[j] = dataName
          (*(*pState).paramDataID)[j] = oChildren[i]->GetFullIdentifier()
        ENDIF
      ENDFOR
    ENDIF ELSE BEGIN
      ;; data is just a data item.  Best guess where to put it.
      FOR i=0,n_elements(*(*pState).paramTypes)-1 DO BEGIN
        wh = (where((*pState).dataType EQ *(*(*pState).paramTypes)[i]))[0]
        ;; if a data type matches, break
        IF wh NE -1 THEN BREAK
      ENDFOR
      IF (i NE n_elements(*(*pState).paramTypes)) THEN BEGIN
        ;; update propertysheet and data item information
        (*pState)._oParamProp->SetPropertyByIdentifier, $
          (*(*pState).paramID)[i],(*pState).dataName
        widget_control,(*pState).wProp,refresh_property=(*(*pState).paramID)[i]
        (*(*pState).paramData)[i] = (*pState).dataName
        (*(*pState).paramDataID)[i] = (*pState).dataID
      ENDIF
    ENDELSE

    ;; things may have been added, set the sensitivity of the remove
    ;; button
    cw_itParameterPropertysheet_UpdateSensitivity, pState, /REMOVE
    return,1

  ENDIF

  ;; this block is for when a vis parameter is selected in the
  ;; propertysheet
  IF (propID NE '') && (propID NE 'VIS_TYPE') THEN BEGIN
    IF (*pState).dataPset THEN BEGIN
      ;; if a container is selected in the DM get the first item in
      ;; the container that matches the types of the current parameter
      ;; and fill it in.
      index = (where(propID EQ *(*pState).paramID))[0]
      ;; get the types supported by the parameter
      paramTypes = *(*(*pState).paramTypes)[index]
      ;; get all the types of data in the container
      dataTypes = *(*pState).dataPsetTypes
      FOR i=0,n_elements(dataTypes)-1 DO BEGIN
        wh = (where(dataTypes[i] EQ paramTypes))[0]
        IF (wh NE -1) THEN BEGIN
          (*(*pState).paramData)[index] = (*(*pState).dataPsetNames)[i]
          (*(*pState).paramDataID)[index] = (*(*pState).dataPsetIDs)[i]
          dataName = (*(*pState).dataPsetNames)[i]

          oSystem = _IDLitSys_GetSystem()
          oData = oSystem->GetByIdentifier((*(*pState).paramDataID)[index])
          dataName = cw_itParameterPropertysheet_GetDataName(oData)
          ;; update propertysheet
          (*pState)._oParamProp->SetPropertyByIdentifier,propID,dataName
          widget_control,(*pState).wProp,refresh_property=propID
          BREAK
        ENDIF
      ENDFOR
    ENDIF ELSE BEGIN
      ;; if a single data item and a single parameter are selected
      ;; then just add the data item to the parameter
      (*pState)._oParamProp->SetPropertyByIdentifier,propID, $
        (*pState).dataName
      widget_control,(*pState).wProp,refresh_property=propID
      wh = where(propID EQ *(*pState).paramID)
      IF (wh[0] NE -1) THEN BEGIN
        (*(*pState).paramData)[wh[0]] = (*pState).dataName
        (*(*pState).paramDataID)[wh[0]] = (*pState).dataID
      ENDIF
    ENDELSE

    ;; things may have been added, set the sensitivity of the remove
    ;; button
    cw_itParameterPropertysheet_UpdateSensitivity, pState, /REMOVE
    return, 1
  ENDIF

  ;; nothing was selected in the propertysheet, thus nothing could be
  ;; added
  return, 0

END

;;---------------------------------------------------------------------------
;; cw_itParameterPropertysheet_FindVisualizationByDataType
;;
;; Purpose:
;;    Uses the given data object to find a visualization descriptor
;;    that can support/manage the data object. This works off the data
;;    type.
;;
;; Parameters:
;;    oData  [in]  - The data object to try and match.
;;
;;    oVis   [out] - The visualization descriptor if a match happens
;;
;; Return Value:
;;    Success   1
;;    No Match  0
;;    Error     -1

FUNCTION cw_itParameterPropertysheet_FindVisualizationByDataType, oData, oVis
  compile_opt hidden, idl2

  ;; this is internal, so we assume that oData is valid and a scalar!

  void = iGetCurrent(tool=oTool)
  IF ~obj_valid(oTool) THEN return,0

  ;; Get the available list of visualizations
  oVisDesc = oTool->GetVisualization(COUNT=nVis,/ALL)

  IF (nVis EQ 0) THEN BEGIN
    self->SignalError, $
      IDLitLangCatQuery('Error:Framework:NoVizAvailable'), $
      SEVERITY=1
    return, -1 ;; major issues.
  ENDIF

  ;; CASE 1
  ;; Straight match with the default visualization
  ;;
  ;; The first visualization is the "default' for the tool. Get the
  ;; visualizations data type
  oVoid = oData->GetByType(oVisDesc[0]->GetDataTypes(), count=nMatch)
  IF (nMatch GT 0) THEN BEGIN
    oVis = oVisDesc[0]
    return, 1
  ENDIF

  ;; Case 2
  ;; Check to see if any visualization matches the data. This search
  ;; looks at the primary data type.
  oData->GetProperty, TYPE=dType
  FOR i=1,nVis-1 DO BEGIN ;; skip the first vis.
    visTypes = oVisDesc[i]->GetDataTypes()
    dex = where(visTypes EQ dType, nMatch)
    IF (nMatch GT 0) THEN BEGIN ;; we have a match !!!
      oVis = oVisDesc[i]
      return, 1
    ENDIF
  ENDFOR

  ;; Case 3
  ;; Check to see if any visualization matches any of the data. This search
  ;; looks at all data in the data object.
  FOR i=1,nVis-1 DO BEGIN ;; skip the first vis.
    oVoid = oData->GetByType(oVisDesc[i]->GetDataTypes(), count=nMatch)
    IF (nMatch GT 0) THEN BEGIN
      oVis = oVisDesc[i]
      return, 1
    ENDIF
  ENDFOR

  ;; At this point, no data-vis match. Return the no match flag
  return, 0

END

;;---------------------------------------------------------------------------
;; cw_itParameterPropertysheet_SetDataSelect
;;
;; PURPOSE:
;;   Sets the selected data item.  Called when an item is selected in
;;   the datamanager
;;
;; PARAMETERS:
;;   WID - The widget ID
;;
;;   ODATA - The data object
;;
PRO cw_itParameterPropertysheet_SetDataSelect, wID, oData
  compile_opt hidden, idl2

  IF ~widget_info(wID,/valid_id) THEN return

  widget_control, widget_info(wID,/child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return

  ;; if an identifier was passed in, get the data object
  IF (size(oData,/type) EQ 7) THEN BEGIN
    oSys = _IDLitSys_GetSystem()
    oData = oSys->GetByIdentifier(oData)
  ENDIF

  IF (obj_valid(oData) && obj_isa(oData, 'IDLitData')) THEN BEGIN
    ;; retrieve and save data name, type, and ID
    paramName = cw_itParameterPropertysheet_GetDataName(oData)
    oData->GetProperty,TYPE=paramType

    (*pState).dataType = paramType
    (*pState).dataName = paramName
    (*pState).dataID = oData->GetFullIdentifier()
    (*pState).dataPset = (obj_isa(oData,'IDLitParameterSet') || $
                          obj_isa(oData,'IDLitDataIDLImage'))
    ;; if the item is a container then get a list of all the types of
    ;; objects contained therin.
    IF (*pState).dataPset THEN BEGIN
      oChildren = oData->Get(/ALL,count=count)
      FOR i=0,count-1 DO BEGIN
        oChildren[i]->GetProperty,TYPE=dataType,NAME=dataName
        IF ~i THEN BEGIN
          (*pState).dataPsetTypes = ptr_new(dataType)
          (*pState).dataPsetNames = ptr_new(dataName)
          (*pState).dataPsetIDs = ptr_new(oChildren[i]->GetFullIdentifier())
        ENDIF ELSE BEGIN
          *(*pState).dataPsetTypes = [*(*pState).dataPsetTypes,dataType]
          *(*pState).dataPsetNames = [*(*pState).dataPsetNames,dataName]
          *(*pState).dataPsetIDs = [*(*pState).dataPsetIDs, $
                                    oChildren[i]->GetFullIdentifier()]
        ENDELSE
      ENDFOR
    ENDIF ELSE BEGIN
      ptr_free,[(*pState).dataPsetTypes,(*pState).dataPsetNames, $
                (*pState).dataPsetIDs]
    ENDELSE

    ;; if currently in insert vis mode and the user has not decided
    ;; which vis to insert, update the possible insert vis object
    ;; based on the data type selected in the data manager
    IF (*pState).isInsVis && ~(*pState).lockList THEN BEGIN
      found=cw_itParameterPropertysheet_FindVisualizationByDataType(oData,oVis)
      IF found THEN BEGIN
        oVisInstance = oVis->_InstantiateObject()
        cw_itParameterPropertysheet_SetValue,wID,oVisInstance
        obj_destroy,oVisInstance
      ENDIF
    ENDIF
  ENDIF ELSE BEGIN
    ;; item in DM is not an IDLitData item
    (*pState).dataType = ''
    (*pState).dataName = ''
    (*pState).dataID = ''
    (*pState).dataPset = 0b
    ptr_free,[(*pState).dataPsetTypes,(*pState).dataPsetNames, $
              (*pState).dataPsetIDs]
  ENDELSE

  cw_itParameterPropertysheet_UpdateSensitivity, pState, /ADD, /PARAMETERS

END

;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet_SetValue
;;
;; PURPOSE:
;;   Sets the object for which to display the parameters
;;
;; PARAMETERS:
;;   WID - widget ID
;;
;;   VALUE - the value of the IDLitParameter object for which to
;;           display the parameters.  This can either be the full
;;           identifier of the object or an object reference
;;
PRO cw_itParameterPropertysheet_SetValue, wID, value, $
                                          PARAMETER_EDITOR=parametereditor, $
                                          INSERT_VISUALIZATION=insVis
  compile_opt idl2, hidden

  widget_control, widget_info(wID,/child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return

  IF keyword_set(parametereditor) THEN BEGIN
    (*pState).isInsVis = 0b
  ENDIF
  IF keyword_set(insVis) THEN BEGIN
    (*pState).isInsVis = 1b
    (*pState).lockList = 0b
  ENDIF

  ;; if we are in insert vis mode and the list is locked, just return
  IF (*pState).isInsVis && (*pState).lockList THEN return

  ;; get oValue
  IF (size(value,/type) EQ 7) && obj_valid((*pState).oUI) THEN BEGIN
    oValue = (*pState).oUI->GetByIdentifier(value)
  ENDIF ELSE BEGIN
    oValue = value
  ENDELSE

  ;; if the incoming value is the same as the one currently displayed,
  ;; just return
  IF ptr_valid((*pState).visID) && obj_valid(oValue) && $
    ((*(*pState).visID)[0] EQ oValue->GetFullIdentifier()) THEN return

  ;; clean up previous values
  IF ptr_valid((*pState).paramTypes) && $
    ptr_valid((*(*pState).paramTypes)[0]) THEN $
      ptr_free,*(*pState).paramTypes
  ptr_free, [(*pState).required,(*pState).paramName,(*pState).paramID, $
             (*pState).paramTypes,(*pState).paramData,(*pState).paramDataID, $
             (*pState).visParamList,(*pState).visParamListShort]
  IF obj_valid((*pState)._oParamProp) THEN $
    obj_destroy,(*pState)._oParamProp

  ;; save name in case value does not have any input parameters
  IF obj_valid(oValue) THEN $
    oValue->GetProperty,NAME=valueName

  IF (*pState).isInsVis THEN BEGIN
    ;; create list of visualizations, if it does not already exist
    IF ~ptr_valid((*pState).visID) || $
      (n_elements(*(*pState).visID) EQ 1) THEN $
      (*pState).visID = ptr_new((*pState).visIDlist)
    vis_type = *(*pState).visID
    ;; set insert vis type to match current object, or first choice in
    ;; the vis list
    IF obj_valid(oValue) && obj_isa(oValue,'IDLitParameter') THEN BEGIN
      oValue->GetProperty,NAME=name
      visType = (where(name EQ vis_type))[0] > 0
    ENDIF ELSE BEGIN
      visType = 0
    ENDELSE
    ;; get tool
    void = iGetCurrent(tool=oTool)
    IF ~obj_valid(oTool) THEN BEGIN
      oTool = (*pState).oUI->GetTool()
      IF ~obj_valid(oTool) THEN $
        oTool=_IDLitSys_GetSystem()
    ENDIF
    ;; get an instance of the object
    oItem = oTool->GetVisualization((*(*pState).visID)[visType])
    IF obj_valid(oItem) THEN $
      oValue = oItem->_InstantiateObject()
  ENDIF

  ;; create paramprop object
  IF obj_valid(oValue) && obj_isa(oValue,'IDLitParameter') THEN BEGIN

    IF ~(*pState).isInsVis THEN BEGIN
      IF ptr_valid((*pState).visID) then $
          *((*pState).visID) = oValue->GetFullIdentifier() $
      ELSE $
          (*pState).visID = ptr_new(oValue->GetFullIdentifier())
      oValue->GetProperty,NAME=vis_type
    ENDIF

    ;; First step, get the parameters for this item
    parameters = oValue->QueryParameter(COUNT=nparam)
    if (nparam gt 0) then begin
      inDesc = bytarr(nparam)
      for i=0,nparam-1 do begin
        oValue->GetParameterAttribute, parameters[i], INPUT=input
        inDesc[i]=input
      endfor
      dex  = where(inDesc, nparam)
      IF (nparam GT 0) THEN $
        parameters = parameters[dex]
    endif

    ;; get parameter set from value
    oPSet = oValue->GetParameterSet()

    ;; if the object in question is not in the insert vis list then do
    ;; not display anything.  Fake a bad value by resetting nparam to
    ;; zero
    IF max(obj_class(oValue) EQ (*pState).visClasslist) NE 1 THEN $
      nparam=0

    ;; Okay, now to loop through and set the parameter names, types, etc
    FOR i=0,nparam-1 DO BEGIN
        oValue->GetParameterAttribute, parameters[i], $
            TYPES=parmTypes, $
            NAME=NAME, $
            OPTIONAL=OPTIONAL, $
            IDENTIFIER=ID
      ;; Does the parameter set contain this item?
      parmName = ''
      paramData = ''
      paramDataID = ''
      oItem = oPSet->GetByName(NAME, count=nItems)
      IF (nItems GT 0) THEN BEGIN
        paramData = cw_itParameterPropertysheet_GetDataName(oItem[0])
        paramDataID = oItem[0]->GetFullIdentifier()
      ENDIF

      ;; save information
      IF (i EQ 0) THEN BEGIN
        (*pState).required = ptr_new(~OPTIONAL)
        (*pState).paramName = ptr_new(NAME)
        (*pState).paramID = ptr_new(IDL_ValidName(ID,/convert_all))
        (*pState).paramTypes = ptr_new(ptr_new(parmTypes))
        (*pState).paramData = ptr_new(paramData)
        (*pState).paramDataID = ptr_new(paramDataID)
        (*pState).visParamList = ptr_new(NAME+' : '+strjoin(parmTypes,', '))
      ENDIF ELSE BEGIN
        *(*pState).required = [*(*pState).required, ~OPTIONAL]
        *(*pState).paramName = [*(*pState).paramName,NAME]
        *(*pState).paramID = [*(*pState).paramID, $
                              IDL_ValidName(ID,/convert_all)]
        *(*pState).paramTypes = [*(*pState).paramTypes,ptr_new(parmTypes)]
        *(*pState).paramData = [*(*pState).paramData, paramData]
        *(*pState).paramDataID = [*(*pState).paramDataID, paramDataID]
        *(*pState).visParamList = [*(*pState).visParamList, $
                                   NAME+' : '+strjoin(parmTypes,', ')]
      ENDELSE
    ENDFOR

    ;; create a list of uniq parameter types in the parameter set
    FOR i=0,nparam-1 DO begin
      str = ~i ? *(*(*pState).paramTypes)[i] : $
            [str,*(*(*pState).paramTypes)[i]]
    endfor

    IF (nparam NE 0) THEN BEGIN
      str = str[uniq(str,sort(str))]
      (*pState).visParamListShort = ptr_new(str,/no_copy)
    ENDIF

    IF (nparam GT 0) THEN BEGIN
      ;; set the vis_type to match the type of value
      vnum = 0
      IF obj_valid(oValue) && (*pState).isInsVis THEN BEGIN
        oValue->GetProperty,NAME=vistype
        vnum = where(vis_type EQ vistype)
        obj_destroy,oValue
      ENDIF

      ;; create structure to be passed to ParamProp object Init
      struct = {vistype:vis_type, vistypenum:vnum, $
                var_names:*(*pState).paramID, $
                names:*(*pState).paramName, values:*(*pState).paramData, $
                required:*(*pState).required}
      (*pState)._oParamProp = obj_new('IDLitParamProp',struct)
    ENDIF ELSE BEGIN
      ;; blank object
      (*pState)._oParamProp = obj_new('IDLitParamProp',valueName)
    ENDELSE

  ENDIF ELSE BEGIN
    ;; blank object
    (*pState)._oParamProp = obj_new('IDLitParamProp','')
    *(*pState).visID = ''
  ENDELSE

  ;; turn off updates
  widget_control,(*pState).wWrapper,update=0

  ;; set the value of the propertysheet
  widget_control,(*pState).wProp,set_value=(*pState)._oParamProp

  IF (*pState).isInsVis THEN BEGIN
    widget_control,(*pState).wProp,propertysheet_setselected='VIS_TYPE'
    IF n_elements(vis_type) NE 0 THEN BEGIN
      ;; set value of supported data types list
      widget_control,(*pState).wList,set_value=*(*pState).visParamList
      widget_control,(*pState).wListLabel, $
                     set_value='Parameters:types of the '+vis_type[vnum[0]]+ $
                     ' visualization'
    ENDIF
  ENDIF ELSE BEGIN
    ;; reset supported data types list
    widget_control,(*pState).wList,set_value=''
    widget_control,(*pState).wListLabel,set_value=(*pState).noParamText
  ENDELSE

  ;; update sensitivities
  cw_itParameterPropertysheet_UpdateSensitivity, pState, /ADD, $
                                                 /PARAMETERS, /REMOVE

  ;; turn updates back on
  widget_control,(*pState).wWrapper,update=1

END


;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet_Resize
;;
;; Purpose:
;;    Resizes the list and propertysheet.  Only resize in X, not Y.
;;    This widget is part of the datamanager and the DM part will take
;;    all the Y resizing.
;;
;; Parameters:
;;    WID - Widget ID
;;
;;    NEWXLEFT - New X size for the propertysheet
;;
;;    NEWXRIGHT - New X size for the list widget
;;
PRO cw_itParameterPropertysheet_Resize, wID, newXleft, newXright
  compile_opt idl2, hidden

  ;; Get the state
  Widget_Control, Widget_Info(wID, /CHILD), GET_UVALUE=pState

  ;; Update widgets with new sizes
  Widget_Control, (*pState).wProp, SCR_XSIZE=newXleft
  Widget_Control, (*pState).wList, SCR_XSIZE=newXright

end 


;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet_Event
;;
;; Purpose:
;;    The widget event handler for this widget. Pretty standard
;;
;; Parameters:
;;    sEvent   - The event that has been triggered
;;
FUNCTION cw_itParameterPropertysheet_Event, sEvent

  compile_opt idl2, hidden

  ;; Get our state
  widget_control, widget_info(sEvent.handler, /child), get_uvalue=pState
  if (~Ptr_Valid(pState)) then return, 0

  ;; if a context menu event has been passed up just pass it on.
  IF (TAG_NAMES(sEvent,/STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN
    IF ((*pState).wContext GT 0) THEN $
      WIDGET_DISPLAYCONTEXTMENU,sEvent.id,sEvent.x,sEvent.y, $
                                (*pState).wContext
    return, sEvent
  ENDIF

  CASE widget_info(sEvent.id, /uname) OF
    'PROP_SHEET' : BEGIN
      widget_control,(*pState).wWrapper,update=0

      IF (sEvent.identifier EQ 'VIS_TYPE') && (sEvent.type EQ 0) THEN BEGIN
        ;; Get the value of the property
        value = WIDGET_INFO(sEvent.id, COMPONENT = sEvent.component, $
                            PROPERTY_VALUE = sEvent.identifier)

        ;; get ID of current vis descriptor
        visID = (*(*pState).visID)[value > 0]
        ;; get tool
        void = iGetCurrent(tool=oTool)
        IF ~obj_valid(oTool) THEN BEGIN
          oTool = (*pState).oUI->GetTool()
          IF ~obj_valid(oTool) THEN $
            oTool=_IDLitSys_GetSystem()
        ENDIF
        ;; get an instance of the object
        oItem = oTool->GetVisualization(visID)
        oObj = oItem->_InstantiateObject()
        ;; unlock changes from the list
        (*pState).lockList = 0b
        ;; update parameter table
        cw_itParameterPropertysheet_SetValue,(*pState).wWrapper,oObj
        ;; destroy object no longer needed
        obj_destroy, oObj
        ;; do not allow DM to change insVis droplist
        (*pState).lockList = 1b

        ;; set value of supported data types list
        types = *(*pState).visParamList
        widget_control,(*pState).wList,set_value=types
        IF obj_valid(sEvent.component) THEN BEGIN
          ;; Get the value of the property
          value = WIDGET_INFO(sEvent.id, COMPONENT = sEvent.component, $
                              PROPERTY_VALUE = sEvent.identifier)
          ;; get ID of current vis descriptor
          visID = (*(*pState).visID)[value > 0]
        ENDIF
        widget_control,(*pState).wListLabel, $
                       set_value='Parameters:types of the '+visID+ $
                       ' visualization'

      ENDIF ELSE BEGIN
        ;; undo any change users made
        IF (sEvent.type EQ 0) THEN BEGIN
          sEvent.component-> $
            SetPropertyByIdentifier, sEvent.identifier, $
            (*(*pState).paramData)[where(sEvent.identifier EQ $
                                         *(*pState).paramID)]
        widget_control,(*pState).wProp,refresh_property=sEvent.identifier
        ENDIF
      ENDELSE

      IF (sEvent.type EQ 1) THEN BEGIN
        ;; remove any multiple selections
        IF (sEvent.nselected GT 1) THEN $
          widget_control,(*pState).wProp,propertysheet_setselected= $
                         (widget_info((*pState).wProp,/propertysheet_selected))[0]

        ;; if an item is selected in the propertysheet update
        ;; add/remove buttons
        cw_itParameterPropertysheet_UpdateSensitivity, pState, /ADD, $
                                                       /REMOVE, /PARAMETERS
        propID = widget_info((*pState).wProp,/propertysheet_selected)
        wh = (where(propID EQ *(*pState).paramID))[0]
        ;; change label above supported data types list
        IF (wh NE -1) THEN BEGIN
          types = *((*(*pState).paramTypes)[wh])
          widget_control,(*pState).wListLabel, $
                         set_value=(*pState).supDataText+ $
                         ((*(*pState).paramName)[wh])
        ENDIF ELSE BEGIN
          IF (propID EQ 'VIS_TYPE') THEN BEGIN
            types = *(*pState).visParamList
            IF obj_valid(sEvent.component) THEN BEGIN
              ;; Get the value of the property
              value = WIDGET_INFO(sEvent.id, COMPONENT = sEvent.component, $
                                  PROPERTY_VALUE = sEvent.identifier)
              ;; get ID of current vis descriptor
              visID = (*(*pState).visID)[value > 0]
            ENDIF
            widget_control,(*pState).wListLabel, $
                           set_value='Parameters:types of the '+visID+ $
                           ' visualization'
          ENDIF ELSE BEGIN
            types = ''
            widget_control,(*pState).wListLabel,set_value=(*pState).noParamText
          ENDELSE
        ENDELSE
        ;; set value of supported data types list
        widget_control,(*pState).wList,set_value=types
        ;; lock out insVis list changes
        (*pState).lockList = 1b
      ENDIF
      widget_control,(*pState).wWrapper,update=1
    END

    'ADD' : BEGIN
      void = cw_itParameterPropertysheet_AddData((*pState).wWrapper)
      ;; set lock so that insert vis type no longer auto-updates
      (*pState).lockList = 1b
    END

    'REMOVE' : BEGIN
      ;; get ID of current selected item
      propID = widget_info((*pState).wProp,/propertysheet_selected)
      IF (propID NE '') THEN BEGIN
        (*pState)._oParamProp->SetPropertyByIdentifier,propID,''
        widget_control,(*pState).wProp,refresh_property=propID
        wh = where(propID EQ *(*pState).paramID)
        IF (wh[0] NE -1) THEN BEGIN
          (*(*pState).paramData)[wh[0]] = ''
          (*(*pState).paramDataID)[wh[0]] = ''
        ENDIF
      ENDIF
      cw_itParameterPropertysheet_UpdateSensitivity, pState, /REMOVE
    END

    'REMOVE_ALL' : BEGIN
      FOR i=0,n_elements(*(*pState).paramID)-1 DO BEGIN
        (*pState)._oParamProp->SetPropertyByIdentifier,(*(*pState).paramID)[i],''
        widget_control,(*pState).wProp,refresh_property=(*(*pState).paramID)[i]
        (*(*pState).paramData)[i] = ''
        (*(*pState).paramDataID)[i] = ''
      ENDFOR
      cw_itParameterPropertysheet_UpdateSensitivity, pState, /REMOVE
    END

    ELSE :
  ENDCASE

  return, sEvent

END

;;---------------------------------------------------------------------------
;; cw_itParameterPropertysheet_cleanup
;;
;; Purpose:
;;   The kill notify routine for this widget. Cleanup resources.
;;
;; Parameters:
;;   The ID of the widget.
;;
PRO cw_itParameterPropertysheet_Cleanup, wID
  compile_opt hidden, idl2

  ;; This is set on the child that contains the state, so just get
  ;; the value
  widget_control, wID, get_uvalue=pState, /no_copy
  if (~Ptr_Valid(pState)) then return

  IF ptr_valid((*pState).paramTypes) && $
    ptr_valid((*(*pState).paramTypes)[0]) THEN $
      ptr_free,*(*pState).paramTypes
  ptr_free, [(*pState).required,(*pState).paramName,(*pState).paramID, $
             (*pState).paramTypes,(*pState).paramData,(*pState).paramDataID, $
             (*pState).visID,(*pState).visParamList, $
             (*pState).visParamListShort,(*pState).dataPsetTypes, $
             (*pState).dataPsetNames,(*pState).dataPsetIDs]
  obj_destroy,(*pState)._oParamProp
  ptr_free, pState

END

;;-------------------------------------------------------------------------
;; cw_itParameterPropertysheet
;;
;; PURPOSE:
;;   Widget creation routine
;;
;; PARAMETERS:
;;   PARENT - widget ID
;;
;;   OUI - UI object reference
;;
;; KEYWORDS:
;;   VALUE - the value of the IDLitParameter object for which to
;;           display the parameters.  This can either be the full
;;           identifier of the object or an object reference
;;
;;   INSERT_VISUALIZATION - if set, put the widget in insert vis mode,
;;                          otherwise put in parameter editor mode
;;   L_XSIZE - the size, in pixels, of the left side of the widget
;;
;;   R_XSIZE - the size, in pixels, of the right side of the widget
;;
;;   Y_SIZE - the size, in rows, of the propertysheet
;;
FUNCTION cw_itParameterPropertysheet, Parent, oUI, $
                                      VALUE=value, $
                                      INSERT_VISUALIZATION=insVis, $
                                      L_XSIZE=lxsize, R_XSIZE=rxsize, $
                                      YSIZE=ysize, $
                                      UNAME=uname, UVALUE=uvalue
  compile_opt idl2, hidden

nparams = 1  ; must be defined for cw_iterror
@cw_iterror


  ;; Build the CW base
  wWrapper = widget_base(Parent, $
    EVENT_FUNC= 'cw_itParameterPropertysheet_event', $
                         uname=uname, uvalue=uvalue, /col)

  ;; widget madness to get two buttons to center in the proper place
  wBase = widget_base(wWrapper)
  wRowBase = widget_base(wBase,column=3,/grid,/align_center,scr_xsize=lxsize)
  wVoid = widget_base(wRowBase)
  wButtonBase = widget_base(wRowBase,/row,space=10,/align_center)
  wVoid = widget_base(wRowBase)
  wAdd = widget_button(wButtonBase, $
                       /bitmap, $
                       value=filepath('switch_down.bmp', $
                                      subdir=['resource','bitmaps']), $
                       sensitive=0, $
                       tooltip='Insert data into parameter below', $
                       uname='ADD')
  wRemove = widget_button(wButtonBase, /bitmap, $
                          sensitive=0, $
                          tooltip='Remove data item from parameter', $
                          value=filepath('delete.bmp', $
                                         subdir=['resource','bitmaps']), $
                          uname='REMOVE')

  wPropListBase = widget_base(wWrapper,/row)

  wLeft = widget_base(wPropListBase,/column)

  wProp = widget_propertysheet(wLeft,ysize=ysize,/sunken_frame, $
                               /context_events, $
                               scr_xsize=lxsize,uname='PROP_SHEET')

  wVoid = widget_label(wLeft,value='* indicates a required parameter')

;;;;; IDLitLangCatQuery()
  noParamText = 'No parameter selected'
  supDataText = 'Data types accepted by '

  wRight = widget_base(wPropListBase,/column)
  wListLabel = widget_label(wRight,value=noParamText,/dynamic_resize)
  wList = widget_list(wRight,sensitive=0,scr_xsize=rxsize)

  ;; make list the same height as the propertysheet
  geoP = widget_info(wProp,/geometry)
  geoL = widget_info(wListLabel,/geometry)
  widget_control,wList,scr_ysize=geoP.scr_ysize-geoL.scr_ysize

  ;; create context menu
  wContext = widget_base(wProp,/context_menu)
  wConAdd = widget_button(wContext,value='Insert selected data item', $
                          uname='ADD')
  wConRemove = widget_button(wContext,value='Remove selected data item', $
                             uname='REMOVE')
  wConRemoveAll = widget_button(wContext,value='Remove all data items', $
                                uname='REMOVE_ALL')

  ;; get list of accepted visualization types
  _cw_itParameterPropertySheet_GetVisualizations,vis_type, $
    void,void,vis_class

  ;; the widgets state structure.
  state = {wWrapper: wWrapper, $
           wRowBase: wRowBase, $
           wAdd: wAdd, $
           wRemove: wRemove, $
           wProp: wProp, $
           wListLabel: wListLabel, $
           wList: wList, $
           wContext: wContext, $
           wConAdd: wConAdd, $
           wConRemove: wConRemove, $
           wConRemoveAll: wConRemoveAll, $
           oUI: (obj_valid(oUI) ? oUI : obj_new()), $
           _oParamProp: obj_new(), $
           lockList: 0b, $
           required: ptr_new(), $
           paramName: ptr_new(), $
           paramID: ptr_new(), $
           paramTypes: ptr_new(), $
           paramData: ptr_new(), $
           paramDataID: ptr_new(), $
           dataName: '', $
           dataType: '', $
           dataID: '', $
           dataPset: 0b, $
           dataPsetNames: ptr_new(), $
           dataPsetTypes: ptr_new(), $
           dataPsetIDs: ptr_new(), $
           visID: ptr_new(), $
           visIDlist: vis_type, $
           visClassList: vis_class, $
           visParamList: ptr_new(), $
           visParamListShort: ptr_new(), $
           noParamText: noParamText, $
           supDataText: supDataText, $
           isInsVis: keyword_set(insVis) $
          }

  WIDGET_CONTROL, widget_info(wWrapper, /child), $
                  SET_UVALUE=ptr_new(state,/no_copy), $
                  KILL_NOTIFY= 'cw_itParameterPropertysheet_cleanup'

  ;; Do we have an initial value?
  IF (keyword_set(value)) THEN $
    cw_itParameterPropertysheet_SetValue, wWrapper, value

  return, wWrapper

END
