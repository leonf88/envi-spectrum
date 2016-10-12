;-------------------------------------------------------------------------
function tex2idl_symboltable

  compile_opt idl2, hidden

  symbolTable = [ $
    '\\alpha', 'a', $
    '\\beta',  'b', $
    '\\chi',   'c', $
    '\\delta', 'd', $
    '\\epsilon','e', $
    '\\eta',   'h', $
    '\\gamma', 'g', $
    '\\iota',  'i', $
    '\\kappa', 'k', $
    '\\lambda','l', $
    '\\mu',    'm', $
    '\\nu',    'n', $
    '\\omega', 'w', $
    '\\omicron','o', $
    '\\phi',   'f', $
    '\\pi',    'p', $
    '\\psi',   'y', $
    '\\rho',   'r', $
    '\\sigma', 's', $
    '\\tau',   't', $
    '\\theta', 'q', $
    '\\upsilon','u', $
    '\\xi',    'x', $
    '\\zeta',  'z', $
    ;
    '\\Alpha', 'A', $
    '\\Beta',  'B', $
    '\\Chi',   'C', $
    '\\Delta', 'D', $
    '\\Epsilon','E', $
    '\\Eta',   'H', $
    '\\Gamma', 'G', $
    '\\Iota',  'I', $
    '\\Kappa', 'K', $
    '\\Lambda','L', $
    '\\Mu',    'M', $
    '\\Nu',    'N', $
    '\\Omega', 'W', $
    '\\Omicron','O', $
    '\\Phi',   'F', $
    '\\Pi',    'P', $
    '\\Psi',   'Y', $
    '\\Rho',   'R', $
    '\\Sigma', 'S', $
    '\\Tau',   'T', $
    '\\Theta', 'Q', $
    '\\Upsilon',String(161b), $
    '\\Xi',    'X', $
    '\\Zeta',  'Z', $
    '\\varepsilon','e', $
    '\\varphi', 'j', $
    '\\varpi', 'v', $
    '\\varsigma','V', $
    '\\vartheta', 'J', $
    ;
    '\\aleph', String(192b), $
    '\\angle', String(208b), $
    '\\approxeq','@', $
    '\\approx', String(187b), $
    '\\bot',   '\^',  $
    '\\bullet', String(183b), $
    '\\cap', String(199b), $
    '\\cdot', String(215b), $
    '\\circledR', String(210b), $
    '\\circ', String(176b), $
    '\\clubsuit', String(167b), $
    '\\copyright', String(211b), $
    '\\cup', String(200b), $
    '\\deg', String(176b), $
    '\\diamondsuit', String(168b), $
    '\\diamond', String(224b), $
    '\\div', String(184b), $
    '\\downarrow', String(175b), $
    '\\Downarrow', String(223b), $
    '\\equiv', String(186b), $
    '\\exists', '$', $
    '\\forall', '"', $
    '\\geq', String(179b), $
    '\\heartsuit', String(169b), $
    '\\Im', String(193b), $
    '\\infty', String(165b), $
    '\\int', String(242b), $
    '\\in', String(206b), $
    '\\langle', String(225b), $
    '\\lceil', String(233b), $
    '\\ldots', String(188b), $
    '\\leftarrow', String(172b), $
    '\\Leftarrow', String(220b), $
    '\\leftrightarrow', String(171b), $
    '\\Leftrightarrow', String(219b), $
    '\\leq', String(163b), $
    '\\lfloor', String(235b), $
    '\\mid', String(189b), $
    '\\nabla', String(209b), $
    '\\neq', String(185b), $
    '\\ni', '''', $
    '\\notin', String(207b), $
    '\\nsubset', String(203b), $
    '\\oplus', String(197b), $
    '\\oslash', String(198b), $
    '\\otimes', String(196b), $
    '\\partial', String(182b), $
    '\\pm', String(177b), $
    "\\'",String(162b), $
    '\\prime',String(162b), $
    '\\prod', String(213b), $
    '\\propto', String(181b), $
    '\\rangle', String(241b), $
    '\\rceil', String(249b), $
    '\\Re', String(194b), $
    '\\rfloor', String(251b), $
    '\\rightarrow', String(174b), $
    '\\Rightarrow', String(222b), $
    '\\sim','~', $
    '\\slash', String(164b), $
    '\\spadesuit', String(170b), $
    '\\sqrt', '!S' + String(214b)+'!R!M`', $
    '\\subseteq', String(205b), $
    '\\subset', String(204b), $
    '\\sum', String(229b), $
    '\\supseteq', String(202b), $
    '\\supset', String(201b), $
    '\\therefore', '\', $
    '\\times', String(180b), $
    '\\uparrow', String(173b), $
    '\\Uparrow', String(221b), $
    '\\vee', String(218b), $
    '\\wedge', String(217b), $
    '\\wp', String(195b), $
    '-', '-' $
    ]

  symbolTable[1:*:2] = '!M' + symbolTable[1:*:2]
  
  symbolTable = [ $
    symbolTable, $
    '\\ ', String(160b), $ ; fixed-width space
    '\\aa', String(229b), $
    '\\AA', String(197b), $
    '\\ae', String(230b), $
    '\\AE', String(198b), $
    '\\DH', String(208b), $
    '\\dh', String(240b), $
    '\\hbar', '!S!8h!X!R!11' + string(175b) + '!X', $
    '\\o', String(248b), $
    '\\O', String(216b), $
    '\\ss', String(223b), $
    '\\TH', String(222b), $
    '\\th', String(254b), $
    '\\bf', '!4', $
    '\\rm', '!X', $
    '\\it', '!5', $
    '\\bi', '!6' $
    ]
  
  unicode = [ $
    '\\Earth', '2641', $
    '\\Jupiter', '2643', $
    '\\Mars', '2642', $
    '\\Mercury', '263f', $
    '\\Moon', '263d', $
    '\\rightmoon', '263d', $
    '\\leftmoon', '263e', $
    '\\Neptune', '2646', $
    '\\Pluto', '2647', $
    '\\Saturn', '2644', $
    '\\Sun', '2609', $
    '\\Uranus', '2645', $
    '\\Venus', '2640', $
    '\\Arrrr', '2620', $
    '\\Frosty', '2603' $
    ]
  unicode[1:*:2] = '!Z(' + unicode[1:*:2] + ')'

  symbolTable = [symbolTable, unicode]
  
  return, symbolTable

end


;-------------------------------------------------------------------------
function tex2idl_matchbrace, str, startIn

  compile_opt idl2, hidden

  start = startIn
  count = 1
  slen = STRLEN(str)
  while (start lt slen) do begin
    left = STRPOS(str, '{', start)
    right = STRPOS(str, '}', start)
    if (right eq -1) then return, slen
    if (left ge 0 && left lt right) then begin
      count++
      start = left + 1
    endif else begin
      count--
      start = right + 1
      if (count eq 0) then return, right
    endelse
  endwhile
  return, slen
end


;-------------------------------------------------------------------------
function tex2idl_substring, str, SUBLEVEL=sublevel

  compile_opt idl2, hidden

  result = str
  start = 0
  previousGroupLength = 0

  while (start lt STRLEN(result)) do begin
    slen = STRLEN(result)
    super = STRPOS(result, '^', start)
    sub = STRPOS(result, '_', start)
    if (super lt 0 && sub lt 0) then break
    if (super lt 0) then super = slen
    if (sub lt 0) then sub = slen
    if (super lt sub) then begin
      hersheyCode = KEYWORD_SET(sublevel) ? '!E' : '!U'
      beginGroup = super
      opposite = '_'
    endif else begin
      hersheyCode = KEYWORD_SET(sublevel) ? '!I' : '!D'
      beginGroup = sub
      opposite = '^'
    endelse
    
    ; Assume just a single character following the sub/superscript
    endGroup = beginGroup + 2

    ; Is sub/super surrounded by braces?
    hasBrace = STRMID(result, beginGroup + 1, 1) eq '{'
    if (hasBrace) then begin
      endGroup = tex2idl_matchbrace(result, beginGroup + 2)
    endif

    len = endGroup - (beginGroup+1+hasBrace)
    tmp = (beginGroup gt 0) ? STRMID(result, 0, beginGroup) : ''

    if (len gt 0) then begin
      groupString = STRMID(result, beginGroup+1+hasBrace, len)
      ; See if we have a superscript followed by a subscript, or vice versa.
      ; In this case we want to stack the two on top of each other.
      followChar = STRMID(result, endGroup+hasBrace, 1)
      subSuperCombined = followChar eq opposite
      if (subSuperCombined) then tmp += '!S'
      tmp += hersheyCode
      
      ; If we are already within a subscript (or a superscript) then we
      ; cannot go to another level.
      ; Otherwise, decode the group, looking for sub-subscripts, etc.
      if (~KEYWORD_SET(sublevel)) then begin
        groupString = tex2idl_substring(groupString, SUBLEVEL=hersheyCode)
      endif
        if (previousGroupLength gt 0) then begin
          nBangs = TOTAL(BYTE(groupString) eq 33b)  ; 33 = '!'
          currGroupLength = STRLEN(groupString) - 2*nBangs
          ; For superscripts and subscripts, the spacing works better if
          ; the longer group come last. If it doesn't, then additional
          ; space characters are added to make up the difference.
          if (previousGroupLength eq currGroupLength) then begin
            ; If the super and subscripts are the same length, insert a "normal"
            ; space character to make things look better.
;            groupString += ' '
          endif else if (previousGroupLength gt currGroupLength) then begin
            ; If the first group was longer, insert "fixed width" spaces
            ; to make up the difference.
            groupString += $;'!3' + $
              STRJOIN(REPLICATE(160b, previousGroupLength-currGroupLength)); + '!X'
          endif
          previousGroupLength = 0
        endif


      if (subSuperCombined) then begin
        nBangs = TOTAL(BYTE(groupString) eq 33b)  ; 33 = '!'
        previousGroupLength = STRLEN(groupString) - 2*nBangs
        groupString += '!R'
      endif else begin
        groupString += KEYWORD_SET(sublevel) ? sublevel : '!N'
      endelse

      tmp += groupString
    endif

    result = tmp + STRMID(result, endGroup + hasBrace)
    start = STRLEN(tmp)
  endwhile

  return, result
end


;-------------------------------------------------------------------------
function tex2idl_convert, texIn

  compile_opt idl2, hidden

  result = texIn

  ; Replace escaped versions of backslashes before converting special chars.
  split = STRTOK(result, '\\\\', /EXTRACT, /PRESERVE_NULL, /REGEX)
  result = STRJOIN(split, '@092@')

  symbolTable = tex2idl_symboltable()

  foreach sym, symbolTable, idx do begin
    ; If a symbol is followed by a space, then swallow the space.
    if (STRLEN(sym) ge 3) then begin
      split = STRTOK(result, sym + ' ', /EXTRACT, /PRESERVE_NULL, /REGEX)
      result = STRJOIN(split, STRMID(sym,1))  ; strip off the first \
    endif
    symIDL = symbolTable[idx+1]
    ; First protect all special \ characters within subscripts or superscripts,
    ; because these will be turned into multiple characters.
    split = STRTOK(result, '\^' + sym, /EXTRACT, /PRESERVE_NULL, /REGEX)
    result = STRJOIN(split, '^{' + symIDL + '}')
    split = STRTOK(result, '\_' + sym, /EXTRACT, /PRESERVE_NULL, /REGEX)
    result = STRJOIN(split, '_{' + symIDL + '}')
    ; Now replace all special characters with the IDL sequence.
    split = STRTOK(result, sym, /EXTRACT, /PRESERVE_NULL, /REGEX)
    result = STRJOIN(split, symIDL)
    idx++  ; step by two's
  endforeach

  ; Replace escaped versions of special characters with dummy sequences,
  ; so we don't have to worry about them below.
  specialChars = ['\','{','}','^','_']
  foreach char, specialChars do begin
    charByte = STRING(BYTE(char), FORMAT='(I3.3)')
    split = STRTOK(result, '\\\' + char, /EXTRACT, /PRESERVE_NULL, /REGEX)
    result = STRJOIN(split, '@' + charByte + '@')
  endforeach

  result = tex2idl_substring(result)

  ; Convert any dummy sequences back into the normal characters.
  specialChars = ['\','{','}','^','_']
  foreach char, specialChars do begin
    charByte = STRING(BYTE(char), FORMAT='(I3.3)')
    split = STRTOK(result, '@' + charByte + '@', /EXTRACT, /PRESERVE_NULL, /REGEX)
    result = STRJOIN(split, char)
  endforeach

  return, result

end


;-------------------------------------------------------------------------
function tex2idl, texIn

  compile_opt idl2, hidden
  
  if (~ISA(texIn, 'STRING')) then $
    MESSAGE, 'Input must be a string or string array.'

  if (N_ELEMENTS(texIn) gt 1) then begin
    result = texIn
    foreach tex, texIn, idx do $
      result[idx] = TeX2IDL(tex)
    return, result
  endif

  result = texIn[0]

  ; Look for pairs of $ $ that enclose "math mode" sequences.
  ; First replace escaped versions of $.
  split = STRTOK(result, '\\\$', /EXTRACT, /PRESERVE_NULL, /REGEX)
  result = STRJOIN(split, '@036@')
  ; Look for matching $ pairs
  index = WHERE(BYTE(result) eq 36b, nindex)
  if (nindex ge 2) then begin
    if (nindex mod 2) then begin
      index[-1] = STRLEN(result)+1
      nindex = (nindex/2)*2
    endif else begin
      index = [index, STRLEN(result)+1]
    endelse
    str = result
    result = (index[0] gt 0) ? STRMID(str, 0, index[0]) : ''
    for i=0,nindex-1,2 do begin
      lenMath = index[i+1] - index[i] - 1
      if (lenMath ge 1) then result += TeX2IDL_Convert(STRMID(str, index[i]+1, lenMath))
      lenReg = index[i+2] - index[i+1] - 1
      if (lenReg ge 1) then result += STRMID(str, index[i+1]+1, lenReg)
    endfor
  endif

  split = STRTOK(result, '@036@', /EXTRACT, /PRESERVE_NULL, /REGEX)
  return, STRJOIN(split, '$')

end

