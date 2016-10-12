; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdrotatebyangle.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdRotateByAngle
;
; PURPOSE:
;   Curve fitting dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdRotateByAngle()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_Update, wImage, angle

    compile_opt idl2, hidden

    WIDGET_CONTROL, wImage, GET_VALUE=oWin, GET_UVALUE=oModel
    oModel->Reset
    oModel->Rotate, [0,0,1], angle
    oWin->Draw

end


;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_angle, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    value = event.value

    ; Restrict the angle to a degrees value between -180 and +360.
    ; The extra "mod 360" first restricts the range from -360 to +360.
    if ((value le -180) || (value ge 360)) then $
        value = ((value mod 360) + 360) mod 360

    ; Set the value if it changed.
    if (value ne event.value) then $
        WIDGET_CONTROL, event.id, SET_VALUE=value

    IDLitwdRotateByAngle_Update, state.wImage, value

end


;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_draw, event

    compile_opt idl2, hidden

    ; Just an expose event.
    if (event.type eq 4) then begin
        WIDGET_CONTROL, event.id, GET_VALUE=oWin
        oWin->Draw
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Retrieve all of our properties.
    WIDGET_CONTROL, state.wAngle, GET_VALUE=angle

    ; Cache the results in the pointer so we can access them.
    *state.pResult = DOUBLE(angle)

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_cancel, event

    compile_opt idl2, hidden

    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdRotateByAngle_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        ; Needed to prevent weird flashing on Windows.
        'WIDGET_KILL_REQUEST': begin
            WIDGET_CONTROL, event.top, /DESTROY
            end

        else: ; do nothing

    endcase

end


;-------------------------------------------------------------------------
function IDLitwdRotateByAngle, oUI, $
    ANGLE=angleIn, $
    CANCEL=cancel, $
    GROUP_LEADER=groupLeaderIn, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdRotateByAngle'

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('Dialog:RotAngle:Title')

    ; Is there a group leader, or do we create our own?
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(groupLeader, /VALID)

    ; We are doing this modal for now.
    if (not hasLeader) then begin
        wTopDummy = WIDGET_BASE(MAP=0)
        groupLeader = wTopDummy
        hasLeader = 1
    endif else $
        wTopDummy = 0L

    ; Create our floating base.
    wBase = WIDGET_BASE( $
        /COLUMN, $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, /MODAL, $
        EVENT_PRO=myname+'_event', $
        /TLB_KILL_REQUEST_EVENTS, $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        _EXTRA=_extra)


    wAngleBase = WIDGET_BASE(wBase, /ROW, SPACE=10)

    wColBase = WIDGET_BASE(wAngleBase, /COLUMN, SPACE=4)
    wLabel = WIDGET_LABEL(wColBase, /ALIGN_LEFT, $
        VALUE=IDLitLangCatQuery('Dialog:RotAngle:EnterAngle'))


    ; Default to zero angle initially (unless user specified).
    angle = KEYWORD_SET(angleIn) ? DOUBLE(angleIn) : 0


    wAngle = CW_ITUPDOWNFIELD(wColBase, $
        EVENT_PRO=myname+'_angle', $
        INCREMENT=5, $
        UNITS=STRING(176b), $
        VALUE=angle)


    wImage = WIDGET_DRAW(wAngleBase, $
        /ALIGN_CENTER, $
        EVENT_PRO=myname+'_draw', $
        /EXPOSE_EVENTS, $
        GRAPHICS_LEVEL=2, $
        RETAIN=0, $
        XSIZE=32, YSIZE=32)


    ; Button row
    wButtons = WIDGET_BASE(wBase, /ALIGN_CENTER, /GRID, /ROW, SPACE=5)

    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('Dialog:OK'))

    wCancel = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_cancel', VALUE=IDLitLangCatQuery('Dialog:Cancel'))
    WIDGET_CONTROL, wBase, CANCEL_BUTTON=wCancel

    ; Realize the widget.
    WIDGET_CONTROL, wBase, /REALIZE


    ; Retrieve my window objref and construct all objects.
    WIDGET_CONTROL, wImage, GET_VALUE=oWin
    oWin->SetCurrentCursor, 'ARROW'
    oModel = OBJ_NEW('IDLgrModel', LIGHTING=0)
    oFont = OBJ_NEW('IDLgrFont', 'Times', SIZE=14)
    oModel->Add, OBJ_NEW('IDLgrText', $
        IDLitLangCatQuery('Dialog:RotAngle:SampleLetter'), $
        ALIGN=0.5, $
        FONT=oFont, $
        VERTICAL_A=0.5)
    oModel->Add, OBJ_NEW('IDLgrPolyline', $
        DATA=0.7*[[-1,-1],[1,-1],[1,1],[-1,1],[-1,-1]])
    face3D = BYTE((WIDGET_INFO(wBase, /SYS)).face_3d)
    oView = OBJ_NEW('IDLgrView', COLOR=face3D)
    oView->Add, oModel
    oWin->SetProperty, GRAPHICS_TREE=oView
    WIDGET_CONTROL, wImage, SET_UVALUE=oModel


    ; Now we can initialize our draw.
    IDLitwdRotateByAngle_Update, wImage, angle


    ; Cache my state information within my child.
    state = { $
        wAngle: wAngle, $
        wImage: wImage, $
        pResult: PTR_NEW(/ALLOC)}

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        NO_BLOCK=0, EVENT_HANDLER=myname+'_event'


    ; Destroy fake top-level base if we created it.
    if (WIDGET_INFO(wTopDummy, /VALID)) then $
        WIDGET_CONTROL, wTopDummy, /DESTROY

    OBJ_DESTROY, oWin
    OBJ_DESTROY, oFont

    ; See if we got any results.
    cancel = (N_ELEMENTS(*state.pResult) eq 0)
    result = ~cancel ? *state.pResult : 0

    PTR_FREE, state.pResult

    return, result
end

