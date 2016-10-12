; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/legend__define.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create a Legend.
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
function Legend::Init, oObj, _EXTRA=_extra
  compile_opt idl2, hidden
  ON_ERROR, 2

  if (ISA(oObj)) then $
    return, self->Graphic::Init(oObj)

  oCmd = self->_Create(oLegend, _EXTRA=_extra)
  if (ISA(oLegend)) then begin
    self.__obj__ = oLegend
    oTool = oLegend->GetTool()
    if (OBJ_VALID(oTool)) then $
      oTool->_TransactCommand, oCmd
    ; Do not leave new legend selected
    self->Select, /Clear
    return, 1
  endif
  
  return, 0
  
end


;-------------------------------------------------------------------------
pro Legend::_FilterTargets, oTargets
  compile_opt idl2, hidden

  ; filter to acceptable visualizations
  oVisTargets = []
  for i=0, N_ELEMENTS(oTargets)-1 do begin
    if ( (OBJ_ISA(oTargets[i], 'IDLitVisPlot') || $
          OBJ_ISA(oTargets[i], 'IDLitVisPlot3D') )) $
      then begin
      ;          (OBJ_ISA(oTargets[i], 'IDLitVisContour')) || $
      ;          (OBJ_ISA(oTargets[i], 'IDLitVisSurface'))) then begin
      oVisTargets = [oVisTargets, oTargets[i]]
    endif
  endfor
  oTargets = oVisTargets

end


;-------------------------------------------------------------------------
function Legend::_Create, oLegend, $
                          DEVICE=device, $
                          DATA=data, $
                          POSITION=positionIn, $
                          TARGET=targetIn, $
                          _REF_EXTRA=_extra
  compile_opt idl2, hidden

  nTargets = 0
  ; Get tool
  if (MIN(OBJ_VALID(targetIn) eq 1)) then begin
    oTool = targetIn[0].tool
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
        ;; Get first data space with a plot
        if (OBJ_VALID(oView)) then begin
          dsIDs = oView->FindIdentifiers('*DATA SPACE*')
          ;; Loop through data spaces until the first data space with
          ;; acceptable legend targets are found
          for i=0,N_ELEMENTS(dsIDs)-1 do begin
            oDS = oTool->GetByIdentifier(dsIDs[i])
            if (OBJ_VALID(oDS) && ISA(oDS, '_IDLitVisualization')) then begin
              oDSObjs = oDS->GetVisualizations()
              self._FilterTargets, oDSObjs  
              if (ISA(oDSObjs)) then break
            endif
          endfor
          oTargets = oDSObjs
          nTargets = N_ELEMENTS(oTargets)
        endif
      endif
    endif
  endelse

  ; filter to acceptable visualizations
  self._FilterTargets, oTargets

  nTargets = N_ELEMENTS(oTargets)

  if (nTargets eq 0) then begin
    message, 'No suitable legend items found'
    return, OBJ_NEW()
  endif
    
  idTargets = STRARR(nTargets)
  for i=0,nTargets-1 do $
    idTargets[i] = oTargets[i]->GetFullIdentifier()
    
  if (N_ELEMENTS(positionIn) ge 2) then begin
    newPos = iConvertCoord(positionIn[0], positionIn[1], /TO_NORMAL, $
                           DATA=data, DEVICE=device, TARGET=idTargets[0])
    position = newPos[0:1]
  endif    

  oCreate = oTool->GetService("CREATE_VISUALIZATION")
  if (~Obj_Valid(oCreate)) then return, OBJ_NEW()

  oVisDesc = oTool->GetAnnotation('LEGEND')

  ; Call _Create so we don't have to worry about type matching.
  ; We know we want to create a legend.
  oCmd = oCreate->_Create(oVisDesc, $
                          ID_VISUALIZATION=visID, $
                          LAYER='ANNOTATION', $
                          VIS_TARGET=idTargets, $
                          /MANIPULATOR_TARGET, $
                          /SHADOW, $
                          POSITION=position, $
                          LOCATION=[0.6d,0.95d], $  ; initially in upper right corner
                          _EXTRA=_extra)
  oLegend = oTool->GetByIdentifier(visID)

  ;; wire up changes to the target vis
  for i=0,nTargets-1 do $
    oTool->AddOnNotifyObserver,visID,oTargets[i]->GetFullIdentifier()

  oCmd[0]->SetProperty, NAME='Insert Legend'
  return, oCmd

end


;-------------------------------------------------------------------------
pro Legend::Add, targetIn, $
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

  for i=0,nTargets-1 do begin
    self.__obj__->AddToLegend, oTargets[i]
  endfor
  oTool = self.__obj__->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow
  
end


;---------------------------------------------------------------------------
function Legend::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['COLOR', $
    'FONT_NAME','FONT_SIZE', 'FONT_STYLE', $
    'HIDE','HORIZONTAL_ALIGNMENT','HORIZONTAL_SPACING','LINESTYLE', $
    'NAME','ORIENTATION','POSITION','SAMPLE_WIDTH','SHADOW','TEXT_COLOR', $
    'THICK', $
    'TRANSPARENCY', 'VERTICAL_ALIGNMENT', 'VERTICAL_SPACING']
  ; Do not return Graphic's properties, since Text is just an annotation.
  return, myprops
end


;-------------------------------------------------------------------------
pro Legend__define
  compile_opt idl2, hidden
  void = {Legend, inherits Graphic}
end

