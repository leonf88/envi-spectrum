; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itpropertypreview.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   cw_itpropertypreview
;
; PURPOSE:
;   This function implements the compound widget for a Preview window.
;
; CALLING SEQUENCE:
;   Result = cw_itpropertypreview(Parent, Tool)
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
;   Tool: Set this argument to the object reference for the IDL Tool.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro cw_itpropertypreview_callback, wBase, strID, messageIn, component

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return

    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), GET_UVALUE=state
    cw_itpropertypreview_updatedraw, state

end


;-------------------------------------------------------------------------
pro cw_itpropertypreview_event, event

    compile_opt idl2, hidden

;    wChild = WIDGET_INFO(event.handler, /CHILD)
;    WIDGET_CONTROL, wChild, GET_UVALUE=pState

end


;-------------------------------------------------------------------------
pro cw_itpropertypreview_updatedraw, state

    compile_opt idl2, hidden

    image = state.oOperation->GetPreview()

    wold = !D.WINDOW
    DEVICE, GET_DECOMPOSED=wasdecomposed
    if (wasdecomposed ne 0) then $
        DEVICE, DECOMPOSED=0

    WSET, state.iWin

    TV, image, TRUE=(SIZE(image, /N_DIM) eq 3)

    if (wold ne state.iWin) then $
        WSET, wold

    if (wasdecomposed ne 0) then $
        DEVICE, DECOMPOSED=wasdecomposed
end


;-------------------------------------------------------------------------
pro cw_itpropertypreview_setvalue, id, oOperation

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    if (OBJ_VALID(state.oOperation)) then begin
        state.oUI->RemoveOnNotifyObserver, state.idSelf, $
            state.oOperation->GetFullIdentifier()
    endif
    state.oUI->AddOnNotifyObserver, state.idSelf, $
        oOperation->GetFullIdentifier()
    state.oOperation = oOperation

    WIDGET_CONTROL, wChild, SET_UVALUE=state

    cw_itpropertypreview_updatedraw, state

end


;-------------------------------------------------------------------------
pro cw_itpropertypreview_killnotify, wDraw

    compile_opt idl2, hidden

    WIDGET_CONTROL, wDraw, GET_UVALUE=state

    ; This will also remove ourself as an observer for all subjects.
    state.oUI->UnRegisterWidget, state.idSelf

end


;-------------------------------------------------------------------------
pro cw_itpropertypreview_realize, wDraw

    compile_opt idl2, hidden

    WIDGET_CONTROL, wDraw, GET_VALUE=iWin, GET_UVALUE=state
    state.iWin = iWin
    WIDGET_CONTROL, wDraw, SET_UVALUE=state

    cw_itpropertypreview_updatedraw, state

end


;-------------------------------------------------------------------------
function cw_itpropertypreview, parent, oUI, $
    VALUE=oOperation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

    oTool = oUI->getTool()

    oOperation->GetProperty, PREVIEW_DIMENSIONS=dimensions
    if (N_ELEMENTS(dimensions) ne 2) then $
        return, 0L

    wBase = WIDGET_BASE(parent, /COLUMN, $
        EVENT_PRO='cw_itpropertypreview_event', $
        PRO_SET_VALUE='cw_itpropertypreview_setvalue', $
        _EXTRA=_extra)

    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    idSelf = oUI->RegisterWidget(wBase,'PropertyPreview', $
        'cw_itpropertypreview_callback')

    ; Register for notification messages
    idOperation = oOperation->GetFullIdentifier()
    oUI->AddOnNotifyObserver, idSelf, idOperation

    ; Cache my widget information.
    state = {oUI: oUI, $
        idSelf: idSelf, $
        idOperation: idOperation, $
        iWin: 0L, $
        oOperation: oOperation}

    wDraw = WIDGET_DRAW(wBase, $
        KILL_NOTIFY='cw_itpropertypreview_killnotify', $
        NOTIFY_REALIZE='cw_itpropertypreview_realize', $
        XSIZE=dimensions[0], $
        YSIZE=dimensions[1], $
        UVALUE=state)

    return, wBase
end

