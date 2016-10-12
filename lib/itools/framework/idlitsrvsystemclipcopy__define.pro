; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvsystemclipcopy__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; IDLitsrvSystemClipCopy
;;
;; Purpose:
;;  This file contains the implementation of the IDLitsrvSystemClipCopy.
;;  This class provides a method to copy a viz tree to the clipboard.
;;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvSystemClipCopy::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvSystemClipCopy object.
;;
;;-------------------------------------------------------------------------
function IDLitsrvSystemClipCopy::Init, _extra=_extra
    compile_opt idl2, hidden

    ;; just call our super-class
    return, self->IDLitsrvCopyWindow::Init("IDLitgrClipboard", $
                                           _extra=_extra)
end

;;-------------------------------------------------------------------------
;; IDLitsrvSystemClipCopy::GetProperty
;;
;; Purpose:
;;   The get property method of this object
;;
;; Parameters:
;;    None.
;;
;; Keywords
;;   RESOLUTION   - The output resolution
;;
;;   DIMENSIONS   - Size of the output device
;;-------------------------------------------------------------------------
pro IDLitsrvSystemClipCopy::GetProperty, $
                          RESOLUTION=RESOLUTION, $
                          DIMENSIONS=DIMENSIONS, $
                          _REF_EXTRA=_extra
   compile_opt idl2, hidden

   if(ARG_PRESENT(DIMENSIONS))then $
     dimensions=self._dims

   if(ARG_PRESENT(resolution))then $
     resolution=self._res


   if (N_ELEMENTS(_extra) gt 0) then $
       self->IDLitsrvCopyWindow::GetProperty, _EXTRA=_extra
end

;;---------------------------------------------------------------------------
;; IDLitsrvSystemClipCopy::SetProperty
;;
;; Purpose:
;;   The set property method for this object.
;;
;; Keywords:
;;   RESOLUTION   - The output resolution
;;
;;   DIMENSIONS   - Size of the output device
pro IDLitsrvSystemClipCopy::SetProperty, $
                          DIMENSIONS=DIMENSIONS, $
                          RESOLUTION=RESOLUTION, $
                          _EXTRA=_extra
   compile_opt idl2, hidden

   if(n_elements(dimensions) gt 0)then begin
       self._bHaveDims=1
       self._dims = dimensions
   endif

   if(n_elements(resolution) gt 0)then begin
       self._bHaveRes=1
       self._res = resolution
   endif

   if(n_elements(_extra) gt 0)then $
       self->IDLitsrvCopyWindow::SetProperty, _EXTRA=_extra

end

;;---------------------------------------------------------------------------
;; IDLitsrvSystemClipCopy::_InitializeOutputDevice
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

function IDLitsrvSystemClipCopy::_InitializeOutputDevice, oWindow, oSource
   compile_opt idl2, hidden

   if(~self->IDLitsrvCopyWindow::_InitializeOutputDevice(oWindow))then $
     return, 0

   oDev = self->GetDevice()

   if(~self._bHaveRes)then $
     oWindow->Getproperty, resolution=res $
   else $
     res = self._res

   oDev->SetProperty, resolution=res/self._scale

   if(~self._bHaveDims)then begin
       if(obj_isa(oSource ,"IDLitgrScene"))then $
         oWindow->Getproperty, dimensions=dims $
       else $
         oSource->Getproperty, dimensions=dims
   endif else $
     dims = self._dims

   oDev->SetProperty, dimensions=dims*self._scale

   return, 1
end


;-------------------------------------------------------------------------
pro IDLitsrvSystemClipCopy__define

    compile_opt idl2, hidden
    struc = {IDLitsrvSystemClipCopy, $
             inherits IDLitsrvCopyWindow,    $
             _bHaveDims  : 0b, $
             _bHaveRes   : 0b, $
             _res        : 0d, $
             _dims       : 0l }
end

