; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopinsertvis__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertVis
;
; PURPOSE:
;   Simple operation used to launch the insert vis dialog
;
; CATEGORY:
;   IDL Tools
;
;;---------------------------------------------------------------------------
;; IDLitopInsertVis::Init
;;
;; Purpose:
;;;  object constructor
;;
function IDLitopInsertVis::Init, _EXTRA=_EXTRA
   compile_opt hidden, idl2

   if(self->IDLitOperation::Init(_eXTRA=_EXTRA, $
                                /SKIP_MACRO, $
                                TYPES="") eq 0)then $
     return, 0

   self._pNames = ptr_new('')
   self._pValues = ptr_new('')

   self->RegisterProperty, 'PARAMETER_NAMES', USERDEF='', $
       NAME='Parameter names', $
       DESCRIPTION='Parameter names'
   self->RegisterProperty, 'DATA_IDS', USERDEF='', $
       NAME='Data identifiers', $
       DESCRIPTION='Data identifiers'
   self->RegisterProperty, 'VISUALIZATION_ID', /STRING, $
       NAME='Visualization ID', $
       DESCRIPTION='Visualization ID'

   self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitopInsertVis::Cleanup
;;
;; Purpose:
;;   Destructor for this class

PRO IDLitopInsertVis::Cleanup
   compile_opt hidden, idl2

   ptr_free, self._pNames
   ptr_free, self._pValues
   self->IDLitOperation::Cleanup
end
;;-------------------------------------------------------------------------
;; IDLitopInsertVis::_CreateVisualization
;;
;; Purpose:
;;    Used to apply any changes resulting from the insert vis
;;    dialog, calling the create vis service.
;;
;; Return Value:
;;    Command set created.
;;
function IDLitopInsertVis::_CreateVisualization
  compile_opt hidden, idl2

   nNames = n_elements(*self._pNames)
   if(nNames eq 0)then return, obj_new()
   oTool = self->GetTool()

   oCV = oTool->GetService("CREATE_VISUALIZATION")
   if(not obj_valid(oCV))then return, obj_new()

   ;; For a good presentation, get some information on the vis we are
   ;; creating
   vDesc = oTool->GetByIdentifier(self._idVis)
   ;; try again in case the vis id is just the name and not the full
   ;; identifier
   IF ~obj_valid(vDesc) THEN $
     vDesc = oTool->GetVisualization(self._idVis)
   if (~obj_valid(vDesc)) then $
        return, obj_new()
   vDesc->getProperty, name=name, icon=icon

   ;; Okay, loop through and see if the set values are different from
   ;; the existing settings. If so, set the new parameter
   oPSet = obj_new("IDLitParameterSet", name=name + " Parameters", icon=icon)
   for i=0, nNames-1 do begin
       ;; Does the parameter set contain the given parameter?
       if(keyword_set((*self._pValues)[i]))then begin ;; name parameter
           oItem = oTool->GetByIdentifier((*self._pValues)[i])
           if(obj_valid(oItem))then $
             oPSet->Add, oItem, parameter_name=(*self._pNames)[i], /preserve_location
       endif
   endfor

   success = oCV->CreateVisualization(oPSet, self._idVis)
   ;; no need to add to data manager as all items have to be from the
   ;; data manager originally
   oPSet->Remove,/ALL
   obj_destroy,oPSet

   return,success

end

;---------------------------------------------------------------------------
pro IDLitopInsertVis::GetProperty, $
    PARAMETER_NAMES=parameterNames, $
    DATA_IDS=dataIDS, $
    VISUALIZATION_ID=visualizationID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(parameterNames) then $
        parameterNames = *self._pNames

    if ARG_PRESENT(dataIDS) then $
        dataIDS = *self._pValues

    if ARG_PRESENT(visualizationID) then $
        visualizationID = self._idVis

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::GetProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
pro IDLitopInsertVis::SetProperty, $
    PARAMETER_NAMES=parameterNames, $
    DATA_IDS=dataIDS, $
    VISUALIZATION_ID=visualizationID, $
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

    if (N_ELEMENTS(visualizationID) gt 0) then $
        self._idVis = visualizationID

   if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::SetProperty, _EXTRA=_extra
    endif

end


;;-------------------------------------------------------------------------
;; IDLitopInsertVis::DoAction
;;
;; Purpose:
;;   Will cause an insert vis interaction to take place and be
;;   applied
;;
;; Parameters:
;;    oTool   - This tool
;;
;; Return Value:
;;    - Resulting command set.
;;
function IDLitopInsertVis::DoAction, oTool
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !ERROR_STATE.msg], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
  endif

  self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI

  ; show is usually false when operation run by macro
  if (showExecutionUI) then begin
    if (~oTool->DoUIService('/InsertVisualization', self)) then $
        return, OBJ_NEW()
  endif

  return, self->_CreateVisualization()

end

;;-------------------------------------------------------------------------
;; IDLitopInsertVis__define
;;
;; Purpose:
;;    When called, it defines the object for the system.
;;
pro IDLitopInsertVis__define
  compile_opt idl2, hidden

  struc = {IDLitopInsertVis,           $
           inherits IDLitOperation, $
           _idVis   : '',           $ ;; the vis to create
           _pNames  : ptr_new(),    $ ;; stash of names
           _pValues : ptr_new()     $ ;; stash of ids
          }
END
