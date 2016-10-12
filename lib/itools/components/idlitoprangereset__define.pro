; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprangereset__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopRangeReset
;
; Purpose:
;   This class implements a range reset operation.  A range reset
;   operation resets the auto-compute flags for the X, Y, and Z
;   ranges for the target dataspaces so that those ranges will be
;   automatically recomputed based upon the bounds of the contained
;   visualizations.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::Init
;
; Purpose:
;   The constructor of the IDLitopRangeReset object.
;
; Arguments:
;   None.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.
;
function IDLitopRangeReset::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(NAME="Data Range Reset", $
        DESCRIPTION='Reset data range to fit all visualizations', $
        TYPES=['_VISUALIZATION'], $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::Cleanup
;
; Purpose:
;   The descructor for the IDLitopRangeReset object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
;pro IDLitopRangeReset::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitOperation::Cleanup
;end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::GetProperty
;
; Arguments:
;   <None>
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to
;   IDLitopRangeReset::Init followed by the word "Get" can be retrieved
;   using this method.
;
;pro IDLitopRangeReset::GetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::GetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::SetProperty
;
; Arguments:
;   <None>
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to
;   IDLitopRangeReset::Init followed by the word "Set" can be set
;   using this method.
;
;pro IDLitopRangeReset::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Pixel Scale Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::_Targets
;
; Purpose:
;   This internal function method retrieves the list of targets
;   for this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this
;     operation is being performed.
;
; Keywords:
;   COUNT:	Set this keyword to a named variable that upon
;     return will contain the number of returned targets.
;
; Outputs:
;   This function returns a vector of object references to
;   the targets found for this operation.
;
function IDLitopRangeReset::_Targets, oTool, COUNT=count

    compile_opt idl2, hidden

    count = 0

    if (OBJ_VALID(oTool) eq 0) then $
        return, OBJ_NEW()

    ; Retrieve the currently selected item(s) in the tool.
    oTargets = oTool->GetSelectedItems(count=nTargets)
    if (nTargets eq 0) then $
      return, OBJ_NEW()
    if (OBJ_VALID(oTargets[0]) eq 0) then $
        return, OBJ_NEW()

    for i=0,nTargets-1 do begin
      oDataspace = oTargets[i]->GetDataspace()
      if (OBJ_VALID(oDataspace)) then $
        oDSs = (i eq 0) ? [oDataSpace] : [oDSs, oDataSpace]
    endfor
    
    ;; remove reduntant dataspaces
    oDSs = oDSs[UNIQ(oDSs, SORT(oDSs))]

    count = N_ELEMENTS(oDSs)

    return, oDSs
end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopRangeReset::DoAction
;
; Purpose:
;   This function method performs the primary action associated with
;   this operation, namely to reset the data ranges.
;
; Arguments:
;   oTool:	A reference to the tool object in which this operation
;     is to be performed.
;
; Outputs:
;   This function returns a reference to the command set object
;   corresponding to the act of performing this operation.
;
function IDLitopRangeReset::DoAction, oTool

    compile_opt idl2, hidden

    self->_SetTool, oTool

    ; Retrieve the current selected item(s).
    oManipTargets = self->IDLitopRangeReset::_Targets(oTool, COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()
        
    ; Retrieve our SetProperty service.
    oSetXYZOp = oTool->GetService('SET_XYZRANGE')
    if (not OBJ_VALID(oSetXYZOp)) then $
        return, OBJ_NEW()
  
    for i=0,count-1 do begin
      oDataSpace = oManipTargets[i]
      oUnNormDataSpace = oDataSpace->GetDataSpace(/UNNORMALIZED)
      if (OBJ_VALID(oUnNormDataSpace) eq 0) then $
          continue
  
      oCmd = OBJ_NEW('IDLitCommandSet', $
          NAME='Data Range Reset', $
          OPERATION_IDENTIFIER=oSetXYZOp->GetFullIdentifier())
  
      iStatus = oSetXYZOp->RecordInitialValues(oCmd, $
          oDataSpace, 'XYZ_RANGE')
      if (~iStatus) then begin
          OBJ_DESTROY, oCmd
          continue
      endif
  
      oDataSpace->SetProperty, X_AUTO_UPDATE=1, Y_AUTO_UPDATE=1, $
          Z_AUTO_UPDATE=1
      oUnNormDataSpace->OnDataChange, oUnNormDataSpace
      oUnNormDataSpace->OnDataComplete, oUnNormDataSpace
  
      iStatus = oSetXYZOp->RecordFinalValues( oCmd, $
          oDataSpace, 'XYZ_RANGE')
          
      oCmds = (N_ELEMENTS(oCmds) eq 0) ? [oCmd] : [oCmds, oCmd]
    endfor
    
    oTool->DoOnNotify, oDataSpace->GetFullIdentifier(), $
        'SETPROPERTY', 'XYZ_RANGE'

    return, oCmds

end


;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
pro IDLitopRangeReset__define

    compile_opt idl2, hidden

    struc = {IDLitopRangeReset,    $
        inherits IDLitOperation,   $
        _scale: 0.0                $ ; Number of image pixels per
                                   $ ;   display pixels.
    }

end

