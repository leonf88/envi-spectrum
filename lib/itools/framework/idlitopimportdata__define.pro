; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopimportdata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopImportData
;
; PURPOSE:
;   This class implements an operation that is used to run the import
;   data wizard.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopImportData::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopImportData::Init
;   IDLitopImportData::Cleanup
;   IDLitopImportData::GetProperty
;   IDLitopImportData::SetProperty
;   IDLitopImportData::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopImportData::Init
;;
;; Purpose:
;; The constructor of the IDLitopImportData object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopImportData::Init, _EXTRA=_SUPER
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_SUPER)
end

;-------------------------------------------------------------------------
;; IDLitopImportData::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopImportData object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopImportData::Cleanup
    compile_opt idl2, hidden
    self->IDLitOperation::Cleanup
end




;;---------------------------------------------------------------------------
;; IDLitopImportData::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopImportData::DoAction, oTool

   ;; Pragmas
   compile_opt idl2, hidden

   ;; Put op in empty state
   self._bSet=0
   ;; Launch the wizard.
   success = oTool->DoUIService('DataImportWizard', self)
   if( success eq 0 )then $
     return, obj_new()

   ;; Get the create vis operation
   oCreate = oTool->GetService("CREATE_VISUALIZATION")
   if(not obj_valid(oCreate))then begin
       self->ErrorMessage, $
         [IDLitLangCatQuery('Error:Framework:CannotCreateVizService')], $
         title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
       return, obj_new()
   endif
   ;; Determine what to do. This information is set by the wizard.

   case self._iType of
       ;; Import data from the command line
       1: begin
           status =0
           ;; The information that was set is an identifier in the
           ;; current command line hierachy. Get the heirarchy and
           ;; import the variable into the data manager
           oCL = oTool->GetService("COMMAND_LINE")
           if(not obj_valid(oCL))then begin
               self->ErrorMessage, $
                 [IDLitLangCatQuery('Error:Framework:CannotAccessCommandLine')], $
                 title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
               return, obj_new()
           endif

           ;; Get the descriptors for the command line
           oCLroot = oCL->GetCLVariableDescriptors()
           if(obj_valid(oCLRoot))then begin
               oDesc = oCLroot->GetByIdentifier(self._strData)
               if(obj_valid(oDesc))then $
                 status = oCL->ImportToDMbyDescriptor(oCLRoot, oDesc, $
                                                      name=self._strname, $
                                                      identifier=Data, $
                                                      data_type=self._dataType)
               oCL->ReturnCLDescriptors, oCLRoot
               ;; If import failed.
           endif
           if(status eq 0)then begin
               self->ErrorMessage, $
                 [IDLitLangCatQuery('Error:Framework:CannotAccessCLData'), $
         IDLitLangCatQuery('Error:Framework:AbortOp')], $
                 severity=1, title=IDLitLangCatQuery('Error:InternalError:Title')
               return, obj_new()
           endif
       end
       ;; Import data from a file
       0: begin
           ;; Open the given file and place in the data manager.
           ;; Do we have our File Reader service?
           oReadFile = oTool->GetService("READ_FILE")
           if(not obj_valid(oReadFile))then begin
               self->ErrorMessage, $
                 [IDLitLangCatQuery('Error:Framework:CannotAccessReaderService')], $
                 title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
               return, obj_new()
           endif

           status = oReadFile->ReadFile(self._strData, oData)
            ; Throw an error message.
            if (status eq 0) then begin
                self->ErrorMessage, /USE_LAST_ERROR, $
                  title=IDLitLangCatQuery('Error:Error:Title'), severity=2, $
                  [IDLitLangCatQuery('Error:Framework:FileReadError'), $
                  self._strData]
            endif
           ; User hit cancel or error occurred.
           if (status ne 1) then $
               return, OBJ_NEW()
           nData = n_elements(oData)
           data = strarr(nData)
           for i=0, nData-1 do begin
               ;; Add data to the data manager!
               oTool->AddByIdentifier, "/Data Manager", oData[i]
               data[i] = oData[i]->GetFullIdentifier()
           endfor
       end
   endcase

   ; If <Default> then don't pass in anything for idVis.
   ; Otherwise replicate our vis descriptor name.
   if (self._idVis ne '') then $
    idVis = replicate(self._idVis, n_elements(data))

   oVisCmd = oCreate->CreateVisualization(data, idVis)

   return,  oVisCmd
end


;;-------------------------------------------------------------------------
;; IDLitopImportData::SetImportParameters
;;
;; Purpose:
;;   Method for the import prameters to be set. This is normally done
;;   by an external entity.
;;
;; Parameters:
;;    iType   - type of import 0-file, 1-CL
;;
;;    data    - Data to import. Either a file name or id to a CL
;;              variable
;;
;;    idVis   - The type of visualization to create
;;
;; Keywords:
;;   NAME  - Name for the data object.
;;
;;   DATA_TYPE - String representing name of data type to be used to
;;     import the data.
;;
pro IDLitopImportData::SetImportParameters, iType, Data, idVis, $
    NAME=name, $
    DATA_TYPE=dataType

    compile_opt idl2, hidden

    self._iType = iType
    self._strData = Data
    self._idVis = idVis
    self._strName = (keyword_set(NAME) ? name : '')
    self._dataType = (keyword_set(dataType) ? dataType : '')
    self._bSet = 1

end
;-------------------------------------------------------------------------
;; Definition
pro IDLitopImportData__define
    compile_opt idl2, hidden
    struc = {IDLitopImportData,            $
             inherits IDLitOperation,    $
             _iType   : 0,  $  ; Type of import
             _strData : '', $  ; data source
             _idVis   : '', $  ; id of vis to use
             _strName : '', $  ; Name for the data object
             _dataType: '', $  ; Data type to be used for import
             _bSet    : 0}     ; values  set?


end
