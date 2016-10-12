; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/axis__define.pro#2 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create an Axis.
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
function Axis::Init, oObj, TICKNAME=tickName, $
    TICKFONT_NAME=tickfontName, $
    TICKFONT_STYLE=tickfontStyle, $
    TICKFONT_SIZE=tickfontSize, $
    _EXTRA=_extra
  
  compile_opt idl2, hidden
@graphic_error

  if (ISA(oObj)) then $
    return, self->Graphic::Init(oObj)

  oCmd = self->_Create(oAxis, _EXTRA=_extra)
  if (ISA(oAxis)) then begin
    self.__obj__ = oAxis
    oTool = oAxis->GetTool()
    if (OBJ_VALID(oTool)) then $
      oTool->_TransactCommand, oCmd
      
    ; Set the TICKNAME property separately to avoid
    ; double setting the value during creation
    self->SetProperty, TICKNAME=tickName, $
      TICKFONT_NAME=tickfontName, $
      TICKFONT_STYLE=tickfontStyle, $
      TICKFONT_SIZE=tickfontSize
      
    ; Deselect the new axi
    self->Select, /Clear
    
    return, 1
  endif
  
  return, 0
  
end

;-------------------------------------------------------------------------
function Axis::_FilterDataSpaceIdentifiers, targets, oTool

  compile_opt idl2, hidden

  dataspaces = []
  foreach t, targets do begin
    startpos = STRPOS( t, "DATA SPACE" )
    if STRPOS( t, "/", startpos ) EQ -1 THEN BEGIN
      oDS = oTool->GetByIdentifier(t)
      ; Must not have a Map Projection to be a valid target
      if (~KEYWORD_SET(oDS.GetProjection())) THEN $
        dataspaces = [dataspaces, t]
    ENDIF
  endforeach

  return, dataspaces

end

;-------------------------------------------------------------------------
function Axis::_Create, oAxis, $
        DIRECTION=direction, $
        TICKLEN=tickLen, $
        LOCATION=location, $
        TITLE=title, $
        TARGET=targetIn, $
        _EXTRA=_extra

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
        if (nTargets gt 0) then begin
          ; If all selected items are within a single dataspace
          ; then we have a valid target, not including map projections
          dsIDs = []
          foreach oTarg, oTargets do begin
            oDS = oTarg.GetDataSpace( )
            DSIdent = oDS.GetFullIDentifier( )
            if (~KEYWORD_SET( oDS.GetProjection())) then begin
;              if ( n_elements( dsIDs ) eq 0 ) then begin
;                dsIDs = [DSIdent]
;              endif else begin
                indices = where( dsIDs eq DSIDent, count )
                if ( count eq 0 ) then dsIDs = [dsIDs, DSIdent]
;              endelse
            endif
          endforeach
        endif else begin ; Nothing selected - find a suitable dataspace
          ;; Get window
          oWin = oTool->GetCurrentWindow()
          oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : []
          ; If nothing is selected and there is only one dataspace
          ; then set that data space as the target 
          if (OBJ_VALID(oView)) then begin
            dsID_List = (oView->FindIdentifiers('*DATA SPACE*'))
            dsIDs = self._FilterDataSpaceIdentifiers( dsID_List, oTool )
          endif
        endelse
      endif
      
      ; Only one valid target is allowed
      if (N_ELEMENTS(dsIDs) eq 1) then begin
        oTargets = oTool->GetByIdentifier(dsIDs[0])
        nTargets = 1
      endif else begin
        nTargets = N_ELEMENTS( dsIDs )
      endelse
      
    endelse
  
    if (nTargets eq 0) then begin
      message, 'Cannot insert axis: no valid targets found.'
      return, OBJ_NEW()
    endif
    
    if (nTargets gt 1) then begin
      message, 'Cannot insert axis: too many targets found.'
      return, OBJ_NEW()
    endif
    
    oDataSpace = oTargets[0]->GetDataSpace( )
    if (~ISA(oDataSpace, 'IDLITVISNORMDATASPACE')) then $
      message, 'Cannot insert axis: no valid targets found.'

    ; Prepare the service that will create the axis visualization.
    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (not OBJ_VALID(oCreate)) then $
        return, OBJ_NEW();

    oDataSpaceUnNorm = oDataSpace->GetDataSpace(/UNNORMALIZED)
    oAxes = (oDataSpaceUnNorm->Get(/ALL, ISA='IDLitVisDataAxes'))[0]
    if (~OBJ_VALID(oAxes)) then $
        return, OBJ_NEW();
    destination = oAxes->GetFullIdentifier()
    oAxisDesc = oTool->GetVisualization("AXIS")

    oAxes->GetProperty, $
        XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

    if N_ELEMENTS(location) eq 0 then begin
      case direction of
      0: begin     ; X axis
           range = xRange
           location = [0, yRange[0]-(yRange[1]-yRange[0])/10.0, $
                           zRange[0]]
      end
      1: begin     ; Y axis
           range = yRange
           location = [xRange[0]-(xRange[1]-xRange[0])/10.0, 0, $
                       zRange[0]]
      end
      2: begin     ; Z axis
           range = zRange
           location = [xRange[0]-(xRange[1]-xRange[0])/10.0, $
                       yRange[0], 0]
      end
      else:
      endcase
    endif
    
    if N_ELEMENTS(tickLen) eq 0 then tickLen = 0.05 ; Set up default value

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    oCommand = oCreate->_Create( $
                        oAxisDesc, $
                        DESTINATION=destination, $
                        DIRECTION=direction, $
                        ID_VISUALIZATION=idVis, $
                        RANGE = range, $
                        LOCATION = location, $
                        TICKLEN=tickLen, $ ; initial default
                        /MANIPULATOR_TARGET, $
                        AXIS_TITLE=title, $
                        _EXTRA=_extra)

    oAxis = oTool->GetByIdentifier(idVis)
    if OBJ_VALID(oAxis) then oAxes->Aggregate, oAxis

    oAxes->_UpdateAxesRanges

    if (~wasDisabled) then $
        oTool->EnableUpdates

    return, oCommand

end


;-------------------------------------------------------------------------
pro Axis::GetProperty, TITLE=title, $
    TICKFONT_NAME=tickfontName, $
    TICKFONT_STYLE=tickfontStyle, $
    TICKFONT_SIZE=tickfontSize, $
    _REF_EXTRA=_extra
    
    @graphic_error
    
    if ARG_PRESENT(title) then begin
        oAxis = self.__obj__
        oAxis->GetProperty, AXIS_TITLE=title
    endif
    
    self.Graphic::GetProperty, $
        FONT_NAME=tickfontName, $
        FONT_STYLE=tickfontStyle, $
        FONT_SIZE=tickfontSize, $
        _EXTRA=_extra

end



;-------------------------------------------------------------------------
pro Axis::SetProperty, TITLE=title, $
    TICKFONT_NAME=tickfontName, $
    TICKFONT_STYLE=tickfontStyle, $
    TICKFONT_SIZE=tickfontSize, $
    _EXTRA=_extra
    
    @graphic_error
    
    if (N_ELEMENTS(title) eq 1) then begin
        oAxis = self.__obj__
        oAxis->SetProperty, AXIS_TITLE=title
    endif
    
    self.Graphic::SetProperty, $
        FONT_NAME=tickfontName, $
        FONT_STYLE=tickfontStyle, $
        FONT_SIZE=tickfontSize, $
        _EXTRA=_extra

    if N_ELEMENTS(_extra) eq 0 then begin
        oTool = self.__obj__->GetTool()
        if (OBJ_VALID(oTool)) then begin
            oTool->RefreshCurrentWindow
        endif
    endif

end


;---------------------------------------------------------------------------
function Axis::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'GRIDSTYLE','HIDE','LOCATION','LOG', $
    'MAJOR', 'MINOR', 'NAME','SUBTICKLEN','TEXT_COLOR', $
    'TEXTPOS','THICK','TICKDIR', $
    'TICKFONT_NAME', 'TICKFONT_SIZE', 'TICKFONT_STYLE', $
    'TICKFORMAT', 'TICKINTERVAL', 'TICKLAYOUT', 'TICKLEN', $
    'TICKNAME', 'TICKUNITS', 'TICKVALUES', 'TITLE', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since Text is just an annotation.
  return, myprops
end


;-------------------------------------------------------------------------
pro Axis__define
  compile_opt idl2, hidden
  void = {Axis, inherits Graphic}
end

