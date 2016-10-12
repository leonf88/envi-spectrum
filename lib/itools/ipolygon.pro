; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ipolygon.pro#2 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iPolygon
;
; PURPOSE:
;   Adds a polygon annotation to an iTool
;
; CALLING SEQUENCE:
;   iPolygon, points [,TARGET_IDENTIFIER=target] [,IDENTIFIER=id]
;
; INPUTS:
;   POINTS - The vertices of the polygon 
;
; KEYWORD PARAMETERS:
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
PRO iPolygon, pointsIn, $
              DATA=dataIn, $
              OBJECT=oPolygon, $
              VISUALIZATION=visIn, $
              TARGET_IDENTIFIER=ID, $
              TOOL=toolIDin, $
              NAME=name, $
              IDENTIFIER=idOut, $
              MAINTAIN_Z=keepZIn, $
              _EXTRA=_extra 
  compile_opt hidden, idl2

@idlit_itoolerror.pro

  ;; Set up parameters
  if (KEYWORD_SET(ID) || KEYWORD_SET(toolIDin)) then begin
    fullID = (iGetID(ID, TOOL=toolIDin))[0]
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
  
  ;; Check to see if Z values were passed in
  dims = SIZE(pointsIn, /DIMENSIONS)
  keepZ = (dims[0] eq 3) ? 1 : 0
  if (N_ELEMENTS(keepZIn) eq 1) then $
    keepZ = KEYWORD_SET(keepZIn)
  
  ;; Convert the points
  toVisLayer = KEYWORD_SET(visIn)
  points = iConvertCoord(pointsIn, TO_ANNOTATION_DATA=(~toVisLayer), $
                         TO_DATA=toVisLayer, DATA=dataIn, $
                         TARGET_IDENTIFIER=ID, TOOL=toolIDin, _EXTRA=_extra)
  ;; If annotation is going into the annotation layer then ensure the Z
  ;; values are as needed.
  if (~toVisLayer && ~keepZ) then $
    points[2,*] = 0.99d

  ;; Get Manipulator
  oManip = $
    oTool->GetByIdentifier(oTool->FindIdentifiers('*manipulators*polygon'))
  if (~OBJ_VALID(oManip)) then return

  ;; Temporarily change manipulator name
  oManip->GetProperty, NAME=oldName
  oManip->SetProperty, NAME='Polygon'
  
  ;; Get Annotation
  oDesc = oTool->GetAnnotation('Polygon')
  oPolygon = oDesc->GetObjectInstance()
  
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
    oDS->Add, oPolygon
    oPolygon->_RemoveRotateHandle
  endif else begin
    oWin->Add, oPolygon, LAYER='ANNOTATION'
  endelse
  
  ; Proper name
  if (N_ELEMENTS(name) eq 1) then begin
    oPolygon->GetProperty, PARENT=oParent
    oObjs = oParent->Get(/ALL, COUNT=cnt)
    sNames = []
    foreach oObj, oObjs do begin
      oObj->GetProperty, IDENTIFIER=objName
      sNames = [sNames, STRUPCASE(objName)]
    endforeach
    newName = IDLitGetUniqueName(sNames, name)
    oPolygon->SetProperty, IDENTIFIER=newName, NAME=name
  endif
    
  ;; Set data on annotation
  oPolygon->SetProperty, _DATA=points, /TESSELLATE, _EXTRA=_extra
  oPolygon->SetAxesRequest, 0, /ALWAYS
  
  oTool->RefreshCurrentWindow

  ;; Put old name back  
  oManip->SetProperty, NAME=oldName
  
  ;; Retrieve ID of new line
  if (Arg_Present(idOut)) then $
    idOut = oPolygon->GetFullIdentifier()
  
end
