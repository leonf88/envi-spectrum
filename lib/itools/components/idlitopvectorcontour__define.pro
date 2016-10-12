; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopvectorcontour__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopVectorContour
;
; PURPOSE:
;   This file implements the operation that
;   creates contours from vector data.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitOperation
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopVectorContour::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopVectorContour::Init
;
; Purpose:
; The constructor of the IDLitopVectorContour object.
;
; Parameters:
;   None.
;
function IDLitopVectorContour::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if(self->IDLitOperation::Init(NAME="Vector Contour", $
        DESCRIPTION="IDL Vector Contour operation", $
        TYPES=["IDLVISVECTOR", "IDLVISSTREAMLINE"], $
        NUMBER_DS='1', $
        /SHOW_EXECUTION_UI, $
        _EXTRA=_extra) eq 0)then $
        return, 0

    return, 1
end

;-------------------------------------------------------------------------
;pro IDLitopVectorContour::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end

;----------------------------------------------------------------------------
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitopVectorContour::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitopVectorContour::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end

;---------------------------------------------------------------------------
function IDLitopVectorContour::DoAction, oTool

    compile_opt idl2, hidden

    ; Get the selected objects.
    oSelVis = (oTool->GetSelectedItems())[0]

    if (~OBJ_VALID(oSelVis)) then $
        return, OBJ_NEW()

    self->IDLitComponent::GetProperty, IDENTIFIER=myid
    isMagnitude = (myid eq 'CONTOURMAGNITUDE')
    myname = isMagnitude ? 'Magnitude' : 'Direction'
    oSelVis->IDLitComponent::GetProperty, NAME=visname

    oDataU = oSelVis->GetParameter('U component')
    oDataV = oSelVis->GetParameter('V component')
    if (~OBJ_VALID(oDataU) || ~OBJ_VALID(oDataU)) then return, OBJ_NEW()

    void = oTool->DoUIService("HourGlassCursor", self)

    if (~oDataU->GetData(udata) || $
        ~oDataV->GetData(vdata)) then return, OBJ_NEW()

    oVisDesc = oTool->GetVisualization('Contour')
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oVisDesc) || ~OBJ_VALID(oCreateVis)) then $
        return, OBJ_NEW()

    oDataX = oSelVis->GetParameter('X')
    oDataY = oSelVis->GetParameter('Y')
    if (OBJ_VALID(oDataX) && OBJ_VALID(oDataY)) then begin
        ; Make a copy of the X and Y data, just to keep it together
        ; with the magnitude or direction data.
        if (oDataX->GetData(x)) then begin
            if (~oDataY->GetData(y)) then begin
                ; We must have both X and Y. If Y is missing, kill X.
                void = TEMPORARY(x)
            endif
        endif
    endif

    ; Sanity check. If U and V are vectors then we must have
    ; X and Y with same # of elements.
    is1d = SIZE(udata, /N_DIM) eq 1
    if (is1d && N_ELEMENTS(x) ne N_ELEMENTS(udata)) then $
        return, OBJ_NEW()

    ; If one-dimensional, then automatically regrid.
    if (is1d) then begin
        n = 100
        udata = GRIDDATA(x, y, udata, DIMENSION=[n,n])
        vdata = GRIDDATA(x, y, vdata, DIMENSION=[n,n])
        minn = MIN(x, MAX=maxx)
        x = (DINDGEN(n)/(n-1))*(maxx - minn) + minn
        minn = MIN(y, MAX=maxx)
        y = (DINDGEN(n)/(n-1))*(maxx - minn) + minn
    endif

    if (isMagnitude) then begin
        result = SQRT(udata^2 + vdata^2)
    endif else begin
        oSelVis->GetProperty, DIRECTION_CONVENTION=directionConvention
        case (directionConvention) of
        ; Meteorological, from which the wind is blowing, 0 to 360
        1: begin
            result = (180/!PI)*ATAN(-udata, -vdata)
            result += 360*(result lt 0)
           end
        ; Wind azimuths, towards which the wind is blowing, 0 to 360
        2: begin
            result = (180/!PI)*ATAN(udata, vdata)
            result += 360*(result lt 0)
           end
        ; Polar angle, -180 to +180
        else: result = (180/!PI)*ATAN(vdata, udata)
        endcase
    endelse

    ; Choose nice contour levels.
    if (isMagnitude) then begin
        minn = MIN(result, MAX=maxx)
        cvalues = (FINDGEN(11)/10)*(maxx - minn) + minn
    endif else begin
        c = [30, 60, 90, 120, 150]
        cvalues = [-REVERSE(c), 0, c]
    endelse

    oParmSet = OBJ_NEW('IDLitParameterSet', NAME=visname + ' ' + myname, $
        DESCRIPTION='Created by ' + myname)
    oResult = OBJ_NEW('IDLitDataIDLArray2d', result, NAME=myname)
    oParmSet->Add, oResult, PARAMETER_NAME='Z'

    if (N_ELEMENTS(x) gt 0) then begin
        oDataX = OBJ_NEW('IDLitDataIDLVector', x, NAME='X')
        oParmSet->Add, oDataX, PARAMETER_NAME='X'
        oDataY = OBJ_NEW('IDLitDataIDLVector', y, NAME='Y')
        oParmSet->Add, oDataY, PARAMETER_NAME='Y'
    endif

    oTool->AddByIdentifier, "/Data Manager", oParmSet

    oSelVis->GetProperty, GRID_UNITS=gridUnits, ZVALUE=zvalue

    ; Create the visualization. Use _Create since we know the
    ; vis type (also avoids potential problems with type matching).
    oVisCommand = oCreateVis->_Create(oVisDesc, oParmSet, $
        NAME=myname, $
        C_VALUE=cvalues, GRID_UNITS=gridUnits, ZVALUE=zvalue)

    ; Make a pretty undo/redo name.
    idx = N_ELEMENTS(oVisCommand) - 1
    if (OBJ_VALID(oVisCommand[idx])) then $
        oVisCommand[idx]->SetProperty, NAME=myname

    return, oVisCommand

end

;-------------------------------------------------------------------------
pro IDLitopVectorContour__define
    compile_opt idl2, hidden
    struc = {IDLitopVectorContour, $
        inherits IDLitOperation $
        }
end

