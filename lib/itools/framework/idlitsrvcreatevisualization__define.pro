; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvcreatevisualization__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitsrvCreateVisualization
;
; PURPOSE:
;   This file implements the operation object that is used to create
;   a visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitsrvCreateVisualization::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitsrvCreateVisualization::Init
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvCreateVisualization object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitsrvCreateVisualization::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
;pro IDLitsrvCreateVisualization::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
function IDLitsrvCreateVisualization::ProgressBar, msg, i, nVis

    compile_opt idl2, hidden

    if (nVis lt 10) then $
        return, 1

    percent = FIX(100*(i + 1d)/nVis)
    if (nVis lt 100) and (percent gt 95) then $
        percent = 100

    return, self->IDLitiMessaging::ProgressBar(msg, $
        PERCENT=percent, $
        SHUTDOWN=(i ge (nVis-1)))

end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::UndoOperation
;;
;; Purpose:
;;  Undo the property commands contained in the command set.
;;
function IDLitsrvCreateVisualization::UndoOperation, oCommandSet, $
    NO_NOTIFY=noNotify

   compile_opt idl2, hidden

   oTool = self->GetTool()
    if (~obj_valid(oTool)) then $
        return, 0

   void = oTool->DoUIService("HourGlassCursor", self)

   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

  noNotify = KEYWORD_SET(noNotify)

  oCmds = oCommandSet->Get(/all, count=nObjs)

    ; Check if the first command is for the view.
    oCmds[0]->GetProperty, TARGET_IDENTIFIER=idView
    oView = oTool->GetByIdentifier(idView)
    if (OBJ_ISA(oView,'IDLitgrView')) then begin
        iStatus = oCmds[0]->GetItem("ORIG_VIRTUAL_DIMENSIONS", $
            viewVirtualDims)
        if (~iStatus) then $
            oView = OBJ_NEW()
        iStatus = oCmds[0]->GetItem("ORIG_MINIMUM_VIRTUAL_DIMENSIONS", $
            viewMinVirtualDims)
        if (~iStatus) then $
            oView = OBJ_NEW()
        iStatus = oCmds[0]->GetItem("ORIG_VISIBLE_LOCATION", $
            viewVisibleLoc)
        if (~iStatus) then $
            oView = OBJ_NEW()
        iStatus = oCmds[0]->GetItem("ORIG_XMARGIN", margin2Dx)
        if (~iStatus) then $
            oView = OBJ_NEW()
        iStatus = oCmds[0]->GetItem("ORIG_YMARGIN", margin2Dy)
        if (~iStatus) then $
            oView = OBJ_NEW()
        oCmds = oCmds[1:(nObjs-1)]
        nObjs--
    endif

    oAllVis = OBJARR(nObjs)
    oPrevParent = OBJ_NEW()
    noUpdate = BYTARR(nObjs)

    ; Loop thru once retrieve all visualizations, and check if some
    ; of them have the same parent. If so we can disable updates when
    ; we remove those visualizations.
    for i=nObjs-1, 0, -1 do begin

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idVis
        oVis = oTool->GetByIdentifier(idVis)
        if (~obj_valid(oVis)) then $
            continue

        oAllVis[i] = oVis

        oVis->IDLitComponent::GetProperty, _PARENT=oParent
        ; If the previous parent is the same as the current parent,
        ; flag the previous visualization as not requiring an update.
        ; Note that we use (i+1) since we are going in reverse order.
        if (OBJ_VALID(oPrevParent) && oParent eq oPrevParent) then begin
            noUpdate[i+1] = 1b
        endif

        oPrevParent = oParent

    endfor

    ; Now loop thru and actually remove the visualizations.
    for i=nObjs-1, 0, -1 do begin

      oVis = oAllVis[i]
      if (~obj_valid(oVis)) then $
        continue

      oVis->Select, /UNSELECT

        ; Check to see if we need to change the autodelete flag on the data
        if (oCmds[i]->getItem("DATA_ID", idData) gt 0)then begin
          iStatus = oCmds[i]->getItem("AUTO_DATA_DELETE", bDelete)
          if (iStatus && bDelete) then begin
              oData = oTool->GetByIdentifier(idData)
              if(obj_valid(oData))then begin
                  if(obj_isa(oData, "IDLitDataContainer"))then $
                    oData->SetAutoDeleteMode, 0 $
                  else if(obj_isa(oData, "IDLitData"))then $
                    oData->SetProperty, AUTO_DELETE=0
              endif
          endif
        endif

      ; Remove from parent container. This will trigger any updates.
      oVis->IDLitComponent::GetProperty, _parent=oParent
      if(obj_valid(oParent))then begin
            oParent->Remove, oVis, $
                NO_NOTIFY=noNotify || (i gt 0), NO_UPDATE=noUpdate[i]

          ; If the dataspace no longer has any visualizations,
          ; and is the only dataspace in its parent root, then delete it.
          if (OBJ_ISA(oParent, '_IDLitVisualization')) then begin
              oDS = oParent->GetDataSpace()

              ; If no dataspaces exist, then there are no dataspaces to
              ;  auto-delete.
              ; If one dataspace exists, and it is the only one in the
              ; dataspace root and is now empty, auto-delete it.
              ; If more than one dataspaces exist, then we do not want to
              ;  auto-delete any of the dataspaces (even if one is now empty).
              if (OBJ_VALID(oDS)) then begin

                  nDS = 0
                  oDSRoot = oDS->GetDataSpaceRoot()
                  if (OBJ_VALID(oDSRoot)) then $
                      oAllDS = oDSRoot->IDLgrModel::Get(/ALL, $
                          ISA='IDLitVisIDataSpace', COUNT=nDS)

                  allowAutoDelete = (nDS eq 1)

                  if (allowAutoDelete) then begin
                      oItems = oDS->GetVisualizations(COUNT=nVis)
                      if (nVis eq 0) then begin
                          oDS->Select, /UNSELECT
                          if (OBJ_VALID(oDSRoot)) then $
                              oDSRoot->Remove, oDS
                          OBJ_DESTROY, oDS
                      endif
                  endif
              endif
         endif
      endif

      if (oCmds[i]->getItem("VISDESC_ID", idVisDesc) gt 0) then begin
        oVisDesc = oTool->GetByIdentifier(idVisDesc)
        if (obj_valid(oVisDesc)) then $
            oVisDesc->ReturnObjectInstance, oVis
      endif

        if (oCmds[i]->GetItem("FOLDER_NAME", foldername)) then begin
            OBJ_DESTROY, oVis
        endif

    endfor

    ; Reset view dimensions and margins if necessary.
    if (OBJ_VALID(oView)) then begin
        oView->SetProperty, VIRTUAL_DIMENSIONS=viewVirtualDims, $
            MINIMUM_VIRTUAL_DIMENSIONS=viewMinVirtualDims, $
            VISIBLE_LOCATION=viewVisibleLoc
        oView->RestoreMargins, [margin2Dx, margin2Dy]
    endif

   if (~previouslyDisabled) then $
       oTool->EnableUpdates

  return, 1

end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::RedoOperation
;;
;; Purpose:
;;   Used to execute this operation on the given command set.
;;   Used with redo for the most part.
;
function IDLitsrvCreateVisualization::RedoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if (~obj_valid(oTool)) then $
     return, 0
   void = oTool->DoUIService("HourGlassCursor", self)

   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

  oCmds = oCommandSet->Get(/all, count=nObjs)
  hasFolder = 0b

  for i=0, nObjs-1 do begin

        ; User hit cancel.
        if (~self->ProgressBar('Recreating Visualizations...', i, nObjs)) then $
            break

        ; Check for a layer.
        if(oCmds[i]->getItem("LAYER", idLayer) eq 0 )then $
            idLayer = ''

        ; Was a destination specified?
        if(oCmds[i]->getItem("DEST_ID", idDest) ne 0)then $
            oDest = oTool->GetByIdentifier(idDest)

        if (~obj_valid(oDest)) then $
            oDest = oTool

        if (oCmds[i]->GetItem('FOLDER_NAME', foldername)) then begin
            hasFolder = 1b
            oFolderVis = OBJ_NEW('IDLitVisualization', $
                NAME=foldername)
            oFolderVis->_SetTool, oTool
            ; For efficiency, disable axes and 3D check until end.
            oFolderVis->SetAxesRequest, 0, /ALWAYS
            oFolderVis->Set3D, 0, /ALWAYS
            oDest->Add, oFolderVis, LAYER=idLayer, /NO_UPDATE, /NO_NOTIFY
        endif

        if (~oCmds[i]->getItem("VISDESC_ID", idVisDesc)) then $
            continue

        oVisDesc = oTool->GetByIdentifier(idVisDesc)
        if (~obj_valid(oVisDesc)) then $
            continue

        iDataStatus = oCmds[i]->getItem("DATA_ID", idData)

        if (iDataStatus gt 0) then begin

            oData = oTool->GetByIdentifier(idData)

            if (~OBJ_VALID(oData)) then begin
                ;; If the data was a parameterset, recreate it
                ;; This is needed because some data items, e.g., non-new data
                ;; items, are removed from parametersets on creation
                if (oCmds[i]->GetItem('__PSET_NAMES_IDS',nameIDArr)) then begin
                  oData = obj_new('IDLitParameterSet')
                  FOR j=0,n_elements(nameIDArr[0,*])-1 DO BEGIN
                    oData->Add,oTool->GetByIdentifier(nameIDArr[1,j]), $
                               PARAMETER_NAME=nameIDArr[0,j],/PRESERVE_LOCATION
                  ENDFOR
                endif else begin
                  self->ErrorMessage, IDLitLangCatQuery('Error:InvalidData:Text'), $
                    title=IDLitLangCatQuery('Error:InvalidData:Title'), SEVERITY=2
                  continue
                endelse
            endif

          ;; Do we need to reset the auto delete mode of the data object?
          iStatus = oCmds[i]->getItem("AUTO_DATA_DELETE", bDelete)
          if(iStatus && bDelete)then begin
              if(obj_isa(oData, "IDLitDataContainer"))then $
                oData->SetAutoDeleteMode, 1 $
              else if(obj_isa(oData, "IDLitData"))then $
                    oData->SetProperty, AUTO_DELETE=1
          endif
        endif

      oVis = oVisDesc->GetObjectInstance()
      oVis->_SetTool, self->GetTool() ;; make sure this is set.

        if (hasFolder) then begin
            oFolderVis->Add, oVis, /NO_UPDATE, /NO_NOTIFY, /AGGREGATE
        endif else begin
            oDest->Add, oVis, layer=idLayer, /NO_UPDATE, $
                NO_NOTIFY=(i lt (nObjs-1))
        endelse

      ; Be sure to set our name to what it was before.
      iStatus = oCmds[i]->getItem("VIS_NAME", visName)
      oVis->IDLitComponent::SetProperty, NAME=visName

      if(iDataStatus)then begin ;;  add after to allow for text calcs
            if (obj_isa(oData, "IDLitParameterSet")) then begin
                void = oVis->SetParameterSet(oData, NO_NOTIFY=hasFolder)
            endif else begin
                void = oVis->SetData(oData, NO_NOTIFY=hasFolder)
            endelse
      endif

      ;; clear and destroy temporary parameter set
      IF (iDataStatus && idData EQ '__PSET') THEN BEGIN
        oData->Remove,/ALL
        obj_destroy,oData
      ENDIF

      ;; Set the id of the new vis
      idVis = oVis->GetFullIdentifier()
      oCmds[i]->SetProperty, TARGET_IDENTIFIER=idVis

       ; Wait to notify about the name property until the end, in case
       ; applying the properties or setting the data changes it.
       oTool->DoOnNotify, idVis, 'SETPROPERTY', 'NAME'

  endfor

    if (hasFolder) then begin
        ; Enable our axes and 3D checks.
        oFolderVis->SetAxesRequest, 0, /AUTO_COMPUTE
        oFolderVis->Set3D, 0, /AUTO_COMPUTE
        idFolderVis = oFolderVis->GetFullIdentifier()
        void = IDLitBasename(idFolderVis, REMAINDER=idParent)
        oTool->DoOnNotify, idParent, "ADDITEMS", idFolderVis
    endif

    ;; Make new visualization selected. This will also notify.
    if (OBJ_VALID(oVis)) then $
        oVis->Select

   if (~previouslyDisabled) then $
       oTool->EnableUpdates

  return, 1
end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::_Create
;;
;; Purpose:
;;   Called to create a set of visualizations given the following
;;   information:
;;        - Viz Object Descriptor
;;        - Data Object
;;
;; Parameters
;;    oVisDesc    - Array of visualization descriptors
;;
;;    oDATA        - Set the an array of data objects that the vis
;;                   will use. This can be not provided.
;;
;; Keywords:
;;   LAYER        - The target layer, if adding to the window.
;;
;;   DESTINATION  - Normally, the item is added to the current winodw
;;                  and the system will determine where to place
;;                  it. However, if this keyword is set, the new vis
;;                  is added to that location.
;;
;;                  This keyword is set to the identifier of the
;;                  parent of the new vis.
;;
;;  ID_VISUALIZATION - An output value that is set to the full
;;                     identifier of the create visualization.
;;
;;  FOLDER_NAME: If multiple visualizations are placed within a single
;;      folder, then set this keyword to the name of the folder to create.
;;      The default is to use the name of the oVisDesc.
;
;; Return Value:
;;    Command set for this operation. Null if an error took place.

function IDLitsrvCreateVisualization::_Create, oVisDesc, oData, $
                                    LAYER=LAYER, DESTINATION=DESTINATION, $
                                    ID_VISUALIZATION=ID_VISUALIZATION, $
                                    NODATA=noData, $
                                    NO_TRANSACT=noTransact, $  ; pass thru
                                    FOLDER_NAME=foldername, $
                                    NAME=nameIn, $  ; Viz name provided by user
                                   _REF_EXTRA=_extra

   compile_opt idl2, hidden

   nVis = n_elements(oVisDesc)
   if(nVis eq 0)then $
     return, obj_new()

   nData = n_elements(oData)

   transact = ~KEYWORD_SET(noTransact)

   oTool = self->GetTool() ;; got to have that tool!
   void = oTool->DoUIService("HourGlassCursor", self)

   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

   oOPProp = oTool->GetService("set_property")

   if(keyword_set(DESTINATION))then $
       oDest = oTool->GetByIdentifier(DESTINATION)

   if (~obj_valid(oDest)) then begin
       oDest = oTool ;; Add this thing somewhere.
       idDest = ''
   endif else idDest = oDest->GetFullIdentifier()

   if (OBJ_VALID(oDest)) then begin
       ; Attempt to locate the view relative to the destination.
       if (OBJ_ISA(oDest, 'IDLitTool')) then begin
           oWin = oTool->GetCurrentWindow()
           oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
       endif else if (OBJ_ISA(oDest,'IDLitWindow')) then begin
           oView = oDest->GetCurrentView()
       endif else if (OBJ_ISA(oDest,'IDLitgrView')) then begin
           oView = oDest
       endif else if (OBJ_ISA(oDest,'IDLitgrLayer')) then begin
           oDest->GetProperty, PARENT=oView
       endif else if (OBJ_ISA(oDest,'_IDLitVisualization')) then begin
           viewOK = oDest->_GetWindowandViewG(oWin, oView)
           if (~viewOK) then oView = OBJ_NEW()
       endif
   endif


   ; Determine whether the tool currently has any visualizations
   ; displayed.  This will be used later to decide whether the
   ; newly created visualization can be customized for the tool.
   hadVis = oTool->HasVisualizations()


   ; CT Jan 2004: If we are adding multiple visualizations,
   ; all with the same VisDesc, then assume they will end up in
   ; the same parent, and avoid notification until we reach the
   ; last item. Notification can be very expensive, especially for
   ; the Viz Browser, where it has to rebuild the entire Viz Layer.
   hasFolder = (nVis gt 1) && ARRAY_EQUAL(oVisDesc, oVisDesc[0])

    ; Output keyword.
    id_visualization = STRARR(nVis)

    ; Make our command set for this action
    if (transact) then begin
        oCmdSet = OBJ_NEW("IDLitCommandSet", $
            OPERATION_IDENTIFIER=self->GetFullIdentifier())
    endif

   ; If a view was found, store initial view dimensions and margins.
   if (OBJ_VALID(oView) && transact) then begin
      oCmd = OBJ_NEW("IDLitCommand", $
          TARGET_IDENTIFIER=oView->GetFullIdentifier())
      oView->GetProperty, $
          VIRTUAL_DIMENSIONS=viewVirtualDims, $
          MINIMUM_VIRTUAL_DIMENSIONS=viewMinVirtualDims, $
          VISIBLE_LOCATION=viewVisibleLoc, $
          XMARGIN=margin2Dx, $
          YMARGIN=margin2Dy
      iStatus = oCmd->AddItem("ORIG_VIRTUAL_DIMENSIONS", viewVirtualDims)
      if (~iStatus) then $
          OBJ_DESTROY, oCmd
      iStatus = oCmd->AddItem("ORIG_MINIMUM_VIRTUAL_DIMENSIONS", $
          viewMinVirtualDims)
      if (~iStatus) then $
          OBJ_DESTROY, oCmd
      iStatus = oCmd->AddItem("ORIG_VISIBLE_LOCATION", viewVisibleLoc)
      if (~iStatus) then $
          OBJ_DESTROY, oCmd
      iStatus = oCmd->AddItem("ORIG_XMARGIN", margin2Dx)
      if (~iStatus) then $
          OBJ_DESTROY, oCmd
      iStatus = oCmd->AddItem("ORIG_YMARGIN", margin2Dy)
      if (~iStatus) then $
          OBJ_DESTROY, oCmd
      if (OBJ_VALID(oCmd)) then $
          oCmdSet->Add, oCmd
   endif

   for i=0, nVis-1 do begin

        ; User hit cancel.
        if (~self->ProgressBar('Creating Visualizations...', i, nVis)) then $
            goto, cancel

       oVis = oVisDesc[i]->GetObjectInstance()
       if (~obj_valid(oVis)) then $
         break

        if (ISA(nameIn)) then begin
          oVis->SetProperty, IDENTIFIER=nameIn[[i]]
        endif

        if (i eq 0) then begin  ; create a pretty Undo/Redo name
            ; Use the viz type to construct a name for this command set.
            type = oVis->GetTypes()
            ; Take the last element.
            type = type[N_ELEMENTS(type)-1]
            if STRCMP(type, 'IDL', 3, /FOLD_CASE) then $
                type = STRMID(type, 3)
            ; Make it pretty.
            type = STRJOIN(STRSPLIT(type, '_', /EXTRACT), ' ')
            type = STRUPCASE(STRMID(type,0,1)) + STRLOWCASE(STRMID(type,1))
        endif


       ;; This is normally done by the object descriptor, but the tool
       ;; can be unset if this is a system level descriptor.
       oVis->_setTool, oTool ;; Set the tool

        if (hasFolder) then begin

            ; First time? Create the vis folder.
            if (i eq 0) then begin
                if (~KEYWORD_SET(foldername)) then $
                    oVis->IDLitComponent::GetProperty, NAME=foldername
                oFolderVis = OBJ_NEW('IDLitVisualization', $
                    NAME=foldername)
                oFolderVis->_SetTool, oTool
                ; For efficiency, disable axes and 3D check until end.
                oFolderVis->SetAxesRequest, 0, /ALWAYS
                oFolderVis->Set3D, 0, /ALWAYS
                oDest->Add, oFolderVis, LAYER=layer, /NO_UPDATE, /NO_NOTIFY
                oTool->_UpdateToolByType, oVis->GetTypes()

                idFolderVis = oFolderVis->GetFullIdentifier()
                if (transact) then begin
                    oCmd = OBJ_NEW("IDLitCommand", TARGET_IDENTIFIER=idFolderVis)
                    iStatus = oCmd->AddItem("FOLDER_NAME", foldername)
                    iStatus = oCmd->AddItem("DEST_ID", idDest)
                    ; Add a layer if we have it to the command set.
                    if(keyword_set(layer))then $
                        iStatus = oCmd->AddItem("LAYER", layer)
                    oCmdSet->Add, oCmd
                endif
            endif

            oFolderVis->Add, oVis, /NO_UPDATE, /NO_NOTIFY, /AGGREGATE

        endif else begin

            ; Add the vis first so that if the vis depends on being in the
            ; tree, it is. (issues with GetTextDims have been seen)
            oDest->Add, oVis, LAYER=layer, /NO_UPDATE, /NO_NOTIFY

        endelse

        ; Now set properties and attach data.
       idVis = oVis->GetFullIdentifier()

       if KEYWORD_SET(nameIn) then begin
            name = nameIn[[i]]
       endif else begin
            ; Get our base name and append the id number.
            oVis->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
            ; See if we have an id number at the end of our identifier.
            idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
            ; Append the id number.
            if (STRMATCH(idnum, '[0-9]*')) then $
                name += ' ' + idnum
       endelse

       oVis->IDLitComponent::SetProperty, NAME=name

       if (transact) then begin
           oCmd = obj_new("IDLitcommand", TARGET_IDENTIFIER=idVis)

           iStatus = oCmd->AddItem("VISDESC_ID", $
                                   oVisDesc[i]->GetFullIdentifier())
           iStatus = oCmd->AddItem("VIS_NAME", name)

           IF (nData GT 0 && obj_valid(oData[i])) THEN BEGIN

                dataID = oData[i]->GetFullIdentifier()
                ; We may have been handed a parameterset that isn't in the tree.
                ; Make sure we have an identifier other than "/".
                ; We still need to add a null string so Undo/Redo knows that
                ; there was some data and can look for the ParameterSet data.
                if (STRLEN(dataID) le 1) then $
                    dataID = ''
                iStatus = oCmd->AddItem("DATA_ID", dataID)

             ;; if the data object is a parameterset, also cache the IDs
             ;; and names of all the objects contained therein.  This is
             ;; in case the items have been added with Preserve_location
             ;; and are stripped out of the parameterset.
             IF obj_isa(oData[i],'IDLitParameterSet') THEN BEGIN
               oObjs = oData[i]->Get(/ALL,NAME=names,COUNT=cnt)
               IF (cnt NE 0) THEN BEGIN
                 nameIDArr = strarr(2,cnt)
                 nameIDArr[0,*] = names
                 FOR j=0,cnt-1 DO BEGIN
                   nameIDArr[1,j] = oObjs[j]->GetFullIdentifier()
                 ENDFOR
                 void = oCmd->AddItem('__PSET_NAMES_IDS',nameIDArr)
               ENDIF
             ENDIF

             if(obj_isa(oData[i], "IDLitData"))then begin
               oData[i]->Getproperty, auto_delete=autodel
               iStatus = oCmd->AddItem("AUTO_DATA_DELETE", autodel)
             endif
           endif
           if(keyword_set(idDest))then $
             iStatus = oCmd->AddItem("DEST_ID", idDest)

           ;; Add a layer if we have it to the command set.
           if(keyword_set(layer))then $
             iStatus = oCmd->AddItem("LAYER", layer)

       endif   ; transact command


       ;; Set the data in the object
       if(nData gt 0 && ~KEYWORD_SET(noData) && obj_valid(oData[i]))then begin
           if(obj_isa(oData[i], "IDLitParameterSet"))then begin
             iStatus = oVis->SetParameterSet(oData[i], NO_NOTIFY=hasFolder)
           endif else begin
             iStatus = oVis->SetData(oData[i], _extra=["BY_VALUE"], $
                NO_NOTIFY=hasFolder)
           endelse
           if(iStatus eq 0)then begin
               ;; Okay, we need to destroy everything and skip this.
               obj_destroy, oVis
                if (OBJ_VALID(oCmd)) then $
                    obj_destroy, oCmd
                if (OBJ_VALID(oProps)) then $
                    obj_destroy, oProps
               continue
           endif
       endif

        ; Apply properties (anything passed in) to the object here.
        if (N_ELEMENTS(_extra) gt 0) then begin
            oProps = oOPProp->doSetPropertyWith_Extra(oVis, $
                NO_TRANSACT=noTransact, _EXTRA=_extra)
            ; Force properties to only be set on a Redo, not an Undo.
            ; On an Undo we are assuming that the visualization will get
            ; destroyed anyway, so no need to undo all the properties.
            if OBJ_VALID(oProps) then $
                oProps->SetProperty, /SKIP_UNDO
        endif else $
            oProps = OBJ_NEW()

        ; Add these commands to the command set.
        if (transact) then $
            oCmdSet->Add,oCmd

        ; Append the properties command set
        if (transact && OBJ_VALID(oProps)) then begin
            oPropSet = (N_ELEMENTS(oPropSet) gt 0) ? $
                [oPropSet, oProps] : oProps
        endif

        ; Wait to notify about the name property until the end, in case
        ; applying the properties or setting the data changes it.
        oTool->DoOnNotify, idVis, 'SETPROPERTY', 'NAME'

        id_visualization[i] = idVis

    endfor

    ; We can now do our ADDITEMS notification, because the parameter sets
    ; have been hooked up.
    if (hasFolder) then begin
        ; Enable our axes and 3D checks.
        oFolderVis->SetAxesRequest, 0, /AUTO_COMPUTE
        oFolderVis->Set3D, 0, /AUTO_COMPUTE
        void = IDLitBasename(idFolderVis, REMAINDER=idParent)
        oTool->DoOnNotify, idParent, "ADDITEMS", idFolderVis
    endif else begin
        for i=0,N_ELEMENTS(id_visualization)-1 do begin
            if (~id_visualization[i]) then $
                continue
            void = IDLitBasename(id_visualization[i], REMAINDER=idParent)
            ; If adding to annotation layer, don't notify since
            ; IDLitGrAnnotateLayer::Add will notify
            if (strpos(idParent, "ANNOTATION LAYER") eq -1) then $
                oTool->DoOnNotify, idParent, "ADDITEMS", id_visualization[i]
        endfor
    endelse


    ; Select the last visualization added.
    if (OBJ_VALID(oVis)) then begin
        oVis->IDLitComponent::GetProperty, PRIVATE=private
        if (~private) then $
            oVis->Select, /SKIP_MACRO
    endif

    ; If we are creating a single VisImage, and the Pixel origin/size
    ; hasn't been set, and we are within a map-like tool, then fire
    ; up the RegisterImage operation.
    if (nVis eq 1 && OBJ_ISA(oVis, 'IDLitVisImage')) then begin
        oTool->GetProperty, _TOOL_NAME=toolName
        oWin = oTool->GetCurrentWindow()
        oView = Obj_Valid(oWin) ? oWin->GetCurrentView() : Obj_New()
        oLayer = Obj_Valid(oView) ? oView->GetCurrentLayer() : Obj_New()
        oWorld = Obj_Valid(oLayer) ? oLayer->GetWorld() : Obj_New()
        oDS = Obj_Valid(oWorld) ? oWorld->GetCurrentDataSpace() : Obj_New()
        sProj = Obj_Valid(oDS) ? oDS->GetProjection() : 0

        if (OBJ_ISA(oData[0], "IDLitParameterSet")) then $
           oGeo = (oData[0]->Get(/ALL, ISA='IDLitDataIDLGeoTIFF'))[0]

        ; Are we within a map tool, or do we have a map projection?
        if (Obj_Valid(oGeo) || toolName eq 'Map Tool' || N_tags(sProj) gt 0) then begin
            oVis->GetProperty, GRID_UNITS=gridUnits, $
                PIXEL_XSIZE=pixelXSize, PIXEL_YSIZE=pixelYSize, $
                XORIGIN=xOrigin, YORIGIN=yOrigin
            needsRegisterImage = gridUnits eq 0 && $
                pixelXSize eq 1 && pixelYSize eq 1 && $
                xOrigin eq 0 && yOrigin eq 0

            ; See if we have a GeoTIFF data object.
            oSrvGeotiff = oTool->GetService('GEOTIFF')
            if (OBJ_VALID(oSrvGeotiff) && $
                OBJ_VALID(oGeo) && oGeo->GetData(geotiff)) then begin
                success = oSrvGeotiff->GeoTIFFtoMapImage(geotiff, oVis)
                ; Fire up the Map Register Image operation?
                needsRegisterImage = ~success
                ; Applying the map proj to the image may also
                ; have inserted a map grid, which became selected.
                ; So restore selection to our vis.
                oVis->Select, /SKIP_MACRO
            endif

            ; If grid properties have not been set, or our GeoTIFF tags
            ; had a problem, then fire up the Map Register Image operation.
            if (needsRegisterImage) then begin
              oDesc = oTool->GetByIdentifier('Operations/Operations/MapRegisterImage')
              if (ISA(oDesc)) then begin
                oOp = oDesc->GetObjectInstance()

                oCmd = oOp->DoAction(oTool, _EXTRA=_extra)
                if (~transact) then $
                    OBJ_DESTROY, oCmd
                if (OBJ_VALID(oCmd[0])) then $
                    oCmdSet = [oCmdSet, oCmd]
              endif
            endif
        endif
    endif

   oTool->ActivateManipulator, /DEFAULT

   ; If the tool had not previously been displaying any visualizations,
   ; customize the newly created graphics now.
   if (~hadVis) then begin
       oCustomCmd = oTool->CustomizeGraphics()
        if (~transact) then $
            OBJ_DESTROY, oCustomCmd
       if (OBJ_VALID(oCustomCmd)) then begin
           oCmdSet = (N_ELEMENTS(oCmdSet) gt 0) ? $
            [oCmdSet, oCustomCmd] : oCustomCmd
       endif
   endif

   ;; ensure dataspace is up to date with all properties, e.g., isotropic
   if OBJ_VALID(oVis) then begin
       oDataSpace = oVis->GetDataSpace()
       ; Some visualizations (like lights) may not have a dataspace.
       if OBJ_VALID(oDataSpace) then begin
           oDataSpace->OnDataChange, oDataSpace
           oDataSpace->OnDataComplete, oDataSpace
       endif
   endif

    if (transact && N_ELEMENTS(oPropSet) gt 0) then $
        oCmdSet = [oCmdSet, oPropSet]

cancel:

   nCommands = N_ELEMENTS(oCmdSet)

   ; The Undo/Redo tooltip looks at the last item in the command set,
   ; so add our name to it.
   if (nCommands gt 0) then $
        oCmdSet[nCommands-1]->SetProperty, NAME='Create '+type

   if (~previouslyDisabled) then $
       oTool->EnableUpdates

   return, (nCommands gt 0 ? oCmdSet : obj_new())

end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::_GetandCheckObject, Objects
;;
;; Purpose:
;;   Method to validate a set of objects.
;;
;; Parameters:
;;   Objects  - The items to check. They can be id's or objects
;
;;   strClass - A list of class types to check
;;
;; Keywords:
;;   COUNT   - The number of items found
;;
;;   VISUALIZATION - If set, the type is a visualization
;;
;; Return Value:
;;
;;  Success - The list of objects
;;
;;  Failure - NULL and count returns 0
;;
function IDLitsrvCreateVisualization::_GetandCheckObjects, Objects, $
                                    strClass, COUNT=nObjs, $
                                    VISUALIZATION=VISUALIZATION
   compile_opt hidden, idl2

   oTool = self->GetTool()
   nObjs = n_elements(Objects)
   ;; Get the proper data
   iType = size(objects[0], /type)
   case iType of
       7: begin
           oObjs = objarr(nObjs)
           if(keyword_set(visualization))then begin
               for i=0, nObjs-1 do begin
                   oObjs[i] = oTool->GetVisualization(Objects[i])
                   if(not obj_valid(oObjs[i]))then $
                     oObjs[i] = oTool->GetByIdentifier(Objects[i])
                   ;; Is this an annotation?
                   if(not obj_valid(oObjs[i]))then $
                     oObjs[i] = oTool->GetAnnotation(Objects[i])
               endfor
           endif else begin
               for i=0, nObjs-1 do $
                 oObjs[i] = oTool->GetByIdentifier(Objects[i])
           endelse
       end
       11: oObjs = Objects
       else: oObjs = obj_new()
   endcase
   ;; Validate
   for i=0, n_elements(strClass)-1 do begin
       void = where(obj_isa(oObjs, strClass[i]), nValid, $
                    complement=iComp, ncomplement=nComp)
       if(nValid eq nObjs)then break
   endfor
   if(nValid ne nObjs)then begin
       case iType of
           7:  msg = IDLitLangCatQuery('Message:Framework:InvalidVizId') + $
               (nComp gt 0 ? Objects[iComp[0]] : "<Unknown>")+"""."
           11: msg = IDLitLangCatQuery('Message:Framework:InvalidVizDesc')
           else: msg = IDLitLangCatQuery('Message:Framework:InvalidObjDesc')
       endcase
       self->SignalError, msg + IDLitLangCatQuery('Message:Framework:CannotCreateViz')
             SEVERITY=1
       nObjs = 0
       return, obj_new()
   endif
   return, oObjs

end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::_HandleDataNoMatch
;;
;; Purpose:
;;   Method called when a visualization match for a particular data
;;   objects is not found.
;;
;; Parameter:
;;   oData  [in]    - The data object that didn't match.
;;
;;   oDataOut [out] - The result from the processing
;;
;; Return Value;
;;   1    - A processing condition took place and oDataOut is valid
;;   0    - The operation was cancelled.
;;   -1   - Error

function IDLitsrvCreateVisualization::_HandleDataNoMatch, oData, oDataOut

    compile_opt idl2, hidden

    oTool = self->GetTool()
;    oData->GetProperty, TYPE=dType

    ; Get the unknown data operation.
    ; Eventually this should be a more generic operation.
    oUnknownData = oTool->GetService("UNKNOWNDATA")
    if (~OBJ_VALID(oUnknownData)) then begin
        oTool->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:UnknownDataService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, -1
    endif

    oDataOut = oUnknownData->Handle(oData)

    return, OBJ_VALID(oDataOut) ? 1 : -1

end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::_CheckVisDataSupport
;;
;; Purpose:
;;   Private method used to verify that the given visualizaton
;;   descriptor supports any information contained in the given data
;;   object.
;;
;; Parameters:
;;     oData    - The data to check.
;;
;;     oVisDesc - The vis to check against.
;;
;; Keywords:
;;    None.
;;
;; Return Value
;;    1 - match
;;    0 - no match
;;
function IDLitsrvCreateVisualization::_CheckVisDataSupport, oData, oVisDesc
   compile_opt hidden, idl2
   oMatch = oData->GetByType(oVisDesc->GetDataTypes(), count=nMatch)
   return, (nMatch gt 0) ;; pretty simple

end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::_FindVisualizationByDataType
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
;;    Success   - 1
;;    No Match  - 0
;;    Error     - -1

function IDLitsrvCreateVisualization::_FindVisualizationByDataType, oData, oVis
   compile_opt hidden, idl2

   ;; this is internal, so we assume that oData is valid and a scalar!

   ;; Get the available list of visualizations
   oTool = self->GetTool()
   oVisDesc = oTool->GetVisualization(COUNT=nVis,/all)

   if(nVis eq 0)then begin
       self->SignalError, $
     IDLitLangCatQuery('Error:Framework:NoVizAvailable'), $
         SEVERITY=1
       return, -1 ;; major issues.
   endif

   ;; CASE 1
   ;; Straight match with the default visualization
   ;;
   ;; The first visualization is the "default' for the tool. Get the
   ;; visualizations data type
   if(self->_CheckVisDataSupport(oData, oVisDesc[0]) eq 1)then begin
       oVis = oVisDesc[0]
       return, 1
   endif

   ;; Case 2
   ;; Check to see if any visualization matches the data. This search
   ;; looks at the primary data type.
   oData->GetProperty, TYPE=dType
   for i=1, nVis-1 do begin ;; skip the first vis.
       visTypes = oVisDesc[i]->GetDataTypes()
       dex = where(visTypes eq dType, nMatch)
       if(nMatch gt 0)then begin ;; we have a match !!!
           oVis = oVisDesc[i]
           return, 1
       endif
   endfor

   ;; Case 3
   ;; Check to see if any visualization matches any of the data. This search
   ;; looks at all data in the data object.
   for i=1, nVis-1 do begin ;; skip the first vis.
       if(self->_CheckVisDataSupport(oData, oVisDesc[i]) eq 1)then begin
           oVis = oVisDesc[i]
           return, 1
       endif
   endfor

   ;; At this point, no data-vis match. Return the no match flag
   return, 0
end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateVisualization::CreateVisualization
;;
;; Purpose:
;;   Main entry point for the create visualization operation. This
;;   method accepts data (id or object) and an optional visualization
;;   descriptor (id or object) and will create the visualization and
;;   add it to the current window. All actions are transacted and
;;   properties (keywords) provided are applied to the target
;;   visualization.
;;
;;   If only data is provided, the list of available visualizations
;;   for this tool is searched for a match. This algorithm takes the
;;   following path:
;;      - The default visualization for the tool is searched to see if
;;        it will support the given data.
;;      <== If a match, the search is stopped.
;;      - The remaining visualizations supported by the tool are
;;        searched. This search is performed first looking at the main
;;        data type of the provided data object. If that fails, then
;;        the search is performed doing a deep query (see the data
;;        spec) of the provided data hiearchy.
;;      <== If a match, the search is
;;      - If a match is still not found, a call is made to the
;;        operation that will provide the user the option to change
;;        the data (grid, retype, reformat..ect). When that is
;;        completed, the search is performed again, looking for a
;;        match. If the match fails again, the proces....(stops?).
;;
;; Parameters
;;    Data     - The data to use for the visualization. If this is a
;;               string, it is assumed to be an id to the target
;;               data. Otherwise this should be a live data object.
;;
;;    VisDesc  - This optional argument is set visualization
;;               descriptor to use for creating the visualization. If
;;               a string, this is assumed to be the id of the
;;               visualization descriptor to use, otherwise the object
;;               should be a descriptor for the visualization.
;;
;; Keywords
;;   All keywords are treaded as properties and passed to the
;;   low-level routines. _Ref_Extra is used to allow for keyword
;;   filtering if needed by the lower level routines.
;;
;; Return Value:
;;   A command set for this operation or null if something failed.
;;
;; Modification History:
;;     1/2003    KDB   - Inital Entry.
;;                       CONSULT ME BEFORE MODIFYING

function IDLitsrvCreateVisualization::CreateVisualization, Data, Vis, $
    UNKNOWN_DATA=unknownData, $
    _REF_EXTRA=_extra

   compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch,/cancel
      self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
        [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], severity=2
       return, obj_new()
   endif


   oData = self->_GetandCheckObjects(Data, "IDLitData", count=nData)
   if(nData eq 0)then begin
       self->SignalError, $
     IDLitLangCatQuery('Error:Framework:InvalidDataRef'), $
         SEVERITY=1
       return, obj_new()
   endif


    ; Handle our UNKNOWN_DATA keyword.
    doUnknown = KEYWORD_SET(unknownData)

    if (doUnknown) then begin
        for i=0,N_ELEMENTS(oData)-1 do begin
            iCheck = self->_HandleDataNoMatch(oData[i], oDataOut)
            ; If user hit cancel, or did not want to create viz.
            if (iCheck eq -1) then $
                return, obj_new()
            ; If created a new data object (rather than adding to the
            ; current one), then add it to the array.
            if OBJ_VALID(oDataOut) then $
                oData[i] = oDataOut
        endfor
    endif

   ;; if we have a visualization desc, see if it's valid.
   ;; The checks are: Vis paramater exists and defined. Use of
   ;; keyword_set() will screen out any nulls and ''
   if(n_params() gt 1 && N_ELEMENTS(Vis) gt 0 && Vis[0] ne '') then begin
       oVisDesc = self->_GetandCheckObjects(Vis, /visualization, $
                                            ["IDLitObjDescVis", "IDLitObjDescProxy"],$
                                            count=nVis)

       if(nVis eq 0)then begin
           self->ErrorMessage, /use_last_error, title=IDLitLangCatQuery('Error:InternalError:Title')
           return, obj_new()
       endif
       ;; Okay, does the number of vis descriptors match?
       if(nVis ne nData)then begin
           self->SignalError, $
         IDLitLangCatQuery('Error:Framework:DataCountMismatch'), $
             SEVERITY=1
           return, obj_new()
       endif
   endif else nVis = 0

   ;; Okay, at this point we have our input validated and
   ;; "understood". If we have a vis and data, just send this to the
   ;; create method and return (the easy path!)
   if(nVis eq 0)then begin
       ;;
       ;; If we don't have a visualization descriptor, we must begin the
       ;; search for a matching visualization. This matching is done by
       ;; the private method _FindVisualizationByDataType.
       ;;
       ;; Note: I'm going through all objects and doing the match before
       ;; calling _Create. This makes a roll-back operation easier.
       oVisDesc = objarr(nData)
       previousType = ''

       for i=0, nData-1 do begin

           status = 0

           while(status eq 0) do begin
                oData[i]->GetProperty, TYPE=dType
                if (previousType && previousType eq dType) then $
                    break
                isUnknownContainer = STRCMP(dType, 'IDLUNKNOWNDATA', /FOLD_CASE)
                status = isUnknownContainer ? 0 : $
                    self->_FindVisualizationByDataType(oData[i], oDesc)
                if(status eq 0)then begin
                   ; Don't want to do the _HandleDataNoMatch more than once.
                   if (doUnknown) then begin
                        status = -1
                        break
                   endif
                   iCheck = self->_HandleDataNoMatch(oData[i], oDataOut)
                   if (iCheck eq 1) then begin
                        oData[i] = oDataOut[0]  ;; the loop will reprocess.
                        if isUnknownContainer then $
                            oData[i]->SetProperty, TYPE=''
                   endif else $
                        status = -1 ;; break out.
                endif
           endwhile

           if(status eq -1)then break ;
           ;; If we are here, we are good to go.
           oVisDesc[i] = oDesc
           nVis++
           previousType = dType

       endfor

   endif else begin
       ;; Visualization descriptors were available, but we need to
       ;; validate them with the provided data.
       for i=0, nData-1 do begin
           status = 0
           while( status eq 0) do begin
               status = self->_CheckVisDataSupport(oData[i], oVisDesc[i])
               if(status eq 0)then begin
                   ; Don't want to do the _HandleDataNoMatch more than once.
                   if (doUnknown) then begin
                        status = -1
                        break
                   endif
                   ;; Okay, the data didn't match the vis. See if the
                   ;; data can be modified.
                   iCheck = self->_HandleDataNoMatch(oData[i], oDataOut)
                   if(iCheck eq 1)then $
                     oData[i] = oDataOut[0] $ ;; the loop will reprocess.
                   else status = -1 ;; break out.
               endif
           endwhile
           if(status eq -1)then break
           ;; If we are here, we are good to go.
       endfor
   endelse
   ;; Check our status
   if(nVis ne nData or status eq -1)then $
     return, obj_new() ;; not a valid input set.

   ;; And the last step is to create the visualizations.
   oCmds = self->_Create(oVisDesc, oData, _EXTRA=_extra);

   return, oCmds

end
;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitsrvCreateVisualization__define

    compile_opt idl2, hidden

    struc = {IDLitsrvCreateVisualization,       $
             inherits IDLitOperation $
            }
end

