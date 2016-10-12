; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopzoomresize__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Zoom Resize operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopZoomResize::Init
;
; Purpose:
; The constructor of the IDLitopZoomResize object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
;function IDLitopZoomResize::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; IDLitopZoomResize::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
function IDLitopZoomResize::DoAction, oTool

    compile_opt idl2, hidden

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()
    ; Retrieve the current property value and toggle it.
    oWin->GetProperty, ZOOM_ON_RESIZE=zoomOnResize
    id = oWin->GetFullIdentifier()
    if (oTool->DoSetProperty(id, 'ZOOM_ON_RESIZE', ~zoomOnResize)) then $
        oTool->CommitActions

    return, OBJ_NEW()

end


;-------------------------------------------------------------------------
pro IDLitopZoomResize__define

    compile_opt idl2, hidden
    struc = {IDLitopZoomResize, $
        inherits IDLitOperation}

end

