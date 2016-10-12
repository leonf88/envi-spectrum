; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislineprofile__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisLineProfile
;
; PURPOSE:
;    The IDLitVisLineProfile class implements a a line profile visualization
;    object for the iTools system.  This class is subclassed from
;    IDLitVisPolyline primarily for the purpose of trapping movement and
;    resizing of the line profile so that the line profile plot can be
;    updated to match.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisPolyline
;
;-


;;----------------------------------------------------------------------------
;; IDLitVisLineProfile::Init
;;
;; Purpose:
;;   Initialization routine of the object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   NAME   - The name to associated with this item.
;;
;;   Description - Short string that will describe this object.
;;
;;   All other keywords are passed to the super class
;;
function IDLitVisLineProfile::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisPolyline::Init(NAME="Line Profile", $
                                         COLOR=[255,0,0], $
                                         /MANIPULATOR_TARGET, $
                                         /MAP_INTERPOLATE, $
                                         IMPACTS_RANGE=0, $
                                         ICON='line', $
                                         DESCRIPTION="Line Profile Annotation",$
                                         TYPE=['IDLLINEPROFILE'], $
                                         _EXTRA=_EXTRA)) then $
        return, 0

    ;; The VERTICES parameter is already registered by the superclass.

    ;; Register these "output" parameters to broadcast changes in the line
    ;; to any observers.
    self->RegisterParameter, 'LINE', DESCRIPTION='Line Profile Endpoints', $
        TYPES='IDLARRAY2D'

    ;; Properties
    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisLineProfile::SetProperty, _EXTRA=_extra

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self._plotProfiles = PTR_NEW(/ALLOC)
    
    self->SetPropertyAttribute, ['ARROW_STYLE', 'ARROW_SIZE'], /ADVANCED_ONLY

    RETURN, 1 ; Success
end


;;----------------------------------------------------------------------------
;; IDLitVisLineProfile::Cleanup
;;
;; Purpose:
;;   Cleanup/destrucutor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
pro IDLitVisLineProfile::Cleanup

    compile_opt idl2, hidden


    oTool = self->GetTool()
    if OBJ_VALID(oTool) then begin
        ;; Stop getting notifications from the image.
        ;; The subscription was estabished by the creator of this object and
        ;; only for images.
        oObj = oTool->GetByIdentifier(self._associatedvisualization)
        if OBJ_ISA(oObj, 'IDLITVISIMAGE') then begin
          self->RemoveOnNotifyObserver, self->GetFullIdentifier(), $
              self._associatedvisualization
        endif
    endif

    PTR_FREE, self._plotProfiles

    ;; Cleanup superclass
    self->IDLitVisPolyline::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisLineProfile::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLineProfile::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
    endif
end

;----------------------------------------------------------------------------
;; IDLitVisLineProfile::SetProperty
;;
;; Purpose:
;;   Used to set the property values for properties provided by
;;   this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   ASSOCIATED_VISUALIZATION:  self explanatory
;;
pro IDLitVisLineProfile::SetProperty, $
    ASSOCIATED_VISUALIZATION=associatedvisualization, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

  IF N_ELEMENTS(associatedvisualization) NE 0 THEN BEGIN
    self._associatedVisualization = associatedvisualization
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oObj = oTool->GetByIdentifier(associatedvisualization)

        if (OBJ_VALID(oObj)) then begin
            ; Send notification of data range change to superclass
            ; so that arrow sizes can be set correctly.
            oDS = oObj->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDS)) then begin
                if (oDS->_GetXYZAxisRange(xRange, yRange, zRange, $
                    /NO_TRANSFORM)) then $
                    self->IDLitVisPolyline::OnDataRangeChange, oDS, $
                        xRange, yRange, zRange
            endif
        endif

    endif
  ENDIF

  IF (N_ELEMENTS(_extra) NE 0) THEN $
    self->IDLitVisPolyline::SetProperty, _EXTRA=_extra

END

;----------------------------------------------------------------------------
;; IDLitVisLineProfile::GetProperty
;;
;; Purpose:
;;   Used to get the property values for properties provided by
;;   this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   ASSOCIATED_VISUALIZATION:  self explanatory
;;
pro IDLitVisLineProfile::GetProperty, $
    ASSOCIATED_VISUALIZATION=associatedvisualization, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

  IF ARG_PRESENT(associatedvisualization) NE 0 THEN BEGIN
    associatedvisualization = self._associatedVisualization
  ENDIF

  IF (N_ELEMENTS(_extra) NE 0) THEN $
    self->IDLitVisPolyline::GetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitVisLineProfile::AddPlotProfile
;
; Purpose:
;  Adds a plotprofile vis id to a list, so that the plot profiles
;  can be deleted if this line profile is deleted.
;
pro IDLitVisLineProfile::AddPlotProfile, idVis

    compile_opt idl2, hidden
    *self._plotProfiles = N_ELEMENTS(*self._plotProfiles) eq 0 ? $
        [idVis] : [*self._plotProfiles, idVis]
end

;---------------------------------------------------------------------------
; IDLitVisLineProfile::_encode
;
; Purpose:
;  Utility function for _clipLine.
;
function IDLitVisLineProfile::_encode, pt, rect

    compile_opt idl2, hidden

    code = 0b
    if pt[0] lt rect[0] then code += 1b
    if pt[0] gt rect[1] then code += 2b
    if pt[1] lt rect[2] then code += 4b
    if pt[1] gt rect[3] then code += 8b
    return, code
end

;---------------------------------------------------------------------------
; IDLitVisLineProfile::_clipLine
;
; Purpose:
;  Implementation of Cohen-Sutherland line clipping algorithm
;
; Parameters: (should all be of the same type)
;  p1, p2 - Line end points.  The clipped line is returned in these parameters.
;           The parameters are passed as [x, y].
;  rect - The clipping rectangle, passed in the array:
;         [left, right, bottom, top]
;
; Return Value:
;  Returns 1 if any part of the line is within the clip rect after clipping.
;  Returns 0 if no part of the line is within the clip rect after clipping.
;
function IDLitVisLineProfile::_clipLine, p1, p2, rect

    compile_opt idl2, hidden

    done = 0b
    repeat begin
        ;; Compute clip codes
        code1 = self->_encode(p1, rect)
        code2 = self->_encode(p2, rect)
        ;; trivial accept
        if (code1 or code2) eq 0 then $
            return, 1
        ;; trivial reject
        if (code1 and code2) ne 0 then $
            return, 0
        ;; At least one point is outside
        ;; Swap to ensure that p1 is outside
        swap = 0b
        if code1 eq 0 then begin
            tmp = code1 & code1 = code2 & code2 = tmp
            tmp = p1 & p1 = p2 & p2 = tmp
            swap = 1b
        endif
        ;; Check for vertical
        if p1[0] eq p2[0] then begin
            p1[1] = (p1[1] > rect[2]) < rect[3]
        endif $
        ;; Compute intersection with rect
        else begin
            slope = DOUBLE(p2[1]-p1[1]) / DOUBLE(p2[0]-p1[0])
            if (code1 and 1) ne 0 then begin
                p1[1] = p1[1] + (rect[0] - p1[0]) * slope
                p1[0] = rect[0]
            endif else $
            if (code1 and 2) ne 0 then begin
                p1[1] = p1[1] + (rect[1] - p1[0]) * slope
                p1[0] = rect[1]
            endif else $
            if (code1 and 4) ne 0 then begin
                p1[0] = p1[0] + (rect[2] - p1[1]) / slope
                p1[1] = rect[2]
            endif else $
            if (code1 and 8) ne 0 then begin
                p1[0] = p1[0] + (rect[3] - p1[1]) / slope
                p1[1] = rect[3]
            endif
        endelse
        ;; Swap back to keep the line direction invariant
        if swap then begin
            tmp = code1 & code1 = code2 & code2 = tmp
            tmp = p1 & p1 = p2 & p2 = tmp
        endif
    endrep until done
end


;---------------------------------------------------------------------------
; IDLitVisLineProfile::_clipAndUpdate
;
; Purpose:
;  Utility function for clipping the profile line.
;
function IDLitVisLineProfile::_clipAndUpdate, CONSTRAIN=constrain

    compile_opt idl2, hidden

    ;; Collect points and range to prep for clipping
    pt0 = self._endpoints[*,0]
    pt1 = self._endpoints[*,1]

    ;; Apply current translation to the points for clipping
    self->GetProperty, TRANSFORM=t
    pt0[0,0] += t[3,0]
    pt0[1,0] += t[3,1]
    pt1[0,0] += t[3,0]
    pt1[1,0] += t[3,1]

    rect = [self._XRange[0], self._XRange[1], $
            self._YRange[0], self._YRange[1]]

    ;; Clip to data range
    bVisible = self->_clipLine(pt0, pt1, rect)

    ;; Indicate that the entire line is out of range.
    if KEYWORD_SET(constrain) and ~bVisible then $
        return, 1

    ;; Update the visualization with our clipped line
    endpoints = [[pt0], [pt1]]
    ;; Backout translation (translation is in the TRANSFORM
    ;; property which gets applied during the draw. )
    endpoints[0,0] -= t[3,0]
    endpoints[1,0] -= t[3,1]
    endpoints[0,1] -= t[3,0]
    endpoints[1,1] -= t[3,1]
    oDataObj = self->GetParameter('VERTICES')
    if (OBJ_VALID(oDataObj) && self->CountVertex()) then begin
        self._clippingFlag = 1
        void = oDataObj->SetData(endpoints)
        self._clippingFlag = 0
    endif

   if bVisible then begin
     ;; Update our Line "output" parameter.
     ;; This updates the line profile plot with the
     ;; clipped and translated line.
     line = [[pt0[0], pt0[1]], [pt1[0], pt1[1]]]
     oLine = self->GetParameter('LINE')
     if OBJ_VALID(oLine) then $
       success = oLine->SetData(line)
   endif

   return, bVisible
end

;;----------------------------------------------------------------------------
;; IDLitVisLineProfile::Translate
;;
;; Purpose:
;;   We override this method to allow us to constrain the movement of the
;;   line profile annotation to the image and to update our LINE parameter.
;;
;; Parameters:
;;
;; Keywords:
;;   None.
;;
pro IDLitVisLineProfile::Translate, x, y, z, _EXTRA=_extra

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if ~OBJ_VALID(oTool) then $
        return

    oVis = oTool->GetByIdentifier(self._associatedvisualization)

    ;; If necessary, convert from x/y in dataspace coords
    ;; to our image coords, using any map projections.
    if OBJ_ISA(oVis, 'IDLitVisImage') then begin
        xvec = [0, x]
        yvec = [0, y]
        oDataSpace = self->GetDataspace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace) && $
            oDataSpace->GetXYZRange(xr,yr,zr)) then begin
            ;; Add in the midpoint of the dataspace,
            ;; to ensure that our x/yvec lies within the dataspace range.
            ;; Otherwise, for certain map projections, the point (0,0)
            ;; might not be mappable.
            xvec += 0.5*(xr[0] + xr[1])
            yvec += 0.5*(yr[0] + yr[1])
        endif
        xy = oVis->DataspaceToVis(xvec, yvec)
        x = xy[0,1] - xy[0,0]
        y = xy[1,1] - xy[1,0]
    endif

    ;; The line profile endpoint vertices are not directly modified by
    ;; a Translate operation.  Instead, we let the Model TRANSFORM handle
    ;; the visual translation.
    ;; But to constrain the movement, we need to fetch the current translation
    ;; from the TRANSFORM property and see if requested additional translation
    ;; (from the x, y parms) keeps the line profile within the parent's range.
    ;; Compute the combined translation.
    self->getProperty, TRANSFORM=t
    xt = t[3,0] + x
    yt = t[3,1] + y

    ;; Compute the extents of the line with combined translation applied.
    lineXMax = MAX(self._endpoints[0,*] + xt, MIN=lineXMin)
    lineYMax = MAX(self._endpoints[1,*] + yt, MIN=lineYMin)

    ;; Trim requested translation to constrain to parent object
    if lineXMin lt self._XRange[0] then x = x + (self._XRange[0]-lineXMin)
    if lineXMax gt self._XRange[1] then x = x + (self._XRange[1]-lineXMax)
    if lineYMin lt self._YRange[0] then y = y + (self._YRange[0]-lineYMin)
    if lineYMax gt self._YRange[1] then y = y + (self._YRange[1]-lineYMax)

    ;; Go ahead and update our vis transform with the combined and constrained translation.
    self->IDLitVisPolyline::Translate, x, y, z

    ;; This may seem redundant, but we need to clip in case the user had moved
    ;; one of the endpoints out of the parent's range.
    ;; Plus, we have to update the LINE parameter anyway.
    void = self->_clipAndUpdate(/CONSTRAIN)

end

;---------------------------------------------------------------------------
; IDLitVisLineProfile::AddVertex
;
; Purpose:
;    Used to set the location of a vertex.
;
; Parameters:
;   x   - X location
;   y   - Y location
;   z   - Z location
;
; Keywords:
;  WINDOW    - If set, the provided values are in Window coordinates
;              and need to be converted into visualization coords.
;
pro IDLitVisLineProfile::AddVertex, xyzIn, WINDOW=WINDOW, INITIAL=INITIAL

    compile_opt hidden, idl2

    xyz = xyzIn  ; make a copy

    if KEYWORD_SET(window) then begin
        self->WindowToVis, xyz, xyz

        ; If necessary, pass thru the map projection.
        oTool = self->GetTool()
        if ~OBJ_VALID(oTool) then $
            return
        oVis = oTool->GetByIdentifier(self._associatedvisualization)
        if (OBJ_ISA(oVis, 'IDLitVisImage')) then begin
            xyz[0:1,*] = oVis->DataspaceToVis(xyz[0,*], xyz[1,*])
        endif
    endif

    self->_IDLitVisVertex::AddVertex, xyz, INITIAL=INITIAL

end


;---------------------------------------------------------------------------
; IDLitVisLineProfile::GetVertex
;
; Purpose:
;   Used to retrieve the location of a data point.
;
; Parameters:
;   Index: A scalar or vector giving the indices of the vertices to return.
;
; Keywords:
;  WINDOW    - If set, the values should be converted from
;              visualization coordinates to Window coords.
;
function IDLitVisLineProfile::GetVertex, index, WINDOW=WINDOW

    compile_opt hidden, idl2

    xyz = self->_IDLitVisVertex::GetVertex(index)

    if (~KEYWORD_SET(window) || N_ELEMENTS(xyz) le 1) then $
        return, xyz

    ; If necessary, pass thru the map projection.
    oTool = self->GetTool()
    if ~OBJ_VALID(oTool) then $
        return, xyz
    oVis = oTool->GetByIdentifier(self._associatedvisualization)
    if (OBJ_ISA(oVis, 'IDLitVisImage')) then begin
        xyz[0:1,*] = oVis->VisToDataspace(xyz[0,*], xyz[1,*])
    endif

    self->_IDLitVisualization::VisToWindow, xyz, dataOut

    return, dataOut
end


;---------------------------------------------------------------------------
; IDLitVisLineProfile::MoveVertex
;
; Purpose:
;    Used to move the location of a data vertex.
;
; Parameters:
;   XYZ: An array of dimensions (2,n) or (3,n) giving the vertices.
;
; Keywords:
;  INDEX:   Set this keyword to a scalar or vector representing the
;    indices of the of the vertices to be moved.  By default, the final
;    vertex is moved.
;
;  WINDOW    - If set, the provided values are in Window coordinates
;              and need to be  converted into visualization coords.
;
pro IDLitVisLineProfile::MoveVertex, xyzIn, INDEX=index, WINDOW=WINDOW

    compile_opt idl2, hidden

    xyz = xyzIn  ; make a copy

    if KEYWORD_SET(window) then begin
        self->WindowToVis, xyz, xyz

        ; If necessary, pass thru the map projection.
        oTool = self->GetTool()
        if ~OBJ_VALID(oTool) then $
            return
        oVis = oTool->GetByIdentifier(self._associatedvisualization)
        if (OBJ_ISA(oVis, 'IDLitVisImage')) then begin
            xyz[0:1,*] = oVis->DataspaceToVis(xyz[0,*], xyz[1,*])
            if (MIN(FINITE(xyz)) eq 0) then $
                return
        endif
    endif

    self->_IDLitVisVertex::MoveVertex, xyz, INDEX=index

end


;;----------------------------------------------------------------------------
;; IDLitVisLineProfile::OnDataChangeUpdate
;;
;; Purpose:
;;   We hook this method to be informed when the line is changed.
;;   For example, when the user resizes the line with the line
;;   manipulator.
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
pro IDLitVisLineProfile::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmName) of

    '<PARAMETER SET>': begin
        oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
        for i=0,nParam-1 do begin
            if (~paramNames[i]) then $
                continue
            oData = oSubject->GetByName(paramNames[i])
            if ~OBJ_VALID(oData) then $
                continue
            self->IDLitVisLineProfile::OnDataChangeUpdate, $
                oData, paramNames[i]
        endfor
        end

    'VERTICES' : BEGIN
        ;; We monitor any changes in the DataRange vis the OnDataRangeChange
        ;; method.  But there's no really easy way to get the initial
        ;; data range, which we need for clipping the line.  So, just
        ;; query it here.
        oDataSpace = self->GetDataspace(/UNNORMALIZED)
        if OBJ_VALID(oDataSpace) then begin
            success = oDataSpace->GetXYZRange(x,y,z)
            if success then begin
                self._XRange = x
                self._YRange = y
            endif
        endif

        ;; This parameter is changed as the line is being dragged
        ;; either during creation or if it is being resized by the user.
        ;; The data should always be FLOAT[3,2].
        ;; First, pass the vertex info to the superclass.
        self->IDLitVisPolyline::OnDataChangeUpdate, oSubject, parmName

        ;; We need to save the line vertex data so we can use it as the
        ;; "original" line, while clipping the line for display.
        ;; But we don't want to save the data if we are setting this parm
        ;; with our own clipped version of the line.

        if self._clippingFlag eq 0 then BEGIN
          success = oSubject->GetData(endpoints)
          endpoints = DOUBLE(endpoints)
          endpoints[2,*] = 0
          pt0 = endpoints[*,0]
          pt1 = endpoints[*,1]
          rect = [self._XRange[0], self._XRange[1], $
                  self._YRange[0], self._YRange[1]]
          bVisible = self->_clipLine(pt0, pt1, rect)
          if bVisible then begin
            self._endpoints = [[pt0], [pt1]]

            ;; Update our Line "output" parameter.
            line = [[pt0[0], pt0[1]], [pt1[0], pt1[1]]]
            oLine = self->GetParameter('LINE')
            if OBJ_VALID(oLine) then $
              success = oLine->SetData(line)
          endif
        endif

      END

    'LINE': begin
        ;; This is an "output" parameter for this class.
        ;; So, we don't need to respond to any changes.
    end

    'LINE3D': begin
        ;; This is an "output" parameter for this class.
        ;; So, we don't need to respond to any changes.
    end

    else: ; ignore unknown parameters
    endcase

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLineProfile::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisLineProfile::]OnDataRangeChange, oSubject, $
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
pro IDLitVisLineProfile::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ;; Update the data range
    self._XRange = XRange
    self._YRange = YRange

    ;; Clip to data range
    bVisible = self->_clipAndUpdate()

    ;; Hide if line is outside of data range.
    self->SetProperty, HIDE=1-bVisible
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisLineProfile::OnNotify
;
; PURPOSE:
;   This procedure method handles notification of changes from a Subject
;   we have subscribed to.
;   In this case, we are watching the image position and pixel size so
;   that we can position the line profile correctly on the image.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisLineProfile::]OnDataChangeUpdate, strItem, strMsg, strUser
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro IDLitVisLineProfile::OnNotify, strItem, strMsg, strUser

compile_opt idl2, hidden

    oTool=self->GetTool()
    if ~OBJ_VALID(oTool) then return
    oObj = oTool->GetByIdentifier(strItem)
    if OBJ_ISA(oObj, 'IDLITVISIMAGE') and $
       STRUPCASE(strMsg) eq 'SETPROPERTY' then begin
      switch STRUPCASE(strUser[0]) of
        "XORIGIN":
        "YORIGIN":
        "PIXEL_XSIZE":
        "PIXEL_YSIZE": begin
            bVisible = self->_clipAndUpdate()
            ;; Hide if line is outside of data range.
            self->SetProperty, HIDE=1-bVisible
        end
        else:
      endswitch
    endif
    if STRUPCASE(strMsg) eq 'DELETE' then begin
        ;; Destroy any plot profile visualizations associated with this
        ;; line profile.
        for i=0, N_ELEMENTS(*self._plotProfiles)-1 do begin
            oPlotProfile = oTool->GetByIdentifier((*self._plotProfiles)[i])
            if OBJ_VALID(oPlotProfile) then begin
                oPlotProfile->GetProperty, _PARENT=oParent
                oParent->Remove, oPlotProfile
                OBJ_DESTROY, oPlotProfile
            endif
        endfor
    endif
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisLineProfile__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLineProfile object.
;
; NOTES:
; - endpoints stores the line according to how the user defines it -
;   both by drawing/moving the endpoints and any translations.
;   This line is clipped by the dataspace range and the clipped line
;   is the line actually stored in the VisPolyline.
;
; - clippingFlag prevents this object from updating _endpoints with
;   clipped data.
;-
pro IDLitVisLineProfile__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLineProfile,       $
               inherits IDLitVisPolyline, $
               _endpoints: DBLARR(3,2),   $
               _clippingFlag: 0b,         $
               _XRange: DBLARR(2),        $
               _YRange: DBLARR(2),        $
               _plotProfiles: PTR_NEW(),  $
               _associatedVisualization: '' $
             }
end
