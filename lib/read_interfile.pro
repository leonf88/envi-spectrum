; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_interfile.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   READ_INTERFILE
;
; PURPOSE:
;   Simplistic Interfile (v3.3) reader. Can only read a series
;   of images containing byte,int,long,float or double data where
;   all images have the same height and with.  Result is returned
;   in a 3-D array.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   READ_INTERFILE, File, Data
;
; INPUTS:
;   File: Scalar string containing the name of the Interfile
;     to read.  Note: if the Interfile has a header file and
;     a data file, this should be the name of the header
;     file (also called the administrative file).
;
; OUTPUTS:
;   Data: A 3-D array of data as read from the file.  Assumed to be
;   a series of 2-D images.
;
; RESTRICTIONS:
;   This is a simplistic reader.  It does not get additional
;   keyword information above and beyond what is needed to read
;   in the image data.  If any problems occur reading the file,
;   READ_INTERFILE prints a message and stops.
;
;   If the data is stored in on a bigendian machine and read on
;   a littleendian machine (or vice versa) the order of bytes in
;   each pixel element may be reversed, requiring a call to
;   BYTEORDER
;
; PROCEDURE:
;   Generates keyword table and initializes it on the fly.
;   Read in administrative data.
;   Read in binary data.
;   Clean up keyword processing information.
;
; EXAMPLE:
;   READ_INTERFILE, '0_11.hdr', X
;
; MODIFICATION HISTORY:
;   Written by:  J. Goldstein, Oct 1993
;
;   12/22/93 JWG,TH     Bug fixes. Added byte swapping for short data
;       10/29/97 RJF       Patched to handle the case of image data in
;          the header file itself.
;   1/7/04 SBS       Modify to avoid use of EXECUTE function for IDL VM
;-

;
;  GetPath
;
FUNCTION GetPath, File, PATH=DoPath, FILE=DoFile
    COMPILE_OPT hidden

    Idx = WHERE(!Version.OS EQ [ "vms", "Win32", "MacOS" ])
    Idx = Idx[0] + 1
       ;   Unix, VMS, WIN, MAC
    First   = ([ '/', ']', '\', ':'])[Idx]
    Second  = ([ '',  ':', ':', ''])[Idx]

    FileStart   = STRPOS(File, First, /REVERSE_SEARCH)+1
    IF FileStart EQ 0 AND Second NE '' THEN $
    FileStart = STRPOS(File,Second, /REVERSE_SEARCH)+1

    IF KEYWORD_SET(DoFile) THEN $
    RETURN, STRMID(File, FileStart, 1000)
    RETURN, STRMID(File,0,FileStart)
END

;
;  Inter_MakeInfo
;   Create keyword table entries.  Create hetergenous data by
;   EXECUTE'ing initialization strings and storing the results
;   in unrealized base widget UVALUE's.  This may seem confusing.
;   It probably is.
;
PRO Inter_MakeInfo, Info, Filename
    COMPILE_OPT hidden

;Here is the meaning of the info structure entries:
;    a(0) Keyword:   "",   $
;    b(1) Value:     0L,    $  ; Use UVALUE to hold current value
;    c(2) Default:   "",   $ ; EXECUTE this to create initial value
;    d(3) Handler:   "",   $ ; Generic keyword processor
;    e(4) Choices:   0L,   $ ; If limited set of choices, these
;    f(5) ChoiceInit:    "",    $  ; are them
;    g(6) IsArray:   0,    $  ; keyword requires indexing?
;    h(7) Proc:   ""  $    ; Special per keyword processing


    ;   These are the currently supported keywords.

    DefaultDataFile = GetPath(Filename, /FILE)

    ;   To avoid use of EXECUTE, use a single structure:
    Info    = { $
    a1:"data starting block",  b1:0L, c1:0L, d1:"INT", e1:0L, f1:"", g1:0, h1:"" , $
    a2:"data offset in bytes", b2:0L, c2:0L, d2:"INT", e2:0L, f2:"", g2:0, h2:"" , $
    a3:"data compression", b3:0L, c3:"none", d3:"STR", e3:0L, f3:"none", g3:0, h3:"" , $
    a4:"data encode", b4:0L, c4:"none", d4:"STR", e4:0L, f4:"none", g4:0, h4:"" , $
    a5:"imagedata byte order", b5:0L, c5:"bigendian", d5:"STR", e5:0L, $
        f5:['bigendian','littleendian'], g5:0, h5:"" , $
    a6:"matrix size", b6:0L, c6:[0L,0L], d6:"INT", e6:0L, f6:"", g6:1, h6:"Inter_Fixed" , $
    a7:"name of data file", b7:0L, c7:"'"+DefaultDataFile+"'", d7:"STR", e7:0L, f7:"", g7:0, h7:"" , $
    a8:"number format", b8:0L, c8:"unsigned integer", d8:"STR", e8:0L, f8:['signed integer','unsigned integer', + $
         'long float','short float','bit'], g8:0, h8:"" , $
    a9:"number of bytes per pixel", b9:0L, c9:0L,d9:"INT",e9:0L, f9:"", g9:0, h9:"" , $
    a10:"total number of images", b10:0L, c10:0L, d10:"INT", e10:0L, f10:"", g10:0, h10:"" }

    ;   Run through keywords and create initial values
    ;   and choice values if keyword has a limited set of choices
    FOR I=0,FIX(N_TAGS(Info)/8)-1 DO BEGIN

    ;  Create value

    Info.(I*8+1)  = WIDGET_BASE();value
    WIDGET_CONTROL, Info.(I*8+1), SET_UVALUE=Info.(I*8+2);default

    ;  Create choices if they exist

    IF (Info.(I*8+5))[0] NE "" THEN BEGIN;ChoiceInit
        Info.(I*8+4)    = WIDGET_BASE();Choices
        WIDGET_CONTROL, Info.(I*8+4), SET_UVALUE=Info.(I*8+5);ChoiceInit
    ENDIF

    ENDFOR
END

;
;  Inter_INT
;   General integer keyword processing routine
;
PRO Inter_INT, KwdInfo, Value, Arr
    COMPILE_OPT hidden

    Value   = LONG(Value)

    ;   limited # of chioces?  See if user has chosen a valid chioce

    IF KwdInfo.(4) NE 0 THEN BEGIN;Choices
    WIDGET_CONTROL, KwdInfo.(4), GET_UVALUE=Choices
    Dummy  = WHERE(Value EQ Choices, Count)
    IF Count NE 1 THEN $
        MESSAGE, 'Illegal choice of values for ' + KwdInfo.(0)
    ENDIF

    IF KwdInfo.(7) THEN BEGIN  ; PROC   Special keyword routine?

    CALL_PROCEDURE, KwdInfo.(7), KwdInfo, Value, Arr

    ENDIF ELSE BEGIN       ; General processing
    IF KwdInfo.(6) THEN BEGIN;ISARRAY
        WIDGET_CONTROL, KwdInfo.(1), GET_UVALUE=Vals;VALUE
        Vals[Arr-1]    = Value
    ENDIF ELSE BEGIN
        Vals   = Value
    ENDELSE

        WIDGET_CONTROL, KwdInfo.(1), SET_UVALUE=Vals
    ENDELSE
END


;
;  Inter_STR
;   General string keyword processing routine
;
PRO Inter_STR, KwdInfo, Value, Arr
    COMPILE_OPT hidden

    ;   Hack. I've seen people use Keyword:=
    ;   Perhaps I should just add '' to the list of valid values.

    IF kwdinfo.(0) EQ 'name of data file'  AND Value EQ '' THEN BEGIN;KEYWORD
            ; in the case of the 'name of data file' keyword being null,
            ; use the header filename instead.
        Strlgth=STRLEN(kwdinfo.(2));DEFAULT
        Value=STRMID(kwdinfo.(2), 1, (Strlgth-2))
    ENDIF ELSE IF Value EQ '' THEN VALUE = 'none'

    IF KwdInfo.(4) NE 0 THEN BEGIN;CHOICES
        WIDGET_CONTROL, KwdInfo.(4), GET_UVALUE=Choices
        Value  = STRLOWCASE(Value)
        Dummy  = WHERE(Value EQ Choices, Count)
        IF Count NE 1 THEN $
            MESSAGE, 'Illegal choice of values for ' + KwdInfo.(0);KEYWORD
        ENDIF

        IF KwdInfo.(7) THEN BEGIN;PROC

        CALL_PROCEDURE, KwdInfo.(7), KwdInfo, Value, Arr

    ENDIF ELSE BEGIN
        IF KwdInfo.(6) THEN BEGIN;ISARRAY
            WIDGET_CONTROL, KwdInfo.(1), GET_UVALUE=Vals;VALUE
            Vals[Arr-1]    = Value
        ENDIF ELSE BEGIN
            Vals     = Value
        ENDELSE

        WIDGET_CONTROL, KwdInfo.(1), SET_UVALUE=Vals
    ENDELSE
END


;
;  Inter_Fixed
;   Routine to tell user that this is a simple reader.
;   If the size of a keyword element has been changed
;   and it wasn't 0 before, tell user we give up.
;
;   This is for :matrix size: because we don't handle images
;   of different sizes.
;
PRO Inter_Fixed, KwdInfo, Value, Arr
    COMPILE_OPT hidden

    WIDGET_CONTROL, KwdInfo.(1), GET_UVALUE=Vals;VALUE
    IF KwdInfo.(6) THEN Val = Vals[Arr-1] $;ISARRAY
    ELSE Val = Vals

    IF Val EQ 0 THEN BEGIN

        IF KwdInfo.(6) THEN Vals[Arr-1] = Value $
        ELSE Vals = Value
        WIDGET_CONTROL, KwdInfo.(1), SET_UVALUE=Vals

    ENDIF ELSE IF Value NE Val THEN BEGIN

        MESSAGE, "Support of Interfiles where " + KwdInfo.(0) + $;KEYWORD
           " changes is not currently supported"

    ENDIF
END


;
;  Inter_ReadHdr
;   Wade through administrative data looking for the keywords
;   we understand.  Quietly ignore any keywords not in the Info
;   list. This should provide enough information to either
;   read the data or realize we can't read the data.
;
;   N.B. STRMID(Str,Start, 255) will return the remainder of a
;   string as long as that string is less than 255 characters long --
;   which the Interfile 3.3 spec guarantees
;
PRO Inter_ReadHdr, Unit, Info
    COMPILE_OPT hidden

    ;   Parse lines until
    Line    = ""
    WHILE NOT EOF(Unit) DO BEGIN
    READF, Unit, Line       ; Read in line of text

    ;  Remove leading/trailing whitespace (blech)
    BLine   = BYTE(Line)
    Idx       = WHERE(Bline EQ 13b OR Bline EQ 10b, Count)
    IF Count GT 0 THEN Bline[Idx] = 32b
    Line     = STRTRIM(BLine,2)

    IF Line EQ '' THEN GOTO, Continue  ; ignore blank lines

    FirstChar  = STRMID(Line,0,1)   ; ';' is comment character
    IF FirstChar EQ ";" THEN GOTO, Continue

    ;  Find full Keyword
    KeyStart   = FirstChar EQ "!"
    KeyEnd     = STRPOS(Line, ":=")
    Kwd       = STRMID(Line, KeyStart,KeyEnd-KeyStart)

    ;  Look for array index
    ArrStart   = STRPOS(Kwd, "[")
    IF ArrStart NE -1 THEN BEGIN
       Arr   = FIX( STRMID(Kwd,ArrStart+1, 255))
       Kwd   = STRMID(Kwd, 0, ArrStart)
    ENDIF ELSE BEGIN
       Arr   = 0
    ENDELSE

    Kwd       = STRLOWCASE(STRTRIM(Kwd,2))

    ;  Look for value
    Value   = STRMID(Line,KeyEnd+2,255)
    ValEnd     = STRPOS(Value, ";")
    IF ValEnd NE -1 THEN Value = STRMID(Value,0,ValEnd-1)
    Value   = STRTRIM(Value,2)

    ;  We now have keyword, array index and value

    ;  Special case for the 'End of Interfile' keyword
    ;  It does not set a value like the other keywords.
    IF Kwd EQ "end of interfile" THEN RETURN
    keywords=[Info.(0),Info.(8),Info.(16),Info.(24),Info.(32),$
       Info.(40),Info.(48),Info.(56),Info.(64),Info.(72)]
    Idx    = WHERE(Kwd EQ keywords, Count)
    IF Count EQ 0 THEN GOTO, Continue
    IF Count EQ 1 THEN BEGIN
        KwdInfo    = { $
           a1:Info.(Idx*8), $
           b1:Info.(Idx*8+1),$
           c1:Info.(Idx*8+2),$
           d1:Info.(Idx*8+3),$
           e1:Info.(Idx*8+4),$
           f1:Info.(Idx*8+5),$
           g1:Info.(Idx*8+6),$
           h1:Info.(Idx*8+7) $
           };expect just one
    ;  Either we have an array with no subscripting which requires
    ;  it or we have an array with a subscript that can't have one
    IF (Arr NE 0) XOR (KwdInfo.(6) NE 0) THEN BEGIN;ISARRAY
        IF Arr NE 0 THEN $
       MESSAGE, 'Keyword :'+KwdInfo.(0) +': cannot have subscript';KEYWORD
        MESSAGE, 'Keyword :' + KwdInfo.(0) + ': must have subscript'
    ENDIF

    CALL_PROCEDURE, "Inter_" + KwdInfo.(3), $;HANDLER
       KwdInfo, Value, Arr
    ENDIF ELSE MESSAGE,'More than one match'
    Continue:
    ENDWHILE
END

;
;  GetIFSYM
;   Thin UI to cover keyword finding mechanism.
;   If hash is implemented it goes here
;
FUNCTION GetIFSYM, Name, Info, INDEX=Idx
    COMPILE_OPT hidden

    ; Hash = FIX(TOTAL(BYTE(Name)))
    ; Idxs = WHERE(Info.Hash EQ Hash, Count)
    ; IF Count eq 0 then <Error>
    ; Idx  = WHERE(Name EQ Info[Idxs].Keyword, Count)

    ;    Bit of a hack to avoid use of EXECUTE:
    keywords=[Info.(0),Info.(8),Info.(16),Info.(24),Info.(32),$
       Info.(40),Info.(48),Info.(56),Info.(64),Info.(72)]
    Idx    = WHERE(Name EQ keywords, Count)
    IF Count NE 1 THEN $
       MESSAGE, "Unknown/unsupported keyword '" + Name + "'"
    KwdInfo    = { $
           a1:Info.(Idx*8), $
           b1:Info.(Idx*8+1),$
           c1:Info.(Idx*8+2),$
           d1:Info.(Idx*8+3),$
           e1:Info.(Idx*8+4),$
           f1:Info.(Idx*8+5),$
           g1:Info.(Idx*8+6),$
           h1:Info.(Idx*8+7) $
           };expect just one
    WIDGET_CONTROL, KwdInfo.(1), GET_UVALUE=Value;VALUE
    RETURN, Value
END


;
;  Inter_ReadData
;   At this point we have all of the information to read the
;   data: File, Offset, Amount and Type.
;
PRO Inter_ReadData, Info, Data, Path
    COMPILE_OPT hidden

    ;   Byte/Block offset
    Offset  = GetIFSYM("data offset in bytes", Info)
    IF Offset EQ 0L THEN BEGIN
        Offset = GetIFSYM("data starting block", Info)
        Offset = Offset * 2048
    ENDIF

    FileName    = Path + GetIFSYM("name of data file", Info)
    Sz   = LONARR(6)
    Sz[0]   = 3   ; 3 dimensions
    Sz[1:2] = GetIFSYM("matrix size", Info)
    Sz[3]   = GetIFSYM("total number of images", Info)

    ;   Now the tricky one. Data Type:
    ;   Use elements size and number format.
    ;   I hope we blow up if things are wierd (3 bytes/pixel
    ;   or other unsupported conditions)

    ElemSize    = GetIFSYM("number of bytes per pixel", Info)
    InterType   = GetIFSYM("number format", Info)

    CASE InterType OF

    'bit':   MESSAGE, "Unsupported Data Type."

    'unsigned integer': GOTO, IntData
    'signed integer':   BEGIN
    IntData:
    Type   = [ 1, 2, 0, 3 ]  ; byte/int/error/long
    Type   = Type[ElemSize-1]
    END

    'short float':  Type = 4
    'long float':   Type  = 5

    ENDCASE

    Sz[4]   = Type

    OPENR, Unit, FileName, /GET_LUN
    Data = MAKE_ARRAY(SIZE=Sz, /NOZERO)
    POINT_LUN, Unit, Offset
    READU, Unit, Data
    FREE_LUN, Unit

    ;   There are other combinations that require
    ;   byteswapping but this is what was found
    ;   so far.

    Endian  = GetIFSYM("imagedata byte order", Info)

    ;   Short int data. If we are on some machine where the
    ;   endianness is the reverse of that in the file...

    IF Type EQ 2 THEN BEGIN

    ;  Determine the endianness of the machine

    LocalEndian    = (BYTE(1, 0, 1))[0]

    ;  If the endianness of the machine doesn't
    ;  match the endianness of the file then swap

    IF (Endian EQ 'littleendian' AND LocalEndian EQ 0) OR $
       (Endian EQ 'bigendian' AND LocalEndian EQ 1) THEN BEGIN

        BYTEORDER, Data, /SSWAP
    ENDIF
    ENDIF
END


PRO Read_Interfile, Filename, Data

compile_opt hidden

    OPENR, Unit, Filename, /GET_LUN
    Inter_MakeInfo, Info, Filename
    Inter_ReadHdr, Unit, Info
    FREE_LUN, Unit
    Inter_ReadData, Info, Data, GetPath(Filename, /PATH)

    ; Release Information structure information
    FOR I=0,FIX(N_TAGS(Info)/8)-1 DO BEGIN
    IF Info.(I*8+1) NE 0L THEN WIDGET_CONTROL, Info.(I*8+1), /DESTROY;Value
    IF Info.(I*8+4) NE 0L THEN WIDGET_CONTROL, Info.(I*8+4), /DESTROY;Choices
    ENDFOR
END
