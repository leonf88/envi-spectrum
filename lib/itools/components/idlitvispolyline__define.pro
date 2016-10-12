; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvispolyline__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisPolyline
;
; PURPOSE:
;    The IDLitVisPolyline class implements a a polyline visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-


;----------------------------------------------------------------------------
; IDLitVisPolyline::_RegisterProperties
;
; Purpose:
;   Internal routine that will register all properties supported by
;   this object.
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisPolyline::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Aggregate the IDLgrPolyline properties.
        self->Aggregate, self._oLine

        self._oLine->SetPropertyAttribute, 'COLOR', $
            NAME='Color', DESCRIPTION='Line Color'

        ; Hide some text properties.
        self->SetPropertyAttribute,['SHADING'], /HIDE

        ; Add properties for arrowheads. This could eventually be put into
        ; its own class if it will be used for other IDLitVis's.
        self._oLine->RegisterProperty, 'ARROW_STYLE', $
            DESCRIPTION='Arrow style', $
            ENUMLIST=[' --------', ' ------->', ' <-------', ' <------>', $
                ' >------>', ' <------<'], $
            NAME='Arrow style'

        self._oLine->RegisterProperty, 'ARROW_SIZE', /FLOAT, $
            DESCRIPTION='Arrowhead size', $
            NAME='Arrowhead size', $
            VALID_RANGE=[0,1,0.01d]
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of line', $
            VALID_RANGE=[0,100,5]

        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

        ; This is registered to provide macro support for polylines
        self->RegisterProperty, '_DATA', USERDEF='', /HIDE, /ADVANCED_ONLY
    endif

    ; Property added in IDL64.
    if (registerAll || (updateFromVersion lt 640)) then begin
        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for polygon', /ADVANCED_ONLY
    endif

end

;;----------------------------------------------------------------------------
;; IDLitVisPolyline::Init
;;
;; Purpose:
;;   Initialization routine of the object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   _NO_VERTEX_VISUAL: Internal keyword to prevent the VisVertex
;;      manipulator visual from being created.
;;
;;   All other keywords are passed to th super class
;;
function IDLitVisPolyline::Init, $
    _NO_VERTEX_VISUAL=noVertexVisual, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(NAME="Line", $
                                           TYPE="IDLPOLYLINE", $
                                           IMPACTS_RANGE=0, $
                                           ICON='line', $
                                           /MANIPULATOR_TARGET, $
                                           DESCRIPTION="Line annotation",$
                                           _EXTRA=_EXTRA))then $
        return, 0

    ; This will also register our X parameter.
    dummy = self->_IDLitVisVertex::Init(POINTS_NEEDED=2)

    ; Add in our special manipulator visual.
    if (~KEYWORD_SET(noVertexVisual)) then begin
        self->SetDefaultSelectionVisual, OBJ_NEW('IDLitManipVisVertex', $
            /HIDE, PREFIX='LINE')
    endif


    ; Set the default arrowhead size. Note that we don't actually create the
    ; arrowhead symbols until they are needed.
    self._arrowSize = 0.05d
    self._arrowDataMult = 1.0d

    ; NOTE: the IDLgrPolyline properties will be aggregated as part of
    ; the property registration process in an upcoming call to
    ; ::_RegisterProperties.
    self._oLine = obj_new("IDLgrPolyline", /REGISTER_PROPERTIES, $
                          /ANTIALIAS, /SHADING, /PRIVATE)
    self->Add, self._oLine, /NO_UPDATE, /NO_NOTIFY

    ; Register all properties.
    self->IDLitVisPolyline::_RegisterProperties

    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisPolyline::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;;----------------------------------------------------------------------------
;; IDLitVisPolyline::Cleanup
;;
;; Purpose:
;;   Cleanup/destrucutor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
pro IDLitVisPolyline::Cleanup
    compile_opt idl2, hidden

    OBJ_DESTROY, self._oLine
    OBJ_DESTROY, self._oArrows
    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
    ;; VisVertext doens't have a cleanup method.
end

;----------------------------------------------------------------------------
; IDLitVisPolyline::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisPolyline::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oLine)) then $
        self._oLine->GetProperty

    ; Register new properties.
    self->IDLitVisPolyline::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then $
        self._arrowDataMult = 1.0d

end

;----------------------------------------------------------------------------
; Purpose:
;   This method is used to store information needed to prepare for pasting to a
;   different layer or dataspace.
;
function IDLitVisPolyline::DoPreCopy, oParmSet, _EXTRA=_extra
  compile_opt idl2, hidden
  
  catch, err
  if (err ne 0) then begin
    catch, /CANCEL
    message, /RESET
    return, 0
  endif
  
  self->GetProperty, _DATA=data, _PARENT=oParent, TRANSFORM=tr, _EXTRA=_extra
  ;; Ensure data is in proper format
  if (OBJ_ISA(oParent, 'IDLitgrAnnotateLayer')) then begin
    device = iConvertCoord(data, ANNOTATION_DATA=tr, /TO_DEVICE)
  endif else begin
    dataConv = iConvertCoord(data, TRANSFORMED_DATA=tr, /TO_DATA)
    device = iConvertCoord(dataConv, /DATA, /TO_DEVICE, $
                           TARGET_IDENTIFIER=self->GetFullIdentifier())
  endelse

  ;; Create a data object to hold data
  oDevice = OBJ_NEW('IDLitData', device, NAME='device')
  if (N_ELEMENTS(dataConv) ne 0) then $
    oData = OBJ_NEW('IDLitData', dataConv, NAME='data')
  
  ;; Create the return parameter set
  oParmSet = OBJ_NEW('IDLitParameterSet')
  oParmSet->Add, oDevice, PARAMETER_NAME='device'
  if (OBJ_VALID(oData)) then $
    oParmSet->Add, oData, PARAMETER_NAME='data'
   
  return, 1
  
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to update the newly created pasted object.
;
function IDLitVisPolyline::DoPostPaste, oParmSet, _EXTRA=_extra
  compile_opt idl2, hidden
  
  catch, err
  if (err ne 0) then begin
    catch, /CANCEL
    message, /RESET
    return, 0
  endif

  self->GetProperty, _PARENT=oParent

  if (OBJ_ISA(oParent, 'IDLitgrAnnotateLayer')) then begin
    oDevice = oParmSet->GetByName('device', count=cnt)
    if (cnt ne 0) then begin
      ;; Device coordinates needed to go into the annotation layer 
      if (oDevice->GetData(device)) then begin
        ;; Convert data
        data = iConvertCoord(device, /DEVICE, /TO_ANNOTATION_DATA)
        ;; Set Z values
        data[2,*] = 0.99 
        self->SetProperty, _DATA=data, TRANSFORM=Identity(4)
      endif
    endif
  endif else begin
    ;; Going into the dataspace, first check for data coordinates
    oData = oParmSet->GetByName('data', count=cnt)
    if (cnt ne 0) then begin
      if (oData->GetData(data)) then begin
        ;; Zero out Z values
        if (~oParent->Is3D()) then $
          data[2,*] = 0.0                     
        self->SetProperty, _DATA=data, TRANSFORM=Identity(4)
      endif
    endif else begin
      ;; Currently not allowed to go into a 3D dataspace from the 
      ;; annotation layer
      if (oParent->Is3D()) then $
        return, 0
      ;; Use device coordinates if data coordinates do not exist
      oDevice = oParmSet->GetByName('device', count=cnt)
      if (cnt ne 0) then begin
        if (oDevice->GetData(device)) then begin
          ;; Convert coordinates
          data = iConvertCoord(device, /DEVICE, /TO_DATA, $
                               TARGET_IDENTIFIER=self->GetFullIdentifier())
          ;; Zero out Z values
          data[2,*] = 0.0                     
          self->SetProperty, _DATA=data, TRANSFORM=Identity(4)
        endif
      endif
    endelse
  endelse
  
  return, 1

end


;;----------------------------------------------------------------------------
;; IDLitVisPolyline::GetProperty
;;
;; Purpose:
;;   Used to retieve the property values for properties provided by
;;   this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   ARROW_SIZE    -The siez of the arrow head
;;
;;   ARROW_STYLE   - The style of arrow head to use.
;;
;;   _DATA         - Used to get the data in the polyline.
;;
pro IDLitVisPolyline::GetProperty, $
    ARROW_SIZE=arrowSize, $
    ARROW_STYLE=arrowStyle, $
    MAP_INTERPOLATE=mapInterpolate, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve arrowhead properties.
    if (ARG_PRESENT(arrowSize)) then $
        arrowSize = self._arrowSize

    if (ARG_PRESENT(arrowStyle)) then $
        arrowStyle = self._arrowStyle

    if (ARG_PRESENT(mapInterpolate)) then $
        mapInterpolate = self._mapInterpolate

    if ARG_PRESENT(transparency) then begin
        self._oLine->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if (ARG_PRESENT(zvalue)) then $
        zvalue = self._zvalue

    if (ARG_PRESENT(_data)) then begin
        ; Retrieve data values. This is for use by the undo/redo command.
        oDataObj = self->GetParameter('VERTICES')
        if (OBJ_VALID(oDataObj)) then $
            success = oDataObj->GetData(_data)
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
;; IDLitVisPolyline::SetProperty
;;
;; Purpose:
;;   Used to retieve the property values for properties provided by
;;   this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   ARROW_SIZE    -The siez of the arrow head
;;
;;   ARROW_STYLE   - The style of arrow head to use.
;;
;;   _DATA         - Used to set the data in the polyline.
;;
;;   THICk         - Thickness of the polyline.
;;
pro IDLitVisPolyline::SetProperty, $
    ARROW_SIZE=arrowSize, $
    ARROW_STYLE=arrowStyle, $
    COLOR=lineColor, $
    CONNECTIVITY=connectivity, $
    _DATA=_data, $
    DATA=data, $
    LINESTYLE=lineStyle, $
    MAP_INTERPOLATE=mapInterpolate, $
    POLYLINES=polylines, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    __DATA=__data, $
    __POLYLINES=__polylines, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Arrowhead size
    if (N_ELEMENTS(arrowSize)) then begin
      self._arrowSize = arrowSize
      ; If necessary, multiply by dataspace multiplier.
      symSize = (self._arrowDataMult ne 1.0) ? $
          arrowSize * self._arrowDataMult : arrowSize
      if (Obj_Valid(self._oArrows[0])) then begin
        self._oArrows[0]->SetProperty, SIZE=symSize
        self._oArrows[1]->SetProperty, SIZE=symSize
      endif
    endif

    ; Thickness
    if (N_ELEMENTS(thick) gt 0) then begin
      self->IDLitVisualization::SetProperty, THICK=thick
      if (Obj_Valid(self._oArrows[0])) then begin
        self._oArrows[0]->SetProperty, THICK=thick
        self._oArrows[1]->SetProperty, THICK=thick
      endif
    endif

    ; Change the arrowhead style.
    if (N_ELEMENTS(arrowStyle)) then begin

        ; If necessary, create our arrowhead symbols.
        if (~Obj_Valid(self._oArrows[0]) && arrowStyle ge 1) then begin
            self._oLine->GetProperty, THICK=linethick

            ; If necessary, multiply by dataspace multiplier.
            symSize = (self._arrowDataMult ne 1.0) ? $
                self._arrowSize * self._arrowDataMult : self._arrowSize

            self._oArrows[0] = OBJ_NEW('IDLgrSymbol', 8, $
                SIZE=symSize, THICK=linethick)
            self._oArrows[1] = OBJ_NEW('IDLgrSymbol', 9, $
                SIZE=symSize, THICK=linethick)
        endif

        case arrowStyle of
            0: begin   ;   No arrow
                labelOffsets = [0]
                labelObjects = -1   ; no labels
               end
            1: begin   ;   ------>
                labelOffsets = [1]
                labelObjects = 0
               end
            2: begin   ;   <------
                labelOffsets = [0]
                labelObjects = 1
               end
            3: begin   ;   <------>
                labelOffsets = [0, 1]
                labelObjects = [1, 0]
               end
            4: begin   ;   >------>
                labelOffsets = [0, 1]
                labelObjects = [0, 0]
               end
            5: begin   ;   <------<
                labelOffsets = [0, 1]
                labelObjects = [1, 1]
               end
            else: return
        endcase

        ; Cache our style index.
        self._arrowStyle = arrowStyle

        ; By default, turn arrows off (also forces internal cache rebuild).
        self._oLine->SetProperty, $
            LABEL_OBJECTS=OBJ_NEW()

        ; Add (or remove) arrowhead labels.
        if (labelObjects[0] ge 0) then begin
            self._oLine->SetProperty, $
                /LABEL_NOGAPS, $
                LABEL_OFFSETS=labelOffsets, $
                LABEL_OBJECTS=self._oArrows[labelObjects]
        endif

    endif


    if (N_ELEMENTS(mapInterpolate)) then begin
        self._mapInterpolate = KEYWORD_SET(mapInterpolate)
        self->OnProjectionChange
    endif


    if (N_ELEMENTS(transparency)) then begin
        self._oLine->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-transparency)/100) < 1
    endif


    if (N_ELEMENTS(data) gt 1) then $
      _data = data

    if (N_ELEMENTS(polylines) gt 1) then $
      connectivity = polylines


    if (N_ELEMENTS(lineColor) gt 0) then begin
      if (isa(lineColor, 'STRING') || N_ELEMENTS(lineColor) eq 1) then $
        style_convert, lineColor, COLOR=lineColor
      self._oLine->SetProperty, COLOR=lineColor
    endif

    if (N_ELEMENTS(lineStyle)) then begin
      self._oLine->SetProperty, LINESTYLE=linestyle_convert(lineStyle)
    endif


    if (N_ELEMENTS(zvalue) ne 0) then begin
        self._zvalue = zvalue
        self->IDLgrModel::GetProperty, TRANSFORM=transform
        transform[2,3] = zvalue
        self->IDLgrModel::SetProperty, TRANSFORM=transform
        ; put the visualization into 3D mode if necessary
        self->Set3D, (zvalue ne 0), /ALWAYS
    endif


    if (N_ELEMENTS(connectivity) gt 0) then begin
        oDataObj = self->GetParameter('CONNECTIVITY')
        if (~OBJ_VALID(oDataObj)) then begin
            oDataObj = OBJ_NEW("IDLitData", connectivity, $
                NAME='Connectivity', $
                TYPE='IDLCONNECTIVITY', ICON='segpoly', /PRIVATE)
            ; If DATA was also passed in, let it do the notification below.
            void = self->IDLitParameter::SetData(oDataObj, $
                PARAMETER_NAME= 'CONNECTIVITY', /BY_VALUE, $
                NO_UPDATE=ISA(_data))
        endif else begin
            ; If DATA was also passed in, let it do the notification below.
            void = oDataObj->SetData(connectivity, NO_NOTIFY=ISA(_data))
        endelse
    endif

    if (N_ELEMENTS(_data) gt 0) then begin
        ; Set data values. This is for use by the undo/redo command and macros.
        oDataObj = self->GetParameter('VERTICES')
        if (~OBJ_VALID(oDataObj)) then begin
            oDataObj = OBJ_NEW("IDLitData", _data, /NO_COPY, $
                NAME='Vertices', $
                TYPE='IDLVERTEX', ICON='segpoly', /PRIVATE)
            void = self->SetData(oDataObj, $
                PARAMETER_NAME= 'VERTICES', /BY_VALUE)
        endif else begin
            void = oDataObj->SetData(_data, /NO_COPY)
        endelse
    endif

    ; Need a way to manually set the data.
    if (N_ELEMENTS(__data) gt 0) then begin
        self._oLine->SetProperty, DATA=__data, HIDE=N_ELEMENTS(__data) le 1, $
          POLYLINES=(N_ELEMENTS(__polylines) gt 0) ? __polylines : 0
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data
;
; Arguments:
;   DATA
;
; Keywords:
;   NONE
;
pro IDLitVisPolyline::GetData, data, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  
  self->GetProperty, _DATA=data, _PARENT=oParent, TRANSFORM=tr, _EXTRA=_extra
  ;; Ensure data is in proper format
  if (OBJ_ISA(oParent, 'IDLitgrAnnotateLayer')) then begin
    data = iConvertCoord(data, ANNOTATION_DATA=tr, /TO_DEVICE)
  endif else begin
    if (~ARRAY_EQUAL(tr, Identity(4))) then $
      data = iConvertCoord(data, TRANSFORMED_DATA=tr, /TO_DATA)
  endelse
    
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   DATA
;
; Keywords:
;   NONE
;
pro IDLitVisPolyline::PutData, DATA, _EXTRA=_extra
  compile_opt idl2, hidden
  
  ;; SetProperty does a /NO_COPY, thus destroying the original data
  tmp = data
  ;; Ensure data is in proper format
  self->GetProperty, _PARENT=oParent
  if (OBJ_ISA(oParent, 'IDLitgrAnnotateLayer')) then begin
    data = iConvertCoord(data, /DEVICE, /TO_ANNOTATION_DATA)
  endif else begin
    ;; Reset the transform so that incoming data is properly reflected
    self->SetProperty, TRANSFORM=Identity(4)
  endelse
  self->SetProperty, _DATA=data
  data = tmp
  
end


;;----------------------------------------------------------------------------
;; IDLitVisPolyline::OnDataChangeUpdate
;;
;; Purpose:
;;   This method is called by the framework when the data associated
;;   with this object is modified or initially associated.
;;
;; Parameters:
;;   oSubject   - The data object of the parameter that changed. if
;;                parmName is "<PARAMETER SET>", this is an
;;                IDLitParameterSet object
;;
;;   parmName   - The name of the parameter that changed.
;;
;; Keywords:
;;   None.
;;
pro IDLitVisPolyline::OnDataChangeUpdate, oSubject, parmName
    compile_opt idl2, hidden

    case STRUPCASE(parmName) OF

    '<PARAMETER SET>': begin
        oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
        for i=0,nParam-1 do begin
            if (~paramNames[i]) then $
                continue
            oData = oSubject->GetByName(paramNames[i])
            if ~OBJ_VALID(oData) then $
                continue
            ; Just directly update the data.
            self->OnProjectionChange
        endfor
        end

    'VERTICES': self->OnProjectionChange

    'CONNECTIVITY': self->OnProjectionChange

    else: ; ignore unknown parameters

    endcase

end


;----------------------------------------------------------------------------
; If desired, interpolate additional points so the
; line follows the map curvature.
;
pro IDLitVisPolyline::_MapInterpolate, vertex, connectivity

    compile_opt idl2, hidden

    nVert = N_ELEMENTS(vertex)/2

    ; Create connectivity if it is missing, so we have just
    ; one code path below.
    if (N_ELEMENTS(connectivity) eq 0) then $
        connectivity = [nVert, LINDGEN(nVert)]

    nConn = N_ELEMENTS(connectivity)
    idx = 0L
    newidx = 0L

    ; Look thru connectivity.
    while (idx lt nConn) do begin

        nVert1 = connectivity[idx]
        if (nVert1 eq -1) then break
        if (nVert1 eq 0) then begin
            idx++
            continue
        endif

        ; Pull out each polyline and find the longest edge length.
        vert1 = vertex[*, connectivity[idx+1:idx+nVert1]]
        maxEdgeLength = MAX(ABS(vert1[*, 1:*] - vert1[*, 0:nVert1-2]))

        ; Try to space points so there is at least 1 per degree lonlat.
        newNvert = (1 > LONG(maxEdgeLength) < 180)*nVert1

        if (newNvert ne nVert1) then begin
            ; Create my new vertices and add to the new connnectivity list.
            newVert1 = CONGRID(vert1, 2, newNvert, /INTERP, /MINUS)
            if (N_ELEMENTS(newvertex) eq 0) then begin
                newvertex = newVert1
                newconn = [newNvert, LINDGEN(newNvert) + newidx]
            endif else begin
                newvertex = [newvertex, newVert1]
                newconn = [newconn, newNvert, LINDGEN(newNvert) + newidx]
            endelse
            newidx += newNvert + 1
        endif

        idx += nVert1 + 1

    endwhile

    if (newidx gt 0) then begin
        vertex = TEMPORARY(newvertex)
        connectivity = TEMPORARY(newconn)
    endif

end


;----------------------------------------------------------------------------
pro IDLitVisPolyline::OnProjectionChange, sMap

    compile_opt idl2, hidden

    oVert = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oVert) || $
        ~oVert->GetData(data)) then $
        return
    oConn = self->GetParameter('CONNECTIVITY')
    if (OBJ_VALID(oConn)) then $
        void = oConn->GetData(polylines)

    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    ; If we have data values out of the normal lonlat range, then
    ; assume these are not coordinates in degrees.
    if (N_TAGS(sMap) gt 0) then begin
        minn = MIN(data, DIMENSION=2, MAX=maxx)
        if (minn[0] lt -360 || maxx[0] gt 720 || $
            minn[1] lt -90 || maxx[1] gt 90) then sMap = 0
    endif

    if (N_TAGS(sMap) gt 0) then begin

        hasZ = (SIZE(data, /DIM))[0] eq 3
        if (hasZ) then begin
            zdata = data[2,*]
            data = data[0:1, *]
        endif

        ; If desired, interpolate additional points so the
        ; line follows the map curvature.
        if (self._mapInterpolate || (N_TAGS(sMap) gt 0)) then $
            self->_MapInterpolate, data, polylines

        data = MAP_PROJ_FORWARD(data, $
            MAP=sMap, $
            CONNECTIVITY=polylines, $
            POLYLINES=polylines)

        if (N_ELEMENTS(data) le 1) then $
            return

        if (hasZ && N_ELEMENTS(zdata) eq N_ELEMENTS(data/2)) then $
            data = [data, zdata]

    endif


    dims = SIZE(data, /DIMENSIONS)

    ; Must have two dimensional vertex data.
    if (N_ELEMENTS(dims) eq 2) then begin

        ; Set our visualization to 2D or 3D
        if dims[0] eq 2 then begin
            self->Set3D, 0, /ALWAYS
        endif else if dims[0] eq 3 then begin
            minn = MIN(data[2,*], MAX=maxx)
            ; Be sure to use an epsilon to avoid switching to 3D due
            ; to roundoff errors.
            self->Set3D, (maxx-minn) gt 1d-11, /ALWAYS
        endif

        ; Convert to logarithmic axes, if necessary.
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
          oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
          if (KEYWORD_SET(xLog)) then data[0,*] = ALOG10(data[0,*])
          if (KEYWORD_SET(yLog)) then data[1,*] = ALOG10(data[1,*])
          if (KEYWORD_SET(zLog)) then data[2,*] = ALOG10(data[2,*])
        endif

        ; If the data is being set, then the connectivity list
        ; needs to be either provided or to be reset, otherwise
        ; we might get an invalid connectivity list error.
        self._oLine->SetProperty, HIDE=0, DATA=data, $
            POLYLINES=(N_ELEMENTS(polylines) gt 0) ? polylines : 0

    endif else begin

        ; Hide our polyline & polygon if data is a scalar.
        if (N_ELEMENTS(data) gt 0) then begin
            ; Also reset the data & connectivity so GetXYZRange doesn't
            ; return the old data range.
            self._oLine->SetProperty, /HIDE, DATA=FLTARR(2), POLYLINES=0
        endif else begin
            ; Pass along the connectivity lists.
            ; If data was provided, it has already been passed along.
            if (N_ELEMENTS(polylines) gt 0) then $
                self._oLine->SetProperty, HIDE=0, POLYLINES=polylines
        endelse

    endelse

end

;----------------------------------------------------------------------------
; IDLitVisPolyline::OnDataRangeChange
;
; Purpose:
;   This procedure method handles notificaton that the data range
;   has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     data range change.
;   XRange:  The new xrange, [xmin, xmax]
;   YRange:  The new yrange, [ymin, ymax]
;   ZRange:  The new zrange, [zmin, zmax]
;
pro IDLitVisPolyline::OnDataRangeChange, oSubject, XRange, YRange, ZRange
    compile_opt idl2, hidden

    ; Update the multiplier for the arrow size.
    self._arrowDataMult = (XRange[1] - XRange[0]) > $
        (YRange[1] - YRange[0])

    ; If arrows have been created, reset their sizes.
    if (OBJ_VALID(self._oArrows[0])) then begin
        ; If necessary, multiply by dataspace multiplier.
        symSize = (self._arrowDataMult ne 1.0) ? $
            self._arrowSize * self._arrowDataMult : self._arrowSize
        self._oArrows[0]->SetProperty, SIZE=symSize
        self._oArrows[1]->SetProperty, SIZE=symSize
    endif
end


;----------------------------------------------------------------------------
; PURPOSE:
;   This function method retrieves the LonLat range of
;   contained visualizations. Override the _Visualization method
;   so we can retrieve the correct range.
;
function IDLitVisPolyline::GetLonLatRange, lonRange, latRange, $
    MAP_STRUCTURE=sMap

    compile_opt idl2, hidden

    oVert = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oVert) || ~oVert->GetData(pData, /POINTER)) then $
        return, 0
    if (N_ELEMENTS(*pData) le 1 || SIZE(*pData, /N_DIMENSIONS) ne 2) then $
        return, 0

    ; Just assume that if we have vertex data, and it is within lon/lat
    ; limits, that it is indeed longitude/latitude data. This method should
    ; only be called from classes such as the MapGrid anyway.
    minn = MIN(*pData, DIMENSION=2, MAX=maxx)
    if (minn[0] lt -360 || maxx[0] gt 720 || $
        minn[1] lt -90 || maxx[1] gt 90) then $
        return, 0

    lonRange = [minn[0], maxx[0]]
    latRange = [minn[1], maxx[1]]

    return, 1

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisPolyline__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisPolyline object.
;
;-
pro IDLitVisPolyline__Define

    compile_opt idl2, hidden

    struct = { IDLitVisPolyline,           $
        inherits IDLitVisualization,       $
        inherits _IDLitVisVertex, $
        _oLine    : OBJ_NEW(), $
        _arrowStyle : 0,    $
        _arrowSize: 0d, $
        _arrowDataMult: 0d, $  ; Multiplier to map normalized arrow
                           $  ;   size to dataspace range.
        _oArrows: OBJARR(2), $
        _mapInterpolate: 0b, $
        _zvalue: 0d $
    }
end
