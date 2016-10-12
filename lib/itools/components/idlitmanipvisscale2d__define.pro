; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisscale2d__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisScale2D class is the 2d scale manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisScale2D')
;
;   or
;
;   Obj->[IDLitManipVisScale2D::]Init
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
function IDLitManipVisScale2D::Init, $
    COLOR=color, $
    NAME=inName, $
    TOOL=oTool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Scale2D Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0


    self._oFont = OBJ_NEW('IDLgrFont', 'Symbol', SIZE=36)
    self._oSmallFont = OBJ_NEW('IDLgrFont', 'Symbol', SIZE=18)

    textex = {ALIGN: 0.53, $
        FONT: self._oFont, $
        RECOMPUTE_DIM: 2, $
        RENDER: 0}

    ; Edges
    oLine = OBJ_NEW('IDLitManipulatorVisual', VISUAL_TYPE='Translate')
    oLine->Add, OBJ_NEW('IDLgrPolyline', $
                        COLOR=!color.dodger_blue, $
                        DATA=TRANSPOSE([[-1,-1,1,1,-1],[-1,1,1,-1,-1]]), $
                        ALPHA_CHANNEL=0)
    self->Add, oLine


    ; Corners handles
    types = ['-X-Y','+X-Y','+X+Y','-X+Y']
    data = [[-1,-1], $
            [1,-1], $
            [1,1], $
            [-1,1]]
    for i=0,3 do begin
        xyposition = [data[0:1,i], 0]
        oCorner = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Scale/'+types[i])
        oText = OBJ_NEW('IDLgrText', String(183b), $  ; bullet character
            LOCATION=xyposition, $
            VERTICAL_ALIGNMENT=0.51, $
            ALPHA_CHANNEL=1, $
            COLOR=!color.white, $
            _EXTRA=textex)
        oCorner->Add, oText
        oText = OBJ_NEW('IDLgrText', String(176b), $  ; circle character
            LOCATION=xyposition, $
            VERTICAL_ALIGNMENT=0.73, $
            COLOR=!color.black, $
            ALPHA_CHANNEL=0.4, $
            _EXTRA=textex)
        oCorner->Add, oText
        self->Add, oCorner
    endfor

    ; Rotate handle
    if (ISA(oTool, 'GraphicsTool')) then begin
      oRotate = OBJ_NEW('IDLitManipulatorVisual', $
         VISUAL_TYPE='Rotate')
      ; Need smaller font size for connector line
      textex.align = 0.56
      textex.font = self._oSmallFont
      oRotate->Add, OBJ_NEW('IDLgrText', string(124b), $  ; connector line
         LOCATION=[0,1], VERTICAL_ALIGNMENT=-0.5, COLOR=!color.black, $
         ALPHA_CHANNEL=0.4, $
         _EXTRA=textex)
      ; Restore font
      textex.font = self._oFont
      textex.align = 0.53
      oRotate->Add, OBJ_NEW('IDLgrText', string(183b), $  ; solid circle
         LOCATION=[0,1], VERTICAL_ALIGNMENT=-0.06, COLOR=!color.green_yellow, $
         ALPHA_CHANNEL=1, $
         _EXTRA=textex)
      oRotate->Add, OBJ_NEW('IDLgrText', string(176b), $  ; outline circle
         LOCATION=[0,1], VERTICAL_ALIGNMENT=0.23, COLOR=!color.black, $
         ALPHA_CHANNEL=0.4, $
         _EXTRA=textex)
      self->Add, oRotate
    endif

    ; Edges handles
    types = ['-X','+X','-Y','+Y']
    for i=0,3 do begin
        oEdge = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Scale/' + types[i])

        case i of
            0: data = [[-1,-1],[-1,1]] ; left
            1: data = [[ 1,-1],[1, 1]] ; right
            2: data = [[-1,-1],[1,-1]] ; bottom
            3: data = [[-1, 1],[1, 1]] ; top
        endcase

        isX = STRPOS(types[i], 'X') ne -1
        
        ; Need smaller font size for diamonds
        textex.font = self._oSmallFont
        oEdge->Add, OBJ_NEW('IDLgrText', string(168b), $  ; solid diamond
            LOCATION=TOTAL(data,2)/2, VERTICAL_ALIGNMENT=0.42, $
            BASELINE=(isX ? [0,1,0] : [1,0,0]), $
            UPDIR=(isX ? [1,0,0] : [0,1,0]), $
            ALPHA_CHANNEL=1, $
            COLOR=!color.white, _EXTRA=textex)
        oEdge->Add, OBJ_NEW('IDLgrText', string(224b), $  ; outline diamond
            LOCATION=TOTAL(data,2)/2, VERTICAL_ALIGNMENT=0.42, $
            BASELINE=(isX ? [0,1,0] : [1,0,0]), $
            UPDIR=(isX ? [1,0,0] : [0,1,0]), $
            ALPHA_CHANNEL=0.4, $
            COLOR=!color.black, _EXTRA=textex)
        ; Restore font
        textex.font = self._oFont

        self->Add, oEdge
    endfor
    
    

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitManipVisScale2D::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont
    OBJ_DESTROY, self._oSmallFont
    self->IDLitManipulatorVisual::Cleanup
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisScale2D__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisScale2D object.
;-
pro IDLitManipVisScale2D__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisScale2D, $
        inherits IDLitManipulatorVisual, $
        _oFont: OBJ_NEW(), $
        _oSmallFont: OBJ_NEW() $
        }
end
