; $Id: //depot/idl/releases/IDL_80/idldir/lib/get_screen_size.pro#2 $
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
;  FILE:
;       get_screen_size.pro
;
;  PURPOSE:
;       This application retrieves the screen size for the current
;       (or specified) display.
;
;  CATEGORY:
;       Graphics
;
;  CONTENTS:
;       fun get_screen_size - retrieves the screen size
;
;  NAMED STRUCTURES:
;       none.
;
;  COMMON BLOCKS:
;       none.
;
;  MODIFICATION HISTORY:
;       10/96  DD - Original.
;       01/97  DD - Use an unmapped widget draw rather than a pixmap
;                   window because in some (rare) cases on certain X
;                   window configurations, a GL pixmap context cannot
;                   be supported.
;
;-
; -----------------------------------------------------------------------------
;
; Purpose: Returns a two-element vector of the form [width, height] that
;          represents the dimensions, measured in device units, of the
;          screen.
;
; Keywords:
;   DISPLAY_NAME   (X Only)  This keyword may be set to a string
;                  indicating the name of the X Windows display
;                  that should be used to determine the screen size.
;
;   RESOLUTION     Set this keyword to a named variable that will contain
;                  a vector of the form [xres, yres] reporting the pixel
;                  resolution, measured in cm/pixel.
;
FUNCTION get_screen_size, display_arg, DISPLAY_NAME=display_name, $
                          RESOLUTION = resolution

    compile_opt idl2, hidden

    ; Set default display name.
    IF (N_ELEMENTS(display_arg) EQ 0) THEN BEGIN
        IF (N_ELEMENTS(display_name) EQ 0) THEN $
            inDisplayName = "" $
        ELSE $
            inDisplayName = display_name
    ENDIF ELSE $
        inDisplayName = display_arg


    oMon = Obj_New('IDLsysMonitorInfo', DISPLAY_NAME=inDisplayName)
    nMons = oMon->GetNumberOfMonitors()
    rects = oMon->GetRectangles()
    resolution = oMon->GetResolutions()
    primary = oMon->GetPrimaryMonitorIndex()
    obj_destroy, oMon
    
    resolution = resolution[*, primary]
    screenDims = rects[2:3, primary]

    ; Return the screen dimensions.
    RETURN, screenDims
END
