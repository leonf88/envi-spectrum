; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitopensav.pro#1 $
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
;+
; :Description:
;    Open an IDL SAV file. If this is a data SAV file then
;    restore the variables in the current scope,
;    otherwise launch the SAV file routine in IDL runtime.
;    
;    *Note*: For internal use by the IDL Workbench.
;
; :Params:
;    filename
;
; :Author: chris
;-
pro _IDLitOpenSAV, filename

    compile_opt idl2, hidden

    On_Error, 2
    
    Catch, iErr
    if (iErr ne 0) then begin
      Catch, /Cancel
      if (Obj_Valid(oSaveFile)) then $
        Obj_Destroy, oSaveFile
      Message, /REISSUE_LAST
    endif
    
    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'

    oSaveFile = OBJ_NEW('IDL_Savefile', filename, /RELAXED_STRUCTURE_ASSIGNMENT)
    contents = oSaveFile->Contents()
    
    
    if (contents.n_procedure gt 0 || contents.n_function gt 0) then begin

      Obj_Destroy, oSaveFile
      
      ; Launch IDL runtime and run the contained procedures.

      MESSAGE, /INFO, /NONAME, 'Launching: ' + filename
      
      isWin = !version.OS_FAMILY eq 'Windows'
      
      arg0 = !DIR + path_sep() + 'bin' + path_sep()
      
      ; Watch out for folders with quotes. See b51997.
      file = Strjoin(Strtok(filename, "'", /EXTRACT), "''")

      if (isWin) then begin
        arg0 += (!version.MEMORY_BITS eq 32) ? 'bin.x86' : 'bin.x86_64'
        arg0 += path_sep() + 'idlrt.exe'
        ; Surround with quotes in case there are spaces.
        arg1 = '"' + file + '"'
        ; On Windows, do not display a shell, and do not block.
        SPAWN, /NOSHELL, /NOWAIT, [arg0, arg1]
      endif else begin
        ; On Unix we also need to escape double quotes.
        file = Strjoin(Strtok(file, '"', /EXTRACT), '"\""')
        ; Surround with quotes in case there are spaces.
        arg1 = '"' + file + '"'
        ; On Unix, we need to use shell processing and the nowait keyword
        ; doesn't exist. Be sure to put the process in the background.
        cmd = arg0 + 'idl -rt=' + arg1 + ' &'
        SPAWN, cmd
      endelse
    
    endif else begin
    
      ; Restore the data file.
      
      MESSAGE, /INFO, /NONAME, 'RESTORE: ' + filename
      
      var = oSaveFile->Names()
  
      for i=0, n_elements(var)-1 do begin
        if (var[i] eq '') then continue
        oSaveFile->Restore, var[i], /VERBOSE
        ; Restore the data into the current IDL stack frame (one level up).
        res = Execute('(SCOPE_VARFETCH(var[i], LEVEL=-1, /ENTER)) = Temporary('+var[i]+')')
      endfor
      
      Obj_Destroy, oSaveFile
      
    endelse

end
