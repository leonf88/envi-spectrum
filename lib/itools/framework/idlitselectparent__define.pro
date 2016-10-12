; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitselectparent__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitSelectParent
;
; PURPOSE:
;    Defines/Implements the default selection parent methods. These
;    just pass information up to it's parent.
;
; ASSUMPTIONS:
;    The class that implements this provides a PARENT property and
;    the parent impelements this interface.
;
;    This is not intended to be a stand-alone class.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   None.
;
; SUBCLASSES:
;
; CREATION:
;
; METHODS:
;    AddSelecedItem
;    RemoveSelectedItem
;    SetSelectedItem
;-

;---------------------------------------------------------------------------
;+
; IDLitSelectContainer::AddSelectedItem
;
; PURPOSE:
;   This method passes up an add selected item to it's parent.
;
; INPUTS:
;   oItem    - The item to select
;-

PRO IDLitSelectParent::AddSelectedItem, oItem

    compile_opt idl2, hidden
    self->getProperty, PARENT=myMommy
    if(obj_valid(myMommy))then $
      myMommy->AddSelectedItem, oItem

end
;---------------------------------------------------------------------------
;+
; IDLitSelectParent::SetSelectedItem
;
; PURPOSE:
;   This routine passes up the set selected item call up the
;   tree.
;
; INPUTS:
;    oItem      - The item to select
;-

PRO IDLitSelectParent::SetSelectedItem, oItem

    compile_opt idl2, hidden
    self->getProperty, PARENT=myMommy
    if(obj_valid(myMommy))then $
      myMommy->SetSelectedItem, oItem

end
;---------------------------------------------------------------------------
;+
; IDLitSelectParent::RemoveSelectedItem
;
; PURPOSE:
;    Used to pass the call to Remove a selected item up the tree.
;
; INPUTS:
;    oItem     - The item to remove
;-

PRO IDLitSelectParent::RemoveSelectedItem, oItem

    compile_opt idl2, hidden
    self->getProperty, PARENT=myMommy
    if(obj_valid(myMommy))then $
      myMommy->RemoveSelectedItem, oItem

END
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::SetPrimarySelectedItem
;
; PURPOSE:
;   Passes call up the tree.
;
; INPUTS:
;    oItem    - The item to set as primary
;-
PRO IDLitSelectParent::SetPrimarySelectedItem, oItem

    compile_opt idl2, hidden
    self->getProperty, PARENT=myMommy
    if(obj_valid(myMommy))then $
      myMommy->SetPrimarySelectedItem, oItem

END


;---------------------------------------------------------------------------
;+
; IDLitSelectParent::Define
;
; Purpose:
;   Define the selection container.
;-

pro IDLitSelectParent__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy. We have to have some instance data
   void = {IDLitSelectParent, __$$__:0b}

end
