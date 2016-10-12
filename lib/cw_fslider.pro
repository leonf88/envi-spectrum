; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_fslider.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_FSLIDER
;
; PURPOSE:
;   The standard slider provided by the WIDGET_SLIDER() function is
;   integer only. This compound widget provides a floating point
;   slider.
;
; CATEGORY:
;   Compound widgets.
;
; CALLING SEQUENCE:
;   widget = CW_FSLIDER(Parent)
;
; INPUTS:
;       Parent:     The ID of the parent widget.
;
; KEYWORD PARAMETERS:
;   DRAG:       Set this keyword to zero if events should only
;           be generated when the mouse is released. If it is
;           non-zero, events will be generated continuously
;           when the slider is adjusted. Note: On slow systems,
;           /DRAG performance can be inadequate. The default
;           is DRAG=0.
;       EDIT:       Set this keyword to make the slider label be
;           editable. The default is EDIT=0.
;   EVENT_FUNC:    The name of an optional user-supplied event function
;           for events. This function is called with the return
;           value structure whenever the slider value is changed, and
;           follows the conventions for user-written event
;           functions.
;   FORMAT:     Provides the format in which the slider value is
;           displayed. This should be a format as accepted by
;           the STRING procedure. The default is FORMAT='(G13.6)'
;   FRAME:      Set this keyword to have a frame drawn around the
;           widget. The default is FRAME=0.
;   MAXIMUM:    The maximum value of the slider. The default is
;           MAXIMUM=100.
;   MINIMUM:    The minimum value of the slider. The default is
;           MINIMUM=0.
;   SCROLL      Sets the SCROLL keyword to the WIDGET_SLIDER underlying
;           this compound widget. Unlike WIDGET_SLIDER, the
;           value given to SCROLL is taken in the floating units
;           established by MAXIMUM and MINIMUM, and not in pixels.
;   SUPPRESS_VALUE: If true, the current slider value is not displayed.
;           The default is SUPPRESS_VALUE=0.
;   TITLE:      The title of slider. (The default is no title.)
;   UVALUE:     The user value for the widget.
;   UNAME:      The user name for the widget.
;   VALUE:      The initial value of the slider
;   VERTICAL:   If set, the slider will be oriented vertically.
;           The default is horizontal.
;   XSIZE:      For horizontal sliders, sets the length.
;   YSIZE:      For vertical sliders, sets the height.
;
; OUTPUTS:
;       The ID of the created widget is returned.
;
; SIDE EFFECTS:
;   This widget generates event structures containing a field
;   named value when its selection thumb is moved. This is a
;   floating point value.
;
; PROCEDURE:
;   WIDGET_CONTROL, id, SET_VALUE=value can be used to change the
;       current value displayed by the widget.  Optionally, the
;       value supplied to the SET_VALUE keyword can be a three
;       element vector consisting of [value, minimum, maximum]
;       in order to change the minimum and maximum values as
;       well as the slider value itself.
;
;   WIDGET_CONTROL, id, GET_VALUE=var can be used to obtain the current
;       value displayed by the widget.  The maximum and minimum
;       values of the slider can also be obtained by calling the
;       FSLIDER_GET_VALUE function directly (rather than the standard
;       usage through the WIDGET_CONTROL interface) with the optional
;       keyword MINMAX:
;           sliderVals = FSLIDER_GET_VALUE(id, /MINMAX)
;       When called directly with the MINMAX keyword, the return
;       value of FSLIDER_GET_VALUE is a three element vector
;       containing [value, minimum, maximum].
;
;
; MODIFICATION HISTORY:
;   April 2, 1992, SMR and AB
;       Based on the RGB code from XPALETTE.PRO, but extended to
;       support color systems other than RGB.
;   5 January 1993, Mark Rivers, Brookhaven National Labs
;       Added EDIT keyword.
;       7 April 1993, AB, Removed state caching.
;   28 July 1993, ACY, set_value: check labelid before setting text.
;   3 October 1995, AB, Added SCROLL keyword.
;   15 July 1998, ACY, Added ability to set and get minimum and maximum.
;   24 July 2000, KDB, Fixed scroll keyword modification.
;   March 2001, CT, RSI: Add double precision. Store value internally,
;        separate from either scrollbar value or text label value.
;-

;-----------------------------------------------------------------------------
; Helper function to calculate integer slider value from floating-point.
; Note - The "value" argument will be truncated to lie within bottom...top.
; We will use an accuracy of 1e5 for the slider position.
function fslider_value2int, value, bottom, top
  COMPILE_OPT hidden

    ; Make sure new value is within range. Different test if bottom > top.
    value = (bottom le top) ? bottom > value < top : top > value < bottom
    return, LONG(100000d * (double(value) - bottom)/(double(top) - bottom))
end

;-----------------------------------------------------------------------------
; Helper function to calculate floating-point value from integer slider.
; We will use an accuracy of 1e5 for the slider position.
function fslider_int2value, int, bottom, top
  COMPILE_OPT hidden

    value = ((double(int) / 100000d) * (double(top) - bottom)) + bottom
    ; Catch any roundoff errors. Different test if bottom > top.
    return, (bottom le top) ? bottom > value < top : top > value < bottom
end


;-----------------------------------------------------------------------------
; If valueIn is a valid number, then return it, otherwise return oldvalue.
function fslider_check_value, valueIn, oldvalue
    COMPILE_OPT hidden

    ; Convert the input value to a double. Any errors will be caught.
    ON_IOERROR, badConvert

    value = valueIn
    ; If value is an empty string, then return old value.
    ; We need this special check because double('') equals 0.0, but we don't
    ; want an empty text string to be equal to the value zero.
    if (SIZE(value,/TNAME) eq 'STRING') then begin
       if (STRLEN(value) eq 0) then return, oldvalue
    endif
    value = DOUBLE(value)
    ; If we've reached this point then the conversion was successful.
    return, value

badConvert:    ; Conversion failed.
    ; Suppress the error and return the old value.
    MESSAGE, /RESET
    return, oldvalue
end


;-----------------------------------------------------------------------------
; Retrieve the current slider value.
; This is either the text label value (if it exists), or the slider value.
function fslider_get_value, id, MINMAX=minmax

    COMPILE_OPT hidden
    ; Return the value of the slider
    ON_ERROR, 2                       ;return to caller

    stash = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=pState

    ; Return the value of the string label or slider value.
    ; If we only have a slider, then the value is already stored in pState.
    ret = (*pState).value
    if ((*pState).labelid ne 0L) then begin
       ; If we have a text label, then the user might have changed the text
       ; without hitting return. In this case, check the text value.
       WIDGET_CONTROL, (*pState).labelid, GET_VALUE=text_value
       text_value = text_value[0]
       if (text_value ne (*pState).text_value) then begin
         ; Text value has changed. Return the text value if valid,
         ; otherwise return the stored value.
         ret = FSLIDER_CHECK_VALUE(text_value, (*pState).value)
       endif
    endif
    if (KEYWORD_SET(minmax)) then $
       ret=[ret, (*pState).bot, (*pState).top]

    if not (*pState).doDouble then ret = FLOAT(ret)
    return, ret
end


;-----------------------------------------------------------------------------
; Set slider (and text label) to the new valueIn.
; ValueIn is unmodified upon return.
pro fslider_set_value, id, valueIn

    COMPILE_OPT hidden

    ; Set the value of both the slider and the label
    ON_ERROR, 2                       ;return to caller
    nV = N_ELEMENTS(valueIn)
    if ((nV ne 1) and (nV ne 3)) then $
       MESSAGE, 'SET_VALUE must have either 1 or 3 elements.'

    stash = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=pState

    ; If we are only inputting one value, then quietly verify it is valid.
    ; Otherwise, for 3 values, convert to double and don't suppress errors.
    value = (nv eq 1) ? $
       FSLIDER_CHECK_VALUE(valueIn, (*pState).value) : DOUBLE(valueIn)

    if (nv eq 3) then begin
       if (value[1] eq value[2]) then begin
         MESSAGE, /INFO, $
          'Min and Max cannot be equal. Ignoring SET_VALUE.'
         return
       endif
       (*pState).bot = value[1]
       (*pState).top = value[2]
    endif
    value = value[0]

    ; Set the slider.
    ; Note: the stored value may be slightly different from the slider
    ; position, due to loss of precision when converting to integer.
    ; FSLIDER_VALUE2INT will also truncate value to within bot,top.
    int_value = FSLIDER_VALUE2INT(value, (*pState).bot, (*pState).top)
    WIDGET_CONTROL, (*pState).slideid, SET_VALUE = int_value

    ; Set the text field.
    ; Note: the stored value may be slightly different from the text field,
    ; due to conversion with the string format.
    if ((*pState).labelid ne 0) then begin
       (*pState).text_value = STRING(value, format=(*pState).format)
       WIDGET_CONTROL, (*pState).labelid, SET_VALUE=(*pState).text_value
    endif

    ; Store the new slider value. This will have the full double precision,
    ; and will not have lost any precision either converting to a text label
    ; or converting to the slider integer.
    (*pState).value = value

end


;-----------------------------------------------------------------------------
function fslide_event, ev

  COMPILE_OPT hidden
  ON_ERROR, 2
  ; Retrieve the structure from the child that contains the sub ids
  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=pState

  ; See which widget was adjusted, the slider or the label
  case ev.id of
    (*pState).slideid: begin
       ; Get the non-adjusted value
       WIDGET_CONTROL, (*pState).slideid, GET_VALUE=int_value
       value = FSLIDER_INT2VALUE(int_value, (*pState).bot, (*pState).top)

       ; Update the string label and the slider.
       ; We will use SET_VALUE since it handles all the error checking.
       FSLIDER_SET_VALUE, ev.handler, value

       drag = ev.drag
    end
    (*pState).labelid: begin
       ; Get the new text value.
       WIDGET_CONTROL, (*pState).labelid, GET_VALUE=text_value

       ; Update the string label and the slider.
       ; We will use SET_VALUE since it converts string to double,
       ; and handles all the error checking.
       FSLIDER_SET_VALUE, ev.handler, text_value[0]

       drag = 0
    end
    else: MESSAGE, 'Unknown event.'
  endcase

  ; Retrieve the new value. This was changed in FSLIDER_SET_VALUE.
  value = FSLIDER_GET_VALUE(ev.handler)

  ret = { ID:parent, TOP:ev.top, HANDLER:0L, VALUE:value, DRAG:drag }
  if (*pState).efun eq '' then $
    return, ret $
  else $
    return, CALL_FUNCTION((*pState).efun, ret)
end


;-----------------------------------------------------------------------------
; Callback procedure. Called when the widget containing the stash dies.
; Used so we can free the pointer.
pro cw_fslider_kill_notify, wChild
  WIDGET_CONTROL, wChild, GET_UVALUE=pState
  PTR_FREE, pState
end


;-----------------------------------------------------------------------------
function cw_fslider, parent, $
        DOUBLE = doubleIn, $
        DRAG = drag, $
        EDIT = edit, $
        EVENT_FUNC = efun, $
        FRAME = frameIn, $
        MAXIMUM = maxIn, $
        MINIMUM = minIn, $
        SCROLL = scrollIn, $
        SUPPRESS_VALUE = sup, $
        TITLE = titleIn, $
        UVALUE = uval, $
        VALUE = valueIn, $
        VERTICAL = vert, $
        XSIZE = xsize, $
        YSIZE = ysize, $
        FORMAT=formatIn, $
        UNAME=unameIn, $
        TAB_MODE=tab_mode

  ON_ERROR, 2                       ;return to caller

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Incorrect number of arguments'

  ; Defaults for keywords
  IF NOT (KEYWORD_SET(drag))  THEN drag = 0
  IF NOT (KEYWORD_SET(edit))  THEN edit = 0
  if N_ELEMENTS(efun) le 0 THEN efun = ''
  frame = N_ELEMENTS(frameIn) gt 0 ? frameIn : 0
  maxx = N_ELEMENTS(maxIn) gt 0 ? maxIn : 100.0
  minn = N_ELEMENTS(minIn) gt 0 ? minIn : 0.0

  if (minn eq maxx) then $
    MESSAGE,'MINIMUM and MAXIMUM cannot be equal.'

  ; Default scroll is 1% of width.
  scroll = (N_ELEMENTS(scrollIn) gt 0) ? scrollIn : 0.01d*ABS(maxx - minn)
  tscroll = FSLIDER_VALUE2INT(scroll, 0, ABS(maxx-minn))

  IF NOT (KEYWORD_SET(sup))   THEN sup = 0
  title = (N_ELEMENTS(titleIn) gt 0) ? titleIn : ''
  uname = (N_ELEMENTS(unameIn) gt 0) ? unameIn : 'CW_FSLIDER_UNAME'
  value = (N_ELEMENTS(valueIn) gt 0) ? valueIn : minn
  format = (N_ELEMENTS(formatIn) gt 0) ? formatIn : '(G13.6)'

  doDouble = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
    (SIZE([value,minn,maxx],/TNAME) eq 'DOUBLE')

  pState = PTR_NEW({ $
    efun: efun, $
    slideid:0L, $
    labelid:0L, $
    top:maxx, $
    bot:minn, $
    value:0d, $
    text_value:'', $
    format:format, $
    doDouble: doDouble })

  ; Motif 1.1 and newer sliders react differently to XSIZE and YSIZE
  ; keywords than Motif 1.0 or OpenLook. These defs are for horizontal sliders
  version = WIDGET_INFO(/version)
  newer_motif = (version.style eq 'Motif') and (version.release ne '1.0')

  ; The sizes of the parts depend on keywords and whether or not the
  ; float slider is vertical or horizontal
  ;these are display specific and known to be inherently evil
  sld_thk = 16
  chr_wid = 7
  IF (KEYWORD_SET(vert)) THEN BEGIN
    if (newer_motif) then begin
      if (not KEYWORD_SET(xsize)) then xsize = 0
    endif else begin
      title_len = STRLEN(title) * chr_wid
      xsize = (sld_thk * 1.4) + title_len   ; Take label into account
    endelse
    IF NOT (KEYWORD_SET(ysize)) THEN ysize = 100
    l_yoff = ysize / 2
  ENDIF ELSE BEGIN                  ;horizontal slider
    vert = 0
    tmp = not keyword_set(xsize)
    if (newer_motif) then begin
      if (tmp) then xsize = 0
      IF NOT (KEYWORD_SET(ysize)) THEN ysize = 0
    endif else begin
      if (tmp) then xsize = 100
      IF (TITLE NE '') THEN sld_thk = sld_thk + 21
      ysize = sld_thk       ; Make the slider not waste label space
    endelse
    l_yoff = 0
  ENDELSE

  if (vert) then begin
    mainbase = WIDGET_BASE(parent, FRAME = frame, /ROW, UNAME=uname)
    labelbase = WIDGET_BASE(mainbase)
  endif else begin
    mainbase = WIDGET_BASE(parent, FRAME = frame, /COLUMN, UNAME=uname)
    labelbase = mainbase
  endelse
  WIDGET_CONTROL, mainbase, EVENT_FUNC = 'fslide_event', $
    PRO_SET_VALUE='FSLIDER_SET_VALUE', $
    FUNC_GET_VALUE='FSLIDER_GET_VALUE'
  if (N_ELEMENTS(uval) gt 0) then $
    WIDGET_CONTROL, mainbase, SET_UVALUE = uval
  if (N_ELEMENTS(tab_mode) ne 0) then $
    WIDGET_CONTROL, mainbase, TAB_MODE = tab_mode


  ; Only build the label if suppress_value is FALSE
  if (sup eq 0) then begin
    (*pState).labelid = WIDGET_TEXT(labelbase, YOFFSET = l_yoff, $
                edit=edit, UNAME=uname+'_TEXT')
  endif

    (*pState).slideid = WIDGET_SLIDER(mainbase, $
        TITLE = TITLE, $
        XSIZE = xsize, $
        YSIZE = ysize, $
        /SUPPRESS_VALUE, $
        MINIMUM = 0, $
        MAXIMUM = FSLIDER_VALUE2INT(1,0,1), $
        VERTICAL = vert, $
        DRAG=drag, $
        SCROLL=tscroll, $
        UNAME=uname+'_SLIDER')


  wChild = WIDGET_INFO(mainbase, /CHILD)
  WIDGET_CONTROL, wChild, $
    SET_UVALUE=pState, /NO_COPY, $
    KILL_NOTIFY='cw_fslider_kill_notify'

  ; Update the string label and the slider.
  FSLIDER_SET_VALUE, mainbase, value

  RETURN, mainbase

END
