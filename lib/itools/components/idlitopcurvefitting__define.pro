; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopcurvefitting__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopCurveFitting
;
; PURPOSE:
;   This file implements the Curve Fitting action.
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
;   See IDLitopCurveFitting::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopCurveFitting::Init
;
; Purpose:
; The constructor of the IDLitopCurveFitting object.
;
; Parameters:
; None.
;
function IDLitopCurveFitting::Init, _EXTRA=_extra
    ; Pragmas
    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init( $
        NAME="Curve Fitting", $
        DESCRIPTION="IDL Curve Fitting", $
        NUMBER_DS='1', $
        TYPES=['IDLVECTOR'])) then $
        return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    models = self->GetModels()
    self->RegisterProperty, 'MODEL', $
        ENUMLIST=models.name, $
        NAME='Model name', $
        DESCRIPTION='Model name'

    self->RegisterProperty, 'PARAMETER_A', /FLOAT, $
       NAME='Parameter A', $
       DESCRIPTION='Value for parameter A'

    self->RegisterProperty, 'PARAMETER_B', /FLOAT, $
       NAME='Parameter B', $
       DESCRIPTION='Value for parameter B'

    self->RegisterProperty, 'PARAMETER_C', /FLOAT, $
       NAME='Parameter C', $
       DESCRIPTION='Value for parameter C'

    self->RegisterProperty, 'PARAMETER_D', /FLOAT, $
       NAME='Parameter D', $
       DESCRIPTION='Value for parameter D'

    self->RegisterProperty, 'PARAMETER_E', /FLOAT, $
       NAME='Parameter E', $
       DESCRIPTION='Value for parameter E'

    self->RegisterProperty, 'PARAMETER_F', /FLOAT, $
       NAME='Parameter F', $
       DESCRIPTION='Value for parameter F'

    ; Force model to zero to pick up property attribute changes.
    self->SetProperty, MODEL=0, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; IDLitopCurveFitting::Cleanup
;
; Purpose:
; The destructor of the IDLitopCurveFitting object.
;
; Parameters:
; None.
;
pro IDLitopCurveFitting::Cleanup
    ; Pragmas
    compile_opt idl2, hidden

    PTR_FREE, self._pX
    PTR_FREE, self._pY
    PTR_FREE, self._pError

    self->IDLitOperation::Cleanup
end


;-------------------------------------------------------------------------
; IDLitopCurveFitting::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopCurveFitting::GetProperty, $
    DATAX=datax, $
    DATAY=datay, $
    MEASURE_ERRORS=measureErrors, $
    MODEL=model, $
    PARAMETER_A=paramA, $
    PARAMETER_B=paramB, $
    PARAMETER_C=paramC, $
    PARAMETER_D=paramD, $
    PARAMETER_E=paramE, $
    PARAMETER_F=paramF, $
    PARAMETERS=parameters, $
    SIGMA=sigma, $
    _REF_EXTRA=_extra

    ; Pragmas
    compile_opt idl2, hidden

    if (ARG_PRESENT(datax)) then $
        datax = PTR_VALID(self._pX) ? *self._pX : 0

    if (ARG_PRESENT(datay)) then $
        datay = PTR_VALID(self._pY) ? *self._pY : 0

    if (ARG_PRESENT(measureErrors)) then $
        measureErrors = PTR_VALID(self._pError) ? *self._pError : 0

    if (ARG_PRESENT(model)) then $
        model = self._model

    if (ARG_PRESENT(paramA)) then $
        paramA = self._parameters[0]

    if (ARG_PRESENT(paramB)) then $
        paramB = self._parameters[1]

    if (ARG_PRESENT(paramC)) then $
        paramC = self._parameters[2]

    if (ARG_PRESENT(paramD)) then $
        paramD = self._parameters[3]

    if (ARG_PRESENT(paramE)) then $
        paramE = self._parameters[4]

    if (ARG_PRESENT(paramF)) then $
        paramF = self._parameters[5]

    if (ARG_PRESENT(parameters)) then $
        parameters = self._parameters

    if (ARG_PRESENT(sigma)) then $
        sigma = self._sigma

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopCurveFitting::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopCurveFitting::SetProperty, $
    MODEL=model, $
    PARAMETER_A=paramA, $
    PARAMETER_B=paramB, $
    PARAMETER_C=paramC, $
    PARAMETER_D=paramD, $
    PARAMETER_E=paramE, $
    PARAMETER_F=paramF, $
    PARAMETERS=parameters, $
    _EXTRA=_extra

    ; Pragmas
    compile_opt idl2, hidden

    if (N_ELEMENTS(model) eq 1) then begin
        self._model = model
        models = self->GetModels()
        nparam = (models[self._model]).nparam
        for i=0,5 do begin
            self->SetPropertyAttribute, $
                'PARAMETER_' + (['A','B','C','D','E','F'])[i], $
                SENSITIVE=i lt nparam
        endfor
    endif

    if (N_ELEMENTS(paramA) eq 1) then $
        self._parameters[0] = paramA

    if (N_ELEMENTS(paramB) eq 1) then $
        self._parameters[1] = paramB

    if (N_ELEMENTS(paramC) eq 1) then $
        self._parameters[2] = paramC

    if (N_ELEMENTS(paramD) eq 1) then $
        self._parameters[3] = paramD

    if (N_ELEMENTS(paramE) eq 1) then $
        self._parameters[4] = paramE

    if (N_ELEMENTS(paramF) eq 1) then $
        self._parameters[5] = paramF

    n = N_ELEMENTS(parameters)
    if (n gt 0) then $
        self._parameters[0:n-1] = parameters

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopCurveFitting::GetModels

    compile_opt hidden

    model = {IDLitopCurveFitModel, $
        name: '', $
        equation: '', $
        display_eqn: '', $
        nparam: 0, $  ; number of required *input* params
        xmin: 0d, $   ; suggested minimum X for sample data
        xmax: 0d}     ; suggested maximum X for sample data

    models = [ $
        {IDLitopCurveFitModel, 'Linear', 'A + B*x', $
            'A + Bx', 0, 0, 1} $
        , {IDLitopCurveFitModel, 'Quadratic', 'A + B*x + C*x^2', $
            'A + Bx + Cx!u2', 0, 0, 1} $
        , {IDLitopCurveFitModel, 'Cubic', 'A+B*x+C*x^2+D*x^3', $
            'A + Bx + Cx!u2!n + Dx!u3!n', 0, 0, 1} $
        , {IDLitopCurveFitModel, 'Quartic', 'A+B*x+C*x^2+D*x^3+E*x^4', $
            'A + Bx + Cx!u2!n + Dx!u3!n + Ex!u4!n', 0, 0, 1} $
        , {IDLitopCurveFitModel, 'Quintic', $
            'A+B*x+C*x^2+D*x^3+E*x^4+F*x^5', $
            'A + Bx + Cx!u2!n + Dx!u3!n + Ex!u4!n + Fx!u5!n', 0, 0, 1} $
        , {IDLitopCurveFitModel, 'Exponential', 'A + B*C^x', $
            'A + BC!ux', 3, 0, 1} $
        , {IDLitopCurveFitModel, 'Gompertz', 'A + B*C^(D*x)', $
            'A + BC!uDx', 4, 0, 1} $
        , {IDLitopCurveFitModel, 'Logsquare', $
            'A + B*alog10(x)+C*alog10(x^2)', $
            'A + B log!d10!n(x) + C log!d10!n(x!u2!n)', 3, 0.01d, 1} $
        , {IDLitopCurveFitModel, 'Hyperbolic', '1/(A + B*x)', $
            '1/(A + Bx)', 2, 0, 10} $
        , {IDLitopCurveFitModel, 'Hyperbolic trigonometric', $
            'A + B*sinh(C*x) + D*cosh(E*x)', $
            'A + Bsinh(Cx) + Dcosh(Ex)', 5, 0, 10} $
        , {IDLitopCurveFitModel, 'Logistic', '1/(A + B*C^x)', $
            '1/(A + BC!ux!n)', 3, -10, 10} $
        , {IDLitopCurveFitModel, 'Geometric', 'A + B*x^C', $
            'A + Bx!uC', 3, 0, 10} $
        , {IDLitopCurveFitModel, 'Trigonometric summation', $
            'A + B*sin(C*x) + D*cos(E*x)', $
            'A + Bsin(Cx) + Dcos(Ex)', 5, -10, 10} $
        , {IDLitopCurveFitModel, 'Trigonometric product', $
            'A + B*sin(C*x)*cos(D*x)', $
            'A + Bsin(Cx)cos(Dx)', 4, -10, 10} $
        , {IDLitopCurveFitModel, 'Variable sinc', $
            'A + sin(B*x)/(C*x)', 'A + sin(Bx)/(Cx)', 3, -20, 20} $
        , {IDLitopCurveFitModel, 'Gaussian', $
            'A*exp(-((x-B)/C)^2/2)', $
            'Aexp(-z!u2!n/2), z=(x-B)/C', 0, -2, 2} $
        , {IDLitopCurveFitModel, 'Gaussian + constant', $
            'A*exp(-((x-B)/C)^2/2) + D', $
            'Aexp(-z!u2!n/2) + D, z=(x-B)/C', 0, -2, 2} $
        , {IDLitopCurveFitModel, 'Gaussian + linear', $
            'A*exp(-((x-B)/C)^2/2) + D + E*x', $
            'Aexp(-z!u2!n/2) + D + Ex, z=(x-B)/C', 0, -2, 2} $
        , {IDLitopCurveFitModel, 'Gaussian + quadratic', $
            'A*exp(-((x-B)/C)^2/2) + D + E*x + F*x^2', $
            'Aexp(-z!u2!n/2) + D + Ex + Fx!u2!n, z=(x-B)/C', 0, -2, 2} $
            ]

    return, models
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Exponential, x, a, f, pder
    compile_opt hidden
    f = a[1] * a[2]^x + a[0]
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [a[2]^x], $
        [a[1] * x * a[2]^(x-1)]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Logsquare, x, a, f, pder
    compile_opt hidden
    b = alog10(x)
    b2 = b^2
    f = a[0] + a[1] * b + a[2] * b2
    if n_params() ge 4 then $
        pder = [[replicate(1., n_elements(x))], [b], [b2]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Gompertz, x, a, f, pder
  compile_opt hidden
  f = a[0] + a[1]*a[2]^(a[3]*x)
  if n_params() ge 4 then pder = [ $
    [replicate(1., n_elements(x))], $
    [a[2]^(a[3]*x)], $
    [a[1] * a[3] * x * a[2]^(a[3]*x - 1)], $
    [a[1] * x * alog(a[2]) * a[2]^(a[3]*x)]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Hyperbolic, x, a, f, pder
    compile_opt hidden
    f = 1.0 / (a[0] + a[1] * x)
    if n_params() ge 4 then $
        pder = [[-1.0 / (a[0] + a[1] * x)^2], [-x / (a[0] + a[1] * x)^2]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Logistic, x, a, f, pder
    compile_opt hidden
    f = 1.0 / (a[1] * a[2]^x + a[0])
    if n_params() ge 4 then begin
        denom =  -1.0/(a[1] * a[2]^x + a[0])^2
        pder = [[denom], [a[2]^x*denom], [a[1] * x * a[2]^(x-1)*denom]]
    endif
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_Geometric, x, a, f, pder
    compile_opt hidden
    f = a[1] * x^a[2] + a[0]
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [x^a[2]], $
        [a[1] * alog(x) * x^a[2]]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_HyperbolicTrigonometric, x, a, f, pder
    compile_opt hidden
    f = a[0] + a[1]*sinh(a[2]*x) + a[3]*cosh(a[4]*x)
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [sinh(a[2]*x)], $
        [a[1]*x*cosh(a[2]*x)], $
        [cosh(a[4]*x)], $
        [a[3]*x*sinh(a[4]*x)]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_TrigonometricSummation, x, a, f, pder
    compile_opt hidden
    f = a[0] + a[1]*sin(a[2]*x) + a[3]*cos(a[4]*x)
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [sin(a[2]*x)], $
        [a[1]*x*cos(a[2]*x)], $
        [cos(a[4]*x)], $
        [-a[3]*x*sin(a[4]*x)]]

end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_TrigonometricProduct, x, a, f, pder
    compile_opt hidden
    f = a[0] + a[1]*sin(a[2]*x)*cos(a[3]*x)
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [sin(a[2]*x)*cos(a[3]*x)], $
        [a[1]*x*cos(a[2]*x)*cos(a[3]*x)], $
        [-a[1]*x*sin(a[2]*x)*sin(a[3]*x)]]
end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting_VariableSinc, x, a, f, pder
    compile_opt hidden
    f = a[0] + sin(a[1]*x)/(a[2]*x)
    if n_params() ge 4 then pder = [ $
        [replicate(1., n_elements(x))], $
        [cos(a[1]*x)/a[2]], $
        [-sin(a[1]*x)/(a[2]^2*x)]]
end


;---------------------------------------------------------------------------
; IDLitopCurveFitting::_CurveFit
;
; Purpose: Perform the curve fitting.
;
; Parameters:
; None.
;
function IDLitopCurveFitting::_CurveFit, xData, yData, errData, yFit, $
    CHISQ=chisq

    compile_opt idl2, hidden

    nData = N_ELEMENTS(yData)
    if (nData ne N_ELEMENTS(xData)) then $
        return, 0  ; failure

    if (N_ELEMENTS(errData) eq nData) then $
        measureErrors = errData

    nparam = 0
    status = 0
    self->GetPropertyAttribute, 'MODEL', ENUMLIST=modelnames
    modelname = STRLOWCASE(modelnames[self._model])

    ; Any pending exceptions?
    checkmath = CHECK_MATH(/NOCLEAR)
    quiet = !QUIET
    !QUIET = 1

    switch STRLOWCASE(modelname) of

        'linear':   if ~nparam then nparam = 1
        'quadratic':if ~nparam then nparam = 2
        'cubic':    if ~nparam then nparam = 3
        'quartic':  if ~nparam then nparam = 4
        'quintic': begin
                    if ~nparam then nparam = 5
                    parameters = POLY_FIT(xData, yData, $
                        nparam, $
                        CHISQ=chisq, $
                        MEASURE_ERRORS=measureErrors, $
                        SIGMA=sigma, $
                        YFIT=yFit)
                    break
                   end

        'trigonometric summation':  if ~nparam then nparam = 5
        'hyperbolic trigonometric': if ~nparam then nparam = 5
        'trigonometric product':    if ~nparam then nparam = 4
        'hyperbolic':               if ~nparam then nparam = 2
        'exponential':              if ~nparam then nparam = 3
        'gompertz':                 if ~nparam then nparam = 4
        'logsquare':                if ~nparam then nparam = 3
        'logistic':                 if ~nparam then nparam = 3
        'geometric':                if ~nparam then nparam = 3
        'variable sinc': begin
                    if ~nparam then nparam = 3
                    parameters = self._parameters[0:nparam-1]
                    weights = (N_ELEMENTS(measureErrors) eq nData) ? $
                        1/measureErrors^2 : DBLARR(nData) + 1
                    fcn = 'IDLitopCurveFitting_' + $
                        STRCOMPRESS(modelname, /REMOVE)
                    yFit = CURVEFIT(xData, yData, weights, $
                        parameters, sigma, $
                        CHISQ=chisq, $
                        FUNCTION_NAME=fcn, $
                        ITMAX=100, $
                        STATUS=status)
                    ; Convert back from "reduced" chi-square by multiplying
                    ; by the degrees of freedom.
                    chisq *= (nData - nparam)
                    break
                    end

        'gaussian':             if ~nparam then nparam = 3
        'gaussian + constant':  if ~nparam then nparam = 4
        'gaussian + linear':    if ~nparam then nparam = 5
        'gaussian + quadratic': begin
                    if ~nparam then nparam = 6
                    yFit = GAUSSFIT(xData, yData, parameters, $
                        CHISQ=chisq, $
                        MEASURE_ERRORS=measureErrors, $
                        NTERMS=nparam, $
                        SIGMA=sigma)
                    ; Convert back from "reduced" chi-square by multiplying
                    ; by the degrees of freedom.
                    chisq *= (nData - nparam)
                    break
                    end

    endswitch

    ; Cache our new parameter values.
    self._parameters = 0
    n = N_ELEMENTS(parameters)
    self._parameters[0:n-1] = parameters

    ; Cache our new sigma values.
    self._sigma = 0
    n = N_ELEMENTS(sigma)
    self._sigma[0:n-1] = sigma

    ; Replace any non-finite values with zero. Hope this is okay.
    if (N_ELEMENTS(yfit) gt 0) then begin
        bad = WHERE(~FINITE(yfit), nbad)
        if (nbad gt 0) then $
            yfit[bad] = 0
    endif

    ; If there were no other pending exceptions, quietly clear ours.
    if (checkmath eq 0) then $
        dummy = CHECK_MATH()
    !QUIET = quiet

    return, (status eq 0)
end


;---------------------------------------------------------------------------
; IDLitopCurveFitting::_ExecuteOnData
;
; Purpose:
;   Execute the operation on the given data object. This routine
;   will extract the expected data type and pass the value onto
;   the actual operation
;
; Parameters:
;   oData  - The data to operate on.
;
pro IDLitopCurveFitting::_ExecuteOnData, xData, oData, errData, oDataOut

    compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return ; do nothing
   endif


    ; Quick checks to make sure we can get our required services.
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return


    ; Get the types this operation can operate on.
    oDataItems = oData->GetByType('IDLVECTOR')
    if (~OBJ_VALID(oDataItems[0])) then $
        return

    ; Loop through all the data we have.
    for i=0, n_elements(oDataItems)-1 do begin

        if (~oDataItems[i]->GetData(yData)) then $
            return

        if (N_ELEMENTS(xData) le 1) then $
            xData = DINDGEN(N_ELEMENTS(yData))

        ; Replace any non-finite values with zero. Hope this is okay.
        if (N_ELEMENTS(yData) gt 0) then begin
            bad = WHERE(~FINITE(yData), nbad)
            if (nbad gt 0) then $
                yData[bad] = 0
        endif


        self->SetProperty, DATAY=ydata

        self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI
        if (showExecutionUI) then begin
            ; Only fire up the dialog for the first selected item.
            firstTime = N_ELEMENTS(oDataOut) eq 0
            if (firstTime) then begin
                if (~PTR_VALID(self._pX)) then $
                    self._pX = PTR_NEW(/ALLOCATE)
                if (~PTR_VALID(self._pY)) then $
                    self._pY = PTR_NEW(/ALLOCATE)
                if (~PTR_VALID(self._pError)) then $
                    self._pError = PTR_NEW(/ALLOCATE)
                *self._pX = xData
                *self._pY = yData
                *self._pError = errData
                if (~oTool->DoUIService('CurveFitting', self)) then $
                    return
            endif
        endif else firstTime = 1


        ; We need to catch errors here...

        if (~self->_CurveFit(xData, yData, errData, yfit, CHISQ=chisq)) then $
            return


        ; Create our plot data object.
        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME='Plot parameters', $
            DESCRIPTION='Plot parameters')
        oDataX = OBJ_NEW('IDLitDataIDLVector', xData, NAME='X')
        oParmSet->Add, oDataX, PARAMETER_NAME='X'
        oDataY = OBJ_NEW('IDLitDataIDLVector', yfit, NAME='Y')
        oParmSet->Add, oDataY, PARAMETER_NAME='Y'
        oTool->AddByIdentifier, "/Data Manager", oParmSet

        oDataOut = firstTime ? oParmSet : [oDataOut, oParmSet]

   endfor

end


;---------------------------------------------------------------------------
pro IDLitopCurveFitting::_ExecuteOnTarget, oTarget, oDataOut

    compile_opt idl2, hidden

    ; Skip visualizations that don't have parameters (like dataspaces).
    if (~OBJ_ISA(oTarget, 'IDLitParameter')) then $
        return

; Get the parameters that this target accepts. This is the set of data
; that the target contains.
;
   oParams= oTarget->GetOpTargets(COUNT=count)

   ; See if we have an X (independent var) parameter.
   oXdata = oTarget->GetParameter('X')
   if (~OBJ_VALID(oXdata) || ~oXdata->GetData(xData)) then $
        xData = 0

    ; See if we have a Y error parameter.
    oYerror = oTarget->GetParameter('Y ERROR')
    if (~OBJ_VALID(oYerror) || ~oYerror->GetData(errData)) then $
        errData = 0

    oYdata = oTarget->GetParameter('Y')
    if (~OBJ_VALID(oYdata)) then $
        return

    self->_ExecuteOnData, xData, oYdata, errData, oDataOut

end


;---------------------------------------------------------------------------
; IDLitopCurveFitting::DoAction
;
; Purpose: Perform (subclass) operation on all data objects that the
; subclass operation can handle in the selected visualization.
;
; Parameters:
; The Tool..
;
;-------------------------------------------------------------------------
function IDLitopCurveFitting::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; Get the create viz operation.
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreateVis)) then $
        return, 0

    ; Get the selected objects.  (this will usually mean DataSpaces)
    oSelVis = oTool->GetSelectedItems(count=nSelVis)
    if (nSelVis eq 0) then $
        return, obj_new()


    ; For each selected Visual
    for iSelVis=0, nSelVis-1 do $
        self->_ExecuteOnTarget, oSelVis[iSelVis], oDataOut


    if (N_ELEMENTS(oDataOut) eq 0) then $
        return, OBJ_NEW()

    ; Create all our visualizations at once, so we have one command obj.
    oCommandSet = oCreateVis->CreateVisualization(oDataOut, $
        NAME='Curvefit', $
        REPLICATE("PLOT", N_ELEMENTS(oDataOut)))

    ; Override default name.
    for i=0,N_ELEMENTS(oCommandSet)-1 do $
        oCommandSet[i]->SetProperty, NAME='Curve Fit'

    return, oCommandSet
end


;-------------------------------------------------------------------------
pro IDLitopCurveFitting__define
   compile_opt idl2, hidden
    struc = {IDLitopCurveFitting, $
             inherits IDLitOperation, $
             _model: 0, $
             _parameters: DBLARR(6), $
             _sigma: DBLARR(6), $
             _pX: PTR_NEW(), $
             _pY: PTR_NEW(), $
             _pError: PTR_NEW() $
            }

end

