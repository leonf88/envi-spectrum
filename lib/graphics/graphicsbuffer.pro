; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphicsbuffer.pro#1 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
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
pro GraphicsBuffer, oTool, $
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
    oUI = OBJ_NEW('IDLitUI', oTool)

    ;***  Drawing area.
    ;
    dimensions = (N_ELEMENTS(dimensionsIn) eq 2) ? $
        dimensionsIn : [640, 512]

    vdim = (N_ELEMENTS(vDimIn) gt 0) ? vDimIn : dimensions

    oWin = OBJ_NEW('GraphicsBuffer', DIMENSIONS=dimensions, $
        RESOLUTION=[1d,1d]/(72d/2.54d)) ; [!d.x_px_cm, !d.y_px_cm])

    oTool->_SetCurrentWindow, oWin

    ; Start out with a 1x1 gridded layout.
    oWin->SetProperty, LAYOUT_INDEX=1

end

