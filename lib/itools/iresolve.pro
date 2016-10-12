; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iresolve.pro#3 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; Name:
;   iRESOLVE
;
; Purpose:
;   Resolves all IDL code within the iTools directory, as well
;   as all other necessary IDL code. Useful for constructing save
;   files containing user code that requires the iTools framework.
;
; Arguments:
;   None.
;
; Keywords:
;   PATH: Set this keyword to a string giving the full path to the iTools
;       directory. The default is to use the lib/itools subdirectory
;       within which the iRESOLVE procedure resides.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, June 2003
;   Modified:
;


;-------------------------------------------------------------------------
pro iresolve, PATH=pathIn

    compile_opt idl2, hidden

    if (N_ELEMENTS(pathIn) gt 0) then begin
        path = pathIn
    endif else begin
        ; Assume this program is in a subdirectory of iTools.
        path = FILE_DIRNAME((ROUTINE_INFO('iresolve', $
            /SOURCE)).path, /MARK_DIR)
        ; Add Graphics directory
        path =[path, FILE_SEARCH(path[0]+'../graphics', /MARK_DIRECTORY)]
        ; Add Datatypes directory
        path =[path, FILE_SEARCH(path[0]+'../datatypes', /MARK_DIRECTORY)]
    endelse

    filenames = FILE_SEARCH(path, '*.pro', /FULLY_QUALIFY)

    ; Files which we don't need (or can't) compile.
    excludelist=[ $
        'idlit_catch','idlit_on_error2', 'idlit_itoolerror', $
        'idlitconfig', 'cw_iterror', $   ;  @ includes
        '_idlitcreatesave', $  ; don't include ourself
        ; Can't compile methods by themselves (see classlist below).
        'idlitcomponent___copyproperty', $
        'idlitsystem__registertoolfunctionality',$
        'idlittool__updateavailability', $
        'export_envi__define', $
        'export_envioview__define', $
        'idlcfembeddeduienvi', $
        'idlcfgrwinscene__define', $
        'idlcfuienvieclipseadaptor__define', $
        ; Resolve routines
        'resolve_all', $
        'resolve_all_body', $
        'resolve_all_class', $
        ; Graphics
        'graphic_error', $
        ; Datatypes
        'mksav_hash', 'mksav_hash__define', 'mksav_idl_hashcode', $
        'mksav_list', 'mksav_list__define']

    ; These are classes which have methods outside of their __define files,
    ; or whose class definitions are in C code.
    classlist = ['idlittool', $
        'idlitsystem', $
        'idlitcomponent', $
        'idlfflangcat', $
        'idlgrtextedit', $
        'trackball']

    filenames = FILE_BASENAME(filenames, '.pro')

    for i=0,N_ELEMENTS(excludelist)-1 do $
        filenames = filenames[WHERE(filenames ne excludelist[i])]

    RESOLVE_ROUTINE, filenames, /EITHER, $
        /COMPILE_FULL_FILE, /NO_RECOMPILE

    RESOLVE_ALL, CLASS=classlist, /QUIET
    
    ; Add read and query routines from iGetReaders
    ; These routines are listed in the idlextensions.xml file and might not get
    ; compiled through any use of RESOLVE_*
    RESOLVE_ROUTINE, 'igetreaders', /EITHER, $
      /COMPILE_FULL_FILE, /NO_RECOMPILE
    readers = iGetReaders()
    for i=0,N_ELEMENTS(readers[0,*])-1 do begin
      catch, err
      if (err eq 0) then begin
        ; Resolve reader routine
        RESOLVE_ROUTINE, readers[0,i], /EITHER, $
            /COMPILE_FULL_FILE, /NO_RECOMPILE

        ; Resolve any additional routines that are accessed 
        ; via CALL_[PROCEDURE|FUNCTION].
        ; This list has to be hardcoded for now
        if (STRPOS(STRUPCASE(readers[0,i]), 'HDF5') ne -1) then $
          RESOLVE_ROUTINE, 'h5_parse', /EITHER, $
            /COMPILE_FULL_FILE, /NO_RECOMPILE
        if (STRPOS(STRUPCASE(readers[0,i]), 'READ_IMAGE') ne -1) then $
          RESOLVE_ROUTINE, 'query_image', /EITHER, $
            /COMPILE_FULL_FILE, /NO_RECOMPILE

        ; Resolve query routine
        if (readers[4,i] ne '') then $
          RESOLVE_ROUTINE, readers[4,i], /EITHER, $
              /COMPILE_FULL_FILE, /NO_RECOMPILE
      endif else begin
        ; If read/query routine is not in the current path, or is C code,
        ; handle error and continue
        catch, /cancel
        message, /reset
        continue
      endelse
    endfor
    
    ; Restore any save files
    filenames = FILE_SEARCH(path, '*.sav', /FULLY_QUALIFY)
    if (MAX(filenames ne '') ne 0) then $
      for i=0,N_ELEMENTS(filenames)-1 do $
        RESTORE, filenames[i]
    
end

