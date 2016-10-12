; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopsetproperty__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSetProperty
;
; PURPOSE:
;   This file implements the operation that is used to set the value
;   of a property. This operation is needed so that property changes
;   can be recorded in the transaction system.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopSetProperty::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopSetProperty::Init
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopSetProperty::Init
;;
;; Purpose:
;; The constructor of the IDLitopSetProperty object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSetProperty::Init,  _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end

;-------------------------------------------------------------------------
;; IDLitopSetProperty::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopSetProperty object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopSetProperty::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end

;;---------------------------------------------------------------------------
;; IDLitopSetProperty::_DoSetProperty
;;
;; Purpose:
;;   Used to set the property on the the target object.
;;
;;   Abstracts out the object-descriptor system.
;;
pro IDLitopSetProperty::_DoSetProperty, oTarget, propID, propValue
  ;; Pragmas
  compile_opt idl2, hidden

  oTarget->SetPropertyByIdentifier, propID, propValue

  ;; Notify our observers that a property has changed.
  ;; idTargets contains the identifier for the component whose prop
  ;; changed.
  self->DoOnNotify, oTarget->GetfullIdentifier(), "SETPROPERTY", propID
end

;;---------------------------------------------------------------------------
;; IDLitopSetProperty::_UndoRedoOperation
;;
;; Purpose:
;;  Internal method to do either Undo or Redo, since the code is almost
;;  identical.
;;
function IDLitopSetProperty::_UndoRedoOperation, oCommandSet, REDO=redo

   compile_opt idl2, hidden

   oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)

  ; Grab either the next property (redo), or the previous (undo).
  strItem = KEYWORD_SET(redo) ? "PROPERTY_NEW" : "PROPERTY_ORIG"

    for i=nObjs-1, 0, -1 do begin
        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget

        oObject = oTool->GetByIdentifier(idTarget)

        if (~obj_valid(oObject)) then $
            continue;

        ; Grab the original property information and set it
        if (oCmds[i]->getItem(strItem, propValue) && $
            oCmds[i]->getItem("PROPERTY_ID", propID))then begin

            self->_DoSetProperty, oObject, propID, propValue
        endif

    endfor

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopSetProperty::UndoOperation
;;
;; Purpose:
;;  Undo the property commands contained in the command set.
;;
function IDLitopSetProperty::UndoOperation, oCommandSet

   compile_opt idl2, hidden

    ; Call our internal method.
    return, self->IDLitopSetProperty::_UndoRedoOperation(oCommandSet)

end


;;---------------------------------------------------------------------------
;; IDLitopSetProperty::RedoOperation
;;
;; Purpose:
;;   Used to execute this operation on the given command set.
;;   Used with redo for the most part.

function IDLitopSetProperty::RedoOperation, oCommandSet

   compile_opt idl2, hidden

    ; Call our internal method.
    return, self->IDLitopSetProperty::_UndoRedoOperation(oCommandSet, /REDO)

end


;;---------------------------------------------------------------------------
;; IDLitopSetProperty::DoAction
;;
;; Purpose:
;;  Used to set a property on a target object.
;;
;; Parameters: (For Now)
;;    oTool       - The tool
;;    idTargets   - List of target objects for the operation.
;;    idProperty  - The id of the property
;;    value       - The new property Value
;;-------------------------------------------------------------------------
function IDLitopSetProperty::DoAction, oTool, idTargets, idProperty, Value, $
    SKIP_MACROHISTORY=skipMacroHistory

   compile_opt idl2, hidden

   ;; Make sure we have a tool.
   if ~obj_valid(oTool) then $
      return, obj_new()

   ; Let my superclass instantiate the command set.
   oCommandSet = self->IDLitOperation::DoAction(oTool)

   ;; For each object set the property.
   for i=0, n_elements(idTargets)-1 do begin
       oTarget = oTool->GetByIdentifier(idTargets[i])
       if (~OBJ_VALID(oTarget)) then $
        goto, failed

        ; Record all of our initial values into the Command set.
        if (~self->RecordInitialValues(oCommandSet, $
            oTarget, idProperty)) then $
            goto, failed

        self->_DoSetProperty, oTarget, idProperty, Value

        ; Find the human-readable name for the first item,
        ; so we can use it for our command set.
        if (i eq 0) then begin
            CATCH, err
            ; If property isn't registered, then quietly catch error.
            if (err ne 0) then begin
                CATCH, /CANCEL
                propertyname = idProperty
            endif else begin
                oTarget->GetPropertyAttribute, idProperty, NAME=propertyname
            endelse
        endif

    endfor

    ; Record all of our final values into the Command set.
    if (~self->RecordFinalValues(oCommandSet, $
        SKIP_MACROHISTORY=skipMacroHistory)) then $
        goto, failed

   ; Set my pretty name.
   oCommandSet->SetProperty, NAME=propertyname

   return, oCommandSet

failed:
    void=self->UndoOperation(oCommandSet)
    obj_destroy,oCommandSet
    return, obj_new()

end


;;-------------------------------------------------------------------------
;; IDLitopSetProperty::DoSetPropertyWith_Extra
;;
;; Purpose:
;;   Will do a undoable setproperty action, using the values contained
;;   in an _extra structure.
;;
;; Prameters:
;;   idTargets      - The ids of the target objects.
;;
;;   _extraValues   - an _extra structure
;;
function IDLitopSetProperty::DoSetPropertyWith_Extra, targets, $
    NO_TRANSACT=noTransact, $
    _EXTRA=_extraValues

   compile_opt idl2, hidden

   if(n_elements(_extraValues) eq 0)then $
      return, obj_new()          ;

    ; Let's make a commmand set for this operation
    if (~KEYWORD_SET(noTransact)) then begin
       oCommandSet = obj_new('IDLitCommandSet', $
            NAME='set property', $
            OPERATION_IDENTIFIER=self->GetFullIdentifier())
    endif else begin
        oCommandSet = obj_new()
    endelse

    isObjref = SIZE(targets, /TYPE) eq 11

    oTool = self->GetTool()

   nTags = n_tags(_extraValues)
   strTags = tag_names(_extraValues)

   ;; For each object set the property.
   for i=0, N_ELEMENTS(targets)-1 do begin
       oTarget = isObjref ? targets[i] : oTool->GetByIdentifier(targets[i])
       if (~OBJ_VALID(oTarget)) then begin
            if (OBJ_VALID(oCommandSet)) then begin
               void=self->UndoOperation(oCommandSet);
               obj_destroy, oCommandSet
            endif
           return, obj_new()
       endif

        ; Record all of our initial values into the Command set.
        ; Do this before setting any properties, in case these affect
        ; the other values. This assumes that setting properties on
        ; one oTarget doesn't affect the props on the other targets.
        if (OBJ_VALID(oCommandSet)) then begin
            for iTag = 0, nTags-1 do begin
                if (~self->RecordInitialValues(oCommandSet, $
                    oTarget, strTags[iTag])) then $
                    continue
            endfor
        endif

       ; Set the property on the target object
       for iTag = 0, nTags-1 do begin
            self->_DoSetProperty, oTarget, strTags[iTag], _extraValues.(iTag)
       endfor

   endfor                       ; target items

    ; Record all of our final values into the Command set.
    if (OBJ_VALID(oCommandSet)) then begin
        void = self->RecordFinalValues(oCommandSet, /SKIP_MACROHISTORY)
    endif

   return, oCommandSet
end


;;---------------------------------------------------------------------------
;; IDLitopSetProperty::RecordInitialValues
;;
;; Purpose:
;;   This routine is used to record the initial property values of the
;;   items provided.
;;
function IDLitopSetProperty::RecordInitialValues, oCommandSet, oTargets, $
                           idProperty

   compile_opt idl2, hidden

   ;; Okay, just loop through and record the current values in the
   ;; the target objects.
   for i=0, n_elements(oTargets)-1 do begin

       if (not OBJ_VALID(oTargets[i])) then $
            continue

        ; For aggregated items such as Groups and Multiple selection,
        ; that use property intersection,
        ; we need to record the initial property value for each
        ; of the grouped items as well as the Group itself.
        ; Otherwise Undo will reset all of the grouped items to the
        ; same property value (usually the first item's value).
        ;
        ; We assume that objects (such as IDLitVisPolygon) which use
        ; union aggregation are assumed to contain only one child
        ; that implements a particular property, and hence we only
        ; need to record the property on the IDLitVisPolygon itself.
        ;
        if (OBJ_ISA(oTargets[i], '_IDLitPropertyAggregate') && $
            oTargets[i]->IsAggregateIntersection()) then begin

            oAgg = oTargets[i]->GetAggregate(/ALL)
            ; Recursively get our original property values.
            ; We don't care if this property doesn't exist,
            ; so ignore the return value.
            dummy = self->RecordInitialValues(oCommandSet, $
                oAgg, idProperty)

        endif  ; Property intersection


       ; Now get my own property value and record it.

       iStatus = oTargets[i]->GetPropertyByIdentifier(idProperty, oldValue)

       if(iStatus eq 0)then $
         return, 0

       ; Do not cache pointers or objrefs since these will get automatically
       ; destroyed if the command set is destroyed.
       type = SIZE(oldValue, /TYPE)
       if ((type eq 10) || (type eq 11)) then $
            return, 0


       oCmd = obj_new('IDLitCommand', TARGET_IDENTIFIER= $
                      oTargets[i]->GetFullIdentifier())

       ;; Add the values to the command object.
       iStatus = oCmd->AddItem("PROPERTY_ID", idProperty)
       iStatus = oCmd->AddItem("PROPERTY_ORIG", oldValue)
       oCommandSet->Add, oCmd

   endfor

   return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopSetProperty::RecordFinalValues
;;
;; Purpose:
;;   This routine is used to record the final property values of the
;;   items provided.
;;
; Keywords:
;   NOTIFY: If set, then call DoOnNotify for each property that changed.
;
function IDLitopSetProperty::RecordFinalValues, oCommandSet, oTargets, $
                           idPropertyIgnore, NOTIFY=notify, $
                           SKIP_MACROHISTORY=skipMacroHistory

   compile_opt idl2, hidden
    
    catch, err
    if (err ne 0) then return, 0
    
    oTool = self->GetTool()

    if (~OBJ_VALID(oTool)) then $
        return, 0

    if (~OBJ_VALID(oCommandSet)) then $
        return, 0

    doNotify = KEYWORD_SET(notify)

    ; Retrieve all our command objects. We are assuming that these
    ; are all SetProperty command objects. We should probably check.
    oCmds = oCommandSet->Get(/ALL, count=nObjs)

    for i=nObjs-1, 0, -1 do begin

        if (~oCmds[i]->GetItem('PROPERTY_ID', idProperty)) then $
            return, 0

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget

        oTarget = oTool->GetByIdentifier(idTarget)
        if (not obj_valid(oTarget)) then $
            continue

        ; Retrieve the new value.
        ; Should it return failure or just continue?
        if (~oTarget->GetPropertyByIdentifier(idProperty, newValue)) then $
            return, 0

        ; Retrieve the original value from our command set.
        ; For efficiency we check if the value was actually changed.
        ; If it was then we add the new value to the command object.
        ; If it didn't change then we remove this command object.
        ;
        ; This efficiency is important for grouping and multiple
        ; selection, where you may be setting a property
        ; on the Group itself rather than its aggregated children.
        ;
        ; For example, if you set the NAME property on the
        ; Group, the code in ::RecordInitialValues will recursively
        ; descend to all the aggregated children and cache the
        ; original NAME for each. Of course the name is only changed
        ; on the Group, so all the children's names are unchanged
        ; and it is wasteful to reset all these on an Undo/Redo.
        ;
        if (~oCmds[i]->GetItem('PROPERTY_ORIG', origValue)) then $
            return, 0

        nNew = N_ELEMENTS(newValue)
        nOrig = N_ELEMENTS(origValue)
        type = SIZE(origValue, /TYPE)
        ; If we have a scalar NaN, see if the other value is also NaN.
        if (nNew eq 1 && nOrig eq 1 && $
            (type eq 4 || type eq 5) && FINITE(origValue, /NAN)) then begin
                ; If new value isn't NaN then it changed.
                changed = ~FINITE(newValue, /NAN)
        endif else begin
            ; ARRAY_EQUAL will compare scalars to arrays, but we want
            ; to flag a change if the # of elements changed.
            changed = (nNew eq nOrig) ? $
                ~ARRAY_EQUAL(origValue, newValue, /NO_TYPECONV) : 1b
        endelse

        ; If the value has changed then add the new item.
        if (changed) then begin
            ; Add the values to the command object.
            iStatus = oCmds[i]->AddItem("PROPERTY_NEW", newValue)

            if (doNotify) then $
                self->DoOnNotify, idTarget, "SETPROPERTY", idProperty

           oSrvMacro = oTool->GetService('MACROS')
           ; don't record property setting on objdesc such as an operation
           ; the operation, with the desired property, will be recorded.
           ; this also filters out property settings made to a macro item
           ; in the editor, which should not be added to history.
           ; In addition, filter out property settings made from
           ; doSetPropertyWith_Extra which are settings made on a newly
           ; created visualization.  We only need the resulting visualization
           ; in history or macros.
           if ~obj_isa(oTarget, 'IDLitObjDescTool') && $
               ~obj_isa(oTarget, 'IDLitContainer') && $
               ~keyword_set(skipMacroHistory) && $
               OBJ_VALID(oSrvMacro) then begin
               ; expose this property in the macro property sheet only
               ; necessary to show props such as transform, even if they
               ; can't be modified, it helps to show what is in the
               ; setproperty macro item.
               oTarget->GetPropertyAttribute, idProperty, HIDE=hide
               oTarget->SetPropertyAttribute, idProperty, HIDE=0
               oSrvMacro->GetProperty, CURRENT_NAME=currentName
               oSrvMacro->PasteMacroSetProperty, oTarget, currentName, idResult, idProperty
               oTarget->SetPropertyAttribute, idProperty, HIDE=hide
           endif
        endif else begin
            ; If the value didn't change,
            ; remove and destroy the command object.
            oCommandSet->Remove, oCmds[i]
            OBJ_DESTROY, oCmds[i]
        endelse

    endfor

    ; Return TRUE if we still have some valid command objects
    ; in our container. Some of them may have been removed if
    ; their SetProperty value didn't change.
    return, (oCommandSet->Count() gt 0)

end

;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
pro IDLitopSetProperty__define

    compile_opt idl2, hidden

    struc = {IDLitopSetProperty,       $
             inherits IDLitOperation $
            }
end

