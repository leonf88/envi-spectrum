; $Id: //depot/idl/releases/IDL_80/idldir/lib/online_help_pdf_index.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;       ONLINE_HELP_PDF_INDEX
;
; PURPOSE:
;       Widget utility that allows the user to select an entry from
;       the IDL documentation master index, then display the selected
;       page in the Adobe Acrobat viewer. This is meant to be called
;       by ONLINE_HELP on UNIX systems when the supplied topic name
;       does not exist.
;
;       This utility only works on platforms that support the IDL-Acrobat
;       plug-in: currently all Unix platforms except AIX and OS X.
;
;       This utility relies on the presence of a file containing a
;       text-only copy of the IDL Master Index document. The file is
;       located in the help subdirectory of the IDL distribution, and
;       is called 'mindex.txt'.
;
; CATEGORY:
;       Help, documentation.
;
; CALLING SEQUENCE:
;       ONLINE_HELP_PDF_INDEX [, TopicString] [, /EXACT]
;
; INPUTS:
;     TopicString: A scalar string containing the item about which
;     help is desired.
;
; KEYWORD PARAMETERS:
;     EXACT: Set this keyword to specify that TopicString is
;     an exact match of a valid named destination (as returned
;     by the ONLINE_HELP_PDF_ND2FILE function).
;
;     Note: this keyword is not documented and its behavior
;     may change in future releases. It is inteded for use by
;     the ONLINE_HELP procedure and ? command, which know how
;     to determine whether a string is in fact a valid desintation.
;
; OUTPUTS:
;       Display the widget interface. If the EXACT keyword is set,
;       (implying that TopicString exactly matches a naed destination
;       in one of the IDL docset PDF files), check the saved
;       preferences to determine whether the widget interface should
;       be displayed.
;
; COMMON BLOCKS:
;       ONLINE_HELP_PDF_INDEX - This block is private to this module,
;       and not to be used by other routines.
;
; MODIFICATION HISTORY:
;       29 April 2004, DD
;
;-
;

;---------------------------------------------------------------------
FUNCTION PickBook, book ;{{{
; Function to match the book abbreviation string used in the
; master index file to the 'real' name of the PDF file.

   COMPILE_OPT idl2, hidden

   CASE book of
      'Bld':  BookName='building.pdf'
      'DM':   BookName='datamine.pdf'
      'EDG':  BookName='edg.pdf'
      'GS':   BookName='getstart.pdf'
      'Img':  BookName='image.pdf'
      'Inst': BookName='instlic.pdf'
      'IonI': BookName='ionintro.pdf'
      'IonJ': BookName='ionjava.pdf'
      'IonQ': BookName='ionquickref.pdf'
      'IonS': BookName='ionscrpt.pdf'
      'ITD':  BookName='itooldevguide.pdf'
      'ITU':  BookName='itooluserguide.pdf'
      'Med':  BookName='medical.pdf'
      'MIDX': BookName='mindex.pdf'
      'Obs':  BookName='obsolete.pdf'
      'Onlg': BookName='onlguide.pdf'
      'Quik': BookName='quickref.pdf'
      'Ref':  BookName='refguide.pdf'
      'SDF':  BookName='sdf.pdf'
      'Use':  BookName='using.pdf'
      'Wav':  BookName='wavelet.pdf'
      'WN':   BookName='whatsnew.pdf'
      else:   BookName='unknown book'
   ENDCASE

   RETURN, BookName

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO ShowHelp, state ;{{{
; Procedure to display the selected page.

   COMPILE_OPT idl2, HIDDEN

   bookpath = !HELP_PATH + PATH_SEP() + (*state).book
   bookinfo = FILE_INFO(bookpath)
   IF bookinfo.exists THEN BEGIN
      IF (*state).page && (*state).book THEN BEGIN
         IF !VERSION.OS_FAMILY EQ 'Windows' THEN BEGIN
            PRINT, 'Display page ', (*state).page, ' of ', (*state).book
         ENDIF ELSE BEGIN
            ONLINE_HELP, BOOK=(*state).book, PAGE=(*state).page
            (*state).clicks=0
         ENDELSE
      ENDIF ELSE BEGIN
         PRINT, 'Nothing selected.'
      ENDELSE
   ENDIF ELSE BEGIN
      err_message = ['The file '+(*state).book+' was not found', $
                     'in the help directory of the IDL distribution.']
      void = DIALOG_MESSAGE(err_message, DIALOG_PARENT=(*state).tbase, $
         /ERROR, TITLE='PDF File Not Found')
   ENDELSE

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
FUNCTION GetBookmarks, PREFS=prefs, BOOKFILE=bkfile; {{{
; Function to read bookmarks from a file in the user's
; .idl directory.

   COMPILE_OPT idl2, HIDDEN

   prefs = { show_always:1, xpos:0.0, ypos:0.0, width:350.0, height:650.0 }

   ; Text of the application readme file.
   app_desc = [ $
     'This is the configuration directory for the IDL online', $
     'help system. It is used to store settings between IDL sessions.', $
     '', $
      'It is safe to remove this directory, as it will be recreated', $
     'on demand. Note that any bookmarks you have created will be', $
     'deleted.']

   ; This is version 1 of the application readme file.
   app_version=1

   ; Get the path to the application user directory.
   app_dir_path = APP_USER_DIR('itt', 'IDL', $
            'help', 'IDL Online Help System', app_desc, $
            app_version, /RESTRICT_IDL_RELEASE)

   bkfile = app_dir_path+PATH_SEP()+'pdf_bookmarks.txt'

   ; Get info on bookmarks file.
   fileInfo = FILE_INFO(bkfile)

   ; If file exists and is readable, read into bkmarks array.
   IF fileInfo.read THEN BEGIN

      ; Create an array to hold the bookmarks
      nlines=LONG(FILE_LINES(bkfile))
      bkmarks=strarr(nlines)

      ; Open the file
      OPENR, unit, bkfile, /GET_LUN, ERROR=err

      ; Exit if error occurs
      IF (err NE 0) THEN BEGIN
         void = DIALOG_MESSAGE(!ERROR_STATE.MSG)
         RETURN, ['There was an error reading the bookmarks file.']
      ENDIF

      ; Read the contents of the file into the 'bkmarks' array.
      line=''
      FOR i = 0l, nlines-1 DO BEGIN
         READF, unit, line
         IF ~(STRMATCH(line, ';*')) THEN bkmarks[i] = line
         IF (STRMATCH(line, '; PREF_Show_Always*')) THEN BEGIN
            prefs.show_always = STRMID(STREGEX(line, '=.*', /EXTRACT), 1)
         ENDIF
         IF (STRMATCH(line, '; PREF_xpos*')) THEN BEGIN
            prefs.xpos = STRMID(STREGEX(line, '=.*', /EXTRACT), 1)
         ENDIF
         IF (STRMATCH(line, '; PREF_ypos*')) THEN BEGIN
            prefs.ypos = STRMID(STREGEX(line, '=.*', /EXTRACT), 1)
         ENDIF
         IF (STRMATCH(line, '; PREF_width*')) THEN BEGIN
            prefs.width = STRMID(STREGEX(line, '=.*', /EXTRACT), 1)
         ENDIF
         ;IF (STRMATCH(line, '; PREF_height*')) THEN BEGIN
         ;   prefs.height = STRMID(STREGEX(line, '=.*', /EXTRACT), 1)
         ;ENDIF
      ENDFOR

      ; Remove blank lines.
      bkmarks = bkmarks[WHERE(bkmarks NE '')]

      ; Close the file
      FREE_LUN, unit

      ; If the array is empty (meaning the file was, too),
      ; create a default bookmark.
      IF (bkmarks[0] EQ '' && N_ELEMENTS(bkmarks) EQ 1) THEN $
         bkmarks = ['Default Bookmark: Online Guide, 1 Onlg']

   ENDIF ELSE BEGIN

      ; If no bookmarks file exists, just start with a default
      ; bookmark.
      bkmarks = ['Default Bookmark: Online Guide, 1 Onlg']

   ENDELSE

   RETURN, bkmarks

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO AddBookmark, ev  ; {{{
; Procedure to add a bookmark.

   COMPILE_OPT idl2, HIDDEN

   ; Get state structure
   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Get contents of the bookmark manager widgets
   WIDGET_CONTROL, (*state).bkText, GET_VALUE=bkText
   bkBook = WIDGET_INFO((*state).bkBooks, /DROPLIST_SELECT)
   WIDGET_CONTROL, (*state).bkPnum, GET_VALUE=bkPnum

   ; Check values of bookmark manager widgets
   IF (bkText EQ '') THEN BEGIN
      void = DIALOG_MESSAGE('Please supply bookmark text.')
      RETURN
   ENDIF

   IF (bkPnum EQ '') THEN BEGIN
      void = DIALOG_MESSAGE('Please supply a page number.')
      RETURN
   ENDIF

   IF (~(STREGEX(bkPnum, '^[0-9]*$', /BOOLEAN))) THEN BEGIN
      void = DIALOG_MESSAGE('Page numbers must be integers.')
      RETURN
   ENDIF

   ; Build the new bookmark
   newBkMark = bkText+', '+bkPnum+' '+((*state).book_abr)[bkBook]

   ; Update the bookmark list
   bkmarks = [*(*state).bkmarks, [newBkMark]]
   *(*state).bkmarks = bkmarks

   ; Write out the changed bookmarks
   WriteBookmarks, ev

   ; Populate the text widget with the new bkmarks
   WIDGET_CONTROL, (*state).bklist, SET_VALUE=bkmarks

   ; Send an event to update the selection highlight
   list_select_ev, { WIDGET_TEXT_SEL, ID:(*state).bklist, TOP:(*state).tbase, $
      HANDLER:(*state).bklist, TYPE:3, OFFSET:FIX(TOTAL(STRLEN(bkmarks))), $
      LENGTH:0L }

END ; }}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO EditBookmark, ev  ; {{{
; Procedure to edit the selected bookmark.

   COMPILE_OPT idl2, HIDDEN

   ; Get state structure
   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Get contents of the bookmark manager widgets
   WIDGET_CONTROL, (*state).bkText, GET_VALUE=bkText
   bkBook = WIDGET_INFO((*state).bkBooks, /DROPLIST_SELECT)
   WIDGET_CONTROL, (*state).bkPnum, GET_VALUE=bkPnum

   ; Check values of bookmark manager widgets
   IF (bkText EQ '') THEN BEGIN
      void = DIALOG_MESSAGE('Please supply bookmark text.')
      RETURN
   ENDIF

   IF (bkPnum EQ '') THEN BEGIN
      void = DIALOG_MESSAGE('Please supply a page number.')
      RETURN
   ENDIF

   IF (~(STREGEX(bkPnum, '^[0-9]*$', /BOOLEAN))) THEN BEGIN
      void = DIALOG_MESSAGE('Page numbers must be integers.')
      RETURN
   ENDIF

   ; Build the edited bookmark
   newBkMark = bkText+', '+bkPnum+' '+((*state).book_abr)[bkBook]

   ; Update the bookmark list
   bkmarks = *(*state).bkmarks
   bkmarks[(*state).line] = [newBkMark]
   *(*state).bkmarks = bkmarks

   ; Write out the changed bookmarks
   WriteBookmarks, ev

   ; Populate the text widget with the new bkmarks
   WIDGET_CONTROL, (*state).bklist, SET_VALUE=bkmarks

   ; Send an event to update the selection highlight
   list_select_ev, { WIDGET_TEXT_SEL, ID:(*state).bklist, TOP:(*state).tbase, $
      HANDLER:(*state).bklist, TYPE:3, OFFSET:(*state).linebegin, $
      LENGTH:0L }

END ; }}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO DeleteBookMark, ev ; {{{
; Procedure to delete a bookmark from the bookmarks list.

   COMPILE_OPT idl2, HIDDEN

   ; Get the state
   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Get the column and row version of the cursor offset
   sel_colrow = WIDGET_INFO((*state).bklist, TEXT_OFFSET_TO_XY=(*state).selection[0])

   ; Update the bookmark list
   bkmarks = *(*state).bkmarks
   IF (N_ELEMENTS(bkmarks) GT 1) THEN BEGIN
      IF (sel_colrow[1] GT 0) THEN BEGIN
         bkmarks[sel_colrow[1]]=''
      ENDIF ELSE BEGIN
         bkmarks[0]=''
      ENDELSE
      bkmarks = bkmarks[WHERE(bkmarks NE '')]
   ENDIF ELSE BEGIN
      bkmarks = ['Default Bookmark: Online Guide, 1 Onlg']
   ENDELSE
   *(*state).bkmarks = bkmarks

   ; Write out the changed bookmarks
   WriteBookmarks, ev

   ; Populate the text widget with the new bkmarks
   WIDGET_CONTROL, (*state).bklist, SET_VALUE=bkmarks

   ; Send an event to update the selection highlight
   list_select_ev, { WIDGET_TEXT_SEL, ID:(*state).bklist, TOP:(*state).tbase, $
      HANDLER:(*state).bklist, TYPE:3, OFFSET:(*state).linebegin, $
      LENGTH:0L }

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO WriteBookmarks, ev   ;{{{
; Procedure to write out the bookmarks file.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
   bkmarks = *(*state).bkmarks

   ; Open the bookmarks file
   OPENW, unit, (*state).bkfile, /GET_LUN, ERROR=err

   ; Exit if error occurs
   IF (err NE 0) THEN BEGIN
      void = DIALOG_MESSAGE(!ERROR_STATE.MSG)
      RETURN
   ENDIF

   ; Write comment block to bookmarks file
   PRINTF, unit, '; ------------------------------------------------------'
   PRINTF, unit, '; ONLINE_HELP_PDF_INDEX Bookmarks file'
   PRINTF, unit, '; '
   PRINTF, unit, '; This file contains bookmarks for the PDF help'
   PRINTF, unit, '; system index utility. You can make changes via'
   PRINTF, unit, '; the index utility, or by editing this file directly.'
   PRINTF, unit, '; See ONLINE_HELP_PDF_INDEX in the IDL Reference Guide'
   PRINTF, unit, '; for details.'
   PRINTF, unit, '; '
   PRINTF, unit, '; Note: do not make changes to this comment block; they'
   PRINTF, unit, ';       will NOT be preserved.'
   PRINTF, unit, '; '
   PRINTF, unit, '; PREF_Show_Always=', $
      STRCOMPRESS((*state).show_always, /REMOVE_ALL)
   PRINTF, unit, '; PREF_xpos=', STRCOMPRESS((*state).xpos, /REMOVE_ALL)
   PRINTF, unit, '; PREF_ypos=', STRCOMPRESS((*state).ypos, /REMOVE_ALL)
   PRINTF, unit, '; PREF_width=', STRCOMPRESS((*state).width, /REMOVE_ALL)
   PRINTF, unit, '; PREF_height=', STRCOMPRESS((*state).height, /REMOVE_ALL)
   PRINTF, unit, '; ------------------------------------------------------'

   ; Write the bookmarks
   FOR i = 0l, N_ELEMENTS(bkmarks)-1 DO BEGIN
      PRINTF, unit, bkmarks[i]
   ENDFOR

   ; Close the file
   FREE_LUN, unit

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO HighlightPageNum, ev   ;{{{
; Procedure to highlight the page number and book name defined
; by state.selection.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
   selection = (*state).selection

   IF (WIDGET_INFO((*state).wTab, /TAB_CURRENT) EQ 0) THEN BEGIN
      currlist = (*state).ixlist
   ENDIF ELSE BEGIN
      currlist = (*state).bklist
   ENDELSE

   ; Highlight the selected page number/book name
   WIDGET_CONTROL, currlist, SET_TEXT_SELECT=[selection[0], selection[1]]
   ; Get the value of the selection
   WIDGET_CONTROL, currlist, GET_VALUE=string, /USE_TEXT_SELECT
   ; Parse the string for page number and book name
   page = LONG((STREGEX(string, '[0-9]+', /EXTRACT))[0])
   book = (STREGEX(string, '[A-Za-z]+', /EXTRACT))[0]
   ; Find the name of the PDF file that corresponds to book
   pdf = PickBook(book)
   ; Store the info
   (*state).page = page
   (*state).book = pdf

   IF (WIDGET_INFO((*state).wTab, /TAB_CURRENT) EQ 1) THEN BEGIN
      curr_line = (*state).line < (N_ELEMENTS(*(*state).bkmarks)-1) > 0
      bkmark = (STRSPLIT((*(*state).bkmarks)[curr_line], ',', /EXTRACT))[0]
      bkidx = WHERE((*state).book_abr EQ book)
      bkpage = (STREGEX(string, '[0-9]+', /EXTRACT))[0]
      WIDGET_CONTROL, (*state).bkText, SET_VALUE=bkmark
      WIDGET_CONTROL, (*state).bkBooks, SET_DROPLIST_SELECT=bkidx
      WIDGET_CONTROL, (*state).bkPnum, SET_VALUE=bkpage
   ENDIF

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
FUNCTION SelectPageNum, ev, sel_offset_line, sel_colrow, list ;{{{
; Function to define a range that corresponds to a page number/
; book name pair. If The user clicks on a number/name pair, that
; pair is selected. If the user clicks in front of the first pair,
; the first pair is selected. If the user clicks on a line that
; has no number/name pair, the next available pair is selected.
;
; Takes the offset to the beginning of the selected line, the
; column/row offset, and the list being displayed in the widget.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Init two arrays
   selection = [0l, 0l]
   sel = [0l, 0l]

   nlines = N_ELEMENTS(list)
   ; Retrieve the text of the selected line.
   IF ((sel_colrow[1] GE 0) && (sel_colrow[1] LT nlines)) THEN BEGIN
      line = (list)[sel_colrow[1]]
   ENDIF ELSE BEGIN
      ; If the user clicks past the end of the list, select the
      ; last line.
      line = (list)[nlines-1]
      sel_colrow = [0,0]
      sel_offset_line = WIDGET_INFO(ev.id, TEXT_XY_TO_OFFSET=[0,nlines-1])
   ENDELSE

   ; Split the selected line on ', ' followed by a number. This
   ; keeps multipart index text entries (like "doing, this, 123 Ref")
   ; from showing up with the text portion broken into multiple
   ; substrings.
   substrings = STRSPLIT(line, ', [0-9]', /REGEX)
   ; Subtract 1 from the substring indices to account for the
   ; integer in the match
   substrings = substrings-1
   ; The first element should always be zero.
   substrings[0] = 0
   ; Add the end of the selected line to the array.
   substrings = [substrings,STRLEN(line)]
   ; Number of elements of the array
   nstrings = N_ELEMENTS(substrings)

   ; If the line contains a number/name pair...
   IF ((nstrings gt 2) && (STREGEX(line, '[0-9]+', /BOOLEAN))) THEN BEGIN
      ; Locate the selection within the current line
      ; and set the sel array to the beginning and ending
      ; selection values.
      FOR ns = 0, nstrings-1 DO BEGIN
         IF (sel_colrow[0] gt substrings[ns]) THEN BEGIN
            sel[0] = substrings[ns]
            sel[1] = substrings[ns+1]
         ENDIF
      ENDFOR
      ; If the selection is in the first substring, select
      ; the second substring.
      IF (sel_colrow[0] le substrings[1]) THEN BEGIN
         sel[0] = substrings[1]
         sel[1] = substrings[2]
      ENDIF
      ; Reset the clicks field
      (*state).clicks=0
   ; If the line doesn't have a number/name pair...
   ENDIF ELSE BEGIN
      ; If we've moved up...
      IF (sel_colrow[1] lt (*state).line) THEN BEGIN
         ; Decrease the row number by 1
         IF (sel_colrow[1] LT nlines) THEN sel_colrow[1]=sel_colrow[1]-1
         ; Move sel_offset_line to the beginning of the previous line
         sel_offset_line = WIDGET_INFO(ev.id, $
            TEXT_XY_TO_OFFSET=[0,sel_colrow[1]])
         ; Set the column number to 0
         sel_colrow[0]=0
         ; Call this function with the new values
         selection = SelectPageNum(ev, sel_offset_line, sel_colrow, list)
         ; Reset the clicks field
         (*state).clicks=0
         ; Return the result.
         RETURN, selection
      ; If we've moved down...
      ENDIF ELSE BEGIN
         ; Move sel_offset_line to the beginning of the next line
         sel_offset_line = sel_offset_line+STRLEN(line)+1
         ; Increase the row number by 1
         IF (sel_colrow[1] LT nlines) THEN sel_colrow[1]=sel_colrow[1]+1
         ; Set the column number to 0
         sel_colrow[0]=0
         ; Call this function with the new values
         selection = SelectPageNum(ev, sel_offset_line, sel_colrow, list)
         ; Reset the clicks field
         (*state).clicks=0
         ; Return the result.
         RETURN, selection
      ENDELSE
   ENDELSE

   ; Build the returned selection array. Note that it contains
   ; the offset to the beginning of the selection, and the length
   ; of the selection.
   selection[0]=sel[0]+sel_offset_line
   selection[1]=sel[1]-sel[0]

   ; Return the result.
   RETURN, selection

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Event handlers for UI controls {{{

PRO Help_ev, ev
; Help button

   COMPILE_OPT idl2, HIDDEN

   ; Just open the correct topic in the IDL Reference Guide.
   ONLINE_HELP, 'online_help_pdf_index'

END

PRO Done_ev, ev
; Done button

   COMPILE_OPT idl2, HIDDEN

   WriteBookmarks, ev

   WIDGET_CONTROL, ev.TOP, /DESTROY

END

PRO Go_ev, ev
; Display button

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
   ShowHelp, state

END

PRO tab_change_ev, ev
; Do this when the user switches tabs.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; If we've selected the bookmarks tab, send a list select event.
   IF (WIDGET_INFO((*state).wTab, /TAB_CURRENT) EQ 1) THEN BEGIN
      list_select_ev, { WIDGET_TEXT_SEL, ID:ev.id, TOP:ev.top, $
         HANDLER:ev.handler, TYPE:3, OFFSET:1, LENGTH:0L }
   ENDIF

END

PRO showpref_ev, ev
; Do this when the user clicks or unclicks the "Show Always"
; checkbox.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
   (*state).show_always=WIDGET_INFO(ev.ID, /BUTTON_SET)

END

PRO online_help_pdf_index_event, ev

   COMPILE_OPT idl2, HIDDEN
   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
   tbase_g = WIDGET_INFO(ev.TOP, /GEOMETRY)

   CASE TAG_NAMES(ev, /STRUCTURE_NAME) OF
   'WIDGET_KILL_REQUEST': Done_ev, ev
   'WIDGET_BASE': BEGIN        ; Resize

      ; Calculate change in width
      IF (ev.x EQ 0) THEN BEGIN
         deltaX = 0
      ENDIF ELSE BEGIN
         deltaX = ev.x - (*state).width
      ENDELSE
      newX = (*state).width + deltaX

      ; NOTE: Height cannot currently be changed.
      ; Calculate change in height
      ;IF (ev.y EQ 0) THEN BEGIN
      ;   deltaY = 0
      ;ENDIF ELSE BEGIN
      ;   deltaY = ev.y - (*state).height
      ;ENDELSE
      ;newY = (*state).height + deltaY

      ; Adjust width of child widgets
      IF ((deltaX NE 0) || (ev.x EQ 0)) THEN BEGIN
         WIDGET_CONTROL, ev.TOP, XSIZE=(((*state).width=newX-(tbase_g.xpad*2)))
         WIDGET_CONTROL, (*state).ixlist, SCR_XSIZE=newX-(tbase_g.xpad*6)
         WIDGET_CONTROL, (*state).bklist, SCR_XSIZE=newX-(tbase_g.xpad*8)
         WIDGET_CONTROL, (*state).bkbase3, SCR_XSIZE=newX-(tbase_g.xpad*10)
         WIDGET_CONTROL, (*state).bkbase4, SCR_XSIZE=newX-(tbase_g.xpad*8)
         labelwidth = (WIDGET_INFO((*state).bkLabel1,/GEOMETRY)).xsize
         WIDGET_CONTROL, (*state).bkText, $
            SCR_XSIZE=newX-(tbase_g.xpad*16)-labelwidth
      ENDIF

      WIDGET_CONTROL, ev.TOP, YSIZE=(*state).height

      ; NOTE: Height cannot currently be changed.
      ; Adjust height of child widgets
      ;IF ((deltaY NE 0) || (ev.y EQ 0)) THEN BEGIN
      ;   WIDGET_CONTROL, ev.TOP, YSIZE=(((*state).height=newY-(tbase_g.ypad*2)))
      ;   bklheight = (WIDGET_INFO((*state).bklist, /GEOMETRY)).scr_ysize
      ;   ixlheight = (WIDGET_INFO((*state).ixlist, /GEOMETRY)).scr_ysize
      ;   WIDGET_CONTROL, (*state).bklist, SCR_YSIZE=((bklheight+deltaY)>80)
      ;   newbklheight = (WIDGET_INFO((*state).bklist, /GEOMETRY)).scr_ysize
      ;   deltabkl = newbklheight - (bklheight+deltaY)
      ;   WIDGET_CONTROL, ev.TOP, YSIZE=(((*state).height=newY+deltabkl))
      ;   WIDGET_CONTROL, (*state).ixlist, SCR_YSIZE=(ixlheight+deltaY+deltabkl)
      ;ENDIF


      ; Get the current size of the top level base and update
      ; the state structure.
      tbase_g = WIDGET_INFO(ev.TOP, /GEOMETRY)
      (*state).width = tbase_g.xsize
   END
   'WIDGET_TLB_MOVE': BEGIN        ; Move
      (*state).xpos = tbase_g.xoffset
      (*state).ypos = tbase_g.yoffset
   END
   'WIDGET_KBRD_FOCUS': BEGIN
      ; Track whether the index has focus. We use this information
      ; to disable updates in the index list when selections are
      ; created in other applciations, causing the list to get a
      ; deselection event.
      IF (ev.ID EQ (*state).tbase) THEN BEGIN
         (*state).hasFocus = ev.ENTER
      ENDIF
   END
   'WIDGET_TLB_ICONIFY': BEGIN
      ; Track whether the index has been iconified, and set the
      ; focus flag appropriately.
      IF (ev.ID EQ (*state).tbase) THEN BEGIN
         (*state).hasFocus = ev.ICONIFIED ? 0 : 1
      ENDIF
   END
   ELSE :
   ENDCASE

END

PRO nothing_ev, ev
; Swallow events generated by widgets in the 'Manage Bookmarks'
; section of the bookmarks tab.

; This event handler would normally do nothing, but we have
; to work around the behavior of text widgets in Motif, wherein
; creating a selection in one text widget removes the selection
; from another widget. In this case, this means that there is
; a selection event generated in the bookmark list, which in
; turn triggers the selection highlighting and possibly the
; ShowHelp function. So we set a "context change" flag here,
; and test for it in list_select_event, resetting the flag
; there if it is found.
WIDGET_CONTROL, ev.TOP, GET_UVALUE=state
(*state).ccFlag=1
END

;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO list_select_ev, ev ;{{{
; Event handler for mouse/cursor movement in the index list.

   COMPILE_OPT idl2, HIDDEN

   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Only do the list select if the index GUI has keyboard focus.
   IF ((*state).hasFocus EQ 0) THEN RETURN

   ; Check whether we're in the index list or the bookmarks list
   IF (WIDGET_INFO((*state).wTab, /TAB_CURRENT) EQ 0) THEN BEGIN
      currlist = *(*state).list
   ENDIF ELSE BEGIN
      currlist = *(*state).bkmarks
   ENDELSE

   lines = N_ELEMENTS(currlist)

   ; If we've got a text select event... {{{
   IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TEXT_SEL') THEN BEGIN

      ; We have to check to see if the event was caused by the
      ; removal of the selection in the bookmark list due to the
      ; creation of a selection elsewhere. See the nothing_ev
      ; procedure for more details.
      IF ((ev.LENGTH EQ 0) && ((*state).ccFlag)) THEN BEGIN
         (*state).ccFlag = 0
         RETURN
      ENDIF

   ; -------------------------------------------------------------
      ; This whole next block of code tries to do the right
      ; thing with arrow keys, which are not well supported
      ; under Motif.
      ;
      ; Get the selection
      beg_sel = (*state).selection[0]
      end_sel = (*state).selection[0]+(*state).selection[1]

      ; Get the column and row version of the cursor offset
      sel_colrow = WIDGET_INFO(ev.id, TEXT_OFFSET_TO_XY=ev.offset)
      ; Get the integer offset to the beginning of the selected line
      sel_offset_line = WIDGET_INFO(ev.id, TEXT_XY_TO_OFFSET=[0,sel_colrow[1]])

      ; Figure out where we are, and where the commas are
      sel_begin = beg_sel - sel_offset_line
      curr_line = sel_colrow[1] < (lines-1) > 0
      commas=STRSPLIT(currlist[curr_line], ',')

      ; Here we try to be smart about where to move when the
      ; user presses the left arrow key.
      IF (ev.offset EQ end_sel-1)  THEN BEGIN
         (*state).clicks=0

         IF (N_ELEMENTS(commas) GT 1) THEN BEGIN
            IF ((sel_begin-4) LE commas[1]) THEN BEGIN
               ; Get the integer offset to the beginning of
               ; the previous line
               IF (sel_colrow[1] NE 0) THEN BEGIN
                  new_offset = WIDGET_INFO(ev.id, $
                     TEXT_XY_TO_OFFSET=[0,(*state).line-1])
               ENDIF ELSE BEGIN
                  new_offset = WIDGET_INFO(ev.id, $
                     TEXT_XY_TO_OFFSET=[0,(*state).line])
               ENDELSE
            ENDIF ELSE BEGIN
               ; Move the offset back to before the previous
               ; page number.
               new_offset = ev.offset-10
            ENDELSE
         ENDIF ELSE BEGIN
            ; Get the integer offset to the beginning of
            ; the previous line
            IF (sel_colrow[1] NE 0) THEN BEGIN
               new_offset = WIDGET_INFO(ev.id, $
                  TEXT_XY_TO_OFFSET=[0,(*state).line-1])
            ENDIF ELSE BEGIN
               new_offset = WIDGET_INFO(ev.id, $
                  TEXT_XY_TO_OFFSET=[0,(*state).line])
            ENDELSE
         ENDELSE

         (*state).clicks=0
         list_select_ev, { WIDGET_TEXT_SEL, ID:ev.id, TOP:ev.top, $
           HANDLER:ev.handler, TYPE:3, OFFSET:new_offset, $
           LENGTH:0L }

         ;(*state).clicks=0

         RETURN

      ENDIF
      ; End of arrow key processing code.
   ; -------------------------------------------------------------

      ; First, if the offset is exactly the same as the saved
      ; offset, treat it like a double-click.
      ; Otherwise, check to see if the current selection is within
      ; the existing selection. If it is, update the clicks field
      ; of the state strucutre. This allows us to do something that
      ; looks like "double-click to select" if there can be an infinite
      ; amount of time between clicks; we need to do this because there
      ; is no 'clicks' field in the WIDGET_TEXT_SEL event structure.
      ; Note that this has the side effect of treating two consecutive
      ; identical selection events as a double-click, no matter how
      ; they come in. For example, hitting the down arrow at the end
      ; of either index or bookmarks list multiple times will open
      ; the PDF file to the selected page.
      IF (ev.offset EQ (*state).offset) THEN BEGIN
         HighlightPageNum, ev
         (*state).clicks++
      ENDIF ELSE BEGIN
         IF ((ev.offset ge (*state).selection[0]) AND $
             (ev.offset le (*state).selection[0]+(*state).selection[1])) $
            THEN BEGIN
            ; Display the selected page
            (*state).clicks++
            (*state).offset = ev.offset
            ; Highlight the page number/book name string.
            HighlightPageNum, ev
         ENDIF ELSE BEGIN
            ; Get the column and row version of the cursor offset
            sel_colrow = WIDGET_INFO(ev.id, TEXT_OFFSET_TO_XY=ev.offset)
            ; Get the integer offset to the beginning of the selected line
            sel_offset_line = WIDGET_INFO(ev.id, $
               TEXT_XY_TO_OFFSET=[0,sel_colrow[1]])
            ; Calculate the offsets for the page number/book name string
            selection = SelectPageNum(ev, sel_offset_line, sel_colrow, currlist)
            ; Update the state with the new selection
            (*state).selection = selection
            ; Make sure we don't wrap around the end of the index or
            ; bookmarks list.
            IF ((sel_colrow[1] EQ 0) && (lines GT 1) && (ev.offset GT 20)) $
               THEN sel_colrow[1] = lines-1
            (*state).line = sel_colrow[1]
            (*state).linebegin = sel_offset_line
            (*state).clicks = 0
            (*state).offset = ev.offset
            ; Highlight the page number/book name string.
            HighlightPageNum, ev
         ENDELSE
      ENDELSE

   ENDIF ;}}}

   ; If we've got a keyboard character event... {{{
   IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TEXT_CH') THEN BEGIN

       CASE ev.ch OF
         9b: BEGIN       ; Tab key
              WIDGET_CONTROL, (*state).ixtext, /INPUT_FOCUS
              list_select_ev, { WIDGET_TEXT_SEL, ID:ev.id, TOP:ev.top, $
                 HANDLER:ev.handler, TYPE:3, OFFSET:ev.offset, $
                 LENGTH:0L }
           END
         10b: ShowHelp, state       ; Enter key
         ELSE:
       ENDCASE
   ENDIF ;}}}

   ; Check the clicks field of the state structure. If the value
   ; is more than one, display the selected topic and reset the
   ; field.
   IF (*state).clicks GT 1 THEN BEGIN
      ShowHelp, state
      (*state).clicks=0
   ENDIF

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO list_search_ev, ev ;{{{
; Event handler for the text input field. Typing in the field
; performs an incremental search in the index list, moving the
; selection in the index list to the first match.

   COMPILE_OPT idl2, HIDDEN


   WIDGET_CONTROL, ev.TOP, GET_UVALUE=state

   ; Set the "context change" flag to specify that a select can
   ; be made in the text input field. This keeps the index list
   ; from updating its selection when a selection is created
   ; in the text input field.
   (*state).ccFlag=1

   ; Catch some special keys:
   IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TEXT_CH') THEN BEGIN
      CASE ev.ch OF
         9b: WIDGET_CONTROL, (*state).ixlist, /INPUT_FOCUS ; Tab
         10b: ShowHelp, state                          ; Enter
         ELSE:
      ENDCASE
   ENDIF

   ; Get the value of the string.
   WIDGET_CONTROL, ev.ID, GET_VALUE=str

   ; Get the number of lines in the list
   lines = N_ELEMENTS(*(*state).list)

   ; Retrieve the value of the element in the 'itable' array that
   ; corresponds to the byte value of the first character in the
   ; input string. This element contains the index of the array
   ; element that contains the first instance of that character in
   ; the index array.
   IF (str NE '') THEN $
      i=(*state).itable[BYTE(STRLOWCASE(STRMID(str,0,1)))] $
      ELSE i=0

   ; Retrieve the value of the _next_ element in the 'itable' array
   ; that is not -1. This value is used to limit the search to
   ; lines that begin with the first character typed.
   j = -1 & k = 1
   WHILE (j eq -1) DO BEGIN
      j=(*state).itable[BYTE(STRLOWCASE(STRMID(str,0,1))) + k++]
      IF (j lt i) THEN j=-1
   ENDWHILE

   ; Initialize the loop control variable
   go=1

   WHILE (go) DO BEGIN
      ; Compare the string in the text widget to each string in the
      ; list until a match is found. Note that we start searching with
      ; the first line in the list that contains the first character
      ; typed, but after that it's a brute-force linear search.
      IF STRCMP(STRLOWCASE(str), STRLOWCASE((*(*state).list)[i]), $
         STRLEN(str)) THEN BEGIN

         ; Get the offset to the beginning of the line that matches.
         sel_offset_line = WIDGET_INFO((*state).ixlist, TEXT_XY_TO_OFFSET=[0,i])
         ;
         ; Scroll the widget to put that line at the top.
         WIDGET_CONTROL, (*state).ixlist, SET_TEXT_TOP_LINE=i

         ; Calculate the offsets for the page number/book name string
         selection = SelectPageNum(ev, sel_offset_line, [0,i], *(*state).list)
         ; Update the state with the new selection
         (*state).selection = selection

         ; Highlight the page number/book name string.
         HighlightPageNum, ev

         ; Escape the loop
         go=0

      ENDIF ELSE BEGIN
         ; Increment the counter
         IF (i lt j) THEN i++ ELSE go=0
      ENDELSE
   ENDWHILE

END ;}}}
;---------------------------------------------------------------------

;---------------------------------------------------------------------
PRO online_help_pdf_index, topic, EXACT=exact

; This is the main procedure for the PDF documentation index
; widget application.

   COMPILE_OPT idl2

   ; Currently, this routine only runs under UNIX.
   IF !VERSION.OS_FAMILY EQ 'Windows' THEN BEGIN
      MESSAGE, 'This routine runs only under UNIX.', /CONTINUE
      RETURN
   ENDIF

   ; We need to store the widget ID of the top-level base in a
   ; common block to be able to control the app from the IDL
   ; command line
   COMMON ONLINE_HELP_PDF_INDEX, tbase

   ; There should be exactly one argument, and it should have
   ; no leading or trailing whitespace.
   IF ( N_ELEMENTS(topic) NE 1 ) THEN topic=''
   topic = STRCOMPRESS(topic, /REMOVE_ALL)

   ; The EXACT keyword indicates that topic is a known Named
   ; Destination that can be displayed directly by ONLINE_HELP.
   IF ~KEYWORD_SET(exact) THEN exact='0'

   ; If the app is already running, first clear the text field
   ; and then populate it with the value of 'topic'.
   IF ( XREGISTERED('online_help_pdf_index') NE 0 ) THEN BEGIN
      WIDGET_CONTROL, tbase, GET_UVALUE=state
      WIDGET_CONTROL, (*state).ixtext, SET_VALUE=''
      (*state).hasFocus = 1
      list_search_ev, {WIDGET_TEXT_CH, ID:(*state).ixtext, TOP:(*state).tbase, $
         HANDLER:(*state).ixtext, TYPE:0, OFFSET:0l, CH:0b }
      WIDGET_CONTROL, (*state).ixtext, SET_VALUE=topic
      list_search_ev, {WIDGET_TEXT_CH, ID:(*state).ixtext, TOP:(*state).tbase, $
         HANDLER:(*state).ixtext, TYPE:0, OFFSET:STRLEN(topic)-1, CH:0b }
      RETURN
   ENDIF

   ; Define the list of books in the IDL doc set
   booknames = [  "Building IDL Applications", $
                  "DataMiner Guide", $
                  "External Development Guide", $
                  "Getting Started", $
                  "Image Processing", $
                  "Installation", $
                  "Intro to ION", $
                  "ION Java User's Guide", $
                  "ION Quick Reference", $
                  "ION Script User's Guide", $
                  "iTool Developer's Guide", $
                  "iTool User's Guide", $
                  "Medical Imaging in IDL", $
                  "Master Index", $
                  "Obsolete Features", $
                  "Online Guide", $
                  "Quick Reference", $
                  "Reference Guide", $
                  "Scientific Data Formats", $
                  "Using IDL", $
                  "Wavelet Toolkit User's Guide", $
                  "What's New in IDL"]

   ; Define the list of books in the IDL doc set. Note that
   ; this list of abbreviations is matched with the names of
   ; PDF files in the PickBook function.
   book_abr = ['Bld', 'DM', 'EDG', 'GS', 'Img', 'Inst', 'IonI', $
      'IonJ', 'IonQ', 'IonS', 'ITD', 'ITU', 'Med', 'MIDX', 'Obs', $
      'Onlg', 'Quik', 'Ref', 'SDF', 'Use', 'Wav', 'WN']

   ; Load bookmarks from file or defaults
   bkmarks = GetBookmarks(BOOKFILE=bkfile, PREFS=prefs)

   ; If we got an exact match of a named destination AND
   ; the user preference says don't show this UI if we got
   ; an exact match, return.
   IF ((exact EQ 1) && (prefs.show_always EQ 0)) THEN RETURN

   ; Find the Index file
   file = FILEPATH('mindex.txt', SUBDIR=['help'])

   ; Get the info structure on the selected file
   fileInfo = FILE_INFO(file)

   ; If file exists and is readable, show the index.
   IF fileInfo.read THEN BEGIN

      ; Create an array to hold the index
      nlines=LONG(FILE_LINES(file))
      index=strarr(nlines)
      ; Create an array to hold the index of the first element
      ; in the 'index' array that starts with each ASCII character.
      itable=LONARR(256)
      itable[*]=-1
      itable[255]=nlines

      ; Open the file
      OPENR, unit, file, /GET_LUN, ERROR=err

      ; Exit if error occurs
      IF (err NE 0) THEN BEGIN
         void = DIALOG_MESSAGE(!ERROR_STATE.MSG)
         RETURN
      ENDIF

      ; Read the contents of the file into the 'index' array and
      ; populate the 'itable' array with the index into the 'index'
      ; array for the first line that contains each letter or symbol.
      ; (The 'itable' array is used in the list_search_ev routine.)
      line=''
      FOR i = 0l, nlines-1 DO BEGIN
         READF, unit, line
         index[i] = line
         letter = BYTE(STRLOWCASE(STRMID(line,0,1)))
         IF (itable[letter] EQ -1) THEN itable[letter]=i
      ENDFOR

      ; Close the file
      FREE_LUN, unit

      ; Create the widgets
      ;
      ; First create the top-level base and common controls
      tbase=WIDGET_BASE(/COLUMN, $
         XSIZE=prefs.width, YSIZE=prefs.height, $
         XOFFSET=prefs.xpos, YOFFSET=prefs.ypos, $
         TLB_FRAME_ATTR=2, $
         /TLB_SIZE_EVENTS, $
         /TLB_ICONIFY_EVENTS, $
         /TLB_MOVE_EVENTS, $
         /TLB_KILL_REQUEST_EVENTS, $
         /TRACKING_EVENTS, $
         /KBRD_FOCUS_EVENTS, $
         TITLE='IDL Documentation Index')
      tbase2=WIDGET_BASE(tbase, /ROW, XPAD=3, /ALIGN_RIGHT)
      bHelp = WIDGET_BUTTON(tbase2, VALUE='  Help  ', TOOLTIP='What is this?', $
         EVENT_PRO='help_ev')
      wTab = WIDGET_TAB(tbase, EVENT_PRO='tab_change_ev')

      ; Next the index-view widgets
      ixbase=WIDGET_BASE(wTab, TITLE='  Index  ', /COLUMN)
      ixbase2=WIDGET_BASE(ixbase, /ROW)
      ixLabel=WIDGET_LABEL(ixbase2, VALUE='Enter a search string')
      ixtext=WIDGET_TEXT(ixbase, YSIZE=1, $
         EVENT_PRO='list_search_ev', /EDIT, /ALL_EVENTS)
      ixlist=WIDGET_TEXT(ixbase, YSIZE=25, $
         EVENT_PRO='list_select_ev', /SCROLL, /ALL_EVENTS)
      prefbase=WIDGET_BASE(ixbase, /NONEXCLUSIVE)
      showpref=WIDGET_BUTTON(prefbase, VALUE='Always Show This List', $
         EVENT_PRO='showpref_ev')

      ; Now the bookmark-view widgets
      bkbase = WIDGET_BASE(wTab, TITLE=' Bookmarks ', /COLUMN)
      label = WIDGET_LABEL(bkbase, VALUE='Select a bookmark', /ALIGN_LEFT)
      bklist = WIDGET_TEXT(bkbase,  /ALL_EVENTS, /SCROLL, $
         VALUE=bkmarks, YSIZE=3, EVENT_PRO='list_select_ev')
      bkbase2 = WIDGET_BASE(bkbase, /COLUMN, YPAD=10)
      label = WIDGET_LABEL(bkbase2, VALUE='Manage Bookmarks', /ALIGN_LEFT)
      bkbase3 = WIDGET_BASE(bkbase2, /COLUMN, /FRAME, /ALIGN_CENTER)
      bkbase4 = WIDGET_BASE(bkbase3, /ROW)
      bkLabel1 = WIDGET_LABEL(bkbase4, VALUE='Bookmark Text: ')
      bkText = WIDGET_TEXT(bkbase4, /EDITABLE, /ALL_EVENTS, $
         XSIZE=100, EVENT_PRO='nothing_ev')
      bkBooks = WIDGET_DROPLIST(bkbase3, TITLE='Book: ', VALUE=booknames, $
         EVENT_PRO='nothing_ev')
      bkbase5 = WIDGET_BASE(bkbase3, /ROW)
      label = WIDGET_LABEL(bkbase5, VALUE='Page number: ')
      bkPnum = WIDGET_TEXT(bkbase5, XSIZE=6, /EDITABLE, /ALL_EVENTS, $
         EVENT_PRO='nothing_ev')
      abkbase = WIDGET_BASE(bkbase3, /ROW, /ALIGN_CENTER)
      bAdd = WIDGET_BUTTON(abkbase, VALUE='  Add  ', $
         EVENT_PRO='AddBookmark')
      pad = WIDGET_BASE(abkbase, XSIZE=20)
      bEditBk = WIDGET_BUTTON(abkbase, VALUE='  Edit  ', $
         EVENT_PRO='EditBookMark')
      pad = WIDGET_BASE(abkbase, XSIZE=20)
      bDelBk = WIDGET_BUTTON(abkbase, VALUE=' Delete ', $
         EVENT_PRO='DeleteBookMark')

      ; Finally, the bottom row of common controls
      xbase3=WIDGET_BASE(tbase, /ROW)
      xbase3a=WIDGET_BASE(xbase3, /COLUMN, /ALIGN_LEFT)
      xbase3b=WIDGET_BASE(xbase3, /COLUMN, /ALIGN_RIGHT)
      bDone=WIDGET_BUTTON(xbase3a, VALUE='  Done  ', EVENT_PRO='Done_ev')
      bDisplay = WIDGET_BUTTON(xbase3b, VALUE=' Display ', EVENT_PRO='Go_ev')

      ; Populate the state structure
      st = { list:PTR_NEW(index, /NO_COPY), $
                page:0L, $
                book:'', $
                offset:0L, $
                line:[0L], $
                linebegin:0L, $
                selection:[0L,0L], $
                clicks:0L, $
                show_always:prefs.show_always, $
                itable:itable, $
                tbase:tbase, $
                hasFocus:0, $
                wTab:wTab, $
                ixbase:ixbase, $
                ixbase2:ixbase2, $
                ixtext:ixtext, $
                ixlist:ixlist, $
                prefbase:prefbase, $
                book_abr:book_abr, $
                bkfile:bkfile, $
                bklist:bklist, $
                bkbase3:bkbase3, $
                bkbase4:bkbase4, $
                bkLabel1:bkLabel1, $
                bkText:bkText, $
                bkBooks:bkBooks, $
                bkPnum:bkPnum, $
                bkmarks:PTR_NEW(bkmarks, /NO_COPY), $
                ccFlag:0, $
                xpos:prefs.xpos, $
                ypos:prefs.ypos, $
                width:prefs.width, $
                height:prefs.height }

      state = PTR_NEW(st, /NO_COPY)
      ; Populate the text widget with the index
      WIDGET_CONTROL, ixlist, SET_VALUE=*(*state).list, /NO_COPY

      ; Store the state structure
      WIDGET_CONTROL, tbase, SET_UVALUE=state

      ; Realize the widgets
      WIDGET_CONTROL, tbase, MAP=0
      WIDGET_CONTROL, tbase, /REALIZE

      ; Set the height of the bookmark list to fit the tab.
      tabheight = (WIDGET_INFO(wTab, /GEOMETRY)).scr_ysize
      bkbheight = ((WIDGET_INFO(bkbase, /GEOMETRY))).scr_ysize
      bkb3height = (WIDGET_INFO(bkbase3, /GEOMETRY)).scr_ysize
      bklheight = tabheight - bkb3height
      WIDGET_CONTROL, bklist, SCR_YSIZE=bkbheight
      bkbheight = (WIDGET_INFO(bkbase, /GEOMETRY)).scr_ysize

      ; Set the height of the index list to fit the tab.
      ixbheight = (WIDGET_INFO(ixbase, /GEOMETRY)).scr_ysize
      prefheight = (WIDGET_INFO(prefbase, /GEOMETRY)).scr_ysize
      ixlheight = tabheight - prefheight
      WIDGET_CONTROL, ixlist, SCR_YSIZE=ixlheight

      ; Populate the text entry field
      WIDGET_CONTROL, ixtext, SET_VALUE=topic, /INPUT_FOCUS

      ; Set the checkmark in the preferences button
      WIDGET_CONTROL, showpref, SET_BUTTON=prefs.show_always

      ; Send an inital event to force the list to update if
      ; a topic was supplied.
      list_search_ev, {WIDGET_TEXT_CH, ID:ixtext, TOP:tbase, HANDLER:ixtext, $
                                       TYPE:0, OFFSET:0l, CH:0b }

      ; Retrieve the "real" geometry and update the state structure
      tbase_g = WIDGET_INFO(tbase, /GEOMETRY)
      (*state).width = tbase_g.scr_xsize - (tbase_g.xpad*2)
      (*state).height = tbase_g.scr_ysize - (tbase_g.ypad*2)

      ; Send an event to force the widget sizes to update.
      online_help_pdf_index_event, {WIDGET_BASE, ID:tbase, TOP:tbase, $
         HANDLER:tbase, X:0, Y:0 }

      ; Run XMANAGER
      XMANAGER, 'online_help_pdf_index', tbase, /NO_BLOCK

      ; Map the base
      WIDGET_CONTROL, tbase, MAP=1

      ; Set focus to the text input widget
      WIDGET_CONTROL, ixtext, /INPUT_FOCUS

   ENDIF ELSE BEGIN
      ; If index file is missing...
      void = DIALOG_MESSAGE(['Index file not found or not readable.', $
         ' ', 'See ONLINE_HELP_PDF_INDEX in the IDL Reference Guide', $
         'for information.'])
   ENDELSE
END
;---------------------------------------------------------------------

