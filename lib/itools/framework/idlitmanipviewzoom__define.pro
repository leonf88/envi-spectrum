; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipviewzoom__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipViewZoom
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipViewZoom::Init
;
; PURPOSE:
;       The IDLitManipViewZoom::Init function method initializes the
;       component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oManipulator = OBJ_NEW('IDLitManipViewZoom')
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipViewZoom::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipViewZoom::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Select", $
        IDENTIFIER="ManipViewZoom", $
        OPERATION_IDENTIFIER="SET_PROPERTY", $
        PARAMETER_IDENTIFIER="CURRENT_ZOOM", $
        /SKIP_MACROHISTORY, $
        NAME="View Zoom", $
        /WHEEL_EVENTS, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

   ; Register the default cursor for this manipulator.
    self->IDLitManipViewZoom::_DoRegisterCursor

    ; Set limits
    self._zoomLimits = [0.0001, 10000]
    self._minWinDims = [32, 32]
    
    ; Set properties.
    self->IDLitManipViewZoom::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipViewZoom::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipViewZoom::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::_DoZoom
;
; Purpose:
;   Zooms the canvas.
;
; Parameters
;  oWin - Source of the event
;  corner1 - X,Y coordinates of the starting corner
;  corner2 - X,Y coordinates of the ending corner
;
pro IDLitManipViewZoom::_DoZoom, oWin, corner1, corner2, oCmd
  compile_opt idl2, hidden

  ; Make sure we have a tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return

  ; Retrieve window dimensions
  oWin->GetProperty, DIMENSIONS=winDims, CURRENT_ZOOM=initialZoom, $
    VISIBLE_LOCATION=winLoc, VIRTUAL_DIMENSIONS=vWinDims

  ; Get lower left corner
  llCorner = [min([corner1[0],corner2[0]]),min([corner1[1],corner2[1]])]

  aspectWin = winDims[0]/winDims[1]
  width = ABS(FLOAT(corner1[0])-corner2[0])
  height = ABS(FLOAT(corner1[1])-corner2[1])
  aspectBox = width / height

  ; Change zoom box to be of the proper aspect ratio with the old box 
  ; portion centered in the new box
  if (aspectBox ge aspectWin) then begin
    newHeight = width / aspectWin
    llCorner[1] -= (newHeight-height)/2
    ; Calculate new zoom factor
    zoomFactor = initialZoom * (winDims[0] / width)
  endif else begin
    newWidth = height * aspectWin
    llCorner[0] -= (newWidth-width)/2
    ; Calculate new zoom factor
    zoomFactor = initialZoom * (winDims[1] / height)
  endelse

  ; If close to 1 ensure it is actually 1 to avoid rounding errors
  if (Abs(zoomFactor - 1) lt (1 - 1/zoomFactor)*0.5d) then zoomFactor = 1
  ; Enforce limits
  zoomFactor >= self._zoomLimits[0]
  zoomFactor <= self._zoomLimits[1]
  ; Ensure a minimum window size; do not zoom out too far
  fullWin = vWinDims / initialZoom
  minZoom = self._minWinDims / fullWin
  if ((zoomFactor lt MAX(minZoom)) && (zoomFactor lt initialZoom)) then return

  ; New location
  newLocation = (winLoc + llCorner) / initialZoom * zoomFactor
  
  ; Set properties: Zoom and location on Window
  oSetProp = oTool->GetService('SET_PROPERTY')
  if (OBJ_VALID(oSetProp)) then begin
    oCmd = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
      'CURRENT_ZOOM', zoomFactor)
    if (OBJ_VALID(oCmd)) then begin
      oCmd->SetProperty, NAME='Zoom'
      oCmd2 = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
        'VISIBLE_LOCATION', newLocation)
      if (OBJ_VALID(oCmd2)) then begin
        oCmd2->SetProperty, NAME='Zoom'
        oCmd = [oCmd, oCmd2]
      endif
    endif
  endif

end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
pro IDLitManipViewZoom::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect
  compile_opt idl2, hidden

  ; Call our superclass.
  self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
    KeyMods, nClicks
    
  ; For middle or right button clicks, cancel the annotation.
  if (iButton ne 1) then begin
    if OBJ_VALID(self._oRectangle) then begin
      self._oRectangle->GetProperty, PARENT=oParent
      if (OBJ_VALID(oParent)) then $
        oParent->IDLgrModel::Remove, self._oRectangle
      self->CancelAnnotation
      self.ButtonPress = 0
    endif
    return
  endif

  ; Enforce zoom limits
  oWin->GetProperty, CURRENT_ZOOM=initialZoom
  if (initialZoom ge self._zoomLimits[1]) then begin
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
  
  self->StatusMessage, IDLitLangCatQuery('Status:Framework:CanvasZoomBox')

end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipViewZoom::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

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
        self->IDLitManipViewZoom::_DoZoom, oWin, self._startPT, self._endPt, $
          oCmd
    endif
    
    oTool = self->GetTool()
    oTool->RefreshCurrentWindow
    oTool->UpdateAvailability
    
    ; Add to undo/redo buffer
    if (haveBox && PRODUCT(OBJ_VALID(oCmd))) then $
      oTool->_TransactCommand, oCmd

  endif
  
  ; Call our superclass.
  self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
  
  ; Restore status message.
  statusMsg = self->GetStatusMessage('', 0)
  self->StatusMessage, statusMsg
  self->ProbeStatusMessage, ''
  
end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipViewZoom::OnMouseMotion, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; Sanity check.
  if (~self.ButtonPress || ~OBJ_VALID(self._oRectangle)) then begin
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
    return
  endif
  
  oWin->GetProperty, DIMENSIONS=winDims

  x0 = self._startPt[0]
  y0 = self._startPt[1]
  ; Don't allow rectangles of zero width/height.
  if (x eq x0) || (y eq y0) then $
    return
  x1 = x
  y1 = y
  
  aspectWin = winDims[0]/winDims[1]
  width = ABS(float(x1)-x0)
  height = ABS(float(y1)-y0)
  aspectBox = width / height

  ; Check for <Shift> key.
  if ((KeyMods and 1) ne 0) then begin
    ; Force rectangle to adhere to the window aspect ratio
    if (aspectBox gt aspectWin) then begin
      newY = width / aspectWin
      y1 = y0 + (newY * (y1 gt y0 ? 1 : -1))
    endif else begin
      newX = height * aspectWin
      x1 = x0 + (newX * (x1 gt x0 ? 1 : -1))
    endelse
  endif
  
  self._endPt[0] = x1
  self._endPt[1] = y1

  ;; Add the Z so that values are in the annotation layer and
  ;; not clipped by the Viz.
  z = self._normalizedZ
  
  ; Calculate new zoom factor
  if (aspectBox gt aspectWin) then begin
    zoomFactor = winDims[0] / width
  endif else begin
    zoomFactor = winDims[1] / height
  endelse
  self->ProbeStatusMessage, $
    STRING(zoomFactor, FORMAT='("Zoom factor: ",F0.2)')
    
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
  
  ; Update the graphics hierarchy.
  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow

end

;--------------------------------------------------------------------------
; _IDLitManipulator::OnWheel
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
pro IDLitManipViewZoom::OnWheel, oWin, x, y, delta, keyMods
  compile_opt idl2, hidden
  
  ; Not at the same time as the bounding box
  if (self.ButtonPress) then return
  
  ; Make sure we have a tool.
  oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  ; Grab the current window
  oWin = oTool->GetCurrentWindow()
  
  ; Retrieve previous zoom factor.
  oWin->GetProperty, VIRTUAL_DIMENSIONS=vWinDims, CURRENT_ZOOM=initialZoom, $
    VISIBLE_LOCATION=winLoc, DIMENSIONS=winDims

  ; New zoom value
  zoomFactor = (delta gt 0) ? 1.25d : 1/1.25d
  zoom = initialZoom * zoomFactor
  
  ; If close to 1 ensure it is actually 1 to avoid rounding errors
  if (Abs(zoom - 1) lt (1 - 1/zoom)*0.5d) then zoom = 1
  
  ; Enforce limits
  zoom >= self._zoomLimits[0]/100d
  zoom <= self._zoomLimits[1]/100d
  ; Ensure a minimum window size; do not zoom out too far
  fullWin = vWinDims / initialZoom
  minZoom = self._minWinDims / fullWin
  if ((zoom lt MAX(minZoom)) && (zoom lt initialZoom)) then return
  
  newLocation = [0,0]
  ; Determine new location; <Shift> zooms around center, otherwise zoom
  ; around mouse location.  Only do this if canvas is larger than window.
  if (((KeyMods and 1) eq 0) && (long(zoom*1000)/1000. gt 1)) then begin
    ; New location
    newXY = (winLoc + [x,y]) / initialZoom * zoom
    newLocation = newXY - [x,y]
  endif
  
  ; Set properties: Zoom and location on Window
  oSetProp = oTool->GetService('SET_PROPERTY')
  if (OBJ_VALID(oSetProp)) then begin
    oCmd = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
      'CURRENT_ZOOM', zoom)
    if (OBJ_VALID(oCmd)) then begin
      oCmd->SetProperty, NAME='Zoom'
      ; Ensure window is in the proper location
      newLocation <= vWinDims*zoom - winDims
      newLocation >= 0
      oCmd2 = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
        'VISIBLE_LOCATION', newLocation)
      if (OBJ_VALID(oCmd2)) then begin
        oCmd2->SetProperty, NAME='Zoom'
        oCmd = [oCmd, oCmd2]
      endif
    endif
  endif

  oTool->RefreshCurrentWindow
  oTool->UpdateAvailability
  ; Add to undo/redo buffer
  if (PRODUCT(OBJ_VALID(oCmd))) then $
    oTool->_TransactCommand, oCmd

end

;;--------------------------------------------------------------------------
;; IDLitManipViewZoom::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipViewZoom::_DoRegisterCursor

    compile_opt idl2, hidden

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
        '  .#.     .##.  ', $
        '   .#.....####. ', $
        '    .######..##.', $
        '     .... .#..#.', $
        '           .##. ', $
        '            ..  ', $
        '                ']

    self->RegisterCursor, strArray, 'Zoom', /DEFAULT

end


;---------------------------------------------------------------------------
; IDLitManipViewZoom::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipViewZoom__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipViewZoom, $
            inherits IDLitManipAnnotation, $
            _zoomLimits: [0d, 0], $
            _minWinDims: [0l, 0], $
            _startPt: [0, 0], $
            _endPt: [0, 0], $
            _oRectangle: OBJ_NEW(), $
            _oPolyline: OBJ_NEW(), $
            oCurrView: OBJ_NEW() $ ; Reference to view to be zoomed
           }
end
