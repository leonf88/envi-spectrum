; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituibuffer.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiBuffer
;
; PURPOSE:
;   Create the IDL UI (widget) interface for an associated tool object.
;
; CALLING SEQUENCE:
;   IDLituiBuffer, Tool
;
; INPUTS:
;   Tool - Object reference to the tool object.
;
;-
pro IDLituiBuffer, oTool, $
                 DIMENSIONS=dimensionsIn, $
                 VIRTUAL_DIMENSIONS=vDimIn, $
                 USER_INTERFACE=oUI, $  ; output keyword
                 _REF_EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    if (~OBJ_VALID(oTool)) then $
        MESSAGE, IDLitLangCatQuery('UI:InvalidTool')

    ;*** Create a new UI tool object, using our iTool.
    ;
    oUI = OBJ_NEW('IDLitUI', oTool);, GROUP_LEADER=wBase)

    ;***  Drawing area.
    ;
    dimensions = (N_ELEMENTS(dimensionsIn) eq 2) ? $
        dimensionsIn : [800, 600]

    vdim = (N_ELEMENTS(vDimIn) gt 0) ? vDimIn : dimensions

    oWin = OBJ_NEW('IDLitgrBuffer', DIMENSIONS=dimensions, $
        RESOLUTION=1d/[!d.x_px_cm, !d.y_px_cm])

    oTool->_SetCurrentWindow, oWin

    ; Start out with a 1x1 gridded layout.
    oWin->SetProperty, LAYOUT_INDEX=1

    ; Set initial canvas zoom to 100% so our checked menus get updated.
    oWin->SetProperty, CURRENT_ZOOM=1


end

