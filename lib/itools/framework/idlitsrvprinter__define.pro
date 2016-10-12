; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvprinter__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; IDLitsrvPrinter
;;
;; Purpose:
;;  This file contains the implementation of the IDLitsrvPrinter.
;;  This class provides a printer service that the entire system can use.
;;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvPrinter::Init
;;
;; Purpose:
;;    The constructor of the IDLitsrvPrinter object.
;;
;;-------------------------------------------------------------------------
function IDLitsrvPrinter::Init, _extra=_extra
    compile_opt idl2, hidden

    ;; Just call our super class
    return, self->IDLitsrvCopyWindow::Init("IDLgrPrinter", $
                                           _extra=_extra)
end
;;---------------------------------------------------------------------------
;; IDLitsrvPrinter::EndDraw
;;
;; Purpose:
;;   Called when the drawing process is finished. We override this to
;;   send and end document call.

pro IDLitsrvPrinter::EndDraw, oDevice
   compile_opt hidden, idl2

   oDevice->NewDocument

end
;;---------------------------------------------------------------------------
;; IDLitsrvPrinter::_InitializeOutputDevice
;;
;; Purpose:
;;   Verify that the output device is setup to match our window
;;   attributes
;;
;; Parameters:
;;   oWindow
;;
;; Return Value:
;;   0 - Error
;;   1 - Success

function IDLitsrvPrinter::_InitializeOutputDevice, oWindow, oSource
   compile_opt idl2, hidden

   if(~self->IDLitsrvCopyWindow::_InitializeOutputDevice(oWindow))then $
     return, 0

   oDev = self->GetDevice()

   ;; Setup our scaling factor if one hasn't been set. This will
   ;; enable WYSIWYG
   if(self._bHasScale eq 0)then begin
       oDev->GetProperty, DIMENSION=printdim, resolution=printRes
       oWindow->GetProperty, DIMENSIONS=windim, resolution = winRes
       self->IDLitsrvCopyWindow::setProperty, scale_factor= winRes/printRes, $
                                              xoffset=0, yoffset=0
   endif

   return, 1
end

;;---------------------------------------------------------------------------
;; IDLitsrvPrinter::DoAction
;;
;; Purpose:
;;   Sets properties on the device and executes the print
;;
;; Parameters:
;;   oTool
;;
FUNCTION IDLitsrvPrinter::DoAction, oTool, $
    PRINT_NCOPIES=ncopies, $
    PRINT_ORIENTATION=print_orientation, $
    PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
    PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
    PRINT_UNITS=print_units, PRINT_CENTER=print_center, $
    _EXTRA=_extra

  compile_opt idl2, hidden

  oWindow = oTool->GetCurrentWindow()
  if (~OBJ_VALID(oWindow)) then $
    return, OBJ_NEW()

  ;; get print settings from window
  oWindow->GetProperty, dimensions=windim, resolution=winRes

    oDev = self->GetDevice()
    oDev->SetProperty, LANDSCAPE=KEYWORD_SET(print_orientation), $
      N_COPIES=ncopies
    oDev->GetProperty, DIMENSION=printdim, resolution=printRes

    offset = [0d, 0d]
    if N_ELEMENTS(print_xmargin) then offset[0] = print_xmargin
    if N_ELEMENTS(print_ymargin) then offset[1] = print_ymargin

    dims = [0d, 0d]
    if N_ELEMENTS(print_width) then dims[0] = print_width
    if N_ELEMENTS(print_height) then dims[1] = print_height

    ;; convert from inches to centimeters if needed
    IF ~KEYWORD_SET(print_units) THEN BEGIN
      offset *= 2.54d
      dims *= 2.54d   ; centimeters
    ENDIF

    scale = dims/(winRes*winDim)    ; no units
    ; Just pick the largest scale factor for both.
    scale >= MAX(scale)
    IF min(scale) eq 0 THEN scale=[1.0, 1.0]
    scale *= winRes    ; cm/pixel

    scale = scale/printRes

    ; This offset is in Window pixels.
    offset = KEYWORD_SET(print_center) ? $
        (printdim/scale - winDim)/2d : offset/(scale*printRes)

    self->SetProperty, XOFFSET=offset[0], YOFFSET=offset[1], $
        SCALE=scale

  ;; get vector setting
  oGeneral = $
    oTool->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
  oGeneral->GetProperty,PRINTER_OUTPUT_FORMAT=printVec

  void = self->DoWindowCopy(oWindow, oWindow->GetScene(), $
                            VECTOR=printVec, _EXTRA=_extra)

  ;; Cannot "undo" a copy/print.
  return, obj_new()

END

;;-------------------------------------------------------------------------
;; IDLitsrvPrinter::SetProperty
;;
;; Purpose:
;;   Used to catch the setting of the scale factor property
;;
pro IDLitsrvPrinter::SetProperty, scale_factor=scale_factor, $
                   default_scale=default_scale,$
                   _EXTRA=_EXTRA

    compile_opt hidden, idl2

    if(n_elements(default_scale) gt 0)then $
      self._bHasScale=0

    if(n_elements(scale_factor) gt 0)then $
      self._bHasScale=1

    if(n_elements(_extra) gt 0)then $
      self->IDLitSrvCopyWindow::SetProperty, _extra=_extra, $
      scale_factor=scale_factor
end
;;-------------------------------------------------------------------------
;; IDLitsrvPrinter__define
;;
;; Purpose:
;;   Class definition.
pro IDLitsrvPrinter__define

    compile_opt idl2, hidden
    struc = {IDLitsrvPrinter, $
             inherits IDLitsrvCopyWindow, $
            _bHasScale : 0b} ;; has the user set the scale factor

end

