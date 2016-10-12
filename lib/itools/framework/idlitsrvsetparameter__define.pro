; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvsetparameter__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; CLASS_NAME:
;   IDLitsrvSetParameter
;
; PURPOSE:
;   This file implements the operation object that is used to
;   set parameters on a target object and record this in an undo-buffer
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitsrvSetParameter::Init
;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvSetParameter::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvSetParameter object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitsrvSetParameter::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
;pro IDLitsrvSetParameter::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;;---------------------------------------------------------------------------
;; IDLitsrvSetParameter::UndoOperation
;;
;; Purpose:
;;  Undo the commands contained in the command set.
;;  This will rest a parameter to it's original value
;;
;; Parameters:
;;   oCommandSet - Contains the undo-redo info
;;
;; Return Value:
;     0 - Error
;     1 - Success

function IDLitsrvSetParameter::UndoOperation, oCommandSet
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
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
      oTarget = oTool->GetByIdentifier(idTarget)
      if (not obj_valid(oTarget)) then $
        continue
      ;; The parameter
      iStatus = oCmds[i]->GetItem("PARAMETER", parameter)
      if(iStatus eq 0)then begin
          self->ErrorMessage, IDLitLangCatQuery('Error:InvalidRedoParameter:Text'), $
            title=IDLitLangCatQuery('Error:InvalidParameter:Title'), SEVERITY=2
          continue              ;
      endif
      ;; Get our redo data.
      iDataStatus = oCmds[i]->getItem("OLD_DATA_ID", idData)
      if(iDataStatus gt 0)then begin
          oData = oTool->GetByIdentifier(idData)

          if(not obj_valid(oData))then begin
              self->ErrorMessage, IDLitLangCatQuery('Error:InvalidDataRef:Text'), $
                title=IDLitLangCatQuery('Error:InvalidData:Title'), SEVERITY=2
              continue          ;
          endif
          ;; Reset the autodelete mode on the old data if needed.
          iStatus = oCmds[i]->getItem("AUTO_DATA_DELETE", bDelete)
          if(iStatus && bDelete)then begin
              if(obj_isa(oData, "IDLitDataContainer"))then $
                oData->SetAutoDeleteMode, 1 $
              else if(obj_isa(oData, "IDLitData"))then $
                oData->SetProperty, AUTO_DELETE=1
          endif
          ;; Set the parameter
          iStatus = oTarget->SetData(oData, parameter_name=parameter)

      endif else $ ;; unset the parameter
        oTarget->UnsetParameter, parameter
  endfor
  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitsrvSetParameter::RedoOperation
;;
;; Purpose:
;;   Used to redo this operation on the given command set.
;;
;; Parameters:
;;   oCommandSet   - The command set that holds the recorded
;;                   information.
;;
;; Return Value
;;   0 - Error
;;   1 - Success
;;
function IDLitsrvSetParameter::RedoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)
  for i=nObjs-1, 0, -1 do begin

      if (OBJ_ISA(oCmds[i], 'IDLitCommandSet')) then begin
        dummy = self->RedoOperation(oCmds[i])
        continue
      endif

      ;; Get the target
      oCmds[i]->getProperty, target_identifier=idTarget
      oTarget = oTool->GetByIdentifier(idTarget)
      if(not obj_valid(oTarget))then $
        continue;

      ;; The parameter
      iStatus = oCmds[i]->GetItem("PARAMETER", parameter)
      if(iStatus eq 0)then begin
          self->ErrorMessage, IDLitLangCatQuery('Error:InvalidRedoParameter:Text'), $
            title=IDLitLangCatQuery('Error:InvalidParameter:Title'), SEVERITY=2
          continue              ;
      endif
      ;; Get our original data and check auto delete
      iDataStatus = oCmds[i]->getItem("OLD_DATA_ID", idData)
      if(iDataStatus gt 0)then begin
          oData = oTool->GetByIdentifier(idData)

          if(obj_valid(oData))then begin
              ;; Reset the autodelete mode on the old data if needed.
              ;; if not done, the old data will destroy itself and
              ;; undo will fail
              iStatus = oCmds[i]->getItem("AUTO_DATA_DELETE", bDelete)
              if(iStatus && bDelete)then begin
                  if(obj_isa(oData, "IDLitDataContainer"))then $
                    oData->SetAutoDeleteMode, 0 $
                  else if(obj_isa(oData, "IDLitData"))then $
                    oData->SetProperty, AUTO_DELETE=0
              endif
          endif
      endif
      ;; Get our redo data.
      iDataStatus = oCmds[i]->getItem("NEW_DATA_ID", idData)
      if(iDataStatus gt 0)then begin
          oData = oTool->GetByIdentifier(idData)

          if(not obj_valid(oData))then begin
              self->ErrorMessage, IDLitLangCatQuery('Error:InvalidRedoData:Text'), $
                title=IDLitLangCatQuery('Error:InvalidData:Title'), SEVERITY=2
              continue          ;
          endif
          ;; Set the parameter
          iStatus = oTarget->SetData(oData, parameter_name=parameter)

      endif else $ ;; unset the parameter
        oTarget->UnsetParameter, parameter
  endfor

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitsrvSetParameter::_GetandCheckObject, Objects
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
;;    NO_CHECK - Skip the check proces
;;
;; Return Value:
;;
;;  Success - The list of objects
;;
;;  Failure - NULL and count returns 0
;;
function IDLitsrvSetParameter::_GetandCheckObjects, Objects, $
                             strClass, COUNT=nObjs, no_check=no_check
   compile_opt hidden, idl2

   oTool = self->GetTool()
   nObjs = n_elements(Objects)
   ;; Get the proper data
   iType = size(objects[0], /type)
   case iType of
       7: begin
           oObjs = objarr(nObjs)
           for i=0, nObjs-1 do $
              oObjs[i] = oTool->GetByIdentifier(Objects[i])
       end
       11: oObjs = Objects
       else: oData = obj_new()
   endcase
   if(keyword_set(no_check))then $
       return, oObjs

   ;; Validate
   void = where(obj_isa(oObjs, strClass), nValid, $
                complement=iComp, ncomplement=nComp)
   if(nValid ne nObjs)then begin
       case iType of
           7:  msg = IDLitLangCatQuery('Error:Framework:InvalidId') + $
               (nComp gt 0 ? Objects[iComp[0]] : "<Unknown>")+"""."
           11: msg = IDLitLangCatQuery('Error:Framework:InvalidDescObj')
           else: msg = IDLitLangCatQuery('Error:Framework:IncorrectObjDesc')
       endcase
       self->SignalError, msg + IDLitLangCatQuery('Error:Framework:UnableToSetParam'), $
             SEVERITY=1
       nObjs = 0
       return, obj_new()
   endif
   return, oObjs

end

;;---------------------------------------------------------------------------
;; IDLitsrvSetParameter::SetParameter
;;
;; Purpose:
;;   This service is called to set the value of a parameter on an
;;   object that implements the parameter interface (IDLitParameter)
;;
;; Parameters
;;
;;   target    - the object or id of the target object
;;
;;   parameter - The parameter to set. This can be a scalar or an array
;;
;;   data      - The data object or id for the data to be set. If an
;;               empty string, the parameter is "unset". This should
;;               be the same size as parameter.

function IDLitsrvSetParameter::SetParameter, target, parameter, data

   compile_opt idl2, hidden

   oTarget = self->_GetAndCheckObjects(target, "IDLitParameter", $
                                       count=count)
   if(count eq 0)then begin
       self->SignalError, $
         [IDLitLangCatQuery('Error:Framework:InvalidTargetRef'), $
      IDLitLangCatQuery('Error:Framework:UnableToSetParam') ], $
         SEVERITY=1
       return, obj_new()
   endif
   ;; Do we have any data?
   oData = self->_GetAndCheckObjects(data, "IDLitData", $
                                     count=nData, /no_check)

   nData = n_elements(oData)
   nParms = n_elements(parameter)

   if(nData ne nParms)then $
     return, obj_new()

   oTool = self->GetTool() ;; got to have that tool!

   ;; Make our command set for this action
   ; If we are only setting 1 parameter, make our undo/redo name
   ; equal to the parameter name.
   cmdName = (nParms eq 1) ? $
        STRMID(parameter[0],0,1)+STRLOWCASE(STRMID(parameter[0],1)) : $
        "Set Parameters"

   oCmdSet = OBJ_NEW("IDLitCommandSet", NAME=cmdName, $
                     OPERATION_IDENTIFIER=self->GetFullIdentifier())

   idTarget = oTarget->GetFullIdentifier()
   ;; Set our parameters
   for i=0, nParms-1 do begin


       oCmd = obj_new("IDLitcommand", $
                      TARGET_IDENTIFIER=idTarget)
       iStatus = oCmd->AddItem("PARAMETER", parameter[i])

       ;; get the old value
       oOld = oTarget->GetParameter(parameter[i], count=isOldValid)
       if(isOldValid ne 0)then begin
           iStatus = oCmd->AddItem("OLD_DATA_ID", $
                                   oOld->GetFullIdentifier())
           ;; Turn off auto-delete on the old parameter data. If not
           ;; done, the object will kill itself and undo will fail.
           oOld->GetProperty, auto_delete=bAutoDel
           iStatus = oCmd->AddItem("AUTO_DATA_DELETE", bAutoDel)
           if(bAutoDel)then begin
               if(obj_isa(oOld, "IDLitDataContainer"))then $
                 oOld->SetAutoDeleteMode, 0 $
               else if(obj_isa(oOld, "IDLitData"))then $
                 oOld->SetProperty, AUTO_DELETE=0
           endif
       endif
       ;; We have a valid data value to set.
       if(obj_valid(odata[i]))then begin
           iStatus = oCmd->AddItem("NEW_DATA_ID", $
                                   oData[i]->GetFullIdentifier())
           void = oTarget->SetData(oDAta[i], $
                                   parameter_name=parameter[i])
       endif else if(isOldValid ne 0)then  $ ;; just disconnect
         oTarget->UnsetParameter, parameter[i]

       ;; Add this to the command set.
       oCmdSet->Add,oCmd
   endfor

   ;; Return if valid
   return, ( nParms gt 0 ? oCmdSet : obj_new())
END

;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitsrvSetParameter__define

    compile_opt idl2, hidden

    struc = {IDLitsrvSetParameter,       $ ;nothing to it
             inherits IDLitOperation $
            }
end

