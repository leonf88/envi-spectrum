; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/dialog_wizard.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   DIALOG_WIZARD
;
; PURPOSE:
;   This function implements the dialog wizard.
;
; CALLING SEQUENCE:
;   Result = DIALOG_WIZARD()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by: CT, RSI, September 2002.
;   Modified:
;
;-
;;---------------------------------------------------------------------------
;; Notes on forward and back page routines
;;
;; Next Page
;;  The next routines are called using the base page name with
;;  "_create" appended to it. When called, this routine should have
;;  the following signature:
;;
;;  PRO <routine>_create, id
;;
;;  Where id is the widget base that the page should build off
;;  of. When this procedure returns, it is assumed that the given
;;  page is displayed and operational.
;;
;; Back Page
;;   The back routines are called using the base page name with
;;   "_destroy" appended to it. When called, this routine should have
;;   the following signature:
;;
;;   status = <routine>_destroy(id, bNext)
;;
;;   Where:
;;      id    - The widget base that this page builds off of
;;
;;      bNext - Set to true if the wizard is moving to the next
;;              page. Set to false if the wizard is moving to the
;;              previous page. The function called can use this to
;;              determine if any validation must take place.
;;
;;              The assumption is that validation will take place with
;;              moving to the next page, but not when moving back.
;;
;;      Return Value:
;;             1 - It is okay to move to the next page. This is only
;;                 check if bNext is true.
;;
;;             0 - It is not okay to move to the next page. If bNext
;;                 is true and the function returns 0, the wizard will
;;                 not move to the next page and expect the current
;;                 page to remain active.
;;
;-------------------------------------------------------------------------
pro dialog_wizard_help, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState
    WIDGET_CONTROL, event.id, GET_UVALUE=helpPro
    ; Call user-defined procedure.
    CALL_PROCEDURE, helpPro, (*pState).wSubbase

end


;-------------------------------------------------------------------------
pro dialog_wizard_update, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, (*pState).wTitle, GET_UVALUE=title

    nscreen = N_ELEMENTS(*(*pState).pScreens)

    if (nscreen gt 1) then begin
        title += IDLitLangCatQuery('UI:diaWiz:Title1') + $
            STRTRIM((*pState).position, 2) + $
            IDLitLangCatQuery('UI:diaWiz:Title2') + $
            STRTRIM(nscreen, 2)
    endif

    WIDGET_CONTROL, (*pState).wTitle, SET_VALUE=title

    if ((*pState).wBack ne 0L) then begin
        WIDGET_CONTROL, (*pState).wBack, $
            SENSITIVE=((*pState).position gt 1)
    endif

    nextText = ((*pState).position lt nscreen) ? $
        IDLitLangCatQuery('UI:diaWiz:Next') + ' >>' : $
        IDLitLangCatQuery('UI:diaWiz:' + $
            ((nscreen eq 1) ? 'OK' : 'Finish'))
    WIDGET_CONTROL, (*pState).wNext, SET_VALUE=nextText

    WIDGET_CONTROL, (*pState).wNext, $
        SENSITIVE=(*pState).bNextEnabled

end


;-------------------------------------------------------------------------
pro dialog_wizard_back, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState

    ;; Call the destroy function on this page, indicating that we are
    ;; moving to back. If this returns 0, do not move forward. We
    ;; ignore the status here, since we don't care. The assumption
    ;; here is that forward requires validation, however back doesnt.
    status = CALL_function( (*(*pState).pScreens)[(*pState).position-1]+'_destroy', $
                            (*pState).wSubbase, 0)
    ; Previous screen.
    (*pState).position--

    CALL_PROCEDURE, (*(*pState).pScreens)[(*pState).position-1]+'_create', $
        (*pState).wSubbase

    DIALOG_WIZARD_UPDATE, pState

end


;-------------------------------------------------------------------------
pro dialog_wizard_next, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState
    WIDGET_CONTROL, event.id, GET_VALUE=value

    ;; Call the destroy function on this page, indicating that we are
    ;; moving to the next page. If this returns 0, do not move forward.
    status = CALL_function( (*(*pState).pScreens)[(*pState).position-1]+'_destroy', $
                            (*pState).wSubbase, 1)

    if(status eq 0)then return ; cannot move forward

    if (value ne IDLitLangCatQuery('UI:diaWiz:Next') + ' >>') then begin
        *(*pState).pSuccess = 1
        WIDGET_CONTROL, event.top, /DESTROY
        return
    endif

    ; Next screen.
    (*pState).position++

    CALL_PROCEDURE, (*(*pState).pScreens)[(*pState).position-1]+'_create', $
        (*pState).wSubbase

    DIALOG_WIZARD_UPDATE, pState

end


;-------------------------------------------------------------------------
pro dialog_wizard_setscreens, id, POSITION=position, SCREENS=screens

    compile_opt idl2, hidden

    WIDGET_CONTROL, WIDGET_INFO(id, /PARENT), GET_UVALUE=pState

    if (N_ELEMENTS(screens) gt 0) then $
        *(*pState).pScreens = screens

    if (N_ELEMENTS(position) gt 0) then $
        (*pState).position = 1 > position < N_ELEMENTS(*(*pState).pScreens)

    DIALOG_WIZARD_UPDATE, pState

end


;-------------------------------------------------------------------------
; Dialog_Wizard_setNext
;
; Purpose:
;   Provide a method to control the availablity of the next button for
;   a page. The page routine can call this will the sub-base id to
;   make the button disabled. At a later time when conditions are
;   valid, but routine can be called again to enable the button.
;
; Parameters:
;   id       - The sub-base id that is provided to pages.
;
;   bEnable  - Set to True to enable and False to disable
;
pro dialog_wizard_setNext, id, bEnable

    compile_opt idl2, hidden

    widget_control, widget_info(id,/parent), get_uvalue=pState

    (*pState).bNextEnabled = KEYWORD_SET(bEnable)
    widget_control, (*pState).wNext, SENSITIVE=(*pState).bNextEnabled


end


;-------------------------------------------------------------------------
pro dialog_wizard_cancel, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, /DESTROY

end


;-------------------------------------------------------------------------
pro dialog_wizard_realize, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    geom = WIDGET_INFO((*pState).wSubbase, /GEOM)
    WIDGET_CONTROL, (*pState).wButtons, XSIZE=(geom.xsize - 100) > 200

end


;-------------------------------------------------------------------------
pro dialog_wizard_event, event

    compile_opt idl2, hidden

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else: ; do nothing

    endcase

end


;-------------------------------------------------------------------------
function dialog_wizard, screens, $
    GROUP_LEADER=groupLeaderIn, $
    HELP_PRO=helpPro, $
    TITLE=titleIn, $
    XSIZE=xsizeIn, YSIZE=ysizeIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ON_ERROR, 2   ; return to caller

    if (N_PARAMS() ne 1) then $
      MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

    if (SIZE(screens, /TYPE) ne 7) then $
        MESSAGE, IDLitLangCatQuery('UI:diaWiz:BadScreens')

    ; Is there a group leader, or do we create our own?
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(groupLeader, /VALID)

    xsize = (N_ELEMENTS(xsizeIn) eq 1) ? xsizeIn[0] : 600
    ysize = (N_ELEMENTS(ysizeIn) eq 1) ? ysizeIn[0] : 400

    ; We are doing this modal.
    if (not hasLeader) then begin
        DEVICE, GET_SCREEN_SIZE=screen
        wDummy = WIDGET_BASE(MAP=0, TITLE=IDLitLangCatQuery('UI:diaWiz:Title'))
        groupLeader = wDummy
        hasLeader = 1
        xoffset = screen[0]/2 - xsize/2
        yoffset = screen[1]/2 - ysize/2
    endif else wDummy = 0L


    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn : $
      IDLitLangCatQuery('UI:diaWiz:Title')


    ; Create our floating base.
    wBase = WIDGET_BASE( $
        /COLUMN, $
        EVENT_PRO='dialog_wizard_event', $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, /MODAL, $
        NOTIFY_REALIZE='dialog_wizard_realize', $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        /TAB_MODE, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        /TLB_KILL_REQUEST_EVENTS, $
        XOFFSET=xoffset, YOFFSET=yoffset)

    ; Cannot guarantee the existence of fonts on Motif.
    if (!version.os_family eq 'Windows') then $
        font = 'Helvetica*24'
    wTitle = WIDGET_LABEL(wBase, $
        /ALIGN_LEFT, $
        /DYNAMIC_RESIZE, $
        FONT=font, $
        VALUE=' ', $
        UVALUE=title)

    ; Returned to the user.
    wSubbase = WIDGET_BASE(wBase, $
        XSIZE=xsize, YSIZE=ysize, $
        _EXTRA=_extra)

    wRow = WIDGET_BASE(wBase, COLUMN=2)
    wHelpBase = WIDGET_BASE(wRow, /ROW, XPAD=0, YPAD=0, XSIZE=100)
    wButtons = WIDGET_BASE(wRow, /COLUMN, XPAD=0, YPAD=0, XSIZE=200)

    if (N_ELEMENTS(helpPro) gt 0) then begin
        wHelp = WIDGET_BUTTON(wHelpBase, $
            EVENT_PRO='dialog_wizard_help', $
            VALUE=IDLitLangCatQuery('UI:diaWiz:Help'), $
            UVALUE=helpPro)
    endif

    wButton1 = WIDGET_BASE(wButtons, /ALIGN_RIGHT, /ROW, $
        SPACE=10, XPAD=0, YPAD=0)
    wBackNext = WIDGET_BASE(wButton1, /GRID, COLUMN=2, XPAD=0, YPAD=0)

    ; Only add the "Back" button if > 1 screen.
    if (N_ELEMENTS(screens) gt 1) then begin
        wBack = WIDGET_BUTTON(wBackNext, $
            EVENT_PRO='dialog_wizard_back', $
            VALUE='  << '+IDLitLangCatQuery('UI:diaWiz:Back')+'  ')
    endif else $
        wBack = 0L

    wNext = WIDGET_BUTTON(wBackNext, $
                          EVENT_PRO='dialog_wizard_next', $
                          VALUE=' >>')

    wCancel = WIDGET_BUTTON(wButton1, $
        EVENT_PRO='dialog_wizard_cancel', $
        VALUE=IDLitLangCatQuery('UI:diaWiz:Cancel'))

    pSuccess = PTR_NEW(0)    ; assume failure

    state = { $
        wSubbase: wSubbase, $
        wButtons: wButtons, $
        wBack: wBack, $
        wNext: wNext, $
        wTitle: wTitle, $
        pSuccess: pSuccess, $
        position: 1L, $   ; first screen
        bNextEnabled: 1b, $
        pScreens: PTR_NEW(screens)}
    ;; put state in a pointer so when a call back  occurs during page
    ;; create, the value will be valid
    pState = ptr_new(state,/no_copy)
    WIDGET_CONTROL, wBase, SET_UVALUE=pState, cancel_button=wCancel

    DIALOG_WIZARD_UPDATE, pState

    WIDGET_CONTROL, wBase, /REALIZE

    CALL_PROCEDURE, screens[0]+'_create', wSubbase

    ; Fire up the xmanager.
    XMANAGER, 'dialog_wizard', wBase, NO_BLOCK=0

    ; Destroy our dummy top-level base if we created it.
    if WIDGET_INFO(wDummy, /VALID) then $
        WIDGET_CONTROL, wDummy, /DESTROY

    success = *pSuccess
    PTR_FREE, pSuccess
    PTR_FREE, (*pState).pScreens
    ptr_free, pState
    return, success

end

