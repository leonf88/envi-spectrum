; $Id: //depot/idl/releases/IDL_80/idldir/lib/binary_template.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       BINARY_TEMPLATE
;
; PURPOSE:
;       Generate a "template" structure that describes a binary file.
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;       template = BINARY_TEMPLATE( [file] )
;
; INPUTS:
;       FILE:  A string indicating a sample data file that will be used
;              to test the validity of user input "on the fly" as the
;              user interacts with Binary_Template's GUI.  The file
;              should contain the kind of data for which a template
;              is being defined.  As the user specifies fields via
;              Binary_Template's GUI, Binary_Template attempts to
;              read this file "behind the scenes" using the user's
;              specifications.  If errors occur during such a test
;              read, Binary_Template displays a Dialog_Message
;              indicating where in the user's specifications
;              a correction may be required.
;
;              Default: if FILE is not supplied, binary_template will
;              prompt the user for a file via DIALOG_PICKFILE.
;
; INPUT KEYWORD PARAMETERS:
;       TEMPLATE: An initial template structure.
;
;       GROUP_LEADER: The widget ID of a widget that calls Binary_Template.
;              When this ID is specified, a death of the caller results in a
;              death of Binary_Template.
;
;       N_ROWS: Specifies the YSIZE of Binary_Template's WIDGET_TABLE.
;
; OUTPUT KEYWORD PARAMETERS:
;       CANCEL: Set to 1 if the user clicked cancel, else set to 0.
;
; OUTPUTS:
;       Function Binary_Template normally returns an anonymous structure.
;       If the user cancels Binary_Template and no initial template was
;       supplied the function returns zero.  If the user cancels
;       Binary_Template and an initial template was supplied (via
;       the TEMPLATE keyword), the initial template is returned.
;
; EXAMPLE:
;       datafile = filepath('hurric.dat', subdir=['examples', 'data'])
;       ;
;       ;Use Binary_Template to interactively define a 440x340 field
;       ;of type BYTE, named "img".
;       ;
;       template = binary_template(datafile)
;       ;
;       ;Use the resulting template to read a file.
;       ;
;       data = read_binary(datafile, template=template)
;       ;
;       ;Display results.
;       ;
;       tvscl, data.img
;
; MODIFICATION HISTORY
;       PCS, 6/1999 - Written.
;
;-
;
@rb_routines

function bt_typecode, wDroplist
compile_opt hidden

widget_control, wDroplist, get_uvalue=typecodes
return, typecodes[ $
    widget_info(wDroplist, /droplist_select) $
    ]
end
;--------------------------------------------------------------------
pro bt_purge_non_digits, event
    compile_opt hidden
    ;
    ;Purge charaters from EVENT.ID text widget that are not one
    ;of the ten digits 0-9.
    ;
    widget_control, event.id, get_value=current_str
    current_str = current_str[0]

    if current_str eq '' then $
        return

    on_ioerror, set_str_to_null
    if 1 then begin
        str = strcompress( $
            abs(long64(current_str)), $
            /remove_all $
            )
    endif else begin
        set_str_to_null:
        str = ''
        message, /reset
    endelse
    on_ioerror, NULL

    if tag_names(event, /structure_name) ne '' then begin
        if str ne current_str then begin
            widget_control, event.id, get_uvalue=previous_str
            if n_elements(previous_str) gt 0 then $
                widget_control, event.id, set_value=previous_str $
            else $
                widget_control, event.id, set_value=''
            case event.type of
                0: offset = event.offset - 1
                1: offset = event.offset $
                          - strlen(event.str) $
                          - 1 ; correct?
                2: offset = 1
            endcase
            widget_control, event.id, set_text_select=offset
        endif
    endif else begin
        widget_control, event.id, set_value=str
    endelse

    widget_control, event.id, get_value=current_str
    widget_control, event.id, set_uvalue=current_str

end


;--------------------------------------------------------------------
function bt_entry_is_valid, $
    bt_state, $            ; IN: program information structure.
    msg=bt_msg             ; OUT: error message string or 'Entry is valid.'

compile_opt hidden
;
;Purpose: Return 1 if the field currently being edited has satisfactory
;values.
;
;Note: variable names in this routine start with "bt_".  This is a
;naming convention to help avoid clashing with user specified
;field names.  The letters "bt_" stand for "Binary_Template",
;
if keyword_set(bt_state.debug) then begin
    on_error, 0
endif else begin
    catch, bt_error_status
    if bt_error_status ne 0 then begin
        catch, /cancel
        if n_elements(bt_lun) gt 0 then $
            free_lun, bt_lun
        bt_msg = [ $
            'Could not validate entry.', $
            'Internal error message was:', $
            '   ' + !error_state.msg_prefix + !error_state.msg $
            ]
        MESSAGE, /RESET
        return, 0
    endif
endelse

; This will supersede the CATCH above.
ON_IOERROR, ioErr

; Assume failure.
bt_msg = 'Entry is invalid.'


bt_num_dims = widget_info(bt_state.wNumDims, /droplist_select)

for bt_i=0,bt_state.max_idl_dims-1 do begin
    widget_control, bt_state.wDimText[bt_i], get_value=bt_single_str

    if bt_single_str[0] eq '' and bt_i lt bt_num_dims then begin
        bt_msg = 'Size of ' + ([ $
            '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th' $
            ])[bt_i] + ' dimension is unspecified.'
        return, 0
        end

    if bt_i eq 0 then $
        bt_arr_str = bt_single_str $
    else $
        bt_arr_str = [bt_arr_str, bt_single_str]
endfor

widget_control, bt_state.wOffset, get_value=bt_offset_str
widget_control, bt_state.wFieldName, get_value=bt_field_name_str
; Replace fieldName with a valid version (spaces->underscores, etc.)
bt_field_name_str = IDL_VALIDNAME(bt_field_name_str[0], /CONVERT_ALL)
widget_control, bt_state.wFieldName, set_value=bt_field_name_str
widget_control, bt_state.wVerifyText, get_value=bt_verify_str

bt_offset_str = bt_offset_str[0]
bt_field_name_str = bt_field_name_str[0]
bt_verify_str = bt_verify_str[0]

if bt_field_name_str eq ''then begin
    bt_msg = 'Field name is empty.'
    return, 0
endif

if strpos(strupcase(bt_field_name_str), 'RB_') ne -1 $
    || strpos(strupcase(bt_field_name_str), 'BT_') ne -1 then begin
    bt_msg = [ $
        'Names that contain "bt_" or "rb_" are reserved for', $
        'internal use by BINARY_TEMPLATE and READ_BINARY.  Please', $
        'specify a different field name.' $
         ]
    return, 0
endif
;
;See if there is already a field with this name specified.
;
if bt_state.fieldcount gt 0 then begin
    bt_indx = where( $
        strupcase(bt_field_name_str) eq strupcase(*bt_state.pNames), $
        bt_count $
        )
    if bt_count gt 0 then begin
        if bt_state.we_are_inserting then begin
            bt_msg = 'Another field has the same name.'
            return, 0
        endif else begin
            if bt_indx[0] ne bt_state.current_field_indx then begin
                bt_msg = 'Another field has the same name.'
                return, 0
            endif
        endelse
    endif
endif

bt_dims_str = rb_dim_str(bt_arr_str, bt_num_dims)

widget_control, bt_state.wAbsoluteRadio, get_value=bt_offset_is_relative
widget_control, bt_state.wVerifyCheckbox, get_value=bt_do_verify



;*****************************************************************
; Important note:
;    Since this code can create variables with user-defined names,
;    you *must* prefix all local variables below this point
;    with either rb_ or bt_. These prefixes are reserved for
;    use by binary_template and read_binary, and are assumed
;    to be "safe". Other variable names should not be used.
;
if bt_state.filename eq '' then begin

;
;       Check user's offset syntax.
;
    ; Strip off leading > or < if necessary.
    rb_offset = bt_offset_str
    rb_firstChar = STRMID(rb_offset, 0, 1)
    if (rb_firstChar eq '>' || rb_firstChar eq '<') then $
        rb_offset = STRMID(rb_offset, 1)
    MESSAGE, /RESET ; clear !error_state
    if (bt_state.useExecute) then $
        rb_void = EXECUTE('rb_void = ' + rb_offset, 1)
    if ~RB_EXPRESSION_IS_VALID('OFFSET', rb_offset, $
        bt_field_name_str, RB_MSG=bt_msg) then return, 0

;
;       Check user's dimensions syntax.
;
    MESSAGE, /RESET ; clear !error_state
    if (bt_state.useExecute) then $
        rb_void = EXECUTE('rb_void = ' + bt_dims_str, 1)
    if ~RB_EXPRESSION_IS_VALID('DIMENSION', bt_dims_str, $
        bt_field_name_str, RB_MSG=bt_msg) then $
        return, 0

;
;       Check user's verify value syntax.
;
    if keyword_set(bt_do_verify) then begin
        MESSAGE, /RESET ; clear !error_state
        if (bt_state.useExecute) then $
            rb_void = EXECUTE('rb_void = ' + bt_verify_str, 1)
        if ~RB_EXPRESSION_IS_VALID('VERIFY', bt_verify_str, $
            bt_field_name_str, RB_MSG=bt_msg) then $
            return, 0
    endif

    bt_msg = 'Entry is valid.'

    return, 1 ; We made it.

endif

; have a filename

    get_lun, bt_lun
    openr, bt_lun, bt_state.filename


    bt_nfield = bt_state.current_field_indx + 1 - $
        (bt_state.we_are_inserting eq 0) - (bt_state.fieldcount eq 0)

    bt_varnames = (bt_nfield gt 0) ? $
        STRCOMPRESS(*bt_state.pNames, /remove_all) : ''

    ; If we can't use execute, we need to cache the data
    ; for each field within a pointer.
    if (bt_nfield gt 0 && ~bt_state.useExecute) then $
        bt_pAlldata = PTRARR(bt_nfield)

    ; We actually go 1 past the last field so we can read the new field.
    for bt_i=0, bt_nfield do begin


        if (bt_i lt bt_nfield) then begin
            bt_offset = (*bt_state.pOffsets)[bt_i]
            bt_ndims = (*bt_state.pNumDims)[bt_i]
            bt_type = (*bt_state.pTypecodes)[bt_i]
            bt_all_dims_str = (*bt_state.pDimensions)[bt_i, *]
            bt_dims_string = rb_dim_str(bt_all_dims_str, bt_ndims)
            bt_offset_relative = (*bt_state.pAbsoluteflags)[bt_i]
        endif else begin
            ; We've now read in all previous fields, so go ahead and try
            ; to read our current field.
            bt_offset = bt_offset_str
            bt_ndims = bt_num_dims
            bt_type = bt_typecode(bt_state.wType)
            bt_dims_string = bt_dims_str
            bt_all_dims_str = bt_arr_str
            bt_offset_relative = bt_offset_is_relative
        endelse

        ; Construct result array.

        if bt_ndims eq 0 then begin ; Scalar.

            bt_tempvar = FIX(0, TYPE=bt_type)

        endif else begin ; Array

            if (bt_state.useExecute) then begin
                bt_str = 'bt_dimension=ULONG64(' + bt_dims_string + ')'
                if ~execute(bt_str, 1) then begin
                    message, /info, 'Error executing string: ' + bt_str
                    message, !error_state.msg
                endif
            endif else begin

                bt_nd = N_ELEMENTS(bt_all_dims_str)
                bt_dimension = ULON64ARR(bt_nd)

                ; Loop thru all dimension strings and either do a simple
                ; cast to an unsigned integer, or see if the dimension
                ; string matches a variable that has just been read in.
                for bt_j = 0, bt_nd-1 do begin
                    bt_dim_string = bt_all_dims_str[bt_j]
                    ; See if our string matches a var name.
                    bt_match = (WHERE(STRCMP(bt_varnames, bt_dim_string, $
                        /FOLD_CASE)))[0]
                    if (bt_match ge 0) then begin
                        if (bt_match ge bt_i) then $
                            MESSAGE, 'Variable has not been read: ' + $
                                bt_varnames[bt_match]
                        bt_dimension[bt_j] = ULONG64((*bt_pAlldata[bt_match])[0])
                    endif else begin
                        ; Just try to cast the string to an integer.
                        bt_dimension[bt_j] = ULONG64(bt_dim_string)
                    endelse
                endfor

                bt_dimension >= 1   ; 0 --> 1
            endelse

            bt_tempvar = MAKE_ARRAY(DIMENSION=bt_dimension, $
                TYPE=bt_type, /NOZERO)
        endelse


        ; Construct offset.

        bt_firstChar = STRMID(bt_offset, 0, 1)
        if ((bt_firstChar eq '>') || (bt_firstChar eq '<')) then $
            bt_offset = STRMID(bt_offset, 1)

        if (bt_state.useExecute) then begin
            ; Must be a signed int in case offset is negative.
            bt_str = 'bt_offset = LONG64(' + bt_offset + ')'
            if ~execute(bt_str, 1) then begin
                message, /info, 'Error executing string: ' + bt_str
                message, !error_state.msg
            endif
        endif else begin
            ; See if our string matches a var name.
            bt_match = (WHERE(STRCMP(bt_varnames, bt_offset, /FOLD_CASE)))[0]
            if (bt_match ge 0) then begin
                if (bt_match ge bt_i) then $
                    MESSAGE, 'Variable has not been read: ' + $
                        bt_varnames[bt_match]
                bt_offset = LONG64((*bt_pAlldata[bt_match])[0])
            endif else begin
                ; Just try to cast the string to an integer.
                bt_offset = LONG64(bt_offset)
            endelse
        endelse

        ; See if relative offset.
        if (~bt_offset_relative) then begin
            point_lun, -bt_lun, bt_pos ; Get the current position.
            bt_offset = (bt_firstChar ne '<') ? $
                bt_pos + bt_offset : ((bt_pos - bt_offset) > 0)
        endif

        if (size(bt_tempvar, /n_dimensions) ne bt_ndims $
            && bt_ndims gt 0) then begin
            bt_msg = [ $
                'Field size yields a number of dimensions that', $
                'does not equal your specified number of dimensions.' $
                ]
            goto, ioErr
        endif


        bt_msg = 'Invalid offset.'
        point_lun, bt_lun, bt_offset

        bt_msg = 'Specified field cannot be read.'
        readu, bt_lun, bt_tempvar

        case strupcase(bt_state.endian) of
        'LITTLE': SWAP_ENDIAN_INPLACE, bt_tempvar, /SWAP_IF_BIG_ENDIAN
        'BIG':    SWAP_ENDIAN_INPLACE, bt_tempvar, /SWAP_IF_LITTLE_ENDIAN
        else:
        endcase

        if (bt_i lt bt_nfield) then begin
            ; Change variable name from bt_tempvar to our current varname.
            if (bt_state.useExecute) then begin
                (SCOPE_VARFETCH(bt_varnames[bt_i], /ENTER)) = $
                    TEMPORARY(bt_tempvar)
            endif else begin
                bt_pAlldata[bt_i] = PTR_NEW(bt_tempvar, /NO_COPY)
            endelse
        endif

    endfor  ; bt_i


;
;   Verify the value we read.
;
    if bt_do_verify then begin

        if (bt_state.useExecute) then begin
            if ~execute('bt_verify = ' + bt_verify_str, 1) then begin
                bt_msg = ['Invalid verify value.', '(' + !error_state.msg + ')']
                goto, ioErr
            endif
        endif else begin

            ; See if our string matches a var name.
            bt_match = (WHERE(STRCMP(bt_varnames, $
                bt_verify_str, /FOLD_CASE)))[0]

            if (bt_match ge 0) then begin
                if (bt_match ge bt_nfield) then $
                    MESSAGE, 'Variable has not been read: ' + $
                        bt_varnames[bt_match]
                bt_verify = (*bt_pAlldata[bt_match])[0]
            endif else begin
                ; Convert from string to same type as data value.
                bt_verify = FIX(bt_verify_str, $
                    TYPE=SIZE(bt_tempvar, /TYPE))
            endelse

        endelse
        if size(bt_verify, /n_dimensions) ne 0 then begin
            bt_msg = 'Verify value must be a scalar.'
            goto, ioErr
        endif
        bt_tname = size(bt_verify, /tname)
        if bt_tname eq 'STRING' $
            || bt_tname eq 'POINTER' $
            || bt_tname eq 'OBJREF' then begin
            bt_msg = 'Verify value cannot be a ' + bt_tname + '.'
            goto, ioErr
        endif
        if (bt_tempvar ne bt_verify) then begin
            bt_msg =[ $
                'Field does not equal verify value.', $
                'Field = ' + strcompress(string(bt_tempvar, /print)) $
                ]
            goto, ioErr
        endif
    endif  ; bt_do_verify

    if (N_ELEMENTS(bt_pAlldata) gt 0) then $
        PTR_FREE, bt_pAlldata

    bt_msg = 'Entry is valid.'


    return, 1 ; We made it.


ioErr:
        if (N_ELEMENTS(bt_pAlldata) gt 0) then $
            PTR_FREE, bt_pAlldata
        bt_msg = [bt_msg, !error_state.msg]
        free_lun, bt_lun
        return, 0

end


;--------------------------------------------------------------------
function bt_typestring, typecode
    compile_opt hidden

    case typecode of
         1: return, 'Byte'
         2: return, 'Int (16-bit)'
         3: return, 'Long (32-bit)'
        14: return, 'Long64 (64-bit)'

         4: return, 'Float (32-bit)'
         5: return, 'Double (64-bit)'

        12: return, 'UInt (16-bit)'
        13: return, 'ULong (32-bit)'
        15: return, 'ULong64 (64-bit)'

         6: return, 'Complex'
         9: return, 'DComplex'
    endcase
end


;--------------------------------------------------------------------
pro bt_rake, struc
    compile_opt hidden
    ;
    ;"Rake" heap from a structure as one would rake leaves from
    ;a lawn.
    ;
    on_error, 2
    if n_elements(struc) le 0 then $
        message, 'Argument is missing.'
    if size(struc, /TNAME) ne 'STRUCT' then $
        message, 'Argument must be a struc.'

    for i=0,n_tags(struc)-1 do begin
        case size((struc).(i), /TNAME) of
            'POINTER': $
                ptr_free, (struc).(i)
            'OBJREF': $
                obj_destroy, (struc).(i)
            else:
        endcase
    endfor
end


;--------------------------------------------------------------------
pro bt_put_val_into_array, array, val, indx, insert=insert, debug=debug

    compile_opt hidden

    on_error, keyword_set(debug) ? 0 : 2

    if n_elements(array) eq 0 then begin
        array = val
        return
    endif

    if indx lt 0 then $
        message, 'Negative array index.'

    siz = size(array)
    if siz[0] eq 0 then begin
        array = [array]
        siz = size(array)
    endif

    if indx gt siz[1]-1 then $
        message, 'Index exceeds array bounds.'

    if keyword_set(insert) then begin
    ;
    ;   Insert value after index.
    ;
        case indx of
            siz[1]-1: array = [array, val]
            else: array = [array[0:indx,*], val, array[indx+1:*, *]]
        endcase
    endif else begin
        array[indx, 0] = val
    endelse

end


;--------------------------------------------------------------------
pro bt_delete_item_from_array, array, indx, debug=debug

    compile_opt hidden

    on_error, keyword_set(debug) ? 0 : 2

    if n_elements(array) eq 1 then begin
        ptr_free, ptr_new(array, /no_copy) ; Undefine array.
        return
    endif

    if indx lt 0 then $
        message, 'Negative array index.'

    siz = size(array)
    if siz[0] eq 0 then $
        message, 'Array is undefined.'

    if indx gt siz[1]-1 then $
        message, 'Index exceeds array bounds.'

    if siz[1] eq 1 then begin
        ptr_free, ptr_new(array, /no_copy) ; Undefined array.
        return
    endif

    ;
    ;Remove value at index.
    ;
    case indx of
        siz[1]-1: array = array[0:indx-1, *]
        0: array = array[1:*, *]
        else: begin
            index = l64indgen(siz[1]-1)
            index[indx:*] = index[indx:*] + 1LL
            array = array[index, *]
            end
    endcase
end


;--------------------------------------------------------------------
pro bt_update_field_display, $
    state, $
    highlight_current_row=highlight_current_row
compile_opt hidden

if state.fieldcount eq 0 then begin
    widget_control, state.wTable, set_value=strarr(7)
    return
endif

if state.fieldcount gt state.n_rows then begin
    widget_control, state.wTable, insert_rows=state.fieldcount-state.n_rows
    state.n_rows = state.fieldcount
endif

value = strarr(7, state.fieldcount)
value[0, *] = *state.pNames
value[1, *] = *state.pOffsets

for i=0,state.fieldcount-1 do begin
    value[2, i] = rb_dim_str( $
        (*state.pDimensions)[i, *], $
        (*state.pNumDims)[i] $
        )
endfor

nBytes = LON64ARR(state.fieldcount)
; Size of each type in bytes.
;            0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
typeSizes = [0, 1, 2, 4, 4, 8, 8, 0, 0,16, 0, 0, 2, 4, 8, 8]
for i=0,state.fieldcount-1 do begin
    nDim = (*state.pNumDims)[i]
    nElements = (nDim gt 0) ? $
        PRODUCT(ULONG64((*state.pDimensions)[i, 0:nDim-1]), /INTEGER) : 1
    nBytes[i] = nElements*typeSizes[(*state.pTypeCodes)[i]]
endfor
value[3, *] = STRTRIM(nBytes, 2)

for i=0,state.fieldcount-1 do $
    value[4, i] = bt_typestring((*state.pTypeCodes)[i])

value[5, *] = 'No'
indx = where(*state.pReturnFlags)
if indx[0] ne -1 then $
    value[5, indx] = 'Yes'

value[6, *] = 'No'
indx = where(*state.pVerifyFlags)
if indx[0] ne -1 then $
    value[6, indx] = 'Yes'

widget_control, $
    state.wTable, $
    set_value=value, $
    ysize=state.fieldcount, $
    column_labels=state.column_labels

if keyword_set(highlight_current_row) then begin
;
;   Highlight the entire current row.
;
    widget_control, state.wTable, $
        set_table_select=[ $
            0, $
            state.current_field_indx, $
            n_elements(state.column_labels) - 1, $
            state.current_field_indx $
            ]
;
;   Center the row that is currently selected.
;
    widget_control, state.wTable, $
        set_table_view=[ $
            0, $
            0 > (state.current_field_indx - (state.n_scroll_rows / 2)) $
                < (state.n_rows - state.n_scroll_rows) $
            ]
endif

end


;--------------------------------------------------------------------
pro bt_modify_field_event, event

    compile_opt hidden

    if (TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST') then begin
        WIDGET_CONTROL, event.top, /DESTROY
        return
    endif


widget_control, event.top, get_uvalue=pState
case event.id of
    (*pState).wOffset: begin
        if event.type lt 3 then begin
            widget_control, event.id, get_value=value
            value = value[0]

            case 1 of
                strpos(value, '>') eq 0: begin
                    widget_control, (*pState).wAbsoluteRadio, set_value=1
                    (*pState).offset_sign = '>'
                    end
                strpos(value, '<') eq 0: begin
                    widget_control, (*pState).wAbsoluteRadio, set_value=1
                    (*pState).offset_sign = '<'
                    end
                else: widget_control, (*pState).wAbsoluteRadio, set_value=0

            endcase

            (*pState).offset_str = value
        endif  ; event.type lt 3
        end  ; (*pState).wOffset

    (*pState).wAbsoluteRadio: begin
        if event.value eq 0 then begin
            (*pState).offset_str = strmid( $
                (*pState).offset_str, $
                stregex((*pState).offset_str, '^[<>]') + 1 $
                )
        endif else begin
            if stregex((*pState).offset_str, '^[<>]') eq -1 then $
                (*pState).offset_str = $
                    (*pState).offset_sign + (*pState).offset_str
        endelse
        widget_control, (*pState).wOffset, set_value=(*pState).offset_str
        end

    (*pState).wNumDims: begin
        for i=0,(*pState).max_idl_dims-1 do begin
            widget_control, $
                (*pState).wIndividualDimBase[i], $
                sensitive=i lt event.index
            if i ge event.index then begin
                widget_control, $
                    (*pState).wDimText[i], $
                    set_value=''
                if i le 2 then $
                    widget_control, $
                        (*pState).wReverseCheckbox[i], $
                        set_value=0
            endif
        endfor

        widget_control, (*pState).wVerifyCheckbox, set_value=0
        bt_modify_field_event, { $
            id: (*pState).wVerifyCheckbox, $
            top: event.top, $
            handler: 0L, $
            select: 0 $
            }
        widget_control, $
            (*pState).wVerifyBase, $
            sensitive=event.index eq 0
        end  ; (*pState).wNumDims

    (*pState).wType: ; do nothing
    
    (*pState).wModifyOK: begin
        widget_control, /hourglass
        if ~bt_entry_is_valid(*pState, msg=msg) then begin
            void = dialog_message(msg, /error)
            return
        endif

        widget_control, (*pState).wDimText[0], get_value=bt_arr_str
        for i=1,(*pState).max_idl_dims-1 do begin
            widget_control, (*pState).wDimText[i], get_value=bt_single_str
            bt_arr_str = [bt_arr_str, bt_single_str]
        endfor

        num_dims = widget_info((*pState).wNumDims, /droplist_select)

        widget_control, (*pState).wOffset, get_value=field_loc_str
        field_loc_str = field_loc_str[0]

        widget_control, (*pState).wFieldName, get_value=field_name_str
        ; Replace fieldName with a valid version (spaces->underscores, etc.)
        field_name_str = IDL_VALIDNAME(field_name_str[0], /CONVERT_ALL)
        widget_control, (*pState).wFieldName, set_value=field_name_str
        field_name_str = field_name_str[0]

        widget_control, (*pState).wVerifyText, get_value=verify_text
        verify_text = verify_text[0]

        bt_put_val_into_array, $
            *(*pState).pNames, $ ; The array.
            field_name_str, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pTypecodes, $ ; The array.
            bt_typecode((*pState).wType), $
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pOffsets, $ ; The array.
            field_loc_str, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pAllowFormulas, $ ; The array.
            1, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pDimAllowFormulas, $ ; The array.
            1, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        widget_control, $
            (*pState).wAbsoluteRadio, $
            get_value=absolute_radio_sel
        bt_put_val_into_array, $
            *(*pState).pAbsoluteFlags, $ ; The array.
            absolute_radio_sel eq 0, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pNumDims, $ ; The array.
            num_dims, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pDimensions, $
            transpose(bt_arr_str), $
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        reverseflags = bytarr((*pState).max_idl_dims)
        for i=0,2 do begin
            widget_control, (*pState).wReverseCheckbox[i], get_value=checked
            reverseflags[i] = checked
            end
        bt_put_val_into_array, $
            *(*pState).pReverseFlags, $
            transpose(reverseflags), $
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        widget_control, (*pState).wReturn, get_value=val
        bt_put_val_into_array, $
            *(*pState).pReturnFlags, $
            val, $
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        widget_control, (*pState).wVerifyCheckbox, get_value=val
        bt_put_val_into_array, $
            *(*pState).pVerifyFlags, $
            val, $
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        bt_put_val_into_array, $
            *(*pState).pVerifyVals, $ ; The array.
            verify_text, $ ; The value.
            (*pState).current_field_indx, $
            insert=(*pState).we_are_inserting, $
            debug=(*pState).debug

        if (*pState).we_are_inserting then begin
            (*pState).fieldcount = (*pState).fieldcount + 1
            (*pState).current_field_indx = $
                ((*pState).current_field_indx + 1) $
                < ((*pState).fieldcount - 1)
        endif

        bt_update_field_display, *pState, /highlight_current_row
        widget_control, event.top, /destroy

        end  ; (*pState).wModifyOK

    (*pState).wModifyCancel: widget_control, event.top, /destroy
    
    (*pState).wModifyHelp: ONLINE_HELP, 'BINARY_TEMPLATE'
    

    (*pState).wVerifyCheckbox: begin
        if event.select eq 0 then $
            widget_control, (*pState).wVerifyText, set_value=''
        widget_control, (*pState).wVerifyText, sensitive=event.select
        end

    (*pState).wFieldName: begin
        widget_control, (*pState).wFieldName, get_value=bt_field_name_str
        ; Replace fieldName with a valid version (spaces->underscores, etc.)
        bt_field_name_str = IDL_VALIDNAME(bt_field_name_str[0], /CONVERT_ALL)
        widget_control, (*pState).wFieldName, set_value=bt_field_name_str
        end

    else:

endcase


return

cast_failed: ; Leading character is illegal.
    widget_control, event.id, set_value=(*pState).offset_str
    widget_control, event.id, set_text_select=radio
    message, /reset

end
;--------------------------------------------------------------------
pro bt_modify_field, pState
compile_opt hidden

tlb = widget_base( $
    /modal, $
    group_leader=(*pState).tlb, $
    /column, $
    space=10, $
    /TLB_KILL_REQUEST_EVENTS, $
    title=((*pState).we_are_inserting ? 'New' : 'Modify') + ' Field', $
    /TAB_MODE)
(*pState).wFieldName = cw_field(tlb, Title='Field name: ', xsize=45, $
    /RETURN_EVENTS)

wRowBase = widget_base(tlb, /row, xpad=0, ypad=0, space=10)

wLeftBase = widget_base(wRowBase, /col, xpad=2, ypad=5)


(*pState).wType = widget_droplist( $
    wLeftBase, $
    title='Type:', $
    value=[ $
        'Byte (unsigned 8-bits)', $
        'Integer (16 bits)', $
        'Long (32 bits)', $
        'Long64 (64 bits)', $

        'Float (32 bits)', $
        'Double-Precision (64 bits)', $

        'Unsigned Integer (16 bits)', $
        'Unsigned Long (32 bits)', $
        'Unsigned Long64 (64 bits)', $

        'Complex (real-imag pair of floats)', $
        'Double complex (pair of doubles)' $
        ], $
    uvalue=[ $ ; IDL typecodes corresponding to each droplist entry.
        1,  $
        2,  $
        3,  $
        14, $

        4,  $
        5,  $

        12, $
        13, $
        15, $

        6,  $
        9   $
        ] $
    )


wOffsetBase = WIDGET_BASE(wLeftBase, /COLUMN, YPAD=5)
wFieldBase = widget_base(wOffsetBase, /row)
void = widget_label(wFieldBase, value='Offset: ')
(*pState).wOffset = widget_text( $
    wFieldBase, $
    scr_xsize=110, $
    /editable, $
    /all_events, $
    value='>0' $
    )
void = widget_label(wFieldBase, value=' bytes')
(*pState).wAbsoluteRadio = cw_bgroup(wOffsetBase, $
    /exclusive, $
    /no_release, $
    set_value=1, $
    ['From beginning of file', $
     (*pState).current_field_indx eq 0 and $
     ((*pState).fieldcount eq 0 or (*pState).we_are_inserting eq 0) ? $
        'From initial position in file' : 'From end of previous field' $
    ], $
    /column, $
    space=0)

if (*pState).useExecute then begin
    expString = [ $
        ' or an expression', $
        'involving fields defined earlier in the template.']
endif else begin
    expString = [ $
        ' or the name', $
        'of a field defined earlier in the template.']
endelse

wDummy = WIDGET_LABEL(wOffsetBase, /ALIGN_LEFT, $
    VALUE='Offset can be an integer' + expString[0])
wDummy = WIDGET_LABEL(wOffsetBase, /ALIGN_LEFT, VALUE=expString[1])

void = WIDGET_LABEL(wOffsetBase, VALUE=' ')
void = widget_label(wOffsetBase, /ALIGN_LEFT, $
    VALUE='When a file is read, this field should be:')
(*pState).wReturn = cw_bgroup( $
    wOffsetBase, $
    /nonexclusive, $
    'Returned in the result' $
    )
widget_control, (*pState).wReturn, set_value=[1]

(*pState).wVerifyBase = widget_base(wOffsetBase, /row, xpad=0, ypad=3)
(*pState).wVerifyCheckbox = cw_bgroup( $
    (*pState).wVerifyBase, $
    /nonexclusive, $
    'Verified as being equal to:' $
    )
(*pState).wVerifyText = widget_text( $
    widget_base((*pState).wVerifyBase, /row, xpad=0), $
    scr_xsize=70, $
    sensitive=0, $
    /editable $
    )

wDummy = WIDGET_LABEL(wOffsetBase, /ALIGN_LEFT, $
    VALUE='The Verify field can be a number' + expString[0])
wDummy = WIDGET_LABEL(wOffsetBase, /ALIGN_LEFT, VALUE=expString[1])


wRightBase = widget_base(wRowBase, /column, xpad=2, ypad=5)

(*pState).wNumDims = widget_droplist( $
    wRightBase, $
    value=[ $
        '0 (scalar)', $
        strcompress(indgen((*pState).max_idl_dims) + 1, /remove_all) $
        ], $
    title='Number of dimensions:' $
    )

void = WIDGET_LABEL(wRightBase, VALUE=' ')

w2x4Base = widget_base(wRightBase, col=1, xpad=0, ypad=0, space=0)

for i=0,2 do begin
    (*pState).wIndividualDimBase[i] = widget_base( $
        w2x4Base, /row, $
        /base_align_left)
    void = widget_label( $
        (*pState).wIndividualDimBase[i], $
        value=(['1st', '2nd', '3rd'])[i] + ':', SCR_XSIZE=40)
    void = widget_label((*pState).wIndividualDimBase[i], value='  Size: ')
    (*pState).wDimText[i] = widget_text( $
        (*pState).wIndividualDimBase[i], $
        /editable, $
        /all_events)
    (*pState).wReverseCheckbox[i] = cw_bgroup( $
        (*pState).wIndividualDimBase[i], $
        'Reverse', $
        /nonexcl, $
        ypad=0)
endfor

for i=3,(*pState).max_idl_dims-1 do begin
    (*pState).wIndividualDimBase[i] = widget_base( $
        w2x4Base, $
        /row, $
        /base_align_left)
    void = widget_label( $
        (*pState).wIndividualDimBase[i], $
        value=strcompress(i+1, /remove_all) + 'th:', SCR_XSIZE=40)
    void = widget_label((*pState).wIndividualDimBase[i], value='  Size: ')
    (*pState).wDimText[i] = widget_text( $
        (*pState).wIndividualDimBase[i], $
        /editable, $
        /all_events)
endfor

wDummy = WIDGET_LABEL(wRightBase, /ALIGN_LEFT, $
    VALUE='Each dimension can be an integer' + expString[0])
wDummy = WIDGET_LABEL(wRightBase, /ALIGN_LEFT, VALUE=expString[1])


wRowBase = widget_base(tlb, /row)
wRB1 = widget_base(wRowBase, /row)
wRB_Spacer = widget_base(wRowBase, xsize=10)
wRB2 = widget_base(wRowBase, /row)

(*pState).wModifyHelp = widget_button(wRB1, value=' Help ')

(*pState).wModifyOK = widget_button(wRB2, value=' OK ')
(*pState).wModifyCancel = widget_button(wRB2, value=' Cancel ')

tlb_geom = widget_info(tlb, /geometry)
rb1_geom = widget_info(wRB1, /geometry)
rb2_geom = widget_info(wRB2, /geometry)
  
rb_space_width = tlb_geom.xsize - rb1_geom.xsize - rb2_geom.xsize - (tlb_geom.xpad * 4)
widget_control, wRB_Spacer, xsize=rb_space_width 


widget_control, tlb, /realize
if ~(*pState).we_are_inserting then begin
    widget_control, $
        (*pState).wFieldName, $
        set_value=(*(*pState).pNames)[(*pState).current_field_indx]
    widget_control, $
        (*pState).wOffset, $
        set_value=(*(*pState).pOffsets)[(*pState).current_field_indx]
    widget_control, $
        (*pState).wAbsoluteRadio, $
        set_value=(*(*pState).pAbsoluteFlags)[(*pState).current_field_indx] eq 0
    widget_control, $
        (*pState).wReturn, $
        set_value=(*(*pState).pReturnFlags)[(*pState).current_field_indx]
    widget_control, $
        (*pState).wVerifyCheckbox, $
        set_value=(*(*pState).pVerifyFlags)[(*pState).current_field_indx]
    widget_control, $
        (*pState).wNumDims, $
        set_droplist_select=(*(*pState).pNumDims)[ $
            (*pState).current_field_indx $
            ]

    for i=0,(*(*pState).pNumDims)[(*pState).current_field_indx]-1 do begin
        widget_control, $
            (*pState).wDimText[i], $
            set_value=(*(*pState).pDimensions)[ $
                (*pState).current_field_indx, $
                i $
                ]
    endfor

    for i=0,((*(*pState).pNumDims)[(*pState).current_field_indx]-1)<2 do begin
        widget_control, $
            (*pState).wReverseCheckbox[i], $
            set_value=(*(*pState).pReverseFlags)[ $
                (*pState).current_field_indx, $
                i $
                ]
    endfor

    widget_control, (*pState).wType, get_uvalue=typecode_table
    widget_control, $
        (*pState).wType, $
        set_droplist_select=(where( $
            typecode_table eq (*(*pState).pTypecodes)[ $
                (*pState).current_field_indx $
                ] $
            ))[0]

    widget_control, $
        (*pState).wVerifyText, $
        sensitive=(*(*pState).pVerifyFlags)[(*pState).current_field_indx] eq 1, $
        set_value=(*(*pState).pVerifyVals)[(*pState).current_field_indx]
endif  ; ~(*pState).we_are_inserting

num_dims = widget_info((*pState).wNumDims, /droplist_select)

for i=0,(*pState).max_idl_dims-1 do begin
    widget_control, $
        (*pState).wIndividualDimBase[i], $
        sensitive=i lt num_dims
endfor

widget_control, $
    (*pState).wVerifyBase, $
    sensitive=num_dims eq 0

widget_control, tlb, set_uvalue=pState

xmanager, 'bt_modify_field', tlb

end


;--------------------------------------------------------------------
pro binary_template_event, event
compile_opt hidden

    ; Need to kill manually to prevent flashing on Windows.
    ; The Cancel state field is initially set to 1, so we're okay.
    if (TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST') then begin
        WIDGET_CONTROL, event.top, /DESTROY
        return
    endif

widget_control, event.top, get_uvalue=pState

case event.id of

    (*pState).wOK: begin
        if (*pState).fieldcount gt 0 then begin
            if max(*(*pState).pReturnFlags) eq 0 then begin
                void = dialog_message( $
                    'Illegal template: no fields are marked "Yes" ' + $
                        'for Return.', $
                    /error $
                    )
                return
            endif
        endif

        widget_control, (*pState).wNameText, get_value=template_name
        (*pState).template_name = template_name

        (*pState).cancel = 0b
        widget_control, event.top, /destroy
        return
        end

    (*pState).wCancel: begin
        widget_control, event.top, /destroy
        return
        end

    (*pState).wHelp: begin
        ONLINE_HELP, 'BINARY_TEMPLATE'
        end

    (*pState).wEndian: $
        (*pState).endian = (['native', 'little', 'big'])[event.index]

    (*pState).wNewFieldButton: begin
        (*pState).we_are_inserting = 1b
        bt_modify_field, pState
        end

    (*pState).wModifyFieldButton: begin
        (*pState).we_are_inserting = 0b
        bt_modify_field, pState
        end

    (*pState).wRemoveFieldButton: begin
        bt_delete_item_from_array, $
            *(*pState).pNames, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pTypecodes, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pOffsets, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pAllowFormulas, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pDimAllowFormulas, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pAbsoluteFlags, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pNumDims, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pDimensions, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pReverseFlags, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pReturnFlags, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pVerifyFlags, $
            (*pState).current_field_indx

        bt_delete_item_from_array, $
            *(*pState).pVerifyVals, $
            (*pState).current_field_indx

        (*pState).fieldcount = (*pState).fieldcount - 1
        (*pState).current_field_indx = ((*pState).current_field_indx - 1) > 0

        bt_update_field_display, *pState, /highlight_current_row

        end

    (*pState).wTable: begin
        if tag_names(event, /structure_name) eq 'WIDGET_TABLE_CELL_SEL' $
            then begin
            if event.sel_top ne -1 && event.sel_left ne -1 then begin
                (*pState).current_field_indx = $
                    0 > (event.sel_top < ((*pState).fieldcount - 1))
                if event.sel_right eq event.sel_left $
                    && event.sel_right eq 5 $
                    && (*pState).fieldcount gt 0 then begin
                    bt_put_val_into_array, $
                        *(*pState).pReturnFlags, $
                        1 - (*(*pState).pReturnFlags)[ $
                            (*pState).current_field_indx $
                            ], $
                        (*pState).current_field_indx, $
                        insert=0, $
                        debug=(*pState).debug
                    bt_update_field_display, *pState
;
;                   The cell at Row 0, Column 0 might now be highlighted, in
;                   addition to the current cell.  To undo this
;                   artifact, highlight only the current cell.
;
                    widget_control, $
                        event.id, $
                        set_table_select=[ $
                            event.sel_left, $
                            event.sel_top , $
                            event.sel_right, $
                            event.sel_bottom $
                            ]
                endif
;
;               Nicety: If an entire column was selected, allow the
;               selection to show on the screen for a moment before
;               un-doing the selection.  This pause also allows the
;               user to see which column is selected if the user is
;               pressing the arrow keys to "walk around" in the table.
;               Seeing which column is selected when using the arrow
;               keys helps the user know when a "Return" will be
;               toggled between "No" and "Yes" as a result of
;               an arrow keypress.
;
                wait, .25
;
;               Select a row.
;
                widget_control, $
                    event.id, $
                    set_table_select=[ $
                        0, $
                        0 > (event.sel_top < ((*pState).fieldcount - 1)), $
                        n_elements((*pState).column_labels) - 1, $
                        0 > (event.sel_top < ((*pState).fieldcount - 1)) $
                        ]
            endif
        endif  ; WIDGET_TABLE_CELL_SEL
    end

    else:

endcase


widget_control, $
    (*pState).wModifyFieldButton, $
    sensitive=(*pState).fieldcount gt 0
widget_control, $
    (*pState).wRemoveFieldButton, $
    sensitive=(*pState).fieldcount gt 0
widget_control, (*pState).wOK, sensitive=(*pState).fieldcount gt 0

end


;--------------------------------------------------------------------
function binary_template, $
    filename, $               ; IN: (opt) test dataset.
    cancel=cancel, $          ; OUT: (opt) set if user canceled this dialog.
    template=template, $      ; IN: (opt) initial template.
    debug=debug, $            ; IN: (opt)
    n_rows=n_rows, $          ; IN: (opt) number of rows in widget_table.
    group=group_leader, $     ; IN: (opt) group_leader for base widget
    no_file=no_file           ; IN: (opt) Undocumented.  This feature may
                              ;           change!  If set, do not require
                              ;           FILENAME argument.

on_error, 2
catch, error_status
if error_status ne 0 then begin
    catch, /cancel
;
;   Clean up.
;
    if n_elements(lun) gt 0 then $
        free_lun, lun
    if n_elements(tlb) gt 0 then $
        if widget_info(tlb, /valid_id) then $
            widget_control, tlb, /destroy
    if n_elements(pState) gt 0 then $
        if ptr_valid(pState) then begin
            bt_rake, *pState
            ptr_free, pState
        endif
    if keyword_set(group_leader_is_fabricated) then begin
        if n_elements(group_leader) gt 0 then begin
            if widget_info(group_leader, /valid_id) then $
                widget_control, group_leader, /destroy
            ptr_free, ptr_new(group_leader, /no_copy)
        endif
    endif
;
;   Re-throw the error.
;
    message, !error_state.msg + ' ' + !error_state.sys_msg
endif
;
if keyword_set(debug) then begin
    catch, /cancel
    on_error, 0
endif

;
;Test TEMPLATE argument.
;
if (n_elements(template) gt 0) then begin
    if ~rb_template_is_valid(template, msg=msg, /edit) then $
        message, msg[0], /noname
endif

;
;Test the FILENAME input argument.  For consistency, the logic here
;is intended to yield results similar to ASCII_TEMPLATE.
;
case 1 of

    keyword_set(no_file): $
        filename = ''

    n_elements(filename) eq 0: begin
        filename = dialog_pickfile(/must_exist, group=group_leader)
        if filename eq '' then begin
            cancel = 1b
            return, 0
        endif
        end

    size(filename, /n_dimensions) gt 1: $
        message, 'First argument must be scalar.', /noname

    size(filename, /tname) ne 'STRING': $
        message, 'First argument must be a string.', /noname

    filename eq '': $
        message, 'Supplied filename is an empty string.', /noname

    else: begin
        if (file_search(filename))[0] eq '' then $
            message, $
                'Could not find specified file: ' + filename + '.', $
                /noname
        end

endcase

;
;Test that we have read access to the file.
;
if filename ne '' then begin
    get_lun, lun
    openr, lun, filename
    close, lun
    free_lun, lun
endif

;
;BINARY_TEMPLATE is a function, thus its GUI will be modal.
;Modal widgets require a group leader.  Make sure that
;we have a group leader, fabricating an invisible one
;if necessary.
;
if n_elements(group_leader) eq 0 then begin
    group_leader = widget_base(map=0)
    group_leader_is_fabricated = 1b
endif else begin
    if ~widget_info(group_leader, /valid_id) then $
        message, 'Specified GROUP_LEADER is invalid.', /noname
    group_leader_is_fabricated = 0b
endelse

title = 'Binary Template'
if (filename ne '') then $
    title += ' [' + FILE_BASENAME(filename) + ']'

tlb = widget_base( $ ; Top-level base.
    /column, $
    /FLOATING, $
    /TLB_KILL_REQUEST_EVENTS, $
    title=title, $
    group_leader=group_leader, $
    /modal, $
    space=30, xpad=10, ypad=10, $
    /TAB_MODE)

wRowBase = widget_base(tlb, /row)
void = widget_label(wRowBase, value='Template name:')
wNameText = widget_text(wRowBase, /editable)

wEndian = widget_droplist( $
    wRowBase, $
    title=' File byte ordering:', $
    value=['Native', 'Little Endian', 'Big Endian'] $
    )

wFrameBase = widget_base(tlb, /col)
void = widget_label(wFrameBase, value='Fields:', /align_left)
column_widths = [120, 100, 100, 100, 100, 50, 50]

column_labels = [ $
    'Name', $
    'Offset', $
    'Dimensions', $
    'Bytes', $
    'Type', $
    'Return', $
    'Verify' $
    ]

if ~keyword_set(n_rows) then $
    n_rows = (n_elements(template) gt 0) ? $
        6 > template.fieldcount < 12 : 6

if n_rows le 0 then $
    message, 'N_ROWS must be positive.'

wTable = widget_table( $
    wFrameBase, $
    column_labels=column_labels, $
    xsize=n_elements(column_labels), $
    scr_xsize=total(column_widths) + 60, $
    ysize=n_rows, $
    y_scroll_size=n_rows, $
    value=strarr(n_elements(column_labels), n_rows), $
    /resizeable_columns, $
    /all_events, $
    /scroll $
    )

widget_control, wTable, column_widths=30, use_table_select=[-1, 0, 0, 0]
widget_control, $
    wTable, $
    column_widths=column_widths, $
    use_table_select=[0, 0, 6, 0]

wRowBase = widget_base(wFrameBase, /row)
wNewFieldButton = widget_button(wRowBase, value='New Field...')
wModifyFieldButton = widget_button(wRowBase, value='Modify Field...')
wRemoveFieldButton = widget_button(wRowBase, value='Remove Field')

wRowBase = widget_base(tlb, /row)
wRB1 = widget_base(wRowBase, /row)
wRB_Spacer = widget_base(wRowBase, xsize=10)
wRB2 = widget_base(wRowBase, /row)

wHelp = widget_button(wRB1, value=' Help ')

wOK = widget_button(wRB2, value=' OK ')
wCancel = widget_button(wRB2, value=' Cancel ')

tlb_geom = widget_info(tlb, /geometry)
rb1_geom = widget_info(wRB1, /geometry)
rb2_geom = widget_info(wRB2, /geometry)
  
rb_space_width = tlb_geom.xsize - rb1_geom.xsize - rb2_geom.xsize - (tlb_geom.xpad * 4)
widget_control, wRB_Spacer, xsize=rb_space_width 
;
;Initialize and store the state of this program.
;
max_idl_dims = 8
pState = ptr_new({ $
    tlb: tlb, $
    wNameText: wNameText, $
    wEndian: wEndian, $
    wHelp: wHelp, $
    wOK: wOK, $
    wCancel: wCancel, $
    wTable: wTable, $
    wNewFieldButton: wNewFieldButton, $
    wModifyFieldButton: wModifyFieldButton, $
    wRemoveFieldButton: wRemoveFieldButton, $
    wFieldName: 0L, $
    wAbsoluteRadio: 0L, $
    wOffset: 0L, $
    wReturn: 0L, $
    wVerifyCheckbox: 0L, $
    wVerifyBase: 0L, $
    wVerifyText: 0L, $
    wNumDims: 0L, $
    max_idl_dims: max_idl_dims, $
    wIndividualDimBase: lonarr(max_idl_dims), $
    wDimLabel: lonarr(max_idl_dims), $
    wDimText: lonarr(max_idl_dims), $
    wReverseCheckbox: lonarr(3), $
    wType: 0L, $
    wModifyHelp: 0L, $
    wModifyOK: 0L, $
    wModifyCancel: 0L, $
    column_labels: column_labels, $
    n_rows: n_rows, $
    n_scroll_rows: n_rows, $
    we_are_inserting: 0L, $
    cancel: 1b, $
    useExecute: ~LMGR(/VM), $   ; Cannot use execute in IDL Virtual Machine.
    fieldcount: 0L, $
    current_field_indx: 0L, $
    offset_str: '>0', $
    offset_sign: '>', $
    debug: keyword_set(debug), $
    filename: filename, $ ; Valid string, or ''.
    template_name: '', $
    endian: 'native', $
    pNames: ptr_new(/allocate_heap), $ ; Array of strings.
    pOffsets: ptr_new(/allocate_heap), $
    pAllowFormulas: ptr_new(/allocate_heap), $ ; Array of "boolean"
    pDimAllowFormulas: ptr_new(/allocate_heap), $ ; Array of "boolean"
    pNumDims: ptr_new(/allocate_heap), $ ; Array of ints.
    pDimensions: ptr_new(/allocate_heap), $ ; Array of array of strings.
    pReverseFlags: ptr_new(/allocate_heap), $ ; Array of ptrs to array.
    pTypecodes: ptr_new(/allocate_heap), $ ; Array.
    pReturnFlags: ptr_new(/allocate_heap), $
    pVerifyFlags: ptr_new(/allocate_heap), $ ; Array of "boolean"
    pVerifyVals: ptr_new(/allocate_heap), $ ; Array of strings.
    pAbsoluteFlags: ptr_new(/allocate_heap), $ ; Array of "boolean"
    pInitialTemplate: ptr_new(/allocate_heap) $
    })
widget_control, tlb, set_uvalue=pState
;
;Center and realize our top-level base.
;
  screen_size = [640, 480]
  DEVICE, GET_SCREEN_SIZE=screen_size

geom = widget_info(tlb, /geometry)
widget_control, $
    tlb, $
    xoffset=(screen_size[0]/2 - geom.scr_xsize/2) > 0, $
    yoffset=(screen_size[1]/2 - geom.scr_ysize/2) > 0
widget_control, tlb, /realize
widget_control, $
    wTable, $
    set_table_select=[0, 0, n_elements(column_labels) - 1, 0]
;
;Store and display initial template, if any.
;
if n_elements(template) gt 0 then begin
    (*pState).template_name = template.templatename
    (*pState).endian = template.endian
    (*pState).fieldcount = template.fieldcount
    *(*pState).pTypecodes = template.Typecodes
    *(*pState).pNames = template.Names
    *(*pState).pOffsets = template.Offsets
    *(*pState).pNumDims = template.NumDims
    *(*pState).pDimensions = template.Dimensions
    *(*pState).pReverseFlags = template.ReverseFlags
    *(*pState).pAbsoluteFlags = template.AbsoluteFlags
    *(*pState).pReturnFlags = template.ReturnFlags
    *(*pState).pVerifyFlags = template.VerifyFlags
    *(*pState).pVerifyVals = template.VerifyVals
    *(*pState).pAllowFormulas = template.OffsetAllowFormulas
    *(*pState).pDimAllowFormulas = template.DimAllowFormulas

    widget_control, (*pState).wNameText, set_value=template.templatename
    if strupcase((*pState).endian) eq 'LITTLE' then $
        widget_control, (*pState).wEndian, set_droplist_select=1
    if strupcase((*pState).endian) eq 'BIG' then $
        widget_control, (*pState).wEndian, set_droplist_select=2
    bt_update_field_display, *pState, /highlight_current_row

    *(*pState).pInitialTemplate = template
endif  ; template

;
;Set initial sensitivity of buttons.
;
if (*pState).fieldcount eq 0 then begin
    widget_control, wModifyFieldButton, sensitive=0
    widget_control, wRemoveFieldButton, sensitive=0
    widget_control, wOK, sensitive=0
    end

;
;Allow the user to interact with this program, affecting the state data.
;
xmanager, 'binary_template', tlb

if (*pState).cancel || (*pState).fieldcount eq 0 then begin
    result = 0
    if n_elements(*(*pState).pInitialTemplate) gt 0 then begin
        result = *(*pState).pInitialTemplate
        end
    cancel = 1b ; Return parameter.
endif else begin
;
;   Append a zero ("0") to offset strings that do not have any numeric
;   digits in them.  This makes the resulting strings more uniform, and
;   thus (hopefully) easier to understand should a person be
;   examining these values for any reason.
;
    indx = where(*(*pState).pOffsets eq '')
    if indx[0] ne -1 then $
        (*(*pState).pOffsets)[indx] = '0'

    indx = where(*(*pState).pOffsets eq '>')
    if indx[0] ne -1 then $
        (*(*pState).pOffsets)[indx] = '>0'

    indx = where(*(*pState).pOffsets eq '<')
    if indx[0] ne -1 then $
        (*(*pState).pOffsets)[indx] = '<0'
;
;   Store a copy of any state information that is to be returned.
;
    result = { $
        version: 1.0, $
        templatename: (*pState).template_name, $
        endian: (*pState).endian, $
        fieldcount: (*pState).fieldcount, $
        typecodes: *(*pState).pTypecodes, $
        names: *(*pState).pNames, $
        offsets: *(*pState).pOffsets, $
        numdims: *(*pState).pNumDims, $
        dimensions: *(*pState).pDimensions, $
        ReverseFlags: *(*pState).pReverseFlags, $
        AbsoluteFlags: *(*pState).pAbsoluteFlags, $
        ReturnFlags: *(*pState).pReturnFlags, $
        VerifyFlags: *(*pState).pVerifyFlags, $
        dimAllowFormulas: *(*pState).pDimAllowFormulas, $
        offsetAllowFormulas: *(*pState).pAllowFormulas, $
        verifyvals: *(*pState).pVerifyVals $
        }
    cancel = 0b ; Return parameter.
endelse

;
;Clean up.
;
bt_rake, *pState
ptr_free, pState
if group_leader_is_fabricated then begin
    widget_control, group_leader, /destroy
;
;   Leave GROUP_LEADER parameter like we found it: undefined.
;
    ptr_free, ptr_new(group_leader, /no_copy)
endif

return, result

end
