; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisintvol__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisIntVol
;
; PURPOSE:
;    The IDLitVisIntVol class implements an Interval Volume visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisIsoSurface
;
;-

;----------------------------------------------------------------------------
; IDLitVisIntVol::Init
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
function IDLitVisIntVol::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisIsoSurface::Init(NAME="Interval Volume", $
        TYPE='IDLINTERVAL VOLUME', $
        ICON='volume', $
        DESCRIPTION="An Interval Volume", $
        COLOR=[0b,0b,0b], $
        _EXTRA=_extra)) then return, 0

    ; Register my additional interval volume parameters
    self->RegisterParameter, 'POLYGONS', $
        DESCRIPTION='Interval Volume Surface Connectivity List', $
        TYPES='IDLVECTOR'
    self->RegisterParameter, 'TETRAHEDRA', $
        DESCRIPTION='Interval Volume Tetrahedra List', $
        TYPES='IDLVECTOR'
    self->RegisterParameter, 'VERTEX_COLORS', $
        DESCRIPTION='Interval Volume Surface Vertex Color Indices', $
        TYPES='IDLVECTOR'

    ; Just tweak the property names.
    self->SetPropertyAttribute, 'ISOVALUE', USERDEF='Select isovalues...', $
      ADVANCED_ONLY=0
    self->SetPropertyAttribute, '_ISOVALUE0', $
        NAME='Isovalue 0', DESCRIPTION='Isovalue 0'

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; IDLitVisIntVol::Cleanup
;
; Purpose:
;   Cleanup/destrucutor method for this object.
;
; Parameters:
;   None.
;
; Keywords:
;    None.
pro IDLitVisIntVol::Cleanup

    compile_opt idl2, hidden

    obj_destroy,self->GetParameter('VERTICES')
    obj_destroy,self->GetParameter('CONNECTIVITY')
    obj_destroy,self->GetParameter('TETRAHEDRA')
    obj_destroy,self->GetParameter('VERTEX_COLORS')

    ; Cleanup superclass
    self->IDLitVisIsoSurface::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisIntVol::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisIntVol::Restore

    compile_opt idl2, hidden

    ; Restore superclass.
    self->IDLitVisIsoSurface::Restore

    if (self.idlitcomponentversion lt 640) then begin
        ; ISOVALUES became ISOVALUE when we made Intvolume be
        ; a subclass of Isosurface.
        self->SetPropertyAttribute, 'ISOVALUES', /HIDE
        ; Just tweak the property names.
        self->SetPropertyAttribute, '_ISOVALUE0', $
            NAME='Isovalue 0', DESCRIPTION='Isovalue 0'
        self->SetPropertyAttribute, '_ISOVALUE1', HIDE=0, /SENSITIVE, $
            VALID_RANGE=[self._volMin, self._volMax]
    endif

end

;----------------------------------------------------------------------------
; IDLitVisIntVol::_SetColor
;
; Purpose:
;   Set the Interval Volume colors - either a per-vertex color or a solid.
;
; Parameters:
;   None.
;
; Keywords:
;    None.

pro IDLitVisIntVol::_SetColor

    compile_opt idl2, hidden

    case self._sourceColor of
    0: begin
        ; The vertex colors are saved as indices into a volume palette.
        oPal = self->GetParameter('RGB_TABLE')
        oVertColors = self->GetParameter('VERTEX_COLORS')
        success1 = 0
        success2 = 0
        if OBJ_VALID(oPal) then begin
            success1 = oPal->GetData(palette)
            if N_ELEMENTS(palette) ne 256*3 then $
                success1 = 0
        endif
        if OBJ_VALID(oVertColors) then begin
            success2 = oVertColors->GetData(vertexColors)
            if N_ELEMENTS(vertexColors) eq 0 then $
                success2 = 0
        endif

        ; We have vertex colors and a palette.
        ; Create RGB color vector from palette lookup.
        if success1 gt 0 and success2 gt 0 then begin
            self->IDLitVisIsoSurface::SetProperty, $
                VERT_COLORS=palette[*, BYTE(vertexColors)]

        ; We have just vertex colors - use gray palette for lookup
        endif else if success1 eq 0 and success2 gt 0 then begin
            vc = BYTE(TEMPORARY(vertexColors))
            self->IDLitVisIsoSurface::SetProperty, $
                VERT_COLORS=TRANSPOSE([[vc],[vc],[vc]])

        ; No vertex colors.
        endif else begin
            self->IDLitVisIsoSurface::SetProperty, VERT_COLORS=0
        endelse
    end
    1: self->IDLitVisIsoSurface::SetProperty, VERT_COLORS=0
    endcase
end

;----------------------------------------------------------------------------
; IDLitVisIntVol::_GenerateIntervalVolume
;
; Purpose:
;   Generate the interval volume vertex and connectivity data.
;
; Parameters:
;   None.
;
; Keywords:
;    None.

pro IDLitVisIntVol::_GenerateVisualization

    compile_opt idl2, hidden

    ; Make sure that our isovalue properties have been set.
    self->GetPropertyAttribute, '_ISOVALUE0', UNDEFINED=undef0
    self->GetPropertyAttribute, '_ISOVALUE1', UNDEFINED=undef1

    isValid = ~undef0 && ~undef1 && $
        (self._volMin ne self._volMax) && $
        (self._isovalues[0] lt self._isovalues[1])

    self->SetPropertyAttribute, 'ISOVALUE', HIDE=0
    self->SetPropertyAttribute, '_ISOVALUE0', HIDE=0, $
        SENSITIVE=isValid, $
        VALID_RANGE=isValid ? [self._volMin, self._volMax] : [0,255]
    self->SetPropertyAttribute, '_ISOVALUE1', HIDE=0, $
        SENSITIVE=isValid, $
        VALID_RANGE=isValid ? [self._volMin, self._volMax] : [0,255]
    self->SetPropertyAttribute, 'DECIMATE', HIDE=0, $
        SENSITIVE=isValid

    if (~isValid) then return

    ; Get volume data to make interval volume with
    oVol = self->GetParameter('VOLUME')
    if not OBJ_VALID(oVol) then return
    success = oVol->GetData(pVol, /POINTER)
    if success eq 0 then return

    ; This may take awhile...
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return

    INTERVAL_VOLUME, *pVol, self._isovalues[0], self._isovalues[1], $
        verts, tets, AUXDATA_IN=BYTSCL(*pVol), AUXDATA_OUT=vertexColors, $
        PROGRESS_OBJECT=self, PROGRESS_METHOD="_ProgressCallback", $
        PROGRESS_USERDATA=oTool
    ; Cancelled.
    if (N_ELEMENTS(verts) le 3) then $
        return
    void = oTool->DoUIService("HourGlassCursor", self)
    conn = TETRA_SURFACE(verts, tets)
    if self._decimate ne 100 then begin
        r = MESH_DECIMATE(verts, conn, conn, PERCENT_POLYGONS=self._decimate, $
            PROGRESS_OBJECT=self, $
            PROGRESS_METHOD='_DecimateCallback', $
            PROGRESS_USERDATA=oTool)
        void = oTool->DoUIService("HourGlassCursor", self)
    endif

    ; Get the parms so we can update the vertex and connectivity data
    ; Create the parms if they are not there
    oVerts = self->GetParameter('VERTICES')
    if not OBJ_VALID(oVerts) then begin
        oVerts = OBJ_NEW('IDLitData', TYPE='IDLVERTEX', $
            ICON='segpoly', NAME='Interval Volume Vertices')
        void = self->SetData(oVerts, PARAMETER_NAME='VERTICES', /NO_UPDATE, /BY_VALUE)
    endif
    oConn = self->GetParameter('CONNECTIVITY')
    if not OBJ_VALID(oConn) then begin
        oConn = OBJ_NEW('IDLitData', TYPE='IDLCONNECTIVITY', $
            ICON='segpoly', NAME='Interval Volume Polygon Connectivity')
        void = self->SetData(oConn, PARAMETER_NAME='CONNECTIVITY', /NO_UPDATE, /BY_VALUE)
    endif

    ; Empty out polygon in case there is no interval volume
    ; (Need to do it in this order!)
    success = oConn->SetData([-1])
    success = oVerts->SetData(FLTARR(3,3))

    ; Make sure that we have enough verts to keep the polygon happy
    if N_ELEMENTS(verts) lt 9 then begin
        verts = FLTARR(3,3)
    endif

    ; Prepare vertex data
    ; - scale by dimensions
    oDimensions = self->GetParameter('VOLUME_DIMENSIONS')
    if OBJ_VALID(oDimensions) then begin
        success = oDimensions->GetData(dimensions)
        dimensions = FLOAT(dimensions)
        volDims = SIZE(*pVol, /DIMENSIONS)
        verts[0,*] *= dimensions[0] / volDims[0]
        verts[1,*] *= dimensions[1] / volDims[1]
        verts[2,*] *= dimensions[2] / volDims[2]
    endif

    ; - translate by volume location
    oLocation = self->GetParameter('VOLUME_LOCATION')
    if OBJ_VALID(oLocation) then begin
        success = oLocation->GetData(location)
        verts[0,*] += location[0]
        verts[1,*] += location[1]
        verts[2,*] += location[2]
    endif

    ; Update Output Parameters
    oTets = self->GetParameter('TETRAHEDRA')
    if not OBJ_VALID(oTets) then begin
        oTets = OBJ_NEW('IDLitDataIDLVector', $
            NAME="Interval Volume Tetrahedra List")
        void = self->SetData(oTets, $
            PARAMETER_NAME='TETRAHEDRA', /NO_UPDATE, /BY_VALUE)
    endif
    oVertexColors = self->GetParameter('VERTEX_COLORS')
    if not OBJ_VALID(oVertexColors) then begin
        oVertexColors = OBJ_NEW('IDLitDataIDLVector', $
            NAME="Interval Volume Vertex Color Indices")
        void = self->SetData(oVertexColors, $
            PARAMETER_NAME='VERTEX_COLORS', /NO_UPDATE, /BY_VALUE)
    endif
    success = oVerts->SetData(verts)
    success = oConn->SetData(conn)
    success = oTets->SetData(tets)
    success = oVertexColors->SetData(vertexColors)

    ; Move the Interval Volume before the Volume Visualization.
    ; This improves the mixed display of Volumes (with ZBUFFER on) and
    ; solid geometry.
    oDataSpace = self->GetDataSpace()
    if OBJ_VALID(oDataSpace) then begin
        oAllList = oDataSpace->Get(/ALL)
        volPosition = WHERE(OBJ_ISA(oAllList, 'IDLITVISVOLUME'))
        isoPosition = WHERE(oAllList eq self)
        if volPosition[0] lt isoPosition[0] then $
            oDataSpace->Move, isoPosition[0], volPosition[0]
    endif

    ; Turn off OPTARGET on the vertices because we don't have
    ; any operations that work on vertex lists.
    self->SetParameterAttribute, 'VERTICES', OPTARGET=0
end

;----------------------------------------------------------------------------
function IDLitVisIntVol::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    switch identifier of

    'ISOVALUE': ; fall thru
    'ISOVALUES': begin  ; ISOVALUES became ISOVALUE in IDL64, keep for BC
        success = oTool->DoUIService('IntervalVolume', self)
        if success then begin
            if self._isovalues[0] eq self._isovalues[1] then begin
                self->ErrorMessage, $
                  IDLitLangCatQuery('Error:IsoSurface:IsoValueEqual'), severity=2
                return, 0
            endif
            return, 1
        endif
        return, 0
        break
    end
    endswitch

    ; Call our superclass.
    return, self->IDLitVisIsoSurface::EditUserDefProperty(oTool, identifier)

end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisIntVol::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIntVol::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIntVol::Init followed by the word "Get"
;      can be retrieved using IDLitVisIntVol::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisIntVol::GetProperty, _REF_EXTRA=_extra

  compile_opt idl2, hidden

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisIsoSurface::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisIntVol::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIntVol::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIntVol::Init followed by the word "Set"
;      can be set using IDLitVisIntVol::SetProperty.
;-
pro IDLitVisIntVol::SetProperty, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisIsoSurface::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisIntVol::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisIntVol::]OnDataChangeUpdate, oSubject
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the surface) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-
pro IDLitVisIntVol::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmName) OF
    'TETRAHEDRA': ; do nothing
    'VERTEX_COLORS': self->_SetColor
    else: $
        self->IDLitVisIsoSurface::OnDataChangeUpdate, oSubject, parmName
    endcase
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisIntVol__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisIntVol object.
;
;-
pro IDLitVisIntVol__Define

    compile_opt idl2, hidden

    struct = {IDLitVisIntVol, $
        inherits IDLitVisIsoSurface}
end
