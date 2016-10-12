
FUNCTION get_data_idx, data, wl_idx
  wl = data[*, 1]
  spec_data = data[*, 0]
  first_idx = wl[0]
  idx = wl_idx - first_idx
  IF (wl_idx NE wl[idx]) THEN BEGIN
    ; TODO find the idx
    print, "ERROR"
  ENDIF
  return, spec_data[idx]
END

FUNCTION vege_index_calc, data, type
  CASE type OF
    "MCARI2": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r670 = DOUBLE(get_data_idx(data, 670))
      r550 = DOUBLE(get_data_idx(data, 550))
      res = (1.5 * (2.5 * (r800 - r670) - 1.3 * (r800 - r550))/sqrt((2 * r800 + 1) - (6 * r800 - 5 * sqrt(r670)) - 0.5))
    END
    "NDVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r680 = DOUBLE(get_data_idx(data, 680))
      res = (r800 - r680)/(r800 + r680)
    END
    "RVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r680 = DOUBLE(get_data_idx(data, 680))
      res = r800 / r680
    END
    "EVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r680 = DOUBLE(get_data_idx(data, 680))
      r450 = DOUBLE(get_data_idx(data, 450))
      res = 2.5 * (r800 - r680)/(r800 + 6 * r680 - 7.5 * r450 + 1)      
    END
    "OSAVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r680 = DOUBLE(get_data_idx(data, 680))
      res = 1.16 * (r800 - r680) / (r800 + r680 + 0.16)
    END
    "MSAVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r670 = DOUBLE(get_data_idx(data, 670))
      res = 0.5 * (2 * r800 + 1 - sqrt((2 * r800 + 1)^2 - 8 * (r800 - r670)))
    END
    "TCI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r700 = DOUBLE(get_data_idx(data, 700))
      r675 = DOUBLE(get_data_idx(data, 675))
      r550 = DOUBLE(get_data_idx(data, 550))
      res = (r800 + 1.5 * r550 - r675)/(r800 - r700)
    END
    "REP": BEGIN
      r780 = DOUBLE(get_data_idx(data, 780))
      r740 = DOUBLE(get_data_idx(data, 740))
      r700 = DOUBLE(get_data_idx(data, 700))
      r670 = DOUBLE(get_data_idx(data, 670))
      res = 700 + (740 - 700) * ((r670 + r780)/2 - r700)/(r740 - r700)
    END
    "ARVI": BEGIN
      r800 = DOUBLE(get_data_idx(data, 800))
      r680 = DOUBLE(get_data_idx(data, 680))
      r450 = DOUBLE(get_data_idx(data, 450))
      res = (r800 - (2 * r680 -r450))/(r800 + (2 * r680 - r450))
    END
    ELSE: BEGIN
      res = -1
    END
  ENDCASE 
  return, res
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

PRO params_calc, yfile, slidir, outfile
  COMPILE_OPT IDL2 

  infiles = FILE_SEARCH(slidir, "*.sli")
  types = ["NDVI", "RVI", "EVI", "OSAVI", "MSAVI", "TCI", "ARVI"] ; "MCARI2", "REP", 
  
  OPENW, lun, outfile, /get_lun
  PRINTF, lun, "类型, 样本编号, Y, " + STRJOIN(types, ",")
  
  data=read_csv0(yfile, HEADER = header)
  fieldCount = n_elements(header)
  hdict = hash(STRLOWCASE(header), indgen(fieldCount))
;  print, header
  file2type = hash(data.(hdict['filename']), data.(hdict['类型']))
  file2sample = hash(data.(hdict['filename']), data.(hdict['样本编号']))
  file2y = hash(data.(hdict['filename']), data.(hdict['y']))
  all = []
  _row = STRARR(N_ELEMENTS(types) + 3)
  FOREACH file, infiles DO BEGIN
    fbase = FILE_BASENAME(file)
    IF file2y.HasKey(fbase) THEN BEGIN
      data = OPEN_ENVI_FILE(file)
      _row[0] = file2type[fbase]
      _row[1] = file2sample[fbase]
      _row[2] = file2y[fbase]
      i = 2  
      FOREACH t, types DO BEGIN
        _row[++i] = vege_index_calc(data, t) 
      ENDFOREACH
      all = [all, transpose(_row)]
      printf, lun, STRJOIN(_row, ",") 
    ENDIF
  ENDFOREACH
  IF n_elements(all) ne 0 THEN BEGIN
    all = transpose(all)
    col_res = cal_correlative(all[3:-1, *], all[2, *])
    printf, lun, '相关系数, , ,' + STRJOIN(col_res, ',')
  ENDIF
  FREE_LUN, lun
 
END