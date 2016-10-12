; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprotate3d__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Rotate 3D manipulator.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipRotate3D::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;  strType     - The type of the manipulator. This is immutable.
;
function IDLitManipRotate3D::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init(NAME='Rotate', $
                           VISUAL_TYPE = 'Rotate', $
                           OPERATION_IDENTIFIER="SET_PROPERTY", $
                           PARAMETER_IDENTIFIER="TRANSFORM", $
                           /SKIP_MACROHISTORY, $
                           _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Initially, rotations are not constrained about a particular axis.
    self.constrainAxis = -1

    self.pCenterRotation = PTR_NEW(0)

    self->IDLitManipRotate3D::_DoRegisterCursor

    return, 1
end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro IDLitManipRotate3D::Cleanup

    compile_opt idl2, hidden

    ; Cleanup ourself.
    PTR_FREE, self.pCenterRotation

    ; Cleanup our superclass.
    self->IDLitManipulator::Cleanup
end


;----------------------------------------------------------------------------
; TRACKBALL_CONSTRAIN
;
; Purpose:
;  Given a point and a constraint vector, map the point to its constrained
;  equivalent.
;
; Arguments:
;  pt - The unconstrained point.
;  vec - A three-element vector, [x,y,z], representing the unit vector about
;        which rotations are constrained.
;
function IDLitManipRotate3D::_Constrain, point, constrainAxis, TYPE=type

    compile_opt idl2, hidden

    ; Store the constraint axis vector for the selected model.
    ; The constraint axis vector only gets changed for mouse down events,
    ; and is used for all subsequent OnMouseMotion events.
    ; Retrieve the primary selection.
    oVis = (*self.pSelectionList)[0]
    if (type eq 0) then begin
        oVis->GetProperty, TRANSFORM=startTransform

        vec = [0d,0d,0d]
        vec[constrainAxis] = 1

        ; Transform the current constraint vector using the starting transform.
        zeroVec = [0d, 0d, 0d, 1d] # startTransform
        vec = [vec, 1] # startTransform
        ; Constraint axis.
        vec = vec[0:2] - zeroVec[0:2]
        ; Normalize
        norm = SQRT(TOTAL(vec^2))
        if (norm gt 0) then $
            vec = TEMPORARY(vec)/norm
        ; Store the constraint axis vector for all subsequent motion events.
        self.constrainVector = vec
    endif

    ; Retrieve the stored constraint axis vector.
    vec = self.constrainVector

    ; Project the point.
    proj = point - TOTAL(vec * point) * vec

    ; Normalizing factor.
    norm = SQRT(TOTAL(proj^2d))

    cpoint = (norm gt 0.0) ? $
        ((proj[2] ge 0) ? proj/norm : -proj/norm) : vec

    RETURN, cpoint
END


;--------------------------------------------------------------------------
; Internal procedure to rotate a 2D viz by an angle about the Z axis.
;
; This will cache our new angle, update the status area,
; and perform the rotation.
;
pro IDLitManipRotate3D::_Rotate2D, angle

    compile_opt idl2, hidden

    ; Reduce to -180 to +180
    self.angle = (self.angle + angle) mod 360
    if (self.angle gt 180) then $
        self.angle -= 360 $
    else if (self.angle le -180) then $
        self.angle += 360

    self->ProbeStatusMessage, $
        STRING(self.angle, FORMAT='(G0)') + STRING(176b) ; degrees symbol

    if (angle eq 0) then $
        return

    ; delta starts at 0 while self.angle is based on initial transform
    self.totalAngle[2] = (self.totalAngle[2] + angle) mod 360

    ; Loop through all selected visualizations.
    for i=0,N_ELEMENTS(*self.pSelectionList)-1 do begin
        oVis = (*self.pSelectionList)[i]

        ;; Perform rotation about visualization's center of rotation.
        oVis->Rotate, [0, 0, 1], angle
    endfor

end

; -----------------------------------------------------------------------------
;
;  Purpose:  Function returns the 3 angles of a space three 1-2-3
;            given a 3 x 3 cosine direction matrix
;            else -1 on failure.
;
;  Definition :  Given 2 sets of dextral orthogonal unit vectors
;                (a1, a2, a3) and (b1, b2, b3), the cosine direction matrix
;                C (3 x 3) is defined as the dot product of:
;
;                C(i,j) = ai . bi  where i = 1,2,3
;
;                A column vector X (3 x 1) becomes X' (3 x 1)
;                after the rotation as defined as :
;
;                X' = C X
;
;                The space three 1-2-3 means that the x rotation is first,
;                followed by the y rotation, then the z.
;
function IDLitManipRotate3D::_AngleFromTrans, transMatrix

    compile_opt idl2, hidden

    ;cosine direction matrix (3 x 3)
    cosMat = transMatrix[0:2, 0:2]

    ;  Compute the 3 angles (in degrees)
    ;
    cosMat = TRANSPOSE(cosMat)
    angle = DBLARR(3)
    angle[1] = -cosMat[2,0]
    angle[1] = ASIN(angle[1])
    c2 = COS(angle[1])
    if (ABS(c2) lt 1.0e-6) then begin
        angle[0] = ATAN(-cosMat[1,2], cosMat[1,1])
        angle[2] = 0.0
    endif else begin
        angle[0] = ATAN( cosMat[2,1], cosMat[2,2])
        angle[2] = ATAN( cosMat[1,0], cosMat[0,0])
    endelse
    angle = angle * (180.0/!DPI)

    RETURN, angle

end    ;   of _AngleFromTrans

;--------------------------------------------------------------------------
pro IDLitManipRotate3D::_CaptureMacroHistory, $
    angles, $
    MOUSE_MOTION=mouseMotion

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then return
    oSrvMacro = oTool->GetService('MACROS')

    if obj_valid(oSrvMacro) then begin

        oSrvMacro->GetProperty, $
            RECORDING=recording, $
            MANIPULATOR_STEPS=manipulatorSteps
        skipMacro = 0
        skipHistory = 0
        if recording && manipulatorSteps then begin
            if keyword_set(mouseMotion) then begin
                ; add each individual manipulation to macro
                ; don't add individual manipulation to history
                skipHistory = 1
            endif else skipMacro = 1    ; overall added to history but not macro
        endif else begin
            ; add overall manipulation to both macro and history
            ; skip the individual manipulations
            if keyword_set(mouseMotion) then return
        endelse

        idSrc = "/Registry/MacroTools/Rotate"
        oDesc = oTool->GetByIdentifier(idSrc)
        if obj_valid(oDesc) then begin
            oDesc->SetProperty, $
                X=angles[0], $
                Y=angles[1], $
                Z=angles[2]
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            oSrvMacro->PasteMacroOperation, oDesc, currentName, $
                SKIP_MACRO=skipMacro, $
                SKIP_HISTORY=skipHistory
        endif
    endif
end


;--------------------------------------------------------------------------
pro IDLitManipRotate3D::_Rotate, oWin, x, y, $
    ANGLE=angle, $
    CLICKS=nClicks, $
    KEYBOARD_MODIFIERS=KeyMods, $
    TYPE=type          ; button was pressed

    compile_opt idl2, hidden

    ; Retrieve previous coordinates.
    pt0 = self.pt0
    ; Calculate distance of mouse click from center of rotation.
    xy = ([x, y] - self.screencenter) / self.radius

    ; Normalize to unit length.
    r = TOTAL(xy^2)
    pt1 = (r GT 1.0) ? [xy/SQRT(r) ,0d] : [xy,SQRT(1.0-r)]

    ; Constrain if necessary.
    constrainAxis = self.is3D ? self.constrainAxis : 2
    if (constrainAxis ge 0) then $
        pt1 = self->_Constrain(pt1, constrainAxis, TYPE=type)

    ; Store new coordinates.
    self.pt0 = pt1

    ; OnMouseDown (button was pressed). Don't actually rotate.
    if (type eq 0) then begin
        self.startXY = [x, y]
        RETURN
    endif

    ; If we havn't moved then return.
    if (ARRAY_EQUAL(pt0, pt1)) then $
        RETURN

    if (self.is3D) then begin   ; 3D arbitrary rotation

        ; Compute transformation.
        q = CROSSP(pt0,pt1)
        x = q[0]
        y = q[1]
        z = q[2]
        w = TOTAL(pt0*pt1)

        rotateTransform = [ $
            [ w^2+x^2-y^2-z^2, 2*(x*y-w*z), 2*(x*z+w*y), 0], $
            [ 2*(x*y+w*z), w^2-x^2+y^2-z^2, 2*(y*z-w*x), 0], $
            [ 2*(x*z-w*y), 2*(y*z+w*x), w^2-x^2-y^2+z^2, 0], $
            [ 0          , 0          , 0              , 1]]

        ; Loop through all selected visualizations.
        for i=0,N_ELEMENTS(*self.pSelectionList)-1 do begin
            oVis = (*self.pSelectionList)[i]

            ;; Translate so the center of rotation is at [0,0,0]
            oVis->GetProperty, TRANSFORM=currentTransform

            ;; Transform center of rotation by current transform
            centerRotation = (*self.pCenterRotation)[*,i]
            cr = [centerRotation, 1.0d] # currentTransform

            ;; Perform translate, rotate, translate back transform
            t1 = IDENTITY(4)
            t1[3,0] = -cr[0]
            t1[3,1] = -cr[1]
            t1[3,2] = -cr[2]
            t2 = IDENTITY(4)
            t2[3,0] = cr[0]
            t2[3,1] = cr[1]
            t2[3,2] = cr[2]
            oVis->GetProperty, TRANSFORM=oldTransform
            transform = oldTransform # t1 # rotateTransform # t2
            oVis->SetProperty, TRANSFORM=transform
        endfor

        angles = self->_AngleFromTrans(rotateTransform)

        ; accumulate the total angle for the overall rotation
        self.totalAngle = (self.totalAngle + angles) mod 360

        self->_CaptureMacroHistory, $
            angles, $
            /MOUSE_MOTION

    endif else begin  ; 2D rotation about Z axis

        if (N_ELEMENTS(angle) eq 0) then begin
            angle = (180/!DPI)*ASIN(pt0[0]*pt1[1]-pt0[1]*pt1[0])

            ; Check for <Shift> key.
            angle = (N_ELEMENTS(KeyMods) && (KeyMods and 1)) ? $
                FIX(angle/15)*15 : FIX(angle)
        endif

        ; Since we changed from an arbitrary angle to an integerized
        ; angle, we need to adjust our current saved position.
        ; Otherwise our mouse location will get out of sync and will
        ; appear to be rotating quicker than the viz itself.
        cosA = COS(angle*!DPI/180)
        sinA = SIN(angle*!DPI/180)
        self.pt0 = [pt0[0]*cosA - pt0[1]*sinA, pt0[0]*sinA + pt0[1]*cosA]

        ; This will cache our new angle, update the status area,
        ; and perform the rotation.
        self->_Rotate2D, angle

        ; x & y rotation = 0
        self->_CaptureMacroHistory, $
            [0.0, 0.0, angle], $
            /MOUSE_MOTION
    endelse  ; 2D

end


;--------------------------------------------------------------------------
; IIDLRotateManipulator Event Interface Section
; This interface implements the IIDLWindowEventObserver interface
;--------------------------------------------------------------------------


;--------------------------------------------------------------------------
; Internal method to set rotation center, radius, constraint.
;
pro IDLitManipRotate3D::_InitRot, oWin
    ; pragmas
    compile_opt idl2, hidden

    ; Retrieve the center of rotation for each selected item,
    ; so we can cache it for efficiency.
    ; We will go thru the list backwards so that oVis will end
    ; up with the primary selection.
    *self.pCenterRotation = DBLARR(3, self.nSelectionList)
    for i=self.nSelectionList-1,0,-1 do begin
        oVis = (*self.pSelectionList)[i]
        oVis->GetProperty, CENTER_OF_ROTATION=centerRotation
        (*self.pCenterRotation)[*,i] = centerRotation
    endfor

    ; Convert the data coordinates for the scaling center
    ; to device coordinates.
    oVis->_IDLitVisualization::VisToWindow, $
        centerRotation, screenCenter
    self.screenCenter = screenCenter[0:1]

    ; Override constraint axis if not 3D.
    self.is3D = oVis->Is3D()

    ; Retrieve the overall viz range, to use for rot radius.
    if(obj_isa(oVis, "IDLitVisNormDataSpace"))then $
      oVis = oVis[0]->GetDataspace(/UNNORMALIZED)
    if (oVis->GetXYZRange(xrange, yrange, zrange)) then begin
        oVis->_IDLitVisualization::VisToWindow, $
            xrange, yrange, zrange, xWin, yWin, zWin
        radius = SQRT((xWin[1]-xWin[0])^2 + (yWin[1]-yWin[0])^2)
    endif

    ; If we don't have a radius, use the screen size as the default.
    if (N_ELEMENTS(radius) lt 1) then begin
        ; Use the Viewgroup viewport dimensions and locations.
        oViewgroup = oWin->GetCurrentView()
        dimensions = oViewgroup->GetViewport(oWin, LOCATION=location)
        radius = 0.5*SQRT(TOTAL(dimensions^2d))
    endif

    self.radius = radius

    if (~self.is3D) then begin
        ; Convert from the transform matrix back to a Z rotation.
        ; This takes into account translations and scaling,
        ; but assume no rotations have ever occurred about X or Y.
        ; Should this be a GetCTM instead, in case the parent is rotated?
        oVis[0]->GetProperty, TRANSFORM=transform
        ; Rotate an x-unit vector, and find its angle relative
        ; to the X axis.
        xrotate = transform ## [1d,0,0,0]
        self.angle = (180/!DPI)*ATAN(xrotate[1], xrotate[0])
        ; Note: Do we want to restrict to integer values?
        self.angle = ROUND(self.angle)
    endif
end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks
;
pro IDLitManipRotate3D::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    ; If nothing selected we are done.
    if (self.nSelectionList eq 0) then $
        return

    self->StatusMessage, IDLitLangCatQuery('Status:Manip:Rotate')

    ; Set rotation center, radius, constraint.
    self->_InitRot, oWin

    ; Set up the rotation.
    self->_Rotate, oWin, x[0], y[0], $
        TYPE=0          ; button was pressed

    ;; Record the current values for the target objects
    iStatus = self->RecordUndoValues()

end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button released
;
; Keywords:
;   ANGLE: Undocumented keyword used for ::OnKeyboard.
;
pro IDLitManipRotate3D::OnMouseUp, oWin, x, y, iButton, ANGLE=angle
   ; pragmas
    compile_opt idl2, hidden

    ; *** Design Feature/Assumption ***
    ; A MouseDown and a MouseUp event bracket a manipulator
    ; transaction. The selection list contents will not change between
    ; these two operations.
    ;

    bWasPressed = (self.ButtonPress ne 0)
    nWasSelected = self.nSelectionList

    ; Clear out the current selection list reference.

    if (self.nSelectionList gt 0) then begin
        ; If there was no change in coordinates between MouseDown and
        ; MouseUp, then do not commit the values.
        noChange = ARRAY_EQUAL([x,y], self.startXY)

        if (noChange eq 0) then begin
            self->_Rotate, oWin, x[0], y[0], $
                ANGLE=angle, $
                TYPE=1          ; button was released
            ; Update the graphics hierarchy.
            oTool = self->GetTool()
            if (OBJ_VALID(oTool)) then $
                oTool->RefreshCurrentWindow
        endif

        ;; Commit this transaction
        iStatus = self->CommitUndoValues(UNCOMMIT=noChange)

    endif

    self->_CaptureMacroHistory, $
        self.totalAngle

    ; clear totalAngle so that each rotation is a relative
    ; angle, not cumulative of all uses of the manipulator.
    self.totalAngle=0

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    if (bWasPressed) then begin
        ; Restore status message.
        ;
        ; Only perform this step if mouse button was previously
        ; pressed.  Otherwise, this is getting called from the
        ; ::OnKeyboard handler, and in this case, the status message
        ; should not flash.
        statusMsg = self->GetStatusMessage('', KeyMods, $
            FOR_SELECTION=(nWasSelected gt 0))
        self->StatusMessage, statusMsg
    endif

end

;--------------------------------------------------------------------------
; IDLitManipRotate3D::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button
;
pro IDLitManipRotate3D::OnMouseMotion, oWin, x, y, KeyMods
   ; pragmas
   compile_opt idl2, hidden

    if ((self.ButtonPress gt 0) and (self.nSelectionList gt 0)) then begin
        self->_Rotate, oWin, x[0], y[0], $
            KEYBOARD_MODIFIERS=KeyMods, $
            TYPE=2          ; mouse motion
        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif else $
      self->idlitmanipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Parameters
;      oWin        - Event Window Component
;      IsAlpha     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
;
pro IDLitManipRotate3D::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ;; pragmas
   compile_opt idl2, hidden
   ;; Abstract method.

    if (isASCII) then $
        return

    if (~Press || (KeyValue lt 5) || (KeyValue gt 8)) then $
        return


    ; Retrieve the list of selected items, and the associated dataspace.
    oSelected = oWin->GetSelectedItems()
    oSelected = self->_FindManipulatorTargets(oSelected)

    *self.pSelectionList = oSelected
    self.nSelectionList = OBJ_VALID(oSelected[0]) ? N_ELEMENTS(oSelected) : 0

    if (self.nSelectionList eq 0) then $
        return

    ; Set rotation center, radius, constraint.
    self->_InitRot, oWin


    if self.is3D then begin  ; 3D

        self->StatusMessage, IDLitLangCatQuery('Status:Manip:Rotate3D1')

        x = self.screenCenter[0]
        y = self.screenCenter[1]

        case KeyValue of
            5: x += self.radius/10   ; left
            6: x -= self.radius/10   ; right
            7: y -= self.radius/10   ; up
            8: y += self.radius/10   ; down
        endcase

        ; Set up the rotation.
        self->_Rotate, oWin, x, y, $
            TYPE=0          ; button was pressed

        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()

        ; Currently, these numbers don't correspond to actual degrees.
        case KeyMods of
            1: offset = 200     ; SHIFT
            2: offset =  2      ; CTRL
            else: offset = 20   ; none
        endcase

        offset *= self.radius/1000

        ; Do the translation.
        case KeyValue of
            5: x -= offset   ; left
            6: x += offset   ; right
            7: y += offset   ; up
            8: y -= offset   ; down
        endcase

        ; Perform the rotation, then reset everything.
        ; This will also Commit the Undo values.
        self->OnMouseUp, oWin, x, y, 1

    endif else begin  ; 2D

        deg = STRING(176b) ; degrees symbol
        self->StatusMessage, $
       IDLitLangCatQuery('Status:Manip:Rotate2D1')+deg+ $
       IDLitLangCatQuery('Status:Manip:Rotate2D2')+deg+ $
       IDLitLangCatQuery('Status:Manip:Rotate2D3')+deg

        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()

        case KeyValue of
            5: angle = 5    ; left
            6: angle = -5   ; right
            7: angle = 5    ; up
            8: angle = -5   ; down
        endcase

        ; Currently, these numbers don't correspond to actual degrees.
        case KeyMods of
            1: angle *= 9     ; SHIFT
            2: angle /= 5      ; CTRL
            else:    ; none
        endcase

        ; Perform the rotation, then reset everything.
        ; This will also Commit the Undo values.
        self->OnMouseUp, oWin, -1, -1, 1, ANGLE=angle

    endelse   ; 2D

end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::GetStatusMesssage
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
function IDLitManipRotate3D::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    return, (KEYWORD_SET(forSelection) ? $
    IDLitLangCatQuery('Status:Framework:Rotate1') : $
    IDLitLangCatQuery('Status:Framework:Rotate'))
end


;--------------------------------------------------------------------------
; IDLitManipRotate3D::_DoRegisterCursor
;
; Purpose:
;   Register the cursor used with this manipulator with the system
;   and set it as the default.
;
pro IDLitManipRotate3D::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '     .##..      ', $
        '    .$####.     ', $
        '     .##..#.    ', $
        '      .#. .#.   ', $
        '       .   .#.  ', $
        '  .        .#.  ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        '  .#.     .#.   ', $
        '   .#.....#.    ', $
        '    .#####.     ', $
        '     .....      ', $
        '                ']

    self->RegisterCursor, strArray, 'Rotate', /default

end


;---------------------------------------------------------------------------
; Purpose:
;   Define the base object for the manipulator
;
pro IDLitManipRotate3D__Define

    compile_opt idl2, hidden

    void = {IDLitManipRotate3D, $
           inherits IDLitManipulator,       $ ; I AM A COMPONENT
           constrainVector: [0d, 0d, 0d], $
           constrainAxis: 0, $
           is3D: 0b, $
           pCenterRotation: PTR_NEW(), $
           screencenter: [0d, 0d], $
           radius: 0d, $
           angle: 0d, $
           totalAngle: [0d, 0d, 0d], $
           startXY: [0L, 0L], $
           pt0: [0d, 0d, 0d] $
      }
end
