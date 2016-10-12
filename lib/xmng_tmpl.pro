; $Id: //depot/idl/releases/IDL_80/idldir/lib/xmng_tmpl.pro#1 $
;
; Copyright (c) 1991-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	XMNG_TMPL
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual 
;	implementation of the XMNG_TMPL widget.  Use a global search and 
;	replace to replace the word "Xmng_tmpl" with the name of the routine 
;	you would like to use. 
;
;	All the comments with a "***" in front of them should be read, decided 
;	upon and removed for your final copy of the XMng_tmpl widget
;	routine.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	XMNG_TMPL
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls XMng_tmpl.  When this
;		ID is specified, the death of the caller results in the death
;		of Xmng_tmpl.
;
;	BLOCK:  Set this keyword to have XMANAGER block when this
;		application is registered.  By default the Xmanager
;               keyword NO_BLOCK is set to 1 to provide access to the
;               command line if active command 	line processing is available.
;               Note that setting BLOCK for this application will cause
;		all widget applications to block, not only this
;		application.  For more information see the NO_BLOCK keyword
;		to XMANAGER.
;
; OUTPUTS:
;
; OPTIONAL OUTPUT PARAMETERS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;	Initiates the XMANAGER if it is not already running.
;
; RESTRICTIONS:
;
; PROCEDURE:
;	Create and register the widget and then exit.
;
; MODIFICATION HISTORY:
;	Created from a template written by: Steve Richards, January, 1991.
;-

;*** Above is a comment template for all IDL library routines with some of the
;*** specifics for XMng_tmpl filled in.  All library routines should use this
;*** format so that the DOC_LIBRARY routine in IDL can be used to find out
;*** more about a given routine.  You should modify the above comments for 
;*** your application.  This header will then be displayed when DOC_LIBRARY is
;*** called for your routine.



;------------------------------------------------------------------------------
;	procedure XMng_tmpl_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the XMng_tmpl widget.  It is 
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the XMng_tmpl widget.  The tool menu choice routines are 
;*** already installed.  This routine is required for the XMng_tmpl widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------
PRO XMng_tmpl_ev, event

COMPILE_OPT hidden					; Don't appear in HELP
							; output unless HIDDEN
							; keyword is specified.

WIDGET_CONTROL, event.id, GET_UVALUE = eventval		;find the user value
							;of the widget where
							;the event occured
IF N_ELEMENTS(eventval) EQ 0 THEN RETURN
IF eventval EQ 'THEMENU' THEN BEGIN
CASE event.value OF

;*** here is where you would add the actions for your events.  Each widget
;*** you add should have a unique string for its user value.  Here you add
;*** a case for each of your widgets that return events and take the
;*** appropriate action.

  "XLoadct": XLoadct, GROUP = event.top			;XLoadct is the library
							;routine that lets you
							;select and adjust the
							;color palette being
							;used.

  "XPalette": XPalette, GROUP = event.top		;XPalette is the
							;library routine that
							;lets you adjust 
							;individual color
							;values in the palette.

  "XManagerTool": XMTool, GROUP = event.top		;XManTool is a library
							;routine that shows 
							;which widget
							;applications are 
							;currently registered
							;with the XManager as
							;well as which
							;background tasks.

  "Done": WIDGET_CONTROL, event.top, /DESTROY		;There is no need to
							;"unregister" a widget
							;application.  The
							;XManager will clean
							;the dead widget from
							;its list.

  ELSE: MESSAGE, "Event User Value Not Found"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE
ENDIF

END ;============= end of XMng_tmpl event handling routine task =============



;------------------------------------------------------------------------------
;	procedure XMng_tmpl
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the XMng_tmpl widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the 
;*** currently active widgets.  
;------------------------------------------------------------------------------
PRO XMng_tmpl, GROUP = GROUP, BLOCK=block

;*** If XMng_tmpl can have multiple copies running, then delete the following
;*** line and the comment for it.  Often a common block is used that prohibits
;*** multiple copies of the widget application from running.  In this case, 
;*** leave the following line intact.

IF(XRegistered("XMng_tmpl") NE 0) THEN RETURN		;only one instance of
							;the XMng_tmpl widget
							;is allowed.  If it is
							;already managed, do
							;nothing and return

IF N_ELEMENTS(block) EQ 0 THEN block=0

;*** Next the main base is created.  You will probably want to specify either
;*** a ROW or COLUMN base with keywords to arrange the widget visually.

XMng_tmplbase = WIDGET_BASE(TITLE = "XMng_tmpl")	;create the main base

;*** Here some default controls are built in a menu.  The descriptions of these
;*** procedures can be found in the XMng_tmpl_ev routine above.  If you would
;*** like to add other routines or remove any of these, remove them both below
;*** and in the XMng_tmpl_ev routine.

menu = CW_PdMenu(XMng_tmplbase, /RETURN_NAME, $
                 ['1\File',$
                  '2\Done',$
                  '1\Tools',$
                  '0\XLoadct',$
                  '0\XPalette',$
                  '2\XManagerTool'], UVALUE='THEMENU')


;*** Typically, any widgets you need for your application are created here.
;*** Create them and use XMng_tmplbase as their base.  They will be realized
;*** (brought into existence) when the following line is executed.

WIDGET_CONTROL, XMng_tmplbase, /REALIZE			;create the widgets
							;that are defined

XManager, "XMng_tmpl", XMng_tmplbase, $			;register the widgets
		EVENT_HANDLER = "XMng_tmpl_ev", $	;with the XManager
		GROUP_LEADER = GROUP, $			;and pass through the
		NO_BLOCK=(NOT(FLOAT(block)))		;group leader if this
							;routine is to be 
							;called from some group
							;leader.

END ;==================== end of XMng_tmpl main routine =======================
