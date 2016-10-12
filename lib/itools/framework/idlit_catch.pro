; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlit_catch.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   An include file that can be used to turn on/off all
;   catches in the iTools system. To use this setting,
;   a catch statement in code would look like:
;     @idlit_catch
;        if(iErr ne 0)then ...
;
; Use:
;   To control the catch settings, use /DEBUG from one of the iTools
;   or from IDLitSys_CreateTool.
;
iErr = 0
Defsysv, '!iTools_Debug', EXISTS=hasDebug
if (~hasDebug || ~!iTools_Debug) then catch, iErr
; end idlit_catch
