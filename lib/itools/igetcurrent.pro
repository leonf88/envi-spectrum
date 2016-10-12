; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/igetcurrent.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iGetCurrent
;
; PURPOSE:
;   Returns the current tool in the system.
;
; CALLING SEQUENCE:
;   idTool = iGetCurrent()
;
; INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   TOOL: Set this keyword to a named variable in which to return the
;       object reference to the current tool object.
;       If there is no current tool then a null object is returned.
;
;   THUMBNAIL : If set to a named variable, and a current tool exists, this 
;               will return a thumbnail image of the current tool.  The image 
;               is returned as a true colour (3xMxM) image.
;
;   THUMBSIZE : The size of the thumbnail to return.  The thumbnail is always
;               returned as a square image.  If not supplied a default value
;               of 32 is used.  THUMBSIZE must be greather than 3 and must 
;               shrink the tool window.  This keyword is ignored if THUMBNAIL 
;               is not used.
;
;   THUMBORDER : Set this keyword to return the thumbnail in top-to-bottom order
;            rather than the IDL default of bottom-to-top order.
;
;   THUMBBACKGROUND : The colour of the excess background to use in the 
;                     thumbnail.  This only has effect if the aspect ratio of
;                     the tool window is not equal to 1.  If set to a scalar
;                     value the colour of the lower left pixel of the window
;                     is used as the background colour.  If set to an RGB
;                     triplet the supplied colour will be used.  If not
;                     specified a value of [255,255,255] (white) is used.  This
;                     keyword is ignored if THUMBNAIL is not used.
;
; RETURN VALUE
;   An identifier for the current tool. If no tool is current,
;   an empty ('') string is returned.
;
; MODIFICATION HISTORY:
;   Written by:  KDB, RSI, Novemember 2002
;   Modified: CT, RSI, Jan 2004: Added TOOL keyword.
;   Modified: AGEH, RSI, Jun 2008: Added THUMB* keywords.
;   Modified: AGEH, RSI, August 2008: Rename it->i
;
;-

;-------------------------------------------------------------------------
FUNCTION iGetCurrent, TOOL=oTool, $
                       THUMBNAIL=thumb, $
                       THUMBORDER=tOrder, $
                       THUMBSIZE=tSizeIn, $
                       THUMBBACKGROUND=tColourIn

   compile_opt hidden, idl2

    ; Be sure to set this in case an error occurs.
    oTool = OBJ_NEW()

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return,''
   endif

   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem(/NO_CREATE)
   if(not obj_valid(oSystem))then $
     return, ''

    idTool = oSystem->GetCurrentTool()

    if ARG_PRESENT(oTool) then $
        oTool = oSystem->GetByIdentifier(idTool)

    if (ARG_PRESENT(thumb)) then begin
      ;; Get raster image from current tool
      oTool = oSystem->GetByIdentifier(idTool)
      if (OBJ_VALID(oTool)) then begin
        thumb = oTool->GetThumbnail(THUMBSIZE=tSizeIn, $
                                    THUMBORDER=tOrder, $
                                    THUMBBACKGROUND=tColourIn)
      endif
   endif

    return, idTool
end


