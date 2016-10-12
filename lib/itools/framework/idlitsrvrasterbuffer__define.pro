; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvrasterbuffer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; IDLitsrvRasterBuffer
;;
;; Purpose:
;;  This file contains the implementation of the IDLitsrvRasterBuffer.
;;
;;  This class provides a service that allows the contents of a
;;  itWindow to be rendered into a buffer. Once rendered, the contents
;;  of this buffer can be retrived as a data object.
;;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvRasterBuffer::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvRasterBuffer object.
;;
;;-------------------------------------------------------------------------
function IDLitsrvRasterBuffer::Init, _extra=_extra
    compile_opt idl2, hidden

    ;; just call our super-class
    return, self->IDLitsrvCopyWindow::Init("IDLitgrBuffer", $
                                           _extra=_extra)
end

;;-------------------------------------------------------------------------
;; IDLitsrvRasterBuffer::GetProperty
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
pro IDLitsrvRasterBuffer::GetProperty, $
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
;; IDLitsrvRasterBuffer::SetProperty
;;
;; Purpose:
;;   The set property method for this object.
;;
;; Keywords:
;;   RESOLUTION   - The output resolution
;;
;;   DIMENSIONS   - Size of the output device
pro IDLitsrvRasterBuffer::SetProperty, $
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
;; IDLitsrvRasterBuffer::_InitializeOutputDevice
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

function IDLitsrvRasterBuffer::_InitializeOutputDevice, oWindow, oSource
   compile_opt idl2, hidden

   if(~self->IDLitsrvCopyWindow::_InitializeOutputDevice(oWindow))then $
     return, 0

   ;; Basically, make sure the buffer resolution and dimensions are correct.
   oDev = self->GetDevice()

   if(~self._bHaveDims)then begin
       if (~OBJ_VALID(oSource) || OBJ_ISA(oSource, "IDLitgrScene"))then $
         oWindow->Getproperty, dimensions=dims $
       else $
         oSource->Getproperty, dimensions=dims
   endif  else $
     dims = self._dims

   scaleDims = ROUND(dims*self._scale)
   oDev->SetProperty, DIMENSIONS=scaleDims
   
   ; If the new dimensions are larger than the max buffer size
   ; (typically 4096x4096), they will be clipped. For sanity,
   ; retrieve the new dims and recompute the scale factor.
   oDev->GetProperty, DIMENSIONS=newScaleDims
   ; Only recalculate if necessary, to avoid roundoff errors.
   if (~ARRAY_EQUAL(scaleDims, newScaleDims)) then $
     self._scale = DOUBLE(newScaleDims)/dims

   if(~self._bHaveRes)then $
     oWindow->Getproperty, resolution=res $
   else $
     res = self._res

   oDev->SetProperty, resolution=res/self._scale

   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitsrvRasterBuffer::DoWindowCopy
;;
;; Purpose:
;;   Override the super class so the buffer is cleared before use.
;;
;; Parameters:
;;    oWindow   - The IDLitWindow being copied.
;;
;;    oSource:  - An IDLgrScene, IDLgrViewgroup, or IDLgrView to draw.
;;
;; Return Value:
;;    0 - Error
;;    1 - Success

function IDLitsrvRasterBuffer::DoWindowCopy, oWindow, oSource, _EXTRA=_extra
   compile_opt idl2, hidden

   oBuffer = self->GetDevice()
   oBuffer->Erase

   return, self->IDLitsrvCopyWindow::DoWindowCopy(oWindow, oSource, _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; IDLitsrvRasterBuffer::GetData
;
; Purpose:
;  Returns the current contents of the buffer in a image data object
;
; Parameters:
;   data[out] - Will be set to a (3,m,n) image.
;
; Return Value:
;   1 - Success
;   0 - Failure
;
function IDLitsrvRasterBuffer::GetData, data

    compile_opt idl2, hidden

    oDev = self->GetDevice()
    oDev->GetProperty, IMAGE_DATA=data

    return, 1

end


;;-------------------------------------------------------------------------
;; IDLitsrvRasterBuffer__define
;;
;; Purpose:
;;   Class definition.
pro IDLitsrvRasterBuffer__define

    compile_opt idl2, hidden
    struc = {IDLitsrvRasterBuffer, $
             inherits IDLitsrvCopyWindow,    $
             _bHaveDims  : 0b, $
             _bHaveRes   : 0b, $
             _res        : 0d, $
             _dims       : lonarr(2) }
end

