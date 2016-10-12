; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/arrow.pro#9 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; :Description:
;    Create IDL Arrow graphic
;
; :Params:
;    parm1 : optional generic argument
;    parm2 : optional generic argument
;    parm3 : optional generic argument
;
; :Keywords:
;    ARROW_STYLE: 
;     0: ' --------'
;     1: ' ------->' --- default
;     2: ' <-------'
;     3: ' <------>'
;     4: ' >------>'
;     5: ' <------<'
;     
;     HEAD_INDENT:
;       Set this property to a floating-point value between -1 and +1 giving the indentation of 
;       the back of the arrowhead along the shaft. A value of 0 gives a triangular shape, 
;       a value of +1 will create an arrowhead that is just two lines, while a value of -1 will 
;       create a diamond shape. The default is 0.4.
;       
;     HEAD_ANGLE:
;       Set this property to a floating-point value between 0 and 90 giving the angle in degrees 
;       of the arrowhead to the shaft. The default is 30.
;       
;    _REF_EXTRA
;
;-

function arrow, x,y,z,DATA=data, TARGET=ID, NAME=name, _REF_EXTRA=_extra
  
  compile_opt idl2, hidden
  @graphic_error
  

 nparams = n_params()
  if (isa(X, 'STRING')) then begin
    MESSAGE, 'Style argument must be passed in after data.'
  endif
  if (isa(Y, 'STRING'))  then begin
    if (nparams gt 2) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Y
    nparams--  
  endif
  if (isa(Z, 'STRING')) then begin
    if (nparams gt 3) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Z
    nparams--
  endif
  if (isa(styleIn, 'STRING')) then begin
    style = styleIn
    nparams--
  endif
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=color, LINESTYLE=linestyle, THICK=thick
  endif

  nx = N_ELEMENTS(x)

  case nparams of
    1 : begin
      if ((SIZE(x, /N_DIMENSIONS) eq 2) && (nx ge 4)) then begin
        dims = SIZE(x, /DIMENSIONS)
        ind2 = where(dims eq 2, cnt2)
        ind3 = where(dims eq 3, cnt3)
        if (cnt2 eq 1) then begin
          pointsIn = x
          if (ind2 eq 1) then $
            pointsIn = TRANSPOSE(pointsIn)
        endif
        if (cnt2 eq 2) then begin
          pointsIn = x
        endif
        if (cnt3 eq 1) then begin
          pointsIn = x
          if (ind3 eq 1) then $
            pointsIn = TRANSPOSE(pointsIn)
        endif
        if (cnt3 eq 2) then begin
          pointsIn = x
        endif
      endif
    end
    2 : if (nx gt 1) then $
      pointsIn = TRANSPOSE([[x],[y]]) 
    3 : begin
        if (nx gt 1) then begin
          pointsIn = (N_ELEMENTS(z) gt 1) ? TRANSPOSE([[x],[y],[z]]) : $
            TRANSPOSE([[x],[y],[REPLICATE(z, nx)]])
        endif
      end
    else : MESSAGE, 'Incorrect number of arguments.'
  endcase
  
  if ~array_equal(size(pointsIn, /dimension), [2l,2l]) then $
    MESSAGE, 'Invalid points specified.  Please insert 2 points as arrow start and end.'

  if (KEYWORD_SET(data) && ~ISA(toVisLayer)) then toVisLayer = 1b else toVisLayer=0b

  ;; Set up parameters
  if (KEYWORD_SET(ID) || KEYWORD_SET(toolIDin)) then begin
    fullID = (iGetID(ID, TOOL=toolIDin))[0]
  endif
  if (N_ELEMENTS(fullID) eq 0) then $
    fullID = iGetCurrent()

  ;; Error checking
  if (fullID[0] eq '') then begin
    message, 'Graphics window does not exist.'
  endif

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then MESSAGE, 'Invalid object'

  ;; Get the object from ID
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then MESSAGE, 'Invalid object'
  
  ;; Get the tool
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then MESSAGE, 'Invalid object'
  
  ;; Check to see if Z values were passed in
  dims = SIZE(pointsIn, /DIMENSIONS)
  keepZ = (dims[0] eq 3) ? 1 : 0
  if (N_ELEMENTS(keepZIn) eq 1) then $
    keepZ = KEYWORD_SET(keepZIn)
  
  ;; Convert the points
  points = iConvertCoord(pointsIn, TO_ANNOTATION_DATA=(~toVisLayer), $
                         TO_DATA=toVisLayer, TARGET_IDENTIFIER=fullID, $
                         TOOL=toolIDin, DATA=data, _EXTRA=_extra)

  ;; If annotation is going into the annotation layer then ensure the Z
  ;; values are as needed
  if (~toVisLayer && ~keepZ) then begin
    points[2,*] = 0.99d
    zValue=0.99d
  endif
  
  npoints = (SIZE(points, /DIM))[1]

  ;; Get Manipulator
  oManip=oTool->GetByIdentifier(oTool->FindIdentifiers('*manipulators*line'))
  if (~OBJ_VALID(oManip)) then MESSAGE, 'Invalid object'

  ;; Temporarily change manipulator name
  oManip->GetProperty, NAME=oldName
  oManip->SetProperty, NAME='Arrow'
  
  ;; Get Annotation
  oDesc = oTool->GetAnnotation('Arrow')
  oArrow = oDesc->GetObjectInstance(_NO_VERTEX_VISUAL=(npoints gt 2))
  
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
    oDS->Add, oArrow, /NO_UPDATE
  endif else begin
    oWin->Add, oArrow, LAYER='ANNOTATION'
  endelse
  
  ; Proper name
  if (N_ELEMENTS(name) eq 1) then begin
    oArrow->GetProperty, PARENT=oParent
    oObjs = oParent->Get(/ALL, COUNT=cnt)
    sNames = []
    foreach oObj, oObjs do begin
      oObj->GetProperty, IDENTIFIER=objName
      sNames = [sNames, STRUPCASE(objName)]
    endforeach
    newName = IDLitGetUniqueName(sNames, name)
    oArrow->SetProperty, IDENTIFIER=newName, NAME=name
  endif
  
  ;; Set data on annotation
  oArrow->SetProperty, DATA=points, ZVALUE=zValue, _EXTRA=_extra
  oArrow->SetAxesRequest, 0, /ALWAYS
  
  oTool->RefreshCurrentWindow

  ;; Put old name back  
  oManip->SetProperty, NAME=oldName
  
  ;; Retrieve ID of new line
  if (Arg_Present(idOut)) then $
    idOut = oArrow->GetFullIdentifier()
 
  Graphic__define
  return, OBJ_NEW('Arrow', oArrow)
end


;--------------------------------------------------------------------------
; This is the old ARROW procedure. We need to define its call here,
; and route the call to our internal .pro routine. Otherwise IDL will never
; find the old procedure name.
;
pro arrow, x0, y0, x1, y1, _REF_EXTRA=ex
  compile_opt hidden
  on_error, 2
  arrow_internal, x0, y0, x1, y1, _EXTRA=ex
end


