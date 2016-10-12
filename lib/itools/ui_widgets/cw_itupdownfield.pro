; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itupdownfield.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_ITUPDOWNFIELD
;
; PURPOSE:
;   Compound widget for an up/down (spinner) field.
;
; CALLING SEQUENCE:
;   Result = CW_ITUPDOWNFIELD(wParent)
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; EVENT STRUCTURE:
;   When the field is modified (either directly) or by the
;   up/down buttons, the following event is returned:
;       {CW_ITUPDOWN, ID: id, TOP: top, $
;           HANDLER: handler, VALUE: value}
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-




;-------------------------------------------------------------------------
function cw_itupdownfield_TrimZeroes, str, units

    compile_opt idl2, hidden

    return, STRING(str, FORMAT='(G0)') + units

end


;-------------------------------------------------------------------------
function cw_itupdownfield_updown, event, DOWN=down

    compile_opt idl2, hidden

    ; Cache current select state. We use this at the end of the loop
    ; below to see if the mouse has been released.
    WIDGET_CONTROL, event.id, SET_UVALUE=event.select

    ; Are we done?
    if (event.select eq 0) then begin
        WIDGET_CONTROL, event.id, /CLEAR_EVENTS
        return, 0
    endif


    ; Retrieve our up/down base.
    wBase = WIDGET_INFO(WIDGET_INFO(event.id, /PARENT), /PARENT)
    ; This is our text field widget ID.
    wText = WIDGET_INFO(wBase, FIND_BY_UNAME='_text')


    ; Retrieve our parent's event handler if any.
    wHandler = wBase
    while (WIDGET_INFO(wHandler, /VALID)) do begin
        event_func = WIDGET_INFO(wHandler, /EVENT_FUNC)
        if (event_func) then $
            break
        event_pro = WIDGET_INFO(wHandler, /EVENT_PRO)
        if (event_pro) then $
            break
        wHandler = WIDGET_INFO(wHandler, /PARENT)
    endwhile

    incr = KEYWORD_SET(down) ? -1L : 1L

    WIDGET_CONTROL, wText, GET_UVALUE=state
    invInc = 1d/state.increment


    ; Number of times to iterate before actually starting spin.
    ; This allows the user to slowly press the button without
    ; activating the spinner.
    spinwait = 10

    result = 0

    ; We will bail out if the mouse is released.
    while (1) do begin

        t1 = SYSTIME(1)

        WIDGET_CONTROL, wText, GET_VALUE=oldvalue
        oldvalue = DOUBLE(oldvalue[0])

        ; Convert from value to an "integerized" value.
        integerized = oldvalue*invInc

        ; If already rounded to nearest fraction, then increment.
        ; Avoid roundoff errors by testing the diff against a tiny #.
        if (ABS(integerized - ROUND(integerized, /L64)) lt 1d-7) then begin
            ; Use an extra tiny increment to avoid roundoff errors.
            newvalue = oldvalue + incr*state.increment + 1d-9*incr
        endif else begin
            ; Otherwise, round off to nearest fraction as the first step.
            newvalue = (KEYWORD_SET(down) ? $
                FLOOR(integerized) : CEIL(integerized))*state.increment
        endelse


        newvalue = CW_ITUPDOWNFIELD_TrimZeroes(newvalue, state.units)
        state.value = newvalue
        WIDGET_CONTROL, wText, SET_VALUE=newvalue, SET_UVALUE=state


        if (event_func || event_pro) then begin
            myevent = {CW_ITUPDOWN, ID: wBase, TOP: event.top, $
                HANDLER: wHandler, VALUE: newvalue}
            ; Change our result to be whatever the event handler returns.
            if (event_func) then $
                result = CALL_FUNCTION(event_func, myevent) $
            else $
                CALL_PROCEDURE, event_pro, myevent
        endif

quickcheck:

        ; See if the mouse up has arrived.
        newevent = WIDGET_EVENT(event.top, BAD_ID=wDead, /NOWAIT)
        if (wDead ne 0L) then $
            return, 0

        WIDGET_CONTROL, event.id, GET_UVALUE=selectState
        if (selectState eq 0) then $
            return, result   ; mouse was released

        ; Loop several times at the beginning, before spinning.
        if (spinwait ne 0) then begin
            WAIT, 0.05d
            spinwait--
            goto, quickcheck
        endif

        time1 = SYSTIME(1) - t1
        if (time1 lt state.spinTime) then $
            WAIT, state.spinTime - time1

    endwhile

end


;-------------------------------------------------------------------------
function cw_itupdownfield_up, event
    compile_opt idl2, hidden
    return, CW_ITUPDOWNFIELD_UPDOWN(event)
end


;-------------------------------------------------------------------------
function cw_itupdownfield_down, event
    compile_opt idl2, hidden
    return, CW_ITUPDOWNFIELD_UPDOWN(event, /DOWN)
end


;-------------------------------------------------------------------------
function cw_itupdownfield_value, event

    compile_opt idl2, hidden

    ON_IOERROR, NULL

    WIDGET_CONTROL, event.id, $
        GET_VALUE=newvalue, GET_UVALUE=state
    oldvalue = state.value

    ; Test if we can successfully convert value to a double.
    ON_IOERROR, skip   ; suppress conversion warnings
    newvalue = DOUBLE(newvalue[0])
    ON_IOERROR, null
    newvalue = CW_ITUPDOWNFIELD_TrimZeroes(newvalue, state.units)

    ; Success, replace the previous uvalue with the new.
    state.value = newvalue
    WIDGET_CONTROL, event.id, $
        SET_VALUE=newvalue, SET_UVALUE=state

    ; Success, pass on event.
    wParent = WIDGET_INFO(event.id, /PARENT)
    return, {CW_ITUPDOWN, ID: wParent, TOP: event.top, $
        HANDLER: event.handler, VALUE: newvalue}

skip:
    ; Failure, restore the previous value.
    WIDGET_CONTROL, event.id, $
        SET_VALUE=oldvalue

    return, 0  ; swallow event
end


;-------------------------------------------------------------------------
function cw_itupdownfield_getvalue, wBase

    compile_opt idl2, hidden

    wText = WIDGET_INFO(wBase, FIND_BY_UNAME='_text')
    WIDGET_CONTROL, wText, GET_VALUE=value
    return, DOUBLE(value[0])

end


;-------------------------------------------------------------------------
pro cw_itupdownfield_setvalue, wBase, value

    compile_opt idl2, hidden

    ; Change the value.
    wText = WIDGET_INFO(wBase, FIND_BY_UNAME='_text')
    WIDGET_CONTROL, wText, SET_VALUE=STRING(value)

    ; Call our event handler to verify the value.
    dummy = CW_ITUPDOWNFIELD_VALUE( $
        {ID: wText, TOP: wBase, HANDLER: wText})


end


;-------------------------------------------------------------------------
function cw_itupdownfield, wParent, $
    INCREMENT=incrementIn, $
    LABEL=label, $
    SPIN_TIME=spinTimeIn, $
    UNITS=unitsIn, $
    VALUE=valueIn, $
    XLABELSIZE=xLabelSize, $
    _EXTRA=_extra

    compile_opt idl2, hidden


    ; Default increment is 0.1
    increment = N_ELEMENTS(incrementIn) ? DOUBLE(incrementIn[0]) : 0.1d
    spinTime = KEYWORD_SET(spinTimeIn) ? $
        (DOUBLE(spinTimeIn) > 0d) : 0.05d
    units = KEYWORD_SET(unitsIn) ? unitsIn : ''


    ; Each field has its own base.
    wBase = WIDGET_BASE(wParent, /ROW, $
        FUNC_GET_VALUE='cw_itupdownfield_getvalue', $
        PRO_SET_VALUE='cw_itupdownfield_setvalue', $
        XPAD=0, YPAD=0, SPACE=1, $
        _EXTRA=_extra)

    if (KEYWORD_SET(label)) then begin
        wLabel = WIDGET_LABEL(wBase, $
            VALUE=label, $
            XSIZE=xLabelSize)
    endif

    value =  CW_ITUPDOWNFIELD_TrimZeroes( $
        KEYWORD_SET(valueIn) ? valueIn : 0, units)
    state = {VALUE: value, $
        INCREMENT: increment, $
        SPINTIME: spinTime, $
        UNITS: units}


    wText = WIDGET_TEXT(wBase, $
        /EDITABLE, $
        EVENT_FUNC='cw_itupdownfield_value', $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        VALUE=value, $
        UNAME='_text', $
        UVALUE=state, $
        XSIZE=8)

    ; Up/down buttons.
    wButBase = WIDGET_BASE(wBase, $
        /ALIGN_CENTER, $
        /COLUMN, $
        /TOOLBAR, $
        XPAD=0, YPAD=0, SPACE=0)

    ; Motif needs an extra 1 pixel padding around bitmaps.
    isMotif = !version.os_family ne 'Windows'

    bitmap = FILEPATH('spinup.bmp', SUBDIR=['resource','bitmaps'])
    wButUp = WIDGET_BUTTON(wButBase, $
        EVENT_FUNC='cw_itupdownfield_up', $
        /BITMAP, VALUE=bitmap, /FLAT, $
        /PUSHBUTTON_EVENTS, $
        UNAME='_up', $
        UVALUE=0, $    ; mouse is up
        XSIZE=16+isMotif, YSIZE=10+isMotif)

    bitmap = FILEPATH('spindown.bmp', SUBDIR=['resource','bitmaps'])
    wButDown = WIDGET_BUTTON(wButBase, $
        EVENT_FUNC='cw_itupdownfield_down', $
        /BITMAP, VALUE=bitmap, /FLAT, $
        /PUSHBUTTON_EVENTS, $
        UNAME='_down', $
        UVALUE=0, $    ; mouse is up
        XSIZE=16+isMotif, YSIZE=10+isMotif)


    return, wBase
end


