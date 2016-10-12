; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitophistogram__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopHistogram
;
; PURPOSE:
;   This file implements the Histogram action.
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopHistogram::Init
;
; Purpose:
; The constructor of the IDLitopHistogram object.
;
; Parameters:
; None.
;
function IDLitopHistogram::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if ~self->IDLitOperation::Init( $
        NAME="Histogram", $
        DESCRIPTION="Histogram function", $
        NUMBER_DS='1', $
        TYPES=['IDLVECTOR', 'IDLARRAY2D', 'IDLARRAY3D', 'IDLIMAGE', $
            'IDLROI']) then $
        return, 0

    self._pDataList = PTR_NEW(/ALLOCATE_HEAP)
    return, 1
end

;---------------------------------------------------------------------------
; IDLitopHistogram::Cleanup
;
; Purpose:
; The destructor of the IDLitopHistogram object.
;
; Parameters:
; None.
;
pro IDLitopHistogram::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._pDataList

    ; Cleanup superclass.
    self->IDLitOperation::Cleanup
end

;---------------------------------------------------------------------------
; IDLitopHistogram::_ExecuteOnData
;
; Purpose:
;   Execute the operation on the given data object. This routine
;   will extract the expected data type and pass the value onto
;   the actual operation
;
; Parameters:
;   oData  - The data to operate on.
;
function IDLitopHistogram::_ExecuteOnData, oData, oDataOut

    compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, 0                ;cause a roll-back
   endif


    ; Quick checks to make sure we can get our required services.
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0


    ; Get the types this operation can operate on.
    self->IDLitOperation::GetProperty, TYPES=strTypes

    ; Loop thru our datatypes until we find a match.
    ; We don't want to match on all types because this might give
    ; us duplicate data (e.g. array2d's within an image)
    for i=0,N_ELEMENTS(strTypes)-1 do begin
        oDataItems = oData->GetByType(strTypes[i])
        if (OBJ_VALID(oDataItems[0])) then $
            break
    endfor

    ; Didn't find any matching types.
    if (~OBJ_VALID(oDataItems[0])) then $
        return, 0

    ; Loop through all the data we have.
    for i=0, N_ELEMENTS(oDataItems)-1 do begin

        ; Check if this data item has already been operated on.
        ; If so, skip.
        bSkip = 0b
        nVisit = N_ELEMENTS(*self._pDataList)
        if (nVisit gt 0) then begin
            for j=0, nVisit-1 do begin
                if ((*self._pDataList)[j] eq oDataItems[i]) then begin
                    bSkip = 1b
                    break
                endif
            endfor
            if (bSkip ne 0) then $
                continue
        endif

        oDataItems[i]->GetProperty, NAME=name

        ; Create our plot data object.
        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME=name + ' histogram', $
            ICON='plot', $
            DESCRIPTION='Histogram of ' + name, $
            TYPE='Plot')

        oParmSet->Add, oDataItems[i], PARAMETER_NAME='HISTOGRAM INPUT', $
            /PRESERVE_LOCATION

        ; Create some empty data objects. The data will be filled in
        ; within the histogram viz.
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', [51,52], $
            NAME=name + ' histogram values'), $
            PARAMETER_NAME='Y'
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', [1,10], $
            NAME=name + ' histogram locations'), $
            PARAMETER_NAME='X'

        oDataOut = (N_ELEMENTS(oDataOut) eq 0) ? $
            oParmSet : [oDataOut, oParmSet]

        ; Add current data to list of visited data items.
        *self._pDataList = (nVisit gt 0) ? $
            [*self._pDataList, oDataItems[i]] : oDataItems[i]
   endfor

   return, 1
end


;---------------------------------------------------------------------------
function IDLitopHistogram::_ExecuteOnTarget, oTarget, oDataOut

    compile_opt idl2, hidden

; Get the parameters that this target accepts. This is the set of data
; that the target contains.
;
   oParams= oTarget->GetOpTargets(COUNT=count)

   ; For each parameter, grab the data and execute the operation.
   for i=0, count-1 do begin
       oParams[i]->GetProperty, name=name
       oDataObj = oTarget->GetParameter(name)
       if(obj_valid(oDataObj))then begin
           if (~self->_ExecuteOnData(oDataObj, oDataOut)) then $
               return, 0
       endif
   endfor
   return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given ROI visualization.
;
; Parameters:
;   oVis  - The ROI Vis object to operate on.
;   Indent - String giving the current indent characters.
;
function IDLitopHistogram::_ExecuteOnROI, oVis, oDataOut

    compile_opt idl2, hidden

    oROIPixels = oVis->GetPixelData()
    oChannelPixelData = oROIPixels->Get(/ALL, COUNT=nChannels)
    for i=0,nChannels-1 do begin
        if (OBJ_VALID(oChannelPixelData[i])) then begin
            if (~self->_ExecuteOnData(oChannelPixelData[i], oDataOut)) then $
                return, 0
        endif
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopHistogram::DoAction
;
; Purpose: Perform (subclass) operation on all data objects that the
; subclass operation can handle in the selected visualization.
;
; Parameters:
; The Tool..
;
;-------------------------------------------------------------------------
function IDLitopHistogram::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; Get the selected objects.  (this will usually mean DataSpaces)
    oSelVis = oTool->GetSelectedItems(COUNT=count)
    if (count eq 0) then $
        return, obj_new()

    ; Get the types this operation can operate on.
    self->IDLitOperation::GetProperty, TYPES=strTypes

    ; Create our new histogram tool.
    newToolID = IDLitSys_CreateTool("Plot Tool", $
        NAME="Histogram",$
        TITLE='IDL iPlot Histogram')

    oNewTool = oTool->GetByIdentifier(newToolID)

    ; Clear out the list of visited data items.
    if (N_ELEMENTS(*self._pDataList) gt 0) then $
        void = TEMPORARY(*self._pDataList)

    ; Get the create viz operation.
    oCreateVis = oNewTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreateVis)) then $
        return, 0

    ; For each selected Visual
    for i=0, count-1 do begin
        ; Separate code for regions of interest.
        if (OBJ_ISA(oSelVis[i], 'IDLitVisROI')) then begin
            iStatus = self->IDLitopHistogram::_ExecuteOnROI(oSelVis[i], $
                oDataOut)
            continue
        endif
        if (~OBJ_ISA(oSelVis[i], 'IDLitParameter')) then $
            continue
        iStatus = self->_ExecuteOnTarget(oSelVis[i], oDataOut)
    endfor


    ; Create our visualizations.
    nData = N_ELEMENTS(oDataOut)

    for i=0,nData-1 do begin

        ; Cycle thru the colors if necessary.
        if (nData gt 1) then begin
            case (i mod 4) of
                0: color = [255,0,0]
                1: color = [0,255,0]
                2: color = [0,0,255]
                3: color = [0,0,0]
            endcase
        endif

        oDataOut[i]->IDLitComponent::GetProperty, NAME=dataname

        ; Create a separate plot line for each histogram.
        ; If there was only one histogram, make it filled and black.
        ; Otherwise, don't fill and use the colors from above.
        oCommandSet = oCreateVis->CreateVisualization(oDataOut[i], $
            "HISTOGRAM", $
            COLOR=color, $
            FILL_BACKGROUND=(nData eq 1), $
            ID_VISUALIZATION=idVis, $
            NAME=dataname)
        OBJ_DESTROY, oCommandSet   ; not undoable

        ; We don't want to keep our histogram input item within the
        ; parameter set, since it is coming from somewhere else.
        ; So after the viz is created, remove it. This assumes
        ; the histogram input is the first item.
        oDataOut[i]->Remove, POSITION=0

    endfor

    oNewTool->AddByIdentifier, "/Data Manager", oDataOut

    ; Clear out the list of visited data items.
    if (N_ELEMENTS(*self._pDataList) gt 0) then $
        void = TEMPORARY(*self._pDataList)

    return, OBJ_NEW()  ; not undoable
end


;-------------------------------------------------------------------------
pro IDLitopHistogram__define
    compile_opt idl2, hidden
    struc = {IDLitopHistogram, $
        inherits IDLitOperation, $
        _pDataList: PTR_NEW() $ ; Ptr to data items visited for current
                                ;  histogram operation.
        }

end

