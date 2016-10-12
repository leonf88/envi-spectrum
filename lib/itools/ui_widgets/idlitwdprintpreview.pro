; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdprintpreview.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------

;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_RecalcGeom
;;
;; Purpose:
;;  Used to recalculate the geometry of the preview graphic. Called
;;  when the mode of the printer or the printer itself changed.
;;
;; Parameters:
;;   pState   - The state struct for this widget
;;
PRO IDLitwdPrintPreview_RecalcGeom, pState
  compile_opt hidden, idl2

  ;; This just performs the same operations that the page setup did,
  ;; but uses the same objects. This is a brute force method of
  ;; doing this.

  s_pgBoarder = (*pState).s_pgBoarder
  s_pgBevel = (*pState).s_pgBevel
  s_pgScaleSize = (*pState).s_pgScaleSize

  szScreen = get_screen_size()
  oPrinter = (*pState).oPrintService->GetDevice()
  oPrinter->GetProperty, dimensions=prtDims, resolution=prtRes, $
                         landscape=landscape

  ;; Calculate page sizes
  aspect = prtDims[1]/prtDims[0]

  ;; Some reported screen sizes are logical (due to multi-monitor
  ;; implementations) which cna will report desktops with large X
  ;; sizes. To manage this, take the smallest dimension of screen
  ;; size and use it to construct the max dimension
  if(szScreen[0] gt szScreen[1])then $ ;; x > y
    szScreen[0] = szScreen[1]*1.2 $
  else $
    szScreen[1] = szScreen[0]*1.2

  if(landscape)then begin
    xSize = fix(szScreen[0]*.4)
    ySize = fix(xSize*aspect)
  endif else begin
    ySize = fix(szScreen[1]*.4)
    xSize = fix(ySize/aspect)
  endelse
  xPage = xSize - 2* s_pgBoarder - s_pgBevel
  yPage = ySize - 2* s_pgBoarder - s_pgBevel

  ;; Resize drawable
  widget_control, (*pState).wDraw, xsize=xSize, ysize=ySize

  ;; Page size and coordinate conversions
  xDim=xSize/2
  yDim=ySize/2
  recPage = [-xDim + s_pgBoarder, $
             -yDim+s_pgBoarder+s_pgBevel, $
             xDim-s_pgBoarder-s_pgBevel,  $
             yDim-s_pgBoarder]
  xCoord = [0, 1./xDim]
  yCoord = [0, 1./yDim]

  ;; Reset the geometry of the existing lines.
  ;; Right Shadow
  (*pState).oRShadow->SetProperty, $
    xCoord_Conv=xCoord, yCoord_conv=yCoord, data = transpose($
    [[recPage[2] +s_pgBevel, recPage[2] + s_pgBevel,recPage[2], recPage[2]],$
     [ recPage[1]-s_pgBevel, recPage[3]-s_pgBevel, $
       recPage[3]-s_pgBevel, recPage[1]-s_pgBevel]])

  ;; Bottom Shadow
  (*pState).oBShadow->SetProperty, $
    xCoord_Conv=xCoord, $
    yCoord_conv=yCoord, data = transpose( $
    [ [recPage[0]+s_pgBevel, recPage[2], $
       recPage[2], recPage[0]+s_pgBevel], $
      [recPage[1]-s_pgBevel, recPage[1]-s_pgBevel, $
       recPage[1], recPage[1]]])

  ;; Paper
  (*pState).oPage->SetProperty, xCoord_Conv=xCoord, $
     yCoord_conv=yCoord, data = transpose($
     [[recPage[0], recPage[0], recPage[2], recPage[2]], $
     [recPage[1], recPage[3], recPage[3], recPage[1]] ])

  (*pState).oDraw->GetProperty, dimensions=winDims, resolution=winRes
  winDimsCM = [xPage, yPage] * winRes
  WinToPrinter = winRes/prtRes ;; convert from window pix to printer pix
  WinPrtRatio = winDimsCM/(prtDims*prtRes) ; Convert from Printer CM to Preview

  ;; convert to printer size and then scale down to print preview space
  imDims = (*pState).srcDims * WinPrtRatio

  (*pState).oImage->SetProperty, $
    location=[recPage[0:1],.1], $
    dimension=imDims, $
    sub_rect=subRect, $
    xCoord_Conv=xCoord, $
    yCoord_Conv=yCoord

  ;; Scale block
  ScaleOffset = imDims + recPage[0:1]
  x = s_pgScaleSize
  (*pState).oScale->SetProperty, $
    xCoord_Conv=xCoord, $
    yCoord_conv=yCoord, data = transpose( $
    [[[0, 0, x, x]+ ScaleOffset[0]], [[0, x, x, 0]+ ScaleOffset[1]], $
     [.1,.1,.1,.1]])

  ;; move the image border
  loc = recPage[0:1]
  (*pState).oBorder->SetProperty, $
    DATA=transpose([[loc[0], loc[0], loc[0]+imDims[0], loc[0]+imDims[0], loc[0]], $
                    [loc[1], loc[1]+imDims[1], loc[1]+imDims[1], loc[1], loc[1]], $
                    [.1,.1,.1,.1,.1]]), $
    xCoord_Conv=xCoord, yCoord_conv=yCoord

  ;; reset image transparency
  (*pState).oImage->GetProperty, DATA=data
  data[3,*,*] = 255b
  (*pState).oImage->SetProperty, DATA=data

  ;; Reset some state values
  (*pState).pt0 = [s_pgBoarder, s_pgBoarder+s_pgBevel]
  (*pState).ptCurrent = [s_pgBoarder, s_pgBoarder+s_pgBevel]
  (*pState).ptImage = recPage[0:1]
  (*pState).recPage = recPage
  (*pState).WinPrtRatio = WinPrtRatio
  (*pState).SrcToPrinter = (*pState).srcRes/prtRes
  (*pState).SrcToPrinterDims = [recPage[2]-recPage[0],recPage[3]-recPage[1]]/prtDims
  (*pState).imDims = imDims
  (*pState).aspect=aspect
  (*pState).ptScale = imDims+s_pgBoarder+[0,s_pgBevel]
  (*pState).landscape=landscape
  (*pState).prtRes = prtRes
  (*pState).prtDims = prtDims
  (*pState).paperDims = [recPage[2]-recPage[0],recPage[3]-recPage[1]]
  (*pState).paperRes = prtRes * prtDims / (*pState).paperDims

  ;; calculate size of image
  sz = (*pState).srcDims * (*pState).srcRes
  ;; convert to inches if necessary
  IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
    sz /= 2.54
  ;; update status bar
  void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, $
                                           set_value=sz[0])
  void = IDLitwdPrintPreview_ValidateValue((*pState).wHeight, $
                                           set_value=sz[1])
  void = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin, $
                                           set_value=0)
  void = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin, $
                                           set_value=0)

  ;; center image
  IF widget_info((*pState).wCenter, /button_set) THEN $
    IDLitwdPrintPreview_CenterImage, pState

  ;; that's all...

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_CenterImage
;;
;; Purpose:
;;    Centers the image on the paper
;;
;; Parameters:
;;    PSTATE - pointer to state structure
;;
;; Keywords:
;;    NONE
;;
PRO IDLitwdPrintPreview_CenterImage, pState
  compile_opt hidden, idl2

  (*pState).oImage->getProperty, dimension=dims
  delta = (-dims/2) - (*pState).ptImage
  IDLitwdPrintPreview_MoveImage, pState, delta[0], delta[1]
  (*pState).oDraw->Draw
  (*pState).oDraw->GetProperty, dimensions=winDims
  (*pState).ptCurrent = winDims/2 - dims/2

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_MoveBorder
;;
;; Purpose:
;;    Moves the image border
;;
;; Parameters:
;;    PSTATE - pointer to state structure
;;
;; Keywords:
;;    NONE
;;
PRO IDLitwdPrintPreview_MoveBorder, pState
  compile_opt hidden, idl2

  ;; move the image border
  loc = (*pState).ptImage
  imDims = floor((*pState).ptScale - (*pState).ptZero)
  (*pState).oBorder->SetProperty, $
    DATA=transpose([[loc[0], loc[0], loc[0]+imDims[0], loc[0]+imDims[0], loc[0]], $
                    [loc[1], loc[1]+imDims[1], loc[1]+imDims[1], loc[1], loc[1]], $
                    [.1,.1,.1,.1,.1]])

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_UpdateTransparency
;;
;; Purpose:
;;    Updates the transparency of the main image
;;
;; Parameters:
;;    PSTATE - pointer to state structure
;;
;; Keywords:
;;    NONE
;;
PRO IDLitwdPrintPreview_UpdateTransparency, pState
  compile_opt hidden, idl2

  ;; get image data and reset transparency
  (*pState).oImage->GetProperty, DATA=imgdata
  dataChange = ~(min(imgdata[3,*,*]) EQ 255b)
  imgdata[3,*,*] = 255b
  ;; update transparency of image, Y sides
  IF ((*pState).ptImage[1]+(*pState).ptScale[1]-(*pState).ptZero[1] GT $
      (*pState).recPage[3]) THEN BEGIN
    cutLine = (-((*pState).ptImage[1]-(*pState).recPage[3]) > 0) / $
              ((*pState).ptScale[1]-(*pState).ptZero[1]) * $
              (size(imgdata,/dimensions))[2]
    imgdata[3,*,cutLine:*] = 0b
    dataChange = 1b
  ENDIF
  IF ((*pState).ptImage[1] LT (*pState).recPage[1]) THEN BEGIN
    cutLine = ((((*pState).recPage[1]-(*pState).ptImage[1]) < $
                ((*pState).ptScale[1]-(*pState).ptZero[1])) / $
               ((*pState).ptScale[1]-(*pState).ptZero[1]) * $
               (size(imgdata,/dimensions))[2]) < $
              (size(imgdata,/dimensions))[2]-1
    imgdata[3,*,0:cutLine] = 0b
    dataChange = 1b
  ENDIF
  ;; update transparency of image, X sides
  IF ((*pState).ptImage[0]+(*pState).ptScale[0]-(*pState).ptZero[0] GT $
      (*pState).recPage[2]) THEN BEGIN
    cutLine = (-((*pState).ptImage[0]-(*pState).recPage[2]) > 0) / $
              ((*pState).ptScale[0]-(*pState).ptZero[0]) * $
              (size(imgdata,/dimensions))[1]
    imgdata[3,cutLine:*,*] = 0b
    dataChange = 1b
  ENDIF
  IF ((*pState).ptImage[0] LT (*pState).recPage[0]) THEN BEGIN
    cutLine = ((((*pState).recPage[0]-(*pState).ptImage[0]) < $
                ((*pState).ptScale[0]-(*pState).ptZero[0])) / $
               ((*pState).ptScale[0]-(*pState).ptZero[0]) * $
               (size(imgdata,/dimensions))[1]) < $
              (size(imgdata,/dimensions))[1]-1
    imgdata[3,0:cutLine,*] = 0b
    dataChange = 1b
  ENDIF
  ;; update transparancy changes
  IF (dataChange) THEN $
    (*pState).oImage->SetProperty, DATA=imgdata

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_ValidateValue
;;
;; Purpose:
;;    Updates the status bar text boxes and ensures that the value in
;;    the margin and size boxes are valid values
;;
;; Parameters:
;;    WID - The widget id of the text widget
;;
;; Keywords:
;;    SET_VALUE - If set the widget is updated to the new value,
;;                otherwise the text entered by the user is
;;                prettyfied.
;;
;;    POSITIVE - If set then negative values will be discarded
;;
FUNCTION IDLitwdPrintPreview_ValidateValue, wID, set_value=newValue, positive=positive
  compile_opt hidden, idl2

  ;; get new value and old value (stored in uvalue)
  widget_control, wID, get_value=val, get_uvalue=uval
  ;; if set_value was passed in use that instead of get_value
  IF (n_elements(newValue) EQ 1) THEN $
    val = newValue
  ;; set up a catch for conversion errors
  on_ioerror, bad_input
  ;; try to convert value to a float
  val = double(val[0])
  ;; check for negative values if positive only
  IF (keyword_set(positive) && (val LT 0)) THEN BEGIN
    widget_control, wID, set_value=uval
    return, !values.f_nan
  ENDIF
  ;; create a nice format for the value
  strVal = string(val, format='(f0.2)')
  ;; put nice string in the widget and in the uvalue
  widget_control, wID, set_value=strVal, set_uvalue=strVal
  return, val

  ;; if a non float was entered reset value to previous value
  bad_input:
  widget_control, wID, set_value=uval
  return, !values.f_nan

END

;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_MoveImage
;;
;; Purpose:
;;    Encapsulates the logic needed to move the image on the
;;    printed page.
;;
;; Parameters:
;;    pState  - The state for this widget
;;
;;    DeltaX  - The x amount to move in pixels
;;
;;    DeltaY  - The y amount to move in pixels
;;
;; Keywords:
;;    NO_STATUS_UPDATE - If set do not recalcuate the values of X and
;;                       Y Margin.  Prevents rounding errors from
;;                       appearing.
;;
PRO IDLitwdPrintPreview_MoveImage, pState, DeltaX, Deltay, $
                                   NO_STATUS_UPDATE=noStatUpdate
  compile_opt hidden, idl2

  ;; Move in Y
  IF (DeltaY NE 0) THEN BEGIN
    ;; scale block
    (*pState).oScale->GetProperty, data=data
    data[1,*] += deltay
    (*pState).oScale->SetProperty, data=data

    (*pState).ptImage[1] += deltay
    (*pState).ptCurrent[1] += deltay
  ENDIF

  ;; Move in x
  IF (DeltaX NE 0) THEN BEGIN
    ;; Scale block
    (*pState).oScale->GetProperty, data=data
    data[0,*] += deltax
    (*pState).oScale->SetProperty, data=data

    (*pState).ptImage[0] += deltax
    (*pState).ptCurrent[0] += deltax
  ENDIF

  IF (deltay NE 0 || deltax NE 0) THEN $
    IDLitwdPrintPreview_UpdateTransparency, pState

  ;; Update the status bar on the page. offset in CM
  IF ~keyword_set(NoStatUpdate) THEN BEGIN
    cmoffSet = ((*pState).ptCurrent - (*pState).pt0) / $
               (*pState).SrcToPrinterDims * (*pState).prtRes
    IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
      cmoffSet /= 2.54
    IF (deltaX NE 0) THEN $
      void = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin, $
                                               set_value=cmoffSet[0])
    IF (deltaY NE 0) THEN $
      void = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin, $
                                               set_value=cmoffSet[1])
  ENDIF

  ;; Offset the image.
  (*pState).oImage->SetProperty, location=[(*pState).ptImage,.1]

  IDLitwdPrintPreview_MoveBorder, pState

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_HandleDrawEvent
;;
;; Purpose:
;;   Encapsulates the event handling for draw widget events.
;;
;; Parameters:
;;    sEvent    - The event
;;
;;    pState    - The state for this widget.
pro idlitwdPrintPreview_HandleDrawEvent, sEvent, pState
  compile_opt hidden, idl2

  ;; Just look at the event type
  CASE sEvent.type OF
    ;; Expose Event
    4 : (*pState).oDraw->Draw

    ;; Motion Event
    2 : BEGIN
      IF (~obj_valid((*pState).oCurrent)) THEN BEGIN
        ;; Not in the middle of a mouse down. Hit anything?
        oObjs= (*pState).oDraw->Select((*pState).oView, $
                                       [sEvent.x,sEvent.y])
        ;; Update the cursor
        IF (obj_valid(oObjs[0])) THEN BEGIN
          oObjs[0]->GetProperty, uvalue=uvalue
          IF ~n_elements(uvalue) THEN uvalue=''
          case uValue of
            "SCALE"  : cursor='size_ne'
            'IMAGE' : cursor = $
              widget_info((*pState).wCenter, /button_set) ? 'arrow' : 'move'
            else: cursor='arrow'
          ENDCASE
        ENDIF ELSE $
          cursor='arrow'
        (*pState).oDraw->SetCurrentCursor, cursor

      ENDIF ELSE BEGIN ;; we are in the middle of a mouse down-up transaction
        ;; number of pixels of image requried to remain on 'page'
        clipMargin = 20
        ;; Move the lines and image
        CASE (*pState).mode OF
          1 : BEGIN ;; move
            ;; do nothing if locked to center
            IF widget_info((*pState).wCenter, /button_set) THEN $
              return

            ;; calculate deltas
            deltax = (sEvent.x - (*pState).ptMouse[0])
            deltay = (sEvent.y - (*pState).ptMouse[1])

            ;; clip upper X end
            deltax <= (*pState).recPage[2]-(*pState).recPage[0]+(*pState).pt0[0]- $
                      (*pState).ptCurrent[0]-clipMargin
            ;; clip lower X end
            deltax >= (*pState).pt0[0]-floor((*pState).ptScale[0]-(*pState).ptZero[0])- $
                      (*pState).ptCurrent[0]+clipMargin
            ;; clip upper Y end
            deltay <= (*pState).recPage[3]-(*pState).recPage[1]+(*pState).pt0[1]- $
                      (*pState).ptCurrent[1]-clipMargin
            ;; clip lower Y end
            deltay >= (*pState).pt0[1]-floor((*pState).ptScale[1]-(*pState).ptZero[1])- $
                      (*pState).ptCurrent[1]+clipMargin

            IDLitwdPrintPreview_MoveImage, pState, deltax, deltay
            (*pState).ptMouse += [deltax, deltay]
          END
          2 : BEGIN ;; scale
            IF widget_info((*pState).wCenter, /button_set) THEN $
              centerPt = (*pState).ptCurrent + ((*pState).ptScale-(*pState).ptZero)/2 $
            ELSE $
              centerPt = (*pState).ptCurrent

            ;; contrain to proper part of the paper
            sEvent.y >= ((*pState).ptZero[1] > centerPt[1]) + clipMargin
            sEvent.x >= ((*pState).ptZero[0] > centerPt[0]) + clipMargin

            ;; contrain to first quadrant
            angleNew = atan(sEvent.y-centerPt[1], sEvent.x-centerPt[0])
            angle = atan((*pState).ptScale[1]-(*pState).ptZero[1], $
                         (*pState).ptScale[0]-(*pState).ptZero[0])

            imDims = (*pState).ptScale - (*pState).ptZero

            ;; Weird stuff.  Track changes to size based on nearest
            ;; side of the image to the mouse
            side = angle LT angleNew
            imDims = [0.0,0.0]
            imDims[side] = sEvent.(4+side) - (*pState).ptCurrent[side]
            imDims[~side] = imDims[side] * $
                            (side ? 1.0/(*pState).imAspect : (*pState).imAspect) / $
                            ((*pState).paperRes[~side]/(*pState).paperRes[side])
            newScale = imDims + (*pState).ptZero

            delta = newScale - (*pState).ptScale
            (*pState).ptScale = newscale

            IF widget_info((*pState).wCenter, /button_set) THEN BEGIN
              ;; scale around center
              IDLitwdPrintPreview_MoveImage, pState, -round(delta[0]/2), $
                                             -round(delta[1]/2)
            ENDIF

            ;; move the scale block
            (*pState).oScale->GetProperty, data=data
            data[side,*] += delta[side]
            data[~side,*] += delta[~side]
            (*pState).oScale->SetProperty, data=data

            ;; resize the image
            (*pState).oImage->SetProperty, dimensions=imDims

            ;; update image transparency
            IDLitwdPrintPreview_UpdateTransparency, pState

            ;; move the image border
            IDLitwdPrintPreview_MoveBorder, pState

            ;; calculate size of image
            sz = imDims * (*pState).paperRes
            ;; convert to inches if necessary
            IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
              sz /= 2.54
            ;; update status bar
            void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, $
                                                     set_value=sz[0])
            void = IDLitwdPrintPreview_ValidateValue((*pState).wHeight, $
                                                     set_value=sz[1])
          END
          ELSE :
        ENDCASE
      ENDELSE
    END

    ;; Mouse Down
    0 : BEGIN
      ;; What did we hit?
      oObjs= (*pState).oDraw->Select((*pState).oView, $
                                     [sEvent.x,sEvent.y])
      IF (obj_valid(oObjs[0])) THEN BEGIN
        ;; Set this object as the current item if it has uvalue
        oObjs[0]->GetProperty, uvalue=uvalue
        IF (keyword_set(uvalue)) THEN BEGIN
          (*pState).oCurrent= oObjs[0]
          (*pState).mode = where(uvalue EQ ['','IMAGE','SCALE'])
          (*pState).ptMouse = [sEvent.x, sEvent.y]
        ENDIF
      ENDIF
    END

    ;; Mouse Up
    1 : (*pState).oCurrent=obj_new()

    ELSE :

  ENDCASE

  ;; Redraw the window
  (*pState).oDraw->Draw

END


;---------------------------------------------------------------------------
; Save values to window.
;
; PRINT: If this keyword is set then also print the window.
;
pro IDLitwdPrintPreview_SaveValues, pState, PRINT=print

    compile_opt hidden, idl2

    print_orientation = (*pState).landscape
    print_xmargin = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin)
    print_ymargin = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin)
    print_width = IDLitwdPrintPreview_ValidateValue((*pState).wWidth)
    print_height = IDLitwdPrintPreview_ValidateValue((*pState).wHeight)
    print_units = widget_info((*pState).wUnits, /droplist_select)
    print_center = widget_info((*pState).wCenter, /button_set)

    (*pState).oPrintOperation->SetProperty, $
        PRINT_ORIENTATION=print_orientation, $
        PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
        PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
        PRINT_UNITS=print_units, PRINT_CENTER=print_center

    if KEYWORD_SET(print) then begin
        void = (*pState).oPrintService->DoAction( $
            (*pState).oWinSrc->getTool(), $
            PRINT_ORIENTATION=print_orientation, $
            PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
            PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
            PRINT_UNITS=print_units, PRINT_CENTER=print_center)
    endif

end


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview_Event
;;
;; Purpose:
;;   Event handler for this widget
;;
;; Parameter:
;;    SEVENT  - The widget event
;;
;;    INIT - If set force the values of WIDTH and HEIGHT to be set
;;
PRO idlitwdPrintPreview_event, sEvent, INIT=init
  compile_opt hidden, idl2

@idlit_catch
  IF (iErr ne 0) THEN BEGIN
    catch, /cancel
    return
  ENDIF

  widget_control, sEvent.top, get_uvalue=pState
  name = widget_info(sEvent.id, /uname)

  ;; Killing the window apes the close button
  IF (TAG_NAMES(sEvent, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') THEN $
    name = 'CLOSE'

  CASE name OF
    ;; Pass draw events to draw event handler
    'DRAW' : IDLitwdPrintPreview_HandleDrawEvent, sEvent, pState

    ;; Layout mode was changed
    'LAYOUT' : BEGIN
      oPrinter = (*pState).oPrintService->getDevice()
      oPrinter->SetProperty, landscape=(sEvent.index eq 1)
      IDLitwdPrintPreview_RecalcGeom, pState
    END

    ;; Printer setup button
    'SETUP' : BEGIN
      oPrinter = (*pState).oPrintService->getDevice()
      status = dialog_printersetup(oPrinter, dialog_parent=sEvent.top)
      IF status THEN BEGIN
        IDLitwdPrintPreview_SaveValues, pState, /PRINT
        widget_control, sEvent.top, /destroy
      ENDIF

      return
    END

    ;; Center the image in the page.
    'CENTER': BEGIN
      IF sEvent.select THEN $
        IDLitwdPrintPreview_CenterImage, pState
      widget_control, (*pState).wXMargin, sensitive=~sEvent.select
      widget_control, (*pState).wYMargin, sensitive=~sEvent.select
    END

    ;; Print the graphic
    'PRINT': BEGIN
        IDLitwdPrintPreview_SaveValues, pState, /PRINT
        widget_control, sEvent.top, /destroy
    END

    ;; Close the preview
    'CLOSE': BEGIN
        IDLitwdPrintPreview_SaveValues, pState
      widget_control, sEvent.top, /destroy
    END

    ;; Reset values to default state
    'RESET' : BEGIN
      widget_control, sEvent.top, update=0
      ;; reset units
      widget_control, (*pState).wUnits, set_droplist_select=0
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wUnits, index:0}
      ;; reset center button
      widget_control, (*pState).wCenter, set_button=0
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wCenter, select:0}
      ;; reset image border
      widget_control, (*pState).wBorder, set_button=1
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wBorder, select:1}
      ;; reset margins
      void = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin, set_value=0)
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wXMargin}
      void = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin, set_value=0)
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wYMargin}
      ;; get window settings
      (*pState).oWinSrc->GetProperty, dimensions=srcDims, resolution=srcRes
      ;; calculate size of image
      sz = srcDims * srcRes / 2.54
      ;; update status bar
      void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, set_value=sz[0])
      IDLitwdPrintPreview_event, {top:sEvent.top, id:(*pState).wWidth}, /init
      ;; turn updates back on
      widget_control, sEvent.top, update=1
    END

    ;; Update X margin
    'XMARGIN' : BEGIN
      ;; ignore moving into field
      IF ((TAG_NAMES(sEvent, /STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS') && $
          (sEvent.enter EQ 1)) THEN $
            return

      val = idlitwdprintpreview_validatevalue(sEvent.id)
      IF ~finite(val) THEN $
        return
      ;; convert to centimeters if needed
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        val *= 2.54
      newVal = val / (*pState).prtRes[0] * (*pState).SrcToPrinterDims[0] + $
               (*pState).pt0[0]

      ;; number of pixels of image requried to remain on 'page'
      clipMargin = 20
      ;; clip upper X end
      newVal <= (*pState).recPage[2]-(*pState).recPage[0]+(*pState).pt0[0]- $
                clipMargin
      ;; clip lower X end
      newVal >= (*pState).pt0[0]-floor((*pState).ptScale[0]-(*pState).ptZero[0])+clipMargin

      deltaX = newVal-((*pState).ptCurrent)[0]
      IF (abs(deltaX) LT 1) THEN deltaX = 0
      IDLitwdPrintPreview_MoveImage, pState, deltaX, 0
      (*pState).oDraw->Draw
    END

    ;; Update Y margin
    'YMARGIN' : BEGIN
      ;; ignore moving into field
      IF ((TAG_NAMES(sEvent, /STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS') && $
          (sEvent.enter EQ 1)) THEN $
            return

      val = idlitwdprintpreview_validatevalue(sEvent.id)
      IF ~finite(val) THEN $
        return
      ;; convert to centimeters if needed
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        val *= 2.54
      newVal = val / (*pState).prtRes[1] * (*pState).SrcToPrinterDims[1] + $
               (*pState).pt0[1]

      ;; number of pixels of image requried to remain on 'page'
      clipMargin = 20
      ;; clip upper Y end
      newVal <= (*pState).recPage[3]-(*pState).recPage[1]+(*pState).pt0[1]- $
                clipMargin
      ;; clip lower Y end
      newVal >= (*pState).pt0[1]-floor((*pState).ptScale[1]-(*pState).ptZero[1])+clipMargin

      deltaY = newVal-((*pState).ptCurrent)[1]
      IF (abs(deltaY) LT 1) THEN deltaY = 0
      IDLitwdPrintPreview_MoveImage, pState, 0, deltaY
      (*pState).oDraw->Draw
    END

    ;; Update Width
    'WIDTH' : BEGIN
      ;; ignore moving into field
      IF ((TAG_NAMES(sEvent, /STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS') && $
          (sEvent.enter EQ 1)) THEN $
            return

      widget_control, sEvent.id, get_uvalue=oldVal
      val = idlitwdprintpreview_validatevalue(sEvent.id, /positive)
      IF ~finite(val) THEN $
        return

      IF ((val EQ oldVal) && ~keyword_set(init)) THEN return

      ;; convert from inches if needed
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        val *= 2.54

      imDims = [val, val*(*pState).imAspect] / (*pState).paperRes

      newScale = imDims + (*pState).ptZero

      delta = newScale - (*pState).ptScale
      (*pState).ptScale = newScale

      IF widget_info((*pState).wCenter, /button_set) THEN BEGIN
        ;; scale around center
        IDLitwdPrintPreview_MoveImage, pState, -round(delta[0]/2.0), $
                                       -round(delta[1]/2.0)
      ENDIF

      (*pState).oImage->setproperty, dimensions=imDims

      ;; update image transparency
      IDLitwdPrintPreview_UpdateTransparency, pState

      ;; move the image border
      IDLitwdPrintPreview_MoveBorder, pState

      ;; move the scale block
      ScaleOffset = imDims + (*pState).recPage[0:1] + $
                    (*pState).ptCurrent - (*pState).pt0

      x = (*pState).s_pgScaleSize
      (*pState).oScale->SetProperty, $
        DATA=transpose([[[0,0,x,x]+ScaleOffset[0]], [[0,x,x,0]+ScaleOffset[1]], $
                        [[.1,.1,.1,.1]]])

      (*pState).oDraw->Draw

      ;; calculate size of image
      sz = imDims * (*pState).paperRes
      ;; convert to inches if necessary
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        sz /= 2.54
      ;; update status bar
      void = IDLitwdPrintPreview_ValidateValue((*pState).wHeight, $
                                               set_value=sz[1])
    END

    ;; Update Height
    'HEIGHT' : BEGIN
      ;; ignore moving into field
      IF ((TAG_NAMES(sEvent, /STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS') && $
          (sEvent.enter EQ 1)) THEN $
            return

      widget_control, sEvent.id, get_uvalue=oldVal
      val = idlitwdprintpreview_validatevalue(sEvent.id, /positive)
      IF ~finite(val) THEN $
        return

      IF ((val EQ oldVal) && ~keyword_set(init)) THEN return

      ;; convert from inches if needed
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        val *= 2.54

      newScale = [val/(*pState).imAspect, val]  / (*pState).paperRes + $
                 (*pState).pt0

      delta = newScale - (*pState).ptScale
      (*pState).ptScale = newScale

      IF widget_info((*pState).wCenter, /button_set) THEN BEGIN
        ;; scale around center
        IDLitwdPrintPreview_MoveImage, pState, -round(delta[0]/2.0), $
                                       -round(delta[1]/2.0)
      ENDIF

      (*pState).oImage->setproperty, dimensions=$
        (*PState).ptScale - (*pState).ptZero

      ;; update image transparency
      IDLitwdPrintPreview_UpdateTransparency, pState

      ;; move the image border
      IDLitwdPrintPreview_MoveBorder, pState

      ;; move the scale block
      ScaleOffset = (*pState).ptScale - (*pState).ptZero + $
                    (*pState).recPage[0:1] + $
                    (*pState).ptCurrent - (*pState).pt0
      x = (*pState).s_pgScaleSize
      (*pState).oScale->SetProperty, $
        DATA=transpose([[[0,0,x,x]+ScaleOffset[0]], [[0,x,x,0]+ScaleOffset[1]], $
                        [[.1,.1,.1,.1]]])

      (*pState).oDraw->Draw

      ;; calculate size of image
      sz = ((*pState).ptScale - (*pState).pt0) * (*pState).paperRes
      ;; convert to inches if necessary
      IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
        sz /= 2.54
      ;; update status bar
      void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, $
                                               set_value=sz[0])
    END

    ;; Change dimension units
    'UNITS' : BEGIN
      widget_control, (*pState).wXMargin, get_value=xmargin
      widget_control, (*pState).wYMargin, get_value=ymargin
      widget_control, (*pState).wWidth, get_value=width
      widget_control, (*pState).wHeight, get_value=height

      CASE sEvent.index OF
        0 : BEGIN
          void = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin, $
                                                   set_value=xmargin/2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin, $
                                                   set_value=ymargin/2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, $
                                                   set_value=width/2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wHeight, $
                                                   set_value=height/2.54)
        END
        1 : BEGIN
          void = IDLitwdPrintPreview_ValidateValue((*pState).wXMargin, $
                                                   set_value=xmargin*2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wYMargin, $
                                                   set_value=ymargin*2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wWidth, $
                                                   set_value=width*2.54)
          void = IDLitwdPrintPreview_ValidateValue((*pState).wHeight, $
                                                   set_value=height*2.54)
        END
        ELSE :
      ENDCASE
    END

    'BORDER' : BEGIN
      (*pState).oBorder->SetProperty, hide=~sEvent.select
      (*pState).oDraw->Draw
    END

    'HELP' : BEGIN
      online_help, 'ITOOLS_PRINTING'
    END

    ELSE :

  ENDCASE

END


;;---------------------------------------------------------------------------
;; IDLitwdPrintPreview
;;
;; Purpose:
;;   Displays a widget that provides a print "preview" to the
;;   user. This widget allows basic control over the print settings
;;   and layout.
;;
;; Parameters:
;;   oUI   - The UI object.
;;
;;   oTarget - The target object that launched this.
;;
function IDLitwdPrintPreview, oUI, oTarget
  compile_opt hidden, idl2

  oUI->GetProperty, group_leader=group_leader
  ;; Some hard coded sizes
  s_pgBoarder  = 50   ;; space around the edge
  s_pgBevel    = 4    ;; size of the bevel.
  s_pgScaleSize = 10  ;; size of scale block

  clrDrop = [0,0,0]    ;; drop shadow color
  clrBack = [128, 128, 128] ;; backgroud clr
  ;; Get the screen size
  szScreen = get_screen_size()

  ;; Get the system print service
  oTool = oUI->GetTool()

  ;; get current window
  oWinSrc = oTool->GetCurrentWindow()
  IF (~OBJ_VALID(oWinSrc)) THEN $
    return, 0
  oWinSrc->GetProperty, dimensions=srcDims, resolution=srcRes

    oPrintOperation = oTool->GetByIdentifier('Operations/File/Print')
    if (~OBJ_VALID(oPrintOperation)) then begin
        void = DIALOG_MESSAGE(/error, DIALOG_PARENT=group_leader, $
            IDLitLangCatQuery('UI:wdPrintPreview:BadPrintSrv'))
        return, 0
    endif
    oPrintOperation->GetProperty, PRINT_ORIENTATION=landscape, $
        PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
        PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
        PRINT_UNITS=print_units, PRINT_CENTER=print_center

  oPrintService = oTool->GetService("PRINTER")
  IF (~obj_valid(oPrintService)) THEN BEGIN
    void = dialog_message(/error, dialog_parent=group_leader, $
                          IDLitLangCatQuery('UI:wdPrintPreview:BadPrintSrv'))
    return, 0
  ENDIF

  oPrinter = oPrintService->GetDevice()
  IF (~OBJ_VALID(oPrinter)) THEN BEGIN
    void = dialog_message(/error, dialog_parent=group_leader, $
                          IDLitLangCatQuery('UI:wdPrintPreview:BadPrinter'))
    return, 0
  ENDIF

  ;; restore landscape setting
  oPrinter->GetProperty, landscape=_landscape
  IF (landscape NE _landscape) THEN $
    oPrinter->SetProperty, landscape=landscape

  oPrinter->GetProperty, dimensions=prtDims, resolution=prtRes

  ;; Size in CM
  prtDimsCM = prtDims * prtRes

  ;; Calculate page sizes
  aspect = prtDims[1]/prtDims[0]
  ;; Some reported screen sizes are logical (due to multi-monitor
  ;; implementations) which cna will report desktops with large X
  ;; sizes. To manage this, take the smallest dimension of screen
  ;; size and use it to construct the max dimension
  IF (szScreen[0] GT szScreen[1]) THEN $ ;; x > y
    szScreen[0] = szScreen[1]*1.2 $
  ELSE $
    szScreen[1] = szScreen[0]*1.2

  IF (landscape) THEN BEGIN
    xSize = fix(szScreen[0]*.4)
    ySize = fix(xSize*aspect)
  ENDIF ELSE BEGIN
    ySize = fix(szScreen[1]*.4)
    xSize = fix(ySize/aspect)
  ENDELSE

  xPage = xSize - 2*s_pgBoarder - s_pgBevel
  yPage = ySize - 2*s_pgBoarder - s_pgBevel

  ;; Create the widget
  wTLB = widget_base(title=IDLitLangCatQuery('UI:wdPrintPreview:Title'), $
                     /column, UNAME="TLB", $
                     /TLB_KILL_REQUEST_EVENTS, $
                     group_leader=group_leader, /modal)

  wButtons = lonarr(4)

  wRow = WIDGET_BASE(wTLB, /ROW)
  
  wDraw = widget_draw(wRow, xsize=xsize, ysize=ysize, $
                      graphics_level=2, uname="DRAW", $
                      /expose, /motion, /button)

  wValueBase = widget_base(wRow, /column, space=5)

  wUnits = widget_droplist(wValueBase, /FLAT, $
                           value=[IDLitLangCatQuery('UI:wdPrintPreview:Inches'), $
                                  IDLitLangCatQuery('UI:wdPrintPreview:Cms')], $
                           uname='UNITS')

  wLabels = LONARR(4)

  w1 = widget_base(wValueBase, /row)
  wLabels[0] = widget_label(w1, /align_left, $
                        value=IDLitLangCatQuery('UI:wdPrintPreview:XMargin')+':')
  wXMargin = widget_text(w1, /editable, xsize=6, value='0.00', $
                         uname='XMARGIN', uvalue='0.00', tab_mode=1, $
                         /kbrd_focus_events)

  w1 = widget_base(wValueBase, /row)
  wLabels[1] = widget_label(w1, /align_left, $
                        value=IDLitLangCatQuery('UI:wdPrintPreview:YMargin')+':')
  wYMargin = widget_text(w1, /editable, xsize=6, value='0.00', $
                         uname='YMARGIN', uvalue='0.00', tab_mode=1, $
                         /kbrd_focus_events)

  w1 = widget_base(wValueBase, /row)
  wLabels[2] = widget_label(w1, /align_left, $
                        value=IDLitLangCatQuery('UI:wdPrintPreview:Width')+':')
  wWidth = widget_text(w1, /editable, xsize=6, value='0.00', $
                       uname='WIDTH', uvalue='0.00', tab_mode=1, $
                       /kbrd_focus_events)

  w1 = widget_base(wValueBase, /row)
  wLabels[3] = widget_label(w1, /align_left, $
                        value=IDLitLangCatQuery('UI:wdPrintPreview:Height')+':')
  wHeight = widget_text(w1, /editable, xsize=6, value='0.00', $
                        uname='HEIGHT', uvalue='0.00', tab_mode=1, $
                        /kbrd_focus_events)
                        
  geom = widget_info(wLabels,/geometry)
  xMax = max(geom.scr_xsize)

  FOR i=0, n_elements(wLabels)-1 DO $
    widget_control, wLabels[i], scr_xsize=xMax
                        
  w1 = widget_base(wValueBase, /row)
  wReset = widget_button(w1, $
                              value=IDLitLangCatQuery('UI:wdPrintPreview:Reset'), $
                              uname="RESET", XSIZE=xMax)

  w1 = widget_base(wValueBase, /row)
  wLabel = widget_label(w1, $
                        value=IDLitLangCatQuery('UI:wdPrintPreview:Orientation'))
  wDList = widget_droplist(w1, /FLAT, $
                           value=[IDLitLangCatQuery('UI:wdPrintPreview:Portrait')+' ', $
                                  IDLitLangCatQuery('UI:wdPrintPreview:Landscp')+' '], $
                           uname="LAYOUT")
  IF (landscape) THEN widget_control,wDList, set_droplist_select=1

  wBBase = widget_base(wValueBase, /row, /nonexclusive, $
                       /align_center)
  wCenter = widget_button(wBBase, $
                          value=IDLitLangCatQuery('UI:wdPrintPreview:Center'), $
                          uname='CENTER')
  wBorder = widget_button(wBBase, $
                          value=IDLitLangCatQuery('UI:wdPrintPreview:Border'), $
                          uname='BORDER', $
                          tooltip=IDLitLangCatQuery('UI:wdPrintPreview:BorderTTip'))
  widget_control, wBorder, /set_button

  wRowBaseLower = widget_base(wTLB, /row, space=5)

  wButtons[0] = widget_button(wRowBaseLower, $
                              value=IDLitLangCatQuery('UI:wdPrintPreview:Help'), $
                              uname="HELP")
  wButtons[1] = widget_button(wRowBaseLower, $
                              value=IDLitLangCatQuery('UI:wdPrintPreview:Setup'), $
                              uname="SETUP")
  wButtons[2] = widget_button(wRowBaseLower, $
                              value=IDLitLangCatQuery('UI:wdPrintPreview:Print'), $
                              uname="PRINT")
  wButtons[3] = widget_button(wRowBaseLower, $
                              value=IDLitLangCatQuery('UI:wdPrintPreview:Close'), $
                              uname="CLOSE", $
                              tooltip=IDLitLangCatQuery('UI:wdPrintPreview:CloseTTip'))

  geom = widget_info(wRow,/geometry)
  xMax = geom.scr_xsize/n_elements(wButtons) - 5
  FOR i=0, n_elements(wButtons)-1 DO $
    widget_control, wButtons[i], scr_xsize=xMax

  ;; launching printerset from a modal widget hangs IDL.
  IF (!version.os_family EQ 'unix') THEN $
    widget_control, wButtons[1], sensitive=0

  widget_control, wTLB, /realize

  widget_control, wDraw, get_value=oDraw

  ;;--------------------------------------------------
  ;; build the Graphic.
  ;;
  oView = obj_new("IDLgrView", color=clrBack)

  ;; Now make the drop highlights
  oModel = obj_new("IdlgrModel")
  oView->Add, oModel
  xDim=xSize/2
  yDim=ySize/2
  recPage = [-xDim + s_pgBoarder, $
             -yDim+s_pgBoarder+s_pgBevel, $
             xDim-s_pgBoarder-s_pgBevel,  $
             yDim-s_pgBoarder]
  xCoord = [0, 1./xDim]
  yCoord = [0, 1./yDim]
  ;; Shadows
  oRShadow = obj_new("IDLgrPolygon", color=clrDrop, $
                     [recPage[2] +s_pgBevel, recPage[2] + s_pgBevel, $
                      recPage[2], recPage[2]],$
                     [ recPage[1]-s_pgBevel, recPage[3]-s_pgBevel, $
                       recPage[3]-s_pgBevel, recPage[1]-s_pgBevel], $
                     xCoord_Conv=xCoord, yCoord_Conv=yCoord,uvalue='')
  oModel->Add, oRShadow
  oBShadow = obj_new("IDLgrPolygon", color=clrDrop, $
                     [recPage[0]+s_pgBevel, recPage[2], $
                      recPage[2], recPage[0]+s_pgBevel], $
                     [recPage[1]-s_pgBevel, recPage[1]-s_pgBevel, $
                      recPage[1], recPage[1]], $
                     xCoord_Conv=xCoord, yCoord_Conv=yCoord,uvalue='')
  oModel->Add, oBShadow

  ;; Paper Rect
  oPage = obj_new("IDLgrPolygon", color=[255,255,255], $
                  [recPage[0], recPage[0], recPage[2], recPage[2]], $
                  [recPage[1], recPage[3], recPage[3], recPage[1]], $
                  xCoord_Conv=xCoord, yCoord_Conv=yCoord, uvalue="")
  oModel->Add, oPage

  oDraw->GetProperty, dimensions=winDims, resolution=winRes

  winDimsCM = [xPage, yPage] * winRes
  winDimsCM = [recPage[2]-recPage[0],recPage[3]-recPage[1]] * winRes
  WinToPrinter = winRes/prtRes ;; convert from window pix to printer pix
  WinPrtRatio = winDimsCM/prtDimsCM ; Convert from Printer CM to Preview CM

  ;; Current layout
  oRaster = oTool->GetService("RASTER_BUFFER")
  srcDimsCM = srcDims * srcRes

  ;; Conversion factors
  SrcToPrinter = srcRes/prtRes
  SrcToPrinterDims = [recPage[2]-recPage[0],recPage[3]-recPage[1]]/prtDims
  SrcToWin     = winRes/srcRes
  oRaster->setProperty, dimensions=srcDims, scale=1.0, xoffset=0, yoffset=0

  status = oRaster->DoWindowCopy(oWinSrc, oWinSrc->GetScene())
  ;; convert to printer size and then scale down to print preview space
  imDims = srcDims * WinPrtRatio

  IF (status NE 0) THEN BEGIN
    status = oRaster->GetData(bits)
;    bits = oTool->_Thumb_Downsize(bits, (srcDims[0] gt srcDims[1]) ? imDims[1] : imDims[0])
    ;; add alpha channel to image
    sz = size(bits,/dimensions)
    newBits = bytarr(4,sz[1],sz[2])
    newBits[0,0,0] = temporary(bits)
    newBits[3,*,*] = 255b

    oImage = obj_new("IDLgrImage", TEMPORARY(newBits), $
                     location=[recPage[0:1],.1], $
                     dimension=imDims, $
                     blend_function=[3,4], $
                     INTERPOLATE=1, $
                     sub_rect=subRect, $
                     xCoord_Conv=xCoord, $
                     yCoord_Conv=yCoord, uvalue="IMAGE")
    oModel->Add,oImage
  ENDIF

  oBorder = obj_new('IDLgrPolyline', color=[255,0,0], alpha_channel=0.5, $
                    xCoord_Conv=xCoord, yCoord_Conv=yCoord, $
                    [recPage[0], recPage[0], recPage[0]+imDims[0], $
                     recPage[0]+imDims[0], recPage[0]], $
                    [recPage[1], recPage[1]+imDims[1], recPage[1]+imDims[1], $
                     recPage[1], recPage[1]], $
                    [.1, .1, .1, .1, .1])
  oModel->add, oBorder

  ;; Scale block
  ScaleOffset = round(imDims + recPage[0:1])

  x = s_pgScaleSize
  oScale = obj_new("IDLgrPolygon", color=[0,0,0], $
                   [0, 0, x, x]+ ScaleOffset[0], [0, x, x, 0]+ ScaleOffset[1], $
                   [.1,.1,.1,.1], $
                   xCoord_Conv=xCoord, yCoord_Conv=yCoord, uvalue="SCALE")
  oModel->add, oScale

  oDraw->SetCurrentCursor, "ARROW"
  ;;    oDraw->DRaw, oView

  oDraw->SetProperty, Graphics_Tree=oView

  ;; some additional needed values
  paperDims = [recPage[2]-recPage[0],recPage[3]-recPage[1]]
  paperRes = prtRes * prtDims / paperDims

  ;; a Big state structure
  state = {oDraw         :        oDraw, $
           oView         :        oView, $
           s_pgBoarder   :        s_pgBoarder, $
           s_pgBevel     :        s_pgBevel, $
           s_pgScaleSize :        s_pgScaleSize, $
           aspect        :        aspect, $
           imAspect : (srcDims[1]*srcRes[1])/(srcDims[0]*srcRes[0]), $
           recPage       :        recPage, $ ;; paper
           pt0           :        [s_pgBoarder, s_pgBoarder+s_pgBevel], $
           ptCurrent     :        [s_pgBoarder, s_pgBoarder+s_pgBevel], $
           ptMouse       :        [0l, 0], $
           oCurrent      :        obj_new(), $ ;;current item for mouse down-up
           ptImage       :        recPage[0:1], $ ;; 0 pt of image, in gr coord
           imDims        :        imDims,$ ;; image dimensions
           ptZero        :        s_pgBoarder+[0,s_pgBevel] , $ ;; in win coord
           ptScale       :        float(imDims+s_pgBoarder+[0,s_pgBevel]),$ ; scale pt
           oImage        :        oImage, $ ;; the image
           mode          :        0, $  ;; horz=0, vert=1
           oRShadow      :        oRShadow, $
           oBShadow      :        oBShadow, $
           oPage         :        oPage,    $
           oBorder       :        oBorder,   $
           oScale        :        oScale,    $
           oPrintService :        oPrintService, $
           oPrintOperation : oPrintOperation, $
           WinPrtRatio   :        WinPrtRatio, $
           SrcToPrinter  :        SrcToPrinter, $
           SrcToPrinterDims  :        SrcToPrinterDims, $
           SrcToWin      :        SrcToWin, $
           srcDims       :        srcDims,  $
           srcRes        :        srcRes,   $
           prtRes        :        prtRes,   $
           paperDims : paperDims, $
           paperRes : paperRes, $
           prtDims : prtDims, $
           wXMargin : wXMargin, $
           wYMargin : wYMargin, $
           wWidth : wWidth, $
           wHeight : wHeight, $
           wUnits : wUnits, $
           wCenter : wCenter, $
           wBorder : wBorder, $
           wDraw         :        wDraw,    $
           wLayout       :        wDList,   $
           landscape     :        landscape,$ ;; in landscape mode?
           oWinSrc       :        oWinSrc $
          }

  pState = ptr_new(/no_copy, state)
  widget_control, wTLB, set_uvalue=pState

  ;; update image to restored settings, if they exist
  IF (print_width && print_height) THEN BEGIN
    ;; update units droplist
    widget_control, wUnits, set_droplist_select=print_units
    void = IDLitwdPrintPreview_ValidateValue(wWidth, set_value=print_width)
    void = IDLitwdPrintPreview_ValidateValue(wHeight, set_value=print_height)
    ;; fake a call to set the scale
    IDLitwdPrintPreview_event, {top:wTLB, id:wWidth}, /init
    IF ~print_center THEN BEGIN
      void = IDLitwdPrintPreview_ValidateValue(wXMargin, set_value=print_xmargin)
      void = IDLitwdPrintPreview_ValidateValue(wYMargin, set_value=print_ymargin)
      ;; fake a call to set the xmargin
      IDLitwdPrintPreview_event, {top:wTLB, id:wXMargin}
      ;; fake a call to set the ymargin
      IDLitwdPrintPreview_event, {top:wTLB, id:wYMargin}
    ENDIF
  ENDIF ELSE BEGIN
    ;; update image transparency in case image is larger than the paper
    IDLitwdPrintPreview_UpdateTransparency, pState
    ;; calculate size of image
    sz = srcDims * srcRes
    ;; convert to inches if necessary
    IF ~widget_info((*pState).wUnits, /droplist_select) THEN $
      sz /= 2.54
    ;; update status bar
    void = IDLitwdPrintPreview_ValidateValue(wWidth, set_value=sz[0])
    ;; fake a call to set the scale
    IDLitwdPrintPreview_event, {top:wTLB, id:wWidth}, /init
  ENDELSE

  if (print_center) then begin
    IDLitwdPrintPreview_CenterImage, pState
    widget_control, wCenter, /set_button
    widget_control, (*pState).wXMargin, sensitive=0
    widget_control, (*pState).wYMargin, sensitive=0
  endif
  
  oDraw->DRaw, oView

  ;; Launch the widget
  xmanager, 'IDLitwdPrintPreview', wTLB, no_block=0

  ptr_Free, pState

  return, 1

END
