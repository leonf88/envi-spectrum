; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbringtofront__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitopBringToFront::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopBringToFront::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitopOrder::DoAction(oTool, 'Bring to Front')
end


;-------------------------------------------------------------------------
pro IDLitopBringToFront__define

    compile_opt idl2, hidden
    struc = {IDLitopBringToFront, $
        inherits IDLitopOrder}

end

