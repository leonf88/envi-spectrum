; $Id: //depot/idl/releases/IDL_80/idldir/lib/parse_url.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   Parse_Url
;
; PURPOSE:
;   This utility function can be used to break a URL into it's
;   individual componets.
;
;   This function returns a structure containing the individual components
;   of the url that can be used to set the corresponding properties on the
;   IDLnetUrl, IDLnetOgcWms and IDLnetOgcWcs objects.

;   URL Components:
;   URL_SCHEME://URL_USERNAME:URL_PASSWORD@URL_HOST:URL_PORT/URL_PATH?URL_QUERY
;
;   Example url:
;   http://me:mypw@host.com:8080/project/data/get_data.cgi?dataset=climate&date=01012006
;
; CATEGORY:
;   URL
;
; CALLING SEQUENCE:
;   Result = Parse_Url(url)
;
; INPUTS:
;   URL: A string containing a url
;
; KEYWORDS:
;   None
;
; OUTPUTS:
;   This function returns a structure containing the URL components.  The
;   returned structure has the following elements
;           Scheme
;           Username
;           Password
;           Host
;           Port
;           Path
;           Query
;
; SIDE EFFECTS:
;   None.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;
; EXAMPLE CALLING SEQUENCE:
;   url_struc = Parse_Url(url)
;
; MODIFICATION HISTORY:
;   Jan 2007 - Initial Version
;-

function Parse_Url, url

  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ; create the return structure that will contain the url components
  xUrlProps = create_struct(    'Scheme',     '', $
                                'Username',   '', $
                                'Password',   '', $
                                'Host',       '', $
                                'Port',       '80', $
                                'Path',       '', $
                                'Query',      '')

  ; get len of passed in url string and if 0 exit
  iUrlLen = strlen(url)
  if (iUrlLen eq 0) then begin
     return, xUrlProps
  endif

  ; find the begining of the host component
  ; if a '://' was not found then exit because this is not a complete url
  iPos = strpos(url, '://')
  if (iPos eq -1) then begin
     return, xUrlProps
  endif

  ; stor the scheme in the return structure
  xUrlProps.Scheme = strmid(url, 0, iPos)

  ; move past the '://'
  iPos = iPos + 3

  ; extract a username and password if they are presnt
  iPosAt = strpos(url, '@', iPos)
  if (iPosAt ne -1) then begin
     iPosPass = strpos(url, ':', iPos)
     if ((iPosPass ne -1) && (iPosPass lt iPosAt)) then begin
         iLen = iPosAt - (iPosPass + 1)
         ; store the password component in the return structure
         xUrlProps.Password = strmid(url, iPosPass+1, iLen)
     endif else begin
         iPosPass = iPosAt
     endelse
     iLen = iPosPass - iPos
     ; store the username component in the return structure
     xUrlProps.username = strmid(url, iPos, iLen)
     iPos = iPosAt + 1
  endif

  ; find the start of the path if the url has a path
  iPosPath = strpos(url, '/', iPos)
  if (iPosPath eq -1) then begin
     iPosPath = iUrlLen
  endif

  iHostEnd = iPosPath

  ; extract port number if present
  iPosPort = strpos(url, ':', iPos)
  if (iPosPort ne -1) then begin
     iLen = iPosPath - (iPosPort + 1)
     ; store the port component in the return structure
     xUrlProps.Port = strmid(url, iPosPort+1, iLen)
     iHostEnd = iPosPath - iLen -1
  endif

  ; store the host component in the return structure
  iLen = iHostEnd - iPos
  xUrlProps.Host = strmid(url, iPos, iLen)

  ; does the url have a query component
  iPosQuery = strpos(url, '?', iHostEnd)
  if (iPosQuery eq -1) then begin
     iPosQuery = iUrlLen
  endif

  iPathEnd = iPosQuery

  ; store the path component in the return structure
  iLen = iPosQuery - (iPosPath + 1)
  xUrlProps.Path = strmid(url, iPosPath+1, iLen)

  ; store the query component in the return structure
  xUrlProps.Query = strmid(url, iPathEnd+1)

  ; return the url components in a structure
  return, xUrlProps

end


