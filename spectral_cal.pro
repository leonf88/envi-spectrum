FUNCTION spectral_cal1, data, type, rname, samplenames, dataY, fout
  dims = size(data, /DIMENSIONS)
  OPENW, lun, fout, /get_lun

  rec_num = dims[0] 
  col_num = dims[1]
  
  allR = []
  
  rhead = []
  for i = 0, col_num - 1 do begin
    for j = 0, col_num - 1 do begin
      if i lt j then begin
        rhead = [rhead, STRING(rname[j], rname[i], FORMAT='("A(", A0,")-B(", A0,")")')]
      endif
    endfor
  endfor
  printf, lun, "类型, 样本编号, Y, " + STRJOIN(rhead, ",")
  
  rdata = []
  for k = 0, rec_num - 1 do begin
    rec_data = data[k, *]
    res = []
    for i = 0, col_num - 1 do begin
      for j = 0, col_num - 1 do begin
        if i lt j then begin
          a = DOUBLE(rec_data[j])
          b = DOUBLE(rec_data[i])
          if (a + b) ne 0 then begin
            spec = DOUBLE(a - b)/(a + b)
            res = [res, STRING(spec)]
          endif else begin
            res = [res, 'NaN']
          endelse
        endif
      endfor
    endfor
    allR = [allR, transpose(res)]
    printf, lun, type[k] + "," + samplenames[k] + ","  + STRING(dataY[k]) + ","+ STRJOIN(res,",")
  endfor
   
  allR= transpose(allR)
  cor_res = cal_correlative(allR, dataY)
  printf, lun, "相关系数,,, " + STRJOIN(cor_res, ",")
  
  FREE_LUN, lun
END

FUNCTION spectral_cal2, data, type, rname, samplenames, dataY, fout
  dims = size(data, /DIMENSIONS)
  OPENW, lun, fout, /get_lun

  rec_num = dims[0] 
  col_num = dims[1]
  
  allR = []
  
  rhead = []
  for i = 0, col_num - 1 do begin
    for j = 0, col_num - 1 do begin
      rhead = [rhead, STRING(rname[j], rname[i], FORMAT='("A(", A0,")-1/B(", A0,")")')]
    endfor
  endfor
  printf, lun, "类型, 样本编号, Y, " + STRJOIN(rhead, ",")
  
  rdata = []
  for k = 0, rec_num - 1 do begin
    rec_data = data[k, *]
    res = []
    for i = 0, col_num - 1 do begin
      for j = 0, col_num - 1 do begin
        a = DOUBLE(rec_data[j])
        if rec_data[i] ne 0 then begin
          b = 1/DOUBLE(rec_data[i])
          spec = (a - b)/(a + b)
          res = [res, STRING(spec)]
        endif else begin
          res = [res, 'NaN']
        endelse
      endfor
    endfor
    allR = [allR, transpose(res)]
    printf, lun, type[k] + "," + samplenames[k] + "," + STRING(dataY[k]) + "," + STRJOIN(res,",")
  endfor
  
  allR= transpose(allR)
  cor_res = cal_correlative(allR, dataY)
  printf, lun, "相关系数,,, " + STRJOIN(cor_res, ",")
  
  FREE_LUN, lun
END

FUNCTION spectral_cal0, data, type, rname, samplenames, dataY, fout
  dims = size(data, /DIMENSIONS)
  OPENW, lun, fout, /get_lun

  rec_num = dims[0] 
  
  print, rname
  printf, lun, "类型, 样本编号, Y, " + rname
  
  rdata = []
  res = []
  for k = 0, rec_num - 1 do begin
    blue = double(data[k, 0])
    red = double(data[k, 1])
    water0 = double(data[k, 2])
    water1 = double(data[k, 3])
    IF (blue eq 0) or (red eq 0) or (water0 eq 0) or (water1 eq 0) THEN continue
    var = ((blue * red) - (water0 * water1)) / ((blue * red) + (water0 * water1))
    res = [res, var]
    printf, lun, type[k] + "," + samplenames[k] + "," + STRING(dataY[k]) + "," + STRJOIN(var ,",")
  endfor
  
  allR= transpose(res)
  cor_res = cal_correlative(allR, dataY)
;  allR = res
;  cor_res = CORRELATE(double(allR), double(dataY))
  print, cor_res
  printf, lun, "相关系数,,, " + STRJOIN(cor_res, ",")
  
  FREE_LUN, lun
END

FUNCTION cal_correlative, Xs, Y
  dims = size(Xs, /DIMENSIONS)
  col_num = dims[0]
  col_res = []
  for i = 0, col_num - 1 do begin
    _r = CORRELATE(double(Xs[i, *]), double(Y))
    col_res = [col_res, _r]
  endfor
  return, col_res
END

PRO spectral_cal, fin, outPath, ctype
  COMPILE_OPT IDL2
  data=read_csv0(fin, HEADER=header)
  types=["sai", "ad", "aw", "h"]
  items = ["蓝谷", "红谷", "水0", "水1"]
  fieldCount = n_elements(header)
  for i = 0, fieldCount - 1 do begin
    header[i] = STRLOWCASE(header[i])
  endfor
  
  hdict = hash(header, indgen(fieldCount))

  foreach type, types do begin
    rdata = []
    rname = [] 
    foreach item, items do begin
      IF hdict.hasKey(item + type) THEN BEGIN
        idx = hdict[item + type]
        rdata = [rdata, transpose(data.(idx))]
        rname = [rname, item + type]
      ENDIF 
    endforeach
    IF n_elements(rdata) ne 0 THEN BEGIN
      fout = outPath + PATH_SEP() + STRING(type, FORMAT='(A0, ".csv")')
      CASE ctype OF
        0: res = spectral_cal0(transpose(rdata), data.(0), type, data.(1), data.(hdict['y']), fout)
        1: res = spectral_cal1(transpose(rdata), data.(0), rname, data.(1), data.(hdict['y']), fout)
        2: res = spectral_cal2(transpose(rdata), data.(0), rname, data.(1), data.(hdict['y']), fout)
      ENDCASE
    ENDIF
  endforeach
END