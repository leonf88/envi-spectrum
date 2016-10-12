; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlarray2d__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLArray2D
;
; PURPOSE:
;   This file implements the IDLitData class. This class is used to store
;   vector (1d array) data
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
;   See IDLitDataIDLArray2D::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLArray2D::Init
;
; Purpose:
; The constructor of the IDLitDataIDLArray2D object.
;
; Parameters:
; Data - The (optional) data to store in the object.
;
; Properties:
;   Everything is passed to it's superclass
;
function IDLitDataIDLArray2D::Init, Data, TYPE=type, ICON=void, $
                                _EXTRA=_extra


    compile_opt idl2, hidden

@idlit_on_error2

    return,self->IDLitData::Init(Data, TYPE="IDLARRAY2D", $
                                 ICON='binary', _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Override our superclass so we can check our data dimensions.
;
function IDLitDataIDLArray2D::SetData, Data, Ident, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(Data) gt 0) then begin
        dim = SIZE(Data, /DIMENSIONS)
        ndim = SIZE(Data, /N_DIMENSIONS)
        if (ndim le 1) || (ndim gt 3) || ((ndim eq 3) && (dim[0] ne 1)) then $
            MESSAGE, IDLitLangCatQuery('Message:Component:Array2D')
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
; IDLitDataIDLArray2D__Define
;
; Purpose:
; Class definition for the IDLitDataIDLArray2D class
;

pro IDLitDataIDLArray2D__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitDataIDLArray2D, $
          inherits   IDLitData}
end
