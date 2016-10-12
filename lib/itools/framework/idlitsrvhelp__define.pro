; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvhelp__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Display the help for a particular topic.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitsrvHelp::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
pro IDLitsrvHelp::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oXML
    PTR_FREE, self._pLinks
    self->IDLitOperation::Cleanup
end


;---------------------------------------------------------------------------
pro IDLitsrvHelp::GetProperty, $
    KEYWORD=keyword, $
    LINKS=links, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(keyword) then $
        keyword = self._keyword

    if ARG_PRESENT(links) then $
        links = (N_ELEMENTS(*self._pLinks) gt 0) ? *self._pLinks : ''

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Arguments:
;   Tool: Object reference to the current tool.
;
;   Keyword: The keyword for which help is desired.
;
; Keywords:
;   None.
;
pro IDLitsrvHelp::HelpTopic, oTool, keyword

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oXML)) then begin
        self._oXML = OBJ_NEW('IDLitXMLHelp')
    endif

    if (!HELP_PATH ne '') then begin
        ; Find all files ending in *help.xml. Sure hope they're ours.
        helpPath = STRSPLIT(!HELP_PATH, PATH_SEP(/SEARCH_PATH), /EXTRACT)
        xmlFile = FILE_SEARCH(helpPath + PATH_SEP()+'*help.xml', COUNT=nmatch)
    endif else begin
        ; If no help path, try to look under the IDL main directory.
        xmlFile = FILEPATH('idlithelp.xml', SUBDIRECTORY = ['help'])
        nmatch = 1
    endelse

    for i=0,nmatch-1 do begin
        if (~FILE_TEST(xmlFile[i], /READ)) then begin
            self->ErrorMessage, $
                [IDLitLangCatQuery('Error:Framework:CannotFindHelpFile'), xmlFile[i]], $
                SEVERITY=2
            return
        endif
        result = self._oXML->_FindKeyword(xmlFile[i], keyword)
        if (result[0] ne '') then $
            break
    endfor

    if (~nmatch || result[0] eq '') then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:NoHelpAvailable'), keyword], $
            SEVERITY=1
        return
    endif

    self._keyword = keyword
    if (~PTR_VALID(self._pLinks)) then $
        self._pLinks = PTR_NEW(/ALLOCATE)
    *self._pLinks = result

    result = oTool->DoUIService('Help', self)

end


;-------------------------------------------------------------------------
pro IDLitsrvHelp__define

    compile_opt idl2, hidden

    struc = {IDLitsrvHelp, $
        inherits IDLitOperation, $
        _oXML: OBJ_NEW(), $
        _pLinks: PTR_NEW(), $
        _keyword: ''}

end

