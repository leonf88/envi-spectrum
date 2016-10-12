; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisview__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitManipVisView class is the view selection visual.
;
; Written by:  CT, RSI, May 2002
;


;----------------------------------------------------------------------------
; Purpose:
;   The IDLitManipVisView::Init function method initializes this object.
;
function IDLitManipVisView::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "View Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init(NAME=name, $
        CENTER_OF_ROTATION=[0.0,0,0], $
        VISUAL_TYPE='View') ne 1) then $
        return, 0

    ; Seems goofy, but we need to do all 4 sides separately, even
    ; though they all translate. This is so we can highlight the
    ; left/right side when moving gridded views.
    types = [ 'Translate', 'Translate', 'Translate', 'Translate', $
        'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight']

    dx = 0.01
    x = 1 - dx

    for i=0,7 do begin
        case i of
            ; Note: To avoid gaps, we extend the edges all the way into the
            ; corners, and assume that because we add the "corner" objects
            ; last, then they will take precedence for selection.
            ; If this is not true, then we need to stop the edges before
            ; the corners.
            ; Position the visuals on the near clipping plane (z=1)
            ; so that they appear in front of the scrollbars.
            0: data = [[0,0,1],[0,1,1]] ; Left
            1: data = [[1,0,1],[1,1,1]] ; Right
            2: data = [[0,1,1],[1,1,1]] ; Top
            3: data = [[0,0,1],[1,0,1]] ; Bottom
            ; Tiny corner polylines, used for scaling.
            4: data = [[0,x,1],[0,1,1],[dx,1,1]]  ; TopLeft
            5: data = [[x,1,1],[1,1,1],[1,x,1]]   ; TopRight
            6: data = [[0,dx,1],[0,0,1],[dx,0,1]]  ; BottomLeft
            7: data = [[x,0,1],[1,0,1],[1,dx,1]]  ; BottomRight
        endcase

        ; We need to have a separate ManipulatorVisual for each line,
        ; so we can do different manipulations depending upon which line.
        oOutline = OBJ_NEW('IDLitManipulatorVisual', $
            NAME=types[i], $
            VISUAL_TYPE=types[i], $
            LIGHTING=0)

        ; The actual polyline representing the view edge or corner.
        ; TODO: CT, Nov 2002: Does this need to be a texture-mapped polygon,
        ; with some thickness, so we can pick up selections right on the
        ; border between 2 views?
        oOutline->Add, OBJ_NEW('IDLgrPolyline', $
            COLOR=[200,200,200], $
            DATA=data, NAME='poly')

        self->IDLitManipulatorVisual::Add, oOutline

    endfor

    ; Assume we are a gridded layout initially.
    self->_UpdateVisualTypes, /GRIDDED

    ; Set any properties.
    self->IDLitManipulatorVisual::SetProperty, _EXTRA=_extra

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Update the selection visual to either selected or not.
;
; Keywords:
;   GRIDDED: Set this keyword if the view is part of a gridded layout.
;
;   SELECT: Set this keyword if the view is becoming selected.
;
pro IDLitManipVisView::_UpdateVisualTypes, $
    GRIDDED=gridded, $
    SELECT=select

    compile_opt idl2, hidden

    if (N_ELEMENTS(gridded) eq 0) then begin
        ; If we are unselecting, then we will always disable our view outline.
        ; Otherwise, we need to check the gridded property on our layout.
        gridded = 0
        if (KEYWORD_SET(select)) then begin
            ; Find the layout in which this vis view is contained.
            if (self->_IDLitVisualization::_GetWindowandViewG(oWin, oView)) then begin
                if (OBJ_ISA(oWin, '_IDLitLayoutManager')) then begin
                    oLayout = oWin->GetLayout()
                    if (OBJ_VALID(oLayout)) then $
                        oLayout->GetProperty, GRIDDED=gridded
                endif
            endif
        endif
    endif

    ; Retrieve my name.
    self->GetProperty, VISUAL_TYPE=myname

    ; Retrieve all my outline objects.
    oOutline = self->Get(/ALL, COUNT=count)

    for i=0,count-1 do begin

        ; We turn off the corners (scaling) for gridded layouts.
        turnOffCorner = KEYWORD_SET(gridded) && (i ge 4)

        if (~KEYWORD_SET(select) || turnOffCorner) then begin
            ; Disable the selection visual by removing our ID.
            tname = myname + '/ '
        endif else begin
            ; Use our real ID, so we are enabled.
            oOutline[i]->GetProperty, NAME=name
            tname = myname + '/' + name
        endelse

        oOutline[i]->SetProperty, $
            VISUAL_TYPE=tname

    endfor

end


;---------------------------------------------------------------------------
; Purpose:
;   Selection for the View. Changes the outline color, and calls
;   either Lock or Unlock.
;
pro IDLitManipVisView::_Select, UNSELECT=unselect

    compile_opt idl2, hidden

    ; Retrieve all my outline objects.
    oOutline = self->Get(/ALL, COUNT=count)

    ; Polyline color for selected or not.
    color = KEYWORD_SET(unselect) ? [200,200,200] : [255, 0, 0]
    hide = 0

    if (~KEYWORD_SET(unselect) && $
        self->_IDLitVisualization::_GetWindowandViewG(oWin, oView)) then begin
      if (OBJ_ISA(oWin, '_IDLitLayoutManager')) then begin
        nView = oWin->Count()
        oLayout = oWin->GetLayout()
        if ((nView le 1) && (~OBJ_ISA(oLayout, 'IDLitLayoutFreeform'))) then $
          hide = 1
      endif
    endif

    for i=0,count-1 do begin
        ; Change the polyline color.
        oLine = oOutline[i]->Get()
        oLine->SetProperty, COLOR=color, UVALUE=color, HIDE=hide
    endfor

    ; Change the visual to locked/unlocked.
    self->_UpdateVisualTypes, SELECT=~KEYWORD_SET(unselect)

end


;---------------------------------------------------------------------------
; Purpose:
;   Highlight the insertion location for the View. Draws a thick dark line
;   to indicate the location.
;
pro IDLitManipVisView::_InsertHighlight, OFF=off, RIGHT=right

    compile_opt idl2, hidden

    if (KEYWORD_SET(off)) then begin
        ; Retrieve the left & right sides and turn off the highlight.
        for i=0,1 do begin   ; 0=left, 1=right
            oSide = (self->Get(POSITION=i))->Get()
            oSide->GetProperty, UVALUE=prevColor
            oSide->SetProperty, COLOR=prevColor, THICK=1
        endfor
    endif else begin
        ; Retrieve either the left or right side and turn on the highlight.
        ; 0=left, 1=right
        oSide = (self->Get(POSITION=KEYWORD_SET(right)))->Get()
        oSide->SetProperty, COLOR=[0,0,0], THICK=5
    endelse

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisView__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisView object.
;-
pro IDLitManipVisView__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisView, $
        inherits IDLitManipulatorVisual}
end
