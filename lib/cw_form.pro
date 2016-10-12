; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_form.pro#1 $
;
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	CW_FORM
;
; PURPOSE:
;	CW_FORM is a compound widget that simplifies creating
;	small forms which contain text, numeric fields, buttons,
;	lists and droplists.  Event handling is also simplified.
;
; CATEGORY:
;	Compound widgets.
;
; CALLING SEQUENCE:
;	widget = CW_FORM([Parent,] Desc)
;
; INPUTS:
;       Parent:	The ID of the parent widget.  Omitted for a top level
;		modal widget.

; Desc: A string array describing the form.  Each element of the
;	string array contains two or more comma-delimited fields.  The
;	character '\' may be used to escape commas that appear within fields.
;	To include the backslash character, escape it with a second
;	backslash.  Field names are case insensitive.
;
;	The fields are defined as follows:
;
; Field 1: Depth: the digit 0, 1, 2, or 3.  0 continues the current
;	level, 1 begins a new level, 2 denotes the last element of the
;	current level, and 3 both begins a new level and is the last entry of
;	the current level.  Nesting is used primarily with row or column
;	bases for layout.  See the example below.
; Field 2: Item type: BASE, BUTTON, DROPLIST, FLOAT, INTEGER, LABEL, LIST,
;		or TEXT.
;	The items return the following value types:
;	BUTTON - For single buttons, 0 if clear, 1 if set.
;		For multiple buttons, also called button groups, that are
;		exclusive, the index of the currently set button is returned.
;		For non-exclusive button groups, the value is an array
;		with an element for each button, containing 1
;		if the button is set, 0 otherwise.
;	DROPLIST, LIST - a 0 based index indicating which item is selected.
;	FLOAT, INTEGER, TEXT - return their respective data type.
;
; Field 3: Initial value.  Omitted for bases.
;	For BUTTON and DROPLIST items, the value field contains one
;		or more item names, delimited by the | character.
;	For FLOAT, INTEGER, LABEL, and TEXT items the value field contains the
;		initial value of the field.
;
; Fields 4 and following: Keywords or Keyword=value pairs that specify
;	optional attributes or options.  Keywords are case insensitive
;	and an optional leading '/' character is discarded.
;	Possibilities include:
;
;	COLUMN	If present, specifies column layout for bases or multiple
;		buttons.
;	EXCLUSIVE  If present makes an exclusive set of buttons.  The
;		default is nonexclusive.
;	EVENT=<name> specifies the name of a user-written event function that
;		is called whenever the element is changed.  The function
;		is called with one parameter, the event structure.  It may
;		return an event structure or zero to indicate that no
;		further event processing is desired.
;	FONT=<font name>  If present, the font for the item is specified.
;	FRAME:	If present, a frame is drawn around the item.  May be used
;		with all items.
;	LABEL_LEFT=<label>  annotate a button or button group with a label
;		placed to the left of the buttons.  Valid with BUTTON,
;		DROPLIST, FLOAT, INTEGER, LIST and TEXT items.
;	LABEL_TOP=<label> annotate a button or button group with a label
;		placed at the top of the buttons.  Valid with BUTTON,
;		DROPLIST, FLOAT, INTEGER, LIST and TEXT items.
;	LEFT, CENTER, or RIGHT   Specifies alignment of label items.
;	QUIT	If present, when the user activiates this entry when it
;		is activated as a modal widget, the form is destroyed
;		and its value returned as the result of CW_FORM.  For non-
;		modal form widgets, events generated by changing this item
;		have their QUIT field set to 1.
;	ROW	If present, specifies row layout for bases or multiple
;		buttons.
;	SET_VALUE  Sets the initial value of button groups or droplists.
;	TAG=<name>   the tag name  of this element.  The widget's value
;		is a structure corresponding to the form.  Each form item
;		has a corresponding tag-value pair in the widget's value.
;		Default = TAGnnn, where nnn is the index of the item
;		in the Desc array.
;	WIDTH=n Specifies the width, in characters, of a TEXT, INTEGER,
;		or FLOAT item.
;
; KEYWORD PARAMETERS:
;	COLUMN:		  If set the main orientation is vertical, otherwise
;			  horizontal.
;	IDS:		  A named variable into which the widget id of
;				each widget corresponding to an element
;				in desc is stored.
;	TITLE:		  The title of the top level base.  Not used
;			  if a parent widget is supplied.
;	UVALUE:		  The user value to be associated with the widget.
;       UNAME:            The user name to be associated with the widget.
;
; OUTPUTS:
;       If Parent is supplied, the result is the ID of the base containing
;	the form.  If Parent is omitted, the form is realized as a modal
;	top level widget. The function result is then a structure containing
;	the value of each field in the form when the user finishes.
;
;	This widget has a value that is a structure with a tag/value pair
;	for each field in the form.  WIDGET_CONTROL, id, GET_VALUE=v may
;	be used to read the current value of the form.  WIDGET_CONTROL, id,
;	SET_VALUE={ Tagname: value, ..., Tagname: value} sets the values
;	of one or more tags.
;
; SIDE EFFECTS:
;	Widgets are created.
;
; RESTRICTIONS:
;
; EXAMPLES:

;	**** Define a form, with a label, followed by two vertical button
;	groups one non-exclusive and the other exclusive, followed by a text
;	field, and an integer field, followed lastly by OK and Done buttons.
;	If either the OK or Done buttons are pressed, the form is exited.
;
;
;		; String array describing the form
;	desc = [ $
;	    '0, LABEL, Centered Label, CENTER', $
;		; Define a row base on a new depth.  All elements until a depth
;		; of two are included in the row.
; 	    '1, BASE,, ROW, FRAME', $
; 	    '0, BUTTON, B1|B2|B3, LABEL_TOP=Nonexclusive:, COLUMN, ' + $
;               'TAG=bg1, ' + $
;               'SET_VALUE=[1\, 0\, 1]', $   ; set first and third buttons
;		; This element terminates the row.
; 	    '2, BUTTON, E1|E2|E2, EXCLUSIVE,LABEL_TOP=Exclusive,COLUMN, ' + $
;               'TAG=bg2, ' + $
;               'SET_VALUE=1', $   ; set second button
; 	    '0, TEXT, , LABEL_LEFT=Enter File name:, WIDTH=12, TAG=fname', $
;	    '0, INTEGER, 0, LABEL_LEFT=File size:, WIDTH=6, TAG=fsize', $
;	    '1, BASE,, ROW', $
;	    '0, BUTTON, OK, QUIT,FONT=*helvetica-medium-r-*-180-*,TAG=OK', $
;	    '2, BUTTON, Cancel, QUIT']
;
;    To use the form in a modal manner:
;	  a = CW_FORM(desc, /COLUMN)
;	  help, /st,a
;    When the form is exited, (when the user presses the OK or Cancel buttons),
;	the following structure is returned as the function's value:
;		BG1             INT       Array(3)  (Set buttons = 1, else 0)
;		BG2             INT              1  (Exclusive: a single index)
;		FNAME           STRING    'test.dat' (text field)
;		FSIZE           LONG               120 (integer field)
;		OK              LONG                 1 (this button was pressed)
;		TAG8            LONG                 0 (this button wasn't)
;	Note that if the Cancel button is pressed, the widget is exited with
;	the OK field set to 0.
;
;  *****************
;
;    To use CW_FORM inside another widget:
;	    a = widget_base(title='Testing')
;	    b = cw_form(a, desc, /COLUMN)
;	    WIDGET_CONTROL, a, /real
;	    xmanager, 'Test', a
;	In this example, an event is generated each time the value of
;	the form is changed.  The event has the following structure:
;	   ID              LONG                <id of CW_FORM widget>
;	   TOP             LONG                <id of top-level widget>
;	   HANDLER         LONG                <internal use>
;	   TAG             STRING    'xxx'	; name of field that changed
;	   VALUE           INT       xxx	; new value of changed field
;	   QUIT            INT              0	; quit flag
;    The event handling procedure (in this example, called TEST_EVENT), may use
;	the TAG field of the event structure to determine which field
;	changed and perform any data validation or special actions required.
;	It can also get and set the value of the widget by calling
;	WIDGET_CONTROL.
;    A simple event procedure might be written to monitor the QUIT field
;	of events from the forms widget, and if set, read and save the
;	widget's value, and finally destroy the widget.
;
;    To set or change a field within the form from a program, use a the
;	WIDGET_CONTROL procedure:
;	   	WIDGET_CONTROL, b, SET_VALUE={FNAME: 'junk.dat'}
;	This statement sets the file name field of this example.
;
; MODIFICATION HISTORY:
;	January, 1995.  DMS, Written.
;       June, 1996.     MLR, allowed SET_VALUE to be specified in the
;                       description string for DROPLIST widgets.
;-
;


function CW_FORM_PARSE, Extra, Name, Value, Index=Index
; Given the extra fields in the string array Extra,
;	determine if one field starts with Name.
; If so, return TRUE, otherwise FALSE.
; If the field contains the character '=' after Name, return the contents
; of the field following the equal sign in Value.
; Return the index of the found element in Index.
;

  COMPILE_OPT hidden

found = where(strpos(extra, name) eq 0, count)
if count eq 0 then return, 0
if count gt 1 then message,'Ambiguous field name: '+name, /CONTINUE

index = found[0]
item = extra[index]
nlen = strlen(name)
value = ''			;Assume no value
equal = strpos(item,'=',nlen) ;Find = character
if equal ge 0 then begin
   value = strmid(item, equal+1, 1000) ;Extract following
   ; Tag must not start with space; Other fields such as
   ; Label may have leading or trailing spaces so only trim Tag.
   if (strupcase(name) eq 'TAG') then value=strtrim(value, 2)
endif
extra[index]=''			;clean it out...
return, 1
end


pro CW_FORM_APPEND, extra, e, keyword, USE_VALUE=use_value, ACTUAL_KEYWORD=akw
  COMPILE_OPT hidden

if CW_FORM_PARSE(e, keyword, value) then begin
    if n_elements(akw) le 0 then akw = keyword
    if KEYWORD_SET(use_value) eq 0 then value = 1
    if n_elements(extra) eq 0 then extra = create_struct(akw, value) $
    else extra = create_struct(extra, akw, value)
endif
end



pro CW_FORM_LABEL, parent, nparent, e, frame
;Put LABEL_LEFT and/or LABEL_RIGHT on a base.

  COMPILE_OPT hidden

nparent = parent
if CW_FORM_PARSE(e, 'LABEL_LEFT', value) then begin
	nparent = WIDGET_BASE(nparent, /ROW, FRAME=frame)
	frame = 0
	junk1 = WIDGET_LABEL(nparent, VALUE=value)
	endif
if CW_FORM_PARSE(e, 'LABEL_TOP', value) then begin
	nparent = WIDGET_BASE(nparent, /COLUMN, FRAME=frame)
	frame = 0
	junk1 = WIDGET_LABEL(nparent, VALUE=value)
	endif
end



pro CW_FORM_BUILD, parent, desc, cur, ids, lasttag
; Recursive routine that builds the form hierarchy described in DESC.
; Returns the ID of each button in ids.

  COMPILE_OPT hidden

; Format of a field descriptor:
; Field 0,  Flags:
; Field 1, Type of item.  BASE, LABEL, INTEGER, FLOAT, DROPLIST,
;	EXCLUSIVE_BUTTONS, TEXT
; Field 2, Value of item...
; Fields >= 3, optional flags
;
;
; Type id = 0 for bgroup, 1 for droplist, 2 for button,
;	3 for integer, 4 for float, 5 for text, 6 for list.
;
  n = n_elements(desc)

  while cur lt n do begin
    a = STRTRIM(strtok(desc[cur], ',', $
           /PRESERVE_NULL, /EXTRACT, ESC='\'), 2)
    if n_elements(a) lt 2 then $
	message,'Form element '+strtrim(cur,2)+'is missing a field separator'
    extra=0			;Clear extra keywords by making it undefined
    junk = temporary(extra)	;Clear common param list
    type = -1			;Assume type == no events.
    quit = 0
    frame = 0
    if n_elements(a) gt 3 then begin	;Addt'l common params?
	e = a[3:*]		;Remove leading/trailing blanks
	for i=0, n_elements(e)-1 do begin  ;Up case it
	    s = e[i]
	    if strmid(s,0,1) eq '/' then s = strmid(s,1,1000)  ;Disc. leading /
	    equal = strpos(s, '=')
	    if equal gt 0 then $
		e[i] = strupcase(strmid(s,0,equal)) + strmid(s,equal, 1000) $
	    else e[i] = strupcase(s)
	    endfor
	quit = CW_FORM_PARSE(e, 'QUIT')
	frame = CW_FORM_PARSE(e, 'FRAME')
	efn = CW_FORM_PARSE(e, 'EVENT', event_fun)
	CW_FORM_APPEND, extra, e, 'FONT', /USE_VALUE
	CW_FORM_APPEND, extra, e, 'COLUMN'
	CW_FORM_APPEND, extra, e, 'ROW'
	CW_FORM_APPEND, extra, e, 'LEFT', ACTUAL='ALIGN_LEFT'
	CW_FORM_APPEND, extra, e, 'CENTER', ACTUAL='ALIGN_CENTER'
	CW_FORM_APPEND, extra, e, 'RIGHT', ACTUAL='ALIGN_RIGHT'
    endif else e = ''

    case STRUPCASE(a[1]) of		;Which widget type?
'BASE': BEGIN
    new = WIDGET_BASE(parent, FRAME=frame, _EXTRA=extra)
    ENDCASE
'BUTTON': BEGIN
    CW_FORM_APPEND, extra, e, 'LABEL_LEFT', /USE_VALUE
    CW_FORM_APPEND, extra, e, 'LABEL_TOP', /USE_VALUE
    exclusive = CW_FORM_PARSE(e,'EXCLUSIVE')
    no_release = CW_FORM_PARSE(e,'NO_RELEASE')
    values = strtok(a[2],'|', /EXTRACT, ESC='\')
    if n_elements(values) ge 2 then begin
        type = 0
        if CW_FORM_PARSE(e, 'SET_VALUE', temp) then begin

            ; Convert the string list of 0's or 1's into ints.
            brack = STRPOS(temp, '[')
            if (brack ge 0) then $
                temp = STRMID(temp, brack + 1)
            brack = STRPOS(temp, ']')
            if (brack gt 0) then $
                temp = STRMID(temp, 0, brack)
            sval = FIX(STRSPLIT(temp, ',', /EXTRACT))

           new = CW_BGROUP(parent, strtok(a[2],'|',/EXTRACT),  $
		        EXCLUSIVE = exclusive, NONEXCLUSIVE = 1-exclusive, $
		        FRAME=frame, NO_RELEASE = no_release, $
                        SET_VALUE = sval, _EXTRA=extra)
        endif else begin
           new = CW_BGROUP(parent, strtok(a[2],'|',/EXTRACT),  $
		        EXCLUSIVE = exclusive, NONEXCLUSIVE = 1-exclusive, $
		        FRAME=frame, NO_RELEASE = no_release, _EXTRA=extra)
        endelse
        WIDGET_CONTROL, new, GET_VALUE=value
    endif else begin
        type = 2
	new = WIDGET_BUTTON(parent, value=values[0], FRAME=frame, _EXTRA=extra)
	value = 0L
    endelse
    uextra = { value: value }
    ENDCASE
'DROPLIST': BEGIN
    CW_FORM_LABEL, parent, nparent, e, frame
    new = WIDGET_DROPLIST(nparent, VALUE = strtok(a[2], '|',/EXTRACT), $
		FRAME=frame, UVALUE=ids[n], _EXTRA=extra)
    if CW_FORM_PARSE(e, 'SET_VALUE', value) then begin
          WIDGET_CONTROL, new, SET_DROPLIST_SELECT = FIX(value)
          uextra = { VALUE: FIX(value) }
    endif else uextra = { VALUE: 0L }
    type = 1
    ENDCASE
'INTEGER': BEGIN
    type = 3
    value = 0L
process_integer:
    uextra = { VALUE: value }
    CW_FORM_LABEL, parent, nparent, e, frame
    if CW_FORM_PARSE(e, 'WIDTH', temp) then width = fix(temp) else width=6
    new = WIDGET_TEXT(nparent, /ALL_EVENTS, /EDITABLE, YSIZE=1, $
		XSIZE=width, UVALUE=ids[n])
    if n_elements(a) ge 3 then BEGIN		;Save value
	WIDGET_CONTROL, new, SET_VALUE=a[2]
	uextra.value = a[2]
	endif
   ENDCASE
'FLOAT': BEGIN
    type = 4
    value = 0.0
    goto, process_integer
    ENDCASE
'LABEL': BEGIN
    new = WIDGET_LABEL(parent, value=a[2], FRAME=frame, _EXTRA=extra)
    ENDCASE
'LIST': BEGIN
    CW_FORM_LABEL, parent, nparent, e, frame
    v = strtok(a[2], '|',/EXTRACT)
    if CW_FORM_PARSE(e, 'HEIGHT', temp) eq 0 then temp = n_elements(v)
    new = WIDGET_LIST(nparent, VALUE = v, YSIZE=temp, $
		FRAME=frame, UVALUE=ids[n], _EXTRA=extra)
    if CW_FORM_PARSE(e, 'SET_VALUE', value) then begin
          WIDGET_CONTROL, new, SET_LIST_SELECT = FIX(value)
          uextra = { VALUE: FIX(value) }
    endif else uextra = { VALUE: 0L }
    v = 0
    type = 6
    ENDCASE
'TEXT': BEGIN
    type=5
    value = ''
    goto, process_integer
    ENDCASE
else: BEGIN
	MESSAGE,'Illegal form element type: ' + a[1], /CONTINUE
	new = WIDGET_BASE(parent)
    ENDCASE
ENDCASE

    ids[cur] = new
    if type ge 0 then begin
	if CW_FORM_PARSE(e, 'TAG', value) then value = STRUPCASE(value) $
	else value='TAG'+strtrim(cur,2)	  ;default name = TAGnnn.
        u = CREATE_STRUCT( $
		{ type: type, base: ids[n+1], tag:value, next: 0L, quit:quit}, $
		uextra)
	widget_control, new, SET_UVALUE= u
		;First tag?  If so, set child uvalue -> important widget ids.
	if lasttag eq 0 then begin
	    WIDGET_CONTROL, ids[n], GET_UVALUE=tmp, /NO_COPY
	    tmp.head = new
	    WIDGET_CONTROL, ids[n], SET_UVALUE=tmp, /NO_COPY
	endif else begin		;Otherwise, update chain.
	    WIDGET_CONTROL, lasttag, GET_UVALUE=u, /NO_COPY
	    u.next = new
	    WIDGET_CONTROL, lasttag, SET_UVALUE=u, /NO_COPY
	    endelse
	lasttag = new
	if (N_ELEMENTS(efn) NE 0) AND (N_ELEMENTS(event_fun) NE 0) then $
           WIDGET_CONTROL, new, EVENT_FUNC = event_fun
	endif			;Type

    i = where(strlen(e) gt 0, count)
    if count gt 0 then begin	;Unrecognized fields?
	Message, /CONTINUE, 'Descriptor: '+ desc[cur]
	for j=0, count-1 do message, /CONTINUE, 'Unrecognized field: '+ e[i[j]]
	endif

    cur = cur + 1
    dflags = fix(a[0])		;Level flags
    if dflags and 1 then CW_FORM_BUILD, new, desc, cur, ids, lasttag  ;Begin new
    if (dflags and 2) ne 0 then return	;End current
  endwhile
end				;CW_FORM_BUILD



Function CW_FORM_EVENT, ev		;Event handler for CW_FORM
  COMPILE_OPT hidden
widget_control,   ev.id, GET_UVALUE=u, /NO_COPY  ;What kind of widget?

if (u.type eq 1) or (u.type eq 6) then begin	;Droplist?  (can't get value)
    v = ev.index
    u.value = v
endif else if u.type eq 2 then begin
    v = ev.select
    u.value=v
endif else begin		;Other types of widgets
    WIDGET_CONTROL, ev.id, GET_VALUE=v
    if u.type ge 3 then begin  ;Toss selection events from text widgets
        v = v[0]
        ret = 0
        if ev.type eq 3 then goto, toss
        ; allow "+" or '-' to be entered without causing failure
        ; of implicit conversion below
        if (ev.type eq 0 or ev.type eq 2) and $
           (v eq '-' or v eq '+') then goto, toss
        ; allow "...e+" or '...e-' to be entered without causing failure
        ; of implicit conversion below
        if (strlen(v) gt 2) then begin
            tail = strupcase(strmid(v, strlen(v)-2))
            if (ev.type eq 0 or ev.type eq 2) and $
                (tail eq 'E-' or tail eq 'E+') then goto, toss
        endif
    endif
    on_ioerror, invalid
    u.value = v			;Does an implicit conversion
    v = u.value
    goto, back_in

; We come here if we get an invalid number.
invalid: WIDGET_CONTROL, ev.id, SET_VALUE=''  ;Blank it out
    v = ''
    u.value = ''
endelse			;u.type

back_in: ret= { id: u.base, top: ev.top, handler: 0L, $
		tag: u.tag, value: v, quit: u.quit} ;Our value
toss: widget_control, ev.id, SET_UVALUE=u, /NO_COPY	;Save new value...
return, ret
end			;CW_FORM_EVENT


Pro CW_FORM_SETV, id, value	;In this case, value = { Tagname : value, ... }
  COMPILE_OPT hidden
x = WIDGET_INFO(id, /CHILD)	;Get head of list
WIDGET_CONTROL, x, GET_UVALUE=u
head = u.head
tags = tag_names(value)
n = n_elements(tags)

while head ne 0 do begin
    WIDGET_CONTROL, head, GET_UVALUE=u, /NO_COPY
    w = where(u.tag eq tags, count)
    if count ne 0 then begin
	u.value = value.(w[0])	;Set the value
	if u.type eq 6 then $
          WIDGET_CONTROL, head, SET_LIST_SELECT=value.(w[0]) $
        else if u.type eq 1 then $
          WIDGET_CONTROL, head, SET_DROPLIST_SELECT = value.(w[0]) $
	else if u.type ne 2 then $
          WIDGET_CONTROL, head, SET_VALUE= $
            STRCOMPRESS(STRING(value.(w[0])), /REMOVE_ALL) ;Change the widget
	n = n - 1
	endif
    next = u.next
    WIDGET_CONTROL, head, SET_UVALUE=u, /NO_COPY
    if n le 0 then return		;Done...
    head = next
endwhile
end


Function CW_FORM_GETV, id	;Return value of a CW_FORM widget.
  COMPILE_OPT hidden

x = WIDGET_INFO(id, /CHILD)	;Get head of list
WIDGET_CONTROL, x, GET_UVALUE=u
head = u.head

while head ne 0 do begin
    WIDGET_CONTROL, head, GET_UVALUE=u, /NO_COPY
    if n_elements(ret) le 0 then ret = CREATE_STRUCT(u.tag, u.value) $
    else ret = CREATE_STRUCT(ret, u.tag, u.value)
    next = u.next
    WIDGET_CONTROL, head, SET_UVALUE=u, /NO_COPY
    head = next
endwhile
return, ret
end


pro cw_form_modal_event, ev
  COMPILE_OPT hidden

IF (TAG_NAMES(ev,/STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') THEN begin
    ev = CREATE_STRUCT(ev,'quit',1)
    ; reset id from the modal parent to it's child to access data
    base = WIDGET_INFO(ev.id, /CHILD)
    ev.id = base
endif

if ev.quit ne 0 then begin
    child = WIDGET_INFO(ev.id, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=u  ;Get handle
    WIDGET_CONTROL, ev.id, GET_VALUE=v  ;The widget's value
    WIDGET_CONTROL, ev.top, /DESTROY
    *u.handle = v
endif

end

FUNCTION CW_FORM, parent, desc, $
	COLUMN = column, $
	GROUP_LEADER=group_leader, $
	IDS=ids, TITLE=title, UVALUE=uvalue, $
    UNAME=uname, TAB_MODE=tab_mode

;  ON_ERROR, 2						;return to caller
  ; Set default values for the keywords
  If KEYWORD_SET(column) then row = 0 else begin row = 1 & column = 0 & end
  IF (NOT KEYWORD_SET(uname)) THEN UNAME='CW_FORM_UNAME'

  p = parent
  handle = 0L
  hasGroup = (N_ELEMENTS(group_leader) GT 0)
  if n_params() eq 1 then begin
	desc = parent
	if n_elements(title) le 0 then title='FORM Widget'
    temp = hasGroup ? group_leader : WIDGET_BASE()
	p = WIDGET_BASE(TITLE=title, Column = column, row=row, $
                        /TLB_KILL_REQUEST, $
                        GROUP_LEADER=temp, /MODAL)
	handle = PTR_NEW(/ALLOCATE_HEAP)
  endif
  Base = WIDGET_BASE(p, Column = column, row=Row)

  if ( n_elements(tab_mode) ne 0 ) then $
    WIDGET_CONTROL, Base, TAB_MODE = tab_mode

  if n_elements(uvalue) gt 0 then WIDGET_CONTROL, base, SET_UVALUE=uvalue
  if n_elements(uname) gt 0 then WIDGET_CONTROL, base, SET_UNAME=uname

  n = n_elements(desc)
  ids = lonarr(n+2)		;Element n is ^ to child, n+1 ^ to base
  child = WIDGET_BASE(base)	;Widget to contain info...
  ids[n] = child
  ids[n+1] = base
  lasttag = 0
  WIDGET_CONTROL, child, SET_UVALUE={ head: 0L, base: base, handle: handle}

  CW_FORM_BUILD, base, desc, 0, ids, lasttag
  widget_control, base, EVENT_FUNC='CW_FORM_EVENT', $
	FUNC_GET_VALUE='CW_FORM_GETV', PRO_SET_VALUE='CW_FORM_SETV'

  if n_params() eq 1 then begin		;Modal?
	WIDGET_CONTROL, p, /realize
	XMANAGER, 'CW_FORM', p, EVENT_HANDLER='CW_FORM_MODAL_EVENT'
        v = TEMPORARY(*handle)
	PTR_FREE, handle
    IF NOT hasGroup THEN WIDGET_CONTROL, temp, /DESTROY
	return, v
	endif
  return, base
END
