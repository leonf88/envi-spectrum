; $Id: //depot/idl/releases/IDL_80/idldir/lib/colormap_applicable.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   COLORMAP_APPLICABLE
;
; PURPOSE:
;   Determine whether the current visual class supports the use of a colormap,
;   and if so, whether colormap changes affect pre-displayed Direct Graphics
;   or if the graphics must be redrawn to pick up colormap changes.
;
; CATEGORY:
;   Direct Graphics, Color.
;
; CALLING SEQUENCE:
;   result = COLORMAP_APPLICABLE(redrawRequired)
;
; INPUTS:
;   None.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   The function returns a long value of 1 if the current visual class allows
;   modification of the color table, and 0 otherwise.
;
;   redrawRequired: Set this to a named variable to retrieve a value
;                   indicating whether the visual class supports automatic
;                   updating of graphics.  The value will be 0 if the
;                   graphics are updated automatically or 1 if the graphics
;                   must be redrawn to pick up changes to the colormap.
;   
; EXAMPLE:
;   To determine whether to redisplay an image after a colormap change:
;
;       result = COLORMAP_APPLICABLE(redrawRequired)
;       IF ((result GT 0) AND (redrawRequired GT 0)) THEN BEGIN
;           my_redraw
;       ENDIF
;
; MODIFICATION HISTORY:
;   Written August 1998, ACY
;
;-
;

function colormap_applicable, redrawRequired
; return value:
;        1: colormap applicable for the given visual class
;        0: colormap is not applicable for this visual class
; return parameter redrawRequired (only valid if return value of function = 1)
;	 1: direct graphics must be redrawn to pick up changes to colormap
;	 0: direct graphics will be updated automatically

   device, get_visual_name=visualName

   case STRUPCASE(visualName) of
   'STATICGRAY':  begin
      cmapApplies=1L
      redrawRequired=1L
   end
   'GRAYSCALE':   begin
      cmapApplies=1L
      redrawRequired=0L
   end
   'STATICCOLOR': begin
      cmapApplies=1L
      redrawRequired=1L
   end
   'PSEUDOCOLOR': begin
      cmapApplies=1L
      redrawRequired=0L
   end
   'TRUECOLOR':   begin
      device, get_decomposed=decomposed
      cmapApplies=(decomposed ? 0L : 1L)
      redrawRequired=1L
   end
   'DIRECTCOLOR': begin
      cmapApplies=1L
      redrawRequired=0L
   end
   ELSE:          begin
      cmapApplies=0L
      redrawRequired=1L
   end
   ENDCASE

   RETURN, cmapApplies

end




