; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvwritefile__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool service for file writing.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitsrvWriteFile object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitsrvWriteFile::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if(self->_IDLitsrvReadWrite::Init(_EXTRA=_SUPER) eq 0)then $
      return, 0

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor of the IDLitsrvWriteFile object.
;
; Arguments:
;   None.
;
;pro IDLitsrvWriteFile::Cleanup
;    compile_opt idl2, hidden
;    self->_IDLitsrvReadWrite::Cleanup
;end

;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::_FindWritersByType
;;
;; Purpose:
;;   Retrieve a list of writers using their type
;;
;; Parameters:
;;  Type  - the type(s) to match
;;
;;  oDesc - The descriptor list
;;
;;  count  - The number of returned items.
function IDLitsrvWriteFile::_FindWritersByType, types, oDesc, count=count
   compile_opt hidden, idl2

   count=0

   nt = N_ELEMENTS(types)

   ; just loop and do a type match check
   for i=0, n_elements(oDesc)-1 do begin
        oDesc[i]->GetProperty, TYPE=objType
        ; Always allow a null type.
        if (objType[0] ne '') then begin
            for j=0,nt-1 do begin
                ; Found a match. Stop looking.
                if (MAX(STRCMP(objType, types[j], /FOLD_CASE)) eq 1) then $
                    break
            endfor
            ; Didn't find a match?
            if (j eq nt) then $
                continue
        endif

        ; Add to list
        oWriters = (count eq 0 ? oDesc[i] : [oWriters, oDesc[i]])
        count++

   endfor

   return, count gt 0 ? oWriters : obj_new()

end


;;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::GetWritersByType
;;
;; Purpose:
;;   Return the ids of writers given a specific type.
;;
;; Parameters:
;;   type - The type to check against
;;
;; Keywords:
;;   count  - the number of ids returned.
;;
;; Return Value:
;;   identifiers fo writes that match the given type.
;;
function IDLitsrvWriteFile::GetWritersByType, type, count=count
   compile_opt hidden, idl2
   oTool = self->GetTool()

   oDesc = oTool->GetFileWriter(count=count,/all)
   if(count eq 0)then $
     return, ''
   oDesc = self->_FindWritersByType(type, oDesc, count=count)
   if(count eq 0)then $
     return, ''

   idRet = strarr(count)
   for i=0, count-1 do $
     idRet[i] = oDesc[i]->GetFullIdentifier()

   return, idRet
end

;;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::_GetDescriptors
;;
;; Purpose:
;;    Return the list of descriptors to the  callee for the specified
;;    writers. This is used by the super-class to peform various
;;    actions.
;;
;; parameters:
;;    None.
;;
;; Keywords:
;;   COUNT  - Return the number of items returned.
;;
;;   SYSTEM - Include the system file formats.
;;
function IDLitsrvWriteFile::_GetDescriptors, system=system, count=count
   compile_opt hidden, idl2

   ;; Get all the writers
   oTool = self->GetTool()
   oDesc = oTool->GetFileWriter( count=count, /all)
   iMatch =-1
   if(~keyword_set(system))then begin
       ;; we need to take out the system writer
       for i=0, count-1 do begin
           oWriter = oDesc[i]->GetObjectInstance()
           tmpExt = oWriter->GetFileExtensions(count=nEXT)
           oDesc[i]->ReturnObjectInstance, oWriter
           if(strcmp(tmpExt[0], "isv", /fold_case) eq 1)then begin
               iMatch = i
               break
           endif
       endfor
       if(iMatch gt -1)then begin
           dex = where(indgen(count) ne iMatch, count)
           if(count gt 0)then $
             oDesc = oDesc[dex] $
           else oDesc = obj_new()
       endif
   endif
   return, oDesc
end

;-------------------------------------------------------------------------
; IDLitsrvWriteFile::GetFilterListByType
;
; Purpose:
;  Return an array of the file extensions that support
;  the given data type
;
; Result:
;   String array of extensions
;
; Arguments:
;   Type  - the data type to match
;
; Keywords:
;   COUNT   - The number of extensions returned.
;
function IDLitsrvWriteFile::GetFilterListByType, type, COUNT=COUNT

    compile_opt idl2, hidden

    oTool = self->GetTool()

    oWriterDesc = oTool->GetFileWriter( count=nWriters, /all)
    oWriterDesc = self->_FindWritersByType(type, oWriterDesc, count=nWriters)

    if(nWriters gt 0)then begin
      self->BuildExtensions, oWriterDesc, sExten, sFilter, sID, /WRITERS
      sFilter[*,1] += ' (' + sFilter[*,0] + ')'
    endif else begin
      sFilter = ''
    endelse

    count = N_ELEMENTS(sFilter)/2

    return, sFilter
end


;---------------------------------------------------------------------------
; Purpose:
;  Given a filename, will return the identifier of writers capable of
;  handling the given file.
;
;  First this system searches file extensions. If that fails, query
;  routines are used.
;
; Arguments:
;   strFile   - The filename to test
;
; Keywords:
;   None.
;
function IDLitsrvWriteFile::FindMatchingWriter, strFile

    compile_opt idl2, hidden

    filename = strtrim(strFile,2)
    if (filename eq '') then $
        return, '' ; invalid

    ; Check extensions
    iDot = STRPOS(filename, '.', /REVERSE_SEARCH)
    if (iDot gt 0) then begin
        oDesc = self->_GetDescriptors(/SYSTEM, COUNT=count)
        if (count gt 0) then begin
            self->BuildExtensions, oDesc, fileExt, sFilterList, sIDs
            count = N_ELEMENTS(fileExt)
        endif
        if (count gt 0) then begin
            fileSuffix = STRUPCASE(STRMID(filename, iDot + 1))
            dex = where(fileSuffix eq strupcase(fileExt), nMatch)
            return, (nMatch gt 0 ? sIDs[dex[0]] : '')
        endif
    endif

    return, ''

end


;---------------------------------------------------------------------------
; Trim an image down by removing any borders.
;
; Image is a [3,n,m] byte array.
;
pro IDLitsrvWriteFile::TrimImage, image, border

  compile_opt idl2, hidden
  on_error, 2
  
  dims = SIZE(image, /DIM)

  ; Lower left corner pixel.
  ll = image[*,0,0]

  ; All 4 corners must be the same color.
  if ~(ARRAY_EQUAL(ll, image[*,-1,0]) && $
    ARRAY_EQUAL(ll, image[*,-1,-1]) && $
    ARRAY_EQUAL(ll, image[*,0,-1])) then return

  ; Convert corner pixel to RGB long64.
  rgb = ll[0]*65536LL + ll[1]*256LL + ll[2]

  ; Sum along the X dimension, convert to RGB long.
  imSumX = TOTAL(image, 2, /INTEGER)
  imSumX = imSumX[0,*]*65536LL + imSumX[1,*]*256LL + imSumX[2,*]
  ; Sum along the Y dimension, convert to RGB long.
  imSumY = TOTAL(image, 3, /INTEGER)
  imSumY = imSumY[0,*]*65536LL + imSumY[1,*]*256LL + imSumY[2,*]

  trimY = WHERE(imSumX ne dims[1]*rgb, ny)
  if (ny gt 0) then begin
    ty0 = (trimY[0] - border) > 0
    ty1 = (MAX(trimY) + border) < (dims[2]-1)
  endif else begin
    ty0 = 0
    ty1 = dims[2]-1
  endelse
    
  trimX = WHERE(imSumY ne dims[2]*rgb, nx)
  if (nx gt 0) then begin
    tx0 = (trimX[0] - border) > 0
    tx1 = (MAX(trimX) + border) < (dims[1]-1)
  endif else begin
    tx0 = 0
    tx1 = dims[1]-1
  endelse

  if (nx gt 0 || ny gt 0) then $
    image = image[*,tx0:tx1,ty0:ty1]
end


;---------------------------------------------------------------------------
; Convert an RGB [3,n,m] image array into an RGBA [4,n,m] array,
; by setting all pixels equal to the Transparent value to zero opacity.
; 
; Image is a [3,n,m] byte array.
; Transparent is a 3-element vector with the transparent pixel color.
;
pro IDLitsrvWriteFile::MakeTransparent, image, transparent

  compile_opt idl2, hidden
  on_error, 2
  
  red = image[0,*,*]
  green = image[1,*,*]
  blue = image[2,*,*]
  mask = red ne transparent[0] or $
    green ne transparent[1] or $
    blue ne transparent[2]
  if ARRAY_EQUAL(mask, 1b) then return

  dims = SIZE(image, /DIM)
  image = BYTARR(4, dims[1], dims[2], /NOZERO)
  image[0,*,*] = red
  image[1,*,*] = green
  image[2,*,*] = blue
  image[3,*,*] = 255b*mask   ; opaque

end


;---------------------------------------------------------------------------
; Purpose:
;  Write the output to the given file.
;
; Arguments:
;   strFile: The filename to write
;
;   oData: The data to write.
;
function IDLitsrvWriteFile::WriteFile, strFile, oItem, $
;    ANTIALIAS=antiAliasIn, $
    CMYK=cmyk, $
    RESOLUTION=resolution, $
    WRITER=idWriter, $
    _EXTRA=_extra

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        self->SignalError, $
          [IDLitLangCatQuery('Error:Framework:ErrorWritingFile'), !error_state.msg], severity=2
        return, 0
    endif

    ; Have we been provided a writer? If not, find a match.
    if(not keyword_set(idWriter))then $
        idWriter = self->FindMatchingWriter(strFile)

    if(strtrim(idWriter,2) eq '')then begin
        self->SignalError, $
            [IDLitLangCatQuery('Error:Framework:FileFormatUnknown'), $
            IDLitLangCatQuery('Error:Framework:FileWriteError'),strFile], $
            severity=2

        return, 0
    endif

    ; Create an instance of our writer
    oTool = self->GetTool()
    oDesc = oTool->GetByIdentifier(idWriter)
    oWriter = oDesc->GetObjectInstance()
    ;; It appears that most of the IDL file writers will fail if the
    ;; filename doesnt have an extenstion. So if this file name
    ;; doesnt have an extension, add one
    strTmp = strFile
    if(strpos(strFile, ".") eq -1)then begin
        strext = oWriter->GetFileExtensions(count=count)
        if(count gt 0)then $
          strTmp = strFile +"."+strExt[0]
    endif
    oWriter->SetFilename, strTmp

    void = oTool->DoUIService("HourGlassCursor", self)

    oData = oItem

    switch (1) of

    ; For VisImage retrieve the image data and palette from the grImage,
    ; so you get what is visually displayed, not the raw data.
    OBJ_ISA(oItem, 'IDLitVisImage'): begin
        oItem->GetProperty, _DATA=image, VISUALIZATION_PALETTE=palette

        ndim = SIZE(image, /N_DIMENSIONS)
        if (ndim eq 0) then $
            return, 0 ; failure

        dims = SIZE(image, /DIMENSIONS)
        hasPalette = ((ndim eq 2) || (ndim eq 3 && dims[0] le 2)) && $
            (N_ELEMENTS(palette) ge 3)
        oData = hasPalette ? $
            OBJ_NEW('IDLitDataIDLImage', image, palette, /NO_COPY) : $
            OBJ_NEW('IDLitDataIDLImagePixels', image, /NO_COPY)
        break
        end

    OBJ_ISA(oItem, "_IDLitgrDest"):  ; fall thru
    OBJ_ISA(oItem, "IDLitgrView"): begin

        image = self->GetImage( oItem, oWriter, RESOLUTION=resolution, $
                 CMYK=cmyk, _EXTRA=_extra )
                 
        ; GetImage might return a !NULL if the writer accepts IDLDEST
        if (image eq !NULL) then break 

        oData = OBJ_NEW('IDLitDataIDLImage', image, /NO_COPY, $
          CMYK=KEYWORD_SET(cmyk), $
          RESOLUTION=resolution)
        break
        end

    else: ; should have the correct type

    endswitch

    ; Actually write the data to the file
    ; Returns 1 for success, 0 for error, -1 for cancel.
    success = oWriter->SetData(oData)

    if (oData ne oItem) then $
        OBJ_DESTROY, oData

    ; Return the instance - we are done with it
    oDesc->ReturnObjectInstance, oWriter

    return, success
end

;-------------------------------------------------------------------------
function IDLitsrvWriteFile::GetImage, oItem, oWriter, $
;    ANTIALIAS=antiAliasIn, $
    BORDER=border, $
    CMYK=cmyk, $
    RESOLUTION=resolution, $
    SCALE_FACTOR=scaleFactor, $  ; obsolete in IDL8.0, use RESOLUTION instead
    TRANSPARENT=transparent, $
    WIDTH=width, HEIGHT=height

;        antiAlias = KEYWORD_SET(antiAliasIn)
;        antiAlias = KEYWORD_SET(antiAliasIn) ? (1 > FIX(4096d/(MAX(dims)*scaleFactor)) < 2) : 0
;        if (antiAlias gt 1) then scaleFactor *= antiAlias

    oTool = self->GetTool()

    oItem->GetProperty, DIMENSIONS=dims

    if (ISA(width)) then begin
      if (width le 0) then MESSAGE, 'Illegal value for WIDTH.'
      scaleFactor = DOUBLE(width)/dims[0]
    endif else if (ISA(height)) then begin
      if (height le 0) then MESSAGE, 'Illegal value for HEIGHT.'
      scaleFactor = DOUBLE(height)/dims[1]
    endif else if (ISA(resolution)) then begin
      ; Convert from resolution to scale factor.
      if (resolution le 0) then MESSAGE, 'Illegal value for RESOLUTION.'
      scaleFactor = resolution/96d  ; assume 96 dpi for screen resolution
      oMon = Obj_New('IDLsysMonitorInfo')
      if (Obj_Valid(oMon)) then begin
        index = oMon->GetPrimaryMonitorIndex()
        res = oMon->GetResolutions()   ; centimeters per pixel
        res = res[0,index > 0]
        if (res gt 0) then begin
          scaleFactor = resolution*res/2.54d
        endif
        OBJ_DESTROY, oMon
      endif
    endif

    if (ISA(oWriter)) then begin
      ; Set the scale factor for IDLDEST writers like EPS and EMF.
      ; Also RESOLUTION, for devices that care more about inches than pixels (like PDF)
      oWriter->SetProperty, SCALE_FACTOR=scaleFactor, RESOLUTION=resolution
        
      oWriter->GetProperty, TYPES=types
      ; If our writer accepts IDLDEST, then no need to convert.
      if (MAX(STRCMP(types, 'IDLDEST', /FOLD_CASE)) eq 1) then return, !NULL
    endif

    ; Our writer presumably wants an IDLIMAGE.
    ; Get the system raster service.
    oRaster = oTool->GetService("RASTER_BUFFER")
    if (~obj_valid(oRaster))then begin
        self->SignalError, $
            IDLitLangCatQuery('Error:Framework:CannotAccessBuffer'), $
            severity=2
        return, 0
    endif
    ;; Save the current raster scale factor
    oRaster->GetProperty, SCALE_FACTOR=curScaleFactor 

    ;; Set the buffer dims
    oRaster->SetProperty, SCALE_FACTOR=scaleFactor, $
        XOFFSET=0, YOFFSET=0, DIMENSIONS=dims

    ;; Do the draw
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    status = oRaster->DoWindowCopy(oWin, $
        OBJ_ISA(oItem, "_IDLitgrDest") ? oItem->GetScene() : oItem)
    if (status eq 0) then $
        return, 0

    success = oRaster->GetData(image)

    ; Retrieve the new scale factor, in case it got shrunk if
    ; it exceeded the maximum buffer size.
    oRaster->GetProperty, SCALE_FACTOR=scaleFactorNew

;        if (antiAlias gt 1) then scaleFactorNew /= antiAlias

    scaleFactorNew = scaleFactorNew[0] ; both X and Y should be equal
    ; Only recalculate if necessary, to avoid roundoff errors.
    if (scaleFactorNew ne scaleFactor) then $
      resolution *= scaleFactorNew/scaleFactor

    ; Reset the IDLgrBuffer dimensions, to conserve memory.
    oDev = oRaster->GetDevice()
    oDev->SetProperty, DIMENSIONS=[2,2]
    ;; Reset raster scale factor
    oRaster->SetProperty, SCALE_FACTOR=curScaleFactor
    
    if (~success) then begin
        self->SignalError, $
            IDLitLangCatQuery('Error:Framework:CannotAccessRaster'), severity=2
        return, 0
    endif

;        if (antiAlias) then begin
;          dims = SIZE(image, /DIM)
;          if (~ISA(width) && ~ISA(height)) then $
;            width = dims[1]/antialias
;          kernel = [[1,2,1],[1,4,1],[1,2,1]]
;          for i=0,2 do image[i,*,*] = CONVOL(REFORM(image[i,*,*]),kernel, /NORM)
;;          image = CONGRID(image, 3, dims[1]/2, dims[2]/2)
;;          image = _IDLitThumbResize(image, WIDTH=width, HEIGHT=height)
;        endif

    if (KEYWORD_SET(transparent)) then begin
      if (N_ELEMENTS(transparent) ne 3) then $
        transparent = image[*,0,0]
    endif

    if (ISA(border)) then $
      self->TrimImage, image, border

    if (KEYWORD_SET(transparent)) then $
      self->MakeTransparent, image, transparent

    if (KEYWORD_SET(cmyk) && ~KEYWORD_SET(transparent)) then begin
      red = image[0,*,*]
      green = image[1,*,*]
      blue = image[2,*,*]
      CMYK_CONVERT, c, m, y, k, red, green, blue, /TO_CMYK
      red=0 & green=0 & blue=0
      image = [c,m,y,k]
      c=0 & m=0 & y=0 & k=0
    endif

    return, image

end
;-------------------------------------------------------------------------
pro IDLitsrvWriteFile__define

    compile_opt idl2, hidden

    struc = {IDLitsrvWriteFile,           $
             inherits _IDLitsrvReadWrite}

end

