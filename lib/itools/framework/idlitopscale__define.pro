; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopscale__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopScale
;
; PURPOSE:
;   This file implements the operation that is used to set the scale
;;  factor on a visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopScale::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopScale::Init
;   IDLitopScale::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopScale::Init
;;
;; Purpose:
;; The constructor of the IDLitopScale object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopScale::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(NUMBER_DS='1', _EXTRA=_extra)

end

;-------------------------------------------------------------------------
;; IDLitopScale::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopScale object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopScale::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end

;-------------------------------------------------------------------------
function IDLitopScale::_DoScale, oVis, scaleFactor
   ;; Pragmas
   compile_opt idl2, hidden

   ;; Apply scale factor in all 3 dimensions, depending upon
   ;; which sub-selection visual is selected.
   oVis->Scale, scaleFactor[0], scaleFactor[1], scaleFactor[2], /PRE

   return, 1
end
;;
;;---------------------------------------------------------------------------
;; IDLitopScale::UndoOperation
;;
;; Purpose:
;;  Undo the property commands contained in the command set.
;;
function IDLitopScale::UndoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)

  for i=nObjs-1, 0, -1 do begin
      ;; Get the target object for this command.
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
      oObject = oTool->GetByIdentifier(idTarget)
      if(not obj_valid(oObject))then $
        continue;
      if(oCmds[i]->getItem("SCALE_FACTOR", scaleFactor) eq 1)then begin
          iStatus=self->_DoScale(oObject, 1./scaleFactor)
          if(iStatus eq 0)then $
            return, 0 ;; error
      endif
      ;; Is any update type of code needed here?
  endfor

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitopScale::RedoOperation
;;
;; Purpose:
;;   Used to execute this operation on the given command set.
;;   Used with redo for the most part.

function IDLitopScale::RedoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)

  for i=nObjs-1, 0, -1 do begin
      ;; Get the target object for this command.
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
      oObject = oTool->GetByIdentifier(idTarget)
      if(not obj_valid(oObject))then $
        continue;
      ;; Grab the new value, property id and set it
      if(oCmds[i]->getItem("SCALE_FACTOR", scaleFactor) eq 1)then begin
          iStatus=self->_DoScale(oObject, scaleFactor)
          if(iStatus eq 0)then $
            return, 0 ;; error
      endif
      ;; Is any update type of code needed here?
  endfor

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitopScale::SetProperty
;;
;; Purpose:
;;   Used to set properties associated with this operation.
;;
;; Properties:
;;   SCALE_CONSTRAINT   - A vector used to control scale constraints

PRO IDLitopScale::SetProperty, SCALE_CONSTRAINT=scConstraint, _extra=_extra
   ;; Pragmas
   compile_opt idl2, hidden
   if(n_elements(scConstraint) gt 0)then $
      self.scaleConstraint = scConstraint
   if(n_elements(_extra))then $
     self->idlitOperation::SetProperty, _EXTRA=_Extra
end
;;---------------------------------------------------------------------------
;; IDLitopScale::GetInitialXY
;;
;; Purpose:
;;   Used to set the start xy for the scale operation
;;
function IDLitopScale::GetInitialXY
    ; Pragmas
    compile_opt idl2, hidden
    return, self.initXY
end
;;---------------------------------------------------------------------------
;; IDLitopScale::SetInitialXY
;;
;; Purpose:
;;   Used to set the start xy for the scale operation
;;
PRO IDLitopScale::SetInitialXY, XY
   ;; Pragmas
   compile_opt idl2, hidden
    self.initXY = XY
end
;;---------------------------------------------------------------------------
;; IDLitopScale::SetFinalXY
;;
;; Purpose:
;;   Used to set the final xy of the scale operation.

PRO IDLitopScale::SetFinalXY, XY
   ;; Pragmas
   compile_opt idl2, hidden
    self.finalXY = XY
end
;;---------------------------------------------------------------------------
;; IDLitopScale::RecordInitialValues
;;
;; Purpose:
;;   This routine is used to record the initial values needed to
;;   perform undo/redo for the scale operation.
;;
function IDLitopScale::RecordInitialValues, oCommandSet, $
                     oTargets, idProperty
   ;; Pragmas
   compile_opt idl2, hidden

   ;; Just make our command objects
   for i=0, n_elements(oTargets)-1 do begin

       oCmd = obj_new('IDLitCommand', TARGET_IDENTIFIER= $
                      oTargets[i]->GetFullIdentifier())
       oCommandSet->Add, oCmd
   endfor

   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitopScale::RecordFinalValues
;;
;; Purpose:
;;   This routine is used to record the final property values of the
;;   items provided.
;;
function IDLitopScale::RecordFinalValues, oCommandSet, oTargets, $
                           idProperty
   ;; Pragmas
   compile_opt idl2, hidden

   ;; Calculate our scale factor
    ;; Calculate the scale factor.
   if(n_elements(oTargets) eq 0)then $
     return, 0

   ;; Get a relativly close ref. point.
   oTargets[0]->GetProperty, CENTER_OF_ROTATION=center

   oTargets[0]->_IDLitVisualization::VisToWindow, $
                    center, screenCenter
   rStart = SQRT(TOTAL( (self.initXY - screenCenter)^2d ))
   rCurrent = SQRT(TOTAL( (self.finalXY - screenCenter)^2d ))
   scaleFactor = (rStart gt 0) ? (finite(rCurrent/rStart) ?  $
                                  rCurrent/rStart : 1) : 1
   scaleFac = fltarr(3,/nozero)
   scaleFac[0] = (self.scaleConstraint[0]) ? scaleFactor : 1
   scaleFac[1] = (self.scaleConstraint[1]) ? scaleFactor : 1
   scaleFac[2] = (self.scaleConstraint[2]) ? scaleFactor : 1

   ;; Okay, just loop through and record the current values in the
   ;; the target objects.
   for i=0, n_elements(oTargets)-1 do begin
       oCmd = oCommandSet->Get(POSITION=i)

       ;; Add the values to the command object.
       iStatus = oCmd->AddItem("SCALE_FACTOR", scaleFac)
   endfor

   return, 1
end

;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
pro IDLitopScale__define

    compile_opt idl2, hidden

    struc = {IDLitopScale,       $
             inherits IDLitOperation, $
             initXY         : lonarr(2), $
             finalXY         : lonarr(2), $
             scaleConstraint : intarr(3) $
            }
end

