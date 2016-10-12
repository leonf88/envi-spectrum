; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopeditparameters__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopEditParameters
;
; PURPOSE:
;   Simple operation used to launch the parameter editor
;
; CATEGORY:
;   IDL Tools
;
;;---------------------------------------------------------------------------
;; IDLitopEditParameters::Init
;;
;; Purpose:
;;;  object constructor
;;
function IDLitopEditParameters::Init, _EXTRA=_EXTRA
   compile_opt hidden, idl2

   if(self->IDLitOperation::Init(_EXTRA=_EXTRA, $
                                /SKIP_MACRO, $
                                TYPES="VISUALIZATION", $
                                NUMBER_DS='1') eq 0)then $
     return, 0

   self._pNames = ptr_new('')
   self._pValues = ptr_new('')

   self->RegisterProperty, 'PARAMETER_NAMES', USERDEF='', $
       NAME='Parameter names', $
       DESCRIPTION='Parameter names'
   self->RegisterProperty, 'DATA_IDS', USERDEF='', $
       NAME='Data identifiers', $
       DESCRIPTION='Data identifiers'

   self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitopEditParameters::Cleanup
;;
;; Purpose:
;;   Destructor for this class

PRO IDLitopEditParameters::Cleanup
   compile_opt hidden, idl2

   self->IDLitOperation::Cleanup
   ptr_free, self._pNames
   ptr_free, self._pValues
end
;;-------------------------------------------------------------------------
;; IDLitopEditParameters::_ApplyEditedValues
;;
;; Purpose:
;;    Used to apply any changes resulting from the parameter
;;    editor. This will check for changes and use the set parameter
;;    services to apply changes.
;;
;; Return Value:
;;    Command set created.
;;
function IDLitopEditParameters::_ApplyEditedValues
  compile_opt hidden, idl2

   nNames = n_elements(*self._pNames)
   if(nNames eq 0)then return, obj_new()
   oTool = self->GetTool()

   ;; Get the set parameter service
   oSetParm = oTool->GetService("SET_PARAMETER")
   if(not obj_valid(oSetParm))then return, obj_new()

   ;; Okay, loop through and see if the set values are different from
   ;; the existing settings. If so, set the new parameter

   oPSet = self._oTarget->GetParameterSet()
   for i=0, nNames-1 do begin
       ;; Does the parameter set contain the given parameter?
       if(keyword_set((*self._pNames)[i]))then begin ;; named parameter
           bSet=0
           oItem = oPSet->GetByName((*self._pNames)[i], count=valid)
           if(valid gt 0)then begin
               ;; Is the data different?
               idItem = oItem[0]->GetFullIdentifier()
               if(strcmp((*self._pValues)[i],idItem, /fold_case) eq 0)then $
                 bSet=1
           endif else if(keyword_set((*self._pValues)[i]))then $ ;; new data
                         bSet=1
           ;; Use this new value?
           if(bSet eq 1)then begin
               okNames = (n_elements(okNames) gt 0 ? $
                          [okNames, (*self._pNames)[i]] : $
                          (*self._pNames)[i])
               okValues = (n_elements(okValues) gt 0 ? $
                           [okValues, (*self._pValues)[i]] : $
                           (*self._pValues)[i])
           endif
       endif
   endfor

   ;; okay, now just set the parameters
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
   oReturn = (n_elements(okNames) gt 0 ? $
              oSetParm->SetParameter( self._oTarget, okNames, okValues) : $
              obj_new())
   IF (~previouslyDisabled) THEN $
     oTool->EnableUpdates
   return, oReturn
end


;---------------------------------------------------------------------------
pro IDLitopEditParameters::GetProperty, $
    PARAMETER_NAMES=parameterNames, $
    DATA_IDS=dataIDS, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(parameterNames) then $
        parameterNames = *self._pNames

    if ARG_PRESENT(dataIDS) then $
        dataIDS = *self._pValues

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::GetProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
pro IDLitopEditParameters::SetProperty, $
    PARAMETER_NAMES=parameterNames, $
    DATA_IDS=dataIDS, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(parameterNames) gt 0) then begin
        ptr_free, self._pNames
        self._pNames = ptr_new(parameterNames)
    endif

    if (N_ELEMENTS(dataIDS) gt 0) then begin
        ptr_free, self._pValues
        self._pValues = ptr_new(dataIDS)
    endif

   if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::SetProperty, _EXTRA=_extra
    endif

end

;;-------------------------------------------------------------------------
;; IDLitopEditParameters::DoAction
;;
;; Purpose:
;;   Will cause an edit parameters interaction to take place and be
;;   applied
;;
;; Parameters:
;;    oTool   - This tool
;;
;; Return Value:
;;    - Resulting command set.
;;
function IDLitopEditParameters::DoAction, oTool
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
      catch, /cancel
      return, obj_new()
  endif

  self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI

  ; show can be false when operation run by macro
  status= showExecutionUI ? oTool->DoUIService('/EditParameters', self) : 1
  if ~showExecutionUI then void = self->GetTarget()

  oCmds = (status ne 0 ? self->_ApplyEditedValues() : obj_new())

  self._otarget=obj_new()

  return, oCmds

end
;;---------------------------------------------------------------------------
;; IDLitopEditParameters::GetTarget
;;
;; Purpose:
;;   Called to get the target for this action. Primarly used by the UI
;;
;; Parameters:
;;   None.
;;
;; Return Value
;;   - The object that implements the IDLitParameter interface
;;     or obj null
;;
function IDLitopEditParameters::GetTarget
  compile_opt hidden, idl2

  oTool = self->GetTool()
  oSel = oTool->getSelectedItems(count=nItems)
  self._otarget = (nItems gt 0 ? oSel[0] : obj_new())
  ;; pretty simple.
  return, self._otarget
end

;;-------------------------------------------------------------------------
;; IDLitopEditParameters__define
;;
;; Purpose:
;;    When called, it defines the object for the system.
;;
pro IDLitopEditParameters__define
  compile_opt idl2, hidden

  struc = {IDLitopEditParameters,           $
           inherits IDLitOperation, $
           _pNames  : ptr_new(),    $ ;; stash of names
           _pValues : ptr_new(),    $ ;; stash of ids
           _oTarget : obj_new()     $ ;; edit target
          }
END
