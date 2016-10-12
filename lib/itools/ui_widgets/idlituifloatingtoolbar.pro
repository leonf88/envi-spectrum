; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituifloatingtoolbar.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This function implements the user interface for a floating toolbar.
;
; Result:
;   This function returns a 1 on success, or a 0 otherwise.
;
; Arguments:
;   UI: A reference to the base IDLitUI object.
;   Requester: A reference to the object that is requesting this
;       user interface.
;

function IDLituiFloatingToolbar, oUI, oRequester

    compile_opt idl2, hidden

    ; Use my operation's name to construct the toolbar.
    oRequester->GetProperty, NAME=toolbarName
    if (toolbarName eq '') then $
        return, 0

    widgetName = toolbarName + '_TOOLBAR'

    ; Is this toolbar already registered?
    wID = oUI->GetWidgetByName(widgetName)

    if (~WIDGET_INFO(wID, /VALID)) then begin

        ; Not registered, built the toolbar and register
        oUI->GetProperty, GROUP_LEADER=groupLeader

        wID = IDLitwdToolbar(oUI, GROUP_LEADER=groupLeader, $
            TARGET_IDENTIFIER=toolbarName, $
            TITLE=toolbarName, $
            TOOLBAR_IDENTIFIER=oRequester->GetFullIdentifier())

        if (~wID) then $
            return,0

        idSelf = oUI->RegisterWidget(wID, widgetName, /FLOATING)

    endif else begin

        ; The widget is registered, so just toggle its mapped state.
        isMapped = WIDGET_INFO(wID, /MAP)
        WIDGET_CONTROL, wID, MAP=~isMapped

    endelse

    return, 1
end

