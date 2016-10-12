; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituihelp.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the user interface for help.
;

;-------------------------------------------------------------------------
function IDLitUIHelp, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    oRequester->GetProperty, KEYWORD=keyword, LINKS=links

    if (N_ELEMENTS(links) le 1) then $
        return, 0

    viewers = links[0,*]
    topics = links[1,*]
    books = links[2,*]

    haveViewer = (WHERE(viewers eq 'IDLHELP'))[0]
    if (haveViewer ge 0) then begin
       ; Optional book keyword.
       if (books[haveViewer]) then $
          book = books[haveViewer]
       ONLINE_HELP, topics[haveViewer], BOOK=book
       return, 1
    endif

    if (!VERSION.os_family eq 'Windows') then begin
        haveViewer = (WHERE(viewers eq 'MSHTMLHELP'))[0]
        if (haveViewer ge 0) then begin
            ON_IOERROR, skipOver
            ; Optional book keyword.
            if (books[haveViewer]) then $
                book = books[haveViewer]
            ONLINE_HELP, LONG(topics[haveViewer]), /CONTEXT, BOOK=book
            return, 1
skipOver:
            ON_IOERROR, null
        endif
    endif

    haveViewer = (WHERE(viewers eq 'PDF'))[0]
    if (haveViewer ge 0) then begin
       ; Optional book keyword.
       if (books[haveViewer]) then $
          book = books[haveViewer]
       ONLINE_HELP, topics[haveViewer], BOOK=book
       return, 1
    endif

    haveViewer = (WHERE(viewers eq 'HTML'))[0]
    if (haveViewer ge 0) then begin
        ; Assume that the filename is stored in the topic data,
        ; but if this fails, try the optional 'book' attribute.
        book = topics[haveViewer] ? $
            topics[haveViewer] : books[haveViewer]
        ONLINE_HELP, BOOK=book
        return, 1
    endif

    haveViewer = (WHERE(viewers eq 'TEXT'))[0]
    if (haveViewer ge 0) then begin
        ; Assume that the filename is stored in the topic data,
        ; but if this fails, try the optional 'book' attribute.
        book = topics[haveViewer] ? $
            topics[haveViewer] : books[haveViewer]
        XDISPLAYFILE, book, /BLOCK, $
            DONE_BUTTON='Close', $
            GROUP=groupLeader, $
            TITLE=keyword
        return, 1
    endif


    return, 0
end

