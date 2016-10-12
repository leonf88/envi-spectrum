; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniproifree__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipROIFree
;
; PURPOSE:
;   This class represents a manipulator for freehand regions of interest.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROIFree::Init
;
; PURPOSE:
;   The IDLitManipROIFree::Init function method initializes the
;   manipulator object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitManipROIFree')
;
;    or
;
;   Obj->[IDLitManipROIFree::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function IDLitManipROIFree::Init, $
    _REF_EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    ; Initialize our superclass.
    iStatus = self->IDLitManipROI::Init( $
        IDENTIFIER='ROI_FREEHAND', $
        NAME='ROI Freehand', $
        /TRANSIENT_DEFAULT, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    return, 1
end


;--------------------------------------------------------------------------
; Manipulator Interface
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIFree::OnMouseDown
;
; PURPOSE:
;   This procedure method handles a mouse down event for this manipulator.
;
; INPUTS:
;   oWin:   A reference to the IDLitWindow object in which the
;     mouse event occurred.
;   x:      X coordinate of the mouse event.
;   y:      Y coordinate of the mouse event.
;   iButton:    An integer representing a mask for which button pressed
;   KeyMods:    An integer representing the keyboard modifiers
;   nClicks:    The number of times the mouse was clicked.
;-
pro IDLitManipROIFree::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    compile_opt idl2, hidden

    if n_elements(noSelect) eq 0 then noSelect = 0

    ; Call our superclass.
    self->IDLitManipROI::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    ; Proceed only if left mouse button pressed.
    if (iButton ne 1) then return

    if (OBJ_VALID(self._oTargetVis) and $
        OBJ_VALID(self._oCurrentROI)) then begin
        ; Set a few properties on the newly created ROI.
        oROI = self._oCurrentROI
        oROI->SetProperty, NAME="Freehand ROI", ICON='freehand'

        ; Initialize as a single point.
        oROI->AppendData, self._initialXYZ[0], $
            self._initialXYZ[1], $
            self._initialXYZ[2]

        self._oTargetVis->Add, oROI

    endif
end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIFree::SubmitTargetVertex
;
; PURPOSE:
;   This procedure method submits the given vertex (in the dataspace
;   of the target visualization) to the current ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIFree::]SubmitTargetVertex, visX, visY, visZ
;
; INPUTS:
;   visX, visY, visZ:   The [x,y,z] location (in the dataspace of
;     the current target visualization) to be submitted to the
;     current ROI.
;-
pro IDLitManipROIFree::SubmitTargetVertex, visX, visY, visZ, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipROI::SubmitTargetVertex, visX, visY, visZ, $
        GRID_LOCATION=gridLoc

    if (self._bIn3DSpace) then begin
        self->ProbeStatusMessage, STRING(visX[0], visY[0], visZ[0], $
            FORMAT='(%"[%g, %g, %g]")')
    endif else begin
        self->ProbeStatusMessage, STRING(visX[0], visY[0], $
            FORMAT='(%"[%g, %g]")')
    endelse
end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIFree::ValidateROI
;
; PURPOSE:
;   This function method determines whether the current ROI is
;   valid.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitManipROIFree::]ValidateROI()
;
; OUTPUTS:
;   This function returns a 1 if the current ROI is valid (i.e.,
;   may be committed), or a 0 if the ROI is invalid.
;-
function IDLitManipROIFree::ValidateROI

    compile_opt idl2, hidden

    if (OBJ_VALID(self._oTargetVis) and $
        OBJ_VALID(self._oCurrentROI)) then begin
        self._oCurrentROI->GetProperty, N_VERTS=nVerts
        if (nVerts ge 3) then begin
            ; Close the ROI, and return as valid.
            self._oCurrentROI->SetProperty, STYLE=2
            return, 1b
        endif
    endif

    return, 0b
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIFree::_DoRegisterCursor
;
; PURPOSE:
;   This procedure method registers the cursor to be associated with
;   this manipulator.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIFree::]_DoRegisterCursor, strName
;
; INPUTS:
;   strName:    A string representing the name to be associated
;     with the cursor.
;-
pro IDLitManipROIFree::_DoRegisterCursor, strName

    compile_opt idl2, hidden

    strArray = [ $
        '          ...   ', $
        '         .###.  ', $
        '         .#..#. ', $
        '        .##..#. ', $
        '       .#..##.  ', $
        '       .#...#.  ', $
        '      .#...#.   ', $
        '      .#...#.   ', $
        '     .#...#.    ', $
        '     .#...#.    ', $
        '    .#...#.     ', $
        '    .##..#.     ', $
        '    .####.      ', $
        '    .###.       ', $
        '    .##.        ', $
        '     $          ']

    self->RegisterCursor, strArray, strName, /DEFAULT

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; NAME:
;   IDLitManipROIFree::Define
;
; PURPOSE:
;   Defines the object structure for an IDLitManipROIFree object.
;-
pro IDLitManipROIFree__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipROIFree,         $
        INHERITS IDLitManipROI         $ ; Superclass.
    }
end
