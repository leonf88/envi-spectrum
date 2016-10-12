; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiprogressbar.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIProgressBar
;
; PURPOSE:
;   Provides the user interface for displaying a Progress Bar.
;
; CALLING SEQUENCE:
;   Result = IDLitUIProgressBar(oUI, Requester)
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;
;-



;-------------------------------------------------------------------------
function IDLitUIProgressBar, oUI, oProgress

   compile_opt idl2, hidden

    ; Basically that the text in the error object and display an
    ; dialog_message()

    common IDLitUIProgressBar_common, wID

    ; Initialize.
    if (N_ELEMENTS(wID) ne 1) then wID = 0L

    oProgress->GetProperty, MESSAGE=title, $
        PERCENT=percent, CANCEL=cancel, TIME=time

    ; Construct a new progress bar if none exists.
    if (~WIDGET_INFO(wID, /VALID)) then begin

        ; Sanity check.
        if (oProgress->IsDone()) then $
            return, 1

        ; Retrieve widget ID of top-level base.
        oUI->GetProperty, GROUP_LEADER=groupLeader
        ; Assume if we don't have a group leader, then we are
        ; running without a user interface. So just return quietly.
        if (~WIDGET_INFO(groupLeader, /VALID)) then $
            return, 1
        wID = IDLitwdProgressBar(CANCEL=cancel, $
            GROUP_LEADER=groupLeader, $
            TIME=time, $
            TITLE=title, $
            VALUE=STRTRIM(percent,2))

    endif else begin

        ; Update the progress bar. Reset the title in case it changed.
        if (title ne '') then $
            newtitle = title
        WIDGET_CONTROL, wID, SET_VALUE=percent, $
            TLB_SET_TITLE=newtitle

    endelse


    ; See if the progress bar has been cancelled.
    if (not WIDGET_INFO(wID, /VALID)) then $
        return, 0   ; failure

    ; Destroy if finished.
    if (oProgress->IsDone()) then $
        WIDGET_CONTROL, wID, /DESTROY

    return, 1   ; success
end

