; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/igetreaders.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iGetReaders
;
; PURPOSE:
;   Returns a list of all IDLitRead* objects
;
; PARAMETERS:
;   NONE
;
; KEYWORDS:
;   EXPAND - If set, expand multiple extensions, one per entry
;
; RETURN VALUE:
;   A 5xN string array where 
;     element [0,x] is the read routine, 
;       e.g., 'Read_JPG'
;     element [1,x] is the reader name (description)
;       e.g., 'Joint Photographic Experts Group'
;     element [2,x] are the reader extensions, comma delimited
;       e.g., '.jpg,.jpeg'
;     element [3,x] is the reader icon, path relative to the read routine
;       e.g., 'demo'
;     element [4,x] is the query routine,
;       e.g., 'Query_JPG'
;-

;----------------------------------------------------------------------------
; _open_isv
;
; Purpose:
;   Opens an iTools isv file
;
; Parameters:
;   FILE - The name of the .isv file to open
;
; Keywords:
;   NONE
;
function _Open_ISV, file, CANCEL=cancel, _EXTRA=_extra
  compile_opt hidden, idl2

  ;; Use call_function instead of calling the file directly.  This file
  ;; is compiled by the workbench on startup and if a user builds a project
  ;; without first doing a .reset then iGetReaders will be included in the
  ;; resolve_all call.  If the routine below is called directly it also ends
  ;; up being resolved, bloating the resulting project .sav file.
  name = '_IDLitOpenISV'
  CALL_PROCEDURE, name, file
  ;; Set the cancel flag so that no further processing will occur, 
  ;; i.e., in iOpen
  cancel = 1b
  return, 1b

end

;----------------------------------------------------------------------------
; _Read_Shape
;
; Purpose:
;   Reads a shapefile and returns the shapefile object
;
; Parameters:
;   FILE - The name of the .shp file to open
;
; Keywords:
;   NONE
;
function _Read_Shape, file, _EXTRA=_extra
  compile_opt hidden, idl2

  image = OBJ_NEW('IDLffShape')

  if (~image->Open(file)) then begin
    OBJ_DESTROY, image
    return, 0b
  endif

  if (N_ELEMENTS(image) ne 0) then $
    return, image
    
  return, 0b

end

;----------------------------------------------------------------------------
; _Read_HDF5
;
; Purpose:
;   Reads an HDF5 file and returns the H5_PARSE structure
;
; Parameters:
;   FILE - The name of the .h5 file to open
;
; Keywords:
;   NONE
;
function _Read_HDF5, file, _EXTRA=_extra
  compile_opt hidden, idl2

  catch, err
  if (err ne 0) then begin
    catch, /cancel
    message, /reset
    return, 0b
  endif

  ;; Use call_function instead of calling the file directly.  This file
  ;; is compiled by the workbench on startup and if a user builds a project
  ;; without first doing a .reset then iGetReaders will be included in the
  ;; resolve_all call.  If the routine below is called directly it also ends
  ;; up being resolved, bloating the resulting project .sav file.
  name = 'H5_PARSE'
  return, CALL_FUNCTION(name, file, /READ_DATA, _EXTRA=_extra)
  
end

;----------------------------------------------------------------------------
; _iGetReaders_show_error
;
; Purpose:
;   output DOM error messages
;
; Parameters:
;   FILENAME - the name of the input file
;
;   LINENUMBER - the line number where the parsing error occurred
;
;   COLUMNNUMBER - the column number where the parsing error occurred
;
;   MESSAGE - the parser error message
;
; Keywords:
;   NONE
;
pro _iGetReaders_show_error, filename, linenumber, columnnumber, message
  compile_opt hidden, idl2

  message, /INFORMATIONAL, /NONAME, $
          'A parsing error occurred at line '+strtrim(linenumber,2)+ $
          ', column '+strtrim(columnnumber,2)+', in file: '+filename

end

;----------------------------------------------------------------------------
; _iGetReaders_swallow_error
;
; Purpose:
;   swallows all DOM parser error messages
;
; Parameters:
;   FILENAME - the name of the input file
;
;   LINENUMBER - the line number where the parsing error occurred
;
;   COLUMNNUMBER - the column number where the parsing error occurred
;
;   MESSAGE - the parser error message
;
; Keywords:
;   NONE
;
pro _iGetReaders_swallow_error, filename, linenumber, columnnumber, message
  compile_opt hidden, idl2
end


;----------------------------------------------------------------------------
; _iGetReaders_ReadXML
;
; Purpose:
;   Retrieves all the readers from an appropriate XML file 
;
; Parameters:
;   FILENAME - the name of the input file
;
;   READERS - an output array of reader inforamtion
;
; Keywords:
;   NONE
;
function _iGetReaders_ReadXML, filename, readers, INCLUDE_BINARY=incBin, $
                               VERBOSE=verboseIn, IDL_DEFAULT=idlDefault, $
                               _EXTRA=_extra
  compile_opt hidden, idl2

  catch, err
  if (err ne 0) then begin
    catch, CANCEL
    MESSAGE, /RESET
    OBJ_DESTROY, oDoc
    return, 0
  endif
  
  verbose = KEYWORD_SET(verboseIn)
  idlDefault = 0b

  ;; set DOM error handling routines
  if verbose then $
    error_file = '_iGetReaders_show_error' $
  else $
    error_file = '_iGetReaders_swallow_error'

  ;; Create new DOM object and load file
  oDoc = obj_new('IDLffXMLDOMDocument')
  oDoc->Load, FILENAME=filename, $
              MSG_ERROR=error_file, MSG_FATAL=error_file, $
              MSG_WARNING=error_file
  
  ;; Load readers
  oReadersList = oDoc->GetElementsByTagName('readers')
  nReaders = oReadersList->GetLength()
  for i=0,nReaders-1 do begin
    oReaders = oReadersList->item(i)

    ;; Check for use default tag
    oIDLDefList = oReaders->GetElementsByTagName('IDL_DEFAULT')
    idlDefault = oIDLDefList->GetLength() gt 0

    ;; Get each reader
    oReaderList = oReaders->GetElementsByTagName('reader')
    nReader = oReaderList->GetLength()
    for j=0,nReader-1 do begin
      oReader = oReaderList->item(j)

      ;; Get read routine
      oReadRoutineList = oReader->GetElementsByTagName('read_routine')
      ;; Must have a read routine
      if (oReadRoutineList->GetLength() eq 0) then begin
        OBJ_DESTROY, oReader
        continue
      endif
      oReadRoutine = oReadRoutineList->item(0)
      ;; Get text node
      oReadRoutineChildren = oReadRoutine->GetChildNodes()
      oReadRoutineText = oReadRoutineChildren->item(0)
      ;; Get text
      readRoutine = OBJ_VALID(oReadRoutineText) ? $
        oReadRoutineText->GetNodeValue() : ''

      ;; Get name
      oReaderNodeMap = oReader->GetAttributes()
      ;; Get name attribute
      oReaderName = oReaderNodeMap->GetNamedItem('name')
      ;; Get text
      name = OBJ_VALID(oReaderName) ? oReaderName->GetNodeValue() : ''

      ;; Do not allow binary readers unless requested
      if ((STRPOS(STRLOWCASE(name), 'binary') ne -1) && $
          ~KEYWORD_SET(incBin)) then begin
        OBJ_DESTROY, oReader
        continue
      endif
      
      ;; Do not allow DICOM on certain machines
      if (STRPOS(STRLOWCASE(name), 'dicom') ne -1) then begin
        ;; Not on Solaris x86
        if ((!version.OS_NAME eq 'Solaris') && $
            (!version.ARCH ne 'sparc')) then begin
          OBJ_DESTROY, oReader
          continue
        endif
      endif

      ;; Get query routine
      queryRoutine = ''
      oQueryRoutineList = oReader->GetElementsByTagName('query_routine')
      if (oQueryRoutineList->GetLength() ne 0) then begin
        oQueryRoutine = oQueryRoutineList->item(0)
        ;; Get text node
        oQueryRoutineChildren = oQueryRoutine->GetChildNodes()
        oQueryRoutineText = oQueryRoutineChildren->item(0)
        ;; Get text
        queryRoutine = OBJ_VALID(oQueryRoutineText) ? $
          oQueryRoutineText->GetNodeValue() : ''
      endif

      ;; Get icon path
      oIconList = oReader->GetElementsByTagName('icon')
      pathSep = PATH_SEP()
      if (oIconList->GetLength() eq 0) then begin
        icon = !DIR+pathSep+'resource'+pathSep+'bitmaps'+pathSep+'demo.bmp'
      endif else begin
        oIcon = oIconList->item(0)
        ;; Get text node
        oIconChildren = oIcon->GetChildNodes()
        oIconText = oIconChildren->item(0)
        ;; Get text
        iconTmp = OBJ_VALID(oIconText) ? oIconText->GetNodeValue() : ''
        ;; Convert icon path into a full path
        ;; Check for IDL_BITMAP tag
        if ((pos=STRPOS(iconTmp, '[IDL_BITMAPS]')) ne -1) then begin
          iconName = STRMID(iconTmp, pos+14)
          icon = !DIR+pathSep+'resource'+pathSep+'bitmaps'+pathSep+iconName
        endif else begin
          icon = (FILE_SEARCH(strtok(!path, PATH_SEP(/SEARCH_PATH), $
                                       /EXTRACT)+'/'+iconTmp))[0]
        endelse
      endelse
      
      ;; Get Extensions
      extensions = ''
      oExtensionList = oReader->GetElementsByTagName('extension')
      nExtensions = oExtensionList->GetLength()
      for k=0,nExtensions-1 do begin
        oExtension = oExtensionList->item(k)
        ;; Get text node
        oExtensionChildren = oExtension->GetChildNodes()
        oExtensionText = oExtensionChildren->item(0)
        ;; Get text
        extensionTmp = OBJ_VALID(oExtensionText) ? $
          oExtensionText->GetNodeValue() : ''
        if (extensionTmp ne '') then $
          extensions = extensions eq '' ? extensionTmp : $
            extensions+','+extensionTmp
      endfor

      ;; Bundle items together
      readerInfo = [readRoutine, name, extensions, icon, queryRoutine]
      
      ;; Add info to return array
      readerArray = N_ELEMENTS(readerArray) eq 0 ? readerInfo : $
        [[readerArray],[readerInfo]]
      
      ;; Clear items for next iteration
      OBJ_DESTROY, oReader
      void = TEMPORARY(extensions)
    endfor
  endfor
  
  OBJ_DESTROY, oDoc
  
  if (N_ELEMENTS(readerArray) ne 0) then $
    readers = readerArray

  return, 1
  
END


;-------------------------------------------------------------------------
function iGetReaders, DEBUG=debug, _EXTRA=_extra
  compile_opt hidden, idl2

on_error, 2

  ;; Return '' if any sort of error occurs
  if (~Keyword_Set(debug)) then begin
    catch, err
    if (err ne 0) then begin
      catch, /CANCEL
      message, /RESET
      return, ['','','','','']
    endif
  endif
  
  readUserFile = 1b
  readDefaultFile = 0b
  pathSep = PATH_SEP()
  userFile = (APP_USER_DIR_QUERY('itt', 'pref', /RESTRICT_IDL_RELEASE, $
                                /RESTRICT_FAMILY)+pathSep+ $
              'idlextensions.xml')[0]
  defaultFile = !DIR+pathSep+'lib'+pathSep+'itools'+pathSep+'components'+ $
                pathSep+'idlextensions.xml'

  exists = FILE_TEST(userFile, /READ)
  ;; If user file does not exist then create one.
  if (~exists) then begin
    readUserFile = 0b
    readDefaultFile = 1b
    ;; Only create file if this is a licensed version
    if (~LMGR(/DEMO)) then begin
      OPENW, lun, userFile, /GET_LUN
      PRINTF, lun, '<idlextensions>'
      PRINTF, lun, '  <readers>'
      PRINTF, lun, '    <IDL_DEFAULT/>'
      PRINTF, lun, '  </readers>'
      PRINTF, lun, '</idlextensions>'
      FREE_LUN, lun
    endif
  endif
  
  ;; Quietly load the XML dlm
  quiet = !quiet
  !quiet = 1
  DLM_LOAD, 'xml'
  !quiet = quiet
  
  if (readUserFile) then begin
    status = _iGetReaders_ReadXML(userFile, readersOut, $
                                  IDL_DEFAULT=idlDef, _EXTRA=_extra)
    if (status) then begin
      if (N_ELEMENTS(readersOut) ne 0) then $
        readers = TEMPORARY(readersOut)
      readDefaultFile OR= idlDef
    endif
  endif

  if (readDefaultFile) then begin
    status = _iGetReaders_ReadXML(defaultFile, readersOut, _EXTRA=_extra)
    if (status) then begin
      readers = N_ELEMENTS(readers) eq 0 ? TEMPORARY(readersOut) : $
        [[readers], [TEMPORARY(readersOut)]]
    endif
  endif

  if (N_ELEMENTS(readers) eq 0) then return, ['','','','','']
  
  return, readers
  
end


