; $Id: //depot/idl/releases/IDL_80/idldir/lib/dialog_read_image.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   DIALOG_READ_IMAGE
;
; PURPOSE:
;       This routine creates a GUI dialog for previewing and selecting
;       images to read.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = DIALOG_READ_IMAGE([Filename])
;
;       Result is a 1 if Open was clicked, 0 if Cancel.
;
; INPUTS:
;       [Filename] = a scalar string of the file to read.
;
; OPTIONAL KEYWORDS:
;
;  BLUE - Vector which returns the blue palette (if any)
;
;  DIALOG_PARENT - The widget ID of a widget that calls DIALOG_READ_IMAGE.
;   When this ID is specified, a death of the caller results in the
;       death of the DIALOG_READ_IMAGE dialog.
;
;  FILE - Set this keyword to a named variable to contain the name of
;   the selected file.
;
;  FILTER_TYPE - Set this keyword to a scalar string containing the format
;   type the dialog filter should begin with.  The default is
;   "IMAGE_FILES".  The user can modify the filter unless the
;   FIX_FILTER keyword is set.  Valid values are obtained from the
;   list of supported image types returned from QUERY_IMAGE.  In
;   addition, there are also 2 more special types: IMAGE_FILES, ALL_FILES.
;
;  FIX_FILTER - When this keyword is set, only files that satisfy the filter
;   can be selected.  The user has no ability to modify the filter
;   and the filter is grayed out.
;
;  GET_PATH = Set this keyword to a named variable in which the path of
;   the selection is returned.
;
;  GREEN - Vector which returns the green palette (if any)
;
;  PATH - Set this keyword to a string that contains the initial path
;   from which to select files.  If this keyword is not set,
;   the current working directory is used.
;
;  QUERY - Set this keyword to a named variable that will return the
;   QUERY_IMAGE structure associated with the returned image.
;
;  RED - Vector which returns the red palette (if any)
;
;  TITLE - Set this keyword to a scalar string to be used for the dialog
;   title.  If not specified, the default title is "Select Image File".
;
; OUTPUTS:
;   This function returns the selected image array.
;
; EXAMPLE:
;       myImage = DIALOG_READ_IMAGE()
;
; MODIFICATION HISTORY:
;   Written by: Scott Lasica, July, 1998
;   Modified: CT, RDI, July 2000: Cleaned up the layout,
;                  resize now works, added GET_PATH keyword.
;                  Force to be MODAL, even if no DIALOG_PARENT.
;-
;

pro dri_bitmap_define, leftFull, left, right, rightFull

  COMPILE_OPT HIDDEN, STRICTARR

  leftFull = [                               $
               [000B, 000B],                   $
               [000B, 000B],                   $
               [000B, 000B],                   $
               [004B, 000B],                   $
               [068B, 000B],                   $
               [100B, 000B],                   $
               [052B, 000B],                   $
               [252B, 063B],                   $
               [252B, 063B],                   $
               [052B, 000B],                   $
               [100B, 000B],                   $
               [068B, 000B],                   $
               [004B, 000B],                   $
               [000B, 000B],                   $
               [000B, 000B],                   $
               [000B, 000B]                    $
             ]

  left = [                               $
           [000B, 000B],                   $
           [000B, 000B],                   $
           [000B, 000B],                   $
           [000B, 000B],                   $
           [064B, 000B],                   $
           [096B, 000B],                   $
           [048B, 000B],                   $
           [248B, 063B],                   $
           [248B, 063B],                   $
           [048B, 000B],                   $
           [096B, 000B],                   $
           [064B, 000B],                   $
           [000B, 000B],                   $
           [000B, 000B],                   $
           [000B, 000B],                   $
           [000B, 000B]                    $
         ]

  right = [                               $
            [000B, 000B],                   $
            [000B, 000B],                   $
            [000B, 000B],                   $
            [000B, 000B],                   $
            [000B, 002B],                   $
            [000B, 006B],                   $
            [000B, 012B],                   $
            [252B, 031B],                   $
            [252B, 031B],                   $
            [000B, 012B],                   $
            [000B, 006B],                   $
            [000B, 002B],                   $
            [000B, 000B],                   $
            [000B, 000B],                   $
            [000B, 000B],                   $
            [000B, 000B]                    $
          ]

  rightFull = [                               $
                [000B, 000B],                   $
                [000B, 000B],                   $
                [000B, 000B],                   $
                [000B, 032B],                   $
                [000B, 034B],                   $
                [000B, 038B],                   $
                [000B, 044B],                   $
                [252B, 063B],                   $
                [252B, 063B],                   $
                [000B, 044B],                   $
                [000B, 038B],                   $
                [000B, 034B],                   $
                [000B, 032B],                   $
                [000B, 000B],                   $
                [000B, 000B],                   $
                [000B, 000B]                    $
              ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro dri_readImage, index
  common dri_common, filenameRet, image_data, query_info, $
    dri_r, dri_g, dri_b, done_type, $
    decompose, orig_r, orig_g, orig_b, orig_device, dri_cached
  COMPILE_OPT HIDDEN, STRICTARR

  image_data = READ_IMAGE(filenameRet, r, g, b, IMAGE_INDEX=index-1)
  dri_cached = 1
  if (N_ELEMENTS(r) gt 0)then begin
    dri_r = r
    dri_g = g
    dri_b = b
  endif else begin  ; reset to no color table
    dri_r = -1
    dri_g = -1
    dri_b = -1
  endelse
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro dri_drawWin, win, type, index, labels, parent

  common dri_common, filenameRet, image_data, query_info, $
    dri_r, dri_g, dri_b, done_type, $
    decompose, orig_r, orig_g, orig_b, orig_device, dri_cached

  COMPILE_OPT HIDDEN, STRICTARR

  catch,error_status
  if (error_status ne 0) then begin
    CATCH, /CANCEL
    result=DIALOG_MESSAGE(!ERROR_STATE.MSG,/ERROR,DIALOG_PARENT=parent)
    MESSAGE, /RESET
    erase,win
    WSET, oldWin
    device,decompose=decompose
    return
  endif

  device,decompose=0
  oldWin = !D.WINDOW
  WSET, win
    loadct, 0, /SILENT
  erase,win

  ; Be sure to use the IMAGE_INDEX for multiple-image files.
  success = QUERY_IMAGE(filenameRet, query_info, IMAGE_INDEX=index-1)

  if success then begin
     WIDGET_CONTROL, labels.fmtLabel, SET_VALUE=query_info.TYPE
     WIDGET_CONTROL, labels.chnLabel, SET_VALUE=STRTRIM(query_info.CHANNELS,2)
     WIDGET_CONTROL, labels.widLabel, SET_VALUE=STRTRIM(query_info.DIMENSIONS[0],2)
     WIDGET_CONTROL, labels.hgtLabel, SET_VALUE=STRTRIM(query_info.DIMENSIONS[1],2)
     if (query_info.HAS_PALETTE) then palLabel = 'Yes' else palLabel = 'No'
     WIDGET_CONTROL, labels.palLabel, SET_VALUE=palLabel
     tname = SIZE(FIX(1,TYPE=query_info.PIXEL_TYPE), /TNAME)
     WIDGET_CONTROL, labels.pixLabel, SET_VALUE=tname
  endif

  if (type eq 2) OR (NOT success) then begin
    device,decompose=decompose
    return
  endif

; now load the image
  dri_readImage, index
  img = image_data  ; make a temporary copy
  if (N_ELEMENTS(img) eq 1) then begin
    if (img[0] eq -1) then begin
        device,decompose=decompose
        return
    endif
  endif
  pixLabel = SIZE(img, /TNAME)
  WIDGET_CONTROL, labels.pixLabel, SET_VALUE=pixLabel


  ;; Let's make sure it's not a 1,n,m image
    img = REFORM(img, /OVERWRITE)
    ndims = SIZE(img,/n_dimensions)

    case ndims of
        1: img = REFORM(img,1,1)
        2: if (query_info.TYPE eq 'PPM') then $ ; Rotate so it's right side up
                img = REVERSE(ROTATE(TEMPORARY(img), 2))
        3: begin
            dims = size(img,/dimensions)

            ; Remove alpha or "higher" channels
            IF (dims[0] LE 2) THEN BEGIN
                img = REFORM(img[0,*,*])   ; keep gray only
            ENDIF ELSE BEGIN
                IF (dims[0] GT 3) THEN img = img[0:2,*,*]  ; keep RGB only
                ;; Rotate so it's right side up
                if (query_info.TYPE eq 'PPM') then begin
                    img[0,*,*] = REVERSE(ROTATE(REFORM(img[0,*,*]), 2))
                    img[1,*,*] = REVERSE(ROTATE(REFORM(img[1,*,*]), 2))
                    img[2,*,*] = REVERSE(ROTATE(REFORM(img[2,*,*]), 2))
                endif
            ENDELSE
            end
        else: GOTO, skip
    endcase


; find dimensions
    ndims = SIZE(img,/n_dimensions)
    dims = size(img,/dimensions)
    dim1 = dims[(ndims EQ 3)]   ; dims[0] or dims[1]
    dim2 = dims[1+(ndims EQ 3)] ; dims[1] or dims[2]

; find scale so image fits window size
    winSize = [!D.X_SIZE, !D.Y_SIZE]
    scale = MIN((DOUBLE(winSize)/[dim1,dim2]) < 1)

    if ((type ne 1) AND (MIN(dri_r) ge 0)) then tvlct, dri_r, dri_g, dri_b

    case ndims of
        2: begin
            if (scale ne 1) then $
                img = CONGRID(img,fix(scale*dim1),fix(scale*dim2))
        end
        3: begin
            if (scale ne 1) then $
                img = CONGRID(TEMPORARY(img), 3, fix(scale*dim1),fix(scale*dim2))
            CASE type OF
                0: BEGIN
                    img = COLOR_QUAN(img, 1, $
                        tmp_r, tmp_g, tmp_b, /DITHER)
                    tvlct, tmp_r, tmp_g, tmp_b
                    END
                1: BEGIN
                    img = (BYTE(.299*img[0,*,*] + .587*img[1,*,*] + $
                        .114*img[2,*,*]) < 255)
                    END
                ELSE: ; shouldn't get here
            ENDCASE
        end
        else:
    endcase
    ; No color table, see if we need to scale the grayscale range.
    if (MIN(dri_r) eq -1) then begin
        if (MAX(img) le 15) then img = BYTSCL(img)
    endif
    TV, img
skip:
  WSET, oldWin
  device,decompose=decompose
end

pro dri_clearWin, window, tlbStruct

    COMPILE_OPT HIDDEN, STRICTARR
  common dri_common, filenameRet, image_data, query_info, $
    dri_r, dri_g, dri_b, done_type, $
    decompose, orig_r, orig_g, orig_b, orig_device, dri_cached

    filenameRet = ''
    image_data = -1
    query_info = -1
    dri_r = -1
    dri_g = -1
    dri_b = -1
    done_type = 0

    erase, window
    WIDGET_CONTROL, tlbStruct.labels.fmtLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.labels.chnLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.labels.widLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.labels.hgtLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.labels.palLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.labels.pixLabel, SET_VALUE=''
    WIDGET_CONTROL, tlbStruct.buttons.lf, SENSITIVE=0
    WIDGET_CONTROL, tlbStruct.buttons.l, SENSITIVE=0
    WIDGET_CONTROL, tlbStruct.buttons.r, SENSITIVE=0
    WIDGET_CONTROL, tlbStruct.buttons.rf, SENSITIVE=0
    WIDGET_CONTROL, tlbStruct.numText, SET_VALUE='0'
    WIDGET_CONTROL, tlbStruct.numLab, SET_VALUE='0'
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Event handler
pro dri_event, ev

  common dri_common, filenameRet, image_data, query_info, $
    dri_r, dri_g, dri_b, done_type, $
    decompose, orig_r, orig_g, orig_b, orig_device, dri_cached

  COMPILE_OPT HIDDEN, STRICTARR

  catch,error_status
  if (error_status ne 0) then begin
    CATCH, /CANCEL
    WIDGET_CONTROL, tlbStruct.preDraw, GET_VALUE=preDraw
    LOADCT, 0, /SILENT
    dri_clearWin, preDraw, tlbStruct
    result=DIALOG_MESSAGE(!ERROR_STATE.MSG,/ERROR,DIALOG_PARENT=ev.top)
    MESSAGE, /RESET
    WIDGET_CONTROL, ev.top, SET_UVALUE=tlbStruct
    return
  endif

  WIDGET_CONTROL, ev.top, GET_UVALUE=tlbStruct

    CASE TAG_NAMES(ev, /STRUCTURE_NAME) OF
    'WIDGET_KILL_REQUEST': BEGIN
        done_type = 0L
        WIDGET_CONTROL, ev.top, /destroy
        return
        end
    'WIDGET_BASE': BEGIN  ; base resize
        WIDGET_CONTROL, tlbStruct.preDraw, GET_UVALUE=baseSize
        ; change in size in X and Y
        dx = ev.x - baseSize[0]
        dy = ev.y - baseSize[1]
        ; old drawing window size
        geom = WIDGET_INFO(tlbStruct.preDraw,/GEOMETRY)
        ; new drawing window size
        xsize1 = (geom.xsize + dx) > 100
        ysize1 = (geom.ysize + dy) > 100
        WIDGET_CONTROL,ev.handler,UPDATE=0
        WIDGET_CONTROL,tlbStruct.preDraw,DRAW_XSIZE=xsize1,DRAW_YSIZE=ysize1
        WIDGET_CONTROL,ev.handler,/UPDATE
        uval = 'reDraw'
        END
    ELSE:  WIDGET_CONTROL, ev.id, GET_UVALUE=uval
    ENDCASE

; update the base size in case it's changed
    WIDGET_CONTROL,ev.handler,TLB_GET_SIZE=newSize
    WIDGET_CONTROL, tlbStruct.preDraw, SET_UVALUE=newSize


    imageNum = 0

  case uval of
    'filesel': begin
      WIDGET_CONTROL, /HOURGLASS
      filenameRet = ev.value
      if (ev.done gt 0) then begin
        done_type = (ev.done eq 2) ? 0L : 1L
        ; make sure the image has already been loaded into common vars
        IF done_type THEN BEGIN
          IF (NOT dri_cached) THEN BEGIN
            WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=numText
            imageNum = FIX(numText[0])
            ; preview must be off, so load the image
            dri_readImage, imageNum
          ENDIF
        ENDIF
        WIDGET_CONTROL, ev.top, /destroy
        return
      endif

        if (QUERY_IMAGE(filenameRet, NUM_IMAGES=nImages)) then begin
            sens = (nImages gt 1)
            WIDGET_CONTROL, tlbStruct.buttons.lf, SENSITIVE=sens
            WIDGET_CONTROL, tlbStruct.buttons.l, SENSITIVE=sens
            WIDGET_CONTROL, tlbStruct.buttons.r, SENSITIVE=sens
            WIDGET_CONTROL, tlbStruct.buttons.rf, SENSITIVE=sens
            WIDGET_CONTROL, tlbStruct.numText, SET_VALUE='1', SENSITIVE=sens
            WIDGET_CONTROL, tlbStruct.numLab, SET_VALUE=STRTRIM(nImages,2)
            imageNum = 1
            dri_cached = 0
        endif else BEGIN
            WIDGET_CONTROL, tlbStruct.preDraw, GET_VALUE=preDraw
            dri_clearWin, preDraw, tlbStruct
        ENDELSE
    end
    'numText': begin
      WIDGET_CONTROL, /HOURGLASS
      if (QUERY_IMAGE(filenameRet, NUM_IMAGES=nImages)) then begin
        WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=val
        if (FIX(val[0]) gt nImages) then $
          WIDGET_CONTROL, tlbStruct.numText, $
              SET_VALUE=STRTRIM(nImages,2)
          imageNum = FIX(val[0])
      endif
    end
    'leftFullBut': begin
      WIDGET_CONTROL, /HOURGLASS
      WIDGET_CONTROL, tlbStruct.numText, SET_VALUE='1'
      imageNum = 1
    end
    'leftBut': begin
      WIDGET_CONTROL, /HOURGLASS
      WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=numText
      if (LONG(numText[0]) gt 1) then begin
        numText = STRTRIM(FIX(numText[0])-1,2)
        WIDGET_CONTROL, tlbStruct.numText, $
           SET_VALUE=numText
        imageNum = FIX(numText)
      endif
    end
    'rightBut': begin
      WIDGET_CONTROL, /HOURGLASS
      if (not QUERY_IMAGE(filenameRet, NUM_IMAGES=nImages)) then begin
        MESSAGE,'Invalid image file: '+filenameRet
        return
      endif
      WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=numText
      if (LONG(numText[0]) lt nImages) then begin
        numText = STRTRIM(FIX(numText[0])+1,2)
        WIDGET_CONTROL, tlbStruct.numText, $
            SET_VALUE=numText
        imageNum = FIX(numText)
      endif
    end
    'rightFullBut': begin
      WIDGET_CONTROL, /HOURGLASS
      if (QUERY_IMAGE(filenameRet, NUM_IMAGES=nImages)) then begin
        WIDGET_CONTROL, tlbStruct.numText, SET_VALUE=STRTRIM(nImages,2)
        imageNum = nImages
      endif
    end
    'preBut': begin
      WIDGET_CONTROL, /HOURGLASS
      tlbStruct.preview = ev.index
      WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=numText
      imageNum = FIX(numText[0])
    end
    'reDraw': begin
      WIDGET_CONTROL, tlbStruct.numText, GET_VALUE=numText
      imageNum = FIX(numText[0])
    end
    else: begin
      MESSAGE,'Unknown event.',/ERROR
    end
  endcase

    IF (imageNum GT 0) AND (tlbStruct.active) THEN BEGIN
        WIDGET_CONTROL, tlbStruct.preDraw, GET_VALUE=preDraw
        dri_drawWin, preDraw, tlbStruct.preview, imageNum, $
            tlbStruct.labels, ev.top
    ENDIF

  WIDGET_CONTROL, ev.top, SET_UVALUE=tlbStruct

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function DIALOG_READ_IMAGE, filename, $
                            RED = red, $
                            GREEN = green, $
                            BLUE = blue, $
                            DIALOG_PARENT = parentIn, $
                            FILE = fileRet, $
                            GET_PATH = get_path, $
                            FILTER_TYPE = filterIn, $
                            FIX_FILTER = fixf, $
                            PATH = pathIn, $
                            QUERY = query, $
                            TITLE = titleIn, $
                            IMAGE = image

COMPILE_OPT strictarr
  common dri_common, filenameRet, image_data, query_info, $
    dri_r, dri_g, dri_b, done_type, $
    decompose, orig_r, orig_g, orig_b, orig_device, dri_cached

  ON_ERROR, 2  ; return to caller
  CATCH, errorStatus
  if (errorStatus ne 0) then begin
    CATCH, /CANCEL
    if (N_ELEMENTS(base) gt 0) then begin
        if WIDGET_INFO(base, /VALID) then WIDGET_CONTROL, base, /DESTROY
    endif
    MESSAGE, !ERROR_STATE.msg, /NONAME
  endif

;  if (((!D.FLAGS and 256) eq 0) or ((!D.FLAGS and 65536) eq 0)) then $
;    MESSAGE, 'Graphics device does not support widgets.'

  TVLCT,orig_r,orig_g,orig_b,/GET


; See if we need to switch graphics devices.
  case STRUPCASE(!VERSION.OS_FAMILY) of
    'WINDOWS': newDevice = 'WIN'
    'UNIX': newDevice = 'X'
    'MACOS': newDevice = 'MAC'
    else: MESSAGE, 'Unknown OS_FAMILY.'
  endcase
  orig_device = ''
  if (!D.NAME ne newDevice) then begin
    orig_device = !D.NAME
    SET_PLOT, newDevice
  endif

  ; Only do the GET_DECOMPOSED once we know it is a useful graphics device.
  DEVICE, GET_DECOMPOSED=decompose

  filenameRet = ''
  image_data = -1
  query_info = -1
  dri_r = -1
  dri_g = -1
  dri_b = -1
  done_type = 0
  dri_cached = 0

  title = (N_ELEMENTS(titleIn) GT 0)  ? STRING(titleIn) : 'Select Image File'
  IF (N_ELEMENTS(pathIn) GT 0) THEN path = pathIn

  has_parent = (N_ELEMENTS(parentIn) gt 0)
  if has_parent then begin
      parent = parentIn[0]
      if (not WIDGET_INFO(parent, /VALID_ID)) then $
        noth=DIALOG_MESSAGE('Invalid widget identifier.',/ERROR)
  endif else begin
    parent = WIDGET_BASE(TITLE=title, MAP=0)   ; create a dummy parent base
  endelse

  base = WIDGET_BASE(TITLE=title, /COLUMN, GROUP_LEADER=parent, $
    /FLOATING, /MODAL, $
    /TLB_KILL_REQUEST_EVENTS, /TLB_SIZE_EVENTS, UNAME='DRI_TLB')


  dri_bitmap_define, leftFull, left, right, rightFull

  if (N_ELEMENTS(filterIn) GT 0) then begin
      if NOT ARRAY_EQUAL(SIZE(filterIn), SIZE('')) then begin
        noth=DIALOG_MESSAGE('Scalar string required in this context: FILTER',/ERROR)
      endif
      filter = filterIn
  endif

  filesel = CW_FILESEL(base, FILENAME=filename, FILTER=filter, $
                       FIX_FILTER=fixf, PATH=path, UVALUE='filesel',$
                       /IMAGE_FILTER, UNAME='DRI_CW_FILESEL')


  ;; The preview base
  preBase = WIDGET_BASE(base, /ROW, /FRAME)

  column1 = WIDGET_BASE(preBase, /COLUMN)
  preview = WIDGET_BASE(column1, /ROW)
  preBut = WIDGET_DROPLIST(preview, VALUE=['Color','Grayscale','None'], $
    UVALUE='preBut', TITLE='Preview:')

  infoCol = WIDGET_BASE(column1, /ROW)
  txt1Col = WIDGET_BASE(infoCol, /COLUMN)
  label = WIDGET_LABEL(txt1Col, VALUE='Format:',/ALIGN_RIGHT)
  label = WIDGET_LABEL(txt1Col, VALUE='Channels:',/ALIGN_RIGHT)
  label = WIDGET_LABEL(txt1Col, VALUE='Width:',/ALIGN_RIGHT)
  label = WIDGET_LABEL(txt1Col, VALUE='Height:',/ALIGN_RIGHT)
  label = WIDGET_LABEL(txt1Col, VALUE='Pixel:',/ALIGN_RIGHT)
  label = WIDGET_LABEL(txt1Col, VALUE='Palette:',/ALIGN_RIGHT)

  txt2Col = WIDGET_BASE(infoCol, /COLUMN)
  fmtLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')
  chnLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')
  widLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')
  hgtLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')
  pixLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')
  palLabel = WIDGET_LABEL(txt2Col, /ALIGN_LEFT, $
    /DYNAMIC_RESIZE, VALUE='')


; Draw window and image selection buttons
  txtDrawCol = WIDGET_BASE(preBase, /COLUMN, /BASE_ALIGN_CENTER)

  preDraw = WIDGET_DRAW(txtDrawCol)

  num2Base = WIDGET_BASE(txtDrawCol, /ROW, XOFFSET=20)
  leftFullBut = WIDGET_BUTTON(num2Base, VALUE=leftFull, $
    UVALUE='leftFullBut', UNAME='DRI_LEFT_FULL')
  leftBut = WIDGET_BUTTON(num2Base, VALUE=left, $
    UVALUE='leftBut', UNAME='DRI_LEFT')
  rightBut = WIDGET_BUTTON(num2Base, VALUE=right, $
    UVALUE='rightBut', UNAME='DRI_RIGHT')
  rightFullBut = WIDGET_BUTTON(num2Base, VALUE=rightFull, $
    UVALUE='rightFullBut', UNAME='DRI_RIGHT_FULL')

  ;; Now for the image number selection
  numBase = WIDGET_BASE(txtDrawCol, /ROW)
  label = WIDGET_LABEL(numBase, VALUE='Image ')
  numText = WIDGET_TEXT(numBase, VALUE='0', UVALUE='numText', XSIZE=2, $
                        /EDITABLE, SENSITIVE=0, UNAME='DRI_IMAGE_NUMBER')
  label = WIDGET_LABEL(numBase, VALUE='of')
  numLab = WIDGET_LABEL(numBase, VALUE='', $
    /DYNAMIC_RESIZE, UNAME='DRI_NUM_IMAGES')


  WIDGET_CONTROL, base, /REALIZE
  WIDGET_CONTROL,base,TLB_GET_SIZE=baseSize
  WIDGET_CONTROL, preDraw, SET_UVALUE=baseSize

  if (N_ELEMENTS(filename) gt 0) then begin
      if (not QUERY_IMAGE(filename, NUM_IMAGES=nImages)) then begin
        WIDGET_CONTROL, leftFullBut, SENSITIVE=0
        WIDGET_CONTROL, leftBut, SENSITIVE=0
        WIDGET_CONTROL, rightBut, SENSITIVE=0
        WIDGET_CONTROL, rightFullBut, SENSITIVE=0
      endif else begin
        if (nImages le 1) then begin
          WIDGET_CONTROL, leftFullBut, SENSITIVE=0
          WIDGET_CONTROL, leftBut, SENSITIVE=0
          WIDGET_CONTROL, rightBut, SENSITIVE=0
          WIDGET_CONTROL, rightFullBut, SENSITIVE=0
        endif
      endelse
  endif else begin
      WIDGET_CONTROL, leftFullBut, SENSITIVE=0
      WIDGET_CONTROL, leftBut, SENSITIVE=0
      WIDGET_CONTROL, rightBut, SENSITIVE=0
      WIDGET_CONTROL, rightFullBut, SENSITIVE=0
  endelse


  tlbStruct = {dri_Struct, $
               filesel: filesel, $
               numText: numText, $
               numLab: numLab, $
               preDraw: preDraw, $
               preview: 0, $
               active: 1, $
               buttons: {dri_buttons, $
                         lf: leftFullBut,$
                         l: leftBut, $
                         r: rightBut, $
                         rf: rightFullBut}, $
               labels:  {dri_labels, $
                         fmtLabel: fmtLabel, $
                         chnLabel: chnLabel, $
                         widLabel: widLabel, $
                         hgtLabel: hgtLabel, $
                         pixLabel: pixLabel, $
                         palLabel: palLabel} $
  }

  WIDGET_CONTROL, base, SET_UVALUE = tlbStruct

  XMANAGER, 'DIALOG_READ_IMAGE', base, EVENT_HANDLER='dri_event', $
    GROUP_LEADER=parent

  IF (NOT has_parent) THEN WIDGET_CONTROL, parent, /DESTROY

  DEVICE, DECOMPOSE=decompose
  if (orig_device ne '') then begin
    SET_PLOT, orig_device
  endif

  TVLCT,orig_r,orig_g,orig_b

  IF (done_type EQ 0) THEN BEGIN  ; user hit "Cancel" or destroyed widget
    filenameRet = ''
    image_data = -1
    query_info = -1
    dri_r = -1
    dri_g = -1
    dri_b = -1
  ENDIF

; find the file path
  get_path = (filenameRet EQ '') ? '' : $
    STRMID(filenameRet,0, STRPOS(filenameRet,PATH_SEP(),/REVERSE_SEARCH)+1)

; assign the other variables
  fileRet = filenameRet
  red = dri_r
  green = dri_g
  blue = dri_b
  query = query_info
  image = image_data

  return, done_type
end
