; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdpropertysheet.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdPropertySheet
;
; PURPOSE:
;   This function implements a simple property sheet dialog
;
; CALLING SEQUENCE:
;   IDLitwdPropertySheet
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-
;-------------------------------------------------------------------------
; IDLitwdPropertySheet_callback
;
; Purpose:
;   This procedure method handles notification from an observed object.
;
pro IDLitwdPropertySheet_callback, wTLB, strID, messageIn, component
    compile_opt idl2, hidden

    if (~WIDGET_INFO(wTLB, /VALID)) then $
        return

    WIDGET_CONTROL, wTLB, GET_UVALUE=pState

    case STRUPCASE(messageIn) of
        'DISMISS': WIDGET_CONTROL, wTLB, /DESTROY

        else: begin
        end
    endcase
end

;-------------------------------------------------------------------------
; IDLitwdPropertySheet_event
;
; Purpose:
;   Event handler for this widget.
;
; Parameters:
;   event   = The widget event.
;
pro IDLitwdPropertySheet_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState

    ; Are we finished?
    if ((TAG_NAMES(event, /STRUCT) eq 'WIDGET_KILL_REQUEST') || $
        (event.id eq (*pState).wCancel) || $
        (event.id eq (*pState).wOK)) then begin

        iSuccess = (event.id eq (*pState).wOK)

        if ((*pState).modal) then begin
            (*pState).result = iSuccess
            WIDGET_CONTROL, event.top, /DESTROY
            return
        endif


        callSuccess = 1

        if ((*pState).callback) then begin
            oRequester = (*pState).oTool->GetByIdentifier($
                (*pState).idComponent)

            bIsDesc = OBJ_ISA(oRequester, 'IDLitObjDesc')
            if (bIsDesc) then begin
                oDesc = oRequester
                oRequester = oDesc->GetObjectInstance()
            endif
            callSuccess = CALL_METHOD('UIcallback', oRequester, iSuccess)
            if (bIsDesc) then $
                oDesc->ReturnObjectInstance, oRequester

            ; If user hit OK, but callback failed, do not destroy ourself.
            if (iSuccess && ~callSuccess) then $
                return
        endif

        ; Sanity check. The UIcallback might have destroyed me.
        if (WIDGET_INFO(event.top, /VALID)) then $
            WIDGET_CONTROL, event.top, /DESTROY

        return
    endif


end


;-------------------------------------------------------------------------
pro IDLitwdPropertySheet_killnotify, wBase

    compile_opt idl2, hidden

    WIDGET_CONTROL, wBase, GET_UVALUE=pState

    ; This will also remove ourself as an observer for all subjects.
    if ((*pState).idSelf ne '') then $
        (*pState).oUI->UnRegisterWidget, (*pState).idSelf

end


;-------------------------------------------------------------------------
; IDLitwdPropertySheet
;
; Purpose:
;   This is a simple widget that will display the properties
;   for a group of components.
;
; Parameters:
;    oUI     - The UI object
;
; Keywords:
;   CANCEL: Set this keyword to include a Cancel button on the dialog.
;           If this keyword is set, then the Result will be 0 if the
;           user presses the Cancel button or closes the widget using
;           the window Close icon. The Result will be 1 only if the
;           user presses the OK button.
;           If this keyword is not set, the Result will always be 1,
;           regardless of how the dialog is closed.
;
;   MODAL: Set this keyword to create a modal dialog.
;       If set then property changes will not be committed.
;       Otherwise, if nonmodal then property changes will be committed.
;
;   VALUE: The identifiers of the components to display
;          properties of. If multiple items are provided, then
;          mulitple columns are displayed.
;
;   All other keywords such as SCR_XSIZE, YSIZE, XOFFSET, etc.
;   are passed on to CW_ITPROPERTYSHEET.
;
function IDLitwdPropertySheet, oUI, $
    CANCEL=cancel, $
    GROUP_LEADER=groupLeaderIn, $
    SCR_XSIZE=scrXsize, SCR_YSIZE=scrYsize, $  ; pass to cw_itpropertysheet
    XSIZE=xsize, YSIZE=ysize, $  ; pass to cw_itpropertysheet
    TITLE=titleIn, VALUE=idComponent, $
    MODAL=modal, $
    UI_CALLBACK=callback, $
    OK_STRING=okString, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Check keywords.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : IDLitLangCatQuery('UI:DefTitle')
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasGL = WIDGET_INFO(groupLeader, /VALID_ID)
    ; Must have a group leader for modal.
    modal = KEYWORD_SET(modal) && hasGL
    wTLB = WIDGET_BASE( uname="TLB",  $
        /COLUMN, $
        FLOATING=hasGL, $
        MODAL=modal, $
        GROUP_LEADER=groupLeader, $
        TITLE=title, $
        /TLB_KILL_REQUEST_EVENTS, $
        _EXTRA=_extra)

    ; If nonmodal, then register the top-level base so it can be
    ; an observer of notifications, such as 'DISMISS'.
    idSelf = ''
    if (~modal) then begin
        idSelf = oUI->RegisterWidget(wTLB, 'PropertySheetTLB', $
            'idlitwdpropertysheet_callback')

        nComponents = N_ELEMENTS(idComponent)
        for i=0,nComponents-1 do $
            oUI->AddOnNotifyObserver, idSelf, idComponent[i]
    endif

    ; Construct the actual property sheet.
    wProp = CW_ITPROPERTYSHEET(wTLB, oUI, value=idComponent, $
        SCR_XSIZE=scrXsize, SCR_YSIZE=scrYsize, $
        XSIZE=xsize, YSIZE=ysize, $
        COMMIT_CHANGES=~modal, $   ; commit=nonmodal
        _EXTRA=_extra)

    ;; Okay button
    wButtons = Widget_Base(wTLB, /align_right, /row, /grid, space=5)

    okStr = (N_ELEMENTS(okString) ne 0) ? okString[0] : $
            '  '+IDLitLangCatQuery('UI:OK')+'  '
    wOK = Widget_Button(wButtons, VALUE=okStr, uname='OK')

    ; Also add a CANCEL button if desired.
    if (KEYWORD_SET(cancel)) then begin
        wCancel = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:CancelPad'), $
            UNAME='CANCEL', UVALUE=pCancel)
        WIDGET_CONTROL, wTLB, CANCEL_BUTTON=wCancel, $
            DEFAULT_BUTTON=wOK
    endif else wCancel = 0


    state = { $
        wOK: wOK, $
        wCancel: wCancel, $
        result: 1b, $
        modal: modal, $
        callback: KEYWORD_SET(callback), $
        oUI: oUI, $
        oTool: oUI->GetTool(), $
        idSelf: idSelf, $
        idComponent: idComponent $
    }
    pState = PTR_NEW(state)
    WIDGET_CONTROL, wTLB, /REALIZE, SET_UVALUE=pState, $
        KILL_NOTIFY='IDLitwdPropertySheet_killnotify'

    ; Fire up the xmanager.
    XMANAGER, "IDLitwdPropertySheet", wTLB,  /NO_BLOCK

    if (modal) then begin
        ; If we have a Cancel button, see if OK or Cancel was hit.
        success = (*pState).result
        PTR_FREE, pState
        return, success
    endif

    return, 1b  ; success
end

