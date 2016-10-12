; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvreadfile__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool service needed for file reading.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitsrvReadFile object.
;
; Arguments:
;   None.
;
;-------------------------------------------------------------------------
function IDLitsrvReadFile::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if(self->_IDLitsrvReadWrite::Init(_EXTRA=_SUPER) eq 0)then $
      return, 0

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor of the IDLitsrvReadFile object.
;
; Arguments:
;   None.
;
;pro IDLitsrvReadFile::Cleanup
;    compile_opt idl2, hidden
;    self->_IDLitsrvReadWrite::Cleanup
;end




;;---------------------------------------------------------------------------
;; IDLitsrvReadFile::FindMatchingReader
;;
;; Purpose:
;;  Given a filename, will return the identifier of readers capable of
;;  handling the given file.
;;
;;  First this system searches file extensions. If that fails, query
;;  routines are used.
;;
;; Parameters:
;;   strFile   - The filename to test
;;
function IDLitsrvReadFile::FindMatchingReader, strFile, $
    _ERRORMSG=errorMsg

   compile_opt idl2, hidden

   filename = strtrim(strFile,2)
   if(filename eq '')then return, '' ;; invalid

   ;; Check extensions
   iDot = STRPOS(filename, '.', /REVERSE_SEARCH)
   if(iDot gt 0)then begin
        oDesc = self->_GetDescriptors(/SYSTEM, COUNT=count)
        if (count gt 0) then begin
            self->BuildExtensions, oDesc, fileExt, sFilterList, sIDs
            count = N_ELEMENTS(fileExt)
        endif
       if (count gt 0) then begin
           fileSuffix = STRUPCASE(STRMID(filename, iDot + 1))
           dex = where(fileSuffix eq strupcase(fileExt), nMatch)
           if(nMatch gt 0)then begin
               ;; Validate. Make sure that this file is what it says
               ;; it is. IF it is not ,we will fall to a phase 2
                ;; check, which is a hard validation
               oTool = self->GetTool()
               oReaderDesc = oTool->GetByIdentifier(sIDs[dex[0]])
               oReader = oReaderDesc->GetObjectInstance()
               isa = oReader->Isa(filename)
               oReaderDesc->ReturnObjectInstance, oReader
               if(isa ne 0)then $ ;; yes it is
                 return, sIDs[dex[0]]
               ;; There wasn't a match based on an extension, so fall
               ;; through to the hard Isa() Check
           endif
       endif
   endif

   ;; Okay, the extension match didn't work, time to do a hard query
   oTool = self->GetTool()
   oReaderDesc = oTool->GetFileReader( count=nReaders,/all)
   for i=0, nReaders-1 do begin
       oReader = oReaderDesc[i]->GetObjectInstance()
       isa = oReader->Isa(strFile)
       oReaderDesc[i]->ReturnObjectInstance, oReader
       if(isa ne 0)then $
         return, oReaderDesc[i]->GetfullIdentifier()
   endfor
   errorMsg = [IDLitLangCatQuery('Error:Framework:UnknownFormat'), $
          IDLitLangCatQuery('Error:Framework:CannotReadFile'), strFile]
   return, ''

end
;;---------------------------------------------------------------------------
;; IDLitsrvReadFile::ReadFile
;;
;; Purpose:
;;  Read the contents of the given file and return the given data
;;  object
;;
function IDLitsrvReadFile::ReadFile, strFile, oData, $
                       READER=idREADER

   compile_opt idl2, hidden

   ;; Have we been provided a reader. If not, find a match.
   if(not keyword_set(READER))then $
     idReader = self->FindMatchingReader(strFile, _ERRORMSG=errorMsg)

   if(strtrim(idReader,2) eq '')then begin
       self->SignalError, errorMsg, severity=2
       return, 0
   endif

   ;; Create an instance of our reader
   oTool = self->GetTool()
   oReaderDesc = oTool->GetByIdentifier(idReader)
   oReader = oReaderDesc->GetObjectInstance()
   oReader->SetFilename, strFile

@idlit_catch
    if(iErr ne 0)then begin
        catch,/cancel
        self->SignalError, $
            title=IDLitLangCatQuery('Error:Error:Title'), severity=2, $
            [IDLitLangCatQuery('Error:Framework:FileReadError'), $
            strFile, !error_state.msg]
        return, 0
    endif

   ;; Actually read the data from the file
   ;; Returns 1 for success, 0 for error, -1 for cancel.
   success = oReader->GetData(oData)

   ;; Return the reader instance - we are done with it
   oReaderDesc->ReturnObjectInstance, oReader

   return, success
end
;;---------------------------------------------------------------------------
;; IDLitsrvReadFile::_GetDescriptors
;;
;; Purpose:
;;    Return the list of descriptors to the  callee for the specified
;;    readers. This is used by the super-class to peform various
;;    actions.
;;
;; parameters:
;;    None.
;;
;; Keywords:
;;   COUNT  - Return the number of items returned.
;;
;;   SYSTEM - Include the system file formats.
;;
function IDLitsrvReadFile::_GetDescriptors, system=system, count=count
   compile_opt hidden, idl2

   ;; Get all the readers
   oTool = self->GetTool()
   oDesc = oTool->GetFileReader( count=count, /all)
   iMatch =-1
   if(~keyword_set(system))then begin
       ;; we need to take out the system writer
       for i=0, count-1 do begin
           oReader = oDesc[i]->GetObjectInstance()
           tmpExt = oReader->GetFileExtensions(count=nEXT)
           oDesc[i]->ReturnObjectInstance, oReader
           if(strcmp(tmpExt[0], "isv", /fold_case) eq 1)then begin
               iMatch = i
               break
           endif
       endfor
       if(iMatch gt -1)then begin
           dex = where(indgen(count) ne iMatch, count)
           if(count gt 0)then $
             oDesc = oDesc[dex] $
           else oDesc = obj_new()
       endif
   endif
   return, oDesc
end

;;---------------------------------------------------------------------------
;; IDLitsrvReadFile::ReadFileAndImport
;;
;; Purpose:
;;  This routine will read in the given file and then place it in the
;;  data manager.
;;
;; Parameters:
;;     strFile   - The name of the file to import
;;
;; Keywords:
;;     NAME      - The name for the new data object.
;;
;; Return Value:
;;   1 - Success
;;   0 - Error
;;
function IDLitsrvReadFile::ReadFileandImport, strFile, NAME=NAME

    compile_opt hidden, idl2

    status = self->ReadFile(strFile, oData)

    if(status eq 0)then return, 0

    nData = N_ELEMENTS(oData)

    ; Assume if we have more than 1 data object, that the name
    ; has been set in ReadFile. Otherwise, use our provided name.
    if(keyword_set(NAME) && nData eq 1)then $
      oData[0]->SetProperty, name=name

    ; Place all data objects into the data manager.
    oTool = self->GetTool()

    ; Add all data objects at once, to avoid multiple updates.
    oTool->AddByIdentifier, "/Data Manager", oData

    ;; That is all.
    return,1

end


;-------------------------------------------------------------------------
pro IDLitsrvReadFile__define

    compile_opt idl2, hidden

    struc = {IDLitsrvReadFile,           $
             inherits _IDLitsrvReadWrite}

end

