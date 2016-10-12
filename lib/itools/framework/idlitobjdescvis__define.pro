; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdescvis__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitObjDescVis
;
; PURPOSE:
;   This file implements the IDLitObjDescVis class. This class provides
;   an object descriptor that allows visualization object registration without the
;   need to instatiated an actual destination object.
;
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitObjDesc
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitObjDescVis::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitObjDescVis::Init
;   IDLitObjDescVis::Cleanup
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines (note: no init method needed)
;;---------------------------------------------------------------------------
;; IDLitObjDescVis::Cleanup
;;
;; Purpose:
;;  Desctructor

pro IDLitObjDescVis::Cleanup

   compile_opt idl2, hidden

   if(ptr_valid(self._pDataTypes))then $
      ptr_free, self._pDataTypes

   self->IDLitObjDescTool::Cleanup
end


;;---------------------------------------------------------------------------
;; IDLitObjDescVis::GetDataTypes
;;
;; Purpose:
;;    This method is used to get the list of data types that the
;;    underling visualization supports. This is just for the primary
;;    (op target) parameters of the visualization.
;;
;; Parameters:
;;    None.
;;
;; Return Value:
;;    String array of types.
;;
function IDLitObjDescVis::GetDataTypes, COUNT=COUNT
   compile_opt idl2, hidden

   if (~ptr_valid(self._pDataTypes)) then begin
       ; Call _InstantiateObject instead of GetObjectInstance since
       ; we don't care about playback of properties.
       oVis = self->_InstantiateObject()
       if (OBJ_ISA(oVis, 'IDLitParameter')) then begin
           strTypes = oVis->GetParameterTypes()
       endif else $
           strTypes = ''
       self->ReturnObjectInstance, oVis
       self._pDataTypes = ptr_new(strTypes, /no_copy)
   endif
   dex = where(*self._pDataTypes, count)
   return, (count gt 0) ? (*self._pDataTypes)[dex] : ''
end


;;---------------------------------------------------------------------------
;; IDLitObjDescVis::GetObjectInstance
;;
;; Purpose:
;;   This routine is used to get an instance of the object
;;   described by this descriptor. This process is abstracted
;;   to allow for "singletons" ...etc.
;;
;;   This vis implements its own version of this to mark any sub-items
;;   that were created as private.
;;
;; Return Value:
;;   An object of the type that is described by this object.

function IDLitObjDescVis::GetObjectInstance, _REF_EXTRA=_extra
  ;; Pragmas
  compile_opt idl2, hidden

   oObj = self->IDlitObjDescTool::GetObjectInstance(_EXTRA=_extra)

   ;; If this object has created any visualizations in it's init
   ;; method, then mark them as "created in init". This is used
   ;; By the clibboard to determine what and what not to copy.
   ;;  We could use private, but that cannot be ensured to give a
   ;;  proper copy, especialy with groups.
   if (obj_valid(oObj)) then begin
       ;; Do we have any valid vis children?
       oChildren = oObj->Get(/all, count=nChild, $
                             ISA="IDLitVisualization")
       for i=0, nChild-1 do begin
         oChildren[i]->SetProperty, /_CREATED_IN_INIT
         ; Set the tool on my children, in case they were created
         ; using OBJ_NEW() rather than the recommended GetObjectInstance.
         oChildren[i]->_SetTool, self._oTool
       endfor
   endif else begin
        MESSAGE, /NONAME, $
		IDLitLangCatQuery('Message:Framework:UnableToCreateVizType') + $
	            self._classname
   endelse

  return, oObj
end
;;---------------------------------------------------------------------------
;; No setproperty provided ..cannot change the value of classname.
;;---------------------------------------------------------------------------


;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; IDLitObjDescVis__Define
;;
;; Purpose:
;; Class definition for the IDLitObjDescVis class
;;

pro IDLitObjDescVis__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitObjDescVis, $
          inherits   IDLitObjDescTool,    $
          _pDataTypes   : ptr_new()    $
         }

end
