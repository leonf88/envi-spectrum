; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdoperationpreview.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdOperationPreview
;
; PURPOSE:
;   This function implements a simple property sheet dialog
;
; CALLING SEQUENCE:
;   IDLitwdOperationPreview
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
;; IDLitwdOperationPreview_event
;;
;; Purpose:
;;   Event handler for this widget. It only really handles the ok
;;   button.
;;
;; Parameters:
;;   event   = The widget event.

pro IDLitwdOperationPreview_event, event

    compile_opt idl2, hidden

    ; Manually destroy our widget to prevents flashing on Windows platforms.
    if (TAG_NAMES(event, /STRUCT) eq 'WIDGET_KILL_REQUEST') then begin
        WIDGET_CONTROL, event.top, GET_UVALUE=pResult
        if (PTR_VALID(pResult)) then $
            *pResult = 0b   ; cancelled
        WIDGET_CONTROL, event.id, /DESTROY
        return
    endif

    case widget_info(event.id, /uname) of
        "OK":   widget_control, event.top, /destroy
        "CANCEL": begin
            WIDGET_CONTROL, event.top, GET_UVALUE=pResult
            *pResult = 0b   ; cancelled
            widget_control, event.top, /destroy
            end
        else:
    endcase
end


;-------------------------------------------------------------------------
; IDLitwdOperationPreview
;
; Purpose:
;   This is a simple modal widget that will display the properties
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
;   NO_COMMIT: Set this keyword to avoid committing changes to the
;           Undo/Redo buffer when the dialog is closed.
;           If this keyword is not set, then any Property Sheet changes
;           are automatically packaged up into an Undo/Redo
;           transaction when the dialog is closed.
;
;   VALUE: The identifiers of the components to display
;          properties of. If multiple items are provided, then
;          mulitple columns are displayed.
;
;   All other keywords such as SCR_XSIZE, YSIZE, XOFFSET, etc.
;   are passed on to CW_ITPROPERTYSHEET.
;
function IDLitwdOperationPreview, oUI, $
    CANCEL=cancel, $
    NO_COMMIT=noCommit, $
    GROUP_LEADER=groupLeaderIn, $
    SCR_XSIZE=scrXsize, SCR_YSIZE=scrYsize, $  ; pass to cw_itpropertysheet
    XSIZE=xsize, YSIZE=ysize, $  ; pass to cw_itpropertysheet
    TITLE=titleIn, VALUE=oComponent, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Check keywords.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
            IDLitLangCatQuery('UI:wdOpPreview:Title')
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasGL = WIDGET_INFO(groupLeader, /VALID_ID)
    ; Create our floating base.
    wTLB = WIDGET_BASE( uname="TLB",  $
        /COLUMN, $
        FLOATING=hasGL, $
        MODAL=hasGL, $
        GROUP_LEADER=groupLeader, $
        TITLE=title, $
        /TLB_KILL_REQUEST_EVENTS, $
        SPACE=10, $
        _EXTRA=_extra)

    ; Construct the actual property sheet.
    wProp = CW_ITPROPERTYSHEET(wTLB, oUI, $
        VALUE=oComponent->GetFullIdentifier(), $
        SCR_XSIZE=scrXsize, SCR_YSIZE=scrYsize, $
        XSIZE=xsize, YSIZE=ysize, $
        COMMIT_CHANGES=~KEYWORD_SET(noCommit), $   ; reverse the meaning
        _EXTRA=_extra)

    wPreview = CW_ITOPERATIONPREVIEW(wTLB, oUI, VALUE=oComponent)

    ;; Okay button
    wButtons = Widget_Base(wTLB, /align_right, /row, /grid, space=5)

    wOK = Widget_Button(wButtons, $
                        VALUE=' '+IDLitLangCatQuery('UI:OK')+'  ', uname='OK')

    ; Also add a CANCEL button if desired.
    ; In this case we need to store a "result" pointer, so we can
    ; return a 1/0 okay/cancel flag. Otherwise, if no Cancel button then
    ; we always return success.
    if (KEYWORD_SET(cancel)) then begin
        pResult = PTR_NEW(1b)
        wCancel = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:CancelPad'), $
            uname='CANCEL', UVALUE=pCancel)
        WIDGET_CONTROL, wTLB, CANCEL_BUTTON=wCancel, $
            DEFAULT_BUTTON=wOK, $
            SET_UVALUE=pResult
    endif

    WIDGET_CONTROL, wTLB, /REALIZE, set_uvalue=state, /no_copy

    ; Fire up the xmanager.
    XMANAGER, "IDLitwdOperationPreview", wTLB,  NO_BLOCK=0

    ; If we have a Cancel button, see if OK or Cancel was hit.
    if (KEYWORD_SET(cancel)) then begin
        success = *pResult
        PTR_FREE, pResult

        ; If user hit Cancel and we chose *not* to commit our undo/redo
        ; transaction, then undo the pending transaction.
        if (~success && KEYWORD_SET(noCommit)) then begin
            oTool = oUI->GetTool()
            oCommandBuffer = oTool->_GetCommandBuffer()
            oCommandBuffer->Rollback
        endif

        return, success
    endif


    return, 1b  ; success
end

