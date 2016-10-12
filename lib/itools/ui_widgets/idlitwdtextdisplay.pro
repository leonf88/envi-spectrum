; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdtextdisplay.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdTextdisplay
;
; PURPOSE:
;   This procedure displays text in a text widget.
;
;
; CALLING SEQUENCE:
;   IDLitwdTextdisplay, Text
;
;
; INPUTS:
;   Text: Set this argument to a string array containing the text
;         to display.
;
;
; KEYWORD PARAMETERS:
;
;   GROUP_LEADER:
;
;   TITLE:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, September 2002
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_saveas, event

    compile_opt idl2, hidden

    lun = 0   ; needed to close file

    ; Jump back here for errors.
    CATCH, error

    if (error ne 0) then begin

        CATCH, /CANCEL

        ; Attempt to close the file if it was opened.
        if (lun ne 0) then $
            FREE_LUN, lun

        ; Throw up a dialog with the error message.
        err = !error_state.msg
        if (!error_state.sys_msg ne '') then $
            err = [err, !error_state.sys_msg]

        dummy = DIALOG_MESSAGE(err, /ERROR, $
            DIALOG_PARENT=Event.top, $
            TITLE=IDLitLangCatQuery('UI:wdTxtDisp:SaveAsTitle'))

        return ; we failed

    endif


    WIDGET_CONTROL, event.top, GET_UVALUE=pState


    file = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
        FILTER='*.txt', $
        /OVERWRITE_PROMPT, $
        TITLE=IDLitLangCatQuery('UI:wdTxtDisp:SaveAsTitle'), $
        /WRITE)

    ; Cancel
    if (file eq '') then $
        return

    ; Append the .txt suffix if user didn't provide their own.
    if (STRPOS(file, '.') eq -1) then $
        file += '.txt'

    WIDGET_CONTROL, (*pState).wText, GET_VALUE=text

    OPENW, lun, file, /GET_LUN
    PRINTF, lun, text, FORMAT='(A)'
    FREE_LUN, lun

end


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_print, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState

    ; Save the previous device name so we can restore it.
    saveDevice = !D.NAME

    SET_PLOT, 'Printer'

    result = DIALOG_PRINTERSETUP(DIALOG_PARENT=event.top, $
        TITLE=IDLitLangCatQuery('UI:wdTxtDisp:PrintTitle'))

    DEVICE, GET_PAGE_SIZE=pagesize

    ; Job cancelled.
    if (result eq 0) then $
        goto, done

    ; Retrieve the text from the widget.
    WIDGET_CONTROL, (*pState).wText, GET_VALUE=text

    n = N_ELEMENTS(text)

    ;    Char height (pixels) / (pixels/cm) / (cm/inch) / 9inches
    height = 1.25*!d.y_ch_size;/!d.y_px_cm/2.54/9

    ; Height of useable page in pixels (minus 1 inch margin).
    yheight = pagesize[1] - !d.y_px_cm*2.54

    ; Number of lines we can fit per page.
    onepage = FIX(yheight/height)
    y = !d.y_size - FINDGEN(onepage)*height

    x = FLTARR(onepage)
    npage = (n + onepage - 1)/onepage

    for i=0, n-1, onepage do begin
        ; This dummy plot will force a new page.
        PLOT, [0,1], [0,1], /NODATA, XSTYLE=5, YSTYLE=5

        ; Dump out one pagefull of text.
        XYOUTS, x, y, text[i: (i+onepage-1) < (n-1)], $
            /DEVICE, FONT=0

        ; Add a page number.
        if (npage gt 1) then begin
            pagenum = STRTRIM(i/onepage + 1,2) + '/' + STRTRIM(npage,2)
            XYOUTS, !D.x_size - 2*!D.x_px_cm, MIN(y) - height, pagenum, $
                /DEVICE, FONT=0
        endif
    endfor

    DEVICE, /CLOSE

; Object graphics code. Currently unused.
;    oText = OBJ_NEW('IDLgrText', '(j', /ONGLASS)
;
;    oModel = OBJ_NEW('IDLgrModel')
;    oModel->Add, oText
;    oView = OBJ_NEW('IDLgrView', VIEWPLANE_RECT=[0,0,1,1])
;    oView->Add, oModel
;
;    oPrinter = OBJ_NEW('IDLgrPrinter')
;    result = DIALOG_PRINTERSETUP(oPrinter, DIALOG_PARENT=wBase, $
;        TITLE='Print')
;
;    ; Job cancelled.
;    if (result eq 0) then $
;        goto, done
;
;    oPrinter->SetProperty, GRAPHICS_TREE=oView
;    oPrinter->GetProperty, $
;        DIMENSIONS=pagedimensions, RESOLUTION=resolution
;
;    ; (res in cm/pixel) * (dim in pixels) / (2.54 cm/inch)
;    pagedim_inches = resolution*pagedimensions/2.54
;    oView->SetProperty, $
;        VIEWPLANE_RECT=[0, 0, pagedim_inches[0], pagedim_inches[1]]
;
;    textdimensions = oPrinter->GetTextDimensions(oText, DESCENT=descent)
;    print, textdimensions, descent
;
;    n = N_ELEMENTS(text)
;
;    x = FLTARR(1, n) + 1
;
;    height = 1.5*(textdimensions[1] - ABS(descent[0]))
;    y = pagedim_inches[1] - 1 - FINDGEN(1, n)*height
;
;    oText->SetProperty, LOCATIONS=[x, y], STRINGS=text
;
;    oPrinter->Draw, /VECTOR
;    oPrinter->NewDocument


done:

    ; Restore the previous device.
    SET_PLOT, saveDevice

; Object graphics code. Currently unused.
;    OBJ_DESTROY, oPrinter
;    OBJ_DESTROY, oView

end


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_close, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, /DESTROY

end


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_edittext, event

    compile_opt idl2, hidden

    isChecked = WIDGET_INFO(event.id, /BUTTON_SET)
    isChecked = 1 - isChecked  ; switch state
    WIDGET_CONTROL, event.id, SET_BUTTON=isChecked, GET_UVALUE=wText
    WIDGET_CONTROL, wText, EDITABLE=isChecked

end


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_killnotify, wBase

    compile_opt idl2, hidden

    WIDGET_CONTROL, wBase, GET_UVALUE=pState
    PTR_FREE, pState
end


;-------------------------------------------------------------------------
pro idlitwdtextdisplay_event, event

    compile_opt idl2, hidden

    if (TAG_NAMES(event, /STRUC) eq 'WIDGET_BASE') then begin

        WIDGET_CONTROL, event.top, GET_UVALUE=pState
        dx = event.x - (*pState).xsize
        dy = event.y - (*pState).ysize
        text_geom = WIDGET_INFO((*pState).wText, /GEOMETRY)

        xsize = (text_geom.scr_xsize + dx) > 1
        ysize = (text_geom.scr_ysize + dy) > 1
        WIDGET_CONTROL, (*pState).wText, SCR_XSIZE=xsize, SCR_YSIZE=ysize

        base_geom = WIDGET_INFO(event.top, /GEOMETRY)
        (*pState).xsize = base_geom.xsize
        (*pState).ysize = base_geom.ysize

    endif

end


;-------------------------------------------------------------------------
; Main Routine
;
pro idlitwdtextdisplay, text, $
    GROUP_LEADER=groupLeader, $
    TITLE=title, $
    XSIZE=xsizeIn, $
    YSIZE=ysizeIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ON_ERROR, 2

    if (N_ELEMENTS(text) lt 1) then $
        MESSAGE, IDLitLangCatQuery('UI:wdTxtDisp:BadText')

    ; Defaults.
    xsize = (N_ELEMENTS(xsizeIn) eq 1) ? xsizeIn[0] : 50
    ysize = (N_ELEMENTS(ysizeIn) eq 1) ? ysizeIn[0] : 30

    ; Create top level base to hold everything.
    wBase = WIDGET_BASE(/COLUMN, $
        GROUP_LEADER=groupLeader, $
        KILL_NOTIFY='idlitwdtextdisplay_killnotify', $
        MBAR=wMenubar, $
        TITLE=title, $
        /TLB_SIZE_EVENTS)

    wFile = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:File'))
    wSaveAs = WIDGET_BUTTON(wFile, $
        EVENT_PRO='idlitwdtextdisplay_saveas', $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:SaveAs'))
    wPrint = WIDGET_BUTTON(wFile, $
        EVENT_PRO='idlitwdtextdisplay_print', $
        /SEPARATOR, $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:Print'))
    wClose = WIDGET_BUTTON(wFile, $
        EVENT_PRO='idlitwdtextdisplay_close', $
        /SEPARATOR, $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:Close'))

    ; Text box.
    wText = WIDGET_TEXT(wBase, $
        /SCROLL, $
        VALUE=text, $
        XSIZE=xsize, YSIZE=ysize, $
        _EXTRA=_extra)


    ; Allow editing.
    wEdit = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:Edit'))
    wEditText = WIDGET_BUTTON(wEdit, $
        /CHECKED, $
        EVENT_PRO='idlitwdtextdisplay_edittext', $
        UVALUE=wText, $
        VALUE=IDLitLangCatQuery('UI:wdTxtDisp:EditTxt'))


    WIDGET_CONTROL, wBase, /REALIZE

    base_geom = WIDGET_INFO(wBase, /GEOMETRY)

    pState = PTR_NEW({ $
        wText: wText, $
        xsize: base_geom.xsize, $
        ysize: base_geom.ysize $
        })

    WIDGET_CONTROL, wBase, SET_UVALUE=pState

    XMANAGER, 'idlitwdtextdisplay', wBase, /NO_BLOCK

end

