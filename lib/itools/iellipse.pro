; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iellipse.pro#2 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iEllipse
;
; PURPOSE:
;   Adds a Ellipse annotation to an iTool
;
; CALLING SEQUENCE:
;   iEllipse, x, y, a [, e [, theta]] [,VISUALIZATION=target] [,IDENTIFIER=id]
;
; INPUTS:
;   X, Y - The center point of the ellipse.
;
;   A - The length of the semi-major axis
;
;   e - The eccentricity of the ellipse, defined as SQRT(a^2 - b^2) / a where
;       a is the length of the semi-major axis and b is the length of the 
;       semi-minor axis. If not supplied, a default of 0, denoting a circle, 
;       is used.
;
;   THETA - The angle, counter-clockwise from horizontal, of the semi-major 
;           axis. If not supplied, a default of 0 is used.
;
; KEYWORD PARAMETERS:
;   VISUALIZATION - If set, add the annotation to the data space.  The default
;                   is to add it to the annotation layer.  VISUALIZATION is the
;                   identifier of the view, or itool to annotate.  If set to 
;                   an item that is not a view or tool then the view that
;                   encompasses the defined object will be used. If not 
;                   supplied, the currently selected item will be used.
;
;   IDENTIFIER - If set to an named variable, returns the full identifier of 
;                the object created or modified.
;                
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

PRO iEllipse, majorIn, xcIn, ycIn, zcIn, $
              DEVICE=device, $
              ECCENTRICITY=eccIn, $
              MAJOR=majorKW, $
              MINOR=minorKW, $
              OBJECT=oEllipse, $
              THETA=thetaIn, $
              DATA=dataIn, $
              NAME=name, $
              VISUALIZATION=visIn, $
              TARGET_IDENTIFIER=ID, $
              TOOL=toolIDin, $
              IDENTIFIER=idOut, $
              MAINTAIN_Z=keepZIn, $
              _EXTRA=_extra 
  compile_opt hidden, idl2

@idlit_itoolerror.pro

  if (N_PARAMS() lt 3) then begin
    message, 'Incorrect number of parameters'
    return
  endif
  
  ;; Set up parameters
  if (KEYWORD_SET(ID)) then begin
    fullID = iGetID(ID[0], TOOL=toolIDin)
  endif
  if (N_ELEMENTS(fullID) eq 0) then $
    fullID = iGetCurrent()

  ;; Error checking
  if (fullID[0] eq '') then begin
    message, 'Graphics window does not exist.'
    return
  endif

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  ;; Get the object from ID
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  ;; Get the tool
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  toVisLayer = KEYWORD_SET(visIn)

  xc = DOUBLE(xcIn[0])
  yc = DOUBLE(ycIn[0])
  zc = N_ELEMENTS(zcIn) eq 0 ? 0.0d : DOUBLE(zcIn[0])

  if (ISA(majorKW)) then begin
    major = majorKW[0]
  endif else begin
    major = DOUBLE(majorIn[0])
    ; If 0 was passed in, pick a "nice" value.
    if (major eq 0) then begin
      major = 50  ; pixels
      if (~KEYWORD_SET(device)) then begin
        xyz = iConvertCoord([0,50], [0,0], /DEVICE, $
          TO_DATA=dataIn, TO_NORMAL=~KEYWORD_SET(dataIn), $
          TARGET_IDENTIFIER=fullID, TOOL=toolIDin)
        major = ABS(xyz[0,1]-xyz[0,0])
      endif
    endif
  endelse

  ecc = ISA(eccIn) ? (0d > eccIn[0] < 1d) : 0d 
  minor = ISA(minorKW) ? minorKW[0] : 0d

  case N_ELEMENTS(thetaIn) of
    3 : theta = DOUBLE(thetaIn)
    1 : theta = [0.0d, 0.0d, DOUBLE(thetaIn)]
    else : theta = [0.0d, 0.0d, 0.0d]
  endcase
  
  ; If only major axis was specified, then create a circle.
  if (~ISA(eccIn) && ~ISA(minorKW)) then begin
    toDevice = KEYWORD_SET(device)
    xyz = iConvertCoord([0,1], [0,1], /DEVICE, $
      TO_DATA=toVisLayer, TO_NORM=~toVisLayer && ~toDevice, TO_DEVICE=toDevice, $
      TARGET_IDENTIFIER=fullID, TOOL=toolIDin)
    ratio = ABS((xyz[1,1]-xyz[1,0])/(xyz[0,1]-xyz[0,0]))
    minor = ratio*major
  endif

  if (major ne 0d && minor ne 0d) then begin
    ; If MINOR is bigger than MAJOR, then flip them and rotate by 90 degrees.
    if (minor gt major) then begin
      tmp = minor
      minor = major
      major = tmp
      theta[2] += 90
    endif
    ecc = SQRT(1d - (DOUBLE(minor)/major)^2)
  endif

  ;; Check to see if Z values were passed in
  keepZ = (N_ELEMENTS(zcIn) ne 0) ? 1 : 0
  if (N_ELEMENTS(keepZIn) eq 1) then $
    keepZ = KEYWORD_SET(keepZIn)
  
  
  ;; Switch from left hand rotation matrix to right hand grModel
  theta *= -1.0d

  ;; Math stuff
  minor = SQRT(major^2 - (major*ecc)^2)
  tm = FINDGEN(181)/180. ;; 180 seems like a good number of points
  x = major*COS(2*!pi*tm)
  y = minor*SIN(2*!pi*tm)
  r = SQRT(x^2+y^2)
  
  th = ATAN(y,x)

  xx = r*COS(th)
  yy = r*SIN(th)
  zz = r*0.0
  
  theta *= !dtor

  transx = [[1, 0, 0], $
           [0, cos(theta[0]), -sin(theta[0])], $
           [0, sin(theta[0]), cos(theta[0])]] 
  transy = [[cos(theta[1]), 0, sin(theta[1])], $
           [0, 1, 0], $
           [-sin(theta[1]), 0, cos(theta[1])]] 
  transz = [[cos(theta[2]), -sin(theta[2]), 0], $
           [sin(theta[2]), cos(theta[2]), 0], $
           [0, 0, 1]] 
  
  for i=0,N_ELEMENTS(xx)-1 do begin
    point = [xx[i], yy[i], zz[i]]
    newPoint = transx#point
    newPoint = transy#newPoint
    newPoint = transz#newPoint
    xx[i] = newPoint[0]
    yy[i] = newPoint[1]
    zz[i] = newPoint[2]
  endfor

  xx += xc
  yy += yc
  zz += zc
  
  ;; Convert the points
  points = iConvertCoord(xx, yy, zz, TO_ANNOTATION_DATA=(~toVisLayer), $
                         TO_DATA=toVisLayer, DATA=dataIn, $
                         TARGET_IDENTIFIER=fullID, TOOL=toolIDin, $
                         DEVICE=device, $
                         _EXTRA=_extra)
  ;; If annotation is going into the annotation layer then ensure the Z
  ;; values are as needed.
  if (~toVisLayer && ~keepZ) then $
    points[2,*] = 0.99d

  ;; Get Manipulator
  oManip = oTool->GetByIdentifier(oTool->FindIdentifiers('*manipulators*oval'))
  if (~OBJ_VALID(oManip)) then return

  ;; Temporarily change manipulator name
  oManip->GetProperty, NAME=oldName
  oManip->SetProperty, NAME='Ellipse'
  
  ;; Get Annotation
  oDesc = oTool->GetAnnotation('Oval')
  oEllipse = oDesc->GetObjectInstance()
  
  oEllipse->SetAxesRequest, 0, /ALWAYS
  
  ;; Add annotation to proper layer in the window
  oWin = oTool->GetCurrentWindow()
  if (toVisLayer) then begin
    ;; Add to data space
    if (OBJ_HASMETHOD(oObj, 'GetDataSpace')) then begin
      oDS = oObj->GetDataSpace()
    endif else begin
      ;; The view does not have a getdataspace method
      if (OBJ_ISA(oObj, 'IDLitgrView')) then begin
        dsID = (oObj->FindIdentifiers('*DATA SPACE*'))[0]
      endif else begin
        ;; Fall back to finding first data space in the window
        dsID = oWin->FindIdentifiers('*Data Space')
      endelse
      oDS = oSystem->GetByIdentifier(dsID)
    endelse
    oDS->Add, oEllipse
    oEllipse->_RemoveRotateHandle
  endif else begin
    oWin->Add, oEllipse, LAYER='ANNOTATION'
  endelse
  ;; Set data on annotation
  oEllipse->SetProperty, _DATA=points, _EXTRA=_extra
  
  ; Proper name
  if (N_ELEMENTS(name) eq 1) then begin
    oEllipse->GetProperty, PARENT=oParent
    oObjs = oParent->Get(/ALL, COUNT=cnt)
    sNames = []
    foreach oObj, oObjs do begin
      oObj->GetProperty, IDENTIFIER=objName
      sNames = [sNames, STRUPCASE(objName)]
    endforeach
    newName = IDLitGetUniqueName(sNames, name)
    oEllipse->SetProperty, IDENTIFIER=newName, NAME=name
  endif
    
  oTool->RefreshCurrentWindow

  ;; Put old name back  
  oManip->SetProperty, NAME=oldName

  ;; Retrieve ID of new line
  if (Arg_Present(idOut)) then $
    idOut = oEllipse->GetFullIdentifier()
  
end
