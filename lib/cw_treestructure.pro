; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_treestructure.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_TREESTRUCTURE
;
; PURPOSE:
;   This function implements a compound widget for the treeview
;   of an IDL structure with nested substructures.
;
;
; CALLING SEQUENCE:
;   Result = CW_TREESTRUCTURE(Parent [, VALUE=value])
;
;
; RETURN VALUE:
;   The result is the widget ID of the newly-created widget.
;
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
;
; KEYWORD PARAMETERS:
;   VALUE = Set this keyword to a structure to be traversed.
;
;           If VALUE has a tag "_NAME" which is a scalar string, then
;           this will be used for the tree label.
;           If VALUE has a tag "_ICONTYPE" which is a scalar string,
;           then this will be used as the name of a bitmap file to
;           be used for the icon.
;           If a tag within VALUE contains another structure, then
;           a new branch is constructed and the substructure is
;           traversed.
;     Note: If the tagname for the tag containing the structure
;           is "_DATA" then a new branch is not constructed.
;           This allows you to skip tags while traversing.
;
;   All keywords to WIDGET_TREE except FUNC_GET_VALUE and PRO_SET_VALUE
;   are passed on to the tree widget.
;
;
; Keywords to WIDGET_CONTROL and WIDGET_INFO:
;
;   The widget ID returned by CW_TREESTRUCTURE is the ID of the
;   WIDGET_TREE root. This means that many keywords to the WIDGET_CONTROL
;   and WIDGET_INFO routines that affect or return information on
;   WIDGET_TREE can be used.
;
;   In addition, you can use the GET_VALUE and SET_VALUE keywords to
;   WIDGET_CONTROL to retrieve or set the structure value.
;
;   The GET_VALUE keyword returns the structure corresponding to the
;   current selection within the widget tree. This structure contains
;   only those tags and substructures at the selected level and below.
;   If nothing is selected then a scalar zero is returned.
;
;   The SET_VALUE keyword adds a structure to the tree at the root level.
;   If SET_VALUE is not a structure variable then the tree is emptied.
;
;
; Widget Events Returned by the CW_TREESTRUCTURE Widget:
;
;   The CW_TREESTRUCTURE widget returns WIDGET_TREE_SEL and
;   WIDGET_TREE_EXPAND events.
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, June 2002
;   Modified:
;
;-

;-------------------------------------------------------------------------
; Add structure(s) to the tree, starting at wParent.
; Substructures are recursively added.
;
; _BITMAPS: Internal structure array used to cache bitmaps from files.
;           Avoids having to read the same bitmap multiple times.
;
pro cw_treestructure_addlevel, wParent, sTrees, $
    _BITMAPS=_bitmaps

    compile_opt idl2, hidden

    ; Initialize the bitmap cache.
    if (N_ELEMENTS(_bitmaps) eq 0) then $
        _bitmaps = {ICONTYPE: '', BITMAP: BYTARR(16,16,3)}

    background = (WIDGET_INFO(wParent, /SYSTEM_COLORS)).window_bk

    for i=0, N_ELEMENTS(sTrees)-1 do begin
        sTree = sTrees[i]

        ; Tag names _NAME and _ICONTYPE have special meaning.
        ; NAME will be used for the tree value.
        ; ICON_TYPE will be used for adding a bitmap file.
        tagNames = TAG_NAMES(sTree)

        ; Retrieve the bitmap name if any.
        iconType = TOTAL(tagNames eq '_ICONTYPE') ? sTree._icontype : ''

        if (iconType ne '') then begin

            ; See if we've already read this bitmap.
            cached = (WHERE(_bitmaps.icontype eq iconType))[0]

            if (cached ge 0) then begin

                ; The bitmap has already been loaded.
                bitmap = _bitmaps[cached].bitmap

            endif else begin

                ; Need to read the bitmap from the file.
                iconFile = FILEPATH(iconType + '.bmp', $
                    SUBDIR=['resource','bitmaps'])

                if (FILE_TEST(iconFile, /READ)) then begin
                    bm = READ_BMP(iconFile, R, G, B)
                    bitmap = [[[R[bm]]], [[G[bm]]], [[B[bm]]]]
                    for c=0,2 do begin
                        channel = bitmap[*,*,c]
                        ; Find all values that match the lower left pixel,
                        ; and set them to the background.
                        channel[WHERE(channel eq channel[0,0])] = background[c]
                        bitmap[0,0,c] = channel
                    endfor
                    ; Append the new bitmap to the cached list.
                    _bitmaps = [_bitmaps, $
                        {ICONTYPE: iconType, BITMAP: bitmap} ]
                endif

            endelse

        endif


        ; Check for substructures within ourself.
        isFolder = 0
        for tag=0,N_ELEMENTS(tagNames)-1 do begin
            if ((tagNames[tag] ne '_DATA') and $
                (SIZE(sTree.(tag), /TYPE) eq 8)) then begin
                isFolder = 1
                break  ; no need to check further
            endif
        endfor


        hasName =  TOTAL(tagNames eq '_NAME') gt 0

        ; Use name field or default name.
        if hasName then begin
            name = sTree._name
        endif else begin
            ; Use structure name unless anonymous.
            sName = TAG_NAMES(sTree, /STRUCTURE_NAME)
            name = (sName ne '') ? sName : $
                (isFolder ? 'Struct' : 'Field')
        endelse


        ; Retrieve the path either from the structure itself, or from
        ; our parent.
        path = (TOTAL(tagNames eq '_PATH') gt 0) ? $
            sTree._path : WIDGET_INFO(wParent, /uname)

        ; Be sure to tack on a trailing slash if there isn't one.
        if (STRMID(path, STRLEN(path)-1) ne '/') then $
            path = path + '/'


        ; Store our structure in the UVALUE so we can
        ; retrieve it later with WIDGET_CONTROL, GET_VALUE.
        ; Store the full path field + name  in the UNAME
        ; of the widget to be able to retrieve the structure
        ; when following links or getting info from non-selected
        ; leafs or nodes.

        if (isFolder) then begin

            ; Branch node.
            wTree = WIDGET_TREE(wParent, /FOLDER, $
                BITMAP=bitmap, $
                VALUE=name, $
                UNAME=path + name, $
                UVALUE=sTree)
            for tag=0,N_ELEMENTS(tagNames)-1 do begin
                ; If the tag is a structure, construct a branch.
                if ((tagNames[tag] ne '_DATA') and $
                    (SIZE(sTree.(tag), /TYPE) eq 8)) then $
                    CW_TREESTRUCTURE_ADDLEVEL, wTree, sTree.(tag), $
                        _BITMAPS=_bitmaps
            endfor

        endif else begin

            ; Leaf node.
            wTree = WIDGET_TREE(wParent, BITMAP=bitmap, $
                VALUE=name, $
                UNAME=path + name, $
                UVALUE=sTree)

        endelse

    endfor
end

;-----------------------------------------------------------------------------
; Retrieve the structure corresponding to the current tree selection.
;
function cw_treestructure_getvalue, wTree

    compile_opt hidden

    ON_ERROR, 2                       ;return to caller

    ; Be sure to start at the root for the selection.
    wTreeRoot = WIDGET_INFO(wTree, /TREE_ROOT)
    wSelect = (WIDGET_INFO(wTreeRoot, /TREE_SELECT))[0]

    ; Nothing was selected.
    if (wSelect eq -1) then $
        return, 0

    ; Retrieve the structure stored in the UVALUE.
    WIDGET_CONTROL, wSelect[0], GET_UVALUE=value

    return, (N_ELEMENTS(value) gt 0) ? value : 0
end


;-----------------------------------------------------------------------------
; Add a new structure to the tree hierarchy.
;
pro cw_treestructure_setvalue, wTree, sTree

    compile_opt hidden

    ON_ERROR, 2                       ;return to caller

    ; If not a structure, clean out the tree widget.
    if (N_TAGS(sTree) eq 0) then begin
        wBranch = WIDGET_INFO(wTree, /CHILD)
        while (WIDGET_INFO(wBranch,/VALID_ID)) do begin
            wTmp = WIDGET_INFO(wBranch, /SIBLING)
            WIDGET_CONTROL, wBranch, /DESTROY
            wBranch = wTmp
        endwhile
    endif else begin
        ; Add new tree
        CW_TREESTRUCTURE_ADDLEVEL, wTree, sTree
    endelse

end


;-------------------------------------------------------------------------
function cw_treestructure, wParent, $
    VALUE=sTree, $
    FUNC_GET_VALUE=swallow1, $
    PRO_SET_VALUE=swallow2, $
    _REF_EXTRA=_extra   ; pass directly to WIDGET_TREE


    compile_opt idl2

    ON_ERROR, 2

    ; Check arguments.
    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'

    if (not WIDGET_INFO(wParent, /VALID)) then $
        MESSAGE, 'Invalid widget identifier.'

    myname = 'cw_treestructure'

    wTree = WIDGET_TREE(wParent, $
        PRO_SET_VALUE= myname+'_setvalue', $
        FUNC_GET_VALUE= myname+'_getvalue', $
        _EXTRA=_extra)


    ; Populate tree with structure.
    if (N_ELEMENTS(sTree) gt 0) then $
        WIDGET_CONTROL, wTree, SET_VALUE=sTree

    return, wTree

end
