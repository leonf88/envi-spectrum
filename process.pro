; remove the continuum from the original graph, 
; each for a subgraph 
function continuum_remove, wave, refl, ws, we
  tmp_wav = wave[0]
  tmp_ref = refl[0]
  tmp_idx = [0] 
  len = n_elements(refl)-1
  
  flag_i=1 
  i=0
  while i le len and flag_i do begin
    if (i eq len) then break
    j=i+1
    flag_j=1
    while j le len and flag_j do begin
      if(j eq len) then begin
        tmp_wav=[tmp_wav,wave[j]]
        tmp_ref=[tmp_ref,refl[j]]
        tmp_idx=[tmp_idx,j]
        flag_i=0
        break
      endif
      m=j+1
      while m le len do begin
        if m eq len then begin
          tmp_wav=[tmp_wav,wave[j]]
          tmp_ref=[tmp_ref,refl[j]]
          tmp_idx=[tmp_idx,j]
          i=j
          flag_j=0
          break
        endif else begin
          a=[[wave[i],1],[wave[j],1]]
          b=[refl[i],refl[j]]
          xx=invert(a)##b
          y1=xx[0]*wave[m]+xx[1]
  
          if y1 lt refl[m] then begin
            j=j+1
            break
          endif else begin
            m=m+1
            continue
          endelse
        endelse
      endwhile
    endwhile
  endwhile
  
  interp_ref = refl[0]
  cr_points_len = n_elements(tmp_ref)
  for i = 1, cr_points_len - 1 do begin
    span = tmp_idx[i] - tmp_idx[i-1]
    if span eq 1 then begin
      interp_ref = [interp_ref, tmp_ref[i]]
    endif
    x=[[tmp_wav[i],1],[tmp_wav[i-1],1]]
    y=[tmp_ref[i],tmp_ref[i-1]]
    p=invert(x)##y
    interp_res = p[0] * wave[tmp_idx[i-1]+1:tmp_idx[i]]+p[1]
    interp_ref=[interp_ref , interp_res]
  end
  interp_ref=[interp_ref,refl[len]]
  cr_ref=refl/interp_ref
  
  return, cr_ref
end

; remove the noise data which is a consecutive spectrum
; then, get several separated spectrum data
; the return index is based on the data dimension
function find_anomal_region, data
;  help, data
  ss = n_elements(data)
  x = indgen(ss)
  d_deriv = deriv(x, data)
  d_deriv = abs(deriv(x, d_deriv))
  dd_idx = where(d_deriv gt 0.003)
  d_size = n_elements(dd_idx)
  region = list()
  if d_size eq 0 then return, region
  s1 = dd_idx[0]
  for i = 1, d_size - 1 do begin
    if (dd_idx[i] - dd_idx[i-1]) lt 60 then continue
    if dd_idx[i] ne s1 then begin
      if (dd_idx[i-1] - s1) gt 10 then begin
        _head = s1
        _tail = dd_idx[i - 1]
        if _head gt 10 then _head -= 10
        if (_tail+10) lt ss then _tail += 10
        region.add, [_head, _tail]
      endif
      s1 = dd_idx[i]
    endif
  end
  
  if s1 ne dd_idx[d_size - 1] then  region.add, [s1, dd_idx[d_size - 1]] 
  ;print, "Region: ", region
  return, region
end

function remove_anomal_region, orig_data
  ns = n_elements(orig_data)
  region = find_anomal_region(orig_data)
  set = list()
  
  xs = 0
  for i = 0, n_elements(region) - 1 do begin
    ems = region[i]
    _head = ems[0]
    _tail = ems[1]
    set.add, [xs, (_head - 1)]
    xs = _tail
  end
  if xs ne (ns - 1) then set.add, [xs, ns - 1] 
;  print, set
  return, set
end

; calculate the derivative of the curve
; smooth the derivative curve for each point
function get_derive, data
  d_deriv = deriv(indgen(n_elements(data)), data)
  d_deriv = smooth(d_deriv, 20) ; smooth with around 20 points
  return, d_deriv
end

; calculate the regions for each wave with
; started point, ended point and minimum point
function find_absp_region, data, wl, threshold1, threshold2
  res = list()
  if n_elements(data) lt 3 then return, res
  d_deriv = get_derive(data)
  abs_d_deriv = abs(d_deriv)
  abs_d_deriv[0] = 0
  abs_d_deriv[n_elements(data) - 1] = 0
  ; extrem value is nearly equal to zero
  d_idx = where(abs_d_deriv lt threshold2)
  s = n_elements(d_idx)
  if s eq 0 then return, res
  
  ; remove the similar values
  tmp = list()
  regions = list()
  for i = 1, s-1 do begin
    ; threshold is 30
    tmp.add, d_idx[i - 1]
    if (d_idx[i] - d_idx[i-1]) gt threshold1 then begin
      ; get the index according to the data
      ss = n_elements(tmp)
      if ss eq 0 then continue
      ; print, tmp
      min_idx = tmp[0]
      min_v = data[min_idx]
      for j = 1, ss - 1 do begin
        if data[tmp[j]] lt min_v then begin
          min_idx = tmp[j]
          min_v = data[min_idx]
        endif 
      end
      regions.add, tmp.toarray()
      res.add, min_idx
      tmp.remove, /all
    endif
  end
  
      
  if n_elements(tmp) gt 0 then begin
    ss = n_elements(tmp)
    if ss ne 0 then begin
      min_idx = tmp[0]
      min_v = data[min_idx]
      for j = 1, ss - 1 do begin
        if data[tmp[j]] lt min_v then begin
          min_idx = tmp[j]
          min_v = data[min_idx]
        endif 
      end
      regions.add, tmp.toarray()
      res.add, min_idx
      tmp.remove, /all
    endif
  endif
  
  ;  for k = 0, n_elements(regions)-1 do begin
  ;    print, "regions "+k
  ;    print, regions[k]
  ;  end

  extr_min_res = list()
  ; get the extreme minmum
  for i = 1, n_elements(res) - 2 do begin
    left_data = d_deriv[res[i-1]:res[i] - 1]
    right_data = d_deriv[res[i] + 1: res[i+1]-1]
    ml = mean(left_data)
    mr = mean(right_data)
    ; print, ml, mr
    if ml lt 0 && mr gt 0 then extr_min_res.add, i
  end

  ; get the extreme minmum, left shoulder, right shoulder
  region_res = list()
  for i = 0, n_elements(extr_min_res) - 1 do begin
    idx = extr_min_res[i]
    region_res.add, [res[idx], (regions[idx-1])[-1], (regions[idx+1])[0]]
  end
  return, region_res
end

; s1, s2, m are formated as [wave, refl]
function calculate_absorption, s1, s2, m
  a=[[s1[0],1],[s2[0],1]]
  b=[s1[1],s2[1]]
  xx=invert(a)##b
  y1=xx[0]*m[0]+xx[1]
  ratio = m[1]/y1
  ad = y1 - m[1]
  aa = (m[0]-s1[0])/(s2[0] - s1[0])
  sai = (aa * s2[1] + (1 - aa)*s1[1])/m[1]
  return, [ad, aa, sai, ratio]
end

; the entry of the analyse program
; including the phase as follows.
; 1. read data, 
; 2. remove noise,
; 3. smooth,
; 4. find the intereseting region
; 5. calculate the xxx, xxx, xxx 
pro process, fpath, outdir, smoothVar, thresh1, thresh2
  COMPILE_OPT IDL2
;  smoothVar = 20
;  thresh1 = 12
;  thresh2 = 0.0001
;  fpath = "D:\Documents\spectrum\data\SLI-NE-76.sli"
;  outdir = "D:\Documents\spectrum\data"
  
  fileName = FILE_BASENAME(fpath)
  pointPos = STRPOS(fileName,'.')
  IF pointPos[0] NE -1 THEN BEGIN
    fileName= STRMID(fileName,0,pointPos)
  ENDIF
  out_dat_name = outdir+PATH_SEP()+fileName+'.csv'
  OPENW, lun, out_dat_name, /get_lun
  CATCH, error_status
  IF error_status NE 0 THEN BEGIN
    FREE_LUN, lun
    RETURN
  ENDIF
  
  printf, lun, "吸收峰名称, 吸收强度刻度, 吸收峰点波长, 吸收峰点反射率, 吸收峰左肩波长, 吸收峰左肩反射率, 吸收峰右肩波长, 吸收峰右肩反射率, 吸收峰深度, 吸收峰对称度, 光谱吸收指数"
    
  ENVI_OPEN_FILE, fpath, R_FID = fid
  
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return 
  endif
  
  ENVI_FILE_QUERY, fid, DIMS = dims, NS = ns, NL = nl, NB = nb, WL = wl, WAVELENGTH_UNITS = wu, XSTART =xs, YSTART = ys
  
  ; print, dims, wu, xs, ys
  band_size = nb + 1
  if band_size > 1 then print, "Only process one band"
  
  ; Get spectrum for the target from the input spectral library. 
  rdata = ENVI_GET_SLICE(fid=fid, line=0, pos=0, xs=dims[1], xe=dims[2])

  ; the reflectance data and wavelength 
  ; help, rdata, wl

  ; get the current window widget for painting
  w = WINDOW(window_title=fileName, dimensions=[900,600])
  
  YRANGE_LOW  = 0
  YRANGE_HIGH = 1.02
  p1 = PLOT([0],[0], xrange=[MIN(wl),MAX(wl)], xtitle='波长 （nm）',ytitle='反射率 ', $
      yrange=[YRANGE_LOW,YRANGE_HIGH],xstyle=1, ystyle=1, title = fileName, /current, position=[.1,.2,0.9,0.9], font_name = 'SimSun')
      
  ; original graph
  ; p1 = PLOT(wl,rdata, 'b--' ,xrange=[MIN(wl),MAX(wl)], xtitle='wavelength (nm)',ytitle='reflectance (%)', $
  ;     yrange=[YRANGE_LOW,YRANGE_HIGH],xstyle=1,ystyle=1, name = "original spectrum",title = fileName, /current, position=[.1,.2,0.95,0.9])
  
  yaxis = AXIS('Y', LOCATION=[max(wl),0], Title = " 包络线去除归一化值", TEXTPOS=1, TICKVALUES=[0,0.2,0.4,0.6,0.8,1], font_name = 'SimSun')   
  rn_idx = remove_anomal_region(rdata)
  
  count = 0
  ; remove the noise graph
  for i = 0, n_elements(rn_idx)-1 do begin
    rn_idx_i = rn_idx[i]
    xs = rn_idx_i[0]
    xe = rn_idx_i[1]
    ; substract original data
    p2 = PLOT(wl[xs:xe], rdata[xs:xe], OVERPLOT =1,xrange=[MIN(wl),MAX(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH],xstyle=1,ystyle=1,$
        name = "噪声去除后的光谱曲线", /current) ;noise removal
    span = smoothVar
    if (xe - xs) > span then begin 
      sub_data = smooth(rdata[xs:xe], span)
      sub_data = smooth(sub_data, span)
      sub_data = smooth(sub_data, span)
    endif else sub_data = rdata[xs:xe]
    
    cr_ref = wl[xs:xe]
    cr_ref = continuum_remove(wl[xs:xe], sub_data, min(wl),max(wl))
    ; smooth the continuum values
    if n_elements(cr_ref) gt smoothVar then cr_ref=smooth(cr_ref,smoothVar)
    
    absp_region = find_absp_region(cr_ref, wl, thresh1, thresh2)

    ; plot the derived reflectance data 
    ; derive_region = get_derive(cr_ref) * 50
    ; p100 = PLOT(wl[xs:xe], derive_region, '-', OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH], xstyle=1,ystyle=1,$
    ;     name = " debug", /current) ; continuum removal  
            
    ; continuum removal graph
    p3 = PLOT(wl[xs:xe], cr_ref, '-:', OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[0,YRANGE_HIGH], xstyle=1,ystyle=1,$
          name = "包络线去除后的光谱曲线", /current) ; continuum removal  
   
    for j = 0, n_elements(absp_region) - 1 do begin
      absp_x = absp_region[j] 
      absp_y = rdata[absp_x + xs]
      cr_ref_y = cr_ref[absp_x]
      absp_x += wl[xs]
      min_x = [absp_x[0]]
      min_y = [absp_y[0]]
      min_cr_ref_y = [cr_ref_y[0]]
      ; plot the point of the minmum
      p4=PLOT(min_x, min_y, '-ro9', psym=4,OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH], xstyle=1, ystyle=1,$
          LINESTYLE = 6, name = "吸收峰点", /current) ; peak
      p=PLOT(min_x, min_cr_ref_y, '-ro9', psym=4,OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH], xstyle=1, ystyle=1,$
          LINESTYLE = 6, /current)
      bound_x = absp_x[1:2]
      bound_y = absp_y[1:2]
      bound_cr_ref_y = cr_ref_y[1:2]
      
      ; plot the boundaries of the minmum
      p5=PLOT(bound_x, bound_y, 'ks-', psym=4,OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH], xstyle=1, ystyle=1,$
          name = "吸收峰肩部", LINESTYLE = 6, /current) ; boundary
      p=PLOT(bound_x, bound_cr_ref_y, 'ks', psym=4,OVERPLOT =1, xrange=[min(wl),max(wl)],yrange=[YRANGE_LOW,YRANGE_HIGH], xstyle=1, ystyle=1,$
          LINESTYLE = 6, /current)
      
      m = [absp_x[0], absp_y[0]]
      s1 = [absp_x[1], absp_y[1]]
      s2 = [absp_x[2], absp_y[2]]
      res = calculate_absorption(s1, s2, m)
      tx = absp_x[0]/(max(wl)*10/9) - 0.04
      ty = cr_ref_y[0]/1.5 + 0.17
      name = strjoin(["m",strtrim(string(count), 2)])
      tv = string(format = '(F5.2)', res[3])
      ot = TEXT(tx, ty, name)
      ov = TEXT(tx-0.01, ty-0.05, tv)
      ; "吸收峰名称, 吸收强度刻度, 吸收峰点波长, 吸收峰点反射率, 吸收峰左肩波长, 吸收峰左肩反射率, 
      ; 吸收峰右肩波长, 吸收峰右肩反射率, 吸收峰深度, 吸收峰对称度, 光谱吸收指数"
      printf, lun, format='(A5,",",F9.6,",",(3(I8,",",F9.6,:,",")),(3(F9.6,:,",")))', $
          name, res[3], m[0], m[1], s1[0], s1[1], s2[0], s2[1], res[0], res[1], res[2]
      count+=1
    end
  end
  free_lun, lun
  l = legend(target=[p2, p3, p4, p5], position = [250, -0.15], orientation=1, sample_width=0.1,$
    horizontal_spacing=0.05, /data, font_name = 'SimSun')
  
  out_img_name = outdir+PATH_SEP()+fileName+'.bmp'
    
  w.save, out_img_name, resolution = 300
  w.close
end
