; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlpalette__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLPalette
;
; PURPOSE:
;   This file implements the IDLitData class. This class is used to
;   store a palette
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
;   See IDLitDataIDLPalette::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitData::Init
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLPalette::Init
;
; Purpose:
; The constructor of the IDLitDataIDLPalette object.
;
; Parameters:
; Data - The (optional) data to store in the object.
;
; Properties:
;   Everything is passed to it's superclass
;
function IDLitDataIDLPalette::Init, Data, TYPE=type, ICON=void, $
                                _EXTRA=_extra


    compile_opt idl2, hidden

@idlit_on_error2

    return,self->IDLitData::Init(Data, TYPE="IDLPALETTE", $
                                 ICON='palette', _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Override our superclass so we can check our data dimensions.
;
function IDLitDataIDLPalette::SetData, Data, Ident, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(Data) gt 0) then begin
        dim = SIZE(Data, /DIMENSIONS)
        ndim = SIZE(Data, /N_DIMENSIONS)
        if (ndim ne 2) || ((dim[0] ne 3) && (dim[0] ne 4)) then begin
            MESSAGE, IDLitLangCatQuery('Message:Component:Array3or4xN'), /continue
            return,0
        endif
    endif

    case (N_PARAMS()) of
        0: return, self->IDLitData::SetData(_EXTRA=_extra)
        1: return, self->IDLitData::SetData(Data, _EXTRA=_extra)
        2: return, self->IDLitData::SetData(Data, Ident, _EXTRA=_extra)
        else:begin
            MESSAGE, IDLitLangCatQuery('Message:Component:IncorrectNumArgs'), /continue
            return,0
        end
    endcase

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataIDLPalette__Define
;
; Purpose:
; Class definition for the IDLitDataIDLPalette class
;

pro IDLitDataIDLPalette__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitDataIDLPalette, $
          inherits   IDLitData}
end
