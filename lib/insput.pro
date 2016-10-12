; $Id: //depot/idl/releases/IDL_80/idldir/lib/insput.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       INSPUT
;
; PURPOSE:
;       Stub for INSPUT.  Displays message saying that Insight must be running.
;       Once Insight is restored and running this routine will be replaced by
;       the actual compiled version in the Insight save file.
;
; NOTES:
;       - See the online documentation for usage information.
;
;------------------------------------------------------------------------------
pro InsPut, $
    arg1,  arg2,  arg3,  arg4,  arg5, $
    arg6,  arg7,  arg8,  arg9,  arg10, $
    arg11, arg12, arg13, arg14, arg15, $
    arg16, arg17, arg18, arg19, arg20, $
    arg21, arg22, arg23, arg24, arg25, $
    _EXTRA=extra

    ;;  Notify user that Insight must be running to use this function.
    ;;
    result = DIALOG_MESSAGE($
        ['Insight must be running in order to use InsPut.', $
        'Please start Insight and try again.'] )
end
