; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegend__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;    The IDLitVisLegend class is the component wrapper for the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;   CT, Dec 2006: Obsolete LEGEND_LOCATION property.
;

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLegend::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisLegend'[, Z[, X, Y]])
;
; INPUTS:
;   Z: (see IDLgrImage)
;   X:
;   Y:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrImage
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;   Create just like an IDLgrImage.
;
;
;
;-
function IDLitVisLegend::Init, $
                       NAME=NAME, $
                       DESCRIPTION=DESCRIPTION, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~keyword_set(name)) then $
        name ="Legend"
    if (~keyword_set(DESCRIPTION)) then $
        DESCRIPTION ="A Legend Visualization"

    ; Initialize superclass
    success = self->IDLitVisualization::Init( $
        /REGISTER_PROPERTIES, $
        NAME=NAME, $
        TYPE="IDLLEGEND", $
        ICON='legend', $
        IMPACTS_RANGE=0, $   ; should not affect DataSpace range
        DESCRIPTION=DESCRIPTION, $
        /MANIPULATOR_TARGET, $
        SELECTION_PAD=10, $ ; pixels. allows easier de-selection
        _EXTRA=_extra)

    if (~success) then $
        return, 0

    ; Add in our special manipulator visual.  This allows translation
    ; but doesn't allow scaling.  We don't want to allow scaling because
    ; it causes problems with the autoposition feature.  Translation is
    ; enabled, however.  For the user's interactive translation to "stick"
    ; they need to disable autoposition.
    self->SetDefaultSelectionVisual, $
        OBJ_NEW('IDLitManipVisSelectBox', /HIDE, COLOR=!COLOR.DODGER_BLUE)

    self._oPolygon = OBJ_NEW('IDLitVisPolygon', $
                             SELECT_TARGET=0, $
                             /IMPACTS_RANGE, $
                             /private)
    self->IDLitVisualization::Add, self._oPolygon, /AGGREGATE

    ; Shadow
    shadow = BYTARR(256,256)+255b
    width = 8
    ;; get fading for corners
    corner = fix(256*((hanning(2*width, 2*width))[1:width, 1:width])^2)
    edge = corner[*,-1]
    shadow[*,0:width-1] = edge ## REPLICATE(1,256)
    shadow[*,256-width:255] = REVERSE(edge ## REPLICATE(1,256),2)
    shadow[0:width-1, *] = REVERSE(edge # REPLICATE(1,256),2)
    shadow[256-width:255,*] = REVERSE(edge # REPLICATE(1,256),1)
    shadow[0:width-1,0:width-1] = ROTATE(corner, 0)
    shadow[0:width-1,256-width:255] = ROTATE(corner, 3)
    shadow[256-width:255,256-width:255] = ROTATE(corner, 2)
    shadow[256-width:255,0:width-1] = ROTATE(corner, 1)
    imagePlane = BYTARR(256,256)
    imageData = [[[imagePlane]],[[imagePlane]],[[imagePlane]],[[shadow]]]
    oShadow = OBJ_NEW('IDLgrImage', transpose(imageData))
    
    self._oShadow = OBJ_NEW('IDLitVisPolygon', $
                            TEXTURE_MAP=oShadow, $
                            TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]], $
                            TEXTURE_INTERP=2, $
                            __DATA=[[0,0],[1,0],[1,1],[0,1]], $
                            LINESTYLE=6, $
                            SELECT_TARGET=0, $
                            HIDE=1, $
                            /PRIVATE)
    self->IDLitVisualization::Add, self._oShadow, POSITION=0

    self->Set3D, 0, /ALWAYS

    self._oFont = Obj_New('IDLitFont')

    self->IDLitVisLegend::_RegisterProperties

    ;; Register the parameters we are using for data
    self->RegisterParameter, 'VISUALIZATIONS', DESCRIPTION='Visualizations ', $
                            /INPUT, TYPES='VISUALIZATION',/optarget
    self._sampleWidth = 0.15d
    self._horizSpacing = 0.02d
    self._vertSpacing = 0.02d
    self._horizAlignment = 0.0d
    self._vertAlignment = 1.0d
    self._orientation = 0       ;vertical
    self._textColor = PTR_NEW([0L,0,0])

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisLegend::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; Purpose:
;    Cleanup this component
;
pro IDLitVisLegend::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oPolygon
    OBJ_DESTROY, self._oShadow
    OBJ_DESTROY, self._oFont

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    if (nItems gt 0) then OBJ_DESTROY, oItems

    PTR_FREE, self._textColor

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
pro IDLitVisLegend::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Must be registered to be able to set from CreateVisualization.
        self->RegisterProperty, 'VIS_TARGET', NAME='Visualization Target',$
            USERDEF="Visualization Target", $
            DESCRIPTION="Visualization Target", /HIDE, /ADVANCED_ONLY

        ; Must be registered to be able to set from CreateVisualization.
        self->RegisterProperty, 'Location',$
            USERDEF="Location", $
            DESCRIPTION="Location", /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'ORIENTATION', $
            ENUMLIST=['Column', 'Row'], $
            DESCRIPTION='Orientation', $
            NAME='Layout'

        self->RegisterProperty, 'SAMPLE_WIDTH', /FLOAT, $
            DESCRIPTION='Legend sample width', $
            NAME='Sample width', $
            VALID_RANGE=[0, 0.5d, .01d], /ADVANCED_ONLY

        self->RegisterProperty, 'HORIZONTAL_SPACING', /FLOAT, $
            DESCRIPTION='Legend horizontal spacing', $
            NAME='Horizontal spacing', $
            VALID_RANGE=[0, 0.25d, .01d], /ADVANCED_ONLY

        self->RegisterProperty, 'VERTICAL_SPACING', /FLOAT, $
            DESCRIPTION='Legend vertical spacing', $
            NAME='Vertical spacing', $
            VALID_RANGE=[0, 0.25d, .01d], /ADVANCED_ONLY

        self->RegisterProperty, 'TEXT_COLOR', /COLOR, $
            DESCRIPTION='Item Text Color', $
            NAME='Text color'

        self._oPolygon->SetPropertyAttribute, $
            ['BOTTOM', 'USE_BOTTOM_COLOR'], /HIDE
    endif

    ; The LEGEND_LOCATION property was made obsolete in IDL64.
    if (~registerAll && updateFromVersion lt 640) then begin
        self->SetPropertyAttribute, 'LEGEND_LOCATION', /HIDE
    endif

    if (registerAll || updateFromVersion lt 640) then begin
        self->Aggregate, self._oFont
    endif

    self->SetPropertyAttribute, ['FILL_BACKGROUND', 'FILL_COLOR'], $
      /ADVANCED_ONLY

end

;----------------------------------------------------------------------------
; IDLitVisLegend::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegend::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::Restore on each aggregated ItVis object
    ; to ensure any new properties are registered.  Also
    ; call its UpdateComponentVersion method so that this
    ; will not be attempted later
    if (OBJ_VALID(self._oPolygon)) then begin
        self._oPolygon->Restore
        self._oPolygon->UpdateComponentVersion
    endif

    if (self.idlitcomponentversion lt 640) then begin
        ; Prior to IDL64, the legend items went upward in Y. In IDL64, they
        ; go downward in Y. So shift the old legend up by the height.
        if (self->GetXYZRange(xr, yr, zr)) then begin
            self->Translate, 0, yr[1]-yr[0], 0, /PREMULTIPLY
        endif
        self._oFont = Obj_New('IDLitFont', FONT_INDEX=self._fontIndex, $
            FONT_STYLE=self._fontStyle, FONT_SIZE=self._fontSize)
    endif

    ; Register new properties.
    self->IDLitVisLegend::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

end

;----------------------------------------------------------------------------
PRO IDLitVisLegend::RecomputeLayout

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)

    ; if last item deleted, preserve size of legend and
    ; simply return.
    ; consider destroying whole legend here, but at present
    ; this cannot be supported with undo/redo.
    if (~nItems) then return

    xMax = self._horizSpacing ; in case no items in legend
    yMin = -self._vertSpacing


    ; Leave a gap between the border and the items.
    xOffset = self._horizSpacing
    yOffset = 0
    prevWidth = 0

    haveItem = 0b

    for i=0,nItems-1 do begin
        oItems[i]->GetProperty, ITEM_RANGE=itemRange, HIDE=hide

        ; Don't include hidden items in calculations
        if (hide) then continue

        ; layout is: space,sampleWidth,space,Text,space
        ; item is responsible for sampleWidth, middle space and text positioning
        ; legend is responsible for leading and trailing horizontal spacing as well as
        ; vertical spacing.

        curWidth = itemRange[0] + self._horizSpacing
        curHeight = itemRange[1] + self._vertSpacing

        if (self._orientation) then begin
            ; For horizontal (row) layout, move to the right of previous item.
            xOffset += prevWidth
            prevWidth = curWidth + self._horizSpacing  ; save for next item
            ; Always shift the current item down by its height.
            yOffset = -curHeight
        endif else begin
            ; For vertical (column) layout, move to the bottom of current item.
            yOffset -= curHeight
        endelse

        oItems[i]->Reset
        ; Push the legend items a little closer to the viewer.
        ; This helps vector output sort the primitives correctly.
        oItems[i]->Translate, xOffset, yOffset, 0.01d

        ; For the border, find the maximum X and minimum Y.
        xMax >= xOffset + curWidth
        yMin <= yOffset - self._vertSpacing

        haveItem = 1b
    endfor

    ; Bail if all hidden, so we don't end up with a tiny little box.
    if (~haveItem) then return

    ; Draw the border.
    xMin = 0
    yMax = 0
    self._oPolygon->SetProperty, $
        DATA=[[xMin,yMin], [xMax,yMin], [xMax,yMax], [xMin,yMax], [xMin,yMin]]
    ; Draw the shadow
    self._oShadow->GetProperty, HIDE=hide
    if (~hide) then begin
      xoffset = 0.015
      yoffset = 0.015    
      self._oShadow->SetProperty, $
          __DATA=[[xMin+xoffset,yMin-yoffset], [xMax+xoffset,yMin-yoffset], $
                [xMax+xoffset,yMax-yoffset], [xMin+xoffset,yMax-yoffset]]
    endif                     

    self->UpdateSelectionVisual

end


;----------------------------------------------------------------------------
pro IDLitVisLegend::_SetPosition, HORIZONTAL=hAlignIn, VERTICAL=vAlignIn
  compile_opt idl2, hidden

  hAlign = N_ELEMENTS(hAlignIn) ? hAlignIn : self._horizAlignment
  vAlign = N_ELEMENTS(vAlignIn) ? vAlignIn : self._vertAlignment
  self->IDLgrModel::GetProperty, TRANSFORM=transform
  !NULL = self->GetXYZRange(xx,yy,zz)
  ; Calculate current positions, taking alignment into account
  curX = self._horizAlignment*(xx[1]-xx[0]) + xx[0]
  curY = self._vertAlignment*(yy[1]-yy[0]) + yy[0]
  newLocX = curX - hAlign*(xx[1]-xx[0])
  newLocY = curY + (1-vAlign)*(yy[1]-yy[0])
  self->Reset
  self->Translate, newLocX, newLocY, transform[3,2], $
    /PREMULTIPLY
  ; Save current state
  self._horizAlignment = hAlign
  self._vertAlignment = vAlign
  self._position = [curX, curY]
  
end    
    
;----------------------------------------------------------------------------
pro IDLitVisLegend::Add, oTargets, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitVisualization::Add, oTargets, _EXTRA=_extra

    ; If we add a legend item, recompute the layout.
    if (Max(Obj_Isa(oTargets, 'IDLitVisLegendItem')) eq 1) then $
        self->RecomputeLayout
end


;----------------------------------------------------------------------------
pro IDLitVisLegend::Remove, oTargets, _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_PARAMS() eq 0) then $
        self->IDLitVisualization::Remove, _EXTRA=_extra $
    else $
        self->IDLitVisualization::Remove, oTargets, _EXTRA=_extra

    ; If we remove a legend item, recompute the layout.
    if (Max(Obj_Isa(oTargets, 'IDLitVisLegendItem')) eq 1) then $
        self->RecomputeLayout
end


; Output: oLegendItems
;----------------------------------------------------------------------------
PRO IDLitVisLegend::AddToLegend, oTargets, oNewLegendItems

    compile_opt idl2, hidden

    self->IDLgrModel::SetProperty, /HIDE

    nItems = n_elements(oTargets)

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return

    for i=0, nItems-1 do begin
        if (~OBJ_VALID(oTargets[i])) then continue

        if ((OBJ_ISA(oTargets[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisPlot3D')))  then begin
            if (OBJ_ISA(oTargets[i], 'IDLBarPlot')) then begin
              classname = 'IDLitVisLegendBarPlotItem'
            endif else begin
              classname = 'IDLitVisLegendPlotItem'
            endelse
        endif else if (OBJ_ISA(oTargets[i], 'IDLitVisSurface')) then begin
            classname = 'IDLitVisLegendSurfaceItem'
        endif else if (OBJ_ISA(oTargets[i], 'IDLitVisContour')) then begin
            classname = 'IDLitVisLegendContourItem'
        endif else continue

        idTarget = oTargets[i]->GetFullIdentifier()

        oItem = OBJ_NEW(classname, TOOL=oTool, $
            HORIZONTAL_SPACING=self._horizSpacing, $
            SAMPLE_WIDTH=self._sampleWidth, $
            VERTICAL_SPACING=self._vertSpacing)

        ; Add to our superclass to avoid recomputing the layout.
        self->IDLitVisualization::Add, oItem

        oItem->SetProperty, VIS_TARGET=idTarget

        oNewLegendItems = N_Elements(oNewLegendItems) gt 0 ? $
            [oNewLegendItems, oItem] : oItem

        self->AddOnNotifyObserver, self->GetFullIdentifier(), idTarget
    endfor

    ; For efficiency, pass directly to/from IDLgrModel.
    self->IDLgrModel::SetProperty, HIDE=0
end

;----------------------------------------------------------------------------
; Override the Move to allow keeping the items in front of polygon and
; behind the selection visual.
;
; Recompute the layout so that when "Move to front" or "Move forward"
; is chosen items move up in the legend.  If "Move to back" or "Move
; backward" is chosen items move down in the legend.
; To do this we need to reverse the order of items within the container.
;
PRO IDLitVisLegend::Move, Source, Destination, NO_NOTIFY=NO_NOTIFY

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, COUNT=nItems)

    ; Reverse the position within the container, since we want the
    ; first item to appear at the top.
    Destination = (nItems - 1) - Destination

    ; skip past the IDLitVisPolygon (legend background),
    ; but before the IDLitManipVisSelect in last position.
    Destination = 1 > Destination < (nItems - 2)

    self->_IDLitVisualization::Move, Source, Destination

    self->RecomputeLayout

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegend::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegend::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegend::Init followed by the word "Get"
;      can be retrieved using IDLitVisLegend::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisLegend::GetProperty, $
    LEGEND_LOCATION=legendLocation, $  ; obsolete but keep for backwards compat
    LOCATION=userLocation, $
    TEXT_COLOR=textColor, $
    SAMPLE_WIDTH=sampleWidth, $
    HORIZONTAL_SPACING=horizSpacing, $
    POSITION=position, $
    VERTICAL_SPACING=vertSpacing, $
    VIS_TARGET=visTarget, $
    ORIENTATION=orientation, $
    HORIZONTAL_ALIGNMENT=horizAlign, $
    VERTICAL_ALIGNMENT=vertAlign, $
    SHADOW=shadow, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get my properties
    if (ARG_PRESENT(textColor)) then begin
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        if (nItems gt 0) then begin
            ; this textColor may not be applied to any objects
            ; or it may be applied to some but overridden by some
            ; lower level objects.  return the cached color value
            ; instead of retrieving it from an object
            textColor = *self._textColor
        endif else begin
            textColor = [0b,0b,0b]
        endelse
    endif

    if ARG_PRESENT(sampleWidth) then begin
        sampleWidth = self._sampleWidth
    endif

    if ARG_PRESENT(horizSpacing) then begin
        horizSpacing = self._horizSpacing
    endif

    if ARG_PRESENT(vertSpacing) then begin
        vertSpacing = self._vertSpacing
    endif

    if ARG_PRESENT(horizAlign) then begin
        horizAlign = self._horizAlignment
    endif

    if ARG_PRESENT(vertAlign) then begin
        vertAlign = self._vertAlignment
    endif

    if ARG_PRESENT(orientation) then begin
        orientation = self._orientation
    endif

    if ARG_PRESENT(legendLocation) then begin
        legendLocation = self._location
    endif

    if ARG_PRESENT(shadow) then begin
        self._oShadow->GetProperty, HIDE=hide
        shadow = ~hide
    endif

    if ARG_PRESENT(userLocation) then begin
        self->IDLgrModel::GetProperty, TRANSFORM=transform
        userLocation = transform[[3,7,11]]
    endif

    if ARG_PRESENT(position) then begin
      self->_SetPosition
      newPos = iConvertCoord(self._position[0], self._position[1], $
                             /ANNOTATION, /TO_NORMAL)
      position = newPos[0:1]
    endif
    
    if ARG_PRESENT(visTarget) then begin
        ; Build up the list of all legend item identifiers.
        oItems = self->Get(/ALL, ISA='IDLitVisLegendItem', COUNT=nItems)
        for i=0,nItems-1 do begin
            if (Obj_Valid(oItems[i])) then begin
                oItems[i]->GetProperty, VIS_TARGET=id
                if (id ne '') then $
                    visTarget = (N_Elements(visTarget) gt 1) ? [visTarget, id] : id
            endif
        endfor
        if (N_Elements(visTarget) eq 0) then visTarget = ''
    endif

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegend::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegend::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegend::Init followed by the word "Set"
;      can be set using IDLitVisLegend::SetProperty.
;-

pro IDLitVisLegend::SetProperty,  $
    FONT_INDEX=fontIndex, $
    FONT_NAME=fontName, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    HORIZONTAL_SPACING=horizSpacing, $
    LEGEND_LOCATION=swallow, $  ; obsolete but keep for backwards compat
    LOCATION=userLocation, $
    ORIENTATION=orientation, $
    POSITION=position, $
    SAMPLE_WIDTH=sampleWidth, $
    SHADOW=shadow, $
    TEXT_COLOR=textColor, $
    TEXTPOS=textpos, $
    TRANSPARENCY=transparency, $
    VERTICAL_SPACING=vertSpacing, $
    HORIZONTAL_ALIGNMENT=horizAlign, $
    VERTICAL_ALIGNMENT=vertAlign, $
    VIS_TARGET=visTarget, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    bRecompLayout = 0b
    bRecompPosition = 0b
    modifiedprops = ''

    if (N_ELEMENTS(textColor) gt 0) then begin
        ; cache textColor even if it does not get applied to any objects
        if (ISA(textColor, 'STRING') || N_ELEMENTS(textColor) eq 1) then $
          style_convert, textColor[0], COLOR=textColor
        *self._textColor = textColor
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            ; ask the item to change its own text color
            oItems[i]->SetProperty, TEXT_COLOR=textColor
        endfor
    endif

    if (N_ELEMENTS(fontIndex) gt 0) then begin
        self._oFont->SetProperty, FONT_INDEX=fontIndex
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_INDEX=fontIndex
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontName) gt 0) then begin
        self._oFont->SetProperty, FONT_NAME=fontName
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_NAME=fontName
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontStyle) gt 0) then begin
        self._oFont->SetProperty, FONT_STYLE=fontStyle
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_STYLE=fontStyle
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontSize) gt 0) then begin
        self._oFont->SetProperty, FONT_SIZE=fontSize
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_SIZE=fontSize
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(sampleWidth) gt 0) then begin
        self._sampleWidth = sampleWidth > 0 < 1
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            if (~OBJ_VALID(oItems[i])) then break
            oItems[i]->SetProperty, SAMPLE_WIDTH=sampleWidth
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(horizSpacing) gt 0) then begin
        self._horizSpacing = horizSpacing > 0 < 1
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, HORIZONTAL_SPACING=horizSpacing
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(vertSpacing) gt 0) then begin
        ; some but not all items need to be updated for vertical spacing
        self._vertSpacing = vertSpacing > 0 < 1
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, VERTICAL_SPACING=vertSpacing
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(horizAlign) eq 1) then begin
        if (ISA(horizAlign, 'STRING')) then begin
          case STRUPCASE(horizAlign) of
            'CENTER' : horizAlign = 0.5
            'RIGHT' : horizAlign = 1.0
            else : horizAlign = 0.0
          endcase
        endif
        if (horizAlign ne self._horizAlignment) then begin
          hAlign = horizAlign > 0.0 < 1.0
          bRecompPosition = 1b
        endif
    endif

    if (N_ELEMENTS(vertAlign) eq 1) then begin
        if (ISA(vertAlign, 'STRING')) then begin
          case STRUPCASE(vertAlign) of
            'CENTER' : vertAlign = 0.5
            'BOTTOM' : vertAlign = 0.0
            else : vertAlign = 1.0
          endcase
        endif
        if (vertAlign ne self._vertAlignment) then begin
          vAlign = vertAlign > 0.0 < 1.0
          bRecompPosition = 1b
        endif
    endif

    ; Flip the orientation.
    if (N_ELEMENTS(orientation) eq 1) then begin
        if (KEYWORD_SET(orientation) ne self._orientation) then begin
            self._orientation = KEYWORD_SET(orientation)
            bRecompLayout = 1b
        endif
    endif

    if (N_ELEMENTS(position) ge 2) then begin
      newLoc = iConvertCoord(position[0],position[1],/NORMAL,/TO_ANNOTATION)
      userLocation = newLoc[0:1]
    endif

    nLoc = N_ELEMENTS(userLocation)
    if (nLoc ge 2) then begin
        self._position = userLocation[0:1]
        !NULL = self->GetXYZRange(xx,yy,zz)
        newLocX = self._position[0] - self._horizAlignment*(xx[1]-xx[0])
        newLocY = self._position[1] + (1-self._vertAlignment)*(yy[1]-yy[0])
        self->Reset
        self->Translate, newLocX, newLocY, $
          (nLoc ge 3) ? userLocation[2] : 0.5d, /PREMULTIPLY
    endif

    if (N_ELEMENTS(visTarget) gt 0) then begin
        oTool = self->GetTool()
        if (Obj_Valid(oTool)) then begin
        nVis = N_Elements(visTarget)
        for i=0,nVis-1 do begin
            oVis = oTool->GetByIdentifier(visTarget[i])
            if (Obj_Valid(oVis)) then begin
                oTarget = (N_Elements(oTarget) gt 0) ? [oTarget, oVis] : oVis
            endif
        endfor
        if (N_Elements(oTarget) gt 0) then self->AddToLegend, oTarget
        endif
    endif

    if (N_ELEMENTS(shadow) ne 0) then begin
      self._oShadow->SetProperty, HIDE=(~KEYWORD_SET(shadow))
    endif
    
    if (N_ELEMENTS(transparency) ne 0) then begin
      self._oPolygon->SetProperty, TRANSPARENCY=transparency
      self._oShadow->SetProperty, TRANSPARENCY=(transparency*0.4+80) < 100
    endif
    
    ; Set superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

    if (bRecompLayout) then self->RecomputeLayout
    if (bRecompLayout || bRecompPosition) then $
      self->_SetPosition, HORIZONTAL=hAlign, VERTICAL=vAlign

end


;----------------------------------------------------------------------------
function IDLitVisLegend::GetHitVisualization, oSubHitList

    compile_opt idl2, hidden

    oReturn=OBJ_NEW()
    if (N_ELEMENTS(oSubHitList) ge 2) then begin
        if (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendPlotItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrPolyline') || $
            (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendContourItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrContour')) || $
            (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendSurfaceItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrSurface'))) then begin
            oVis = oSubHitList[0]->GetVis()
            return, oVis
        endif
    endif

    return, self->_IDLitVisualization::GetHitVisualization(oSubHitList)

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
pro IDLitVisLegend::OnNotify, strItem, StrMsg, strUser

    compile_opt idl2, hidden

    case StrMsg of

        "DELETE": begin
            oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
            for i=0, nItems-1 do begin
                if (~OBJ_ISA(oItems[i], 'IDLitVisLegendItem')) then continue
                oVis = oItems[i]->GetVis()
                oItems[i]->IDLitComponent::GetProperty, $
                    IDENTIFIER=identifier
                self->RemoveOnNotifyObserver, $
                    strItem + '/' + identifier, $
                    oVis->GetFullIdentifier()
            endfor
            end

        "UNDELETE": begin
            oTool = self->GetTool()
            oItem = oTool->GetByIdentifier(strItem)
            self->AddToLegend, oItem

            end

        else:

    endcase

end

;---------------------------------------------------------------------------
; IDLitVisLegend::OnViewZoom
;
; Purpose:
;   This procedure method handles notification that the view zoom factor
;   has changed
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom factor change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewZoom: The new zoom factor for the view.
;
pro IDLitVisLegend::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    if (~nItems) then $
        return

    for i=0,nItems-1 do begin
        ; Check if view zoom factor has changed.  If so, update the font.
        oItems[i]->GetProperty, VIEW_ZOOM=fontViewZoom

        if (fontViewZoom ne viewZoom) then $
            oItems[i]->SetProperty, VIEW_ZOOM=viewZoom

        oItems[i]->RecomputeLayout
    endfor
end

;---------------------------------------------------------------------------
; IDLitVisLegend::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport has
;   changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     width and height of the viewport (in pixels).
;
;   normViewDims: A 2-element vector, [w,h], representing the new
;     width and height of the visibile view (normalized relative to
;     the virtual canvas).
;
pro IDLitVisLegend::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    if (~nItems) then $
        return

    if (OBJ_VALID(oDestination)) then $
        oDestination->GetProperty, CURRENT_ZOOM=zoomFactor $
    else $
        zoomFactor = 1.0

    normFactor = MIN(normViewDims)

    for i=0,nItems-1 do begin
        oItems[i]->GetProperty, FONT_ZOOM=fontZoom, FONT_NORM=fontNorm

        if ((fontZoom ne zoomFactor) || $
            (fontNorm ne normFactor)) then $
            oItems[i]->SetProperty, FONT_ZOOM=zoomFactor, FONT_NORM=normFactor

        ; If zoom factor was not the source of the change, then recompute
        ; layout.
        if (fontZoom eq zoomFactor) then $
            oItems[i]->RecomputeLayout
    endfor
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegend__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegend object.
;
;-
pro IDLitVisLegend__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegend,           $
        inherits IDLitVisualization, $
        _oPolygon: OBJ_NEW(),        $
        _oShadow: OBJ_NEW(), $
        _textColor: PTR_NEW(), $
        _oFont: Obj_New(), $
        _location: 0L,  $  ; obsoleted in IDL64, keep for backwards compat
        _orientation: 0L,        $
        _sampleWidth:0.0d, $
        _fontIndex: 0L, $  ; obsoleted in IDL64, keep for backwards compat
        _fontStyle: 0L, $  ; obsoleted in IDL64, keep for backwards compat
        _fontSize: 0L, $   ; obsoleted in IDL64, keep for backwards compat
        _horizSpacing:0.0d, $
        _vertSpacing:0.0d, $
        _position: [0.0d, 0.0d], $
        _horizAlignment:0.0d, $
        _vertAlignment:0.0d $
    }
end
