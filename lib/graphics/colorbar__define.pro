; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/colorbar__define.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create a Colorbar.
;
; :Params:
;    Projection
;
; :Keywords:
;    
;
; :Author: ITTVIS, March 2010
;-
;-------------------------------------------------------------------------
function Colorbar::Init, oObj, _EXTRA=_extra
  compile_opt idl2, hidden
  ON_ERROR, 2

  if (ISA(oObj)) then $
    return, self->Graphic::Init(oObj)

  oCmd = self->_Create(oColorbar, _EXTRA=_extra)
  if (ISA(oColorbar)) then begin
    self.__obj__ = oColorbar
    oTool = oColorbar->GetTool()
    if (OBJ_VALID(oTool)) then $
      oTool->_TransactCommand, oCmd
    ; Do not leave new colourbar selected
    self->Select, /Clear
    return, 1
  endif
  
  return, 0
  
end


;-------------------------------------------------------------------------
function Colorbar::_Create, oColorbar, $
                            ORIENTATION=orientation, $
                            POSITION=positionIn, $
                            DEVICE=device, $
                            DATA=data, $
;                            LOCATION=locationIn, $
                            TARGET=targetIn, $
                            TITLE=title, $
                            _REF_EXTRA=_extra
  compile_opt idl2, hidden

  nTargets = 0
  ; Get tool
  if (MIN(OBJ_VALID(targetIn) eq 1)) then begin
    oTool = targetIn.tool
    oTargets = []
    if (ISA(oTool)) then begin
      for i=0,N_ELEMENTS(targetIn)-1 do $
        oTargets = [oTargets, $
          oTool->GetByIdentifier(targetIn[i]->GetFullIdentifier())]
      nTargets = N_ELEMENTS(oTargets)
    endif 
  endif else begin
    !NULL = iGetCurrent(TOOL=oTool)
    if (ISA(oTool)) then begin
      ; Retrieve the current selected item(s).
      oTargets = oTool->GetSelectedItems(count=nTargets)
      if (nTargets eq 0) then begin
        ;; Get window
        oWin = oTool->GetCurrentWindow()
        oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : []
        ;; Get first data space
        if (OBJ_VALID(oView)) then begin
          dsID = (oView->FindIdentifiers('*DATA SPACE*'))[0]
          oDS = oTool->GetByIdentifier(dsID)
        endif
        if (OBJ_VALID(oDS)) then begin
          oDSObjs = oDS->GetVisualizations()
          if ((N_ELEMENTS(oDSObjs) eq 1) && (OBJ_VALID(oDSObjs))) then begin
            oTargets = oDSObjs[0]
            nTargets = 1
          endif
        endif
      endif
    endif
  endelse

  if (nTargets eq 0) then begin
    message, 'No items found that contain color palettes'
    return, OBJ_NEW()
  endif
    
  oCreate = oTool->GetService("CREATE_VISUALIZATION")
  if (not OBJ_VALID(oCreate)) then $
    return, OBJ_NEW()
    
  oColorbarDesc = oTool->GetVisualization('COLORBAR')
  
  oVisCmdSet = OBJ_NEW()  ; list of undo/redo commands to return
  
  for i=0, nTargets-1 do begin

    if ~OBJ_ISA(oTargets[i], 'IDLitParameter') then $
      continue
      
    ; Skip colorbars even though they have palettes
    if (~OBJ_VALID(oTargets[i]) || $
      OBJ_ISA(oTargets[i], 'IDLitVisColorbar')) then $
      continue
      
    ; First look for a special parameter that gives the actual
    ; data used for the colorbar range.
    oData = oTargets[i]->GetParameter('VISUALIZATION DATA')
    ; If not found then get the first optarget parameter.
    if (~OBJ_VALID(oData)) then begin
      oTargetParams = oTargets[i]->QueryParameter(COUNT=nTargetParam)
      for j=0,nTargetParam-1 do begin
        oTargets[i]->GetParameterAttribute, oTargetParams[j], $
          OPTARGET=isOpTarget
        if (isOpTarget) then begin
          oData = oTargets[i]->GetParameter(oTargetParams[j])
          break
        endif
      endfor
      if (~OBJ_VALID(oData)) then $
        continue
    endif
    
    nBars = oTargets[i]->GetParameterDataByType($
      ['IDLPALETTE','IDLOPACITY_TABLE'], oBarObj)
    if (~nBars) then continue
    
    nOpac = oTargets[i]->GetParameterDataByType($
      ['IDLOPACITY_TABLE'], oOpacObj)
      
    ;; Compute layout
    locations = FLTARR(3, nBars)
    locations[0,*] = (FINDGEN(nBars) - (nBars-1)/2.0) / (nBars*4) - 0.5
    locations[1,*] = (FINDGEN(nBars) - (nBars-1)/2.0) / (nBars*4) - 0.75
    locations[2,*] = 0.99d   ; above the Z plane so it doesn't get clipped
    
    ; Use user-provided locations.
    if (N_Elements(locationIn) gt 1) then begin
      ; Be nice and fill in only those elements which were provided.
      dims = Size(locationIn, /DIM)
      dim0 = dims[0] < 3
      dim1 = (N_Elements(dims) gt 1) ? (dims[1] < nBars) : 1
      locations[0:dim0-1, 0:dim1-1] = locationIn
    endif
    
    if (N_ELEMENTS(orientationIn) ne 0) then begin
      orientation = orientationIn
      while (N_ELEMENTS(orientation) lt nBars) do $
        orientation = [orientation, orientation]
    endif
    
    if (N_Elements(positionIn) eq nBars*4) then begin
      position = DOUBLE(positionIn)
      for j=0,nBars-1 do begin
        newPos = iConvertCoord(positionIn[[0,2]], positionIn[[1,3]], $
                               DEVICE=device, DATA=data, /TO_NORMAL, $
                               TARGET=oTargets[i])
        position[*,j] = [newPos[0:1,0],newPos[0:1,1]]               
      endfor
    endif else begin
      position = DBLARR(4)
      ; Place the colorbar under/right of the target
      deviceXYrange = (iConvertCoord(oTargets[i].parent.xrange, $
                                     oTargets[i].parent.yrange, /DATA, $
                                     /TO_DEVICE, TARGET=oTargets[i]))[0:1,*] 
      ; Place under/right of current target
      if ((N_ELEMENTS(orientation) ne 0) && (orientation[i] eq 1)) then begin
        deviceX = deviceXYrange[0,1] + ((50) * $
          (deviceXYrange[0,1] gt deviceXYrange[0,0]))
        deviceY = MEAN(deviceXYrange[1,*]) - ((256./2) * $
          (deviceXYrange[1,1] gt deviceXYrange[1,0]))
        pos = iConvertCoord([deviceX,deviceX+25.6], $
                            [deviceY,deviceY+256.], /DEVICE, $
                            /TO_NORMAL, TARGET=oTargets[i])
      endif else begin
        deviceX = MEAN(deviceXYrange[0,*]) - ((256./2) * $
          (deviceXYrange[0,1] gt deviceXYrange[0,0]))
        deviceY = deviceXYrange[1,0] - ((25 + 25) * $
          (deviceXYrange[1,1] gt deviceXYrange[1,0]))
        pos = iConvertCoord([deviceX,deviceX+256.], $
                            [deviceY,deviceY+25.6], /DEVICE, $
                            /TO_NORMAL, TARGET=oTargets[i])
      endelse
      position[*,i] = [pos[0:1,0],pos[0:1,1]]       
    endelse
    
    oTargets[i]->GetProperty, TRANSPARENCY=transparency
    
    for j=0, nBars-1 do begin
    
      oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME="ColorBarData", $
        DESCRIPTION="Color Bar Data")
        
      oParmSet->Add, oData[0], PARAMETER_NAME='VISUALIZATION DATA', $
        /PRESERVE_LOCATION
        
      ;; Decide between color and opacity.
      parmName = 'PALETTE'
      if nOpac gt 0 then begin
        if (WHERE(oBarObj[j] eq oOpacObj))[0] gt 0 then begin
          parmName = 'OPACITY TABLE'
        endif
      endif
      oParmSet->Add, oBarObj[j], PARAMETER_NAME=parmName,/PRESERVE_LOCATION
      
      if nBars gt 1 then $
        oBarObj[j]->GetProperty, NAME=title
        
      ;; disable updates so that if the colorbar needs to change
      ;; the inital range it will not be seen onscreen
      oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
      
      ; Call _Create so we don't have to worry about type matching.
      ; We know we want to create a colorbar.
      oVisCmd = oCreate->_Create(oColorbarDesc, oParmSet, $
                                 ID_VISUALIZATION=visID, $
                                 LAYER='ANNOTATION', $
                                 AXIS_TITLE=title, $
                                 LOCATION=locations[*,j], $
                                 IMAGE_TRANSPARENCY=transparency, $
                                 _EXTRA=_extra)
      oColorbar = oTool->GetByIdentifier(visID)
        
      ;; wire up changes to the target vis
      oTool->AddOnNotifyObserver,visID,oTargets[i]->GetFullIdentifier()
      ;; ensure that the current range is correct
      IF obj_isa(oTargets[i],'IDLitVisImage') THEN BEGIN
        oTargets[i]->GetProperty,BYTESCALE_MIN=bMin,BYTESCALE_MAX=bMax
        oColorbar->SetProperty,BYTESCALE_RANGE=[bMin,bMax]
      ENDIF
      if (OBJ_VALID(oColorbar)) then begin
        ;; Apply needed properties
        if (N_ELEMENTS(orientation) ne 0) then $
          oColorbar->SetProperty, ORIENTATION=orientation[i]
        if (N_ELEMENTS(position) ne 0) then $
          oColorbar->SetProperty, POSITION=position[*,i]
      endif
      
      IF (~previouslyDisabled) THEN $
        oTool->EnableUpdates
      oTool->RefreshCurrentWindow
      
      oParmSet->Remove,/ALL
      obj_destroy,oParmSet
      
      oVisCmdSet = OBJ_VALID(oVisCmdSet[0]) ? $
        [oVisCmdSet, oVisCmd] : oVisCmd
        
    endfor
  endfor
  
  if ~OBJ_VALID(oVisCmdSet[0]) then begin
    if (OBJ_VALID(oColorbar)) then $
      OBJ_DESTROY, oColorbar
    Message, 'Unable to create colorbar'
    return, OBJ_NEW()
  endif
  
  ; Make a prettier undo/redo name.
  oVisCmdSet[0]->SetProperty, NAME='Insert colorbar'
  
  return, oVisCmdSet

end


;-------------------------------------------------------------------------
pro Colorbar::GetProperty, $
  TITLE=title, $
  _REF_EXTRA=_extra
    
  @graphic_error
  
  if ARG_PRESENT(title) then $
    self.__obj__->GetProperty, AXIS_TITLE=title
  
  if (ISA(_extra)) then self.Graphic::GetProperty, _EXTRA=_extra

end



;-------------------------------------------------------------------------
pro Colorbar::SetProperty, $
  TITLE=title, $
  _EXTRA=_extra
    
  @graphic_error
  
  if (ISA(title)) then $
    self.__obj__->SetProperty, AXIS_TITLE=title
  
  if ISA(_extra) then $
    self.Graphic::SetProperty, _EXTRA=_extra

  if N_ELEMENTS(_extra) eq 0 then begin
    oTool = self.__obj__->GetTool()
    if (OBJ_VALID(oTool)) then begin
      oTool->RefreshCurrentWindow
    endif
  endif

end


;---------------------------------------------------------------------------
function Colorbar::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS', $
    'BORDER_ON','COLOR', $
    'FONT_NAME','FONT_SIZE', 'FONT_STYLE', $
    'HIDE', $
    'MAJOR', 'MINOR', $
;    'LOG', 'RANGE', $  ; CT, May 2010: these don't work quite right
    'NAME','ORIENTATION', 'SUBTICKLEN', 'TEXT_COLOR', $
    'TEXTPOS', 'THICK', 'TICKDIR', 'TICKFORMAT', $
    'TICKINTERVAL', 'TICKLAYOUT', 'TICKLEN', $
    'TICKNAME', 'TICKVALUES', $
    'TITLE', 'TRANSPARENCY']
  ; Do not return Graphic's properties, since Text is just an annotation.
  return, myprops
end


;-------------------------------------------------------------------------
pro Colorbar__define
  compile_opt idl2, hidden
  void = {Colorbar, inherits Graphic}
end

