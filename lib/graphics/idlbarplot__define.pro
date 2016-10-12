; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/idlbarplot__define.pro#1 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLBarPlot
;
; PURPOSE:
;    The IDLBarPlot class is the component wrapper for IDLgrPlot
;
; CATEGORY:
;    Components
;
; MODIFICATION HISTORY:
;     Written by:   AGEH, 01/2010
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAMES:
;   IDLBarPlot::Init
;
; PURPOSE:
;   Initialize this component
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;
;   Obj = OBJ_NEW('IDLBarPlot', [[X,] Y]])
;
; INPUTS:
;   X: Vector of X coordinates
;   Y: Vector of Y coordinates
;
; OUTPUTS:
;   This function method returns 1 on success, or 0 on failure.
;
;-
function IDLBarPlot::Init, _REF_EXTRA=_extra
  compile_opt idl2, hidden

  ; Initialize superclass
  if (~self->IDLitVisPlot::Init(/REGISTER_PROPERTIES, NAME='IDLBarPlot', $
                                ICON='plot', TYPE='IDLPLOT', $
                                DESCRIPTION='A IDLBarPlot Visualization', $
                                _EXTRA=_extra)) then return, 0

  ; Defaults
  self.color = [0b,0b,255b]
  self.bottom_color = [0b,0b,255b]
  self.use_bottom_color = 0
  self.color_range = [0d, 0d]
  self.has_color_range = 0b
  self.data = PTR_NEW(!VALUES.F_NAN)
  self.x_data = PTR_NEW(!VALUES.F_NAN)
  self.bottom_data = PTR_NEW(0)
  self.width = 0.8d
  self.n_bars = 1
  self.horizontal = 0
  self.outline_color = [0b,0b,0b]
  self.outline_hide = 0b
  self.outline_style = 0b
  self.outline_thick = 1
  
  self->SetAxesStyleRequest, 2 ; Request box style axes by default.

  ; Bar
  self._oBar = OBJ_NEW('IDLitVisPolygon', $
                       COLOR=self._fillColor, $
                       FILL_COLOR=self._fillColor, $
                       TRANSPARENCY=self._fillTransparency, $
                       /HIDE, /PRIVATE, LINESTYLE=6, /TESSELLATE)
  ;; Add to the beginning so it is in the background.
  self->Add, self._oBar, POSITION=0
  ; Outline
  self._oLine = OBJ_NEW('IDLitVisPolyline', $
                        COLOR=self.outline_color, $
                        TRANSPARENCY=self._fillTransparency, $
                        /HIDE, /PRIVATE)
  self->Add, self._oLine, POSITION=1
  
  ; Register all properties and set property attributes
  self->IDLBarPlot::_RegisterProperties

  ; Set any properties
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLBarPlot::SetProperty,  _EXTRA=_extra

  self->RemoveAggregate, self._oSymbol
  
  RETURN, 1 ; Success

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLBarPlot::Cleanup
;
; PURPOSE:
;   This procedure method performs all cleanup on the object.
;
;   NOTE: Cleanup methods are special lifecycle methods, and as such
;   cannot be called outside the context of object destruction.  This
;   means that in most cases, you cannot call the Cleanup method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Cleanup method
;   from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;     or
;   Obj->[IDLBarPlot::]Cleanup
;
;-
pro IDLBarPlot::Cleanup, _EXTRA=_extra
  compile_opt idl2, hidden

  OBJ_DESTROY, [self._oBar, self._oLine]
  PTR_FREE, [self.data, self.x_data, self.bottom_data]

  ; Cleanup superclass
  self->IDLitVisPlot::Cleanup

end


;----------------------------------------------------------------------------
; IDLBarPlot::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLBarPlot::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLBarPlot::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

  compile_opt idl2, hidden

  registerAll = ~KEYWORD_SET(updateFromVersion)

  if (registerAll) then begin
    self._oPlot->RegisterProperty, 'Width', /FLOAT, $
      DESCRIPTION='Bar width', NAME='Bar width'
  endif

end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLBarPlot::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLBarPlot::Init followed by the word "Get"
;      can be retrieved using IDLBarPlot::GetProperty.
;
;-
pro IDLBarPlot::GetProperty, $
    ANTIALIAS=antialias, $
    WIDTH=width, $
    INDEX=index, $
    NBARS=nBars, $
    FILL_COLOR=color, $
    TRANSPARENCY=transparency, $
    BOTTOM_VALUES=bottomData, $
    BOTTOM_COLOR=bottomColor, $
    USE_BOTTOM_COLOR=useBottomColor, $
    C_RANGE=colorRange, $
    COLOR=outlineColor, $
    THICK=outlineThick, $
    LINESTYLE=outlineStyle, $
    OUTLINE=showOutline, $
    HORIZONTAL=horizontal, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

  if (ARG_PRESENT(antialias)) then $
    self._oLine->GetProperty, ANTIALIAS=antialias

  if (ARG_PRESENT(width)) then $
    width = self.width

  if (ARG_PRESENT(index)) then $
    index = self.index

  if (ARG_PRESENT(nBars)) then $
    nBars = self.n_bars

  if (ARG_PRESENT(color)) then $
    color = self.color

  if (ARG_PRESENT(transparency)) then $
    self._oBar->GetProperty, TRANSPARENCY=transparency

  if (ARG_PRESENT(bottomData)) then $
    bottomData = *self.bottom_data

  if (ARG_PRESENT(bottomColor)) then $
    bottomColor = self.bottom_color

  if (ARG_PRESENT(useBottomColor)) then $
    useBottomColor = self.use_bottom_color

  if (ARG_PRESENT(colorRange)) then $
    colorRange = self.has_color_range ? self.color_range : [0d, 0d]

  if (ARG_PRESENT(outlineColor)) then $
    outlineColor = self.outline_color

  if (ARG_PRESENT(outlineThick)) then $
    outlineThick = self.outline_thick

  if (ARG_PRESENT(outlineStyle)) then $
    outlineStyle = self.outline_style

  if (ARG_PRESENT(showOutline)) then $
    showOutline = ~self.outline_hide

  if (ARG_PRESENT(horizontal)) then $
    horizontal = self.horizontal

  ; get superclass properties
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitVisPlot::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLBarPlot::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLBarPlot::Init followed by the word "Set"
;      can be set using IDLBarPlot::SetProperty.
;-
pro IDLBarPlot::SetProperty, $
    ANTIALIAS=antialias, $
    WIDTH=width, $
    INDEX=index, $
    NBARS=nBars, $
    FILL_COLOR=color, $
    TRANSPARENCY=transparency, $
    BOTTOM_VALUES=bottomData, $
    BOTTOM_COLOR=bottomColor, $
    USE_BOTTOM_COLOR=useBottomColor, $
    C_RANGE=colorRange, $
    COLOR=outlineColor, $
    THICK=outlineThick, $
    LINESTYLE=outlineStyle, $
    OUTLINE=showOutline, $
    HORIZONTAL=horizontal, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

  update = 0b
  
  if (N_ELEMENTS(antialias) gt 0) then begin
    self._oLine->SetProperty, ANTIALIAS=antialias
  endif

  if (N_ELEMENTS(width) gt 0) then begin
    oldWidth = self.width
    self.width = FLOAT(width[0]) < 1 > 0.00001
    update = oldWidth ne self.width
  endif
  
  if ((N_ELEMENTS(index) eq 1) && (index ne self.index)) then begin
    oldIndex = self.index
    self.index = index > 0
    update = oldIndex ne self.index
  endif
  
  if (N_ELEMENTS(nBars) eq 1) then begin
    oldBars = self.n_bars
    self.n_bars = nBars > 1
    update = oldBars ne self.n_bars
  endif

  if (N_ELEMENTS(color) gt 0) then begin
    self.color = self->_GetColor(color)
    update = 1b
  endif
  
  if (N_ELEMENTS(transparency) gt 0) then begin
    trans = transparency > 0 < 100
    self->IDLitVisPlot::SetProperty, FILL_TRANSPARENCY=trans
    update = 1b
  endif
  
  if (N_ELEMENTS(bottomData) ne 0) then begin
    if (N_ELEMENTS(bottomData) eq 1) then begin
      *self.bottom_data = $
        REPLICATE(bottomData, N_ELEMENTS(*self.data)) 
      update = 1b
    endif
    if (N_ELEMENTS(bottomData) eq N_ELEMENTS(*self.data)) then begin
      *self.bottom_data = bottomData
      update = 1b
    endif
  endif

  if (N_ELEMENTS(bottomColor) ne 0) then begin
    oldUse = self.use_bottom_color
    botCol = self->_GetColor(bottomColor)
    if (N_ELEMENTS(botCol) eq 1) then begin
      self.use_bottom_color = 0b
    endif else begin
      self.bottom_color = botCol
      self.use_bottom_color = 1b
    endelse
    if (self.use_bottom_color || oldUse) then $
      update = 1b
  endif

  if (N_ELEMENTS(useBottomColor) ne 0) then begin
    oldUse = self.use_bottom_color
    self.use_bottom_color = KEYWORD_SET(useBottomColor[-1]) 
    update = (oldUse ne self.use_bottom_color)
  endif

  if (N_ELEMENTS(colorRange) ne 0) then begin
    oldHasRange = self.has_color_range
    if (N_ELEMENTS(colorRange) eq 1) then begin
      self.has_color_range = 0b
    endif
    if (N_ELEMENTS(colorRange) eq 2) then begin
      self.color_range = colorRange
      self.has_color_range = colorRange[0] ne colorRange[1]
    endif
    update = (oldHasRange ne self.has_color_range)
  endif

  if (N_ELEMENTS(outlineColor) ne 0) then begin
    self.outline_color = self->_GetColor(outlineColor)
    self._oLine->SetProperty, COLOR=self.outline_color
  endif

  if (N_ELEMENTS(outlineThick) ne 0) then begin
    self.outline_thick = outlineThick > 0
    self._oLine->SetProperty, THICK=self.outline_thick
  endif

  if (N_ELEMENTS(outlineStyle) ne 0) then begin
    self.outline_style = outlineStyle > 0
    self._oLine->SetProperty, LINESTYLE=self.outline_style
  endif

  if (N_ELEMENTS(showOutline) ne 0) then begin
    self.outline_hide = ~KEYWORD_SET(showOutline)
    self._oLine->SetProperty, HIDE=self.outline_hide
  endif

  if (N_ELEMENTS(horizontal) eq 1) then begin
    oldHoriz = self.horizontal
    self.horizontal = KEYWORD_SET(horizontal)
    update = oldHoriz ne self.horizontal
    doRangeUpdate = 1b
  endif

  if (N_ELEMENTS(_extra) gt 0) then begin
    self->IDLitVisPlot::SetProperty, _EXTRA=_extra
    update = 1b
  endif

  if (update) then begin
    if (N_ELEMENTS(horizontal) ne 0) then begin
      !NULL = self->GetXYZRange(xRange, yRange, zRange)
    endif else begin
      oDS = self->GetDataspace(/UNNORMALIZED)
      if (OBJ_VALID(oDS)) then $
        !NULL = oDS->_GetXYZAxisRange(xRange, yRange, zRange)
    endelse
    self->_UpdateFill, xRange, yRange, zRange
    self->_UpdateSelectionVisual
  endif
  
  if (ISA(doRangeUpdate) && doRangeUpdate) then begin
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
      oDesc = oTool->GetOperations(IDENTIFIER='Edit/DataspaceReset')
      oDSR = OBJ_VALID(oDesc) ? oDesc->GetObjectInstance() : OBJ_NEW()
      if (OBJ_VALID(oDSR)) then $
        !NULL = oDSR->DoAction(oTool, SELECTION=self)
    endif
  endif
  
end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;; IDLBarPlot::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the plot.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLBarPlot::OnDataDisconnect, ParmName
  compile_opt hidden, idl2
  
  ;; Just check the name and perform the desired action
  case ParmName of
    'X': begin
      ; Replace X values with indgen
      self._oBar->GetProperty, data=data
      szDims = size(data,/dimensions)
      data[0,*] = indgen(szDims[1])
      self._oBar->SetProperty, data=data
      self->_UpdateSelectionVisual
    end
    'Y': begin
      ; Set dummy data and hide bar
      self._oBar->SetProperty, data=[[0,0,0],[1,0,0],[0,1,0]]
      self->_UpdateSelectionVisual
      self._oBar->SetProperty, /HIDE
      self._oLine->SetProperty, /HIDE
    end
  
    else:
  endcase

  ; Since we are changing a bunch of attributes, notify
  ; our observers in case the prop sheet is visible.
  self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
; METHODNAME:
;    IDLBarPlot::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the
;    subject and updates the internal IDLgrPlot object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLBarPlot::]OnDataChangeUpdate, oSubject, parmName
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the plot) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then it puts the data in the IDLgrPlot object.
;
;    parmName: The name of the registered parameter.
;
; KEYWORDS:
;   NO_UPDATE: Undocumented keyword to suppress updates when adding
;       multiple data objects within a parameter set.
;
pro IDLBarPlot::OnDataChangeUpdate, oSubject, parmName, $
    NO_UPDATE=noUpdate
    
  compile_opt idl2, hidden
  
  case strupcase(parmName) of
    '<PARAMETER SET>':begin
      ;; Get our data
      position = oSubject->Get(/ALL, count=nCount, NAME=name)
      for i=0, nCount-1 do begin
        if (name[i] eq '') then $
          continue
        oData = (oSubject->GetByName(name[i]))[0]
        if (~OBJ_VALID(oData)) then $
          continue
        if (oData->GetData(data, NAN=nan) le 0) then $
          continue
        
        case name[i] of
      
          'Y': begin
            self->IDLBarPlot::OnDataChangeUpdate, oData, 'Y', /NO_UPDATE
          
            oData = oSubject->GetByName('X')
            if (OBJ_VALID(oData)) then begin
              self->IDLBarPlot::OnDataChangeUpdate, oData, 'X', /NO_UPDATE
            endif
          
            self->_UpdateFill
          end
        
          'X':  ; X is handled in the Y branch to control order
        
          ; Pass all other parameters on to ourself.
          else: self->IDLBarPlot::OnDataChangeUpdate, oData, name[i]
        
        endcase
      
      endfor
    end
  
    'X': begin
      if (~oSubject->GetData(data)) then $
        break
      *self.x_data = data
      if (~KEYWORD_SET(noUpdate)) then begin
        ;; Call OnDataChangeUpdate to update the visual stuff
        if (self->GetXYZRange(xRange, yRange, zRange)) then $
          self->OnDataRangeChange, self, xRange, yRange, zRange
      endif
    end
  
    'Y': begin
      if (~oSubject->GetData(data)) then $
        break
      *self.data = data
      if (~KEYWORD_SET(noUpdate)) then begin
        ;; Call OnDataChangeUpdate to update the visual stuff
        if (self->GetXYZRange(xRange, yRange, zRange)) then $
          self->OnDataRangeChange, self, xRange, yRange, zRange
      endif
    end
  
    else: ; ignore unknown parameters
  
  endcase

  self->_UpdateSelectionVisual

  ; Since we are changing a bunch of attributes, notify
  ; our observers in case the prop sheet is visible.
  self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->[IDLBarPlot::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLBarPlot::OnDataRangeChange, oSubject, XRange, YRange, ZRange
  compile_opt idl2, hidden
  
  ; Retrieve the range of the plot data (before clipping).
  !NULL = self->GetXYZRange(dataXRange, dataYRange, dataZRange)
  
  dataXRange[0] = dataXRange[0] > xrange[0]
  dataXRange[1] = dataXRange[1] < xrange[1]
  dataYRange[0] = dataYRange[0] > yrange[0]
  dataYRange[1] = dataYRange[1] < yrange[1]
  
  self->_UpdateFill, XRange, YRange, ZRange
  self->_UpdateSelectionVisual
  
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisAxis::GetXYZRange
;
; PURPOSE:
;   This function method overrides the _IDLitVisualization::GetXYZRange
;   function, taking into the tick labels.
;
function IDLBarPlot::GetXYZRange, outxRange, outyRange, outzRange, _EXTRA=_extra
    compile_opt idl2, hidden

  if (MAX(FINITE((*self.data))) eq 0) then return, 0
  
  outzRange = [0,0]
  
  if (N_ELEMENTS((*self.data)) eq 1) then begin
    smallWidth = 1
  endif else begin
    smallWidth = min((*self.x_data)[1:-1]-(*self.x_data)[0:-2])
  endelse
  
  outxRange = [MIN(*self.x_data, MAX=max),max]
  outyRange = [MIN([*self.data,*self.bottom_data], MAX=max),max]

  outxRange[0] -= smallWidth
  outxRange[1] += smallWidth
  
  if (self.horizontal) then begin
    tmp = outxRange
    outxRange = outyRange
    outyRange = tmp
  end

  return, 1
  
end


;----------------------------------------------------------------------------
; Purpose:
;   Perform any X clipping needed on the polygon.
;
; Result:
;   Returns true if any polygons still exist
;
function IDLBarPlot::_FillClipX, xrange, yrange, data
  compile_opt idl2, hidden

  range = self.horizontal ? yrange : xrange
  if (range[0] gt range[1]) then $
    range = REVERSE(range)
    
  ; Check each polygon
  keepData = []
  for i=0,N_ELEMENTS(data[0,*])/4-1 do begin
    dataTmp = data[*,i*4:i*4+3]
    !NULL = WHERE(dataTmp[0,*] lt range[0], nBadLeft)
    !NULL = WHERE(dataTmp[0,*] gt range[1], nBadRight)
    ; Do not keep if everything is out of range
    if ((nBadLeft eq 4) || (nBadRight eq 4)) then continue
    ; Clip polygon
    if (nBadLeft eq 2) then $
      dataTmp[0,0:1] = range[0]
    if (nBadRight eq 2) then $
      dataTmp[0,2:3] = range[1]
    ; Keep polygon
    keepData = [[keepData], [dataTmp]]
  endfor
  
  data = keepData

  return, KEYWORD_SET(data)
  
end


;----------------------------------------------------------------------------
; Purpose:
;   Perform any Y clipping needed on the polygon.
;
; Result:
;   Returns true if any polygons still exist
;
function IDLBarPlot::_FillClipY, xrange, yrange, data
  compile_opt idl2, hidden

  range = self.horizontal ? xrange : yrange

  ; Check each polygon
  keepData = []
  for i=0,N_ELEMENTS(data[1,*])/4-1 do begin
    dataTmp = data[*,i*4:i*4+3]
    !NULL = WHERE(dataTmp[1,*] lt range[0], nBadBelow)
    !NULL = WHERE(dataTmp[1,*] gt range[1], nBadAbove)
    ; Do not keep if everything is out of range
    if ((nBadBelow eq 4) || (nBadAbove eq 4)) then continue
    ; Clip polygon
    if (nBadBelow eq 2) then begin
      indices = (dataTmp[1,1] gt dataTmp[1,0]) ? [0,3] : [1,2]
      dataTmp[1,indices] = range[0]
    endif
    if (nBadAbove eq 2) then begin
      indices = (dataTmp[1,1] gt dataTmp[1,0]) ? [1,2] : [0,3]
      dataTmp[1,indices] = range[1]
    endif
    ; Keep polygon
    keepData = [[keepData], [dataTmp]]
  endfor
  
  data = keepData

  return, KEYWORD_SET(data)
  
end


;----------------------------------------------------------------------------
; Purpose:
;   Create vert_color vertices and modify polygon list to account for shading
;
pro IDLBarPlot::_DoShading, data, polygons, vertColors, shading, $ ; In data
                            barData, barPolygons ; Out data
  compile_opt idl2, hidden

  if (self.use_bottom_color) then begin
    if (self.has_color_range) then begin
      vertColors = []
      newData = []
      newPolygons = []
      polyIndex = 0
      ; Interpolate colours within colour range
      for i=0,N_ELEMENTS(data[1,*])/4-1 do begin
        dataTmp = data[*,i*4:i*4+3]
        if (dataTmp[1,0] gt dataTmp[1,1]) then $
          dataTmp = dataTmp[*,[1,0,3,2]]
        cRange = FIX(self.color) - FIX(self.bottom_color)
        range = self.color_range[1] - self.color_range[0]
        per = (dataTmp[1,0:1] - self.color_range[0]) / range
        bottomC = per[0] * cRange + self.bottom_color  
        topC = per[1] * cRange + self.bottom_color
        vert = BYTE([[bottomC],[topC],[topC],[bottomC]])
        ; If both points are below the bottom color range
        if ((per[0] le 0) && (per[1] le 0)) then begin
          vert = [[self.bottom_color],[self.bottom_color],$
                  [self.bottom_color],[self.bottom_color]]
        endif
        ; If both points are above the top color range
        if ((per[0] ge 1) && (per[1] ge 1)) then begin
          vert = [[self.color],[self.color],$
                  [self.color],[self.color]]
        endif
        ; Are additional points needed?
        if ((per[1] gt 1) && (per[0] lt 1)) then begin
          ; Insert data point
          dataTmp = [[dataTmp[*,0]],$
                     [[dataTmp[0,0],self.color_range[1]]],$
                     [dataTmp[*,1:-2]],$
                     [[dataTmp[0,-1],self.color_range[1]]],$
                     [dataTmp[*,-1]]]
          vert = [[vert[*,0]],[self.color],[self.color],[self.color],$
                  [self.color],[vert[*,-1]]]
        endif
        if ((per[0] lt 0) && (per[1] gt 0)) then begin
          ; Insert data point
          dataTmp = [[dataTmp[*,0]],$
                     [[dataTmp[0,0],self.color_range[0]]],$
                     [dataTmp[*,1:-2]],$
                     [[dataTmp[0,-1],self.color_range[0]]],$
                     [dataTmp[*,-1]]]
          vert = [[self.bottom_color],[self.bottom_color],[vert[*,1:-2]],$
                  [self.bottom_color],[self.bottom_color]]
        endif
        ; Concatenate arrays
        vertColors = [[vertColors],[vert]]
        newData = [[newData],[dataTmp]]
        nPoly = N_ELEMENTS(dataTmp[0,*])
        ; Set up polygons with separate vertical boxes for proper shading
        case nPoly of
          6 : newPolygons = [newPolygons,5,[0,1,4,5,0]+polyIndex, $
                             5,[1,2,3,4,1]+polyIndex]
          8 : newPolygons = [newPolygons,5,[0,1,6,7,0]+polyIndex, $
                             5,[1,2,5,6,1]+polyIndex, 5,[2,3,4,5,2]+polyIndex]
          else : newPolygons = [newPolygons,5,[0,1,2,3,0]+polyIndex]
        endcase
        polyIndex += nPoly
      endfor
      barData = TEMPORARY(newData)
      barPolygons = TEMPORARY(newPolygons)
    endif else begin
      ; Colours scale from bottom to top for every bar
      vertColors = [[self.bottom_color],[self.color],$
                    [self.color],[self.bottom_color]]
      barData = data
      barPolygons = polygons                    
    endelse
    shading = 1
  endif else begin
    barData = data
    barPolygons = polygons                    
    vertColors = 0
    shading = 0
  endelse

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::_UpdateData
;
;-
;----------------------------------------------------------------------------
pro IDLBarPlot::_UpdateData
  compile_opt idl2, hidden

  if ((N_ELEMENTS(*self.x_data) ne N_ELEMENTS(*self.data)) || $
      (MAX(FINITE(*self.x_data)) eq 0)) then $
    *self.x_data = indgen(N_ELEMENTS(*self.data))
  
  if (N_ELEMENTS(*self.bottom_data) ne N_ELEMENTS(*self.data)) then $
    *self.bottom_data = fltarr(N_ELEMENTS(*self.data))

END


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::_GetColor
;
; PURPOSE:
;      This procedure returns a color.
;
;-
;----------------------------------------------------------------------------
function IDLBarPlot::_GetColor, color
  compile_opt idl2, hidden

  if (SIZE(color, /TNAME) eq 'STRING') then begin
    index = where(STRUPCASE(color[0]) eq TAG_NAMES(!color), cnt)
    if (cnt) then begin
      outColor = !color.(index[0])
    endif else begin
      outColor = [0b,0b,0b]
    endelse
    return, outColor
  endif
  
  if (N_ELEMENTS(color) eq 3) then return, BYTE(color)
  
  return, color
  
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::_UpdateSelectionVisual
;
; PURPOSE:
;      This procedure method updates the selection visual based
;      on the plot data.
;
; CALLING SEQUENCE:
;      Obj->[IDLBarPlot::]_UpdateSelectionVisual
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLBarPlot::_UpdateSelectionVisual
  compile_opt idl2, hidden

  self._oBar->GetProperty, DATA=barData, HIDE=hide

  ; Bars
  self._oPlotSelectionVisual->SetProperty, $
    DATAX=barData[0,*], DATAY=barData[1,*], HIDE=hide
    
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLBarPlot::_UpdateFill
;
; PURPOSE:
;      This procedure method updates the polygon representing
;      the filled area under the plot.  It must be updated when
;      the fill level (the lower boundary) changes or when going
;      into or out of histogram mode, for example.
;
; CALLING SEQUENCE:
;      Obj->[IDLBarPlot::]_UpdateFill
;
; INPUTS:
;      DataspaceX/Yrange: Optional args giving the dataspace ranges.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLBarPlot::_UpdateFill, DSxRange, DSyRange, DSzRange
  compile_opt idl2, hidden

  self->_UpdateData
  
  if (~FINITE((*self.data)[0])) then return
  
  plotData = TRANSPOSE([[*self.x_data], [*self.data]])
  if (MAX(FINITE(plotData)) eq 0) then return
  
  ys = (xs = DBLARR(N_ELEMENTS(plotData[0,*])*4))
  if (N_ELEMENTS(plotData[0,*]) eq 1) then begin
    smallWidth = 1
  endif else begin
    smallWidth = min(plotData[0,1:-1]-plotData[0,0:-2])
  endelse
  usableWidth = smallWidth/2.*self.width
  
  index = self.index < (self.n_bars-1)
  
  xs[0:-1:4] = plotData[0,*] + usableWidth * (index/self.n_bars*2 - 1)
  xs[1:-1:4] = xs[0:-1:4]
  xs[2:-1:4] = plotData[0,*] + usableWidth * ((index+1)/self.n_bars*2 - 1)
  xs[3:-1:4] = xs[2:-1:4]

  ys[0:-1:4] = *self.bottom_data
  ys[1:-1:4] = plotData[1,*]
  ys[2:-1:4] = plotData[1,*]
  ys[3:-1:4] = *self.bottom_data

  data = TRANSPOSE([[xs],[ys]])
  
  ; Handle dataspace clipping
  if ((N_ELEMENTS(DSxRange) ne 0) && (N_ELEMENTS(DSyRange) ne 0)) then begin
    if (~self->_FillClipX(DSxRange, DSyRange, data) || $
        ~self->_FillClipY(DSxRange, DSyRange, data)) then begin
      self._oBar->SetProperty, HIDE=1
      self._oLine->SetProperty, HIDE=1
      return
    endif
  endif

  ; Create connectivity list
  polygonBase = [0,1,2,3,0]
  polygons = [5,polygonBase]
  for i=1,N_ELEMENTS(data[1,*])/4-1 do $
    polygons = [polygons, 5, polygonBase+4*i]
    
  ; Shading
  self->_DoShading, data, polygons, vertColors, shading, barData, barPolygons

  ; Handle horizontal
  if (self.horizontal) then begin
    tmp = data[0,*]
    data[0,*] = data[1,*]
    data[1,*] = tmp
    tmp = barData[0,*]
    barData[0,*] = barData[1,*]
    barData[1,*] = tmp
  endif

  self._oBar->SetProperty, __DATA=barData, $
    __POLYGONS=barPolygons, HIDE=0, FILL_COLOR=self.color, $
    VERT_COLORS=vertColors, SHADING=shading, $
    TRANSPARENCY=self._fillTransparency, TESSELLATE=0
  self._oLine->SetProperty, __DATA=data, $
    __POLYLINES=polygons, HIDE=self.outline_hide, COLOR=self.outline_color, $
    TRANSPARENCY=self._fillTransparency, LINESTYLE=self.outline_style, $
    THICK=self.outline_thick

end


;----------------------------------------------------------------------------
;+
; IDLBarPlot__Define
;
; PURPOSE:
;      Defines the object structure for an IDLBarPlot object.
;-
;----------------------------------------------------------------------------
pro IDLBarPlot__Define
  compile_opt idl2, hidden

  struct = {IDLBarPlot,           $
            inherits IDLitVisPlot, $   ; Superclass: _IDLitVisualization
            _oBar: OBJ_NEW(), $
            _oLine: OBJ_NEW(), $ 
            data: PTR_NEW(), $
            x_data: PTR_NEW(), $
            bottom_data: PTR_NEW(), $
            bottom_color: [0b,0b,0b], $
            use_bottom_color: 0b, $
            color_range: [0d, 0d], $
            has_color_range: 0b, $
            index: 0, $
            n_bars: 0d, $
            color: [0b,0b,0b], $
            outline_color: [0b,0b,0b], $
            outline_thick: 0, $
            outline_hide: 0b, $
            outline_style: 0b, $
            horizontal: 0b, $
            width: 0d $
           }
             
end
