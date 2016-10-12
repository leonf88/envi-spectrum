; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertaxis__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertAxis
;
; PURPOSE:
;   This file implements the insert Axis operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertAxis::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopInsertAxis::Init
;   IDLitopInsertAxis::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopInsertAxis::Init
;;
;; Purpose:
;; The constructor of the IDLitopInsertAxis object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertAxis::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(NUMBER_DS='1', _EXTRA=_extra)
end


;;---------------------------------------------------------------------------
;; IDLitopInsertAxis::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertAxis::DoAction, oTool, DIRECTION=direction

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTargets)

    if (nTargets eq 0) then begin
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
          return, OBJ_NEW()
        oView = oWindow->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
    endif else begin
        ; Find a first valid dataspace that contains one of the targets.
        oDataSpace = OBJ_NEW()
        for i=0, nTargets-1 do begin
            if (not OBJ_VALID(oTargets[i])) then $
                continue
            oDataSpace = oTargets[i]->GetDataSpace()
            if (OBJ_VALID(oDataSpace)) then $
                break
        endfor
    endelse

    if (OBJ_VALID(oDataSpace) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:NoDataSpace:Text')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:NoDataSpace:Title')
        return, OBJ_NEW()
    endif

    ; Prepare the service that will create the axis visualization.
    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (not OBJ_VALID(oCreate)) then $
        return, OBJ_NEW();

    oDataSpaceUnNorm = oDataSpace->GetDataSpace(/UNNORMALIZED)
    oAxes = (oDataSpaceUnNorm->Get(/ALL, ISA='IDLitVisDataAxes'))[0]
    if (~OBJ_VALID(oAxes)) then $
        return, OBJ_NEW();
    destination = oAxes->GetFullIdentifier()
    oAxisDesc = oTool->GetVisualization("AXIS")

    oAxes->GetProperty, $
        XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange

    case direction of
    0: begin     ; X axis
         range = xRange
         location = [0, yRange[0]-(yRange[1]-yRange[0])/10.0, $
                         zRange[0]]
         normLocation = [0, -0.1, 0]
    end
    1: begin     ; Y axis
         range = yRange
         location = [xRange[0]-(xRange[1]-xRange[0])/10.0, 0, $
                     zRange[0]]
         normLocation = [-0.1, 0, 0]
    end
    2: begin     ; Z axis
         range = zRange
         location = [xRange[0]-(xRange[1]-xRange[0])/10.0, $
                     yRange[0], 0]
         normLocation = [-0.1, 0, 0]
    end
    else:
    endcase

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    oCommand = oCreate->_Create( $
                        oAxisDesc, $
                        DESTINATION=destination, $
                        DIRECTION=direction, $
                        ID_VISUALIZATION=idVis, $
                        RANGE = range, $
                        LOCATION = location, $
                        TICKLEN=0.05, $ ; initial default
                        NORM_LOCATION=normLocation, $
                        /MANIPULATOR_TARGET)

    oVis = oTool->GetByIdentifier(idVis)
    if OBJ_VALID(oVis) then oAxes->Aggregate, oVis

    oAxes->_UpdateAxesRanges

    if (~wasDisabled) then $
        oTool->EnableUpdates

    return, oCommand

end


;-------------------------------------------------------------------------
pro IDLitopInsertAxis__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertAxis, $
        inherits IDLitOperation}

end

