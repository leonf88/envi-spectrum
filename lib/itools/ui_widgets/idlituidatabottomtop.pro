; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituidatabottomtop.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIDataBottomTop
;
; PURPOSE:
;   This function implements the user interface for the
;   Data Bottom/Top selections.
;   The result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIDataBottomTop(UI, Requester [, UVALUE=uvalue])
;
; INPUTS:
;   UI object
;   Requester
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIDataBottomTop, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 400)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    ; Get the needed information from the requester
    oRequester->GetProperty, $
      BYTESCALE_MIN=dataBottom, $
      BYTESCALE_MAX=dataTop, $
      BYTESCALE_DATARANGE=dataRange, $
      BYTESCALE_EXTENDRANGES=extendRanges, $
      ODATA=oData

    ; Launch the GUI
    result = IDLitwdDataBottomTop(oUI, $
                                  DATA_BOTTOM=dataBottom, $
                                  DATA_TOP=dataTop, $
                                  DATA_RANGE=dataRange, $
                                  EXTENDABLE_RANGES=extendRanges, $
                                  ODATA=oData, $
                                  GROUP_LEADER=groupLeader, $
                                  XOFFSET=xoffset, $
                                  YOFFSET=yoffset)

    ; Failure.
    if (N_TAGS(result) lt 1) then $
        return, 0

    ; Fetch the data values from the result and store in the requester.
    oRequester->SetProperty, $
      BYTESCALE_MIN=result.data_bottom, $
      BYTESCALE_MAX=result.data_top, $
      BYTESCALE_DATARANGE=result.data_range

    return, 1
end

