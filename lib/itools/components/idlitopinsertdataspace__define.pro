; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertdataspace__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertDataSpace
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a property sheet is used.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertDataSpace::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopInsertDataSpace::Init
;   IDLitopInsertDataSpace::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopInsertDataSpace::Init
;;
;; Purpose:
;; The constructor of the IDLitopInsertDataSpace object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;function IDLitopInsertDataSpace::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra) ; TYPE="VISUALIZATON")
;end


;;---------------------------------------------------------------------------
;; IDLitopInsertDataSpace::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertDataSpace::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the current window.
    oWindow = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWindow) eq 0) then $
        return, OBJ_NEW()

    ; Prepare the service that will create the axis visualization.
    oCreate = oTool->GetService("CREATE_DATASPACE")
    if (not OBJ_VALID(oCreate)) then $
        return, OBJ_NEW();

    ; Create the axis.
    return, oCreate->CreateDataSpace("DATA SPACE")
end


;-------------------------------------------------------------------------
pro IDLitopInsertDataSpace__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertDataSpace, $
        inherits IDLitOperation}

end

