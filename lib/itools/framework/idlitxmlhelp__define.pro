; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitxmlhelp__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the parser for the iTools XML help files.
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
function IDLitXMLHelp::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLffXMLSAX::Init(_EXTRA=_extra)) then $
        return, 0

    self._pLinks = PTR_NEW(/ALLOCATE)

    return, 1

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp::StartDocument

    compile_opt idl2, hidden

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._pLinks

    self->IDLffXMLSAX::Cleanup

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp::StartElement, URI, Local, qName, attName, attValue

    compile_opt idl2, hidden

    element = (Local ne '') ? Local : qName

    case element of

        'Help':

        'Topic': *self._pLinks = ['', '', '']

        'Keyword':

        'Link': begin
            ; Check for 'type' attribute.
            isType = (WHERE(attName eq 'type'))[0]
            if (isType lt 0) then $
                return
            self._type = attValue[isType]
            ; Check for 'book' attribute.
            isBook = (WHERE(attName eq 'book'))[0]
            self._book = (isBook ge 0) ? attValue[isBook] : ''
            end

        else: return

    endcase

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp::EndElement, URI, Local, qName

    compile_opt idl2, hidden

    element = (Local ne '') ? Local : qName

    case element of

        'Help':

        'Topic': if (self._foundMatch) then $
            self->StopParsing

        'Keyword': if ((self._char ne '') && $
            (STRUPCASE(self._char) eq self._keyword)) then begin
                self._foundMatch = 1b
            endif

        'Link': if (self._char ne '') then begin
                *self._pLinks = [[*self._pLinks], $
                    [self._type, self._char, self._book]]
            endif

        else: return

    endcase

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp::Characters, sChar

    compile_opt idl2, hidden

    self._char = sChar

end


;-------------------------------------------------------------------------
function IDLitXMLHelp::_FindKeyword, filename, keyword

    compile_opt idl2, hidden

    if (keyword eq '') then $
        return, ''

    self._foundMatch = 0b
    self._keyword = STRUPCASE(keyword)
    self->ParseFile, filename
    if (~self._foundMatch || (N_ELEMENTS(*self._pLinks) le 3)) then $
        return, ''

    return, (*self._pLinks)[*,1:*]

end


;-------------------------------------------------------------------------
pro IDLitXMLHelp__define

    compile_opt idl2, hidden

    struct = {IDLitXMLHelp, $
        inherits IDLffXMLSAX, $
        _char: '', $
        _keyword: '', $
        _type: '', $
        _book: '', $
        _pLinks: PTR_NEW(), $
        _foundMatch: 0b}

end


