; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvcreatedataspace__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitsrvCreateDataSpace
;
; PURPOSE:
;   This file implements the operation object that is used to create
;   a visualization.
;
;-

;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvCreateDataSpace object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitsrvCreateDataSpace::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
;pro IDLitsrvCreateDataSpace::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::UndoOperation
;;
;; Purpose:
;;  Undo the property commands contained in the command set.
;;
function IDLitsrvCreateDataSpace::UndoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)
  for i=nObjs-1, 0, -1 do begin

      ; Could be recursive if we created a bunch of viz at the
      ; same time (e.g. from different files).
      if (OBJ_ISA(oCmds[i], 'IDLitCommandSet')) then begin
        dummy = self->UndoOperation(oCmds[i])
        continue
      endif

      ;; Get the target object for this command.
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idVis
      oVis = oTool->GetByIdentifier(idVis)
      if (not obj_valid(oVis)) then $
        continue

      iStatus = oCmds[i]->getItem("VISDESC_ID", idVisDesc)
      oVisDesc = oTool->GetByIdentifier(idVisDesc)
      if (not obj_valid(oVisDesc)) then $
        continue

      oVis->Select, /UNSELECT, /NO_NOTIFY

      ;; Remove from our parent container. This will trigger any update
      oVis->GetProperty, _parent=oParent
      if(obj_valid(oParent))then $
        oParent->Remove, oVis

      oVisDesc->ReturnObjectInstance, oVis
  endfor

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::RedoOperation
;;
;; Purpose:
;;   Used to execute this operation on the given command set.
;;   Used with redo for the most part.

function IDLitsrvCreateDataSpace::RedoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)
  for i=nObjs-1, 0, -1 do begin

      ; Could be recursive if we created a bunch of viz at the
      ; same time (e.g. from different files).
      if (OBJ_ISA(oCmds[i], 'IDLitCommandSet')) then begin
        dummy = self->RedoOperation(oCmds[i])
        continue
      endif

      iStatus = oCmds[i]->getItem("VISDESC_ID", idVisDesc)

      oVisDesc = oTool->GetByIdentifier(idVisDesc)
      if(not obj_valid(oVisDesc))then $
        continue
      oDS = oVisDesc->GetObjectInstance()
      oDS->_SetTool, self->GetTool() ;; make sure this is set.
      ;; Check for a layer.
      if(oCmds[i]->getItem("LAYER", idLayer) eq 0 )then $
         idLayer = ''

      ;; Was a destination specified?
      if(oCmds[i]->getItem("DEST_ID", idDest) ne 0)then $
          oDest = oTool->GetByIdentifier(idDest)

      if(not obj_valid(oDest))then $
        oDest = oTool

      oDest->Add, oDS, layer=idLayer, /NO_UPDATE

       oDS->SetXYZRange, [0.0,1.0], [0.0,1.0], [0.0,0.0]

       ; Typically, the default style for the axes within a dataspace
       ; is 0 (no axes) until a visualization that requests axes is
       ; added.  In this case, the user is likely to want to see the
       ; axes before any visualizations are added, so set the style
       ; to 1 (i.e., show axes at the origin).
       oDS->SetAxesRequest, 1

      ;; Set the id of the new vis
      oCmds[i]->SetProperty, TARGET_IDENTIFIER=oDS->GetFullIdentifier()
  endfor

  return, 1
end

;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::_Create
;;
;; Purpose:
;;   Called to create a set of dataspaces given the following
;;   information:
;;        - DataSpace Object Descriptor
;;
;; Parameters
;;    oDesc:    Array of dataspace descriptors.
;;
;; Keywords:
;;    LAYER:    The target layer, if adding to the window.
;;
;;    DESTINATION  - Normally, the item is added to the current winodw
;;                  and the system will determine where to place
;;                  it. However, if this keyword is set, the new vis
;;                  is added to that location.
;;
;;                  This keyword is set to the identifier of the
;;                  parent of the new vis.
;;
;;  ID_VISUALIZATION - An output value that is set to the full
;;                     identifier of the created dataspace.
;; Return Value:
;;    Command set for this operation. Null if an error took place.

function IDLitsrvCreateDataSpace::_Create, oDesc, $
                                    LAYER=LAYER, DESTINATION=DESTINATION, $
                                    ID_VISUALIZATION=ID_VISUALIZATION, $
                                   _REF_EXTRA=_extra

   compile_opt idl2, hidden

   nDS = n_elements(oDesc)

   oTool = self->GetTool()

   if (keyword_set(DESTINATION))then $
       oDest = oTool->GetByIdentifier(DESTINATION)
   if(not obj_valid(oDest))then begin
       oDest = oTool ;; Add this thing somewhere.
       idDest = ''
   endif else idDest = oDest->GetFullIdentifier()

   ID_VISUALIZATION = strarr(nDS)
   nCommands=0
   for i=0, nDS-1 do begin
       ;; Make our command set for this action
       oTmpSet = OBJ_NEW("IDLitCommandSet", $
                         OPERATION_IDENTIFIER=self->GetFullIdentifier())

       oDS = oDesc[i]->GetObjectInstance()
       if(not obj_valid(oDS))then $
         return, obj_new()

       ;; This is normally done by the object descriptor, but the tool
       ;; can be unset if this is a system level descriptor.
       oDS->_setTool, oTool ;; Set the tool

       ;; Add the vis first so that if the vis depends on being in the
       ;; tree, it is. (issues with GetTextDims..have been seen)
       oDest->Add, oDS, LAYER=LAYER, /NO_UPDATE
       oDS->SetXYZRange, [0.0,1.0], [0.0,1.0], [0.0,0.0]

       ; Typically, the default style for the axes within a dataspace
       ; is 0 (no axes) until a visualization that requests axes is
       ; added.  In this case, the user is likely to want to see the
       ; axes before any visualizations are added, so set the style
       ; to 1 (i.e., show axes at the origin).
       oDS->SetAxesRequest, 1

       ID_VISUALIZATION[i] = oDS->GetFullIdentifier()

       oCmd = obj_new("IDLitcommand", $
                      TARGET_IDENTIFIER=ID_VISUALIZATION[i])
       iStatus = oCmd->AddItem("VISDESC_ID", $
                               oDesc[i]->GetFullIdentifier())

       if(keyword_set(idDest))then $
         iStatus = oCmd->AddItem("DEST_ID", idDest)

       ;; Add a layer if we have it to the command set.
       if(keyword_set(layer))then $
         iStatus = oCmd->AddItem("LAYER", layer)

       ;; Add these commands to the temp command set. This is used so
       ;; if the creation fails, it is easy to cleanup
       oTmpSet->Add,oCmd

      ;; Apply properties (anything passed in ) to the object here.
       oProps = self->_ApplyProperties(oTmpSet, count=nProps, _extra=_extra)

       if(nProps gt 0)then $ ;; Append the properties command set
         oTmpSet = [oTmpSet, oProps]
       ;; Add the command sets to the outbound array
       oCmdSet = (nCommands gt 0 ? [oCmdSet, oTmpSet] : oTmpSet)
       nCommands = n_elements(oCmdSet)

       ;; Make new dataspace selected. This will also notify.
       oDS->Select
   endfor

   oTool->ActivateManipulator, /DEFAULT

   ;; Return if valid
   return, (nCommands gt 0 ? oCmdSet : obj_new())
END
;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::_ApplyProperties
;;
;; Purpose:
;;  This routine will set and transact a set of properties to
;;  the set of visualizations that were created during a create
;;  operation. It is assumed that the properies are provided via
;;  _extra.
;;
;; Parameters:
;;   oCmdSet   - An array of create vis commands. This is looped
;;               through and property transactions added.
;;
;; Keywords:
;;   _EXTRA    - The properties and values to set.
;;
;;   COUNT     - The number of items applied
;;
;; Return Value:
;;   The command sets for the properties applied, or obj_new() if none
;;   were.
function IDLitsrvCreateDataSpace::_ApplyProperties, oCmdSet,$
                                    COUNT=COUNT, _extra=_extra

   compile_opt hidden, idl2

   COUNT=0
   nCmds = n_elements(oCmdSet)
   if(nCmds eq 0 or n_elements(_extra) eq 0)then $
     return, obj_new()

   oTool = self->GetTool()
   oOPProp = oTool->GetService("set_property")
   for i=0, nCmds-1 do begin
       ;; get our target viz id.
       oVizCMD =  oCmdSet[i]->get()
       oVizCmd->GetProperty, target_identifier=idVis
       oPropSet = oOPProp->doSetPropertyWith_Extra(idVis , _extra=_extra)
       ;; If we set properties, cat them onto the command set
       ;; array.
       if(obj_valid(oPropSet))then begin
           oCmdProps = (count gt 0 ? [oCmdProps, oPropSet] : oPropSet)
           count++
       endif
   endfor

   return, (count gt 0 ?  oCmdProps : obj_new())
end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::_GetandCheckObject, Objects
;;
;; Purpose:
;;   Method to validate a set of objects.
;;
;; Parameters:
;;   Objects  - The items to check. They can be id's or objects
;
;; Keywords:
;;   COUNT   - The number of items found
;;
;; Return Value:
;;
;;  Success - The list of objects
;;
;;  Failure - NULL and count returns 0
;;
function IDLitsrvCreateDataSpace::_GetandCheckObjects, Objects, $
                                   strClass, COUNT=nObjs
   compile_opt hidden, idl2

   oTool = self->GetTool()
   nObjs = n_elements(Objects)
   ;; Get the proper data
   iType = size(objects[0], /type)
   case iType of
       7: begin
           oObjs = objarr(nObjs)
           for i=0, nObjs-1 do begin
               oObjs[i] = oTool->GetVisualization(Objects[i])
               if(not obj_valid(oObjs[i]))then $
                 oObjs[i] = oTool->GetByIdentifier(Objects[i])
           endfor
       end
       11: oObjs = Objects
       else: oData = obj_new()
   endcase
   ;; Validate
   void = where(obj_isa(oObjs, strClass), nValid, $
                complement=iComp, ncomplement=nComp)
   if(nValid ne nObjs)then begin
       case iType of
           7:  msg = IDLitLangCatQuery('Message:Framework:InvalidDataSpaceId') + $
               (nComp gt 0 ? Objects[iComp[0]] : "<Unknown>")+"""."
           11: msg = IDLitLangCatQuery('Message:Framework:InvalidDataSpaceDesc')
           else: msg = IDLitLangCatQuery('Message:Framework:InvalidObjDesc')
       endcase
       self->SignalError, msg + IDLitLangCatQuery('Message:Framework:CannotCreateViz'), $
             SEVERITY=1
       nObjs = 0
       return, obj_new()
   endif
   return, oObjs

end
;;---------------------------------------------------------------------------
;; IDLitsrvCreateDataSpace::CreateDataSpace
;;
;; Purpose:
;;   Main entry point for the create dataspace operation.
;;
;; Parameters:
;;   Descriptor:    Either a string representing the identifier of
;;     a registered dataspace class, or an instance of an object descriptor
;;     for a registered dataspace class.  The created dataspace will be
;;     an instance of this class.
;;
;; Keywords
;;   All keywords are treated as properties and passed to the
;;   low-level routines.
;;
;; Return Value:
;;   A command set for this operation or null if something failed.
;;
function IDLitsrvCreateDataSpace::CreateDataSpace, descriptor, _ref_extra=_extra
   compile_opt idl2, hidden

   ;; Verify validity of descriptor.
   oDesc = self->_GetandCheckObjects(Descriptor, $
                                     "IDLitObjDescVis", COUNT=nDS)

   if (nDS eq 0) then begin
       self->ErrorMessage, /USE_LAST_ERROR, TITLE=IDLitLangCatQuery('Error:CreationError:Title')
       return, OBJ_NEW()
   endif

   ;; Create the dataspaces.
   ;; Disable updates so multiple items don't cause mutliple repaints.
   oTool = self->GetTool()
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
   oCmds = self->_Create(oDesc, _EXTRA=_extra);
   IF (~previouslyDisabled) THEN $
     oTool->EnableUpdates
   return, oCmds
end

;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitsrvCreateDataSpace__define

    compile_opt idl2, hidden

    struc = {IDLitsrvCreateDataSpace, $
             inherits IDLitOperation  $
            }
end

