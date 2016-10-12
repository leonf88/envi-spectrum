; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrorangechange__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroRangeChange
;
; PURPOSE:
;   This file implements the operation that changes the range
;   of the current data spaces.  It is for use in macros
;   and history when a user uses the range box, range pan or
;   range zoom manipulators.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroRangeChange::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroRangeChange::Init
;   IDLitopMacroRangeChange::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroRangeChange::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroRangeChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRangeChange::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Range Change", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X_MINIMUM', /FLOAT, $
        NAME='X minimum', $
        DESCRIPTION='X minimum'

    self->RegisterProperty, 'X_MAXIMUM', /FLOAT, $
        NAME='X maximum', $
        DESCRIPTION='X maximum'

    self->RegisterProperty, 'Y_MINIMUM', /FLOAT, $
        NAME='Y minimum', $
        DESCRIPTION='Y minimum'

    self->RegisterProperty, 'Y_MAXIMUM', /FLOAT, $
        NAME='Y maximum', $
        DESCRIPTION='Y maximum'

    self->RegisterProperty, 'Z_MINIMUM', /FLOAT, $
        NAME='Z minimum', $
        DESCRIPTION='Z minimum'

    self->RegisterProperty, 'Z_MAXIMUM', /FLOAT, $
        NAME='Z maximum', $
        DESCRIPTION='Z maximum'

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroRangeChange::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroRangeChange::GetProperty, $
    X_MINIMUM=xMin, X_MAXIMUM=xMax, $
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
    Z_MINIMUM=zMin, Z_MAXIMUM=zMax, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(xMin)) then $
        xMin = self._xMin

    if (arg_present(xMax)) then $
        xMax = self._xMax

    if (arg_present(yMin)) then $
        yMin = self._yMin

    if (arg_present(yMax)) then $
        yMax = self._yMax

    if (arg_present(zMin)) then $
        zMin = self._zMin

    if (arg_present(zMax)) then $
        zMax = self._zMax

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroRangeChange::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroRangeChange::SetProperty,      $
    X_MINIMUM=xMin, X_MAXIMUM=xMax, $
    Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
    Z_MINIMUM=zMin, Z_MAXIMUM=zMax, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(xMin) ne 0) then begin
        self._xMin = xMin
    endif

    if (N_ELEMENTS(xMax) ne 0) then begin
        self._xMax = xMax
    endif

    if (N_ELEMENTS(yMin) ne 0) then begin
        self._yMin = yMin
    endif

    if (N_ELEMENTS(yMax) ne 0) then begin
        self._yMax = yMax
    endif

    if (N_ELEMENTS(zMin) ne 0) then begin
        self._zMin = zMin
    endif

    if (N_ELEMENTS(zMax) ne 0) then begin
        self._zMax = zMax
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroRangeChange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroRangeChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroRangeChange::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroRangeChange::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroRangeChange::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    idTool = oToolCurrent->GetFullIdentifier()

    oSelected = oToolCurrent->GetSelectedItems()
    if (~OBJ_VALID(oSelected))then $
        return, obj_new()

    oSetXYZOp = oToolCurrent->GetService('SET_XYZRANGE')
    if (~OBJ_VALID(oSetXYZOp))then begin
        return, obj_new()
    endif

    ;; get the range zoom manipulator in order to get the manipulator
    ;; targets (data spaces).  Range pan or range box would also work.
    oManipDataRange = oToolCurrent->getByIdentifier( $
        idTool+'/MANIPULATORS/DATA RANGE')
    if (~OBJ_VALID(oManipDataRange))then $
        return, obj_new()

    oSelected = oManipDataRange->_FindManipulatorTargets(oSelected)
    bFirst = 1b
    for i=n_elements(oSelected)-1, 0, -1 do begin

        oDS = oSelected[i]->GetDataSpace(/UNNORMALIZED)
        if (~OBJ_VALID(oDS)) then $
            continue
        ; Use the normalized dataspace to record the operations -
        ; the unnormalized one is private.
        oNormDS = oSelected[i]->GetDataSpace()
        if (~OBJ_VALID(oNormDS)) then $
            continue

        ; The Data Range macro is applied as follows:
        ;
        ; The recorded X/Y data ranges are used to define the new range
        ; for the first dataspace.
        ;
        ; The recorded X/Y range is also converted to window coordinates,
        ; then back to data coordinates for each of the subsequent
        ; dataspaces.  Thus, the same window coordinate box is applied
        ; to all dataspaces (just as is true for the data range box
        ; manipulator).

        if (bFirst eq 1b) then begin
            ; Transform the locations to window coordinates (so that
            ; all other dataspaces can convert to their own corresponding
            ; ranges).
            xyStart = [self._xMin, self._yMin]
            xyEnd = [self._xMax, self._yMax]
            oDS->_IDLitVisualization::VisToWindow, $
                xyStart, xyWinStart
            oDS->_IDLitVisualization::VisToWindow, $
                xyEnd, xyWinEnd
            bFirst = 0b
        endif else begin

            ; Transform the location to dataspace coordinates.
            oDS->_IDLitVisualization::WindowToVis, $
                xyWinStart, xyStart
            oDS->_IDLitVisualization::WindowToVis, $
                xyWinEnd, xyEnd
        endelse

        ; Switch min/max order if necessary.
        if (xyStart[0] lt xyEnd[0]) then begin
            xmin = xyStart[0]
            xmax = xyEnd[0]
        endif else begin
            xmin = xyEnd[0]
            xmax = xyStart[0]
        endelse
        if (xyStart[1] lt xyEnd[1]) then begin
            ymin = xyStart[1]
            ymax = xyEnd[1]
        endif else begin
            ymin = xyEnd[1]
            ymax = xyStart[1]
        endelse

        ; Valid rectangle?
        if ((xmax gt xmin) and (ymax gt ymin)) then begin
            oDS->_GetXYZAxisReverseFlags, xReverse, yReverse, zReverse
            oCmdSet = obj_new("IDLitCommandSet", NAME='Range Change', $
                                    OPERATION_IDENTIFIER= $
                                    oSetXYZOp->getFullIdentifier())

            iStatus = oSetXYZOp->RecordInitialValues(oCmdSet, $
                oNormDS, 'XYZ_RANGE')

            ;; Set Range to the new values.
            oDS->SetProperty, $
                X_MINIMUM=(xReverse ? xmax : xmin), $
                X_MAXIMUM=(xReverse ? xmin : xmax), $
                Y_MINIMUM=(yReverse ? ymax : ymin), $
                Y_MAXIMUM=(yReverse ? ymin : ymax)

            iStatus = oSetXYZOp->RecordFinalValues(oCmdSet, $
                oNormDS, 'XYZ_RANGE', /SKIP_MACROHISTORY)

            oCmdSets = (N_ELEMENTS(oCmdSets) gt 0) ? $
                [oCmdSets, oCmdSet] : oCmdSet
        endif
    endfor

    return, (N_ELEMENTS(oCmdSets) gt 0) ? oCmdSets : OBJ_NEW()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroRangeChange__define

    compile_opt idl2, hidden

    void = {IDLitopMacroRangeChange, $
            inherits IDLitOperation, $
            _xMin: 0D     , $
            _xMax: 0D     , $
            _yMin: 0D     , $
            _yMax: 0D     , $
            _zMin: 0D     , $
            _zMax: 0D       $
                        }
end

