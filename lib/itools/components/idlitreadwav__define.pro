; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadwav__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadWav class.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadWav object.
;
function IDLitReadWav::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    return, self->IDLitReader::Init("wav", $
        NAME="Windows Waveform", $
        DESCRIPTION="Windows Waveform Audio Stream (wav)", $
        ICON='profile', $
        _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; IDLitReadWav::GetData
;
; Purpose:
; Read the file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadWav::GetData, oData

    compile_opt idl2, hidden

    filename = self->GetFilename()

    if(query_wav(filename, fInfo) eq 0)then $
        return, 0

    data = Read_WAV(filename)

    ; Store image data in Data object.
    oData = OBJ_NEW('IDLitDataIDLVector', $
                         NAME=FILE_BASENAME(fileName))

    result = oData->SetData(data, /NO_COPY)

    return, result

end
;;---------------------------------------------------------------------------
;; IDLitReadWav::Isa
;;
;; Purpose:
;;   Return true if the given file is a WAV file
;;
;;
function IDLitReadWav::Isa, strFilename
   compile_opt idl2, hidden

   return,query_wav(strFilename);

end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadWav__Define
;
; Purpose:
; Class definition for the IDLitReadWav class
;

pro IDLitReadWav__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadWav, $
          inherits IDLitReader $
         }
end
