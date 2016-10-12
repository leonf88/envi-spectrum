; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipdatarangezoom__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipDatarangeZoom
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipDatarangeZoom::Init
;
; PURPOSE:
;       The IDLitManipDatarangeZoom::Init function method initializes the
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
;       oManipulator = OBJ_NEW('IDLitManipDatarangeZoom')
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
; IDLitManipDatarangeZoom::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipDatarangeZoom::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Select", $
        IDENTIFIER="ManipDatarangeZoom", $
        TYPES="_VISUALIZATION", $
        NUMBER_DS='1', $
        OPERATION_IDENTIFIER="SET_PROPERTY", $
        PARAMETER_IDENTIFIER="CURRENT_ZOOM", $
        /SKIP_MACROHISTORY, $
        NAME="Datarange Zoom", $
        /WHEEL_EVENTS, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

   ; Register the default cursor for this manipulator.
    self->IDLitManipDatarangeZoom::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipDatarangeZoom::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipDatarangeZoom::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipDatarangeZoom::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipDatarangeZoom::_SetDataspaceRange
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
function IDLitManipDatarangeZoom::_SetDataspaceRange, oDS, xMin, xMax, $
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
; IDLitManipDatarangeZoom::_DoZoom
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
pro IDLitManipDatarangeZoom::_DoZoom, oWin, corner1, corner2, oCmd
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
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax
  newXmax = (xMax gt xMin) ? MAX(xdata, MIN=newXmin) : MIN(xdata, MAX=newXmin)      
  newYmax = (yMax gt yMin) ? MAX(ydata, MIN=newYmin) : MIN(ydata, MAX=newYmin)      

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
; IDLitManipDatarangeZoom::OnMouseDown
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
pro IDLitManipDatarangeZoom::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect
  compile_opt idl2, hidden

  ; Call our superclass.
  self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
    KeyMods, nClicks
    
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
  
  self->StatusMessage, IDLitLangCatQuery('Status:Framework:CanvasZoomBox')

end


;--------------------------------------------------------------------------
; IDLitManipDatarangeZoom::OnMouseUp
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
pro IDLitManipDatarangeZoom::OnMouseUp, oWin, x, y, iButton
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
        self->IDLitManipDatarangeZoom::_DoZoom, oWin, self._startPT, self._endPt, $
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
; IDLitManipDatarangeZoom::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipDatarangeZoom::OnMouseMotion, oWin, x, y, KeyMods
  compile_opt idl2, hidden

  ; Sanity check.
  if (~self.ButtonPress || ~OBJ_VALID(self._oRectangle)) then begin
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
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
  self->ProbeStatusMessage, str

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
pro IDLitManipDatarangeZoom::OnWheel, oWin, x, y, delta, keyMods
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

  ; Convert window coords to dataspace coords
  oDSObj = (oDS->Get())[0]
  oDSObj->WindowToVis, x, y, xdata, ydata
  
  ; zoom value
  zoomFactor = (delta gt 0) ? 1/1.25d : 1.25d
  
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

;;--------------------------------------------------------------------------
;; IDLitManipDatarangeZoom::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipDatarangeZoom::_DoRegisterCursor

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
; IDLitManipDatarangeZoom::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipDatarangeZoom__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipDatarangeZoom, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _endPt: [0, 0], $
            _oRectangle: OBJ_NEW(), $
            _oPolyline: OBJ_NEW(), $
            oCurrView: OBJ_NEW() $ ; Reference to view to be zoomed
           }
end
