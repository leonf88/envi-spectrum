; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislight__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;----------------------------------------------------------------------------
; Purpose:
;    The IDLitVisLight class is the component wrapper for IDLgrLight.
;
; Written by:   DLD, October 24, 2001.
;


;----------------------------------------------------------------------------
pro IDLitVisLight::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Register properties.
        self->RegisterProperty, 'LIGHT_TYPE', $
            ENUMLIST=['Ambient', 'Positional', 'Directional', 'Spotlight'], $
            NAME='Type', $
            DESCRIPTION='Type of light'

        self->RegisterProperty, 'Distance', /FLOAT, $
            DESCRIPTION='Distance from the plane Z=0', $
            VALID_RANGE=[-1,1,0.1d], /ADVANCED_ONLY

        self->RegisterProperty, 'Intensity', /FLOAT, $
            DESCRIPTION='Light intensity', $
            VALID_RANGE=[0,1,0.05d]

        self->RegisterProperty, 'Color', /COLOR, $
            DESCRIPTION='Color'

        self->RegisterProperty, 'CONEANGLE', /INTEGER, $
            NAME='Cone angle', $
            DESCRIPTION='Spotlight cone angle in degrees', $
            VALID_RANGE=[0,180,5], /ADVANCED_ONLY

        self->RegisterProperty, 'FOCUS', /FLOAT, $
            NAME='Focus attenuation', $
            DESCRIPTION='Spotlight focus attenuation', $
            VALID_RANGE=[0,128,2], /ADVANCED_ONLY

    endif

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLight::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisLight')
;
; INPUTS:
;   <None>
;
; KEYWORD PARAMETERS:
;   All keywords accepted by IDLgrLight::Init, and:
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitVisLight::Init, NAME=name, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (self->_IDLitVisualization::Init( $
        TYPE='IDLLIGHT', $
        ICON='bulb', $
        /MANIPULATOR_TARGET, $
        NAME=(N_ELEMENTS(name) gt 0) ? name : 'Light', $
        /SELECT_TARGET, $
        _EXTRA=_extra) ne 1) then $
        RETURN, 0

    self->Set3D, /ALWAYS

    if(self->IDLitparameter::Init() ne 1)then begin
        self->_idlitvisualization::cleanup
        return,0
    end
    ; Create the light.
    self.oLight = OBJ_NEW('IDLgrLight', /PRIVATE, $
        INTENSITY=0.6, $
        LOCATION=[0,0,1], $
        TYPE=1)
    if (OBJ_VALID(self.oLight) eq 0) then begin
        self->_IDLitVisualization::Cleanup
        RETURN, 0
    endif
    self->Add, self.oLight

    self._distance = 1d

    self->IDLitVisLight::_RegisterProperties

    self.oVisual = OBJ_NEW('IDLgrModel', /HIDE, LIGHTING=2, /PRIVATE)
    self->Add, self.oVisual

    ; Set any property values.
    ; This will also cause a build of the visual representation.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisLight::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
; PURPOSE:
;    Cleanup this component
;
pro IDLitVisLight::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oTexture  ; needed for BC for IDL61 and earlier

    ; self.oLight gets destroyed when the _IDLitVisualization is destroyed

    ; Cleanup superclass
    self->_IDLitVisualization::Cleanup
    self->IDLitParameter::Cleanup
end


;----------------------------------------------------------------------------
; IDLitVisLight::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLight::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisLight::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
; Private Methods
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLight::_RevolveProfile
;
; PURPOSE:
;    This procedure method computes the vertices and connectivity for
;    a surface of revolution for the given XY profile.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisLight::]_RevolveProfile, x, y, outVerts, outConn
;
; INPUTS:
;    x: A vector of the x components of the profile vertices.
;    y: A vector of the y components of the profile vertices.
;    outVerts:  A named variable that upon return will contain a [3,N] array
;   representing the vertices for the surface of revolution.
;    outConn: A named variable that upon return will contain the connectivity
;   vector for the surface of revolution.
;-
pro IDLitVisLight::_RevolveProfile, x, y, outVerts, outConn, $
    ANGLE_STEP=inAngleStep

    compile_opt idl2, hidden

    ; Determine number of revolutions.
    angStep = (N_ELEMENTS(inAngleStep) ne 0) ? inAngleStep[0] : 30.0
    nRevs = LONG(360. / angStep)

    ; Allocate vertex list.
    nXY = N_ELEMENTS(x)
    nInterior = nXY - 2             ; All except top and btm vert.
    nTotalInt = nInterior * nRevs
    nVert = nTotalInt + 2
    outVerts = DBLARR(3,nVert)
    outVerts[0,0] = [x[0],y[0],0.0]
    outVerts[0,nVert-1] = [x[nXY-1],y[nXY-1],0.0]

    ; Allocate connectivity list.
    nPerTri = 4                  ; [3, v0, v1, v2]
    nQuad = nInterior-1
    nConn = nRevs * ( $
        nPerTri + $                         ; Top triangles
        (nQuad * (2*nPerTri)) + $   ; Interior triangles
        nPerTri)                            ; Bottom triangles
    outConn = LONARR(nConn)

    ; Convert interior vertices to homogeneous coord representation.
    intVerts = [[x[1:nInterior]], $
                [y[1:nInterior]], $
                [REPLICATE(0.0,nInterior)], $
                [REPLICATE(1.0,nInterior)]]

    ; Step through each angle of revolution.
    iConn = 0
    iVert = 1

    ang = 0.0
    rotMat = IDENTITY(4)
    for i=0,nRevs-1 do begin
        isFinalRev = i eq (nRevs-1)

        ; Prepare the rotation matrix.
        rAng = !DTOR * ang
        cosTheta = COS(rAng)
        sinTheta = SIN(rAng)
        oneMinusCos = 1.0 - cosTheta

        dX = 0.0
        dY = 1.0
        dZ = 0.0
        rotMat[0,0] = FLOAT(oneMinusCos * dX * dX + cosTheta)
        rotMat[0,1] = FLOAT(oneMinusCos * dX * dY + sinTheta * dZ)
        rotMat[0,2] = FLOAT(oneMinusCos * dX * dZ - sinTheta * dY)

        rotMat[1,0] = FLOAT(oneMinusCos * dY * dX - sinTheta * dZ)
        rotMat[1,1] = FLOAT(oneMinusCos * dY * dY + cosTheta)
        rotMat[1,2] = FLOAT(oneMinusCos * dY * dZ + sinTheta * dX)

        rotMat[2,0] = FLOAT(oneMinusCos * dZ * dX + sinTheta * dY)
        rotMat[2,1] = FLOAT(oneMinusCos * dZ * dY - sinTheta * dX)
        rotMat[2,2] = FLOAT(oneMinusCos * dZ * dZ + cosTheta)

        rotVerts = TRANSPOSE(intVerts # rotMat)
        outVerts[0,iVert] = rotVerts[0:2,*]

        ; Top triangle.
        outConn[iConn] = [3, iVert, 0, isFinalRev ? 1 : iVert+nInterior]
        iConn = iConn+4

        ; Interior quad triangles.
        v = iVert
        for j=0,nQuad-1 do begin
            if (isFinalRev) then begin
                outConn[iConn] = [3, v, $
                    ((v+nInterior-1) MOD nTotalInt) + 1, $
                    ((v+1+nInterior-1) MOD nTotalInt) + 1, $
                    3, v, $
                    ((v+1+nInterior-1) MOD nTotalInt) + 1, $
                    v+1]
             endif else begin
                 outConn[iConn] = [3, v, v+nInterior, v+1+nInterior, $
                     3, v, v+1+nInterior, v+1]
             endelse
             iConn = iConn+8
             v = v+1
        endfor

        ; Bottom triangle.
        v = iVert + nInterior - 1
        outConn[iConn] = [3, v, $
            isFinalRev ? nInterior : v+nInterior, $
            nVert-1]
        iConn = iConn + 4

        iVert = iVert + nInterior
        ang = ang + angStep
    endfor
end


;----------------------------------------------------------------------------
; Make the light visual brighter or dimmer.
;
function IDLitVisLight::_ColorIntensity, Color, Intensity
    compile_opt idl2, hidden
    return, 0 > (128+((Color/2)*Intensity)) < 255

end


;----------------------------------------------------------------------------
pro IDLitVisLight::_BuildAmbient, lightColor, mysize

    compile_opt idl2, hidden

    ; Create the visual for the bulb.
    x = 0.8
    verts = [[-x,0],[x,0],[x,1.5],[-x,1.5]]*mysize

    self.oVisualBulb = OBJ_NEW('IDLgrPolygon', verts, $
        COLOR=lightColor, $
        ALPHA=0.75)
    self.oVisual->Add, self.oVisualBulb

    c = 0.05
    verts = [[-x,-c],[-x,-1.5],[x,-1.5],[x,-c], $
        [-x,0], [x, 0], $ ; middle
        [-2*c,-c/2],[2*c,-c/2], $ ; top handle
        [-x,-0.75],[x,-0.75], [-x,0.75],[x,0.75], $ ; horiz muntins
        [-2*c,-1.5-c/2],[2*c,-1.5-c/2], $ ; bottom handle
        [-x/3,-1.5],[-x/3,-c], [x/3,-1.5],[x/3,-c], $ ; vert muntin bottom
        [-x/3,0],[-x/3,1.5], [x/3,0],[x/3,1.5], $ ; vert muntin top
        [-x-c,-c],[x+c,-c], $ ; bottom of top sash
        [-x-c,-1.5-c],[x+c,-1.5-c],[x+c,1.5+c],[-x-c,1.5+c], $
        [-x,0],[x,0],[x,1.5],[-x,1.5], $ ; inside top sash
        [-x-3*c,-1.5-3*c],[x+3*c,-1.5-3*c],[x+3*c,1.5+3*c],[-x-3*c,1.5+3*c]]
    polylines = [4,0,1,2,3, $
        2,4,5, $ ; middle
        2,6,7, $ ; top handle
        2,8,9, 2,10,11, $ ; horiz muntins
        2,12,13, $ ; bottom handle
        2,14,15, 2,16,17, $ ; vert muntin bottom
        2,18,19, 2,20,21, $ ; vert muntin top
        2,22,23, $ ; bottom of top sash
        5,24,25,26,27,24, $ ; outside
        5,28,29,30,31,28, $ ; inside top sash
        5,32,33,34,35,32]  ; frame
    verts *= mysize
    oPoly = OBJ_NEW('IDLgrPolyline', verts, POLYLINES=polylines)
    self.oVisual->Add, oPoly

end


;----------------------------------------------------------------------------
pro IDLitVisLight::_BuildLightBulb, lightColor, mysize

    compile_opt idl2, hidden

    ; Create profile of a light bulb.
    ang = 0.0
    angStep = 30.0
    nStep = LONG(180.0 / angStep) ; Number of verts along globe of bulb.
    nExtra = 2                    ; Number of verts along 'stem'.
    nXY = nStep + nExtra
    x = DBLARR(nXY)
    y = DBLARR(nXY)
    for i=0,nStep-1 do begin
        rAng = !DTOR * ang
        x[i] = SIN(rAng) * 0.6          ; Map to 0.0...0.60
        y[i] = (COS(rAng) * 0.6) + 0.4  ; Map to -0.2...1.00
        ang = ang + angStep
    endfor
    lastx = x[nStep-1]
    lasty = y[nStep-1]

    stemLen = 2.0 - (lasty + 1.0)
    shaftLen = 0.4 * stemLen
    i = nStep
    x[i] = lastx
    y[i] = lasty-shaftLen
    lasty = y[i]
    i = i+1

    x[i] = 0
    y[i] = lasty

    self->_RevolveProfile, x, y, verts, conn

    ; Create the visual for the bulb.
    oPoly = OBJ_NEW('IDLgrPolygon', verts*mysize, POLYGON=conn, $
        COLOR=lightColor, DEPTH_OFFSET=-1, SHADING=1, $
        ALPHA=0.75)
    self.oVisualBulb = oPoly
    self.oVisual->Add, oPoly

    ; Now create the threaded base of the bulb.
    nXY = 11
    x = DBLARR(nXY)
    y = DBLARR(nXY)

    i = 0
    x[i] = 0
    y[i] = lasty
    i = i+1

    x[i] = lastx
    y[i] = lasty
    i = i+1

    nThread = 3
    threadLen = 0.045 * stemLen
    for j=0,nThread-1 do begin
        x[i] = lastx+threadLen
        y[i] = lasty-threadLen
        lasty = y[i]
        i = i + 1
        x[i] = lastx
        y[i] = lasty-threadLen
        lasty = y[i]
        i = i + 1
    endfor

    x[i] = lastx
    y[i] = lasty-threadLen
    lasty = y[i]
    i = i + 1
    x[i] = lastx-threadLen
    y[i] = lasty-threadLen
    i = i + 1
    x[i] = 0
    y[i] = -1

    self->_RevolveProfile, x, y, verts, conn

    oPoly = OBJ_NEW('IDLgrPolygon', verts*mysize, POLYGON=conn, $
                     COLOR=[100,100,100], SHADING=1)
    self.oVisual->Add, oPoly

end


;----------------------------------------------------------------------------
pro IDLitVisLight::_BuildDirectional, lightColor, mysize

    compile_opt idl2, hidden

    angStep = 30.0
    nStep = LONG(180.0 / angStep) ; Number of verts for sphere.
    nExtra = 4                    ; Number of verts for arrow.
    nXY = nStep + nExtra
    x = DBLARR(nXY)
    y = DBLARR(nXY)

    ; Start with the arrow.
    arrowLen = 0.4
    shaftLen = 0.6 * arrowLen
    i = 0
    x[i] = 0.0
    y[i] = 1.0
    i = i+1

    headW = 0.3 * arrowLen
    rAng = !DTOR * (0.4*angStep)
    shaftW = SIN(rAng)*0.6
    x[i] = shaftW + headW
    y[i] = 1.0-arrowLen+shaftLen
    lasty = y[i]
    i = i+1

    x[i] = shaftW
    y[i] = lasty
    i = i+1

    x[i] = shaftW
    y[i] = COS(rAng) * 0.6
    i = i+1

    ; Add the sphere.
    ang = angStep
    for j=i, i+nStep-1 do begin
        rAng = !DTOR * ang
        x[j] = SIN(rAng) * 0.6
        y[j] = COS(rAng) * 0.6
        ang = ang + angStep
    endfor

    self->_RevolveProfile, x, y, verts, conn

    ; Create the visual.

    ; For directional lights, we need to slightly change the
    ; location so that the light points in the correct direction.
    self->_IDLitVisualization::GetProperty, TRANSFORM=transform
    lightLoc = (transform ## [0,0,0,1])[0:2]/10000d
    self.oLight->SetProperty, $
        LOCATION=lightLoc

    dir = -1.0*lightLoc
    dir = dir / SQRT(TOTAL(dir*dir))
    vec = CROSSP([0.0,1.0,0.0],dir)
    if (TOTAL(vec*vec) ne 0) then begin
        vec = vec / SQRT(TOTAL(vec*vec))
        ang = ACOS(dir[1]) * !RADEG
        self.oVisual->IDLgrModel::Rotate, vec, ang
    endif

    oPoly = OBJ_NEW('IDLgrPolygon', verts*mysize, POLYGON=conn, $
        COLOR=lightColor, SHADING=1, $
        ALPHA=0.75)
    self.oVisual->Add, oPoly
    self.oVisualBulb = oPoly

end


;----------------------------------------------------------------------------
pro IDLitVisLight::_BuildSpotlight, lightColor, mysize

    compile_opt idl2, hidden

    ang = 0.0
    angStep = 30.0
    nStep = LONG(180.0 / angStep)+ 1
    nXY = nStep
    x = DBLARR(nXY)
    y = DBLARR(nXY)
    for i=0,nStep-1 do begin
        rAng = !DTOR * ang
        x[i] = SIN(rAng) * 0.6          ; Map to 0.0...0.60
        y[i] = (COS(rAng) * 0.6) + 0.4  ; Map to -0.2...1.00
        ang = ang + angStep
    endfor
    lastx = x[nStep-1]
    lasty = y[nStep-1]

    self->_RevolveProfile, x, y, verts, conn

    self.oLight->GetProperty, DIRECTION=lightDir
    lightDir = lightDir / SQRT(TOTAL(lightDir*lightDir))
    vec = CROSSP([0.0,1.0,0.0],lightDir)
    if (TOTAL(vec*vec) ne 0) then begin
        vec = vec / SQRT(TOTAL(vec*vec))
        ang = ACOS(lightDir[1]) * !RADEG
        self.oVisual->IDLgrModel::Rotate, vec, ang
    endif
    oPoly = OBJ_NEW('IDLgrPolygon', verts*mysize, POLYGON=conn, $
        COLOR=lightColor, SHADING=1, $
        ALPHA=0.75)
    self.oVisualBulb = oPoly
    self.oVisual->Add, oPoly

    ; Now the exterior casing of the spotlight.
    nXY = 10
    caseH = 1.5
    bulbRad = 0.6
    x = DBLARR(nXY)
    y = DBLARR(nXY)
    i = 0
    x[i] = 0
    y[i] = 2.0-caseH
    lasty = y[i]
    i = i+1

    lipH = caseH*0.1
    lipW = lipH*0.5
    x[i] = bulbRad*1.1
    y[i] = lasty
    lastx = x[i]
    i = i+1

    x[i] = lastx
    y[i] = lasty+(0.4*lipH)
    lasty = y[i]
    i = i+1

    x[i] = lastx + lipW
    y[i] = lasty
    lastx = x[i]
    i = i+1

    x[i] = lastx
    y[i] = lasty-lipH
    lasty = y[i]
    i = i+1

    x[i] = lastx-lipW
    y[i] = lasty
    lastx = x[i]
    i = i+1

    btmRad = bulbRad*0.7
    x[i] = btmRad
    y[i] = -1+lipH
    lastx = x[i]
    i = i+1

    x[i] = lastx+lipW
    y[i] = -1+lipH
    lastx = x[i]
    i = i+1

    x[i] = lastx
    y[i] = -1
    i = i+1

    x[i] = 0
    y[i] = -1

    self->_RevolveProfile, x, y, verts, conn

    oPoly = OBJ_NEW('IDLgrPolygon', verts*mysize, POLYGON=conn, $
                     COLOR=[160,160,160], SHADING=0)
    self.oVisual->Add, oPoly

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLight::_BuildVisual
;
; PURPOSE:
;    This procedure method builds a visual representation for the light
;    based upon its type.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisLight::]_BuildVisual
;
; INPUTS:
;    <None>
;
;-
pro IDLitVisLight::_BuildVisual

    compile_opt idl2, hidden


    ; Free old visual.
    oContained = self.oVisual->Get(/ALL, COUNT=count)
    if (count gt 0) then begin
        self.oVisual->Remove, /ALL
        OBJ_DESTROY, oContained
    endif

    ; Reset my distance. For initial creation this needs to be done here
    ; as well as in the SetProperty for distance.
    self->IDLgrModel::GetProperty, TRANSFORM=transform
    transform[3,2] = self._distance
    self->IDLgrModel::SetProperty, TRANSFORM=transform

    self.oVisual->Reset

    ; Determine the type of the light.
    self.oLight->GetProperty, $
        COLOR=lightColor, $
        INTENSITY=intensity, $
        LOCATION=lightLoc, $
        TYPE=type


    ; Make the light visual brighter or dimmer.
    lightColor = self->_ColorIntensity(lightColor, intensity)
    mysize = 0.2d/(2d - self._distance)

    case type of
        0: self->_BuildAmbient, lightColor, mysize ; Ambient.
        1: self->_BuildLightBulb, lightColor, mysize ; Positional
        2: self->_BuildDirectional, lightColor, mysize ; Directional
        3: self->_BuildSpotlight, lightColor, mysize ; Spot light
    endcase

    ; For directional lights, we need to slightly change the
    ; location so that the light points in the correct direction.
    if (type ne 2) then $
        self.oLight->SetProperty, LOCATION=[0,0,0]

    self.oVisual->SetProperty, LIGHTING=2*(type ne 0)

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLight::GetProperty
;
; PURPOSE:
;    This procedure method retrieves the value of a property or group of
;    properties.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisLight::]GetProperty
;
; INPUTS:
;    <None>
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitVisLight::Init followed by the word "Get"
;    can be retrieved using IDLitVisLight::GetProperty.
;
;-
pro IDLitVisLight::GetProperty, $
    DISTANCE=distance, $
    LIGHT_TYPE=type, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; My properties.

    ; Get them all from here
    self.oLight->GetProperty, $
        TYPE=type, $
        _EXTRA=_extra

    if (ARG_PRESENT(distance)) then $
        distance = self._distance

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLight::SetProperty
;
; PURPOSE:
;    This procedure method sets the value of a property or group of properties.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisLight::]SetProperty
;
; INPUTS:
;    <None>
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitVisLight::Init followed by the word "Set"
;    can be set using IDLitVisLight::SetProperty.
;-
pro IDLitVisLight::SetProperty, $
    COLOR=color, $
    DIRECTION=direction, $
    DISTANCE=distance, $
    INTENSITY=intensity, $
    LOCATION=location, $
    LIGHT_TYPE=type, $
    TRANSFORM=transform, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get former lighting values for properties that impact
    ; the visual.
    self.oLight->GetProperty, $
        COLOR=oldColor, $
        DIRECTION=oldDirection, $
        INTENSITY=oldIntensity, $
        LOCATION=oldLocation, $
        TYPE=oldType


    ; Intercept the model transform.
    if (N_ELEMENTS(transform) gt 0) then begin

        ; Don't allow ambient lights to be translated, rotated, or scaled.
        if (oldType eq 0) then $
            return

        ; For directional lights, we need to slightly change the
        ; location so that the light points in the correct direction.
        if (oldType eq 2) then begin
            self.oLight->SetProperty, $
                LOCATION=(transform ## [0,0,0,1])[0:2]/10000d
        endif

        ; Pass on to our superclass.
        self->_IDLitVisualization::SetProperty, TRANSFORM=transform

    endif


    if (N_ELEMENTS(distance)) then begin
        self._distance = distance
        ; Change the Z translation directly.
        self->IDLgrModel::GetProperty, TRANSFORM=transform
        transform[3,2] = self._distance
        self->IDLgrModel::SetProperty, TRANSFORM=transform
    endif


    ; Intercept the location, and convert it into a model translate.
    if (N_ELEMENTS(location) eq 3) then begin
        ; Store our new distance.
        self._distance = location[2]
        ; Assume that we want to reset the entire transform.
        self->Reset
        self->Translate, location[0], location[1], location[2], /PREMULTIPLY
    endif


    ; All new light-specific property values go to the light
    self.oLight->SetProperty, $
        COLOR=color, $
        DIRECTION=direction, $
        INTENSITY=intensity, $
        TYPE=type, $
        _EXTRA=_extra


    ; Update the visual as need be.
    colorChange = (N_ELEMENTS(color) eq 3)
    intensityChange = (N_ELEMENTS(intensity) ne 0)

    if (N_ELEMENTS(type) || N_ELEMENTS(location) || $
        N_ELEMENTS(distance) || N_ELEMENTS(direction)) then begin

        self->_BuildVisual

        ; Turn on/off spotlight properties.
        if (N_ELEMENTS(type)) then begin
            self->SetPropertyAttribute, ['CONEANGLE', 'FOCUS'], $
                SENSITIVE=(type[0] eq 3)
        endif

    endif else begin

        if (~OBJ_VALID(self.oVisualBulb)) then $
            self->_BuildVisual

        if (colorChange or intensityChange) then begin
            self.oLight->GetProperty, $
                COLOR=lightColor, INTENSITY=intensity
            ; Make the light visual brighter or dimmer.
            lightColor = self->_ColorIntensity(lightColor, intensity)
            self.oVisualBulb->SetProperty, COLOR=lightColor
        endif

    endelse

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->_IDLitVisualization::SetProperty, $
            _EXTRA=_extra
    endif
end


;----------------------------------------------------------------------------
; Purpose:
;   Override the superclass' method. We keep our selection visual in sync
;   with our visualization using UpdateSelectionVisualVisibility.
;
pro IDLitVisLight::UpdateSelectionVisual
    compile_opt idl2, hidden
    ; Do nothing.
end


;----------------------------------------------------------------------------
; Purpose:
;   Override the superclass' method, so we can simply hide/show our light.
;
pro IDLitVisLight::UpdateSelectionVisualVisibility

    compile_opt idl2, hidden

    self.oVisual->IDLgrModel::SetProperty, HIDE=~self->IsSelected()

end


;----------------------------------------------------------------------------
; Purpose:
;   Override the select method, so we can hide/show our light bulb.
;
pro IDLitVisLight::Select, iMode, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_PARAMS() eq 1) then $
        self->_IDLitVisualization::Select, iMode, _EXTRA=_extra $
    else $
        self->_IDLitVisualization::Select, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   Override the translate method,
;   so we can modify our light location if necessary.
;
pro IDLitVisLight::Translate, tx, ty, tz, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self.oLight->GetProperty, LOCATION=location, TYPE=type

    ; For directional lights, we need to slightly change the
    ; location so that the light points in the correct direction.
    if (type eq 2) then begin
        self.oLight->SetProperty, $
            LOCATION=location + [tx, ty, tz]/10000d
    endif

    ; Pass on to our superclass.
    self->_IDLitVisualization::Translate, tx, ty, tz, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLight__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLight object.
;
;-
pro IDLitVisLight__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLight,         $
        inherits _IDLitVisualization, $   ; Superclass: _IDLitVisualization
        inherits IDLitParameter,      $
        oLight: OBJ_NEW(),            $   ; IDLgrLight object
        _oTexture: OBJ_NEW(),         $   ; needed for BC for IDL61 and earlier
        oVisual: OBJ_NEW(),           $   ; Visual representation
        oVisualBulb: OBJ_NEW(),       $   ; Bulb portion of visual rep.
        _distance: 0.0d               $   ; Distance in Z
    }
end
