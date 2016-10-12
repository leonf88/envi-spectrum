; $Id: //depot/idl/releases/IDL_80/idldir/lib/time_test.pro#2 $
;
; Copyright (c) 1986-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;       
;---
PRO TIME_TEST_TIMER, name
  ;Time test procedure.. Print values of commonly used timings.
  ;Print timing information, name = descriptive string for message.

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  t = SYSTIME(1)    ;Get current time
  ntest = ntest + 1
  tt = t - time
  total_time = total_time + tt
  geom_time = geom_time + ALOG(tt > (MACHAR()).xmin)
  
  IF (demomode) THEN PRINT, ntest, FLOAT(tt), ' ', name $
  ELSE PRINTF, lunno, ntest, FLOAT(tt), ' ', name
  
  time = SYSTIME(1) ;Starting time for next test
  
END
;---


;---
PRO TIME_TEST_INIT, file
  ;Initialize timer, file = optional param containing name of file to write info to

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2              ;Return to caller if an error occurs
  
  total_time = 0.
  geom_time = 0.
  ntest = 0
  
  quiet = !quiet
  !quiet = 1
  demomode = LMGR(/DEMO)
  !quiet = quiet
  
  IF (N_PARAMS(0) GE 1) AND (NOT demomode) THEN BEGIN
    GET_LUN, lunno  ;Get a lun
    OPENW, lunno, file
  ENDIF ELSE lunno = -1 ;Set to stdout
  
  time = SYSTIME(1)
  RETURN
  
END
;---


;---
PRO TIME_COMPARE, files, outfile, THRESHOLD = threshold
  ;Compare results of two time tests...
  ; Files = array of file names containing output of each test
  ; Outfile = filename for output. If omitted, only output to log window.
  ; THRESHOLD = comparison threshold, values outside the range of 1.0
  ;   plus or minus threshold are flagged.  Default = 0.15 = 15%.
  ; A report is printed..
  ;
  ; For example:  TIME_COMPARE, FILE_SEARCH('time*.dat'), 'junk.lis'
  ;
  COMPILE_OPT hidden, strictarr
  
  IF N_ELEMENTS(threshold) LE 0 THEN threshold = 0.15
  
  nf = N_ELEMENTS(files)    ;# of files
  
  nmax = 100      ;Max number of tests.
  t = FLTARR(nf, nmax)
  names = STRARR(nmax)
  
  FOR j = 0, nf - 1 DO BEGIN    ;Read each file
    OPENR, lun, /get, files[j]
    b = ''
    m = 0     ;Test index
    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, b
      ;Ignore lines containing "Total Time" and the | character.
      IF STRPOS(b, '|') GE 0 THEN PRINT, files[j], b, format = "(a10, ': ', a)" $
      ELSE IF (STRPOS(b, 'Total Time') LT 0) THEN BEGIN
        a1 = STRCOMPRESS(b)
        k = STRPOS(a1, ' ', 1)
        t[j, m] = FLOAT(STRMID(a1, k + 1, 100))
        k = STRPOS(a1, ' ', k + 1)
        label = STRMID(a1, k + 1, 100)
        IF j EQ 0 THEN names[m] = label $
        ELSE IF LABEL NE names[m] THEN $
          PRINT, 'Tests are inconsistent: ', names[m], label
        m = m + 1
      ENDIF
    ENDWHILE
    FREE_LUN, lun
  ENDFOR

  nr = m + 1      ;New # of rows
  t = t[*, 0:nr]      ;Truncate
  names = names[0:nr]
  t[0, m] = TOTAL(t, 2)   ;Column sums
  names[m] = 'Total Time'
  ;   Geometric mean
  FOR i = 0, nf - 1 DO t[i, nr] = EXP(TOTAL(ALOG(t[i, 0:m - 1])) / m)
  names[nr] = 'Geometric mean'
  
  luns = -1
  IF N_ELEMENTS(outfile) GT 0 THEN BEGIN
    OPENW, i, /get, outfile
    luns = [luns, i]
  ENDIF
  fmt = '(f8.2,' + STRCOMPRESS(nf) + 'i8, 3x,a)'
  
  slen = 80 - 12 - 8 * nf > 10
  
  FOR file = 0, N_ELEMENTS(luns) - 1 DO BEGIN
    PRINTF, luns[file]
    PRINTF, luns[file] , ['Time', STRMID(files, 0, 7)], format = '(10A8)'
    
    FOR j = 0, nr DO BEGIN
      fast = MIN(t[*, j])
      tt = ROUND(t[*, j] / fast * 100.)
      s = STRING(fast, tt, STRMID(names[j], 0, slen - 1), format = fmt)
      FOR k = 0, nf - 1 DO BEGIN
        p  = 8 + (k + 1) * 8    ;Char pos
        IF t[k, j] GT (1.0 + threshold) * fast THEN STRPUT, s, '*', p
        IF t[k, j] EQ fast THEN STRPUT, s, '^', p
      ENDFOR
      PRINTF, luns[file], s
    ENDFOR
    PRINTF, luns[file], ' '
    PRINTF, luns[file], '^ = fastest.'
    PRINTF, luns[file], '* = Slower by ' + STRTRIM(FIX(threshold * 100), 2) + '% or more.'
    PRINTF, luns[file], SYSTIME(0)
  ENDFOR    ;File
  IF N_ELEMENTS(outfile) GT 0 THEN FREE_LUN, luns[1]
  
END
;---


;---
PRO TIME_TEST_RESET, dummy  ;Reset timer, used to ignore set up times...
  ; No-op this procedure to include setup times mainly comprise
  ; the time required to allocate arrays and to set them to
  ; a given value.

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  time = SYSTIME(1)
  RETURN
  
END
;---


;---
PRO TIME_TEST_DUMMY, dummy

  COMPILE_OPT hidden, strictarr
  RETURN
  
END
;---


;---
PRO GRAPHICS_TIMES4_INTERNAL, filename
  ; Time common graphics operations in the same manner as graphics_times3
  ; Just added 2 tests and beefed up the previous tests.

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  IF (!d.x_size NE 640) OR (!d.y_size NE 512) THEN $
    WINDOW, xs = 640, ys = 512  ;Use the same size window for fairness.
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  a = DIST(2)                     ;So we don't get "COMPILED DIST message"
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|GRAPHICS_TIMES4 performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH, ' '
    PRINT, '|  ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|GRAPHICS_TIMES4 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  ; Simple Frequency Plot
  n = 100
  FOR i = 1, n DO BEGIN
    ; Create data array:
    X = FLTARR(256 + (i / 10))
    ; Make a step function. Array elements 80 through 120 are set to 1:
    X[80:120] = 1
    ; Make a filter:
    FREQ = FINDGEN(256 + (i / 10))
    ; Make the filter symmetrical about the value x = 128:
    FREQ = FREQ < ((256 + i) - FREQ)
    ; Second order Butterworth, cutoff frequency = 20.
    FIL = 1.0 / (1 + (FREQ / i)^2)
    ; Plot with a logarithmic x-axis. Use exact axis range:
    PLOT, /YLOG, FREQ, ABS(FFT(X, 1)), $
      XTITLE = 'Relative Frequency', YTITLE = 'Power', XSTYLE = 1
    OPLOT, FREQ, FIL
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Frequency plot, ' + STRTRIM(n, 2) + ' times'
  
  ;Vectors
  n = 5000 ; number of vectors
  t = 20 ; number of times
  x = RANDOMU(seed, n) * (2 * !pi)
  y = FIX((SIN(x) + 1) * (0.5 * !d.y_vsize))
  x = FIX((COS(x) + 1) * (0.5 * !d.x_vsize))
  FOR i = 1, t DO BEGIN
    ERASE
    EMPTY
    PLOTS, x, y, /dev
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, STRTRIM(n, 2) + ' vectors, ' + STRTRIM(t, 2) + ' times'
  
  ;Polygons
  n = 103
  PLOT, [-1, 1], [-1, 1]
  FOR i = 3, n DO BEGIN
    x = FINDGEN(i) * ( 2 * !pi / i)
    ERASE
    POLYFILL, SIN(x), COS(x)
    FOR j = 1, i+2 DO BEGIN
      xx = RANDOMU(seed, 3)
      yy = RANDOMU(seed, 3)
      POLYFILL, xx, yy, /norm, color = !d.N_COLORS / 2
    ENDFOR
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Polygon filling, ' + STRTRIM(n - 3, 2) + ' times'
  
  ;Image display
  n = 512
  t = 50
  a = FINDGEN(n) * (8 * !pi / n)
  c = BYTSCL(SIN(a) # COS(a), top = !d.table_size - 1)
  d = not c
  ERASE
  TIME_TEST_RESET
  FOR i = 1, t DO BEGIN
    TV, c
    EMPTY
    TV, d
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Display ' + STRTRIM(n, 2) + 'x' + STRTRIM(n, 2) + $
    ' image, ' + STRTRIM(t * 2, 2) + ' times'
  
  ;Image Read
  FOR i = 1, t * 2 DO BEGIN
   c = 0
   c = TVRD(0, 0, n, n)
  ENDFOR
  TIME_TEST_TIMER, 'Read ' + STRTRIM(n, 2) + 'x' + STRTRIM(n, 2) + $
    ' image, ' + STRTRIM(t * 2, 2) + ' times'
  
  ;Surface
  n = 256
  t = 4
  FOR i = 1, t DO SURFACE, DIST(n)
  TIME_TEST_TIMER, 'Surface ' + STRTRIM(n, 2) + 'x' + $
    STRTRIM(n, 2) + ', ' + STRTRIM(t, 2) + ' times'
  
  ;Shaded Surface
  n = 256
  t = 4
  FOR i = 1, t DO SHADE_SURF, DIST(n)
  TIME_TEST_TIMER, 'Shaded surface ' + STRTRIM(n, 2) + 'x' + $
    STRTRIM(n, 2) + ', ' + STRTRIM(t, 2) + ' times'

  ;Gaussian Surface
  n = 80
  t = 20
  FOR i = 1, t DO BEGIN
    ; equal to the Euclidean distance from the center:
    Z = SHIFT(DIST(n), n / 2, n / 2)
    ; Make Gaussian with a 1/e width of 10:
    Z = EXP(-(Z / 100)^2) 
    SURFACE, Z 
  ENDFOR
  TIME_TEST_TIMER, 'Gaussian Surface, ' + STRTRIM(t, 2) + ' times'
  
  ;Hershey
  ERASE
  n = 5000
  FOR i = 0L, n DO BEGIN
    siz  = RANDOMN(seed) + 1 > .4
    str = STRING(BYTE(RANDOMU(seed, RANDOMU(seed) * 20 > 3) * 100 + 34))
    XYOUTS, RANDOMU(seed), RANDOMU(seed), str, charsize = siz, /NORM
  ENDFOR
  TIME_TEST_TIMER, 'Hershey strings, ' + STRTRIM(n, 2) + ' times'
  
  ;Hardware Font Strings
  ERASE
  n = 10000
  FOR i = 0L, n DO BEGIN
    str = STRING(BYTE(RANDOMU(seed, RANDOMU(seed) * 20 > 3) * 100 + 34))
    XYOUTS, RANDOMU(seed), RANDOMU(seed), str, /NORM, FONT = 0
  ENDFOR
  TIME_TEST_TIMER, 'Hardware font strings, ' + STRTRIM(n, 2) + ' times'
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time),'=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  IF lunno GT 0 THEN FREE_LUN, lunno
  WDELETE
  
END
;---


;---
PRO GRAPHICS_TIMES3_INTERNAL, filename
  ; Time common graphics operations in the same manner as time_test  (REVISED)

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  IF (!d.x_size NE 640) OR (!d.y_size NE 512) THEN $
    WINDOW, xs = 640, ys = 512  ;Use the same size window for fairness.
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  a = DIST(2)                     ;So we don't get "COMPILED DIST message"
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|GRAPHICS_TIMES3 performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH, ' '
    PRINT, '|  ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|GRAPHICS_TIMES3 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  FOR i = 1, 30 DO BEGIN
    PLOT, SIN(FINDGEN(100) / (2 + i))
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Simple plot, 30 times'
  
  n = 1000
  x = RANDOMU(seed, n) * (2 * !pi)
  y = FIX((SIN(x) + 1) * (0.5 * !d.y_vsize))
  x = FIX((COS(x) + 1) * (0.5 * !d.x_vsize))
  FOR i = 1, 20 DO BEGIN
    ERASE
    EMPTY
    PLOTS, x, y, /dev
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, STRTRIM(n, 2) + ' vectors x 100'
  
  n = 50
  PLOT, [-1, 1], [-1, 1]
  
  FOR i = 3, n DO BEGIN
    x = FINDGEN(i) * ( 2 * !pi / i)
    ERASE
    POLYFILL, SIN(x), COS(x)
    FOR j = 1, i DO BEGIN
      xx = RANDOMU(seed, 3)
      yy = RANDOMU(seed, 3)
      POLYFILL, xx, yy, /norm, color = !d.table_size / 2
    ENDFOR
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Polygon filling'
  
  n = 512
  a = FINDGEN(n) * (8 * !pi / n)
  c = BYTSCL(SIN(a) # COS(a), top = !d.table_size - 1)
  d = not c
  ERASE
  TIME_TEST_RESET
  FOR i = 1, 5 DO BEGIN
    TV, c
    EMPTY
    TV, d
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Display 512 x 512 image, 10 times'
  
  FOR i = 1, 2 DO SURFACE, DIST(128)
  TIME_TEST_TIMER, 'Surface 128x128, 2 times'
  
  FOR i = 1, 2 DO SHADE_SURF, DIST(128)
  TIME_TEST_TIMER, 'Shaded surface 128x128, 2 times'
  
  ERASE
  nrep = 500
  FOR i = 0L, nrep DO BEGIN
    siz  = RANDOMN(seed) + 1 > .4
    str = STRING(BYTE(RANDOMU(seed, RANDOMU(seed) * 20 > 3) * 100 + 34))
    XYOUTS, RANDOMU(seed), RANDOMU(seed), str, charsize = siz, /NORM
  ENDFOR
  TIME_TEST_TIMER, 'Hershey strings X' + STRTRIM(nrep, 2)
  
  ERASE
  nrep = 1000
  FOR i = 0L, nrep DO BEGIN
    str = STRING(BYTE(RANDOMU(seed, RANDOMU(seed) * 20 > 3) * 100 + 34))
    XYOUTS, RANDOMU(seed), RANDOMU(seed), str, /NORM, FONT = 0
  ENDFOR
  TIME_TEST_TIMER, 'Hardware font strings X' + STRTRIM(nrep, 2)
  
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time),'=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  IF lunno GT 0 THEN FREE_LUN, lunno
  WDELETE
  
END
;---


;---
PRO GRAPHICS_TIMES2_INTERNAL, filename
  ; Time common graphics operations in the same manner as time_test  (REVISED)

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  IF (!d.x_size NE 640) OR (!d.y_size NE 512) THEN $
    WINDOW, xs = 640, ys = 512  ;Use the same size window for fairness.
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|GRAPHICS_TIMES2 performance for IDL ', !VERSION.RELEASE,' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH, ' '
    PRINT, '| ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|GRAPHICS_TIMES2 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH, ' '
    PRINTF, lunno,'| ', SYSTIME(0)
  ENDELSE
  
  FOR i = 1, 10 DO BEGIN
    PLOT, [0, 1] + i
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Simple plot, 10 times'
  
  n = 1000
  x = RANDOMU(seed, n) * (2 * !pi)
  y = FIX((SIN(x) + 1) * (0.5 * !d.y_vsize))
  x = FIX((COS(x) + 1) * (0.5 * !d.x_vsize))
  FOR i = 1, 20 DO BEGIN
    ERASE
    EMPTY
    PLOTS, x, y, /dev
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, STRTRIM(n, 2) + ' vectors x 100'
  
  n = 50
  PLOT, [-1, 1], [-1, 1]
  
  FOR i = 3, n DO BEGIN
    x = FINDGEN(i) * ( 2 * !pi / i)
    ERASE
    POLYFILL, SIN(x), COS(x)
    FOR j = 1, i DO BEGIN
      xx = RANDOMU(seed, 3)
      yy = RANDOMU(seed, 3)
      POLYFILL, xx, yy, /norm, color = !d.table_size / 2
    ENDFOR
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Polygon filling'
  
  n = 512
  a = FINDGEN(n) * (8 * !pi / n)
  c = BYTSCL(SIN(a) # COS(a), top = !d.table_size - 1)
  d = not c
  ERASE
  TIME_TEST_RESET
  FOR i = 1, 5 DO BEGIN
    TV, c
    EMPTY
    TV, d
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Display 512 x 512 image, 10 times'
  ;for i=1,10 do begin
  ; c = 0
  ; c = tvrd(0,0,512,512)
  ; endfor
  ;time_test_timer,'Read back 512 by 512 image, 10 times'
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time),'=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  IF lunno GT 0 THEN FREE_LUN, lunno
  WDELETE
  
END
;---


;---
PRO GRAPHICS_TIMES_INTERNAL, filename
  ; Time common graphics operations in the same manner as time_test

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  IF (!d.x_size NE 640) OR (!d.y_size NE 512) THEN $
    WINDOW, xs = 640, ys = 512  ;Use the same size window for fairness.
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|GRAPHICS_TIMES performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINT,'|  ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|GRAPHICS_TIMES performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS,', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  FOR i = 1, 10 DO BEGIN
    PLOT, [0, 1] + i
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Simple plot, 10 times'
  
  n = 1000
  x = RANDOMU(seed, n) * (2 * !pi)
  y = FIX((SIN(x) + 1) * (0.5 * !d.y_vsize))
  x = FIX((COS(x) + 1) * (0.5 * !d.x_vsize))
  FOR i = 1, 5 DO BEGIN
    ERASE
    EMPTY
    PLOTS, x, y, /dev
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'vectors'
  
  n = 24
  PLOT, [-1, 1], [-1, 1]
  
  FOR i = 3, n DO BEGIN
    x = FINDGEN(i) * ( 2 * !pi / i)
    ERASE
    POLYFILL, SIN(x), COS(x)
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Polygon filling'
  
  n = 512
  a = FINDGEN(n) * (8 * !pi / n)
  c = BYTSCL(SIN(a) # COS(a), top = !d.table_size - 1)
  d = not c
  ERASE
  TIME_TEST_RESET
  FOR i = 1, 5 DO BEGIN
    TV, c
    EMPTY
    TV, d
    EMPTY
  ENDFOR
  TIME_TEST_TIMER, 'Display 512 x 512 image, 10 times'
  ;for i=1,10 do begin
  ; c = 0
  ; c = tvrd(0,0,512,512)
  ; endfor
  ;time_test_timer,'Read back 512 by 512 image, 10 times'
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  IF lunno GT 0 THEN FREE_LUN, lunno
  WDELETE
  
END
;---


;---
PRO TIME_TEST4_INTERNAL, filename, NOFILEIO = nofileio
  ; Time common operations in the same manner as time_test3
  ; Just added a test and beefed up the previous tests.
  
  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  
  nofileio = KEYWORD_SET(nofileio)
  
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|TIME_TEST4 performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINT, '| ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|TIME_TEST4 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS,', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  fact = 3 ; Global scale factor for all tests....
  
  ; Empty for loop:
  nrep = LONG(2000000 * fact)
  TIME_TEST_RESET
  FOR i = 1L, nrep DO BEGIN & END
  TIME_TEST_TIMER, 'Empty for loop, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Foreach:
  nrep = LONG(2000000 * fact)
  a = INDGEN(nrep)
  TIME_TEST_RESET
  FOREACH element, a DO BEGIN & END
  TIME_TEST_TIMER, 'Foreach, ' + STRTRIM(nrep, 2) + ' elements'
  
  ; Empty procedure:
  nrep = LONG(100000 * fact)
  TIME_TEST_RESET
  FOR i = 1L, nrep DO TIME_TEST_DUMMY, i
  TIME_TEST_TIMER, 'Call empty procedure (1 param) ' + STRTRIM(nrep, 2) + ' times'
  
  ; Add scalar ints:
  nrep = LONG(200000 * fact)
  TIME_TEST_RESET
  FOR i = 1L, nrep DO a = i + 1
  TIME_TEST_TIMER, 'Add ' + STRTRIM(nrep, 2) + ' integer scalars and store'
  
  ; Scalar arithmetic loop:
  nrep = LONG(fact * 50000)
  TIME_TEST_RESET
  FOR i = 1L, nrep DO BEGIN
    a = i + i - 2
    b = a / 2 + 1
    IF b NE i THEN PRINT, 'You screwed up', i, a, b
  ENDFOR
  TIME_TEST_TIMER, STRTRIM(nrep, 2) + ' scalar loops each of 5 ops, 2 =, 1 if)'
  
  ; Multiply bytes:
  a = REPLICATE(2b, 512, 512)
  TIME_TEST_RESET
  nrep = LONG(30L * fact)
  FOR i = 1, nrep DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 byte by constant and store, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Shift bytes:
  nrep = LONG(300L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 by 512 byte and store, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Add by constant:
  nrep = LONG(100L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = a + 3b
  TIME_TEST_TIMER, 'Add constant to 512x512 byte array, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Add bytes:
  nrep = LONG(80L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 byte arrays and store, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Multiply by constant:
  a = RANDOMU(seed, 512, 512)
  nrep = LONG(30L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 floating by constant, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Shift array:
  nrep = LONG(60L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 x 512 array, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Add floats:
  nrep = LONG(40L * fact)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 floating images, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Random number generation:
  TIME_TEST_RESET
  nrep = LONG(10L * fact)
  FOR i = 1, nrep DO a = RANDOMU(qqq, 100000L)  ;Random number matrix
  TIME_TEST_TIMER, 'Generate ' + STRTRIM(100000L * nrep, 2) + ' random numbers'
  
  ; Inverting matrix:
  siz = LONG(SQRT(fact) * 192)
  a = RANDOMU(seed, siz, siz)
  TIME_TEST_RESET
  b = INVERT(a)
  TIME_TEST_TIMER, 'Invert a ' + STRTRIM(siz, 2) + '^2 random matrix'
  
  ; Decomp:
  TIME_TEST_RESET
  LUDC, a, index
  TIME_TEST_TIMER, 'LU Decomposition of a ' + STRTRIM(siz, 2) + '^2 random matrix'
  
  ; Transposing:
  siz = LONG(384 * SQRT(fact))
  a = BINDGEN(siz, siz) & b = a
  TIME_TEST_RESET
  FOR i = 0, (siz - 1) DO FOR j = 0,(siz - 1) DO b[j, i] = a[i, j]
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, FOR loops'
  FOR j = 1, 10 DO FOR i = 0, (siz - 1) DO BEGIN
    b[0, i] = TRANSPOSE(a[i, *])
  END
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, row and column ops x 10'
  FOR i = 1, 100 DO b = TRANSPOSE(a)
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, TRANSPOSE function x 100'
  
  ; Logs:
  siz = LONG(100000L * fact)
  a = FINDGEN(siz) + 1
  c = a
  b = a
  TIME_TEST_RESET
  FOR i = 0L, N_ELEMENTS(a) - 1 DO b[i] = ALOG(a[i])
  TIME_TEST_TIMER, 'Log of ' + STRTRIM(siz, 2) + ' numbers, FOR loop'
  FOR i = 1, 10 DO b = ALOG(a)
  TIME_TEST_TIMER, 'Log of ' + STRTRIM(siz, 2) + ' numbers, vector ops 10 times'
  
  ; FFT:
  n = 2L^LONG(7L * fact)
  a = FINDGEN(n)
  TIME_TEST_RESET
  b = FFT(a, 1)
  b = FFT(b, -1)
  TIME_TEST_TIMER, STRTRIM(n, 2) + ' point forward plus inverse FFT'
  
  ; Boxcar:
  nrep = LONG(10L * fact)
  a = BYTARR(512, 512)
  a[200:250, 200:250] = 10b
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512x512 byte array, 5x5 boxcar, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Boxcar 2:
  nrep = LONG(10L * fact)
  a = FLOAT(a)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512x512 floating array, 5x5 boxcar, ' + STRTRIM(nrep, 2) + ' times'
  
  ; Write and read byte array:
  a = BINDGEN(512, 512)
  aa = ASSOC(1, a)
  TIME_TEST_RESET
  nrep = LONG(40L * fact)
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 1, FILEPATH('test.dat', /TMP), 512, $
      initial = 512L * nrep ;Must be changed for vax
    FOR i = 0, nrep - 1 DO aa[i] = a
    FOR i = 0, nrep - 1 DO a = aa[i]
    TIME_TEST_TIMER, 'Write and read 512x512 byte array, ' + STRTRIM(nrep, 2) + ' times'
    CLOSE, 1
  ENDIF ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
      PRINT, '                      Skipped read/write test' $
    ELSE $
      PRINT, '                      Skipped read/write test in demo mode'
  ENDELSE
  
  ; Create list:
  n = (40000UL * fact)
  TIME_TEST_RESET
  list = LIST( )
  FOR i = 0UL, n - 1 DO list.Add, list, i
  TIME_TEST_TIMER, 'Create ' + STRTRIM(n, 2) + ' empty lists'
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  ;  Remove the data file
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 2, FILEPATH('test.dat', /TMP), /DELETE
    CLOSE, 2
  ENDIF
  IF lunno GT 0 THEN FREE_LUN, lunno
  
END
;---


;---
PRO TIME_TEST3_INTERNAL, filename, NOFILEIO = nofileio, FACT = fact
  ; Time_test revised....again...

  ; Why??  This routine is similar to time_test and time_test2, but with
  ; longer and larger tests to obtain more accurate comparisons with
  ; ever faster machines.

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  
  nofileio = KEYWORD_SET(nofileio)
  
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|TIME_TEST3 performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINT, '| ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|TIME_TEST3 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS,', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  IF N_ELEMENTS(fact) EQ 0 THEN fact = 1.0 ;Global scale factor for all tests....
  
  ; Empty for loop
  nrep = LONG(2000000 * fact)
  FOR i = 1L, nrep DO BEGIN & END
  TIME_TEST_TIMER, 'Empty For loop, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(100000 * fact)
  FOR i = 1L, nrep DO TIME_TEST_DUMMY, i
  TIME_TEST_TIMER, 'Call empty procedure (1 param) ' + STRTRIM(nrep, 2) + ' times'
  
  ; Add 200000 scalar ints:...
  nrep = LONG(200000 * fact)
  FOR i = 1L, nrep DO a = i + 1
  TIME_TEST_TIMER, 'Add ' + STRTRIM(nrep, 2) + ' integer scalars and store'
  
  ; Scalar arithmetic loop:
  nrep = LONG(fact * 50000)
  FOR i = 1L, nrep DO BEGIN
    a = i + i - 2
    b = a / 2 + 1
    IF b NE i THEN PRINT, 'You screwed up', i, a, b
  ENDFOR
  TIME_TEST_TIMER, STRTRIM(nrep, 2) + ' scalar loops each of 5 ops, 2 =, 1 if)'
  
  a = REPLICATE(2b, 512, 512)
  TIME_TEST_RESET
  nrep = LONG(30L * fact)
  FOR i = 1, nrep DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 byte by constant and store, ' + STRTRIM(nrep, 2) + ' times'
  nrep = LONG(300L * fact)
  FOR i = 1, nrep DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 by 512 byte and store, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(100L * fact)
  FOR i = 1, nrep DO b = a + 3b
  TIME_TEST_TIMER, 'Add constant to 512x512 byte array, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(80L * fact)
  FOR i = 1, nrep DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 byte arrays and store, ' + STRTRIM(nrep, 2) + ' times'
  
  a = RANDOMU(seed, 512, 512)
  TIME_TEST_RESET
  nrep = LONG(30L * fact)
  FOR i = 1, nrep DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 floating by constant, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(60L * fact)
  FOR i = 1, nrep DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 x 512 array, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(40L * fact)
  FOR i = 1, nrep DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 floating images, ' + STRTRIM(nrep, 2) + ' times'
  
  TIME_TEST_RESET
  nrep = LONG(10L * fact)
  FOR i = 1, nrep DO a = RANDOMU(qqq, 100000L)  ;Random number matrix
  TIME_TEST_TIMER, 'Generate ' + STRTRIM(100000L * nrep, 2) + ' random numbers'
  
  siz = LONG(SQRT(fact) * 192)
  a = RANDOMU(seed, siz, siz)
  TIME_TEST_RESET
  b = INVERT(a)
  TIME_TEST_TIMER, 'Invert a ' + STRTRIM(siz, 2) + '^2 random matrix'
  
  TIME_TEST_RESET
  LUDC, a, index
  TIME_TEST_TIMER, 'LU Decomposition of a ' + STRTRIM(siz, 2) + '^2 random matrix'
  
  siz = LONG(384 * SQRT(fact))
  a = BINDGEN(siz, siz) & b = a
  TIME_TEST_RESET
  FOR i = 0, (siz - 1) DO FOR j = 0,(siz - 1) DO b[j, i] = a[i, j]
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, FOR loops'
  FOR j = 1, 10 DO FOR i = 0, (siz - 1) DO BEGIN
    b[0, i] = TRANSPOSE(a[i, *])
  END
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, row and column ops x 10'
  FOR i = 1, 100 DO b = TRANSPOSE(a)
  TIME_TEST_TIMER, 'Transpose ' + STRTRIM(siz, 2) + '^2 byte, TRANSPOSE function x 100'
  
  siz = LONG(100000L * fact)
  a = FINDGEN(siz) + 1
  c = a
  b = a
  TIME_TEST_RESET
  FOR i = 0L, N_ELEMENTS(a) - 1 DO b[i] = ALOG(a[i])
  TIME_TEST_TIMER, 'Log of ' + STRTRIM(siz, 2) + ' numbers, FOR loop'
  FOR i = 1, 10 DO b = ALOG(a)
  TIME_TEST_TIMER, 'Log of ' + STRTRIM(siz, 2) + ' numbers, vector ops 10 times'
  
  n = 2L^LONG(17 * fact)
  a = FINDGEN(n)
  TIME_TEST_RESET
  b = FFT(a, 1)
  b = FFT(b, -1)
  TIME_TEST_TIMER, STRTRIM(n, 2) + ' point forward plus inverse FFT'
  
  nrep = LONG(10L * fact)
  a = BYTARR(512, 512)
  a[200:250, 200:250] = 10b
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 byte array, 5x5 boxcar, ' + STRTRIM(nrep, 2) + ' times'
  
  nrep = LONG(5L * fact)
  a = FLOAT(a)
  TIME_TEST_RESET
  FOR i = 1, nrep DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 floating array, 5x5 boxcar, ' + STRTRIM(nrep, 2) + ' times'
  
  a = BINDGEN(512, 512)
  aa = ASSOC(1, a)
  TIME_TEST_RESET
  nrep = LONG(40L * fact)
  
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 1, FILEPATH('test.dat', /TMP), 512, $
      initial = 512L * nrep ;Must be changed for vax
    FOR i = 0, nrep - 1 DO aa[i] = a
    FOR i = 0, nrep - 1 DO a = aa[i]
    TIME_TEST_TIMER, 'Write and read 512 by 512 byte array x ' + STRTRIM(nrep, 2)
    CLOSE, 1
  END ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
      PRINT, '                      Skipped read/write test' $
    ELSE $
      PRINT, '                      Skipped read/write test in demo mode'
  ENDELSE
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  ;  Remove the data file
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 2, FILEPATH('test.dat', /TMP), /DELETE
    CLOSE, 2
  ENDIF
  IF lunno GT 0 THEN FREE_LUN, lunno
  
END
;---


;---
PRO TIME_TEST2_INTERNAL, filename, NOFILEIO = nofileio  ;Time_test revised....

  ; Why??  This routine is similar to time_test, but with longer and
  ; larger tests to obtain more accurate comparisons with ever faster
  ; machines.

  ; As machines have become faster over the years, the time required for
  ; some of the individual tests became small in comparison the the
  ; resolution of the system clock, making the results inaccurate.  This
  ; test is based on the original time_test, but with the interations and
  ; data size adjusted to yield times on the order of 5 seconds/test.

  ; In a few years, this is written in 1996, the tests will probably
  ; have to be again adjusted.

  COMPILE_OPT hidden, strictarr
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  
  nofileio = KEYWORD_SET(nofileio)
  
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|TIME_TEST2 performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINT, '| ', SYSTIME(0)
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|TIME_TEST2 performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
    PRINTF, lunno, '| ', SYSTIME(0)
  ENDELSE
  
  ; Empty for loop
  nrep = 2000000
  FOR i = 1L, nrep DO BEGIN & END
  TIME_TEST_TIMER, 'Empty For loop,' + STRING(nrep) + ' times'
  
  FOR i = 1L, 100000 DO TIME_TEST_DUMMY, i
  TIME_TEST_TIMER, 'Call empty procedure (1 param) 100,000 times'
  
  ; Add 100000 scalar ints:...
  FOR i = 0L,99999 DO a = i + 1
  TIME_TEST_TIMER, 'Add 100,000 integer scalars and store'
  
  ; Scalar arithmetic loop:
  FOR i = 0L, 25000 DO BEGIN
    a = i + i -2
    b = a / 2 + 1
    IF b NE i THEN PRINT, 'You screwed up', i, a, b
  ENDFOR
  TIME_TEST_TIMER, '25,000 scalar loops each of 5 ops, 2 =, 1 if)'
  
  a = REPLICATE(2b, 512, 512)
  TIME_TEST_RESET
  FOR i = 1, 10 DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 byte by constant and store, 10 times'
  FOR i = 1, 100 DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 by 512 byte and store, 100 times'
  FOR i = 1, 50 DO b = a + 3b
  TIME_TEST_TIMER, 'Add constant to 512 x 512 byte array and store, 50 times'
  FOR i = 1, 30 DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 byte images and store, 30 times'
  
  a = FLOAT(a)
  TIME_TEST_RESET
  FOR i = 1, 30 DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 floating by constant and store, 30 times'
  FOR i = 1, 30 DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Add constant to 512 x 512 floating and store, 40 times'
  FOR i = 1, 40 DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 floating images and store, 30 times'
  
  TIME_TEST_RESET
  FOR i = 1, 10 DO a = RANDOMU(qqq, 150, 150) ;Random number matrix
  TIME_TEST_TIMER, 'Generate 225000 random numbers'
  
  TIME_TEST_RESET
  b = INVERT(a)
  TIME_TEST_TIMER, 'Invert a 150 by 150 random matrix'
  
  TIME_TEST_RESET
  LUDC, a, index
  TIME_TEST_TIMER, 'LU Decomposition of a 150 by 150 random matrix'
  
  a = BINDGEN(256, 256) & b = a
  TIME_TEST_RESET
  FOR i = 0, 255 DO FOR j = 0, 255 DO b[j, i] = a[i, j]
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, FOR loops'
  FOR j = 1, 10 DO FOR i = 0, 255 DO BEGIN
    b[0, i] = TRANSPOSE(a[i, *])
  END
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, row and column ops x 10'
  FOR i = 1, 10 DO b = TRANSPOSE(a)
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, TRANSPOSE function x 10'
  
  a = FINDGEN(100000) + 1
  c = a
  b = a
  TIME_TEST_RESET
  FOR i = 0L, N_ELEMENTS(a) - 1 DO b[i] = ALOG(a[i])
  TIME_TEST_TIMER, 'Log of 100,000 numbers, FOR loop'
  b = ALOG(a)
  TIME_TEST_TIMER, 'Log of 100,000 numbers, vector ops'
  
  n = 2L^17
  a = FINDGEN(n)
  TIME_TEST_RESET
  b = FFT(a, 1)
  b = FFT(b, -1)
  TIME_TEST_TIMER, STRING(n) + ' point forward plus inverse FFT'
  
  a = BYTARR(512, 512)
  a[200:250, 200:250] = 10b
  TIME_TEST_RESET
  FOR i = 1, 10 DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 byte array, 5x5 boxcar, 10 times'
  
  a = FLOAT(a)
  TIME_TEST_RESET
  FOR i = 1, 2 DO b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 floating array, 5x5 boxcar, 2 times'
  
  a = BINDGEN(512, 512)
  aa = ASSOC(1, a)
  TIME_TEST_RESET
  nrecs = 20
  
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 1, FILEPATH('test.dat', /TMP), 512, $
      initial = 512L * nrecs ;Must be changed for vax
    FOR i = 0, nrecs - 1 DO aa[i] = a
    FOR i = 0, nrecs - 1 DO a = aa[i]
    TIME_TEST_TIMER, 'Write and read 512 by 512 byte array x ' + STRTRIM(nrecs, 2)
    CLOSE, 1
  END ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
      PRINT, '                      Skipped read/write test' $
    ELSE $
      PRINT, '                      Skipped read/write test in demo mode'
  ENDELSE
  
  IF (demomode) THEN $
    PRINT, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.' $
  ELSE PRINTF, lunno, FLOAT(total_time), '=Total Time, ', $
    EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  
  ;  Remove the data file
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 2, FILEPATH('test.dat', /TMP), /DELETE
    CLOSE, 2
  ENDIF
  IF lunno GT 0 THEN FREE_LUN, lunno
  
END
;---


;---
PRO TIME_TEST, filename, NOFILEIO = nofileio  ;Run some time tests.
  ; filename = name of listing file or null for terminal output.
  ; nofileio = The presence of this keyword means that no file I/O should be
  ;            done in the test.  Results from demo mode may be compared to
  ;            those from full IDL.
  ;
  ;+
  ; NAME:
  ; TIME_TEST
  ;
  ; PURPOSE:
  ; General purpose IDL benchmark program that performs
  ; approximately 20 common operations and prints the time
  ; required.
  ;
  ; CATEGORY:
  ; Miscellaneous.
  ;
  ; CALLING SEQUENCE:
  ; TIME_TEST [, Filename]
  ;
  ; OPTIONAL INPUTS:
  ;    Filename:  The string containing the name of output file for the
  ;   results of the time test.
  ;
  ; KEYWORD PARAMETERS:
  ; NoFileIO = Optional keyword when set disables file Input/Output
  ; operations.  Results from tests run in demo mode may be compared to
  ; those run in full mode with this keyword set.
  ;
  ; OUTPUTS:
  ; No explicit outputs.  Results of the test are printed to the screen
  ; or to a file.
  ;
  ; OPTIONAL OUTPUT PARAMETERS:
  ; None.
  ;
  ; COMMON BLOCKS:
  ; TIMER_COMMON
  ;
  ; SIDE EFFECTS:
  ; Many operations are performed.  Files are written, etc.
  ;
  ; RESTRICTIONS:
  ; Could be more complete, and could segregate integer, floating
  ; point and file system IO times into separate figures.
  ;
  ; PROCEDURE:
  ; Straightforward.
  ; See also the procedure GRAPHICS_TEST, in this file, which
  ; times a few of the common graphics operations.
  ;
  ; We make no claim that these times are a fair or accurate
  ; measure of computer performance.  In particular, different
  ; versions of IDL were used.
  ;
  ; Graphics performance varies greatly, depending largely on the
  ; window system, or lack of thereof.
  ;
  ; Typical times obtained to date include:
  ;    (where Comp.     = computational tests
  ;     Graphics  = graphics tests
  ;   Geo. Avg. = geometric average)
  ;
  ; Machine / OS / Memory            Comp.   Geo. Avg.   Graphics Geo. Avg.
  ;
  ; MicroVAX II, VMS 5.1, 16MB        637     14.4        39.9    6.57
  ; MicroVAX II, Ultrix 3.0, 16MB     616     13.9        58.1    8.27
  ; Sun 3/110, SunOS 4.0, 12MB        391      8.19       32.0    7.81
  ; Sun 3/80, 12MB, 24 bit color      282      6.03       89.3   21.7
  ; PC 386 25MHz, 80387, MSDOS, 4MB   276      6.9        29.5    5.94
  ; Mips R2030, RISC/os 4.1, 8MB      246      3.67       14.6    2.62
  ; VAXStation 3100, VMS 5.1, 16MB    235      5.13       24.3    3.71
  ; HP 9000, Model 375, ?? ??         163      4.14       20.8    3.37
  ; DecStation 3100, UWS 2.1, 16MB    150      4.00       17.6    3.23
  ; 486 33mhz Clone, MS Windows, 8MB   70      1.81       12.9    3.00
  ; Sun 4/65, SunOS 4.1, 16MB          66      1.81        7.0    1.64
  ; Silicon Graphics 4D/25, ??         51      1.38       19.4    2.44
  ; Sun 4/50 IPX, 16MB                 40      1.03        7.7    0.80
  ; IBM 6000 Model 325 24MB            40      0.87        5.8    1.21
  ; HP 9000 / 720 48 MB                20      0.52        5.0    0.70
  ; SGI Indigo XS4000, 32MB            20      0.46        2.1    0.44
  ; SGI Indigo2, 150Mhz, 32MB          16      0.32        2.4    0.51
  ; DEC Alpha 3000/500, 224MB          13      0.30        2.3    0.43
  ;
  ;
  ; MODIFICATION HISTORY:
  ; DMS, 1986.
  ;
  ; DMS, Revised July 1990,  Increased the size of arrays and the number
  ;   of repetitions to make most of the tests take longer.
  ;   This is to eliminate the effect of clock granularity
  ;   and to acknowledge that machines are becoming faster.
  ;   Many of the tests were made longer by a factor of 10.
  ;
  ; MWR, Jan 1995,  Modified to run in demo mode.  All routines except
  ;   TIME_COMPARE now run in demo mode.  Added platform and
  ;   version information.  Added NoFileIO keyword.
  ;-
  COMPILE_OPT idl2
  
  COMMON timer_common, time, lunno, total_time, geom_time, ntest, demomode
  
  ON_ERROR, 2                      ;Return to caller if an error occurs
  
  IF N_ELEMENTS(time) EQ 0 THEN BEGIN
    PRINT, 'TIME_TEST is obsolete.'
    PRINT, 'Use the newer, more accurate, TIME_TEST2, contained in this file.'
  ENDIF
  
  do_floating = 1 ;Do floating point array tests
  
  nofileio = KEYWORD_SET(nofileio)
  
  IF N_PARAMS() GT 0 THEN TIME_TEST_INIT, filename ELSE TIME_TEST_INIT
  
  ; Print header
  IF (demomode) THEN BEGIN
    PRINT, '|TIME_TEST performance for IDL ', !VERSION.RELEASE, ' (demo):'
    PRINT, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS, ', ARCH=', !VERSION.ARCH
  ENDIF ELSE BEGIN
    PRINTF, lunno, '|TIME_TEST performance for IDL ', !VERSION.RELEASE, ':'
    PRINTF, lunno, '|       OS_FAMILY=', !VERSION.OS_FAMILY, $
      ', OS=', !VERSION.OS,', ARCH=', !VERSION.ARCH
  ENDELSE
  
  ; Empty for loop
  FOR i = 0L, 999999l DO BEGIN & END
  TIME_TEST_TIMER, 'Empty For loop, 1 million times'
  
  FOR i = 1L, 100000 DO TIME_TEST_DUMMY, i
  TIME_TEST_TIMER, 'Call empty procedure (1 param) 100,000 times'
  
  ; Add 100000 scalar ints:...
  FOR i = 0L, 99999 DO a = i + 1
  TIME_TEST_TIMER, 'Add 100,000 integer scalars and store'
  
  ; Scalar arithmetic loop:
  FOR i = 0L, 25000 DO BEGIN
    a = i + i - 2
    b = a / 2 + 1
    IF b NE i THEN PRINT, 'You screwed up', i, a, b
  ENDFOR
  TIME_TEST_TIMER, '25,000 scalar loops each of 5 ops, 2 =, 1 if)'
  
  a = REPLICATE(2b, 512, 512)
  TIME_TEST_RESET
  FOR i = 1, 10 DO b = a * 2b
  TIME_TEST_TIMER, 'Mult 512 by 512 byte by constant and store, 10 times'
  FOR i = 1, 10 DO c = SHIFT(b, 10, 10)
  TIME_TEST_TIMER, 'Shift 512 by 512 byte and store, 10 times'
  FOR i = 1, 10 DO b = a + 3b
  TIME_TEST_TIMER, 'Add constant to 512 x 512 byte array and store, 10 times'
  FOR i = 1, 10 DO b = a + b
  TIME_TEST_TIMER, 'Add two 512 by 512 byte images and store, 10 times'
  
  IF do_floating THEN BEGIN
    a = FLOAT(a)
    TIME_TEST_RESET
    FOR i = 1, 10 DO b = a * 2b
    TIME_TEST_TIMER, 'Mult 512 by 512 floating by constant and store, 10 times'
    FOR i = 1, 10 DO c = SHIFT(b, 10, 10)
    TIME_TEST_TIMER, 'Add constant to 512 x 512 floating and store, 10 times'
    FOR i = 1, 10 DO b = a + b
    TIME_TEST_TIMER, 'Add two 512 by 512 floating images and store, 10 times'
  ENDIF
  
  a = RANDOMU(qqq, 100, 100)  ;Random number matrix
  TIME_TEST_RESET
  b = INVERT(a)
  TIME_TEST_TIMER, 'Invert a 100 by 100 random matrix'
  
  a = BINDGEN(256, 256) & b = a
  TIME_TEST_RESET
  FOR i = 0, 255 DO FOR j = 0, 255 DO b[j, i] = a[i, j]
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, FOR loops'
  FOR i = 0, 255 DO BEGIN
    b[0, i] = TRANSPOSE(a[i, *])
  END
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, row and column ops'
  b = TRANSPOSE(a)
  TIME_TEST_TIMER, 'Transpose 256 x 256 byte, transpose function'
  
  a = FINDGEN(100000) + 1
  c = a
  b = a
  TIME_TEST_RESET
  FOR i = 0L, N_ELEMENTS(a) - 1 DO b[i] = ALOG(a[i])
  TIME_TEST_TIMER, 'Log of 100,000 numbers, FOR loop'
  b = ALOG(a)
  TIME_TEST_TIMER, 'Log of 100,000 numbers, vector ops'
  
  FOR i = 0L, N_ELEMENTS(a) - 1 DO c[i] = a[i] + b[i]
  TIME_TEST_TIMER, 'Add two 100000 element floating vectors, FOR loop'
  
  c = a + b
  TIME_TEST_TIMER, 'Add two 100000 element floating vectors, vector op'
  
  a = FINDGEN(65536L)
  TIME_TEST_RESET
  b = FFT(a, 1)
  TIME_TEST_TIMER, '65536 point real to complex FFT'
  
  a = BYTARR(512, 512)
  a[200:250, 200:250] = 10b
  TIME_TEST_RESET
  b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 byte array, 5x5 boxcar'
  
  a = FLOAT(a)
  TIME_TEST_RESET
  b = SMOOTH(a, 5)
  TIME_TEST_TIMER, 'Smooth 512 by 512 floating array, 5x5 boxcar'
  
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    a = BINDGEN(512, 512)
    aa = ASSOC(1, a)
    TIME_TEST_RESET
    OPENW, 1, FILEPATH('test.dat', /TMP), 512, initial = 5120 ;Must be changed for vax
    FOR i = 1, 10 DO aa[0] = a
    FOR i = 1, 10 DO a = aa[0]
    TIME_TEST_TIMER, 'Write and read 10 512 by 512 byte arrays'
    CLOSE, 1
  ENDIF ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN BEGIN
      PRINT, '                      Skipped read/write test'
    ENDIF ELSE BEGIN
      PRINT, '                      Skipped read/write test in demo mode'
    ENDELSE
  ENDELSE
  
  IF (demomode) THEN BEGIN
    PRINT, FLOAT(total_time), '=Total Time, ', $
      EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  ENDIF ELSE BEGIN 
    PRINTF, lunno, FLOAT(total_time), '=Total Time, ', $
      EXP(geom_time / ntest), '=Geometric mean,', ntest, ' tests.'
  ENDELSE
  
  ;  Remove the data file
  IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    OPENW, 2, FILEPATH('test.dat', /TMP), /DELETE
    CLOSE, 2
  ENDIF
  IF lunno GT 0 THEN FREE_LUN, lunno
  
END
;---