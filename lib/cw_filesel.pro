; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_filesel.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
; CW_FILESEL
;
; PURPOSE:
;       This is a compound widget for file selection.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = CW_FILESEL(Parent)
;
; INPUTS:
;       Parent - The widget ID of the parent.
;
; OPTIONAL KEYWORDS:
;
;        FILENAME
;        Set this keyword to have the initial filename filled in the filename text area.
;
;        FILTER - Set this keyword to an array of strings determining the
;                 filter types.  If not set, the default is "All Files".  All
;                 files containing the chosen filter string will be displayed
;                 as possible selections.  "All Files" is a special filter
;                 which returns all files in the current directory.  A single
;         filter "field" may have several filters separated by a comma.
;
;                 Example:  FILTER=['All Files', '.txt', '.jpg,.jpeg']
;
;        FIX_FILTER - If set, the user can not change the file filter.
;
;        FRAME - If set, a frame is drawn around the widget.
;
;        IMAGE_FILTER - If set, the filter "Image Files" will be added to the
;                 list of filters.  If set, and FILTER is not set,
;                 "Image Files" will be the only filter displayed.  Valid
;                 image files are determined from QUERY_IMAGE.
;
;        MULTIPLE - If set, the file selection list will allow multiple
;                 filenames to be selected.  The filename text area will not
;                 be editable in this case.  MULTIPLE and SAVE are exclusive
;                 keywords.
;
;        PATH - Set this keyword to the initial path the widget is to start
;                 in.  The default is the current directory.
;
;        SAVE - If set, the dialog will change to a file saving interface.
;               The "Open" button changes to "Save" and the "Filter" dialog
;               is named "Save as:".  SAVE and MULTIPLE are exclusive keywords.
;
;        UVALUE - The "user value" to be assigned to the widget.
;
;        UNAME - The "user name" to be assigned to the widget.
;
;        WARN_EXIST - If set, the user is warned if a filename is chosen
;               that matches an already existing file. This is useful in
;               routines that save to a file.
;
; OUTPUTS:
; This function returns its Widget ID.
;
; EXAMPLE:
;
;       fileSel = CW_FILESEL(myBase)
;
;   Using CW_FILESEL
;     The widget has a string value that is the currently-selected filename:
;       WIDGET_CONTROL, fileSel, GET_VALUE=filename
;     To set the filename, use the command:
;       WIDGET_CONTROL, fileSel, SET_VALUE=string
;
; MODIFICATION HISTORY:
;   Written by: Scott Lasica, July, 1998
;   CT, RSI, July 2000: Minor rewrite. Change dir sorting on Windows.
;               Added WARN_EXIST.
;-
;

function Filename_Path_Sep, fullName, PATH=path

  COMPILE_OPT HIDDEN, STRICTARR

  filename = ''
  path = ''

  delimit = STRPOS(fullName, PATH_SEP(), /REVERSE_SEARCH)

  if (delimit gt -1) then begin
    filename = STRMID(fullName, delimit+1)
    path = STRMID(fullName, 0, delimit+1)
  endif $
  else begin
    filename = fullName
    path=''
  endelse

  return, filename
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION cw_fileSel_continue, fullfilename, filename, action, id

    compile_opt hidden, strictarr

    if ~FILE_TEST(fullfilename) then $
        return, 1

    result = DIALOG_MESSAGE([filename + ' already exists.', $
        'Continue with ' + action + '?'], $
        DIALOG_PARENT=id, $
        /DEFAULT_NO, /QUESTION, TITLE='File Exists')
    RETURN, (result EQ 'Yes')
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro cw_fileSel_dirHelp, files, filter

    compile_opt hidden, strictarr

    if (filter eq 'All Files') then $
        return

    if (filter ne 'Image Files') then begin
        mfilter = (STRPOS(filter, ',') ne -1) ? $
            STRTOK(filter, ',', /EXTRACT) : filter
        oldFiles = files
        files = ''
        mfilter = STRUPCASE(STRTRIM(mfilter, 2))
        for i=0,N_ELEMENTS(mfilter)-1 do begin
            test = WHERE(STRPOS(STRUPCASE(oldFiles), mfilter[i]) ge 0)
            if (test[0] ne -1) then $
                files = [files, oldFiles[test]]
        endfor
        files = (N_ELEMENTS(files) gt 1) ? files[1:*] : -1
    endif else begin
        ; This needs to query the image types
        for i = 0,N_ELEMENTS(files)-1 do begin
            CATCH, errorStatus
            if (errorStatus ne 0) then continue
            if (~QUERY_IMAGE(files[i])) then $
                files[i] = ''
        endfor
        CATCH, /CANCEL
        MESSAGE, /RESET
        test = WHERE(files ne '')
        files = (test[0] ne -1) ? files[test] : -1
    endelse

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This function will return a string array of all the directories and
;; image files for the current dir
;
function cw_fileSel_GetDirs, FILTER = filter

    compile_opt hidden, strictarr

    WIDGET_CONTROL,/HOURGLASS

    ; Return only directories, with the trailing path separator.
    ; Don't rely on FILE_SEARCH to sort, since it always does case sensitive.
    dirs = FILE_SEARCH(COUNT=dcount, /MATCH_INITIAL_DOT, $
        /MARK_DIRECTORY, /NOSORT, /TEST_DIRECTORY)
    ; Use a case-insensitive sort on Windows, otherwise case sensitive.
    s = SORT((!VERSION.os_family eq 'Windows') ? STRUPCASE(dirs) : dirs)
    dirs = dirs[s]

    ; Return only files.
    ; Don't rely on FILE_SEARCH to sort, since it always does case sensitive.
    files = FILE_SEARCH(count=fcount, /MATCH_INITIAL_DOT, $
        /NOSORT, /TEST_REGULAR)
    ; Use a case-insensitive sort on Windows, otherwise case sensitive.
    s = SORT((!VERSION.os_family eq 'Windows') ? STRUPCASE(files) : files)
    files = files[s]

    if (fcount gt 0) then begin
        ; Pick out only the image files.
        CW_FILESEL_DIRHELP, files, filter
        fcount = (SIZE(files[0], /TYPE) eq 7) ? N_ELEMENTS(files) : 0
    endif

    if (dcount && fcount) then $
        return, [dirs, files]
    if (dcount gt 0) then $
        return, dirs
    if (fcount gt 0) then $
        return, files

    return, -1

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check if at top of directory
FUNCTION cwfileSel_atTop, path

  compile_opt hidden, strictarr

  CASE !version.os_family OF
    'Windows': atTop = (STRMID(path, STRLEN(path)-2) EQ ':\')
    else:  atTop = (path EQ '/')
  ENDCASE
  RETURN, atTop
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make sure path ends in correct character
FUNCTION cwfileSel_fixPath, path

    compile_opt hidden, strictarr

    pathsep = PATH_SEP()
    if (STRMID(path, STRLEN(path)-1) ne pathsep) then $
        path += pathsep
    RETURN, path
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Event handler
function cwfileSel_event, ev

  COMPILE_OPT HIDDEN, STRICTARR

  WIDGET_CONTROL,/HOURGLASS
  filename=''
  parent = ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

  report_error = 1

  catch, error_status
  if (error_status ne 0) then begin
  IF report_error THEN result=DIALOG_MESSAGE(!ERROR_STATE.msg,/ERROR)
  WIDGET_CONTROL, stash, SET_UVALUE=state,/NO_COPY
  return,0
  endif

  new_event = 0  ; assume no event passed on

  case (ev.id) of
      state.dirPull: begin
        WIDGET_CONTROL, state.fnameText, $
      SET_VALUE=''
    state.filename = ''
        drives = get_drive_list()
        if (drives[0] ne '') then begin
          cd, drives[ev.index]
            cd, CURRENT=currDir
            state.path = currDir
            if (PTR_VALID(state.mfilename)) then $
            PTR_FREE, state.mfilename
      PTR_FREE, state.dFiles
            dFiles=cw_filesel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
            state.dFiles = PTR_NEW(dFiles)

            if (SIZE(dFiles,/TYPE) ne 7) then $
              WIDGET_CONTROL, state.fileList, SENSITIVE=0, SET_VALUE='' $
            else $
              WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, SENSITIVE=1
            WIDGET_CONTROL, state.upBut, SENSITIVE=0
      WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
    endif
      end
      state.upBut: begin
        WIDGET_CONTROL, state.fnameText, $
      SET_VALUE=''
    state.filename = ''
    cd, state.path
    cd, '..'
    cd, CURRENT=topCheck
    state.path = topCheck
    IF cwfileSel_atTop(topCheck) THEN $
      WIDGET_CONTROL, state.upBut, SENSITIVE=0
    PTR_FREE, state.dFiles
    dFiles = cw_filesel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
    state.dFiles = PTR_NEW(dFiles)
    if (SIZE(dFiles,/TYPE) ne 7) then $
      WIDGET_CONTROL, state.fileList, SENSITIVE=0, SET_VALUE='' $
    else $
      WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, SENSITIVE=1
    WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
    cd,state.oldPath
      end

      state.pathLab: begin
    WIDGET_CONTROL, state.pathLab, GET_VALUE=newPath
    IF (newPath[0] NE state.path) THEN BEGIN
      WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
      report_error = 0   ; turn off "can't change directory" warning
      cd, newPath[0]
      report_error = 1   ; turn on error messages
      cd, CURRENT=topCheck
      state.path = topCheck
      WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
      atTop = cwfileSel_atTop(topCheck)
      WIDGET_CONTROL, state.upBut, SENSITIVE=1-atTop
      PTR_FREE, state.dFiles
      dFiles = cw_filesel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
      state.dFiles = PTR_NEW(dFiles)

      if (SIZE(dFiles,/TYPE) ne 7) then $
      WIDGET_CONTROL, state.fileList, SENSITIVE=0, SET_VALUE='' $
      else $
      WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, SENSITIVE=1
      cd,state.oldPath
    ENDIF
      end

      state.fileList: begin
      isDirectory = STRPOS((*state.dFiles)[ev.index], PATH_SEP()) ne -1
      IF isDirectory THEN BEGIN
    WIDGET_CONTROL, state.fnameText, $
      SET_VALUE=''
    state.filename = ''
      ENDIF
    CASE (ev.clicks) OF
    1: begin  ; single click
        if (isDirectory) then break
        if (not state.multiple) then begin
          WIDGET_CONTROL, state.fnameText, $
            SET_VALUE=(*state.dFiles)[ev.index]
          state.filename = (*state.dFiles)[ev.index]
        endif else begin
          PTR_FREE,state.mfilename
          selected = WIDGET_INFO(state.fileList,/LIST_SELECT)
          if (selected[0] ne -1) then begin
            state.mfilename = PTR_NEW((*state.dFiles)[selected])
            state.filename = (*state.dFiles)[ev.index]
          endif
          fileLabels = STRING('"'+*state.mfilename+'"', $
            FORMAT='(32767(A,:,1x))')
          WIDGET_CONTROL, state.fnameText, $
            SET_VALUE=fileLabels
        endelse
        filename = state.filename
          path=state.path
        theFilter = (*state.filters)[state.filtIndex]
        path = cwfileSel_fixPath(path)
        new_event = {FILESEL_EVENT, parent, ev.top, 0L, $
          path+filename, 0L, theFilter}
      end  ; single-click
    2: begin  ; double-click
            if (isDirectory) then begin
              cd, state.path
              cd, (*state.dFiles)[ev.index]
              cd, CURRENT=currDir
              state.path = currDir

        WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
              if (PTR_VALID(state.mfilename)) then $
              PTR_FREE, state.mfilename
        PTR_FREE, state.dFiles
              dFiles=cw_filesel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
              state.dFiles = PTR_NEW(dFiles)

              if (SIZE(dFiles,/TYPE) ne 7) then $
                WIDGET_CONTROL, state.fileList, SENSITIVE=0, SET_VALUE='' $
              else $
                WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, SENSITIVE=1
              WIDGET_CONTROL, state.upBut, SENSITIVE=1

              cd, state.oldPath
          endif else begin
              state.filename = (*state.dFiles)[ev.index]
              filename = state.filename
              path = state.path
              theFilter = (*state.filters)[state.filtIndex]
            path = cwfileSel_fixPath(path)
              continue = 1
        IF state.warn_exist THEN BEGIN
          WIDGET_CONTROL, state.openBut, GET_VALUE=areWeSave
        continue = CW_FILESEL_CONTINUE(path+filename, $
          filename, areWeSave, ev.handler)
        ENDIF
        IF continue THEN BEGIN
                WIDGET_CONTROL, state.pathLab, SET_VALUE=state.path
                new_event = {FILESEL_EVENT, parent, ev.top, 0L, $
                  path+filename, 1L, theFilter}
            ENDIF
            endelse
          end  ; double-click
        endcase  ; ev.click
      end
      state.fnameText: begin
          WIDGET_CONTROL, ev.id, GET_VALUE=filename
          state.filename = filename
      end
      state.filtPull: begin
          cd,state.path
          state.filtIndex = ev.index
        PTR_FREE, state.dFiles
          dFiles=cw_filesel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
          state.dFiles = PTR_NEW(dFiles)
          if (SIZE(dFiles,/TYPE) ne 7) then $
            WIDGET_CONTROL, state.fileList, SENSITIVE=0, $
            SET_VALUE='' $
          else $
            WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, $
            SENSITIVE=1
          theFilter = (*state.filters)[state.filtIndex]
          cd,state.oldPath
          new_event = {FILESEL_EVENT, parent, ev.top, 0L, '', 0L, theFilter}
      end
      state.openBut: begin
          cd,state.path
          test = FILE_SEARCH(state.filename, COUNT=cnt)
          filename = state.filename
          path = state.path
          WIDGET_CONTROL, state.openBut, GET_VALUE=areWeSave
          if ((cnt gt 0) or (areWeSave eq 'Save')) then begin
              continue = 1
        IF state.warn_exist THEN BEGIN
        continue = CW_FILESEL_CONTINUE(state.filename[0], $
            filename, areWeSave, ev.handler)
        ENDIF
        IF continue THEN BEGIN
              theFilter = (*state.filters)[state.filtIndex]
          cd,state.oldPath
              path = cwfileSel_fixPath(path)
              new_event = {FILESEL_EVENT, parent, ev.top, 0L, $
                path+filename, 1L, theFilter}
          ENDIF
          endif $
          else begin
              void = DIALOG_MESSAGE('File not found: '+filename, /ERROR)
              filename=''
          endelse
  skipsave:
          cd,state.oldPath
      end
      state.cancBut: begin
      state.filename = ''
      state.path = ''
      PTR_FREE, state.mfilename
      state.mfilename = PTR_NEW()
      WIDGET_CONTROL, state.fnameText, SET_VALUE=''
      theFilter = (*state.filters)[state.filtIndex]
        new_event = {FILESEL_EVENT, parent, ev.top, 0L, '', 2L, theFilter}
      end
      else: begin
          result=DIALOG_MESSAGE('Unknown event.',/ERROR)
      end
  endcase

  WIDGET_CONTROL, stash, SET_UVALUE=state,/NO_COPY
  RETURN, new_event
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Set Value
;;
pro CWFILESEL_SET_VALUE, id, value

  COMPILE_OPT HIDDEN, STRICTARR

  ;;Retrieve the state information.
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

  if ((N_ELEMENTS(value) eq 1) and (SIZE(value[0],/TYPE) eq 7)) then begin
    filename = Filename_Path_Sep(value, PATH=path)
    state.filename = filename
    state.path = path
    cd, state.path
    cd, CURRENT=currDir
    state.path = currDir
    if (PTR_VALID(state.mfilename)) then $
      PTR_FREE, state.mfilename
    PTR_FREE, state.dFiles
    dFiles = cw_fileSel_GetDirs(FILTER=(*state.filters)[state.filtIndex])
    state.dFiles = PTR_NEW(dFiles)
    if (SIZE(files,/TYPE) ne 7) then $
      WIDGET_CONTROL, state.fileList, SENSITIVE=0, SET_VALUE='' $
    else $
      WIDGET_CONTROL, state.fileList, SET_VALUE=dFiles, SENSITIVE=1

    WIDGET_CONTROL, state.fnameText, SET_VALUE=value
    if (state.multiple) then begin
      PTR_FREE, state.mfilename
      fullNames = value
      filenames = STRARR(N_ELEMENTS(fullNames))
      filenames[0] = Filename_Path_Sep(fullNames[0], PATH=path)
      state.path=path
      for i=1, N_ELEMENTS(fullNames)-1 do begin
        filenames[i] = Filename_Path_Sep(fullNames[i])
      endfor
      state.mfilename = PTR_NEW(filenames)
    endif
    cd, state.oldPath
  endif

  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Get Value
;;
function CWFILESEL_GET_VALUE, id

  COMPILE_OPT HIDDEN, STRICTARR

  ;;Retrieve the state information.
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

  path = state.path
  if (path ne '') then $
    path += PATH_SEP()

  if (state.multiple) then $
    ret = path+(*state.mfilename) $
  else $
    ret = path+state.filename

  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Kill - so clean up
pro CWFILESEL_KILL, id

  COMPILE_OPT HIDDEN, STRICTARR

  ;;Retrieve the state information.
  WIDGET_CONTROL, id, GET_UVALUE=state, /NO_COPY
  cd,state.oldPath
  PTR_FREE, state.dFiles, state.filters, state.mfilename
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Realize the widget
pro CWFILESEL_REALIZE, id

  COMPILE_OPT HIDDEN, STRICTARR

  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

  cd, CURRENT=topCheck
  IF cwfileSel_atTop(topCheck) THEN $
    WIDGET_CONTROL, state.upBut, SENSITIVE=0

  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main function
function CW_FILESEL, parent, $
                 FILENAME = filename, $
                     FILTER = filters, $
                     FIX_FILTER = fix, $
                     FRAME = frame, $
                     IMAGE_FILTER = igFilter, $
                     MULTIPLE = mult, $
                     PATH = path, $
                     SAVE = save, $
                     TAB_MODE = tab_mode, $
                     UVALUE = uval, $
                     UNAME = uname, $
                     WARN_EXIST = warn_exist

COMPILE_OPT strictarr
  defining = {FILESEL_EVENT, $
              ID: 0L, $
              TOP: 0L, $
              HANDLER: 0L, $
              VALUE: '', $
              DONE: 0L, $
        FILTER: '' $
  }

  state = {dirPull:   0L, $
           upBut:     0L, $
           openBut:   0L, $
           cancBut:   0L, $
           fileList:  0L, $
           pathLab:   0L, $
           multiple:  0L, $
           fnameText: 0L, $
           filtPull:  0L, $
           filtIndex: 0L, $
           filters:   PTR_NEW(), $
           dFiles:     PTR_NEW(), $
           oldPath:   '', $
           currPath:  '', $
           path:      '', $
           filename:  '', $
           mfilename: PTR_NEW(), $
           warn_exist: KEYWORD_SET(warn_exist) $
          }

  on_error, 2

  if (N_ELEMENTS(filename) gt 0) then $
    state.filename = Filename_Path_Sep(filename, PATH=tPath)

  if (not WIDGET_INFO(parent, /VALID_ID)) then $
    MESSAGE, 'Invalid widget identifier.'

  if (KEYWORD_SET(save) and KEYWORD_SET(mult)) then $
    MESSAGE, 'Exclusive keyword error: SAVE, MULTIPLE'

  if (not KEYWORD_SET(frame)) then frame = 0
  if (not KEYWORD_SET(uval)) then uval = 0
  if (not KEYWORD_SET(uname)) then uname = 'CW_FILESEL_UNAME'
  if (not KEYWORD_SET(fix)) then no_edit = 0
  if (not KEYWORD_SET(mult)) then mult = 0
  state.multiple = mult

  base = WIDGET_BASE(parent, /COLUMN, FRAME=frame, UVALUE=uval, UNAME=uname, $
                     EVENT_FUNC='CWFILESEL_EVENT', $
                     FUNC_GET_VALUE='CWFILESEL_GET_VALUE', $
                     PRO_SET_VALUE='CWFILESEL_SET_VALUE', $
                     NOTIFY_REALIZE='CWFILESEL_REALIZE')

  if ( N_ELEMENTS(tab_mode) ne 0 ) then $
    WIDGET_CONTROL, base, TAB_MODE = tab_mode

  ;; Top row for directory changing
  dirRow = WIDGET_BASE(base, /ROW, KILL_NOTIFY='CWFILESEL_KILL')

  if (N_ELEMENTS(path) gt 0) then begin
      cd, CURRENT=oldPath, path
      state.oldPath = oldPath
      state.path = path
  endif $
  else begin
      cd, CURRENT=path
      state.path = path
      state.oldPath = path
  endelse

  if (N_ELEMENTS(filters) ne 0) then filtMask = 1 else filtMask = 0
  if (KEYWORD_SET(igFilter)) then igMask = 1 else igMask = 0

  if (filtMask and igMask) then filters = [filters, 'Image Files']
  if (not filtMask and igMask) then filters = 'Image Files'
  if (not filtMask and not igMask) then filters = 'All Files'

  PTR_FREE, state.dFiles, state.filters
  dFiles = cw_fileSel_GetDirs(FILTER=filters[0])
  if (SIZE(dFiles,/TYPE) ne 7) then dFiles=''
  state.dFiles = PTR_NEW(dFiles)
  state.filters = PTR_NEW(filters)

  bitmap_filename = FILEPATH('up1lvl.bmp', ROOT_DIR = IDL_DIR,$
  SUBDIRECTORY = ['resource','bitmaps'])

  case !VERSION.OS_FAMILY of
    'Windows': begin
      driveVol = 'Drive:'
      drives = get_drive_list()
      drive_loc = (WHERE(STRUPCASE(STRMID(path,0,STRPOS(path,'\')+1)) eq STRUPCASE(drives)) > 0)[0]
    end
  else: begin
    driveVol = ''
  end
  endcase

  if (driveVol ne '') then begin
    label = WIDGET_LABEL(dirRow, VALUE=driveVol)
    state.dirPull = WIDGET_DROPLIST(dirRow, VALUE=drives, $
      UVALUE='dirPull', $
      XSIZE=100, $
      UNAME='CW_FILESEL_DIR_DROPLIST')
    WIDGET_CONTROL, state.dirPull, SET_DROPLIST_SELECT=drive_loc
  endif

  pathLabBase = WIDGET_BASE(base, /ROW)
  state.upBut = WIDGET_BUTTON(pathLabBase, VALUE=bitmap_filename, $
    UVALUE='upBut', UNAME='CW_FILESEL_DIR_BUTTON',/BITMAP,/DYNAMIC_RESIZE)

  ;; Path listing
  state.pathLab = WIDGET_TEXT(pathLabBase, VALUE=path, XSIZE=28, YSIZE=1, $
    EDITABLE=(driveVol EQ ''))

  ;; File list for current dir
  state.fileList = WIDGET_LIST(base, VALUE=dFiles, $
    UVALUE='fileList',$
    MULTIPLE=mult, $
    UNAME='CW_FILESEL_FILELIST', $
    YSIZE=8)

  ;; Filename, filter, buttons
  fileBase = WIDGET_BASE(base, COLUMN=2)

  state.fnameText = CW_FIELD(fileBase, TITLE='File name:', UVALUE='fnameText',$
                             /ALL_EVENTS, NOEDIT=(mult), VALUE=state.filename, $
                             UNAME='CW_FILESEL_FILENAME')

  if (KEYWORD_SET(save)) then begin
      butVal = 'Save'
      filtTitle = 'Save as:'
  endif $
  else begin
      butVal = 'Open'
      filtTitle = 'Filter:'
  endelse

  if (KEYWORD_SET(fix)) then $
    filters = filters[0]
  state.filtPull = WIDGET_DROPLIST(fileBase, VALUE=filters, UVALUE='filtPull',$
                                   TITLE=filtTitle, UNAME='CW_FILESEL_FILTER')

  state.openBut = WIDGET_BUTTON(fileBase, VALUE=butVal, UVALUE='openBut', UNAME='CW_FILESEL_OPEN')
  state.cancBut = WIDGET_BUTTON(fileBase, VALUE='Cancel', UVALUE='cancBut', UNAME='CW_FILESEL_CANCEL')

  WIDGET_CONTROL, CANCEL_BUTTON=state.cancBut, $
    DEFAULT_BUTTON=state.openBut
  cd, state.oldPath

  WIDGET_CONTROL, WIDGET_INFO(base,/CHILD), SET_UVALUE = state, /NO_COPY

  return, base
end


