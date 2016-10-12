FUNCTION RMSE, x, y
    COMPILE_OPT IDL2
    
    IF (N_ELEMENTS(x) EQ N_ELEMENTS(y)) THEN BEGIN
        ;Check for Infinite or NAN values.
        idx_x0 = WHERE(FINITE(x) EQ 0, idx_x_count, COMPLEMENT = idx_x1)
        IF (idx_x_count GT 0) THEN BEGIN
            x = x[idx_x1]
            y = y[idx_x1]
        ENDIF
        
        idx_y0 = WHERE(FINITE(y) EQ 0, idx_y_count, COMPLEMENT = idx_y1)
        IF (idx_y_count GT 0) THEN BEGIN
            x = x[idx_y1]
            y = y[idx_y1]
        ENDIF
        
        RETURN, SQRT(TOTAL((x - y)^2) / FLOAT(N_ELEMENTS(x)))
    ENDIF ELSE BEGIN
        PRINT, 'The number of elements of x and y must be same!'
        RETURN, -1
    ENDELSE
END

FUNCTION MEC, x, y
    COMPILE_OPT IDL2
    
    IF (N_ELEMENTS(x) EQ N_ELEMENTS(y)) THEN BEGIN
        ;Check for Infinite or NAN values.
        idx_x0 = WHERE(FINITE(x) EQ 0, idx_x_count, COMPLEMENT = idx_x1)
        IF (idx_x_count GT 0) THEN BEGIN
            x = x[idx_x1]
            y = y[idx_x1]
        ENDIF
        
        idx_y0 = WHERE(FINITE(y) EQ 0, idx_y_count, COMPLEMENT = idx_y1)
        IF (idx_y_count GT 0) THEN BEGIN
            x = x[idx_y1]
            y = y[idx_y1]
        ENDIF
        
        RETURN, TOTAL(ABS(x-y)/y) / FLOAT(N_ELEMENTS(x))
    ENDIF ELSE BEGIN
        PRINT, 'The number of elements of x and y must be same!'
        RETURN, -1
    ENDELSE
END

FUNCTION R_SQUARE, y_fit, y
    COMPILE_OPT IDL2
    
    IF (N_ELEMENTS(y_fit) EQ N_ELEMENTS(y)) THEN BEGIN
        ;Check for Infinite or NAN values.
        idx_x0 = WHERE(FINITE(y_fit) EQ 0, idx_x_count, COMPLEMENT = idx_x1)
        IF (idx_x_count GT 0) THEN BEGIN
            y_fit = y_fit[idx_x1]
            y = y[idx_x1]
        ENDIF
        
        idx_y0 = WHERE(FINITE(y) EQ 0, idx_y_count, COMPLEMENT = idx_y1)
        IF (idx_y_count GT 0) THEN BEGIN
            y_fit = y_fit[idx_y1]
            y = y[idx_y1]
        ENDIF
        y_mean = MEAN(y)
        SSE = TOTAL((y_fit - y) ^ 2)
        SSR = TOTAL((y_fit - y_mean) ^ 2)
        SST = TOTAL((y - y_mean) ^ 2)
;        if (1 - (SSE / SST)) gt 1 or (1 - (SSE / SST)) lt 0 then print, (1 - (SSE / SST)) , SSR/ SST, SSE, SST
        RETURN, SSR / SST
    ENDIF ELSE BEGIN
        PRINT, 'The number of elements of y_fit and y must be same!'
        RETURN, -1
    ENDELSE
END

FUNCTION LINEAR_MODEL, _x, _y
   ; y=y=a+bx
   X = _x
   Y = _y
   result = POLY_FIT(X, Y, 1, $
                    SIGMA=sigma, $
                    MEASURE_ERRORS=measure_errors, $
                    YFIT = yfit)
   f = FV_TEST(yfit, Y) ; return two-element vector containing the F-statistic and its significance
   corr = CORRELATE(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, f[*], rsquare, result[*]]
END

FUNCTION LINEAR_FIT, _x, A
   ; y=y=a+bx
   yfit = A[0] + A[1] * _x
   return, yfit
END

FUNCTION LINEAR_TEST, _x, _y, A
   yfit = LINEAR_FIT(_x, A)
   Y = _y
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rmse = rmse(yfit, Y)
   mec = mec(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, rsquare, rmse, mec, f[*]]
END

FUNCTION QUADRATIC_MODEL, _x, _y
   ; y=a+bx+cx^2
   X = _x
   Y = _y
   result = POLY_FIT(X, Y, 2, $
                    SIGMA=sigma, $
                    MEASURE_ERRORS=measure_errors, $
                    YFIT = yfit)
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, f[*], rsquare, result[*]]
END

FUNCTION QUADRATIC_FIT, _x, A
   ; y=a+bx+cx^2
   yfit = A[0] + A[1] * _x + A[2] * (_x ^ 2)
   return, yfit
END

FUNCTION QUADRATIC_TEST, _x, _y, A
   ; y=a+bx+cx^2
   yfit = QUADRATIC_FIT(_x, A)
   Y = _y
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rmse = rmse(yfit, Y)
   mec = mec(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, rsquare, rmse, mec, f[*]]
END

FUNCTION CUBIC_MODEL, _x, _y
   ; y=a+bx+cx^2+dx^3
   X = _x
   Y = _y
   result = POLY_FIT(X, Y, 3, $
                    SIGMA=sigma, $
                    MEASURE_ERRORS=measure_errors, $
                    YFIT = yfit)
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, f[*], rsquare, result[*]]
END

FUNCTION CUBIC_FIT, _x, A
   ; y=a+bx+cx^2+dx^3
   yfit = A[0] + A[1] * _x + A[2] * (_x ^ 2) + A[3] * (_x ^ 3)
   
   return, yfit
END

FUNCTION CUBIC_TEST, _x, _y, A
   yfit = CUBIC_FIT(_x, A)
   Y = _y
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rmse = rmse(yfit, Y)
   mec = mec(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, rsquare, rmse, mec, f[*]]
END

FUNCTION LOG_MODEL, _x, _y
   ; y=a+bln(x)
   X = ALOG(_x)
   Y = _y
   result = POLY_FIT(X, Y, 1, $
                    SIGMA=sigma, $
                    MEASURE_ERRORS=measure_errors, $
                    YFIT = yfit)
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, f[*], rsquare, result[*]]
END

FUNCTION LOG_FIT, _x, A
   ; y=a+bln(x)
   yfit = A[0] + A[1] * ALOG(_x)
   return, yfit
END

FUNCTION LOG_TEST, _x, _y, A
   ; y=a+bln(x)
   yfit = LOG_FIT(_x, A)
   Y = _y
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rmse = rmse(yfit, Y)
   mec = mec(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, rsquare, rmse, mec, f[*]]
END

PRO gfunct, X, A, F, pder
  ; F(x) = a * exp(b*x) 
  bx = EXP(A[1] * X)
  F = A[0] * bx
  ;If the procedure is called with four parameters, calculate the
  ;partial derivatives.
  IF N_PARAMS() GE 4 THEN $
    pder = [[bx], [A[0] * X * bx]]
END

FUNCTION gfunexp, X, A
  bx = A[0]*EXP(A[1]*X)
  RETURN, [[bx], [EXP(A[1]*X)], [bx*X]]
END

FUNCTION EXPONENT_MODEL, _x, _y
   ; y=a*e^(b*x)
   X = _x
   Y = _y
   weights = 1.0/Y
   A = [0.1, 0.1]
;   yfit = CURVEFIT(X, Y, weights, A, SIGMA, FUNCTION_NAME='gfunct')
  fita = [1.0, 1.0]
  measure_errors = 0.05 * Y
  yfit = LMFIT(X, Y, A, MEASURE_ERRORS=measure_errors, /DOUBLE, FITA = fita, FUNCTION_NAME = 'gfunexp')
  
  print, yfit

   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, f[*], rsquare, A[*]]
END

FUNCTION EXPONENT_FIT, _x, A
   ; y=a*e^(b*x)
   yfit = A[0] * EXP(A[1] * _x)
   return, yfit
END

FUNCTION EXPONENT_TEST, _x, _y, A
   ; y=a*e^(b*x)
   yfit = EXPONENT_FIT(_x, A)
   Y = _y
   f = FV_TEST(yfit, Y)
   corr = CORRELATE(yfit, Y)
   rmse = rmse(yfit, Y)
   mec = mec(yfit, Y)
   rsquare = R_SQUARE(yfit, Y)
   return, [corr, rsquare, rmse, mec, f[*]]
END

FUNCTION PLOT_GRAPH, imgpath, name, x, y, xfit, yfit, xlabel, ylabel, info
  data = [transpose(x), transpose(y)]
  sortIndex = Sort(data[0,*])
  FOR j=0,1 DO data[j, *] = data[j, sortIndex]
  
  w = WINDOW(window_title=fileName, dimensions=[800,600])
;  out_img_name = outdir+PATH_SEP()+name+'.bmp'
  _x_max = ceil(max(data[0, *]))
  x_max = _x_max gt 1 ? _x_max : 1
  p1 = PLOT(data[0, *], data[1, *], 'b+9', psym=4, OVERPLOT =1, xrange=[0, x_max], xtitle = xlabel,ytitle = ylabel, $
      yrange=[0,1], xstyle=1 ,ystyle=1, title = name, /current, position=[.1,.2,0.95,0.9], name = "Sample Data")
  p2 = PLOT(xfit, yfit, '-r1', psym=4, OVERPLOT =1, xrange=[0, x_max], $
      yrange=[0,1], xstyle=1 ,ystyle=1, title = name, /current, position=[.1,.2,0.95,0.9], name = "Fitting Curve")
  l = legend(target=[p1, p2], position = [0.05 * x_max, 0.95], orientation=1, sample_width=0.1,$
    horizontal_spacing=0.05, /data)
  IF info ne !NULL THEN BEGIN
    span = 0.05
    FOREACH line, info DO BEGIN
      t = TEXT(0.05 * x_max, 0.85 - span, line, /DATA, FONT_SIZE=18)
      span += 0.05
    ENDFOREACH
  ENDIF
  w.save, imgpath, resolution = 300
  w.close
END

PRO singel_model, samples, tests, model, outDir
  
  OPENW, lun, model, /get_lun
  printf, lun, "指数, 方程, 检验相关系数, 检验R^2, RMSE, MEC, 检验F统计量, 检验F统计量概率, 建模相关系数, 建模F统计量, 建模F统计量概率, 建模R^2, A0, A1, A2, A3"
  sdata=read_csv0(samples, HEADER = sheader)
  fieldCount = n_elements(sheader)
  sheader = STRLOWCASE(sheader)
  sdict = hash(sheader, indgen(fieldCount))
  samplename = sdata.(1)
  sampley = DOUBLE(sdata.(2))
  
  tdata=read_csv0(tests, HEADER = theader)
  fieldCount = n_elements(theader)
  theader = STRLOWCASE(theader)
  tdict = hash(theader, indgen(fieldCount))
  testy = DOUBLE(tdata.(2))
  
  FOR i = 3, fieldCount - 1 DO BEGIN
    samplename = sheader[i]
    print, samplename
    outPath = outDir + PATH_SEP() + samplename
    IF FILE_TEST(outPath, /DIRECTORY) eq 0 THEN BEGIN
      FILE_MKDIR, outPath
    ENDIF 
    testidx = tdict[samplename]
    testx = tdata.(testidx) 
    x = sdata.(i)
    _x_max = ceil(max(x))
    x_max = _x_max gt 1 ? _x_max : 1
    
    res = LINEAR_MODEL(x, sampley)  
    test = LINEAR_TEST(testx, testy, [res[4], res[5]])
    dim = 100
    xfit = INDGEN(dim) * double(x_max)/ dim
    yfit = LINEAR_FIT(xfit, [res[4], res[5]])
    testy_fit = LINEAR_FIT(testx, [res[4], res[5]])
    
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'model_linear.bmp', "Linear Fitting Curve", x, sampley, xfit, yfit, STRUPCASE(samplename), "FAPAR", [$
                        STRING(res[1], FORMAT='("F = ", f8.2)'), $
                        STRING(res[3], FORMAT='("R2 = ", f8.2)'), $
                        STRING([res[4], res[5]], FORMAT='("y=",f8.2,"+",f8.2,"*x")')$
                        ])
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'test_linear.bmp', "Linear Fitting", testy, testy_fit, xfit, xfit, "Real FAPAR", "Predict FAPAR", [$
                        STRING([res[4], res[5]], FORMAT='("y = ",f8.2,"+",f8.2,"*x")'), $
                        STRING(test[1], FORMAT='("R2 = ", f8.2)'), STRING(test[2], FORMAT='("RMSE = ", f8.2)'), $
                        STRING(test[3], FORMAT='("MEC = ", f8.2)')$
                        ])
    printf, lun, STRJOIN([samplename, "Y=A0 + A1 * x", STRING(test), STRING(res)], ',')
    
    res = QUADRATIC_MODEL(x, sampley)
    test = QUADRATIC_TEST(testx, testy, [res[4], res[5], res[6]])
    dim = 100
    xfit = INDGEN(dim) * double(x_max)/ dim
    yfit = QUADRATIC_FIT(xfit, [res[4], res[5], res[6]])
    testy_fit = QUADRATIC_FIT(testx, [res[4], res[5], res[6]])
    
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'model_quadratic.bmp', "Quadratic Fitting Curve", x, sampley, xfit, yfit, STRUPCASE(samplename), "FAPAR", [$
                        STRING(res[1], FORMAT='("F = ", f8.2)'), $
                        STRING(res[3], FORMAT='("R2 = ", f8.2)'), $
                        STRING([res[4], res[5], res[6]], FORMAT='("y=",f8.2,"+",f8.2,"*x+",f8.2,"*x^2")')$
                        ])
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'test_quadratic.bmp', "Quadratic Fitting Curve", testy, testy_fit, xfit, xfit, "Real FAPAR", "Predict FAPAR", [$
                        STRING([res[4], res[5], res[6]], FORMAT='("y=",f8.2,"+",f8.2,"*x+",f8.2,"*x^2")'), $
                        STRING(test[1], FORMAT='("R2 = ", f8.2)'), STRING(test[2], FORMAT='("RMSE = ", f8.2)'), $
                        STRING(test[3], FORMAT='("MEC = ", f8.2)')$
                        ])
    printf, lun, STRJOIN([samplename, "Y=A0 + A1 * x + A2 * x^2", STRING(test), STRING(res)], ',')  
    res = CUBIC_MODEL(x, sampley)  
    test = CUBIC_TEST(testx, testy, [res[4], res[5], res[6], res[7]]) 
    dim = 100
    xfit = INDGEN(dim) * double(x_max)/ dim
    yfit = res[4] + res[5] * xfit + res[6] * (xfit ^ 2)+ res[7] * (xfit ^ 3)
    
    yfit = CUBIC_FIT(xfit, [res[4], res[5], res[6], res[7]])
    testy_fit = CUBIC_FIT(testx, [res[4], res[5], res[6], res[7]])
    
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'model_cubic.bmp', "Cubic Fitting Curve", x, sampley, xfit, yfit, STRUPCASE(samplename), "FAPAR", [$
                        STRING(res[1], FORMAT='("F = ", f8.2)'), $
                        STRING(res[3], FORMAT='("R2 = ", f8.2)'), $
                        STRING([res[4], res[5], res[6], res[7]], FORMAT='("y=",f8.2,"+",f8.2,"*x+",f8.2,"*x^2+",f8.2,"*x^3")')$
                        ])
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'test_cubic.bmp', "Cubic Fitting Curve", testy, testy_fit, xfit, xfit, "Real FAPAR", "Predict FAPAR", [$
                        STRING([res[4], res[5], res[6], res[7]], FORMAT='("y=",f8.2,"+",f8.2,"*x+",f8.2,"*x^2+",f8.2,"*x^3")'), $
                        STRING(test[1], FORMAT='("R2 = ", f8.2)'), STRING(test[2], FORMAT='("RMSE = ", f8.2)'), $
                        STRING(test[3], FORMAT='("MEC = ", f8.2)')$
                        ])
    printf, lun, STRJOIN([samplename, "Y=A0 + A1 * x + A2 * x^2 + A3 * x^3", STRING(test), STRING(res)], ',')
    res = LOG_MODEL(x, sampley)  
    test = LOG_TEST(testx, testy, [res[4], res[5]]) 
    dim = 100
    xfit = INDGEN(dim) * double(x_max)/ dim
    yfit = LOG_FIT(xfit, [res[4], res[5]])
    testy_fit = LOG_FIT(testx, [res[4], res[5]])
    
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'model_logarithmic.bmp', "logarithmic Fitting Curve", x, sampley, xfit, yfit, STRUPCASE(samplename), "FAPAR", [$
                        STRING(res[1], FORMAT='("F = ", f8.2)'), $
                        STRING(res[3], FORMAT='("R2 = ", f8.2)'), $
                        STRING([res[4], res[5]], FORMAT='("y=",f8.2,"+",f8.2,"*ln(x)")')$
                        ])
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'test_logarithmic.bmp', "logarithmic Fitting Curve", testy, testy_fit, xfit, xfit, "Real FAPAR", "Predict FAPAR", [$
                        STRING([res[4], res[5]], FORMAT='("y=",f8.2,"+",f8.2,"*ln(x)")'), $
                        STRING(test[1], FORMAT='("R2 = ", f8.2)'), STRING(test[2], FORMAT='("RMSE = ", f8.2)'), $
                        STRING(test[3], FORMAT='("MEC = ", f8.2)')$
                        ])
    printf, lun, STRJOIN([samplename, "Y=A0 + A1 * ln(x)", STRING(test), STRING(res)], ',')
    res = EXPONENT_MODEL(x, sampley) 
    test = EXPONENT_TEST(testx, testy, [res[4], res[5]]) 
    dim = 100
    xfit = INDGEN(dim) * double(x_max)/ dim
    yfit = EXPONENT_FIT(xfit, [res[4], res[5]])
    testy_fit = EXPONENT_FIT(testx, [res[4], res[5]])
    
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'model_exponent.bmp', "Exponent Fitting Curve", x, sampley, xfit, yfit, STRUPCASE(samplename), "FAPAR", [$
                        STRING(res[1], FORMAT='("F = ", f8.2)'), $
                        STRING(res[3], FORMAT='("R2 = ", f8.2)'), $
                        STRING([res[4], res[5]], FORMAT='("y=",f8.2,"*","exp(",f8.2,"*x)")')$
                        ])
    graph = PLOT_GRAPH(outPath + PATH_SEP()+'test_exponent.bmp', "Exponent Fitting Curve", testy, testy_fit, xfit, xfit, "Real FAPAR", "Predict FAPAR", [$
                        STRING([res[4], res[5]], FORMAT='("y=",f8.2,"*","exp(",f8.2,"*x)")'), $
                        STRING(test[1], FORMAT='("R2 = ", f8.2)'), STRING(test[2], FORMAT='("RMSE = ", f8.2)'), $
                        STRING(test[3], FORMAT='("MEC = ", f8.2)')$
                        ])
    printf, lun, STRJOIN([samplename, "Y=A0 * exp(A1 * x)", STRING(test), STRING(res)], ',')
  ENDFOR
  FREE_LUN, lun
END