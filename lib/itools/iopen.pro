; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iopen.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iOpen
;
; PURPOSE:
;   A command line routine used to open files in the Workbench.
;
; PARAMETERS:
;   STRFILE - The name of the file to open
;
;   VISTYPE - The type of visualization to create
;
; KEYWORDS:
;   NONE
;-

;----------------------------------------------------------------------------
; _iOpen_Call_Function
;
; Purpose:
;   Handles the problem of keyword usage between iOpen and reader routines.
;   This allows reader routines to accept any combination of keywords, or none,
;   without causing an error.
;
; Parameters:
;   READER - The name of the read routine to be called
;   
;   STRFILE - The name of the file to open
;
; Keywords:
;   NONE
;
;-------------------------------------------------------------------------
function _iOpen_Call_Function, reader, strFile, $
                               _REF_EXTRA=_extra
  compile_opt hidden, idl2

  ;; Get routine information, compiling routine if needed
  catch, err
  if (err ne 0) then begin
    catch, /CANCEL
    message, /reset
    RESOLVE_ROUTINE, reader, /NO_RECOMPILE, /IS_FUNCTION
  endif
  info = ROUTINE_INFO(reader, /PARAMETERS, /FUNCTIONS)

  ;; Call function either with or without keywords
  catch, err
  if (err eq 0) then begin
    if (info.num_kw_args ne 0) then begin
      data = CALL_FUNCTION(reader, strFile, _EXTRA=_extra)
    endif else begin
      data = CALL_FUNCTION(reader, strFile)
    endelse
  endif else begin
    catch, /CANCEL
    message, /RESET
    return, 0
  endelse
  
  return, data
  
end

;-------------------------------------------------------------------------
function _iOpen_FindMatchingReader, strFile, readers
  compile_opt hidden, idl2

  filename = strtrim(strFile,2)
  if (filename eq '') then return, '' ;; invalid

  ;; Check extensions
  catch, err
  if (err eq 0) then begin
    isDot = STRPOS(filename, '.', /REVERSE_SEARCH)
    if (isDot gt 0) then begin
      fileExt = readers[2,*]
      fileSuffix = STRUPCASE(STRMID(filename, isDot))
      index = WHERE(STRPOS(STRUPCASE(fileExt), fileSuffix) ne -1, nMatch)
      if (nMatch gt 0) then begin
        ;; Attempt to verify file type
        query = readers[4, index[0]]
        if (query eq '') then $
          return, readers[0, index[0]]
        isa = CALL_FUNCTION(query, filename)
        if (isa ne 0) then $
          return, readers[0, index[0]]
      endif
      ;; There wasn't a match based on an extension, so fall
      ;; through to the hard query check
    endif
  endif else begin
    catch, /cancel
    message, /reset
  endelse
  
  ;; Okay, the extension match didn't work, time to do a hard query
  for i=0, N_ELEMENTS(readers[0,*])-1 do begin
    catch, err
    if (err ne 0) then begin
      catch, /CANCEL
      MESSAGE, /RESET
      continue
    endif
    query = readers[4,i]
    isa = CALL_FUNCTION(query, filename)
    if (isa ne 0) then $
      return, readers[0,i]
  endfor
  
  return, ''

end


;-------------------------------------------------------------------------
;+
; :Description:
;    The IOPEN procedure opens and reads data from a file. 
;
; :Params:
;    Filename:
;      A string containing the name of the file to open and read.
;    Data:
;      A named variable that will contain the data.
;    Palette:
;      A named variable that will contain the 3xN color palette,
;      if a palette is included in the file. 
;
; :Keywords:
;    BINARY
;      Set this keyword to include the binary file reader in the
;      list of available readers.
;    GEOTIFF
;      Set this keyword to a named variable in which to return
;      the GEOTIFF tag data for the file, if it exists.
;    TEMPLATE
;      Set this keyword to an ASCII or Binary template to be used
;      when reading the file.
;    VISUALIZE
;      Set this keyword to display the data in an appropriate iTool window.
;    WBOPEN
;      This is an internal keyword indicating that iOpen was called
;      from the Workbench. If this keyword is set, and iOpen is called
;      without Data or Palette arguments, then iOpen will automatically
;      create these variables in the current scope.
;
; :Author: ITTVIS, 2008
;-
pro iOpen, strFileIn, data, palette, $
           PALETTE=palette2, $  ;; Needed to prevent PALETTE in _EXTRA conflict
           BINARY=binIn, $
           GEOTIFF=geotiff, $
           ORIENTATION=orientation, $  ; needed for TIFF reader
           TEMPLATE=templateIn, $
           VISUALIZE=visIn, $
           WBOPEN=wbopen, $
           _REF_EXTRA=_extra

  compile_opt hidden, idl2

@idlit_itoolerror.pro

  if (N_PARAMS() eq 0) then begin
    message, IDLitLangCatQuery('Message:Component:IncorrectNumArgs')
    return
  endif
  
  strFile = STRING(strFileIn[0])
  
  ;; Verify file exists
  if ((strFile eq '') || (FILE_SEARCH(strFile) eq '')) then begin
    message, IDLitLangCatQuery('Error:Framework:CannotOpenFile')+strFile
    return
  endif
  
  ;; Get available readers
  readers = iGetReaders()
  ;; Error if no readers are found
  if ((N_ELEMENTS(readers) eq 1) && (readers[0] eq '')) then begin
    message, 'No available file readers'
    return
  endif
  
  success = 0b
  ;; Get appropriate file reader
  reader = _iOpen_FindMatchingReader(strFile, readers)
  ;; Error if no matching reader found
  if (reader eq '') then begin
    if (~KEYWORD_SET(binIn) && $
        (SIZE(templateIn, /TNAME) ne 'STRUCT')) then begin
      message, $
        STRJOIN([IDLitLangCatQuery('Error:Framework:UnknownFormat'), $
                 IDLitLangCatQuery('Error:Framework:CannotReadFile'), $
                 strFile], ' ')
      return
    endif
  endif else begin
    catch, err
    if (err eq 0) then begin
      data = _iOpen_Call_Function(reader, strFile, $
                                  PALETTE=palette, TEMPLATE=templateIn, $
                                  GEOTIFF=geotiff, WBOPEN=wbopen, $
                                  ORIENTATION=orientation, $
                                  CANCEL=cancel, _EXTRA=_extra)
      success = ~((N_ELEMENTS(data) eq 1) && (SIZE(data, /TYPE) le 5) && $
                  (data[0] eq 0))
    endif else begin
      catch, /CANCEL
      MESSAGE, /RESET
      success = 0
    endelse
  endelse
  
  ;; If dialog was canceled then return without error
  if ((N_ELEMENTS(cancel) ne 0) && (cancel ne 0b)) then return
  
  if ((success eq 0) && (KEYWORD_SET(binIn) || $
                         (SIZE(templateIn, /TNAME) eq 'STRUCT'))) then begin
    ;; Is template a binary template
    useBinary = 0b
    if (SIZE(templateIn, /TNAME) eq 'STRUCT') then begin
      tags = TAG_NAMES(templateIn)
      void = where(tags eq 'ENDIAN', cnt)
      if (cnt ne 0) then $
        useBinary = 1b
    endif
    if (KEYWORD_SET(binIn)) then $
      useBinary = 1b
    if (useBinary) then begin
      ;; Get readers
      readers = iGetReaders(/INCLUDE_BINARY)
      wh = where(STRPOS(readers[0,*],'binary') ne -1, cnt)
      if (cnt ne 0) then begin
        binReader = readers[0,wh[0]]
        catch, err
        if (err eq 0) then begin
          data = _iOpen_Call_Function(reader, strFile, $
                                      PALETTE=palette, TEMPLATE=templateIn, $
                                      WBOPEN=wbopen, CANCEL=cancel, $
                                      _EXTRA=_extra)
          success = ~((N_ELEMENTS(data) eq 1) && (SIZE(data, /TYPE) le 5) && $
                      (data[0] eq 0))
        endif else begin
          catch, /CANCEL
          MESSAGE, /RESET
          success = 0
        endelse
      endif
    endif
  endif

  ;; If dialog was canceled then return without error
  if ((N_ELEMENTS(cancel) ne 0) && (cancel ne 0b)) then return
  
  if (success eq 0) then $
    message, $
      STRJOIN([IDLitLangCatQuery('Error:Framework:CannotReadFile'), $
               strFile], ' ')

  if (N_ELEMENTS(data) && N_ELEMENTS(orientation)) then begin
    ndim = SIZE(data, /N_DIMENSIONS)

    ; Orientations >= 5 need to be transposed.
    if (orientation ge 5) then begin
        data = (ndim eq 2) ? TRANSPOSE(data) : $
            TRANSPOSE(data, [0, 2, 1])
        orientation -= 4
    endif

    ; May need to flip one or both dimensions.
    case (orientation) of
    1: data = REVERSE(data, ndim, /OVERWRITE)
    2: data = REVERSE(REVERSE(data, ndim, /OVERWRITE), $
        ndim-1, /OVERWRITE)
    3: data = REVERSE(data, ndim-1, /OVERWRITE)
    else:
    endcase
  endif
  
  ;; Copy palette argument to palette keyword
  if (arg_present(palette2) && (N_ELEMENTS(palette) ne 0)) then $
    palette2 = palette
    
  if ((N_PARAMS() eq 1) && KEYWORD_SET(wbopen)) then begin
    ;; Move data up one stack frame
    name = IDL_VALIDNAME(FILE_BASENAME(strFile), /CONVERT_ALL)
    if (N_ELEMENTS(data) ne 0) then begin
      (SCOPE_VARFETCH(name, /ENTER, LEVEL=-1)) = data
      if (N_ELEMENTS(palette) ne 0) then begin
        (SCOPE_VARFETCH(name+'_pal', /ENTER, LEVEL=-1)) = palette
      endif
      if (N_ELEMENTS(geotiff) ne 0) then begin
        (SCOPE_VARFETCH(name+'_geotiff', /ENTER, LEVEL=-1)) = geotiff
      endif
    endif
  endif
  
  if (KEYWORD_SET(visIn)) then begin
    ;; iImage
    nDims = SIZE(data, /N_DIMENSIONS)
    dims = SIZE(data, /DIMENSIONS)
    doImage = 0b
    ;; 2D, non vector
    if ((nDims eq 2) && (min(dims) gt 1)) then doImage = 1b
    ;; 3D with one dim used for channels
    if ((nDims eq 3) && (min(dims) le 4)) then doImage = 1b
    if (doImage) then begin
      if (N_Elements(geotiff) gt 0) then begin
        if (KEYWORD_SET(wbopen)) then begin
           im = Image(data, GEOTIFF=geotiff, RGB_TABLE=palette, WINDOW_TITLE=strFile, _EXTRA=_extra)
        endif else begin
          iMap, data, GEOTIFF=geotiff, RGB_TABLE=palette, WINDOW_TITLE=strFile, _EXTRA=_extra
        endelse
      endif else begin
        overplotStr = ""  
        if (KEYWORD_SET(wbopen)) then begin
           ; Use Image graphic to put image into workbench
           im = Image(data, RGB_TABLE=palette, WINDOW_TITLE=strFile, _EXTRA=_extra)
      endif else begin
        iImage, data, RGB_TABLE=palette, WINDOW_TITLE=strFile, _EXTRA=_extra
      endelse
      endelse 
    endif else if (ISA(data, 'IDLFFSHAPE') && KEYWORD_SET(wbopen)) then begin
      void = MAPCONTINENTS(strFileIn)
    endif
  endif
  
  return
    
end


