; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgetresource.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
;;---------------------------------------------------------------------------
;; _idlitGR_GetBitmap(strName, value, _EXTRA=_extra)
;;
;; Purpose:
;;  Handle the internal work of retrieving a bitmap resource.
;;
;; Parameters:
;;  strName  - Name of the resource
;;
;;  Value    - The returned bitmap.
;;
;; Return Value:
;;    1 - Success
;;    0 - Error
;;
;; Keywords:
;;    BACKGROUND   - Set to an RGB value that the background color of
;;                   the bitmap should be set to. The background color
;;                   is assumed to be the first pixel [0,0] in the
;;                   image.
function _idlitGR_GetBitmap, strName, value, $
                             BACKGROUND=BACKGROUND
    compile_opt hidden, idl2

    common __IDLitTools$SystemResourceCache$_, $
        c_sysColors, c_strNames, c_Userdir, c_bitmapNames, c_bitmapValues


@idlit_catch
    if(iErr ne 0)then begin
        catch,/cancel
        return, 0
    endif

    ;; Okay, see if the file exists. We look for two file types:
    ;; bmp and png. Start with bmp.

    ; If the filename already contains the correct suffix, assume
    ; it is a fully-qualified filename and just use it.
    ; Otherwise, look in the IDL resource/bitmaps directory.
    filename = (STRPOS(STRLOWCASE(strName), '.bmp') gt 0) ? strName : $
        FILEPATH(strName + '.bmp', SUBDIR=['resource','bitmaps'])

    if (N_ELEMENTS(c_bitmapNames) gt 0) then begin
        idx = (WHERE(c_bitmapNames eq filename))[0]
        if (idx ge 0) then begin
            value = *c_bitmapValues[idx]
            return, 1
        endif
    endif

    ;; Is the bmp file there?
    if (FILE_TEST(fileName, /READ)) then begin  ; BMP

        bm = READ_BMP(fileName, R, G, B)

    endif else begin   ; PNG

        ; If the filename already contains the correct suffix, assume
        ; it is a fully-qualified filename and just use it.
        ; Otherwise, look in the IDL resource/bitmaps directory.
        filename = (STRPOS(STRLOWCASE(strName), '.png') gt 0) ? strName : $
            FILEPATH(strName + '.png', SUBDIR=['resource','bitmaps'])

        if (N_ELEMENTS(c_bitmapNames) gt 0) then begin
            idx = (WHERE(c_bitmapNames eq filename))[0]
            if (idx ge 0) then begin
                value = *c_bitmapValues[idx]
                return, 1
            endif
        endif

        ;; Is the png file there?
        if (FILE_TEST(fileName, /READ)) then $
          bm = read_png(filename, r,g,b)

    endelse

    ;; Okay, we should have something.
    if (N_ELEMENTS(bm) eq 0) then $
        return, 0

    if (SIZE(bm, /N_DIM) eq 3) then begin    ; True-color image

        dims = SIZE(bm, /DIMENSIONS)
        ; Convert to planar interleaving.
        case (WHERE(dims eq 3))[0] of
            0: Value = TRANSPOSE(bm, [1,2,0])
            1: Value = TRANSPOSE(bm, [0,2,1])
            2: ; don't need to do anything
            else: return, 0
        endcase

        ;; Does the caller want to set the background color?
        if(keyword_set(BACKGROUND))then begin
            for i=0,2 do begin
                channel = Value[*,*,i]
                ; Find all values that match the lower left pixel,
                ; and set them to the background.
                channel[WHERE(channel eq channel[0,0])] = background[i]
                Value[0,0,i] = channel
            endfor
        endif

    endif else begin    ; Indexed-color image

        ;; Does the caller want to set the background color?
        if(keyword_set(BACKGROUND))then begin
            ;; get palette index at [0,0].
            idx = bm[0,0]
            r[idx] = BACKGROUND[0]
            g[idx] = BACKGROUND[1]
            b[idx] = BACKGROUND[2]
        endif

        ;; Okay, make a planar-interleaved rgb image
        Value = [[[R[bm]]], [[G[bm]]], [[B[bm]]]]

    endelse

    if (~N_ELEMENTS(c_bitmapNames)) then begin
        c_bitmapNames = filename
        c_bitmapValues = PTR_NEW(value)
    endif else begin
        c_bitmapNames = [c_bitmapNames, filename]
        c_bitmapValues = [c_bitmapValues, PTR_NEW(value)]
    endelse

    return, 1
end


;;---------------------------------------------------------------------------
;; _idlitGR_GetColor(strName, value, _EXTRA=_extra)
;;
;; Purpose:
;;  Handle the internal work of retrieving system color values and
;;  returning them to the user. This is a quick method to get the
;;  values from the system. Names accepted are those field names in
;;  the system colors structure.
;;
;; Parameters:
;;  strName  - Name of the resource
;;
;;  Value    - The returned bitmap.
;;
;; Return Value:
;;    1 - Success
;;    0 - Error
;;
;; Keywords:
function _idlitGR_GetColor, strName, value, _extra=_extra
   compile_opt hidden, idl2

    ; Declare our cache
    common __IDLitTools$SystemResourceCache$_, $
        c_sysColors, c_strNames, c_Userdir, c_bitmapNames, c_bitmapValues

   if(n_elements(c_sysColors) eq 0)then begin
       ;; First time in, init the cache
       wTmp = widget_base()
       c_sysColors = widget_info(wTmp, /system_colors)
       widget_control, wTmp,/destroy
       c_strNames = tag_names(c_sysColors)
   endif

   dex = where(strupcase(strName) eq c_strNames, cnt)
   if(cnt eq 0)then return, 0

   value = c_sysColors.(dex[0])
   return, 1
end


;;---------------------------------------------------------------------------
;; _idlitGR_GetTimeFormat(strName, value, FORMATS=formats, NAMES=formatNames, $
;;                        EXAMPLES=examples, PRINT=print, _EXTRA=_extra)
;;
;; Purpose:
;;  Retrieve time formats and the names of the formats.  Provides a
;;  central location to keep the format and name in sync.
;;
;; Parameters:
;;  strName  - Unused
;;
;;  Value    - The returned formats or format names.
;;
;; Return Value:
;;    1 - Success
;;    0 - Error
;;
;; Keywords:
;;    FORMATS   - Set this keyword to a named variable to retrieve the
;;                  time format strings.
;;
;;    NAMES     - Set this keyword to a named variable to retrieve the
;;                  names of the corresponding time format strings.
;;
;;    EXAMPLE   - Set this keyword to retrieve the current time using
;;                each of the format strings
;;
;;    PRINT     - Set this keyword to print the current time using each
;;                  of the format strings.   The name of the format will
;;                  be printed along with the sample time.
;;
function _idlitGR_GetTimeFormat, $
                                 strName, value, $
                                 FORMATS=formats, $
                                 NAMES=names, $
                                 EXAMPLES=examples, $
                                 PRINT=print, $
                                 _extra=_extra

  ;; Pragmas
  compile_opt idl2, hidden

  ;; data needed for example formats
  curTime = SYSTIME(/JULIAN)
  i = 0

  ;; Initialize format table with Year
  formatNames = ['YYYY']
  formatStrings = ['(C(CYI0))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(I)/Year
  formatNames = [formatNames, 'MM/YYYY']
  formatStrings = [formatStrings, '(C(CMoI,"/",CYI0))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(A) Year
  formatNames = [formatNames, 'MMM YYYY']
  formatStrings = [formatStrings, '(C(CMoA," ",CYI0))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(A);Year
  formatNames = [formatNames, 'MMM;YYYY']
  formatStrings = [formatStrings, '(C(CMoA,"!C",CYI0))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(I)/Day/Year
  formatNames = [formatNames, 'MM/DD/YYYY']
  formatStrings = [formatStrings, '(C(CMoI,"/",CDI2.2,"/",CYI0))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Year/Month(I)/Day
  formatNames = [formatNames, 'YYYY/MM/DD']
  formatStrings = [formatStrings, '(C(CYI0,"/",CMoI2.2,"/",CDI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(I)/Day/Year;Hour:Min:Sec
  formatNames = [formatNames, 'MM/DD/YYYY;HH:mm:SS']
  formatStrings = [formatStrings, $
                   '(C(CMoI,"/",CDI2.2,"/",CYI0,"!C",CHI,":",' + $
                   'CMI2.2,":",CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Year/Month(I)/Day;Hour:Min:Sec
  formatNames = [formatNames, 'YYYY/MM/DD;HH:mm:SS']
  formatStrings = [formatStrings, $
                   '(C(CYI0,"/",CMoI2.2,"/",CDI2.2,"!C",CHI,":",' + $
                   'CMI2.2,":",CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(A)
  formatNames = [formatNames, 'MMM']
  formatStrings = [formatStrings, '(C(CMoA))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(I)/Day
  formatNames = [formatNames, 'MM/DD']
  formatStrings = [formatStrings, '(C(CMoI,"/",CDI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Month(A);Day
  formatNames = [formatNames, 'MMM;DD']
  formatStrings = [formatStrings, '(C(CMoA,"!C",CDI))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Day
  formatNames = [formatNames, 'DD']
  formatStrings = [formatStrings, '(C(CDI))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Day;Hour:Min:Sec
  formatNames = [formatNames, 'DD;HH:mm:SS']
  formatStrings = [formatStrings, '(C(CDI,"!C",CHI,":",CMI2.2,":",CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Hour
  formatNames = [formatNames, 'HH']
  formatStrings = [formatStrings, '(C(CHI))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Hour:Min
  formatNames = [formatNames, 'HH:mm']
  formatStrings = [formatStrings, '(C(CHI,":",CMI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Hour:Min:Sec
  formatNames = [formatNames, 'HH:mm:SS']
  formatStrings = [formatStrings, '(C(CHI,":",CMI2.2,":",CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Hour:Min:Sec.00
  formatNames = [formatNames, 'HH:mm:SS.00']
  formatStrings = [formatStrings, $
                   '(C(CHI,":",CMI2.2,":",CSF5.2,TL5,CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Min
  formatNames = [formatNames, 'mm']
  formatStrings = [formatStrings, '(C(CMI))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Min:Sec
  formatNames = [formatNames, 'mm:SS']
  formatStrings = [formatStrings, '(C(CMI,":",CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Min:Sec.00
  formatNames = [formatNames, 'mm:SS.00']
  formatStrings = [formatStrings, '(C(CMI,":",CSF5.2,TL5,CSI2.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Sec
  formatNames = [formatNames, 'SS']
  formatStrings = [formatStrings, '(C(CSI))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  ;; Sec.00
  formatNames = [formatNames, 'SS.00']
  formatStrings = [formatStrings, '(C(CSF5.2))']
  formatted = STRING(curTime, FORMAT=(formatStrings)[i++])
  formatExamples = [formatExamples, $
                    strjoin(strsplit(formatted,'!C',/EXTRACT),';')]

  if keyword_set(FORMATS) then begin
    value = formatStrings
  endif else if keyword_set(NAMES) then begin
    value = formatNames
  ENDIF ELSE IF keyword_set(EXAMPLES) THEN BEGIN
    value = formatExamples
  ENDIF ELSE if keyword_set(print) then begin
    print, 'Time Formats shown with example value (current time)'
    print
    curTime = SYSTIME(/JULIAN)
    for i=0, N_ELEMENTS(formatStrings)-1 do begin
      print, (formatNames)[i]
      formatted = STRING(curTime, FORMAT=(formatStrings)[i])
                                ; split to mimic action of embedded !C
      split = STRSPLIT(formatted, '!C', /EXTRACT)
      for j=0, N_ELEMENTS(split)-1 do print, split[j]
      print                     ; spacer
    endfor
    value = 1
  endif

  return, 1

end

;;---------------------------------------------------------------------------
;; _idlitGR_GetNumericFormat(strName, value, FORMATS=formats,
;;                           NAMES=formatNames, EXAMPLES=examples, $
;;                           _EXTRA=_extra)
;;
;; Purpose:
;;  Retrieve numeric formats and the names of the formats.  Provides a
;;  central location to keep the format and name in sync.
;;
;; Parameters:
;;  strName  - Unused
;;
;;  Value    - The returned strings.
;;
;; Return Value:
;;    1 - Success
;;    0 - Error
;;
;; Keywords:
;;    FORMATS   - Set this keyword to retrieve the format strings.
;;
;;    NAMES     - Set this keyword to retrieve the names of the
;;                corresponding format strings.
;;
;;    EXAMPLE   - Set this keyword to retrieve examples using each of
;;                the format strings
;;
FUNCTION _idlitGR_GetNumericFormat, $
                                    strName, value, $
                                    FORMATS=formats, $
                                    NAMES=names, $
                                    EXAMPLES=examples, $
                                    _extra=_extra

  ;; Pragmas
  compile_opt idl2, hidden

  ;; data needed for example formats
  value = 0.0

  i = 0

  ;; Initialize format table with Integer
  formatNames = ['Free form Integer']
  formatStrings = ['(I0)']
  formatExamples = [STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Filled fixed width integer
  formatNames = [formatNames, 'Filled fixed width Integer']
  formatStrings = [formatStrings, '(I3.3)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Free form Float
  formatNames = [formatNames, 'Free form Float']
  formatStrings = [formatStrings, '(F0)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Float, 1 decimal place
  formatNames = [formatNames, 'Float with 1 decimal place']
  formatStrings = [formatStrings, '(F0.1)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Float, 2 decimal places
  formatNames = [formatNames, 'Float with 2 decimal places']
  formatStrings = [formatStrings, '(F0.2)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Float, 4 decimal places
  formatNames = [formatNames, 'Float with 4 decimal places']
  formatStrings = [formatStrings, '(F0.4)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Exponential, 1 decimal place
  formatNames = [formatNames, 'Exponential, 1 decimal place']
  formatStrings = [formatStrings, '(E0.1)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Exponential, 2 decimal places
  formatNames = [formatNames, 'Exponential, 2 decimal places']
  formatStrings = [formatStrings, '(E0.2)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  ;; Exponential, 4 decimal places
  formatNames = [formatNames, 'Exponential, 4 decimal places']
  formatStrings = [formatStrings, '(E0.4)']
  formatExamples = [formatExamples, STRING(value, FORMAT=(formatStrings)[i++])]

  IF keyword_set(FORMATS) THEN BEGIN
    value = formatStrings
  ENDIF ELSE IF keyword_set(NAMES) THEN BEGIN
    value = formatNames
  ENDIF ELSE IF keyword_set(EXAMPLES) THEN BEGIN
    value = formatExamples
  ENDIF

  return, 1

END


;---------------------------------------------------------------------------
; _idlitGR_GetUserdir(strName, value, _EXTRA=_extra)
;
; Purpose:
;  Handle internal work of retrieving the .idl iTools user directory and
;  returning it to the user.
;
; Parameters:
;  strName  - Name of the subdirectory. Set to null string to return
;       top-level iTools user directory.
;
;  Value    - The full path to the directory.
;
; Return Value:
;    1 - Success
;    0 - Error
;
; Keywords:
;   WRITE: If set, then verify that the returned (sub)directory has
;       write permissions. If necessary, create the subdirectory.
;       If WRITE is not set, verify that the returned (sub)directory
;       exists and has read permissions, but don't create a subdirectory.
;
function _idlitGR_GetUserdir, strName, value, WRITE=write

    compile_opt hidden, idl2

    ; Note: Any pointers within this common block (like c_bitmapValues)
    ; should be freed by ITRESET.
    ;
    common __IDLitTools$SystemResourceCache$_, $
        c_sysColors, c_strNames, c_Userdir, c_bitmapNames, c_bitmapValues

    if (~N_ELEMENTS(c_Userdir) || $
        ~FILE_TEST(c_Userdir, /DIRECTORY)) then begin

    app_version = 1  ;increment this every time app_desc changes.
    app_desc = [ $
               'This is the configuration directory for the IDL iTools.', $
               'It is used to store iTools settings between IDL sessions.', $
               '', $
               'The IDL Intelligent Tools (iTools) are a set of interactive', $
               'utilities that combine data analysis and visualization with', $
               'the task of producing presentation quality graphics.', $
               '', $
               'Examples of iTools include:', $
               '  iPlot - 2D and 3D plots (line, scatter, polar, and histogram)', $
               '  iSurface - 3D surface representations', $
               '  iContour - 2D and 3D contour maps', $
               '  iImage - Image display and manipulation', $
               '  iVolume - Volume visualizations', $
               '', $
               'The iTools are built upon an object-oriented framework,', $
               'or set of object classes, that serve as the building blocks', $
               'for the interface and functionality of the Intelligent Tools.', $
               'IDL programmers can easily use this framework to create', $
               'custom data analysis and visualization environments.', $
               '', $
               'Note: It is safe to remove this directory, as it will be', $
               'recreated on demand. All Preferences will revert', $
               'to their default settings, and all user-defined styles', $
               'and macros will be removed.', $
               '']

        c_Userdir = APP_USER_DIR('ITT', 'IDL', $
            'itools', 'IDL Intelligent Tools (iTools)', $
            app_desc, app_version, $
            /RESTRICT_IDL_RELEASE)

    endif

    ; Default is to return the top-level userdir.
    ; The directory will already have been created above.
    value = c_Userdir
    if (~STRLEN(strName)) then $
        return, FILE_TEST(value, /DIRECTORY, WRITE=write)

    ; Tack on a subdirectory.
    value += PATH_SEP() + strName

    if (~KEYWORD_SET(write)) then $
        return, FILE_TEST(value, /DIRECTORY, /READ)

    ; If /WRITE then actually create the subdirectory.
    ; Sanity check.
    if (~FILE_TEST(c_Userdir, /DIRECTORY, /WRITE)) then $
        return, 0

    FILE_MKDIR, value

    return, FILE_TEST(value, /DIRECTORY, /WRITE)


end


;;---------------------------------------------------------------------------
;;IDLitGetResource
;;
;; Purpose:
;;   Generic abstraction routine to get a resource for the iTools
;;   system. The general goal is to isolate access in one place, which
;;   allows a central point for all resource acess and the potential
;;   use of cache schemes.
;;
;;   Currentling  (1/03) this is primarly for bitmaps.
;;
;; Parameter:
;;   strName[in]    - The name of the resource requested.
;;
;;   Resource[out]  - The requested resource
;;
;; Keyword:
;;    BITMAP    - If set bitmap resource is requested. This is the
;;                default.  When set, the function will return a RGB
;;                value image.
;;
;;    COLOR     - Used to retrieve system specific color information
;;                The return value is a RGB triplet.
;;
;;    TIMEFORMAT     - Used to retrieve time format strings and their names.
;;
;;    NUMERICFORMAT  - Used to retrieve numeric format strings and their names.
;;
;; Return Value:
;;    1 - Success
;;    0 - Failure
;;
;; Resource Specific Information:
;;
;; BITMAPS
;;
;;     "DEFAULT"     - If the resource name is set to default, a default
;;                     bitmap for buttons is returned.
;;
;;   Keywords
;;
;;    BACKGROUND   - Set to an RGB value that the background color of
;;                   the bitmap should be set to. The background color
;;                   is assumed to be the first pixel [0,0] in the
;;                   image.
;;
;; COLOR
;;   <Field Name>  - Provided a field name from the
;;                   WIDGET_SYSTEM_COLORS structure, this routine will
;;                   return the given color. This allows the values to
;;                   be cached for the application.
;;
;; TIMEFORMAT
;;    VALUES    - Used to retrieve time format strings.
;;
;;    NAMES     - Used to retrieve corresponding names of
;;                          time format strings.
;;
function IDLitGetResource, strName, Value, $
                           BITMAP=BITMAP, $
                           COLOR=COLOR, $
                           TIMEFORMAT=TIMEFORMAT, $
                           NUMERICFORMAT=NUMERICFORMAT, $
                           USERDIR=userdir, $
                           _extra=_extra

   compile_opt hidden, idl2

   if (~N_PARAMS() || ~N_ELEMENTS(strName)) then $
    return, 0

   ;; What does the user want.

    if (KEYWORD_SET(COLOR)) then return, $
        _idlitGR_GetColor(strName, value, _EXTRA=_extra)

    if (KEYWORD_SET(USERDIR)) then return, $
        _idlitGR_GetUserDir(strName, value, _EXTRA=_extra)

    if (KEYWORD_SET(TIMEFORMAT)) then return, $
        _idlitGR_GetTimeFormat(strName, value, _EXTRA=_extra)

    if (KEYWORD_SET(NUMERICFORMAT)) then return, $
        _idlitGR_GetNumericFormat(strName, value, _EXTRA=_extra)

    return, $ ;; bitmap is the default
        _idlitGR_GetBitmap(strName, value, _EXTRA=_extra)

end

