; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadbinary__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadBinary class.
;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadTIFF object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadBinary::Init,  _EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

    ;; Init superclass
    ;; The only properties that can be set at INIT time can be set
    ;; in the superclass Init method.
    if(self->IDLitReader::Init('', $
                               NAME="Binary data", $
                               DESCRIPTION="Binary data", $
                               ICON='demo', $
                               _EXTRA=_extra) eq 0) then $
        return, 0

    ;; Register properties
    self->RegisterProperty, 'Template', USERDEF='', /HIDE, $
        Description='Binary Template'

    ;; Set the properties.
    self->IDLitReadBinary::SetProperty, _EXTRA=_EXTRA

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitReadBinary::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro IDLitReadBinary::Cleanup
    ;; Pragmas
    compile_opt idl2, hidden

    PTR_FREE, self._pTemplate

    ;; Cleanup superclass
    self->IDLitReader::Cleanup
end

;;---------------------------------------------------------------------------
;; Property Management
;;---------------------------------------------------------------------------
;; IDLitReadBinary::GetProperty
;;
;; Purpose:
;;   Used to get the value of the properties associated with this class.
;;

pro IDLitReadBinary::GetProperty, $
    TEMPLATE=template, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(template)) then begin
        template =  (PTR_VALID(self._pTemplate) && $
            (N_ELEMENTS(*self._pTemplate) gt 0)) ? *self._pTemplate : 0
    endif

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitReader::GetProperty, _EXTRA=_super
end

;;---------------------------------------------------------------------------
;; IDLitReadBinary::SetProperty
;;
;; Purpose:
;;   Used to set the value of the properties associated with this class.
;; Properties:
;;

pro IDLitReadBinary::SetProperty, $
    TEMPLATE=template, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(template) ne 0) then begin
        ; Initialize if necessary.
        if (~PTR_VALID(self._pTemplate)) then $
            self._pTemplate = PTR_NEW(/ALLOC)
        *self._pTemplate = template
    endif

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitReader::SetProperty,  _EXTRA=_super
end


;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
function IDLitReadBinary::_GetBinaryTemplateData, $
    strFilename, oBinaryData

    compile_opt idl2, hidden


    oTool = self->GetTool()
    if (not OBJ_VALID(oTool)) then $
        return, 0

    success = oTool->DoUIService('BinaryTemplate', self)

    ; See if user hit "Cancel" on the dialog. Return -1.
    if (~success || ~N_TAGS(*self._pTemplate)) then $
        return, -1


    data = READ_BINARY(strFilename, $
        TEMPLATE=*self._pTemplate)


    nFields = N_TAGS(data)
    if (nFields eq 0) then $
        return, 0

    ; The user may have chosen to not return all fields. In this case
    ; we need to convert from the field name index into the actual
    ; name for our Data object.
    fieldNames = (*self._pTemplate).names
    keep = WHERE((*self._pTemplate).returnFlags eq 1)


    ; Create a data container if we have more than one field.
    ; Otherwise we will just return a simple data object below.
    if (nFields gt 1) then begin

        ; User doesn't have to enter a template name.
        name = (*self._pTemplate).templateName
        ; If they didn't just use the filename.
        if (~name) then $
            name = FILE_BASENAME(strFilename)

        oBinaryData = OBJ_NEW('IDLitDataContainer', $
            NAME=name, $
            DESCRIPTION=strFilename, $
            TYPE='DATA')

    endif


    for i=0,nFields-1 do begin

        dataDims = SIZE(data.(i), /DIMENSIONS)

        ; Try to pick the best type
        case N_ELEMENTS(dataDims) of
            0:    oData1 = obj_new('IDLitData', type="SCALAR")
            1:    oData1 = obj_new('IDLitDataIDLVector')
            2:    oData1 = obj_new('IDLitDataIDLArray2D')
            3:    oData1 = obj_new('IDLitDataIDLArray3D')
            else: oData1 = obj_new('IDLitData', type="ARRAY")
        endcase

        ; Create the Data object. Note that we need an index from
        ; our template fieldnames into the actual tags, in case the
        ; user chose to not return all fields. We could have used the
        ; structure tag name, but this preserves the lowercase.
        oData1->SetProperty, NAME=fieldNames[keep[i]]

        result = oData1->SetData(data.(i))
        if (~result) then begin
            OBJ_DESTROY, oData1
            ; Just keep going if we have a SetData error?
            continue
        endif

        if (nFields eq 1) then begin   ; We're done
            oBinaryData = oData1
            oBinaryData->SetProperty, $
                NAME=FILE_BASENAME(strFilename), DESCRIPTION=strFilename
            return, 1
        endif

        ; Add the data object to my container.
        oBinaryData->Add, oData1

    endfor

    return, 1

end


;;---------------------------------------------------------------------------
;; IDLitReadBinary::GetData
;;
;; Purpose:
;; Internal procedure for obtaining the properties of an image file.
;;
;; Parameters:
;; None.
;;
function IDLitReadBinary::GetData, oBinaryData
    compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       goto, ioerr  ;; do any cleanup needed
   endif
   on_ioerror, ioerr

    strFilename = self->GetFilename()

    ; BINARY_TEMPLATE
    success = self->_GetBinaryTemplateData(strFilename, $
        oBinaryData)

    return, success   ; could be -1, 0 or 1


ioerr: ;; IO Error handler

    self->SignalError, !error_state.msg, severity=2

    return, 0  ; error

end


;;---------------------------------------------------------------------------
;; IDLitReadBinary::Isa
;;
;; Purpose:
;;    Called to determine if this reader can read the give file.
;;
;; Returns true if this file is supported.
;;
function IDLitReadBinary::Isa, strFilename

    compile_opt idl2, hidden

    ; We can read *anything*.
    return, 1

end


;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitReadBinary__Define
;;
;; Purpose:
;; Class definition for the IDLitReadBinary class
;;
pro IDLitReadBinary__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadBinary, $
          inherits      IDLitReader,     $
          _pTemplate     : ptr_new()      $
         }
end
