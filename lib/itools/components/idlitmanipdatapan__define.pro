; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipdatapan__define.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Class Name:
;   IDLitManipDataPan
;
; Purpose:
;   This class represents a manipulator used to pan within views.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
; IDLitManipDataPan::Init
;
; Purpose:
;   This function method initializes the object.
;
; Return Value:
;   This method returns a 1 on success, or 0 on failure.
;
; Keywords:
;   This method accepts all keywords suppored by the ::Init method
;   of this object's superclass.
;
function IDLitManipDataPan::Init, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  
  ; Initialize our superclass.
  iStatus = self->IDLitManipulator::Init( $
                                         VISUAL_TYPE="Select", $
                                         TYPES="_VISUALIZATION", $
                                         NUMBER_DS='1', $
                                         IDENTIFIER="DATAPAN", $
                                         NAME="DataPan", $
                                         /WHEEL_EVENTS, $
                                         _EXTRA=_extra)
  if (iStatus eq 0) then $
    return, 0
    
  ; Register the default cursor for this manipulator.
  self->IDLitManipDataPan::_DoRegisterCursor
  
  ; Set properties.
  self->IDLitManipDataPan::SetProperty, _EXTRA=_extra
  
  return, 1

end


;--------------------------------------------------------------------------
; IDLitManipDataPan::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitManipDataPan::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;---------------------------------------------------------------------------
; Manipulator Interface
;---------------------------------------------------------------------------

;--------------------------------------------------------------------------
; IDLitManipDataPan::OnMouseDown
;
; Purpose:
;   This procedure method handles notification of a mouse down.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
pro IDLitManipDataPan::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    _EXTRA=_extra
    
  compile_opt idl2, hidden
  
  ; Call our superclass.
  self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    
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
  
end


;--------------------------------------------------------------------------
pro IDLitManipDataPan::SetProperty, HIDE=hide, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  
  if (N_ELEMENTS(hide) eq 1) then begin
    ; Make sure we have a tool.
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then return
    
    ; Get Dataspace
    oSel = (oWin->GetSelectedItems())[0]
    if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
      oDS = oSel->GetDataSpace()
    if (OBJ_VALID(oDS)) then oAxes = oDS->GetAxes(/CONTAINER)
    if (OBJ_VALID(oAxes)) then begin
      if (hide) then begin
        oAxes->SetProperty, HIDE=self._axesHide, AXIS_STYLE=self._axesStyle, $
          TRANSPARENCY=self._axesTransparency
      endif else begin
        oAxes->GetProperty, HIDE=axesHide, AXIS_STYLE=axesStyle, $
          TRANSPARENCY=axesTransparency
        self._axesHide = axesHide
        self._axesStyle = axesStyle
        self._axesTransparency = axesTransparency
        oAxes->SetProperty, HIDE=0
        if (axesStyle eq 0) then $
          oAxes->SetProperty, AXIS_STYLE=2
        if (axesTransparency gt 90) then $
          oAxes->SetProperty, TRANSPARENCY=90
      endelse
    endif
  endif
  
  self->IDLitManipulator::SetProperty, HIDE=hide, _EXTRA=_extra
  
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::_SetDataspaceRange
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
function IDLitManipDataPan::_SetDataspaceRange, oDS, xMin, xMax, $
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
pro IDLitManipDataPan::_CaptureMacroHistory, dx, dy, MOUSE_MOTION=mouseMotion
    
  compile_opt idl2, hidden
  
  if (dx eq 0 && dy eq 0) then $
    return
    
  oTool = self->GetTool()
  oSrvMacro = oTool->GetService('MACROS')
  if ~obj_valid(oSrvMacro) then $
    return
    
  oSrvMacro->GetProperty, $
    RECORDING=recording, $
    MANIPULATOR_STEPS=manipulatorSteps
    
  if recording && manipulatorSteps then begin
    if keyword_set(mouseMotion) then begin
      ; add each individual manipulation to macro
      ; don't add individual manipulation to history
      skipMacro = 0
      skipHistory = 1
    endif else begin
      ; overall added to history but not macro
      skipMacro = 1
      skipHistory = 0
    endelse
  endif else begin
    ; skip the individual manipulations
    if keyword_set(mouseMotion) then return
    ; add overall manipulation to both macro and history
    skipMacro = 0
    skipHistory = 0
  endelse
  
  idSrc = "/Registry/MacroTools/DataPan"
  oDesc = oTool->GetByIdentifier(idSrc)
  if obj_valid(oDesc) then begin
    oDesc->SetProperty, $
      X=dx, $
      Y=dy
    oSrvMacro->GetProperty, CURRENT_NAME=currentName
    oSrvMacro->PasteMacroOperation, oDesc, currentName, $
      SKIP_MACRO=skipMacro, $
      SKIP_HISTORY=skipHistory
  endif
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::OnMouseUp
;
; Purpose:
;   This procedure method handles notification of a mouse up.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipDataPan::OnMouseUp, oWin, x, y, iButton
  compile_opt idl2, hidden
  
  self.ButtonPress = 0  ; button is up
  
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then $
    return
  oDesc = oTool->GetByIdentifier('/Registry/MacroTools/DataPan')
  if (~OBJ_VALID(oDesc)) then $
    return
  oPan = oDesc->GetObjectInstance()
  
  oCmdSet = oPan->EndPan(oWin, x, y)
  
  if OBJ_VALID(oCmdSet[0]) then $
    oTool->_TransactCommand, oCmdSet
    
  self->_CaptureMacroHistory, x - self._startXY[0], y - self._startXY[1]
  
  oWin->SetCurrentCursor, 'DataPan'
  
end


;--------------------------------------------------------------------------
; IDLitManipDataPan::OnMouseMotion
;
; Purpose:
;   This procedure method handles notification of a mouse motion.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button
;
pro IDLitManipDataPan::OnMouseMotion, oWin, x, y, KeyMods

  compile_opt idl2, hidden
  
  if (self.ButtonPress eq 0) then begin
    ; Simply pass control to superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
    return
  endif
  
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
    
  self->_CaptureMacroHistory, deltaX, deltaY, /MOUSE_MOTION
  
  self._currentXY = [x, y]
  
end


;--------------------------------------------------------------------------
pro IDLitManipDataPan::_HandleArrowKey, oWin, $
      IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
    
  compile_opt idl2, hidden

  if (Press) then begin
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
      return
    oDesc = oTool->GetByIdentifier('/Registry/MacroTools/DataPan')
    if (~OBJ_VALID(oDesc)) then $
      return
    oPan = oDesc->GetObjectInstance()
    
    success = oPan->StartPan(oWin, x, y)
    
    if (~success) then $
      return
      
    case KeyMods of
      1: offset = 40
      2: offset = 2
      else: offset = 10
    endcase
    
    deltaX = 0
    deltaY = 0
    
    ; Do the translation.
    case KeyValue of
      5: deltaX = offset
      6: deltaX = -offset
      7: deltaY = -offset
      8: deltaY = offset
    endcase
    
    ; Call our internal method.
    panStr = oPan->DoPan(oWin, deltaX, deltaY)
    
    if (panStr) then $
      self->ProbeStatusMessage, panStr
      
    oCmdSet = oPan->EndPan(oWin, x + deltaX, y + deltaY)
    
    if OBJ_VALID(oCmdSet[0]) then $
      oTool->_TransactCommand, oCmdSet
      
    ; First press event.
    if (~self._keyDown) then begin
      self._keyDown = 1b
      self._startXY = [x, y]
      self._currentXY = [x, y]
      self->StatusMessage, IDLitLangCatQuery('Status:Manip:Rotate3D1')
    endif
    
    self._currentXY += [deltaX, deltaY]
    
  endif else begin
  
    ; When key is released, consider the delta to be from the current
    ; XY all the way back to the start.
    self._keyDown = 0b
    deltaX = self._currentXY[0] - self._startXY[0]
    deltaY = self._currentXY[1] - self._startXY[1]
    
  endelse
  
  self->_CaptureMacroHistory, deltaX, deltaY, MOUSE_MOTION=Press

end

;--------------------------------------------------------------------------
; IDLitManipDataPan::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Parameters
;      oWin        - Event Window Component
;      IsASCII     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
;
pro IDLitManipDataPan::OnKeyBoard, oWin, $
      IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
    
  compile_opt idl2, hidden
  
  if (KeyValue ge 5 && KeyValue le 8) then begin
    self->_HandleArrowKey, oWin, $
      IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
  endif else if (KeyValue eq 11) then begin
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then return
    void = oTool->DoAction("Operations/DataspaceReset")
  endif else if (Character eq 61 || Character eq 45) then begin
    if (Press && ((KeyMods or 2) ne 0)) then begin
      ; Get Dataspace
      oSel = (oWin->GetSelectedItems())[0]
      if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
        oDS = oSel->GetDataSpace()
      if (~OBJ_VALID(oDS)) then return
      oDS->GetProperty, X_MINIMUM=xMin, X_MAXIMUM=xMax, $
        Y_MINIMUM=yMin, Y_MAXIMUM=yMax
      self->_Zoom, oDS, (Character eq 61), 0.5*(xMin+xMax), 0.5*(yMin+yMax)
    endif
  endif

end


;--------------------------------------------------------------------------
pro IDLitManipDataPan::_Zoom, oDS, zoomIn, xdata, ydata
  compile_opt idl2, hidden

  ; Make sure we have a tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  ; zoom value
  zoomFactor = zoomIn ? 1/1.25d : 1.25d
  
  ; Get current ranges
  oDS->GetProperty, X_MINIMUM=xMin, X_MAXIMUM=xMax, $
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax
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
  
  oCmd = self->_SetDataspaceRange(oDS, newXmin, newXmax, newYmin, newYmax)

  oTool->RefreshCurrentWindow
  oTool->UpdateAvailability
  ; Add to undo/redo buffer
  if (PRODUCT(OBJ_VALID(oCmd))) then $
    oTool->_TransactCommand, oCmd


end

;--------------------------------------------------------------------------
; IDLitManipDataPan::OnWheel
;
; Purpose:
;   Implements the OnWheel method. This is a no-op and only used
;   to support the Window event interface.
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
pro IDLitManipDataPan::OnWheel, oWin, x, y, delta, keyMods
  compile_opt idl2, hidden
  
  ; Not at the same time as the bounding box
  if (self.ButtonPress) then return
  
  ; Get Dataspace
  oSel = (oWin->GetSelectedItems())[0]
  if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
    oDS = oSel->GetDataSpace()
  if (~OBJ_VALID(oDS)) then return

  oLayer = oDS->_GetLayer()
  if(obj_Isa(oLayer,'IDLitgrAnnotateLayer'))then return

  ; Convert window coords to dataspace coords
  oDSObj = (oDS->Get())[0]
  oDSObj->WindowToVis, x, y, xdata, ydata
  
  self->_Zoom, oDS, (delta gt 0), xdata, ydata

end


;--------------------------------------------------------------------------
; IDLitManipDataPan::_DoRegisterCursor
;
; Purpose:
;   This procedure method registers the cursors used by this manipulator.
;
pro IDLitManipDataPan::_DoRegisterCursor

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
  self->RegisterCursor, strArray, 'DataPan', /DEFAULT
  
  strArray = [ $
    '       ##       ', $
    '   ##.#..###    ', $
    '  #..##..#..#   ', $
    '  #..##..#..#.# ', $
    '   #..#..#..##.#', $
    '   #..#..#..#..#', $
    ' ##.#.......#..#', $
    '#..##..###.....#', $
    '#...#.#...#...# ', $
    '.#...#...#.#..# ', $
    '  #..#..#..#..# ', $
    '  #..#.#...#.#  ', $
    '   #..#...#..#  ', $
    '    #..###..#   ', $
    '     #......#   ', $
    '                ']
  self->RegisterCursor, strArray, 'NoGrab'
  
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
  
end

;-------------------------------------------------------------------------
; IDLitManipDataPan::QueryAvailability
;
; Purpose:
;   This function method determines whether this manipulator is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if this manipulator is applicable for the
;   selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None.
;
function IDLitManipDataPan::QueryAvailability, oTool, selTypes
  compile_opt idl2, hidden
  
  ; Use our superclass as a first filter.
  ; If not available by matching types, then no need to continue.
  success = self->IDLitManipulator::QueryAvailability(oTool, selTypes)
  if (~success) then return, 0

  ; Only on 2D dataspaces
  oWin = oTool->GetCurrentWindow()
  oSel = (oWin->GetSelectedItems())[0]
  if (OBJ_VALID(oSel) && OBJ_ISA(oSel, '_IDLitVisualization')) then $
    oDS = oSel->GetDataSpace()
  if (~OBJ_VALID(oDS)) then return, 0
  if (oDS->Is3D()) then return, 0
  
  return, 1
  
end


;---------------------------------------------------------------------------
; IDLitManipDataPan__Define
;
; Purpose:
;   Define the object structure for the IDLitManipDataPan class.
;
pro IDLitManipDataPan__Define

  compile_opt idl2, hidden
  
  void = {IDLitManipDataPan,         $
          inherits IDLitManipulator, $ ; Superclass
          _startXY: DBLARR(2),       $ ; Initial window location.
          _currentXY: DBLARR(2),     $
          _axesHide:0,               $
          _axesStyle:0,              $
          _axesTransparency:0,       $
          _xyConstrain: 0b,          $
          _keyDown: 0b               $
         }
         
end
