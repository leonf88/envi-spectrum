; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopannotation__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopAnnotation
;
; PURPOSE:
;   This file implements the operation that is used to set the scale
;  factor on a visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopAnnotation::Init
;
; METHODS:
;   This class has the following methods:
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopAnnotation::Init
;
; Purpose:
; The constructor of the IDLitopAnnotation object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopAnnotation::Init,  _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
; IDLitopAnnotation::Cleanup
;
; Purpose:
; The destructor of the IDLitopAnnotation object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
;pro IDLitopAnnotation::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
; IDLitopAnnotation::UndoOperation
;
; Purpose:
;  Undo the property commands contained in the command set. Basically
;  re-activate the annotation.
;
function IDLitopAnnotation::UndoOperation, oCommandSet

   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0
   oCmds = oCommandSet->Get(/all, count=nObjs)
   for i=nObjs-1, 0, -1 do begin
        ; Get the object
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idAnnot
        oAnnotation = oTool->GetByIdentifier(idAnnot)
        if (~OBJ_VALID(oAnnotation))then $
            continue
        iStatus = oCmds[i]->getItem("_PARENT", idParent)
        oParent = oTool->getByIdentifier(idParent);

        if(iStatus eq 1 && obj_valid(oParent))then begin
            oParent->Remove, oAnnotation
        endif else begin
            oAnnotation->GetProperty, _PARENT=oParent
            oParent->Remove, oAnnotation
            oAnnotation->SetProperty, _PARENT=obj_new()
        endelse
        void = oCmds[i]->AddItem("O_ANNOTATION", oAnnotation, /OVERWRITE)
   endfor

   return, 1
end


;---------------------------------------------------------------------------
; IDLitopAnnotation::RedoOperation
;
; Purpose:
;   Used to execute this operation on the given command set.
;   Used with redo for the most part.

function IDLitopAnnotation::RedoOperation, oCommandSet

   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0

   oCmds = oCommandSet->Get(/all, count=nObjs)
   for i=nObjs-1, 0, -1 do begin
       ; Get the object
       if(oCmds[i]->getItem("O_ANNOTATION", oAnnotation) eq 1)then begin
           if(obj_valid(oAnnotation))then begin
               iStatus = oCmds[i]->getItem("_PARENT", idParent)
               oParent = oTool->getByIdentifier(idParent);
               if(iStatus eq 0 or not obj_valid(oParent))then $
                 oTool->Add, oAnnotation $
               else $
                   oParent->Add, oAnnotation
           endif
        void = oCmds[i]->AddItem("O_ANNOTATION", OBJ_NEW(), /OVERWRITE)
       endif else begin
           self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:InvalidUndoRedoState'), $
            self->GetFullIdentifier()], severity=1
           continue
       endelse
   endfor

   return, 1
end


;---------------------------------------------------------------------------
; stub
function IDLitopAnnotation::RecordInitialValues, oCommandSet, oAnnots, $
                          idParam
    compile_opt idl2, hidden

    return,1
end


;---------------------------------------------------------------------------
; IDLitopAnnotation::RecordFinalValues
;
; Purpose:
;   This routine is used to record the final property values of the
;   items provided.
;
function IDLitopAnnotation::RecordFinalValues, oCommandSet, oTargets, $
                           idProperty

   compile_opt idl2, hidden

   if(n_elements(oTargets) eq 0 or not obj_valid(oTargets[0]))then $
     return, 0
   for i=0, n_elements(oTargets)-1 do begin
       oCmd = obj_new('IDLitCommand', TARGET_IDENTIFIER= $
                      oTargets[i]->GetFullIdentifier())

       ; Add the values to the command object.
       iStatus = oCmd->AddItem("O_ANNOTATION", OBJ_NEW())
       oTargets[i]->GetProperty, _PARENT=oParent
       iStatus = oCmd->AddItem("_PARENT", $
                               oParent->GetFullIdentifier())
       oCommandSet->Add, oCmd
       oTool = self->GetTool()
       oSrvMacro = oTool->GetService('MACROS')
       if OBJ_VALID(oSrvMacro) then begin
           oSrvMacro->GetProperty, CURRENT_NAME=currentName
           oSrvMacro->PasteMacroVisualization, oTargets[i], currentName
       endif
   endfor

   return, 1
end


;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
pro IDLitopAnnotation__define

    compile_opt idl2, hidden

    struc = {IDLitopAnnotation,       $
             inherits IDLitOperation $
            }
end

