; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/isave.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iSave
;
; PURPOSE:
;   Saves the selected visualization to an image file
;
; PARAMETERS:
;   FILENAME - The name of the file to open
;
; KEYWORDS:
;   SAVE_AS - If set, and filename is not supplied, then always prompt for a
;             new filename. The default is to mimic the behaviour of 
;             File->Save; if the tool has already been saved to a file, then
;             save to the file again, overwriting the old file, without
;             prompting for a new filename.
;
;   RESOLUTION - The output resolution in dots-per-inch (dpi).
;             The default is to use the iTools resolution preference.
;
;   TARGET_IDENTIFIER - The identifier of the window, or iTool to save. If set
;                       to an item that is not a tool or window, the window
;                       that encompasses the defined object will be used. If
;                       not supplied the current iTool will be used.
;
;-

;-------------------------------------------------------------------------
pro iSave, strFileIn, $
           BITMAP=bitmapIn, $
           SAVE_AS=saveAs, $
           RESOLUTION=resolutionIn, $
           TARGET_IDENTIFIER=ID, $
           TOOL=toolIn, $
           _EXTRA=_extra
  compile_opt hidden, idl2

@idlit_itoolerror.pro

  strFile = (N_ELEMENTS(strFileIn) gt 0 ? strFileIn[0] : '')

  ;; Set up parameters
  fullId = (N_ELEMENTS(ID) eq 0) ? iGetCurrent() : iGetID(ID[0], TOOL=toolIn)

  ;; Error checking
  if (fullID[0] eq '') then begin
    message, 'Target not found: '+ID
    return
  endif

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  ;; Get the object from ID
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  ;; Get the tool
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then return
  
  ;; Get the save operation
  oDesc = oTool->GetByIdentifier('OPERATIONS/FILE/SAVE')
  oSave = oDesc->GetObjectInstance() 

  oSave->SetProperty, FILENAME=strFile
  
  ;; If save as, then always show ui (CT: leave this as an &&)
  if ((strFile eq '') && KEYWORD_SET(saveAs)) then begin
    oSave->GetProperty, SHOW_EXECUTION_UI=oldShowUI
    oSave->SetProperty, SHOW_EXECUTION_UI=1
  endif
  
  ;; Output resolution
  if (N_ELEMENTS(resolutionIn) ne 0) then begin
    resolution = DOUBLE(resolutionIn[0])
    oGeneral = oTool->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
    if (Obj_Valid(oGeneral)) then begin
      oGeneral->GetProperty, RESOLUTION=oldResolution
      oGeneral->SetProperty, RESOLUTION=resolution
    endif
  endif
  
  if (ISA(bitmapIn)) then begin
    bitmap = KEYWORD_SET(bitmapIn)
  endif else begin
    ; If any of the contained dataspaces are 3D, then switch from
    ; vector rendering to bitmap rendering.
    id = iGetID('Data Space*', TOOL=oTool->GetFullIdentifier())
    for i=0,N_Elements(id)-1 do begin
      if (id[i] eq '') then continue
      oDS = oTool->GetByIdentifier(id[i])
      if (obj_Valid(oDS) && oDS->Is3D()) then begin
        bitmap = 1
        break
      endif
    endfor
  endelse
    
  
  ;; Do it
  void = oSave->DoAction(oTool, SUCCESS=success, BITMAP=bitmap, _EXTRA=_extra)

  ;; Reset output resolution, if it was changed temporarily
  if ((N_ELEMENTS(resolutionIn) ne 0) && OBJ_VALID(oGeneral)) then begin
    oGeneral->SetProperty, RESOLUTION=oldResolution
  endif

  ;; Reset show execution flag
  if (success) then begin
    oSave->SetProperty, SHOW_EXECUTION_UI=0
  endif else begin
    oSave->SetProperty, SHOW_EXECUTION_UI=oldShowUI
  endelse
    
end
