; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopclexport__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopCLExport
;
; PURPOSE:
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopCLExport::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopCLExport::Init
;   IDLitopCLExport::Cleanup
;   IDLitopCLExport::GetProperty
;   IDLitopCLExport::SetProperty
;   IDLitopCLExport::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopCLExport::Init
;;
;; Purpose:
;; The constructor of the IDLitopCLExport object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopCLExport::Init, _EXTRA=_SUPER
  compile_opt idl2, hidden

  self._pData = ptr_new(/allocate_heap)
  return, self->idlitOperation::Init(TYPE="VISUALIZATION", NUMBER_DS='1', $
                                     _EXTRA=_SUPER)

end

;-------------------------------------------------------------------------
;; IDLitopCLExport::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopCLExport object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopCLExport::Cleanup
  compile_opt idl2, hidden

  ptr_free,self._pData
  self->IDlitOperation::Cleanup

end


;-------------------------------------------------------------------------
;; IDLitopCLExport::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopCLExport::GetProperty, pData=pData, $
                                  _REF_EXTRA=_SUPER
  ;; Pragmas
  compile_opt idl2, hidden

  if ARG_PRESENT(pData) then $
    pData = *self._pData

  if(n_elements(_SUPER) gt 0)then $
    self->IDLitOperation::GetProperty, _EXTRA=_SUPER

end

;-------------------------------------------------------------------------
;; IDLitopCLExport::SetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopCLExport::SetProperty, pData=pData, $
                                  _EXTRA=_SUPER

  compile_opt idl2, hidden

  if N_ELEMENTS(pData) NE 0 then $
    *self._pData = pData

  if(n_elements(_SUPER) gt 0)then $
    self->IDLitOperation::SetProperty, _extra=_super

END


;;---------------------------------------------------------------------------
;; IDLitopCLExport::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopCLExport::DoAction, oTool
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, obj_new()
  endif

  setVarNames = '' ;; list of set var names

  ;; Plan of action:
  ;;   - Get the selected visualizations
  ;;      - For each parameter, get the data
  ;;          - For each data element, copy it to the main scope of
  ;;               IDL

  oItems = oTool->GetSelectedItems(count=nItems)

  if ((nItems eq 0) OR $
      ((nItems eq 1) AND $
       (OBJ_ISA(oItems[0], 'IDLitVisIDataSpace')))) THEN BEGIN
      oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return, OBJ_NEW()
    oView = oWindow->GetCurrentView()
    oLayer = oView->GetCurrentLayer()
    oWorld = oLayer->GetWorld()
    oDataSpace = oWorld->GetCurrentDataSpace()
    oItems = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
    if (count eq 0) then return, OBJ_NEW()
  endif

  ;; Get
  self->StatusMessage, IDLitLangCatQuery('Status:Framework:ExportingData')
  for i=0, n_elements(oItems)-1 do begin
    IF ~obj_valid(oItems[i]) || ~obj_isa(oItems[i],'IDLitVisualization') $
      THEN CONTINUE

    oItems[i]->GetProperty, name=strName

    parameters = oItems[i]->QueryParameter(COUNT=nparam)

    for j=0, nparam-1 do begin

        ; Get the name of the parameter and it's data object
        oItems[i]->GetParameterAttribute, parameters[j], NAME=strParamName

        oData = oItems[i]->GetParameter(strParamName)
        if (~obj_valid(oData))then $
            continue

        ; Descend into containers, except ImagePixels.
        if (obj_isa(oData, "IDLitDataContainer") && $
            ~obj_isa(oData,'IDLitDataIDLImagePixels')) then begin

            strData = oData->FindIdentifiers(/LEAF_NODES)
            nData = n_elements(strData)
            recs = replicate({_IDLit$clExportRec_}, nData)
            for k=0, nData-1 do begin
                oTmp = oData->GetByIdentifier(strData[k])
                oTmp->IDLitComponent::GetProperty, name=name
                recs[k].strName = name
                recs[k].strParamName = strParamName[0]
                recs[k].oData = oTmp
            endfor

        endif else begin

            if (~oData->GetSize()) then $
                continue
            oData->IDLitComponent::GetProperty, NAME=name
            recs = {_IDLit$clExportRec_, name, strParamName[0], oData}

        endelse

        *self._pData = (n_elements(*self._pData) gt 0 ? $
                        [*self._pData, recs] : $
                        temporary(recs))

    ENDFOR
  endfor

  IF n_elements(*self._pData) NE 0 THEN BEGIN
    if (~oTool->DoUIService('CommandLineExport', self)) then BEGIN
        void = temporary(*self._pData)
        return, obj_new()
    ENDIF
  ENDIF ELSE BEGIN
      return, obj_new()
  ENDELSE
  ;; do the hourglass
  void=  oTool->DoUIService("HourGlassCursor", self)
  ;; Get the command line service
  oCL = oTool->GetService("COMMAND_LINE")
  status = 1
  sData = *self._pData
  FOR i=0,n_elements(sData)-1 DO $
    status <= oCL->ExportDataToCL(sData[i].oData, $
                                  sData[i].variableName)
  ;; clear out data list
  void = temporary(*self._pData)

   ;; Check our status.
  if (status eq 0)then begin ;; unknow error
      self->ErrorMessage, SEVERITY=2, $
        [ IDLitLangCatQuery('Error:Framework:UnknownError') + $
	    IDLitLangCatQuery('Error:Framework:UnknownErrorCL') + $
	    IDLitLangCatQuery('Error:Framework:UnableToCompleteExport')]
  endif

  return, obj_new()

end

;-------------------------------------------------------------------------

pro IDLitopCLExport__define
  compile_opt idl2, hidden

  struc = {IDLitopCLExport,           $
           inherits IDLitOperation,   $
           _pData:ptr_new()}
  void = {_IDLit$CLExportRec_, strName: '', strParamName: '', oData:obj_new()}

END
