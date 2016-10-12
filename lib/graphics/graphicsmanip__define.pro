; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphicsmanip__define.pro#2 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;----------------------------------------------------------------------------
; Purpose:
;   The primary manipulator.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;  The constructor of the manipulator object.
;
; Arguments:
;
; Keywords:
;
function GraphicsManip::Init, TOOL=TOOL, _EXTRA=_extra
  compile_opt idl2, hidden
  
  success = self->IDLitManipulatorContainer::Init( $
    VISUAL_TYPE = 'Select', $
    /WHEEL_EVENTS, $
    /AUTO_SWITCH, $
    TOOL=TOOL, $
    _EXTRA=_extra)
  if (not success) then $
    return, 0

  self.oSelect = OBJ_NEW('IDLitManipScale', TOOL=tool, /PRIVATE)
  self->Add, self.oSelect
  
  ; Needed for drawing a selection box around multiple items.
  ; We cache this objref so we can manually switch to it if nothing was hit.
  self.oManipSelectBox = OBJ_NEW('IDLitManipSelectBox', $
    TOOL=tool, /PRIVATE)
  self->Add, self.oManipSelectBox
  
  ; Set current manipulator.
  self->SetCurrent, self.oSelect
  
  ; Register the default cursor for this manipulator.
  self->_DoRegisterCursor

  self.pTransInfo = PTR_NEW(/allocate_heap)

  ; Initially, rotations are not constrained about a particular axis.
  self.constrainAxis = -1
  self.pCenterRotation = PTR_NEW(0)

  oTool = self->GetTool()
  self._oSetProperty = oTool->GetService("SET_PROPERTY")

  return, 1

end


;---------------------------------------------------------------------------
pro GraphicsManip::Cleanup

  PTR_FREE, self.pTransInfo, self.pCenterRotation
  self->IDLitManipulatorContainer::Cleanup
end


;---------------------------------------------------------------------------
pro GraphicsManip::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
                                     NO_SELECT=noSelect
  compile_opt idl2, hidden

  ; Call our superclass.
  self->_IDLitManipulator::OnMouseDown, $
    oWin, x, y, iButton, KeyMods, nClicks

  if (self.nSelectionList eq 0) then begin
    self->SetCurrentManipulator, self.oManipSelectBox
    self._currentManip = 'selectbox'
  endif else begin
    ; If we are in "auto-route" mode, see what sub-mode we should
    ; switch to.
    ; Fake no button down during autoswitch so it does not think we are panning
    self.ButtonPress = 0
    if (self.m_bAutoSwitch) then $
        self->_AutoSwitch, oWin, x, y, KeyMods
  endelse
  
  self.ButtonPress = iButton

  self.is3D = 0b
  self._initialKeyMods = KeyMods
  if (OBJ_VALID(oTarget)) then $ 
    self._oTarget = oTarget

  ; For middle or right button clicks, cancel the annotation and remove the
  ; zoom box if it exists
  if (iButton ne 1) then begin
    if (OBJ_VALID(self._oRectangle)) then begin
      ; If our manip viz has a parent, assume this is a valid select box.
      self._oRectangle->GetProperty, PARENT=oParent
      if (OBJ_VALID(oParent)) then begin
        oParent->IDLgrModel::Remove, self._oRectangle
        oTool = self->GetTool()
        oTool->RefreshCurrentWindow
      endif
    endif
  endif

  status = 0b
  self._oCmd = OBJ_NEW("IDLitCommandSet", $
                 NAME=STRUPCASE(STRMID(self._currentManip,0,1))+ $
                      STRMID(self._currentManip,1), $
                 OPERATION_IDENTIFIER=self._oSetProperty->GetFullIdentifier())
  case self._currentManip of
    'selectbox' : begin
      self.oManipSelectBox->OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    end
    'scale' : begin
      if (self.nSelectionList gt 0) then begin
        ; See if any of the selected viz are 3d.
        ; Assume that we only need to check this on a mouse down.
        for i=0,self.nSelectionList-1 do begin
          if (*self.pSelectionList)[i]->Is3D() then begin
            self.is3D = 1b
            break   ; no need to continue checking.
          endif
        endfor
        self.scaleFactors = [1d, 1d, 1d]
        status = self._oSetProperty->RecordInitialValues(self._oCmd, $
          *self.pSelectionList, 'TRANSFORM')
      endif
    end ; scale
    'translate' : begin
      if (self.nSelectionList gt 0) then begin
      
        sTransInfo = replicate({        $
          initialTrans: DBLARR(3),   $
          dxVec: DBLARR(3), $
          dyVec: DBLARR(3)  $
          }, self.nSelectionList)
          
        ;; Loop through all selected visualizations.
        for i=0, self.nSelectionList-1 do begin
          oVis = (*self.pSelectionList)[i]
          
          ; Hack for now, do not allow translation of axes
          if (OBJ_ISA(oVis, 'IDLitVisAxis')) then $
            oVis = oVis->GetDataspace()

          ;; Grab the current CTM.
          oVis->IDLgrModel::GetProperty, TRANSFORM=tm
          sTransInfo[i].initialTrans = tm[3, 0:2]
          
          ;; Transform data space origin to screen space.
          oVis->VisToWindow, [0.0d, 0.0d, 0.0d], scrOrig
          
          ;; Add one pixel in X to the screen origin, and revert back to
          ;; screen space.
          oVis->WindowToVis, scrOrig + [1.,0.,0.], dataPt
          sTransInfo[i].dxVec = dataPt
          
          ;; Add one pixel in Y to the screen origin, and revert back to
          ;; screen space.
          oVis->WindowToVis, scrOrig + [0.,1.,0.], dataPt
          sTransInfo[i].dyVec = dataPt
          
        endfor
        *self.pTransInfo = temporary(sTransInfo)
        status = self._oSetProperty->RecordInitialValues(self._oCmd, $
          *self.pSelectionList, 'TRANSFORM')
      endif
    end ; translate
    'rotate' : begin
      ; Set rotation center, radius, constraint.
      self->_InitRot, oWin
      ; Set up the rotation.
      self->_Rotate, oWin, x[0], y[0], $
        TYPE=0          ; button was pressed
      status = self._oSetProperty->RecordInitialValues(self._oCmd, $
        *self.pSelectionList, 'TRANSFORM')
    end ; rotate
    'zoom' : begin
      ; Get Dataspace
      oSel = (oWin->GetSelectedItems())[0]
      if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
        oDS = oSel->GetDataSpace()
      if (~OBJ_VALID(oDS)) then begin
        self.ButtonPress = 0
        return
      endif
      ; Only 2D dataspaces
      if (oDS->Is3D()) then begin
        self.ButtonPress = 0
        return
      endif
    
      oLayer = oDS->_GetLayer()
      if(obj_Isa(oLayer,'IDLitgrAnnotateLayer'))then begin
        self.ButtonPress = 0
        return
      endif
    
      ; For middle or right button clicks, cancel the annotation.
      if (iButton ne 1) then begin
        self.ButtonPress = 0
        return
      endif

      ; Create our new annotation.
      if (OBJ_VALID(self._oRectangle)) then begin
        ; If our zoom box was previously part of a model,
        ; remove it. This can happen when you switch views.
        self._oRectangle->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
          oParent->IDLgrModel::Remove, self._oRectangle
      endif else begin
        self._oRectangle = OBJ_NEW('IDLitManipulatorVisual', $
          VISUAL_TYPE='SelectBox', /PRIVATE)
        oSubManipVis = OBJ_NEW('IDLitManipulatorVisual', $
          VISUAL_TYPE='SelectBox', /PRIVATE)
        self._oPolyline = OBJ_NEW('IDLgrPolyline', $
          LINESTYLE=[1, 'F0F0'x], COLOR=[255b,0b,0b])
        oSubManipVis->Add, self._oPolyline
        self._oRectangle->Add, oSubManipVis
      endelse

      self._startPT = [x, y]
      
      oWin->SetCurrentCursor, 'CROSSHAIR'
    end ; zoom
    'pan' : begin
      ; Get Dataspace
      oSel = (oWin->GetSelectedItems())[0]
      if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
        oDS = oSel->GetDataSpace()
      if (~OBJ_VALID(oDS)) then begin
        self.ButtonPress = 0
        return
      endif
      ; Only 2D dataspaces
      if (oDS->Is3D()) then begin
        self.ButtonPress = 0
        return
      endif
      oLayer = oDS->_GetLayer()
      if(obj_Isa(oLayer,'IDLitgrAnnotateLayer'))then begin
        self.ButtonPress = 0
        return
      endif
      if (iButton ne 1) then begin
        self.ButtonPress = 0
        return
      endif
    
      oTool = self->GetTool()
      if (~OBJ_VALID(oTool)) then $
        return
      oDesc = oTool->GetByIdentifier('/Registry/MacroTools/DataPan')
      if (~OBJ_VALID(oDesc)) then $
        return
      oPan = oDesc->GetObjectInstance()
      
      success = oPan->StartPan(oWin, x, y)
      
      self._startXY = [x, y]
      self._currentXY = [x, y]
      
      self->StatusMessage, IDLitLangCatQuery('Status:Framework:Pan')
      
      oWin->SetCurrentCursor, success ? 'Grab' : 'NoGrab'
    end ; pan
    'line' : begin
      status = self._oSetProperty->RecordInitialValues(self._oCmd, $
        *self.pSelectionList, '_DATA')
    end ; line
    else :
  endcase

  if (~status) then $
    OBJ_DESTROY, self._oCmd

  self.startXY = [x,y]
  self.prevXY = [x,y]

end


;--------------------------------------------------------------------------
; GraphicsManip::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button released

pro GraphicsManip::OnMouseUp, oWin, x, y, iButton
  compile_opt idl2, hidden

  status = 0b
  case self._currentManip of
    'selectbox' : begin
      self.oManipSelectBox->OnMouseUp, oWin, x, y, iButton
    end
    'scale' : begin
      status = self._oSetProperty->RecordFinalValues(self._oCmd, $
        *self.pSelectionList, 'TRANSFORM', /SKIP_MACROHISTORY)
    end
    'translate' : begin
      self.xyConstrain = 0
      status = self._oSetProperty->RecordFinalValues(self._oCmd, $
        *self.pSelectionList, 'TRANSFORM', /SKIP_MACROHISTORY)
    end
    'rotate' : begin
      status = self._oSetProperty->RecordFinalValues(self._oCmd, $
        *self.pSelectionList, 'TRANSFORM', /SKIP_MACROHISTORY)
    end
    'zoom' : begin
      ; Sanity check.
      if (self.ButtonPress && OBJ_VALID(self._oRectangle)) then begin
      
        ; If our manip viz has a parent, assume this is a valid select box.
        self._oRectangle->GetProperty, PARENT=oParent
        
        minSize = 5
        haveBox = ((ABS(self._startPT[0] - x) gt minSize) && $
                   (ABS(self._startPT[1] - y) gt minSize))
        
        if (OBJ_VALID(oParent)) then begin
          oParent->IDLgrModel::Remove, self._oRectangle
          ; Make sure we defined a valid region.
          if (haveBox) then $
            self->_DoZoom, oWin, self._startPT, self._endPt, oCmd
        endif
        
        oTool = self->GetTool()
        oTool->RefreshCurrentWindow
        oTool->UpdateAvailability
        
        ; Add to undo/redo buffer
        if (haveBox && PRODUCT(OBJ_VALID(oCmd))) then $
          oTool->_TransactCommand, oCmd
    
      endif
    end
    'pan' : begin
      oTool = self->GetTool()
      if (~OBJ_VALID(oTool)) then $
        return
      oDesc = oTool->GetByIdentifier('/Registry/MacroTools/DataPan')
      if (~OBJ_VALID(oDesc)) then $
        return
      oPan = oDesc->GetObjectInstance()
      oCmdSet = oPan->EndPan(oWin, x, y)
      if (ISA(oCmdSet) && oCmdSet->Count() gt 0) then $
        oTool->_TransactCommand, oCmdSet
    end
    'line' : begin
      if (self.nSelectionList gt 0) then begin
        ;; Commit this transaction
        iStatus = self->CommitUndoValues( $
          UNCOMMIT=ARRAY_EQUAL(self.startXY, [x,y]))
        status = self._oSetProperty->RecordFinalValues(self._oCmd, $
          *self.pSelectionList, '_DATA', /SKIP_MACROHISTORY)
      endif
    end
    else :
  endcase

  if (~status) then $
    OBJ_DESTROY, self._oCmd
    
  if (N_ELEMENTS(self._oCmd) ne 0) then begin
    oTool = self->GetTool()
    oTool->_TransactCommand, self._oCmd
  endif
  
  ; Call our superclass.
  self->IDLitManipulatorContainer::OnMouseUp, oWin, x, y, iButton

end

;--------------------------------------------------------------------------
; GraphicsManip::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro GraphicsManip::OnMouseMotion, oWin, x, y, KeyMods
  compile_opt idl2, hidden
  
  ; If we are auto-switching and no mouse button is down,
  ; automatically change the cursor.
  if (self.m_bAutoSwitch && (self.ButtonPress eq 0)) then begin
    self->_AutoSwitch, oWin, x, y, KeyMods    
    return
  endif

  if (self.ButtonPress eq 1) then begin
    case self._currentManip of
      'selectbox' : self.oManipSelectBox->OnMouseMotion, oWin, x, y, KeyMods
      'scale' : self->_Scale, oWin, x, y, KeyMods
      'translate' : self->_Translate, oWin, x, y, KeyMods
      'rotate' : self->_Rotate, oWin, x, y, KeyMods, TYPE=2
      'zoom' : self->_Zoom, oWin, x, y, KeyMods
      'pan' : self->_Pan, oWin, x, y, KeyMods
      'line' : self->_Line, oWin, x, y, KeyMods
      else :
    endcase
  endif

  ; Update the graphics hierarchy.
  self.tool.RefreshCurrentWindow
  
;  if( obj_valid(self.m_currManip))then begin
;    ; Ensure that our current manipulator actually wants these events.
;    Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
;      MOTION_EVENTS=wantEvent
;    if (wantEvent) then $
;      self.m_currManip->OnMouseMotion, oWin, x, y, KeyMods
;  endif

end


;--------------------------------------------------------------------------
; GraphicsManip::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Parameters
;      oWin        - Event Window Component
;      IsAlpha     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
pro GraphicsManip::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
  compile_opt idl2, hidden

  if (IsASCII) then begin
    switch Character of
      127:   ; delete key fall thru
      8: begin   ; backspace
        if (Release) then begin
          otool = self->GetTool()
          result = oTool->DoAction('OPERATIONS/EDIT/DELETE')
        endif
        break
      end
      else:
    endswitch
  endif else begin
  endelse
  
  ; Update cursor if needed
  if (ISA(KeyMods) && (KeyMods ne 0)) then $
    self->_AutoSwitch, oWin, X, Y, KeyMods
  
;  ; Call our superclass.
;  self->IDLitManipulatorContainer::OnKeyBoard, oWin, $
;    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
    
end


;--------------------------------------------------------------------------
; GraphicsManip::_SetDataspaceRange
;
; Purpose:
;   Sets the new dataspace range
;
; Parameters
;  oDS - The dataspace to be changed
;  xMin,xMax - New X min,max values
;  yMin,yMax - New Y min,max values
;  zMin,zMax - New Z min,max values
;
function GraphicsManip::_SetDataspaceRange, oDS, xMin, xMax, $
                                                 yMin, yMax, zMin, zMax
  compile_opt idl2, hidden

  oTool = self->GetTool()
  
  oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
  
  ; Retrieve the SetProperty operation.
  oSetProp = oTool->GetService("SET_PROPERTY")

  ; Set minimum and maximum dataspace range values
  if (N_ELEMENTS(xMin) && FINITE(xMin)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'X_MINIMUM', xMin)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(xMax) && FINITE(xMax)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'X_MAXIMUM', xMax)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(yMin) && FINITE(yMin)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'Y_MINIMUM', yMin)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(yMax) && FINITE(yMax)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'Y_MAXIMUM', yMax)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (oDS->Is3D()) then begin
    if (N_ELEMENTS(zMin) && FINITE(zMin)) then begin
      oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
        'Z_MINIMUM', zMin)
      if (OBJ_VALID(oCmdTmp)) then begin
        oCmdTmp->SetProperty, NAME='Dataspace reset'
        oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
      endif
    endif
    if (N_ELEMENTS(zMax) && FINITE(zMax)) then begin
      oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
        'Z_MAXIMUM', zMax)
      if (OBJ_VALID(oCmdTmp)) then begin
        oCmdTmp->SetProperty, NAME='Dataspace reset'
        oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
      endif
    endif
  endif
  
  if (~wasDisabled) then $
      oTool->EnableUpdates
      
  return, oCmd

end


;--------------------------------------------------------------------------
; GraphicsManip::OnWheel
;
; Purpose:
;   Routes OnWheel events to the current manipulator.
;
; Parameters
;   oWin: The source of the event
;   X: The location of the event
;   Y: The location of the event
;   delta: direction and distance that the wheel was rolled.
;       Forward movement gives a positive value,
;       backward movement gives a negative value.
;   keymods: Set to values of any modifier keys.
;
pro GraphicsManip::OnWheel, oWin, x, y, delta, keyMods
  compile_opt idl2, hidden

  ; Not at the same time as the bounding box
  if (self.ButtonPress) then return
  
  ; Make sure we have a tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  ; Get Dataspace
  oSel = (oWin->GetSelectedItems())[0]
  if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
    oDS = oSel->GetDataSpace()
  if (~OBJ_VALID(oDS)) then return

  oLayer = oDS->_GetLayer()
  if(obj_Isa(oLayer,'IDLitgrAnnotateLayer'))then $
    return

  ; Only 2D dataspaces
  if (oDS->Is3D()) then $
    return

  ; Convert window coords to dataspace coords
  oDSObj = (oDS->Get())[0]
  oDSObj->WindowToVis, x, y, xdata, ydata
  
  ; zoom value
  zoomFactor = (delta gt 0) ? 1/1.25d : 1.25d
  
  ; Get current ranges
  oDS->GetProperty, X_MINIMUM=xMin, X_MAXIMUM=xMax, $
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax, XLOG=xLog, YLOG=yLog

  ; Handle logarithmic axes, if necessary.
  if (KEYWORD_SET(xLog)) then begin
    xMin = ALOG10(xMin)
    xMax = ALOG10(xMax)
  endif
  if (KEYWORD_SET(yLog)) then begin
    yMin = ALOG10(yMin)
    yMax = ALOG10(yMax)
  endif

  xRange = xMax - xMin
  yRange = yMax - yMin 

  ; Calculate new ranges
  newXrange = xRange * zoomFactor
  newYrange = yRange * zoomFactor
  
  ; Determine minimum values such that mouse data location remains constant
  newXmin = xdata - (xdata-xMin)*zoomFactor
  newXmax = newXmin + newXrange
  newYmin = ydata - (ydata-yMin)*zoomFactor
  newYmax = newYmin + newYrange
  
  if (KEYWORD_SET(xLog)) then begin
    newXmin = 10d^newXmin
    newXmax = 10d^newXmax
  endif
  if (KEYWORD_SET(yLog)) then begin
    newYmin = 10d^newYmin
    newYmax = 10d^newYmax
  endif

  oCmd = self->_SetDataspaceRange(oDS, newXmin, newXmax, newYmin, newYmax)

  oTool->RefreshCurrentWindow
  oTool->UpdateAvailability
  ; Add to undo/redo buffer
  if (PRODUCT(OBJ_VALID(oCmd))) then $
    oTool->_TransactCommand, oCmd

end


;--------------------------------------------------------------------------
; GraphicsManip::_ScaleCenter
;
; Purpose:
;  Return the scaling center, depending upon the cornerConstraint.
;
function GraphicsManip::_ScaleCenter, oVis, KeyMods
  compile_opt idl2, hidden
  
  ; By default use the center of rotation of the viz.
  success = 0
  oVis->GetProperty, CENTER_OF_ROTATION=scaleCenter
  
  ; If the <Ctrl> key is down, scale about the center.
  cornerConstraint = ((KeyMods and 2) ne 0) ? $
    [-1, -1, -1] : self.cornerConstraint
    
  ; We are scaling about the corners/edges instead of the center.
  ; Retrieve the ranges for the selected visualization.
  if not ARRAY_EQUAL(cornerConstraint, [-1, -1, -1]) then begin
    success = oVis->GetXYZRange(xRange, yRange, zRange, $
      /NO_TRANSFORM)
  endif
  
  if (success) then begin
    ; If we are constrained, use either the range min or max.
    ; If we aren't constrained, we'll use the center from above.
    if (cornerConstraint[0] ge 0) then $
      scaleCenter[0] = xRange[self.cornerConstraint[0]]
    if (cornerConstraint[1] ge 0) then $
      scaleCenter[1] = yRange[self.cornerConstraint[1]]
    if (cornerConstraint[2] ge 0) then $
      scaleCenter[2] = zRange[self.cornerConstraint[2]]
  endif
  
  return, scaleCenter

end


;--------------------------------------------------------------------------
; GraphicsManip::_Scale
;
; Purpose:
;   This method performs scaling
;
pro GraphicsManip::_Scale, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; If we havn't moved then return.
  if ((x eq self.prevXY[0]) && (y eq self.prevXY[1])) then $
    RETURN

  if (OBJ_VALID(self._oTarget)) then begin
    oVis = self._oTarget
  endif else begin
    oVis = (*self.pSelectionList)[0]
  endelse
 
  ; Find the scaling center. We need to do this each time, in case
  ; the KeyMods has changed.
  centerXYZ = self->_ScaleCenter(oVis, KeyMods)
  ; Maintain aspect ratio?
  keepAspect = oVis->IsIsotropic() || (KeyMods and 1) || self.is3D

  ; Shift key forces uniform scaling.
  if (keepAspect) then begin
  
    ; Convert center from viz coords to window coords.
    oVis->_IDLitVisualization::VisToWindow, $
      centerXYZ, screenCenter
    screenCenter = screenCenter[0:1]
    
    ; Calculate the uniform scale factor using the difference
    ; in screen coordinates between location and scale center.
    rStart = SQRT(TOTAL(ABS(self.prevXY - screenCenter)^2d))
    rCurrent = SQRT(TOTAL(ABS([x,y] - screenCenter)^2d))
    scaleFactor = (rStart gt 0) ? (finite(rCurrent/rStart) ?  $
      rCurrent/rStart : 1) : 1
      
    scaleX = (self.scaleConstraint[0]) ? scaleFactor : 1
    scaleY = (self.scaleConstraint[1]) ? scaleFactor : 1
    
    ; Only use the Z scale factor if we are scaling a 3D viz.
    scaleZ = (self.is3D && self.scaleConstraint[2]) ? scaleFactor : 1
    
  endif else begin
  
    ; Do computations in viz coords, so we can include rotations.
    oVis->_IDLitVisualization::WindowToVis, $
      [[x, y], [self.prevXY]], xyVis
    xVis = xyVis[0,0]
    yVis = xyVis[1,0]
    startXYvis = xyVis[*,1]

    ; Scaling is the current delta divided by starting delta.

    ; X scale factor.
    if (self.scaleConstraint[0]) then begin
      xstart = (startXYvis[0] - centerXYZ[0])
      if (xstart eq 0) then $
        return
      scaleX = (xVis - centerXYZ[0])/xstart
      ; Don't allow negative scaling.
      if (scaleX le 0) then $
        return
    endif else $
      scaleX = 1
      
    ; Y scale factor.
    if (self.scaleConstraint[1]) then begin
      ystart = (startXYvis[1] - centerXYZ[1])
      if (ystart eq 0) then $
        return
      scaleY = (yVis - centerXYZ[1])/ystart
      ; Don't allow negative scaling.
      if (scaleY le 0) then $
        return
    endif else $
      scaleY = 1
      
    scaleZ = 1   ; no Z scaling
    
  endelse
  
  
  ; Update the overall scale factor.
  self.scaleFactors *= [scaleX, scaleY, scaleZ]
  
  ; Loop through all selected visualizations.
  for i=0, self.nSelectionList-1 do begin
    oVis = (*self.pSelectionList)[i]
    if (ISA(oVis, 'IDLitVisText')) then continue
    ; Compute the scale center separately for each viz.
    if (i gt 0) then $
      centerXYZ = self->_ScaleCenter(oVis, KeyMods)
    oVis->Scale, scaleX, scaleY, scaleZ, /PREMULTIPLY, $
      CENTER_OF_ROTATION=centerXYZ
  endfor  ; selected vis loop

  ;; Bump up the initial xy points for the next application
  ;; of the algorithm.
  self.prevXY = [x, y]

end

;--------------------------------------------------------------------------
; GraphicsManip::_Translate
;
; Purpose:
;   This method performs translation
;
pro GraphicsManip::_Translate, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; Find distance the mouse moved.
  dx = x - self.prevXY[0]
  dy = y - self.prevXY[1]
  
  oDoneVis = []
  ;; Loop through all selected visualizations.
  for i=0, self.nSelectionList - 1 do begin
    oVis = (*self.pSelectionList)[i]
;    if (isAxis && self.nSelectionList gt 1) then continue

    ; Hack for now, do not allow translation of axes or titles
    isAxis = OBJ_ISA(oVis, 'IDLitVisAxis')
    if (isAxis) then begin
      oVis = oVis->GetDataspace()
      isAxis = 0
    endif
    isTitle = STRPOS(oVis.IDENTIFIER, 'TITLE') ne -1
    if (isTitle) then begin
      if (self.nSelectionList eq 1) then begin
        oVis = oVis->GetDataspace()
      endif else begin
        continue
      endelse
    endif

    ; Check to see if item has already been translated
    !NULL = where(oVis eq oDoneVis, cnt)
    if (cnt ne 0) then continue
    
    ; Ignore <Shift> key for axes (they're already constrained).
    if (~isAxis) then begin
      ; Check for <Shift> key.
      if ((KeyMods and 1) ne 0) then begin
        ; See if we need to initialize the constraint.
        ; The biggest delta (x or y) wins, until <Shift> is released.
        if (self.xyConstrain eq 0) then $
          self.xyConstrain = (ABS(dx) gt ABS(dy)) ? 1 : 2
        ; Apply the constraint.
        if (self.xyConstrain eq 1) then $
          dy = 0 $
        else $
          dx = 0
      endif else $
        self.xyConstrain = 0   ; turn off constraint
    endif
    
    ;; The translation in data space equals the screen space delta
    ;; multiplied by the unit data space vectors.
    dVec = (dx * (*self.pTransInfo)[i].dxVec) $
      + (dy * (*self.pTransInfo)[i].dyVec)

    ;; Translate to the new coordinates.
    if (isAxis) then begin
      ; Special code for axes, since we need to pass in Keymods,
      ; and retrieve the probe message.
      oVis->Translate, dVec[0], dVec[1], dVec[2], $
        KEYMODS=keymods, KEYVALUE=KeyValue
    endif else begin
      oVis->Translate, dVec[0], dVec[1], dVec[2], /PREMULTIPLY
    endelse
    ; Mark this vis as having been translated
    oDoneVis = [oDoneVis, oVis]
  endfor  ; selected vis loop
  
  self.prevXY = [x,y]

end

;----------------------------------------------------------------------------
; TRACKBALL_CONSTRAIN
;
; Purpose:
;  Given a point and a constraint vector, map the point to its constrained
;  equivalent.
;
; Arguments:
;  pt - The unconstrained point.
;  vec - A three-element vector, [x,y,z], representing the unit vector about
;        which rotations are constrained.
;
function GraphicsManip::_Constrain, point, constrainAxis, TYPE=type
  compile_opt idl2, hidden
  
  ; Store the constraint axis vector for the selected model.
  ; The constraint axis vector only gets changed for mouse down events,
  ; and is used for all subsequent OnMouseMotion events.
  ; Retrieve the primary selection.
  oVis = (*self.pSelectionList)[0]
  if (type eq 0) then begin
    oVis->GetProperty, TRANSFORM=startTransform
    
    vec = [0d,0d,0d]
    vec[constrainAxis] = 1
    
    ; Transform the current constraint vector using the starting transform.
    zeroVec = [0d, 0d, 0d, 1d] # startTransform
    vec = [vec, 1] # startTransform
    ; Constraint axis.
    vec = vec[0:2] - zeroVec[0:2]
    ; Normalize
    norm = SQRT(TOTAL(vec^2))
    if (norm gt 0) then $
      vec = TEMPORARY(vec)/norm
    ; Store the constraint axis vector for all subsequent motion events.
    self.constrainVector = vec
  endif
  
  ; Retrieve the stored constraint axis vector.
  vec = self.constrainVector
  
  ; Project the point.
  proj = point - TOTAL(vec * point) * vec
  
  ; Normalizing factor.
  norm = SQRT(TOTAL(proj^2d))
  
  cpoint = (norm gt 0.0) ? $
    ((proj[2] ge 0) ? proj/norm : -proj/norm) : vec
    
  RETURN, cpoint

END


;--------------------------------------------------------------------------
; Internal procedure to rotate a 2D viz by an angle about the Z axis.
;
; This will cache our new angle, update the status area,
; and perform the rotation.
;
pro GraphicsManip::_Rotate2D, angle
  compile_opt idl2, hidden
   
  ; Reduce to -180 to +180
  self.angle = (self.angle + angle) mod 360
  if (self.angle gt 180) then $
    self.angle -= 360 $
  else if (self.angle le -180) then $
  self.angle += 360
  
  if (angle eq 0) then $
    return
  
  ; delta starts at 0 while self.angle is based on initial transform
  self.totalAngle[2] = (self.totalAngle[2] + angle) mod 360

  ; Loop through all selected visualizations.
  for i=0,self.nSelectionList-1 do begin
    oVis = (*self.pSelectionList)[i]

    ; Do not allow axes to be rotated.
    if (self.nSelectionList gt 1 && OBJ_ISA(oVis, 'IDLitVisAxis')) then continue
    
    ; No rotation of dataspace text
    isText = ISA(oVis, 'IDLitVisText')
    if (isText) then begin
      ID = oVis->GetFullIdentifier()
      if (STRPOS(ID, 'DATA SPACE') ne -1) then continue
    endif

    ;; Perform rotation about visualization's center of rotation.
    oVis->Rotate, [0, 0, 1], angle
  endfor

end


; -----------------------------------------------------------------------------
;
;  Purpose:  Function returns the 3 angles of a space three 1-2-3
;            given a 3 x 3 cosine direction matrix
;            else -1 on failure.
;
;  Definition :  Given 2 sets of dextral orthogonal unit vectors
;                (a1, a2, a3) and (b1, b2, b3), the cosine direction matrix
;                C (3 x 3) is defined as the dot product of:
;
;                C(i,j) = ai . bi  where i = 1,2,3
;
;                A column vector X (3 x 1) becomes X' (3 x 1)
;                after the rotation as defined as :
;
;                X' = C X
;
;                The space three 1-2-3 means that the x rotation is first,
;                followed by the y rotation, then the z.
;
function GraphicsManip::_AngleFromTrans, transMatrix
  compile_opt idl2, hidden
  
  ;cosine direction matrix (3 x 3)
  cosMat = transMatrix[0:2, 0:2]
  
  ;  Compute the 3 angles (in degrees)
  ;
  cosMat = TRANSPOSE(cosMat)
  angle = DBLARR(3)
  angle[1] = -cosMat[2,0]
  angle[1] = ASIN(angle[1])
  c2 = COS(angle[1])
  if (ABS(c2) lt 1.0e-6) then begin
    angle[0] = ATAN(-cosMat[1,2], cosMat[1,1])
    angle[2] = 0.0
  endif else begin
    angle[0] = ATAN( cosMat[2,1], cosMat[2,2])
    angle[2] = ATAN( cosMat[1,0], cosMat[0,0])
  endelse
  angle = angle * (180.0/!DPI)
  
  RETURN, angle
  
end    ;   of _AngleFromTrans


;--------------------------------------------------------------------------
; Internal method to set rotation center, radius, constraint.
;
pro GraphicsManip::_InitRot, oWin
  compile_opt idl2, hidden
  
  ; Retrieve the center of rotation for each selected item,
  ; so we can cache it for efficiency.
  ; We will go thru the list backwards so that oVis will end
  ; up with the primary selection.
  *self.pCenterRotation = DBLARR(3, self.nSelectionList)
  for i=self.nSelectionList-1,0,-1 do begin
    oVis = (*self.pSelectionList)[i]
    oVis->GetProperty, CENTER_OF_ROTATION=centerRotation
    (*self.pCenterRotation)[*,i] = centerRotation
  endfor
  
  ; Convert the data coordinates for the scaling center
  ; to device coordinates.
  oVis->_IDLitVisualization::VisToWindow, $
    centerRotation, screenCenter
  self.screenCenter = screenCenter[0:1]
  
  ; Override constraint axis if not 3D.
  self.is3D = oVis->Is3D()
  
  ; Retrieve the overall viz range, to use for rot radius.
  if(obj_isa(oVis, "IDLitVisNormDataSpace"))then $
    oVis = oVis[0]->GetDataspace(/UNNORMALIZED)
  if (oVis->GetXYZRange(xrange, yrange, zrange)) then begin
    oVis->_IDLitVisualization::VisToWindow, $
      xrange, yrange, zrange, xWin, yWin, zWin
    radius = SQRT((xWin[1]-xWin[0])^2 + (yWin[1]-yWin[0])^2)
  endif
  
  ; If we don't have a radius, use the screen size as the default.
  if (N_ELEMENTS(radius) lt 1) then begin
    ; Use the Viewgroup viewport dimensions and locations.
    oViewgroup = oWin->GetCurrentView()
    dimensions = oViewgroup->GetViewport(oWin, LOCATION=location)
    radius = 0.5*SQRT(TOTAL(dimensions^2d))
  endif
  
  self.radius = radius
  
  if (~self.is3D) then begin
    ; Convert from the transform matrix back to a Z rotation.
    ; This takes into account translations and scaling,
    ; but assume no rotations have ever occurred about X or Y.
    ; Should this be a GetCTM instead, in case the parent is rotated?
    oVis[0]->GetProperty, TRANSFORM=transform
    ; Rotate an x-unit vector, and find its angle relative
    ; to the X axis.
    xrotate = transform ## [1d,0,0,0]
    self.angle = (180/!DPI)*ATAN(xrotate[1], xrotate[0])
    ; Note: Do we want to restrict to integer values?
    self.angle = ROUND(self.angle)
  endif

end


;--------------------------------------------------------------------------
; GraphicsManip::_Rotate
;
; Purpose:
;   This method performs rotation
;
pro GraphicsManip::_Rotate, oWin, x, y, KeyMods, TYPE=type
  compile_opt idl2, hidden

  ; Retrieve previous coordinates.
  pt0 = self.pt0
  ; Calculate distance of mouse click from center of rotation.
  xy = ([x, y] - self.screencenter) / self.radius
  
  ; Normalize to unit length.
  r = TOTAL(xy^2)
  pt1 = (r GT 1.0) ? [xy/SQRT(r) ,0d] : [xy,SQRT(1.0-r)]
  
  ; Constrain if necessary.
  constrainAxis = self.is3D ? self.constrainAxis : 2
  if (constrainAxis ge 0) then $
    pt1 = self->_Constrain(pt1, constrainAxis, TYPE=type)
    
  ; Store new coordinates.
  self.pt0 = pt1
  
  ; OnMouseDown (button was pressed). Don't actually rotate.
  if (type eq 0) then begin
    self.startXY = [x, y]
    RETURN
  endif
  
  ; If we havn't moved then return.
  if (ARRAY_EQUAL(pt0, pt1)) then $
    RETURN
    
  if (self.is3D) then begin   ; 3D arbitrary rotation
  
    ; Compute transformation.
    q = CROSSP(pt0,pt1)
    x = q[0]
    y = q[1]
    z = q[2]
    w = TOTAL(pt0*pt1)
    
    rotateTransform = [ $
      [ w^2+x^2-y^2-z^2, 2*(x*y-w*z), 2*(x*z+w*y), 0], $
      [ 2*(x*y+w*z), w^2-x^2+y^2-z^2, 2*(y*z-w*x), 0], $
      [ 2*(x*z-w*y), 2*(y*z+w*x), w^2-x^2-y^2+z^2, 0], $
      [ 0          , 0          , 0              , 1]]

    ; Loop through all selected visualizations.
    for i=0,self.nSelectionList-1 do begin
      oVis = (*self.pSelectionList)[i]
      
      ; No rotation of axes
      if (self.nSelectionList gt 1 && $
          OBJ_ISA(oVis, 'IDLitVisAxis')) then continue

      ; No rotation of dataspace text
      isText = ISA(oVis, 'IDLitVisText')
      if (isText) then begin
        ID = oVis->GetFullIdentifier()
        if (STRPOS(ID, 'DATA SPACE') ne -1) then continue
      endif

      ;; Translate so the center of rotation is at [0,0,0]
      oVis->GetProperty, TRANSFORM=currentTransform
      
      ;; Transform center of rotation by current transform
      centerRotation = (*self.pCenterRotation)[*,i]
      cr = [centerRotation, 1.0d] # currentTransform
      
      ;; Perform translate, rotate, translate back transform
      t1 = IDENTITY(4)
      t1[3,0] = -cr[0]
      t1[3,1] = -cr[1]
      t1[3,2] = -cr[2]
      t2 = IDENTITY(4)
      t2[3,0] = cr[0]
      t2[3,1] = cr[1]
      t2[3,2] = cr[2]
      oVis->GetProperty, TRANSFORM=oldTransform
      transform = oldTransform # t1 # rotateTransform # t2
      oVis->SetProperty, TRANSFORM=transform
    endfor
    
    angles = self->_AngleFromTrans(rotateTransform)
    
    ; accumulate the total angle for the overall rotation
    self.totalAngle = (self.totalAngle + angles) mod 360
    
  endif else begin  ; 2D rotation about Z axis
  
    if (N_ELEMENTS(angle) eq 0) then begin
      angle = (180/!DPI)*ASIN(pt0[0]*pt1[1]-pt0[1]*pt1[0])
      
      ; Check for <Shift> key.
      angle = (N_ELEMENTS(KeyMods) && (KeyMods and 1)) ? $
        FIX(angle/15)*15 : FIX(angle)
    endif
    
    ; Since we changed from an arbitrary angle to an integerized
    ; angle, we need to adjust our current saved position.
    ; Otherwise our mouse location will get out of sync and will
    ; appear to be rotating quicker than the viz itself.
    cosA = COS(angle*!DPI/180)
    sinA = SIN(angle*!DPI/180)
    self.pt0 = [pt0[0]*cosA - pt0[1]*sinA, pt0[0]*sinA + pt0[1]*cosA]
    
    ; This will cache our new angle, update the status area,
    ; and perform the rotation.
    self->_Rotate2D, angle
    
    ; x & y rotation = 0
  endelse  ; 2D

end

;--------------------------------------------------------------------------
; GraphicsManip::_DoZoom
;
; Purpose:
;   Zooms dataspace based on box corner locations
;
; Parameters
;  oWin - Source of the event
;  corner1 - X,Y coordinates of the starting corner
;  corner2 - X,Y coordinates of the ending corner
;  oCmd - [out], newly created command set
;
pro GraphicsManip::_DoZoom, oWin, corner1, corner2, oCmd
  compile_opt idl2, hidden

  ; Make sure we have a tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return

  ; Get Dataspace
  oSel = (oWin->GetSelectedItems())[0]
  if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
    oDS = oSel->GetDataSpace()
  if (~OBJ_VALID(oDS)) then return

  ; Convert window coords to dataspace coords
  oDSObj = (oDS->Get())[0]
  oDSObj->WindowToVis, [corner1[0],corner2[0]], [corner1[1],corner2[1]], $
    xdata, ydata
    
  ; Set new minimum and maximum values
  oDS->GetProperty, X_MINIMUM=xMin, X_MAXIMUM=xMax, $
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax, XLOG=xLog, YLOG=yLog

  ; Handle logarithmic axes, if necessary.
  if (KEYWORD_SET(xLog)) then begin
    xMin = ALOG10(xMin)
    xMax = ALOG10(xMax)
  endif
  if (KEYWORD_SET(yLog)) then begin
    yMin = ALOG10(yMin)
    yMax = ALOG10(yMax)
  endif

  newXmax = (xMax gt xMin) ? MAX(xdata, MIN=newXmin) : MIN(xdata, MAX=newXmin)      
  newYmax = (yMax gt yMin) ? MAX(ydata, MIN=newYmin) : MIN(ydata, MAX=newYmin)      

  if (KEYWORD_SET(xLog)) then begin
    newXmin = 10d^newXmin
    newXmax = 10d^newXmax
  endif
  if (KEYWORD_SET(yLog)) then begin
    newYmin = 10d^newYmin
    newYmax = 10d^newYmax
  endif

  ; Adjust for isotropy
  if (oDS->IsIsotropic()) then begin
    currAspect = ABS((yMax-yMin)/(xMax-xMin))
    xRange = newXmax-newXmin
    yRange = newYmax-newYmin
    newAspect = ABS(yRange/xRange)
    if (currAspect lt newAspect) then begin
      newXrange = yRange/currAspect
      newXmax += (newXrange-xRange)/2
      newXmin -= (newXrange-xRange)/2
    endif else begin
      newYrange = xRange*currAspect
      newYmax += (newYrange-yRange)/2
      newYmin -= (newYrange-yRange)/2
    endelse
  endif
  
  oCmd = self->_SetDataspaceRange(oDS, newXmin, newXmax, newYmin, newYmax)
  
end


;--------------------------------------------------------------------------
; GraphicsManip::_Zoom
;
; Purpose:
;   This method performs zooming
;
pro GraphicsManip::_Zoom, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; Sanity check.
  if (~self.ButtonPress || ~OBJ_VALID(self._oRectangle)) then begin
    return
  endif
  
  x0 = self._startPt[0]
  y0 = self._startPt[1]
  ; Don't allow rectangles of zero width/height.
  if (x eq x0) || (y eq y0) then $
    return
  x1 = x
  y1 = y
  
  self._endPt[0] = x1
  self._endPt[1] = y1

  ;; Add the Z so that values are in the annotation layer and
  ;; not clipped by the Viz.
  z = self._normalizedZ
  
  ; Reorder the points if necessary.
  if (x0 gt x1) then begin
    tmp = x0
    x0 = x1
    x1 = tmp
  endif
  if (y0 gt y1) then begin
    tmp = y0
    y0 = y1
    y1 = tmp
  endif
  
  ; If we havn't been added yet, then add ourself.
  self._oRectangle->GetProperty, PARENT=oParent
  if (~OBJ_VALID(oParent)) then $
    oWin->Add, self._oRectangle, layer='ANNOTATION'
    
  xydata = [[x0,y0,z], [x1,y0,z], [x1,y1,z], [x0,y1,z]]
  self._oRectangle->_IDLitVisualization::WindowToVis, xydata, xyout
  
  ; Update the rectangle.
  self._oPolyline->SetProperty, DATA=[[xyout], [xyout[*,0]]]
  
  ; xmin, xmax, ymin, ymax
  xystr = STRCOMPRESS(STRING(xyout[[0,3,1,7]], FORMAT='(G11.4)'))
  str = STRING(xystr,FORMAT='("X: ",A,",",A,"  Y: ",A,",",A)')

  ; Update the graphics hierarchy.
  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow

end

;--------------------------------------------------------------------------
; GraphicsManip::_Pan
;
; Purpose:
;   This method performs data panning
;
pro GraphicsManip::_Pan, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  deltaX = x - self._currentXY[0]
  deltaY = y - self._currentXY[1]
  
  ; Check for <Shift> key.
  if ((KeyMods and 1) ne 0) then begin
    ; See if we need to initialize the constraint.
    ; The biggest delta (x or y) wins, until <Shift> is released.
    if (~self._xyConstrain) then $
      self._xyConstrain = (ABS(deltaX) gt ABS(deltaY)) ? 1 : 2
    ; Apply the constraint.
    if (self._xyConstrain eq 1) then $
      deltaY = 0 $
    else $
      deltaX = 0
  endif else begin
    self._xyConstrain = 0   ; turn off constraint
  endelse
  
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then $
    return
  oDesc = oTool->GetByIdentifier('/Registry/MacroTools/DataPan')
  if (~OBJ_VALID(oDesc)) then $
    return
  oPan = oDesc->GetObjectInstance()
  
  panStr = oPan->DoPan(oWin, deltaX, deltaY)
  
  if (panStr) then $
    self->ProbeStatusMessage, panStr
  
  self._currentXY = [x, y]

end

;-------------------------------------------------------------------------
; GraphicsManip::_Line
;
; Purpose:
;   This method performs line vertex manipulation
;
pro GraphicsManip::_Line, oWin, x, y, KeyMods
  compile_opt idl2, hidden
  
  if (self.nSelectionList gt 0) && (self.point le 1) then begin
  
    oVis = (*self.pSelectionList)[0]

    newXY = [x, y]   ; Default is to simply move to new point.
    
    ; Retrieve both starting & end point.
    points = oVis->GetVertex([0,1], /WINDOW)
    zvalue = (points[2,0] ne 0) ? self._normalizedZ : 0
    ; If the line is in the dataspace instead of the annotation layer
    ; then a super small, but non-zero value for z changes the display
    ; to 3D.  Check for that condition.
    if (ABS(zvalue) lt (MACHAR()).EPS) then $
      zvalue = 0
    ptClick = points[0:1,self.point]
    ptOther = points[0:1,1 - self.point]
    
    ; <Shift> key forces constrained scaling along the line.
    if (KeyMods and 1) then begin
    
      ; Distance from start XY to the further point.
      lineXYother = self.prevXY - ptOther
      distOther = SQRT(TOTAL(lineXYother^2))
      
      if (distOther) then begin
        ; Project the line from the further pt to the current XY
        ; down onto the line connecting the two points,
        ; using the dot product.
        projection = $
          TOTAL((newXY - ptOther)*lineXYother) / distOther
        newXY = ptOther + (projection/distOther)*lineXYother
      endif
      
    endif
    
    newPoints = [newXY, zvalue]
    pointIndex = self.point
    
    ; <Ctrl> key forces constrained scaling about the center.
    if ((KeyMods and 2) ne 0) then begin
      otherXY = ptOther + (ptClick - newXY)
      newPoints = [[newPoints], [otherXY, zvalue]]
      pointIndex = [pointIndex, 1 - self.point]
    endif
    
    ; Move vertex location(s). This will also update the graphics.
    oVis->MoveVertex, newPoints, INDEX=pointIndex, /WINDOW
    
    ; Find length and angle and report in status area.
    xy1 = newPoints[*,0]
    xy0 = (N_ELEMENTS(pointIndex) eq 2) ? $
      newPoints[*,1] : ptOther
    length = LONG(SQRT(TOTAL((xy1[0:1] - xy0[0:1])^2)))
    angle = (180/!DPI)*ATAN(xy1[1]-xy0[1], xy1[0]-xy0[0])
    angle = LONG(((angle+360) mod 360)*100)/100d
    self->ProbeStatusMessage, STRING(x, y, length, angle, $
      FORMAT='(%"[%d,%d]   %d   %g")') + STRING(176b)
      
    ; Cache our new starting location.
    self.prevXY = newXY
    
  endif
  
end

;--------------------------------------------------------------------------
; GraphicsManip::_AutoSwitch
;
; Purpose:
;   This function method gets the cursor type.
;
pro GraphicsManip::_AutoSwitch, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; If a button is held down, just see if the cursor has changed,
  ; due to different KeyMods. Then return.
  if (self.ButtonPress gt 0) then begin
    cursorName = self->GetCursorType(self._subtype, KeyMods)
    oWin->SetCurrentCursor, cursorName ne '' ? cursorName : $
      self._defaultCursor        ;default name.
    return
  endif

  ; The rest of this method is to change cursors if needed.
  cursorName = 'ARROW'
  currentManip = ''
  statusLoc = ''
  statusMsg = ''

  if (self.nSelectionList ne 0) then begin
    ; Check to see if we hit any visuals
    oVisHitList = oWin->DoHitTest(x, y, DIMENSIONS=[9,9], /ORDER, $
      SUB_HIT=oSubHitList, VIEWGROUP=oView)
    void = CHECK_MATH()  ; swallow underflow errors
    oVisHit = oVisHitList[0]   ; just check first item

    if OBJ_VALID(oVisHit) && OBJ_ISA(oVisHit, '_IDLitVisualization') then begin
      ; Check if a manipulator visual has been hit.
      ; This code is the same as that in
      ; IDLitManipulatorContainer::OnMouseDown.
      cursorName = 'PAN'
      oManipVis = OBJ_NEW()
      if (OBJ_ISA(oVisHit, 'IDLitManipulatorVisual')) then begin
        oManipVis = oVisHit
      endif else begin
        n = N_ELEMENTS(oSubHitList)
        for i=0,n-1 do begin
          if OBJ_ISA(oSubHitList[i], 'IDLitManipulatorVisual') then begin
            ; Here is our manipulator visual.
            oManipVis = oSubHitList[i]
            ; Only keep the subvis's after the manip visual.
            oSubHitList = oSubHitList[(i+1)< (n-1):*]
            break        ; we're done
          endif
        endfor
      endelse

      oDS = oVisHit->GetDataSpace()
      if (OBJ_VALID(oDS)) then begin
        oWin->GetProperty, VISIBLE_LOCATION=vLocation
        oVisHit->WindowToVis, x - vLocation[0], y - vLocation[1], 0, $
          xdata, ydata, zdata
        statusLoc = oVisHit->GetDataString([xdata, ydata, zdata])
        if (oDS->Is3D()) then begin
          cursorName = 'ROTATE'
          currentManip = 'rotate'
        endif else begin
          cursorName = (ISA(KeyMods) && (KeyMods eq 1)) ? $
            'RANGE_ZOOM' : 'DATAPAN'
          currentManip = (ISA(KeyMods) && (KeyMods eq 1)) ? 'zoom' : 'pan'
        endelse
        oLayer = OBJ_VALID(oDS) ? oDS->_GetLayer() : []
        if (OBJ_VALID(oLayer) && $
            (OBJ_ISA(oLayer,'IDLitgrAnnotateLayer'))) then begin
          cursorName = 'TRANSLATE'
          currentManip = 'translate'  
        endif
        if (OBJ_ISA(oVisHit, 'IDLitVisAxis')) then begin
          cursorName = 'TRANSLATE'
          currentManip = 'translate'
        endif
      endif else begin
        ; Do a pickdata to retrieve the data coordinates.
        oLayer = oView->GetCurrentLayer()
        ; Use a 9x9 pickbox to match our selection pickbox.
        result = oWin->Pickdata(oLayer, oVisHit, [x, y], xyz, $
          DIMENSIONS=[9,9], PICK_STATUS=pickStatus)
        if (result eq 1) then begin
          ; Start from middle of array and work outwards to find
          ; the hit closest to the center.
          for n=0,4 do begin
            good = (WHERE(pickStatus[4-n:4+n,4-n:4+n] eq 1))[0]
            if (good ge 0) then begin
              ; index into the subrect of the original 9x9,
              ; the width of the subrect is 2n+1.
              indexX = 4 - n + (good mod (2*n+1))
              indexY = 4 - n + (good /   (2*n+1))
              statusLoc = oVisHit->GetDataString( $
                xyz[*, indexX, indexY])
              break
            endif
          endfor
        endif
      endelse

      ; If we hit a manipulator visual, change the current
      ; manipulator.
      if (OBJ_VALID(oManipVis)) then begin
      
        ; Set the cursor using the manipulator type.
        ; Check for global manipulator first.
        type = oManipVis->GetSubHitType(oSubHitList)
        cursorName = self->GetCursorType(type, KeyMods, $
                                         CURRENT_MANIP=currentManip)
        statusMsg = self->GetStatusMessage(type, KeyMods, $
          /FOR_SELECTION)
        self->SetCurrentManipulator, type
      endif else begin         ;we are over a selected item
      
        ; Are any items selected?
        oSelectedVis = (oWin->GetSelectedItems())[0]
        
        ; If the Manipulator Targets for the selected item and the
        ; hit item are the same, then assume we are allowed to manipulate
        ; the hit item, and change the cursor.
        if (OBJ_VALID(oSelectedVis) && $
          ARRAY_EQUAL(self->_FindManipulatorTargets(oSelectedVis), $
          self->_FindManipulatorTargets(oVisHit))) then begin
          oSelectionVisual = $
            oSelectedVis->GetCurrentSelectionVisual()
          if (OBJ_VALID(oSelectionVisual)) then begin
            ; Set the cursor using the manipulator type.
            type = oSelectionVisual->GetSubHitType(oSubHitList)
            if (type ne '') then begin
              cursorName = self->GetCursorType(type, KeyMods, $
                                               CURRENT_MANIP=currentManip)
              statusMsg = self->GetStatusMessage(type, KeyMods, $
                                                 /FOR_SELECTION)
            endif
          endif
        endif else $
          statusMsg = self->GetStatusMessage('', KeyMods)
          
        ; If no status message yet, retrieve the hit viz name.
        if (statusMsg eq '') then begin
          oStatusVis = oVisHit->GetHitVisualization(oSubHitList)
          oStatusVis->IDLitComponent::GetProperty, NAME=statusMsg
        endif
        
      endelse                  ; look for selected items
    endif
  endif
  
  ; Display the location in the status area.
  if (statusLoc eq '') then begin
    oWin->GetProperty, VISIBLE_LOCATION=visibleLoc
    statusLoc = STRING(FORMAT='(%"[%d,%d]")', $
      visibleLoc[0]+x, visibleLoc[1]+y)
  endif
  self->ProbeStatusMessage, statusLoc
  
  ; If we don't have a status message, use our own description.
  if (statusMsg eq '') then $
    self->IDLitComponent::GetProperty, DESCRIPTION=statusMsg

  ; Update the status message.
  self->StatusMessage, statusMsg
  ; Finally, set the cursor.
  oWin->SetCurrentCursor, cursorName ne '' ? cursorName : 'ARROW'
  self._currentManip = currentManip

end


;--------------------------------------------------------------------------
; GraphicsManip::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function GraphicsManip::GetCursorType, typeIn, KeyMods, $
  CURRENT_MANIP=currentManip
  compile_opt idl2, hidden

  switch strupcase(typeIn) of
    'SCALE/+X':
    'SCALE/-X': 
    'SCALE/+Y_ROT':
    'SCALE/-Y_ROT': begin
      currCur = 'SIZE_EW'
      currentManip = 'scale'
      break
    end
    
    'SCALE/+Y':
    'SCALE/-Y':
    'SCALE/+Z':
    'SCALE/-Z':
    'SCALE/+X_ROT':
    'SCALE/-X_ROT':
    'SCALE/+Z_ROT':
    'SCALE/-Z_ROT': begin
      currCur = 'SIZE_NS'
      currentManip = 'scale'
      break
    end
    
    'SCALE/+X+Y':
    'SCALE/-X-Y':
    'SCALE/-X+Y_ROT':
    'SCALE/+X-Y_ROT': begin
      currCur = 'SIZE_NE'
      currentManip = 'scale'
      break
    end
    
    'SCALE/-X+Y':
    'SCALE/+X-Y':
    'SCALE/+X+Y_ROT':
    'SCALE/-X-Y_ROT': begin
      currCur = 'SIZE_SE'
      currentManip = 'scale'
      break
    end
    
    'SCALE/XYZ':
    'SCALE/XYZ_ROT': begin
      currCur = 'Scale3D'
      currentManip = 'scale'
      break
    end
    
    'ROTATE': begin
      currCur = 'Rotate'
      currentManip = 'rotate'
      break
    end
    
    'SCALE/XY':
    'SCALE/XZ':
    'SCALE/YZ':
    'TRANSLATE': begin
      currCur = 'Translate'
      currentManip = 'translate'
      break
    end
    
    'ZOOM': begin
      currCur = 'Range_zoom'
      currentManip = 'zoom'
      break
    end
    
    'PAN': begin
      currCur = 'DataPan'
      currentManip = 'pan'
      break
    end
    
    'GRAB': begin
      currCur = 'Grab'
      break
    end
    
    'CROSSHAIR': begin
      currCur = 'Crosshair'
      break
    end
    
    'LINE/VERT0':
    'LINE/VERT1': begin
      currCur = 'SIZE_SE'
      currentManip = 'line'
      break
    end
    
    else: currCur = ''
  endswitch

  return, currCur

end


;--------------------------------------------------------------------------
; GraphicsManip::_DoRegisterCursor
;
; Purpose:
;   This procedure method registers the cursors used by this manipulator.
;
pro GraphicsManip::_DoRegisterCursor

  compile_opt idl2, hidden
  
  strArray = [ $
    '       ##       ', $
    '   ## #..###    ', $
    '  #..##..#..#   ', $
    '  #..##..#..# # ', $
    '   #..#..#..##.#', $
    '   #..#..#..#..#', $
    ' ## #.......#..#', $
    '#..##..........#', $
    '#...#.........# ', $
    ' #............# ', $
    '  #...........# ', $
    '  #..........#  ', $
    '   #.........#  ', $
    '    #.......#   ', $
    '     #......#   ', $
    '                ']
  self->RegisterCursor, strArray, 'DataPan'
  
  strArray = [ $
    '                ', $
    '                ', $
    '       ###      ', $
    '    ###..###    ', $
    '   #..#..#..##  ', $
    '   #..#..#..#.# ', $
    '   ##.......#..#', $
    '   ##..........#', $
    '  #.#.........# ', $
    ' #............# ', $
    '  #...........# ', $
    '  #..........#  ', $
    '   #.........#  ', $
    '    #.......#   ', $
    '     #......#   ', $
    '                ']
  self->RegisterCursor, strArray, 'Grab'
  
  strArray = [ $
    '     .....      ', $
    '    .#####.     ', $
    '   .#.....#.    ', $
    '  .#.     .#.   ', $
    ' .#.       .#.  ', $
    ' .#.       .#.  ', $
    ' .#.   $   .#.  ', $
    ' .#.       .#.  ', $
    ' .#.       .#.  ', $
    '  .#..... .##.  ', $
    '   .#.....####. ', $
    '    .######..##.', $
    '     .... .#..#.', $
    '           .##. ', $
    '            ..  ', $
    '                ']
  self->RegisterCursor, strArray, 'Range_zoom'
  
  strArray = [ $
    '       .        ', $
    '      .#.       ', $
    '     .###.      ', $
    '    .#####.     ', $
    '   ....#....    ', $
    '  .#. .#. .#.   ', $
    ' .##...#...##.  ', $
    '.######$######. ', $
    ' .##...#...##.  ', $
    '  .#. .#. .#.   ', $
    '   ....#....    ', $
    '    .#####.     ', $
    '     .###.      ', $
    '      .#.       ', $
    '       .        ', $
    '                ']
  self->RegisterCursor, strArray, 'Translate', /DEFAULT
  
  strArray = [ $
    '       .        ', $
    '      .#.       ', $
    '     .##..      ', $
    '    .$####.     ', $
    '     .##..#.    ', $
    '      .#. .#.   ', $
    '       .   .#.  ', $
    '  .        .#.  ', $
    ' .#.       .#.  ', $
    ' .#.       .#.  ', $
    ' .#.       .#.  ', $
    '  .#.     .#.   ', $
    '   .#.....#.    ', $
    '    .#####.     ', $
    '     .....      ', $
    '                ']
  self->RegisterCursor, strArray, 'Rotate'

end


;--------------------------------------------------------------------------
; GraphicsManip::GetStatusMesssage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given type.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   typeIn <Optional> - String representing the current type.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
function GraphicsManip::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    return, IDLitLangCatQuery('Status:Manip:Scale')
end


;---------------------------------------------------------------------------
; GraphicsManip::SetCurrentManpulator
;
; Purpose:
;   Used to set the current manipulator in the manipulator
;   hierarchy.
;
;   A manipulator object or a relative IDENTIFER to a manipulator is
;   provided to identify the target object.
;
; Paramaters:
;    Manipulator String - Relative ID to the target manipulator
;                object - Target manpulator. Must be
;                         isa(_IDLitManipulator)
;
; Keywords:
;   None.
pro GraphicsManip::SetCurrentManipulator, type, VISUALIZATION=oVis
  compile_opt idl2, hidden

  ;;;;;;;; Scaling code ;;;;;;;;;;;;;;;;;;;;;;;
  if (ISA(type, 'STRING')) then begin
    ; Assume all scaling constraints.
    self.scaleConstraint  = [0, 0, 0]
    ; Assume no corner constraints.
    self.cornerConstraint = [-1, -1, -1]
    if (N_ELEMENTS(type) gt 0) then begin
        if (STRPOS(type, 'X') ge 0) then self.scaleConstraint[0] = 1
        if (STRPOS(type, 'Y') ge 0) then self.scaleConstraint[1] = 1
        if (STRPOS(type, 'Z') ge 0) then self.scaleConstraint[2] = 1
        if (STRPOS(type, '+X') ge 0) then self.cornerConstraint[0] = 0
        if (STRPOS(type, '-X') ge 0) then self.cornerConstraint[0] = 1
        if (STRPOS(type, '+Y') ge 0) then self.cornerConstraint[1] = 0
        if (STRPOS(type, '-Y') ge 0) then self.cornerConstraint[1] = 1
        if (STRPOS(type, '+Z') ge 0) then self.cornerConstraint[2] = 0
        if (STRPOS(type, '-Z') ge 0) then self.cornerConstraint[2] = 1
        self._initialType = type
    endif
    if ((pos=STRPOS(type, 'VERT')) ge 0) then self.point = $
      LONG(STRMID(type, pos+4))
  endif

  ;;;;;;; Generic code ;;;;;;;;;;;;;;;;;;;;;;;
  if (OBJ_VALID(Manipulator)) then begin
    ; Assume argument is a valid manipulator object.
    Manipulator->SetCurrentManipulator
  endif else begin
    ; If this string is '', just get the first element and
    ; set it as current
    if (~KEYWORD_SET(Manipulator)) then begin
      oDS = OBJ_VALID(oVis) ? oVis[0]->GetDataSpace() : []
      oLayer = OBJ_VALID(oDS) ? oDS->_GetLayer() : []
      pos = (OBJ_VALID(oLayer) && (OBJ_ISA(oLayer,'IDLitgrAnnotateLayer')))
      oManip = self->IDLitContainer::Get(POSITION=pos, count=nItems)

      oManip = self.oSelect
      if (nItems eq 0) then return ; no reason to continue
      ; Only change manipulator if necessary.
      ; Helps prevent flashing of selection visuals.
      if (oManip ne self->GetCurrentManipulator()) then $
        oManip->SetCurrentManipulator
    endif else begin
      ; pop off the next string
      strItem = IDLitBasename(Manipulator, remainder=strRemain, $
        /reverse)
      oManip = self->IDLitContainer::GetByIdentifier(strItem)
      if(obj_valid(oManip))then $
        oManip->SetCurrentManipulator, strRemain
    endelse
  endelse

end


;--------------------------------------------------------------------------
; GraphicsManip::GetStatusMessage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given manipulator
;   identifier.
;
;   Note: this method overrides the implementation provided by
;   the IDLitManipulatorContainer superclass.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   ident   - Optional string representing the current identifier.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
; Keywords:
;   FOR_SELECTION: Set this keyword to a non-zero value to indicate
;     that the mouse is currently over an already selected item
;     whose manipulator target can be manipulated by this manipulator.
;
function GraphicsManip::GetStatusMessage, ident, KeyMods, $
    FOR_SELECTION=forSelection
  compile_opt idl2, hidden
  
  if (~self.m_bAutoSwitch) then $
    return, ''
    
  if (~KEYWORD_SET(ident)) then begin
    oManipOver = self->IDLitContainer::Get()  ;; first manip
    type =''
  endif else begin
    ; Pop off the next string
    strItem = IDLitBasename(ident, REMAINDER=type, /REVERSE)
    oManipOver = self->IDLitContainer::GetByIdentifier(strItem)
    
    ; If we failed to get the manipulator by type, try to just
    ; get the first manipulator in the container (the default).
    if (~OBJ_VALID(oManipOver)) then $
      oManipOver = self->IDLitContainer::Get()
  endelse
  
  if (OBJ_VALID(oManipOver)) then begin
    if (KEYWORD_SET(forSelection)) then begin
      ; Call the method on the appropriate manipulator.
      return, oManipOver->GetStatusMessage(type, KeyMods, $
        FOR_SELECTION=forSelection)
    endif else $
      return, ''
  endif else begin
    self->SignalError, IDLitLangCatQuery('Error:Framework:InvalidManipId') + ident + '"'
    return, ''
  endelse
  
end


;---------------------------------------------------------------------------
; GraphicsManip__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro GraphicsManip__Define
  compile_opt idl2, hidden
  
  void = {GraphicsManip, $
          inherits IDLitManipulatorContainer, $
          _currentManip : '', $
          oSelect : OBJ_NEW(), $
          oManipSelectBox : OBJ_NEW(), $
          _oSetProperty: OBJ_NEW(), $
          _oCmd: OBJ_NEW(), $
          ; Scale
          _initialType: '', $
          _initialKeymods: 0L, $
          _oTarget: OBJ_NEW(), $
          startXY: [0d, 0d], $
          prevXY: [0d, 0d], $
          scaleFactors: [0d, 0d, 0d], $
          scaleConstraint: [0, 0, 0], $
          cornerConstraint: [0, 0, 0], $
          is3D: 0b, $
          ; Translate
          xyConstrain: 0b, $   ; am I constrained in the X or Y dir?
          pTransInfo: PTR_NEW(), $
          ; Rotate
          constrainVector: [0d, 0d, 0d], $
          constrainAxis: 0, $
          pCenterRotation: PTR_NEW(), $
          screencenter: [0d, 0d], $
          radius: 0d, $
          angle: 0d, $
          totalAngle: [0d, 0d, 0d], $
          pt0: [0d, 0d, 0d], $
          ; Zoom
          _startPt: [0, 0], $
          _endPt: [0, 0], $
          _oRectangle: OBJ_NEW(), $
          _oPolyline: OBJ_NEW(), $
          oCurrView: OBJ_NEW(), $ ; Reference to view to be zoomed
          ; Pan
          _startXY: DBLARR(2),       $ ; Initial window location.
          _currentXY: DBLARR(2),     $
          _axesHide:0,               $
          _axesStyle:0,              $
          _axesTransparency:0,       $
          _xyConstrain: 0b,          $
          _keyDown: 0b,               $
          ; Line
          point: 0L $
         }
    
end
