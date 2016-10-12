; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdtool.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdTool
;
; PURPOSE:
;   Create the IDL UI (widget) interface for an associated tool object.
;
; CALLING SEQUENCE:
;   IDLitwdTool, Tool
;
; INPUTS:
;   Tool - Object reference to the tool object.
;
;-


;;-------------------------------------------------------------------------
;; IDLitwdTool_callback
;;
;; Purpose:
;;   Callback routine for the tool interface widget, allowing it to
;;   receive update messages from the system.
;;
;; Parameters:
;;   wBase     - Base id of this widget
;;
;;   strID     - ID of the message.
;;
;;   MessageIn - What is the message
;;
;;   userdata  - Data associated with the message
;
pro IDLitwdTool_callback, wBase, strID, messageIn, userdata
    compile_opt idl2, hidden

    if (~WIDGET_INFO(wBase, /VALID)) then $
        return

    ;; Grab the state of the widget
    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), GET_UVALUE=pState

    case STRUPCASE(messageIn) of

    ; Check the file name changes to display
    'FILENAME': begin
        ; Use the new filename to construct the title.
        ; Remove the path.
        filename = STRSPLIT(userdata, '/\', /EXTRACT)
        filename = filename[N_ELEMENTS(filename)-1]
        ; Append the filename onto the base title.
        newTitle = (*pState).title + ' [' + filename + ']'
        WIDGET_CONTROL, wBase, TLB_SET_TITLE=newTitle
    end

    ; A panel was added to the tool. See if our size changed.
    'ADDUIPANELS': begin
        IDLitwdTool_resize, pState, 0, 0
        end

    ; The show/hide was changed. See if our size changed.
    'SHOWUIPANELS': begin
        IDLitwdTool_resize, pState, 0, 0
        end

    ;; Virtual dims changed
    'VIRTUAL_DIMENSIONS': begin
        ; Retrieve the original geometry (prior to the resize).
        WIDGET_CONTROL, wBase, TLB_GET_SIZE=basesize
        geom = WIDGET_INFO((*pState).wDraw, /GEOMETRY)

        ; See if the window shrank.
        dx = (userdata[0] - geom.xsize) < 0
        dy = (userdata[1] - geom.ysize) < 0

        ; No shrinkage.
        if ((dx eq 0) && (dy eq 0)) then $
            break

        IDLitwdTool_resize, pState, dx, dy
        end

    ; The sensitivity is to be changed
    'SENSITIVE': begin
        WIDGET_CONTROL, wBase, SENSITIVE=userdata
    end

    ;; Canvas zoom might have added/removed scroll bars changing the
    ;; size of the top-level base
    'CANVAS_ZOOM' : begin
      ;; Reset the draw window to previous size to eliminate any
      ;; resizing due to adding/removing scroll bars
      Cw_Itwindow_Resize, (*pState).wDraw, ((*pState).drawSize)[0], $
                          ((*pState).drawSize)[1]

      ;; Retrieve and store the new top-level base size.
      if (WIDGET_INFO((*pState).wBase, /REALIZED)) then begin
        WIDGET_CONTROL, (*pState).wBase, TLB_GET_SIZE=basesize
        (*pState).basesize = basesize
      endif

    end

    else:  ; do nothing

    endcase

end


;;-------------------------------------------------------------------------
;; IDLitwdTool_resize
;;
;; Purpose:
;;    Called when the user has resize the TLB of this tool interface.
;;    Will recalculate the size of the major elements in the
;;    interface.
;;
;; Parameters:
;;   pState   - pointer to the state struct for this widget.
;;
;;   deltaW   - The change in the width of the interface.
;;
;;   deltaH   - The change in the height of the interface.
;
pro IDLitwdTool_resize, pState, deltaW, deltaH

    compile_opt idl2, hidden

    ; Retrieve the original geometry (prior to the resize)
    ; of the draw widget.
    drawgeom = WIDGET_INFO((*pState).wDraw, /GEOMETRY)

    ; Compute the updated dimensions of the visible portion
    ; of the draw widget.
    newVisW = (drawgeom.scr_xsize + deltaW) > (*pState).minsize[0]
    newVisH = (drawgeom.scr_ysize + deltaH) > (*pState).minsize[1]

    isUpdate = WIDGET_INFO((*pState).wBase, /UPDATE)

    ; If update turned off on unix, draw window won't resize properly.
    ; So just turn off update on Windows.
    if (!version.os_family eq 'Windows') then begin
        if (isUpdate) then $
            widget_control, (*pState).wBase, UPDATE=0
    endif else begin
        ; On Unix make sure update is on.
        if (~isUpdate) then $
            widget_control, (*pState).wBase, /UPDATE
    endelse

    ; Resize the panel retrieve the size.
    cw_itpanel_resize, (*pState).wPanel, newVisH
    panelgeom = widget_info((*pState).wPanel, /geometry)

    ; Update the statusbar to be the same width as the draw + panel.
    cw_itStatusBar_Resize, (*pState).wStatus, newVisW + panelgeom.xsize

    ; Update the toolbar row to be the same width as the draw.
    WIDGET_CONTROL, (*pState).wToolbar, SCR_XSIZE=newVisW

    ; Update the draw widget dimensions and scrollbars.
    if (newVisW ne drawgeom.xsize || newVisH ne drawgeom.ysize) then begin
        CW_ITWINDOW_resize, (*pState).wDraw, newVisW, newVisH
    endif


    if (isUpdate && ~WIDGET_INFO((*pState).wBase, /UPDATE)) then $
        widget_control, (*pState).wBase, /UPDATE


    ; Retrieve and store draw widget size.
    drawgeom = WIDGET_INFO((*pState).wDraw, /GEOMETRY)
    (*pState).drawSize = [drawgeom.scr_xsize, drawgeom.scr_ysize]

    ; Retrieve and store the new top-level base size.
    if (WIDGET_INFO((*pState).wBase, /REALIZED)) then begin
        WIDGET_CONTROL, (*pState).wBase, TLB_GET_SIZE=basesize
        (*pState).basesize = basesize
    endif
end


;;-------------------------------------------------------------------------
;; IDLitwdtool__cleanup
;;
;; Purpose:
;;   Called when the widget is dying, allowing the state ptr to be
;;   released.
;;
;; Parameters:
;;    wChild   - The id of the widget that contains this widgets
;;               state.
;;
pro IDLitwdTool_cleanup, wChild

    compile_opt hidden, idl2

    if (~WIDGET_INFO(wChild, /VALID)) then $
        return

    WIDGET_CONTROL, wChild, GET_UVALUE=pState

    if (PTR_VALID(pState)) then begin
      ; If we haven't seen a kill request then we have been killed
      ; via widget_control,/reset. In this case we are responsible
      ; for shutting down the tool. Also, at this point the widget
      ; is dead, so we do *not* want to do the Save prompt.
      if (~(*pState).bKillRequestSeen) then begin
        oTool = (*pState).oTool
        if (OBJ_VALID(oTool)) then begin
          oTool->SetProperty, /NO_SAVEPROMPT
          void = oTool->DoAction("/SERVICES/SHUTDOWN")
        endif
      endif

      if (PTR_VALID(pState)) then PTR_FREE, pState
    endif
end


;;-------------------------------------------------------------------------
;; IDLitwdTool_Event
;;
;; Purpose:
;;    Event handler for the tool interface IDL widget.
;;
;; Parameters:
;;    event    - The widget event to process.
;;
pro IDLitwdTool_event, event
    compile_opt idl2, hidden

@idlit_on_error2

    ;; Get our state
    wChild = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=pState

    case TAG_NAMES(event, /STRUCTURE_NAME) of

    ;; Kill the widget?
    'WIDGET_KILL_REQUEST': begin
        ; Let the tool know that shutdown was requested.
        ; This code must be here, and not in the _cleanup, because
        ; the tool may not actually be killed, say if the user is
        ; asked if they want to "save", and they hit "Cancel" instead.
        oTool = (*pState).oTool

        ; If we have been killed using widget_control,/reset then we won't
        ; come thru here, and will go directly to IDLitwdTool_cleanup.
        ; Set a flag to indicate that we are doing a "normal" shutdown.
        (*pState).bKillRequestSeen = 1b

        ; This will trigger a call to IDLitwdTool_cleanup.
        void = oTool->DoAction("/SERVICES/SHUTDOWN")

        ; pState will usually be dead at this point, unless the user
        ; has hit "Cancel" on the Save dialog and the tool is still alive.
        ; In that case, just reset our flag.
        if (PTR_VALID(pState)) then (*pState).bKillRequestSeen = 0b
    end

    ;; Focus change
    'WIDGET_KBRD_FOCUS': begin
        if (obj_valid((*pState).oUI) && event.enter) then begin
            oTool = (*pState).oTool
            oCurrent = oTool->GetService("SET_AS_CURRENT_TOOL")
            void = oTool->DoAction(oCurrent->GetFullIdentifier())
            ;; DONT DO THIS our tools could enter a focus loop in the
            ;; following situation:
            ;;    IDL> Iplot & iPlot
            ;; widget_control, (*pState).wDraw, /input_Focus
        endif
    end

    ;; The TLB was resized
    'WIDGET_BASE': begin
        ; Compute the size change of the base relative to
        ; its stored former size.
        WIDGET_CONTROL, event.top, TLB_GET_SIZE=newSize
        deltaW = newSize[0] - (*pState).basesize[0]
        deltaH = newSize[1] - (*pState).basesize[1]
        ; Bail if no change.
        if (deltaW eq 0 && deltaH eq 0) then $
            break
        IDLitwdTool_resize, pState, deltaW, deltaH
        end

    else: ; do nothing

    endcase

end


;;-------------------------------------------------------------------------
;; IDLitwdTool
;;
;; Purpose:
;;    This is the main entry point for the iTools common IDL Widget
;;    user interface. This is passed a tool and the routine will then
;;    build a UI that contains the contents of the tool object.
;;
;; Parameters:
;;   oTool    - The tool object to use.
;;
;; Keywords:
;;    TITLE          - The title for the tool. If not provided, IDL
;;                     iTool is used.
;;
;;    LOCATION       - Where to place the new widget. X,Y
;;
;;    DIMENSIONS     - The size of the drawable.
;;
;;    VIRTUAL_DIMENSIONS - The virtual size of the drawing area
;;
;;    USER_INTERFACE - If set to an IDL variable, will return the user
;;                     interface object built during this UI
;;                     construction.
;
pro IDLitwdTool, oTool, TITLE=titleIn, $
                 LOCATION=location, $
                 DIMENSIONS=dimensionsIn, $
                 VIRTUAL_DIMENSIONS=virtualDimensions, $
                 XSIZE=swallow1, $  ; should use DIMENSIONS
                 YSIZE=swallow2, $  ; should use DIMENSIONS
                 USER_INTERFACE=oUI, $  ; output keyword
                 _REF_EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    if (~OBJ_VALID(oTool)) then $
        MESSAGE, IDLitLangCatQuery('UI:InvalidTool')

    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
      IDLitLangCatQuery('UI:wdTool:Title')

    WIDGET_CONTROL, /HOURGLASS

    ;*** Base to hold everything
    ;
    wBase = WIDGET_BASE(/COLUMN, MBAR=wMenubar, $
                        TITLE=title, $
                        /TLB_KILL_REQUEST_EVENTS, $
                        /TLB_SIZE_EVENTS, $
                        /KBRD_FOCUS_EVENTS, $
                        _EXTRA=_extra)

    ;*** Create a new UI tool object, using our iTool.
    ;
    oUI = OBJ_NEW('IDLitUI', oTool, GROUP_LEADER=wBase)


    ;***  Menubars
    ;
    wFile       = CW_ITMENU(wMenubar, oUI, 'Operations/File')
    wInsert     = CW_ITMENU(wMenubar, oUI, 'Operations/Edit')
    wInsert     = CW_ITMENU(wMenubar, oUI, 'Operations/Insert')
    wOperations = CW_ITMENU(wMenubar, oUI, 'Operations/Operations')
    wWindow     = CW_ITMENU(wMenubar, oUI, 'Operations/Window')
    wHelp       = CW_ITMENU(wMenubar, oUI, 'Operations/Help')

    ;***  Drawing area.
    ;
    screen = GET_SCREEN_SIZE(RESOLUTION=cm_per_pixel)
    hasDimensions = (N_ELEMENTS(dimensionsIn) eq 2)
    if (~hasDimensions)then begin
        ;; Some multi monitor deployments will report a screen size
        ;; that includes all monitors, which can lead to some
        ;; interesting screen geometry. To take this into account, the
        ;; following logic is used to determine the default tool size.
        ;;  - Find the minimum dimension
        ;;  - minDim = dim/2
        ;;  - The other maxDim = minDim * 1.4
        ;;
        ;; The only possible issue with this logic would be if the
        ;; logical screen is so large that this calculation will
        ;; result in a window exceeding a screen.
        dimensions = 0.5*screen
        if(screen[0] gt screen[1])then $ ;; x larger than Y
          dimensions[0] = dimensions[1] * 1.4 $
        else $
          dimensions[1] = dimensions[0] * 1.4
    endif else $
        dimensions = dimensionsIn

    ; Make sure our dimensions are larger than the menubar.
    ; Otherwise strange things happen on Windows.
    ; We do this regardless of whether the user provided
    ; their own dimensions.
    geom = WIDGET_INFO(wMenubar, /GEOMETRY)
    minsize = [geom.scr_xsize + 10, 100]

    dimensions >= minsize


    ;***  Toolbars
    ;
    wToolbar = WIDGET_BASE(wBase, /ROW, XPAD=0, YPAD=0, SPACE=7)
    wTool1 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/File')
    wTool2 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/Edit')
    wTool3 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators', /EXCLUSIVE)
    wTool4 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators/View', /EXCLUSIVE)
    wTool5 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/View')
    wTool6 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators/Annotation', /EXCLUSIVE)


    ; It may happen that our toolbar is just slightly larger than
    ; the specified dimensions. In this case, adjust the dimensions
    ; to fit the toolbar (unless the user has provided their
    ; own dimensions).
    if (~hasDimensions) then begin
        geom = WIDGET_INFO(wToolbar, /GEOMETRY)
        if ((geom.xsize gt dimensions[0]) && $
            (geom.xsize lt (dimensions[0] + 40))) then $
        dimensions[0] = geom.xsize
    endif

    ; Always adjust the toolbar to fit the base width.
    if (dimensions[0] lt geom.xsize) then $
        WIDGET_CONTROL, wToolbar, SCR_XSIZE=dimensions[0]

    ;***  Panel and Drawing area
    wRow = widget_base(wBase, /ROW, $
                         xpad=0, ypad=0, space=0)

    wBaseDraw = widget_base(wRow, xpad=0, ypad=0, space=0)
    wBasePanel  = widget_base(wRow, xpad=0, ypad=0, space=0)

    wPanel = CW_ITPANEL(wBasePanel, oUI)

    ; If the user did not explicitly provide dimensions, and
    ; the panel height is greater than the default (half-screen)
    ; height, but less than half again the default height, then
    ; adjust our default height to match the panel height (so
    ; scrollbars will not be necessary).
    if (~hasDimensions) then begin
        geom = WIDGET_INFO(wPanel, /GEOMETRY)
        if ((geom.scr_ysize gt dimensions[1]) && $
            (geom.scr_ysize lt (dimensions[1]*1.5))) then begin
            dimensions[1] = geom.scr_ysize
        endif
    endif

    ;; Make our window
    if (hasDimensions && N_ELEMENTS(virtualDimensions) eq 0) then $
        virtualDimensions = dimensions

    wDraw = CW_ITWINDOW(wBaseDraw, oUI, $
                        DIMENSIONS=dimensions, $
                        VIRTUAL_DIMENSIONS=virtualDimensions, $
                        _EXTRA=['RENDERER'])

    ;*** Status bar.
    ;
    wStatus = CW_itStatusBar(wBase, oUI, XSIZE=dimensions[0])

    ; Cache some information.
    ;
    wChild = WIDGET_INFO(wBase, /CHILD)

    if(n_elements(location) eq 0)then begin
        location = [(screen[0] - dimensions[0])/2 - 10, $
                    ((screen[1] - dimensions[1])/2 - 100) > 10]
    endif
    WIDGET_CONTROL, wBase, MAP=0, $
        TLB_SET_XOFFSET=location[0], TLB_SET_YOFFSET=location[1]

    ;; State structure for the widget
    State = { $
              oTool     : oTool,    $
              oUI       : oUI,      $
              wBase      : wBase,    $
              title     : title,    $
              minsize   : minsize,  $
              basesize  : [0L, 0L], $
              wToolbar  : wToolbar, $
              wDraw     : wDraw,    $
              drawSize  : dimensions, $
              wPanel    : wPanel,   $
              wStatus   : wStatus,   $
              bKillRequestSeen: 0b   }
    pState = PTR_NEW(state, /NO_COPY)
    WIDGET_CONTROL, wChild, SET_UVALUE=pState

    ; Force an initial resize.
    IDLitwdTool_resize, pState, 0, 0

    WIDGET_CONTROL, wBase, /REALIZE

    ; Retrieve the starting dimensions and store them.
    ; Used for window resizing in event processing.
    WIDGET_CONTROL, wBase, TLB_GET_SIZE=basesize
    (*pState).basesize = basesize

    ;; Register ourself as a widget with the UI object.
    ;; Returns a string containing our identifier.
    myID = oUI->RegisterWidget(wBase, 'ToolBase', 'idlitwdtool_callback')

    ;; Register for our messages.
    oUI->AddOnNotifyObserver, myID, oTool->GetFullIdentifier()
    oSys = oTool->_GetSystem()
    ; Observe the system so that we can be desensitized when a macro is running
    oUI->AddOnNotifyObserver, myID, oSys->GetFullIdentifier()

    WIDGET_CONTROL, wChild, KILL_NOTIFY="idlitwdTool_cleanup"
    WIDGET_CONTROL, wBase, /MAP ;show the user what we have made.

    ; Start event processing for the tool.
    XMANAGER, 'IDLitwdTool', wBase, /NO_BLOCK

end

