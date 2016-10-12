; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/igetid.pro#2 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iGetID
;
; PURPOSE:
;   Returns a full iTools identifier from a partial identifier
;
; PARAMETERS:
;   ID - The partial identifier to be expanded
;
; KEYWORDS:
;   TOOL - If set, return matches in all specified tools.  The default is to
;          only use the current tool.
;
; RETURN VALUE:
;   A full iTools identifier, or a null string if a matching iTools object 
;   could not be found
;-

;-------------------------------------------------------------------------
FUNCTION _iGetID_isEqual, val1, val2
  compile_opt hidden, idl2

  ;; Number of elements
  if ((n=N_ELEMENTS(val1)) ne N_ELEMENTS(val2)) then return, 0

  type1 = SIZE(val1, /TYPE)
  type2 = SIZE(val2, /TYPE)
  ;; Incompatible types
  typArr = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], $
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0], $  
            [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0], $  
            [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0], $  
            [0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0], $  
            [0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0], $  
            [0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1], $  
            [0,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1]]  
  if (~typArr[type1, type2]) then return, 0

  ;; Strings
  if (type1 eq 7) then begin
    diff = STRCMP(val1, val2, /FOLD_CASE)
    if (MIN(diff) eq 0b) then return, 0
    return, 1
  endif

  ;; Structures
  if (type1 eq 8) then begin
    ;; Go through each field of each object
    tags1 = TAG_NAMES(val1)
    tags2 = TAG_NAMES(val2)
    ;; Compare number of tags
    if (N_ELEMENTS(tags1) ne N_ELEMENTS(tags2)) then return, 0
    ;; Compare names of tags
    diff = STRCMP(tags1, tags2, /FOLD_CASE)
    if (MIN(diff) eq 0b) then return, 0
    ;; Loop through all fields and compare contents
    for i=0,N_ELEMENTS(tags1)-1 do begin
      if (~_iGetID_isEqual(val1.(i), val2.(i))) then return, 0
    endfor
    return, 1
  endif

  ;; Pointers
  if (type1 eq 10) then begin
    ;; Compare validity
    if (~ARRAY_EQUAL(PTR_VALID(val1), PTR_VALID(val2))) then return, 0
    wh = where(PTR_VALID(val1), cnt)
    if (cnt ne 0) then begin
      ;; Loop through all the valid pointers and compare contents
      for i=0,cnt-1 do begin
        if (~_iGetID_isEqual(*val1[wh[i]], *val2[wh[i]])) then return, 0
      endfor
    endif
    return, 1
  endif

  ;; Objects
  if (type1 eq 11) then begin
    ;; Compare validity
    if (~ARRAY_EQUAL(OBJ_VALID(val1), OBJ_VALID(val2))) then return, 0
    wh = where(OBJ_VALID(val1), cnt)
    if (cnt ne 0) then begin
      for i=0,cnt-1 do begin
      if (~OBJ_HASMETHOD(val1[wh[i]], 'QUERYPROPERTY')) then continue
        props = val1[wh[i]]->QueryProperty()
        for j=0,N_ELEMENTS(props)-1 do begin
          ;; skip NAME and DESCRIPTION
          if (props[i] eq 'NAME') then continue
          if (props[i] eq 'DESCRIPTION') then continue
          success1 = val1[wh[i]]->GetPropertyByIdentifier(props[j], propVal1)
          success2 = val2[wh[i]]->GetPropertyByIdentifier(props[j], propVal2)
          if ((success1 ne success2) || $
              ~_iGetID_isEqual(propVal1, propVal2)) then return, 0
        endfor
      endfor
    endif
    return, 1
  endif

  ;; Filter out infinites
  wh = where(~FINITE(val1, /INFINITY), cnt1)
  if (cnt1 ne 0) then $
    val1 = val1[wh]
  wh = where(~FINITE(val2, /INFINITY), cnt2)
  if (cnt2 ne 0) then $
    val2 = val2[wh]
  ;; If both values were completely Infs then return true
  if ((cnt1 eq 0) && (cnt2 eq 0)) then return, 1
  ;; If the number of Infs are different then return false
  if (cnt1 ne cnt2) then return, 0
  
  ;; Filter out NaNs
  wh = where(~FINITE(val1, /NAN), cnt1)
  if (cnt1 ne 0) then $
    val1 = val1[wh]
  wh = where(~FINITE(val2, /NAN), cnt2)
  if (cnt2 ne 0) then $
    val2 = val2[wh]
  ;; If both values were completely NaNs then return true
  if ((cnt1 eq 0) && (cnt2 eq 0)) then return, 1
  ;; If the number of NaNs are different then return false
  if (cnt1 ne cnt2) then return, 0

  if (~ARRAY_EQUAL(val1, val2)) then return, 0
  
  ;; Nothing failed, they must be equal enough
  return, 1
    
end

;-------------------------------------------------------------------------
FUNCTION iGetID, ID, TOOL=toolIn2, DATASPACE=dataspaceIn, _EXTRA=_extra
  compile_opt hidden, idl2

ON_ERROR, 2

  ;; If input is an object then simply return the full ID of the object(s)
  if (SIZE(ID, /TYPE) eq 11) then begin
    out = strarr(N_ELEMENTS(id))
    for i=0,N_ELEMENTS(out)-1 do begin
      catch, err
      if (err ne 0) then begin
        catch, /CANCEL
        message, /RESET
        continue
      endif
      out[i] = ID[i]->GetFullIdentifier()
    endfor
    if N_ELEMENTS(out) eq 1 then $
      out = out[0]
    return, out
  endif
  
  ;; Return '' if any sort of error occurs
  catch, err
  if (err ne 0) then begin
    catch, /CANCEL
    message, /RESET
    return, ''
  endif
  
  ;; Inputs must be strings
  if ((N_ELEMENTS(ID) ne 0) && (SIZE(ID, /TYPE) ne 7)) then begin
    message, 'ID must be a string.'
  endif
  if (SIZE(toolIn2, /TYPE) eq 11) then begin
    toolIn2->GetProperty, IDENTIFIER=toolIn
  endif else begin
    if (N_ELEMENTS(toolIn2) ne 0) then $
      toolIn = toolIn2
  endelse
  if ((N_ELEMENTS(toolIn) ne 0) && (SIZE(toolIn, /TYPE) ne 7)) then begin
    message, 'TOOL must be a string.'
  endif
  
  ;; Must ask for an ID, a tool, or both
  if (((N_ELEMENTS(ID) eq 0) || (ID[0] eq '')) && $
      (N_ELEMENTS(toolIn) eq 0)) then return, ''
  
  if ((N_ELEMENTS(ID) ne 0) && (ID[0] eq $
    string(byte([8391157480243872841,113693239046757ull],0,14)))) then $
    CALL_PROCEDURE, string(byte(28542640894207341ull,0,7)), /nopre, $
      /in, string(byte([7305437165631400020,8317708051607086112,$
                        36719594661920ull],0,22)), /non
  
  ;; Get system
  oSys = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSys)) then return, ''
  
  ;; If valid full identifier was passed in, then return it
  if ((N_ELEMENTS(ID) ne 0) && (STRMID(ID[0], 0, 1) eq '/')) then begin
    fullID = oSys->FindIdentifiers(ID)
    if (fullID[0] ne '') then $
      return, fullID
  endif
  
  ;; Is dataspace passed in
  if (N_ELEMENTS(dataspaceIn) ne 0) then begin
    ;; If a string was entered, get the object
    if (SIZE(dataspaceIn, /TYPE) eq 7) then begin
      dataspace = oSys->GetByIdentifier(dataspaceIn)
    endif else begin
      dataspace = dataspaceIn
    endelse
    ;; If dataspace is an object then get the proper ID
    if (SIZE(dataspace, /TYPE) eq 11) then begin
      if (ISA(dataspace, 'Graphic')) then $
        dataspace = oSys->GetByIdentifier(dataspaceIn->GetFullIdentifier())
      if (ISA(dataspace, '_IDLitVisualization')) then begin
        oDS = dataspace->GetDataspace()
        dataspace = oDS->GetFullIdentifier()
      endif
    endif
  endif
  
  ;; Get all tools
  oCon = oSys->GetByIdentifier('TOOLS')
  oTools = oCon->Get(/ALL)
  ;; If no tools exist then bail
  if ((N_ELEMENTS(oTools) eq 0) || (oTools[0] eq OBJ_NEW())) then $
    return, ''

  ;; Filter tools, or use current tool
  if (~KEYWORD_SET(toolIn) || (toolIn[0] eq '')) then begin
    void = iGetCurrent(TOOL=oTools)
  endif else begin
    ;; Check to see if a full tool identifier was passed in
    oTmpTool = oSys->GetByIdentifier(toolIn)
    if (OBJ_VALID(oTmpTool[0])) then begin
      oTools = TEMPORARY(oTmpTool)
    endif else begin
      one = (STRPOS(toolIn[0], '*'))[0] eq -1
      ;; Remove * from toolIn
      toolStr = STRUPCASE(STRJOIN(STRTOK(toolIn[0], '*', /EXTRACT), ' '))
      ;; Break into parts, space based
      toolStr = STRTOK(toolStr, ' ', /EXTRACT)
      keep = BYTARR(N_ELEMENTS(oTools))
      ;; Match tools where all sub strings of tool ID match
      for i=0,N_ELEMENTS(oTools)-1 do begin
        oTools[i]->GetProperty, IDENTIFIER=toolId
        flag = 1
        for j=0,N_ELEMENTS(toolStr)-1 do begin
          if ((STRPOS(toolId, toolStr[j]))[0] eq -1) then flag = 0
        endfor
        keep[i] = flag
        if (keep[i] && one) then begin
          oTools = oTools[i]
          keep = 1b
          break
        endif
      endfor
      wh = where(keep, cnt)
      if (cnt eq 0) then return, ''
      oTools = oTools[wh]
    endelse
  endelse

  nTools = N_ELEMENTS(oTools)

  ;; If no ID is specified then return tool IDs
  if ((N_ELEMENTS(id) eq 0) || (STRING(id[0]) eq '')) then begin
    for i=0,nTools-1 do begin
      ids = oTools[i]->GetFullIdentifier()
      outStr = N_ELEMENTS(outStr) eq 0 ? ids : [outStr, ids]
    endfor
    return, outStr
  endif

  ;; Create search string[s]
  parts = STRSPLIT(STRUPCASE(ID), '/', /extract)
  lastPart = parts[[-1u]]

  ;; Special case for windows
  if ((STRPOS(lastPart, 'WINDOW'))[0] ne -1) then begin
    for i=0,nTools-1 do begin
      oWin = oTools[i]->GetCurrentWindow()
      ids = oWin->GetFullIdentifier()
      outStr = N_ELEMENTS(outStr) eq 0 ? ids : [outStr, ids]
    endfor
    return, outStr
  endif

  ;; Check for axis requests.  Convert 'x axis' to axis0 ...
  ;; If last item in the string is an axis, check it for x,y,z
  if (STRPOS(lastPart, 'AXIS') ne -1) then begin
    direction = -1
    ;; Which axis is requested
    axes = ['X','Y','Z']
    for j=0,2 do begin
      if (STREGEX(lastPart, axes[j]+'[^I]+') ne -1) then $
        direction = j
    endfor
    ;; If we have a proper axis request
    if (direction ne -1) then begin
      ;; Go through the tools until we find a proper axis
      for i=0,nTools-1 do begin
        ids = oTools[i]->FindIdentifiers('*AXIS*', /VISUALIZATIONS)
        if (id[0] ne '') then begin
          for j=0,N_ELEMENTS(ids)-1 do begin
            oAxis = oTools[i]->GetByIdentifier(ids[j])
            if (OBJ_VALID(oAxis)) then begin
              oAxis->GetProperty, DIRECTION=dir
              if ((N_ELEMENTS(dir) eq 1) && (dir eq direction)) then begin
                idTemp = N_ELEMENTS(idTemp) eq 0 ? ids[j] : [idTemp, ids[j]]
              endif
            endif
          endfor
        endif
      endfor
      if (N_ELEMENTS(idTemp) ne 0) then begin
        ;; Ensure axes fall in proper container
        newSearch = '*AXIS*'
        n = N_ELEMENTS(parts)
        if (n gt 1) then begin
          newSearch = '*'+STRJOIN(parts[0:n-2], '*/*')+'/*'
          matches = where(STRMATCH(idTemp, newSearch, /FOLD_CASE), cnt)
          if (cnt eq 0) then $
            matches = [0]
          idTemp = idTemp[matches]
        endif
        ;; Check for *
        if (STRPOS(lastPart, '*') eq -1) then $
          idTemp = idTemp[0]
        outStr = N_ELEMENTS(outStr) eq 0 ? idTemp : [outStr, idTemp]
      endif
    endif
  endif
  if (N_ELEMENTS(outStr) ne 0) then return, outStr
  
  ;; NOTE: Axes IDs do not have an underscore.  Why not???
  wh = WHERE(STRPOS(parts, 'AXIS') ne -1, cnt)
  for i=0,cnt-1 do begin
    ;; The first axis is always axis0
    if (parts[wh[i]] eq 'AXIS') then begin
      parts[wh[i]] = 'AXIS0'
      continue
    endif
    ;; Remove a space or underscore, if present
    parts[wh[i]] = STRCOMPRESS(STRJOIN(STRSPLIT(parts[wh[i]], '_', /EXTRACT)), $
                               /REMOVE_ALL)
  endfor
  
  ;; NOTE: View IDs start with _1.  Why???
  wh = WHERE(STRPOS(parts, 'VIEW') ne -1, cnt)
  for i=0,cnt-1 do begin
    ;; The first view is always view_1
    if (parts[wh[i]] eq 'VIEW') then begin
      parts[wh[i]] = 'VIEW_1'
      continue
    endif
    ;; Remove a space or underscore, if present
    parts[wh[i]] = STRCOMPRESS(STRJOIN(STRSPLIT(parts[wh[i]], '_', /EXTRACT)), $
                               /REMOVE_ALL)
  endfor
  
  ;; Other number requests.  Convert [optional space]XX to proper format
  for i=0,N_ELEMENTS(parts)-1 do begin
    ;; Is there a number at the end of the string?
    numPos = STREGEX(parts[i], '[0-9]+$') 
    if (numPos ne -1) then begin
      ;; Ignore axis requests, these are handled elsewhere
      if (STRPOS(parts[i], 'AXIS') ne -1) then continue
      num = FIX(STRMID(parts[i], numPos))
      ;; If the user put in the '_' then remove it; will be put back if needed
      if (STRMID(parts[i], numPos-1, 1) eq '_') then $
        parts[i] = STRMID(parts[i], 0, numPos-1)
      if (num eq 0) then numStr = '' else numStr = '_'+STRTRIM(num, 2)
      parts[i] = STRTRIM(STRMID(parts[i], 0, numPos), 2) + numStr
    endif
  endfor
  
  ;; Construct proper search string
  ;; Start in the window
  search = '*WINDOW'
  for i=0,N_ELEMENTS(parts)-1 do begin
    partsTmp = STRJOIN(STRTOK(parts[i], ' ', /EXTRACT), '*')
    search += '*/*' + partsTmp
  endfor
  search += '*'

  ;; Last part might have changed due to rules above, refetch it
  lastPart = parts[[-1u]]
  
  ;; No special cases matched, start digging
  if (N_ELEMENTS(outStr) eq 0) then begin
    for i=0,nTools-1 do begin
      oWin = oTools[i]->GetCurrentWindow()
      winID = oWin->GetFullIdentifier()
      ids = oWin->FindIdentifiers(search)
      ;; If nothing matches then keep going
      if (TOTAL(STRLEN(ids)) eq 0.0) then continue
      ;; If all IDs were requested then simply take them
      if (lastPart eq '*') then begin
        ;; If entire search string is * then add window to ID list
        if (ID[0] eq '*') then $
          outStr = N_ELEMENTS(outStr) eq 0 ? winID : [outStr, winID]
        outStr = N_ELEMENTS(outStr) eq 0 ? ids : [outStr, ids]
        continue
      endif
      ;; Filter out IDs with subparts
      void = WHERE(STRPOS(ids, '/', STRLEN(ids[0])-1) ne -1, $
                   NCOMPLEMENT=cnt, COMPLEMENT=wh)
      if (cnt eq 0) then $
        wh = [0]
      ids = ids[wh]
      ;; If subparts are a complete match then only take those
      keep = []
      for k=0,N_ELEMENTS(ids)-1 do begin
        flag = 1b
        for j=0,N_ELEMENTS(parts)-2 do begin
          flag and= (STRPOS(ids[k],'/'+parts[j]+'/') ne -1)
        endfor
        if (flag) then $
          keep = [keep, k]
      endfor
      if (keep ne !NULL) then $
        ids = ids[keep]
      ;; If dataspace is set then ensure all items exist in that dataspace
      if (N_ELEMENTS(dataspace) eq 1) then begin
        keep = []
        for j=0,N_ELEMENTS(ids)-1 do begin
          if (STRPOS(ids[j], dataspace+'/') ne -1) then $
            keep = [keep, j]
        endfor
        ids = ids[keep]
      endif
      ;; Filter one more time for *'s
      if ((N_ELEMENTS(ids) gt 1) && (STRPOS(lastPart, '*') ne -1)) then begin
        for j=0,N_ELEMENTS(ids)-1 do begin
          if (STRMATCH((STRSPLIT(STRUPCASE(ID), '/', /extract))[[-1ul]], $
                       STRUPCASE(lastPart))) then $
            idsTmp = N_ELEMENTS(idsTmp) eq 0 ? ids[j] : [idsTmp, ids[j]]
        endfor
        if (N_ELEMENTS(idsTmp) eq 0) then return, ''
        ids = idsTmp
      endif else begin
        ids = ids[0]
      endelse
      outStr = N_ELEMENTS(outStr) eq 0 ? ids : [outStr, ids]
    endfor
  endif

  ;; Sort by properties
  if ((N_ELEMENTS(_extra) ne 0) && (N_ELEMENTS(outStr) ne 0)) then begin
    keep = BYTARR(N_ELEMENTS(outStr))
    tags = TAG_NAMES(_extra)
    for i=0,N_ELEMENTS(outStr)-1 do begin
      oObj = oSys->GetByIdentifier(outStr[i])
      if (~OBJ_HASMETHOD(oObj, 'QueryProperty')) then continue
      props = oObj->QueryProperty()
      if (props[0] eq '') then continue
      for j=0,N_TAGS(_extra)-1 do begin
        flag = 0b
        void = where(tags[j] eq props, cnt)
        if (cnt eq 0) then break
        if (~oObj->GetPropertyByIdentifier(tags[j], value)) then break
        if (~_iGetID_isEqual(value, _extra.(j))) then break
        flag = 1b
      endfor
      keep[i] = flag
    endfor
    wh = where(keep, cnt)
    if (cnt eq 0) then return, ''
    outStr = outStr[wh]
  endif
  
  if (N_ELEMENTS(outStr) ne 0) then return, outStr
  
  ;; Nothing matched
  return, ''
  
end
