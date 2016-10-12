; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphic.pro#2 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; :Description:
;   Generic function for creating an IDL graphic.
;   
; :Author: sbolin
;-

      
;+
; :Description:
;   Local utility function used to build up an XML DOM
;   with children.
;
; :Params:
;    oDoc          : XML Document Object
;    oParent       : Dom element to append to.
;    elementName   : Name of the XML Element to create
;    data          : data for the element
;
;-
PRO Graphic_AppendChild, oDoc, oParent, elementName, data

  compile_opt idl2, hidden

  oElem = oDoc->CreateElement(elementName)
  oVoid = oParent->AppendChild(oElem)
  oText = oDoc->CreateTextNode(data)
  oVoid = oElem->AppendChild(oText)


END

;+
; :Description:
;    Create an idl graphic, return a handle to the graphic object.
;
; :Params:
;    toolName   : (Contour,Image,Map,Plot,Surface,Vector,Volume)
;    arg1       : optional generic argument
;    arg2       : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
pro Graphic, graphicName, arg1, arg2, arg3, arg4, $
  BUFFER=buffer, $
  CURRENT=currentIn, $
  DEBUG=debug, $
  DIMENSIONS=dimensions, $
  GRAPHIC=graphic, $
  LAYOUT=layoutIn, $
  LOCATION=location, $
  MARGIN=marginIn, $
  OVERPLOT=overplotIn, $
  TEST=test, $
  WINDOW_TITLE=winTitle, $
  WIDGETS=widgets, $  ; undocumented - use IDL widgets for the window
  _REF_EXTRA=ex

  compile_opt idl2, hidden
  
@graphic_error
  
  toolName = 'Graphic'
  
  ; Ensure that all class definitions are available.
  Graphic__define

;  if (N_PARAMS() eq 1) then begin
;    if (~KEYWORD_SET(test)) then $
;      MESSAGE, /NONAME, STRUPCASE(toolName) + ': Incorrect number of arguments.'
;  endif

  nparams = N_PARAMS() > 1

  ; If we have a graphic, then create a tool of that type,
  ; otherwise just use iPlot to create a generic empty tool.
  procName = ISA(graphicName) ? 'i'+graphicName : 'iPlot'
  title = ISA(winTitle,'STRING') ? winTitle : $
    (ISA(graphicName) ? graphicName : 'Graphic')

  ; Check for overplot situation
  toolID = iGetCurrent()
  current = KEYWORD_SET(currentIn) && (toolID ne '')
  overplot = KEYWORD_SET(overplotIn) && (toolID ne '') ? overplotIn : 0b

  createCanvas = ~current && ~KEYWORD_SET(overplot) && $
    ~KEYWORD_SET(buffer) && ~KEYWORD_SET(widgets)

  dimStr = '0,0'
  if (ISA(dimensions)) then begin
    if (N_ELEMENTS(dimensions) ne 2) then $
      MESSAGE, 'DIMENSIONS must have 2 elements.'
    dimStr = STRING(dimensions, FORMAT='(I0,",",I0)')
  endif
  if (ISA(location)) then begin
    if (N_ELEMENTS(location) ne 2) then $
      MESSAGE, 'LOCATION must have 2 elements.'
    dimStr += STRING(location, FORMAT='(",",I0,",",I0)')
  endif else begin
    dimStr += ',-1,-1'
  endelse

  ; Now, request the workbench to create a canvas for us to
  ; render into.  If a workbench is not available to create
  ; the canvas, just use normal IDL widgets for the iTool container.
  wbCanvasID = createCanvas ? IDLNotify('wb_create_canvas',dimStr,'') : 0

  if (wbCanvasID ne 0 && wbCanvasID ne 1) then begin
     ; The workbench has created a graphics canvas.

     ; Create a uiAdaptor object that will be the communication
     ; mechanism between the workbench and the iTool.
     ; For Example, it gets all native GUI events 
     ;  (OnEnter, OnExit, OnWheel, OnMouseMotion, OnMouseDown,
     ;   OnMouseUp, OnExpose, etc..)
     uiAdaptor = OBJ_NEW('GraphicsWin', toolName, EXTERNAL_WINDOW=wbCanvasID, $
      LAYOUT_INDEX=1, $
      /ZOOM_ON_RESIZE)

     ; Attach our uiAdaptor to the wbGraphic Canvas
     uiAdaptorStr = obj_valid(uiAdaptor, /get_heap_id)
     oTool = uiAdaptor->GetTool()
     id = oTool->GetFullIdentifier()
     payload = STRTRIM(uiAdaptorStr,2) + '::' + id
     void = IDLNotify('attachUIAdaptorToCanvas',wbCanvasID, payload)

     ; Pass the window title to the workbench.
     void = IDLNotify('IDLitThumbnail', title + '::' + id, '')

  endif

  ; Add layout if either layout or margin is specified
  if ((N_ELEMENTS(marginIn) ne 0) || (N_ELEMENTS(layoutIn) eq 3)) then $
    layout = N_ELEMENTS(layoutIn) eq 3 ? layoutIn : [1,1,1]

  ; Render the plot into the IDL Workbench

  case nparams of
    1: call_procedure, procName, TEST=test, $
         _EXTRA=ex, /NO_SAVEPROMPT, BUFFER=buffer, /AUTO_DELETE, /NO_TRANSACT, $
         /NO_MENUBAR, WINDOW_TITLE=title, LAYOUT=layout, MARGIN=marginIn, $
         TOOLNAME='Graphic', USER_INTERFACE='Graphic', $
         DIMENSIONS=dimensions, LOCATION=location, $
         CURRENT=(current || (wbCanvasID gt 1)), OVERPLOT=overplot
    2: call_procedure, procName, arg1, $
         _EXTRA=ex, /NO_SAVEPROMPT, BUFFER=buffer, /AUTO_DELETE, /NO_TRANSACT, $
         /NO_MENUBAR, WINDOW_TITLE=title, LAYOUT=layout, MARGIN=marginIn, $
         TOOLNAME='Graphic', USER_INTERFACE='Graphic', $
         DIMENSIONS=dimensions, LOCATION=location, $
         CURRENT=(current || (wbCanvasID gt 1)), OVERPLOT=overplot
    3: call_procedure, procName, arg1, arg2, $
         _EXTRA=ex, /NO_SAVEPROMPT, BUFFER=buffer, /AUTO_DELETE, /NO_TRANSACT, $
         /NO_MENUBAR, WINDOW_TITLE=title, LAYOUT=layout, MARGIN=marginIn, $
         TOOLNAME='Graphic', USER_INTERFACE='Graphic', $
         DIMENSIONS=dimensions, LOCATION=location, $
         CURRENT=(current || (wbCanvasID gt 1)), OVERPLOT=overplot
    4: call_procedure, procName, arg1, arg2, arg3, $
         _EXTRA=ex, /NO_SAVEPROMPT, BUFFER=buffer, /AUTO_DELETE, /NO_TRANSACT, $
         /NO_MENUBAR, WINDOW_TITLE=title, LAYOUT=layout, MARGIN=marginIn, $
         TOOLNAME='Graphic', USER_INTERFACE='Graphic', $
         DIMENSIONS=dimensions, LOCATION=location, $
         CURRENT=(current || (wbCanvasID gt 1)), OVERPLOT=overplot
    5: call_procedure, procName, arg1, arg2, arg3, arg4, $
         _EXTRA=ex, /NO_SAVEPROMPT, BUFFER=buffer, /AUTO_DELETE, /NO_TRANSACT, $
         /NO_MENUBAR, WINDOW_TITLE=title, LAYOUT=layout, MARGIN=marginIn, $
         TOOLNAME='Graphic', USER_INTERFACE='Graphic', $
         DIMENSIONS=dimensions, LOCATION=location, $
         CURRENT=(current || (wbCanvasID gt 1)), OVERPLOT=overplot
  endcase

  ; Return the created graphic object to the caller
  graphic = OBJ_NEW()
  void = iGetCurrent(TOOL=oTool)
  
  if (OBJ_VALID(oTool)) then begin

    oTool->ProbeStatusMessage, "Click to Pan, <Shift>Click to Zoom"

    oWin = oTool->GetCurrentWindow()
    oSel = oTool->GetSelectedItems(COUNT=nSel)
    graphic = oSel[0]
    if (nSel gt 0 && OBJ_VALID(graphic)) then begin
      ; If the graphic is already the correct class then return it.
      if (~ISA(graphic, graphicName)) then begin
        ; Otherwise, if a class exists, use it.
        ; Otherwise, just wrap it in the generic Graphic class.
        catch, ierr1
        if (ierr1 ne 0) then begin
          graphic = OBJ_NEW('Graphic', oSel[0])
        endif else begin
          graphic = Graphic_GetGraphic(oSel[0])
        endelse
      endif
      oWin->ClearSelections
    endif else begin
      ; Return the window if no graphics were created.
      graphic = oWin
    endelse
  
    ; Reset the Undo/Redo buffer if this is the first graphic.
    if (wbCanvasID ne 0) then begin
      oBuffer = oTool->_GetCommandBuffer()
      oBuffer->ResetBuffer
      oTool->_SetDirty, 0b
    endif
  endif

end
