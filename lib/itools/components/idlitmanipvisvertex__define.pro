; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisvertex__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipVisVertex
;
; PURPOSE:
;   The IDLitManipVisVertex class is the vertex manipulator visual.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLgrModel
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipVisVertex::Init
;
; METHODS:
; Intrinsic Methods
;   IDLitManipVisVertex::Init
;   IDLitManipVisVertex::Cleanup
;   IDLitManipVisVertex::_TransformToVisualization
;
; MODIFICATION HISTORY:
;   Written by: CT, RSI, Jan 2003
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipVisVertex::Init
;
; PURPOSE:
;   The IDLitManipVisVertex::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitManipVisVertex')
;
;   or
;
;   Obj->[IDLitManipVisVertex::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-
function IDLitManipVisVertex::Init, NAME=inName, $
    PREFIX_TYPE=prefix, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Vertex Visual"

    ; Initialize superclasses.
    if (self->IDLitManipVisSelect::Init( $
        NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    if (N_ELEMENTS(prefix)) then $
        self._prefix = prefix

    return, 1
end


;----------------------------------------------------------------------------
pro IDLitManipVisVertex::Cleanup
    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont

    ; Cleanup superclass
    self->IDLitManipVisSelect::Cleanup
end


;----------------------------------------------------------------------------
; METHODNAME:
;   IDLitManipVisVertex::_TransformToVisualization
;
; PURPOSE:
;   This private procedure method transforms the selection visual
;   to the size and position of ourself.
;
pro IDLitManipVisVertex::_TransformToVisualization, oVis

    compile_opt idl2, hidden

    ; Retrieve the vertices. Assumes the parameter name.
    oDataObj = oVis->GetParameter('VERTICES')

    if (~OBJ_VALID(oDataObj) || ~oDataObj->GetData(vertex)) then $
        return

    ; Find our position in the hierarchy and make sure we are
    ; in the first position (so we are drawn & selected first).
    if (~oVis->IsContained(self, POSITION=pos)) then $
        return
    if (pos ne 0) then $
        oVis->Move, pos, 0


    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    ; If we have data values out of the normal lonlat range, then
    ; assume these are not coordinates in degrees.
    if (N_TAGS(sMap) gt 0) then begin
        minn = MIN(vertex, DIMENSION=2, MAX=maxx)
        if (minn[0] lt -360 || maxx[0] gt 720 || $
            minn[1] lt -90 || maxx[1] gt 90) then sMap = 0
    endif

    if (N_TAGS(sMap) gt 0) then begin

        hasZ = (SIZE(vertex, /DIM))[0] eq 3
        if (hasZ) then begin
            zdata = vertex[2,*]
            vertex = vertex[0:1, *]
        endif

        vertex = MAP_PROJ_FORWARD(vertex[0:1, *], MAP=sMap)

        if (hasZ) then $
            vertex = [vertex, zdata]

    endif


    nData = (SIZE(vertex, /DIMENSIONS))[1]
    oManipPoints = self->Get(/ALL, COUNT=nCurrent)

    is3D = oVis->Is3D()

    if (~OBJ_VALID(self._oFont)) then $
      self._oFont = OBJ_NEW('IDLgrFont', 'Symbol', SIZE=36)

    textex = {ALIGN: 0.53, $
        VERTICAL_ALIGN: 0.51, $
        COLOR: !COLOR.DODGER_BLUE, $
        FONT: self._oFont, $
        RECOMPUTE_DIM: 2, $
        ALPHA_CHANNEL: 0.4, $
        RENDER: 0}

    ; Create one manipulator visual per vertex in the viz.
    for i=0,nData - 1 do begin

        if (i ge nCurrent) then begin  ; need to create new point

            oPoint = OBJ_NEW('IDLgrText', String(183b), $  ; bullet character
                LOCATION=vertex[*,i], $
                _EXTRA=textex)

            oManipPoint = OBJ_NEW('IDLitManipulatorVisual', $
                VISUAL_TYPE=self._prefix + '/VERT'+STRTRIM(i,2))

            oManipPoint->Add, oPoint
            self->Add, oManipPoint

        endif else begin   ; modify current point

            oManipPoint = oManipPoints[i]
            oManipPoint->SetProperty, HIDE=0
            oPoint = oManipPoint->Get()
            oPoint->SetProperty, LOCATION=vertex[*,i]

        endelse

        if (is3D) then begin
            ; For 3D add another handle perpendicular to the first, to make
            ; it easier to select a vertex on a line profile on a surface.
            if (oManipPoint->Count() le 1) then begin
                oPoint2 = OBJ_NEW('IDLgrText', String(183b), $  ; bullet character
                    BASELINE=[0,1,0], $
                    UPDIR=[0,0,1], $
                    LOCATION=vertex[*,i], $
                    _EXTRA=textex)
                oManipPoint->Add, oPoint2
            endif else begin
                oPoint2 = oManipPoint->Get(POSITION=1)
                oPoint2->SetProperty, LOCATION=vertex[*,i]
            endelse

        endif

    endfor

    ; For efficiency, hide any unneeded manipulator visuals
    ; rather than destroying them.
    for i=nData, nCurrent-1 do $
        oManipPoints[i]->SetProperty, /HIDE

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisVertex__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisVertex object.
;-
pro IDLitManipVisVertex__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisVertex, $
        inherits IDLitManipVisSelect, $
        _oFont: OBJ_NEW(), $
        _prefix: '' $
        }
end
