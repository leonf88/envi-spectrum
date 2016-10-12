; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopvectorstreamline__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopVectorStreamline
;
; PURPOSE:
;   This file implements the operation that
;   creates streamline from vector data.
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
;   See IDLitopVectorStreamline::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopVectorStreamline::Init
;
; Purpose:
; The constructor of the IDLitopVectorStreamline object.
;
; Parameters:
;   None.
;
function IDLitopVectorStreamline::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if(self->IDLitOperation::Init(NAME="Streamline", $
        DESCRIPTION="IDL Streamline operation", $
        TYPES=["IDLVISVECTOR"], $
        NUMBER_DS='1', $
        /SHOW_EXECUTION_UI, $
        _EXTRA=_extra) eq 0)then $
        return, 0

    ; Register all properties.
    self->IDLitopVectorStreamline::_RegisterProperties

    self._xStreamParticles = 25
    self._yStreamParticles = 25
    self._streamStepsize = 0.2d
    self._streamNsteps = 100

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1
end


;-------------------------------------------------------------------------
;pro IDLitopVectorStreamline::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end


;----------------------------------------------------------------------------
; IDLitopVectorStreamline::_RegisterProperties
;
; Purpose:
;   Internal routine that will register all properties supported by
;   this object.
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitopVectorStreamline::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'X_STREAMPARTICLES', /INTEGER, $
            NAME='X stream particles', $
            DESCRIPTION='X stream particles', $
            VALID_RANGE=[2, 2e9]

        self->RegisterProperty, 'Y_STREAMPARTICLES', /INTEGER, $
            NAME='Y stream particles', $
            DESCRIPTION='Y stream particles', $
            VALID_RANGE=[2, 2e9]

        self->RegisterProperty, 'STREAMLINE_NSTEPS', /INTEGER, $
            NAME='Streamline steps', $
            DESCRIPTION='Streamline steps', $
            VALID_RANGE=[1,1e6]

        self->RegisterProperty, 'STREAMLINE_STEPSIZE', /FLOAT, $
            NAME='Streamline step size', $
            DESCRIPTION='Streamline step size', $
            VALID_RANGE=[0.05d, 2, 0.05d]

    endif

end


;----------------------------------------------------------------------------
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitopVectorStreamline::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitopVectorStreamline::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;-------------------------------------------------------------------------
; IDLitopVectorStreamline::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopVectorStreamline::GetProperty,        $
    STREAMLINE_NSTEPS=streamNsteps, $
    STREAMLINE_STEPSIZE=streamStepsize, $
    X_STREAMPARTICLES=xStreamParticles, $
    Y_STREAMPARTICLES=yStreamParticles, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(streamNsteps)) then $
        streamNsteps = self._streamNsteps

    if (ARG_PRESENT(streamStepsize)) then $
        streamStepsize = self._streamStepsize

    if (ARG_PRESENT(xStreamParticles)) then $
        xStreamParticles = self._xStreamParticles

    if (ARG_PRESENT(yStreamParticles)) then $
        yStreamParticles = self._yStreamParticles

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopVectorStreamline::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopVectorStreamline::SetProperty, $
    STREAMLINE_NSTEPS=streamNsteps, $
    STREAMLINE_STEPSIZE=streamStepsize, $
    X_STREAMPARTICLES=xStreamParticles, $
    Y_STREAMPARTICLES=yStreamParticles, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(streamNsteps) gt 0) then begin
        self._streamNsteps = streamNsteps
    endif

    if (N_ELEMENTS(streamStepsize) gt 0) then begin
        self._streamStepsize = streamStepsize
    endif

    if (N_ELEMENTS(xStreamParticles) gt 0) then begin
        self._xStreamParticles = xStreamParticles
    endif

    if (N_ELEMENTS(yStreamParticles) gt 0) then begin
        self._yStreamParticles = yStreamParticles
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopVectorStreamline::DoAction, oTool

    compile_opt idl2, hidden

    ; Get the selected objects.
    oSelVis = (oTool->GetSelectedItems())[0]

    if (~OBJ_VALID(oSelVis)) then $
        return, OBJ_NEW()

    oDataU = oSelVis->GetParameter('U component')
    oDataV = oSelVis->GetParameter('V component')
    if (~OBJ_VALID(oDataU) || ~OBJ_VALID(oDataU)) then RETURN, OBJ_NEW()

    ;; Is some UI needed prior to execution?
    self->GetProperty, SHOW_EXECUTION_UI=bShowExecutionUI
    hasPropSet = 0b
    if bShowExecutionUI then begin
        ; Record all of our initial registered property values.
        oPropSet = self->IDLitOperation::RecordInitialProperties()
        hasPropSet = OBJ_VALID(oPropSet)
        if (~oTool->DoUIService('PropertySheet', self)) then $
            goto, failure
        ; Record all of our final property values.
        if (hasPropSet) then $
            self->IDLitOperation::RecordFinalProperties, oPropSet
    endif

    void = oTool->DoUIService("HourGlassCursor", self)

    self->IDLitComponent::GetProperty, NAME=myname

    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME=myname + ' Data', $
        DESCRIPTION='Created by ' + myname)
    oParmSet->Add, oDataU, PARAMETER_NAME='U component', /PRESERVE_LOCATION
    oParmSet->Add, oDataV, PARAMETER_NAME='V component', /PRESERVE_LOCATION
    oDataX = oSelVis->GetParameter('X')
    if OBJ_VALID(oDataX) then begin
        oParmSet->Add, oDataX, PARAMETER_NAME='X', /PRESERVE_LOCATION
    endif
    oDataY = oSelVis->GetParameter('Y')
    if OBJ_VALID(oDataY) then begin
        oParmSet->Add, oDataY, PARAMETER_NAME='Y', /PRESERVE_LOCATION
    endif
    oPalette = oSelVis->GetParameter('PALETTE')
    if OBJ_VALID(oPalette) then begin
        oParmSet->Add, oPalette, PARAMETER_NAME='PALETTE', /PRESERVE_LOCATION
    endif

    oSelVis->GetProperty, DIRECTION_CONVENTION=directionConvention

    ; Create the visualization. Use _Create since we know the
    ; vis type (also avoids potential problems with type matching).
    oVisDesc = oTool->GetVisualization('Streamline')
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    oVisCommand = oCreateVis->_Create(oVisDesc, oParmSet, $
        DIRECTION_CONVENTION=directionConvention, $
        STREAMLINE_NSTEPS=self._streamNsteps, $
        STREAMLINE_STEPSIZE=self._streamStepsize, $
        X_STREAMPARTICLES=self._xStreamParticles, $
        Y_STREAMPARTICLES=self._yStreamParticles)

    oParmSet->Remove, /ALL
    OBJ_DESTROY, oParmSet

    ; Make a pretty undo/redo name.
    oVisCommand[N_ELEMENTS(oVisCommand)-1]->SetProperty, NAME=myname

    RETURN, hasPropSet ? [oPropSet, oVisCommand] : oVisCommand

failure:
    if (hasPropSet) then begin
        ; Undo all of our set properties.
        void = self->UndoOperation(oPropSet)
        OBJ_DESTROY, oPropSet
    endif
    return, obj_new()
end

;-------------------------------------------------------------------------
pro IDLitopVectorStreamline__define
    compile_opt idl2, hidden
    struc = {IDLitopVectorStreamline, $
        inherits IDLitOperation,    $
        _xStreamParticles: 0L, $
        _yStreamParticles: 0L, $
        _streamNsteps: 0L, $
        _streamStepsize: 0d $
        }
end

