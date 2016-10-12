; $Id: //depot/idl/releases/IDL_80/idldir/lib/ascii_template.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       ASCII_TEMPLATE
;
; PURPOSE:
;       Generate a template that defines an ASCII file format.
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;       template = ASCII_TEMPLATE( [file] )
;
; INPUTS:
;       file              - Name of file to base the template on.
;                           Default = use DIALOG_PICKFILE to get the file.
;
; INPUT KEYWORD PARAMETERS:
;       browse_lines      - Number of lines to read in at a time via the
;                           GUI's browse button.  Default = 50.
;
; OUTPUT KEYWORD PARAMETERS:
;       cancel            - Boolean indicating if the user canceled
;                           out of the interface (1B = canceled).
;
; OUTPUTS:
;       The function returns a template (structure) defining ASCII files
;       of the input file's format.  Such templates may be used as inputs
;       to function READ_ASCII.  (0 is returned if the user canceled.)
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       See DESCRIPTION.
;
; DESCRIPTION:
;       This routine presents a graphical user interface (GUI) that assists
;       the user in defining a template.
;
;       ASCII files handled by this routine consist of an optional header
;       of a fixed number of lines, followed by columnar data.  Files may
;       also contain comments, which exist between a user-specified comment
;       string and the corresponding end-of-line.
;
;       One or more rows of data constitute a "record."  Each data element
;       within a record is considered to be in a different column, or "field."
;       Adjacent fields may be "grouped" into multi-column fields.
;       The data in one field must be of, or promotable to, a single
;       type (e.g., FLOAT).
;
; EXAMPLES:
;       ; Generating a template to be used later, maybe on a set of files.
;       template = ASCII_TEMPLATE()
;
;       ; Same as above, but immediately specifying which file to use.
;       template = ASCII_TEMPLATE(file)
;
;       ; Same as above, but returning flag if the user canceled.
;       template = ASCII_TEMPLATE(file, CANCEL=cancel)
;
;       ; Generating and using a template in place for reading data.
;       data = READ_ASCII(file, TEMPLATE=ASCII_TEMPLATE(file))
;
; DEVELOPMENT NOTES:
;       - see ???,!!!,xxx in the code
;       - errors preserving state when switch pages with 'back/next'
;       - make NaN default missing value as in reader ?
;
; MODIFICATION HISTORY:
;       AL & RPM, 8/96 - Written.
;
;-

; -----------------------------------------------------------------------------
;
;  Purpose:  Build an ASCII file template, using defaults as necessary.
;
function at_build_templ, $
    num_fields=num_fields, $
    field_types=field_types, $
    field_names=field_names, $
    field_locations=field_locations, $
    record_start_loc=record_start_loc, $
    delimiter=delimiter, $
    groups=groups, $
    missing_value=missing_value, $
    comment_symbol=comment_symbol

  compile_opt idl2, hidden

  if (n_elements(num_fields) eq 0) then num_fields = 1
  tot_num_fields = total(num_fields)

  if (n_elements(field_types) eq 0) then field_types = 4L
  if (n_elements(field_locations) eq 0) then $
    field_locations = lonarr(tot_num_fields)
  if (n_elements(field_names) eq 0) then begin
    digits_str = string(strlen(strtrim(string(fix(tot_num_fields)),2)))
    fstr = '(i' + strtrim(digits_str,2) + '.' + strtrim(digits_str,2) + ')'
    field_names = 'FIELD' + string(lindgen(tot_num_fields)+1,format=fstr)
  endif

  if (n_elements(record_start_loc) eq 0) then record_start_loc = 0L
  if (n_elements(delimiter) eq 0) then delimiter = 0B
  if (n_elements(missing_value) eq 0) then missing_value = 0.0
  if (n_elements(groups) eq 0) then groups = lindgen(tot_num_fields)
  if (n_elements(comment_symbol) eq 0) then comment_symbol = ''

  ; define the ASCII template structure
  ;
  fields = replicate({ascii_field_struct, name:'', type:0, loc:0L}, $
    tot_num_fields)
  if (tot_num_fields eq 1) then begin
    fields.name = field_names[0]
    fields.type = field_types[0]
    fields.loc  = field_locations[0]
  endif else begin
    fields.name = field_names
    fields.type = field_types
    fields.loc  = field_locations
  endelse

  template = { $
    record_start_loc: record_start_loc, $
    delimit: delimiter[0], $
    missing_value: float(missing_value), $      ; Why FLOAT() ???
    comment_symbol: comment_symbol, $
    p_num_fields: ptr_new(num_fields), $
    p_fields: ptr_new(fields), $
    p_groups: ptr_new(groups) $
    }

  return, template

end                     ; at_build_templ

; -----------------------------------------------------------------------------
;
;  Purpose:  Delete an ASCII file template.
;
pro at_delete_template, template

  compile_opt idl2, hidden

  if (size(template,/type) ne 8) then return

  if (ptr_valid(template.p_num_fields)) then ptr_free, template.p_num_fields
  if (ptr_valid(template.p_fields)) then ptr_free, template.p_fields
  if (ptr_valid(template.p_groups)) then ptr_free, template.p_groups

end                     ; at_delete_template

; -----------------------------------------------------------------------------
;
;  Purpose:  Return a requested number of lines from the ASCII file.
;            If skip is set, then skip the first skip number of lines before
;            starting the read.
;            Return the last_pos to resume reading from a given point and
;            notify when the end of file has been reached.
;
function at_get_lines, name, num_lines, last_pos=last_pos, $
  end_reached=end_reached, skip=skip

  COMPILE_OPT idl2, hidden

  catch, error_status
  if (error_status ne 0) then begin
    end_reached = 1
    if (n_elements(unit) gt 0) then $
        if (unit ne 0) then free_lun, unit
    return, ''
  endif

  if (n_elements(last_pos) eq 0) then last_pos = 0
  if (n_elements(skip) eq 0) then skip = 0
  lines = strarr(num_lines)
  line = ''
  count = 0L
  openr, unit, name, /get_lun
  point_lun, unit, last_pos
  for i=0, skip-1 do readf, unit, line
  while (not eof(unit) and count lt num_lines) do begin
    readf, unit, line
    lines[count] = line
    count = count + 1
  endwhile

  end_reached = (count lt num_lines)
  point_lun, -unit, last_pos

  free_lun, unit
  if (count eq 0) then              return, '' $
  else if (count lt num_lines) then return, lines[0:count-1] $
  else                              return, lines

end                     ; at_get_lines

; -----------------------------------------------------------------------------
;
;  Purpose:  Build a default template structure.
;
function at_build_template, data, missing_value

  COMPILE_OPT idl2, hidden

  ; Use the first record from the file (ignoring comment strings
  ; and blank lines).
  ;
  lines = (*data.p_rlines)[0:n_elements(*data.p_num_fields)-1]

  ; lut is used to determine if a given field is integer,
  ; floating point, or a string.
  ;
  lut = bytarr(256) + 1b
  lut[0:32] = 0b
  lut[48:57] = 0b
  lut[byte('e')] = 0
  lut[byte('E')] = 0
  lut[byte('+')] = 0
  lut[byte('-')] = 0
  lut[byte('.')] = 0

  ; scan through a sample record and determine a default column
  ; position and IDL type for each field.
  ;
  tot_num_fields  = long(total(*data.p_num_fields))
  field_locations = lonarr(tot_num_fields)
  field_types     = intarr(tot_num_fields)
  fpos = 0L
  for i=0, n_elements(*data.p_num_fields)-1 do begin
    bline = [byte(lines[i]), 32b]

    if (data.delimit eq 32b) then begin       ; delimiter is 'space'
      nptr = where(bline ne 32b and bline ne 9b, ncount)
      fptr = nptr[0]
      for j=1, ncount-1 do $
        if (nptr[j] gt nptr[j-1]+1) then fptr = [fptr, nptr[j]]
      fptr = [fptr, n_elements(bline)]
      add = [0,1]

    endif else begin
      nptr = where(bline eq data.delimit, ncount)
      if (ncount eq 0) then fptr = [-1, n_elements(bline)] $
      else                  fptr = [-1, nptr, n_elements(bline)]
      add = [1,1]
    endelse

    for j=0, (n_elements(fptr)-2)<((*data.p_num_fields)[i]-1) do begin
      field_locations[fpos] = fptr[j] + add[0]
      bsub = bline[fptr[j]+add[0]:(fptr[j+1]-add[1])>(fptr[j]+add[0])]
      is_string = (total(lut[bsub]) gt 0)
      if (is_string eq 0) then begin
        if (total(bsub eq 46b) gt 0 or total(bsub eq 101b) gt 0 or $
                 total(bsub eq 69b) gt 0) then field_types[fpos] = 4 $
        else $
          field_types[fpos] = 3
      endif else $
        field_types[fpos] = 7
      fpos = fpos + 1
    endfor
  endfor

  s_delimit = ([0b, data.delimit])[data.mode]

  template = at_build_templ(num_fields=*data.p_num_fields, $
    field_types=field_types, field_locations=field_locations, $
    record_start_loc=data.data_start, delimiter=s_delimit, $
    missing_value=missing_value, comment_symbol=data.comment)

  return, template

end                     ; at_build_template

; -----------------------------------------------------------------------------
;
;  Purpose:  Return an array containing the number of fields/line
;            for each line of a record (based upon the delimiters found).
;
function at_num_fields, lines, delimit, comment

  COMPILE_OPT idl2, hidden

  for i=0, n_elements(lines)-1 do begin
    bline = byte(lines[i])

    if (delimit eq 32b) then begin       ; delimiter is 'space'

      nptr = where(bline ne 32b and bline ne 9b, count)
      fptr = nptr[0]

      for j=1, count-1 do $
        if (nptr[j] gt nptr[j-1]+1) then fptr = [fptr, nptr[j]]

    endif else begin                     ; delimiter is not 'space'
      nptr = where(bline eq delimit, count)
      fptr = bytarr(count+1)
    endelse

    if (n_elements(num_fields) eq 0) then $
        num_fields = n_elements(fptr) $
    else begin
        if (n_elements(fptr) eq num_fields[0]) then return, num_fields
        num_fields = [num_fields, n_elements(fptr)]
    endelse

  endfor

  if (n_elements(num_fields) gt 0) then return, num_fields $
  else                                  return, 1

end                     ; at_num_fields

; -----------------------------------------------------------------------------
;
;  Purpose:  Given the first line of data make a guess as to the delimiter
;            in use.
;
function at_default_delimit, line, comment

  compile_opt idl2, hidden

  if (comment ne '') then begin
    pos = strpos(line, comment, 0)
    if (pos[0] ge 0) then line = strmid(line, 0, pos[0])
  endif

  ; Remove leading & trailing blanks so we don't get misled.
  line = STRTRIM(line, 2)

  if (STRPOS(line, ';') ge 0) then return, 59b
  if (STRPOS(line, ',') ge 0) then return, 44b
  if (STRPOS(line, STRING(9b)) ge 0) then return, 9b

; don't assume that the delimiter can be a colon...
;  if (STRPOS(line, ':') ge 0) then return, 58b

  ; Default return 'space' as the delimiter.
  ;
  return, 32B

end                     ; at_default_delimit

; -----------------------------------------------------------------------------
;
; THIS FUNCTION IS NOT CURRENTLY USED !!!!!
;
;  Purpose:  Return a best guess of the groupings of data base upon initial
;            data type.
;
;function at_default_groups, data
;
;  compile_opt idl2, hidden
;
;  types = (*data.p_fields).type
;  groups = intarr(n_elements(types))
;  cur_group = 0
;
;  for i=1, n_elements(types)-1 do begin
;    if (types[i] eq types[i-1]) then groups[i] = groups[i-1] $
;    else begin
;      cur_group = cur_group + 1
;      groups[i] = cur_group
;    endelse
;  endfor
;
;  return, groups
;
;end                     ; at_default_groups

; -----------------------------------------------------------------------------
;
;  Purpose:  Given a position between 0 and tot_num_fields-1 determine
;            the line and location on the line of the given field.
;
function at_which_field, $
    num_fields, $  ; IN:
    pos, $         ; IN: the sequential field to check
    col            ; OUT: the corresponding column that the field is in

  compile_opt idl2, hidden

  count = 0

  for i=0, n_elements(num_fields)-1 do begin
    if (pos lt count+num_fields[i]) then begin
      col = pos - count

      ;  Return the sequential line that the field is in.
      ;
      return, i

    endif
    count = count + num_fields[i]
  endfor

end                     ; at_which_field

; -----------------------------------------------------------------------------
;
;  Purpose:  Convert a scalar string into a long or floating point value;
;            return 0 for any problems.
;
function at_str_to_val, str, floating=floating

  compile_opt idl2, hidden

  catch, error_status
  if (error_status ne 0) then begin
    message, /reset
    return, 0
  end

  if (keyword_set(floating)) then temp = 0. $
  else                            temp = 0L

  reads, str[0], temp

  return, temp

end                     ; at_str_to_val

; -----------------------------------------------------------------------------
;
;  Purpose:  Convert an array of numbers into a string of comma separated
;            values.
;
function at_list_to_str, vals

  compile_opt idl2, hidden

  str = strtrim(string(vals[0]),2)

  for i=1, n_elements(vals)-1 do $
    str = str + ',' + strtrim(string(vals[i]),2)

  return, str

end                     ; at_list_to_str

; -----------------------------------------------------------------------------
;
;  Purpose:  Given a string of comma separated values, convert into an array
;            of values.
;
function at_str_to_list, str

  compile_opt idl2, hidden

  len = strlen(str[0])
  ptr = where(byte(str[0]) eq 44b, count)
  sub = (strmid(str[0],len-1,1) eq ',')
  count = count - sub
  vals = lonarr(count+1)
  vals[0] = at_str_to_val(str[0])

  for i=0, count-1 do $
    vals[i+1] = at_str_to_val(strmid(str[0],ptr[i]+1,len))

  return, vals

end                     ; at_str_to_list

; -----------------------------------------------------------------------------
;
;  Purpose:  Scan through the string array and replace any instance of
;            tab (9b) with four white spaces.
;
pro at_remove_tabs, lines

  compile_opt idl2, hidden

  s_tab = string(9b)

  for i=0, n_elements(lines)-1 do begin

    loc = 0l
    len = strlen(lines[i])

    repeat begin
      pos = strpos(lines[i], s_tab, loc)
      if (pos ge 0) then begin
        lines[i] = strmid(lines[i], 0, pos) + '    ' + $
                   strmid(lines[i], pos+1, len)
        loc = pos + 1
      endif
    endrep until (pos eq -1)

  endfor

end                     ; at_remove_tabs

; -----------------------------------------------------------------------------
;
;  Purpose:  Display the appropriate text into the main table widget.
;
pro at_display_text, data, first=first

  compile_opt idl2, hidden

  if (keyword_set(first)) then begin

    num_lines = n_elements(*data.p_lines)
    rstr = strtrim(string(indgen(num_lines)+1),2)

    ;  remove any tabs
    if (total(byte(*data.p_lines) eq 9b) gt 0) then begin
      lines = *data.p_lines
      at_remove_tabs, lines
      lines = reform(lines, 1, num_lines, /overwrite)
    endif else $
      lines = reform(*data.p_lines, 1, num_lines)

    widget_control, data.tw[6], set_value=lines, row_labels=rstr
    widget_control, data.tw[6], $
      set_table_select=[0,data.data_start<(data.twm[1]-1), $
                        0,data.data_start<(data.twm[1]-1)]
  endif else begin

    num_lines = n_elements(*data.p_rlines)
    rstr = strtrim(string(indgen(num_lines)+1),2)
    if num_lines lt n_elements(*data.p_lines) then begin
      null_strings = replicate('', n_elements(*data.p_lines) - num_lines)
      rstr = [rstr, null_strings]
    end

    ;  remove any tabs
    if (total(byte(*data.p_rlines) eq 9b) gt 0) then begin
      lines = *data.p_rlines
      at_remove_tabs, lines
      lines = reform(lines, 1, num_lines, /overwrite)
    endif else begin
      lines = reform(*data.p_rlines, 1, num_lines)
    endelse

    widget_control, data.tw[6], set_table_view=[0,0], set_value=lines, $
      row_labels=rstr, set_table_select=[0,0,0,0]

  endelse

end                     ; at_display_text

; -----------------------------------------------------------------------------
;
;  Purpose:  Resize a given table widget to a new number of row / col cells.
;
pro at_resize_table, filename, tw, prev_size, new_size, cyclops_column_width, $
  text_table=text_table, last=last

  compile_opt idl2, hidden

; There are two different table widgets used in this widget. If the text_table
; keyword is set, then this refers to the table widget on the bottom which
; displays the text in STEP 1, the data in STEP 2 and a sample record in
; STEP 3. If not set, then this refers to the table wdiget in STEP 3 in the
; upper left corner which displays the field information.

  if (prev_size[0] eq new_size[0] and prev_size[1] eq new_size[1]) then return

  widget_control, tw, $
    table_xsize=new_size[0], table_ysize=new_size[1]

  if (keyword_set(text_table)) then begin
    ; the text table has a different look in STEP 3 than in STEP 1 & 2...
    ;
    if (keyword_set(last)) then begin
      widget_control, tw, column_widths=90
    endif else begin
      widget_control, tw, column_labels=[filename]
      widget_control, tw, column_widths=40, use_table_select=[-1, 0, -1, 0]
      widget_control, $
        tw, $
        column_widths=[cyclops_column_width], $
        use_table_select=[0, 0, 0, 0]
    endelse
  endif

end                     ; at_resize_table

; -----------------------------------------------------------------------------
;
;  Purpose:  Organize and display a sample record of n lines to demonstrate
;            how the current defined template interprets the ASCII file.
;
pro at_sample_record, data

  compile_opt idl2, hidden

  num_fields = *data.p_num_fields
  lines = (*data.p_rlines)[0:n_elements(num_fields)-1]

  new_twm = [max(num_fields), n_elements(num_fields)]

  at_resize_table, data.name, data.tw[6], data.twm, new_twm, /text_table, /last

  data.twm = new_twm
  str = strarr(new_twm[0], new_twm[1])
  fpos = 0

  ;  Loop for each field.
  ;
  for i=0, n_elements(num_fields)-1 do begin
    for j=0, num_fields[i]-1 do begin

      if (j eq num_fields[i]-1) then $        ; last field
        len = strlen(lines[i]) - (*data.p_fields)[fpos].loc $
      else $                                  ; not last field
        len = (*data.p_fields)[fpos+1].loc - (*data.p_fields)[fpos].loc; - 1

      str[j,i] = strtrim(strmid(lines[i], (*data.p_fields)[fpos].loc, len),2)
      fpos = fpos + 1
    endfor
  endfor

  widget_control, data.tw[6], set_value=str

end                     ; at_sample_record

; -----------------------------------------------------------------------------
;
;  Purpose:  Organize and display the field specifications into a table widget.
;
pro at_set_list, data, just_highlight=just_highlight

  compile_opt idl2, hidden

  groups = *data.p_groups

  ;  If NOT just highlighting...
  ;
  if (keyword_set(just_highlight) eq 0) then begin

    dstr = ['Skip', 'Byte', 'Integer', 'Long', 'Floating', 'Double', $
            'Complex', 'String']

    ;  Set new table widget size.
    ;
    new_tws = [ ([3,2])[data.mode], long(total(*data.p_num_fields)) ]
    at_resize_table, data.name, data.tw[8], data.tws, new_tws
    data.tws = new_tws

    ;  String array, set to [3,1] in at_widget.
    ;  [0,0] =
    ;  [1,0] =
    ;  [2,0] =
    ;
    str = strarr(data.tws[0], data.tws[1])
    gptr = 0

    ;  Loop for each group.
    ;
    for i=0, (n_elements(groups) < data.tws[1])-1 do begin

      if (i eq 0) then new_group = 1 $
      else             new_group = (groups[i] ne groups[i-1])

      ptr = where(groups eq groups[i], count)

      if (new_group) then begin
        gptr = i

        if (count eq 1) then str[0,i] = (*data.p_fields)[i].name $
        else                 str[0,i] = '{1} ' + (*data.p_fields)[i].name

        str[1,i] = dstr[(*data.p_fields)[i].type]

        if (data.mode eq 0) then $
          str[2,i] = strtrim(string((*data.p_fields)[i].loc),2)

      endif else begin

        str[0,i] = '{' + strtrim(string(i-gptr+1),2) + '}'

        if (data.mode eq 0) then $
          str[2,i] = strtrim(string((*data.p_fields)[i].loc),2)

      endelse

    endfor

    ;  Set column labels in main table widget.
    ;
    if (n_elements(*data.p_num_fields) eq 1) then $
      c_str = reform(str[0,*]) $
    else $
      c_str = strarr(data.twm[0]) + ' '
    widget_control, data.tw[6], column_label=c_str

    ;  Set value and row labels in upper-left table widget.
    ;
    rstr = strtrim(string(indgen(data.tws[1])+1),2)
    widget_control, data.tw[8], set_value=str, row_labels=rstr,  $
      alignment=0, column_labels=['Name','Data Type','Location']

  endif

  ;  Set table selection in upper-left table widget.
  ;
  widget_control, data.tw[8], set_table_select= $
    [0, data.lptr, data.tws[0]-1, data.lptr]

  ;  Set selection in main table widget corresponding to the field selected.
  ;
  lpos = at_which_field(*data.p_num_fields, data.lptr, col)
  widget_control, data.tw[6], set_table_select=[col,lpos,col,lpos]

  ;  Set sensitivity of Type droplist and Ungroup button.
  ;    (For Type, is sensitive if on the first entry of the group.)
  ;    (For Ungroup, is sensitive if on the first entry of the group,
  ;     and more than one entry in the group.)
  ;
  ptr = where(groups eq groups[data.lptr], count)
  widget_control, data.dl, sensitive=(ptr[0] eq data.lptr)
  widget_control, data.buts[14], sensitive=(ptr[0] eq data.lptr and count gt 1)

end                     ; at_set_list

; -----------------------------------------------------------------------------
;
;  Purpose:  Update the 3rd step page.
;
pro at_update, data, new_lptr, change=change, new=new

  compile_opt idl2, hidden

  if (n_elements(change) eq 0) then change = 0

  if (keyword_set(new) eq 0) then begin

    ;  Get Name.
    ;  Get Column number (used for Fixed Width data organization).
    ;
    widget_control, data.tw[4], get_value=name
    widget_control, data.tw[5], get_value=col

    ;  Check if name or column was changed.
    ;
    change = change or (name[0] ne (*data.p_fields)[data.lptr].name or $
                        long(col[0]) ne (*data.p_fields)[data.lptr].loc)

    (*data.p_fields)[data.lptr].name = name[0]
    (*data.p_fields)[data.lptr].loc = long(col[0])
  endif

  data.lptr = new_lptr

  ;  Update field table widget (just highlight if not changing values).
  ;
  at_set_list, data, just_highlight=(change eq 0)

  ;  Fill in Name in text widget.
  ;
  widget_control, data.tw[4], set_value=(*data.p_fields)[new_lptr].name

  ;  Set the Type droplist selection.
  ;
  widget_control, data.dl, set_droplist_select= $
    (*data.p_fields)[new_lptr].type

  ;  Set Column number (used for Fixed Width data organization).
  ;
  widget_control, data.tw[5], set_value= $
    strtrim(string((*data.p_fields)[new_lptr].loc),2)

end                     ; at_update

; -----------------------------------------------------------------------------
;
;  Purpose:  Handle events for third page of GUI.
;
pro at_3_event, ev

  compile_opt idl2, hidden

  widget_control, ev.id, get_uvalue=uvalue
  widget_control, ev.top, get_uvalue=data

  if (data.step ne 2) then return
  
  if (uvalue eq 'group') or (uvalue eq 'group all') then begin

    ;  (Return selection is in form [left, top, right, bottom].)
    ;
    sel = widget_info(data.tw[8], /table_select)
    if uvalue eq 'group all' then begin
        sel[1] = 0
        sel[3] = data.tws[1] - 1
    end

    if (sel[1] ne sel[3]) then begin
      types = (*data.p_fields)[sel[1]:sel[3]].type
      is_string = (total(types eq 7) gt 0)
      if (is_string) then $
        (*data.p_fields)[sel[1]:sel[3]].type = (7 * (types ne 0)) $
      else $
        (*data.p_fields)[sel[1]:sel[3]].type = (max(types) * (types ne 0))
      (*data.p_groups)[sel[1]:sel[3]] = (*data.p_groups)[sel[1]]
      at_update, data, data.lptr, /change, /new
    endif
  endif

  if (uvalue eq 'ungroup') then begin
    ptr = where(*data.p_groups eq (*data.p_groups)[data.lptr])
    (*data.p_groups)[ptr] = (indgen(n_elements(*data.p_fields)))[ptr]
    (*data.p_fields)[ptr].type = (*data.p_types)[ptr]
    at_set_list, data
  endif

  if (uvalue eq 'ungroup all') then begin
    *data.p_groups = indgen(n_elements(*data.p_fields))
    (*data.p_fields).type = *data.p_types
    at_set_list, data
  endif

  if (uvalue eq 'ltable') then begin
    ; if selection event...
    if (ev.type eq 4) then $
      if (ev.sel_top eq ev.sel_bottom and ev.sel_top ne -1) then $
        at_update, data, ev.sel_top
  endif

  if (uvalue eq 'table') then begin
    ; if selection event...
    if (ev.type eq 4) then $
      if (ev.sel_top eq ev.sel_bottom and ev.sel_top ne -1) then begin
        tot_num_fields = long(total(*data.p_num_fields))
        if (ev.sel_top eq 0) then add = 0 $
        else add = long(total((*data.p_num_fields)[0:ev.sel_top-1]))
        new_ptr = (ev.sel_left + add) < (tot_num_fields-1)
        at_update, data, new_ptr, /change
      endif
  endif

  if (uvalue eq 'list') then begin
    if (ev.index lt n_elements(*data.p_fields)) then $
      at_update, data, ev.index
  endif

  if (uvalue eq 'name') then begin

      ; If the text widget is only gaining keyboard focus, don't
      ; bother checking the name. Note that we need to do the check
      ; in 2 stages since the other text events don't have the ENTER tag.
      if (TAG_NAMES(ev, /STRUCT) eq 'WIDGET_KBRD_FOCUS') then $
        if (ev.enter eq 1) then goto, done

      widget_control, ev.id, get_value=name
      name = name[0]  ; convert 1-element array to scalar

      ; Verify that this is a valid structure tagname.
      ; Returns null string if it contains invalid characters.
      ; Converts spaces to underscores, but leaves lowercase.
      name = IDL_VALIDNAME(name, /CONVERT_SPACES)

      ; Valid name. See if the name is a duplicate of another field.
      if (name) then begin

        for i=0, N_ELEMENTS(*data.p_fields)-1 do begin

            ; Skip the current field.
            if (i eq data.lptr) then continue

            ; Check for duplicates. Use /FOLD_CASE because these are
            ; structure tagnames and cannot match, even if different case.
            if (STRCMP(name, (*data.p_fields)[i].name, /FOLD)) then begin
                name = ''   ; flag for reset
                break
            endif

        endfor

      endif

      ; Add the new name?
      if (name) then begin

          ; Don't use the /FOLD_CASE keyword here, because we want to change
          ; the fieldname even if just the upper/lowercase changed.
          if (not STRCMP(name, (*data.p_fields)[data.lptr].name)) then begin
            (*data.p_fields)[data.lptr].name = name[0]
            ; Update the widget in case we changed to uppercase.
            WIDGET_CONTROL, ev.id, SET_VALUE=name
            at_set_list, data
          endif

      endif else begin   ; not a valid variable

        ; Reset to the previous name.
          widget_control, ev.id, set_value=(*data.p_fields)[data.lptr].name
          widget_control, ev.id, set_text_select= $
            strlen((*data.p_fields)[data.lptr].name)

      endelse

  endif


  if (uvalue eq 'type') then begin
    ptr = where(*data.p_groups eq (*data.p_groups)[data.lptr], count)
    if (count eq 1) then begin
      (*data.p_fields)[data.lptr].type = ev.index
      (*data.p_types)[data.lptr] = ev.index
    endif else $
      (*data.p_fields)[ptr].type = (ev.index * ((*data.p_types)[ptr] ne 0))
    at_set_list, data
  endif

  if (uvalue eq 'location') then begin

    widget_control, ev.id, get_value=str
    (*data.p_fields)[data.lptr].loc = at_str_to_val(str)
    at_set_list, data

    ; Organize and display a sample record of n lines to demonstrate
    ; how the current defined template interprets the ASCII file.
    ;
    at_sample_record, data

  endif

done:
  widget_control, ev.top, set_uvalue=data

end                     ; at_3_event

; -----------------------------------------------------------------------------
;
;  Purpose:  Handle events for second page of GUI.
;
pro at_2_event, ev

  compile_opt idl2, hidden

  widget_control, ev.id, get_uvalue=uvalue
  widget_control, ev.top, get_uvalue=data

  if (uvalue eq 'user' or strmid(uvalue,0,7) eq 'delimit') then begin

    if (uvalue eq 'user') then type = 5 $
    else                       type = fix(strmid(uvalue,7,1))
    data.delimit = ([9,59,32,44,58,32])[type]
    widget_control, data.mb[5], sensitive=(type eq 5)
    if (type eq 5) then begin
      widget_control, data.tw[1], get_value=str
      data.delimit = (byte(strmid(str[0],0,1)))[0]
    endif

    ;  Get the number of fields/line for each line in a record.
    ;
    num_fields = at_num_fields(*data.p_rlines, data.delimit, data.comment)
    widget_control, data.tw[2], set_value=at_list_to_str(num_fields)
    *data.p_num_fields = temporary(num_fields)

    data.change = 1
  endif

  if (uvalue eq 'fields') then begin

    ;  Get the number of fields/line for each line in a record.
    ;
    widget_control, ev.id, get_value=str
    if (strtrim(strcompress(str[0]),2) eq '') then str = '1'
    *data.p_num_fields = at_str_to_list(str)

    data.change = 1
  endif

  if (strmid(uvalue,0,4) eq 'miss') then begin
    data.miss_type = fix(strmid(uvalue,4,1))
    widget_control, data.mb[4], sensitive=data.miss_type
  endif

  if (uvalue eq 'value') then begin
    type = TAG_NAMES(ev, /STRUCT)
    ; If user hits <Return> or widget loses keyboard focus,
    ; then check the value.
    if (type eq 'WIDGET_TEXT_CH' && ev.ch eq 10) || $
        (type eq 'WIDGET_KBRD_FOCUS' && ev.enter eq 0) then begin
        WIDGET_CONTROL, ev.id, get_value=str
        WIDGET_CONTROL, data.tw[0], $
            SET_VALUE=STRTRIM(at_str_to_val(str, /floating), 2)
    endif
  endif

  widget_control, ev.top, set_uvalue=data

end                     ; at_2_event

; -----------------------------------------------------------------------------
;
;  Purpose:  Handle events for first page of GUI.
;
pro at_1_event, ev

  compile_opt idl2, hidden

  widget_control, ev.id, get_uvalue=uvalue
  widget_control, ev.top, get_uvalue=data

  if (uvalue eq 'text') then begin

    if (ev.type le 2) then begin  ; ignore selection events
        widget_control, ev.id, get_value=str

        ; Subtract one because table widget is zero based.
        ds = at_str_to_val(str) - 1

        ; Empty string defaults to line=1
        if (str eq '') then ds = 0

        if (ds ge 0) or (str eq '') then begin
            ds = ds > 0
            if (ds ne data.data_start) then begin
              data.data_start = ds
              widget_control, data.tw[6], set_table_select= $
                [0,data.data_start<(data.twm[1]-1),0,data.data_start<(data.twm[1]-1)]
              data.change = 1
            endif
        endif else begin
            WIDGET_CONTROL, ev.id, SET_VALUE=STRTRIM(data.data_start + 1,2)
        endelse

    endif

  endif


  if (uvalue eq 'comment') then begin
    widget_control, ev.id, get_value=str
    data.comment = str[0]
    data.change = 1
  endif

  if (strmid(uvalue,0,4) eq 'mode') then begin
    data.mode = fix(strmid(uvalue,4,1))
    data.change = 1
  endif

  ;  Handle table events.
  ;
  if (uvalue eq 'table') then begin
    ; if selection event...
    if (ev.type eq 4) then $
      if (ev.sel_left eq 0) then begin
        widget_control, data.tw[7], set_value= $
        strtrim(string(ev.sel_top+1),2)
        data.change = 1
      endif

  ;  Handle "Next n Lines" button event.
  ;
  endif else if (uvalue eq 'next set') then begin
    widget_control, /hourglass
    last_pos = data.last_pos
    new_lines = at_get_lines(data.name, data.browseLines, $
      last_pos=last_pos, end_reached=end_reached)
    data.last_pos = last_pos
    data.end_reached = end_reached
    widget_control, data.mb[7], sensitive=(end_reached eq 0)
    if (n_elements(new_lines) gt 1 or new_lines[0] ne '') then begin
      *data.p_lines = [*data.p_lines, new_lines]
      widget_control, data.tw[6], insert_rows=n_elements(new_lines)
      at_display_text, data, /first
    endif
  endif

  widget_control, ev.top, set_uvalue=data

end                     ; at_1_event

; -----------------------------------------------------------------------------
;
;  Purpose:  Control the setting of the three progessive states of the
;            template definition (sets all of the widgets and pointers
;            involved and allows movement both forward and backward).
;
pro at_set_state, $
    data, $             ; IN:
    forward=forward, $  ; IN: (opt)
    back=back           ; IN: (opt) [currently not used]

  compile_opt idl2, hidden

  case (data.step) of

    ; ----------------------------------------
    0: begin        ; STEP 1
    ; ----------------------------------------

      WIDGET_CONTROL, WIDGET_INFO(data.base, FIND_BY_UNAME='Title'), $
          SET_VALUE=' ASCII Template Step 1 of 3: Define Data Type/Range'
      widget_control, data.buts[9], sensitive=0
      widget_control, data.buts[0], set_button=(data.mode eq 0)
      widget_control, data.buts[1], set_button=data.mode

      widget_control, data.buts[2], set_button=(data.miss_type eq 0)
      widget_control, data.buts[3], set_button=data.miss_type

      widget_control, data.mb[4], sensitive=data.miss_type

      widget_control, data.slab[2], map=0
      widget_control, data.slab[1], map=0
      widget_control, data.slab[0], map=1
      widget_control, data.mb[7], sensitive=(data.end_reached eq 0), map=1

      widget_control, data.tw[7], set_value= $
        strtrim(string(data.data_start+1),2)
      widget_control, data.tw[6], event_pro='at_1_event'
      at_display_text, data, /first

      data.change = 0

    end

    ; ----------------------------------------
    1: begin        ; STEP 2
    ; ----------------------------------------

      ;  Retreive the data_start value.
      ;
      widget_control, data.tw[7], get_value=str
      data.data_start =(at_str_to_val(str)-1) > 0

      ;  Retrieve the comment character.
      ;
      widget_control, data.tw[9], get_value=str
      data.comment = str[0]

      ;  Scan through lines and remove comments and blank lines for
      ;  steps two and three (after the start of the data).
      ;
      if (keyword_set(forward)) then begin
        lines = *data.p_lines
        rlines = strarr(n_elements(lines))
        count = 0
        for i=data.data_start, n_elements(lines)-1 do begin
          line = lines[i]
          if (data.comment ne '') then begin
            pos = strpos(line, data.comment)
            if (pos[0] ne -1) then line = strmid(line, 0, pos[0])
          endif
          if (strtrim(line,2) ne '') then begin
            rlines[count] = line
            count = count + 1
          endif
        endfor
        if (count gt 0) then  *data.p_rlines = rlines[0:count-1] $
        else                  *data.p_rlines = ['']
      endif

      widget_control, data.mb[3], map=data.mode
      widget_control, data.buts[9], sensitive=1
      widget_control, data.buts[10], SET_VALUE='Next >>', SET_UVALUE='next'
      widget_control, data.mb[7], map=0

      widget_control, data.slab[0], map=0
      widget_control, data.slab[2], map=0
      widget_control, data.slab[1], map=1

      if (keyword_set(forward)) then $
        data.delimit = at_default_delimit((*data.p_rlines)[0], data.comment)

      if (data.mode eq 1) then begin

        WIDGET_CONTROL, WIDGET_INFO(data.base, FIND_BY_UNAME='Title'), $
            SET_VALUE=' ASCII Template Step 2 of 3: Define Delimiter/Fields'

        user_defined = (total([59b,58b,32b,44b,9b] eq data.delimit) eq 0)
        if (user_defined) then tstr = string(data.delimit) $
        else                   tstr = ''
        widget_control, data.tw[1], set_value=tstr
        widget_control, data.mb[5], sensitive=user_defined
        widget_control, data.buts[5], set_button=(data.delimit eq 59b)
        widget_control, data.buts[6], set_button=(data.delimit eq 32b)
        widget_control, data.buts[7], set_button=(data.delimit eq 44b)
        widget_control, data.buts[11],set_button=(data.delimit eq 9b)
        widget_control, data.buts[16], set_button=(data.delimit eq 58b)
        widget_control, data.buts[8], set_button=user_defined
      endif else begin

        WIDGET_CONTROL, WIDGET_INFO(data.base, FIND_BY_UNAME='Title'), $
            SET_VALUE=' ASCII Template Step 2 of 3: Define Fields'

      endelse
      ;
      if ((keyword_set(forward) and data.change) or $
          n_elements(*data.p_num_fields) eq 0) then $
        num_fields = at_num_fields(*data.p_rlines, data.delimit,data.comment) $
      else begin
        num_fields = *data.p_num_fields
        new_twm = [1, n_elements(*data.p_lines)]
        at_resize_table, data.name, data.tw[6], data.twm, new_twm, /text_table, $
          data.cyclops_column_width
        data.twm = new_twm
      endelse
      ;
      widget_control, data.tw[2], set_value=at_list_to_str(num_fields)
      *data.p_num_fields = temporary(num_fields)
      ;
      widget_control, data.tw[6], event_pro='at_2_event'
      at_display_text, data
    end

    ; ----------------------------------------
    2: begin        ; STEP 3
    ; ----------------------------------------


      WIDGET_CONTROL, WIDGET_INFO(data.base, FIND_BY_UNAME='Title'), $
        SET_VALUE=' ASCII Template Step 3 of 3:  Field Specification'
      widget_control, data.buts[10], SET_VALUE='Finish', SET_UVALUE='finish'
      widget_control, data.mb[6], map=(data.mode eq 0)
      widget_control, data.slab[0], map=0
      widget_control, data.slab[1], map=0
      widget_control, data.slab[2], map=1

      if (data.miss_type eq 0) then $
        miss_value = !values.f_nan $
      else begin
        widget_control, data.tw[0], get_value=str
        miss_value = at_str_to_val(str)
      endelse

      if (n_elements(*data.p_template) eq 0) or data.change then begin

        ;  Build new template.
        ;  Delete previous template.
        ;  Save new template
        ;
        template = at_build_template(data, miss_value)
        at_delete_template, *data.p_template
        *data.p_template = temporary(template)

        ;  Assign a copy of pointers from the template to the data structure
        ;  for simpler access.
        ;
        data.p_fields = (*data.p_template).p_fields
        data.p_groups = (*data.p_template).p_groups
        *data.p_types = (*data.p_fields).type
      endif
      data.change = 0

        if (data.miss_type eq 0) then $
            (*data.p_template).missing_value = !values.f_nan $
        else begin
            widget_control, data.tw[0], get_value=str
            (*data.p_template).missing_value = at_str_to_val(str, /floating)
            widget_control, data.tw[0], $
                SET_VALUE=STRTRIM((*data.p_template).missing_value, 2)
        endelse

      ;  Organize and display a sample record of n lines to demonstrate
      ;  how the current defined template interprets the ASCII file.
      ;
      at_sample_record, data

      widget_control, data.tw[6], event_pro='at_3_event'
      data.lptr = 0
      at_update, data, data.lptr, /change, /new
    end

  endcase

end                     ; at_set_state

; -----------------------------------------------------------------------------
;
;  Purpose:
;
pro at_widget_cleanup, base

  compile_opt idl2, hidden

  widget_control, base, get_uvalue=data, /no_copy
  widget_control, base, /destroy
  if (n_elements(data) eq 0) then return

  ptr_free, data.p_lines
  ptr_free, data.p_rlines
  ptr_free, data.p_num_fields
  ptr_free, data.p_template
  ptr_free, data.p_types

end                     ; at_widget_cleanup

; -----------------------------------------------------------------------------
;
;  Purpose:  Handle the buttons at the bottom of the dialog.
;
pro at_widget_event, ev

  compile_opt idl2, hidden

  if (tag_names(ev,/struct) eq 'WIDGET_KILL_REQUEST') then begin
    at_widget_cleanup, ev.top
    return
  endif

  widget_control, ev.id, get_uvalue=uvalue
  widget_control, ev.top, get_uvalue=data

  if (uvalue eq 'next') then begin
    widget_control, data.mb[data.step], map=0
    data.step = data.step + 1
    widget_control, data.mb[data.step], map=1
    at_set_state, data, /forward
  endif

  if (uvalue eq 'back') then begin
    widget_control, data.mb[data.step], map=0
    data.step = data.step - 1
    widget_control, data.mb[data.step], map=1
    at_set_state, data, /back
  endif

  if (uvalue eq 'finish') then begin
    *data.p_result = {accept:1, template:*data.p_template}
    widget_control, ev.top, set_uvalue=data, /no_copy
    at_widget_cleanup, ev.top
    return
  endif

  if (uvalue eq 'help') then begin
     ONLINE_HELP, 'ASCII_TEMPLATE'
  endif

  if (uvalue eq 'cancel') then begin
    at_delete_template, *data.p_template
    widget_control, ev.top, set_uvalue=data, /no_copy
    at_widget_cleanup, ev.top
    return
  endif

  if (uvalue eq 'wbopen') then begin
    at_delete_template, *data.p_template
    ;; callback on the workbench to open the file in the default text editor
    void = IDLNotify('IDLOpenFile', data.name, "default")
    widget_control, ev.top, set_uvalue=data, /no_copy
    at_widget_cleanup, ev.top
    return
  endif

  widget_control, ev.top, set_uvalue=data, /no_copy

end                     ; at_widget_event

; -----------------------------------------------------------------------------
;
;  Purpose:  Create the widgets.
;
function at_widget, $
    name, $                    ; IN:
    GROUP=group, $             ; IN: (opt)
    CANCEL=cancel, $           ; OUT:
    WBOPEN=wbopen, $           ; IN: (opt)
    BROWSE_LINES=browseLines   ; IN:

  compile_opt idl2, hidden

  ;  Set number of lines for browse button.
  ;
  if (N_ELEMENTS(browseLines) ne 0) then browseLinesUse = browseLines $
  else                                   browseLinesUse = 50

  ;  Check out the size of the screen and adjust the widget acordingly.
  ;
  switch !D.NAME of
    'MAC':
    'X':
    'WIN': DEVICE, GET_SCREEN_SIZE=screen_size
  endswitch

  table_scr_ysize = ([110,185])[screen_size[1] gt 600]
  xoff = ((screen_size[0] - 600) / 2) > 0
  yoff = ((screen_size[1] - 600) / 2) > 0

  dt_str = ['Skip Field', 'Byte', 'Integer', 'Long Integer', $
    'Floating Point', 'Double Precision', 'Complex', 'String']

  lines = at_get_lines(name, browseLinesUse, last_pos=last_pos, $
    end_reached=end_reached)

  buts = lonarr(17)
  tw = lonarr(10)
  mb = lonarr(8)

  ;  Create a group if one wasn't specified.
  ;
  if (N_ELEMENTS(group) eq 0) then begin
        group = widget_base(map=0)
        groupCreated = 1B
  endif else $
        groupCreated = 0B
  base = widget_base(title='ASCII Template [' + FILE_BASENAME(name) + ']', $
    /column, xoff=xoff, yoff=yoff, $
    /modal, group=group, /tlb_frame_attr, space=1, /TAB_MODE)
  font = (!version.os_family eq 'Windows') ? 'Helvetica*24' : 'helvr14'
  lab  = widget_label(base, /align_left, $
    FONT=font, $
    uname = 'Title', $
    value=' ASCII Template Step 1 of 3: Define Data Type/Range')

  sb   = widget_base(base, /column, ypad=0)
  mbs  = widget_base(sb)

  ; -----------------------------------------------
  ;  STEP 1 of 3: Define Data Type / Range
  ; -----------------------------------------------

  mb[0]= widget_base(mbs, /column, event_pro='at_1_event')
  sb   = widget_base(mb[0], /column, ypad=10)

  lab  = widget_label(sb, /align_left, $
    value='First choose the field type which best describes your data:')
  lab  = widget_label(sb, value='')
  sb1  = widget_base(sb, /column, /exclusive, space=0)
  buts[0]= widget_button(sb1, /no_release, uvalue='mode0', $
    value=' Fixed Width  (fields are aligned in columns)')
  buts[1]= widget_button(sb1, /no_release, uvalue='mode1', $
    value=' Delimited  (fields are separated by commas, whitespace, etc.)')

  sb   = widget_base(mb[0], /row)
  lab  = widget_label(sb, value=' Comment String to Ignore:  ')
  tw[9]= widget_text(sb, xs=10, ys=1, /edit, frame=0, /all_events, $
    uvalue='comment')

  sb   = widget_base(mb[0], /row)
  lab  = widget_label(sb, value=' Data Starts at Line:  ')
  tw[7]= widget_text(sb, xs=5, ys=1, /edit, frame=0, /all_events, $
    uvalue='text')

  ; -----------------------------------------------
  ;  STEP 2 of 3: Define Delimiter / Fields
  ; -----------------------------------------------

  mb[1]= widget_base(mbs, /column, map=0, event_pro='at_2_event')
  sb   = widget_base(mb[1], /column, ypad=10)
  sb1  = widget_base(sb, /row)
  lab = widget_label(sb1, value='Number of Fields Per Line:  ')
  tw[2]= widget_text(sb1, xs=10, ys=1, /edit, /all_events, $
    uvalue='fields')

  mb[3]= widget_base(mb[1], /column)
  lab  = widget_label(mb[3], /ALIGN_LEFT, $
    value='Delimiter Between Data Elements:')
  sb1  = widget_base(mb[3], /row)
  sb2  = widget_base(sb1, column=3, /exclusive, space=0, ypad=0)
  mb[5]= widget_base(sb1, /row, /align_bottom)
  tw[1]= widget_text(mb[5], xs=2, ys=1, /edit, frame=0, $
    /all_events, uvalue='user')
  buts[6] = widget_button(sb2, value='White Space', uvalue='delimit2', /no_rel)
  buts[7] = widget_button(sb2, value='Comma',       uvalue='delimit3', /no_rel)
  buts[16]= widget_button(sb2, value='Colon',       uvalue='delimit4', /no_rel)
  buts[5] = widget_button(sb2, value='Semicolon',   uvalue='delimit1', /no_rel)
  buts[11]= widget_button(sb2, value='Tab',         uvalue='delimit0', /no_rel)
  buts[8] = widget_button(sb2, value='Other:',      uvalue='delimit5', /no_rel)

  sb   = widget_base(mb[1], /row, ypad=0)
  lab  = widget_label(sb, value=' Value to Assign to Missing Data:  ')
  sb1  = widget_base(sb, /row, ypad=0)
  sb2  = widget_base(sb1, /row, /exclusive, ypad=0)
  buts[2]= widget_button(sb2, value='IEEE NaN ', /no_rel, uvalue='miss0')
  buts[3]= widget_button(sb2, value='', /no_rel, uvalue='miss1')
  mb[4]  = widget_base(sb1, /row)
  tw[0]= widget_text(mb[4], xs=7, ys=1, frame=0, /edit, /all_events, $
    /KBRD_FOCUS_EVENTS, $
    uvalue='value')

  ; -----------------------------------------------
  ;  STEP 3 of 3: Field Specifications
  ; -----------------------------------------------

  mb[2]= widget_base(mbs, /column, map=0, event_pro='at_3_event')
  sb   = widget_base(mb[2], column=2)

  ;  Field information table widget (upper-left).
  ;
  sb1  = widget_base(sb, /column)
  tw[8]= widget_table(sb1, value=strarr(3,1), alignment=0, scr_xsize=275, $
    scr_ysize=120, uvalue='ltable', $
    column_labels=['Name','Data Type','Location'], /ALL_EVENTS, /SCROLL, $
    /RESIZEABLE_COLUMNS)

  sb1  = widget_base(sb, /column)
  sb2  = widget_base(sb1, /row)
  lab  = widget_label(sb2, value='Name:  ')
  tw[4]= widget_text(sb2, xs=18, ys=1, frame=0, $
    /EDITABLE, /KBRD_FOCUS_EVENTS, $
    uvalue='name')
  sb2  = widget_base(sb1, /row)
  dl   = widget_droplist(sb2, Title='Type:  ', value=dt_str, uvalue='type')

  ; ("Column" is used for Fixed Width data organization.)
  mb[6]= widget_base(sb1, /row)
  lab  = widget_label(mb[6], value='Column:  ')
  tw[5]= widget_text(mb[6], xs=3, ys=1, frame=0, /edit, /all_events, $
    uvalue='location')

  sb2  = widget_base(mb[2], col=4, /grid)
  but  = widget_button(sb2, value='Group', uvalue='group')
  but  = widget_button(sb2, value='Group All', uvalue='group all')
  buts[14] = widget_button(sb2, value='UnGroup', uvalue='ungroup')
  but  = widget_button(sb2, value='Ungroup All', uvalue='ungroup all')

  ; -----------------------------------------------

  ; general text widget and <back, next> buttons
  ;
  sb   = widget_base(base, /column, ypad=0)
  sb1  = widget_base(sb, /row, /base_align_bottom, ypad=0)
  stacker_base = widget_base(sb1)
  slab = [ $
    widget_base(stacker_base), $
    widget_base(stacker_base), $
    widget_base(stacker_base) $
    ]
  void = widget_label(slab[0], value='Selected Text File:')
  void = widget_label(slab[1], value='Selected Records:')
  void = widget_label(slab[2], value='Sample Record:')

  mb[7]= widget_base(sb1, /row, ypad=0, xpad=150)
  widget_control, mb[7], sensitive=(end_reached eq 0)

  value = 'Get next ' + STRTRIM(STRING(browseLinesUse),2) + ' lines...'
  but  = widget_button(mb[7], value=value, uvalue='next set', $
    event_pro='at_1_event')
  str  = strarr(1,n_elements(lines))
  tw[6]= widget_table(sb, value=str, alignment=0, $
    scr_xsize= 582, $ ; determined empirically.
    scr_ysize=table_scr_ysize, uvalue='table', column_labels=[name], $
    font='courier*12', $
    /ALL_EVENTS, /SCROLL, /RESIZEABLE_COLUMNS)


  sb   = widget_base(base, /row)
  sb1  = widget_base(sb, /row)
  sb_space = widget_base(sb, /row)
  sb2  = widget_base(sb, /row)
  
  but = widget_button(sb1, value=' Help ', uvalue='help')
  
 ; spacer = widget_base(sb1, xsize=50)
  
  ; add "Open in Editor" button if the keyword flag is set
  if (N_ELEMENTS(wbopen) ne 0) then begin
    b = widget_button(sb1, value=' Open in Editor ', uvalue='wbopen')
  endif
  
   
  but  = widget_button(sb2, value=' Cancel ', uvalue='cancel')
  buts[9] = widget_button(sb2, value=' << Back ', uvalue='back')
  buts[10]= widget_button(sb2, value=' Next >> ', uvalue='next')
  
  sb_geom = widget_info(base, /geometry)
  sb1_geom = widget_info(sb1, /geometry)
  sb2_geom = widget_info(sb2, /geometry)
  
  sb_space_width = sb_geom.xsize - sb1_geom.xsize - sb2_geom.xsize - (sb_geom.xpad * 6)
  
  widget_control, sb_space, xsize=sb_space_width

  widget_control, base, /realize
  widget_control, /update, base ; fixes size idiosyncrasies on Windows95

; Do all table resizing after /realize so it works correctly on Mac
  widget_control, tw[8], column_widths=[25], use_table_select=[-1,0,-1,0]
  widget_control, tw[8], column_widths=[75,75,75]

  widget_control, tw[6], column_widths=[40],  use_table_select=[-1, 0, -1, 0]

  ;  Set a column width to be used in the first two pages of the wizard.
  ;  This hardcoded width was determined by trial and error.  The
  ;  Non-mac value may be seen to leave a gap at the right of the
  ;  column.  (In other words the column may be a bit smaller than
  ;  the width of the table.)  This is due to the various font sizes
  ;  available on Windows (via e.g. Windows95's Display properties
  ;  "settings").  On Windows95 and AlphaNT machines (and thus
  ;  probably regular NT too), differing font sizes have been seen
  ;  to effect the size of the column with respect to the size of
  ;  the table.  Thus we choose a column width small enough to
  ;  accomodate large fonts.  Since this will leave a gap in
  ;  many cases, we choose a width that is additionally small
  ;  enough to leave a gap that is aesthetically pleasing in size.
  ;  The added, "aesthetic" amount of gap also serves as a bit
  ;  of insurance that the column will fit in the table in
  ;  unforseen font/size/platform situations.
  ;
  cyclops_column_width = 500

  widget_control, $
    tw[6], $
    column_widths=[cyclops_column_width], $
    use_table_select=[0, 0, 0, 0]


  widget_control, tw[8], /input_focus

  p_result = ptr_new({accept:0})

  ;  Set up widget state information.
  ;
  data = { $
    base: base, $
    mb: mb, $
    tw: tw, $
    buts: buts, $
    dl: dl, $
    step: 0, $
    name: name, $
    p_lines: ptr_new(lines), $
    p_rlines: ptr_new(/allocate_heap), $
    p_num_fields: ptr_new(/allocate_heap), $
    p_template: ptr_new(/allocate_heap), $
    p_types: ptr_new(/allocate_heap), $
    p_fields: ptr_new(), $
    p_groups: ptr_new(), $
    p_result: p_result, $
    mode: 1, $
    data_start: 0L, $
    lptr: 0, $
    delimit: 32b, $
    miss_type: 0, $
    last_pos: last_pos, $
    change: 1, $
    end_reached: end_reached, $
    comment: '', $
    twm: [1,n_elements(lines)], $
    tws: [3,1], $
    cyclops_column_width: cyclops_column_width, $
    slab: slab, $
    browseLines: browseLinesUse $
    }

  at_set_state, data
  widget_control, base, set_uvalue=data, /no_copy
  xmanager, 'at_widget', base

  if (groupCreated) then $
        widget_control, group, /destroy

  cancel = ((*p_result).accept eq 0)
  if ((*p_result).accept) then template = (*p_result).template $
  else                         template = 0
  ptr_free, p_result
  return, template

end                     ; at_widget

; -----------------------------------------------------------------------------
;
;  Purpose: Check that the input filename is a string, exists, and appears
;           to be ASCII...
;
function at_check_file, fname

  compile_opt idl2, hidden

  if (SIZE(fname, /TYPE) ne 7) then $
    return, -1 ; filename isn't a string

  info = FILE_INFO(fname)
  if (~info.exists) then $
    return, -2
  if (~info.read) then $
    return, -3

  success = QUERY_ASCII(fname)
  return, success ? 1 : -4

end                     ; at_check_file

; -----------------------------------------------------------------------------
;
;  Purpose:  The main routine.
;
function ascii_template, $
    file, $                     ; IN: (opt)
    BROWSE_LINES=browseLines, $ ; IN: (opt)
    GROUP=group, $              ; IN: (opt)
    CANCEL=cancel, $            ; OUT: (opt)
    _EXTRA=extra                ; 

  ;  Set to return to caller on error.
  ;
  ON_ERROR, 2
;  ON_ERROR, 0

  ;  Set some defaults.
  ;
  cancel = 0

  ;  Set number of lines for browse button.
  ;
  if (N_ELEMENTS(browseLines) ne 0) then browseLinesUse = browseLines $
                                    else browseLinesUse = 50

  ;  If no file specified, use DIALOG_PICKFILE.
  ;
  if (n_elements(file) eq 0) then begin
    file = DIALOG_PICKFILE(/MUST_EXIST, GROUP=group)
    if (file eq '') then begin
        cancel = 1b
        RETURN, 0
    endif
  endif

  ; check that the file is readable and appears to be ASCII
  ;
  ret = at_check_file(file)
  case ret of
    -1: MESSAGE, 'File name must be a string.'
    -2: MESSAGE, 'File "' + file + '" not found.'
    -3: MESSAGE, 'Error Reading from file "' + file + '"
    -4: MESSAGE, 'File "' + file + '" is not a  valid ASCII file.'
    else:
  endcase

  ;  Put up the GUI.
  ;
  templateWithPtrs = $
    at_widget(file, cancel=cancel, BROWSE_LINES=browseLinesUse, GROUP=group, _EXTRA=extra)

  ;  If user canceled, return 0.
  ;
  if (cancel) then RETURN, 0

  ;  Restructure template to eliminate pointers and return it.
  ;  (Include a version number for easier processing if modify
  ;  the template definition later.)
  ;
  template = { $
    version:            1.0, $
    dataStart:          templateWithPtrs.record_start_loc, $
    delimiter:          templateWithPtrs.delimit, $
    missingValue:       templateWithPtrs.missing_value, $
    commentSymbol:      templateWithPtrs.comment_symbol, $
    fieldCount:         *templateWithPtrs.p_num_fields, $
    fieldTypes:         (*templateWithPtrs.p_fields).type, $
    fieldNames:         (*templateWithPtrs.p_fields).name, $
    fieldLocations:     (*templateWithPtrs.p_fields).loc, $
    fieldGroups:        *templateWithPtrs.p_groups $
    }
  at_delete_template, templateWithPtrs
  RETURN, template

end                     ; ascii_template

; -----------------------------------------------------------------------------

