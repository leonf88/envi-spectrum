; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5_browser.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5_BROWSER
;
; PURPOSE:
;   Provides a graphical user interface (GUI) to examine HDF5 files
;   and import data into IDL.
;
; CALLING SEQUENCE:
;   Result = H5_BROWSER(Files [, /DIALOG_READ] )
;
; RETURN VALUE:
;   Result: If the DIALOG_READ keyword is set, then the Result is either
;          a structure containing the dataset/group, or a 0 if the Cancel
;          button was pressed.
;          If DIALOG_READ is not set, then the Result is the widget ID
;          for the base widget.
;
; INPUTS:
;   Files: A scalar or array of strings giving the file(s) to open
;          in the browser. Users can also interactively import new files.
;          Files may contain wildcard characters.
;
; KEYWORD PARAMETERS:
;
;   DIALOG_READ = If this keyword is set then the HDF5 browser is created
;          as a modal Open/Cancel dialog instead of a standalone GUI.
;          In this case, the IDL command line is blocked, and no further
;          input is taken until the Open or Cancel button is pressed.
;          If the GROUP_LEADER keyword is specified, then that widget ID
;          is used as the group leader, otherwise a default group leader
;          base is created.
;
;   All keywords to WIDGET_BASE such as GROUP_LEADER, TITLE, etc.
;   are passed on to the top level base.
;
;
; EXAMPLE
;   file = FILEPATH('hdf5_test.h5', SUBDIR=['examples','data'])
;   r = H5_BROWSER(file)
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, June 2002
;   Modified by:
;       AJ, CREASO B.V., February 12th 2003: Use with ENVI
;
;-


;-------------------------------------------------------------------------
pro h5_browser_addfile, wTree, files

    compile_opt idl2, hidden

    ; Retrieve list of current files.
    WIDGET_CONTROL, wTree, GET_UVALUE=currentFiles
    ; Initialize if necessary.
    if (N_ELEMENTS(currentFiles) eq 0) then currentFiles = ''
    WIDGET_CONTROL, /HOURGLASS

    ; Flags so we don't repeat hundreds of error msgs.
    noexist = 0
    nothdf5 = 0
    noparse = 0


    for i=0,N_ELEMENTS(files)-1 do begin

        ; First see if we have a single, simple filename.
        ; This is faster than doing a generic file search.
        if (FILE_TEST(files[i], /READ)) then begin
            fname = files[i]
            count = 1
        endif else begin
            ; There may be more than one matching file if the
            ; user entered a wildcard character.
            fname = FILE_SEARCH(files[i], COUNT=count)
        endelse

        ; Make sure file exists.
        if (count eq 0) then begin
            if (noexist eq 0) then begin
                noexist = 1  ; only show message once
                dummy = DIALOG_MESSAGE( $
                    "Can't open the file '"+files[i]+"'.", $
                    DIALOG_PARENT=wTree, /ERROR)
            endif
            continue
        endif

        ; Loop thru all matching files.
        for j=0,count-1 do begin

            ; Make sure we havn't already opened the file.
            if (TOTAL(currentFiles eq fname[j]) gt 0) then $
                continue

            ; Make sure is a valid HDF5 file.
            if (not H5F_IS_HDF5(fname[j])) then begin
                if (nothdf5 eq 0) then begin
                    nothdf5 = 1  ; only show message once
                    dummy = DIALOG_MESSAGE( $
                        "Not a valid HDF5 file: '"+fname[j]+"'.", $
                        DIALOG_PARENT=wTree, /ERROR)
                endif
                continue
            endif

            CATCH, error
            if (error ne 0) then begin   ; error parsing
                CATCH, /CANCEL
                if (noparse eq 0) then begin
                    noparse = 1
                    dummy = DIALOG_MESSAGE( $
                        ["Error parsing '"+fname[j]+"':", $
                        !ERROR_STATE.msg], $
                        DIALOG_PARENT=wTree, /ERROR)
                endif
                MESSAGE, /RESET
            endif else begin
                sTree = H5_PARSE(fname[j])
                WIDGET_CONTROL, wTree, UPDATE=0
                WIDGET_CONTROL, wTree, SET_VALUE=sTree
                WIDGET_CONTROL, wTree, /UPDATE
           endelse

            currentFiles = [currentFiles, fname[j]]
        endfor  ; j

    endfor  ; i

    WIDGET_CONTROL, HOURGLASS=0
    WIDGET_CONTROL, wTree, SET_UVALUE=currentFiles

end


;-------------------------------------------------------------------------
; Handle File/Open events.
; Allow user to select multiple HDF5 files, and parse them.
;
pro h5_browser_fileopen, event

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; Allow user to select files.
    files = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
        FILTER=['*.h5', '*.hdf5', '*.he5'], $
        GET_PATH=path, $
        /MULTIPLE_FILES, $
        /MUST_EXIST, $
        TITLE='Select HDF5 files to open')

    ; User hit cancel.
    if (files[0] eq '') then $
        return

    ; Change current working directory. Hope this makes people happy.
    CD, path

    H5_BROWSER_ADDFILE, state.wTree, files
end


;-------------------------------------------------------------------------
; Handle File/Exit events.
;
pro h5_browser_fileexit, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, /DESTROY

end


;-------------------------------------------------------------------------
; Handle button events which cause a redraw.
;
pro h5_browser_toggle, event

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; Update the preview window.
    H5_BROWSER_TREE_PREVIEW, state

end


;-------------------------------------------------------------------------
; Handle Import events.
; Allow user to import HDF5 groups and datasets into IDL session.
; Checks the "Include data" button and reads data if necessary.
;
pro h5_browser_import, event

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state
    WIDGET_CONTROL, state.wTree, GET_VALUE=sSelect

    if (N_TAGS(sSelect) eq 0) then begin
        MESSAGE, /INFO, /NONAME, 'Nothing selected.'
        return
    endif

    includeData = 1  ; default

    if (not state.dialogread) then begin

        ; We can assume that name is a valid IDL variable name,
        ; since it should have been checked when the user modified it.
        WIDGET_CONTROL, state.wName, GET_VALUE=name

        ; Cannot store into an unnamed variable.
        if (name eq '') then $
            return

        includeData = WIDGET_INFO(state.wIncdata, /BUTTON_SET)
    endif

    ; If we are importing a dataset or a group, we may
    ; need to re-parse the file and read the actual data.
    ; Attributes don't have this problem because we automatically
    ; read in all attribute data.
    isDataset = sSelect._type eq 'DATASET'
    isGroup = sSelect._type eq 'GROUP'

    if ((isDataset or isGroup) and includeData) then begin

        CATCH, error

        if (error ne 0) then begin   ; error parsing
            CATCH, /CANCEL
            dummy = DIALOG_MESSAGE( $
                ["Error parsing '"+sSelect._file+"':", $
                !ERROR_STATE.msg], $
                DIALOG_PARENT=state.wTree, /ERROR)
            MESSAGE, /RESET
            return
        endif

        WIDGET_CONTROL, /HOURGLASS

        ; Open the file, and descend down to the selected group.
        file_id = H5F_OPEN(sSelect._file)
        group_id = H5G_OPEN(file_id, sSelect._path)

        ; Parse just the selected group or dataset, reading the data.
        ; If we are at the top level, then the _NAME actually contains
        ; the filename. In this case use / as the object to parse.
        ; Otherwise just use the _NAME.
        object = (sSelect._name ne sSelect._file) ? sSelect._name : '/'
        sSelect = H5_PARSE(group_id, object, $
            FILE=sSelect._file, $
            PATH=sSelect._path, $
            /READ_DATA)

        H5G_CLOSE, group_id
        H5F_CLOSE, file_id

    endif

    if (state.dialogread) then begin
        ; Return variable as the function result.
        *state.pSelect = TEMPORARY(sSelect)
        ; We've hit the "Open" button, so we're done.
        WIDGET_CONTROL, event.top, /DESTROY
    endif else begin
        ; Import variable into the $MAIN$ IDL session level.
        (SCOPE_VARFETCH(name, /ENTER, LEVEL=1)) = TEMPORARY(sSelect)
        MESSAGE, /INFO, /NONAME, 'Imported variable: '+ name
    endelse

end


;-------------------------------------------------------------------------
pro h5_browser_checkname, event

    compile_opt idl2, hidden

    ; If the text widget is only gaining keyboard focus, don't
    ; bother checking the name. Note that we need to do the check
    ; in 2 stages since the other text events don't have the ENTER tag.
    if (TAG_NAMES(event, /STRUCT) eq 'WIDGET_KBRD_FOCUS') then $
        if (event.enter eq 1) then return

    WIDGET_CONTROL, event.id, GET_VALUE=name, GET_UVALUE=oldname

    if (STRLEN(name) gt 0) then $
        name = IDL_VALIDNAME(name, /CONVERT_ALL)

    ; If the user enters a null string, revert to prior name.
    if (name eq '') then name = oldname
    WIDGET_CONTROL, event.id, SET_VALUE=name, SET_UVALUE=name
end


;-------------------------------------------------------------------------
; Convert a string to mixed case, Abcde.
;
function h5_browser_strmixcase, name

    compile_opt idl2, hidden

    return, STRUPCASE(STRMID(name,0,1))+STRLOWCASE(STRMID(name,1))

end


;-------------------------------------------------------------------------
; Given an IDL variable, return a string representation.
;
function h5_browser_parsevalue, value

    compile_opt idl2, hidden

    type = SIZE(value, /TYPE)

    case type of

        0: result = '<Undefined>'

        8: result = '<Structure>'

        10: result = '<Pointer>'

        11: result = '<Objref>'

        else: begin

            n = N_ELEMENTS(value)

            if (SIZE(value,/N_DIM) eq 0) then begin   ; scalar

                if (type ne 7) then begin     ; nonstrings

                    ; Remove extra whitespace from non-strings.
                    result = STRTRIM(STRING(value, /PRINT), 2)

                endif else begin              ; strings

                    crlf = STRING(13b) + STRING(10b)

                    if (!VERSION.os_family eq 'Windows') then begin

                        ; Windows expects CR/LF characters after each line.
                        ; Split at linefeeds, but not LF preceeded by CR.
                        result = STRSPLIT(value, STRING(10b), $
                            ESCAPE=STRING(13b), /EXTRACT)
                        ; Join back together with CR/LF.
                        result = STRJOIN(result, crlf)

                    endif else begin

                        ; Unix expects LF characters after each line.
                        ; Split at CR/LF (not CR or LF individually).
                        result = STRSPLIT(value, crlf, /REGEX, /EXTRACT)
                        ; Join back together with LF only.
                        result = STRJOIN(result, STRING(10b))

                    endelse

                endelse   ; string

            endif else begin   ; array

                ; If it is a string array with each character in a seperate
                ; cell then just join the elements and show the result
                if (type eq 7) and (n ge 2) then begin
                    ; Do not include the last character (CR/LF).
                    sl = STRLEN(value[0:n-2])
                    ; Check they are all of length 1 (or 0).
                    join = MAX(sl) eq 1
                endif else $
                    join = 0

                if join then begin

                  result = H5_BROWSER_PARSEVALUE(STRJOIN(value))

                endif else begin

                  ; Convert first few elements to strings.
                  nmax = 20
                  n1 = n < nmax
                  result = ''
                  for i=0,n1-1 do begin
                      result = result + H5_BROWSER_PARSEVALUE(value[i]) + $
                          ((i lt n1-1) ? ', ' : ((n gt nmax) ? ',...' : ''))
                  endfor
                  if (n gt 1) then $
                      result = '[' + result + ']'

                endelse

            endelse   ; array

            end

    endcase

    return, result
end


;-------------------------------------------------------------------------
function h5_browser_get_palette, sSelect, dataset_id

    compile_opt idl2, hidden

    ; There are a lot of reasons why getting the palette
    ; may fail:
    ;  The data may not be of class 'IMAGE'.
    ;  There may be no palette.
    ;  The reference may be invalid.
    ; To avoid having error checking for all these cases, we
    ; bravely attempt to extract the palette data, catching all
    ; errors and quietly returning.
    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, /RESET
        return, 0
    endif

    ; Try to read the PALETTE attribute, containing the reference data.
    attr_id = H5A_OPEN_NAME(dataset_id, 'PALETTE')
    reference = H5A_READ(attr_id)

    ; Try to read the palette data.
    palette_dataset = H5R_DEREFERENCE(attr_id, reference[0])
    result = H5D_READ(palette_dataset)
    H5D_CLOSE, palette_dataset
    H5A_CLOSE, attr_id

    return, result
end



;-------------------------------------------------------------------------
; Internal procedure to update the preview window.
;
; state is our Widget state structure.
;
; sSelect is the optional HDF5 structure stored in the tree.
; If not supplied it will be retrieved from the widget.
;
; UPDATE_TEXT: If set, then add the first few data elements to the
;      text window.
;
pro h5_browser_tree_preview, state, sSelect, UPDATE_TEXT=updateText

    compile_opt idl2, hidden

    ; Be sure to clear out previous contents.
    WSET, state.iWin

    ; Make sure the preview box is checked.
    if (not WIDGET_INFO(state.wPreview, /BUTTON_SET)) then begin
        ERASE
        return
    endif

    ; Retrieve structure corresponding to current selection.
    if (N_PARAMS() eq 1) then $
        WIDGET_CONTROL, state.wTree, GET_VALUE=sSelect

    ; In case nothing is selected.
    if (N_TAGS(sSelect) lt 1) then begin
        ERASE
        return
    endif

    ; Do all of our generic checks first, before doing the widget check.
    if (sSelect._type ne 'DATASET') then begin
        ERASE
        return
    endif

    ; We can only handle a few datatypes.
    if (sSelect._datatype ne 'H5T_INTEGER') and $
       (sSelect._datatype ne 'H5T_FLOAT') then begin
        ERASE
        return
    endif

    ; Can't plot a scalar.
    if (sSelect._ndimensions lt 1) then begin
        ERASE
        return
    endif


    CATCH, error

    if (error ne 0) then begin   ; error parsing
        CATCH, /CANCEL
        dummy = DIALOG_MESSAGE( $
            ["Error previewing '"+sSelect._file+"':", $
            !ERROR_STATE.msg], $
            DIALOG_PARENT=state.wTree, /ERROR)
        MESSAGE, /RESET
        return
    endif

    WIDGET_CONTROL, /HOURGLASS

    ndim = sSelect._ndimensions
    dims = sSelect._dimensions
    start = LONARR(ndim)
    count = LONARR(ndim) + 1

    ; We only read in the first 1 or 2 dimensions.
    ndmax = (ndim le 1) ? 1 : 2

    ; Check for multi-channel images.
    ; Look for a 3 in the first three dimensions.
    interleave = (ndim eq 3) ? (WHERE(dims eq 3))[0] : -1
    if (interleave ge 0) then ndmax = 3

    ; Ignore first two dimensions of length 1.
    if (dims[0] le 1) then ndmax = 2 > ndmax
    if (ndim ge 2) then if (dims[1] le 1) then ndmax = 3

    ; Restrict the count to the first 3 dimensions (or less).
    count[0] = dims[0:(ndmax-1) < (ndim-1)]

    ; If necessary, use stride to fit the data to the window.
    if (ndim ge 2) then begin

        ; Image dimensions within HDF5 file.
        nx = (interleave eq 0) ? dims[1] : dims[0]
        ny = ((interleave eq 0) or (interleave eq 1)) ? dims[2] : dims[1]

        ; Compute factor to scale image down by to fit window.
        geom = WIDGET_INFO(state.wDraw, /GEOMETRY)
        xfactor = nx/geom.scr_xsize
        yfactor = ny/geom.scr_ysize
        factor = FIX((xfactor > yfactor) + 0.99999999d)

        ; Read in slightly larger than necessary if Fit to window.
        ; We will shrink the image below.
        fitwindow = WIDGET_INFO(state.wFitwindow, /BUTTON_SET)
        if (fitwindow) then factor = factor - 1

        ; Only need to use stride to shrink the data.
        if (factor gt 1) then begin
            stride = REPLICATE(factor, ndim)
            if (interleave ge 0) then stride[interleave] = 1
            ; Watch out for count values that become 0.
            count = (count/stride) > 1
        endif

        memspace_id = H5S_CREATE_SIMPLE(count)
    endif

    file_id = H5F_OPEN(sSelect._file)
    group_id = H5G_OPEN(file_id, sSelect._path)
    dataset_id = H5D_OPEN(group_id, sSelect._name)

    dataspace_id = H5D_GET_SPACE(dataset_id)
    H5S_SELECT_HYPERSLAB, dataspace_id, start, count, $
        STRIDE=stride, /RESET

    ; (memspace_id will be undefined if no shrinkage needed)
    data = H5D_READ(dataset_id, $
        FILE_SPACE=dataspace_id, $
        MEMORY_SPACE=memspace_id)

    H5S_CLOSE, dataspace_id
    if (N_ELEMENTS(memspace_id) eq 1) then $
        H5S_CLOSE, memspace_id

    data = REFORM(data, /OVER)   ; drop dimensions of length 1
    ndim = SIZE(data, /N_DIMENSIONS)


    ; Add in the first few data elements, if desired.
    if (KEYWORD_SET(updateText)) then begin

        ntext = 20

        ; If we needed a stride for the preview, we need to
        ; re-read the first few data elements.
        if (N_ELEMENTS(stride) && ~ARRAY_EQUAL(stride, 1)) then begin
            nelts = PRODUCT(dims) < ntext
            ; Calculate coordinates for the first few data elements.
            coords = ARRAY_INDICES(dims, LINDGEN(nelts), /DIMENSIONS)

            dataspace_id = H5D_GET_SPACE(dataset_id)
            H5S_SELECT_ELEMENTS, dataspace_id, coords, /RESET
            ; Throw the points into a vector.
            memspace_id = H5S_CREATE_SIMPLE(nelts)
            textdata = H5D_READ(dataset_id, $
                FILE_SPACE=dataspace_id, $
                MEMORY_SPACE=memspace_id)
            H5S_CLOSE, dataspace_id
            H5S_CLOSE, memspace_id

        endif else begin

            textdata = data[0:(ntext < N_ELEMENTS(data))-1]

        endelse

        WIDGET_CONTROL, state.wText, GET_VALUE=text
        text = [text, $
            'Data:', H5_BROWSER_PARSEVALUE(textdata)]
        WIDGET_CONTROL, state.wText, SET_VALUE=text
    endif


    if (ndim eq 1) then begin

        n = N_ELEMENTS(data)

        if (n gt 1) then begin

            ; STYLE=26 is "Extend range, No box, Y minimum not 0"
            PLOT, data, $
                PSYM=-6*(n lt 1000), $
                SYMSIZE=0.75, $
                XSTYLE=26, YSTYLE=26

        endif else begin
            ; Scalar point. Do nothing.
            ERASE
        endelse

    endif else begin

        ; Swap interleaved dimensions to planar interleaving.
        ; This is just for programming convenience below.
        case (interleave) of
            0: data = TRANSPOSE(data, [1,2,0])
            1: data = TRANSPOSE(data, [0,2,1])
            else:  ; do nothing
        endcase


        LOADCT, 0, /SILENT   ; switch to black & white palette


        ; Expand or shrink image to fit in window?
        if (fitwindow) then begin
            dims = SIZE(data, /DIMENSIONS)
            xfactor = dims[0]/geom.scr_xsize
            yfactor = dims[1]/geom.scr_ysize
            factor = (xfactor > yfactor)
            dims[0:1] = dims[0:1]/factor
            data = (ndim eq 3) ? $
                CONGRID(data, dims[0], dims[1], dims[2]) : $
                CONGRID(data, dims[0], dims[1])
        endif


        ; Center image within the window.
        dims = SIZE(data, /DIMENSIONS)
        xpos = ((geom.scr_xsize - dims[0])/2) > 0
        ypos = ((geom.scr_ysize - dims[1])/2) > 0


        ; Flip vertical or horizontal?
        order = WIDGET_INFO(state.wFlipvert, /BUTTON_SET)
        if (WIDGET_INFO(state.wFliphoriz, /BUTTON_SET)) then $
            data = REVERSE(data)   ; works fine for 2D or 3D data


        ; Byte data?
        if (sSelect._storagesize eq 1) then begin

            ; If single channel, then look for a palette.
            if (interleave eq -1) then begin
                palette = H5_BROWSER_GET_PALETTE(sSelect, dataset_id)
                if (SIZE(palette, /N_DIM) eq 2) then begin
                    d = SIZE(palette, /DIMENSIONS)
                    if (d[0] eq 3) then $
                        TVLCT, TRANSPOSE(palette) $
                    else if (d[1] eq 3) then TVLCT, palette
                endif
            endif

            ERASE
            TV, data, xpos, ypos, ORDER=1-order, TRUE=3*(ndim ge 3)

        endif else begin

            ERASE

            ; If there are no pending math exceptions, suppress any BYTSCL
            ; underflow errors.
            swallow = (CHECK_MATH(/NOCLEAR) eq 0)

            ; For non-byte data, just do a bytscl.
            data = BYTSCL(data)

            if (swallow) then $
                dummy = CHECK_MATH()

            if (MAX(data) eq 0b) then $
                data = data + 255b

            TV, data, xpos, ypos, ORDER=1-order, TRUE=3*(ndim ge 3)

        endelse

    endelse   ; 2D

    H5D_CLOSE, dataset_id
    H5G_CLOSE, group_id
    H5F_CLOSE, file_id

end


;-------------------------------------------------------------------------
pro h5_browser_tree_event, event

    compile_opt idl2, hidden

    ; Don't need to do anything for WIDGET_TREE_EXPAND events.
    if (event.type ne 0) then $
        return

    ; Double click events don't mean anything special, just swallow them.
    if (event.clicks eq 2) then $
        return

    wChild = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; Retrieve structure corresponding to current selection.
    WIDGET_CONTROL, state.wTree, GET_VALUE=sSelect

    text = ''
    name = ''

    if (N_TAGS(sSelect) gt 0) then begin

        name = sSelect._name
        text = H5_BROWSER_STRMIXCASE(sSelect._type) + ": '" + name + "'"

        switch (sSelect._type) of

            'GROUP': begin
                if (sSelect._comment ne '') then $
                    text = [text, "Comment: '" + sSelect._comment + "'"]
                break
                end

            'ATTRIBUTE':
            'DATASET':
            'DATATYPE': begin

                ; Start adding properties common to all.
                ssize = H5_BROWSER_PARSEVALUE(sSelect._storagesize) + $
                    ' byte' + $
                    ((sSelect._storagesize gt 1) ? 's' : '')
                if (sSelect._sign ne '') then $
                    ssize = ssize + ', ' + sSelect._sign
                text = [text, sSelect._datatype + ' (' + ssize + ')']

                ; Add dataspace properties.
                if ((sSelect._type eq 'ATTRIBUTE') or $
                    (sSelect._type eq 'DATASET')) then begin
                    text = [text, $
                        H5_BROWSER_PARSEVALUE(sSelect._nelements) + $
                        ' element' + ((sSelect._nelements gt 1) ? 's' : '')]
                    if (sSelect._ndimensions gt 1) then begin
                        text = [text, $
                        'Dimensions: ' + $
                        H5_BROWSER_PARSEVALUE(sSelect._dimensions)]
                    endif
                    if (sSelect._type eq 'ATTRIBUTE') then text = [text, $
                        'Data:', H5_BROWSER_PARSEVALUE(sSelect._data)]
                endif

                break
                end

            ; If it is a link follow it and display the content
            'LINK': begin
                ; Get the widget_id of the linked leaf using the UNAME
                linked_leaf = WIDGET_INFO(state.wTree, find_by_uname = sSelect._data)

                ; If empty link or non-existing link
                ; the linked_leaf widget-id will be invalid. Check this.
                if WIDGET_INFO(linked_leaf, /VALID) then begin

                    ; Select this leaf, make sure the tree expands.
                    WIDGET_CONTROL, WIDGET_INFO(linked_leaf, /PARENT), $
                        /SET_TREE_EXPANDED
                    WIDGET_CONTROL, state.wTree, SET_TREE_SELECT = linked_leaf

                    ; Resent the event now the new leaf is selected
                    WIDGET_CONTROL, event.id, send_event=event

                endif else begin

                    ; We might want to show where the link points at
                    ; to indicate to the user that it is not a valid link.
                    link = (sSelect._Data ne '') ? sSelect._Data : '<Nothing>'
                    text = [text, "Points to: '" + link + "'"]

                endelse

                break
                end

            else:

        endswitch
    endif

    WIDGET_CONTROL, state.wText, SET_VALUE=text


    if (N_TAGS(sSelect) eq 0) then $
        return

    ; If non-modal, change the variable name.
    if (not state.dialogread) then begin
        name = IDL_VALIDNAME(name, /CONVERT_ALL)
        if (name eq '') then name = 'temp'
        ; Also set the UVALUE to the same name, so we can revert to it
        ; if the user later types in a bad string.
        WIDGET_CONTROL, state.wName, $
            /SENSITIVE, $
            SET_VALUE=name, $
            SET_UVALUE=name
    endif

    WIDGET_CONTROL, state.wImport, /SENSITIVE

    H5_BROWSER_TREE_PREVIEW, state, sSelect, /UPDATE_TEXT

    return


end


;-------------------------------------------------------------------------
; Perform cleanup.
; id is the Widget ID of one of the subchildren of the base.
; This subchild contains the cached data needed to restore.
;
pro h5_browser_killnotify, id

    compile_opt idl2, hidden

    ; In case the user switches devices or something else fails,
    ; just quietly return since we are dying anyway.
    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, /RESET
        return
    endif

    WIDGET_CONTROL, id, GET_UVALUE=state

    ; Restore graphics variables.
    TVLCT, state.red, state.green, state.blue
    DEVICE, DECOMPOSED=state.decomposed

end


;-------------------------------------------------------------------------
pro h5_browser_event, event

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    case (TAG_NAMES(event, /STRUCT)) of

        'WIDGET_BASE': begin  ; resize

            ; Relative change in base size.
            dx = FIX((event.x - state.xsize)/2)*2
            dy = event.y - state.ysize

            ; We want to split the width change between the tree
            ; and the draw. However, we want to have a maximum tree
            ; width, and then give the rest of the change to the draw.

            ; Current size of tree and draw.
            geomtree = WIDGET_INFO(state.wTree, /GEOMETRY)
            geomdraw = WIDGET_INFO(state.wDraw, /GEOMETRY)

            ; Minimum & maximum widths.
            xmin = 150
            xmax = 300

            if (dx lt 0) then begin  ; Shrink width

                if (geomdraw.scr_xsize ge xmax) then begin
                    dx1 = ((dx + (geomdraw.scr_xsize - xmax))/2) < 0
                    xdrawsize = geomdraw.scr_xsize + (dx-2*dx1) + dx1
                    xtreesize = xmax + dx1
                endif else begin
                    ; Split the shrinkage evenly.
                    xdrawsize = geomdraw.scr_xsize + dx/2
                    xtreesize = xdrawsize
                endelse

                xdrawsize = xdrawsize > xmin
                xtreesize = xtreesize > xmin

            endif else begin  ; Expand width

                if (geomdraw.scr_xsize ge xmax) then begin
                    ; Give it all to the draw window.
                    xdrawsize = geomdraw.scr_xsize + dx
                    xtreesize = xmax
                endif else begin
                    ; Give half to the tree, up to the maximum.
                    xtreesize = (geomtree.scr_xsize + dx/2) < xmax
                    ; Give the rest to the draw.
                    dx1 = dx - (xtreesize - geomtree.scr_xsize)
                    xdrawsize = geomdraw.scr_xsize + dx1
                endelse

            endelse


            ; Change height of draw.
            ydrawsize = (geomdraw.scr_ysize + dy) > 100

            ; New "real" change, in case we were out of range.
            dy = ydrawsize - geomdraw.scr_ysize

            ; Change height of tree.
            ytreesize = (geomtree.ysize + dy) > 100

            WIDGET_CONTROL, state.wTree, XSIZE=xtreesize, YSIZE=ytreesize
            WIDGET_CONTROL, state.wDraw, XSIZE=xdrawsize, YSIZE=ydrawsize
            WIDGET_CONTROL, state.wText, SCR_XSIZE=xdrawsize
            if (not state.dialogread) then $
                WIDGET_CONTROL, state.wName, SCR_XSIZE=xdrawsize

            ; Cache new size of base.
            geom = WIDGET_INFO(state.wBase, /GEOMETRY)
            state.xsize = geom.xsize
            state.ysize = geom.ysize
            WIDGET_CONTROL, wChild, SET_UVALUE=state

            ; Update the preview window.
            H5_BROWSER_TREE_PREVIEW, state

            end

        else:
    endcase

end


;-------------------------------------------------------------------------
function h5_browser, files, $
    DIALOG_READ=dialogreadIn, $
    GROUP_LEADER=groupleaderIn, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2

    ON_ERROR, 2  ; return to caller

    myname = 'h5_browser'
    xsize = 300
    ysize = 530
    title = (SIZE(titleIn,/TYPE) eq 7) ? titleIn[0] : 'HDF5 Browser'
    dialogread = KEYWORD_SET(dialogreadIn)

    bitmappath = FILEPATH('', SUBDIR=['resource','bitmaps'])

    if (dialogread) then begin
        hasleader = N_ELEMENTS(groupleaderIn) eq 1
        groupleader = hasleader ? groupleaderIn[0] : $
            WIDGET_BASE(MAP=0)
    endif

    ; Top level base.
    wBase = WIDGET_BASE(/COLUMN, $
        /BASE_ALIGN_RIGHT, $
        GROUP_LEADER=groupleader, $
        FLOATING=dialogread, $
        MODAL=dialogread, TLB_FRAME_ATTR=0, $
        SPACE=1, XPAD=1, YPAD=1, $
        /TLB_SIZE_EVENTS, $
        TITLE=title, $
        _EXTRA=_extra)

    ; Row of buttons.
    wButtonrow =  WIDGET_BASE(wBase, /ROW, /ALIGN_LEFT, $
        SPACE=5)

    ; Simple pushbuttons.
    w1 = WIDGET_BASE(wButtonrow, /ROW, SPACE=0, /TOOLBAR)

    wFileOpen = WIDGET_BUTTON(w1, /BITMAP, $
        VALUE=bitmappath + 'open.bmp', $
        TOOLTIP='Open HDF5 file', $
        EVENT_PRO=myname+'_fileopen')

    ; Nonexclusive toggle buttons.
    wNonexc = WIDGET_BASE(wButtonrow, /NONEXCLUSIVE, /ROW, $
        EVENT_PRO=myname+'_toggle', /TOOLBAR)

    wPreview = WIDGET_BUTTON(wNonexc, /BITMAP, $
        VALUE=bitmappath + 'image.bmp', $
        TOOLTIP='Show preview')

    wFitwindow = WIDGET_BUTTON(wNonexc, /BITMAP, $
        VALUE=bitmappath + 'fitwindow.bmp', $
        TOOLTIP='Fit in window')

    wFlipVert = WIDGET_BUTTON(wNonexc, /BITMAP, $
        VALUE=bitmappath + 'flipvert.bmp', $
        TOOLTIP='Flip vertical')

    wFlipHoriz = WIDGET_BUTTON(wNonexc, /BITMAP, $
        VALUE=bitmappath + 'fliphoriz.bmp', $
        TOOLTIP='Flip horizontal')

    WIDGET_CONTROL, wPreview, /SET_BUTTON


    ; Row containing everything except last button row.
    wRow = WIDGET_BASE(wBase, /ROW, $
        SPACE=4, XPAD=0, YPAD=0)

    ; Column containing tree.
    wCol1 = WIDGET_BASE(wRow, /COLUMN, SPACE=0, XPAD=0, YPAD=0)

    ; Second column containing info/options.
    wCol2 = WIDGET_BASE(wRow, /BASE_ALIGN_RIGHT, /COLUMN, $
        SPACE=4, XPAD=0, YPAD=0)

    ; Tree view.
    wTree = CW_TREESTRUCTURE(wCol1, VALUE=sTree, $
        EVENT_PRO=myname+'_tree_event', $
        XSIZE=xsize, $
        YSIZE=ysize)


    ; Info and options views.
    wDraw = WIDGET_DRAW(wCol2, XSIZE=xsize, YSIZE=xsize)


    ; Text information window.
    wText = WIDGET_TEXT(wCol2, /WRAP, $
        SCR_XSIZE=xsize, $
        SCR_YSIZE=ysize-xsize-(dialogread ? 40 : 110), $
        /SCROLL)


    ; All controls for importing data into IDL.
    if (dialogread) then begin

        ; Last button row.
        wLastRow = WIDGET_BASE(wCol2, /ROW, /GRID, XPAD=0, YPAD=0, SPACE=4)

; Motif bug: comment out tooltips on buttons which destroy the widget.
        wCancel = WIDGET_BUTTON(wLastRow, VALUE='    Cancel    ', $
;            TOOLTIP='Cancel the dialog', $
            EVENT_PRO=myname+'_fileexit')

; Motif bug: comment out tooltips on buttons which destroy the widget.
        wImport = WIDGET_BUTTON(wLastRow, VALUE='Open', $
;            TOOLTIP='Open the selected item', $
            EVENT_PRO=myname+'_import')

        ; These widget ID's are undefined for "dialog" mode.
        wName = 0L
        wIncdata = 0L

    endif else begin

        wControl = WIDGET_BASE(wCol2, /COLUMN, /BASE_ALIGN_RIGHT)

        wLabel = WIDGET_LABEL(wControl, /ALIGN_LEFT, VALUE='Variable name for import:')

        ; User-editable name for variable.
        wName = WIDGET_TEXT(wControl, SCR_XSIZE=xsize, /EDITABLE, $
            FRAME=1, SENSITIVE=0, $
            /KBRD_FOCUS_EVENTS, $
            EVENT_PRO=myname+'_checkname')

        wNonexc = WIDGET_BASE(wControl, /NONEXCLUSIVE, XPAD=0, YPAD=0)
        wIncdata = WIDGET_BUTTON(wNonexc, VALUE='Include data', $
            TOOLTIP='Include all data on import')
        WIDGET_CONTROL, wIncdata, /SET_BUTTON

        wLastRow = WIDGET_BASE(wControl, /ROW, /GRID, SPACE=5)
        wImport = WIDGET_BUTTON(wLastRow, VALUE='Import to IDL', $
            SENSITIVE=0, $
            TOOLTIP='Import group or dataset into IDL session', $
            EVENT_PRO=myname+'_import')

; Motif bug: comment out tooltips on buttons which destroy the widget.
        wCancel = WIDGET_BUTTON(wLastRow, VALUE='Done', $
;            TOOLTIP='Close the HDF5 browser', $
            EVENT_PRO=myname+'_fileexit')

    endelse   ; non-blocking dialog

    ; Cache variables for restoring.
    DEVICE, GET_DECOMPOSED=decomposed
    TVLCT, red, green, blue, /GET

    DEVICE, DECOMPOSED=0
    WIDGET_CONTROL, wBase, /REALIZE

    ; Retrieve the draw widget window ID and cache it.
    WIDGET_CONTROL, wDraw, GET_VALUE=iWin

    ; Retrieve base geometry so we can compute size changes.
    geom = WIDGET_INFO(wBase, /GEOMETRY)

    pSelect = dialogread ? PTR_NEW(/ALLOCATE_HEAP) : 0L

    state = { $
        wBase: wBase, $
        wTree: wTree, $
        wText: wText, $
        wDraw: wDraw, $
        wName: wName, $
        wPreview: wPreview, $
        wFitwindow: wFitwindow, $
        wFlipVert: wFlipVert, $
        wFlipHoriz: wFlipHoriz, $
        wIncdata: wIncdata, $
        wImport: wImport, $
        iWin: iWin, $
        dialogread: dialogread, $
        pSelect: pSelect, $
        xsize: geom.xsize, $
        ysize: geom.ysize}


    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, $
        SET_UVALUE=state, /NO_COPY

    ; These are variables we need to restore when browser dies.
    ; Don't make part of the regular state, since they are large.
    savestate = { $
        decomposed: decomposed, $
        red: red, $
        green: green, $
        blue: blue}
    wSubChild = WIDGET_INFO(wChild, /CHILD)
    WIDGET_CONTROL, wSubChild, $
        KILL_NOTIFY='h5_browser_killnotify', $
        SET_UVALUE=savestate, /NO_COPY

    if (N_ELEMENTS(files) gt 0) then begin
        H5_BROWSER_ADDFILE, wTree, files
    endif else begin
        H5_BROWSER_FILEOPEN, $
            {ID: wFileOpen, TOP: wBase, HANDLER: wFileOpen}
    endelse

    XMANAGER, myname, wBase, NO_BLOCK=(1-dialogread)

    if (dialogread) then begin

        ; Destroy group leader if we created it.
        if (not hasleader) then $
            WIDGET_CONTROL, groupleader, /DESTROY

        ; Fill in result, or 0 if user hit Cancel
        result = (N_ELEMENTS(*pSelect) gt 0) ? $
            TEMPORARY(*pSelect) : 0

        PTR_FREE, pSelect
        return, result

    endif else begin

        ; For nonmodal dialogs, return the top-level id.
        return, wBase

    endelse

end

