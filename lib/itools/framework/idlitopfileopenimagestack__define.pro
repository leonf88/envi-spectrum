; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfileopenimagestack__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Read a set of image files and form a volume by stacking the images.
;   This is intended for use mainly by the volume tool.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
;-------------------------------------------------------------------------
function IDLitOpFileOpenImageStack::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if (~self->IDLitOpFileOpen::Init(_EXTRA=_SUPER)) then $
      return, 0

    return, 1
end


;---------------------------------------------------------------------------
; IDLitOpFileOpenImageStack::DoAction
;
; Purpose:
;    Read "stack" of image files, form volume data, and create a viz..
;
; Parameters:
;  oTool   - The tool we are operating in.
;
; Return Value
;   Command if created.
;
function IDLitOpFileOpenImageStack::DoAction, oTool, IDENTIFIER=identifier

    compile_opt idl2, hidden

    ; Get the vis create operation and create the visualizations.
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    if(not obj_valid(oCreateVis))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotCreateVizService')],  $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
    endif

    ; Do we have our File Reader service?
    oReadFile = oTool->GetService("READ_FILE")
    if(not obj_valid(oReadFile))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotAccessReaderService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
    endif

    ; Ask the UI service to present the file selection dialog to the user.
    ; The caller sets my filenames property before returning.
    ; This should also call my GetFilterList().
    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI
    if (showUI) then begin
        success = oTool->DoUIService('FileOpen', self)
        if (success eq 0) then $
            return, obj_new()
    endif

    ; check our filename cache
    nFiles = N_ELEMENTS(*self._fileNames)
    if(nFiles eq 0)then $
      return, obj_new()

    if(nFiles eq 1)then begin
        self->ErrorMessage, $
          title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
         [IDLitLangCatQuery('Error:Framework:NeedMoreFiles')]
        return, obj_new()
    endif

    ; Read data, accumulating each image into a volume
    nFilesRead = 0
    ; Repeat for each file selected by the user.
    for i=0, nFiles-1 do begin
        status = oReadFile->ReadFile((*self._fileNames)[i], oData)
        ; Throw an error message.
        if (status eq 0) then begin
            self->ErrorMessage, /USE_LAST_ERROR, $
              title=IDLitLangCatQuery('Error:Error:Title'), severity=2, $
              [IDLitLangCatQuery('Error:Framework:FileReadError'), $
              (*self._fileNames)[i]]
        endif
        ; User hit cancel or error occurred.
        if (status ne 1) then $
            continue
        ; We are really only going to deal with one image per file.
        oData = oData[0]
        ; We only deal with image data
        if not OBJ_ISA(oData, 'IDLitDataIDLImage') then $
            continue
        ; Use the only the first palette we find
        if N_ELEMENTS(paletteData) eq 0 then begin
            status = oData->GetData(paletteData, 'Palette')
        endif
        ; Now for the pixels
        status = oData->GetData(imagePixels, 'ImagePixels')
        if status eq 0 then continue
        imagePixels = REFORM(imagePixels)
        ; First image
        if N_ELEMENTS(volData0) eq 0 then begin
            nDims = SIZE(imagePixels, /N_DIMENSIONS)
            dims = SIZE(imagePixels, /DIMENSIONS)
            ; Single-channel (probably indexed) image
            if nDims eq 2 then begin
                volData0 = imagePixels
            endif else $
            ; RGB image
            if nDims eq 3 then begin
                volData0 = REFORM(imagePixels[0,*,*])
                volData1 = REFORM(imagePixels[1,*,*])
                volData2 = REFORM(imagePixels[2,*,*])
            endif
        endif $
        ; Add on the stacked images
        else begin
            if nDims ne SIZE(imagePixels, /N_DIMENSIONS) || $
               ARRAY_EQUAL(dims, SIZE(imagePixels, /DIMENSIONS)) eq 0 then begin
                ; Image files are not consistent - bail
                self->ErrorMessage, $
                title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
                    [IDLitLangCatQuery('Error:Framework:ImageInconsistentDims')]
                nFilesRead = 0
                break
            endif
            if nDims eq 2 then begin
                volData0 = [ [[volData0]], [[imagePixels]] ]
            endif else $
            if nDims eq 3 then begin
                volData0 = [ [[volData0]], [[REFORM(imagePixels[0,*,*])]] ]
                volData1 = [ [[volData1]], [[REFORM(imagePixels[1,*,*])]] ]
                volData2 = [ [[volData2]], [[REFORM(imagePixels[2,*,*])]] ]
            endif
        endelse
        nFilesRead++
    endfor

    ; We never received any data. Either all of the files were bad,
    ; or the user hit cancel on some dialog, or we were restoring
    ; a save state file.  Or there really wasn't an image file.
    if (nFilesRead eq 0 || N_ELEMENTS(volData0) eq 0) then $
        return, OBJ_NEW()

    ; We really do need to make a Parm Set so that the data gets
    ; associated with the right parameters.
    oParmSet = OBJ_NEW('IDLitParameterSet', NAME="Volume Image Stack")
    oVolData = OBJ_NEW('IDLitDataIDLArray3D', volData0, NAME='Image Channel 0')
    oParmSet->Add, oVolData, PARAMETER='VOLUME0'
    if N_ELEMENTS(volData1) gt 0 then begin ; must be 4-channel
        oVolData = OBJ_NEW('IDLitDataIDLArray3D', volData1, NAME='Image Channel 1')
        oParmSet->Add, oVolData, PARAMETER='VOLUME1'
        oVolData = OBJ_NEW('IDLitDataIDLArray3D', volData2, NAME='Image Channel 2')
        oParmSet->Add, oVolData, PARAMETER='VOLUME2'
        ; If we had RGB images, we are faced with the task of coming up with
        ; the 4th channel (opacity) for the volume data.  We use the NTSC
        ; formula to get something reasonable.
        volData3 = BYTE(volData0*0.299+volData1*0.587+volData2*0.114)
        oVolData = OBJ_NEW('IDLitDataIDLArray3D', volData3, NAME='Image Channel 3')
        oParmSet->Add, oVolData, PARAMETER='VOLUME3'
    endif

    ; Pass along the palette if we have one.
    if N_ELEMENTS(paletteData) gt 0 then begin
        oPalData = OBJ_NEW('IDLitDataIDLPalette', paletteData, NAME='Image palette')
        oParmSet->Add, oPalData, PARAMETER='RGB_TABLE0'
    endif

    ; Create the viz
    oTool->AddByIdentifier, "/Data Manager", oParmSet
    oVisCmd = oCreateVis->CreateVisualization(oParmSet->GetFullIdentifier())

    if (MIN(OBJ_VALID(oVisCmd)) eq 0) then begin
        self->ErrorMessage, /USE_LAST_ERROR, $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
        [IDLitLangCatQuery('Error:Framework:CannotCreateVizWithSelectedData')]
    endif

    return, oVisCmd

end


;-------------------------------------------------------------------------
pro IDLitOpFileOpenImageStack__define

    compile_opt idl2, hidden

    struc = {IDLitOpFileOpenImageStack,  $
        inherits IDLitOpFileOpen  $
        }

end

