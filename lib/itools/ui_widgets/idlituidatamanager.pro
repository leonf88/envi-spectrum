;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituidatamanager.pro#1 $
;; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;+
;; NAME:
;;   IDLitUIDataManager
;;
;; PURPOSE:
;;   This function implements the user interface for the data manager,
;;   paramater editor, and insert visualization dialogs.
;;
;; CALLING SEQUENCE:
;;   Result = IDLitUIDataManager(UI, Requester)
;;
;; INPUTS:
;;   oUI - object
;;
;;   oRequester - Set this argument to the object reference for the caller.
;;
;; KEYWORD PARAMETERS:
;;   NONE
;;
;; MODIFICATION HISTORY:
;;   Written by:  AGEH, RSI, Mar 2004
;;   Modified:
;;
;-------------------------------------------------------------------------
FUNCTION IDLitUIDataManager, oUI, oRequestor
  compile_opt idl2, hidden

  isEditParams = obj_isa(oRequestor,'IDLitOpEditParameters')
  isInsertVis = obj_isa(oRequestor,'IDLitOpInsertVis')

  IF isEditParams THEN $
    oValue = oRequestor->GetTarget()

  IF isInsertVis THEN $
    oValue = (((oUI->GetTool())->_GetCurrentTool())->GetSelectedItems())[0]

  return, IDLitwdDataManager(oUI, oRequestor, $
                             PARAMETER_EDITOR=isEditParams, $
                             INSERT_VISUALIZATION=isInsertVis, $
                             VALUE=oValue)

END
