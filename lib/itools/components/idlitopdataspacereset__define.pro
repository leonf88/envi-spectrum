; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopdataspacereset__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the operation for reseting a dataspace to the ranges
;   defined by the contained data
;

;---------------------------------------------------------------------------
; Lifecycle Methods
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   This function method initializes the component object.
;
; Arguments:
;   None.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
function IDLitopDataspaceReset::Init, _EXTRA=_extra
  compile_opt idl2, hidden

  ; Initialize superclass.
  return, self->IDLitOperation::Init(_EXTRA=_extra)
  
end


;--------------------------------------------------------------------------
; IDLitopDataspaceReset::_SetDataspaceRange
;
; Purpose:
;   Sets the new dataspace range
;
; Parameters
;  oDS - The dataspace to be changed
;  xMin,xMax - New X min,max values
;  yMin,yMax - New Y min,max values
;  zMin,zMax - New Z min,max values
;
function IDLitopDataspaceReset::_SetDataspaceRange, oDS, xMin, xMax, $
                                                    yMin, yMax, zMin, zMax
  compile_opt idl2, hidden

  oTool = self->GetTool()
  
  oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
  
  ; Retrieve the SetProperty operation.
  oSetProp = oTool->GetService("SET_PROPERTY")

  oCmd = OBJ_NEW()

  ; Set minimum and maximum dataspace range values
  if (N_ELEMENTS(xMin) && FINITE(xMin)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'X_MINIMUM', xMin)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(xMax) && FINITE(xMax)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'X_MAXIMUM', xMax)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(yMin) && FINITE(yMin)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'Y_MINIMUM', yMin)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (N_ELEMENTS(yMax) && FINITE(yMax)) then begin
    oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
      'Y_MAXIMUM', yMax)
    if (OBJ_VALID(oCmdTmp)) then begin
      oCmdTmp->SetProperty, NAME='Zoom'
      oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
    endif
  endif
  if (oDS->Is3D()) then begin
    if (N_ELEMENTS(zMin) && FINITE(zMin)) then begin
      oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
        'Z_MINIMUM', zMin)
      if (OBJ_VALID(oCmdTmp)) then begin
        oCmdTmp->SetProperty, NAME='Dataspace reset'
        oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
      endif
    endif
    if (N_ELEMENTS(zMax) && FINITE(zMax)) then begin
      oCmdTmp = oSetProp->DoAction(oTool, oDS->GetFullIdentifier(), $
        'Z_MAXIMUM', zMax)
      if (OBJ_VALID(oCmdTmp)) then begin
        oCmdTmp->SetProperty, NAME='Dataspace reset'
        oCmd = (N_ELEMENTS(oCmd) eq 0) ? oCmdTmp : [oCmd, oCmdTmp]
      endif
    endif
  endif
  
  if (~wasDisabled) then $
      oTool->EnableUpdates
      
  return, oCmd

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method does the action of reseting the ranges of a dataspace.
;
; Result:
;   This function returns a reference to an IDLitCommandSet object that
;     contains all commands required to perform the action.
;
; Arguments:
;   oTool:  A reference to an IDLitTool object that is
;     requesting the action to take place.
;
function IDLitopDataspaceReset::DoAction, oTool, SELECTION=oSel
  compile_opt hidden, idl2

  ; Make sure we have a tool.
  if (~ISA(oTool) || ~OBJ_ISA(oTool, 'IDLitTool')) then $
    oTool = self->GetTool()
  if (~OBJ_VALID(oTool)) then return, OBJ_NEW()

  if (N_ELEMENTS(oSel) eq 0) then begin
    ; Grab the window.
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
      return, OBJ_NEW()
    oSel = (oWin->GetSelectedItems())
  endif
    
  ; Get Dataspaces
  for i=0,N_ELEMENTS(oSel)-1 do begin
    if (OBJ_VALID(oSel[i]) && $
      OBJ_ISA(oSel[i], '_IDLitVisualization')) then begin
      oDSTmp = oSel[i]->GetDataSpace()
      if (OBJ_VALID(oDSTmp)) then $
        oDS = N_ELEMENTS(oDS) eq 0 ? [oDSTmp] : [oDS, oDSTmp]
    endif
  endfor
  if (~PRODUCT(OBJ_VALID(oDS))) then return, OBJ_NEW()
  oDS = oDS[UNIQ(oDS,SORT(oDS))]
  

  for i=0,N_ELEMENTS(oDS)-1 do begin
    haveRange = 0b
    oVis = oDS[i]->GetVisualizations(COUNT=count)
    for j=0,count-1 do begin
      ; CR59368: Skip things that don't impact range like axes and text.
      oVis[j]->GetProperty, IMPACTS_RANGE=impactsRange
      if (~impactsRange) then continue

      if (oVis[j]->GetXYZRange(xx,yy,zz, /DATA)) then begin
        ; Convert ranges back from logarithmic axes, if applicable.
        oDS[i]->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
        if (KEYWORD_SET(xLog)) then xx = 10d^xx
        if (KEYWORD_SET(yLog)) then yy = 10d^yy
        if (KEYWORD_SET(zLog)) then zz = 10d^zz
        ; Now find the min/max for all dataspaces.
        xmin = haveRange ? xmin < xx[0] : xx[0]
        xmax = haveRange ? xmax > xx[1] : xx[1]
        ymin = haveRange ? ymin < yy[0] : yy[0]
        ymax = haveRange ? ymax > yy[1] : yy[1]
        zmin = haveRange ? zmin < zz[0] : zz[0]
        zmax = haveRange ? zmax > zz[1] : zz[1]
        haveRange = 1b
      endif
    endfor
    
    if (haveRange && (xmin ne xmax) && (ymin ne ymax)) then begin
      oCmdTmp = self->_SetDataspaceRange(oDS[i],xmin,xmax,ymin,ymax,zmin,zmax)
      if ((OBJ_VALID(oCmdTmp))[0]) then $
        oCmd = N_ELEMENTS(oCmd) eq 0 ? [oCmdTmp] : [oCmd, oCmdTmp]
    endif
    
  endfor
  
  if (N_ELEMENTS(oCmd) eq 0) then return, OBJ_NEW()
  return, oCmd

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitopDataspaceReset object.
;
pro IDLitopDataspaceReset__define
  compile_opt idl2, hidden

  struc = {IDLitopDataspaceReset,       $
           inherits IDLitOperation  $
  }
  
end

