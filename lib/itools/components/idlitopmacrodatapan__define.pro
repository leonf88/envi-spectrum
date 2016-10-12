; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmacrodatapan__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroDataPan
;
; PURPOSE:
;   This file implements the operation that pans
;   the current window's current view.  It is for use in macros
;   and history when a user uses the view pan manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroDataPan::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroDataPan::Init
;   IDLitopMacroDataPan::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroDataPan::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroDataPan object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroDataPan::Init,  _EXTRA=_extra
  compile_opt idl2, hidden
  
  ;; Just pass on up
  if (self->IDLitOperation::Init(NAME="View Pan", $
                                 TYPES='', $
                                 _EXTRA=_extra) eq 0) then $
    return, 0
    
  self->RegisterProperty, 'X', /FLOAT, $
    NAME='X pan', $
    DESCRIPTION='X pan (pixels)'
    
  self->RegisterProperty, 'Y', /FLOAT, $
    NAME='Y pan', $
    DESCRIPTION='Y pan (pixels)'
    
  return, 1
  
end


;-------------------------------------------------------------------------
; IDLitopMacroDataPan::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroDataPan::GetProperty, X=x, Y=y, _REF_EXTRA=_extra
    
  compile_opt idl2, hidden
  
  if (arg_present(x)) then $
    x = self._x
    
  if (ARG_PRESENT(y)) then $
    y = self._y
    
  if (n_elements(_extra) gt 0) then $
    self->IDLitOperation::GetProperty, _EXTRA=_extra
    
end


;-------------------------------------------------------------------------
; IDLitopMacroDataPan::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroDataPan::SetProperty, X=x, Y=y, _EXTRA=_extra
  compile_opt idl2, hidden
  
  if (N_ELEMENTS(x) ne 0) then $
    self._x = x
  
  if (N_ELEMENTS(y) ne 0) then $
    self._y = y
  
  if (n_elements(_extra) gt 0) then $
    self->IDLitOperation::SetProperty, _EXTRA=_extra
    
end


;-------------------------------------------------------------------------
;pro IDLitopMacroDataPan::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
; IDLitManipDataPan::RecordUndoValues
;
; Purpose:
;   This function method records the initial values of targets so
;   that an undo/redo can later be performed.
;
function IDLitopMacroDataPan::RecordUndoValues, oWin
  compile_opt idl2, hidden
  
  if (~OBJ_VALID(self._oTargetDS)) then $
    return, 0
    
  ; Grab a reference to the tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then $
    return, 0
    
  ; Get my own name.
  self->IDLitComponent::GetProperty, NAME=myname
  
  ; Retrieve the SetProperty operation.
  oSetPropOp = oTool->GetService("SET_PROPERTY")
  
  ; Prepare a command set for setting the properties.
  self._oCmdSet = OBJ_NEW("IDLitCommandSet", NAME=myname, $
    OPERATION_IDENTIFIER=oSetPropOp->GetFullIdentifier())
    
  void = oSetPropOp->RecordInitialValues(self._oCmdSet, self._oTargetDS, $
                                         "X_MINIMUM")
  void = oSetPropOp->RecordInitialValues(self._oCmdSet, self._oTargetDS, $
                                         "X_MAXIMUM")
  void = oSetPropOp->RecordInitialValues(self._oCmdSet, self._oTargetDS, $
                                         "Y_MINIMUM")
  void = oSetPropOp->RecordInitialValues(self._oCmdSet, self._oTargetDS, $
                                         "Y_MAXIMUM")
  
  return,1
  
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::StartPan
;
; Purpose:
;   This procedure method starts the pan.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;
function IDLitopMacroDataPan::StartPan, oWin, x, y
  compile_opt idl2, hidden
  
  oSel = (oWin->GetSelectedItems())[0]
  
  if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then begin
    oDS = oSel->GetDataSpace()
    if (OBJ_VALID(oDS)) then begin
      ; Store mouse down location
      self._startXY = [x,y]
      self._macroXY = [x,y]
      self._oTargetDS = oDS
      ; Record the current values for the target view.
      iStatus = self->RecordUndoValues(oWin)
      return, 1
    endif
  endif
  
  return, 0
  
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::Pan
;
; Purpose:
;   This procedure method performs the actual pan.
;
; Parameters
;  oWin    - Event Window Component
;  deltaX   - X coordinate
;  deltaY   - Y coordinate
;
function IDLitopMacroDataPan::DoPan, oWin, deltaX, deltaY
  compile_opt idl2, hidden
  
  if (~OBJ_VALID(self._oTargetDS)) then $
    return, ''
    
  oWin->GetProperty, VISIBLE_LOCATION=vLocation
  x = self._macroXY[0] + [0, deltaX]
  y = self._macroXY[1] + [0, deltaY]
  ; Get the first child, to perform the conversion.
  oDSObj = (self._oTargetDS->Get())[0]
  oDSObj->WindowToVis, x - vLocation[0], y - vLocation[1], xdata, ydata
  xdiff = xdata[1] - xdata[0]
  ydiff = ydata[1] - ydata[0]
  self._macroXY = [x[1], y[1]]
  self._oTargetDS->GetProperty, X_MINIMUM=xmin, X_MAXIMUM=xmax, $
    Y_MINIMUM=ymin, Y_MAXIMUM=ymax, XLOG=xLog, YLOG=yLog

  ; Handle logarithmic axes, if necessary.
  if (KEYWORD_SET(xLog)) then begin
    xmin = 10d^(ALOG10(xmin) - xdiff)
    xmax = 10d^(ALOG10(xmax) - xdiff)
  endif else begin
    xmin -= xdiff
    xmax -= xdiff
  endelse
  if (KEYWORD_SET(yLog)) then begin
    ymin = 10d^(ALOG10(ymin) - ydiff)
    ymax = 10d^(ALOG10(ymax) - ydiff)
  endif else begin
    ymin -= ydiff
    ymax -= ydiff
  endelse

  self._oTargetDS->SetProperty, X_MINIMUM=xmin, X_MAXIMUM=xmax, $
    Y_MINIMUM=ymin, Y_MAXIMUM=ymax
  xystr = STRCOMPRESS(STRING([xmin,xmax,ymin,ymax], FORMAT='(G11.4)'))
  str = STRING(xystr,FORMAT='("X: ",A,",",A,"  Y: ",A,",",A)')
  
  return, str
  
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::EndPan
;
; Purpose:
;   This procedure method ends the pan.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
function IDLitopMacroDataPan::EndPan, oWin, x, y
  compile_opt idl2, hidden
  
  if (~OBJ_VALID(self._oTargetDS) || ~OBJ_VALID(self._oCmdSet)) then $
    return, OBJ_NEW()
    
  ; Grab a reference to the tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then $
    return, 0
    
  ; Retrieve the SetProperty operation.
  oSetPropOp = oTool->GetService("SET_PROPERTY")
  
  void = oSetPropOp->RecordFinalValues(self._oCmdSet)
  return, self._oCmdSet
  
end


;;---------------------------------------------------------------------------
;; IDLitopMacroDataPan::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroDataPan::DoAction, oTool
  compile_opt hidden, idl2
  
  ;; Make sure we have a tool.
  if ~obj_valid(oTool) then $
    return, obj_new()
    
  oWin = oTool->GetCurrentWindow()
  if ~obj_valid(oWin) then $
    return, obj_new()
    
  success = self->StartPan(oWin, 0, 0)
  
  if (~success) then $
    return, obj_new()
    
  ; Call our internal method.
  void = self->DoPan(oWin, self._x, self._y)
  
  oCmdSet = self->EndPan(oWin, self._x, self._y)
  
  return, oCmdSet
  
end


;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroDataPan__define
  compile_opt idl2, hidden
  
  void = {IDLitopMacroDataPan, $
          inherits IDLitOperation, $
          _x: 0L,                  $
          _y: 0L,                  $
          _oTargetDS: OBJ_NEW(),   $ ; Reference to dataspace to be panned.
          _startXY: DBLARR(2),     $ ; Initial window location.
          _macroXY: DBLARR(2),     $ ; Subsequent cursor location for recording.
          _oCmdSet: OBJ_NEW()      $ ; Command sets for undo/redo
         }
end
