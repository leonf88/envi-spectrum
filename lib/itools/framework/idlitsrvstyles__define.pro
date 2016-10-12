; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvstyles__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool services needed for styles.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitsrvReadFile object.
;
; Arguments:
;   None.
;
;function IDLitsrvStyles::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; IDLitsrvStyles::CreateStyle
;
; Purpose:
;   Used to create a style for use by the system.
;
; Arguments:
;   Name: The style name.
;
pro IDLitsrvStyles::CreateStyle, style

    compile_opt idl2, hidden

    oSys = self->GetTool()

    oSys->CreateFolders, '/Registry/Styles/My Styles/'+style, $
        CLASSNAME='IDLitStyleFolder', $
        FOLDER_ICON='style', $
        /NOTIFY

    oStyle = self->Get(style)
    oStyle->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], /SENSITIVE

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::RegisterStyleItem
;
; Purpose:
;   Used to register a style item for use by the system.
;
; Arguments:
;   Name: The name of the visualization or annotation item.
;
;   Classname: The classname for the visualization or annotation.
;
; Keywords:
;   IDENTIFIER: The name of the style in which to place the item.
;       If this style doesn't exist then a new style container is
;       automatically created.
;
pro IDLitsrvStyles::RegisterStyleItem, strName, strClassName, $
    IDENTIFIER=identifier, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    oSys = self->GetTool()

    if (N_ELEMENTS(identifier) eq 0) then $
        identifier = strName

    oSys->Register, strName, strClassName, $
        IDENTIFIER="/Registry/Styles/My Styles/"+IDENTIFIER, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::GetByName
;
; Purpose:
;   Retrieve a Style object descriptor by name.
;
; Parameters:
;   Name: Name of the particular style being requested
;
; Keywords:
;   None.
;
function IDLitsrvStyles::GetByName, name

    compile_opt idl2, hidden

    if (STRCMP('Current Style', name, /FOLD_CASE)) then begin
        oSys = self->GetTool()
        oTool = oSys->_GetCurrentTool()
        if (~OBJ_VALID(oTool)) then $
            return, OBJ_NEW()
        return, oTool->GetByIdentifier('Current Style')
    endif

    oStyles = self->Get(/ALL, COUNT=nstyle)
    for i=0,nstyle-1 do begin
        oStyles[i]->IDLitComponent::GetProperty, NAME=stylename
        if (STRCMP(stylename, name, /FOLD_CASE)) then $
            return, oStyles[i]
    endfor
    return, OBJ_NEW()
end



;---------------------------------------------------------------------------
; IDLitsrvStyles::Get
;
; Purpose:
;   Used to gain external access to the Style object
;   descriptors contained in the system.
;
; Parameters:
;   id   - ID of the particular style being requested
;
; Keywords:
;  ALL    - Return All
;  COUNT  - The number of elements returned
;
function IDLitsrvStyles::Get, id, ALL=all, COUNT=count

    compile_opt idl2, hidden

    oSys = self->GetTool()

    self->VerifyStyles

    if (~KEYWORD_SET(all)) then begin
        oStyle = oSys->GetbyIdentifier("/Registry/Styles/My Styles/" + id)
        if (~OBJ_VALID(oStyle)) then begin
            oStyle = oSys->GetbyIdentifier( $
                "/Registry/Styles/System Styles/" + id)
        endif
        count = OBJ_VALID(oStyle)
        return, oStyle
    endif

    oMyStyleCont = oSys->GetbyIdentifier("/Registry/Styles/My Styles/")
    if (OBJ_VALID(oMyStyleCont)) then begin
        oMyStyles = oMyStyleCont->Get(/ALL, COUNT=mystyles)
    endif else begin
        ; We really need to have an empty My Styles folder.
        oSys->CreateFolders, "Registry/Styles/My Styles"
        mystyles = 0
    endelse

    oSysStyleCont = oSys->GetbyIdentifier("/Registry/Styles/System Styles/")
    if (OBJ_VALID(oSysStyleCont)) then begin
        oSysStyles = oSysStyleCont->Get(/ALL, COUNT=sysstyles)
    endif else begin
        sysstyles = 0
    endelse

    count = mystyles + sysstyles

    if (sysstyles gt 0) then begin
        result = (mystyles gt 0) ? [oMyStyles, oSysStyles] : oSysStyles
    endif else begin
        result = (mystyles gt 0) ? oMyStyles : OBJ_NEW()
    endelse

    return, result

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::_NewStyleName
;
; Purpose:
;   Internal method to construct a new style name that doesn't conflict
;   with existing names.
;
; Return value:
;   A string containing the new style name.
;
; Arguments:
;   StyleName: The style name to verify.
;
; Keywords:
;   COPY: If set, preface duplicate names with "Copy of".
;       The default is to put a duplicate number in parentheses after.
;
function IDLitsrvStyles::_NewStyleName, stylename, COPY=copy

    compile_opt idl2, hidden

    ; Existing style names.
    oStyles = self->Get(/ALL, COUNT=nstyle)
    styleNames = STRARR(2*nstyle > 1)
    for i=0,nstyle-1 do begin
        oStyles[i]->IDLitComponent::GetProperty, NAME=name, $
            IDENTIFIER=identifier
        styleNames[2*i] = name
        styleNames[2*i+1] = identifier
    endfor

    ; Be sure to choose a new name that isn't a duplicate.
    newstylename = stylename
    if (STRCMP(newstylename, 'Current Style', /FOLD_CASE)) then $
        newstylename = 'Copy of Current Style'
    index = 0
    while (MAX(STRCMP(styleNames, newstylename, /FOLD_CASE)) eq 1) do begin
        index++
        if (KEYWORD_SET(copy)) then begin
            newstylename = 'Copy '
            if (index gt 1) then $
                newstylename += STRTRIM(index, 2) + ' '
            newstylename += 'of ' + stylename
        endif else begin
            newstylename = stylename + ' (' + STRTRIM(index, 2) + ')'
        endelse
    endwhile

    return, newstylename
end


;---------------------------------------------------------------------------
; Purpose:
;   Update the FONT_INDEX property of a style item with the
;   list of available fonts on this system. Also try to match the desired
;   font index. If the font doesn't exist on this system, choose Helvetica.
;
pro IDLitsrvStyles::_FixFontList, oItem

    compile_opt idl2, hidden

    ; Retrieve the desired font name and the old fontlist.
    oItem->GetProperty, FONT_INDEX=fontIndex
    oItem->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=oldfonts
    fontName = oldfonts[fontIndex < (N_Elements(oldfonts)-1)]

    ; Retrieve the available font list.
    oFont = Obj_New('IDLitFont')
    if (~Obj_Valid(oFont)) then return
    oFont->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=newfonts
    Obj_Destroy, oFont

    ; Try to find a match, and set the new fontlist.
    match = (Where(newfonts eq fontName))[0]
    fontIndex = (match ge 0) ? match : 0
    oItem->SetProperty, FONT_INDEX=fontIndex
    oItem->SetPropertyAttribute, 'FONT_INDEX', ENUMLIST=newfonts
end

;---------------------------------------------------------------------------
; IDLitsrvStyles::Import
;
; Purpose:
;   Import a saved style from a file.
;
; Arguments:
;   Filename: The file name or names.
;
; Keywords:
;   NO_NOTIFY: If set, do not issue a notification.
;
;   SYSTEM: If set, add the new style to the system style folder.
;
pro IDLitsrvStyles::Import, filename, $
    NO_NOTIFY=noNotify, $
    SYSTEM=system

    compile_opt idl2, hidden

    notify = ~KEYWORD_SET(noNotify)

    oSys = self->GetTool()
    system = KEYWORD_SET(system)

    folder = '/Registry/Styles/' + $
        (system ? 'System Styles' : 'My Styles')
    if (~OBJ_VALID(oSys->GetByIdentifier(folder))) then $
        oSys->CreateFolders, folder

    mystyles = 0
    threwerror = 0

    for i=0,N_ELEMENTS(filename)-1 do begin

        ; First retrieve all structure/object classnames so we
        ; can instantiate the structures. This prevents the save file
        ; from restoring old object definitions, and also compiles all
        ; of the methods within the __define files.
        oSaveFile = OBJ_NEW('IDL_Savefile', filename[i])

        structs = oSaveFile->Names(COUNT=nstruct, /STRUCTURE_DEFINITION)

        ; Make sure we have a StyleFolder object structure.
        if (MAX(structs eq 'IDLITSTYLEFOLDER')) then begin
            OBJ_DESTROY, oSaveFile  ; don't need anymore
            ; To pick up our current structure defs, create our own
            ; structures first, then use relaxed structure on the file.
            for j=0,nstruct-1 do $
                void = CREATE_STRUCT(NAME=structs[j])
            RESTORE, filename[i], /RELAXED_STRUCTURE
        endif

        if (~OBJ_VALID(oStyle)) then begin
            ; Only display the error dialog once.
            if (~threwerror) then begin
                self->ErrorMessage, $
                    [IDLitLangCatQuery('Error:Framework:CannotReadFile') + filename[i], $
                    IDLitLangCatQuery('Error:Style:Unknown')], $
                    title=IDLitLangCatQuery('UI:Style:Import'), severity=2
            endif
            threwerror++
            continue
        endif

        oStyle->GetProperty, NAME=stylename

        ; Choose a new name (not already in use). This could change
        ; the name of a previously saved style, but we need to avoid
        ; name conflicts.
        newstylename = self->_NewStyleName(stylename)

        ; Always set the identifier equal to the name. It might not
        ; match if the user changed the Style name in a previous session,
        ; because we can't change the identifier while the system is active.
        oStyle->SetProperty, NAME=newstylename, $
            IDENTIFIER=STRUPCASE(newstylename)

        oStyle->SetPropertyAttribute, $
            ['NAME', 'DESCRIPTION'], SENSITIVE=~system

        oItems = oStyle->Get(/ALL, COUNT=nitems)
        for j=0,nitems-1 do begin
            props = oItems[j]->QueryProperty()
            oItems[j]->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], /HIDE
            for k=0,N_ELEMENTS(props)-1 do begin
                oItems[j]->GetPropertyAttribute, props[k], $
                    HIDE=hide, SENSITIVE=sens, TYPE=type, UNDEFINED=undef
                ; Convert from old fonts to available fonts.
                if (props[k] eq 'FONT_INDEX') then $
                    self->_FixFontList, oItems[j]
                if hide then continue
                if (~sens || type eq 0 || undef) then begin
                    oItems[j]->SetPropertyAttribute, props[k], /HIDE
                endif else begin
                    if (system && sens) then $
                        oItems[j]->SetPropertyAttribute, props[k], SENSITIVE=0
                endelse
            endfor
        endfor

        oSys->AddByIdentifier, folder, oStyle
        if notify then begin
            oSys->DoOnNotify, folder, "ADDITEMS", $
                oStyle->GetFullIdentifier()
        endif
    endfor

end

;---------------------------------------------------------------------------
; IDLitsrvStyles::RestoreAll
;
; Purpose:
;   Remove existing styles and retrieve all saved styles.
;
pro IDLitsrvStyles::RestoreAll, TOOL=oToolIn

    compile_opt idl2, hidden

    oSys = self->GetTool()
    oMyStyleCont = oSys->GetByIdentifier('/REGISTRY/STYLES/My Styles')
    if (OBJ_VALID(oMyStyleCont)) then begin
        oOldStyles = oMyStyleCont->Get(/ALL, COUNT=nstyles)
        oMyStyleCont->Remove, /ALL
        if (nstyles gt 0) then $
            OBJ_DESTROY, oOldStyles
    endif else begin
        ; We really need to have a My Styles folder.
        oSys->CreateFolders, "Registry/Styles/My Styles"
        oMyStyleCont = oSys->GetByIdentifier('/REGISTRY/STYLES/My Styles')
    endelse
    oSysStyleCont = oSys->GetByIdentifier('/REGISTRY/STYLES/System Styles')
    if (OBJ_VALID(oSysStyleCont)) then begin
        oOldStyles = oSysStyleCont->Get(/ALL, COUNT=nstyles)
        oSysStyleCont->Remove, /ALL
        if (nstyles gt 0) then $
            OBJ_DESTROY, oOldStyles
    endif else begin
        ; We really need to have a System Styles folder.
        oSys->CreateFolders, "Registry/Styles/System Styles"
        oSysStyleCont = oSys->GetByIdentifier('/REGISTRY/STYLES/System Styles')
    endelse

    ; System styles.
    ; Assume this program is in a subdirectory of iTools.
    path = FILEPATH('',subdir=['resource','itools','styles'])
    styleFiles = FILE_SEARCH(path, '*_style.sav', COUNT=nstyles)
    if (nstyles gt 0) then $
        self->Import, styleFiles, /NO_NOTIFY, /SYSTEM

    ; User styles.
    if (IDLitGetResource('styles', path, /USERDIR)) then begin
        styleFiles = FILE_SEARCH(path, '*_style.sav', COUNT=nstyles)
        if (nstyles gt 0) then $
            self->Import, styleFiles, /NO_NOTIFY
    endif

    oTool = (N_Elements(oToolIn) gt 0) ? oToolIn : oSys->_GetCurrentTool()
    if (Obj_Valid(oTool)) then begin
        ; Copy the Current Style and create the IDL Standard style.
        ; This is only done once per iTool session.
        self->Duplicate, 'Current Style', NAME='IDL Standard'
        oIDLStandard = oSys->GetbyIdentifier('/Registry/Styles/My Styles/IDL Standard')
        oMyStyleCont->Remove, oIDLStandard
        oIDLStandard->SetProperty, NAME='IDL Standard', IDENTIFIER='IDL Standard'
        oSysStyleCont->Add, oIDLStandard
        oIDLStandard->SetPropertyAttribute, ['Name', 'Description'], SENSITIVE=0
        oItems = oIDLStandard->Get(/ALL, COUNT=nItems)
        for i=0,nItems-1 do begin
            properties = oItems[i]->QueryProperty()
            oItems[i]->SetPropertyAttribute, properties, SENSITIVE=0
        endfor
    endif

    ; Use updateitem, not just additems, so that the tree is rebuilt
    ; and the items removed above are eliminated.  This could include
    ; styles that have been created but not saved which need to be
    ; destroyed. Notify both our top level folder and our subfolder.
    oSys->DoOnNotify, '/REGISTRY/STYLES', "UPDATEITEM", ''
    oSys->DoOnNotify, '/REGISTRY/STYLES/MY STYLES', "UPDATEITEM", ''

end

;---------------------------------------------------------------------------
; IDLitsrvStyles::VerifyStyles
;
; Purpose:
;   Verify that all current styles exist and are loaded.
;
; Keyword:
;   TOOL: Optional tool objref from which to copy the Current Style.
;       The default is to use the System's current tool.
;
pro IDLitsrvStyles::VerifyStyles, TOOL=oTool

    compile_opt idl2, hidden

    ; Prevent re-entrancy from the ::Get method. See CR47009.
    if self.withinVerify then return
    self.withinVerify = 1b

    oSys = self->GetTool()
    oIDLStandard = oSys->GetbyIdentifier('/Registry/Styles/System Styles/IDL Standard')
    if (~Obj_Valid(oIDLStandard)) then self->RestoreAll, TOOL=oTool

    self.withinVerify = 0b
end

;---------------------------------------------------------------------------
; IDLitsrvStyles::SaveStyle
;
; Purpose:
;   Save all current styles.
;
pro IDLitsrvStyles::SaveStyle, styleName, FILENAME=filename

    compile_opt idl2, hidden

    oStyle = self->GetByName(styleName)
    if (~OBJ_VALID(oStyle)) then $
        return

    if (N_ELEMENTS(filename) eq 0) then begin
        if (~IDLitGetResource('styles', path, /USERDIR, /WRITE)) then $
            return
        oStyle->GetProperty, NAME=stylename
        filename = STRLOWCASE(path + PATH_SEP() + $
            IDL_VALIDNAME(stylename, /CONVERT_ALL) + $
            '_style.sav')
    endif

    oStyle->GetProperty, _PARENT=oParent
    oStyle->SetProperty, _PARENT=OBJ_NEW()
    CATCH, errStatus
    if (errStatus eq 0) then begin
        SAVE, oStyle, FILENAME=filename, /COMPRESS, $
            DESCRIPTION='iTools Style File'
        CATCH, /CANCEL
    endif
    oStyle->SetProperty, _PARENT=oParent

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::SaveAll
;
; Purpose:
;   Save all current styles.
;
pro IDLitsrvStyles::SaveAll

    compile_opt idl2, hidden

    ; Delete all of our previous style files.
    if (IDLitGetResource('styles', path, /USERDIR)) then begin
        styleFiles = FILE_SEARCH(path, '*_style.sav', COUNT=noldstyles)
        if (noldstyles gt 0) then $
            FILE_DELETE, styleFiles, /QUIET
    endif

    oSys = self->GetTool()
    oStyleCont = oSys->GetbyIdentifier("/Registry/Styles/My Styles/")
    if (~OBJ_VALID(oStyleCont)) then $
        return
    oStyles = oStyleCont->Get(/ALL, COUNT=nstyles)

    for i=0,nstyles-1 do begin
        oStyles[i]->IDLitComponent::GetProperty, NAME=styleName
        self->SaveStyle, styleName
    endfor

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::PasteItem
;
; Purpose:
;   Duplicate a style item and put it into a new or existing style.
;
; Arguments:
;   oSrcItem: Object reference of the style item to duplicate.
;
;   idDstStyle: ID of the style in which to put the new item.
;       If this style doesn't exist then it will be created.
;
; Keywords:
;   PROPERTIES: Set this keyword to an array of property names to copy
;       to the new item. If not set then all properties are copied.
;
pro IDLitsrvStyles::PasteItem, oSrcItem, idDstStyle, $
    PROPERTIES=properties

    compile_opt idl2, hidden

    ; See if we are trying to add an item to our My Styles
    ; container (without a style name). If so, create a
    ; new style to hold it.
    if (idDstStyle eq '/REGISTRY/STYLES/MY STYLES') then begin
        newstylename = self->_NewStyleName('New Style')
        self->PasteItem, oSrcItem, newstylename, PROPERTIES=properties
        return
    endif

    ; Recurse on containers.
    if (OBJ_ISA(oSrcItem, 'IDLitContainer')) then begin
        oItems = oSrcItem->Get(/ALL, COUNT=nitems)
        for i=0,nitems-1 do $
            self->PasteItem, oItems[i], idDstStyle
        return
    endif

    ; Register our new style item for this visualization.
    oSrcItem->GetProperty, $
        NAME=name, $
        CLASSNAME=classname, $
        DESCRIPTION=description, $
        ICON=icon

    oSys = self->GetTool()

    ; Is this a full identifier? If so, assume we are overwriting
    ; an existing style item.
    withinTool = 0b
    if (STRCMP(idDstStyle, '/', 1)) then begin
        ; If we can't find our style, bail.
        oDstStyle = oSys->GetByIdentifier(idDstStyle)
        if (~OBJ_VALID(oDstStyle)) then $
            return
        oDstStyle->GetProperty, IDENTIFIER=idDstStyle
        oDstItem = oDstStyle->GetByIdentifier(name)
        if (~OBJ_VALID(oDstItem)) then begin
            ; This might be a visualization/annotation
            ; within the current tool style.
            oDstItem = oDstStyle->GetByIdentifier('Visualizations/' + name)
            if (~OBJ_VALID(oDstItem)) then begin
                oDstItem = oDstStyle->GetByIdentifier('Annotations/' + name)
            endif
            withinTool = OBJ_VALID(oDstItem)
        endif
    endif

    if (~OBJ_VALID(oDstItem)) then begin
        oStyle = self->Get(idDstStyle)
        if (~OBJ_VALID(oStyle)) then $
            self->CreateStyle, idDstStyle
        ; Not a full identifier, create a new style item.
        self->RegisterStyleItem, name, classname, $
            DESCRIPTION=description, ICON=icon, $
            IDENTIFIER=idDstStyle + '/' + name
        oDstItem = oSys->GetByIdentifier('/REGISTRY/STYLES/MY STYLES/' + $
            idDstStyle + '/' + name)
    endif


    ; Copy all properties?
    if (N_ELEMENTS(properties) gt 0) then begin
        for i=0,N_ELEMENTS(properties)-1 do begin
            oDstItem->RecordProperty, oSrcItem, properties[i], $
                OVERWRITE=~withinTool
        endfor
    endif else begin
        oDstItem->RecordProperties, oSrcItem, $
            OVERWRITE=~withinTool, /SKIP_HIDDEN
        if ~withinTool then $
            properties = oDstItem->QueryProperty()
    endelse

    if ~withinTool then begin
        oDstItem->SetPropertyAttribute, properties, HIDE=0, /SENSITIVE
        oDstItem->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], /HIDE
    endif

end


;---------------------------------------------------------------------------
; IDLitsrvStyles::Duplicate
;
; Purpose:
;   Duplicate a style.
;
; Arguments:
;   idStyleSrc: ID of the style to duplicate.
;
pro IDLitsrvStyles::Duplicate, styleName, NAME=newstylename

    compile_opt idl2, hidden

    oSys = self->GetTool()

    if (styleName eq 'Current Style') then begin
        oTool = oSys->_GetCurrentTool()
        if (~OBJ_VALID(oTool)) then $
            return
        oStyleSrc = oTool->GetByIdentifier('Current Style')
    endif else begin
        oStyleSrc = self->GetByName(styleName)
    endelse

    if (~OBJ_VALID(oStyleSrc)) then $
        return

    ; Choose a new name (not already in use).
    if (N_Elements(newstylename) eq 0) then begin
        oStyleSrc->GetProperty, NAME=stylename
        newstylename = self->_NewStyleName(stylename, /COPY)
    endif

    oItems = oStyleSrc->Get(/ALL, COUNT=nitems)
    for i=0,nitems-1 do $
        self->PasteItem, oItems[i], newstylename


end


;---------------------------------------------------------------------------
; IDLitsrvStyles::UpdateCurrentStyle
;
; Purpose:
;   Updates current tool style with a style.
;
; Arguments:
;   styleName: Name of the style to copy.
;
; Keywords:
;   NO_TRANSACT: If set then an Undo/Redo command set is not returned.
;
;   TOOL: Set this keyword to the ID of the tool to update.
;       If not specified then the current tool is updated.
;
function IDLitsrvStyles::UpdateCurrentStyle, styleName, $
    NO_TRANSACT=noTransact, $
    TOOL=oTool

    compile_opt idl2, hidden

    if (styleName eq '') then $
        return, OBJ_NEW()

    oSys = self->GetTool()

    if (~N_ELEMENTS(oTool)) then $
        oTool = oSys->_GetCurrentTool()
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; Retrieve using full identifier.
    oStyleSrc = self->GetByName(styleName)
    if (~OBJ_VALID(oStyleSrc)) then return, OBJ_NEW()

    ; Are we actually doing just a single item?
    if (OBJ_ISA(oStyleSrc, 'IDLitObjDesc')) then begin
        oItems = oStyleSrc
        nitems = 1
    endif else begin
        oItems = oStyleSrc->Get(/ALL, COUNT=nitems)
    endelse

    doTransact = ~KEYWORD_SET(noTransact)

    for i=0,nitems-1 do begin
        oItems[i]->IDLitComponent::GetProperty, IDENTIFIER=id
        ; Retrieve from either the visualizations or annotations.
        oVisDesc = oTool->GetVisualization(id)
        if (~OBJ_VALID(oVisDesc)) then $
            oVisDesc = oTool->GetAnnotation(id)
        if (~OBJ_VALID(oVisDesc)) then $
            continue

        ; Make sure our properties are initialized. This is needed on Tool
        ; startup if you have a default style.
        oVisDesc->_InitializePropertyBag

        ; Record all of our initial registered property values.
        if (doTransact) then begin
            oPropSet = self->RecordInitialProperties(oVisDesc, oItems[i], $
                /SKIP_HIDDEN)
        endif
        oVisDesc->RecordProperties, oItems[i], /SKIP_HIDDEN
        ; Record all of our final property values.
        if (OBJ_VALID(oPropSet)) then begin
            self->RecordFinalProperties, oPropSet, /SKIP_MACROHISTORY
            oCmdSet = (N_ELEMENTS(oCmdSet) gt 0) ? $
                [oCmdSet, oPropSet] : oPropSet
        endif

        ; Notify all observers of this Current Style item.
        ; This is usually just the PropSheet in the Style Editor.
        oTool->DoOnNotify, oVisDesc->GetFullIdentifier(), 'SETPROPERTY', ''

    endfor

    return, (N_ELEMENTS(oCmdSet) gt 0) ? oCmdSet : OBJ_NEW()
end


;---------------------------------------------------------------------------
pro IDLitsrvStyles__define

    compile_opt idl2, hidden

    struct = {IDLitsrvStyles, $
        inherits IDLitOperation, withinVerify: 0b}

end
