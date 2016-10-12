; $Id: //depot/idl/releases/IDL_80/idldir/lib/pref_migrate.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


pro pref_migrate_mark
  ; Ensure that the pref_migrate file exists. The IDL kernel checks for
  ; this file at startup in order to decide whether or not PREF_MIGRATE
  ; has ever run.

  dir =  APP_USER_DIR_QUERY('itt', 'pref', /RESTRICT_IDL_RELEASE, $
				  /RESTRICT_FAMILY, count=count)
  if (count eq 1) then begin
    file = dir[0] + path_sep() + 'pref_migrate'
    if (~ FILE_TEST(file)) then begin
      OPENW, u, file, /GET_LUN
      printf, u, 'File:    ', file
      printf, u, 'Purpose: PREF_MIGRATE Marker File'
      login = get_login_info()
      printf, u, 'User:    ', login.user_name, '@', login.machine_name
      printf, u, 'Date:    ', systime()
      printf, u, format='(%"Creator: IDL %s (%s %s m%d f%d)")', $
	     !version.release, !version.os, !version.arch, $
	     !version.memory_bits, !version.file_offset_bits
      printf, u, ''
      printf, u, 'This is your PREF_MIGRATE marker file. It was created'
      printf, u, 'by the PREF_MIGRATE routine the first time it ran.'
      printf, u, 'IDL uses the existance of this file to indicate that'
      printf, u, 'it has already offered to migrate preferences from older'
      printf, u, 'versions of IDL and to avoid doing so more than once.'
      printf, u, ''
      printf, u, 'You may remove this file. If you do, IDL will believe'
      printf, u, 'that PREF_MIGRATE has not run yet, and will run it'
      printf, u, 'the next time you run it in normal interactive mode.'
      FREE_LUN, u
    endif
  endif

end







function pref_migrate_ok, num_potential
  ;
  ; Called if PREF_MIGRATE is run with the STARTUP keyword and there
  ; are preferences files for other versions that can be migrated. STARTUP
  ; is set by the IDL executive at startup when IDL detects that the user
  ; has no preference file. Since the user didn't explicitly
  ; start us in this situation, they need to be told why we're running,
  ; and be given a chance to decline our services.
  ;
  ; entry:
  ;	num_potential - Number of IDL versions from which preferences
  ;		are available.
  ; exit:
  ;     Returns 1 for OK, and 0 if our services are not desired.


  text = [ 'This appears to be the first time you are running' , $
	   'this version of IDL. IDL allows you to specify', $
      'user preferences to set defaults for certain aspects', $
	   'of its operation. Preferences are specific to', $
	   'the version of IDL that set them.', $
	   '', $
           'You have previously specified non-default user preferences', $
           'for ' + STRING(num_potential, format='(I0)') $
	       + ' other versions of IDL on this system. IDL can assist', $
	   'you in migrating them to this version.', $
	   '', $
	   'Would you like to copy your IDL preference settings', $
	   'from another version of IDL?' ]

  ; Gotcha for X11 versions of IDL: What if there's no server
  ; available? Normally, the usual X error would be fine, but since
  ; the user didn't run us explicitly, they're going to be confused
  ; unless we handle it. So, we issue a message saying that we
  ; can't run, suggest that they run us manually later, and tell our
  ; caller "no".
  ;
  ; The only way to know you can't get a server is to try it and
  ; see. The abscence of the DISPLAY variable doesn't mean "no",
  ; and the presence of it does not mean "yes". Hence, the CATCH block.
  CATCH, err
  if (err ne 0) then begin
    CATCH,/CANCEL
    MESSAGE, /continue, /noname, $
    	'This appears to be the first time you are running this version of IDL. ' + $
    	'IDL would like to run the PREF_MIGRATE utility to help you copy your ' + $
    	'IDL preference settings from another version of IDL, but cannot because ' + $
    	'you do not seem to have an X11 graphics server available. Please consider ' + $
    	'running PREF_MIGRATE manually at some other time when you have a server available.'
    return, 0
  endif

  return, DIALOG_MESSAGE(text, /question) eq 'Yes'
end







pro pref_migrate_not_possible, name
  ;
  ; Called if PREF_MIGRATE is run without the STARTUP keyword and there
  ; are are no preference/macro files for other versions that can be migrated.
  ; Tells the user we can't help them.
  ;
  ; name is the phrase with with to describe the current application mode.

  text = [ 'There are no other versions of IDL available on', $
           'this system from which ' + name + ' can be migrated.' ]

  ; Gotcha for X11 versions of IDL: What if there's no server
  ; available?
  ;
  ; The only way to know you can't get a server is to try it and
  ; see. The abscence of the DISPLAY variable doesn't mean "no",
  ; and the presence of it does not mean "yes". Hence, the CATCH block.
  CATCH, err
  if (err ne 0) then begin
    CATCH,/CANCEL
    MESSAGE, /continue, /noname, $
    	'PREF_MIGRATE is unable to run because you do not seem to ' + $
    	'have an X11 graphics server available. Please consider ' + $
    	'running PREF_MIGRATE manually at some other time when you ' + $
    	'have a server available.'
    return
  endif

  toss = DIALOG_MESSAGE(text, /information, title='IDL Preference Migration')
end







function pref_migrate_read_data, donor_dirs, app_mode
  ; Reads the preference and macro files in the specified donor_dirs,
  ; and returns an array of PREF_MIGRATE_FILE structs containing the
  ; recovered data.

  ; The data from a preference of macro file is kept in one of these structs
  ;	file		Name of file
  ;     count		# of items contained in pref_file
  ;     help_id		If display the file,this is the widget ID of display
  perfile = { file:'', count:0L, help_id:0L }

  ; The data from each app user directory is maintained in one of these
  ; structures:
  ;     pref		Preference file data
  ;     macro		Macro file data
  ;	version         IDL version string extracted from either file
  ;	date            Most recent modification date from the two files
  filedef = { pref:perfile, macro:perfile, version:'', date:0ll }


  c = n_elements(donor_dirs)
  psep = path_sep()

  data = replicate(filedef, c)

  for i = 0, c-1 do begin
    if (app_mode ne 1) then begin	; Mode 1 is macros-only
      data[i].pref.file = donor_dirs[i] + psep + 'idl.pref'

      openr, fin, data[i].pref.file, /GET_LUN, ERROR=err
      if (err eq 0) then begin
        data[i].date = (FSTAT(fin)).mtime

        line = ''
        while (not eof(fin)) do begin
          readf, fin, line
          if (data[i].version eq '') then begin
            if (strpos(line, '# Creator: ') eq 0) then begin
	      pos = strpos(line, ' (', /REVERSE_SEARCH)
	      if (pos eq -1) then pos = strlen(line)
	      pos -= 11
              data[i].version = strmid(line, 11, pos)
            endif
          endif

          ; Strip comments and remove leading/trailing whitespace.
          ; If anything is left, then it must be a preference. We
          ; trust that the files contain valid preferences, since they
          ; have been in use by other versions of IDL, so we don't do
          ; syntax checking. The worse case scenario, which is very unlikely,
          ; is that a syntax error will be detected if the file is actually
          ; imported. If so, it is harmless --- PREF_SET will just send some
          ; errors to the users stdout.
          pos = strpos(line, '#')
          if (pos ne 0) then begin	; 0 means a whole line comment
            if (pos eq -1) then begin
              line = strtrim(temporary(line), 2)
            endif else begin
              line = strtrim(strmid(temporary(line), 0, pos), 2)
            endelse
            if (strlen(line) ne 0) then data[i].pref.count++
          endif

        endwhile
        free_lun, fin
        if (data[i].version eq '') then data[i].pref.count = 0
      endif		; err eq 0
    endif		; Preferences (app_mode ne 1)

    if (app_mode ne 0) then begin	; Mode 0 is preferences-only
      data[i].macro.file = donor_dirs[i] + psep + 'macros.ini'

      openr, fin, data[i].macro.file, /GET_LUN, ERROR=err
      if (err eq 0) then begin
        date = (FSTAT(fin)).mtime
        if (data[i].date lt date) then data[i].date = date;

        line = ''
        while (not eof(fin)) do begin
          readf, fin, line
          if (data[i].version eq '') then begin
            if (strpos(line, '; Creator: ') eq 0) then begin
	      pos = strpos(line, ' (', /REVERSE_SEARCH)
	      if (pos eq -1) then pos = strlen(line)
	      pos -= 11
              data[i].version = strmid(line, 11, pos)
            endif
          endif

          ; Strip comments and remove leading/trailing whitespace.
          ; If anything is left, and if it is surrounded in square
          ; brackets, it must be a macro. We trust that the files
          ; have valid format, since they have been in use by other
          ; versions of IDL, so we don't do serious syntax checking.
          ; The worse case scenario, which is very unlikely,
          ; is that a syntax error will be detected if the file is actually
          ; imported. If so, it is harmless --- some errors will be
          ; written to the users stdout.
          pos = strpos(line, ';')
          if (pos ne 0) then begin	; 0 means a whole line comment
            if (pos eq -1) then begin
              line = strtrim(temporary(line), 2)
            endif else begin
              line = strtrim(strmid(temporary(line), 0, pos), 2)
            endelse
	    len = strlen(line)
            if ((len gt 2) && (strmid(line, 0, 1) eq '[') $
                && (strmid(line, len-1, 1) eq ']')) then data[i].macro.count++
          endif

        endwhile
        free_lun, fin
        if (data[i].version eq '') then data[i].macro.count = 0
      endif		; err eq 0
    endif		; Preferences (app_mode ne 1)

  endfor		; Outer loop

  return, data
end







pro pref_migrate_help, group_leader, state

  hdr_pref = [ $
    'The IDL Preference Migration Dialog allows you to import preferences', $
    'preferences from other IDL releases.' ]

  hdr_macro = [ $
    'The IDL IDE Macro Migration Dialog allows you to import IDE macros', $
    'from other IDL releases.' ]

  hdr_both = [ $
    'The IDL Preference and IDE Macro Migration Dialog allows you to', $
    'import preferences and IDE macros from other IDL releases.' ]

  par_1 = [ $
    '', $
    'IDL versions that have items available for migration are listed', $
    'at the top of the dialog. Each item shows the version of IDL', $
    'and how many items it has available for import. The versions with', $
    'the most recently modified items are listed first. Use the list to', $
    'select the version of IDL from which items should be imported.' ]

  checkbox = [ $
    '', $
    'A given version of IDL may have both preferences and macros available.', $
    'By default, IDL imports both types of information. Directly below', $
    'the list of IDL versions are checkboxes that allow you to specify', $
    'that you wish only one or the other to be imported. If the currently', $
    'selected version of IDL has only one type of information available,', $
    'the checkbox representing the missing type will be desensitized.']

  button_top = [ $
    '', $
    'At the bottom is a row of buttons used to control the application:', $
    '', $
    '  OK: Import the specified items and exit this application.', $
    '', $
    '  Cancel: Exit this application without importing anything.', $
    '    You can invoke this application manually by entering', $
    '    PREF_MIGRATE at the IDL prompt if you wish to import', $
    '    items later.', $
    '', $
    '  More Options >>> : Display all available options.', $
    '    If your list of IDL versions is large, it may be difficult', $
    '    to know which version contains the items you are trying to', $
    '    import. In this situation, it can be helpful to view the', $
    '    individual preference or macro files that would be imported.', $
    '    Since the need to view these preference or macro files is', $
    '    infrequent, the following are not shown by default:' ]

  button_pref = [ $
    '', $
    '    View Preferences: Display the preference file for the', $
    '      version of IDL currently selected in the list.' ]

  button_macro = [ $
    '', $
    '    View Macros: Display the macro definition file for the', $
    '      version of IDL currently selected in the list.' ]

  button_tail = [ $
    '', $
    '  <<< Fewer Options : Hide infrequently used options.', $
    '', $
    '  Help: Display this information.', $
    '' ]

  case state.app_mode of
    0: text = [ hdr_pref, par_1, button_top, $
                button_pref, button_tail ]
    1: text = [ hdr_macro, par_1, button_top, $
                button_macro, button_tail ]
    2: text = [ hdr_both, par_1, checkbox, button_top, $
                button_pref, button_macro, button_tail ]
  endcase

  help_id = state.help_id
  if (widget_info(help_id, /valid_id))then begin
    widget_control, /SHOW, help_id
  endif else begin
    XDisplayFile, TEXT=text, TITLE=state.app_title + ': Help', $
	GROUP = group_leader, RETURN_ID=help_id, FONT=state.help_font, $
        WIDTH = max(strlen(text)), /GROW_TO_SCREEN
    state.help_id = help_id
  endelse
  widget_control, /SHOW, state.wid.base

end







pro pref_migrate_center_bbase, state, w
  ; Adjust the simple and expert button bases so that they
  ; will appear centered inside a TLB that is w pixels wide.

  l_w = w - 2*state.layout.base_x_pad	; Account for margins

  sub_w = l_w - state.layout.bbase_simple_x
  if (sub_w lt 0) then sub_w = 0
  sub_w /= 2
  widget_control, state.wid.bbase_simple, xoffset=sub_w

  sub_w = l_w - state.layout.bbase_expert_x
  if (sub_w lt 0) then sub_w = 0
  sub_w /= 2
  widget_control, state.wid.bbase_expert, xoffset=sub_w
end







pro pref_migrate_set_current, state, idx
  ; Update the state and the display so that idx becomes the
  ; current item in the list.

  state.cur_item = idx		; Move to new index

  ; If we are displaying a user mode panel, then update it to match
  ; the new data. If the result is "both", make it sensitive so the
  ; user can change it. If the result is one or the other, then there
  ; is no choice to make, so make it insensitive.
  ;
  ; If the result is "both", then the default is to import only preferences.
  ; This is to be consistent with the way things used to be when IDL used
  ; the Windows registry for macros. The base reason is that we want people
  ; who don't care one way or the other to get the newest versions of the
  ; predefined macros.
  has_pref = (state.donor_data[idx].pref.count ne 0)
  has_macro = (state.donor_data[idx].macro.count ne 0)
  state.import.pref = (state.app_mode ne 1) && has_pref
  ; Default for import.macro is TRUE if we are in "macros only"
  ; mode, and FALSE otherwise
  state.import.macro = (state.app_mode eq 1) && has_macro
  if (state.wid.user_mode ne 0) then begin
    widget_control, state.wid.user_mode, $
	set_value=[state.import.pref, state.import.macro]
    widget_control, state.wid.user_mode, sensitive=has_pref && has_macro
  endif


  ; The View preference and macros buttons
  if (state.wid.view_pref ne 0) then $
    WIDGET_CONTROL, state.wid.view_pref, $
	sensitive=state.donor_data[state.cur_item].pref.count ne 0
  if (state.wid.view_macro ne 0) then $
    WIDGET_CONTROL, state.wid.view_macro, $
	sensitive=state.donor_data[state.cur_item].macro.count ne 0


end







pro pref_migrate_display_error
  ; There's an error in !ERROR_STATE. Display it.

  text = [ 'PREF_MIGRATE has encountered an unexpected error:', $
           '', $
           '    % ' + !error_state.msg, $
           '      ' + !error_state.sys_msg]

  toss = DIALOG_MESSAGE(text)
end







pro pref_migrate_event, ev

  ; Get the state from the TLB
  widget_control, ev.top, get_uvalue=state, /no_copy
  save_state = 1


  if ((ev.top eq ev.id) $
      && (tag_names(ev, /structure) eq 'WIDGET_BASE')) then begin
    ; This is a TLB resize event. Use it to resize the contents.

    ; Enforce minimum values
    w = (ev.x gt state.layout.orig_x) ? ev.x : state.layout.orig_x
    h = (ev.y gt (state.layout.orig_y_nonlist + state.layout.orig_y_list)) $
      ? (ev.y - state.layout.orig_y_nonlist) : state.layout.orig_y_list

    widget_control, state.wid.list, scr_xsize=w, scr_ysize=h
    pref_migrate_center_bbase, state, w

    WIDGET_CONTROL, ev.top, set_uvalue=state, /no_copy	; Put state back
    return
  endif


  ; The non-TLB widgets that can generate events each have a
  ; unique uvalue that we use to determine which one we're seeing.
  WIDGET_CONTROL, ev.id, get_uvalue=code
  case code of
  0 : begin			; The donor list index changed
      ; Recover the state, change the current item, put it back
      pref_migrate_set_current, state, ev.index
    end

  1: begin			; OK
      do_pref = state.import.pref $
	&& (state.donor_data[state.cur_item].pref.count ne 0)
      do_macro = state.import.macro $
	&& (state.donor_data[state.cur_item].macro.count ne 0)

      if (~(do_pref || do_macro)) then begin
        text = [ 'This request does not include any preferences or', $
                 'or macros. Please change the request and try again.' ]
	toss = DIALOG_MESSAGE(text, /INFORMATION, $
			      title=state.app_title + ': No Imports Selected')
	goto, done;
      endif


      ; If they are migrating macros, the first step is to ask whether
      ; they want to add them to the existing ones, or whether to toss
      ; the current set and replace them wholesale.
      if (do_macro) then begin
	text = ['Discard existing macros?', $
	'', $
	'Press Yes to discard any current macros and replace', $
	'them with the newly imported macros.', $
	'', $
	'Press No to retain the current macros and append the imported', $
	'macros to the end of the current set. Afterwards, you can', $
	'use the Edit Macros dialog in the IDL Development Environment', $
   'to modify or discard redundant or unwanted items.']
	r = DIALOG_MESSAGE(text, /QUESTION, /CANCEL, $
			   title=state.app_title + ': Discard Existing Macros?')
        if (r eq 'Cancel') then goto, done
        retain_current = r eq 'No'
      endif

      if (do_pref) then begin
        PREF_SET, FILENAME=state.donor_data[state.cur_item].pref.file
        PREF_COMMIT
      endif

      if (do_macro) then begin
	; The the user has a pre-existing macros.ini file, make a backup
        ; copy. If any error occurs, we can revert back to it.
        ;
        ; Note that we don't remove the backup file if things work
	; out. These files are small, it's nice to leave it.
        have_backup = 0
        dir =  APP_USER_DIR_QUERY('itt', 'pref', /RESTRICT_IDL_RELEASE, $
				  /RESTRICT_FAMILY, count=count)
        if (count eq 1) then begin
	  file = dir[0] + path_sep() + 'macros.ini'
          backup_file = file + '.backup'
	  if (FILE_TEST(file)) then begin
	    catch, err
	    if (err ne 0) then begin
	      CATCH, /CANCEL
	      pref_migrate_display_error
	      goto, done
	    endif else begin
	      FILE_COPY, file, backup_file, /OVERWRITE
	      CATCH, /CANCEL
	      have_backup = 1
	    endelse
	  endif
	endif

	; IMPORTANT NOTE: This code uses WDE_IMPORT_MACROS, an
	; undocumented routine provided by the IDL core system
        ; exclusively for this single use.
	;
	; This feature is undocumented because it is not considered
	; permanent. We reserve the right to remove or alter
	; it at any time. Do not use it in other code.
	catch, err
	if (err ne 0) then begin
	  CATCH, /CANCEL
	  pref_migrate_display_error
          if (have_backup) then FILE_MOVE, backup_file, file, /OVERWRITE
	  goto, done
	endif else begin
          WDE_IMPORT_MACROS, state.donor_data[state.cur_item].macro.file, $
		RETAIN_CURRENT=retain_current
	  CATCH, /CANCEL
	endelse

      endif

      WIDGET_CONTROL,/DESTROY, ev.top
      save_state = 0
    end

  2: begin			; CANCEL
      WIDGET_CONTROL,/DESTROY, ev.top
      save_state = 0
    end

  3: begin			; Switch to "expert" buttons
      widget_control, ev.top, update=0
      widget_control, state.wid.bbase_expert, map=1
      widget_control, state.wid.bbase_simple, map=0
      widget_control, ev.top, update=1
    end

  4: begin			; Switch to simple buttons
      widget_control, ev.top, update=0
      widget_control, state.wid.bbase_expert, map=0
      widget_control, state.wid.bbase_simple, map=1
      widget_control, ev.top, update=1
    end

  5 : begin			; View Preferences
      title = string(format='(%"User Preference File:  [%d]  %s")', $
		     state.cur_item+1, $
                     state.donor_data[state.cur_item].version)
      help_id = state.donor_data[state.cur_item].pref.help_id
      if (widget_info(help_id, /valid_id))then begin
        widget_control, /SHOW, help_id
      endif else begin
	file = state.donor_data[state.cur_item].pref.file
        XDISPLAYFILE, file, GROUP=ev.top, TITLE=title, $
		RETURN_ID=help_id, FONT=state.help_font, $
		/GROW_TO_SCREEN
        state.donor_data[state.cur_item].pref.help_id = help_id
      endelse
      widget_control, /SHOW, state.wid.base
    end

  6 : begin			; View Macros
      title = string(format='(%"User Macro File:  [%d]  %s")', $
		     state.cur_item+1, $
                     state.donor_data[state.cur_item].version)
      help_id = state.donor_data[state.cur_item].macro.help_id
      if (widget_info(help_id, /valid_id))then begin
        widget_control, /SHOW, help_id
      endif else begin
	file = state.donor_data[state.cur_item].macro.file
        XDISPLAYFILE, file, GROUP=ev.top, TITLE=title, $
		RETURN_ID=help_id, FONT=state.help_font, $
		/GROW_TO_SCREEN
        state.donor_data[state.cur_item].macro.help_id = help_id
      endelse
      widget_control, /SHOW, state.wid.base
    end

  7: begin			; HELP
      PREF_MIGRATE_HELP, ev.top, state
    end

  8: begin			; User mode import buttons
      if (ev.value eq 0) then state.import.pref = ev.select
      if (ev.value eq 1) then state.import.macro = ev.select
    end
  endcase

done:
  ; Put the state back for next time
  if (save_state) then WIDGET_CONTROL, ev.top, set_uvalue=state, /no_copy

end







;+
; NAME:
;       PREF_MIGRATE
; PURPOSE:
;       A graphical interface to the PREF_SET and PREF_COMMIT routines
;	designed to ease the migration of IDL user preferences between
;       IDL versions.
; CATEGORY:
;       User Preferences
; CALLING SEQUENCE:
;       PREF_MIGRATE
; INPUTS:
;       None.
; KEYWORDS:
;       MACRO: If set, the migration process only migrates Idlde macros.
;		This option is only allowed under Microsoft Windows, as it
;		has no meaning to the Motif/Unix version of the Idlde.
;       PREFERENCE: If set, the migration process only migrates Idlde
;               preferences, and not macros. This option only has meaning
;               when running under Microsoft Windows. It is quietly ignored
;               on other platforms.
;       STARTUP: Intended for internal use by IDL. At startup, if IDL
;		determines that the user does not have a user preference
;		file, it runs PREF_MIGRATE with the STARTUP keyword set
;		prior to running the startup file (if any) or prompting the
;		user for input. STARTUP mode differs from a regular call
;		in a few ways:
;		    - Since the user didn't explicitly run us, we use
;		      a dialog to explain ourselves and ask their permission
;		      to continue before moving into the main application.
;                   - We block in XMANAGER so any changes we make will
;		      be in effect when the startup file runs and the user
;		      is able to enter commands.
;
; OUTPUTS:
;       None.
; COMMON BLOCKS:
;       None.
; SIDE EFFECTS:
;       Importing preferences can cause IDL's behavior to change, as specified
;	by those preferences.
; RESTRICTIONS:
;	None
; MODIFICATION HISTORY:
;       4 May 2004, Written by AB, RSI.
;-
pro pref_migrate, STARTUP=startup, MACRO=macro, PREFERENCE=pref

  ; There is no practical reason why it would be useful to have more
  ; than one of this application running.
  if (XREGISTERED('PREF_MIGRATE')) then return

  on_error, 2

  ; Remember that we've run. The IDL kernel checks for this before
  ; deciding to run us automatically.
  pref_migrate_mark

  ; This application is designed to operatte in one of 3 possible modes:
  ;
  ;	0 - Migrate preferences
  ;     1 - Migrate Idlde macros
  ;     2 - Migrate both preferences and macros
  ;
  ; Modes 1 and 2 are only allowed when running under Microsoft Windows,
  ; because we maintain the macros using macros.ini files found within
  ; the preference application user data directories. For Motif/Unix, they
  ; are kept in the users .idlde file, and as such, are always shared between
  ; all versions of IDL.
  ;
  ; The MACRO and PREFERENCE keywords, along with the current platform, are
  ; used to determine the mode to run in.
  if (!version.os_family eq 'Windows') then begin
    i = keyword_set(pref) + keyword_set(macro)
    if ((i eq 0) or (i eq 2)) then begin		; If neither, or both
      app_mode = 2		; Do Both
    endif else if (keyword_set(pref)) then begin
      app_mode = 0		; Do Preferences
    endif else begin
      app_mode = 1		; Do Macros
    endelse
  endif else begin
    app_mode = 0		; Preferences is only valid option
    if (keyword_set(macro)) then $
      MESSAGE, 'MACRO keyword only allowed under Microsoft Windows.'
  endelse

  ; These arrays can be indexed by app_mode to get appropriate strings
  name = [ 'preferences', 'macros', 'preferences and macros' ]
  title = [ 'Import IDL Preferences', 'Import IDL Macros', $
	    'Import IDL Preferences and Macros' ]


  ; Build a list of all preference directories that might
  ; serve as preference donors.
  donor_dirs1 = APP_USER_DIR_QUERY('rsi', 'pref', /RESTRICT_IDL_RELEASE, $
				  /RESTRICT_FAMILY, /QUERY_IDL_RELEASE, $
				  /EXCLUDE_CURRENT, count=c1)
  donor_dirs2 = APP_USER_DIR_QUERY('itt', 'pref', /RESTRICT_IDL_RELEASE, $
				  /RESTRICT_FAMILY, /QUERY_IDL_RELEASE, $
				  /EXCLUDE_CURRENT, count=c2)
  c = c1 + c2
  if (c eq 0) then begin	; No other IDL versions, so nothing to do.
      if (~keyword_set(startup)) then pref_migrate_not_possible, name[app_mode]
    return
  endif

  if (c1 gt 0) then donor_dirs = donor_dirs1
  if (c2 gt 0) then donor_dirs = (c1 gt 0) ? $
    [donor_dirs1, donor_dirs2] : donor_dirs2



  donor_data = pref_migrate_read_data(donor_dirs, app_mode)

  good = where((donor_data.pref.count ne 0) or (donor_data.macro.count ne 0), $
	       good_count);
  if (good_count eq 0) then begin
    if (~keyword_set(startup)) then pref_migrate_not_possible, name[app_mode]
    return	; No migration candidates
  endif
  if (good_count ne c) then donor_data = donor_data[good]	; Toss bad items
  c = good_count

  ; Sort them so that the most recently modified are first
  donor_data = donor_data[reverse(sort(donor_data.date))]


  ; If running this was our idea at startup instead of the users doing,
  ; then ask for permission to continue.
  if (keyword_set(startup) && ~pref_migrate_ok(c)) then return

  ; We need to start with no pending preferences in the system. Otherwise,
  ; if the user hits the Cancel button, we won't be able to distinguish
  ; between the pending preferences we started with, and those we created
  ; by migration. So, if there are pending preferences, offer to commit
  ; them, and bail if we're not allowed to do so.
  if ((app_mode ne 1) && (PREF_GET(/NUM_PENDING) ne 0)) then begin
     text = [ 'There are uncommitted preference changes.', $
	      'PREF_MIGRATE requires that all preference changes be', $
              'committed in order to function correctly.', $
	      '', $
	      'Press ''Yes'' to have PREF_MIGRATE commit the preferences for', $
	      'you, or ''No'' to have PREF_MIGRATE exit without making', $
              'any changes.' ]
      if (DIALOG_MESSAGE(text, /question) eq 'No') then return
      PREF_COMMIT
  endif

  display = strarr(c)
  for i=0, c-1 do begin
    pstring = (donor_data[i].pref.count gt 1) ? "preferences" : "preference"
    mstring = (donor_data[i].macro.count gt 1) ? "macros" : "macro"
    if ((donor_data[i].pref.count ne 0) $
        && (donor_data[i].macro.count ne 0)) then begin
      display[i] = string(format='(%"[%d]  %s  (%d %s, %d %s)")', $
		          i+1, donor_data[i].version, $
			  donor_data[i].pref.count, pstring, $
		          donor_data[i].macro.count, mstring)
    endif else if (donor_data[i].pref.count ne 0) then begin
      display[i] = string(format='(%"[%d]  %s  (%d %s)")', $
		          i+1, donor_data[i].version, $
			  donor_data[i].pref.count, pstring)
    endif else begin
      display[i] = string(format='(%"[%d]  %s  (%d %s)")', $
		          i+1, donor_data[i].version, $
			  donor_data[i].macro.count, mstring)
    endelse
  endfor

  ; If a widget is used in the event handler, it needs to be in
  ; the state block. I gather all such widget IDs here to keep it organized
  wid = { base:0L, list:0L, user_mode:0L, bbase_simple:0L, bbase_expert:0L, $
          view_pref:0L, view_macro:0L }

  base_x_pad = 10
  wid.base = widget_base(/COLUMN, /TLB_SIZE_EVENTS, TITLE=title[app_mode], $
			 space=20, ypad=20, xpad=base_x_pad)



  l = widget_label(wid.base, /align_center, $
      VALUE='Select the previous IDL installation from which to migrate ' $
            + name[app_mode] + '.')

  wid.list = widget_list(wid.base, value=display, UVALUE=0, $
			 ysize=min([10,n_elements(display)]))


  ; If the app mode is to allow migrating both preferences and macros,
  ; then allow the user to specify which they really want. This uses
  ; the same values as app_mode, and it must have a value that fits within
  ; the value of app_mode (i.e. no setting Macros in app_mode doesn't have
  ; macros).
  if (app_mode eq 2) then begin
    wid.user_mode = cw_bgroup(wid.base, [ 'Preferences', 'Macros'], $
			      label_left = 'Import:  ',/nonexclusive, /row, $
			      uvalue=8, ids=ids)
    WIDGET_CONTROL, ids[0], tooltip='If set, preferences will be imported'
    WIDGET_CONTROL, ids[1], tooltip='If set, macros will be imported'
  endif

  ; There is a simple button base, and an "expert" button base.
  ; I put them both in a bulletin board base so that they are
  ; positioned on top of each other. Sadly, this causes the buttons
  ; to line up on the left of the column instead of centering automatically.
  ; So, centering is handled using pref_migrate_center_bbase
  bbase=widget_base(wid.base)
  wid.bbase_simple = widget_base(/ROW, bbase, space=20)
  wid.bbase_expert = widget_base(/ROW, bbase, space=10, map=0)

  tip = 'Import from selected IDL version and exit'
  b_ok = widget_button(wid.bbase_simple, value='OK', TOOLTIP=tip, UVALUE=1)
  b1 = widget_button(wid.bbase_expert, value='OK', TOOLTIP=tip, UVALUE=1)

  tip = 'Exit without importing'
  b1 = widget_button(wid.bbase_simple, value='Cancel', TOOLTIP=tip, UVALUE=2)
  b1 = widget_button(wid.bbase_expert, value='Cancel', TOOLTIP=tip, UVALUE=2)

  b1 = widget_button(wid.bbase_simple, value='More Options >>>', UVALUE=3, $
		     TOOLTIP='Show advanced features')

  if (app_mode ne 1) then $
    wid.view_pref = widget_button(wid.bbase_expert, $
                                  value='View Preferences', UVALUE=5, $
				  TOOLTIP='Display preference file contents',$
	                          SENSITIVE=donor_data[0].pref.count ne 0)
  if (app_mode ne 0) then $
    wid.view_macro = widget_button(wid.bbase_expert, $
                                   value='View Macros', UVALUE=6, $
				   TOOLTIP='Display macro file contents', $
	                           SENSITIVE=donor_data[0].macro.count ne 0)

  b1 = widget_button(wid.bbase_expert, value='<<< Fewer Options', UVALUE=4, $
		     TOOLTIP='Hide advanced features')

  b1 = widget_button(wid.bbase_simple, value='Help', UVALUE=7, $
		     TOOLTIP='Describe options in more detail')
  b1 = widget_button(wid.bbase_expert, value='Help', UVALUE=7, $
		     TOOLTIP='Describe options in more detail')


  ; Capture layout dimensions needed for size calculations.
  geo_base = WIDGET_INFO(wid.base, /geometry)
  geo_list = WIDGET_INFO(wid.list, /geometry)

  layout={ orig_x:geo_base.scr_xsize, $
           orig_y_nonlist:geo_base.scr_ysize - geo_list.scr_ysize, $
           orig_y_list:geo_list.scr_ysize, $
	   base_x_pad:base_x_pad, $
	   bbase_simple_x:(WIDGET_INFO(wid.bbase_simple,/geometry)).scr_xsize,$
	   bbase_expert_x:(WIDGET_INFO(wid.bbase_expert,/geometry)).scr_xsize }


  ; Proportional fonts are bad news for displaying our pref and macro files
  help_font = (!version.os_family eq 'Windows') ? 'COURIER*FIXED*12' : '9x15'

  state = { app_mode:app_mode, app_title:title[app_mode], $
	    import:{pref:0, macro:0}, donor_data:donor_data, $
            help_id:0L, help_font:help_font, $
            wid:wid, cur_item:0, layout:layout }
  pref_migrate_center_bbase, state, state.layout.orig_x

  pref_migrate_set_current, state, 0
  widget_control, wid.base, set_uvalue=state
  widget_control, wid.base, /realize
  widget_control, wid.list, set_list_select=0
  widget_control, b_ok, /INPUT_FOCUS

  ; We block in XMANAGER if in STARTUP mode, because we want our changes
  ; to take effect before the user's startup file runs, or they get a chance
  ; to enter commands at the IDL> prompt. If not in STARTUP mode, then
  ; we have no reason to take away the command line, so we don't.
  xmanager, 'PREF_MIGRATE', wid.base, NO_BLOCK=~keyword_set(startup)
end
