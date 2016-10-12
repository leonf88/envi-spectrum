;FUNCTION getXY
;  RETURN, hash('1_001', 0.8129, '9_001', 0.1659, '9_002', 0.2203, '9_003', 0.06980364, $
;  '1_002', 0.7571, '1_003', 0.7724, '10_001', 0.5555, '11_001', 0.8676, '11_002', 0.9045, $
;  '11_003', 0.8608, '12_001', 0.5853, '12_002', 0.4096, '12_003', 0.1924, '13_003', 0.0142, $
;  '14_001', 0.0607, '14_002', 0.0277, '14_003', 0.0107, '15_001', 0.5683, '15_002', 0.5238, $
;  '16_001', 0.0017, '16_002', 0.0151, '16_003', 0.0836, '2_001', 0.055465556, '2_003', 0.0494, $
;  '25-001', 0.2573, '25-002', 0.2287, '25-003', 0.3369, '26-001', 0.6509, '26-002', 0.6738, $
;  '3_001', 0.3042, '3_002', 0.2448, '3_003', 0.3248, '7_001', 0.0291, '7_002', 0.229, '7_003', 0.3502, $
;  '8_001', 0.5351, '8_002', 0.475, '8_003', 0.504, '8_004', 0.4062, '8_005', 0.5769)
;END

FUNCTION GET_BESTX, data_lst, data_y, a_si, a_ei, b_si, b_ei, incr 
  d_len = N_ELEMENTS(data_lst) ; equal to n_elements(data_y) 
  Y = data_y.ToArray()
  max_corr = 0
  max_ai = 0
  max_bi = 0
  FOR ai = a_si, a_ei, incr DO BEGIN
    print, ai
    FOR bi = b_si, b_ei, incr DO BEGIN
      ndvi_arr = fltarr(d_len)
      cnt = 0
      FOREACH di, data_lst DO BEGIN
        wl_start = di[0, 1]
        ai_offset = ai - wl_start ; offset of A
        bi_offset = bi - wl_start ; offset of B
        ai_refl = di[ai_offset, 0]
        bi_refl = di[bi_offset, 0]
        ndvii = (ai_refl - bi_refl)/(ai_refl + bi_refl)
        ndvi_arr[cnt] = ndvii
        cnt = cnt + 1
      ENDFOREACH
      result = CORRELATE(ndvi_arr, Y)
      ; positive correlation
      IF result gt 0 THEN BEGIN
        IF max_corr lt result THEN BEGIN
          max_corr = result
          max_ai = ai
          max_bi = bi
        ENDIF
      ENDIF
    ENDFOR
  ENDFOR
  RETURN, [max_ai, max_bi, max_corr]
END

FUNCTION BEST_NDVI, a_si, a_ei, b_si, b_ei, yfile, slidir 
  COMPILE_OPT IDL2 
  ; TODO user define
;  xy = getXY()
;  yfile = "D:\Projects\lizhe\data\遍历数据-mini.csv"
;  slidir = "D:\Projects\lizhe\data\1-16号点位真实反射率标准库——ENVI格式"
;  a_si = 620
;  a_ei = 760
;  b_si = 765
;  b_ei = 1045
  data=read_csv0(yfile, HEADER = header)
  fieldCount = n_elements(header)
  hdict = hash(STRLOWCASE(header), indgen(fieldCount))
;  file2sample = hash(data.(hdict['filename']), data.(hdict['样本编号']))
  file2y = hash(data.(hdict['filename']), data.(hdict['y']))
  infiles = FILE_SEARCH(slidir, "*.sli")
  
  data=list()
  cnt = 0
  data_y = list()
  FOREACH file, infiles DO BEGIN
;    fbase = FILE_BASENAME(file, ".sli")
    fbase = FILE_BASENAME(file)
    IF file2y.HasKey(fbase) THEN BEGIN
      res = OPEN_ENVI_FILE(file)
      data.Add, res
      data_y.Add, file2y[fbase]
      cnt++  
    ENDIF
  ENDFOREACH
  
  d_len = N_ELEMENTS(data)
;  print, d_len
  
  incr = 3
  res = GET_BESTX(data, data_y, a_si, a_ei, b_si, b_ei, incr)
  return, res
END