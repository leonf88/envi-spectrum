; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprangepan__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipRangePan
;
; PURPOSE:
;   The IDLitManipRangeBox class represents a manipulator used to modify
;   the XYZ range of one or more target dataspace objects.  The dataspace
;   range modification occurs by clicking a visual that indicates either
;   a pan left or a pan right.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipRangePan::Init
;
; PURPOSE:
;   The IDLitManipRangePan::Init function method initializes the
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
;   oManipulator = OBJ_NEW('IDLitManipRangePan')
;
;-
function IDLitManipRangePan::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Range", $
        OPERATION_IDENTIFIER="SET_XYZRANGE", $
        NAME="Range Pan", $
        /SKIP_MACROHISTORY, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Register the default cursor for this manipulator.
    self->IDLitManipRangePan::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipRangePan::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipRangePan::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipRangePan::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipRangePan::_FindManipulatorTargets
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
function IDLitManipRangePan::_FindManipulatorTargets, oVisIn, $
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
; IDLitManipRangePan::_DisableAutoUpdates
;
; Purpose:
;   This procedure method disables auto-updates of the XYZ Ranges
;   for each target dataspace.
;-
pro IDLitManipRangePan::_DisableAutoUpdates

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
; IDLitManipRangePan::OnMouseDown
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
pro IDLitManipRangePan::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    nDS = self.nSelectionList
    oDataSpaces = *self.pSelectionList

    ; Disable window updates until a mouse up.
    oTool = oWin->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->DisableUpdates

    if (nDS gt 0) then $
        iStatus = self->RecordUndoValues()
end

;--------------------------------------------------------------------------
; IDLitManipRangePan::_Pan
;
; Purpose:
;   Pans the selected dataspace(s).
;
; Parameters
;   Direction   The direction in which the pan is to occur.
;       Negative values pan left/down.
;       Positive values pan right/up.
;
; Keywords
;   AXIS    The axis along which the pan is to occur.
;       0=X, 1=Y, 2=Z
pro IDLitManipRangePan::_Pan, Direction, AXIS=inAxis
    ; pragmas
    compile_opt idl2, hidden

    axis = (N_ELEMENTS(inAxis) ne 0) ? inAxis : 0

    ; Only operate on selected dataspace
    oTool = self->GetTool()
    oSel = oTool->GetSelectedItems()
    oDataSpace = oSel[0]->GetDataSpace()

    oDataSpace->GetProperty, $
        X_MINIMUM=xMin, X_MAXIMUM=xMax, $
        Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
        Z_MINIMUM=zMin, Z_MAXIMUM=zMax

    case axis of
        0: begin
            axisLen = xMax-xMin
            panOffset = axisLen * 0.1 * Direction
            xMin = xMin+panOffset
            xMax = xMax+panOffset
            oDataSpace->SetProperty, $
                X_MINIMUM=xMin, X_MAXIMUM=xMax
        end

        1: begin
            axisLen = yMax-yMin
            panOffset = axisLen * 0.1 * Direction
            yMin = yMin+panOffset
            yMax = yMax+panOffset
            oDataSpace->SetProperty, $
                Y_MINIMUM=yMin, Y_MAXIMUM=yMax
        end

        2: begin
            axisLen = zMax-zMin
            panOffset = axisLen * 0.1 * Direction
            zMin = zMin+panOffset
            zMax = zMax+panOffset
            oDataSpace->SetProperty, $
                Z_MINIMUM=zMin, Z_MAXIMUM=zMax
        end
    endcase

    oSrvMacro = oTool->GetService('MACROS')
    idSrc = "/Registry/MacroTools/Range Change"
    oDescRangeChange = oTool->GetByIdentifier(idSrc)
    if obj_valid(oSrvMacro) && $
            obj_valid(oDescRangeChange) then begin
        oDescRangeChange->SetProperty, $
            X_MINIMUM=xMin, X_MAXIMUM=xMax, $
            Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
            Z_MINIMUM=zMin, Z_MAXIMUM=zMax
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, oDescRangeChange, currentName
    endif

end

;--------------------------------------------------------------------------
; IDLitManipRangePan::OnMouseUp
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
pro IDLitManipRangePan::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    self.ButtonPress = 0  ; button is up

    if (self.nSelectionList gt 0) then begin
        self->_DisableAutoUpdates

        case self._subType of
            'Left': self->_Pan, -1, AXIS=0
            'Right': self->_Pan,  1, AXIS=0
            'Down': self->_Pan, -1, AXIS=1
            'Up': self->_Pan,  1, AXIS=1
            '-Z': self->_Pan, -1, AXIS=2
            '+Z': self->_Pan,  1, AXIS=2
            else : return
        endcase

        iStatus = self->CommitUndoValues()
    endif

    ; Re-enable window updates.
    oTool = oWin->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->EnableUpdates
end


;;--------------------------------------------------------------------------
;; IDLitManipRangePan::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipRangePan::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#####.     ', $
        '   ....#....    ', $
        '  .#. .#. .#.   ', $
        ' .##...#...##.  ', $
        '.######$######. ', $
        ' .##...#...##.  ', $
        '  .#. .#. .#.   ', $
        '   ....#....    ', $
        '    .#####.     ', $
        '     .###.      ', $
        '      .#.       ', $
        '       .        ', $
        '                ']
    self->RegisterCursor, strArray, 'Range_Pan'

end

;--------------------------------------------------------------------------
; IDLitManipRangePan::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitManipRangePan::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    switch STRUPCASE(typeIn) of
        'RIGHT':
        'LEFT':
        'UP':
        'DOWN':
        '+Z':
        '-Z': begin
            currCur = 'RANGE_PAN'
            break
            end
        else: currCur = ''
    endswitch

    return, currCur
end

;--------------------------------------------------------------------------
; IDLitManipRangePan::GetStatusMesssage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given type.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   typeIn <Optional> - String representing the current type.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
function IDLitManipRangePan::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    case STRUPCASE(typeIn) of
        'RIGHT': statusMsg = IDLitLangCatQuery('Status:ManipRangePan:Right')
        'LEFT': statusMsg = IDLitLangCatQuery('Status:ManipRangePan:Left')
        'UP': statusMsg = IDLitLangCatQuery('Status:ManipRangePan:Up')
        'DOWN': statusMsg = IDLitLangCatQuery('Status:ManipRangePan:Down')
        else: statusMsg = IDLitLangCatQuery('Status:ManipRangePan:Default')
    endcase

    return, statusMsg
end


;---------------------------------------------------------------------------
; IDLitManipRangePan::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipRangePan__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipRangePan,        $
            inherits IDLitManipulator  $ ; Superclass
    }
end
