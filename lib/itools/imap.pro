; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/imap.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iMap
;
; PURPOSE:
;   Implements the iMap wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iMap[, Image][, X, Y]
;   or
;   iMap[, Z] [, X, Y], /CONTOUR
;
; INPUTS:
;   See iImage for a description of the Image, X, Y arguments.
;   If /CONTOUR is set see iContour for a description of
;       the Z, X, Y arguments.
;
; KEYWORD PARAMETERS:
;   CONTOUR: Set this keyword to create a Contour visualization from
;       the supplied data. By default, an Image visualization is created.
;
;   See iImage  and iContour for list of available keywords.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Feb 2004
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro iMap, parm1, parm2, parm3, parm4, $
    DEBUG=debug, $
    CONTOUR=doContour, $
    GEOTIFF=geotiff, $
    RGB_TABLE=rgbTableIn, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    title = 'IDL iMap'
    toolname = 'Map Tool'

    ; Handle filename parameter
    if (SIZE(parm1, /TNAME) eq 'STRING' && ~KEYWORD_SET(doContour)) then begin
      filenameTmp = parm1
      iOpen, filenameTmp, parm1, rbgTableIn, GEOTIFF=geotiff, _EXTRA=_extra
      ; We might have just opened an ISV file instead of returning data.
      ; If so, then we are done.
      if (ARRAY_EQUAL(parm1, 1b, /NO_TYPECONV)) then begin
        parm1 = filenameTmp
        return
      endif
    endif
    
    ; Look for our special shapefile input data.
    isShapeFile = SIZE(parm1,/TYPE) eq 11 && Obj_Isa(parm1[0], 'IDLffShape')
    
    ; Swallow the shapefile parameter (we will handle it below).
    nparams = isShapeFile ? 0 : N_PARAMS()
    
    if KEYWORD_SET(doContour) then begin

        case (nparams) of
        0: iContour, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        1: iContour, parm1, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        2: iContour, parm1, parm2, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        3: iContour, parm1, parm2, parm3, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        endcase

    endif else begin

        case (nparams) of
        0: iImage, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        1: iImage, parm1, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        2: iImage, parm1, parm2, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        3: iImage, parm1, parm2, parm3, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        4: iImage, parm1, parm2, parm3, parm4, $
            WINDOW_TITLE=title, TOOLNAME=toolname, RGB_TABLE=rgbTableIn, $
            GEOTIFF=geotiff, _EXTRA=_extra
        endcase

    endelse

    ; Insert data from a shapefile object.
    if (isShapeFile) then begin
      parm1[0]->GetProperty, FILENAME=file
      ; If our shapefile actually came in from a file, then
      ; destroy the temporary object so it doesn't leak.
      if (SIZE(filenameTmp, /TNAME) eq 'STRING') then begin
        OBJ_DESTROY, parm1
      endif
      
      it = iGetCurrent(TOOL=oTool)
      ; Temporarily use the Insert->Map->Continents operation.
      oper = 'Operations/Insert/Map/Continents'
      oDesc = oTool->GetByIdentifier(oper)

      if (Obj_Valid(oDesc)) then begin
        oOp = oDesc->GetObjectInstance()
        oOp->GetProperty, NAME=name

        shapeName = FILE_BASENAME(file, '.shp')
        oOp->SetProperty, NAME=shapeName, SHAPEFILE=file
        oCmd = oOp->DoAction(oTool)
        OBJ_DESTROY, oCmd   ; not undoable
        
        ; Restore our Insert->Map->Continents operation.
        oOp->SetProperty, NAME=name, SHAPEFILE=''
      endif
    endif
    
    ; Reset filename parameter
    if (SIZE(filenameTmp, /TNAME) eq 'STRING') then begin
      parm1 = filenameTmp
    endif

end


