; $Id: //depot/idl/releases/IDL_80/idldir/lib/xregistered.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


function XRegistered, NAME, NOSHOW = NOSHOW
;+
; NAME: 
;	XREGISTERED
;
; PURPOSE:
;	This function returns non-zero if the widget named as its argument 
;	is currently registered with the XMANAGER as an exclusive widget, 
;	otherwise this routine returns false.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	Result = XREGISTERED(Name)
;
; INPUTS:
;	Name:	A string containing the name of the widget in question.
;
; KEYWORD PARAMETERS:
;	NOSHOW:	If the widget in question is registered, it is brought
;		to the front of all the other windows by default.  Set this
;		keyword to keep the widget from being brought to the front.
;
; OUTPUTS:
;	If the named widget is registered, XREGISTERED returns the number
;	of instances of that name in the list maintained by XMANAGER.  
;	Otherwise, XREGISTERED returns 0.
;
; COMMON BLOCKS:
;	MANAGED
;
; SIDE EFFECTS:
;	Brings the widget to the front of the desktop if it finds one.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	Searches the list of exclusive widget names and if a match is found
;	with the one in question, the return value is modified.
;
; MODIFICATION HISTORY:
;	Written by Steve Richards, November, 1990
;	Jan, 92 - SMR	Fixed a bug where an invalid widget
;			was being referenced with 
;			WIDGET_CONTROL and the /SHOW keyword.
;	17 November 1993 - AB and SMR. Added ID validity checking to
;			fix a bug where already dead widgets were being
;			accessed.
;	Apr, 96 - DJE	Rewrite for asynchronous widget event handling.
;-

  COMMON managed,	ids, $		; IDs of widgets being managed
  			names, $	; and their names
			outermodal	; list of active modal widgets

  FORWARD_FUNCTION	LookupManagedWidget

  ; If no widgets are being managed, we're done. (This also handles the case
  ; where XMANAGER hasn't been compiled yet.)
  IF (NOT keyword_set(ids)) THEN $
    return, 0

  answer = 0
  
  ; look for the named widget
  id = LookupManagedWidget(name)
  IF (id NE 0L) THEN BEGIN
    ; bring the widget to the front
    IF (NOT keyword_set(noshow)) THEN $
      widget_control, id, /show

    ; return the count of widgets with the given name
    tmp = where(names EQ name, answer)
  ENDIF

  RETURN, answer

END

