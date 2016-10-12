FUNCTION OPEN_ENVI_FILE, fpath
  COMPILE_OPT IDL2 
  ENVI_OPEN_FILE, fpath, R_FID = fid
  IF(fid eq -1) THEN BEGIN
    ENVI_BATCH_EXIT
  ENDIF
  ENVI_FILE_QUERY, fid, DIMS = dims, NS = ns, NL = nl, NB = nb, WL = wl, WAVELENGTH_UNITS = wu, XSTART =xs, YSTART = ys
  rdata = ENVI_GET_SLICE(fid=fid, line=0, pos=0, xs=dims[1], xe=dims[2])
  RETURN, [[rdata], [wl]]
END