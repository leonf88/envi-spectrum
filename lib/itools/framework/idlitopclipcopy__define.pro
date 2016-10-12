; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopclipcopy__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopClipCopy
;
; PURPOSE:
;   This file implements the operation that will copy the currently
;   selected items to the local clipboard.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopClipCopy::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopClipCopy::Init
;
; Purpose:
; The constructor of the IDLitopClipCopy object.
;
; Parameters:
; None.
;
function IDLitopClipcopy::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    return, self->IDLitOperation::Init(TYPES="VISUALIZATION", _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; IDLitopClipCopy::DoAction
;
; Purpose:
;   Will cause the currently selected items to be copyied to the
;   local clipboard of the system.
;
; Return Value:
;   Since this is not transactional, a obj null is returned.
;
function IDLitopClipCopy::DoAction, oTool
   compile_opt hidden, idl2

   ;; Make sure we have a tool.
   if ~obj_valid(oTool) then $
      return, obj_new()

  ;; Get the selected objects.
    oSelVis = oTool->GetSelectedItems()

    ;; We can only copy visualizations
    iValid  = where(obj_valid(oSelVis) and $
        obj_isa(oSelVis, "IDLitVisualization"), nValid)

   ;; We will need the system, which has the clipboard.
   oSystem = oTool->_GetSystem()

   ; If we have a selection, then copy it. Otherwise, just do
   ; a screen scrape copy.
   if (nValid gt 0) then begin

     oSelVis= oSelVis[iValid]
  
     ; Be sure to move the axes to the front of the list,
     ; so they get pasted first. This avoid the creation of
     ; duplicate axes since the "default" axes will have already
     ; been pasted in once the viz is created.
     isAxes = WHERE(OBJ_ISA(oSelVis, 'IDLitVisAxis'), nAxes, $
       COMPLEMENT=notAxes)
     if ((nAxes gt 0) && (nAxes lt nValid)) then $
          oSelVis = [oSelVis[isAxes], oSelVis[notAxes]]
  
     ;; clear out the current contents of the clipboard.
     oSystem->BeginClipboardInterAction
     oSystem->ClearClipboard
  
     ;; For each valid object do the following:
     ;;   - Get it's parameters
     ;;   - Get the id of the data associated with the parameters.
     ;;   - Create a clipboard object
     ;;   - Record the current property settings of the object to copy.
     ;;   - Record the class name of the object.
     ;;   - Determine if this object is an annotation.
     for i=0, nValid-1 do begin
         oItem = obj_new("IDLitClipBoardItem", TOOL=oTool)
         oItem->CopyItem, oSelVis[i]
         ;; Get the layer of this item....annotations need to go into
         ;; the annotation layer...
         oLayer = oSelVis[i]->_GetLayer()
         if(obj_Isa(oLayer,'IDLitgrAnnotateLayer'))then $
           oItem->SetProperty, LAYER="ANNOTATION"
  
         ;; Add this to the clipboard
         oSystem->AddByIdentifier, "/CLIPBOARD", oItem
     end
     oSystem->EndClipboardInterAction

   endif

   ;; Now for the system.
   oSysCopy = oSystem->GetService("SYSTEM_CLIPBOARD_COPY")
   owin=otool->GetcurrentWindow()
   if (~OBJ_VALID(oWin)) then $
       return, OBJ_NEW()
   ;; get vector preference
   oGeneral = oTool->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
   oGeneral->GetProperty,CLIPBOARD_OUTPUT_FORMAT=clipVec
   iStatus = oSysCopy->DoWindowCopy( oWin, oWin->getCurrentView(), $
                                     VECTOR=clipVec)
   return, obj_new()
end


;---------------------------------------------------------------------------
function IDLitopClipcopy::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden
    return, 1
end


;---------------------------------------------------------------------------
pro IDLitopClipCopy__define

    compile_opt idl2, hidden

    struc = {IDLitopClipcopy,       $
             inherits IDLitOperation            }
end

