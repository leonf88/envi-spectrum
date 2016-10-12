; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvpdf__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; IDLitsrvPDF
;
; Purpose:
;  This file contains the implementation of the IDLitsrvPDF.
;  This class provides a printer service that the entire system can use.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitsrvPDF::Init
;
; Purpose:
;    The constructor of the IDLitsrvPDF object.
;
;-------------------------------------------------------------------------
function IDLitsrvPDF::Init, _extra=_extra
    compile_opt idl2, hidden

    ; Just call our super class
    return, self->IDLitsrvCopyWindow::Init("IDLgrPDF", $
                                           _extra=_extra)
end


;-------------------------------------------------------------------------
function IDLitsrvPDF::DoWindowCopy, oWindow, oSource, $
  CENTIMETERS=centimeters, $
  RESOLUTION=resolution, $
  FILENAME=filename, $
  HEIGHT=height, $
  LANDSCAPE=landscape, $
  PAGE_SIZE=pageSize, $
  WIDTH=width, $
  XMARGIN=xmargin, $
  YMARGIN=ymargin, $
  _EXTRA=_extra   ; Note (CT): Do *not* change this to _REF_EXTRA

  if(~self->_InitializeOutputDevice(oWindow, oSource))then $
    return, 0

  centimeters = KEYWORD_SET(centimeters)
  if (~ISA(pageSize) || pageSize[0] eq 0) then begin
    ; This is true even for landscape.
    pageSize = [8.5d, 11]
  endif else begin
    ; Always convert to inches
    if centimeters then pageSize /= 2.54d
  endelse

  if (~ISA(width) || width eq 0) then begin
    width = pageSize[0]*0.9
  endif else begin
    ; Always convert to inches
    if centimeters then width /= 2.54d
  endelse

  if (~ISA(height) || height eq 0) then begin
    height = pageSize[1]*0.9
  endif else begin
    ; Always convert to inches
    if centimeters then height /= 2.54d
  endelse

  ; Always convert to inches
  if (ISA(xmargin) && centimeters) then xmargin /= 2.54d
  if (ISA(ymargin) && centimeters) then ymargin /= 2.54d

  oDev = self->GetDevice()
  oDev->IDLgrPDF::Clear
  oDev->SetProperty, UNITS=1  ; inches
  oDev->IDLgrPDF::AddPage, DIMENSIONS=pageSize, LANDSCAPE=landscape

  ; Some graphics objects assume device coordinates.
  oDev->SetProperty, UNITS=0
  
  ; Get dimensions
  oWindow->GetProperty, DIMENSIONS=winDims
  oDev->GetProperty, SCREEN_DIMENSIONS=maxDims

  ; Make some assumptions about the page.
  bounds   = ([width, height] * resolution) < maxDims
  
  ; Figure out the best dimensions and resolution to fit the plot on page
  self._scale = min(bounds/winDims)
  dimensions  = winDims*self._scale

  ; For /LANDSCAPE we need to flip the page size when computing the offset.
  if KEYWORD_SET(landscape) then pagesize = pagesize[[1,0]]
  offset      = (pagesize*resolution - dimensions) / 2.

  if (ISA(xmargin)) then offset[0] = xmargin*resolution
  if (ISA(ymargin)) then offset[1] = ymargin*resolution

;  if KEYWORD_SET(landscape) then offset = offset[[1,0]]

  cmPerPixel  = 2.54 / resolution

  oDev->SetProperty, DIMENSIONS=dimensions, $
                     RESOLUTION=[cmPerPixel, cmPerPixel], $
                     LOCATION=offset
  
  success = self->IDLitSrvCopyWindow::DoWindowCopy(oWindow, oSource, _EXTRA=_extra)
  if (~success) then return, 0
  
  oDev->Save, filename
  return, 1
end


;-------------------------------------------------------------------------
; IDLitsrvPDF__define
;
; Purpose:
;   Class definition.
pro IDLitsrvPDF__define

    compile_opt idl2, hidden
    struc = {IDLitsrvPDF, $
             inherits IDLitsrvCopyWindow }

end

