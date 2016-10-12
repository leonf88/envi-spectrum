; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopnewtool__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopNewTool
;
; PURPOSE:
;   This file implements a new tool operation. This will create a new
;   tool at a given location.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopNewTool::Init
;
; METHODS:
;   This class has the following methods:
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopNewTool::Init
;;
;; Purpose:
;; The constructor of the IDLitopNewtool object
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitOpNewTool::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if(self->IDLitOperation::Init(_EXTRA=_SUPER) eq 0)then $
      return, 0

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitopNewTool::DoAction
;;
;; Purpose:
;;   Create a new tool
;;
;; Parameters:
;;  oTool   - The tool we are operating in.
;;
;; Return Value
;;   Command if created.
;-------------------------------------------------------------------------
function IDLitOpNewtool::DoAction, oTool

    compile_opt idl2, hidden

    oSystem = oTool->_GetSystem()
    self->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=myname

    ; The toolbar button is registered as TOOLBAR/FILE/NEWTOOL.
    if (id eq 'NEWTOOL') then begin
        ; We are creating the same tool as ourself.
        oTool->GetProperty, _TOOL_NAME=toolname, NAME=title
    endif else begin
        ; We are creating a different tool. Our operation identifier
        ; should match our registered tool name. However,
        toolname = id + ' Tool'
        ; Sure hope that my operation name matches the default tool
        ; title in the iPlot, etc. wrappers.
        title = "IDL " + myname
    endelse

    oNewTool = oSystem->CreateTool(toolname, WINDOW_TITLE=title)

    return, obj_new()
end



;-------------------------------------------------------------------------
pro IDLitOpNewTool__define

    compile_opt idl2, hidden

    struc = {IDLitOpNewTool,            $
             inherits IDLitOperation    $
            }

end

