; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislineprofile3d__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisLineProfile3D
;
; PURPOSE:
;    The IDLitVisLineProfile3D class implements a a line profile visualization
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
;; IDLitVisLineProfile3D::Init
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
FUNCTION IDLitVisLineProfile3D::Init, _REF_EXTRA=_extra
  compile_opt idl2, hidden

  ;; Initialize superclass
  if (~self->IDLitVisLineProfile::Init(_EXTRA=_EXTRA)) then $
    return, 0

  ;; Register these "output" parameters to broadcast changes in the line
  ;; to any observers.
  self->RegisterParameter, 'LINE3D', DESCRIPTION='3D Line Profile Points', $
                           TYPES='IDLARRAY2D'

  ;; Properties
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitVisLineProfile3D::SetProperty, _EXTRA=_extra

  RETURN, 1                     ; Success

END


;;----------------------------------------------------------------------------
;; IDLitVisLineProfile3D::Cleanup
;;
;; Purpose:
;;   Cleanup/destrucutor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
PRO IDLitVisLineProfile3D::Cleanup
  compile_opt idl2, hidden

  ;; Cleanup superclass
  self->IDLitVisLineProfile::Cleanup

  IF ptr_valid(self._3DLineData) THEN $
    ptr_free, self._3DLineData

END


;----------------------------------------------------------------------------
; IDLitVisLineProfile3D::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
PRO IDLitVisLineProfile3D::Restore
  compile_opt idl2, hidden

  ;; Call superclass restore.
  self->IDLitVisLineProfile::Restore

END


;---------------------------------------------------------------------------
; IDLitVisLineProfile3D::_clipAndUpdate
;
; Purpose:
;  Utility function for clipping the profile line.
;
FUNCTION IDLitVisLineProfile3D::_clipAndUpdate, CONSTRAIN=constrain
  compile_opt idl2, hidden

  ;; 3D dataspaces do not clip so no clipping is necessary
  return, 1

END


;;----------------------------------------------------------------------------
;; IDLitVisLineProfile3D::Translate
;;
;; Purpose:
;;   We override this method to allow us to clip the
;;   line profile annotation to the image and to update our LINE parameter.
;;
;; Parameters:
;;
;; Keywords:
;;   None.
;;

PRO IDLitVisLineProfile3D::Translate, x, y, z, _EXTRA=_extra
  compile_opt idl2, hidden

  ;; currently not handling the 3D case for translate
  return

END


;---------------------------------------------------------------------------
; IDLitVisLineProfile3D::MoveVertex
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
pro IDLitVisLineProfile3D::MoveVertex, xyz, INDEX=index, WINDOW=WINDOW

    compile_opt idl2, hidden

    oTool = self->getTool()
    if (~OBJ_VALID(oTool)) then $
        return

    oSurface = oTool->getByIdentifier(self._associatedVisualization)
    ;; if the surface is hidden do not allow the ends to be moved.
    oSurface->getProperty,hide=hidden
    IF hidden THEN return

    oWin = oTool->getCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return

    ;; make sure that the surface is the item the mouse is over
    indx = max(index) < (n_elements(index)-1)
    oVisList = oWin->DoHitTest(xyz[0,indx], xyz[1,indx], $
                               DIMENSIONS=[1,1], /ORDER, $
                               SUB_HIT=oSubHitList)
    IF ~(obj_valid(oVisList[0]) && $
         oVisList[0]->getFullIdentifier() EQ self._associatedVisualization && $
         obj_isa(oSubHitList[0],'IDLGRSURFACE')) THEN return

    ;; get layer for pickdata
    oView = oWin->GetCurrentView()
    oLayer = oView->GetCurrentLayer()

    ;; translate to 3D dataspace.  If point is not on the surface then
    ;; use last saved point
    newXYZ = double(xyz)
    FOR i=0,n_elements(xyz)/3-1 DO BEGIN
      IF (oWin->Pickdata(oLayer,oSurface,[xyz[0,i],xyz[1,i]],xyzOut)) $
        THEN BEGIN
        newXYZ[*,i] = xyzOut
        self._endpoints3D[*,i] = xyzOut
      ENDIF ELSE BEGIN
        newXYZ[*,i] = self._endpoints3D[*,i]
      ENDELSE
    ENDFOR

    self->_IDLitVisVertex::MoveVertex,newXYZ,INDEX=index

END


;---------------------------------------------------------------------------
; IDLitVisLineProfile3D::Create3DLine
;
; Purpose:
;    Creates a 3D line on a surface
;
; Parameters:
;   ENDPOINTS: An array of dimensions (3,2) giving the vertices of the
;   endpoints.
;
;   OUTDATA: output parameter that can return the newly created line data
;
; Keywords:
;   NONE
;
pro IDLitVisLineProfile3D::Create3DLine, endpoints, OUTDATA=outdata
  compile_opt idl2, hidden

  ;; bail if line length is zero
  IF array_equal(endpoints[*,0], endpoints[*,1]) THEN BEGIN
    IF ptr_valid(self._3DLineData) THEN $
      *self._3DLineData = endpoints $
    ELSE $
      self._3DLineData = ptr_new(endpoints)
    IF arg_present(outdata) THEN outdata=*self._3DLineData
    return
  ENDIF

  ;; if current vis is a surface, get its data
  oTool = self->getTool()
  if (~OBJ_VALID(oTool)) then $
    return
  oSurface = oTool->GetByIdentifier(self._associatedVisualization)
  IF ~(oSurface->GetParameter('Z'))->getData(zData) THEN return

  ;; get xData or create an indgen based on size of zData
  oXData = oSurface->GetParameter('X')
  IF obj_valid(oXData) THEN void = oXData->getData(xData) $
  ELSE xData = indgen((size(zData,/dimensions))[0])

  ;; get yData or create an indgen based on size of zData
  oYData = oSurface->GetParameter('Y')
  IF obj_valid(oYData) THEN void = oYData->getData(yData) $
  ELSE yData = indgen((size(zData,/dimensions))[1])

  ;; calculate slope of line in X-Y space for determining where the
  ;; line crosses known X and Y values
  slope = (endpoints[0,0] EQ endpoints[0,1] ? !values.f_infinity : $
           (float(endpoints[1,1])-endpoints[1,0])/ $
           (endpoints[0,1]-endpoints[0,0]))

  swap = 0b
  ;; get all known X values between endpoints
  IF endpoints[0,1] GE endpoints[0,0] THEN BEGIN
    x_where = where(xData GE endpoints[0,0] AND xData LE endpoints[0,1])
  ENDIF ELSE BEGIN
    x_where = where(xData LE endpoints[0,0] AND xData GE endpoints[0,1])
    ;; set swap flag if X value moves to the other side of the
    ;; stationary vertex in order to draw the line profile with the
    ;; same end always at the beginning.
    swap = 1b
  ENDELSE
  IF x_where[0] NE -1 THEN BEGIN
    xcross = xData[x_where]
    ;; calculate y values where line crosses an X value
    y_xcross = slope*(xcross-endpoints[0,1])+endpoints[1,1]
    ;; interpolate to get Z value
    z_xcross = fltarr(n_elements(xcross))
    FOR i=0,n_elements(xcross)-1 DO $
      z_xcross[i] = interpol(zData[where(xData EQ xcross[i]),*],yData, $
                             y_xcross[i])
  ENDIF ELSE BEGIN
    ;; create dummy data if nothing can be calculated
    xcross = endpoints[0,0]
    y_xcross = endpoints[1,0]
    z_xcross = endpoints[2,0]
  ENDELSE

  ;; get all known Y values between endpoints
  IF endpoints[1,1] GE endpoints[1,0] THEN BEGIN
    y_where = where(yData GE endpoints[1,0] AND yData LE endpoints[1,1])
  ENDIF ELSE BEGIN
    y_where = where(yData LE endpoints[1,0] AND yData GE endpoints[1,1])
  ENDELSE
  IF y_where[0] NE -1 THEN BEGIN
    ycross = yData[y_where]
    ;; calculate x values where line crosses an Y value
    x_ycross = finite(slope) ? $
               (slope EQ 0 ? $
                congrid(endpoints[0,0:1],n_elements(ycross),/interp,/minus_one) : $
                (ycross-endpoints[1,1])/slope + endpoints[0,1]) : $
               replicate(endpoints[0,0], n_elements(ycross))
    ;; interpolate to get Z value
    z_ycross = fltarr(n_elements(ycross))
    FOR i=0,n_elements(ycross)-1 DO $
      z_ycross[i] = interpol(zData[*,where(yData EQ ycross[i])],xData, $
                             x_ycross[i])
  ENDIF ELSE BEGIN
    ;; create dummy data if nothing can be calculated
    ycross = endpoints[1,0]
    x_ycross = endpoints[0,0]
    z_ycross = endpoints[2,0]
  ENDELSE

  ;; create temp array holding all points, including end points
  temp_points = [[transpose([[xcross],[y_xcross],[z_xcross]])], $
                 [transpose([[x_ycross],[ycross],[z_ycross]])],[endpoints]]

  ;; sort points and filter out any duplicates
  temp_points = temp_points[*,where(finite(temp_points[2,*]))]

  IF (ABS(slope) GT 50000) THEN BEGIN
    y_points = temp_points[1,*]
    IF swap THEN $
      yLocs = uniq(y_points,reverse(sort(y_points))) $
    ELSE $
      yLocs = uniq(y_points,sort(y_points))
    points = temp_points[*,yLocs]
  ENDIF ELSE BEGIN
    x_points = temp_points[0,*]
    IF swap THEN $
      xLocs = uniq(x_points,reverse(sort(x_points))) $
    ELSE $
      xLocs = uniq(x_points,sort(x_points))
    points = temp_points[*,xLocs]
  ENDELSE

  ;; store new line data
  IF ptr_valid(self._3DLineData) THEN $
    *self._3DLineData = points $
  ELSE $
    self._3DLineData = ptr_new(points)

  IF arg_present(outdata) THEN outdata=points

END

;;----------------------------------------------------------------------------
;; IDLitVisLineProfile3D::OnDataChangeUpdate
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
pro IDLitVisLineProfile3D::OnDataChangeUpdate, oSubject, parmName
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
        self->IDLitVisLineProfile3D::OnDataChangeUpdate, $
          oData, paramNames[i]
      endfor
    end

    'VERTICES' : BEGIN

        success = oSubject->GetData(endpoints3D)
        ;; if operating on a 3D surface update the LINE3D
        ;; parameter instead of LINE
        self->Create3DLine,endpoints3D
        IF size(*self._3DLineData,/n_dimensions) EQ 2 THEN BEGIN
;          oParam = obj_new('IDLitDataIDLArray2D',*self._3DLineData)
;          self->IDLitVisPolyline::OnDataChangeUpdate,oParam,'VERTICES'
            self->IDLitVisPolyline::SetProperty, DATA=*self._3DLineData
            oLine3D = self->GetParameter('LINE3D')
            IF obj_valid(oLine3D) THEN $
                success = oLine3D->setData(*self._3DLineData)
        ENDIF
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
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisLineProfile3D__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLineProfile3D object.
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
pro IDLitVisLineProfile3D__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLineProfile3D,       $
               inherits IDLitVisLineProfile, $
               _endpoints3D: DBLARR(3,2), $
               _3DLineData: PTR_NEW() $
             }
end
