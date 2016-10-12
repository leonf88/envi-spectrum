; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlpolyvertex__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLPolyVertex
;
; PURPOSE:
;   This file implements the IDLitDataIDLPolyVertex class. This class is used to store
;   vertex and connectivity lists that are suitable for use with IDL polyline and polygon
;   objects.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataIDLPolyVertex::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLPolyVertex::Init
;
; Purpose:
; The constructor of the IDLitDataIDLPolyVertex object.
;
; Parameters:
;   Vertices - (optional) The vertex data to store in the object
;   Conn     - (optional) The connectivity data to store in the object
;
; Properties:
;   See properties from superclass

function IDLitDataIDLPolyVertex::Init, Vertices, Conn, _EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    ; Init superclass
    if(self->IDLitDataContainer::Init(TYPE='IDLPOLYVERTEX', _EXTRA=_extra) eq 0) then $
        return, 0

    ; Initialize ourself
    self->Add, obj_new('IDLitData', NAME='Vertices')
    self->Add, obj_new('IDLitData', NAME='Connectivity')

    ; Have verts?
    if(n_elements(Vertices) gt 0)then begin
        iStatus = self->SetData(Vertices, "Vertices", _EXTRA=_extra)
        if(iStatus eq 0)then begin
            self->IDLitDataContainer::Cleanup
            return, 0
        endif
    endif

    ; Have Conn?
    if(n_elements(Conn) gt 0)then begin
        iStatus = self->SetData(Conn, "Connectivity", _EXTRA=_extra)
        if(iStatus eq 0)then begin
            self->IDLitDataContainer::Cleanup
            return, 0
        endif
    endif

    return, 1
end
;--------------------------------------------------------------------------
; IDLitDataIDLPolyVertex::SetData
;
; Purpose:
;  Method used to set the data in this object. This method will
;  validate the input values and then pass them to the sub-items
;  being used for storage.
;
; Parameters:
;   Data - The data being set.
;
;   Identifier - The item to set the data in. Valid values are:
;                Vertices and Connectivity.
;
;  Return Value:
;    1 - Success
;    0 - Failure
;
function IDLitDataIDLPolyVertex::SetData, Data, Identifier, _extra=_extra
    compile_opt idl2, hidden
    ; Set any data provided

    if(~keyword_set(identifier) || n_elements(data) eq 0)then return, 0
    case strupcase(Identifier) of
        'VERTICES': begin
            sz = size(Data)
            if(sz[0] ne 2 || ~(sz[1] eq 2 || sz[1] eq 3))then begin
                Message, IDLitLangCatQuery('Message:Component:InvalidVertArray'), $
                  /continue
                return,0
            endif
            return, self->IDLitDataContainer::SetData(Data, 'Vertices', _EXTRA=_extra)
        end
        'CONNECTIVITY':begin
            sz = size(Data)
            if(sz[0] ne 1)then begin
                Message, IDLitLangCatQuery('Message:Component:InvalidConnectArray'),/continue
                return,0
            endif
            return, self->IDLitDataContainer::SetData(Data, 'Connectivity', _EXTRA=_extra)
        end
        else:
    endcase
    return, 0
end

;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataIDLPolyVertex__Define
;
; Purpose:
; Class definition for the IDLitDataIDLPolyVertex class
;

pro IDLitDataIDLPolyVertex__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitDataIDLPolyVertex, $
          inherits   IDLitDataContainer         $
         }
end
