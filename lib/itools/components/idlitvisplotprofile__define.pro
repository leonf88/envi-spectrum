; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisplotprofile__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisPlotProfile
;
; PURPOSE:
;    The IDLitVisPlotProfile class implements a plot profile visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisPlot
;
;-


;;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::Init
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
function IDLitVisPlotProfile::Init, $
    NAME=name, $
    DESCRIPTION=description, $
    HELP=help, $
    ICON=icon, $
    TOOL=tool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (not self->IDLitVisPlot::Init( $
        NAME=keyword_set(name) ? NAME : "Plot Profile", $
        TYPE="IDLPLOT PROFILE", $
        HELP=help, $
        ICON=icon, $
        TOOL=tool, $
        DESCRIPTION=keyword_set(DESCRIPTION) ? $
            DESCRIPTION : "Plot Profile Visualization",$
        _EXTRA=_EXTRA)) then $
        return, 0

    ;; Register Parms
    self->RegisterParameter, 'IMAGE', DESCRIPTION='Image Data', $
        /INPUT, TYPES='IDLARRAY2D'
    self->RegisterParameter, 'LINE', DESCRIPTION='Line Endpoints', $
        /INPUT, TYPES='IDLARRAY2D'
    self->RegisterParameter, 'LINE3D', DESCRIPTION='Line 3D points', $
        /INPUT, TYPES='IDLARRAY2D'

    ;; Note that these parms are already registered by IDLitVisPlot.
    ;; Fix them so they are not INPUT and are OUTPUT.
    self->SetParameterAttribute, ['X', 'Y', 'VERTICES', 'PALETTE'], $
        INPUT=0, OUTPUT=1

    self->SetPropertyAttribute, ['SYMBOL', 'SYM_SIZE', 'SYM_COLOR'], $
      /ADVANCED_ONLY

    ;; Properties
    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisPlot::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::Cleanup
;;
;; Purpose:
;;   Cleanup/destructor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
pro IDLitVisPlotProfile::Cleanup
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

    ;; Cleanup superclass
    self->IDLitVisPlot::Cleanup
end

;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::SetProperty
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
pro IDLitVisPlotProfile::SetProperty, $
                       ASSOCIATED_VISUALIZATION= $
                       associatedvisualization, $
                       LINE_PROFILE=lineProfile, $
                       _REF_EXTRA=_extra

  compile_opt idl2, hidden

  IF N_ELEMENTS(associatedvisualization) NE 0 THEN BEGIN
      self._associatedVisualization = associatedvisualization
  ENDIF

  IF N_ELEMENTS(lineProfile) NE 0 THEN BEGIN
      self._lineProfile = lineProfile
  ENDIF

  IF (N_ELEMENTS(_extra) NE 0) THEN $
    self->IDLitVisPlot::SetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::GetProperty
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
pro IDLitVisPlotProfile::GetProperty, $
                       ASSOCIATED_VISUALIZATION= $
                       associatedvisualization, $
                       LINE_PROFILE=lineProfile, $
                       _REF_EXTRA=_extra

  compile_opt idl2, hidden

  IF ARG_PRESENT(associatedvisualization) NE 0 THEN BEGIN
      associatedvisualization = self._associatedVisualization
  ENDIF

  IF ARG_PRESENT(lineProfile) NE 0 THEN BEGIN
      lineProfile = self._lineProfile
  ENDIF

  IF (N_ELEMENTS(_extra) NE 0) THEN $
    self->IDLitVisPlot::GetProperty, _EXTRA=_extra
END

;;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::_UpdateVis
;;
;; Purpose:  Scan convert the incomimg line (LINE parm) to determine
;;   which image pixels are to be fetched from the image (IMAGE parm)
;;   between the two endpoints.
;;   Then look up the image data at each of the selected pixels to form
;;   the plot profile.
;;   Update the superclass plot data with the result.
;;
;; Parameters:
;;
;; Keywords:
;;   None.
;;

pro IDLitVisPlotProfile::_UpdateVis

    compile_opt idl2, hidden

    ;; Get Image data so we can compute the new profile
    oImageData = self->GetParameter('IMAGE')
    if not OBJ_VALID(oImageData) then return
    success = oImageData->GetData(pData, /POINTER)
    if success eq 0 then return
    dims = SIZE(*pData, /DIMENSIONS)

    ;; Get Line endpoint data so we can compute the new profile
    oLine = self->GetParameter('LINE')
    if not OBJ_VALID(oLine) then return
    success = oLine->GetData(endpoints)
    if success eq 0 then return

    ;; Get current image position and pixel size data
    posData = [0,0,1,1]
    oTool = self->GetTool()
    if OBJ_VALID(oTool) then begin
        oImage = oTool->GetByIdentifier(self._associatedvisualization)
        if OBJ_ISA(oImage, 'IDLITVISIMAGE') then begin
            oImage->GetProperty, XORIGIN=XOrigin, YORIGIN=YOrigin, $
                PIXEL_XSIZE=pixelXSize, PIXEL_YSIZE=pixelYSize
            posData = [XOrigin, YOrigin, pixelXSize, pixelYSize]
        endif
    endif

    ;; Line endpoints
    pt0 = (endpoints[*,0]-posData[0:1])/posData[2:3]
    pt1 = (endpoints[*,1]-posData[0:1])/posData[2:3]

    ;; Scan-convert the line so we know what array elements are
    ;; covered by the line.  This code was adapted from PROFILE.PRO
    dx = FLOAT(pt1[0]-pt0[0])
    dy = FLOAT(pt1[1]-pt0[1])
    n = ABS(dx) > ABS(dy)
    if n eq 0 then return
    if ABS(dx) gt ABS(dy) then begin
        if pt1[0] ge pt0[0] then incx=1 else incx=-1
        incy = (pt1[1]-pt0[1])/ABS(dx)
    endif else begin
        if pt1[1] ge pt0[1] then incy=1 else incy=-1
        incx = (pt1[0]-pt0[0])/ABS(dy)
    endelse
    xx = LONG(FINDGEN(n+1l)*incx+pt0[0])   ;X values
    yy = LONG(FINDGEN(n+1l)*incy+pt0[1])   ;Y values
    plot = (*pData)[LONG(yy)*dims[0] + xx]

    xx *= posData[2]
    yy *= posData[3]

    if N_ELEMENTS(xx) gt 1 and N_ELEMENTS(yy) gt 1 then BEGIN
      distance = [0,total(sqrt((xx[1:*]-xx[0:*])^2 + (yy[1:*]-yy[0:*])^2), $
                          /CUMULATIVE)]
      IF self._bSinglePoint THEN BEGIN
        self._bSinglePoint = 0b
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        oDataSpace->SetProperty,X_AUTO_UPDATE=1,Y_AUTO_UPDATE=1
      ENDIF
    ENDIF ELSE BEGIN
      distance = [0]
      self._bSinglePoint = 1b
    ENDELSE

    ;; Update superclass with the Plot data.
    oData = self->IDLitVisPlot::GetParameter('Y')
    if OBJ_VALID(oData) then $
        void = oData->SetData(plot)

    oData = self->IDLitVisPlot::GetParameter('X')
    if OBJ_VALID(oData) then $
        void = oData->SetData(distance)

end

;;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::_UpdateVis3D
;;
;; Purpose:  Use the incoming LINE3D parameter to update the plot profile.
;;
;; Parameters:
;;
;; Keywords:
;;   None.
;;

pro IDLitVisPlotProfile::_UpdateVis3D
  compile_opt idl2, hidden

  ;; Get 3D Line data so we can compute the new profile
  oLine = self->GetParameter('LINE3D')
  if not OBJ_VALID(oLine) then return
  success = oLine->GetData(points)
  if success eq 0 then return

  ;; use the Z data for the profile
  profile = REFORM(points[2,*])

  ;; calculate distance along profile line
  x = points[0,*]
  y = points[1,*]
  distance = [0,total(sqrt((x[1:*]-x[0:*])^2 + (y[1:*]-y[0:*])^2),/CUMULATIVE)]

  ;; Update superclass with the Plot data.
  oData = self->IDLitVisPlot::GetParameter('Y')
  if OBJ_VALID(oData) then $
    void = oData->SetData(profile)
  ;; Update superclass with the X data.
  oData = self->IDLitVisPlot::GetParameter('X')
  if OBJ_VALID(oData) then $
    void = oData->SetData(distance)

end

;;----------------------------------------------------------------------------
;; IDLitVisPlotProfile::OnDataChangeUpdate
;;
;; Purpose:
;;   We hook this method to be informed when the line or image data is changed.
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
pro IDLitVisPlotProfile::OnDataChangeUpdate, oSubject, parmName
  compile_opt idl2, hidden

  case STRUPCASE(parmName) of
    '<PARAMETER SET>': BEGIN
      IF obj_valid(self->getParameter('LINE3D')) THEN $
        self->_UpdateVis3D $
      ELSE $
        self->_UpdateVis
    end
    'IMAGE': begin
      self->_UpdateVis
    end
    'LINE': begin
      self->_UpdateVis
    end
    'LINE3D': begin
      self->_UpdateVis3D
    end
    'Y': begin
      ;; Pass on to superclass
      self->IDLitVisPlot::OnDataChangeUpdate, oSubject, parmName
    end
    'X': begin
      ;; Pass on to superclass
      self->IDLitVisPlot::OnDataChangeUpdate, oSubject, parmName
    END

    else:                       ; ignore unknown parameters
    endcase
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisPlotProfile::OnNotify
;
; PURPOSE:
;   This procedure method handles notification of changes from a Subject
;   we have subscribed to.
;   In this case, we are watching the image position and pixel size so
;   that we can gather the correct data from the image to make the plot.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisPlotProfile::]OnDataChangeUpdate, strItem, strMsg, strUser
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro IDLitVisPlotProfile::OnNotify, strItem, strMsg, strUser

compile_opt idl2, hidden

    oTool=self->GetTool()
    if ~OBJ_VALID(oTool) then return
    oImage = oTool->GetByIdentifier(strItem)
    if STRUPCASE(strMsg) eq 'SETPROPERTY' then $
      switch STRUPCASE(strUser[0]) of
        "XORIGIN":
        "YORIGIN":
        "PIXEL_XSIZE":
        "PIXEL_YSIZE": $
            self->_UpdateVis
        else:
      endswitch
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisPlotProfile__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisPlotProfile object.
;
;-
pro IDLitVisPlotProfile__Define

    compile_opt idl2, hidden

    struct = { IDLitVisPlotProfile,                   $
               inherits IDLitVisPlot,                 $
               _associatedVisualization: '',          $
               _bSinglePoint: 0b,                     $
               _lineProfile: ''                       $
             }
end
