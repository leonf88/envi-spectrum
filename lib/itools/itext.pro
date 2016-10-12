; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/itext.pro#3 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iText
;
; PURPOSE:
;   Adds a text annotation to an iTool
;
; CALLING SEQUENCE:
;   iText, TEXT, X, Y, [Z]
;
; INPUTS:
;   TEXT - The text to add
;
;   X,Y,Z - The location of the text 
;
; KEYWORD PARAMETERS:
;   ORIENTATION - The angle, from horizontal, to rotate the text.  The default
;                 is 0.
;
;   TARGET_IDENTIFIER - The identifier of the view, or itool to annotate. 
;                       If set to an item that is not a view or tool then 
;                       the view that encompasses the defined object will be 
;                       used. If not supplied, the currently selected item 
;                       will be used.
;
;   IDENTIFIER - If set to an named variable, returns the full identifier of 
;                the object created or modified.
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iText, textIn, xIn, yIn, Zin, $
           DATA=data, $
           FONT_NAME=fontName, $
           ORIENTATION=orientIn, $
           VISUALIZATION=visIn, $
           TARGET_IDENTIFIER=ID, $
           TOOL=toolIDin, $
           UPDIR=updir, $
           BASELINE=baseline, $
           IDENTIFIER=identifier, $
           OBJECT=oText, $
           NAME=name, $
           TITLE=title, $
           _EXTRA=_extra 
  compile_opt hidden, idl2

on_error, 2

  catch, err
  if (err ne 0) then begin
    catch, /CANCEL
    if (N_ELEMENTS(oText)) then OBJ_DESTROY, oText
    ; Remove name in front of the error message.
    semi = STRPOS(!ERROR_STATE.msg, ':')
    if (semi gt 0) then !ERROR_STATE.msg = STRMID(!ERROR_STATE.msg, semi+2)
    message, !ERROR_STATE.msg
    return
  endif

  ;; Set up parameters
  if (KEYWORD_SET(ID) || KEYWORD_SET(toolIDin)) then begin
    fullID = (iGetID(ID, TOOL=toolIDin))[0]
  endif
  if (N_ELEMENTS(fullID) eq 0) then $
    fullID = iGetCurrent()

  if (fullID[0] eq '') then begin
    catch, /CANCEL
    message, 'Graphics window does not exist.'
    return
  endif

  if (N_PARAMS() eq 0) then begin
    catch, /CANCEL
    message, 'Incorrect number of parameters'
    return
  endif
  
  text = STRING(textIn)
  x = (N_ELEMENTS(xIn) ne 0) ? DOUBLE(xIn[0]) : 0.5
  y = (N_ELEMENTS(yIn) ne 0) ? DOUBLE(yIn[0]) : 0.9
  keepZ = (N_ELEMENTS(zIn) ne 0)
  z = keepZ ? DOUBLE(zIn[0]) : 0.0
  toVisLayer = KEYWORD_SET(visIn)
  

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  ;; Get the object from ID
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  ;; Get the tool
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  oWin = oTool->GetCurrentWindow()
  
  ;; Get Manipulator
  oManip=oTool->GetByIdentifier(oTool->FindIdentifiers('*manipulators*text'))
  if (~OBJ_VALID(oManip)) then return
  
  ;; Get Annotation
  oDesc = oTool->GetAnnotation('Text')
  oText = oDesc->GetObjectInstance()
  
  
  if (toVisLayer || KEYWORD_SET(title)) then begin
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
  endif


  ; If /TITLE is set, then automatically compute X,Y,Z from dataspace range.
  if (KEYWORD_SET(title)) then begin
    toVisLayer = 1
    data = 1

    baseline = [1,0,0]
    updir = [0,1,0]

    oDataspace = Obj_Valid(oDS) ? oDS->GetDataSpace(/UNNORMALIZED) : OBJ_NEW()
    if (Obj_Valid(oDataspace)) then begin
      is3D = oDataspace->Is3D()
      void = oDataspace->GetXYZRange(xRange, yRange, zRange, /INCLUDE_AXES)
      oDataspace->_GetXYZAxisReverseFlags, xReverse, yReverse, zReverse
      x = 0.5*(xRange[0] + xRange[1])
      
      if (is3D) then begin
        y = (yReverse ? yRange[0] : yRange[1])
        if (zReverse) then zRange = zRange[[1,0]]
        z = zRange[1] + 0.04*(zRange[1] - zRange[0])
      endif else begin
        if (yReverse) then yRange = yRange[[1,0]]
        y = yRange[1] + 0.04*(yRange[1] - yRange[0])
        z = 0
      endelse
      
      ; Set proper orientation
      if (xReverse) then baseline[0] *= -1
      if (is3d) then begin
        updir = [0,0,1]
        if (zReverse) then updir[2] *=-1
      endif else begin
        if (yReverse) then updir[1] *= -1
      endelse

    endif else begin
      toVisLayer = 0
      data = 0
      x = 0.5
      y = 0.9
      z = 0
    endelse
    
    name = 'Title'
    oText->SetProperty, ALIGNMENT=0.5
  endif


  ;; Convert the points
  points = iConvertCoord(x, y, z, TO_ANNOTATION_DATA=(~toVisLayer), $
                         TO_DATA=toVisLayer, TARGET_IDENTIFIER=fullID, $
                         TOOL=toolIDin, DATA=data, _EXTRA=_extra)
  ;; If annotation is going into the annotation layer then ensure the Z
  ;; values are as needed.
  if (~toVisLayer && ~keepZ) then $
    points[2,*] = 0.99d

  ;; Add annotation to proper layer in the window
  if (toVisLayer) then begin
    oDS->Add, oText
    oText->_RemoveRotateHandle
  endif else begin
    oWin->Add, oText, LAYER='ANNOTATION'
  endelse
  
  ; Proper name
  if (N_ELEMENTS(name) eq 1) then begin
    oText->GetProperty, PARENT=oParent
    oObjs = oParent->Get(/ALL, COUNT=cnt)
    sNames = []
    foreach oObj, oObjs do begin
      oObj->GetProperty, IDENTIFIER=objName
      sNames = [sNames, STRUPCASE(objName)]
    endforeach
    newName = IDLitGetUniqueName(sNames, name)
    oText->SetProperty, IDENTIFIER=newName, NAME=name
  endif
  
  ; see if FONT_NAME is set
  if (~ISA(fontName) && (!version.os_family eq "Windows") && $
      (CALL_FUNCTION('language_get') eq 1041)) then begin
    fontName = 'MS PGothic' 
  endif
    
  ;; Set data on annotation
  oText->SetProperty, STRING=text, UPDIR=updir, BASELINE=baseline, $
    VERTICAL_ALIGNMENT=0, /ENABLE_FORMATTING, FONT_NAME=fontName, _EXTRA=_extra
  oText->SetAxesRequest, 0, /ALWAYS
  
  ;; Rotate text
  if (N_ELEMENTS(orientIn) ne 0) then $
    oText->Rotate, [0,0,1], DOUBLE(orientIn[0])

  ;; Position text
  ; Check for map warping
  if ((toVisLayer) && ~KEYWORD_SET(title)) then begin
    sMap = oDS->GetProjection()
    if (N_TAGS(sMap) ne 0) then $
      points[0:1] = MAP_PROJ_FORWARD(points[0], points[1], MAP_STRUCTURE=sMap)
  endif

  ; Convert to logarithmic axes, if necessary.
  oDataSpace = oText->GetDataSpace(/UNNORMALIZED)
  if (OBJ_VALID(oDataSpace)) then begin
    oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
    if (KEYWORD_SET(xLog)) then points[0] = ALOG10(points[0])
    if (KEYWORD_SET(yLog)) then points[1] = ALOG10(points[1])
    if (KEYWORD_SET(zLog)) then points[2] = ALOG10(points[2])
  endif
  
  oText->Translate, points[0], points[1], points[2]

  oTool->RefreshCurrentWindow

  ;; Retrieve ID of new line
  if (Arg_Present(identifier)) then $
    identifier = oText->GetFullIdentifier()

end
