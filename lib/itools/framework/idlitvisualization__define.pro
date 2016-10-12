; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisualization__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisualization
;
; PURPOSE:
;   This class represents a collection of graphics and/or other
;   visualizations that as a group serve as a visual
;   representation for data.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisualization::Init
;
; PURPOSE:
;   This function method initializes the component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitVisualization')
;
;    or
;
;   Obj->[IDLitVisualization::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses. In addtion, the following keywords
;   are supported:
;
;   TOOL:   Set this keyword to a reference to the IDLitTool
;     object with which this visualization is to be associated.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function IDLitVisualization::Init, $
                           _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    if(( self->_IDLitVisualization::Init(/REGISTER_PROPERTIES, $
        _EXTRA=_extra, /SELECT_TARGET) ne 1) OR $
       (self->IDLitParameter::Init() ne 1)) then $
      RETURN, 0

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisualization::Cleanup
;
; PURPOSE:
;      This procedure method preforms all cleanup on the object.
;
;      NOTE: Cleanup methods are special lifecycle methods, and as such
;      cannot be called outside the context of object destruction.  This
;      means that in most cases, you cannot call the Cleanup method
;      directly.  There is one exception to this rule: If you write
;      your own subclass of this class, you can call the Cleanup method
;      from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[IDLitVisualization::]Cleanup
;
;-
pro IDLitVisualization::Cleanup

    compile_opt idl2, hidden

    ;; Call our super-class
    self->IDLitParameter::Cleanup
    self->_IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; Visualization Interface
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitVisualization::GetTypes
;;
;; Purpose:
;;   Override the _Vis method and tack on a "VISUALIZATION" type.
;;

function IDLitVisualization::GetTypes

    ;; Pragmas
    compile_opt idl2, hidden

    return, ['VISUALIZATION', self->_IDLitVisualization::GetTypes()]

end


;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisualization::OnDataChange
;
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisualization::]OnDataChange, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro IDLitVisualization::OnDataChange, oSubject

    compile_opt idl2, hidden
    ;; If this object is in a "deleted" state, skip any updates. This
    ;; is needed since a delete object can still be "alive" (see undo-redo)
    if(self._bIsDeleted)then return
    ;; Just pass to our super-classes
    self->IDLitParameter::OnDataChange, oSubject ;; notify data
    self->_IDLitVisualization::OnDataChange, oSubject ;; Handle draw loop
end
;;---------------------------------------------------------------------------
;; IDLitVisualization::OnNotify
;;
;; Purpose:
;;    Override the OnNotify method to allow the delete messages to be
;;    trapped. This is needed to put the object in a "deleted state",
;;    in which it ignores data update messages.
;;
;; Parameters
;;    id - source id
;;    message - the message
;;    data  - the message data
;;
pro IDLitVisualization::OnNotify, id, message, data
    compile_opt hidden, idl2

    if(message eq 'DELETE')then $
      self._bIsDeleted = 1 $
    else if(message eq 'UNDELETE')then $
      self._bIsDeleted = 0
    self->_idlitVisualization::OnNotify, id, message,data
end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisualization::OnDataComplete
;
; PURPOSE:
;   This procedure method handles notification that the data change
;   ins complete.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisualization::]OnDataComplete, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro IDLitVisualization::OnDataComplete, oSubject

    compile_opt idl2, hidden

    ;; If this object is in a "deleted" state, skip any updates. This
    ;; is needed since a delete object can still be "alive" (see undo-redo)
    if(self._bIsDeleted)then return

    ;; Just pass to our super-classes
    self->IDLitParameter::OnDataComplete, oSubject ;; notify data
    self->_IDLitVisualization::OnDataComplete, oSubject ;; Handle draw loop
end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisualization::OnDataDelete
;
; PURPOSE:
;   This procedure method handles notification that the data has been deleted
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisualization::]OnDataDelete, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data is being deleted.
;-
pro IDLitVisualization::OnDataDelete, oSubject
    compile_opt idl2, hidden
    ;; If this object is in a "deleted" state, skip any updates. This
    ;; is needed since a delete object can still be "alive" (see undo-redo)
    if(self._bIsDeleted)then return
    ;; Just pass to our super-classes
    self->IDLitParameter::OnDataDelete, oSubject ;; notify data
    self->_IDLitVisualization::OnDataDelete, oSubject ;; Handle draw loop
end
;;----------------------------------------------------------------------------
;; IDLitVisualization::SetParameterSet
;;
;; Purpose:
;;   Method used to seta parameter set on the visualization. This
;;   overrides the method on the IDLitParameter superclass, allowing
;;   the visualization to be updated after the prameters have been
;;   updated.
;;
;; Parameters:
;;     oParamSet     - The parameter set being set. If this set
;;                     conains no elements nothing is done.
;;
;; Return Value:
;;     1 - Ok
;;     0 - Error in the set. No parameters were associated
;;
function IDLitVisualization::SetParameterSet, oParamSet, NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    status = self->IDLitParameter::SetParameterSet(oParamSet)
    ;; If successful, update the vis tree
    if(status eq 1 && ~KEYWORD_SET(noNotify))then begin
        self->_IDLitVisualization::OnDataChange, self
        self->_IDLitVisualization::OnDataComplete, self
        ;; Send a notification message to update UI.
        self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
    endif
    return, status
end

;----------------------------------------------------------------------------
; Purpose:
;   This method is used to store information needed to prepare for pasting to a
;   different layer or dataspace.
;   This should be implemented by the subclass.
;
function IDLitVisualization::DoPreCopy, _EXTRA=_extra
  compile_opt idl2, hidden
  ;; Do nothing
  return, 0
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to process information after a paste, possibly 
;   converting data if the layer has changed.
;   This should be implemented by the subclass.
;
function IDLitVisualization::DoPostPaste, _EXTRA=_extra
  compile_opt idl2, hidden
  ;; Do nothing
  return, 0
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve data.
;   This should be implemented by the subclass.
;
pro IDLitVisualization::GetData, arg1, arg2, arg3, arg4, arg5, arg6, arg7, $
                                 _EXTRA=_extra
  compile_opt idl2, hidden
  ;; Do nothing
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set data.
;   This should be implemented by the subclass.
;
pro IDLitVisualization::PutData, arg1, arg2, arg3, arg4, arg5, arg6, arg7, $
                                 _EXTRA=_extra
  compile_opt idl2, hidden
  ;; Do nothing
end


;;---------------------------------------------------------------------------
;; IDLitVisualization::SetData
;;
;; Purpose:
;;   Overrides the method of the IDLitParameter of it's superclass so
;;   an update can be triggered when called.
;;
;; Parameters:
;;   oData - The data object to set in the visualization
;;
;; Keywords:
;;   These are all passed to the superclass.

function IDLitVisualization::SetData, oData, _extra=_extra

    compile_opt idl2, hidden
    status = self->IDLitParameter::SetData(oData, _extra=_extra)
    ;; If successful, update the vis tree
    if(status eq 1)then begin
        self->_IDLitVisualization::OnDataChange, self
        self->_IDLitVisualization::OnDataComplete, self
        ;; Send a notification message to update UI
        self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
    endif
    return, status
end
;;---------------------------------------------------------------------------
;; IDLitVisualization::UnsetParameter
;;
;; Purpose:
;;   Overrides the method of the IDLitParameter of it's superclass so
;;   an update can be triggered when called.
;;
;; Parameters:
;;   parmName - Name of the parameter to unset
;;
pro IDLitVisualization::UnsetParameter, parmName, _REF_EXTRA=_extra

    compile_opt idl2, hidden
    self->IDLitParameter::UnsetParameter, parmName, _EXTRA=_extra
    ;; If successful, update the vis tree
    self->_IDLitVisualization::OnDataChange, self
    self->_IDLitVisualization::OnDataComplete, self
    ;; Send a notification message to update UI
    self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
end
;;---------------------------------------------------------------------------
;; IDLitVisualization::GetbyIdentifier
;;
;; Purpose:
;;  This overrides the standard mehtod provided by _IDLitContainer,
;;  allowing access to items contained in the parameter set of the
;;  visualization. Most of this implementation is a modification of
;;  the standard functionatly, with the full path identification
;;  mission.
;;
;; Parameters:
;;   strInput - The path to continue to search.
;;
;; Return Value:
;;   - The target object or obj_new() if nothing was found.,
;;
function IDLitVisualization::GetByIdentifier, strInput
   ;; Pragmas
   compile_opt idl2, hidden

   strInTmp = strInput[0]
   IF strInTmp EQ '' THEN return, obj_new()
   ;; Absolute Path?

   strID = strInTmp
   strItem  = IDLitBasename(strID, remainder=strRemain,/reverse)

   if(strItem eq '')then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:Framework:ErrorParsingId') +strID, SEVERITY=1
       return, obj_new()
   endif

   ;; Merge the parameter set onto the target item list.
   oItems = self->Get(/ALL, COUNT=nItems)
   oPS = self->getParameterSet()
   if(nItems gt 0)then begin
       nItems ++
       oItems = [oItems, oPS]
   endif else begin
       nItems=1
       oItems=oPS
   endelse
   for i=0, nItems-1 do begin
       if(not obj_valid(oItems[i]))then $
           continue
       oItems[i]->IDLitComponent::GetProperty, IDENTIFIER=strTmp
       if(strcmp(strItem, strTmp, /fold_case) ne 0)then begin
           ;; If more information exists in the path and the
           ;; object isa container traverse down
           if(strRemain eq '')then $
             return, oItems[i] $
           else if( obj_isa(oItems[i], "_IDLitContainer"))then $
             return, oItems[i]->GetByIdentifier(strRemain)
           break ;; if we are here, this will case a null retval
       endif
   endfor
   return, obj_new()
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisualization__Define
;
; PURPOSE:
;   Defines the object structure for an IDLitVisualization object.
;-
pro IDLitVisualization__Define

    compile_opt idl2, hidden

    struct = { IDLitVisualization, $
               inherits _IDLitVisualization, $
               inherits IDLitParameter, $
               _bIsDeleted : 0b $
             }
end
