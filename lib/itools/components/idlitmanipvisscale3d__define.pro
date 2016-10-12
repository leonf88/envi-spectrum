; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisscale3d__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisScale3D class is the 3D scale manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisScale3D')
;
;   or
;
;   Obj->[IDLitManipVisScale3D::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisScale3D::Init, NAME=inName, COLOR=color, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Scale3D Visual"


    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init(NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    ; Scale along the X axis
    color = !COLOR.DODGER_BLUE
    alpha = 0.4
    lines = [[-1.25, 0, 0], [-1, 0, 0], [1, 0, 0], [1.25, 0, 0]]
    polylines = [2,0,1, 2,2,3]
    types = 'Scale/' + ['+X','+Y','+Z','-X','-Y','-Z']

; Whiskers for constrained scaling.
    for i=0,5 do begin
        case i of
            0: line = [[1, 0, 0], [1.25, 0, 0]]
            1: line = [[0, 1, 0], [0, 1.25, 0]]
            2: line = [[0, 0, 1], [0, 0, 1.25]]
            3: line = [[-1.25, 0, 0], [-1, 0, 0]]
            4: line = [[0, -1.25, 0], [0, -1, 0]]
            5: line = [[0, 0, -1.25], [0, 0, -1]]
        endcase
        ; Initially hide the whiskers. If we are a 3D plot, they will
        ; be turned back on in Set3D.
        oScale = OBJ_NEW('IDLitManipulatorVisual', HIDE=0, VISUAL_TYPE=types[i])
        oScale->Add, OBJ_NEW('IDLgrPolyline', $
            COLOR=color, $
            DATA=line, $
            ALPHA_CHANNEL=alpha, $
            THICK=1)
        self->Add, oScale, /NO_UPDATE, /NO_NOTIFY
;        self.oWhisker[i] = oScale
    endfor


    data = [ $
        [-1,-1,-1], $
        [1,-1,-1], $
        [1,1,-1], $
        [-1,1,-1], $
        [-1,-1,1], $
        [1,-1,1], $
        [1,1,1], $
        [-1,1,1]]

    polygons = [ $
        [4, 3, 2, 1, 0], $
        [4, 0, 1, 5, 4], $
        [4, 0, 4, 7, 3], $
        [4, 1, 2, 6, 5], $
        [4, 2, 3, 7, 6], $
        [4, 4, 5, 6, 7]]

    ; Create a bunch of cubes.

    ; Create a manipulator visual containing a bunch of cubes.
    types = ['-X-Y','+X-Y','+X+Y','-X+Y']
    for i=0,7 do begin
        oPoly = OBJ_NEW('IDLgrPolygon', COLOR=color, $
            DATA=data/40d + REBIN(data[*,i],3,8), $
            ALPHA_CHANNEL=alpha, $
            POLYGONS=polygons)
        self.oCorners[i] = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Scale/XYZ');, LIGHTING=2)
        self.oCorners[i]->Add, oPoly
        self->Add, self.oCorners[i]
    endfor


    ; Create the edges.
    oEdge = OBJ_NEW('IDLitManipulatorVisual', VISUAL_TYPE='Scale/YZ')
    oEdge->Add, OBJ_NEW('IDLgrPolyline', $
        COLOR=color, DATA=data, ALPHA_CHANNEL=0.4, $
        POLYLINES=[2, 0, 1, 2, 2, 3, 2, 4, 5, 2, 6, 7])
    self->Add, oEdge

    oEdge = OBJ_NEW('IDLitManipulatorVisual', VISUAL_TYPE='Scale/XZ')
    oEdge->Add, OBJ_NEW('IDLgrPolyline', $
        COLOR=color, DATA=data, ALPHA_CHANNEL=0.4, $
        POLYLINES=[2, 1, 2, 2, 3, 0, 2, 5, 6, 2, 7, 4])
    self->Add, oEdge

    oEdge = OBJ_NEW('IDLitManipulatorVisual', VISUAL_TYPE='Scale/XY')
    oEdge->Add, OBJ_NEW('IDLgrPolyline', $
        COLOR=color, DATA=data, ALPHA_CHANNEL=0.4, $
        POLYLINES=[2, 0, 4, 2, 1, 5, 2, 2, 6, 2, 3, 7])
    self->Add, oEdge


    return, 1
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisScale3D__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisScale3D object.
;-
pro IDLitManipVisScale3D__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisScale3D, $
        inherits IDLitManipulatorVisual, $
        oCorners: OBJARR(8) $
        }
end
