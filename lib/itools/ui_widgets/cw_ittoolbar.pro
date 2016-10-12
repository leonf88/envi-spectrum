; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_ittoolbar.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_ITTOOLBAR
;
; PURPOSE:
;   This function implements the compound widget for an iTools toolbar.
;
; CALLING SEQUENCE:
;   Result = CW_ITTOOLBAR(Parent, UI, Target)
;
; INPUTS:
;   Parent: The widget ID of the parent base for the new toolbar.
;
;   UI: The object reference of the IDLitUI object associated with the iTool.
;
;   Target: Set this argument to a string containing the relative or full
;       identifier of the tool container from which to construct the toolbar.
;
; KEYWORD PARAMETERS:
;   EXCLUSIVE: Set this keyword to create a toolbar with exclusive buttons,
;       where only one button may be depressed, and remains depressed until
;       another button is selected. The default is to create a pushbutton
;       toolbar.
;
;   ROW: Set this keyword to number of button rows within the toolbar.
;       The default is one row.
;
;   All other keywords (such as FRAME, TRACKING_EVENTS, etc.)
;   are passed on to the toolbar base.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified: CT, July 2003: Fixed docs, removed useless GROUP_LEADER.
;   Modified: CT, May 2004: Changed Target from keyword to argument.
;
;-


;-------------------------------------------------------------------------
function cw_ittoolbar_getbitmapfile, iconType

    compile_opt idl2, hidden

    if (iconType eq '') then $
        return, ''

    ; If the ICON already contains the correct suffix, assume
    ; it is a fully-qualified filename and just use it.
    ; Otherwise, look in the IDL resource/bitmaps directory.
    filename = (STRPOS(STRLOWCASE(iconType), '.bmp') gt 0) ? $
        iconType : $
        FILEPATH(iconType + '.bmp', SUBDIR=['resource','bitmaps'])

    ; Is that file there ?
    bExists = FILE_TEST(fileName, /READ)

    if (~bExists) then begin
        fileName = FILEPATH('default.bmp', $
            SUBDIR=['resource','bitmaps'])
        ; Is that file there ?
        bExists = FILE_TEST(fileName, /READ)
    endif

    return, bExists ? fileName : ''
end


;-------------------------------------------------------------------------
pro cw_ittoolbar_callback, wBase, strID, messageIn, userdata

    compile_opt idl2, hidden

    if (~WIDGET_INFO(wBase, /VALID)) then $
        return
    wChild = WIDGET_INFO(wBase, /CHILD)
    if (~WIDGET_INFO(wChild, /VALID)) then $
        return
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; Is the strID equal to ourself? Because we are a compound widget we
    ; aren't allowed to use our UNAME to store our ID.
    if (strID eq state.idContainer) then begin

        wID = wBase

    endif else begin

        ; Some identifiers will have "extra" sub-items that the toolbar
        ; doesn't care about. So nip those off until we find a match.
        idTmp = strID
        while (1) do begin
            wID = widget_info(wBase, find_by_uname=idTmp)
            if (wID ne 0) then $
                break
            base = IdlitBaseName(idTmp, remain=idTmp)
            if (base eq '') then $
                return ;; no match!
        endwhile

        if (~WIDGET_INFO(wID, /VALID)) then $
            return
    endelse


    case STRUPCASE(messageIn) of

    'SETVALUE': $
        case WIDGET_INFO(wID, /NAME) of

        'COMBOBOX': begin
            ; Retrieve current list.
            WIDGET_CONTROL, wID, GET_VALUE=values
            match = (WHERE(values eq userdata))[0]

            ; Either select an existing item, or add to list.
            if (match ge 0) then begin
                WIDGET_CONTROL, wID, SET_COMBOBOX_SELECT=match
                break
            endif

            ; Determine if the number of items in the combobox
            ; matches the number in the original list.
            ; If not, then just keep replacing the first
            ; element.  Otherwise, prepend to the list.
            nItems = WIDGET_INFO(wID, /COMBOBOX_NUMBER)
            targetID = WIDGET_INFO(wID, /UNAME)
            oTarget = state.oTool->GetByIdentifier(targetID)
            if (OBJ_VALID(oTarget)) then begin
                oTarget->GetProperty, DROPLIST_ITEMS=items
                replace = (nItems ne N_ELEMENTS(items))
            endif else $
                replace = 0
            if (replace) then begin
                ; Workaround.  On Unix, if the currently
                ; selected item is deleted, an event is
                ; issued (when it should not be).  So
                ; temporarily select any item other than
                ; the one to be deleted.
                WIDGET_CONTROL, wID, SET_COMBOBOX_SELECT=1
                ; Remove former first item from list.
                WIDGET_CONTROL, wID, $
                     COMBOBOX_DELETEITEM=0
            endif

            ; Prepend new first value.
            WIDGET_CONTROL, wID, COMBOBOX_ADDITEM=userdata, $
                 COMBOBOX_INDEX=0
            WIDGET_CONTROL, wID, SET_COMBOBOX_SELECT=0

            end

        'DROPLIST': begin
            ; Retrieve current list.
            WIDGET_CONTROL, wID, GET_VALUE=values
            match = (WHERE(values eq userdata))[0]
            if (match eq -1) then $
                break
            WIDGET_CONTROL, wID, SET_DROPLIST_SELECT=match
            end

        else:  ; need to implement other types

        endcase

    'SELECT': begin  ; Turn on/off our button.
        wasSet = WIDGET_INFO(wID, /BUTTON_SET)
        doSet = KEYWORD_SET(userdata)
        if (wasSet ne doSet) then begin
            WIDGET_CONTROL, wID, SET_BUTTON=doSet
        endif
        end

    'SENSITIVE': widget_control, wID, SENSITIVE=KEYWORD_SET(userdata)

    'SETPROPERTY': begin
        if (userdata ne 'NAME') then $
            break
        oItem = state.oTool->GetByIdentifier(strID)
        if (~OBJ_VALID(oItem)) then $
            break
        oItem->IDLitComponent::GetProperty, NAME=name
        WIDGET_CONTROL, wID, TOOLTIP=name
        end


    'ADDITEMS': begin       ;add an entry to the widget
        oItem = state.oTool->getbyidentifier(userdata)
        oItem->GetProperty, NAME=name, $
                            DESCRIPTION=desc, $
                            ICON=iconType, $
                            DISABLE=disable
        fileName = CW_ITTOOLBAR_GETBITMAPFILE(iconType)
        if (fileName ne '') then begin
            wButton = WIDGET_BUTTON(wID, /BITMAP, /FLAT, $
                                    VALUE=fileName, $
                                    FRAME=0, $
                                    SENSITIVE=1-KEYWORD_SET(disable), $
                                    TOOLTIP=name, $
                                    UNAME=userData)
            state.oUI->AddOnNotifyObserver, state.idUIadaptor, userData
        endif
       end

    'REMOVEITEMS': begin
        wItem = WIDGET_INFO(wBase, FIND_BY_UNAME=userData)
        if WIDGET_INFO(wItem, /VALID) then $
            WIDGET_CONTROL, wItem, /DESTROY
        state.oUI->RemoveOnNotifyObserver, state.idUIadaptor, userData
       end
    else:

    endcase

end


;-------------------------------------------------------------------------
pro cw_ittoolbar_event, event

    compile_opt idl2, hidden

@idlit_catch
    if (iErr ne 0) then begin
        CATCH, /CANCEL
        if (N_TAGS(state) gt 0) then begin
            if OBJ_VALID(state.oTool) then $
                state.oTool->ErrorMessage, !ERROR_STATE.msg, $
                    TITLE='cw_ittoolbar_event', SEVERITY=2
        endif
        return
    endif

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    strPath = WIDGET_INFO(event.id, /UNAME)

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_COMBOBOX': begin
            success = state.oTool->DoAction(strPath, OPTION=event.str)
            end

        'WIDGET_DROPLIST': begin
            WIDGET_CONTROL, event.id, GET_VALUE=droplist
            success = state.oTool->DoAction(strPath, OPTION=droplist[event.index])
            end

        'WIDGET_BUTTON': begin
            if (event.select) then begin
                success = state.oTool->DoAction(strPath)
            endif
            end

        else: ;help, event, /struc
    endcase

end


;-------------------------------------------------------------------------
pro cw_ittoolbar_build, oUI, idUIadaptor, wBase, oTools, $
    EXCLUSIVE=exclusive

    compile_opt idl2, hidden

    nTools = N_ELEMENTS(oTools)
    if (nTools eq 0) then $
        return

    for i=0,nTools-1 do begin

        ; Manipulators don't have this property, so define it.
        hasDroplist = 0b

        oTools[i]->GetProperty, NAME=name, $
            HAS_DROPLIST=hasDroplist, $
            ICON=iconType, $
            DISABLE=disable

        if (hasDroplist) then begin

            if (KEYWORD_SET(exclusive)) then $
                MESSAGE, 'An EXCLUSIVE toolbar cannot contain a droplist or combobox item.'

            strPath = oTools[i]->GetFullIdentifier()

            oTools[i]->GetProperty, DROPLIST_EDIT=droplistEdit, $
                DROPLIST_ITEMS=droplistItems, DROPLIST_INDEX=droplistIndex

            if (droplistEdit) then begin

                wOptions = WIDGET_COMBOBOX(wBase, $
                    /EDITABLE, $
                    VALUE=droplistItems, $
                    FRAME=0, /FLAT, $
                    IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
                    SENSITIVE=1-KEYWORD_SET(disable), $
                    UNAME=strPath)

                WIDGET_CONTROL, wOptions, SET_COMBOBOX_SELECT=droplistIndex

            endif else begin

                wOptions = WIDGET_DROPLIST(wBase, $
                    VALUE=droplistItems, $
                    FRAME=0, /FLAT, $
                    SENSITIVE=1-KEYWORD_SET(disable), $
                    UNAME=strPath)

                WIDGET_CONTROL, wOptions, SET_DROPLIST_SELECT=droplistIndex

            endelse

            oUI->AddOnNotifyObserver, idUIadaptor, strPath
        endif else begin
            ; Just skip the button if no bitmap.
            if (iconType eq '') then $
                continue
            ; Must be a toolbar button.
            fileName = CW_ITTOOLBAR_GETBITMAPFILE(iconType)

            if (fileName ne '') then begin
                strPath = oTools[i]->GetFullIdentifier()

                wButton = WIDGET_BUTTON(wBase, /BITMAP, /FLAT, $
                                        VALUE=fileName, $
                                        FRAME=0, $
                                        SENSITIVE=1-KEYWORD_SET(disable), $
                                        TOOLTIP=name, $
                                        UNAME=strPath)

                oUI->AddOnNotifyObserver, idUIadaptor, strPath
            endif else $
              Message,/CONTINUE, $
              IDLitLangCatQuery('UI:cwToolBar:BadBitmap') ;; kdb cleanup todo
        endelse
    endfor

end


;-------------------------------------------------------------------------
function cw_ittoolbar, parent, oUI, target, $
    EXCLUSIVE=exclusive, $
    ROW=rowIn, $
    NONEXCLUSIVE=nonexclusive, $   ; swallow
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

nparams = 3  ; must be defined for cw_iterror
@cw_iterror

    row = (N_ELEMENTS(rowIn) gt 0) ? rowIn[0] : 1
    space = (N_ELEMENTS(spaceIn) gt 0) ? spaceIn[0] : 0
    xpad = (N_ELEMENTS(xpadIn) gt 0) ? xpadIn[0] : 0
    ypad = (N_ELEMENTS(ypadIn) gt 0) ? ypadIn[0] : 0


    oTool = oUI->GetTool()


    ; Retrieve the list of items within our tool container.
    ;
    oContainer = oTool->GetByIdentifier(target)
    if(not obj_valid(oContainer))then return, 0l
    if (~OBJ_ISA(oContainer, 'IDL_Container')) then $
        MESSAGE, 'Target is not a container: ' + target

    oContainer->GetProperty, NAME=containername
    oItems = oContainer->Get(/ALL, COUNT=nitems)
    if (~nitems) then $
        return, 0L

    if (MIN(OBJ_ISA(oItems, 'IDLitObjDesc') or $
        OBJ_ISA(oItems, '_IDLitManipulator')) eq 0) then $
        MESSAGE, 'All items within the target must be registered operations or manipulators.'

    wBase = WIDGET_BASE(parent, $
        EVENT_PRO= 'cw_ittoolbar_event', $
        EXCLUSIVE=exclusive, $
        ROW=row, $
        /ALIGN_CENTER, $
        SPACE=0, XPAD=0, YPAD=0, $
        /TOOLBAR, $
        _EXTRA=_extra)

    idUIadaptor = oUI->RegisterToolBar(wBase, containername, $
        'cw_ittoolbar_callback')

    ; Register for notification messages
    oUI->AddOnNotifyObserver, idUIadaptor, containername

    CW_ITTOOLBAR_BUILD, oUI, idUIadaptor, wBase, oItems, $
        EXCLUSIVE=exclusive

    idContainer =  oContainer->GetFullIdentifier()

    ; Cache my widget information.
    state = {BASE: wBase, $
        oTool: oTool, $
        idUIAdaptor:idUIAdaptor, $
        oUI:oUI, $
        idContainer: idContainer}

    wChild = WIDGET_INFO(wBase, /CHILD)
    if (wChild ne 0 ) then $
        WIDGET_CONTROL, wChild, SET_UVALUE=state

    ; Register for notification messages
    oUI->AddOnNotifyObserver, idUIadaptor, idContainer

    return, wBase
end

