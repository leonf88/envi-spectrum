; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisgrobject__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisGrObject
;
; PURPOSE:
;    The IDLitVisGrObject class implements a generic visualization
;    object that can contain any IDL gr Object.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-


;;----------------------------------------------------------------------------
;; IDLitVisGrObject::Init
;;
;; Purpose:
;;   Initialization routine of the object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   NAME   - The name to associated with this item.
;;
;;   DESCRIPTION - Short string that will describe this object.
;;
;;   All other keywords are passed to th super class
function IDLitVisGrObject::Init, $
                         NAME=NAME, $
                         DESCRIPTION=DESCRIPTION, $
                         _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not keyword_set(name))then name ="IDL Graphics Object"
    if(not keyword_set(DESCRIPTION))then DESCRIPTION ="IDL Object Graphics Element"
    ; Initialize superclass
    if (not self->IDLitVisualization::Init(NAME=NAME, $
                                           TYPE="IDLOBJECTGRAPHIC", $
                                           ICON='demo', $
                                           DESCRIPTION=DESCRIPTION,$
                                           _EXTRA=_EXTRA))then $
        return, 0

    self->RegisterParameter, 'GRAPHICS OBJECT', $
      DESCRIPTION='A IDL Object Graphics element.', $
      /OPTARGET, /INPUT, TYPES='IDLGROBJECT'

    RETURN, 1 ; Success
end
;;---------------------------------------------------------------------------
;; IDLitVisGRObject::Cleanup
;;
;; Purpose:
;;    Destructor for this class. Make sure the contained object is
;;    removed from this visualization before it dies. Otherwize,
;;    Object graphics will destroy it.
;;
;; Parameter:
;;    None.
;;
pro IDLitVisGrObject::Cleanup
   compile_opt hidden, idl2

   self->Remove, self._oObject ;; do not leave the object in this vis, or it's gone
   self->IDLitVisualization::Cleanup
end
;;---------------------------------------------------------------------------
;; IDLitVisGrObject::GetTypes
;;
;; Purpose:
;;   This routine overrides the super-classes routines so that an
;;   invalid type can be returned. This method is used by the
;;   framework to determine if operations and clipboard copying can be
;;   performed. Since this is not a framework object, these must be
;;   disabled.
;;
function IDLitVisGrObject::GetTypes
   compile_opt hidden, idl2
   return, "<void>"
end
;;---------------------------------------------------------------------------
;; IDLitVisGrObject::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the surface.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLitVisGRObject::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   if(ParmName ne 'GRAPHICS OBJECT' || ~obj_valid(self._OObject))then return

   self->Remove, self._oObject
   self._oObject = obj_new()

end
;;----------------------------------------------------------------------------
;; IDLitVisGrObject::OnDataChangeUpdate
;;
;; Purpose:
;;   This method is called by the framework when the data associated
;;   with this object is modified or initially associated.
;;
;; Parameters:
;;   oSubject   - The data object of the parameter that changed. if
;;                parmName is "<PARAMETER SET>", this is an
;;                IDLitParameterSet object
;;
;;   parmName   - The name of the parameter that changed.
;;
;; Keywords:
;;   None.
;;
pro IDLitVisGrObject::OnDataChangeUpdate, oSubject, parmName
    compile_opt idl2, hidden

    oItem = oSubject             ;preserve oSubject
    switch STRUPCASE(parmName) OF
    '<PARAMETER SET>' : begin
        oItem = oSubject->GetByName('GRAPHICS OBJECT',count=nCount)
        if(nCount eq 0 || ~obj_valid(oItem))then break
    end
    'GRAPHICS OBJECT': BEGIN
        success = oItem->GetData(oGR)
        if(success && oGR ne self._oObject)then begin
            oGr->SetProperty,/private
            oGR->GetProperty, parent=parent
            if(obj_valid(parent))then $
              parent->Remove, oGR
            self->Add, oGR, /aggregate
            self._oObject = oGR
        endif
        break
    end
    else: ;; nothing
    endswitch

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisGrObject__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisGrObject object.
;
;-
pro IDLitVisGrObject__Define

    compile_opt idl2, hidden

    struct = { IDLitVisGrObject,           $
               inherits IDLitVisualization,$
               _oObject : obj_new()        $
             }
end
