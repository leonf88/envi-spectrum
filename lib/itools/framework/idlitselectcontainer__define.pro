; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitselectcontainer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitSelectContainer
;
; PURPOSE:
;   Used to manage the containment and state of a visualization
;   tree selection state.
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
;   See ::Init
;
; METHODS:
;   ClearSelections
;   AddSelectedItem
;   RemoveSelectedItem
;   SetSelectedItem
;   GetSelectedItems
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitSelectContainer::Init
;
; Purpose:
;  The constructor of the selection container
;
; Parameters:
;   NONE
;

function IDLitSelectContainer::Init

    ; pragmas
    compile_opt idl2, hidden

    self.m_oSelected = obj_new("IDL_Container")

    return, 1
end
;--------------------------------------------------------------------------
; IDLitSelectContainer::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro IDLitSelectContainer::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    self.m_oSelected->Remove,/ALL ;; Do not destroy our contained items!
    obj_destroy, self.m_oSelected
end
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::ClearSelections
;
; PURPOSE:
;   Clears out the selection list, deselecting any selected items.
;
; INPUTS:
;   None.
;
; Keywords:
;   NO_NOTIFY  - The notifier seq. is not initiated if set.
;-

PRO IDLitSelectContainer::ClearSelections, NO_NOTIFY=NO_NOTIFY

    compile_opt idl2, hidden

   ;; Clear out any currently selected items and deselect them.
   if(self.m_oSelected->Count() eq 0 )then $
     return

   ;; Clear out the list
   aItems = self.m_oSelected->Get(/ALL)
   for i=0, n_elements(aItems)-1 do begin
     if (OBJ_VALID(aItems[i])) then begin
         aItems[i]->Select, 0, /NO_NOTIFY  ;; No updates needed
         ;; broadcast to the system
         id = aItems[i]->GetFullIdentifier()
         self->DoOnNotify, id, "SELECT", 0
     endif
   endfor
   self.m_oSelected->Remove, /ALL
;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;;   self.m_oSelParent = obj_new()

    ; Clear out the subselection.
    self._oSubSelect = OBJ_NEW()

    if(not keyword_set(no_notify))then $
      self->_NotifySelectionChange
END
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::AddSelectedItem
;
; PURPOSE:
;   It is used to add a selected item to the selection list.
;   If the parent is different to the current parent, any items
;   currently maintained by the list are removed and deselected.
;   If the parent is the same, the item is just added.
;
; INPUTS:
;    oItem   - The item to select
;-

PRO IDLitSelectContainer::AddSelectedItem, oItem, $
    SUBSELECTION=oSubSelect

    compile_opt idl2, hidden


;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;    oItem->GetProperty, PARENT=oParent
;    if(self.m_oSelParent ne oParent)then $
;       self->IDLitSelectContainer::SetSelectedItem, oItem $
;  else begin
    if(not self.m_oSelected->IsContained(oItem))then begin
        self.m_oSelected->Add, oItem, POSITION=0
        ;; Broadcast to system
        id = oItem->GetFullIdentifier()
        self->DoOnNotify, id, "SELECT", 1
    endif
;  endelse

    if (N_ELEMENTS(oSubSelect) eq 1) then $
        self._oSubSelect = oSubSelect

    self->_NotifySelectionChange
end
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::SetSelectedItem
;
; PURPOSE:
;   This routine is used to set the currently selected item. Basically
;   this implements a non-mulitple selection system: only one item is
;   selected at a time.
;
; INPUTS:
;   oItem   - The item to select.
;-

PRO IDLitSelectContainer::SetSelectedItem, oItem, $
    SUBSELECTION=oSubSelect

    compile_opt idl2, hidden

    if (N_ELEMENTS(oSubSelect) eq 1) then $
        self._oSubSelect = oSubSelect

    ; Clear out any currently selected items and deselect them.
    oOldItems = self.m_oSelected->Get(/ALL, COUNT=count)
    if (count gt 0) then begin
        ; If our item is already selected, then bail.
        if (count eq 1 && oOldItems[0] eq oItem) then $
            return
        self->IDLitSelectContainer::ClearSelections, /NO_NOTIFY
    endif

   ;; Now set selection to the passed in vis/parent combo.
   self.m_oSelected->add, oItem
   ;; Broadcast to system
   id = oItem->GetFullIdentifier()
   self->DoOnNotify, id, "SELECT", 1
;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;   oItem->GetProperty, PARENT=oParent
;   self.m_oSelParent = oParent

   ;; Let the system know the selection state changed.
   self->_NotifySelectionChange
end
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::RemoveSelectedItem
;
; PURPOSE:
;  Used to remove an selected item from the selection list. If the
;  item is not contained, this routine just quietly exits.
;
; INPUTS:
;    oItem    - The item to remove
;-

PRO IDLitSelectContainer::RemoveSelectedItem, oItem

    compile_opt idl2, hidden

;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;  oItem->GetProperty, PARENT=oParent
;  if(self.m_oSelParent ne oParent)then $
;    return

  if(self.m_oSelected->IsContained(oItem) eq 1)then begin
      self.m_oSelected->Remove, oItem
      oItem->Select, 0, /NO_NOTIFY  ;; no updates
     ;; Broadcast to system
      id = oItem->GetFullIdentifier()
      self->DoOnNotify, id, "SELECT", 0
  endif
;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;;  if(self.m_oSelected->Count() eq 0)then $
  ;;     self.m_oSelParent = obj_new();

  self->_NotifySelectionChange

END
;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::SetPrimarySelectedItem
;
; PURPOSE:
;   Used to set an item as primary in the selection list.
;
; INPUTS:
;    oItem    - The item to set as primary
;-

PRO IDLitSelectContainer::SetPrimarySelectedItem, oItem

    compile_opt idl2, hidden

  if(self.m_oSelected->IsContained(oItem, POSITION=pos) eq 1)then $
     self.m_oSelected->Move, pos, 0

END

;---------------------------------------------------------------------------
; +
; IDLitSelectContainer::GetSelectedItems
;
; Purpose:
;   This routine will return an array of the items this container
;   contains. If nothing is contained, a NULL object is returned
;
; Keywords:
;   COUNT   - Returns the number of valid values returned.
;
;   ALL     - Everything, not just visualizations
;-

FUNCTION IDLitSelectContainer::GetSelectedItems, COUNT=COUNT, all=all

    compile_opt idl2, hidden

    ;; Do we want all managed selections?
    if(keyword_set(all))then $
        oItems = self.m_oSelected->Get(/all, count=count) $
    else $
      oItems = self.m_oSelected->Get(/all, isa="_IDLitVisualization", count=count)

    return,  (count gt 0 ? oItems : obj_new())
end
;;---------------------------------------------------------------------------
;; IDLitSelectContainer::_NotifySelectionChange
;;
;; Purpose:
;;   This routine is an internal routine used to notify the parent of
;;   what ever object this is part of that the selection is/has
;;   changed.

pro IDLitSelectContainer::_NotifySelectionChange
   compile_opt idl2, hidden

   self->Getproperty, _PARENT=parent
   if (OBJ_ISA(parent, '_IDLitgrDest')) then $
       parent->NotifySelectionChange

end
;---------------------------------------------------------------------------
; IDLitSelectContainer::Define
;
; Purpose:
;   Define the selection container.
;

pro IDLitSelectContainer__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitSelectContainer, $
            m_oSelected    : obj_new(),   $ ;List of selected items
;; Keep this commented out for selection across
;; layers; kdb - 1/2003
;;            m_oSelParent   : obj_new(),   $ ;Parent of selected items.
            _oSubSelect    : obj_new()    $ ; Single subselected item.
          }
end
