; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphic__define.pro#3 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;---------------------------------------------------------------------------
function Graphic::Init, obj, _EXTRA=ex
  compile_opt idl2, hidden

  if (ISA(obj) && ISA(obj, 'OBJREF')) then begin
    self.__obj__ = obj
    if (ISA(obj, '_IDLitContainer')) then begin
      obj._IDLitContainer::SetProperty, PROXY = self
    endif
  endif
  return, 1

end

;---------------------------------------------------------------------------
;+
; :Description:
;    Close the graphic window.
;
; :Params:
;    Filename
;
; :Keywords:
;
;-
pro Graphic::Close
  compile_opt idl2, hidden

@graphic_error
  oTool = ISA(self.__obj__) ? self.__obj__->GetTool() : self->GetTool()
  if (ISA(oTool)) then $
    iDelete, oTool->GetFullIdentifier(), /NO_PROMPT

  OBJ_DESTROY, self
end


;---------------------------------------------------------------------------
;+
; :Description:
;    Save the graphic.
;
; :Params:
;    Filename
;
; :Keywords:
;
;-
pro Graphic::Save, filename, _REF_EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error
  if (N_PARAMS() eq 0) then MESSAGE, 'Incorrect number of arguments.'
  if (~ISA(filename, 'STRING')) then MESSAGE, 'Filename must be a string.'
  obj = ISA(self.__obj__) ? self.__obj__ : self
  iSave, filename, TARGET_IDENTIFIER=obj->GetFullIdentifier(), _EXTRA=_extra

end


;---------------------------------------------------------------------------
;+
; :Description:
;    Print the graphic.
;
; :Params:
;    Filename
;
; :Keywords:
;
;-
pro Graphic::Print, $
  HEIGHT=height, $
  LANDSCAPE=landscape, $
  CENTIMETERS=centimeters, $
  NCOPIES=ncopies, $
  WIDTH=width, $
  XMARGIN=xmargin, $
  YMARGIN=ymargin

  compile_opt idl2, hidden

@graphic_error
  
  oTool = ISA(self.__obj__) ? self.__obj__->GetTool() : self->GetTool()
  if (~ISA(oTool)) then $
    return
  oSystem = oTool->_GetSystem()
  oSysPrint = oSystem->GetService("PRINTER")
  oSysPrint->_setTool, oTool
  
  center = ~ISA(xmargin) && ~ISA(ymargin)

  iStatus = oSysPrint->DoAction( oTool, $
    PRINT_ORIENTATION=landscape, $
    PRINT_XMARGIN=xmargin, $
    PRINT_YMARGIN=ymargin, $
    PRINT_NCOPIES=ncopies, $
    PRINT_WIDTH=width, $
    PRINT_HEIGHT=height, $
    PRINT_UNITS=centimeters, $
    PRINT_CENTER=center, $
    _EXTRA=_extra)
    
end
;---------------------------------------------------------------------------
;+
; :Description:
;    Copy the graphic to the system clipboard.
;
; :Params:
;
;
; :Keywords:
;
;-
pro Graphic::CopyToClipboard, _REF_EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error
  
  oTool = ISA(self.__obj__) ? self.__obj__->GetTool() : self->GetTool()
  if (~ISA(oTool)) then $
    return
  oSystem = oTool->_GetSystem()
  oSysCopy = oSystem->GetService("SYSTEM_CLIPBOARD_COPY")
  owin = oTool->GetcurrentWindow()
  if (~OBJ_VALID(oWin)) then $
      return
  iStatus = oSysCopy->DoWindowCopy( oWin, oWin->getCurrentView(), _EXTRA=_extra)
end


;---------------------------------------------------------------------------
;+
; :Description:
;    Edit the graphic using a Property Sheet.
;
; :Params:
;
;
; :Keywords:
;
;-
pro Graphic::Edit, _REF_EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  oRequester = ISA(self.__obj__) ? self.__obj__ : self
  oTool = oRequester->GetTool()
  if (~ISA(oTool)) then return
  
  void = oTool->DoUIService( 'PropertySheet', oRequester )

end


;---------------------------------------------------------------------------
pro Graphic::GetProperty, $
  AXES=axes, $
  ASPECT_RATIO=aspectRatio, $
  ASPECT_Z=aspectZ, $
  BACKGROUND_COLOR=bgColor, $
  DEPTH_CUE=depthCue, $
  MAPGRID=oGrid, $
  MAPPROJECTION=oMap, $
  TITLE=oTitle, $
  WINDOW=oWin, $
  PARENT=oParent, $
  XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, $
  _REF_EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  if (~ISA(self.__obj__)) then return
  
  ; Get Axis related Values from the Axes object
  if (~ISA( self.__obj__,'GRAPHICSWIN' ) && $
      ~ISA(self.__obj__,'GRAPHICSBUFFER') && $
      ISA(ex)) then begin
    oDataSpace = self.__obj__.GetDataSpace()
    if ISA(oDataSpace) then $
      oAxes = oDataSpace->GetAxes(/CONTAINER)
    if (ISA(oAxes)) then $
      oAxes.GetProperty, _EXTRA=ex
  endif
  
  if ARG_PRESENT(axes) then begin
     oDS = ISA(self.__obj__, '_IDLitVisualization') ? $
       self.__obj__.GetDataSpace() : OBJ_NEW()
    if (ISA(oDS)) then begin
      ids = iGetID(oDS->GetFullIdentifier() + '/*axis*')
      axes = self[ids]
    endif else begin
      axes = self['*axis*']
    endelse
  endif

  if (ARG_PRESENT(aspectRatio)) then begin
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then $
        oDS.GetProperty, ASPECT_RATIO=aspectRatio
    endif
  endif

  if (ARG_PRESENT(aspectZ)) then begin
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then $
        oDS.GetProperty, ASPECT_Z=aspectZ
    endif
  endif

  if ARG_PRESENT(bgColor) then begin
    oTool = self.__obj__.GetTool()
    oWin = oTool.GetCurrentWindow()
    oView = ISA(oWin) ? oWin.GetCurrentView() : OBJ_NEW()
    oLayer = ISA(oView) ? oView.GetCurrentLayer() : OBJ_NEW()
    if ISA(oLayer) then oLayer.GetProperty, COLOR=bgColor
  endif

  if ARG_PRESENT(depthCue) then begin
    oTool = self.__obj__.GetTool()
    oWin = oTool.GetCurrentWindow()
    oView = ISA(oWin) ? oWin.GetCurrentView() : OBJ_NEW()
    oLayer = ISA(oView) ? oView.GetCurrentLayer() : OBJ_NEW()
    if ISA(oLayer) then oLayer.GetProperty, DEPTH_CUE=depthCue
  endif

  if ARG_PRESENT(oGrid) then $
    oGrid = self['MAP GRID']

  if ARG_PRESENT(oMap) then begin
    ; Try to retrieve the map projection object the brute
    ; force way (from the dataspace), in case the user gave
    ; it their own name/identifier.
    oDS = ISA(self.__obj__, '_IDLitVisualization') ? $
      self.__obj__.GetDataSpace(/UNNORMALIZED) : OBJ_NEW()
    mapProj = ISA(oDS) ? oDS->_GetMapProjection() : OBJ_NEW()
    if (ISA(mapProj)) then begin
      oMap = (mapProj ne self.__obj__) ? Graphic_GetGraphic(mapProj) : self
    endif else begin
      ; If all else fails, try to get it using the default name.
      oMap = self['MAP PROJECTION']
    endelse
  endif

  if ARG_PRESENT(oParent) then begin
    self.__obj__->GetProperty, PARENT=oP
    if (ISA(oP, 'IDLitVisDataspace')) then $
      oP = oP->GetDataspace()
    oParent = OBJ_NEW('Graphic', oP)
  end

  if ARG_PRESENT(oTitle) then begin
    ; Get the title from the proper data space
    oTool = self.__obj__.GetTool()
    oSelf = oTool->GetByIdentifier(self.__obj__->GetFullIdentifier())
    dsID = ''
    if (ISA(oSelf, '_IDLitVisualization')) then begin
      oDS = oSelf->GetDataspace()
      oDS->GetProperty, IDENTIFIER=dsID
      dsID += '/'
    endif 
    oTitle = self[dsID+'TITLE']
  endif

  if ARG_PRESENT(oWin) then begin
    oTool = self.__obj__->GetTool()
    oWin = oTool->GetCurrentWindow()
  endif

  if (ARG_PRESENT(xrange) || ARG_PRESENT(yrange) || ARG_PRESENT(zrange)) then begin
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.GetProperty, X_MINIMUM=xMin, X_MAXIMUM=xMax, $
          Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
          Z_MINIMUM=zMin, Z_MAXIMUM=zMax
        xrange = [xMin, xMax]
        yrange = [yMin, yMax]
        zrange = [zMin, zMax]
      endif
    endif
  endif

  if (ISA(ex)) then begin
    ; Hack to avoid keyword conflicts with WINDOW keyword.
    ; Just get the WINDOW_TITLE out of the ref_extra.
    if (MAX(ex eq 'WINDOW_TITLE') eq 1) then begin
      oTool = self.__obj__.GetTool()
      if (ISA(oTool)) then oTool.GetProperty, NAME=winTitle
      (SCOPE_VARFETCH('WINDOW_TITLE', /REF_EXTRA)) = winTitle
    endif
    if (self.__obj__ ne self) then begin
      (self.__obj__)->GetProperty, _EXTRA=ex
    endif
  endif

end


;---------------------------------------------------------------------------
pro Graphic::SetProperty, $
  ASPECT_RATIO=aspectRatio, $
  ASPECT_Z=aspectZ, $
  BACKGROUND_COLOR=bgColor, $
  DEPTH_CUE=depthCue, $
  TITLE=title, $
  WINDOW_TITLE=winTitle, $
  XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, $
  _EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  if (~ISA(self.__obj__)) then return

  axisKeywords = ["XCOLOR", "YCOLOR", "ZCOLOR", "XGRIDSTYLE", "YGRIDSTYLE", "ZGRIDSTYLE", $
                "XLOG", "YLOG", "ZLOG", "XMAJOR", "YMAJOR", "ZMAJOR", "XMINOR", "YMINOR", $
                "ZMINOR", "XSUBTICKLEN", "YSUBTICKLEN", "ZSUBTICKLEN", "XTEXT_COLOR", $
                "YTEXT_COLOR", "ZTEXT_COLOR", "XTEXTPOS", "YTEXTPOS", "ZTEXTPOS", "XTHICK", $
                "YTHICK", "ZTHICK", "XTICKDIR", "YTICKDIR", "ZTICKDIR", "XTICKFONT_NAME", $
                "YTICKFONT_NAME", "ZTICKFONT_NAME", "XTICKFONT_SIZE", "YTICKFONT_SIZE", $
                "ZTICKFONT_SIZE", "XTICKFONT_STYLE", "YTICKFONT_STYLE", "ZTICKFONT_STYLE", $
                "XTICKFORMAT", "YTICKFORMAT", "ZTICKFORMAT", "XTICKINTERVAL", "YTICKINTERVAL", $
                "ZTICKINTERVAL", "XTICKLAYOUT", "YTICKLAYOUT", "ZTICKLAYOUT", "XTICKLEN", $
                "YTICKLEN", "ZTICKLEN", "XTICKNAME", "YTICKNAME", "ZTICKNAME", "XTICKUNITS", $
                "YTICKUNITS", "ZTICKUNITS", "XTICKVALUES", "YTICKVALUES", "ZTICKVALUES", "XTITLE", $
                "YTITLE", "ZTITLE", "XTRANSPARENCY", "YTRANSPARENCY", "ZTRANSPARENCY"]

  ; If we find at least one Axis keyword, then pass
  ; everything in _EXTRA to SetProperty on the
  ; Axes object
  if (ISA(ex)) then begin
    propsSet = 0
    tagnames = TAG_NAMES(ex)
    foreach tagname, tagnames, index do begin
      foreach axisKey, axisKeywords do begin
        if (strmatch(axisKey,tagname)) then begin
          oDataSpace = self.__obj__.GetDataSpace()
          if ISA(oDataSpace) then $
            oAxes = oDataSpace->GetAxes(/CONTAINER)
          if (ISA(oAxes)) then begin
            oAxes.SetProperty, _EXTRA=ex
            propsSet = 1
            break
          endif
        endif
      endforeach
    if propsSet then break
    endforeach
  endif

  if (ISA(ex)) then begin
  tagnames = TAG_NAMES(ex)
  extra = {}
  
  foreach tagname, tagnames, index do begin
    value = ex.(index)
    if (strmatch(tagname, "*COLOR*") && $
      (tagname ne "USE_DEFAULT_COLOR") && (tagname ne "AUTO_COLOR")) || $
      (tagname eq "BOTTOM") || (tagname eq "AMBIENT") then begin
      valueIn = value
      Style_Convert, valueIn, COLOR=value
    endif
    
    if ((tagname eq "LINESTYLE") && isa(value, 'STRING')) then $
      value  = linestyle_convert(value)
    
    if (((tagname eq "SYM_INDEX") || (tagname eq "SYMBOL")) && isa(value, 'STRING'))  then $
      value  = symbol_convert(value)

    extra = CREATE_STRUCT(extra, tagname, value)
  endforeach

  endif

  if (ISA(aspectRatio)) then begin
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.SetProperty, ASPECT_RATIO=aspectRatio
        oTool = self.__obj__.GetTool()
        oTool.RefreshCurrentWindow
      endif
    endif
  endif
  
  if (ISA(aspectZ)) then begin
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.SetProperty, ASPECT_Z=aspectZ
        oTool = self.__obj__.GetTool()
        oTool.RefreshCurrentWindow
      endif
    endif
  endif
  
  if (ISA(bgColor)) then begin
    Style_Convert, bgColor, COLOR=backgroundColor
    oTool = self.__obj__.GetTool()
    oWin = oTool.GetCurrentWindow()
    oView = ISA(oWin) ? oWin.GetCurrentView() : OBJ_NEW()
    oLayer = ISA(oView) ? oView.GetCurrentLayer() : OBJ_NEW()
    if ISA(oLayer) then oLayer.SetProperty, COLOR=backgroundColor
  endif

  if (ISA(depthCue)) then begin
    oTool = self.__obj__.GetTool()
    oWin = oTool.GetCurrentWindow()
    oView = ISA(oWin) ? oWin.GetCurrentView() : OBJ_NEW()
    oLayer = ISA(oView) ? oView.GetCurrentLayer() : OBJ_NEW()
    if ISA(oLayer) then oLayer.SetProperty, DEPTH_CUE=depthCue
  endif

  if (ISA(title)) then begin
    if ~ISA(title,'STRING') then MESSAGE, 'TITLE must be a string.'
    ; This will retrieve the title object, or create one if it doesn't exist.
    self.GetProperty, TITLE=oTitle
    ; If we don't have a title yet, then create one.
    if (~ISA(oTitle) && ISA(self.__obj__)) then begin
      id = self.__obj__->GetFullIdentifier()
      iText, '', TARGET=id, /TITLE
      oTitle = self['TITLE']
    endif
    if ~ISA(oTitle) then MESSAGE, 'Unable to retrieve title.'
    oTitle.string = title
  endif

  if (ISA(winTitle,'STRING')) then begin
    ; Pass the window title to the workbench.
    oTool = self.__obj__->GetTool()
    if (ISA(oTool)) then begin
      oTool->SetProperty, NAME=winTitle
      void = IDLNotify('IDLitThumbnail', $
        winTitle + '::' + oTool->GetFullIdentifier(), '')
    endif
  endif

  if (ISA(xrange)) then begin
    if (N_ELEMENTS(xrange) ne 2) then MESSAGE, 'XRANGE must have 2 elements.'
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.SetProperty, X_MINIMUM=xrange[0], X_MAXIMUM=xrange[1]
      endif
    endif
  endif

  if (ISA(yrange)) then begin
    if (N_ELEMENTS(yrange) ne 2) then MESSAGE, 'YRANGE must have 2 elements.'
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.SetProperty, Y_MINIMUM=yrange[0], Y_MAXIMUM=yrange[1]
      endif
    endif
  endif

  if (ISA(zrange)) then begin
    if (N_ELEMENTS(zrange) ne 2) then MESSAGE, 'ZRANGE must have 2 elements.'
    if (ISA(self.__obj__, '_IDLitVisualization')) then begin
      oDS = self.__obj__.GetDataSpace()
      if (ISA(oDS)) then begin
        oDS.SetProperty, Z_MINIMUM=zrange[0], Z_MAXIMUM=zrange[1]
      endif
    endif
  endif
  
  if (ISA(extra) && self.__obj__ ne self) then begin
    self.__obj__->SetProperty, _EXTRA=extra
    oTool = self.__obj__->GetTool()
    if (OBJ_VALID(oTool)) then begin
      tags = TAG_NAMES(extra)
      for i=0,N_ELEMENTS(extra)-1 do $
        oTool->DoOnNotify, self.__obj__->GetfullIdentifier(), "SETPROPERTY", $
          tags[i]
      oTool->RefreshCurrentWindow
    endif
  endif
end


;---------------------------------------------------------------------------
function Graphic::GetFullIdentifier
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    return, (self.__obj__)->GetFullIdentifier()
  endif else if (ISA(self, 'IDLitComponent')) then begin
    return, self->IDLitComponent::GetFullIdentifier()
  endif
  return, ''

end

;---------------------------------------------------------------------------
pro Graphic::Translate, X, Y, Z, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then $
    iTranslate, self->GetFullIdentifier(), X, Y, Z, _EXTRA=_extra
  
end

;---------------------------------------------------------------------------
pro Graphic::Rotate, degrees, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then $
    iRotate, self->GetFullIdentifier(), degrees, _EXTRA=_extra
  
end

;---------------------------------------------------------------------------
pro Graphic::Scale, X, Y, Z, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then $
    iScale, self->GetFullIdentifier(), X, Y, Z, _EXTRA=_extra
  
end

;---------------------------------------------------------------------------
pro Graphic::Order, orderIn, BRING_TO_FRONT=bringToFront, $
                             BRING_FORWARD=bringForward, $
                             SEND_TO_BACK=sendToBack, $
                             SEND_BACKWARD=sendBackward, $
                             _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    ; Determine order
    order = 'Bring to Front'
    if (N_ELEMENTS(orderIn) eq 1) then begin
      orderUP = STRUPCASE(orderIn)
      if (STRPOS(orderUP, 'BRING') ne -1) then $
        order = 'Bring Forward'
      if (STRPOS(orderUP, 'FORWARD') ne -1) then $
        order = 'Bring Forward'
      if (STRPOS(orderUP, 'FRONT') ne -1) then $
        order = 'Bring to Front'
      if (STRPOS(orderUP, 'SEND') ne -1) then $
        order = 'Send Backward'
      if (STRPOS(orderUP, 'BACK') ne -1) then $
        order = 'Send to Back'
      if (STRPOS(orderUP, 'BACKWARD') ne -1) then $
        order = 'Send Backward'
    endif
    if (KEYWORD_SET(sendBackward)) then $
      order = 'Send Backward'
    if (KEYWORD_SET(bringForward)) then $
      order = 'Bring Forward'
    if (KEYWORD_SET(sendToBack)) then $
      order = 'Send to Back'
    if (KEYWORD_SET(bringToFront)) then $
      order = 'Bring to Front'

    oTool = self.__obj__->GetTool()

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
    
    ; Call the Order action
    oDesc = oTool->GetOperations(IDENTIFIER='Edit/Order/Order')
    oOrder = oDesc->GetObjectInstance()
    oCmd = oOrder->DoAction(oTool, order, TARGET=self.__obj__)
    
    if (~wasDisabled) then $
      oTool->EnableUpdates

    if (ISA(oCmd)) then $
      oTool->_TransactCommand, oCmd
      
  endif
  
end


;---------------------------------------------------------------------------
pro Graphic::Refresh, DISABLE=disable
  compile_opt idl2, hidden

  if (ISA(self.__obj__)) then begin
    oTool = self.__obj__->GetTool()
    if (ISA(oTool)) then begin
      if (KEYWORD_SET(disable)) then begin
        oTool->DisableUpdates
      endif else begin
        oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
        oTool->EnableUpdates
        ; If we weren't disabled before, then the EnableUpdates will not
        ; actually do a re-draw. So force the re-draw.
        if (~wasDisabled) then begin
          oWin = oTool->GetCurrentWindow()
          if (ISA(oWin)) then oWin->Draw          
        endif
      endelse
    endif
  endif
end


;---------------------------------------------------------------------------
function Graphic::ConvertCoord, X, Y, Z, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    case n_params() of
    1: return, (self.__obj__)->ConvertCoord(X, _EXTRA=_extra)    
    2: return, (self.__obj__)->ConvertCoord(X, Y, _EXTRA=_extra)
    3: return, (self.__obj__)->ConvertCoord(X, Y, Z, _EXTRA=_extra)
    endcase
  endif else if (ISA(self, '_IDLitVisualization')) then begin
    return, self->_IDLitVisualization::ConvertCoord(X, Y, Z, _EXTRA=_extra)
  endif

  return, 0

end

;---------------------------------------------------------------------------
pro Graphic::PutData, arg1, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    case n_params() of
    1: (self.__obj__)->PutData, arg1, _EXTRA=_extra
    endcase
  endif else if (ISA(self, '_IDLitVisualization')) then begin
;    return, self->_IDLitVisualization::ConvertCoord(X, Y, Z, _EXTRA=_extra)
  endif

end


;---------------------------------------------------------------------------
function Graphic::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ASPECT_RATIO','ASPECT_Z','BACKGROUND_COLOR','DEPTH_CUE', $
    'HIDE','NAME', $
    'TITLE','WINDOW_TITLE','XRANGE','YRANGE','ZRANGE']
  return, myprops
end


;---------------------------------------------------------------------------
pro Graphic::Select, ALL=all, CLEAR=clear, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    oTool = self.__obj__->GetTool()
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
    
    (self.__obj__)->Select, UNSELECT=clear, _EXTRA=_extra
    ; Select everything
    if (KEYWORD_SET(all) || KEYWORD_SET(clear)) then begin
      oVis = []
      ; Get all data spaces
      dsID = iGetID('DATA SPACE*', TOOL=oTool->GetFullIdentifier())
      for i=0,N_ELEMENTS(dsID)-1 do begin
        oDS = oTool->GetByIdentifier(dsID[i])
        if (OBJ_VALID(oDS)) then begin
          oDSVis = oDS->GetVisualizations()
          if (OBJ_VALID(oDSVis[0])) then $
            oVis = [oVis, oDSVis]
        endif
      endfor
      ; Get annotations
      annID = iGetID('ANNOTATION LAYER/*', TOOL=oTool->GetFullIdentifier())
      for i=0,N_ELEMENTS(annID)-1 do begin
        oAnn = oTool->GetByIdentifier(annID[i])
        if (ISA(oAnn, '_IDLitVisualization')) then $
          oVis = [oVis, oAnn]
      endfor
      for i=0,N_ELEMENTS(oVis)-1 do $
        oVis[i]->Select, ADD=KEYWORD_SET(all), UNSELECT=KEYWORD_SET(clear) 
    endif

    if (~previouslyDisabled) then begin
      oTool->EnableUpdates
      oTool->RefreshCurrentWindow
    endif

    ; Make sure this is the current tool.
    iSetCurrent, oTool->GetFullIdentifier()
    ; Notify the workbench to bring the window to the front
    !NULL = IDLNotify('IDLitSetCurrent', oTool->GetFullIdentifier(), '')
  endif

end


;---------------------------------------------------------------------------
function Graphic::GetSelect, _EXTRA=_extra
  compile_opt idl2, hidden

@graphic_error

  oGraphics = []
  if (ISA(self.__obj__) && self.__obj__ ne self) then begin
    oTool = self.__obj__->GetTool()
    oSel = oTool->GetSelectedItems(count=nSel)
    for i=0,nSel-1 do begin
      if (ISA(oSel[i], 'IDLitVisNormDataspace')) then begin
        oVis = oSel[i]->GetVisualizations(COUNT=cnt)
        if (cnt eq 1) then oSel[i] = oVis
      endif
      oGraphics = [oGraphics, Graphic_GetGraphic(oSel[i])]
    endfor
    if (N_ELEMENTS(oGraphics) eq 1) then $
      oGraphics = oGraphics[0]
  endif

  return, ISA(oGraphics) ? oGraphics : !NULL
  
end



;---------------------------------------------------------------------------
function Graphic::_overloadPrint
  compile_opt idl2, hidden
@graphic_error

  result = OBJ_CLASS(self) + $
    ' <' + STRTRIM(OBJ_VALID(self,/GET_HEAP_ID),2) + '>'
  if (OBJ_ISA(self.__obj__, 'IDLitComponent')) then begin
    props = self->QueryProperty()
    n = N_ELEMENTS(props)
    if (n gt 0) then begin
      props = props[SORT(props)]
      result = [result, STRARR(n)]
      for i=0,n-1 do begin
        result[i+1] = STRING(props[i], FORMAT='("  ", A-25, " = ")')
        CATCH, iErr
        ; Quietly keep going if an error occurs.
        if (iErr ne 0) then begin
          CATCH, /CANCEL
          continue
        endif
        if (self.GetPropertyByIdentifier(props[i], value)) then begin
          sval = STRING(value, /PRINT)
          isMultiLine = N_ELEMENTS(sval) gt 1
          sval = STRTRIM(sval[0], 2)
          if (ISA(value, 'STRING')) then sval = "'" + sval
          result[i+1] += STRTRIM(sval,2)
          if isMultiLine then result[i+1] += ' ...'
          if (ISA(value, 'STRING')) then result[i+1] += "'"
        endif
      endfor
    endif
    ; Ensure that we print out 1 line per string.
    result = REFORM(result, 1, N_ELEMENTS(result), /OVERWRITE)
  endif

  return, result

end


;---------------------------------------------------------------------------
function Graphic::_overloadHelp, varname
  compile_opt idl2, hidden

  result = varname
  slen = STRLEN(varname)
  if (slen lt 15) then result += STRJOIN(REPLICATE(' ', 15 - slen))
  result += ' ' + OBJ_CLASS(self) + $
    ' <' + STRTRIM(OBJ_VALID(self,/GET_HEAP_ID),2) + '>'

  return, result

end


;---------------------------------------------------------------------------
function Graphic::_overloadBracketsRightSide, isRange, $
  i1, i2, i3, i4, i5, i6, i7, i8

  compile_opt idl2, hidden
@graphic_error

  ; If we have a string then find the object by identifier.
  if (ISA(i1, 'STRING') && ISA(self.__obj__)) then begin
    oTool = self.__obj__->GetTool()
    if (~OBJ_VALID(oTool)) then return, OBJ_NEW()

    myid = self.__obj__->GetFullIdentifier()

    result = !NULL
;    foreach identifier, i1 do begin
    for i=0,n_elements(i1)-1 do begin
      identifier = i1[i]

      ; If this is a relative identifier, then first try to find the
      ; object within my graphic's container.
      if (myid ne '' && STRMID(identifier,0,1) ne '/') then begin
;        id = iGetID(myid + '/*' + identifier)
        id = iGetID(identifier+'*', DATASPACE=myid, TOOL=oTool->GetFullIdentifier())
        isTitle = STRPOS(STRUPCASE(identifier), 'TITLE') ne -1
        if (N_ELEMENTS(id) eq 1 && id eq '' && ~isTitle) then begin
          ; Watch out - iGetID only returns the first partial match,
          ; which might not be correct. So throw a wildcard * on front.
          id = iGetID('*' + identifier, TOOL=oTool->GetFullIdentifier())
        endif
        ; If we retrieved more than 1 match, and we were not using a wildcard,
        ; then try to find an exact match. For example, this avoids a bug
        ; when trying to retrieve "Kansas" from a shapefile graphic,
        ; and you incorrectly get both "Arkansas" and "Kansas".
        if (N_ELEMENTS(id) gt 1 && STRPOS(identifier, '*') eq -1) then begin
          w = WHERE(STRPOS(id, '/' + STRUPCASE(identifier)) ge 0, /NULL)
          if (N_ELEMENTS(w) eq 1) then begin
            id = id[w[0]]
          endif else begin
            id = id[0]
          endelse
        endif
      endif else begin
        id = iGetID(identifier, TOOL=oTool->GetFullIdentifier())
      endelse
  
      n = N_ELEMENTS(id)
      graphics = (n gt 1) ? OBJARR(n) : OBJ_NEW()
  
      for j=0,n-1 do begin
        if (id[j] eq '') then continue
        obj1 = oTool->GetByIdentifier(id[j])
        if (~ISA(obj1)) then continue

        ; If our own object is the one we found, just return ourself.
        ; Otherwise wrap the new object in a Graphic subclass.
        graphics[j] = (obj1 ne self.__obj__) ? Graphic_GetGraphic(obj1) : self
      endfor

      result = ISA(result) ? [result, graphics] : graphics
    endfor
    
    good = WHERE(OBJ_VALID(result), ngood)
    if (ngood gt 1) then begin
      result = result[good]
    endif else if (ngood eq 1) then begin
      result = result[good[0]]
    endif else begin
      result = OBJ_NEW()
    endelse
    return, result

  endif

  return, self->IDL_Object::_overloadBracketsRightSide( $
    isRange, i1, i2, i3, i4, i5, i6, i7, i8)

end


;---------------------------------------------------------------------------
; This should only get called if someone does a Foreach on a scalar
; Graphic object, say as the result of a call to graphic['*']. The user might
; want to just do a Foreach without having to check whether multiple items
; were returned, or a single Graphic.
;
function Graphic::_overloadForeach, value, index

  compile_opt idl2, hidden
  ON_ERROR, 2

  if (index eq !null) then index = 0 else index++

  ; If index is 0, just return ourself. Otherwise we're done.
  if index lt 1 then begin
    value = self
    return, 1
  endif
  return, 0

end

;---------------------------------------------------------------------------
; Returns a 3xMxN array of image data from the current graphics window
;
function Graphic::CopyWindow, WIDTH=width, $
                              HEIGHT=height, $
                              RESOLUTION=resolution, $
                              _EXTRA=_extra

    compile_opt idl2, hidden

@graphic_error

  oTool = ISA(self.__obj__) ? self.__obj__->GetTool() : self->GetTool()
  if (~ISA(oTool)) then message, "Unable to retrieve graphics window."
  
  oWin = oTool->GetCurrentWindow( )

  ; get file writer service - that service will be used to
  ; retrieve the image data
  oWriteFile = oTool->GetService("WRITE_FILE")
  
  ; If no resolution, width, or height have been specified, return
  ; an image the same size as the graphics window
  if (~keyword_set(resolution) && $
      ~keyword_set(width) && $
      ~keyword_set(height)) then width = (oWin.DIMENSIONS)[0]
  
  ; Get image data
  return, oWriteFile.GetImage( oWin, WIDTH=width, HEIGHT=height, RESOLUTION=resolution, _EXTRA=_extra )
  
end

;---------------------------------------------------------------------------
function Plot::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'ERRORBAR_COLOR', 'ERRORBAR_CAPSIZE', $
    'FILL_BACKGROUND','FILL_COLOR','FILL_LEVEL', $
    'FILL_TRANSPARENCY','LINESTYLE', $
    'MAX_VALUE','MIN_VALUE','SYM_COLOR','SYM_FILLED', $
    'SYM_FILL_COLOR','SYM_INCREMENT','SYMBOL','SYM_SIZE','SYM_THICK', $
    'SYM_TRANSPARENCY','THICK','TRANSPARENCY']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Barplot::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','BOTTOM_COLOR','BOTTOM_VALUES','COLOR', $
    'C_RANGE','FILL_COLOR','HORIZONTAL','INDEX','LINESTYLE', $
    'NBARS','OUTLINE','THICK','TRANSPARENCY','WIDTH']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Plot3D::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
;    'ERRORBAR_COLOR', 'ERRORBAR_CAPSIZE', $
    'LINESTYLE', $
    'SHADOW_COLOR','SYM_COLOR','SYM_FILLED', $
    'SYM_FILL_COLOR','SYM_INCREMENT','SYMBOL','SYM_SIZE','SYM_THICK', $
    'SYM_TRANSPARENCY','THICK','TRANSPARENCY', $
    'XY_SHADOW', 'XZ_SHADOW', 'YZ_SHADOW']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Image::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['GRID_UNITS','INTERPOLATE', $
    'MAP_PROJECTION','MAX_VALUE','MIN_VALUE','RGB_TABLE', $
    'TRANSPARENCY']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Surface::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['BOTTOM_COLOR','COLOR', $
    'LINESTYLE','MAX_VALUE','MIN_VALUE','SHADING', $
    'SHOW_SKIRT','SKIRT','STYLE','TEXTURE_INTERP','THICK', $
    'TRANSPARENCY']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Contour::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['C_COLOR','C_FILL_PATTERN','C_LABEL_INTERVAL', $
    'C_LABEL_NOGAPS', 'C_LABEL_OBJECTS', 'C_LABEL_SHOW', 'C_LINESTYLE', $
    'COLOR', 'C_THICK', 'C_USE_LABEL_COLOR', 'C_USE_LABEL_ORIENTATION', $
    'C_VALUE', 'DAYS_OF_WEEK', 'DOWNHILL', 'FILL', 'GRID_UNITS', $
    'LABEL_COLOR', 'LABEL_FORMAT', 'LABEL_UNITS', $
    'MAX_VALUE','MIN_VALUE','MONTHS','N_LEVELS','PLANAR', $
    'SHADE_RANGE','SHADING', $
    'TICKINTERVAL','TICKLEN', $
    'TRANSPARENCY','USE_TEXT_ALIGNMENTS']
  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Text::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ALIGNMENT','BASELINE','COLOR', $
    'FILL_BACKGROUND', 'FILL_COLOR', $
    'FONT_COLOR', 'FONT_NAME', 'FONT_SIZE', 'FONT_STYLE', $
    'HIDE','NAME', 'STRING', $
    'TRANSPARENCY','UPDIR', 'VERTICAL_ALIGNMENT']
  ; Do not return Graphic's properties, since this is just a helper graphic.
  return, myprops
end


;---------------------------------------------------------------------------
function Polygon::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'FILL_BACKGROUND', 'FILL_COLOR', 'FILL_TRANSPARENCY', $
    'HIDE','LINESTYLE','NAME','THICK', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since this is just a helper graphic.
  return, myprops
end


;---------------------------------------------------------------------------
function Polyline::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'HIDE','LINESTYLE','NAME','THICK', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since this is just a helper graphic.
  return, myprops
end


;---------------------------------------------------------------------------
function Ellipse::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', 'FILL_TRANSPARENCY', $
    'FILL_BACKGROUND', 'FILL_COLOR', $
    'HIDE','LINESTYLE','NAME','THICK', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since Text is just an annotation.
  return, myprops
end


;---------------------------------------------------------------------------
function MapGrid::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'FONT_NAME', 'FONT_SIZE', 'FONT_STYLE', $
    'GRID_LONGITUDE', 'GRID_LATITUDE', $
    'HIDE','LABEL_ALIGN','LABEL_ANGLE','LABEL_COLOR', $
    'LABEL_FILL_BACKGROUND', 'LABEL_FILL_COLOR', 'LABEL_POSITION', $
    'LABEL_SHOW', 'LABEL_VALIGN', $
    'LATITUDE_MAX', 'LATITUDE_MIN', 'LONGITUDE_MAX', 'LONGITUDE_MIN', $
    'LINESTYLE','NAME','THICK', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since this is just a helper graphic.
  return, myprops
end


;---------------------------------------------------------------------------
function Vector::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','ARROW_STYLE','ARROW_THICK', $
    'AUTO_COLOR', 'AUTO_RANGE', 'AUTO_SUBSAMPLE','COLOR', $
    'DATA_LOCATION','DIRECTION_CONVENTION', $
    'GRID_UNITS','HEAD_ANGLE','HEAD_INDENT','HEAD_PROPORTIONAL','HEAD_SIZE',$
    'LENGTH_SCALE','MAX_VALUE','MIN_VALUE', $
    'SUBSAMPLE_METHOD', $
    'SYM_COLOR','SYM_FILLED','SYM_FILL_COLOR','SYMBOL','SYM_SIZE', $
    'SYM_THICK','SYM_TRANSPARENCY','THICK', $
    'TRANSPARENCY', $
    'USE_DEFAULT_COLOR','VECTOR_STYLE', $
    'X_SUBSAMPLE','Y_SUBSAMPLE', 'ZVALUE']

  return, [myprops, self->Graphic::QueryProperty()]
end


;---------------------------------------------------------------------------
function Streamline::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS', $
    'ARROW_COLOR','ARROW_OFFSET', 'ARROW_SIZE', 'ARROW_THICK', $
    'ARROW_TRANSPARENCY', $
    'AUTO_COLOR', 'AUTO_RANGE', 'COLOR', $
    'DIRECTION_CONVENTION', $
    'GRID_UNITS',$
    'STREAMLINE_NSTEPS','STREAMLINE_STEPSIZE', $
    'THICK', 'TRANSPARENCY', $
    'X_STREAMPARTICLES','Y_STREAMPARTICLES', 'ZVALUE']

  return, [myprops, self->Graphic::QueryProperty()]
end



;------------------------------------------------------------------------
pro Graphic__define
  compile_opt idl2, hidden
 
  void = {Graphic, inherits IDL_Object}

  void = {Plot, inherits Graphic}
  void = {Barplot, inherits Graphic}
  void = {Plot3D, inherits Graphic}
  void = {Image, inherits Graphic}
  void = {Surface, inherits Graphic}
  void = {Contour, inherits Graphic}
  void = {Vector, inherits Graphic}
  void = {Streamline, inherits Graphic}
  void = {Text, inherits Graphic}
  void = {Polygon, inherits Graphic}
  void = {Polyline, inherits Graphic}
  void = {Ellipse, inherits Graphic}
  void = {MapGrid, inherits Graphic}

end
