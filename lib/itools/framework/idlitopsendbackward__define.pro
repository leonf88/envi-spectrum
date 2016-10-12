; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopsendbackward__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitopSendBackward::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSendBackward::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitopOrder::DoAction(oTool, 'Send Backward')
end


;-------------------------------------------------------------------------
pro IDLitopSendBackward__define

    compile_opt idl2, hidden
    struc = {IDLitopSendBackward, $
        inherits IDLitopOrder}

end

