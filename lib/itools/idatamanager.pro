; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/idatamanager.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iDataManager
;
; PURPOSE:
;   Launches the DataManager
;
; CALLING SEQUENCE:
;   iDataManager
;
; INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, November 2003
;
;-

;-------------------------------------------------------------------------
PRO IDATAMANAGER

    compile_opt idl2, hidden

    oSystem = _IDLitSys_GetSystem()
    void = oSystem->DoUIService('/DataManagerBrowser',oSystem)

END
