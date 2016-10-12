; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlarray3d__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLArray3D
;
; PURPOSE:
;   This file implements the IDLitData class. This class is used to store
;   3d array data
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitData
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataIDLArray3D::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLArray3D::Init
;
; Purpose:
; The constructor of the IDLitDataIDLArray3D object.
;
; Parameters:
; Data - The (optional) data to store in the object.
;
; Properties:
;   Everything is passed to it's superclass
;
function IDLitDataIDLArray3D::Init, Data, TYPE=type, ICON=void, $
                                _EXTRA=_extra


    compile_opt idl2, hidden

@idlit_on_error2

    return,self->IDLitData::Init(Data, TYPE="IDLARRAY3D", $
                                 ICON='binary3d', _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Override our superclass so we can check our data dimensions.
;
function IDLitDataIDLArray3D::SetData, Data, Ident, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(Data) gt 0) then begin
        dim = SIZE(Data, /DIMENSIONS)
        ndim = SIZE(Data, /N_DIMENSIONS)
        if (ndim ne 3) then $
            MESSAGE, IDLitLangCatQuery('Message:Component:Array3D')
    endif

    case (N_PARAMS()) of
        0: return, self->IDLitData::SetData(_EXTRA=_extra)
        1: return, self->IDLitData::SetData(Data, _EXTRA=_extra)
        2: return, self->IDLitData::SetData(Data, Ident, _EXTRA=_extra)
        else: ; Interpreter will catch this
    endcase

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataIDLArray3D__Define
;
; Purpose:
; Class definition for the IDLitDataIDLArray3D class
;

pro IDLitDataIDLArray3D__Define

  compile_opt idl2, hidden

  void = {IDLitDataIDLArray3D, $
          inherits   IDLitData}
end
