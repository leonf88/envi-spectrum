; $Id: //depot/idl/releases/IDL_80/idldir/lib/rb_routines.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;The rotuines in this file were created for use by READ_BINARY and
;BINARY_TEMPLATE.  The "rb_" prefix used on the routine names
;stands for Read_Binary, but the routines are used by binary_template
;also.

function rb_dim_str, dims, num_dims

    compile_opt hidden, strictarr
    ;
    ;Assemble a dimension string from the strings in DIMS.
    ;A dimension string is like '[640, 512]', and can have
    ;variables or expressions in it, e.g. '[xsize, ysize].'
    ;
    if num_dims eq 0 then begin
        result = 'scalar'
    endif else begin
        result = '['
        for i=0,num_dims-1 do begin
            result = result + strtrim(dims[i], 2)
            if i lt num_dims-1 then $
                result = result + ', '
        endfor
        result = result + ']'
    endelse

    return, result

end


;--------------------------------------------------------------------
function rb_is_integral, val

    compile_opt hidden, strictarr

    ;
    ;Purpose: test value to see if it is an integer.
    ;
    switch size(val, /TYPE) of
        1:
        2:
        3:
        12:
        13:
        14:
        15: return, 1
        else: return, 0
    endswitch

end


;--------------------------------------------------------------------
; Internal routine to verify an expression.
;
function rb_expression_is_valid, $
    rb_tagname, rb_expression, rb_fieldname, rb_useExecute, $
    RB_MSG=rb_msg

    compile_opt hidden, strictarr

    rb_msg = ''  ; no error

    if STRPOS(STRUPCASE(rb_expression), 'RB_') ne -1 $
        || STRPOS(STRUPCASE(rb_expression), 'BT_') ne -1 then begin
        rb_msg = 'Invalid template: ' + rb_tagname + ' for field ' $
            + STRUPCASE(rb_fieldname) $
            + ' is invalid. ("RB_" and "BT_" not allowed.)'
        return, 0
    endif

    ; This assumes that the EXECUTE has already been done.
    if !error_state.name eq 'IDL_M_BADSYNTAX' $
        || !error_state.name eq 'IDL_M_ILLOP' $
        || !error_state.name eq 'IDL_M_ILLCHAR' then begin
        rb_msg = ['Invalid template: ' + rb_tagname + ' for field ' $
                + strupcase(rb_fieldname) $
                + ' is invalid.', $
            '(' + !error_state.msg + ')']
        return, 0
    endif

    return, 1   ; success
end


;--------------------------------------------------------------------
function rb_template_is_valid_internal, rb_template, edit=edit

COMPILE_OPT hidden, strictarr
;
;Purpose: return null string if template is valid, else return msg.
;Also return a message string via the MSG keyword.
;
;If keword EDIT is set, test template for use with the template
;editor, BINARY_TEMPLATE, else test the template for use with
;READ_BINARY.
;
;Note: some variables in this routine are named with an
;"rb_" prefix.  This is to help avoid clashes with field
;names specified in the template.  "rb_" stands for
;"Read_Binary".
;

; We cannot use execute in the IDL Virtual Machine.
rb_useExecute = ~LMGR(/VM)

if n_elements(rb_template) gt 1 then $
    return, 'Template cannot be an array.'

if size(rb_template, /tname) ne 'STRUCT' then $
    return, 'Template must be a structure.'

;
;Make sure 'version' field is present.
;
tag_names_found = tag_names(rb_template)
void = where(tag_names_found eq 'VERSION', count)
if count ne 1 then $
    return, 'Version field is missing from template.'

;
;Check the rest of the fields in the template.
;
case rb_template.version of
    1.0: begin
        tag_names_required = strupcase([ $
            'endian', $
            'fieldCount', $
            'Typecodes', $
            'Names', $
            'Offsets', $
            'NumDims', $
            'Dimensions', $
            'reverseflags', $
            'AbsoluteFlags', $
            'ReturnFlags', $
            'VerifyFlags', $
            'VerifyVals' $
            ])
        if keyword_set(edit) then begin
            tag_names_required = [ $
                tag_names_required, $
                strupcase([ $
                    'TemplateName', $
                    'DimAllowFormulas', $
                    'OffsetAllowFormulas' $
                    ]) $
                ]
        endif
        end

    else: return, 'The only recognized template version is: 1.0.'

endcase

for i=0,n_elements(tag_names_required)-1 do begin
    void = where(tag_names_found eq tag_names_required[i], count)
    if count ne 1 then $
        return, tag_names_required[i] + ' field missing from template.'
endfor

if size(rb_template.names, /tname) ne 'STRING' then $
    return, 'Invalid template: Names must be of type STRING.'

if keyword_set(edit) then begin
    if size(rb_template.templatename, /tname) ne 'STRING' then $
        return, 'Invalid template: TemplateName must be of type STRING.'
    if n_elements(rb_template.templatename) gt 1 then $
        return, 'Invalid template: TemplateName cannot have more than ' $
            + 'one element.'
endif

if size(rb_template.offsets, /tname) ne 'STRING' then $
    return, 'Invalid template: Offsets must STRING expressions.'

if size(rb_template.dimensions, /tname) ne 'STRING' then $
    return, 'Invalid template: Dimensions must be STRING expressions.'

if size(rb_template.verifyvals, /tname) ne 'STRING' then $
    return, 'Invalid template: VerifyVals must be STRING expressions.'

if n_elements(rb_template.endian) gt 1 then $
    return, 'Invalid template: Endian specification cannot have more ' + $
        'than one element.'

rb_nf = rb_template.fieldCount
if ~rb_is_integral(rb_nf) then $
    return, 'Invalid template: FieldCount is not an integer.'

if rb_nf lt 1 then $
    return, 'Invalid template: FieldCount is less than 1.'

;
;Check that specified field names are unique.
;
if n_elements(uniq(strupcase(rb_template.names), $
    sort(strupcase(rb_template.names)))) ne rb_nf then $
    return, 'Invalid template: specified field names are not unique.'

if ~rb_is_integral(rb_template.Typecodes) then $
    return, 'Invalid template: Typecodes must be integers.'

if ~rb_is_integral(rb_template.NumDims) then $
    return, 'Invalid template: NumDims must be integers.'

if ~rb_is_integral(rb_template.reverseflags) then $
    return, 'Invalid template: ReverseFlags must be integers.'

if ~rb_is_integral(rb_template.absoluteflags) then $
    return, 'Invalid template: AbsoluteFlags must be integers.'

if ~rb_is_integral(rb_template.ReturnFlags) then $
    return, 'Invalid template: ReturnFlags must be integers.'

if ~rb_is_integral(rb_template.VerifyFlags) then $
    return, 'Invalid template: VerifyFlags must be integers.'


if keyword_set(edit) then begin
    if ~rb_is_integral(rb_template.DimAllowFormulas) then $
        return, 'Invalid template: DimAllowFormulas must be integers.'

    if ~rb_is_integral(rb_template.OffsetAllowFormulas) then $
        return, 'Invalid template: OffsetAllowFormulas must be integers.'
endif

if n_elements(rb_template.Typecodes) ne rb_nf then $
    return, 'Invalid template: number of Typecodes does ' + $
        'not match FieldCount.'

if n_elements(rb_template.Names) ne rb_nf then $
    return, 'Invalid template: number of Names does ' + $
        'not match FieldCount.'

if n_elements(rb_template.Offsets) ne rb_nf then $
    return, 'Invalid template: number of Offsets does ' + $
        'not match FieldCount.'

if n_elements(rb_template.NumDims) ne rb_nf then $
    return, 'Invalid template: number of NumDims does ' + $
        'not match FieldCount.'


siz = size(rb_template.Dimensions)
if siz[0] lt 2 then $
    return, 'Invalid template: Dimensions field must be a 2D array.'

if siz[1] ne rb_nf then $
    return, 'Invalid template: 1st dimension of Dimensions array ' + $
            'should be same as FieldCount.'

if siz[2] ne 8 then $
    return, 'Invalid template: Dimensions'' 2nd dimension must be 8.'

siz = size(rb_template.reverseflags)
if siz[0] lt 2 then $
    return, 'Invalid template: ReverseFlags field must have two dimensions.'

if siz[1] ne rb_nf then $
    return, 'Invalid template: 1st dimension of reverseflags array ' + $
            'should be same as FieldCount.'

if siz[2] ne 8 then $
    return, 'Invalid template: ReverseFlags''s 2nd dimension must be 8.'

if n_elements(rb_template.absoluteflags) ne rb_nf then $
    return, 'Invalid template: number of AbsoluteFlags does ' + $
            'not match FieldCount.'

if n_elements(rb_template.ReturnFlags) ne rb_nf then $
    return, 'Invalid template: number of ReturnFlags does ' + $
            'not match FieldCount.'

if n_elements(rb_template.VerifyFlags) ne rb_nf then $
    return, 'Invalid template: number of VerifyFlags does ' + $
            'not match FieldCount.'


if keyword_set(edit) then begin
    if n_elements(rb_template.dimallowformulas) ne rb_nf then $
        return, 'Invalid template: number of dimallowformulas does ' + $
                'not match FieldCount.'

    if n_elements(rb_template.offsetallowformulas) ne rb_nf then $
        return, 'Invalid template: number of offsetallowformulas does ' + $
                'not match FieldCount.'
endif

if n_elements(rb_template.verifyvals) ne rb_nf then $
    return, 'Invalid template: number of verifyvals does ' + $
            'not match FieldCount.'

if not keyword_set(edit) then begin
    returns_indx = where(rb_template.ReturnFlags ne 0)
    if returns_indx[0] eq -1 then $
        return, 'Invalid template: no fields are set to be returned.'
endif

for rb_i=0,rb_nf-1 do begin
;
;   Check field name syntax.
;
    if rb_template.names[rb_i] eq '' then $
        return, 'Invalid template: names[' $
            + strcompress(rb_i, /remove_all) $
            + '] is blank.'

    if strpos(strupcase(rb_template.names[rb_i]), 'RB_') ne -1 $
        || strpos(strupcase(rb_template.names[rb_i]), 'BT_') ne -1 then $
        return, 'Invalid template: Invalid field name ' $
            + strupcase(rb_template.names[rb_i]) $
            + '. ("RB_" and "BT_" not allowed.)'

    if ~IDL_VALIDNAME(rb_template.names[rb_i], /CONVERT_SPACES) then $
        return, ['Invalid template: field name ' $
                + strupcase(rb_template.names[rb_i]) $
                + ' is invalid.', $
            '(' + !error_state.msg + ')']

    ; Construct a named variable with a scalar zero in case
    ; we need the variable name for the EXECUTE's below.
    if (rb_useExecute) then $
        (SCOPE_VARFETCH(rb_template.names[rb_i], /ENTER)) = 0

;
;   Check offset syntax.
;

    ; Strip off leading > or < if necessary.
    rb_offset = rb_template.offsets[rb_i]
    rb_firstChar = STRMID(rb_offset, 0, 1)
    if (rb_firstChar eq '>' || rb_firstChar eq '<') then $
        rb_offset = STRMID(rb_offset, 1)
    MESSAGE, /RESET ; clear !error_state
    ; Do the EXECUTE here in case it relies on previous field names.
    if (rb_useExecute) then $
        rb_void = EXECUTE('rb_void = ' + rb_offset, 1)
    if ~RB_EXPRESSION_IS_VALID('OFFSET', rb_offset, $
        rb_template.names[rb_i], RB_MSG=rb_msg) then $
        return, rb_msg

;
;   Check dimensions syntax.
;
    if rb_template.numdims[rb_i] gt 0 then begin
        rb_dimension = RB_DIM_STR(rb_template.dimensions[rb_i, *], $
            rb_template.numdims[rb_i])
        MESSAGE, /RESET ; clear !error_state
        ; Do the EXECUTE here in case it relies on previous field names.
        if (rb_useExecute) then $
            rb_void = EXECUTE('rb_void = ' + rb_dimension, 1)
        if ~RB_EXPRESSION_IS_VALID('DIMENSION', rb_dimension, $
            rb_template.names[rb_i], rb_useExecute, RB_MSG=rb_msg) then $
            return, rb_msg
    endif

;
;   Check verify value syntax.
;
    if rb_template.VerifyFlags[rb_i] eq 1 then begin
        MESSAGE, /RESET ; clear !error_state
        ; Do the EXECUTE here in case it relies on previous field names.
        if (rb_useExecute) then $
            rb_void = EXECUTE('rb_void = ' + rb_template.verifyvals[rb_i], 1)
        if ~RB_EXPRESSION_IS_VALID('VERIFY', $
            rb_template.verifyvals[rb_i], $
            rb_template.names[rb_i], rb_useExecute, RB_MSG=rb_msg) then $
            return, rb_msg
    endif

endfor  ; rb_nf

msg = 'Template is valid.'
return, ''   ; success (no error message)

end


;--------------------------------------------------------------------
; Purpose: return 1 if template is valid, else return 0.
; Also return a message string via the MSG keyword.
;
; If keword EDIT is set, test template for use with the template
; editor, BINARY_TEMPLATE, else test the template for use with
; READ_BINARY.
;
; Note: some variables in this routine are named with an
; "rb_" prefix.  This is to help avoid clashes with field
; names specified in the template.  "rb_" stands for
; "Read_Binary".
;
function rb_template_is_valid, rb_template, edit=edit, msg=msg

    compile_opt hidden, strictarr

    msg = rb_template_is_valid_internal(rb_template, edit=edit)

    if (msg eq '') then begin
        msg = 'Template is valid.'
        return, 1  ; success
    endif

    return, 0  ; failure
end


;--------------------------------------------------------------------
; dummy stub so that rb_routines can be compiled using RESOLVE_ROUTINE
pro rb_routines
	compile_opt hidden
end