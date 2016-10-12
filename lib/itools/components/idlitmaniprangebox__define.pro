; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprangebox__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipRangeBox
;
; PURPOSE:
;   The IDLitManipRangeBox class represents a manipulator used to modify
;   the XYZ range of one or more target dataspace objects.  The dataspace
;   range modification occurs by clicking and dragging a bounding box.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipRangeBox::Init
;
; PURPOSE:
;   The IDLitManipRangeBox::Init function method initializes the
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   oManipulator = OBJ_NEW('IDLitManipRangeBox')
;
;-
function IDLitManipRangeBox::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE='Range', $
        IDENTIFIER="RANGE_BOX", $
        OPERATION_IDENTIFIER="SET_XYZRANGE", $
        NAME="Range Box", $
        /SKIP_MACROHISTORY, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Initialize pointers.
    self._pStartXY = PTR_NEW(/ALLOCATE_HEAP)
    self._pRects = PTR_NEW(/ALLOCATE_HEAP)

    ; Register the default cursor for this manipulator.
    self->IDLitManipRangeBox::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipRangeBox::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipRangeBox::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro IDLitManipRangeBox::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    PTR_FREE, self._pStartXY
    PTR_FREE, self._pRects

    self->IDLitManipulator::Cleanup
end


;--------------------------------------------------------------------------
; IDLitManipRangeBox::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., dataspaces) to be manipulated by this manipulator
;   (based upon the given list of visualizations current selected).
;
; Keywords:
;   MERGE
;     Note: this keyword is ignored for this manipulator because
;     we only want dataspaces to be considered manipulator targets.
;
function IDLitManipRangeBox::_FindManipulatorTargets, oVisIn, $
    MERGE=merge

    compile_opt idl2, hidden

    nVis = N_ELEMENTS(oVisIn)
    if (nVis eq 0) then return, OBJ_NEW()
    if (OBJ_VALID(oVisIn[0]) eq 0) then $
        return, OBJ_NEW()

    oLayer = oVisIn[0]->_GetLayer()
    if (OBJ_VALID(oLayer) eq 0) then $
        return, OBJ_NEW()
    if (OBJ_ISA(oLayer, 'IDLitGrAnnotateLayer')) then $
       return, OBJ_NEW()

    oTool = self->GetTool()
    oWin = OBJ_VALID(oTool) ? oTool->GetCurrentWindow() : OBJ_NEW()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()
    oWorld = OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW()
    oDataSpaces = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW()

    return, oDataSpaces
end

;--------------------------------------------------------------------------
;+
; IDLitManipRangeBox::_DisableAutoUpdates
;
; Purpose:
;   This procedure method disables auto-updates of the XYZ Ranges
;   for each target dataspace.
;-
pro IDLitManipRangeBox::_DisableAutoUpdates

    compile_opt idl2, hidden

    nDS = self.nSelectionList

    if (nDS gt 0) then begin
        for i=0,nDS-1 do begin
            oDS = (*self.pSelectionList)[i]
            oDS->SetProperty, $
                X_AUTO_UPDATE=0, $
                Y_AUTO_UPDATE=0, $
                Z_AUTO_UPDATE=0
        endfor
    endif
end

;--------------------------------------------------------------------------
; IDLitManipRangeBox::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
pro IDLitManipRangeBox::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    nDS = self.nSelectionList
    oDataSpaces = *self.pSelectionList

    if (nDS gt 0) then begin
        startXY = DBLARR(2, nDS)
        oRects = OBJARR(nDS)

        for i=0,nDS-1 do begin
            if (OBJ_VALID(oDataSpaces[i]) eq 0) then continue
            oDataSpace = (oDataSpaces[i])->GetDataSpace(/UNNORMALIZED)

            ; Transform the location to dataspace coordinates.
            oDataSpace->_IDLitVisualization::WindowToVis, $
                [x,y], xyVis
            startXY[0:1,i] = xyVis[0:1]

            ; Create a selection box.
            startx = xyVis[0]
            starty = xyVis[1]
            data = [[startx, starty], [startx, starty], $
                    [startx, starty], [startx, starty]]

            oRects[i] = OBJ_NEW('IDLgrPolyline', /PRIVATE, $
                HIDE=(i ne 0), $
                COLOR=[0,64,0], $
                LINESTYLE=3, $
                DATA=data, POLYLINE=[5,0,1,2,3,0])
            oDataSpace->IDLgrModel::Add, oRects[i]
        endfor

        *self._pStartXY = startXY
        *self._pRects = oRects

        iStatus = self->RecordUndoValues()

    endif else begin
        *self._pStartXY = [0,0]
        *self._pRects = OBJ_NEW()
    endelse
end

;--------------------------------------------------------------------------
; IDLitManipRangeBox::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipRangeBox::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    self.ButtonPress = 0  ; button is up

    nDS = self.nSelectionList

    if (nDS gt 0) then begin
        self->_DisableAutoUpdates

        doCommit = 0
        for i=0,nDS-1 do begin

            oTopDataSpace = (*self.pSelectionList)[i]
            oDataSpace = OBJ_VALID(oTopDataSpace) ? $
                oTopDataSpace->GetDataSpace(/UNNORMALIZED) : OBJ_NEW()

            ; Keep track of first selected dataspace
            ; (used for macro recording).
            if (i eq 0) then $
                oFirstDS = oDataSpace

            oRect = (*self._pRects)[i]
            if ((OBJ_VALID(oDataSpace) eq 0)) then begin
                OBJ_DESTROY, oRect
                continue
            endif
            if (OBJ_VALID(oRect) eq 0) then $
                continue

            oDataSpace->IDLgrModel::Remove, oRect

            oRect->GetProperty, DATA=data
            xmin = MIN(data[0,*], MAX=xmax)
            ymin = MIN(data[1,*], MAX=ymax)

            oDataSpace->_GetXYZAxisReverseFlags, xReverse, yReverse, zReverse
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog
            if (xLog) then begin
                xmin = 10.^xmin
                xmax = 10.^xmax
            endif
            if (yLog) then begin
                ymin = 10.^ymin
                ymax = 10.^ymax
            endif

            if ((xmax gt xmin) && (ymax gt ymin)) then begin
                doCommit = 1

                oDataSpace->SetProperty, $
                    X_MINIMUM=(xReverse ? xmax : xmin), $
                    X_MAXIMUM=(xReverse ? xmin : xmax), $
                    Y_MINIMUM=(yReverse ? ymax : ymin), $
                    Y_MAXIMUM=(yReverse ? ymin : ymax)
            endif

            OBJ_DESTROY, oRect
        endfor

        iStatus = self->CommitUndoValues(UNCOMMIT=(1-doCommit))

        oTool = self->GetTool()
        oSrvMacro = oTool->GetService('MACROS')
        idSrc = "/Registry/MacroTools/Range Change"
        oDescRangeChange = oTool->GetByIdentifier(idSrc)
        if obj_valid(oSrvMacro) && $
                obj_valid(oDescRangeChange) then begin
            oFirstDS->GetProperty, $
                Z_MINIMUM=zNewMin, $
                Z_MAXIMUM=zNewMax
            oDescRangeChange->SetProperty, $
                X_MINIMUM=(xReverse ? xmax : xmin), $
                X_MAXIMUM=(xReverse ? xmin : xmax), $
                Y_MINIMUM=(yReverse ? ymax : ymin), $
                Y_MAXIMUM=(yReverse ? ymin : ymax), $
                Z_MINIMUM=zNewMin, $
                Z_MAXIMUM=zNewMax
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            oSrvMacro->PasteMacroOperation, oDescRangeChange, currentName
        endif

    endif


    ; Clear out data.
    *self._pStartXY = [0,0]
    *self._pRects = OBJ_NEW()

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
end


;--------------------------------------------------------------------------
; IDLitManipRangeBox::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipRangeBox::OnMouseMotion, oWin, x, y, KeyMods
    ; pragmas
    compile_opt idl2, hidden

    nDS = self.nSelectionList

    if (nDS gt 0) then begin
        for i=0,nDS-1 do begin

            oTopDataSpace = (*self.pSelectionList)[i]
            oDataSpace = OBJ_VALID(oTopDataSpace) ? $
                oTopDataSpace->GetDataSpace(/UNNORMALIZED) : OBJ_NEW()
            oRect = (*self._pRects)[i]
            if ((OBJ_VALID(oDataSpace) eq 0) or (OBJ_VALID(oRect) eq 0)) then $
                continue

            oDataSpace->_IDLitVisualization::WindowToVis, $
                [x,y], xyVis
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog

            startx = (*self._pStartXY)[0,i]
            starty = (*self._pStartXY)[1,i]
            endx = xyVis[0]
            endy = xyVis[1]
            data = [[startx, starty], [endx,starty], [endx, endy], [startx, endy]]
            oRect->SetProperty, DATA=data

            if (i eq 0) then begin
                x0 = MIN([startx,endx], MAX=x1)
                y0 = MIN([starty,endy], MAX=y1)
                if (xLog) then begin
                    x0 = 10.^x0
                    x1 = 10.^x1
                endif
                if (yLog) then begin
                    y0 = 10.^y0
                    y1 = 10.^y1
                endif
                probeMsg = STRING(FORMAT='(%"X: %g...%g  Y: %g...%g")', $
                    x0, x1, y0, y1)
                self->ProbeStatusMessage, probeMsg
            endif

        endfor

        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow

    endif else begin
        ; Call our superclass.
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
    endelse
end


;;--------------------------------------------------------------------------
;; IDLitManipRangeBox::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipRangeBox::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '      ...       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#. .#.     ', $
        '....#.   .#.... ', $
        '.####. $ .####. ', $
        '....#.   .#.... ', $
        '    .#. .#.     ', $
        '     .###.      ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      ...       ', $
        '                ']

    self->RegisterCursor, strArray, 'Range_Box', /DEFAULT

end


;---------------------------------------------------------------------------
; IDLitManipRangeBox::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipRangeBox__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipRangeBox,        $
            inherits IDLitManipulator, $ ; Superclass
            _pStartXY: PTR_NEW(),      $ ; ^ to initial points
                                       $ ;    (one per dataspace)
            _pRects: PTR_NEW()         $ ; ^ to temporary box visuals
                                       $ ;    (one per dataspace)
    }
end
