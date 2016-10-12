; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitcommandbuffer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitCommandBuffer
;
; PURPOSE:
;   This file implements the command undo-redo buffer of the IDL tools
;   system. The buffer is similar to a command set, but it maintains
;   the concept of a position and only executes on command on a undo
;   or redo operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;   IDLitCommand
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitCommandBuffer::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitCommandBuffer::Init
;
; Purpose:
;   Constructor for this object.
;
; Parameters
;    oEnv    - The enviroment object this is operating in.
;              This is normally the tool
;
; Keywords:
;   MEMORY_LIMIT   - Set the to limit in Kilo bytes for this buffer. This
;                    limits the amount of memory that the contents of
;                    this buffer can utilize. This is an approximate
;                    limit.
;
;                    If the value is <= 0, the limit is infinity
function IDLitCommandBuffer::Init, oEnv,$
                           MEMORY_LIMIT=MEMORY_LIMIT, $
                           _EXTRA=_super

   compile_opt idl2, hidden

   self._oEnv = oEnv      ;normally the tool

   iStatus = self->IDLitCommand::Init(_extra=_super)
   if(iStatus ne 0 and n_elements(MEMORY_LIMIT) gt 0)then $
       self._BufferLimit=MEMORY_LIMIT > 0

   self._iCurrent = -1

   return, iStatus
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::Cleanup
;
; Purpose:
;   Destructor for this class.
;
pro IDLitCommandBuffer::Cleanup

   compile_opt idl2, hidden

   obj_destroy, self._oTransBuffer
   self->IDLitCommandSet::Cleanup
end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; IDLitCommandBuffer::SetProperty
;
; Purpose:
;   Used to set properties on the object
;
; Properties/Keywords:
;   MEMORY_LIMIT   - Set the to limit in Kilo bytes for this buffer. This
;                    limits the amount of memory that the contents of
;                    this buffer can utilize. This is an approximate
;                    limit.
;
;                    If the value is <= 0, the limit is infinity
;
PRO IDLitCommandBuffer::SetProperty, MEMORY_LIMIT=MEMORY_LIMIT, $
                      _extra=_extra
    compile_opt hidden, idl2

    ; Has the memory limit for the buffer changed?
    if(n_elements(MEMORY_LIMIT) gt 0)then begin
       Limit = MEMORY_LIMIT > 0 ; nothing less that 0
       if(Limit ne self._BufferLimit)then begin
           self._BufferLimit = Limit
           ; At this point, the current state buffer needs to be
           ; updated
           if(self._BufferLimit ne 0)then begin
               ; Prune the buffer to the new limit
               self->IDLitCommandBuffer::_PruneBufferToSize, self._BufferLimit
               ; Update UI
               self->_NotifyUIUpdates
           endif
       endif
   endif

   if(n_elements(_extra) gt 0)then $ ;up to the super class
     self->IDLitCommandSet::SetProperty, _extra=_extra
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::GetProperty
;
; Purpose:
;   Used to get properties on the object
;
; Properties/Keywords:
;   MEMORY_LIMIT   - Set the to limit in Kilo bytes for this buffer. This
;                    limits the amount of memory that the contents of
;                    this buffer can utilize. This is an approximate
;                    limit.
;
;                    If the value is 0, the limit is infinity
;
;   CURRENT_LOCATION The current location or insert point in the
;                    command buffer. This is 0 based.
;
PRO IDLitCommandBuffer::GetProperty, MEMORY_LIMIT=MEMORY_LIMIT, $
                      CURRENT_LOCATION=current_location,$
                      _REF_EXTRA=_extra
    compile_opt hidden, idl2

    if(arg_present(MEMORY_LIMIT))then $
        MEMORY_LIMIT = self._BufferLimit

    if(arg_present(CURRENT_LOCATION))then $
        CURRENT_LOCATION = self._iCurrent

    if(n_elements(_extra) gt 0)then $
      self->IDLitCommandSet::GetProperty, _extra=_extra
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_PruneBufferToSize
;
; Purpose:
;   When called, this routine will prune the contents of command
;   buffer to fit within the given size. To meet the given size limit
;   the following algorithm is used:
;      - Remove and destroy any redo operations starting at the end
;        of the buffer.
;      - Remove and destroy any undo operations, starting at the head
;        of the command buffer.
;
; Parameters:
;   szLimit    - The limit in KBytes
;
PRO IDLitCommandBuffer::_PruneBufferToSize, szLimit

   compile_opt idl2, hidden

   ; Get the current buffer size in bytes
   szBuffer = self->IDLitCommandBuffer::GetSize()

   szLimBuf = szLimit * 1000ULL ; get limit in bytes
   if(szBuffer le szLimBuf)then $ ;within limits
     return

   ; Okay, it is time to prune. Do we have any "redo ops"
   nContained = self->IDL_Container::Count()-1
   if(nContained gt self._iCurrent)then begin
      ; Prune the list
       for i=nContained, self._iCurrent+1, -1 do begin
           ; Get and remove the item
           oItem=  self->IDL_Container::Get(POSITION=i)
           self->IDL_Container::Remove, POSITION=i
           ; remove the size of this item in Kilos
           szBuffer -= oItem->GetSize()
           obj_destroy,oItem ; destroy command set
           if(szBuffer le szLimBuf)then return ; Within limit!
       endfor
   end

   ; Okay, at this point, the buffer size still exceeds the limit.
   ; Start popping off items from the head of the list (oldest).
   nContained = self._iCurrent   ; note iCurrent is 0 based
   for i=0, nContained do begin
       ; Get and remove the head item
       oItem=  self->IDL_Container::Get()
       self->IDL_Container::Remove
       self._iCurrent-- ; list shifted left, dec current index

       szBuffer -= oItem->GetSize()  ; remove size of this item in Kilos
       obj_destroy,oItem ; destroy command set
       if(szBuffer le szLimBuf)then return ; Within limit!
   endfor
   ; if we get here, there is nothing in the list so the limit would
   ; have been met!
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_NotifyUIUpdates
;
; Purpose:
;   This internal routine is called to trigger update notifiction
;   messages for control and UI decorations for the buffer.
;
; Parameters:
;    None.
;
pro IDLitCommandBuffer::_NotifyUIUpdates

   compile_opt idl2, hidden

    ; Get the target operations
    oUndo = self._oEnv->GetByIdentifier('OPERATIONS/EDIT/UNDO')
    if (~OBJ_VALID(oUndo)) then $
        return
    idUndo =  oUndo->GetFullIdentifier()
    oRedo = self._oEnv->GetByIdentifier('OPERATIONS/EDIT/REDO')
    if (~OBJ_VALID(oRedo)) then $
        return
    idRedo =  oRedo->GetFullIdentifier()

    ; Undo
    bState = (self._iCurrent ge 0)

    ; This will also send out notification if the state changed.
    oUndo->SetProperty, DISABLE=~bState

    ; If sensitive, then use the current name to create tooltip.
    name = IDLitLangCatQuery('Menu:Edit:Undo')
    if (bState) then begin
        oCmdSet = self->IDL_Container::Get(POSITION=self._iCurrent)
        if (OBJ_VALID(oCmdSet)) then begin
            oCmdSet->IDLitComponent::GetProperty, NAME=myname
            if (myname ne '') then $
                name += ' ' + myname
        endif
    endif

    ; Change name of Edit/Undo and Toolbar/Undo if present.
    oUndo->SetProperty, NAME=name
    oToolUndo = self._oEnv->GetByIdentifier('TOOLBAR/EDIT/UNDO')
    if (OBJ_VALID(oToolUndo)) then $
        oToolUndo->SetProperty, NAME=name

    ; Need to send out a message.
    self._oEnv->DoOnNotify, idUndo, 'SETPROPERTY', 'NAME'


    ; Redo
    bState = self._iCurrent lt (self->Count()-1)

    ; This will also send out notification if the state changed.
    oRedo->SetProperty, DISABLE=~bState

    ; If sensitive, then use the current name to create tooltip.
    name = IDLitLangCatQuery('Menu:Edit:Redo')
    if (bState) then begin
        oCmdSet = self->IDL_Container::Get(POSITION=self._iCurrent+1)
        if (OBJ_VALID(oCmdSet)) then begin
            oCmdSet->IDLitComponent::GetProperty, NAME=myname
            if (myname ne '') then $
                name += ' ' + myname
        endif
    endif

    ; Change name of Edit/Redo and Toolbar/Redo if present.
    oRedo->SetProperty, NAME=name
    oToolRedo = self._oEnv->GetByIdentifier('TOOLBAR/EDIT/REDO')
    if (OBJ_VALID(oToolRedo)) then $
        oToolRedo->SetProperty, NAME=name

    ; Need to send out a message.
    self._oEnv->DoOnNotify, idRedo, 'SETPROPERTY', 'NAME'

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_GetUndoTransaction
;
; Purpose:
;    This function is used to retrieve the command set at the undo
;    position. If no commands are available, then null is returned.
;
; Parameters:
;   None
;
function IDLitCommandBuffer::_GetUndoTransaction

   compile_opt idl2, hidden

   if(self._iCurrent lt 0)then $
     return , obj_new()                     ;nothing to undo

   oCmdSet = self->IDL_Container::Get(POSITION=self._iCurrent, COUNT=count)

   if (count eq 0) then $
        return, OBJ_NEW()

   self._iCurrent = self._iCurrent -1;

   return, oCmdSet

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_GetRedoTransaction
;
; Purpose:
;  This routine is called to redo the particular operation. For a
;  command buffer, this means calling the redo operation on the next
;  object from the current of the command list.
;
; Parameters:
;   None
;
function IDLitCommandBuffer::_GetRedoTransaction

   compile_opt idl2, hidden

   nContained = self->IDL_Container::Count()
   if(self._iCurrent+2 gt nContained)then $ ; Cannot redo
      return, obj_new();
   self._iCurrent  = self._iCurrent + 1

   oCommandSet = self->IDL_Container::Get(POSITION=self._iCurrent)
   return, oCommandSet
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::Add
;
; Purpose:
;   Override the container add command. This method will add the new
;   commands to the current transaction.
;
;   Note: If this item is larger that the size limit of this buffer,
;   the buffer will be reset (clearing out everything), the
;   transaction cleared and a message sent to the user.
;
pro IDLitCommandBuffer::Add, oCommands

   compile_opt idl2, hidden

   idx = where(obj_valid(oCommands) and  $
                 obj_isa(oCommands, "IDLitCommand"), cnt)

   if(cnt eq 0)then return

   ; If we don't have a transaction buffer, create one
   if(obj_valid(self._oTransBuffer) eq 0)then $
      self._oTransBuffer = obj_new("IDLitCommandSet")

   ;  Add this command to the end of the command set.
   self._oTransBuffer->Add, oCommands[idx]

   ; Okay, will this transaction exceed the limit of the buffer?
   if(self._BufferLimit gt 0)then begin ; 0 -> no limit
       ; Size of the transaction?
       szTrans = self._oTransBuffer->GetSize(/KILOBYTES) ; kilos

       ; Does the transaction size exceed the buffer limit?
       if(szTrans gt self._BufferLimit)then begin
           ; Okay, this transaction exceeds the undo buffer.
           ; Everything must go!!
           self->IDLitCommandBuffer::ResetBuffer

           ; The user should probably know about this!
           if(obj_valid(self._oEnv))then $
             self._oEnv->ErrorMessage, $
             [IDLitLangCatQuery('Error:BufferLimitExceeded:Text1'), $
              IDLitLangCatQuery('Error:BufferLimitExceeded:Text2')], $
             TITLE=IDLitLangCatQuery('Error:BufferLimitExceeded:Title'), SEVERITY=1
       endif
   endif
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::Remove
;
; Purpose:
;   Override the container remove command. This procedure removes the
;   given commands from the command buffer, and destroys them.
;
;   Removal of one or more commands makes sense when a particular operation
;   causes previously transacted commands to no longer apply.
;
;   An example is when a crop operation occurs.  In this case, previously
;   transacted commands to position or resize the crop box no longer apply,
;   and should be removed from the buffer.
;
pro IDLitCommandBuffer::Remove, oCommands

    compile_opt idl2, hidden

    oTransBuffers = self->IDL_Container::Get(/ALL, COUNT=nTrans)
    if (nTrans eq 0) then $
        return

    iOrigCurrent = self._iCurrent

    for i=0,nTrans-1 do begin

        ; Remove any transaction buffer that contains any of the
        ; given commands.
        isIn = oTransBuffers[i]->IDL_Container::IsContained(oCommands)
        if (TOTAL(isIn) ne 0) then begin
            self->IDL_Container::Remove, oTransBuffers[i]
            OBJ_DESTROY, oTransBuffers[i]
            if (i le iOrigCurrent) then $
                self._iCurrent--
        endif
    endfor

    OBJ_DESTROY, oCommands

    self->IDLitCommandBuffer::_NotifyUIUpdates
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::DoUndo
;
; Purpose:
;   Execute an UnDo operation on the command buffer
;
;   This will wipe out any pending transactions and the execute
;   the previous transaction in the internal buffer.
;
;   If a valid transaction doesn't exist, this method will just
;   quietly return
;
pro IDLitCommandBuffer::DoUndo

   compile_opt idl2, hidden

   oTrans = self->_GetUndoTransaction()
   if(obj_valid(oTrans) eq 0)then $
     return;

   ; Clear out any pending transaction.
   self->Rollback

   ; And undo this transaction.
   self->_UndoTransaction, oTrans

   oTool = self._oEnv
   oSrvMacro = oTool->GetService('MACROS')
   if obj_valid(oSrvMacro) then begin
       oSrvMacro->MarkAsUndone, oTrans
   endif

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::DoRedo
;
; Purpose:
;   Execute a redo operation on the "next" item in the command buffer
;
;   This will wipe out any pending transactions and the execute
;   the next transaction in the internal buffer.
;
;   If a valid transaction doesn't exist, this method will just
;   quietly return
;
pro IDLitCommandBuffer::DoRedo

   compile_opt idl2, hidden

   oTrans = self->_GetRedoTransaction()
   if(obj_valid(oTrans) eq 0)then $
     return;

   ; Clear out any pending transaction.
   self->Rollback

   ; And redo this transaction.
   self->_DoTransaction, oTrans

   oTool = self._oEnv
   oSrvMacro = oTool->GetService('MACROS')
   if obj_valid(oSrvMacro) then begin
       oSrvMacro->MarkAsUndone, oTrans, /REDO
   endif

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_DoTransaction
;
; Purpose:
;   Execute a redo (do) operation on a transaction command set.
;
; Parameters:
;  oTransaction     - The command set that forms the transaction that
;                     needs to be done.
;
pro IDLitCommandBuffer::_DoTransaction, oTransaction

   compile_opt idl2, hidden

   ; Do we have anything?
   if(obj_valid(oTransaction) eq 0)then $
      return;

   nCommands = oTransaction->Count()
   oCommands = oTransaction->Get(/all)

   ; For each command set in the transaction, the
   ; undo operation on the target operation must be called.

   for i=0, nCommands -1 do begin

       if(obj_valid(oCommands[i]) eq 0)then $
         continue ; NEXT!

       ; Get the target operation
       oCommands[i]->GetProperty, SKIP_REDO=skipRedo, $
            OPERATION_IDENTIFIER=idTarget

       ; Skip for Redo if desired.
       if (skipRedo) then $
            continue

       oOpDesc = self._oEnv->GetByIdentifier(idTarget)

       if (~OBJ_VALID(oOpDesc)) then $
         continue;

       if(obj_isa(oOpDesc, "IDLitObjDesc"))then $
         oOp = oOpDesc->GetObjectInstance() $
       else begin
           ; Just use the object. This could be a shared service,
           ; so make sure the tool environment is set correctly.
           oOp = oOpDesc
           oOp->_SetTool, self._oEnv
       endelse
       if (~OBJ_VALID(oOp))then $
         continue;

       iStatus = oOp->RedoOperation(oCommands[i])
       if(oOp ne oOpDesc)then $
         oOpDesc->ReturnObjectInstance, oOp
   endfor

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::_UndoTransaction
;
; Purpose:
;   Execute a undo operation on a transaction command set.
;
; Parameters:
;  oTransaction     - The command set that forms the transaction that
;                     needs to be undone.
;
pro IDLitCommandBuffer::_UndoTransaction, oTransaction

   compile_opt idl2, hidden

   ; Do we have anything?
   if(obj_valid(oTransaction) eq 0)then $
      return;

   nCommands = oTransaction->Count()
   oCommands = oTransaction->Get(/all)

   ; For each command set in the transaction, the
   ; undo operation on the target operation must be called.
   for i=nCommands-1, 0, -1 do begin

       if(obj_valid(oCommands[i]) eq 0)then $
         continue ; NEXT!

       ; Get the target operation
       oCommands[i]->GetProperty, SKIP_UNDO=skipUndo, $
        OPERATION_IDENTIFIER=idTarget

       ; Skip for Undo if desired.
       if (skipUndo) then $
        continue

       oOpDesc = self._oEnv->GetByIdentifier(idTarget)

       if (~OBJ_VALID(oOpDesc)) then $
         continue;

       if(obj_isa(oOpDesc, "IDLitObjDesc"))then $
         oOp = oOpDesc->GetObjectInstance() $
       else begin
           ; Just use the object. This could be a shared service,
           ; so make sure the tool environment is set correctly.
           oOp = oOpDesc
           oOp->_Settool, self._oEnv
       endelse
       if (~OBJ_VALID(oOp)) then $
         continue;

       iStatus = oOp->UndoOperation(oCommands[i])
       if(oOp ne oOpDesc)then $
         oOpDesc->ReturnObjectInstance, oOp
   endfor

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer;:RollBack
;
; Purpose:
;   Rollback a pending transaction. This basically will execute
;   an "Undo" operation on all items in the pending transaction
;   buffer.
;
pro IDLitCommandBuffer::RollBack

   compile_opt idl2, hidden

   ; Do we have anything to rollback?
   if(obj_valid(self._oTransBuffer) eq 0)then $
     return
   if(self._oTransBuffer->IDL_Container::Count() eq 0 )then $
     return

   oItems = self._oTransBuffer->IDL_Container::Get(/all)

   self->IDLitCommandBuffer::_UndoTransaction, self._oTransBuffer
   self._oTransBuffer->IDL_Container::Remove, /all

   obj_destroy, oItems
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::Commit
;
; Purpose:
;   This method will commit the pending transaction command set.
;
pro IDLitCommandBuffer::Commit

   compile_opt idl2, hidden

   ; Do we have anything to commit?
   if(obj_valid(self._oTransBuffer) eq 0)then $
     return
    cnt = self._oTransBuffer->IDL_Container::Count()
    if (cnt eq 0 )then $
        return   ; I have nothing to commit.

    ; Make the name of the transaction command set the same as the
    ; name of the last command item.
    oLastCmd = self._oTransBuffer->IDL_Container::Get(POSITION=cnt-1)
    oLastCmd->IDLitComponent::GetProperty, NAME=name
    self._oTransBuffer->IDLitComponent::SetProperty, NAME=name

   ; If any "redo" commands exist, delete them.
   nContained = self->IDL_Container::Count()-1
   if(nContained gt self._iCurrent)then begin
      ; Prune the list
       for i=0, nContained-self._iCurrent-1 do begin
           oItem=  self->IDL_Container::Get(POSITION=self._iCurrent+1)
           self->IDL_Container::Remove, POSITION=self._iCurrent+1
           obj_destroy,oItem
       endfor
   end
   ; Will this new transaction fit into the buffer? If not,
   ; make it so.
   if(self._BufferLimit gt 0)then begin ; 0 -> no limit
       ; note:
       ; It is assumed that this transaction doen't exceed the
       ; buffer. Why? This is checked when command sets are added to
       ; the open transaction.

       ; Okay, prune the buffer if needed (Limit minus transaction size)
       self->_PruneBufferToSize, self._BufferLimit- $
                    self._oTransBuffer->GetSize(/KILOBYTES)
   endif

   ; Okay, add the transaction to the end of the list
   self->IDL_Container::Add, self._oTransBuffer

   self._oTransBuffer = obj_new();
   self._iCurrent = self->Count()-1

   ; UI Updates Notifications
   self->IDLitCommandBuffer::_NotifyUIUpdates

end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::ResetBuffer
;
; Purpose:
;   When called, all items in the the buffer are removed and any open
;   transactions destroyed.
;
pro IDLitCommandBuffer::ResetBuffer
   Compile_opt hidden,idl2

   oItems=  self->IDL_Container::Get(/All, COUNT=nItems)
   if(nItems gt 0)then begin
       self->IDL_Container::Remove, /AlL
       obj_destroy, oItems
   endif

   if(obj_valid(self._oTransBuffer))then $
     obj_destroy, self._oTransBuffer
   self._oTransBuffer = obj_new() ;
   self._iCurrent = -1

   ; UI Updates Notifications
   self->IDLitCommandBuffer::_NotifyUIUpdates
end


;---------------------------------------------------------------------------
; IDLitCommandBuffer::GetSize
;
; Purpose:
;   Returns the approximate size of the data that is contained in
;   this command buffer. The value is in bytes by default
;
; Keywords:
;   KILOBYTES    - If set, the value in kilobytes
;
function IDLitCommandBuffer::GetSize, KILOBYTES=KILOBYTES
    compile_opt hidden, idl2

    ; Get the contained size in bytes.
    nBytes = self->IDLitCommandSet::GetSize()

    ; Add what's in the transaction buffer.
    nBytes += (obj_valid(self._oTransBuffer) ? $
               self._oTransBuffer->GetSize() : 0)

    ; Kilos?
    if(keyword_set(KILOBYTES))then $
      nBytes = ceil(float(nBytes)/1000., /L64)

    return, nBytes
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitCommandBuffer__define
;
; Purpose:
;  This routine is used to define the command buffer object class.
;
pro IDLitCommandBuffer__define

   compile_opt idl2, hidden

   void = {IDLitCommandBuffer, $
           inherits IDLitCommandSet, $
           _BufferLimit : 0ULL,  $ ; The limit in bytes for the buffer
           _oTransBuffer: obj_new(), $ ; non-committed transaction
           _oEnv : obj_new(), $ ;the operating enviroment..normally the tool
           _iCurrent : 0 $
          }                     ;not much too this component.

end
