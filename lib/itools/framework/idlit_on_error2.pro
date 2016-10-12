; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlit_on_error2.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   An include file that can be used to turn on/off all
;   on_error,2 in the iTools system. To use this setting,
;   this file is included.
;     @idlit_on_error2
;
; Use:
;   To control the on_error,2 setting, use /DEBUG from one of the iTools
;   or from IDLitSys_CreateTool.
;
Defsysv, '!iTools_Debug', EXISTS=hasDebug
if (~hasDebug || ~!iTools_Debug) then on_error, 2
; end idlit_on_error2
