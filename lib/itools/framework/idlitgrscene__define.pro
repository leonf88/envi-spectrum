; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrscene__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitgrScene
;
; PURPOSE:
;    The IDLitgrScene class represents the entire scene to be drawn
;    within a destination object (such as an IDLitWindow or IDLitBuffer).
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;    IDLgrScene
;
; MODIFICATION HISTORY:
;    Written by:    DLD, Mar. 2001.
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::Init
;
; PURPOSE:
;    Initializes an IDLitgrScene object.
;
; CALLING SEQUENCE:
;    oScene = OBJ_NEW('IDLitgrScene', oDestination)
;
;        or
;
;    Result = oScene->[IDLitgrScene::]Init(oDestination)
;
; INPUTS:
;    oDestination:    A reference to a destination object (window
;        or buffer) in which this scene will be drawn.
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 if initialization
;    fails.
;
;-
function IDLitgrScene::Init, oDestination, _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLgrScene::Init(/REGISTER_PROPERTIES, $
        NAME='IDLitgrScene', DESCRIPTION='Scene', _EXTRA=_extra, $
        color=[200,200,200]) ne 1) then $
        RETURN, 0

    self.oDest = oDestination

    self.geomRefCount = 0UL

    ; Register property descriptors.
    self->RegisterProperty, 'DESTINATION', USERDEF='', $
            DESCRIPTION='Destination in which scene appears'

    RETURN, 1
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::Cleanup
;
; PURPOSE:
;    Performs all cleanup for an IDLitgrScene object.
;
; CALLING SEQUENCE:
;    OBJ_DESTROY, oScene
;
;        or
;
;    oScene->[IDLitgrScene::]Cleanup
;
;-
;pro IDLitgrScene::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup the superclass.
;    self->IDLgrScene::Cleanup
;
;end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::GetProperty
;
; PURPOSE:
;    The IDLitgrScene::GetProperty procedure method retrieves the
;    value of a property or group of properties.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]GetProperty
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitgrScene::Init followed by the word "Get"
;    can be retrieved using IDLitgrScene::GetProperty.  In addition
;    the following keywords are available:
;
;    DESTINATION    Set this keyword to a named variable that upon return
;        will contain a reference to the destination object in which the
;        scene is drawn.
;
;-
pro IDLitgrScene::GetProperty, DESTINATION=oDestination, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(oDestination)) then $
        oDestination = self.oDest

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLgrScene::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
; IIDLScene Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::GetCurrentView
;
; PURPOSE:
;    Retrieves the current View within the scene.
;
; CALLING SEQUENCE:
;    oView = oScene->[IDLitgrScene::]GetCurrentView()
;
; OUTPUTS:
;    This function method returns a reference to an IDLitgrView.
;
;-
function IDLitgrScene::GetCurrentView

    compile_opt idl2, hidden

    if (~OBJ_VALID(self.oCurrView) || ~self->IsContained(self.oCurrView)) then begin
        oView = self->Get(COUNT=count)
        if (count eq 0) then begin
            ; If the destination is a layout manager, allow it
            ; to manage creation of the view.
            if (OBJ_ISA(self.oDest, "_IDLitLayoutManager")) then begin
                self.oDest->CreateView
            endif else begin
                ; Create a new view and add it.
                if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then $
                    oTool = self.oDest->GetTool()
                oView = OBJ_NEW('IDLitgrView', NAME='View_1', TOOL=oTool)
                self->Add, oView

            endelse

            oView = self->Get(COUNT=count)
        endif

        if (count gt 0) then $
            self->SetCurrentView, oView[0]
    endif

    RETURN, self.oCurrView
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::SetCurrentView
;
; PURPOSE:
;    Sets the current View within the scene.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]SetCurrentView, oView
;
; INPUTS:
;    oView:    A reference to an IDLitgrView that is to
;        become the current View within the scene.
;
;-
pro IDLitgrScene::SetCurrentView, oView

    compile_opt idl2, hidden

    ; Verify that the given View is contained within the scene.
    if (self->IsContained(oView) eq 0) then $
      return

    ; Unselect the previous view.
    if (OBJ_VALID(self.oCurrview)) then begin
        ; If already current view, do nothing.
        if (self.oCurrView eq oView) then $
            return

        self.oCurrView->SetSelectVisual, /UNSELECT
    endif

    self.oCurrView = oView
    self.oCurrView->SetSelectVisual

    ; Update the view zoom control in the toolbar to reflect
    ; the zoom factor of the newly selected view.
    oView->GetProperty, CURRENT_ZOOM=viewZoom
    oTool = oView->GetTool()
    if (OBJ_VALID(oTool)) then begin
        id = oTool->GetFullIdentifier() + "/TOOLBAR/VIEW/VIEWZOOM"
        oTool->DoOnNotify, id, 'SETVALUE', $
            STRTRIM(ULONG((viewZoom*100)+0.5),2)+'%'
    endif
end

;----------------------------------------------------------------------------
; IIDLResizeObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::OnResize
;
; PURPOSE:
;    Handles notification of a resize of the destination.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]OnResize, oNotifier, width, height
;
; INPUTS:
;    oNotifier: A reference to the destination object that has been resized.
;    width: The new width of the destination.
;    height: The new height of the destination.
;
;-
pro IDLitgrScene::OnResize, oNotifier, width, height

    compile_opt idl2, hidden

    ; Grab the Views.
    oViewArr = self->Get(ISA='IDLitgrView', /ALL, $
                         COUNT=nViews)
    if (nViews eq 0) then $
        RETURN

    ; Notify each of the Views.
    for i=0, nViews-1 do $
        oViewArr[i]->OnResize, oNotifier, width, height


    ; A change in the window size can change availability,
    ; so update.
    if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then begin
        oTool = self.oDest->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->UpdateAvailability
    endif

    ; Our window has width and height properties which may need to
    ; change if the property sheet is currently displayed.
    if (OBJ_ISA(oNotifier, 'IDLitIMessaging')) then $
        oNotifier->DoOnNotify, oNotifier->GetFullIdentifier(), $
            'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::OnZoom
;
; PURPOSE:
;    Handles notification of a zoom of the destination.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]OnResize, oNotifier, width, height
;
; INPUTS:
;    oNotifier: A reference to the destination object that has been zoomed.
;    width: The new width of the destination.
;    height: The new height of the destination.
;
;-
pro IDLitgrScene::OnZoom, oNotifier, width, height

    compile_opt idl2, hidden

    ; Grab the Views.
    oViewArr = self->Get(ISA='IDLitgrView', /ALL, $
                         COUNT=nViews)
    if (nViews eq 0) then $
        RETURN

    ; Notify each of the Views.
    for i=0, nViews-1 do $
        oViewArr[i]->OnCanvasZoom, oNotifier, width, height
end


;----------------------------------------------------------------------------
; IIDLScrollObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::OnScroll
;
; PURPOSE:
;    The IDLitgrScene::OnScroll procedure method crops the
;    contained Views to the visible portion of a scrolling
;    destination.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]OnScroll, oNotifier, ScrollX, ScrollY
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the scroll.
;    ScrollX, ScrollY:    The coordinates (in device units, relative
;        to the virtual canvas) of the lower-left corner of the
;        visible area of the scrolled destination.
;
;-
pro IDLitgrScene::OnScroll, oNotifier, ScrollX, ScrollY

    compile_opt idl2, hidden

    ; Grab the Views.
    oViewArr = self->Get(ISA='IDLitgrView', /ALL, $
        COUNT=nViews)
    if (nViews eq 0) then $
        RETURN

    ; Notify each of the Views.
    for i=0, nViews-1 do $
        oViewArr[i]->OnCanvasScroll, oNotifier, ScrollX, ScrollY

    if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then begin
        oTool = self.oDest->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif else $
        self.oDest->Draw
end
;;---------------------------------------------------------------------------
;; IDLitgrScene::GetSelectedItems
;;
;; Purpose:
;;   Returns the set of currently selected items for the current view.
;;
;; Keywords:
;;   count   - The number of items returned.
function IDLitgrScene::GetSelectedItems, count=count, all=all

    compile_opt idl2, hidden

    ;; Return the values contained in the current view. If no view
    ;; is current, return null.
    if(not obj_valid(self.oCurrView))then begin
        count =0
        return, obj_new()
    endif else $
      return, self.oCurrView->GetSelectedItems(count=count, all=all)

end
;;---------------------------------------------------------------------------
;; IDLitgrScene::ClearSelections
;;
;; Purpose:
;;    Will cause the selection state of the current view to be cleared.
pro IDLitgrScene::ClearSelections

    compile_opt idl2, hidden

    if(obj_valid(self.oCurrView))then $
      self.oCurrView->ClearSelections

end
;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::OnDataChange
;
; PURPOSE:
;    The IDLitgrScene::OnDataChange procedure method handles
;    notification of pending data changes within the contained
;    visualization hierarchy.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]OnDataChange, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
;-
pro IDLitgrScene::OnDataChange, oNotifier

    compile_opt idl2, hidden

    ; Increment reference count.
    self.geomRefCount = self.geomRefCount + 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrScene::OnDataComplete
;
; PURPOSE:
;    The IDLitgrScene::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oScene->[IDLitgrScene::]OnDataComplete, oNotifier
;
;-
pro IDLitgrScene::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    ; Decrement the reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount = self.geomRefCount - 1

    ; If all children have reported in that they are ready to flush,
    ; then the reference count should be zero and a redraw can occur.
    if (self.geomRefCount eq 0) then begin
        if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then begin
            oTool = self.oDest->GetTool()
            if (OBJ_VALID(oTool)) then $
                oTool->RefreshCurrentWindow
        endif else begin
            if (OBJ_VALID(self.oDest)) then self.oDest->Draw
        endelse
    endif
end


;;---------------------------------------------------------------------------
;; IDLitgrScene::Add
;;
;; Purpose:
;;   Used to manage the parent and _parent properties of the Scene.
;;   This helps with the tree abstraction used in the tool system.
;;
;;
pro IDLitgrScene::Add, oVis, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    isView = WHERE(OBJ_ISA(oVis, 'IDLgrViewGroup'), nViewgroup, $
        COMPLEMENT=nonView, NCOMP=nNon)

    if (nViewgroup gt 0) then begin
        self->IDLgrScene::Add, oVis[isView], _EXTRA=_extra
        ;; We do a manual notification here (normally the itContainer
        ;; will do this), but due to the implementation of the itWindow
        ;; (it's in C) we send messages here.
        idItems = strarr(nViewGroup)
        for i=0,nViewgroup-1 do begin
            oVis[isView[i]]->SetProperty, _PARENT=self.oDest
            idItems[i] = oVis[isView[i]]->GetFullIdentifier()
        endfor

        if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then begin
            ;; send a notification that we added something
            self.oDest->DoOnNotify, self.oDest->GetFullIdentifier(), $
                "ADDITEMS", idItems
        endif
    endif


    if (nNon gt 0) then begin
        oCurrView = self->GetCurrentView()
        oCurrView->Add, oVis[nonView], _EXTRA=_extra
    endif

end


;;---------------------------------------------------------------------------
;; IDLitgrScene::Remove
;;
;; Purpose:
;;   Used to manage the parent and _parent properties of the Scene.
;;   This helps with the tree abstraction used in the tool system.
;;
;;
pro IDLitgrScene::Remove, oVis, ALL=all, POSITION=position

    compile_opt idl2, hidden

    if (KEYWORD_SET(all) or (N_ELEMENTS(position) gt 0)) then begin
        self->IDLgrScene::Remove, ALL=all, POSITION=position
        return
    endif

    for i=0,N_ELEMENTS(oVis)-1 do begin
        if (not OBJ_VALID(oVis[i])) then $
            continue
        oVis[i]->GetProperty, PARENT=oParent
        if (not OBJ_VALID(oParent)) then $
            continue
        ; Avoid infinite loops for myself by providing superclass.
        if (oParent eq self) then begin
            if (OBJ_ISA(oVis[i], 'IDLitComponent')) then $
                oVis[i]->SetProperty, _PARENT=OBJ_NEW()
            oParent->IDLgrScene::Remove, oVis[i]

            if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then begin
                ;; send a notification that we added something
                self.oDest->DoOnNotify, self.oDest->GetFullIdentifier(), $
                    "REMOVEITEMS",  oVis[i]->GetFullIdentifier()
            endif
        endif else $
            oParent->Remove, oVis[i]
    endfor

end


;;---------------------------------------------------------------------------
;; IDLitgrScene::SetProperty
;;
;; Purpose:
;;   Used to manage the _parent property of the Scene.
;;   This helps with the tree abstraction used in the tool system.
;;
;;   All other properties are passed to the super class.
;;
pro IDLitgrScene::SetProperty, $
    DESTINATION=oDestination, $
    _PARENT=oParent, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(oDestination) gt 0) then $
        self.oDest = oDestination

   if(n_elements(oParent) gt 0 and OBJ_VALID(oParent))then begin
       oItems = self->Get(/all, COUNT=count)
       for i=0, count-1 do $
           oItems[i]->IDLitComponent::SetProperty, _PARENT=oParent
   endif

    if(n_elements(_extra) gt 0)then $
        self->IDLgrScene::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
pro IDLitgrScene::Draw, oDest

    compile_opt idl2, hidden

    if (self.inDraw) then $
        return

    self.inDraw = 1b

    oDest->IDLgrSrcDest::GetProperty, IS_BANDING=isBanding
    if (OBJ_ISA(self.oDest, 'IDLitIMessaging')) then $
        oTool = self.oDest->GetTool()

    if (isBanding && OBJ_VALID(oTool)) then begin
        oDest->IDLgrSrcDest::GetProperty, $
            CURRENT_BAND=iBand, $
            N_BANDS=nBands

        ; If we are on the first band, assume this is a new printjob,
        ; and reset the cancel flag. This will fail for multi-page jobs.
        if (iBand eq 0) then $
            self._cancel = 0b

        if (self._cancel) then begin
            self.inDraw = 0b
            return ; without drawing this band
        endif

        percent = 100*(iBand+1d)/nBands
        if (nBands lt 100) and (percent gt 95) then $
            percent = 100

        status = oTool->ProgressBar('Printing...', $
            PERCENT=percent, $
            SHUTDOWN=(iBand ge (nBands-1)))

        ; If unsuccessful, skip the rest of the bands.
        if (status ne 1) then begin
            self._cancel = 1b
            self.inDraw = 0b
            return ; without drawing this band
        endif

    endif else begin
        self._cancel = 0b   ; always reset for regular draws.
        ; If the previous draw took a "long" time, assume this draw will
        ; also take time, and change to an hourglass cursor.
        if (self._time gt 0.3 && OBJ_VALID(oTool)) then $
            dummy = oTool->DoUIService("HourglassCursor", self)
    endelse

    t = SYSTIME(1)
    self->IDLgrScene::Draw, oDest
    void = CHECK_MATH()  ; swallow underflow errors
    ; Cache the time needed for this draw.
    self._time = SYSTIME(1) - t

    self.inDraw = 0b

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitgrScene__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitgrScene object.
;
;-
pro IDLitgrScene__define

    compile_opt idl2, hidden

    struct = {IDLitgrScene,          $
        inherits IDLgrScene,       $ ; Superclass: IDLgrScene
        oDest: OBJ_NEW(),          $ ; Destination in which scene appears
        oCurrView: OBJ_NEW(),      $ ; Current View
        _time: 0d,                 $ ; Time for previous draw
        geomRefCount: 0UL,         $ ; Reference count for data changes
        inDraw: 0b,                $ ; flag that we are within draw
        _cancel: 0b                $ ; flag to cancel drawing
    }
end

