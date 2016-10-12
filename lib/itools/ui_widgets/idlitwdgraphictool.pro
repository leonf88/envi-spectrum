; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdgraphictool.pro#4 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdGraphicTool
;
; PURPOSE:
;   Create the IDL UI (widget) interface for an associated tool object.
;
; CALLING SEQUENCE:
;   IDLitwdGraphicTool, Tool
;
; INPUTS:
;   Tool - Object reference to the tool object.
;
;-


;;-------------------------------------------------------------------------
;; IDLitwdGraphicTool_callback
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
pro IDLitwdGraphicTool_callback, wBase, strID, messageIn, userdata
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

    ;; Virtual dims changed
    'VIRTUAL_DIMENSIONS': begin
        WIDGET_CONTROL, (*pState).wDraw, $
          DRAW_XSIZE=userdata[0], DRAW_YSIZE=userdata[1], $
          SCR_XSIZE=userdata[0], SCR_YSIZE=userdata[1]
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
;      Cw_Itwindow_Resize, (*pState).wDraw, ((*pState).drawSize)[0], $
;                          ((*pState).drawSize)[1]

      ;; Retrieve and store the new top-level base size.
;      if (WIDGET_INFO((*pState).wBase, /REALIZED)) then begin
;        WIDGET_CONTROL, (*pState).wBase, TLB_GET_SIZE=basesize
;        (*pState).basesize = basesize
;      endif

    end

    else:  ; do nothing

    endcase

end


;;-------------------------------------------------------------------------
;; IDLitwdGraphicTool__cleanup
;;
;; Purpose:
;;   Called when the widget is dying, allowing the state ptr to be
;;   released.
;;
;; Parameters:
;;    wChild   - The id of the widget that contains this widgets
;;               state.
;;
pro IDLitwdGraphicTool_cleanup, wChild

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
;; IDLitwdGraphicTool_Event
;;
;; Purpose:
;;    Event handler for the tool interface IDL widget.
;;
;; Parameters:
;;    event    - The widget event to process.
;;
pro IDLitwdGraphicTool_event, event
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
        ; come thru here, and will go directly to IDLitwdGraphicTool_cleanup.
        ; Set a flag to indicate that we are doing a "normal" shutdown.
        (*pState).bKillRequestSeen = 1b

        ; This will trigger a call to IDLitwdGraphicTool_cleanup.
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
        WIDGET_CONTROL, event.id, TLB_GET_SIZE=newSize
        ; Change the draw widget to match the new size, minus padding.
        xy = newSize - (*pState).padding
        xy[0] >= (*pState).minsize
        WIDGET_CONTROL, (*pState).wDraw, $
          DRAW_XSIZE=xy[0], DRAW_YSIZE=xy[1], $
          SCR_XSIZE=xy[0], SCR_YSIZE=xy[1]
        end

    else: ; do nothing

    endcase

end


;;-------------------------------------------------------------------------
;; IDLitwdGraphicTool
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
pro IDLitwdGraphicTool, oTool, TITLE=titleIn, $
                 LOCATION=location, $
                 DIMENSIONS=dimensionsIn, $
                 NO_MENUBAR=noMenuBar, $
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
    noMenuBar = 1
    wBase = WIDGET_BASE(/COLUMN, $
                        TITLE=title, $
                        /TLB_KILL_REQUEST_EVENTS, $
                        /TLB_SIZE_EVENTS, $
                        /KBRD_FOCUS_EVENTS, $
                        _EXTRA=_extra)
    wMenubar = 0L

    ;*** Create a new UI tool object, using our iTool.
    ;
    oUI = OBJ_NEW('GraphicsUI', oTool, GROUP_LEADER=wBase)

    ;***  Drawing area.
    ;
    screen = GET_SCREEN_SIZE(RESOLUTION=cm_per_pixel)
    hasDimensions = (N_ELEMENTS(dimensionsIn) eq 2)
    dimensions = hasDimensions ? dimensionsIn : [640, 512]

    ; Be sure to pass in our UI object so the widget_window
    ; doesn't create its own tool & UI.
    wDraw = WIDGET_WINDOW(wBase, UI=oUI, $
      XSIZE=dimensions[0], YSIZE=dimensions[1], $
      _EXTRA=['RENDERER'])
    
    ;***  Toolbars
    ;
    wToolbar = WIDGET_BASE(wBase, /ROW, XPAD=0, YPAD=0, SPACE=7)
     wTool1 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/File')
      wTool2 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/Edit')
;      wTool5 = CW_ITTOOLBAR(wToolbar, oUI, 'Toolbar/View')
;      wTool4 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators/View', /EXCLUSIVE)
;      wTool3 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators', /EXCLUSIVE)
     wTool6 = CW_ITTOOLBAR(wToolbar, oUI, 'Manipulators/Annotation', /EXCLUSIVE)

    ; Just hardcode the toolbar size.
    minsize = 480

    dimensions >= minsize


    oTool = oUI->GetTool()
    wStatusSegment = oTool->GetStatusBarSegments(IDENTIFIER = 'PROBE')
    wStatusSegment->GetProperty, NORMALIZED_WIDTH=normalized_width
    segId = wStatusSegment->GetFullIdentifier()
    wStatusBase = WIDGET_BASE(wBase, /ROW)
    wStatus = WIDGET_LABEL(wStatusBase, VALUE=' ', UNAME=segId, /DYNAMIC_RESIZE)
  
    resolve_routine, 'cw_itstatusbar', /no_recompile, /is_function
  
    ; Register for notification messages.
    idUIadaptor = oUI->RegisterToolBar(wStatus, segId, $
       'cw_itstatusbar_callback')
    oUI->AddOnNotifyObserver, idUIadaptor, segId
      
    
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
              padding   : [0L, 0L], $
              wToolbar  : wToolbar, $
              wDraw     : wDraw,    $
              drawSize  : dimensions, $
              wStatus   : wStatus,   $
              bKillRequestSeen: 0b   }
    pState = PTR_NEW(state, /NO_COPY)
    WIDGET_CONTROL, wChild, SET_UVALUE=pState

    WIDGET_CONTROL, wBase, /REALIZE

    WIDGET_CONTROL, wDraw, GET_VALUE=oWindow
    oTool->_SetCurrentWindow, oWindow
    
    ; Start out with a 1x1 gridded layout.
    oWindow->SetProperty, LAYOUT_INDEX=1
  
    ; Set initial canvas zoom to 100% so our checked menus get updated.
    oWindow->SetProperty, CURRENT_ZOOM=1

    ; Retrieve the starting dimensions and store them.
    ; Used for window resizing in event processing.
    WIDGET_CONTROL, wBase, TLB_GET_SIZE=basesize
    (*pState).padding = basesize - dimensions

    ;; Register ourself as a widget with the UI object.
    ;; Returns a string containing our identifier.
    myID = oUI->RegisterWidget(wBase, 'ToolBase', 'IDLitwdGraphicTool_callback')

    ;; Register for our messages.
    oUI->AddOnNotifyObserver, myID, oTool->GetFullIdentifier()
    oSys = oTool->_GetSystem()
    ; Observe the system so that we can be desensitized when a macro is running
    oUI->AddOnNotifyObserver, myID, oSys->GetFullIdentifier()

    WIDGET_CONTROL, wChild, KILL_NOTIFY="IDLitwdGraphicTool_cleanup"
    WIDGET_CONTROL, wBase, /MAP ;show the user what we have made.

    ; Start event processing for the tool.
    XMANAGER, 'IDLitwdGraphicTool', wBase, /NO_BLOCK

end

