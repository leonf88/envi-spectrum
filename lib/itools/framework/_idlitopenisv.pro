; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitopenisv.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; Name:
;   _idlitopenisv
;
; Purpose:
;   Open an iTools isv file and create a new tool.
;
; Arguments:
;   Filename: A string giving the name of the .isv file to open.
;
; Keywords:
;   None.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, June 2003
;   Modified:
;


;-------------------------------------------------------------------------
pro _IDLitOpenISV, filename

    compile_opt idl2, hidden

    on_error, 2
    
    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'

    ; Create the system (if necessary) and retrieve our isv reader.
    oSystem = _IDLitSys_GetSystem()
    oReaderDesc = oSystem->GetFileReader('ITOOLS STATE')
    oReader = oReaderDesc->GetObjectInstance()
    oReader->SetFilename, filename

    ; Read the state file and create a new tool.
    success = oReader->GetData(/CREATE_TOOL)

end
