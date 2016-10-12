;---------------------------------------------------------------------------
; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/create_cursor.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
;+
; Create_Cursor
;
; Purpose:
;   Given a string array representing a 16x16 window cursor, this
;   function returns an Image array (a vector of 16 long integers).
;
;   Using keywords, you can optionally return
;   a Mask array (16x16 byte), and a 2-element Hotspot vector.
;
;   These can then be passed to IDLgrWindow::SetCurrentCursor.
;
; Example:
;    strArray = [ $
;        '       .        ', $
;        '      .#.       ', $
;        '     .##..      ', $
;        '    .$####.     ', $
;        '     .##..#.    ', $
;        '      .#. .#.   ', $
;        '       .   .#.  ', $
;        '  .        .#.  ', $
;        ' .#.       .#.  ', $
;        ' .#.       .#.  ', $
;        ' .#.       .#.  ', $
;        '  .#.     .#.   ', $
;        '   .#.....#.    ', $
;        '    .#####.     ', $
;        '     .....      ', $
;        '                ']
;
;    The "image" consists of the # or $ character.
;    The "hotspot" is a 2-element vector giving the location
;    of the $ character. If there is no '$' then [0,0] is returned.
;    The "mask" consists of any non-space characters.
;
;    image = CREATE_CURSOR(strArray, HOTSPOT=hotspot, MASK=mask)
;    oWin->SetCurrentCursor, IMAGE=image, HOTSPOT=hotspot, MASK=mask
;-
function Create_Cursor, strArray, $
    HOTSPOT=hotspot, MASK=mask

    compile_opt idl2, hidden

    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'

    str = STRLEN(strArray)
    mn = MIN(str, MAX=mx)
    if ((N_ELEMENTS(strArray) ne 16) or (mn ne 16) or (mx ne 16)) then $
        MESSAGE, 'Input must be a 16-element string array, each of length 16.'

    ; Flip upside down.
    image = REVERSE(strArray)

    ; Convert from string vector to string array.
    image = STRING(REFORM(BYTE(image), 1, 16, 16))

    if (ARG_PRESENT(hotspot)) then begin
        ; Find the hotspot location.
        hotspot = MIN(WHERE(image eq '$'))
        ; Convert hotspot vector index to array index.
        hotspot = (hotspot eq -1) ? [0,0] : $
            [hotspot mod 16, hotspot/16]
    endif

    if (ARG_PRESENT(mask)) then begin
        mask = image ne ' '
        mask = CVTTOBM(mask, THRESHOLD=1)
        mask = 256L*mask[0,*] + mask[1,*]
    endif

    ; Convert from string array to integer bit pattern.
    image = (image eq '#') or (image eq '$')
    image = CVTTOBM(image, THRESHOLD=1)
    image = 256L*image[0,*] + image[1,*]

    return, image

end



