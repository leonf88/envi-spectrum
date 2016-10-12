; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacroviewpan__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroViewPan
;
; PURPOSE:
;   This file implements the operation that pans
;   the current window's current view.  It is for use in macros
;   and history when a user uses the view pan manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroViewPan::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroViewPan::Init
;   IDLitopMacroViewPan::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroViewPan::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroViewPan object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroViewPan::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="View Pan", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X', /FLOAT, $
        NAME='X pan', $
        DESCRIPTION='X pan (pixels)'

    self->RegisterProperty, 'Y', /FLOAT, $
        NAME='Y pan', $
        DESCRIPTION='Y pan (pixels)'

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroViewPan::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroViewPan::GetProperty,        $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(x)) then $
        x = self._x

    if (ARG_PRESENT(y)) then $
        y = self._y

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroViewPan::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroViewPan::SetProperty,      $
    X=x, $
    Y=y, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(x) ne 0) then begin
        self._x = x
    endif

    if (N_ELEMENTS(y) ne 0) then begin
        self._y = y
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
;pro IDLitopMacroViewPan::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
; IDLitManipViewPan::RecordUndoValues
;
; Purpose:
;   This function method records the initial values of targets so
;   that an undo/redo can later be performed.
;
function IDLitopMacroViewPan::RecordUndoValues, oWin

    compile_opt idl2, hidden

    ; If no target view, then bail.
    if (~OBJ_VALID(self._oTargetView)) then $
        return, 0

    ; Grab a reference to the tool.
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    ; Free any old command sets.
    if (OBJ_VALID(self._oCmdSetArr[0])) then $
        OBJ_DESTROY, self._oCmdSetArr[0]
    if (OBJ_VALID(self._oCmdSetArr[1])) then $
        OBJ_DESTROY, self._oCmdSetArr[1]

    ; Get my own name.
    self->IDLitComponent::GetProperty, NAME=myname

    ; Retrieve the SetSubView operation.
    oSubViewOp = oTool->GetService("SET_SUBVIEW")
    if (~OBJ_VALID(oSubViewOp))then begin
        self._oCmdSetArr[0] = OBJ_NEW()
        self._oCmdSetArr[1] = OBJ_NEW()
        return, 0
    endif

    ; Prepare a command set for setting the sub-view.
    oSubViewCmdSet = OBJ_NEW("IDLitCommandSet", NAME=myname, $
        OPERATION_IDENTIFIER=oSubViewOp->GetFullIdentifier())

    ; Retrieve the SetProperty operation.
    oSetPropOp = oTool->GetService("SET_PROPERTY")
    if (~OBJ_VALID(oSubViewOp))then begin
        OBJ_DESTROY, oSubViewCmdSet
        self._oCmdSetArr[0] = OBJ_NEW()
        self._oCmdSetArr[1] = OBJ_NEW()
        return, 0
    endif

    ; Prepare a command set for setting the visible location for
    ; the window.
    oWinCmdSet = OBJ_NEW("IDLitCommandSet", NAME=myname, $
        OPERATION_IDENTIFIER=oSetPropOp->GetFullIdentifier())
    self._oCmdSetArr = [oSubViewCmdSet, oWinCmdSet]

    ; Allow the operations to record initial values.
    iStatus = oSubViewOp->RecordInitialValues( oSubViewCmdSet, $
        self._oTargetView, '')
    if (iStatus eq 0) then begin
        OBJ_DESTROY, self._oCmdSetArr
        self._oCmdSetArr[0] = OBJ_NEW()
        self._oCmdSetArr[1] = OBJ_NEW()
        return, 0
    endif

    iStatus = oSetPropOp->RecordInitialValues( oWinCmdSet, $
        oWin, "VISIBLE_LOCATION")
    if (iStatus eq 0) then begin
        OBJ_DESTROY, self._oCmdSetArr
        self._oCmdSetArr[0] = OBJ_NEW()
        self._oCmdSetArr[1] = OBJ_NEW()
        return, 0
    endif

    return,1

end


;--------------------------------------------------------------------------
; IDLitManipViewPan::StartPan
;
; Purpose:
;   This procedure method starts the pan.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
function IDLitopMacroViewPan::StartPan, oWin, x, y

    compile_opt idl2, hidden

    ; Retrieve a reference to the current view.  Store relevent info.
    oWin->GetProperty, CURRENT_ZOOM=canvasZoom
    self._oTargetView = oWin->GetCurrentView()
    if (~OBJ_VALID(self._oTargetView)) then $
        return, 0
    virtualDims = self._oTargetView->GetVirtualViewport()
    vwDims = self._oTargetView->GetViewport(oWin, /VIRTUAL, $
        LOCATION=vwLoc)
    self._vwLoc = vwLoc
    self._vwDims = vwDims
    self._prevViewScroll = [0,0]

    ; Store information about the window.
    winVisDims = oWin->GetDimensions(VISIBLE_LOCATION=winVisLoc)
    self._winVisDims = winVisDims
    self._winVisLoc = winVisLoc

    bVwOut = ((vwLoc[0] lt winVisLoc[0]) || $
              ((vwLoc[0]+vwDims[0]-1) gt $
               (winVisLoc[0]+winVisDims[0]-1)) || $
              (vwLoc[1] lt winVisLoc[1]) || $
              ((vwLoc[1]+vwDims[1]-1) gt $
               (winVisLoc[1]+winVisDims[1]-1)))
    visViewDims = vwDims / canvasZoom
    bVirtualLarger = (visViewDims[0] lt virtualDims[0]) || $
        (visViewDims[1] lt virtualDims[1])
    if (~bVwOut && ~bVirtualLarger) then begin
        self._oTargetView = OBJ_NEW()
        return, 0
    endif

    ; Store mouse down location (relative to the virtual canvas).
    self._startXY = [x,y] + winVisLoc
    self._macroXY0 = [x,y]
    self._macroXY1 = [x,y]

    ; Record the current values for the target view.
    iStatus = self->RecordUndoValues(oWin)

    return, 1
end


;--------------------------------------------------------------------------
; IDLitManipViewPan::Pan
;
; Purpose:
;   This procedure method performs the actual pan.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button
;
function IDLitopMacroViewPan::DoPan, oWin, deltaX, deltaY

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oTargetView)) then $
        return, ''

    x = self._macroXY1[0] + deltaX
    y = self._macroXY1[1] + deltaY

    panStr = ''

    newxy = [x,y] + self._winVisLoc

    xScroll = self._startXY[0] - newxy[0]
    yScroll = self._startXY[1] - newxy[1]

    vwX0 = self._vwLoc[0]
    vwX1 = vwX0 + self._vwDims[0] - 1
    vwY0 = self._vwLoc[1]
    vwY1 = vwY0 + self._vwDims[1] - 1

    winVisX0 = self._winVisLoc[0]
    winVisX1 = winVisX0 + self._winVisDims[0] - 1
    winVisY0 = self._winVisLoc[1]
    winVisY1 = winVisY0 + self._winVisDims[1] - 1

    ; Panning occurs in two parts:
    ;   1. window scroll (until relevent portion of viewport is contained
    ;      within the visible portion of the canvas)
    ;   2. view pan
    if (xScroll eq 0) then begin
       winXScroll = 0
       viewXScroll = 0
    endif else if (xScroll gt 0) then begin
        ; Drag left: Move visible port to the right.
        if (vwX1 gt winVisX1) then begin
            winXScroll = xScroll < (vwX1 - winVisX1)
            viewXScroll = xScroll - winXScroll
        endif else begin
            winXScroll = 0
            viewXScroll = xScroll
        endelse
    endif else if (xScroll lt 0) then begin
        ; Drag right: move visible port to the left.
        if (vwX0 lt winVisX0) then begin
            winXScroll = xScroll > (vwX0 - winVisX0)
            viewXScroll = xScroll - winXScroll
        endif else begin
            winXScroll = 0
            viewXScroll = xScroll
        endelse
    endif

    if (yScroll eq 0) then begin
       winYScroll = 0
       viewYScroll = 0
    endif else if (yScroll gt 0) then begin
        ; Pan visible port up.
        if (vwY1 gt winVisY1) then begin
            winYScroll = yScroll < (vwY1 - winVisY1)
            viewYScroll = yScroll - winYScroll
        endif else begin
            winYScroll = 0
            viewYScroll = yScroll
        endelse
    endif else if (yScroll lt 0) then begin
        ; Pan visible port down.
        if (vwY0 lt winVisY0) then begin
            winYScroll = yScroll > (vwY0 - winVisY0)
            viewYScroll = yScroll - winYScroll
        endif else begin
            winYScroll = 0
            viewYScroll = yScroll
        endelse
    endif

    bWinScroll = (winXScroll ne 0) || (winYScroll ne 0)

    if ((viewXScroll ne 0) || (viewYScroll ne 0)) then begin
        ; Apply the scroll.
        ; (Do not redraw if the window is about to be scrolled.)
        relViewXScroll = viewXScroll - self._prevViewScroll[0]
        relViewYScroll = viewYScroll - self._prevViewScroll[1]
        self._oTargetView->Scroll, relViewXScroll, relViewYScroll
        self._prevViewScroll = [viewXScroll, viewYScroll]

        panStr = IDLitLangCatQuery('Status:Manip:ViewPan') + $
            STRING(FORMAT='(%"[%d,%d]")', viewXScroll, viewYScroll)

    endif

    ; Apply any canvas scroll.
    if (bWinScroll) then begin
        newVisLoc = self._winVisLoc+[winXScroll,winYScroll]
        oWin->SetProperty, VISIBLE_LOCATION=newVisLoc
        oWin->GetProperty, VISIBLE_LOCATION=newVisLoc
        self._winVisLoc = newVisLoc

        if (~panStr) then $
            panStr = IDLitLangCatQuery('Status:Manip:ViewPanScroll') + $
                STRING(FORMAT='(%"[%d,%d]")', winXScroll, winYScroll)
    endif

    ; and update point
    self._macroXY1 = [x,y]

    return, panStr
end


;--------------------------------------------------------------------------
; IDLitManipViewPan::EndPan
;
; Purpose:
;   This procedure method ends the pan.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
function IDLitopMacroViewPan::EndPan, oWin, x, y

    compile_opt idl2, hidden

    oCmdSet = self._oCmdSetArr
    self._oCmdSetArr = OBJARR(2)
    oTargetView = self._oTargetView
    self._oTargetView = OBJ_NEW()

    ; If uncommitting or no target view, free the command sets.
    if (~OBJ_VALID(oTargetView) || $
        (x eq self._startXY[0] && y eq self._startXY[1])) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    ; Retrieve the SetProperty and SetSubView operation.
    oTool = self->GetTool()
    oSetPropOp = OBJ_VALID(oTool) ? $
        oTool->GetService("SET_PROPERTY") : OBJ_NEW()
    oSubViewOp = OBJ_VALID(oTool) ? $
        oTool->GetService("SET_SUBVIEW") : OBJ_NEW()
    if (~OBJ_VALID(oSetPropOp) || ~OBJ_VALID(oSubViewOp)) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    ; Record final sub-view values.
    iStatus = oSubViewOp->RecordFinalValues(oCmdSet[0], oTargetView, '')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet[0]
        oCmdSet[0] = OBJ_NEW()
        ; Failure by the SubViewOp may simply indicate no change.
        ; Do not return a failure status in this case, since the
        ; following SetProperty command set may still apply.
    endif

    ; Record final window visible location.
    iStatus = oSetPropOp->RecordFinalValues(oCmdSet[1], $
        oWin, "VISIBLE_LOCATION", $
        /SKIP_MACROHISTORY)
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet[1]
        oCmdSet[1] = OBJ_NEW()
        ; Failure by the SetPropOp may simply indicate no change.
        ; Do not return a failure status in this case, since the
        ; previous SubViewOp command set may still apply.
    endif

    ; If neither of the command sets is valid, return a failure status.
    iValid = WHERE(OBJ_VALID(oCmdSet), nValid)
    if (nValid eq 0) then $
        return, OBJ_NEW()

    oCmdSet = oCmdSet[iValid]

    return, oCmdSet

end



;;---------------------------------------------------------------------------
;; IDLitopMacroViewPan::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroViewPan::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if ~obj_valid(oTool) then $
        return, obj_new()

    oWin = oTool->GetCurrentWindow()
    if ~obj_valid(oWin) then $
        return, obj_new()

    success = self->StartPan(oWin, 0, 0)

    if (~success) then $
        return, obj_new()

    ; Call our internal method.
    void = self->DoPan(oWin, self._x, self._y)

    oCmdSet = self->EndPan(oWin, self._x, self._y)

    return, oCmdSet

end


;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroViewPan__define

    compile_opt idl2, hidden

    void = {IDLitopMacroViewPan, $
            inherits IDLitOperation, $
            _x: 0L     , $
            _y: 0L     , $
        _oTargetView: OBJ_NEW(),     $ ; Reference to view to be panned.
        _vwDims: DBLARR(2),          $ ; Pixel dimensions of viewport
                                     $ ;  (relative to virtual canvas)
        _vwLoc: DBLARR(2),           $ ; Pixel location of viewport
                                     $ ;  (relative to virtual canvas)
        _startXY: DBLARR(2),         $ ; Initial window location.
        _macroXY0: DBLARR(2),        $ ; Initial cursor location for recording.
        _macroXY1: DBLARR(2),        $ ; Subsequent cursor location for recording.
        _prevViewScroll: DBLARR(2),  $ ; Most recent view scroll
        _winVirtualDims: FLTARR(2),  $ ; Virtual canvas dimensions
        _winVisDims: FLTARR(2),      $ ; Visible canvas dimensions
        _winVisLoc: FLTARR(2),       $ ; Location of visible within virtual
        _oCmdSetArr: OBJARR(2)       $ ; Command sets for undo/redo:
                                     $ ;   [0] -> sub-view
                                     $ ;   [1] -> window visible loc
                        }
end

