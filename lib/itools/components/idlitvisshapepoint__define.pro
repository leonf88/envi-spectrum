; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisshapepoint__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisShapePoint
;
; PURPOSE:
;    The IDLitVisShapePoint class implements a a polyline visualization
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
; IDLitVisShapePoint::Init
;
; Purpose:
;   Initialization routine of the object.
;
; Parameters:
;   None.
;
; Keywords:
;   NAME   - The name to associated with this item.
;
;   Description - Short string that will describe this object.
;
;   All other keywords are passed to the super class
;
function IDLitVisShapePoint::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(NAME="Shape Point", $
        TYPE="IDLSHAPEPOINT", $
        /IMPACTS_RANGE, $
        ICON='drawing', $
        DESCRIPTION="Point shapes",$
        /ISOTROPIC, $
        SELECTION_PAD=2, $
        _EXTRA=_EXTRA))then $
        return, 0

    ; This will also register our Vertex parameter.
    dummy = self->_IDLitVisVertex::Init(POINTS_NEEDED=1)

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->RegisterParameter, 'ATTRIBUTES', $
        DESCRIPTION='Shapefile attributes', $
        TYPES='IDLSHAPEATTRIBUTES', $
        /INPUT, /OPTIONAL

    self->SetParameterAttribute, 'VERTICES', $
        TYPES=['IDLVERTEX', 'IDLSHAPEPOINT']

    self._oSymbol = OBJ_NEW('IDLitSymbol', PARENT=self, $
        SYM_INDEX=4, USE_DEFAULT_COLOR=0)

    ; Don't need to register any polyline properties.
    self._oLine = OBJ_NEW('IDLgrPolyline', $
        LINESTYLE=6, $
        /PRIVATE, $
        SYMBOL=self._oSymbol->GetSymbol())
    self->Add, self._oLine

    ; Register all properties.
    self->IDLitVisShapePoint::_RegisterProperties
    
    self->SetPropertyAttribute, ['SYMBOL', 'SYM_SIZE'], ADVANCED_ONLY=0

    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisShapePoint::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; IDLitVisShapePoint::_RegisterProperties
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
pro IDLitVisShapePoint::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        ; Aggregate the symbol properties.
        self->Aggregate, self._oSymbol

        ; Currently, IDLitSymbol doesn't expose a transparency property.
        ; So we handle it here. But register it on the IDLitSymbol
        ; so it shows up at the end of the list.
        self._oSymbol->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of points', $
            VALID_RANGE=[0,100,5]

        self._oSymbol->SetPropertyAttribute, 'USE_DEFAULT_COLOR', /HIDE

        ; This is registered to provide macro support.
        self->RegisterProperty, '_DATA', USERDEF='', /HIDE, /ADVANCED_ONLY

    endif

    ; Property added in IDL64.
    if (registerAll || (updateFromVersion lt 640)) then begin
        ; Register on our symbol so it shows up at the end.
        self._oSymbol->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for points', /ADVANCED_ONLY
    endif

end


;----------------------------------------------------------------------------
; IDLitVisShapePoint::Cleanup
;
; Purpose:
;   Cleanup/destrucutor method for this object.
;
; Parameters:
;   None.
;
; Keywords:
;    None.
pro IDLitVisShapePoint::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oSymbol

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisShapePoint::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisShapePoint::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oLine)) then $
        self._oLine->GetProperty
    if (OBJ_VALID(self._oSymbol)) then begin
        oSym = self._oSymbol->GetSymbol()
        if (OBJ_VALID(oSym)) then $
            oSym->GetProperty
    endif

    ; Register new properties.
    self->IDLitVisShapePoint::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end

;----------------------------------------------------------------------------
; IDLitVisShapePoint::GetProperty
;
; Purpose:
;   Used to retieve the property values for properties provided by
;   this object.
;
; Parameters:
;   None.
;
; Keywords:
;   ARROW_SIZE    -The siez of the arrow head
;
;   ARROW_STYLE   - The style of arrow head to use.
;
;   _DATA         - Used to get the data in the polyline.
;
pro IDLitVisShapePoint::GetProperty, $
    COLOR=color, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; The COLOR property is registered with Symbol,
    ; but is hidden. However, the tool still needs to be able to retrieve
    ; a value. We can't request it from the Symbol because it tries to
    ; request it from its parent (us!). So just return a bogus value.
    ; This shouldn't appear anywhere.
    if ARG_PRESENT(color) then $
        color = [0b, 0b, 0b]

    if ARG_PRESENT(transparency) then $
        self._oSymbol->GetProperty, SYM_TRANSPARENCY=transparency

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
; IDLitVisShapePoint::SetProperty
;
; Purpose:
;   Used to retieve the property values for properties provided by
;   this object.
;
; Parameters:
;   None.
;
; Keywords:
;   _DATA         - Used to set the data in the polyline.
;
pro IDLitVisShapePoint::SetProperty, $
    DATA=data, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(transparency)) then $
        self._oSymbol->SetProperty, SYM_TRANSPARENCY=transparency

    n = N_ELEMENTS(data)
    if (n gt 0) then begin
        if (n eq 1) then begin
            ; Hide our polyline if data is a scalar.
            ; Also reset the data so GetXYZRange doesn't
            ; return the old data range.
            self._oLine->SetProperty, /HIDE, DATA=FLTARR(2)
        endif else begin

            dims = SIZE(data, /DIMENSIONS)
            ; Set our visualization to 2D or 3D
            if dims[0] eq 2 then begin
                self->Set3D, 0, /ALWAYS
            endif else if dims[0] eq 3 then begin
                minn = MIN(data[2,*], MAX=maxx)
                self->Set3D, (minn ne maxx), /ALWAYS
            endif

            ; Be sure to unhide our polyline.
            self._oLine->SetProperty, HIDE=0, DATA=data

        endelse
    endif

    if (N_ELEMENTS(zvalue) ne 0) then begin
        self._zvalue = zvalue
        self->IDLgrModel::GetProperty, TRANSFORM=transform
        transform[2,3] = zvalue
        self->IDLgrModel::SetProperty, TRANSFORM=transform
        ; put the visualization into 3D mode if necessary
        self->Set3D, (zvalue ne 0), /ALWAYS
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

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; IDLitVisShapePoint::OnDataChangeUpdate
;
; Purpose:
;   This method is called by the framework when the data associated
;   with this object is modified or initially associated.
;
; Parameters:
;   oSubject   - The data object of the parameter that changed. if
;                parmName is "<PARAMETER SET>", this is an
;                IDLitParameterSet object
;
;   parmName   - The name of the parameter that changed.
;
; Keywords:
;   None.
;
pro IDLitVisShapePoint::OnDataChangeUpdate, oSubject, parmName
    compile_opt idl2, hidden

    case STRUPCASE(parmName) OF

    '<PARAMETER SET>': begin
        oSubject->IDLitComponent::GetProperty, $
            NAME=name, DESCRIPTION=description
        self->IDLitVisShapePoint::SetProperty, NAME=name, $
            DESCRIPTION=description
        oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
        for i=0,nParam-1 do begin
            if (~paramNames[i]) then $
                continue
            oData = oSubject->GetByName(paramNames[i])
            if ~OBJ_VALID(oData) then $
                continue
            self->IDLitVisShapePoint::OnDataChangeUpdate, $
                oData, paramNames[i]
        endfor
        end

    'VERTICES': self->OnProjectionChange

    else: ; ignore unknown parameters

    endcase

end


;----------------------------------------------------------------------------
pro IDLitVisShapePoint::OnProjectionChange, sMap

    compile_opt idl2, hidden

    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    oVert = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oVert) || $
        ~oVert->GetData(vertex)) then $
        return

    hasMap = N_TAGS(sMap) gt 0

    ; If we have data values out of the normal lonlat range, then
    ; assume these are not coordinates in degrees.
    if (SIZE(vertex, /N_DIM) eq 2) then begin
        minn = MIN(vertex, DIMENSION=2, MAX=maxx)
    endif else begin
        minn = vertex
        maxx = vertex
    endelse

    if (minn[0] lt -360 || maxx[0] gt 720 || $
        minn[1] lt -90 || maxx[1] gt 90) then hasMap = 0

    if (hasMap) then begin

        data = MAP_PROJ_FORWARD(vertex, MAP=sMap)
        good = WHERE(MIN(FINITE(data), DIMENSION=1), ngood)
        if (ngood lt N_ELEMENTS(data)/2) then begin
            data = (ngood gt 0) ? data[*, good] : 0
        endif

        self->IDLitVisShapePoint::SetProperty, DATA=data

    endif else begin

        self->IDLitVisShapePoint::SetProperty, DATA=vertex

    endelse

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisImage::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisImage::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
;-
pro IDLitVisShapePoint::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; Force our symbol to recompute its size.
    self._oSymbol->GetProperty, SYM_SIZE=symSize
    self._oSymbol->SetProperty, SYM_SIZE=symSize

    ; Call superclass.
    self->_IDLitVisualization::OnDataRangeChange, oSubject, $
        XRange, YRange, ZRange
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisShapePoint__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisShapePoint object.
;
;-
pro IDLitVisShapePoint__Define

    compile_opt idl2, hidden

    struct = { IDLitVisShapePoint,           $
        inherits IDLitVisualization,       $
        inherits _IDLitVisVertex, $
        _oLine: OBJ_NEW(), $
        _oSymbol: OBJ_NEW(), $
        _zvalue: 0d $
    }
end
