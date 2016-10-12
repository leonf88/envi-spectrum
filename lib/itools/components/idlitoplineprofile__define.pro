; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoplineprofile__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopLineProfile
;
; PURPOSE:
;   This file implements the operation invoked by the line profile
;   manipulator to obtain cursor input and determine endpoints for
;   a line profile visualization.  It then launches the plot profile
;   operation to take the specified endpoints and actually create
;   the line profile visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopLineProfile::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopLineProfile::Init
;   IDLitopLineProfile::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopLineProfile::Init
;;
;; Purpose:
;; The constructor of the IDLitopLineProfile object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopLineProfile::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Line Profile", $
                                       DESCRIPTION="Line Profile", $
                                       TYPES=['IDLIMAGE','IDLSURFACE'], $
                                       NUMBER_DS='1', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X0', /FLOAT, $
        NAME='X Start', $
        DESCRIPTION='X Start'

    self->RegisterProperty, 'Y0', /FLOAT, $
        NAME='Y Start', $
        DESCRIPTION='Y Start'

    self->RegisterProperty, 'X1', /FLOAT, $
        NAME='X End', $
        DESCRIPTION='X End'

    self->RegisterProperty, 'Y1', /FLOAT, $
        NAME='Y End', $
        DESCRIPTION='Y End'

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopLineProfile::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopLineProfile::GetProperty,        $
    X0=x0, $
    Y0=y0, $
    X1=x1, $
    Y1=y1, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(x0)) then $
        x0 = self._x0

    if (ARG_PRESENT(y0)) then $
        y0 = self._y0

    if (arg_present(x1)) then $
        x1 = self._x1

    if (ARG_PRESENT(y1)) then $
        y1 = self._y1

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopLineProfile::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopLineProfile::SetProperty,      $
    X0=x0, $
    Y0=y0, $
    X1=x1, $
    Y1=y1, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(x0) ne 0) then begin
        self._x0 = x0
    endif

    if (N_ELEMENTS(y0) ne 0) then begin
        self._y0 = y0
    endif

    if (N_ELEMENTS(x1) ne 0) then begin
        self._x1 = x1
    endif

    if (N_ELEMENTS(y1) ne 0) then begin
        self._y1 = y1
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopLineProfile::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopLineProfile object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopLineProfile::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end





;;---------------------------------------------------------------------------
;; IDLitopLineProfile::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopLineProfile::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    oSelVis = oTool->GetSelectedItems()
    oSelVis = OBJ_VALID(oSelVis[0]) ? oSelVis[0] : OBJ_NEW()
    if ~(obj_isa(oSelVis, 'IDLitVisImage') || $
         obj_isa(oSelVis, 'IDLitVisSurface')) then return, obj_new()

    ;; Display dialog as a propertysheet
    IF self._bShowExecutionUI THEN BEGIN
        success = oTool->DoUIService('PropertySheet', self)
        IF success EQ 0 THEN $
            return,obj_new()
    ENDIF

    pt0 = [self._x0, self._y0, 0]
    pt1 = [self._x1, self._y1, 0]

    ; get Z from surface
    if obj_valid(oSelVis) && obj_isa(oSelVis, 'IDLitVisSurface') then begin
        z0 = oSelVis->_IDLitVisGrid2D::GetZValue(self._x0, self._y0)
        pt0[2]=z0
        z1 = oSelVis->_IDLitVisGrid2D::GetZValue(self._x1, self._y1)
        pt1[2]=z1
    endif

    pts = [[pt0],[pt1]]

    IF obj_isa(oSelVis, 'IDLitVisSurface') THEN BEGIN
      oDescNew = oTool->GetAnnotation('Line Profile 3D')
    ENDIF ELSE BEGIN
      oDescNew = oTool->GetAnnotation('Line Profile')
    ENDELSE
    oLine = oDescNew->GetObjectInstance()

    ; create these parameters for use by superclass
    oData = OBJ_NEW("IDLitDataIDLArray2D", NAME='Line Verts', /PRIVATE)
    void = oLine->SetData(oData, PARAMETER_NAME= 'LINE', $
        /BY_VALUE)
    oData = OBJ_NEW("IDLitDataIDLArray2D", NAME='Line Points', /PRIVATE)
    void = oLine->SetData(oData, PARAMETER_NAME= 'LINE3D', $
        /BY_VALUE)

    oWin = oTool->getCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()
    oLine->SetProperty, $
        ASSOCIATED_VISUALIZATION=oSelVis->GetFullIdentifier()
    oWin->Add, oLine
    oLine->SetProperty, _DATA=pts

    ; now run the plot profile operation
    idSrc = "Operations/Operations/Plot Profile"
    oDescOpPlotProfile = oTool->GetByIdentifier(idSrc)
    oOpPlotProfile = oDescOpPlotProfile->GetObjectInstance()
    oOpPlotProfile->SetProperty, /LINEPROFILEOP_INVOCATION

    oSrvMacro = oTool->GetService('MACROS')
    oSrvMacro->GetProperty, CURRENT_NAME=currentName
    oSrvMacro->PasteMacroOperation, self, currentName

    ; now launch the plot profile
    oLine->Select, /SKIP_MACRO
    oCmd = oOpPlotProfile->DoAction(oTool)

    ; return invocation flag of singleton to default
    oOpPlotProfile->SetProperty, LINEPROFILEOP_INVOCATION=0

    return, OBJ_NEW()   ; not undoable
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopLineProfile__define

    compile_opt idl2, hidden

    void = {IDLitopLineProfile, $
            inherits IDLitOperation, $
            _x0: 0.0D     , $
            _y0: 0.0D     , $
            _x1: 0.0D     , $
            _y1: 0.0D       $
                        }
end

