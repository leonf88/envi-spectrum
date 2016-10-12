; $Id: //depot/idl/releases/IDL_80/idldir/lib/time_thread.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TIME_THREAD
;
; PURPOSE:
;       Math oriented multi-processing benchmark program used to
;       determine the performance of threaded math operations on
;       the current platform. It performs a simple addition of floating
;       point vectors, varying the number of CPUs used and the length
;       of the vectors. It can produce speedup data and/or a graphical
;       summary of the results.
;
; CATEGORY:
;       Miscellaneous
;
; CALLING SEQUENCE:
;       TIME_THREAD
;
; KEYWORD PARAMETERS:
;       ALL_PLOT: Equivalent to setting all graphic producing keywords
;               (PLOT, PNG_PLOT, PS_PLOT). If those keywords
;               are also set independently, their values supersede ALL_PLOT,
;               which allows setting the file names.
;       MAX: Specifies the maximum number of elements in the vectors to
;               be added. The default for this value is 20 million.
;       MIN: Specifies the minimum number of elements in the vectors to
;               be added. The default for this value is !CPU.HW_NCPU.
;       NITER: Performance of threaded code is highly statistical. In order
;               to obtain statistically representative results, TIME_THREAD
;               performs each computation multiple times and then uses the
;               median time. The default is to interate 5 times. The NITER
;               keyword can be used to change this setting. (Hint: Setting
;               NITER to 1 and STEP to a small value is a good way to see
;               how volatile threading performance can be).
;       PLOT: If set, TIME_THREAD produces a plot of the results on the
;               current display.
;       PNG_PLOT: Produce graphic output in the PNG format. If PNG_PLOT is
;               set to a string value, that value is taken to be the file
;               name. Otherwise, a file named "tthread.png" is created
;               in the current working directory.
;       PS_PLOT: Produce graphic output in PostScript format. If PS_PLOT is
;               set to a string value, that value is taken to be the file
;               name. Otherwise, a file named "tthread.ps" is created
;               in the current working directory.
;       RESULT: If present, a named variable to receive a structure containing
;               all of the resulting data from the run of TIME_THREAD. RESULT
;               contains the following fields:
;
;                  NELTS: Vector of NTEST (# of computations) values
;                       giving the number of elements in each computation.
;                  TIME: [ntest, ncpu] array giving the time required to
;                       perform each computation.
;                  SPEEDUP: [ntest, ncpu] array giving the speedup for each
;                       computation when compared to the 1-cpu case for the
;                       same number of elements.
;                  VERSION: Contents of !VERSION.
;                  DATE: Date string at which the tests completed.
;                  HOSTNAME: Name of host.
;                  NCPU: # of CPUs in the system.
;                  NTHREADS: Maximum number of threads tested.
;                  P: Proportion of computation that is parallelizable.
;
;       RESTORE: If set, TIME_THREAD recovers the data previously written
;               using the SAVE keyword from an IDL SAVE file. In this
;               case, no computation is done, and computation related
;               keywords are ignored. If RESTORE is set to a string value,
;               that value is taken to be the name of the SAVE file.
;               Otherwise, a file named "tthread.sav" is expected to
;               exist in the current working directory.
;       SAVE: If set, TIME_THREAD saves the results of the computation
;               in an IDL SAVE file. Such data can be reused in a subsequent
;               call using the RESTORE keyword without the need to re-compute
;               a potentially expensive operation. If SAVE is set to a
;               string value, that value is taken to be the name of the
;               SAVE file. Otherwise, a file named "tthread.sav" is
;               created in the current working directory.
;       SPEEDUP: If set, the name of variable to receive the result of
;               the computation. The resulting variable is a 2-dimensional
;               array
;       STEP: Specifies how many additional elements are added to the
;             vectors for each step. The default for this value is
;             10% of the difference between MAX and MIN.
;       TIME
;       VERBOSE: TIME_THREAD normally does its work quietly. Set VERBOSE
;                 to cause informational information to be printed to the
;                screen as the computation progresses.
;
; OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       COLORS: Contains the current RGB color tables.
;
; SIDE EFFECTS:
;       - Can change the current colortable via TEK_COLOR.
;       - If killed in mid computation, can leave the graphics and/or
;         threading state in an intermediate setting.
;
; PROCEDURE:
;       TIME_THREAD adds vectors and notes the time taken to do so.
;       It starts with vectors of MIN floating point elements and progresses
;       towards vectors of MAX elements by adding STEP elements after
;       each computation. By altering the default values of these parameters
;       it is possible to obtain highly detailed information (at one extreme)
;       or to generate broad approximations of performance (at the other).
;
;       Each computation is performed on all possible numbers of CPUs for a
;       given machine in order to access how much improvement comes from
;       the addition of each processor. For example, on a dual processor
;       the computation is performed on 1, and then again on 2 CPUs. On
;       a 4 processor system, it is computed using 1, 2, 3, and 4 CPUs.
;       Tasks that benefit highly from extra CPUs are said to be
;       "scalable".
;
; EXAMPLE:
;       It is a fact of threading life that using threads to solve a given
;       problem can take longer than a single threaded computation if the
;       problem size is too small. This occurs when the overhead of a
;       threaded computation (setting up the computation, and the cost
;       of thread communication) is not offset by overlapped computation. IDL
;       uses the !CPU.TPOOL_MIN_ELTS system variable to avoid using threads
;       in such situations. TIME_THREADS (which sets !CPU.TPOOL_MIN_ELTS
;       to a very low value) can be used to artificially observe this effect.
;       The following IDL command:
;
;               TIME_THREAD, MAX=500000, STEP=10000, PLOT
;
;       will show the poor performace that results from threading on a
;       problem that is too small.
;
;
; MODIFICATION HISTORY:
;       7 June 1990, AB, Written to provide benchmarks for new thread
;               pool functionality in IDL.
;-








function tthread_calc_p, speedup

  ; Calculates the parallel part of the program using data for
  ; the longest computation and the speedup for N and N-1 CPUs
  ; according to the formula:
  ;
  ;      2    SpeedUp(2) - 1
  ; p = --- * --------------    (Amdahl's law: p given Speedup(2))
  ;      1      SpeedUp(2) 
  ;
  ; If the 2-cpu speedup is superlinear, then we use the alternative formula:
  ;
  ;                Speedup(n) - Speedup(m)
  ; p  =  -------------------------------------------
  ;       (1 - 1/n)*Speedup(n) - (1 - 1/m)*Speedup(m)
  ;
  ; This is based on Amdahl's Law, as discussed at
  ;
  ;	http://techpubs.sgi.com/library/manuals/3000/007-3511-001/
  ;            html/O2000Tuning.4.html
  ;

  if (!cpu.tpool_nthreads eq 1) then return, 0.0  ; Uniprocessor is all serial

  dim = size(speedup, /dimensions)
  s_2 = speedup[dim[0]-1, 1]

  if (s_2 gt 2) then begin
    n = dim[1]-1
    m = dim[1]
    s_n = speedup[dim[0]-1, n-1]
    s_m = speedup[dim[0]-1, m-1]
    p = (s_n - s_m) / ((1-1/n)*s_n - (1 - 1/m)*s_m)
  endif else begin
    p = 2 * ((s_2 - 1)/s_2)
  endelse

  return, p
end

pro tthread_legend_line, text, color
  ; Output a line for the legend and advance the current position

  common tthread_legend, line, max_len, height, x, y

  xyouts, x + !d.x_ch_size, y + line * height, text, /device, color=color
  line = line - 1
  tmp = strlen(text)
  if (tmp gt max_len) then max_len = tmp

end



pro tthread_legend_pline, ncpu, color, lstyle
  ; Output a line consisting of a CPU number followed by a line in
  ; the correct color and linestyle for that CPU. Then, advance the
  ; current position

  common tthread_legend, line, max_len, height, x, y

  text = string(format='(I3)', ncpu)
  xyouts, x + !d.x_ch_size, y + line * height, text, /device, color=color[0]
  tmp_y = y + line * height ; + (.4 * height)
  plots, [ x + (!d.x_ch_size*5), x + (!d.x_ch_size*30)], [tmp_y, tmp_y], $
	color=color[ncpu-1], linestyle=lstyle[ncpu-1], /device

  line = line - 1
  tmp = strlen(text)
  if (tmp gt max_len) then max_len = tmp

end



pro tthread_legend, data, color, lstyle
  common tthread_legend

  line = -1
  max_len = 0
  height = long(!d.y_ch_size * 1.2)
  x = .01 * !d.x_size
  y = (!d.name eq 'PS') ? .16 : .1
  y = y * !d.x_size
  save_charsize = !p.charsize
;  if (!d.name eq 'PS') then begin
;    y = y * .95
;    !P.charsize=.75
;    height = height * .75
;  endif
  start_y = y

  tthread_legend_line, 'IDL ' + data.version.release, color[0]
  tthread_legend_line, data.date, color[0]
  if (data.hostname ne '') then $
      tthread_legend_line, 'Hostname: ' + data.hostname, color[0]
  tthread_legend_line, 'OS: ' + data.version.os, color[0]
  tthread_legend_line, 'Arch: ' + data.version.arch, color[0]

  line = -1
  x = .33 * !d.x_size
  y = start_y
  tthread_legend_line, $
	STRING(format='("Memory Bits: ", I0)', data.version.memory_bits), $
	color[0]
  tthread_legend_line, $
	STRING(format='("File Offset Bits: ", I0)', $
	       data.version.file_offset_bits), $
	color[0]
  tthread_legend_line, STRING(format='("# CPUs: ", I0)', data.ncpu), color[0]
  tthread_legend_line, STRING(format='("# Threads: ", I0)', data.nthreads), $
	color[0]
  tthread_legend_line, $
	STRING(format='("% Parallel: ", F6.2)', 100.0 * data.p), color[0]

  ; Plot line legend in third column
  line = -1
  x = .6 * !d.x_size
  y = start_y
  for i = 1, data.nthreads do tthread_legend_pline, i, color, lstyle


  plots, [ 0, 0, 1, 1, 0], [ 0, .13, .13, .0, .0], /normal, color=color[0]
  !p.charsize = save_charsize
end





pro tthread_plot, data, PS_PLOT=ps_plot, PNG_PLOT=png_plot
  ; Produce a summary plot of the collected data.

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  do_ps = keyword_set(ps_plot)
  do_png = keyword_set(png_plot)
  do_pixmap = do_png

  if (do_ps and do_png) then MESSAGE, 'Conflicting keywords'

  save_p = !p
  save_winidx = !d.window
  ofile = 'tthread'
  if (do_ps) then begin
    ps_file = (size(ps_plot, /TYPE) eq 7) ? ps_plot : (ofile + '.ps')
    save_dev = !d.name
    set_plot,'ps'
    device,file=ps_file
    ;device,/landscape
    device,ysize=10,yoff=.5,/inch
    color = intarr(data.nthreads)
    ; linestyle = indgen(data.nthreads) mod 6
  endif else begin
    !p.charsize=1.3
    tek_color
    !p.background = 1
    if (!d.name eq 'WIN') then !P.charsize = 1.0
    bcolor = 1
    color = indgen(data.nthreads) + 1
    color[0] = 0	; Use white instead of black for 1st color
    ; linestyle = intarr(data.nthreads)
    if (do_pixmap) then begin
      if (do_png) then $
	png_file = (size(png_plot, /TYPE) eq 7) ? png_plot : (ofile + '.png')
      window, /FREE, /PIXMAP
    endif else begin
      if (!d.n_colors gt 256) then begin	; True color display
        newtmp = b_curr * 65536L + g_curr * 256L + r_curr
        color = newtmp[color]
	bcolor = newtmp[1]
      endif
    endelse
  endelse
  linestyle = indgen(data.nthreads) mod 6


  !p.region = (!d.name eq 'PS') ? [0, .53, .98, .98 ] : [0, .55, .98, 1 ]
  mtitle=string(format='(A, " Using 1 to ", ' $
		        +'I0, " CPUs")', data.plot_title, data.nthreads)
  plot, data.nelts, data.time[*, 0], $
	xtitle='Number Of Elements', ytitle='Time (seconds)', $
	title=mtitle, background=bcolor, color=color[0], xtickformat='(I0)', $
	linestyle=linestyle[0], /NOCLIP
  for i=1, data.nthreads-1 do $
	oplot, data.nelts, data.time[*,i], color=color[i], linestyle=linestyle[i]


  !p.region = (!d.name eq 'PS') ? [0, .13, .98, .555 ] : [0, .15, .98, .575 ]
  plot, data.nelts, data.speedup[*, 0], $
	xtitle='Number Of Elements', ytitle='Speedup vs 1 CPU', $
	yrange=[-1, data.nthreads+2 ], xtickformat='(I0)', $
	ystyle=1, color=color[0], linestyle=linestyle[0], /NOERASE, /NOCLIP
  for i=1, data.nthreads-1 do $
	oplot, data.nelts, data.speedup[*,i], color=color[i], linestyle=linestyle[i]

;    ; Per-CPU efficiency
;    t_1 = data.time[*, 0]
;    eff = data.time
;    for i = 1, data.nthreads do eff[*, i-1] = t_1/(i * data.time[*, i-1])
;    plot, data.nelts, eff[*, 0], $
;	xtitle='Number Of Elements', ytitle='', $
;	title='Per-CPU Efficiency', yrange=[0, 1.1 ], $
;	ystyle=1, color=color[0], linestyle=linestyle[0]
;    for i=1, data.nthreads-1 do $
;	oplot, nelts, eff[*,i], color=color[i], linestyle=linestyle[i]

  ; Box
  plots, [0, 0, !d.x_size-1, !d.x_size-1, 0], $
	[0, !d.y_size-1, !d.y_size-1, 0, 0], /device, color=color[0]

  ; Legend at bottom
  tthread_legend, data, color, linestyle

  if (do_ps) then begin
    file = ps_file
    device,/close
    set_plot,save_dev   
    MESSAGE, /INFORMATIONAL, 'Postscript output is in: ' + file
    ;spawn,'pageview ' + file
  endif else begin
    if (do_pixmap) then begin
      image = tvrd()
      wdelete
      if (do_png) then begin
        write_png, png_file, image, r_curr[0:data.nthreads], $
		g_curr[0:data.nthreads], b_curr[0:data.nthreads]
        MESSAGE, /INFORMATIONAL, 'PNG output is in: ' + png_file
        ;spawn, 'netscape ' + file
      endif
    endif
  endelse



  !p = save_p
  if (save_winidx ne -1) then wset, save_winidx

end




function tthread_internal, npts, num_iter, SQRT=do_sqrt
  ; Perform the operation for the specified number of points
  ; num_iter times and return the median time for it (in seconds).

  vec = findgen(npts)
  times = fltarr(num_iter)

  if (keyword_set(do_sqrt)) then begin

    for i = 0, num_iter-1 do begin
      b = 0
      t = systime(1)
      b = sqrt(vec)
      times[i] = systime(1) - t
    endfor

  endif else begin

    for i = 0, num_iter-1 do begin
      b = 0
      t = systime(1)
      b = vec + vec
      times[i] = systime(1) - t
    endfor

  endelse

  return, median(times)
end


pro time_thread, min=min, max=max, step=step, plot=plot, ALL_PLOT=all_plot, $
	PS_PLOT=ps_plot, PNG_PLOT=png_plot, $
	restore=restore, save=save, niter=niter, VERBOSE=verbose, $
	RESULT=tthread_data, SQRT=do_sqrt

  do_verbose = keyword_set(verbose)
  if (keyword_set(all_plot)) then begin
    PLOT = 1
    if (not keyword_set(PS_PLOT)) then PS_PLOT = 1
    if (not keyword_set(PNG_PLOT)) then PNG_PLOT = 1
  endif

  if (keyword_set(do_sqrt)) then begin
    plot_title = 'Floating Point Square Root (b = SQRT(a))'
  endif else begin
    plot_title = 'Floating Point Binop (b = a + a)'
  endelse



  if (keyword_set(restore)) then begin
      file = (size(restore, /TYPE) eq 7) ? restore : 'tthread.sav'
      RESTORE, /VERBOSE, /RELAXED_STRUCTURE_ASSIGNMENT, file

      ; If the restored value of TTHREAD_DATA lacks the plot_title field,
      ; then reconstruct it so that it does.
      catch, status
      if (status eq 0) then begin
        junk = tthread_data.plot_title
      endif else begin
        catch,/cancel
        tthread_data = { nelts:tthread_data.nelts, time:tthread_data.time, $
			 speedup:tthread_data.speedup, $
			 version:tthread_data.version, $
			 date:tthread_data.date, $
			 hostname:tthread_data.hostname, $
		         ncpu:tthread_data.ncpu, $
			 nthreads:tthread_data.nthreads, $
		         p:tthread_data.p, $
		         plot_title:'Floating Point Binop (b = a + a)' }
      endelse
      catch,/cancel
  endif else begin
      if (n_elements(min) eq 0) then min = 0
      if (n_elements(max) eq 0) then max = 20000000
      l_min = long((min lt 0) ? 0 : min)
      l_max = long((max lt min) ? min : max)
      if (n_elements(step) eq 0) then step = long((l_max - l_min) * .10)
      l_step = long((step le 0) ? long((l_max - l_min) * .10) : step)

      if (n_elements(niter) eq 0) then niter=5	; # of times to run each case

      save_nthreads = !CPU.TPOOL_NTHREADS
      max_nthreads = save_nthreads gt 1 ? save_nthreads : 2
      save_min_thread_elts = !CPU.TPOOL_MIN_ELTS
      CPU, tpool_min_elts=0

      nelts = (lindgen((l_max - l_min) / l_step + 1) * l_step) + l_min
      ; If the first computation is on 0 points, change that to the number
      ; of CPUs on the system. This will cause the thread pool to be used
      ; on the smallest possible case.
      if (nelts[0] eq 0) then nelts[0] = !cpu.hw_ncpu
      nnelts = n_elements(nelts)

      times = fltarr(nnelts, max_nthreads)
      speedup = fltarr(nnelts, max_nthreads)
      if (do_verbose) then print, plot_title
      for ncpu=1, max_nthreads do begin
        CPU, TPOOL_NTHREADS=ncpu
        if (do_verbose) then begin
          print, 'Number of threads: ', ncpu
	  help,/st,!cpu
        endif
    
	for i = 0, nnelts-1 do begin
          npts = nelts[i]
          times[i, ncpu-1] = tthread_internal(npts, niter, SQRT=do_sqrt)
    
	  if (do_verbose) then begin
            if (ncpu eq 1) then begin
              print, format='("    Time for 1 CPU on ", I0, " points: ", ' $
	                   +'T55, F7.3)', $
    	        npts, times[i, ncpu-1]
            endif else begin
              print, format='("    Time/Speedup for ", I0, " CPUs on ", I0' $
    		       +', " points: ", T55, F7.3, 4X, F7.3)', $
    	        ncpu, npts, times[i, ncpu-1], times[i, 0]/times[i, ncpu-1]
            endelse
          endif
        endfor
      endfor
      CPU, TPOOL_NTHREADS=save_nthreads, TPOOL_MIN_ELTS=save_min_thread_elts
    
    
      for ncpu=0, max_nthreads-1 do begin
        speedup[*, ncpu] = times[*, 0] / times[*, ncpu]
      endfor

      ; Pack the results in a final data structure
      hname = ''
      case !version.os_family of
        'unix' : begin spawn, 'hostname', hname & hname=hname[0] & end
        'Windows':  begin spawn, 'hostname', hname, /HIDE & hname=hname[0] &end
      endcase

      ; Use unqualified (no domain) hostname
      pos = strpos(hname, '.')
      if (pos ne -1) then hname = strmid(hname, 0, pos)

      tthread_data = { nelts:nelts, time:times, speedup:speedup, $
		       version:!version, date:systime(), hostname:hname, $
		       ncpu:!cpu.hw_ncpu, nthreads:max_nthreads, $
		       p:tthread_calc_p(speedup), plot_title:plot_title }

  endelse

  ; Produce the requested plots, if any
  if keyword_set(plot) then tthread_plot, tthread_data
  if (keyword_set(ps_plot)) then $
	tthread_plot, tthread_data, PS_PLOT=ps_plot
  if (keyword_set(png_plot)) then $
	tthread_plot, tthread_data, PNG_PLOT=png_plot

  ; Save the data if requested.
  if (keyword_set(save)) then begin
    file = (size(save, /TYPE) eq 7) ? save : 'tthread.sav'
    SAVE, tthread_data, file=file, verbose=do_verbose
    MESSAGE,/INFORMATIONAL, 'Data saved in: ' +  file
  endif


end
