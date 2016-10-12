; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvcopywindow__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; IDLitsrvCopyWindow
;;
;; Purpose:
;;  This file contains the implementation of the IDLitsrvCopyWindow.
;;  This class provides basic functionalty needed to copy the contents
;;  of a IDLitWindow to another output device.
;;
;;  Exploiting the features of the IDL object graphics output devices,
;;  this class will create an manage the ouput device provided by the
;;  user.
;;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvCopyWindow object.
;;
;; Parameters:
;;  strDestClass  - The class name of the output device. This must be
;;                  the class that is an IDLgrSrcDest.
;;
;;-------------------------------------------------------------------------
function IDLitsrvCopyWindow::Init, strDestClass, _extra=_extra
    compile_opt idl2, hidden

    if (not self->IDLitOperation::Init(_extra=_extra)) then $
        return, 0

    if (SIZE(strDestClass, /TYPE) ne 7) then $
        MESSAGE, IDLitLangCatQuery('Message:Framework:InvalidDestClass')

    self._destClass = strDestClass
    self._scale=1
    return, 1
end

;;-------------------------------------------------------------------------
;; IDLitsrvCopyWindow::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitsrvCopyWindow object. Any resources
;; allocated by this object are released.
;;
;; Parameters:
;; None.
;;
;;-------------------------------------------------------------------------
pro IDLitsrvCopyWindow::Cleanup
    compile_opt idl2, hidden
    OBJ_DESTROY, self._oDest
    self->IDLitOperation::Cleanup
end


;;-------------------------------------------------------------------------
;; IDLitsrvCopyWindow::GetProperty
;;
;; Purpose:
;;   The get property method of this object
;;
;; Parameters:
;; None.
;;
;; Keywords:
;;   XOFFSET   - Offset in x direction
;;
;;   YOFFSET   - offset in the y direction
;;
;;   SCALE_FACTOR - Scale factor for the output
;;-------------------------------------------------------------------------
pro IDLitsrvCopyWindow::GetProperty, $
                      XOFFSET=XOFFSET, $
                      YOFFSET=YOFFSET, $
                      SCALE_FACTOR=SCALE_FACTOR, $
                      _REF_EXTRA=_extra
   compile_opt idl2, hidden


   if(arg_present(xoffset))then $
     xoffset=self._offset[0]

   if(arg_present(yoffset))then $
     yoffset=self._offset[1]

   if(ARG_PRESENT(scale_factor))then $
     scale_factor=self._scale

   if (N_ELEMENTS(_extra) gt 0) then $
       self->IDLitOperation::GetProperty, _EXTRA=_extra

end

;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::SetProperty
;;
;; Purpose:
;;   The set property method for this object.
;;
;; Keywords:
;;   XOFFSET   - Offset in x direction
;;
;;   YOFFSET   - offset in the y direction
;;
;;   SCALE_FACTOR - Scale factor for the output
;;
pro IDLitsrvCopyWindow::SetProperty, $
                      XOFFSET=XOFFSET, $
                      YOFFSET=YOFFSET, $
                      SCALE_FACTOR=SCALE_FACTOR, $
                      _EXTRA=_extra
   compile_opt idl2, hidden


   if(n_elements(xoffset) gt 0)then $
     self._offset[0] = xoffset

   if(n_elements(yoffset) gt 0)then $
     self._offset[1] = yoffset

   if(n_elements(scale_factor) gt 0)then $
     self._scale = scale_factor

   if(n_elements(_extra) gt 0)then $
       self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::_InitializeOutputDevice
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

function IDLitsrvCopyWindow::_InitializeOutputDevice, oWindow, oSource
   compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
throwError:
       self->SignalError, [IDLitLangCatQuery('Error:Framework:CopyWindowError'), $
                           !error_state.msg], $
         severity=2
       return, 0
   endif

   ;; Create the singleton graphics destination object.
   if(~obj_valid(self._oDest)) then begin
       ;; Retrieve permanent window properties.
       oWindow->GetProperty, COLOR_MODEL=color_model, $
                             N_COLORS=n_colors
      oDest = OBJ_NEW(self._destClass, $
                      COLOR_MODEL=color_model, $
                      N_COLORS=n_colors)

      ; The OBJ_NEW may actually return a null object, rather than
      ; throwing an error. So if it is null, re-throw the last error.
      if (~OBJ_VALID(oDest)) then $
        goto, throwError

      ;; TODO: Something is killing the id, so I do the following
      self->getproperty,identifier=id
      self._oDest=oDest
      self->setproperty,identifier=id
   endif

   ;;Retrieve current window properties.
   oWindow->GetProperty,PALETTE=palette

   ;; Set the current properties.
   self._oDest->SetProperty, PALETTE=palette

   return, 1
end


;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::_GetViews
;;
;; Purpose:
;;   Return the views that will be copied to the given device
;;
;; Parameters:
;;  oSource   - The source to search for views in
;;
;; Keywords:
;;    COUNT    - Set to the number of items returned
;;
;; Return Value:
;;    The views to copy or obj null if non are found
;;
function IDLitsrvCopyWindow::_GetViews, oSource, COUNT=count
   compile_opt idl2, hidden

   switch 1 of
       ;; Scene or View group....
       obj_isa(oSource, "IDLgrViewGroup"):
       OBJ_ISA(oSource, 'IDLgrScene'): begin
           oChildren = oSource->Get(/ALL, COUNT=countChildren)
           count = 0
           for i=0, countChildren-1 do begin
               oSubchildren = self->_GetViews(oChildren[i], COUNT=subcount)
               if (subcount gt 0) then begin
                   oViews = (count gt 0) ? $
                     [oViews, oSubchildren] : oSubchildren
                   count += subcount
               endif
           endfor
           break
       end
       OBJ_ISA(oSource, 'IDLgrView'): begin
           oViews = oSource
           count = 1
           break
       end

       else: $
           self->SignalError, IDLitLangCatQuery('Error:Framework:NonViewClassCopyError'), $
             severity=2
   endswitch

   return, (count gt 0) ? oViews : OBJ_NEW()

end

;---------------------------------------------------------------------------
; IDLitsrvCopyWindow::_Disable2DImageDepthTest
;
; Purpose:
;   This procedure method disables depth testing on 2D images within the
;   graphics hierarchy.  This is useful when the clipboard is set to
;   produce vector output, in which case only the LESS depth test function
;   can be simulated (the rest of iTools uses the LESS_EQUAL depth test
;   function).  Thus, for example, if an image appears before a contour
;   within the hierarchy, but both are at the same Z depth, then the
;   image would "win" (if depth testing were enabled).  This would be
;   an undesirable result, so this function offers a way around it.
;
; Arguments:
;   oParent: A reference to the root object at which the search
;     for images should begin.
;
; Keywords:
;   COUNT: Set this keyword to a named variable that upon return will
;     contain the number of images for which depth testing was disabled.
;
; Return Value;
;   This function returns a vector of references to the images for which
;   depth testing was disabled.
;
function IDLitsrvCopyWindow::_Disable2DImageDepthTest, oParent, $
    COUNT=count

    compile_opt idl2, hidden

    count = 0
    oImages = OBJ_NEW()

    if (OBJ_ISA(oParent, 'IDL_Container')) then begin
        oChildren = oParent->IDL_Container::Get(/ALL, COUNT=nChild)
        for i=0,nChild-1 do begin
            oSubImages = self->_Disable2DImageDepthTest(oChildren[i], $
                COUNT=subCount)
            if (subCount gt 0) then begin
                oImages = (count eq 0) ? oSubImages : [oImages, oSubImages]
                count += subCount
            endif
        endfor
    endif else begin
        if (OBJ_ISA(oParent, 'IDLgrImage')) then begin
            oImg = oParent
            ; Check if dataspace is 2D.
            ; Seek parent _IDLitVisualization.
            oImg->GetProperty, _PARENT=imgParent
            while (~OBJ_ISA(imgParent, '_IDLitVisualization')) do begin
                if (~OBJ_VALID(imgParent)) then $
                    break
                oTmp = imgParent
                oTmp->GetProperty, _PARENT=imgParent
            endwhile
            if (OBJ_ISA(imgParent, '_IDLitVisualization')) then begin
                oDS = imgParent->GetDataSpace()
                if (OBJ_VALID(oDS)) then begin
                    if (~oDS->Is3D()) then begin
                        ; Dataspace is 2D, so image should be considered
                        ; to be 2D too.
                        oImg->GetProperty, DEPTH_TEST_DISABLE=dtd
                        if (~KEYWORD_SET(dtd)) then begin
                            ; Temporarily disable.
                            oImg->SetProperty, DEPTH_TEST_DISABLE=1
                            count = 1
                            oImages = oImg
                       endif
                   endif
                endif
            endif
        endif
    endelse

    return, oImages
end

;---------------------------------------------------------------------------
; IDLitsrvCopyWindow::_ReEnable2DImageDepthTest
;
; Purpose:
;   This procedure method re-enables depth testing on 2D images within the
;   graphics hierarchy (that had temporarily had their depth testing
;   disabled via IDLitsrvCopyWindow::_Disable2DImageDepthTest).
pro IDLitsrvCopyWindow::_ReEnable2DImageDepthTest, oImages
    compile_opt idl2, hidden

    nImg = N_ELEMENTS(oImages)
    for i=0,nImg-1 do $
        oImages[i]->SetProperty, DEPTH_TEST_DISABLE=0
end

;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::EndDraw
;;
;; Purpose:
;;   This method is called after the draw action has taken place and
;;   allows the sub-class to perform any actions on the output
;;   device.
pro IDLitsrvCopyWindow::EndDraw, oDevice
    compile_opt hidden, idl2

    ;; nothing.

end


;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::DoWindowCopy
;;
;; Purpose:
;;    DoAction helper method. Scales all the contained views, then calls
;;    self->Draw, then restores the view dimensions & locations.
;;
;; Parameters:
;;    oWindow   - The IDLitWindow being copied.
;;
;;    oSource:  - An IDLgrScene, IDLgrViewgroup, or IDLgrView to draw.
;;
;; Return Value:
;;    0 - Error
;;    1 - Success

function IDLitsrvCopyWindow::DoWindowCopy, oWindow, oSource, $
    VECTOR=vector, $
    _EXTRA=_extra   ; Note (CT): Do *not* change this to _REF_EXTRA

   compile_opt idl2, hidden

   ;; Set up our device
   if(~self->_InitializeOutputDevice(oWindow, oSource))then $
     return, 0

   ;; Retrieve all contained IDLgrViews.
   oViews = self->_GetViews(oSource, COUNT=nViews)
   if (nViews eq 0) then $
     return, 0

   ;; If this is a IDLitgrView, get the offset of the location.
   if(obj_isa(oSource, "IDLitgrView"))then $
     oSource->getproperty, location=srcOffset $
   else $
     srcOffset=[0,0]

   ;; Make sure the scene is transparent. Cleans up output.
   isScene = obj_isa(oSource, "IDLgrScene")
   if(isScene)then begin
       oSource->GetProperty, transparent=transScene
       oSource->SetProperty, /transparent
   endif

    ; Be sure to restrict the maximum scaled dimensions to be less than
    ; the maximum for the clipboard (usually 4096x4096).
    ; Don't do this for the IDLgrPrinter object...
    if (OBJ_ISA(self._oDest, 'IDLgrBuffer')    || $
        OBJ_ISA(self._oDest, 'IDLgrClipboard') || $
        OBJ_ISA(self._oDest, 'IDLgrWindow')    || $
        OBJ_ISA(self._oDest, 'IDLgrPDF')) then begin
      if (isScene) then begin
        oWindow->GetProperty, DIMENSIONS=currDims
      endif else begin
        oSource->GetProperty, DIMENSIONS=currDims
      endelse
      self._oDest->GetProperty, SCREEN_DIMENSIONS=maxDims
      self._scale = self._scale < MIN(DOUBLE(maxDims)/currDims)
    endif
    
   ;; Stash all view dimensions and locations.
   save_loc_dims = DBLARR(4, nViews)
   do_hide = BYTARR(nViews)
   ;; Loop thru all views and modify dimensions & location.
   for i=0, nViews-1 do begin

       oViews[i]->IDLgrView::GetProperty, $
                DIMENSIONS=old_dimensions, $
                LOCATION=old_location, $
                NAME=name
       ;; CT: Outline around the views.
       ;; If the name "Outline" ever changes we need to change this.
       make_hidden = 1
       if (name eq 'Outline') then $
         do_hide[i] = 1 $
       else $
         dummy = TEMPORARY(make_hidden)
        save_loc_dims[*,i] = [old_location,old_dimensions]
        ;; Set to our new destination dimensions and locations.
        oViews[i]->IDLgrView::SetProperty, $
          HIDE=make_hidden, $   ; usually an undefined var
          DIMENSIONS=old_dimensions*self._scale, $
          LOCATION=(old_location + self._offset - srcOffset)*self._scale

        if (KEYWORD_SET(vector)) then begin
            ;; Disable depth testing for any contained 2D images.
            oView2DImgs = self->_Disable2DImageDepthTest(oViews[i], $
                COUNT=nView2DImg)
            if (nView2DImg gt 0) then $
                o2DImgs = (N_ELEMENTS(o2DImgs) eq 0) ? oView2DImgs : $
                    [o2DImgs, oView2DImgs]
        endif
    endfor

    ;; Now disable any selection visuals.
    oVis = oWindow->GetSelectedItems(count=nVis)
    for i=0,nVis-1 do begin
        if (~OBJ_VALID(oVis[i])) then $
            continue
        ;; Does the currently selected item have a selection visual?
        oSelVis = oVis[i]->GetCurrentSelectionVisual()
        if (OBJ_VALID(oSelVis)) then begin
            oSelVis->IDLgrComponent::GetProperty, HIDE=hide
            if (~hide) then begin
                ; Turn off selection visual and cache our objref.
                oSelVis->IDLgrComponent::SetProperty, /HIDE
                oSelVisual = (n_elements(oSelVisual) gt 0 ? $
                              [oSelVisual, oSelVis] : oSelVis)
            endif
        endif
        ;; See if we need to also turn off our manipulator target's
        ;; selection visual.
        oManipTarget = oVis[i]->GetManipulatorTarget()
        if (oManipTarget ne oVis[i]) then begin
            oVis[i] = oManipTarget
            i--                 ; go thru the loop again
        endif
    endfor
    ;; Here we go...

    ; Not all destinations accept the VECTOR keyword, so just append
    ; it to the _extra struct.
    myextra = {VECTOR: KEYWORD_SET(vector)}
    if (N_ELEMENTS(_extra) gt 0) then $
        myextra = CREATE_STRUCT(_extra, myextra)
    self._oDest->Draw, oSource, _EXTRA=myextra

    ;; Call post draw routine.
    self->EndDraw, self._oDest
    ;; Now to restore everything back to our pre-copy state.

    ;; Re-enable depth testing for any contained 2D images.
    if ((KEYWORD_SET(vector)) && (N_ELEMENTS(o2DImgs) gt 0)) then $
        self->_ReEnable2DImageDepthTest, o2DImgs

    ;; Turn all the selection visuals back on.
    for i=0,N_ELEMENTs(oSelVisual)-1 do $
        oSelVisual[i]->IDLgrComponent::SetProperty, HIDE=0

    ;; Restore my original viewplane_rect.
    for i=0,nViews-1 do begin
        ;; Show outline again
        make_hidden = 0
        ;; We need to do this temp trick to avoid showing Views
        ;; that were indeed hidden before our draw.
        if (do_hide[i] eq 0) then $
          dummy = TEMPORARY(make_hidden)
        oViews[i]->IDLgrView::SetProperty, $
          HIDE=make_hidden, $   ; usually an undefined var
          DIMENSIONS=save_loc_dims[2:3,i], $
          LOCATION=save_loc_dims[0:1,i]
    endfor
    if(isScene)then $
      oSource->SetProperty, transparent=transScene

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitsrvCopyWindow::DoAction
;;
;; Purpose:
;;   Should be overridden by subclass.
;;
;; Parameters:
;;   oTool
;;
function IDLitsrvCopyWindow::DoAction, oTool, _EXTRA=ex

    compile_opt idl2, hidden

    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return, OBJ_NEW()
    self->DoWindowCopy, oWindow, oWindow->GetScene(), _EXTRA=ex

    ;; Cannot "undo" a copy/print.
    return, obj_new()
end


;;-------------------------------------------------------------------------
;; IDLitsrvCopyWindow::GetDevice
;;
;; Purpose:
;;   Return the current output device.
;;
;;
function IDLitsrvCopyWindow::GetDevice
  compile_opt hidden, idl2
  if(~obj_valid(self._oDest))then begin
      oTool = self->GetTool()
      if (~OBJ_VALID(oTool)) then $
          return, OBJ_NEW()
      oWin = oTool->GetCurrentWindow()
      if (~OBJ_VALID(oWin)) then $
          return, OBJ_NEW()
      if(~self->_InitializeOutputDevice(oWin, obj_new()))then $
        return, obj_new()
  endif

  return, self._oDest
end
;-------------------------------------------------------------------------
pro IDLitsrvCopyWindow__define

    compile_opt idl2, hidden
    struc = {IDLitsrvCopyWindow, $
             inherits IDLitOperation,    $
             _oDest    : OBJ_NEW(), $
             _destClass: '', $
             _offset   : lonarr(2), $
             _scale    : dblarr(2)}


end

