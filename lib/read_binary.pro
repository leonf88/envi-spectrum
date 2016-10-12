; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_binary.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       READ_BINARY
;
; PURPOSE:
;       Load contents of a binary file into IDL.
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;       result = READ_BINARY([file])
;
; INPUTS:
;       FILE: The filename or logical unit number of a file to be read.
;           If a logical unit number is supplied, it must be open
;           on a file for reading. If no FILE argument is supplied,
;           READ_BINARY will call DIALOG_PICKFILE to prompt the user to
;           select a file for reading.
;
; INPUT KEYWORD PARAMETERS:
;       TEMPLATE: A template structure describing the file to be read.
;           A template can be created using BINARY_TEMPLATE.
;
;           Keyword TEMPLATE cannot be used simultaneously with keywords
;           DATA_START, HEADER, DATA_TYPE, DATA_DIMS or ENDIAN.
;
;       DATA_START: Where to begin reading in a file.  This value is
;           as an offset, in bytes, that will be applied to the
;           initial position in the file.  Default is 0.
;
;       DATA_TYPE: IDL typecode of the data to be read.  See
;           documentation for the IDL SIZE command for a listing
;           of typecodes.  Default is 1 (IDL's BYTE typecode).
;
;       DATA_DIMS: A scalar, or array of up to eight elements specifying
;           the size of the data to be read and returned.  For example,
;           DATA_DIMS=[512,512] specifies that a 2D, 512 by 512 array be
;           read and returned.  DATA_DIMS=0 specifies that a single,
;           scalar value be read and returned.  Default is -1, which,
;           if a TEMPLATE is not supplied that specifies otherwise,
;           indicates that READ_BINARY will read to end-of-file and
;           store the result in a 1D array.
;
;       ENDIAN: 'big', 'little' or 'native'.  Specifies the byte ordering
;           of the file to be read.  If the computer running Read_Binary
;           uses byte ordering that is different than that of the file,
;           Read_Binary will swap the order of bytes in multi-byte
;           data types read from the file.  Default: 'native' == perform
;           no byte swapping.
;
; OUTPUTS:
;       Function Read_Binary returns data read from the specified file.
;       If keyword TEMPLATE is used, Read_Binary returns a structure with
;       fields specified by the template.
;
; SIDE EFFECTS:
;       If a logical unit number is given for the file argument, the
;       current position of a file opened for reading on that logical
;       unit number is advanced.
;
; RESTRICTIONS:
;       Note: variables used in this routine are prefixed with "rb_".
;       This is to avoid conflicts with template-specified expressions
;       or field names.  Templates having field names, offset expressions
;       dimension expressions or verify value expressions containing
;       the character sequence "rb_" or "bt_" are not allowed.
;
;       READ_BINARY does not have functionality to read strings, but
;       strings can be read as an arrays of bytes, and then converted
;       via IDL's STRING command.
;
; EXAMPLES:
;
;       To select a file and read all of it as a simple, "raw" vector
;       of bytes...
;
;           result = READ_BINARY()
;
;       To read 149600 bytes from a file, and display as an image...
;
;           datafile = FILEPATH('hurric.dat', SUBDIR=['examples', 'data'])
;           TVSCL, READ_BINARY(datafile, DATA_DIMS=[440, 340])
;
;       or...
;
;           GET_LUN, lun
;           OPENR, lun, FILEPATH('hurric.dat', SUBDIR=['examples', 'data'])
;           TVSCL, REFORM(READ_BINARY(lun), 440, 340)
;           CLOSE, lun
;           FREE_LUN, lun
;
; MODIFICATION HISTORY
;       PCS, 6/1999 - Written.
;
;-
;
@rb_routines

function read_binary, $
    rb_file, $
    template=rb_template, $
    data_start=rb_data_start, $
;   header=rb_header, $
    data_type=rb_data_type, $
    data_dims=rb_data_dims, $
    endian=rb_endian, $
    debug=rb_debug, $
    cancel=cancel, $
    wbopen=wbopen, $
    _EXTRA=_extra

compile_opt hidden

on_error, 2 ; Return to caller on error.
if keyword_set(rb_debug) then $
    on_error, 0

;*****************************************************************
; Important note:
;    Since this code can create variables with user-defined names,
;    you *must* prefix all local variables below this point
;    with either rb_ or bt_. These prefixes are reserved for
;    use by binary_template and read_binary, and are assumed
;    to be "safe". Other variable names should not be used.
;

catch, rb_error_status
if rb_error_status ne 0 then begin
    catch, /cancel
    if keyword_set(rb_free_lun_on_cleanup) then $
        free_lun, rb_lun
    message, !error_state.msg
endif
if keyword_set(rb_debug) then $
    catch, /cancel

if ((N_ELEMENTS(rb_template) eq 0) && KEYWORD_SET(wbopen)) then begin
  rb_template = BINARY_TEMPLATE(rb_file, CANCEL=cancel, _EXTRA=_extra)
  if ((N_ELEMENTS(cancel) ne 0) && (cancel ne 0)) then begin
    ;; return gracefully
    return, 0
  endif
endif

;
;Validate keywords.
;
if (n_elements(rb_template) gt 0) then begin
    if n_elements(rb_data_start) gt 0 then $
        message, $
            'DATA_START and TEMPLATE keywords cannot be used ' + $
                'simultaneously.', $
            /noname
    if n_elements(rb_data_type) gt 0 then $
        message, $
            'DATA_TYPE and TEMPLATE keywords cannot be used ' + $
                'simultaneously.', $
            /noname
    if n_elements(rb_data_dims) gt 0 then $
        message, $
            'DATA_DIMS and TEMPLATE keywords cannot be used ' + $
                'simultaneously.', $
            /noname
    if n_elements(rb_endian) gt 0 then $
        message, $
            'ENDIAN and TEMPLATE keywords cannot be used ' + $
                'simultaneously.', $
            /noname

    if ~rb_template_is_valid(rb_template, msg=rb_msg) then $
        message, rb_msg[0], /noname

endif

if n_elements(rb_data_start) gt 0 then begin
    if n_elements(rb_data_start) gt 1 then $
        message, 'DATA_START must be a scalar.', /noname
    if ~rb_is_integral(rb_data_start) then $
        message, 'DATA_START is not an integer.', /noname
endif

if n_elements(rb_data_type) gt 0 then begin
    if n_elements(rb_data_type) gt 1 then $
        message, 'DATA_TYPE must be a scalar.', /noname
    if ~rb_is_integral(rb_data_type) then $
        message, 'DATA_TYPE should be an integer value.', /noname

    case rb_data_type of
        0: message, 'DATA_TYPE is undefined type.', /noname
        1: rb_byte_size = 1   ; byte
        2: rb_byte_size = 2   ; int
        3: rb_byte_size = 4   ; long
        4: rb_byte_size = 4   ; float
        5: rb_byte_size = 8   ; double
        6: rb_byte_size = 8   ; complex
        7: message, $
            'Reading strings via READ_BINARY is not supported. ' + $
                '(Specify an array of bytes instead.)', $
            /noname
        8: message, $
            'Reading strucures via READ_BINARY is not supported.', $
            /noname
        9: rb_byte_size = 16  ; dcomplex
        10: message, $
            'Reading pointers via READ_BINARY is not supported.', $
            /noname
        11: message, $
            'Reading object references via READ_BINARY is not ' + $
                'supported.', $
            /noname
        12: rb_byte_size = 2   ; uint
        13: rb_byte_size = 4   ; ulong
        14: rb_byte_size = 8   ; long64
        15: rb_byte_size = 8   ; ulong64
        else: message, 'DATA_TYPE must be less than 16.', /noname
    endcase
endif

if n_elements(rb_data_dims) gt 0 then begin
    if n_elements(rb_data_dims) gt 8 then $
        message, 'DATA_DIMS must have 8 or less values.', /noname
    if ~rb_is_integral(rb_data_dims) then $
        message, 'DATA_DIMS must be integer(s).', /noname
    if rb_data_dims[0] ne -1 then begin ; -1 == use the default
        if min(rb_data_dims) lt 0 then $
            message, 'Invalid DATA_DIMS.', /noname
    endif
endif

if n_elements(rb_endian) gt 0 then begin
    if n_elements(rb_endian) gt 1 then $
        message, 'ENDIAN cannot be an array.', /noname
    if size(rb_endian, /tname) ne 'STRING' then $
        message, 'Endian must be a string.', /noname
    if strupcase(rb_endian) ne 'NATIVE' $
        && strupcase(rb_endian) ne 'LITTLE' $
        && strupcase(rb_endian) ne 'BIG' then $
        message, 'ENDIAN must be "native", "little" or "big."', /noname
endif
;
;Obtain a valid file.
;
rb_tname = size(rb_file, /tname)
if rb_tname eq 'UNDEFINED' then begin
    if arg_present(rb_file) then $
        message, 'Filename argument is undefined.', /noname

    rb_file = dialog_pickfile( $
        /must_exist, $
        /read $
        )
    if rb_file eq '' then $
        message, 'No file was selected for reading.', /noname
    rb_tname = 'STRING'

endif

if rb_tname eq 'POINTER' $
    || rb_tname eq 'STRUCT' $
    || rb_tname eq 'OBJREF' $
    || rb_tname eq 'COMPLEX' $
    || rb_tname eq 'DCOMPLEX' then $
    message, $
        'First argument must be a file name or a logical unit number.', $
        /noname

if rb_tname eq 'STRING' then begin
    if rb_file eq '' then $
        message, 'The given file name is an empty string.'
    rb_void = FILE_SEARCH(rb_file, count=rb_count)
    if rb_count eq 0 then $
        message, 'Could not find file: ' + rb_file, /noname
    get_lun, rb_lun
    rb_free_lun_on_cleanup = 1b
    openr, rb_lun, rb_file, error=rb_error
    if rb_error ne 0 then $
        message, 'Unable to open ' + rb_file + ' for reading.', /noname
    rb_file_status = fstat(rb_lun)
endif else begin
    rb_lun = rb_file
    rb_file_status = fstat(rb_lun)
    case 1 of
        rb_file_status.open eq 0: $
            message, $
                'The supplied Logical Unit has not been Opened.', $
                /noname
        rb_file_status.isatty: $
            message, $
                'The supplied Logical Unit is a terminal ("TTY").', $
                /noname
        rb_file_status.isagui: $
            message, 'The supplied Logical Unit is not a file.', /noname
        rb_file_status.read eq 0: $
            message, $
                'The supplied Logical Unit is not open for read access.', $
                /noname
        else:
    endcase
endelse

if rb_file_status.size le 0 then $
    message, 'The file to be read has zero length.', /noname

;
;Obtain a template.
;
if n_elements(rb_template) gt 0 then begin

    rb_template_use = rb_template
    rb_return_structure = 1b

endif else begin

;
;   Default template: specify one big byte vector into which the file
;   will be read.
;
    rb_fstat = fstat(rb_lun)
    rb_template_use = { $
        version: 1.0, $
        endian: 'native', $
        fieldcount: 1, $
        typecodes: 1, $ ; byte
        names: 'rb_result', $
        offsets: '>0', $
        numdims: 1, $
        dimensions: strcompress( $
            transpose([rb_fstat.size - rb_fstat.cur_ptr, intarr(7)]) $
            ), $
        reverseflags: transpose(intarr(8)), $
        absoluteflags: 0, $
        returnflags: 1, $
        verifyflags: 0 $
        }
;
;   Override defaults with any pertinant specified keywords.
;
    if n_elements(rb_data_start) gt 0 then begin
        if rb_fstat.size - rb_data_start le 0 then $
            message, 'DATA_START is at or beyond the end of file.', /noname
        rb_template_use.Dimensions[0] = $
            strcompress(rb_fstat.size - rb_data_start, /remove_all)
        rb_template_use.Offsets = $
            strcompress(rb_data_start, /remove_all)
        rb_template_use.absoluteflags = 1
    endif

    if n_elements(rb_data_type) gt 0 then begin
        rb_template_use.Typecodes = rb_data_type

        if n_elements(rb_data_start) gt 0 then begin
            rb_template_use.Dimensions[0] = strcompress( $
                ((rb_fstat.size - rb_data_start) / rb_byte_size) > 1, $
                /remove_all $
                )
        endif else begin
            rb_template_use.Dimensions[0] = strcompress( $
                (rb_fstat.size / rb_byte_size) > 1, $
                /remove_all $
                )
        endelse
    endif

    if n_elements(rb_data_dims) gt 0 then begin
        if rb_data_dims[0] ne -1 then begin ; -1 == use default.
            rb_template_use.Dimensions = [strcompress(rb_data_dims)]

            rb_template_use.NumDims = n_elements(rb_data_dims)
            for rb_i=n_elements(rb_data_dims)-1,0,-1 do begin
                if rb_data_dims[rb_i] le 0 then $
                    rb_template_use.NumDims = rb_i
            endfor
        endif
    endif

    if n_elements(rb_endian) gt 0 then $
        rb_template_use.endian = rb_endian

    rb_return_structure = 0b

endelse  ; default template

;
;Template has been obtained and validated. Proceed....
;
rb_varnames = strcompress(rb_template_use.names, /remove_all)

; We cannot use execute in the IDL Virtual Machine.
rb_useExecute = ~LMGR(/VM)

rb_returns_indx = WHERE(rb_template_use.ReturnFlags ne 0, rb_nreturns)
if (rb_nreturns eq 0) then $
    MESSAGE, 'No fields are being returned.'


; If we can't use execute, and we are returning a structure,
; we will need to cache the data for each field within a pointer.
if (~rb_useExecute && rb_return_structure) then $
    rb_pAlldata = PTRARR(rb_template_use.fieldcount)


for rb_i=0,rb_template_use.fieldcount-1 do begin

;
;   Declare temporary variable.
;
    if rb_template_use.numdims[rb_i] eq 0 then begin ; Scalar.

        rb_tempvar = fix(0, TYPE=rb_template_use.typecodes[rb_i])

    endif else begin ; Array

        if (rb_useExecute) then begin
            rb_str = 'rb_dimension = ULONG64(' + $
                rb_dim_str(rb_template_use.dimensions[rb_i, *], $
                rb_template_use.numdims[rb_i]) + ')'
            if ~execute(rb_str, 1) then begin
                message, /info, 'Error executing string: ' + rb_str
                message, !error_state.msg, /noname
            endif
        endif else begin

            rb_nd = rb_template_use.NumDims[rb_i]
            rb_dimension = ULON64ARR(rb_nd)

            ; Loop thru all dimension strings and either do a simple
            ; cast to an unsigned integer, or see if the dimension
            ; string matches a variable that has just been read in.
            for rb_j = 0, rb_nd-1 do begin
                rb_dim_string = rb_template_use.dimensions[rb_i, rb_j]
                ; See if our string matches a var name.
                rb_match = (WHERE(STRCMP(rb_varnames, rb_dim_string, $
                    /FOLD_CASE)))[0]
                if (rb_match ge 0) then begin
                    if (rb_match ge rb_i) then $
                        MESSAGE, 'Variable has not been read: ' + $
                            rb_varnames[rb_match]
                    rb_dimension[rb_j] = ULONG64((*rb_pAlldata[rb_match])[0])
                endif else begin
                    ; Just try to cast the string to an integer.
                    rb_dimension[rb_j] = ULONG64(rb_dim_string)
                endelse
            endfor

            rb_dimension >= 1   ; 0 --> 1

        endelse

        rb_tempvar = MAKE_ARRAY(DIMENSION=rb_dimension, /NOZERO, $
            TYPE=rb_template_use.typecodes[rb_i])

    endelse

;
;   Move to the appropriate file position.
;
    rb_offset = rb_template_use.offsets[rb_i]
    rb_firstChar = STRMID(rb_offset, 0, 1)
    if ((rb_firstChar eq '>') || (rb_firstChar eq '<')) then $
        rb_offset = STRMID(rb_offset, 1)

    if (rb_useExecute) then begin
        ; Must be a signed int in case offset is negative.
        rb_str = 'rb_offset = LONG64(' + rb_offset + ')'
        if ~execute(rb_str, 1) then begin
            message, /info, 'Error executing string: ' + rb_str
            message, !error_state.msg, /noname
        endif
    endif else begin
        ; See if our string matches a var name.
        rb_match = (WHERE(STRCMP(rb_varnames, rb_offset, /FOLD_CASE)))[0]
        if (rb_match ge 0) then begin
            if (rb_match ge rb_i) then $
                MESSAGE, 'Variable has not been read: ' + $
                    rb_varnames[rb_match]
            rb_offset = LONG64((*rb_pAlldata[rb_match])[0])
        endif else begin
            ; Just try to cast the string to an integer.
            rb_offset = LONG64(rb_offset)
        endelse
    endelse

    ; Adjust for relative offsets.
    if (~rb_template_use.absoluteflags[rb_i]) then begin
        point_lun, -rb_lun, rb_pos ; Get the current position.

        ; If first char is > then offset forward.
        ; Else if < then offset backward.
        rb_offset = (rb_firstChar ne '<') ? $
            rb_pos + rb_offset : ((rb_pos - rb_offset) > 0)
    endif

    ; Change file position.
    point_lun, rb_lun, rb_offset

;
;   Read the temporary variable.
;
    readu, rb_lun, rb_tempvar

;
;   Swap endian-ness.
;
    case strupcase(rb_template_use.endian) of
        'LITTLE': SWAP_ENDIAN_INPLACE, rb_tempvar, /SWAP_IF_BIG_ENDIAN
        'BIG':    SWAP_ENDIAN_INPLACE, rb_tempvar, /SWAP_IF_LITTLE_ENDIAN
        else:
    endcase

;
;   Verify the value we read.
;
    if rb_template_use.VerifyFlags[rb_i] then begin

        if (rb_useExecute) then begin

            rb_str = 'rb_verify = ' + rb_template_use.verifyvals[rb_i]
            if ~execute(rb_str, 1) then begin
                message, $
                    'Could not determine the verification value for field ' $
                    + strupcase(rb_varnames[rb_i]) $
                    + '. ' + !error_state.msg $ ; e.g. syntax error
                    + ' '  + !error_state.sys_msg, $ ; e.g. ran out of memory
                    /noname
            endif

        endif else begin

            ; See if our string matches a var name.
            rb_match = (WHERE(STRCMP(rb_varnames, $
                rb_template_use.verifyvals[rb_i], /FOLD_CASE)))[0]

            if (rb_match ge 0) then begin
                if (rb_match ge rb_i) then $
                    MESSAGE, 'Variable has not been read: ' + $
                        rb_varnames[rb_match]
                rb_verify = (*rb_pAlldata[rb_match])[0]
            endif else begin
                ; Convert from string to same type as data value.
                rb_verify = FIX(rb_template_use.verifyvals[rb_i], $
                    TYPE=SIZE(rb_tempvar, /TYPE))
            endelse

        endelse

        if (rb_tempvar ne rb_verify) then begin
            message, $
                'Value read from file did not pass verification: ' $
                    + strupcase(rb_varnames[rb_i]) $
                    + ' does not equal ' $
                    + strtrim(rb_template_use.verifyvals[rb_i], 2) $
                    + '.', $
                /noname
        endif
    endif

;
;   Reverse in the first three dimensions of the variable, if desired.
;   (The IDL REVERSE command can only operate on the first
;   three dimensions of an array.)
;
    for rb_j=0,(rb_template_use.NumDims[rb_i]-1)<2 do begin
        if rb_template_use.reverseflags[rb_i, rb_j] then $
            rb_tempvar = REVERSE(rb_tempvar, rb_j + 1, /OVERWRITE)
    endfor

    if (rb_useExecute) then begin
        ; Change variable name from rb_tempvar to our current varname.
        (SCOPE_VARFETCH(rb_varnames[rb_i], /ENTER)) = TEMPORARY(rb_tempvar)
    endif else begin
        if rb_return_structure then begin
            rb_pAlldata[rb_i] = PTR_NEW(rb_tempvar, /NO_COPY)
        endif else begin
            rb_result = TEMPORARY(rb_tempvar)
        endelse
    endelse

endfor  ; rb_i


if keyword_set(rb_free_lun_on_cleanup) then $
    free_lun, rb_lun

if rb_return_structure then begin
;
;   Put the fields into a structure.
;
    if (rb_useExecute) then begin
        rb_str = 'rb_result = create_struct(' $
            + 'rb_varnames[rb_returns_indx[0]], ' $
            + 'temporary(' + rb_varnames[rb_returns_indx[0]] + ')' $
            + ')'
        if ~execute(rb_str, 1) then begin
            message, /info, 'Error executing string: ' + rb_str
            message, !error_state.msg, /noname
        endif
        for rb_i=1,rb_nreturns-1 do begin
            rb_str = 'rb_result = create_struct(' $
                + 'temporary(rb_result), ' $
                + 'rb_varnames[rb_returns_indx[rb_i]], temporary(' $
                + rb_varnames[rb_returns_indx[rb_i]] $
                + '))'
            if ~execute(rb_str, 1) then begin
                message, /info, 'Error executing string: ' + rb_str
                message, !error_state.msg, /noname
            endif
         endfor
     endif else begin
        ; Create a structure on the fly, copying from our cached
        ; pointer data into the structure.
        rb_result = CREATE_STRUCT(rb_varnames[rb_returns_indx[0]], $
            TEMPORARY(*rb_pAlldata[rb_returns_indx[0]]))
        for rb_i=1,rb_nreturns-1 do begin
            rb_result = CREATE_STRUCT(rb_result, $
                rb_varnames[rb_returns_indx[rb_i]], $
                TEMPORARY(*rb_pAlldata[rb_returns_indx[rb_i]]))
        endfor
        PTR_FREE, rb_pAlldata
     endelse
endif

return, rb_result

end

