; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_light_editor.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; FILE:
;    cw_light_editor.pro
;
; NAME:
;    CW_LIGHT_EDITOR
;
; PURPOSE:
;    CW_LIGHT_EDITOR is a compound widget that provides widgets to
;    adjust light properties.
;
; CATEGORY:
;    Compound widgets.
;
; CALLING SEQUENCE:
;    Widget = CW_LIGHT_EDITOR(Parent)
;
; INPUTS:
;    Parent:   The ID of the parent widget.
;
; KEYWORD PARAMETERS:
;    DIRECTION_DISABLED:        Set to disable direction modification
;    DRAG_EVENTS=dragEvents:    Set to enable drag event
;    HIDE_DISABLED:             Set to disable hide modification
;    LIGHT:                     One or more light references to edit
;    LOCATION_DISABLED:         Set to disable location modification
;    TYPE_DISABLED:             Set to disable type modification
;    UNAME          The "user name" to be assigned to the widget.
;    XRANGE:                    X Range to display location graphic
;    XSIZE:                     X size of draw widget
;    YRANGE:                    Y Range to display location graphic
;    YSIZE:                     Y size of draw widget
;    ZRANGE:                    Z Range to display location graphic
;    _EXTRA:                    keywords passed onto widget base
;
; OUTPUTS:
;    The ID of the created widget is returned.
;
; PROCEDURES:
;    cw_Light_Editor_Get:     Get light editor compound widget properties.
;    cw_Light_Editor_Set:     Set light editor compound widget properties.
;    cw_Light_Editor_Cleanup: Destroy any heap used by the compound widget.
;
; SIDE EFFECTS:
;    Sets properties on lights.
;
; RESTRICTIONS:
;    An assumption is made that the lights are located within the view
;    volume. The cw_lighteditor will not allow the lights to be moved
;    outside the view volume.
;
;    It's also expected that the lights are contained within a view.
;
;    This light editor can only operate on isotropic space. If the lights
;    are in anisotropic space, the light location and direction graphics
;    may not perform as expected.
;
;    Note that the axes displayed for manipulating the light location
;    do not necessarily reflect any actual axes the user may have in their
;    scene. They only reflect the data range passed in through the
;    *RANGE keywords.
;
; MODIFICATION HISTORY:
;    Feb. 1999, WSO, Created.
;-

; -----------------------------------------------------------------------------
;
;   Purpose: Create cone used to represent the light direction
;
pro cw_LE_MakeCone, $
    verts, $            ; OUT: Cone vertices
    conn, $             ; OUT: Cone connectivity point list
    coneDirection, $    ; OUT: Direction vector of the cone
    nSides              ;  IN: Number of sides to make the cone

    COMPILE_OPT HIDDEN, STRICTARR

    height = .5

    coneDirection = [0.0, 0.0, -1.0]

    verts = fltarr(3,nSides+1)
    verts[0,0] = 0.0 ; Create vertex at top of cone
    verts[1,0] = 0.0
    verts[2,0] = height

    radianAngle = 0.0
    radius = 0.1    ; radius at base of cone
    angleIncrement = (2.0 * !PI) / float(nSides)

    for i=1,nSides do begin
        verts[0,i] = radius * cos(radianAngle)
        verts[1,i] = radius * sin(radianAngle)
        verts[2,i] = -height
        radianAngle = radianAngle + angleIncrement
    endfor

;   skip the bottom of the cone so you can see the cone's bottom color
;    conn = fltarr(4*nSides+(nSides+1))
;
;    conn[0] = nSides
;
;    for i=1, nSides do $
;        conn[i] = nSides - i + 1
;
;    j = nSides + 1

    conn = fltarr(4*nSides)

    j=0
    for i=1, nSides do begin
        conn[j] = 3
        conn[j+1] = i + 1
        conn[j+2] = 0
        conn[j+3] = i
        if (i eq nSides) then $
            conn[j+1] = 1
        j = j + 4
    endfor
end

; -----------------------------------------------------------------------------
;
;   Purpose: Get the view associated with the light
;
function cw_LE_GetView, $
    sState, $            ;  IN: State structure of compound widget
    oLight               ;  IN: Light used to go up the tree to get the view

    oView = OBJ_NEW()

    oLight->GetProperty, PARENT=oParent

    if (OBJ_VALID(oParent)) then begin

        while (OBJ_VALID(oParent)) do begin

            ;; If the parent is a view, we have found what we are
            ;; looking for.
            if OBJ_ISA(oParent, 'IDLgrView') then $
              return, oParent

            oExistingParent = oParent

            oExistingParent->GetProperty, PARENT=oParent

        endwhile

        if (OBJ_ISA(oExistingParent, 'IDLgrView')) then begin

            oView = oExistingParent
        endif
    endif

    return, oView
end

; -----------------------------------------------------------------------------
;
;   Purpose: Set the local view's properties based on the
;            properties associated with the light's view.
;
pro cw_LE_SetView, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    VIEWPLANE_RECT=viewplane_rect, $ ; OUT:
    ZCLIP=zClip          ; OUT:

    COMPILE_OPT HIDDEN, STRICTARR

    ; Get the light's view
    ;
    oView = cw_LE_GetView(sState, oLight)

    if (OBJ_VALID(oView)) then begin

        ; Get the light's view's properties
        ;
        oView->GetProperty, VIEWPLANE_RECT=viewplane_rect, ZCLIP=zClip, $
            PROJECTION=projection, EYE=eye, DIMENSIONS=dimensions
    endif else begin

        ; if the view doesn't exist, then use default values
        ;
        viewplane_rect = [-1.0, -1.0, 2.0, 2.0]
        eye = 4.0
        projection = 1
        zClip = [1, -1]
    endelse

    geometry = WIDGET_INFO(sState.wDirAndLoc, /GEOMETRY)

    aspect = FLOAT(geometry.xSize)/FLOAT(geometry.ySize)
    viewplane_rect[0] = viewplane_rect[0] * aspect
    viewplane_rect[2] = viewplane_rect[2] * aspect

    ; Set the graphic location and direction views to match

    sState.oLocationView->SetProperty, VIEWPLANE_RECT=viewplane_rect, $
        ZCLIP=zClip, PROJECTION=projection, EYE=eye

    sState.oDirectionView->SetProperty, VIEWPLANE_RECT=viewplane_rect, $
        ZCLIP=zClip, PROJECTION=projection, EYE=eye
end

; -----------------------------------------------------------------------------
;
;   Purpose: Get the minimum and maximum values of the view volume in
;            data coordinates.
;
pro cw_LE_GetViewVolumeRange, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    XRANGE=xRange, $     ; OUT:
    YRANGE=yRange, $     ; OUT:
    ZRANGE=zRange        ; OUT:

    COMPILE_OPT HIDDEN, STRICTARR

    oView = cw_LE_GetView(sState, oLight)

    if (OBJ_VALID(oView)) then begin

        ; Get the CTM for the light
        ;
        lightCTM = oLight->GetCTM()

        ; Invert the matrix so we can go from view volume
        ; space back to the light's data space.
        ;
        invLightCTM = INVERT(lightCTM)

        oView->GetProperty, VIEWPLANE_RECT=viewplane_rect, $
            ZCLIP=zClip

        ; Compute corner locations of the view volume

        corners = FLTARR(4,8)

        corners[*,0] = [viewplane_rect[0], viewplane_rect[1], $
            zClip[0], 1]

        corners[*,1] = [viewplane_rect[0]+viewplane_rect[2], $
            viewplane_rect[1], zClip[0], 1]

        corners[*,2] = [viewplane_rect[0]+viewplane_rect[2], $
            viewplane_rect[1]+viewplane_rect[3], zClip[0], 1]

        corners[*,3] = [viewplane_rect[0], $
            viewplane_rect[1]+viewplane_rect[3], zClip[0], 1]

        corners[*,4] = [viewplane_rect[0], viewplane_rect[1], $
            zClip[1], 1]

        corners[*,5] = [viewplane_rect[0]+viewplane_rect[2], $
            viewplane_rect[1], zClip[1], 1]

        corners[*,6] = [viewplane_rect[0]+viewplane_rect[2], $
            viewplane_rect[1]+viewplane_rect[3], zClip[1], 1]

        corners[*,7] = [viewplane_rect[0], $
            viewplane_rect[1]+viewplane_rect[3], zClip[1], 1]

        cornersInDataSpace = FLTARR(4,8)

        ; Convert the view volume corners to data coordinates and
        ; make sure they're normalized with respect to "w" (homogeneous coord)
        ;
        for iRow = 0, 7 do begin
            cornersInDataSpace[*,iRow] = corners[*,iRow] # invLightCTM
            if (cornersInDataSpace[3,iRow] ne 0.0) then $
                cornersInDataSpace[*,iRow] = $
                    cornersInDataSpace[*,iRow] / cornersInDataSpace[3,iRow]
        endfor

        ; Determine the min and max of the view voljme in data space.
        ;
        minX = MIN(cornersInDataSpace[0,*], MAX=maxX)
        minY = MIN(cornersInDataSpace[1,*], MAX=maxY)
        minZ = MIN(cornersInDataSpace[2,*], MAX=maxZ)

        xRange = [minX, maxX]
        yRange = [minY, maxY]
        zRange = [minZ, maxZ]
    endif else begin

        xRange = [0.0, 1.0]
        yRange = [0.0, 1.0]
        zRange = [0.0, 1.0]
    endelse
end

; -----------------------------------------------------------------------------
;
;   Purpose: Called to enable/disable and set spot light direction graphics.
;
pro cw_LE_SetGraphicDirection, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    enable, $            ;  IN: True to enable the graphic direction window
    DIRECTION=lightDirection ; IN: (opt) Current light direction

    COMPILE_OPT HIDDEN, STRICTARR

    if (enable) then begin

        ; Set the local view's properties based on the
        ; properties associated with the light's view.
        ;
        cw_LE_SetView, sState, oLight

        ; Get the transformation matrix upto the view.
        ;
        lightCTM = oLight->GetCTM()

        ; Remove the translation
        ;
        lightCTM[3,0] = 0.0
        lightCTM[3,1] = 0.0
        lightCTM[3,2] = 0.0

        ; Update the model that contains the light direction graphic
        ; with the same transformation as the light we're controlling.
        ;
        sState.oDirCtmModel->SetProperty, TRANSFORM=lightCTM

        sState.oDirectionModel->Reset
        sState.oDirRotModel->Reset

        xLength = sState.xRange[1] - sState.xRange[0]
        yLength = sState.yRange[1] - sState.yRange[0]
        zLength = sState.zRange[1] - sState.zRange[0]

        ; Scale up the light direction graphic to the actual data space
        ; range since it's only 1 unit long.
        ;
        sState.oDirectionModel->Scale, xLength, yLength, zLength

        ; If the direction vector wasn't passed in then get it.
        ;
        if (N_ELEMENTS(lightDirection) eq 0) then begin
            oLight->GetProperty, DIRECTION=lightDirection
        endif

        ; Keep track of it to use while rotating the
        ; light direction graphic.
        ;
        sState.originalDirection = [lightDirection,1]

        ; Avoid the possibility of a null direction vector
        ;
        if ((lightDirection[0] eq 0.0) and (lightDirection[1] eq 0.0) and $
            (lightDirection[2] eq 0.0)) then begin
            lightDirection = [0.0, 0.0, -1.0]
        endif

        ; Normalize the light direction
        ;
        lightDirection = $
            lightDirection / SQRT(TOTAL(lightDirection * lightDirection))

        ; Create cone data to represent spot light
        ;   (Return the newly manufactured cone's original direction vector)
        ;
        cw_LE_MakeCone, verts, conn, coneDirection, 8 ; n sided cone

        ; Set the light indicator polygon to the new vertice & connect data
        ;
        sState.oDirIndicator->SetProperty, DATA=verts, POLYGON=conn

        ; Determine the normal vector to the plane defined by cone direction
        ; vector and the light direction vector by taking their cross product.
        ;
        rotNormVector = CROSSP(coneDirection, lightDirection)

        ; Calculate the angle of rotation (in radians).
        ; Arccosine of vector dot product.
        ;
        rotAngle = ACOS(TOTAL(coneDirection*lightDirection))

        ; Rotate the direction model to have the cone pointing in the
        ; same direction as the light it represents.
        ;
        sState.oDirectionModel->Rotate, rotNormVector, !RADEG*rotAngle
    endif

    WIDGET_CONTROL, sState.wSpotBase, SENSITIVE=enable
    WIDGET_CONTROL, sState.wDirAndLoc, SENSITIVE=enable
end

; -----------------------------------------------------------------------------
;
;   Purpose: Called to set the slider location values
;
pro cw_LE_SetDiscreteLocation, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    LOCATION=lightLocation ; IN: Current light location

    COMPILE_OPT HIDDEN, STRICTARR

    cw_LE_GetViewVolumeRange, sState, oLight, XRANGE=xRange, $
        YRANGE=yRange, ZRANGE=zRange

    ; set the [value, minimum value, maximum value] of the CW_FSLIDER

    xValue = [lightLocation[0], xRange[0] < lightLocation[0], $
        lightLocation[0] > xRange[1]]
    yValue = [lightLocation[1], yRange[0] < lightLocation[1], $
        lightLocation[1] > yRange[1]]
    zValue = [lightLocation[2], zRange[0] < lightLocation[2], $
        lightLocation[2] > zRange[1]]

    WIDGET_CONTROL, sState.wXLocation, SET_VALUE=xValue
    WIDGET_CONTROL, sState.wYLocation, SET_VALUE=yValue
    WIDGET_CONTROL, sState.wZLocation, SET_VALUE=zValue
end

; -----------------------------------------------------------------------------
;
;   Purpose: Called to set the slider direction values
;
pro cw_LE_SetDiscreteDirection, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    DIRECTION=lightDirection ; IN: Current light direction

    COMPILE_OPT HIDDEN, STRICTARR

    cw_LE_GetViewVolumeRange, sState, oLight, XRANGE=xRange, $
        YRANGE=yRange, ZRANGE=zRange

    ; set the [value, minimum value, maximum value] of the CW_FSLIDER

    xValue = [lightDirection[0], xRange[0] < lightDirection[0], $
        lightDirection[0] > xRange[1]]
    yValue = [lightDirection[1], yRange[0] < lightDirection[1], $
        lightDirection[1] > yRange[1]]
    zValue = [lightDirection[2], zRange[0] < lightDirection[2], $
        lightDirection[2] > zRange[1]]

    WIDGET_CONTROL, sState.wXDirection, SET_VALUE=xValue
    WIDGET_CONTROL, sState.wYDirection, SET_VALUE=yValue
    WIDGET_CONTROL, sState.wZDirection, SET_VALUE=zValue
end

; -----------------------------------------------------------------------------
;
;   Purpose: Called to enable/disable and set the graphical location indicator
;
pro cw_LE_SetGraphicLocation, $
    sState, $            ;  IN: State structure of compound widget
    oLight, $            ;  IN: Light used to go up the tree to get the view
    enable, $            ;  IN: True to enable the graphic location window
    LOCATION=lightLocation ; IN: (opt) Current light location

    COMPILE_OPT HIDDEN, STRICTARR

    if (enable) then begin

        ; Set the local view's properties based on the
        ; properties associated with the light's view.
        ;
        cw_LE_SetView, sState, oLight, VIEWPLANE_RECT=viewplane_rect, $
            ZCLIP=zClip

        ; Get the transformation matrix upto the view.
        ;
        lightCTM = oLight->GetCTM()

        ; Make sure we have the same transformation as the light we're
        ; representing.
        ;
        sState.oLocCtmModel->SetProperty, TRANSFORM=lightCTM

        ; Reset the other model to add in scaling below.
        ;
        sState.oLocationModel->Reset

        xLength = sState.xRange[1] - sState.xRange[0]
        yLength = sState.yRange[1] - sState.yRange[0]
        zLength = sState.zRange[1] - sState.zRange[0]

        ; Scale up the light location graphic to the actual data space
        ; range since it's only in the range of 0 to 1.
        ;
        sState.oLocationModel->Scale, xLength, yLength, zLength

        ; If the light location wasn't passed in then get it.
        ;
        if (N_ELEMENTS(lightLocation) eq 0) then begin
            oLight->GetProperty, LOCATION=lightLocation
        endif

        ; Since the light location graphic is in the 0 to 1 space
        ; we need to scale its position to that space.
        ;
        sState.oLocIndicator->SetProperty, POS=[lightLocation[0]/xLength, $
            lightLocation[1]/yLength, lightLocation[2]/zLength]

        ; Determine the depth by transforming the lightLocation in
        ; data space of the light to view volume space (ZCLIP[0] to ZCLIP[1])
        ; and set the depth slider [value,min,max] appropriately.
        ;
        normLoc = [lightLocation, 1] # lightCTM

        ; Normalize relative to "w" homogeneous coordinates
        ;
        if (normLoc[3] ne 0.0) then $
            normLoc = normLoc / normLoc[3]

        WIDGET_CONTROL, sState.wZDepth, $
            SET_VALUE=[normLoc[2], zClip[1], zClip[0]]
    endif

    WIDGET_CONTROL, sState.wDirAndLoc, SENSITIVE=enable
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Get the size of one pixel in data space. This is used to allow
;             simple conversion of mouse movements in the wDirAndLoc widget
;             to data space coordinates. This is used for direct manipulation
;             of the graphical location (not spot direction which uses
;             the TrackBall object).
;
pro cw_LE_GetPixelSizeInDataSpace, $
    oLight, $           ;  IN: Light used to get the transformation
    oWindow, $          ;  IN: Used to get destination information
    oneXPixel, $        ; OUT: Results: size of one pixel in x direction
    oneYPixel           ; OUT: Results: size of one pixel in y direction

    COMPILE_OPT HIDDEN, STRICTARR

    ; Since we setup the view to always be the same size as the graphics
    ; window we can just get the graphics window dimensions to determine the
    ; views dimensions in pixels.
    ;
    oWindow->GetProperty, DIMENSIONS=dest_dim

    ; Get the CTM (normalized so that x,y,z are in the range -1 to 1)
    ;
    lightCTM = oLight->GetCTM(DESTINATION=oWindow)

    ; Transform the point (0,0,0) in data space to normalized space (-1 to 1)
    ;
    initLoc = [0,0,0,1] # lightCTM

    ; Normalize relative to "w" homogeneous coordinates
    ;
    if (initLoc[3] ne 0.0) then $
        initLoc = initLoc / initLoc[3]

    ; Now transform the point from normalized space to screen space.
    ; Offset point to "0 to 2" range then take half that to get to "0 to 1"
    ; space now take that facter (fraction of one) and multiply that times
    ; the view dimensions in pixels to get point location in pixels.
    ;
    initLoc[0] = (initLoc[0] + 1.0)*0.5*dest_dim[0]
    initLoc[1] = (initLoc[1] + 1.0)*0.5*dest_dim[1]
    initLoc[2] = (initLoc[2] + 1.0)*0.5
    initLoc[3] = 1.0

    ; Now we have a point "initLoc" at (0,0,0) in data space now in pixels

    ; 1. Add one to x and convert (using inverse CTM) back to data space
    ; to determine the amount in data space (x,y,z) moved when the cursor
    ; is moved one pixel in the x direction.
    ;
    oneXPixel = initLoc + [1,0,0,0]

    ; 2. First normalize relative to the size of the view in pixels.
    ; Then convert it from that "0 to 1" space to the "-1 to 1" space.
    ;
    oneXPixel[0] = (oneXPixel[0] / FLOAT(dest_dim[0]))*2.0-1.0
    oneXPixel[1] = (oneXPixel[1] / FLOAT(dest_dim[1]))*2.0-1.0
    oneXPixel[2] = oneXPixel[2]*2.0-1.0

    ; 3. Now invert the matrix and multiply to get to data space.
    ;
    oneXPixel = oneXPixel # INVERT(lightCTM)

    ; Normalize relative to "w" homogeneous coordinates
    ;
    if (oneXPixel[3] ne 0.0) then $
        oneXPixel = oneXPixel / oneXPixel[3]

    ; Now do the same steps (#1, #2 and #3) to get the offset in data space
    ; one pixel in the y direction.

    ; 1. Add one to y and convert (using inverse CTM) back to data space
    ; to determine the amount in data space (x,y,z) moved when the cursor
    ; is moved one pixel in the y direction.
    ;
    oneYPixel = initLoc + [0,1,0,0]

    ; 2. First normalize relative to the size of the view in pixels.
    ; Then convert it from that "0 to 1" space to the "-1 to 1" space.
    ;
    oneYPixel[0] = (oneYPixel[0] / FLOAT(dest_dim[0]))*2.0-1.0
    oneYPixel[1] = (oneYPixel[1] / FLOAT(dest_dim[1]))*2.0-1.0
    oneYPixel[2] = oneYPixel[2]*2.0-1.0

    ; 3. Now invert the matrix and multiply to get to data space.
    ;
    oneYPixel = oneYPixel # INVERT(lightCTM)

    ; Normalize relative to "w" homogeneous coordinates
    ;
    if (oneYPixel[3] ne 0.0) then $
        oneYPixel = oneYPixel / oneYPixel[3]
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Set the current light selection in the CW
;
pro cw_LE_SetLight, $
    sState, $            ;  IN: State structure of compound widget
    lightIndex           ;  IN: Index of light to make currently selected

    COMPILE_OPT HIDDEN, STRICTARR

    oLight = (*(sState.pLightList))[lightIndex]

    oLight->GetProperty, TYPE=lightType, $
        INTENSITY=lightIntensity, HIDE=lightHide, CONEANGLE=lightConeAngle, $
        FOCUS=lightFocus, COLOR=lightColor, NAME=lightName, $
        LOCATION=lightLocation, DIRECTION=lightDirection

    WIDGET_CONTROL, sState.wLightList, SET_DROPLIST_SELECT=lightIndex
    WIDGET_CONTROL, sState.wTypeList, SET_DROPLIST_SELECT=lightType
    WIDGET_CONTROL, sState.wIntensitySlider, SET_VALUE=lightIntensity
    WIDGET_CONTROL, sState.wHideCheckbox, SET_VALUE=lightHide
    WIDGET_CONTROL, sState.wFocus, SET_VALUE=lightFocus
    WIDGET_CONTROL, sState.wConeAngle, SET_VALUE=lightConeAngle
    WIDGET_CONTROL, sState.wNameText, SET_VALUE=lightName
    WIDGET_CONTROL, sState.wRed, SET_VALUE=lightColor[0]
    WIDGET_CONTROL, sState.wGreen, SET_VALUE=lightColor[1]
    WIDGET_CONTROL, sState.wBlue, SET_VALUE=lightColor[2]

    sState.lightColor = lightColor
    sState.oColorWindow->Erase, COLOR=lightColor

    ; Depending on if we're in location graphic mode (0),
    ; location discrete mode (1), spot light direction graphic mode (2) or in
    ; spot light direction discrete mode (3), update the appropriate graphic
    ; and/or widgets
    ;
    case sState.modeIndex of

        0: begin ; Graphical location

            cw_LE_SetGraphicLocation, sState, oLight, (lightType ne 0), $
                LOCATION=lightLocation
        end

        1: begin ; discrete location

            cw_LE_SetDiscreteLocation, sState, oLight, LOCATION=lightLocation
        end

        2: begin ; Graphical direction

            cw_LE_SetGraphicDirection, sState, oLight, (lightType eq 3),$
                DIRECTION=lightDirection
        end

        3: begin ; discrete direction

            cw_LE_SetDiscreteDirection, sState, oLight,DIRECTION=lightDirection
        end

        else:
    endcase

    ; Draw either the light location or light direction graphics
    ;
    cw_LE_UpdateDraw, sState, lightType
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Update the graphics effected by the change in range or rotation
;             external to this compound widget (e.g., direct manipulation
;             of the original scene where the lights exist).
;
pro cw_LE_Grow, $
    sState               ;  IN: State structure of compound widget

    COMPILE_OPT HIDDEN, STRICTARR

    lightIndex = WIDGET_INFO(sState.wLightList, /DROPLIST_SELECT)

    oLight = (*(sState.pLightList))[lightIndex]

    oLight->GetProperty, TYPE=lightType, $
        DIRECTION=lightDirection, LOCATION=lightLocation

    ; Depending on if we're in location graphic mode (0),
    ; location discrete mode (1), spot light direction graphic mode (2) or in
    ; spot light direction discrete mode (3), update the appropriate graphic
    ; and/or widgets
    ;
    case sState.modeIndex of

        0: begin ; Graphical location

            cw_LE_SetGraphicLocation, sState, oLight, (lightType ne 0), $
                LOCATION=lightLocation

            cw_LE_UpdateDraw, sState, lightType
        end

        1: begin ; discrete location

            cw_LE_SetDiscreteLocation, sState, oLight, LOCATION=lightLocation
        end

        2: begin ; Graphical direction

            cw_LE_SetGraphicDirection, sState, oLight, (lightType eq 3), $
                DIRECTION=lightDirection

            cw_LE_UpdateDraw, sState, lightType
        end

        3: begin ; discrete direction

            cw_LE_SetDiscreteDirection, sState, oLight,DIRECTION=lightDirection
        end

        else:
    endcase
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Redraw the draw widget used for manipulation
;
pro cw_LE_UpdateDraw, $
    sState, $            ;  IN: State structure of compound widget
    lightType            ;  IN: Type of light that's currently selected

    COMPILE_OPT HIDDEN, STRICTARR

    ; If we're in location graphic mode (0) and the light type is not ambient
    ;
    if ((sState.modeIndex eq 0) and (lightType ne 0)) then begin

        sState.oDirAndLocWindow->Draw, sState.oLocationView

    endif else if ((sState.modeIndex eq 2) and (lightType eq 3)) then begin

        ; Else if we're in spot light direction graphic mode (2) and the light
        ; type is a spot light.
        ;
        sState.oDirAndLocWindow->Draw, sState.oDirectionView

    endif else begin

        ; Else erase to the background color.
        ;
        sState.oDirAndLocWindow->Erase, COLOR=sState.backgroundColor
    endelse
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Called when the widget is realized. Initialize the widget.
;
pro cw_LE_NotifyRealize, $
    wId               ;  IN: Widget ID of compound widget

    COMPILE_OPT HIDDEN, STRICTARR

    ;  Get the widget state information.
    ;
    WIDGET_CONTROL, wId, GET_UVALUE=sState

    if (sState.initialized eq 0) then begin

        ; Get the IDLgrWindow object for the color swatch.
        ;
        WIDGET_CONTROL, sState.wColor, GET_VALUE=oColorWindow
        sState.oColorWindow = oColorWindow

        ; Get the IDLgrWindow object for the location/direction.
        ;
        WIDGET_CONTROL, sState.wDirAndLoc, GET_VALUE=oDirAndLocWindow
        sState.oDirAndLocWindow = oDirAndLocWindow

        ; Default to the first light
        ;
        if (sState.nLights gt 0) then $
            cw_LE_SetLight, sState, 0

        sState.initialized = 1
    endif

    WIDGET_CONTROL, wId, SET_UVALUE=sState
end

; -----------------------------------------------------------------------------
;
;   Purpose:  Convert a vector from screen space into data space.
;
function ScreenToData, sState, oLight, vector

    sState.oDirRotModel->SetProperty, TRANSFORM=sState.initialRotation

    ctm = oLight->GetCTM(DESTINATION=sState.oDirAndLocWindow)

    ; Project the origin (0,0,0) in data space to the screen (-1 to +1 domain)
    ;
    origin = [0.0,0.0,0.0,1.0] # ctm

    if (origin[3] ne 0.0) then $
        origin = origin / origin[3]

    ; Add the vector to the origin to get the point in screen space
    ;
    vectorInSS = origin[0:2] + vector

    ; Transform the point back into data space
    ;
    vectorInDS = [vectorInSS,1] # INVERT(ctm)

    if (vectorInDS[3] ne 0.0) then $
        vectorInDS = vectorInDS / vectorInDS[3]

    ; Renormalize the resulting vector
    ;
    vectorInDS = vectorInDS[0:2] / SQRT(TOTAL(vectorInDS[0:2]^2.0))

    RETURN, vectorInDS
END


; -----------------------------------------------------------------------------
;
;   Purpose:  Handle events for the compound widget.
;
function cw_LE_HandleEvents, $
    sEvent            ;  IN: Event from compound widget

    COMPILE_OPT HIDDEN, STRICTARR

    ;  Get the widget state information.
    ;
    wSubBase = sEvent.handler
    WIDGET_CONTROL, wSubBase, GET_UVALUE=sState

    ;  Return zero if fail (no event propagation).
    ;
    returnEvent = 0L

    ; Set the return event up here since it is returned in many places below.
    ;
    LM_Event = { cw_Light_Editor_LM, ID: WIDGET_INFO(wSubBase, /PARENT), $
        TOP: sEvent.top, handler: 0L }

    ; Catch any errors and dislay a dialog

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=sState.wMainBase)
        MESSAGE, /RESET
        RETURN, 0L
    endif

    if (sState.initialized eq 0) then begin

        ; Just return if it hasn't been realized yet.
        RETURN, 0L
    endif

    ; Which light is the currently selected light.
    ;
    lightIndex = WIDGET_INFO(sState.wLightList, /DROPLIST_SELECT)

    ; Make a shortcut for readability
    ;
    oLight = (*(sState.pLightList))[lightIndex]

    ;  Process events.
    ;
    case (sEvent.id) of

        ; --------------------------
        ;   Light Selection Droplist
        ; --------------------------
        sState.wLightList: begin

            lightIndex = WIDGET_INFO(sState.wLightList, /DROPLIST_SELECT)

            ; Set that selection to be the currently selected light.
            ;
            cw_LE_SetLight, sState, lightIndex

            ; Return that a different light was selection from the droplist
            ;
            returnEvent = { cw_Light_Editor_LS, $
                ID: WIDGET_INFO(wSubBase, /PARENT), $
                TOP: sEvent.top, $
                handler: 0L, $
                light: oLight $
                }
        end

        ; --------------------------
        ;   Mode Droplist
        ;   0: Graphical location, 1: Discrete location
        ;   2: Graphical direction, 3: Discrete direction
        ; --------------------------
        sState.wModeSelect: begin

            modeIndex = WIDGET_INFO(sState.wModeSelect,/DROPLIST_SELECT)

            if (sState.modeIndex ne modeIndex) then begin

                sState.modeIndex = modeIndex

                oLight->GetProperty, TYPE=lightType, $
                    DIRECTION=lightDirection, LOCATION=lightLocation

                case sState.modeIndex of

                    0: begin ; Graphical location

                        ; Update the location graphic, draw it
                        ; and map it (if needed).
                        ;
                        cw_LE_SetGraphicLocation, sState, oLight, $
                            (lightType ne 0), LOCATION=lightLocation

                        cw_LE_UpdateDraw, sState, lightType

                        WIDGET_CONTROL, sState.wMap1Base, MAP=1, $
                            SENSITIVE=(sState.locDisabled eq 0)
                        WIDGET_CONTROL, sState.wZDepthBase, MAP=1

                        WIDGET_CONTROL, sState.wMap2Base, MAP=0
                        WIDGET_CONTROL, sState.wMap3Base, MAP=0
                    end

                    1: begin ; Discrete location

                        ; Update the location widget,
                        ; and map it (if needed).
                        ;
                        cw_LE_SetDiscreteLocation, sState, oLight, $
                            LOCATION=lightLocation

                        WIDGET_CONTROL, sState.wMap1Base, MAP=0
                        WIDGET_CONTROL, sState.wMap2Base, MAP=1
                        WIDGET_CONTROL, sState.wMap3Base, MAP=0
                    end

                    2: begin ; Graphical direction

                        ; Update the direction graphic, draw it
                        ; and map it (if needed).
                        ;
                        cw_LE_SetGraphicDirection, sState, $
                            oLight, (lightType eq 3), DIRECTION=lightDirection

                        cw_LE_UpdateDraw, sState, lightType

                        WIDGET_CONTROL, sState.wMap1Base, MAP=1, $
                            SENSITIVE=(sState.dirDisabled eq 0)

                        WIDGET_CONTROL, sState.wZDepthBase, MAP=0
                        WIDGET_CONTROL, sState.wMap2Base, MAP=0
                        WIDGET_CONTROL, sState.wMap3Base, MAP=0
                    end

                    3: begin ; Discrete direction

                        ; Update the direction widget,
                        ; and map it (if needed).
                        ;
                        cw_LE_SetDiscreteDirection, sState, oLight, $
                            DIRECTION=lightDirection
                        WIDGET_CONTROL, sState.wMap1Base, MAP=0
                        WIDGET_CONTROL, sState.wMap2Base, MAP=0
                        WIDGET_CONTROL, sState.wMap3Base, MAP=1
                    end
                endcase
            endif
        end

        ; --------------------------
        ;   graphical Z depth slider event
        ; --------------------------
        sState.wZDepth: begin

            oLight->GetProperty, LOCATION=lightLocation, TYPE=lightType

            WIDGET_CONTROL, sState.wZDepth, GET_VALUE=zDepth

            ; Get the light's transformation matrix upto the view.
            ;
            lightCTM = oLight->GetCTM()

            ; Transform the light's original location in the light's data
            ; space to the view volume space (VIEWPLANE_RECT & ZCLIP)
            ;
            lightLocation = [lightLocation, 1] # lightCTM

            ; Normalize the location in world space
            ;
            if (lightLocation[3] ne 0.0) then $
                lightLocation = lightLocation / lightLocation[3]

            ; Set the z location from the depth slider widget
            ;
            lightLocation[2] = zDepth

            ; Transform the lightLocation in view volume space
            ; (VIEWPLANE_RECT & ZCLIP) back to the light's data space.
            ;
            lightLocation = lightLocation # INVERT(lightCTM)

            ; Normalize the location in world space
            ;
            if (lightLocation[3] ne 0.0) then $
                lightLocation = lightLocation / lightLocation[3]

            ; Set the location adjusted by the new depth value.
            ;
            oLight->SetProperty, LOCATION=lightLocation[0:2]

            xLength = sState.xRange[1] - sState.xRange[0]
            yLength = sState.yRange[1] - sState.yRange[0]
            zLength = sState.zRange[1] - sState.zRange[0]

            ; Adjust the graphic location indicator's position. Depth cueing
            ; will make it appear brighter or darker depending on if it's
            ; moving closer or farther away.
            ;
            sState.oLocIndicator->SetProperty, POS=[lightLocation[0]/xLength, $
                lightLocation[1]/yLength, lightLocation[2]/zLength]

            ; Draw it.
            ;
            cw_LE_UpdateDraw, sState, lightType

            returnEvent = LM_Event
        end

        ; --------------------------
        ;   graphical location / direction draw event
        ; --------------------------
        sState.wDirAndLoc: begin

            if (sEvent.type eq 2) then begin ; mouse motion

                ; if directly manipulating graphical location
                ;
                if (sState.modeIndex eq 0) then begin

                    ; How much did the mouse move since we started the drag?
                    ;
                    xDelta = FLOAT(sEvent.x - sState.mouseLoc[0])
                    yDelta = FLOAT(sEvent.y - sState.mouseLoc[1])

                    ; Multiply the mouse motion in pixels by the
                    ; conversion factor to get the new location in data space.
                    ;
                    xDelta = xDelta * sState.oneXPixel
                    yDelta = yDelta * sState.oneYPixel

                    ; Add the amount moved (from mouse down) to the original
                    ; light location.
                    ;
                    lightLocation = sState.originalLocation + xDelta + yDelta

                    ; Set the new light location
                    ;
                    oLight->SetProperty, LOCATION=lightLocation

                    xLength = sState.xRange[1] - sState.xRange[0]
                    yLength = sState.yRange[1] - sState.yRange[0]
                    zLength = sState.zRange[1] - sState.zRange[0]

                    ; Adjust the graphic location indicator's position.
                    ;
                    sState.oLocIndicator->SetProperty, $
                        POS=[lightLocation[0]/xLength, $
                        lightLocation[1]/yLength, lightLocation[2]/zLength]

                    oLight->GetProperty, TYPE=lightType

                    ; Update the draw area.
                    ;
                    cw_LE_UpdateDraw, sState, lightType

                    ; if the user wants events returned during drags, return it
                    ;
                    if (sState.dragEvents eq 1) then begin
                        returnEvent = LM_Event
                    endif

                endif else begin ; (sState.modeIndex eq 2)

                    ; Directly manipulating graphical direction

                    ; Project the mouse point onto the hemisphere

                    xy = (sState.origin[0:1] - [sEvent.x, sEvent.y]) / $
                        sState.origin[2]

                    r = TOTAL(xy^2)

                    if (r gt 1.0) then begin
                        secondVector = [xy/sqrt(r), 0.0]
                    endif else begin
                        secondVector = [xy, sqrt(1.0-r)]
                    endelse

                    ; Transform new hemisphere vector to data space.
                    ;
                    secondVector = ScreenToData(sState, oLight, secondVector)

                    ; Rotate about the axis in data space.
                    ; The axis is the cross product of the two data
                    ; space vectors (Quaternion form).
                    ;
                    quaternion = [CROSSP(sState.firstVector, secondVector),$
                         TOTAL(sState.firstVector*secondVector)]

                    ; Move to x,y,z,w for code readability
                    ;
                    x = quaternion[0]
                    y = quaternion[1]
                    z = quaternion[2]
                    w = quaternion[3]

                    ; Convert a rotation specified in Quaternion form into
                    ; a 4x4 rotation matrix
                    ;
                    rotationMatrix = $
                        [[ w^2+x^2-y^2-z^2, 2*(x*y-w*z), 2*(x*z+w*y), 0], $
                         [ 2*(x*y+w*z), w^2-x^2+y^2-z^2, 2*(y*z-w*x), 0], $
                         [ 2*(x*z-w*y), 2*(y*z+w*x), w^2-x^2-y^2+z^2, 0], $
                         [ 0          , 0          , 0              , 1]]

                    ; Multiply the rotation matrix by the model's initial
                    ; transformation matrix
                    ;
                    newTransform = rotationMatrix # sState.initialRotation

                    sState.oDirRotModel->SetProperty, TRANSFORM=newTransform

                    ; Since direction is a vector and not a point (like
                    ; location) we need to transpose and invert the matrix
                    ; to allow for vector multiplication
                    ;
                    directionalMatrix = TRANSPOSE(INVERT(newTransform))

                    ; Combine rotation transformation matrix and original
                    ; light direction vector to get the new light direction
                    ;
                    lightDirection = $
                        sState.originalDirection # directionalMatrix

                    ; Normalize the direction in world space
                    ;
                    if (lightDirection[3] ne 0.0) then $
                        lightDirection = lightDirection / lightDirection[3]

                    ; Update the light to the new direction
                    ;
                    oLight->SetProperty, DIRECTION=lightDirection[0:2]

                    oLight->GetProperty, TYPE=lightType

                    ; Update the draw area.
                    ;
                    cw_LE_UpdateDraw, sState, lightType

                    if (sState.dragEvents eq 1) then begin
                        returnEvent = LM_Event
                    endif
                endelse
            endif else if (sEvent.type eq 0) then begin

                ; mouse button press - start tracking
                ;
                WIDGET_CONTROL, sState.wDirAndLoc, /DRAW_MOTION_EVENTS

                ; if starting manipulation of the spot light direction graphic.
                ;
                if (sState.modeIndex eq 2) then begin

                    ; Record the manipulations starting point

                    sState.oDirRotModel->GetProperty, TRANSFORM=initialRotation
                    sState.initialRotation = initialRotation

                    ; The manipulations need to be aware of their location
                    ; in screen space.  We do this here by obtaining the
                    ; view we are in and computing the necessary
                    ; pixel/view transforms.
                    ;
                    sState.oDirAndLocWindow->GetProperty, DIMENSIONS=dest_dim

                    ; Since the view dimensions were initially set to zero
                    ; they actually match the destination's dimensions.
                    ;
                    view_dim = dest_dim

                    ; Get the current transformation matrix to screen space
                    ;
                    ctm = sState.oDirRotModel->GetCTM(DESTINATION=$
                        sState.oDirAndLocWindow)

                    ; Transform origin (0,0,0) in data space to
                    ; screen space (-1 to +1 domain)
                    ;
                    origin = [0.0,0.0,0.0,1.0] # ctm

                    if (origin[3] ne 0.0) then $
                        origin = origin / origin[3]

                    ; Convert the point from normalized coords to pixels
                    ;
                    origin[0] = (origin[0] + 1.0)*0.5*view_dim[0]
                    origin[1] = (origin[1] + 1.0)*0.5*view_dim[1]
                    origin[2] = (dest_dim[0] < dest_dim[1]) * .5 * .75

                    ; Save the manipulation data origin (in screen space).
                    ;
                    sState.origin = origin

                    ; Rotation is computed as follows:
                    ; Form a hemisphere at the object's center of rotation
                    ; Take the relative X,Y coords of the mouse point and
                    ; project these onto the hemisphere, forming a vector
                    ; from the origin to this point in 3D.  As the mouse moves,
                    ; project the new mouse point onto the hemisphere.  The
                    ; object is then rotated over a line perpendicular to
                    ; the hemisphere vectors formed by the initial and current
                    ; mouse points.  The angle of rotation is the angle between
                    ; the two vectors.

                    ; Project the initial point onto hemisphere.
                    ;
                    xy = (sState.origin[0:1] - [sEvent.x, sEvent.y]) / $
                        sState.origin[2]

                    r = TOTAL(xy^2)

                    ; Mouse motion outside of a circle centered at the
                    ; origin point will be converted into pure screen
                    ; Z axis rotation.
                    ;
                    if (r gt 1.0) then begin
                        firstVector = [xy/SQRT(r), 0.0]
                    endif else begin
                        firstVector = [xy, SQRT(1.0-r)]
                    endelse

                    ; Transform the initial hemisphere vector to data space.
                    ;
                    sState.firstVector = $
                        ScreenToData(sState, oLight, firstVector)
                endif else begin

                    ; else we're starting to manipulate the light
                    ; location graphic.
                    ;
                    oLight->GetProperty, LOCATION=originalLocation

                    ; Keep track of the original light location. During the
                    ; mouse motion we'll add the amount moved to this.
                    ;
                    sState.originalLocation = originalLocation

                    ; Determine what one pixel size is in data space. This
                    ; is used to transform the x,y mouse movement into
                    ; the movement of the light location in data space.
                    ;
                    cw_LE_GetPixelSizeInDataSpace, oLight, $
                        sState.oDirAndLocWindow, oneXPixel, oneYPixel

                    sState.oneXPixel = oneXPixel
                    sState.oneYPixel = oneYPixel

                    sState.mouseLoc = [sEvent.x, sEvent.y]
                endelse
            endif else if (sEvent.type eq 1) then begin

                ; mouse button release - finished tracking

                WIDGET_CONTROL, sState.wDirAndLoc, DRAW_MOTION_EVENTS=0

                returnEvent = LM_Event
            endif else begin

                ; expose event - draw it.

                if (sState.nLights eq 0) then begin

                    lightType = 0 ; since no lights currently defined
                endif else begin

                    oLight->GetProperty, TYPE=lightType
                endelse

                cw_LE_UpdateDraw, sState, lightType
            endelse
        end

        ; --------------------------
        ;   red color event
        ; --------------------------
        sState.wRed: begin

            sState.lightColor = $
                [sEvent.value, sState.lightColor[1], sState.lightColor[2]]

            oLight->SetProperty, COLOR=sState.lightColor

            sState.oColorWindow->Erase, COLOR=sState.lightColor

            returnEvent = LM_Event
        end

        ; --------------------------
        ;   green color event
        ; --------------------------
        sState.wGreen: begin

            sState.lightColor = $
                [sState.lightColor[0], sEvent.value, sState.lightColor[2]]

            oLight->SetProperty, COLOR=sState.lightColor

            sState.oColorWindow->Erase, COLOR=sState.lightColor

            returnEvent = LM_Event
        end

        ; --------------------------
        ;   blue color event
        ; --------------------------
        sState.wBlue: begin

            sState.lightColor = $
                [sState.lightColor[0], sState.lightColor[1], sEvent.value]

            oLight->SetProperty, COLOR=sState.lightColor

            sState.oColorWindow->Erase, COLOR=sState.lightColor

            returnEvent = LM_Event
        end

        ; --------------------------
        ;   color draw event
        ; --------------------------
        sState.wColor: begin

            if (sEvent.type eq 4) then begin

                ; Expose event- simply draw it.
                ;
                sState.oColorWindow->Erase, COLOR=sState.lightColor

            endif
        end

        sState.wTypeList: begin

            ; The user has decided to change the light type
            ; 0 = ambient, 1: positional, 2=directional, 3=spot

            lightType = WIDGET_INFO(sState.wTypeList, /DROPLIST_SELECT)

            oLight->SetProperty, TYPE=lightType

            if (lightType eq 3) then begin

                cw_LE_SetGraphicDirection, sState, oLight, 1

            endif else if (lightType ne 0) then begin

                cw_LE_SetGraphicLocation, sState, oLight, 1
            endif

            cw_LE_UpdateDraw, sState, lightType

            returnEvent = LM_Event
        end

        sState.wXDirection: begin

            WIDGET_CONTROL, sState.wXDirection, GET_VALUE=xDirection

            oLight->GetProperty, DIRECTION=lightDirection
            lightDirection[0] = xDirection

            oLight->SetProperty, DIRECTION=lightDirection

            returnEvent = LM_Event
        end

        sState.wYDirection: begin

            WIDGET_CONTROL, sState.wYDirection, GET_VALUE=yDirection

            oLight->GetProperty, DIRECTION=lightDirection
            lightDirection[1] = yDirection

            oLight->SetProperty, DIRECTION=lightDirection

            returnEvent = LM_Event
        end

        sState.wZDirection: begin

            WIDGET_CONTROL, sState.wZDirection, GET_VALUE=zDirection

            oLight->GetProperty, DIRECTION=lightDirection
            lightDirection[2] = zDirection

            oLight->SetProperty, DIRECTION=lightDirection

            returnEvent = LM_Event
        end

        sState.wXLocation: begin

            WIDGET_CONTROL, sState.wXLocation, GET_VALUE=xLocation

            oLight->GetProperty, LOCATION=lightLocation
            lightLocation[0] = xLocation

            oLight->SetProperty, LOCATION=lightLocation

            returnEvent = LM_Event
        end

        sState.wYLocation: begin

            WIDGET_CONTROL, sState.wYLocation, GET_VALUE=yLocation

            oLight->GetProperty, LOCATION=lightLocation
            lightLocation[1] = yLocation

            oLight->SetProperty, LOCATION=lightLocation

            returnEvent = LM_Event
        end

        sState.wZLocation: begin

            WIDGET_CONTROL, sState.wZLocation, GET_VALUE=zLocation

            oLight->GetProperty, LOCATION=lightLocation
            lightLocation[2] = zLocation

            oLight->SetProperty, LOCATION=lightLocation

            returnEvent = LM_Event
        end

        sState.wNameText: begin

            WIDGET_CONTROL, sState.wNameText, GET_VALUE=lightName

            oLight->SetProperty, NAME=lightName[0]

            (*sState.pLightNames)[lightIndex] = lightName[0]

            WIDGET_CONTROL, sState.wLightList, $
                SET_VALUE=*sState.pLightNames, $
                SET_DROPLIST_SELECT=lightIndex

            returnEvent = LM_Event
        end

        ; --------------------------
        ;   Edit Event
        ; --------------------------
        else: begin

            WIDGET_CONTROL, sState.wIntensitySlider, GET_VALUE=lightIntensity
            WIDGET_CONTROL, sState.wHideCheckbox, GET_VALUE=lightHide
            WIDGET_CONTROL, sState.wFocus, GET_VALUE=lightFocus
            WIDGET_CONTROL, sState.wConeAngle, GET_VALUE=lightConeAngle

            oLight->SetProperty, INTENSITY=lightIntensity, HIDE=lightHide[0], $
                CONEANGLE=lightConeAngle, FOCUS=lightFocus

            returnEvent = LM_Event
        end

    endcase

    WIDGET_CONTROL, wSubBase, SET_UVALUE=sState

    ;  Swallow the event on failure (return zero), else pass it on.
    ;
    RETURN, returnEvent

end

; -----------------------------------------------------------------------------
;
;   Purpose:   Get light editor compound widget current light selection. This
;               is an external API called when WIDGET_CONTROL, GET_VALUE
;               is executed.
;
function cw_LE_Get_Selection, $
    wId               ;  IN: Widget ID of compound widget

    COMPILE_OPT HIDDEN, STRICTARR

    ON_ERROR, 2                     ;return to caller

    wBase = WIDGET_INFO(wId, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=sState, /NO_COPY

    lightIndex = WIDGET_INFO(sState.wLightList, /DROPLIST_SELECT)

    value = (*(sState.pLightList))[lightIndex]

    WIDGET_CONTROL, wBase, SET_UVALUE=sState, /NO_COPY

    return, value
end

; -----------------------------------------------------------------------------
;
;   Purpose:   Set light editor compound widget current light selection. This
;               is an external API called when WIDGET_CONTROL, SET_VALUE
;               is executed.
;
pro cw_LE_Set_Selection, $
    wId, $              ;  IN: Widget ID of compound widget
    value               ;  IN: Object ref of light to make curent selection

    COMPILE_OPT HIDDEN, STRICTARR

    ON_ERROR, 2                     ;return to caller

    wBase = WIDGET_INFO(wId, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=sState

    lightIndex = (WHERE(value eq *(sState.pLightList)))[0]

    if (lightIndex eq -1) then begin

        MESSAGE, $
            'The light requested to set does not exist in the light editor.'
    endif

    cw_LE_SetLight, sState, lightIndex

    WIDGET_CONTROL, wBase, SET_UVALUE=sState
end

; -----------------------------------------------------------------------------
;
;   Purpose:   Call to destroy any heap used by the compound widget.
;
pro cw_Light_Editor_Cleanup, $
    wId                 ;  IN: Widget ID of compound widget

    COMPILE_OPT HIDDEN, STRICTARR

    ON_ERROR, 2                     ;return to caller

    WIDGET_CONTROL, wId, GET_UVALUE=sState, /NO_COPY

    if (OBJ_VALID(sState.oDirectionView)) then $
        OBJ_DESTROY, sState.oDirectionView
    if (OBJ_VALID(sState.oLocationView)) then $
        OBJ_DESTROY, sState.oLocationView
    if (OBJ_VALID(sState.oXTickText)) then $
        OBJ_DESTROY, sState.oXTickText
    if (OBJ_VALID(sState.oYTickText)) then $
        OBJ_DESTROY, sState.oYTickText
    if (OBJ_VALID(sState.oZTickText)) then $
        OBJ_DESTROY, sState.oZTickText

    PTR_FREE, sState.pLightNames, sState.pLightList

;   Don't need to set the sState back since it's being destroyed.
;    WIDGET_CONTROL, wBase, SET_UVALUE=sState, /NO_COPY
end

; -----------------------------------------------------------------------------
;
;   Purpose:   Get light editor compound widget properties.
;
pro cw_Light_Editor_Get, $
    wId, $                            ;  IN: Widget ID of compound widget
    DIRECTION_DISABLED=dirDisabled, $ ; OUT: Set to disable direction modif.
    DRAG_EVENTS=dragEvents, $         ; OUT: Set to enable drag event
    HIDE_DISABLED=hideDisabled, $     ; OUT: Set to disable hide modif.
    LIGHT=oLight, $                   ; OUT: one or more lights to edit
    LOCATION_DISABLED=locDisabled, $  ; OUT: Set to disable location modif.
    TYPE_DISABLED=typeDisabled, $     ; OUT: Set to disable type modif.
    XRANGE=xRange, $                  ; OUT: Range to display location graphic
    XSIZE=xSize, $                    ; OUT: X size of draw widget
    YRANGE=yRange, $                  ; OUT: Range to display location graphic
    YSIZE=ySize, $                    ; OUT: Y size of draw widget
    ZRANGE=zRange                     ; OUT: Range to display location graphic

    COMPILE_OPT STRICTARR

    ON_ERROR, 2                     ;return to caller

    wBase = WIDGET_INFO(wId, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=sState, /NO_COPY

    dirDisabled = sState.dirDisabled
    dragEvents = sState.dragEvents
    hideDisabled = sState.hideDisabled
    oLight = *(sState.pLightList)
    locDisabled = sState.locDisabled
    typeDisabled = sState.typeDisabled
    xRange = sState.xRange
    xSize = sState.xSize
    yRange = sState.yRange
    ySize = sState.ySize
    zRange = sState.zRange

    WIDGET_CONTROL, wBase, SET_UVALUE=sState, /NO_COPY
end

; -----------------------------------------------------------------------------
;
;   Purpose:   Set light editor compound widget properties.
;
pro cw_Light_Editor_Set, $
    wId, $                             ;  IN: Widget ID of compound widget
    DIRECTION_DISABLED=dirDisabled, $  ; IN: Set to disable direction modif.
    DRAG_EVENTS=dragEvents, $          ; IN: Set to enable drag event
    HIDE_DISABLED=hideDisabled, $      ; IN: Set to disable hide modif.
    LIGHT=oLight, $                    ; IN: one or more lights to edit
    LOCATION_DISABLED=locDisabled, $   ; IN: Set to disable location modif.
    TYPE_DISABLED=typeDisabled, $      ; IN: Set to disable type modif.
    XRANGE=xRange, $                   ; IN: Range to display location graphic
    XSIZE=xSize, $                     ; IN: X size of draw widget
    YRANGE=yRange, $                   ; IN: Range to display location graphic
    YSIZE=ySize, $                     ; IN: Y size of draw widget
    ZRANGE=zRange                      ; IN: Range to display location graphic

    COMPILE_OPT STRICTARR

    ON_ERROR, 2                     ;return to caller

    bRangeChanged = 0

    wBase = WIDGET_INFO(wId, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=sState, /NO_COPY

    if (N_ELEMENTS(oLight) ne 0) then begin

        nLights = N_ELEMENTS(oLight)

        lightNames = STRARR(nLights)

        for iIndex = 0, nLights-1 do begin

            if (not OBJ_ISA(oLight[iIndex], 'IDLgrLight')) then begin

                MESSAGE, $
                    'One of the lights passed in is not a valid IDLgrLight object'
            endif

            oLight[iIndex]->GetProperty, NAME=lightName
            lightNames[iIndex] = lightName
        endfor

        sState.nLights = nLights

        ; Set the light list to the set of lights passed in
        ;
        *(sState.pLightList) = oLight

        *sState.pLightNames = lightNames

        WIDGET_CONTROL, sState.wLightList, SET_VALUE=lightNames, $
            SET_DROPLIST_SELECT=0

        WIDGET_CONTROL, wBase, SENSITIVE=(sState.nLights gt 0)

        ; Set the first light to the currently selected light
        ;
        cw_LE_SetLight, sState, 0
    endif

    if (N_ELEMENTS(dragEvents) ne 0) then $
        sState.dragEvents = KEYWORD_SET(dragEvents)

    if (N_ELEMENTS(hideDisabled) ne 0) then begin

        sState.hideDisabled = KEYWORD_SET(hideDisabled)
        WIDGET_CONTROL, sState.wHideCheckbox, $
            SENSITIVE=(sState.hideDisabled eq 0)
    endif

    if (N_ELEMENTS(typeDisabled) ne 0) then begin

        sState.typeDisabled = KEYWORD_SET(typeDisabled)
        WIDGET_CONTROL, sState.wTypeList, $
            SENSITIVE=(sState.typeDisabled eq 0)
    endif

    if (N_ELEMENTS(xRange) ne 0) then begin

        if ((sState.xRange[0] ne xRange[0]) or $
            (sState.xRange[1] ne xRange[1])) then begin

            sState.xRange = xRange

            bRangeChanged = 1
        endif
    endif

    if (N_ELEMENTS(yRange) ne 0) then begin

        if ((sState.yRange[0] ne yRange[0]) or $
            (sState.yRange[1] ne yRange[1])) then begin

            sState.yRange = yRange

            bRangeChanged = 1
        endif
    endif

    if (N_ELEMENTS(zRange) ne 0) then begin

        if ((sState.zRange[0] ne zRange[0]) or $
            (sState.zRange[1] ne zRange[1])) then begin

            sState.zRange = zRange

            bRangeChanged = 1
        endif
    endif

    if (bRangeChanged) then begin

        ; Make sure the location and direction graphics are updated
        ; to reflect the new range.
        ;
        cw_LE_Grow, sState
    endif

    if ((N_ELEMENTS(xSize) ne 0) or $
        (N_ELEMENTS(ySize) ne 0)) then begin

        if (N_ELEMENTS(xSize) ne 0) then $
            sState.xSize = xSize

        if (N_ELEMENTS(ySize) ne 0) then $
            sState.ySize = ySize

        WIDGET_CONTROL, sState.wMap1Base, XSIZE=sState.xSize, $
            YSIZE=sState.ySize
        WIDGET_CONTROL, sState.wDirAndLoc, DRAW_XSIZE=sState.xSize, $
            DRAW_YSIZE=sState.ySize
    endif

    if ((N_ELEMENTS(dirDisabled) ne 0) or $
        (N_ELEMENTS(locDisabled) ne 0)) then begin

        if (N_ELEMENTS(dirDisabled) ne 0) then $
            sState.dirDisabled = KEYWORD_SET(dirDisabled)

        if (N_ELEMENTS(locDisabled) ne 0) then $
            sState.locDisabled = KEYWORD_SET(locDisabled)

        dirAndLocSensitivity = $
            (((sState.dirDisabled eq 0) and (sState.modeIndex eq 2)) or $
             ((sState.locDisabled eq 0) and (sState.modeIndex eq 0)))

        WIDGET_CONTROL, sState.wMap1Base, SENSITIVE=dirAndLocSensitivity
        WIDGET_CONTROL, sState.wMap2Base, SENSITIVE=(sState.locDisabled eq 0)
        WIDGET_CONTROL, sState.wMap3Base, SENSITIVE=(sState.dirDisabled eq 0)
    endif

    WIDGET_CONTROL, wBase, SET_UVALUE=sState, /NO_COPY
end

; -----------------------------------------------------------------------------
;
;   Purpose:   Create light editor compound widgets.
;
function cw_Light_Editor, $
    wMainBase, $                        ; IN: main (modal) base of the dialog
    DIRECTION_DISABLED=dirDisabled, $   ; IN: Set to disable direction modif.
    DRAG_EVENTS=dragEvents, $           ; IN: Set to enable drag event
    HIDE_DISABLED=hideDisabled, $       ; IN: Set to disable hide modif.
    LIGHT=oLight, $                     ; IN: one or more lights to edit
    LOCATION_DISABLED=locDisabled, $    ; IN: Set to disable location modif.
    TYPE_DISABLED=typeDisabled, $       ; IN: Set to disable type modif.
    UNAME=uname, $          ; IN; The user name of the widget.
    XRANGE=xRange, $                    ; IN: Range to display location graphic
    XSIZE=xSize, $                      ; IN: X size of draw widget
    YRANGE=yRange, $                    ; IN: Range to display location graphic
    YSIZE=ySize, $                      ; IN: Y size of draw widget
    ZRANGE=zRange, $                    ; IN: Range to display location graphic
    _EXTRA=extra                        ; IN: keywords passed onto widget base

    COMPILE_OPT STRICTARR

    if (N_ELEMENTS(xSize) eq 0) then $
        xSize = 180
    if (N_ELEMENTS(ySize) eq 0) then $
        ySize = 180
    if (N_ELEMENTS(xRange) eq 0) then $
        xRange = [0.0,1.0]
    if (N_ELEMENTS(yRange) eq 0) then $
        yRange = [0.0,1.0]
    if (N_ELEMENTS(zRange) eq 0) then $
        zRange = [0.0,1.0]
    if (NOT KEYWORD_SET(uname)) then $
        uname = 'CW_LIGHT_EDITOR_UNAME'

    nLights = N_ELEMENTS(oLight)

    ;  Create base widget.
    ;
    wLightEditorBase = WIDGET_BASE(wMainBase, /COLUMN, XPAD=0, YPAD=0, $
        PRO_SET_VALUE='cw_LE_Set_Selection', $
        FUNC_GET_VALUE='cw_LE_Get_Selection', $
        UNAME=uname, $
        _STRICT_EXTRA=extra)

    wSubBase = WIDGET_BASE(wLightEditorBase, /COLUMN, /ALIGN_RIGHT, $
        SENSITIVE=(nLights gt 0), EVENT_FUNC='cw_LE_HandleEvents', $
        NOTIFY_REALIZE='cw_LE_NotifyRealize', $
        KILL_NOTIFY='cw_Light_Editor_Cleanup', $
        UNAME=uname+'_SUBBASE')

    ; Setup the list of light names
    ;
    if (nLights gt 0) then begin

        oLightUse = oLight

        lightNames = STRARR(nLights)
        for iIndex = 0, nLights-1 do begin

            if (not OBJ_ISA(oLight[iIndex], 'IDLgrLight')) then begin

                MESSAGE, $
                    'One of the lights passed in is not a valid IDLgrLight object'
            endif

            oLight[iIndex]->GetProperty, NAME=lightName
            lightNames[iIndex] = lightName
        endfor

    endif else begin

        ;  Create droplist with bogus long string in order to fake
        ;  out the width, since setting XSIZE does not set the width
        ;  of the droplist number in chars
        ;
        oLightUse=OBJ_NEW()
        lightNames=['                 ']
    endelse

    wLightList = WIDGET_DROPLIST(wSubBase, TITLE='Light:', $
        UNAME=uname+'_LIGHTLIST')

    WIDGET_CONTROL, wLightList, SET_VALUE=lightNames

    modes = ['Graphical Location', 'Discrete Location', $
            'Direction', 'Discrete Direction']

    modeIndex = 0 ; default to 'Location' initially

    wModeSelect = WIDGET_DROPLIST(wSubBase, VALUE=modes, $
        UNAME=uname+'_MODESELECT')

    WIDGET_CONTROL, wModeSelect, SET_DROPLIST_SELECT=modeIndex

    dirAndLocSensitivity = $
        (((KEYWORD_SET(dirDisabled) eq 0) and (modeIndex eq 2)) or $
         ((KEYWORD_SET(locDisabled) eq 0) and (modeIndex eq 0)))

    wMapBase = WIDGET_BASE(wSubBase, XPAD=0, YPAD=0, SPACE=0, /FRAME, $
        UNAME=uname+'_MAPBASE')
    wMap1Base = WIDGET_BASE(wMapBase, MAP=(modeIndex ne 1), XPAD=0, YPAD=0, $
        SPACE=0, /COLUMN, SENSITIVE=dirAndLocSensitivity, $
        UNAME=uname+'_MAP1BASE')
    wMap2Base = WIDGET_BASE(wMapBase, /COLUMN, XPAD=0, YPAD=0, $
        MAP=(modeIndex eq 1), SENSITIVE=(KEYWORD_SET(locDisabled) eq 0), $
        UNAME=uname+'_MAP2BASE')
    wMap3Base = WIDGET_BASE(wMapBase, /COLUMN, XPAD=0, YPAD=0, $
        MAP=(modeIndex eq 3), SENSITIVE=(KEYWORD_SET(dirDisabled) eq 0), $
        UNAME=uname+'_MAP3BASE')

    ; Create draw widget that will contain the direction and location
    ; graphic indicators.
    ;
    wDirAndLoc = WIDGET_DRAW(wMap1Base, XSIZE=xSize, YSIZE=ySize, $
        GRAPHICS_LEVEL=2, /EXPOSE_EVENTS, RETAIN=0, $
        /BUTTON_EVENTS, COLOR_MODEL=0, UNAME=uname+'_DIRANDLOC')

    wZDepthBase = WIDGET_BASE(wMap1Base, /ROW, YPAD=0, $
        MAP=(modeIndex eq 0), UNAME=uname+'_ZDEPTHBASE')

    void = WIDGET_LABEL(wZDepthBase, VALUE='Depth:')
    wZDepth = CW_FSLIDER(wZDepthBase, /SUPPRESS_VALUE, $
        DRAG=KEYWORD_SET(dragEvents), UNAME=uname+'_ZDEPTH')

    wXLocBase = WIDGET_BASE(wMap2Base, /ROW, YPAD=0, UNAME=uname+'_XLOCBASE')
    void = WIDGET_LABEL(wXLocBase, VALUE='X:')
    wXLocation = CW_FSLIDER(wXLocBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_XLOCATION')

    wYLocBase = WIDGET_BASE(wMap2Base, /ROW, YPAD=0, UNAME=uname+'_YLOCBASE')
    void = WIDGET_LABEL(wYLocBase, VALUE='Y:')
    wYLocation = CW_FSLIDER(wYLocBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_YLOCATION')

    wZLocBase = WIDGET_BASE(wMap2Base, /ROW, YPAD=0, UNAME=uname+'_ZLOCBASE')
    void = WIDGET_LABEL(wZLocBase, VALUE='Z:')
    wZLocation = CW_FSLIDER(wZLocBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_ZLOCATION')

    wXDirBase = WIDGET_BASE(wMap3Base, /ROW, YPAD=0, UNAME=uname+'_XDIRBASE')
    void = WIDGET_LABEL(wXDirBase, VALUE='X:')
    wXDirection = CW_FSLIDER(wXDirBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_XDIRECTION')

    wYDirBase = WIDGET_BASE(wMap3Base, /ROW, YPAD=0)
    void = WIDGET_LABEL(wYDirBase, VALUE='Y:')
    wYDirection = CW_FSLIDER(wYDirBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_YDIRECTION')

    wZDirBase = WIDGET_BASE(wMap3Base, /ROW, YPAD=0, UNAME=uname+'_ZDIRBASE')
    void = WIDGET_LABEL(wZDirBase, VALUE='Z:')
    wZDirection = CW_FSLIDER(wZDirBase, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_ZDIRECTION')

    wSub1bBase = WIDGET_BASE(wSubBase, /ROW, XPAD=0, YPAD=0)

    wTypeList = WIDGET_DROPLIST(wSub1bBase, VALUE=['Ambient', $
        'Positional', 'Directional', 'Spot'], TITLE='Type:', $
        UNAME=uname+'_TYPELIST')

    WIDGET_CONTROL, wTypeList, SENSITIVE=(KEYWORD_SET(typeDisabled) eq 0)

    wHideCheckbox  = CW_BGROUP(wSub1bBase, /NONEXCLUSIVE, ['Hide'], $
        UNAME=uname+'_HIDECHECKBOX')

    WIDGET_CONTROL, wHideCheckbox, SENSITIVE=(KEYWORD_SET(hideDisabled) eq 0)

    wSub1Base = WIDGET_BASE(wSubBase, /ROW, XPAD=0, YPAD=0)

    wSub1aBase = WIDGET_BASE(wSub1Base, /ROW, XPAD=0, YPAD=0)

    void = WIDGET_LABEL(wSub1aBase, VALUE='Name:')

    wNameText = WIDGET_TEXT(wSub1aBase, /EDITABLE, XSIZE=10, $
        UNAME=uname+'_NAMETEXT')

    wColorBase = WIDGET_BASE(wSubBase, /ROW, /FRAME)
    wColorCol1Base = WIDGET_BASE(wColorBase, /COLUMN)
    wColorCol2Base = WIDGET_BASE(wColorBase, /COLUMN)

    wColorSwatchBase = WIDGET_BASE(wColorCol1Base, /COLUMN, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wColorSwatchBase, VALUE='Color:')
    ; Create draw widget that will display the light color.
    ;
    wColor = WIDGET_DRAW(wColorSwatchBase, XSIZE=20, YSIZE=20, $
        GRAPHICS_LEVEL=2, /EXPOSE_EVENTS, RETAIN=1, $
        UNAME=uname+'_COLOR')

    wRedBase = WIDGET_BASE(wColorCol2Base, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wRedBase, VALUE='Red:')
    wRed = WIDGET_SLIDER(wRedBase, DRAG=KEYWORD_SET(dragEvents), $
        MAXIMUM=255, UNAME=uname+'_RED')
    wGreenBase = WIDGET_BASE(wColorCol2Base, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wGreenBase, VALUE='Green:')
    wGreen = WIDGET_SLIDER(wGreenBase, DRAG=KEYWORD_SET(dragEvents), $
        MAXIMUM=255, UNAME=uname+'_GREEN')
    wBlueBase = WIDGET_BASE(wColorCol2Base, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wBlueBase, VALUE='Blue:')
    wBlue = WIDGET_SLIDER(wBlueBase, DRAG=KEYWORD_SET(dragEvents), $
        MAXIMUM=255, UNAME=uname+'_BLUE')

    wIntensityBase = WIDGET_BASE(wSubBase, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wIntensityBase, VALUE='Intensity:')
    wIntensitySlider = CW_FSLIDER(wIntensityBase, $
        MINIMUM=0.0, MAXIMUM=1.0, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_INTENSITYSLIDER')

    wSpotBase = WIDGET_BASE(wSubBase, /COLUMN, XPAD=0, YPAD=0)

    wConeAngleBase = WIDGET_BASE(wSpotBase, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wConeAngleBase, VALUE='Cone Angle:')
    wConeAngle = WIDGET_SLIDER(wConeAngleBase, MIN=0, $
        MAX=180, UNAME=uname+'_CONEANGLE')

    wFocusBase = WIDGET_BASE(wSpotBase, /ROW, XPAD=0, YPAD=0)
    void = WIDGET_LABEL(wFocusBase, VALUE='Focus:')
    wFocus = CW_FSLIDER(wFocusBase, $
        MINIMUM=0, MAXIMUM=128.0, /EDIT, DRAG=KEYWORD_SET(dragEvents), $
        UNAME=uname+'_FOCUS')

    ; Dark on light color scheme
;    backgroundColor = [255,255,255]
;    graphicColor = [255,255,255]
;    locIndicatorColor = [128,128,128]
;    dirIndicatorColor = [128,128,128]
;    dirIndicatorBottom = [128,128,128]
;    lightColor = [255,255,255]

    ; Light on dark color scheme
    backgroundColor = [0,0,0]
    graphicColor = [255,255,255]
    locIndicatorColor = [255,255,0]
    dirIndicatorColor = [255,0,255]
    dirIndicatorBottom = [255,255,0]
    lightColor = [255,255,255]

    oDirectionView = OBJ_NEW('IDLgrView', COLOR=backgroundColor)

    oLightModel = OBJ_NEW('IDLgrModel')
    oDirectionView->Add, oLightModel

    oDirCtmModel = OBJ_NEW('IDLgrModel')
    oDirectionView->Add, oDirCtmModel

    oDirRotModel = OBJ_NEW('IDLgrModel')
    oDirCtmModel->Add, oDirRotModel

    oDirectionModel = OBJ_NEW('IDLgrModel')
    oDirRotModel->Add, oDirectionModel

    oAmbientLight = OBJ_NEW('IDLgrLight', TYPE=0, COLOR=lightColor, $
        INTENSITY=0.5)
    oLightModel->Add, oAmbientLight

    oDirectionLight = OBJ_NEW('IDLgrLight', TYPE=2, LOCATION=[1,-1,10], $
        COLOR=lightColor)
    oLightModel->Add, oDirectionLight

    oDirectionLight2 = OBJ_NEW('IDLgrLight', TYPE=2, LOCATION=[-2,2,2], $
        COLOR=lightColor)
    oLightModel->Add, oDirectionLight2

    oDirIndicator = OBJ_NEW('IDLgrPolygon', COLOR=dirIndicatorColor, $
        BOTTOM=dirIndicatorBottom, STYLE=2, SHADING=1)
    oDirectionModel->Add, oDirIndicator

    oLocationView = OBJ_NEW('IDLgrView', DEPTH_CUE=[-1,4], $
        COLOR=backgroundColor)

    oLocCtmModel = OBJ_NEW('IDLgrModel')
    oLocationView->Add, oLocCtmModel

    oLocationModel = OBJ_NEW('IDLgrModel')
    oLocCtmModel->Add, oLocationModel

    orbRadius = .03
    oLocIndicator = OBJ_NEW('orb', COLOR=locIndicatorColor, RAD=orbRadius)

    oLocationModel->Add, oLocIndicator

    oXTickText = OBJ_NEW('IDlgrText', RECOMPUTE_DIMENSIONS=2, $
        STRINGS=[' ','X',' '])
    oYTickText = OBJ_NEW('IDlgrText', RECOMPUTE_DIMENSIONS=2, $
        STRINGS=[' ','Y',' '])
    oZTickText = OBJ_NEW('IDlgrText', RECOMPUTE_DIMENSIONS=2, $
        STRINGS=[' ','Z',' '])

    oXAxis = OBJ_NEW('IDLgrAxis', 0, RANGE=[0,1], COLOR=graphicColor, /EXACT, $
        TICKLEN=.1, MAJOR=3, MINOR=0, TICKTEXT=oXTickText)
    oLocationModel->Add, oXAxis

    oYAxis = OBJ_NEW('IDLgrAxis', 1, RANGE=[0,1], COLOR=graphicColor, /EXACT, $
        TICKLEN=.1, MAJOR=3, MINOR=0, TICKTEXT=oYTickText)
    oLocationModel->Add, oYAxis

    oZAxis = OBJ_NEW('IDLgrAxis', 2, RANGE=[0,1], COLOR=graphicColor, /EXACT, $
        TICKLEN=.1, MAJOR=3, MINOR=0, TICKTEXT=oZTickText)
    oLocationModel->Add, oZAxis

    ;  Create the cw state.
    ;
    sState = { $
            initialized: 0, $
            modeIndex: modeIndex, $
            backgroundColor: backgroundColor, $
            nLights: nLights, $
            pLightNames: PTR_NEW(lightNames), $
            lightColor: [0,0,0], $
            pLightList: PTR_NEW(oLightUse), $
            oneXPixel: FLTARR(4), $
            oneYPixel: FLTARR(4), $
            firstVector: [0.0,0.0,0.0,0.0], $
            origin: [0.0,0.0,0.0,0.0], $
            initialRotation: IDENTITY(4), $
            xRange: xRange, $
            yRange: yRange, $
            zRange: zRange, $
            xSize: xSize, $
            ySize: ySize, $
            dirDisabled: KEYWORD_SET(dirDisabled), $
            hideDisabled: KEYWORD_SET(hideDisabled), $
            locDisabled: KEYWORD_SET(locDisabled), $
            typeDisabled: KEYWORD_SET(typeDisabled), $
            dragEvents: KEYWORD_SET(dragEvents), $
            oColorWindow: OBJ_NEW(), $
            oLightModel: oLightModel, $
            originalDirection: [0.0,0.0,0.0,1.0], $
            originalLocation: [0.0,0.0,0.0], $
            oXAxis: oXAxis, $
            oYAxis: oYAxis, $
            oZAxis: oZAxis, $
            oXTickText: oXTickText, $
            oYTickText: oYTickText, $
            oZTickText: oZTickText, $
            oDirectionView: oDirectionView, $
            oDirectionModel: oDirectionModel, $
            oDirRotModel: oDirRotModel, $
            oDirCtmModel: oDirCtmModel, $
            oDirIndicator: oDirIndicator, $
            oDirAndLocWindow: OBJ_NEW(), $
            oLocationView: oLocationView, $
            oLocationModel: oLocationModel, $
            oLocCtmModel: oLocCtmModel, $
            oLocIndicator: oLocIndicator, $
            mouseLoc: [0,0], $
            wMainBase: wMainBase, $
            wSpotBase: wSpotBase, $
            wLightList: wLightList, $
            wMap1Base: wMap1Base, $
            wMap2Base: wMap2Base, $
            wMap3Base: wMap3Base, $
            wModeSelect: wModeSelect, $
            wNameText: wNameText, $
            wXLocation: wXLocation,$
            wYLocation: wYLocation, $
            wZLocation: wZLocation, $
            wXDirection: wXDirection, $
            wYDirection: wYDirection, $
            wZDirection: wZDirection, $
            wDirAndLoc: wDirAndLoc, $
            wZDepth: wZDepth, $
            wZDepthBase: wZDepthBase, $
            wColor: wColor, $
            wRed: wRed, $
            wGreen: wGreen, $
            wBlue: wBlue, $
            wTypeList: wTypeList, $
            wIntensitySlider: wIntensitySlider, $
            wFocus: wFocus, $
            wConeAngle: wConeAngle, $
            wHideCheckbox: wHideCheckbox $
        }

    ;  Store state info in child of base.
    ;
    WIDGET_CONTROL, WIDGET_INFO(wLightEditorBase, /CHILD), $
        SET_UVALUE=sState, /NO_COPY

    ;  Return the base.
    ;
    RETURN, wLightEditorBase

end

; -----------------------------------------------------------------------------
