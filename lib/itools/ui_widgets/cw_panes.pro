; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_panes.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	CW_PANES
;
; PURPOSE:
;       Create a two panel widget with a slider bar between the panels
;       and methods for exposing both or only one of the two panels.
;       Any widget, including bases and compound widgets, can be used
;       to populate the two panels.  Panel visiblity and slider
;       position can be changed via the mouse or programatically.
;
; CATEGORY:
;	Compound Widgets.
;
; CALLING SEQUENCE:
;	WidgetID = CW_PANES(parent)
;
; INPUTS:
;       PARENT: (required) Parent widget ID.
;
; KEYWORD PARAMETERS:
;       LEFT_CREATE_PRO: (required) Name of procedure for populating
;       the left pane.
;       RIGHT_CREATE_PRO: (required) Name of procedure for populating
;       the right pane.
;
;       LEFT_EVENT_PRO (LEFT_EVENT_FUNC): (required) Name of event
;       handling procedure (or function) for the left pane.
;       RIGHT_EVENT_PRO (RIGHT_EVENT_FUNC): (required) Name of event
;       handling procedure (or function) for the right pane.
;       TOP_EVENT_PRO (TOP_EVENT_FUNC): (required) Name of event
;       handling procedure (or function) for the top level base.
;
;       LEFT_XSIZE: X size of the left base.
;       LEFT_YSIZE: Y size of the left base.
;       RIGHT_XSIZE: X size of the right base.
;       RIGHT_YSIZE: Y size of the right base.
;
;       VISIBLE: 1: left pane visible, 2: right pane visible, 3: both
;       panes visible.
;
;       MARGIN: Minimum visible width of any visible pane.
;
;       UVALUE: uvalue for tlb.
;
;       UNAME: uname for tlb.
;
;       GROUP_LEADER: widget ID of optional group leader
;
; OUTPUTS:
;       The ID of the created widget.
;
; SIDE EFFECTS:
;	This widget generates event structures with the following definitions:
;
;       When a resize event of the top level base occurs an event
;       structure should be created and sent to 'cw_panes_event' as
;       follows:
;
;       eventStruct = {CW_PANES_RESIZE, ID:0l, TOP:0l, HANDLER:0l,
;                                       deltaX:0l, deltaY:0l}
;       void = CALL_FUNCTION('cw_panes_event',eventStruct)
;
;       The deltaX and deltaY will be recalculated and a
;       CW_PANES_RESIZE event will be then sent to the event handlers
;       of each pane.
;       Note: because all the event handlers of cw_panes are
;       functions, it is possible that the events could percolate back
;       to the top level base.
;
;       When the left or right arrow buttons are clicked, the top
;       level base will receive an event with the following structure:
;         {CW_PANES_SET_VALUE, ID:0l, TOP:0l, HANDLER:0l ,value:0}
;       Note: it is up to the event handler of the top level base to
;       change the value of the cw_panes base with the following call:
;
;       Widget_control, cw_panes_base, set_value=event.value
;
;       When the visibility of a pane changes the top level base will
;       receive an event with the following structure:
;         {CW_PANES_TOP_RESIZE, ID:0l, TOP:0l, HANDLER:0l, $
;                               deltaX:0l, deltaY:0l}
;
; PROCEDURE:
;	Use WIDGET_CONTROL, SET_VALUE and GET_VALUE to change/read the
;	widget's value.  Set set_ and get_ procedures for details.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;	AGEH,	January, 2003.	Original.
;

;----------------------------------------
;+
; NAME:
;	CW_PANES_LEFT_BUTTON
;
; PURPOSE:
;       Event handler when the left arrow button is clicked
;
; INPUTS:
;	EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_LEFT_BUTTON,event
  compile_opt hidden,idl2
  eventname = tag_names(event,/structure_name)

  cw_base = widget_info(widget_info(event.id,/parent),/parent)
  widget_control,cw_base,get_value=val

    CASE eventname OF

      'WIDGET_BUTTON' : BEGIN
        if ((val[0] AND 2) NE 0) && event.select then $
            CW_PANES_SET, cw_base, (val[0] AND 2)+(~(val[0] AND 1))
        END

      else: ; do nothing
    ENDCASE

END

;----------------------------------------
;+
; NAME:
;	CW_PANES_RIGHT_BUTTON
;
; PURPOSE:
;       Event handler when the right arrow button is clicked
;
; INPUTS:
;	EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_RIGHT_BUTTON,event
  compile_opt hidden,idl2

  eventname = tag_names(event,/structure_name)

  cw_base = widget_info(widget_info(event.id,/parent),/parent)
  widget_control,cw_base,get_value=val

    CASE eventname OF

      'WIDGET_BUTTON' : BEGIN
        if ((val[0] AND 1) NE 0) && event.select then $
            CW_PANES_SET, cw_base, (val[0] AND 1)+(~(val[0] AND 2))*2
      END

      else: ; do nothing
    ENDCASE

END

;----------------------------------------
;+
; NAME:
;	CW_PANES_LINE_EVENT
;
; PURPOSE:
;       Handles moving of slider bar and of sending resize events to
;       the children of the two sides.
;
; INPUTS:
;	EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
pro CW_PANES_LINE_EVENT, event
  compile_opt hidden,idl2

  widget_control,widget_info(event.top,find_by_uname='cw_panes_line'), $
                 get_uvalue=state

  eventname = tag_names(event,/structure_name)

  CASE eventname OF
    'WIDGET_DRAW' : BEGIN

      IF event.type EQ 4 THEN BEGIN
        CW_PANES_DISPLAY_SLIDER_BAR,event.id,*state.linepix, $
                                   state.visible NE 3, $
                                   state.clrs.face_3d
        return
      END

      ;;only valid if both panes are visible
      IF state.visible NE 3 THEN return

      ;;button down, make move line visible.  Note: two lines are
      ;;needed to handle differences between Windows and Motif
      IF event.type EQ 0 THEN BEGIN
        state.curpos = event.x
        state.delta = 0
        state.down = 1
        info = widget_info(state.line_base,/geometry)
        widget_control,state.moveline1,xoffset=info.xoffset
        widget_control,state.moveline1,map=1
        widget_control,state.moveline2,xoffset=info.xoffset+1
        widget_control,state.moveline2,map=1
      ENDIF

      ;;button up, hide move line and process new sizes and offsets of
      ;;side bases
      IF event.type EQ 1 THEN BEGIN
        state.down = 0
        infoleft = widget_info(state.left_base,/geometry)
        infoline = widget_info(state.line_base,/geometry)
        inforight = widget_info(state.right_base,/geometry)
        widget_control,state.moveline1,map=0,xoffset=0
        widget_control,state.moveline2,map=0,xoffset=0

        widget_control,state.left_base,xsize=((state.left_xsize+=state.delta))
        widget_control,state.line_base,xoffset=(infoline.xoffset+state.delta)>0
        widget_control,state.right_base, $
                       xsize=((state.right_xsize-=state.delta)), $
                       xoffset=(inforight.xoffset+state.delta)> $
                       infoline.scr_xsize

        child = widget_info(state.left_base,/child)
        evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                    HANDLER:child, deltaX:state.delta, deltaY:0l}
        IF state.leftIsPro THEN call_procedure,state.leftevent,evstruct $
        ELSE void = call_function(state.leftevent,evstruct)

        child = widget_info(state.right_base,/child)
        evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                    HANDLER:child, deltaX:-state.delta, deltaY:0l}
        IF state.rightIsPro THEN call_procedure,state.rightevent,evstruct $
        ELSE void = call_function(state.rightevent,evstruct)

      ENDIF

      ;;motion event whilst button is down, just move dashed line
      IF event.type EQ 2 AND state.down EQ 1 THEN BEGIN
        topinfo = widget_info(event.top,/geometry)
        lineinfo = widget_info(state.line_base,/geometry)
        rightinfo = widget_info(state.right_base,/geometry)
        leftinfo = widget_info(state.left_base,/geometry)
        state.delta = (-state.curpos-leftinfo.scr_xsize+state.margin)> $
          (event.x-state.curpos)< $
          (rightinfo.scr_xsize+lineinfo.scr_xsize-state.curpos-state.margin)
        widget_control,state.moveline1, $
                       xoffset=0>(lineinfo.xoffset+state.delta) $
                       <(topinfo.xsize-state.margin-1)
        widget_control,state.moveline2, $
                       xoffset=0>(lineinfo.xoffset+1+state.delta)< $
                       (topinfo.xsize-state.margin)
      ENDIF
    END

    'WIDGET_TRACKING' : BEGIN
      ;;only valid if both panes are visible
      IF state.visible EQ 3 THEN BEGIN
        ;;update the slider bar as highlighted or not
        CW_PANES_DISPLAY_SLIDER_BAR,event.id,*state.linepix, $
                                   event.enter ? 2 : 0, $
                                   state.clrs.face_3d
        ;;must set !d.window so something other than -1 in order to
        ;;change the direct graphics cursor without the system
        ;;creating a new window
        widget_control,event.id,get_value=wID
        win = !d.window
        wset,wID
        ;;change cursor to arrow on track_in, back to original on
        ;;track_out.  This will affect other direct graphics windows
        ;;but that is all part of the DG world.
        ;;use "Size E-W" (Windows) or "XC_sb_h_double_arrow" (X)
        IF event.enter THEN $
          device,cursor_standard= $
          (!version.os_family ne 'Windows' ? 108 : 32644) $
        ELSE device,/cursor_crosshair
        wset,win
      ENDIF ELSE BEGIN
        widget_control,event.id,get_value=wID
        win = !d.window
        wset,wID
        IF event.enter THEN $
          device,/cursor_original $
        ELSE device,/cursor_crosshair
        wset,win
      ENDELSE
    END

    ELSE :
  ENDCASE

  widget_control,widget_info(event.top,find_by_uname='cw_panes_line'), $
                 set_uvalue=state

end

;----------------------------------------
;+
; NAME:
;	CW_PANES_NULL_EVENT
;
; PURPOSE:
;       Allow events to percolate up, if needed
;
; INPUTS:
;	EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       Returns the event that was passed in
;-
FUNCTION CW_PANES_NULL_EVENT, event
  compile_opt hidden,idl2
  return,event
END

;----------------------------------------
;+
; NAME:
;	CW_PANES_DASHED_BAR
;
; PURPOSE:
;       Resize the dashed bar used during slider bar movement
;
; INPUTS:
;	DRAW1: (required) the widget ID of the first dashed bar base
;
;	DRAW2: (required) the widget ID of the first dashed bar base
;
;       YSIZE: (required) the new y size of the base
;
;       XSIZE: the x size of the base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_DASHED_BAR, draw1, draw2, ysize, xsize
  compile_opt hidden,idl2

  IF n_elements(xsize) EQ 0 THEN xsize = 2
  widget_control,draw1,get_value=wID1,ysize=ysize
  widget_control,draw2,get_value=wID2,ysize=ysize
  tvlct,rr,gg,bb,/get
  device,get_decomposed=dec
  device,decomposed=0
  win = !d.window
  tvlct,[0,255],[0,255],[0,255]
  b=(bytarr(~(xsize mod 2)+xsize,ysize)+ $
     (lindgen(xsize+1,ysize)mod 2))[0:xsize-1,0:ysize-1]
  wset,wID1
  tv,b
  wset,wID2
  tv,b
  wset,win
  device,decomposed=dec
  tvlct,rr,gg,bb

END

;----------------------------------------
;+
; NAME:
;	CW_PANES_EVENT
;
; PURPOSE:
;       Handle resize events from the top level base.
;
; INPUTS:
;       EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       Returns the input event
;-
FUNCTION CW_PANES_EVENT, event
  compile_opt hidden,idl2

  eventName = tag_names(event,/structure_name)

  IF ((eventName EQ 'CW_TREE_SEL') || $
      (eventName EQ 'CW_ITCOMPONENT_TREE')) && event.clicks EQ 2 THEN BEGIN
    top = event.id
    WHILE ((temp=widget_info(top,/parent))) NE 0 DO top=temp
    widget_control,widget_info(top,find_by_uname='cw_panes_line'), $
                   get_uvalue=state
    widget_control,state.wBase,get_value=visible
    IF (visible[0] AND 3) NE 3 THEN $
      widget_control,state.wBase, set_value=(visible[0] OR 3)
    oTool = (_IDLitSys_GetSystem())->_GetCurrentTool()
    if (eventName ne 'CW_ITCOMPONENT_TREE') then $
        return, event
    oObj = oTool->GetByIdentifier(event.identifier)
    IF ~OBJ_ISA(oObj,'IDLITCONTAINER') && $
      OBJ_ISA(oObj,'IDLITOBJDESC') THEN BEGIN
      oItem = oObj->getObjectInstance()
      IF OBJ_ISA(oItem,'IDLITOPERATION') THEN $
        void = oTool->DoAction(event.identifier)
      oObj->returnObjectInstance,oItem
    ENDIF
    return,event
  ENDIF

  IF eventName NE 'CW_PANES_RESIZE' || $
    ~widget_info(event.id,/valid_id) ||  $
    ((linebase=widget_info(event.id,find_by_uname='cw_panes_line'))) $
    EQ 0 THEN BEGIN
    return,event
  ENDIF

  widget_control,linebase,get_uvalue=state

  ;;get geometry for main components
  infoleft = widget_info(state.left_base,/geometry)
  infoline = widget_info(state.line_base,/geometry)
  inforight = widget_info(state.right_base,/geometry)
  infol = widget_info(state.line,/geometry)
  infobase = widget_info(state.wBase,/geometry)

  ;;calculate new sizes.
  deltaY = event.deltaY

  IF deltaY NE 0 THEN begin
    widget_control,state.left_base,ysize=((state.left_ysize+=deltaY))
    widget_control,state.right_base,ysize=((state.right_ysize+=deltaY))
    widget_control,state.line_base,scr_ysize=infoline.scr_ysize+deltaY
    widget_control,state.line,ysize=infol.ysize+deltaY
    ;;set sizes of slider bars
    cw_panes_dashed_bar,state.draw1,state.draw2,infoline.scr_ysize+deltaY
  ENDIF

  ;;send resize info to the right and left base children
  CASE state.visible OF
    1 : BEGIN

      widget_control,state.left_base,xsize=((state.left_xsize+=event.deltaX))
      child = widget_info(state.left_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:event.deltaX, deltaY:deltaY}
      IF state.leftIsPro THEN call_procedure,state.leftevent,evstruct $
      ELSE void = call_function(state.leftevent,evstruct)

      child = widget_info(state.right_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:0l, deltaY:deltaY}
      IF state.rightIsPro THEN call_procedure,state.rightevent,evstruct $
      ELSE void = call_function(state.rightevent,evstruct)
      widget_control,state.line_base,xoffset=infoline.xoffset+event.deltaX

    END
    2 : BEGIN

      widget_control,state.right_base,xsize=((state.right_xsize+=event.deltaX))
      child = widget_info(state.right_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:event.deltaX, deltaY:deltaY}
      IF state.rightIsPro THEN call_procedure,state.rightevent,evstruct $
      ELSE void = call_function(state.rightevent,evstruct)

      child = widget_info(state.left_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:0l, deltaY:deltaY}
      IF state.leftIsPro THEN call_procedure,state.leftevent,evstruct $
      ELSE void = call_function(state.leftevent,evstruct)

    END
    3 : BEGIN

      deltaXleft = ((infoleft.xsize+infoline.xsize+inforight.xsize $
                     + event.deltaX) - $
                    (inforight.xoffset + state.margin)) < 0
      deltaXright = event.deltaX > (state.margin - inforight.xsize)
      widget_control,state.left_base, $
                     xsize=((state.left_xsize+=deltaXleft))

      child = widget_info(state.left_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:deltaXleft, deltaY:deltaY}
      IF state.leftIsPro THEN call_procedure,state.leftevent,evstruct $
      ELSE void = call_function(state.leftevent,evstruct)
      widget_control,state.line_base,xoffset=infoline.xoffset+deltaXleft
      widget_control,state.right_base,xoffset=inforight.xoffset+deltaXleft, $
                     xsize=((state.right_xsize+=deltaXright))

      child = widget_info(state.right_base,/child)
      evstruct = {CW_PANES_RESIZE, ID:child, TOP:event.top, $
                  HANDLER:child, deltaX:deltaXright, deltaY:deltaY}
      IF state.rightIsPro THEN call_procedure,state.rightevent,evstruct $
      ELSE void = call_function(state.rightevent,evstruct)

    END

    ELSE :

  ENDCASE

  widget_control,linebase,set_uvalue=state
  return,event

END

;----------------------------------------
;+
; NAME:
;	CW_PANES_KILL
;
; PURPOSE:
;       Cleanup
;
; INPUTS:
;       ID: (required) a widget ID
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_KILL, id
  compile_opt hidden,idl2

  widget_control,widget_info(id,find_by_uname='cw_panes_line'), $
                 get_uvalue=state
  objects = *state.objects
  FOR i=0,n_elements(objects)-1 DO $
    IF obj_valid(objects[i]) THEN obj_destroy,objects[i]
  ptr_free,state.objects
  if(ptr_valid(state.linepix))then $
    ptr_free, state.linepix
end

;----------------------------------------
;+
; NAME:
;	CW_PANES_DRAW_SLIDER_BAR
;
; PURPOSE:
;       Updates the display of the arrows or sliderbar
;
; INPUTS:
;       TLB: (required) the widget ID of the top level base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_DRAW_SLIDER_BAR, tlb
  compile_opt hidden,idl2
  
  widget_control,widget_info(tlb, $
                             find_by_uname='cw_panes_line'), $
                 get_uvalue=linestate
  CW_PANES_DISPLAY_SLIDER_BAR,linestate.line,*linestate.linepix, $
                              linestate.visible NE 3, $
                              linestate.clrs.face_3d

END 

;----------------------------------------
;+
; NAME:
;	CW_PANES_DISPLAY_SLIDER_BAR
;
; PURPOSE:
;       Updates the display of the arrows or sliderbar
;
; INPUTS:
;       WDRAW: (required) a widget ID
;
;       ARRAY: (required) a byte array containing the three different
;       views the slider bar can take
;
;       INDEX: (required) an integer specifying which view of the
;       slider bar to display.  0 - normal view (active, gray
;       background), 1 - inactive, 2 - highlighted
;
;       FACE: (required) an RGB triplet specifying the colour to be
;       used for the background gray colour of the bar
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_DISPLAY_SLIDER_BAR, wDraw, array, index, face
  compile_opt hidden,idl2

  widget_control,wDraw,get_value=wID
  tvlct,rr,gg,bb,/get
  device,get_decomposed=dec
  win = !d.window
  device,decomposed=0
  wset,wID
  tvlct,[0,face[0],0,face[0]*0.8,face[0],255], $
        [0,face[1],0,face[1]*0.8,face[1],255], $
        [0,face[2],0,face[2]*0.8,255,    255]
  tv,array[index*8:(index+1)*8-1,*]
  ysize = (widget_info(wDraw,/geometry)).ysize
  tv,bytarr(8)+1b,0,ysize-1
  tv,bytarr(8),0,ysize-2
  tv,bytarr(6)+5b,1,ysize-3
  tv,bytarr(8),0,0
  wset,win
  device,decomposed=dec
  tvlct,rr,gg,bb

END

;----------------------------------------
;+
; NAME:
;	CW_PANES_REALIZE_LINE
;
; PURPOSE:
;       Creates the slider bar
;
; INPUTS:
;       WDRAW: (required) a widget ID
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_REALIZE_LINE, wDraw
  compile_opt hidden,idl2

  widget_control,widget_info(wDraw,/parent),get_uvalue=state
  (*state.linepix)[16:23,*] = 4b
  (*state.linepix)[[0,7,8,15,16,23],*] = 0b
  (*state.linepix)[[1,9,17],*] = 5b
  (*state.linepix)[[3,11,19],3:*:3] = 5b
  (*state.linepix)[[4,20],2:*:3] = 2b
  device,/cursor_original

  CW_PANES_DISPLAY_SLIDER_BAR,wDraw,*state.linepix,0,state.clrs.face_3d

end

;----------------------------------------
;+
; NAME:
;	CW_PANES_GET
;
; PURPOSE:
;       Returns the value of the widget
;
; INPUTS:
;       ID: (required) the widget ID of the cw_panes base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       A long int vector:
;         [current visible state, left base widget ID, right base widget ID]
;-
function CW_PANES_GET, id
  compile_opt hidden,idl2

  widget_control,widget_info(id,find_by_uname='cw_panes_line'), $
                 get_uvalue=state
  return, [state.visible,state.left_base,state.right_base]

end

;----------------------------------------
;+
; NAME:
;	CW_PANES_SET
;
; PURPOSE:
;       Sets the value of the widget
;
; INPUTS:
;       ID: (required) the widget ID of the cw_panes base
;
;       ARRAY: (required) a scalar or 2 element vector of integers
;         Array[0] : visibility : 0=no change, 1=show only left pane,
;           2=show only right pane, 3=show both panes
;         Array[1] : position of slider in device units
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_PANES_SET, id, array
  compile_opt hidden, idl2

  SWITCH n_elements(array) OF
    2 : position = array[1]
    1 : BEGIN
      visible = array[0]
      BREAK
    END
    ELSE : BEGIN
      return
    ENDELSE
  ENDSWITCH

  top = id & WHILE ((temp=widget_info(top,/parent))) NE 0 DO top=temp

  widget_control,widget_info(id,find_by_uname='cw_panes_line'), $
                 get_uvalue=state
  infoleft = widget_info(state.left_base,/geometry)
  infoline = widget_info(state.line_base,/geometry)
  inforight = widget_info(state.right_base,/geometry)
  infotop = widget_info(id,/geometry)

  ;;if slider position is set, pass value to LINE_EVENT handling routine
  IF n_elements(position) NE 0 THEN BEGIN
    state.delta = position-infoline.xoffset
    widget_control,widget_info(id,find_by_uname='cw_panes_line'), $
                   set_uvalue=state
    CW_PANES_LINE_EVENT,{WIDGET_DRAW,ID:id,TOP:id,HANDLER:id,TYPE:1, $
                             X:0l,Y:0l,PRESS:0B,RELEASE:0B,CLICKS:0, $
                             MODIFIERS:0L,CH:0,KEY:0L}
  ENDIF

  IF visible NE 0 AND visible NE state.visible THEN BEGIN
    if (~state.allowCollapse) then $
        visible = 3
    CASE visible OF
      1 : BEGIN
        ;;desensitize arrow of collapsed panel and sensitize other
        widget_control,state.arrow1,sensitive=0
        widget_control,state.arrow2,sensitive=1, $
                       tooltip=IDLitLangCatQuery('UI:cwPanes:ShowRtPanel')
        CW_PANES_DISPLAY_SLIDER_BAR,state.line,*state.linepix,1, $
                                   state.clrs.face_3d

        IF state.visible EQ 3 THEN BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:-state.right_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          inforight = widget_info(state.right_base,/geometry)
          widget_control,state.right_base,map=0
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize-inforight.scr_xsize
          widget_control,state.right_base,xsize=1,ysize=1,xoffset=0
        ENDIF ELSE BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:state.left_xsize-state.right_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          inforight = widget_info(state.right_base,/geometry)
          widget_control,state.right_base,map=0
          widget_control,state.right_base,xsize=1,ysize=1,xoffset=0
          widget_control,state.left_base,xsize=state.left_xsize, $
                         ysize=state.left_ysize
          infoleft = widget_info(state.left_base,/geometry)
          widget_control,state.line_base,xoffset=infoleft.scr_xsize
          widget_control,state.left_base,map=1
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize+infoleft.scr_xsize- $
                         inforight.scr_xsize
        ENDELSE
        widget_control,state.arrow1,map=0
        widget_control,state.arrow1,map=1
        widget_control,state.arrow2,map=0
        widget_control,state.arrow2,map=1
      END
      2 : BEGIN
        widget_control,state.arrow1,sensitive=1, $
                       tooltip=IDLitLangCatQuery('UI:cwPanes:ShowLftPanel')
        widget_control,state.arrow2,sensitive=0
        CW_PANES_DISPLAY_SLIDER_BAR,state.line,*state.linepix,1, $
                                   state.clrs.face_3d

        widget_control,state.line_base,xoffset=0
        widget_control,state.right_base,xoffset=infoline.scr_xsize
        IF state.visible EQ 3 THEN BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:-state.left_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          infoleft = widget_info(state.left_base,/geometry)
          widget_control,state.left_base,map=0
          widget_control,state.left_base,xsize=1,ysize=1
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize-infoleft.scr_xsize
        ENDIF ELSE BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:state.right_xsize-state.left_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          widget_control,state.right_base,xsize=state.right_xsize, $
                         ysize=state.right_ysize
          widget_control,state.right_base,map=1
          inforight = widget_info(state.right_base,/geometry)
          infoleft = widget_info(state.left_base,/geometry)
          widget_control,state.left_base,map=0
          widget_control,state.left_base,xsize=1,ysize=1
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize-infoleft.scr_xsize+ $
                         inforight.scr_xsize
        ENDELSE
        widget_control,state.arrow1,map=0
        widget_control,state.arrow1,map=1
        widget_control,state.arrow2,map=0
        widget_control,state.arrow2,map=1
      END
      3 : BEGIN
        if (state.allowCollapse) then begin
          widget_control,state.arrow1,sensitive=1, $
                         tooltip=IDLitLangCatQuery('UI:cwPanes:HideLftPanel')
          widget_control,state.arrow2,sensitive=1, $
                         tooltip=IDLitLangCatQuery('UI:cwPanes:HideRtPanel')
        endif
        CW_PANES_DISPLAY_SLIDER_BAR,state.line,*state.linepix,0, $
                                   state.clrs.face_3d

        IF state.visible EQ 1 THEN BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:state.right_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          widget_control,state.right_base,xsize=state.right_xsize, $
                         ysize=state.right_ysize
          inforight = widget_info(state.right_base,/geometry)
          widget_control,state.right_base,xoffset=infoleft.scr_xsize+ $
                         infoline.scr_xsize
          widget_control,state.right_base,map=1
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize+inforight.scr_xsize
        ENDIF ELSE BEGIN
          evstruct = {CW_PANES_TOP_RESIZE, ID:top, TOP:top, $
                      HANDLER:top, $
                      deltaX:state.left_xsize, deltaY:0l}
          IF state.topIsPro THEN call_procedure,state.topevent,evstruct $
          ELSE void = call_function(state.topevent,evstruct)
          widget_control,state.left_base,xsize=state.left_xsize, $
                         ysize=state.left_ysize
          infoleft = widget_info(state.left_base,/geometry)
          widget_control,state.right_base,xoffset=infoleft.scr_xsize+ $
                         infoline.scr_xsize
          widget_control,state.left_base,map=1
          widget_control,state.line_base,xoffset=infoleft.scr_xsize
          widget_control,id,scr_xsize= $
                         infotop.scr_xsize+infoleft.scr_xsize
        ENDELSE
        if (state.allowCollapse) then begin
            widget_control,state.arrow1,map=0
            widget_control,state.arrow1,map=1
            widget_control,state.arrow2,map=0
            widget_control,state.arrow2,map=1
        endif
      END
      ELSE :
    ENDCASE
    state.visible = visible
  ENDIF

  widget_control,widget_info(id,find_by_uname='cw_panes_line'), $
                 set_uvalue=state

END

;----------------------------------------
;+
;See top of file for documention on main routine
;-
function CW_PANES, parent, LEFT_CREATE_PRO=left_createpro, $
                   RIGHT_CREATE_PRO=right_createpro, $
                   LEFT_EVENT_PRO=leftEventPro, $
                   LEFT_EVENT_FUNC=leftEventFunc, $
                   RIGHT_EVENT_PRO=rightEventPro, $
                   RIGHT_EVENT_FUNC=rightEventFunc, $
                   TOP_EVENT_PRO=topEventPro, $
                   TOP_EVENT_FUNC=topEventFunc, $
                   LEFT_XSIZE=left_xsize,LEFT_YSIZE=left_ysize, $
                   RIGHT_XSIZE=right_xsize,RIGHT_YSIZE=right_ysize, $
                   VERTICAL=vertical,VISIBLE=visible,MARGIN=margin, $
                   UVALUE=uvalue,UNAME=uname, $
                   GROUP_LEADER=groupLeader, $
                   NO_COLLAPSE=noCollapse, $
                   _REF_EXTRA=_extra

  compile_opt hidden,idl2

  IF (n_elements(parent) NE 1) || $
    (size(parent,/type) NE 3) || $
    ~widget_info(parent,/valid_id) THEN return, 0l

  IF ~((((leftIsPro=size(leftEventPro,/type))) EQ 7) XOR $
       (size(leftEventFunc,/type) EQ 7)) || $
    ~((((rightIsPro=size(rightEventPro,/type))) EQ 7) XOR $
      (size(rightEventFunc,/type) EQ 7)) || $
    ~((((topIsPro=size(topEventPro,/type))) EQ 7) XOR $
      (size(topEventFunc,/type) EQ 7)) THEN return, 0l

  if (not keyword_set(uname)) then uname = 'CW_PANES_UNAME'
  IF (NOT keyword_set(uvalue)) THEN uvalue = 0

  IF n_elements(left_xsize) EQ 0 THEN left_xsize = 200
  IF n_elements(left_ysize) EQ 0 THEN left_ysize = 200
  IF n_elements(right_xsize) EQ 0 THEN right_xsize = 200
  IF n_elements(right_ysize) EQ 0 THEN right_ysize = 200
  allowCollapse = ~KEYWORD_SET(noCollapse)

  ;; because of a quirk in the resizing of modal widgets, and the
  ;; resulting geometry returned for said widget, do not allow modal
  ;; widgets to have the option of collapsing one or the other of the
  ;; panes.
  IF widget_info(parent,/modal) THEN allowCollapse = 0

  if ~allowCollapse || (n_elements(visible) eq 0) then $
    visible = 3
  if n_elements(margin) eq 0 then margin = 15
  vertical = 0;keyword_set(vertical)   not yet implemented

  hasLeader = (N_ELEMENTS(groupLeader) gt 0) ? $
    WIDGET_INFO(groupLeader, /VALID) : 0

  state = {CW_PANES_STATE, $
           wBase:0l,left_base:0l,right_base:0l,line_base:0l,moveline1:0l, $
           moveline2:0l,parent:0l,arrow1:0l,arrow2:0l,line:0l, $
           linepix:ptr_new(bytarr(24,(get_screen_size())[1])+1b), $
           delta:0l,curpos:0,down:0,vertical:0,visible:0,margin:margin, $
           objects:ptr_new(objarr(1)), $
           leftevent:leftIsPro ? leftEventPro[0] : leftEventFunc[0], $
           leftIsPro:leftIsPro, $
           rightevent:rightIsPro ? rightEventPro[0] : rightEventFunc[0], $
           rightIsPro:rightIsPro, $
           topevent:topIsPro ? topEventPro[0] : topEventFunc[0], $
           topIsPro:topIsPro, $
           clrs:widget_info(widget_base(),/system_colors), $
           draw1:0l,draw2:0l,left_xsize:left_xsize,left_ysize:left_ysize, $
           right_xsize:right_xsize,right_ysize:right_ysize, $
           allowCollapse: allowCollapse}
  state.vertical = vertical
  state.visible = 3

  dwindow = !d.window

  tlb = widget_base(parent,$
                    FUNC_GET_VALUE='CW_PANES_GET', $
                    PRO_SET_VALUE='CW_PANES_SET', $
                    UVALUE=uvalue, $
                    UNAME='CW_PANES', $
                    EVENT_FUNC='CW_PANES_EVENT',MAP=0, $
                    _STRICT_EXTRA=_extra)

  state.parent = parent
  state.wBase = tlb

  widget_control,tlb,/realize

  state.left_base = widget_base(tlb,xsize=left_xsize,ysize=left_ysize, $
                                xpad=2,ypad=2)
  info = widget_info(state.left_base,/geometry)
  widget_control,state.left_base,/destroy
  offset = info.(0+vertical)+info.(4+vertical)+info.(8)+ $
    info.(9+vertical)+info.(11)

  ;;create moving slider bar #1
  lineoffset = offset
  state.moveline1 = widget_base(tlb,xoffset=0,xpad=2,ypad=2,map=0)
  state.draw1=widget_draw(state.moveline1,xsize=2,ysize=left_ysize>right_ysize)

  ;;create base for holding slider bar and arrows
  state.line_base = widget_base(tlb,frame=0,xoffset=offset,xpad=0, $
                                ypad=0,space=0,/toolbar, $
                                ysize=left_ysize>right_ysize, $
                                uname='cw_panes_line',/column)
  widget_control,state.line_base,set_uvalue=state

  if allowCollapse then begin
    ;;create left arrow button
    bmRight = FILEPATH("spinright.bmp", SUBDIR=['resource','bitmaps'])
    bmLeft = FILEPATH("spinleft.bmp", SUBDIR=['resource','bitmaps'])

    state.arrow1 = widget_button(state.line_base,xsize=10, $
                               ysize=14, /FLAT, $
                               value=bmLeft, /BITMAP, $
                               event_PRO='CW_PANES_LEFT_BUTTON')
    ;;create right arrow button
    state.arrow2 = widget_button(state.line_base,xsize=10, $
                               ysize=14, /FLAT, $
                               value=bmRight, /BITMAP, $
                               event_PRO='CW_PANES_RIGHT_BUTTON')
  endif

  ;;create slider bar
  ysize = left_ysize > right_ysize
  if allowCollapse then $
    ysize -= 28

  state.line = widget_draw(state.line_base,xsize=8, $
                           ysize=ysize, $
                           graphics_level=0, $
                           event_pro='CW_PANES_LINE_EVENT', $
                           /expose_events,/tracking_events, $
                           NOTIFY_REALIZE='CW_PANES_REALIZE_LINE', $
                           /motion_events,retain=0,/button_events)

  ;;create left base
  state.left_base = widget_base(tlb,xsize=left_xsize,ysize=left_ysize, $
                                xpad=2,ypad=2, $
                                event_func='CW_PANES_NULL_EVENT')

  ;;create right base with proper offset
  info = widget_info(state.line_base,/geometry)
  offset = info.(0+vertical)+info.(4+vertical)+info.(8)+ $
    info.(9+vertical)+info.(11)
  state.right_base = widget_base(tlb,xsize=right_xsize,ysize=right_ysize, $
                                 xoffset=offset,xpad=2,ypad=2, $
                                 event_func='CW_PANES_NULL_EVENT')

  ;;create moving slider bar #1
  state.moveline2 = widget_base(tlb,xoffset=0,xpad=2,ypad=2,map=0)
  state.draw2=widget_draw(state.moveline2,xsize=2,ysize=left_ysize>right_ysize)

  ;;hash moving slider bar
  cw_panes_dashed_bar,state.draw1,state.draw2,left_ysize>right_ysize

  ;;call procedure to populate the left panel
  call_procedure,left_createpro,state.left_base
  ;;call procedure to populate the right panel
  call_procedure,right_createpro,state.right_base

  widget_control,state.line_base,kill_notify='CW_PANES_KILL'
  widget_control,state.line_base,set_uvalue=state
  widget_control,tlb,set_value=visible
  widget_control,tlb,map=1
  ;;register the direct graphics windows so that we can properly reset
  ;;the current window
  xmanager,'cw_panes',state.draw1,/just_reg
  xmanager,'cw_panes',state.draw2,/just_reg
  xmanager,'cw_panes',state.line,/just_reg
  widget_control,state.line,event_PRO='CW_PANES_LINE_EVENT'
  wset,dwindow

  return, tlb

END
