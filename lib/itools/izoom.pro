; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/izoom.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iZoom
;
; PURPOSE:
;   Zooms selection in an iTool
;
; CALLING SEQUENCE:
;   iZoom, zoomFactor, [, TARGET_IDENTIFIER=target] [, /RESET]
;
; INPUTS:
;   ZOOMFACTOR - The percentage by which to zoom the selected visualization.
;                This affect is cumulative, e.g., a second zooming of 200%
;                will result in an overall zoom factor of 400%.
;
; KEYWORD PARAMETERS:
;   TARGET_IDENTIFIER - The identifier of the view to zoom. If not supplied,
;                       the first view in the current tool will be used.
;
;   RESET - If set, reset the zoom factor to 100% before performing any
;           zooming supplied via ZOOMFACTOR. Using this keyword is the same 
;           as setting an absolute zoom factor instead of a cumulative, or 
;           relative, zoom factor.
;                              
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Sep 2008
;
;-

;-------------------------------------------------------------------------
PRO iZoom, zoomIn, CENTER=centerIn, RESET=resetIn, $
                   TARGET_IDENTIFIER=ID, CURRENT=zoomFactor, _EXTRA=_extra 
  compile_opt hidden, idl2

@idlit_itoolerror.pro

  noInput = 0b
  if (N_ELEMENTS(zoomIn) eq 0) then begin
    if (KEYWORD_SET(resetIn)) then begin
      zoomIn = 1.0d
    endif else begin
      ;; No input, possibly bail
      if (~ARG_PRESENT(zoomFactor)) then $
        return
      noInput = 1b
      zoomIn = 1.0d
    endelse
  endif
  
  if (N_ELEMENTS(ID) eq 0) then begin
    fullID = iGetCurrent()
  endif else begin
    fullID = (iGetID(ID, _EXTRA=_extra))[0]
  endelse

  zoomFac = double(zoomIn[0]) > 0.01d
  useCenter = 0

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  ;; Get tool and window
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then return
  oWin = oTool->GetCurrentWindow()
  if (~OBJ_VALID(oWin)) then return

  ; Retrieve previous zoom factor.
  oWin->GetProperty, CURRENT_ZOOM=initialZoom, VIRTUAL_HEIGHT=vHeight, $
                     VIRTUAL_WIDTH=vWidth, VISIBLE_LOCATION=vLocation

  ; Parse the new zoom factor string.
  zoomFactor = KEYWORD_SET(resetIn) ? zoomFac : zoomFac * initialZoom

  if (noInput) then $
    return
  
  if (N_ELEMENTS(centerIn) eq 2) then begin
    center = (iConvertCoord(centerIn, /TO_DEVICE, TARGET_IDENTIFIER=fullID, $
                            _EXTRA=_extra))[0:1]
    useCenter = 1
    ;; Constrain center to canvas
    prevCenter = center > [0, 0] < [vWidth, vHeight]
    ;; Adjust for visible location to get current window location
    offset = prevCenter - vLocation
    normPrevCenter = prevCenter / initialZoom
    newCenter = normPrevCenter * zoomFactor
    newLocation = newCenter - offset
  endif                   
  
  oSetProp = oTool->GetService('SET_PROPERTY')
  if (OBJ_VALID(oSetProp)) then begin
    oCmd = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
      'CURRENT_ZOOM', zoomFactor)
    if (OBJ_VALID(oCmd)) then begin
      oCmd->SetProperty, NAME='Zoom'
      if (useCenter) then begin
        oCmd2 = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
          'VISIBLE_LOCATION', newLocation)
        if (OBJ_VALID(oCmd2)) then begin
          oCmd2->SetProperty, NAME='Zoom'
          oCmd = [oCmd, oCmd2]
        endif
      endif
    endif
  endif

  ; Add to undo/redo buffer
  oTool->_TransactCommand, oCmd
  ; We don't always get a redraw event on zoom, so do it manually.
  oTool->RefreshCurrentWindow

end
