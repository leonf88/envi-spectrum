; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdexportwizard.pro#1 $
;---------------------------------------------------------------------------
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
; NAME:
;   IDLitwdExportWizard
;
; PURPOSE:
;   This function implements the export wizard functionality, allowing
;   tool information to be output to either a file or variable.
;


;-------------------------------------------------------------------------
pro _idlitwdEW_help, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    oTool = (*pState).oTool
    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return
    oHelp->HelpTopic, oTool, 'iToolsExportWizard'

end


;;---------------------------------------------------------------------------
;;Begin source selection section.
;;---------------------------------------------------------------------------
;; Variable naming section
;;---------------------------------------------------------------------------
;; _idlitwdIW_Variable_Cleanup
;;
;; Purpose:
;;   Cleanup routine
;;
pro _idlitwdEW_Variable_Cleanup, id
   compile_opt hidden, idl2

   widget_control,id, get_uvalue=pState
   if(ptr_valid(pState))then ptr_free, pstate
end
;;---------------------------------------------------------------------------
;; _idlitIW_GetFileName
;;
;; Purpose:
;;
;; Parameter
;;  The state struct (in a pointer) of the page.
;;
;; Return Value:
;;    1 - yes
;;    0 - No

function _idlitEW_GetVariableName, pState, name, idWriter

   compile_opt idl2, hidden

   widget_control, (*pState).wVName, get_value=value
   name = IDL_ValidName(value[0], /convert_all)

   return, keyword_set(name)
end
;;---------------------------------------------------------------------------
;; _idlitwdEW_Variable_CheckName
;;
;; Purpose:
;;   Validate the name that is contained in the text field of the page
;;
;; Parameters:
;;    pState - Our state struct
;;
pro _idlitwdEW_Variable_CheckName, pState
   compile_opt hidden, idl2
   widget_control, (*pState).wVName, get_value=name
   if(IDL_ValidName(name[0]) eq '')then begin
       void = dialog_message(/information, dialog_parent=(*pState).wWizard, $
                             IDLitLangCatQuery('UI:wdExportWiz:BadVar'))

       name = IDL_ValidName(name[0], /convert_all)
       widget_control, (*pState).wVName, set_value=name, $
         set_text_select=[0, strlen(name)]
   endif
   dialog_wizard_setNext, (*pState).wWizard, (*pState).bNext
end
;;---------------------------------------------------------------------------
;; _idlitwdEW_Variable_EV
;;
;; Purpose:
;;   This is the IDL event handler for the variable naming page of the
;;   wizard.
;;
pro _idlitwdEW_Variable_EV, sEvent

   compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       return
   endif
   widget_control, sEvent.handler, get_uvalue=pSTate
   type = widget_info(sEvent.id, /uname)
   case type of
       'NAME': _idlitwdEW_Variable_CheckName, pState ;validate the name
       else:
   endcase
end
;;---------------------------------------------------------------------------
;;  _idlitWdEW_Variable
;;
;; Purpose:
;;  Creates the page for the variable naming page of the wizard.
;;
;; Parameters:
;;    id  - Our parent
;;
;;    pState - Dialog state

function _idlitWdEW_Variable, id, pState
    compile_opt hidden, idl2

    ;; Create our display
    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                        MAP=0, SPACE=5, $
                        kill_notify='_idlitwdEW_Variable_Cleanup', $
                       event_pro='_idlitwdEW_Variable_EV')
    sGeom = widget_info(id, /geometry)

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPrompt, value= $
                         IDLitLangCatQuery('UI:wdExportWiz:EnterVar'))

    wFileSel = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wFileSel, /COLUMN)

    oTool = (*pState).oTool
    oItem = oTool->GetByIdentifier((*pState).idSrc)

    oItem->GetProperty, name=name, description=description, type=type

    ; Cannot allow null strings for widget_label on Windows.
    if (name eq '') then $
        name = ' '
    if (description eq '') then $
        description = ' '
    if (type eq '') then $
        type = ' '

    ;; file name section
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:DataName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=name, $
                        scr_xsize=sGeom.xsize*.8, /align_left)

    ;; Type display
    wBCL = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wBCL, /COLUMN)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:DataType'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wType = Widget_Label(wTmp, value=type, $
                        scr_xsize=sGeom.xsize*.8, /align_left)

    ;; description
    wBCL = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wBCL, /COLUMN)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:Desc'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wDesc = Widget_Label(wTmp, value=description, $
                        scr_xsize=sGeom.xsize*.8, /align_left)


    wBCL = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wBCL, /COLUMN)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:VarName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wVName = Widget_Text(wTmp, value=idl_validname(name, /convert_all), $
                        /editable, uname="NAME", $
                        scr_xsize=sGeom.xsize*.8, /align_left)



    ;; Our state
    state = { wName          : wName,       $
              wType          : wType,       $
              wDesc          : wDesc,       $
              wVName         : wVName,      $
              wWizard        : id,          $

              bNext          : 1}
   *(*pState).pSubState[1] = state
   widget_control, wPage, set_uvalue=(*pState).pSubState[1]

   return, wPage
end



;;---------------------------------------------------------------------------
;; File Selection section
;;---------------------------------------------------------------------------
;; _idlitIW_GetFileAttributes
;;
;; Purpose:
;;   Used to get the attributes or values from the file selection page.
;;
;; Parameter
;;  pState - The state struct (in a pointer) of the page.
;;
;;  name[out] - name of the file.
;;
;;  idWriter[out] - The id of the selected writer.
;;
;;  scale[out] - Scale factor.
;;
;; Return Value:
;;    1 - yes
;;    0 - No

function _idlitIW_GetFileAttributes, pState, name, idWriter, scale

   compile_opt idl2, hidden

   widget_control, (*pState).wName, get_value=value
   name = strtrim(value[0], 2)

   widget_control, (*pState).wWriters, get_uvalue=ids
   index = widget_info((*pState).wWriters, /droplist_select)
   if(index ge 0 and index lt n_elements(ids))then $
     idWriter = ids[index] $
   else $
     idWriter=''

    ; If no file extension, we need to add one.
    ; We need to do this here so we can prompt for overwrite below.
    if (STRPOS(name, '.') eq -1) then begin
        oWriteDesc = (*pState).oTool->GetByIdentifier(idWriter)
        oWriter = oWriteDesc->GetObjectInstance()
        strext = oWriter->GetFileExtensions(count=count)
        oWriteDesc->ReturnObjectinstance,oWriter
        if (count gt 0) then $
            name += '.' + strExt[0]
    endif

    ; See if we need to prompt for overwrite.
    if (FILE_TEST(name)) then begin
        if (DIALOG_MESSAGE([name + IDLitLangCatQuery('UI:wdExportWiz:Exists'), $
            IDLitLangCatQuery('UI:wdExportWiz:Replace?')], $
            /QUESTION, DIALOG_PARENT=(*pState).wWizard) ne 'Yes') then $
            return, 0
    endif

   scale = (*pState).scale
   return, keyword_set(name)
end
;;---------------------------------------------------------------------------
;; _idlitwdIW_SelectWRiter_Cleanup
;;
;; Purpose:

;;
pro _idlitwdEW_SelectWriter_Cleanup, id
   compile_opt hidden, idl2

   widget_control,id, get_uvalue=pState
   if(ptr_valid(pState))then ptr_free, pstate
end


;;---------------------------------------------------------------------------
;; _idlitwdEx_UpdateFileExtension
;;
;; Purpose:
;;   Change file extension if a new filter is selected
;;
;; Parameters:
;;   pState   - page state
;;
;;   idxWriter - Index of the new writer.
;;
pro _idlitwdEX_UpdateFileExtension, pState, idxWriter
    compile_opt hidden, idl2
    ;; Update our extension
    widget_control, (*pState).wPbase, get_uvalue=strExt
    strExt = strExt[idxWriter]
    widget_control, (*pState).wName, get_value=strName
    if(strtrim(strName,2) eq '')then return

    iDot = strpos(strName, '.',/reverse_search)
    if(iDot gt 0)then $
      strName = strMid(strName,0,iDot)
    strName = strName[0] + '.'+strExt
    widget_control, (*pState).wName, set_value=strName
end


;;---------------------------------------------------------------------------
;; _idlitwdEx_UpdateWriterType
;;
;; Purpose:
;;   Change the displayed writer type.
;;
;; Parameters:
;;   pState   - page state
;;
;;   filename - The current filename.
;;
pro _idlitwdEX_UpdateWriterType, pState, filename
    compile_opt hidden, idl2

    oWrite  = (*pState).oTool->GetService("WRITE_FILE")
    if(not obj_valid(oWrite))then return

    widget_control, (*pstate).wWriters, get_uvalue=idWriters
    if(n_elements(idwriters) gt 0)then begin
        id = oWrite->FindMatchingWriter(filename)
        dex = where(id eq idWriters, count)
        if(count gt 0)then begin
            widget_control, (*pstate).wWriters, set_droplist_select=dex[0]
            widget_control, (*pState).wProps, $
                SET_VALUE=idWriters[dex[0]]
        endif
    endif
end


;---------------------------------------------------------------------------
pro _idlitwdEX_SelectWriter_UpdateScale, pState, scale

    compile_opt hidden, idl2

    minscale = 16./MIN((*pState).dims)
    maxscale = MIN(DOUBLE((*pState).maxdims)/(*pState).dims)
    WIDGET_CONTROL, (*pState).wScale, GET_VALUE=currentscale

    if (scale lt minscale) || (scale gt maxscale) || $
        (scale ne currentscale) then begin
        scale = minscale > scale < maxscale
        WIDGET_CONTROL, (*pState).wScale, SET_VALUE=scale
    endif

    (*pState).scale = scale

    dims = STRTRIM(LONG((*pState).dims * (*pState).scale), 2)
    WIDGET_CONTROL, (*pState).wDim1, $
        SET_VALUE=dims[0], SET_UVALUE=dims[0]
    WIDGET_CONTROL, (*pState).wDim2, $
        SET_VALUE=dims[1], SET_UVALUE=dims[1]

end


;;---------------------------------------------------------------------------
;; _idlitwdEX_SelectWriter_UpdatePage
;;
;; Purpose:
;;   This routine will update the contents of the file selectoin page.
;;
;; Parameters:
;;   pState   - The state for this page.

PRO  _idlitwdEX_SelectWriter_UpdatePage, pState, idPrevWriter
   compile_opt hidden, idl2

   strNames=''
   ;; Get the set of available writers for the current data type
   idWriters=''
   oWrite  = (*pState).oTool->GetService("WRITE_FILE")
   if(obj_valid(oWrite))then begin
        types = STRSPLIT(STRCOMPRESS((*pState).type, /REMOVE), ',', /EXTRACT)
       idWriters = oWrite->GetWritersByType(types, count=nWriters)
       if(nWriters gt 0)then begin
           ;; Make a name list
           strNames = strarr(nWriters)
           strExt   = strNames
            for i=0, nWriters-1 do begin
                oTmp = (*pState).oTool->GetByIdentifier(idWriters[i])
                oTmp->getproperty, name=name, desc=desc
                strNames[i] = name
                oWriter = oTmp->GetObjectInstance()
                ext = oWriter->GetFileExtensions(count=count)
                oTmp->ReturnObjectinstance,oWriter
                if(count gt 0)then $
                  strExt[i] = ext[0]
            endfor
        endif
    endif else  nWriters =0

    ;; Set the values on the writerdroplist & label
    widget_control, (*pState).wWriters, $
        SET_VALUE=strNames + ' (*.' + strExt + ')', SET_UVALUE=idWriters

    idx = 0

    ; See if we remembered the writer from last time.
    if (idPrevWriter ne '') then begin
        idx = (WHERE(idWriters eq idPrevWriter))[0] > 0
        WIDGET_CONTROL, (*pState).wWriters, SET_DROPLIST_SELECT=idx
    endif

    widget_control, (*pState).wProps, SET_VALUE=idWriters[idx]

    ;; Stash extensions in the props button
    widget_control, (*pState).wPbase, set_uvalue=strExt
    ;; enable/disable file selection portion of the dialog
    WIDGET_CONTROL, (*pState).wFileSel, SENSITIVE=(nWriters gt 0)
    WIDGET_CONTROL, (*pState).wName, SET_VALUE=''

    ;; Okay, are we rastorizing?
    ;; Get the item we are outputing and setup the scale factor.
    oItem = (*pState).oTool->GetByIdentifier((*pState).idSrc)
    if( obj_isa(oItem, "IDLitGrView") || obj_isa(oItem, "IDLitgrWinScene"))then begin
        oItem->GetProperty, dimensions=dims
        (*pState).dims = FIX(dims)
        _idlitwdEX_SelectWriter_UpdateScale, pState, (*pState).scale
        widget_control, (*pState).wBScale, /map
    endif else begin
        widget_control, (*pState).wBScale, map=0
    endelse

end


;;---------------------------------------------------------------------------
;; _idlitwdIW_FileSel_EV
;;
;; Purpose:
;;   This is the IDL event handler for this file selection page of the
;;   wizard.
;;
;; Parameters:
;;   sEvent - The event from the system.

pro _idlitwdEW_SelectWriter_EV, sEvent

   compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       return
   endif

    if ((TAG_NAMES(sEvent, /STRUC) eq 'WIDGET_KBRD_FOCUS') $
        && sEvent.enter) then return

   widget_control, sEvent.handler, get_uvalue=pSTate
   type = widget_info(sEvent.id, /uname) ;what triggered an event.

   case type of

       ;; Check to see if the select file button was pushed
       'FILE_SEL': begin
           nExt = 0
           oWrite  = (*pState).oTool->GetService("WRITE_FILE")

           ; get our extensions
           if(obj_valid(oWrite))then begin
            types = STRSPLIT(STRCOMPRESS((*pState).type, /REMOVE), ',', /EXTRACT)
             ext = oWrite->GetFilterListByType(types, COUNT=nExt)

             if (nExt gt 0) then begin
                 ; On Motif, the filters cannot have spaces between them.
                 ext[*,0] = STRCOMPRESS(ext[*,0], /REMOVE_ALL)

                ; Rearrange the filter list so our currently selected
                ; writer type is first. This assumes that the droplist
                ; is in sync with the filter list returned above.
                currentWriter = WIDGET_INFO((*pState).wWriters, $
                   /DROPLIST_SELECT)
                ic = INDGEN(nExt) + 1
                ; Sort to front of list (also a sanity check for the index).
                ic[currentWriter < (nExt-1)] = 0
                ext = ext[SORT(ic), *]
             endif

           endif

            if (nExt eq 0) then $
                ext='*'

            ; Retrieve working directory.
            (*pState).oTool->GetProperty, $
                CHANGE_DIRECTORY=changeDirectory, $
                WORKING_DIRECTORY=workingDirectory
            WIDGET_CONTROL, (*pState).wName, GET_VALUE=currentFilename

           file = dialog_pickfile(dialog_parent=sEvent.top, /WRITE, $
                GET_PATH=newDirectory, $
                PATH=workingDirectory, $
                FILE=currentFilename, $
                FILTER=ext)

           if(file ne '')then begin
               widget_control, (*pState).wName, set_value=file[0]
               _idlitwdEX_UpdateWriterType, pState, file[0]
               dialog_wizard_setNext, (*pState).wWizard, 1
               (*pState).bNext = 1
                ; Set the new working directory if change_directory is enabled.
                if (KEYWORD_SET(changeDirectory)) then $
                    (*pState).oTool->SetProperty, $
                        WORKING_DIRECTORY=newDirectory
           endif
       end

       'FILENAME': begin
            widget_control, sEvent.id, get_value=file, get_uvalue=oldfile
            if (file ne oldfile) then begin
                widget_control, sEvent.id, set_uvalue=file
            endif
            if (strtrim(file,2) eq '') then begin
                dialog_wizard_setNext, (*pState).wWizard, 0 ;; disable
            endif else begin
                _idlitwdEX_UpdateWriterType, pState, file[0]
                dialog_wizard_setNext, (*pState).wWizard, 1       ;; enable next button
            endelse
       end

       'WRITER': begin ;; update our writer status
           widget_control, (*pState).wWriters, get_uvalue=idWriters
           widget_control, (*pState).wProps, $
               SET_VALUE=idWriters[sEvent.index]
           ;; Update our extension
           _idlitwdEX_UpdateFileExtension, pState, sEvent.index
       end

       'SCALE_FACTOR':begin  ; scale bar selected.
            _idlitwdEX_SelectWriter_UpdateScale, pState, sEvent.value
       end

        'WIDTH':begin
            WIDGET_CONTROL, (*pState).wDim1, $
                GET_VALUE=width, GET_UVALUE=oldwidth
            ; Test if we can successfully convert value to a double.
            ON_IOERROR, skipwidth   ; suppress conversion warnings
            scale = DOUBLE(width)/(*pState).dims[0]
            ON_IOERROR, null
            _idlitwdEX_SelectWriter_UpdateScale, pState, scale
            break
skipwidth:
            WIDGET_CONTROL, (*pState).wDim1, SET_VALUE=oldwidth
            end

        'HEIGHT':begin
            WIDGET_CONTROL, (*pState).wDim2, GET_VALUE=height
            ; Test if we can successfully convert value to a double.
            ON_IOERROR, skipheight   ; suppress conversion warnings
            scale = DOUBLE(height)/(*pState).dims[1]
            ON_IOERROR, null
            _idlitwdEX_SelectWriter_UpdateScale, pState, scale
            break
skipheight:
            WIDGET_CONTROL, (*pState).wDim2, SET_VALUE=oldwidth
            end

        else:
   endcase
end
;;---------------------------------------------------------------------------
;;  _idlitWdIW_SelectWriter
;;
;; Purpose:
;;  Creates the page for the file selection and writer options in the
;;  wizard. This is the first sub-page of page 3.
;;
;; Parameters:
;;    id  - Our parent
;;
;;    pState - Dialog state

function _idlitWdEW_SelectWriter, id, pState
    compile_opt hidden, idl2

    ;; Create our display
    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                        MAP=0, SPACE=5, $
                        kill_notify='_idlitwdEW_SelectWriter_Cleanup', $
                       event_pro='_idlitwdEW_SelectWriter_EV')
    sGeom = widget_info(id, /geometry)

;    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPage, value= $
                         IDLitLangCatQuery('UI:wdExportWiz:SelFile'))

    wFileSel = widget_base(wPage, /ROW, space=8, XPAD=0)
    wBase = widget_base(wFileSel, /COLUMN, XPAD=0)

    ;; file name section
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:FileName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Text(wTmp, value='', /EDITABLE, $
                        uname="FILENAME",/all_events, $
                        scr_xsize=sGeom.xsize*.8, /align_left, $
                        uvalue='')


    ;; Get the file open button.
    fileName = FILEPATH('open.bmp', SUBDIR=['resource','bitmaps'])
    bThere = file_test(fileName, /read)
    if(bThere)then $
      wButton = widget_button(wTmp, value=filename, /bitmap, /FLAT, uname='FILE_SEL') $
    else $
      wButton = widget_button(wTmp, value="...", uname='FILE_SEL')

    ;; Type display
    wTmp = Widget_Label(wPage, value= $
                        IDLitLangCatQuery('UI:wdExportWiz:FileType'), $
                        /align_left)
    wTmp = Widget_base(wPage,/row, xpad=10, ypad=0)
    wWriters = widget_droplist(wTmp, uname='WRITER', uvalue='', $
        scr_xsize=sGeom.xsize*.6, $
        /dynamic, /FLAT)

    wBCL = widget_base(wPage, COLUMN=2, space=8)

    wBase = widget_base(wBCL, /COLUMN)

    ;; Display area for output dimensions
    wBScale = widget_base(wBase, /COLUMN, xpad=0, $
        ypad=8, space=1, /base_align_right)
    wScale = CW_ITUPDOWNFIELD(wBScale, $
        INCREMENT=0.1d, $
        LABEL=IDLitLangCatQuery('UI:wdExportWiz:Scale'), $
        UNAME='SCALE_FACTOR', $
        VALUE=(*pState).scale)
    wBase1 =  widget_base(wBScale, /ROW, SPACE=5, XPAD=0, YPAD=0)
    wVoid = WIDGET_LABEL(wBase1, VALUE=IDLitLangCatQuery('UI:wdExportWiz:Width'))
    wDim1 = WIDGET_TEXT(wBase1, VALUE='1234', $
        /EDITABLE, /KBRD_FOCUS_EVENTS, $
        XSIZE=5, UNAME='WIDTH')
    wBase1 =  widget_base(wBScale, /ROW, SPACE=5, XPAD=0, YPAD=0)
    wVoid = WIDGET_LABEL(wBase1, VALUE= $
                         IDLitLangCatQuery('UI:wdExportWiz:Height'))
    wDim2 = WIDGET_TEXT(wBase1, VALUE='1234', $
        /EDITABLE, /KBRD_FOCUS_EVENTS, $
        XSIZE=5, UNAME='HEIGHT')


    wPbase = widget_base(wBCL, /COLUMN)
    ;; Writer property sheet
    wProps = CW_ITPROPERTYSHEET(wPbase, (*pState).oUI, $
        SCR_XSIZE=sGeom.xsize*.65, YSIZE=5, $
        /SUNKEN_FRAME, $
        /COMMIT_CHANGES)

    ; Retrieve the maximum buffer dimensions.
    oBuffer = OBJ_NEW('IDLgrBuffer')
    oBuffer->GetDeviceInfo, MAX_VIEWPORT_DIMENSIONS=maxdims
    OBJ_DESTROY, oBuffer

    ;; Our state. This page provides a lot of functionality, so the
    ;; state is large
    state = { wName          : wName,       $
              wFileSel       : wFileSel,    $
              wWizard        : id,          $
              bNext          : 0,           $
              wWriters       : wWriters,    $
              wPbase         : wPbase,      $
              wProps         : wProps,      $
              oTool          : (*pState).oTool, $
              oUI            : (*pState).oUI, $
              type           : (*pState).strType, $
              idSrc          : (*pState).idSrc, $
              wBScale        : wBScale,     $
              wScale         : wScale, $
              wDim1          : wDim1, $
              wDim2          : wDim2, $
              scale          : (*pState).scale,           $
              dims           : lonarr(2),   $
              maxdims        : maxdims}
   *(*pState).pSubState[0] = state
   widget_control, wPage, set_uvalue=(*pState).pSubState[0]

   ;; Update the writer list and display
   _idlitwdEX_SelectWriter_UpdatePage, $
        (*pState).pSubState[0], (*pState).idWriter

   return, wPage
end

;;-------------------------------------------------------------------------
;; IDLitWDExportWizard_3_Create
;;
;; Purpose:
;;   Constructs the 3nd page of the export wizard. This page actually
;;   contains 2 sub-pages that key off the item selected on the first
;;   page of the wizard. As such, this routine will decide which page
;;   is active and route the create execute to it's associated
;;   routine.
;;
;; Parameters:
;;   id - The id of the wizard.

pro IDLitWdExportWizard_3_Create, id
    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    ;; Determine where we are getting the data from
    iPage =(*pState).iDstType ;; easier to read.

    ;; Is the page already up (ie realized)?
    if(widget_info((*pState).w2Subs[iPage],/valid))then begin
        wPage = (*pState).w2Subs[iPage]
        ;; Update our sub-page values so they are valid.
        if(iPage eq 0)then begin ;;
            pSub =    (*pState).pSubState[0]
            (*pSub).type = (*pState).strType
            (*pSub).idSrc = (*pState).idSrc
            _idlitwdEX_SelectWriter_UpdatePage, pSub, (*pState).idWriter
        endif else begin ;; variables page
            ;; If the variable name changed...etc, we will need to
            ;; update the page display.
            oTool = (*pState).oTool
            oItem = oTool->GetByIdentifier((*pState).idSrc)
            oItem->GetProperty, name=name, description=description, type=type
            pSub =    (*pState).pSubState[1]
            widget_control, (*pSub).wName, set_value=name
            widget_control, (*pSub).wType, set_value=type
            widget_control, (*pSub).wDesc, set_value=description
            widget_control, (*pSub).wVName, set_value=idl_validname(name,/convert_all)
        endelse
    endif else begin ;; Build the page
        case iPage of
            0: wPage = _idlitWdEW_SelectWriter(id, pState)
            1: wPage = _idlitWdEW_Variable(id, pState)
        endcase
        (*pState).w2Subs[iPage] = wPage
    endelse
    ;; Update the next button to the current state.
    dialog_wizard_setNext, id, (*(*pState).pSubState[iPage]).bNext
    widget_control, wPage,  /map    ;; show the page
    (*pState).wPages[2] = wPage ;; Set the main page list to current sub-page
end
;;-------------------------------------------------------------------------
;; IDLitWDExportWizard_3_destroy
;;
;; Purpose:
;;  Called to destroy the page.
;;
;;  Since page 3 is actually a set of two pages, determine which
;;  page is active and hide it.
;;
;; Parameters:
;;   id - The page id.
;;
;;   bNext - True if the system is moving towards the next page
;;
;; Return Value:
;;   1 - If it is okay to move to next
;;
;;   0 - If it is not okay to move to the next page.
;;
function IDLitWDExportWizard_3_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    if(bNext) then begin ;; moving forward
        ;; get sub page state
        widget_control, (*pState).w2Subs[(*pState).iDstType] , get_uvalue=pSubstate
        case (*pState).iDstType of
            ;; Get the filename and writer
            0: if(_idlitIW_GetFileAttributes(pSubState, name, idWriter, scale))then begin
                (*pState).dstName = name
                (*pState).idWriter = idWriter
                (*pState).scale = scale
               endif else $
                return, 0
            ;; Get the variable name
            1: if(_idlitEW_GetVariableName(pSubState, name))then $
                (*pState).dstName = name
        endcase
    endif
    ;; Unmap the old sub-page.
    widget_control, (*pState).wPages[2], map=0
    return,1
end
;;---------------------------------------------------------------------------
;; Page 2 Section.
;;
;; This page is used to select the desired item to export.
;;---------------------------------------------------------------------------
;; _idlitwdEW_ItemSelect_EV
;;
;; Purpose:
;;   Event handler for page 2 of the wizard.
;;
;; Parameters:
;;   sEvent   - The event fired to this page.

pro _idlitwdEW_ItemSelect_EV, sEvent
     compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       return
   endif

   ;; State
   widget_control, sEvent.handler, get_uvalue=State
   ;; wizard state
   wWizard = widget_info(sEvent.handler,/parent)
   widget_control, wWizard, get_uvalue=pState

    ; Get the item selected from the system.
    selection = (*sEvent.value)[0]
    type = ''
    name = ''
    oItem = Obj_New()
    if (selection ne '') then begin
        oItem = State.oTool->GetByIdentifier(selection)
        oItem->IDLitComponent::GetProperty, NAME=name
    endif

    ; If data object selected, retrieve the data type.
    isData = OBJ_ISA(oItem, "IDLitData") && $
        ~OBJ_ISA(oItem, "IDLitParameterSet")
    if (isData) then $
        oItem->GetProperty, TYPE=type


    if ((*pState).iDstType) then begin   ; export to variable

        bValid = isData

    endif else begin   ; export to file

        oWrite  = (*pState).oTool->GetService("WRITE_FILE")
        if (~obj_valid(oWrite)) then $
            return

        if (OBJ_ISA(oItem, 'IDLitVisImage')) then begin
            type = 'IDLIMAGE'
        endif else if (OBJ_ISA(oItem, "IDLitWindow") || $
            OBJ_ISA(oItem, "IDLitgrView")) then begin
            ; Special type just for buffer/clipboard destinations.
            type = 'IDLDEST, IDLIMAGE'
        endif

        types = STRSPLIT(STRCOMPRESS(type, /REMOVE), ',', /EXTRACT)
        idWriters = oWrite->GetWritersByType(types, count=nWriters)
        bValid = (nWriters gt 0)

    endelse

   ; Cannot allow null strings for widget_label on Windows.
    if (name eq '') then $
        name = ' '
    if (type eq '') then $
        type = ' '
   widget_control, State.wName, set_value=name
   widget_control, State.wType, set_value=type

   if(bValid)then begin;; If valid, stash current values
       State.idItem = selection
       state.strType = type
   endif
   widget_control, state.wSupport, map=~bValid
   widget_control, State.wBDisplay, sensitive=bValid
   dialog_wizard_setNext, wWizard, bValid
   widget_control, sEvent.handler, set_uvalue=State, /no_copy
end


;;---------------------------------------------------------------------------
;; IDLitWDExportWizard_2_Destroy
;;
;; Purpose:
;;   This routine is called with the page is being destroyed.
;;   <not current anymore>
;;
;; Parameters:
;;   id  - The wizard id
;;
;;   bNext - Set if the wizard is moving to the next page.

function IDLitWDExportWizard_2_destroy, id, bNext
    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    ;; Save the id and type of the item selected, placing them in the
    ;; overall state structure.
    widget_control, (*pState).wPages[1] , get_uvalue=state
    (*pState).idSrc = (bNext ? state.idItem : '')
    (*pState).strType = (bNext ? state.strType : '')

    widget_control, (*pState).wPages[1], map=0
    return,1
end

;;---------------------------------------------------------------------------
;;  IDLitWDExportWizard_2_Create
;;
;; Purpose:
;;   Sets up UI to allow the of the item to export. This page presents
;;   a tree view of the tools hierachy allowing the user to select the
;;   item to export.
;;
;; ;; Parameters:
;;    id - The parent widget identifier.
;;
pro IDLitWDExportWizard_2_Create, id
   compile_opt hidden, idl2

   ;; If this page is already up, just remap it.
   WIDGET_CONTROL, id, GET_UVALUE=pState
   if(widget_info((*pState).wPages[1],/valid))then begin
       ;; If we have no writers, update the display if in writer mode
       widget_control, (*pState).wPages[1], get_uvalue=state
       if(widget_info(state.wWriters,/valid_id))then begin ;; valid=>no writers
           ;;map/unmap depending on mode (file or variable)
           widget_control, state.wWriters, map = ((*pState).iDstType eq 0)
           widget_control, state.wPage, map = ((*pState).iDstType eq 1)
       endif
       widget_control, (*pState).wPages[1], /map
       ;; Determine if the next button should be enabled. Look at the
       ;; current state of the tree widget and determine what is
       ;; selected in the it
       idSel = cw_ittreeview_getSelect(State.wDM , count=nSel)
       if(nSel gt 0)then begin
           oItem = State.oTool->GetByIdentifier(idSel[0])
           bValid=1
           ;; Get the type of the item
           switch 1 of
               obj_isa(oItem, "IDLitData") && $
                 ~obj_isa(oItem, "IDLitParameterSet"): break

               obj_isa(oItem, "IDLitWindow"):
               obj_isa(oItem, "IDLitgrView"): begin
                   ;; This is only valid if we are exporting to a file
                   if((*pState).iDstType eq 0)then $
                     break
               end ;; else fall through
               else: bValid=0
           endswitch


       endif else bValid=0
       dialog_wizard_setNext, id, bValid ;; always assume in a bad state.
       return
   endif

   ;; If we are exporting to a file, we need to check that we have
   ;; writer support for the data being selected. As such, get a
   ;; list of the data types supported by our current writer set.
   oTool = (*pstate).oTool
   oDesc = oTool->GetFileWriter(count=nWriters,/all)

   ;; If no writers are available, we need to put a page up to reflect
   ;; this and disable "next".

   ;; build the interface. Container, page base
   wWrapper = widget_base(id, xpad=0, ypad=0, space=0, map=1, $
                       event_pro='_idlitwdEW_ItemSelect_EV')

   ;; If we have no writer support, make a banner that can be used.
   if(nWriters eq 0)then begin
       wWriters = widget_base(wWrapper, /column, map=((*pState).iDstType eq 0))
       wLabel = widget_label(wWriters, value= $
                             IDLitLangCatQuery('UI:wdExportWiz:NoWriters'), $
                            /align_left)
       wLabel = widget_label(wWriters, value= $
                             IDLitLangCatQuery('UI:wdExportWiz:NoExport'), $
                            /align_left)
   endif else wWriters=0L ;; invalid id, => Have writer support

   ;; Base for the major controls. This is mapped on-off (toggled)
   ;; with wWriters if there are now writers and the user selectes
   ;; between file and variable export. Yes, this is complicated.
   wPage = WIDGET_BASE(wWrapper, /BASE_ALIGN_LEFT, /COLUMN, SPACE=5, $
                       map =(nWriters gt 0 || (*pState).iDstType eq 1))

   wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)

    ;; What is the type of item being selected?
    filler = (*pState).iDstType eq 0 ? IDLitLangCatQuery('UI:wdExportWiz:WinView') : ''
    wText = Widget_Label(wPrompt, value= $
                         IDLitLangCatQuery('UI:wdExportWiz:SelDesired')+filler+ $
                         IDLitLangCatQuery('UI:wdExportWiz:DataExp'))

    ;; Get the identifier of our target vis tree.
    oWin = oTool->GetCurrentWindow()
    idWin = OBJ_VALID(oWin) ? oWin->GetFullIdentifier() : ''
    wBDM = widget_base(wPage, /ROW)
    sGeom = widget_info(id, /geometry)

    wDM = cw_ittreeview(wBDM, (*pState).oUI, $
                        IDENTIFIER=idWin, $
                        ysize = sGeom.ysize *.8, $
                        xsize = sGeom.xsize*.55)

    ;; We want nothing in the tree selected, so deselect everything.
    cw_itTreeView_SetSelect, wDM, /CLEAR

    ;; Selected item display area.
    wB2 = widget_base(wBDM, /column, space=0)
    wBDisplay = widget_base(wB2, /column, space=6)
    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, value=IDLitLangCatQuery('UI:wdExportWiz:Name'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=' ', $
                         scr_xsize=sGeom.xsize*.3,/align_left)
    ;; Type
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, value=IDLitLangCatQuery('UI:wdExportWiz:Type'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wType = Widget_Label(wTmp, value=' ', $
                         scr_xsize=sGeom.xsize*.3,/align_left)

    wSupport = Widget_Base(wB2,/column, space=5)
    wTmp = Widget_Label(wSupport, value=IDLitLangCatQuery('UI:wdExportWiz:BadType'), $
                        /align_left)
    widget_control, wTmp, set_value='' ;; original value was for sizing

    ;; State for this page.
    state = { wName          : wName,       $
              bNext          : 0,           $
              wType          : wType,       $
              wDM            : wDM,         $
              wBDisplay      : wBDisplay,   $
              idItem         : '',          $
              strType        : '',          $
              wSupport       : wSupport,    $
              wWriters       : wWriters,    $
              wPage          : wPage,       $
              oTool          :oTool}

    widget_control, wBDisplay, sensitive=0 ;; initial value
    widget_control, wWrapper, set_uvalue=state, /no_copy, /map
    (*pState).wPages[1] = wWrapper

    dialog_wizard_setNext, id, 0

    ; If export to file, by default make the Window selected.
    idSel = ((*pState).iDstType eq 0) ? idWin : ''

    ; See if we have an initial selection.
    if ((*pState).idSrc ne '') then begin
        if OBJ_VALID(oTool->GetByIdentifier((*pState).idSrc)) then $
            idSel = (*pState).idSrc
    endif

    ; Do we need to change selection to either the window or an object?
    if (idSel ne '') then begin
        pSelID = PTR_NEW(idSel)
        cw_itTreeView_SetSelect, wDM, idSel
        _idlitwdEW_ItemSelect_EV, {ID: wDM, TOP: id, HANDLER: wWrapper,  $
            VALUE: pSelID}
        PTR_FREE, pSelID
    endif

end


;;-------------------------------------------------------------------------
;; Page 1 Section: Selection of the export destination: file or variable
;;-------------------------------------------------------------------------
;; IDLitWDExportWizard_1_Create
;;
;; Purpose:
;;   This routine is used to create the first page of the export
;;   wizard. This page allow the user to select the destination of the data
;;   for the export.
;;
;; Parameters:
;;    id - The parent widget identifier.
;;
pro IDLitWdExportWizard_1_Create, id
    compile_opt idl2, hidden

    ;; Get our the state for the wizard. If this page already exist,
    ;; just map it and return.
    WIDGET_CONTROL, id, GET_UVALUE=pState
    if(widget_info((*pState).wPages[0],/valid))then begin
        widget_control, (*pState).wPages[0], /map
        dialog_wizard_setNext, id, 1
        return
    endif

    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                       MAP=0, SPACE=5)
    ;; Make our prompt
    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    text = [IDLitLangCatQuery('UI:wdExportWiz:Prompt1'), $
            IDLitLangCatQuery('UI:wdExportWiz:Prompt2')]
    for i=0, n_elements(text)-1 do $
      wText = WIDGET_LABEL(wPrompt, VALUE=text[i])

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPrompt, value=  IDLitLangCatQuery('UI:wdExportWiz:SelDest'))

    ;; Okay, Time to select our destination.
    wBBase = widget_base(wPage, /column, space=5, /exclusive, $
                        /base_align_left, xpad=20)

    wButtons = lonarr(2)

    ; If DEMO mode, disable export to file.
    if (LMGR(/DEMO)) then begin
        wButtons[0] = widget_button(wBBase, $
            VALUE=IDLitLangCatQuery('UI:wdExportWiz:ToFileDemo'), $
            UVALUE='FILE')
        WIDGET_CONTROL, wButtons[0], SENSITIVE=0
        (*pState).iDstType = (*pState).iDstType > 1
    endif else begin
      wButtons[0] = widget_button(wBBase, value= $
                                  IDLitLangCatQuery('UI:wdExportWiz:ToFile'), $
                                  uvalue='FILE')
    endelse

    wButtons[1] = widget_button(wBBase, value= $
                                IDLitLangCatQuery('UI:wdExportWiz:ToVar'), $
                                uvalue='CL')


    widget_control, wButtons[(*pState).iDstType], /set_button

    state = {wButtons:wButtons, wWizard:id}
    widget_control, wPage,  /map, set_uvalue=state

    (*pState).wPages[0] = wPage

    ;; enable the next button
    dialog_wizard_setNext, id, 1
end


;;-------------------------------------------------------------------------
;; IDLItWDExportWizard_1_Destroy
;;
;; Purpose:
;;   Destroys page 1 of the wizard. This will set the source we are
;;   selected from in state and unmap this page.
;;
;; Parameters:
;;   id - The parent for page 1.
;;
;;   bNext - Is the transition moving toward "next".

function IDLitWDExportWizard_1_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    wPage = widget_info(id, /child)
    widget_control, wPage , get_uvalue=state

    dex = where(widget_info(state.wButtons, /button_set))
    (*pState).iDstType = dex[0]
    widget_control, (*pState).wPages[0], map=0
    return,1
end



;;-------------------------------------------------------------------------
;; IDLitwdExportWizard
;;
;; Purpose:
;;   This file contains the logic to build and manage the data export
;;   wizard for the tool system. This wizard allows items in the
;;   visualization tree to be exported to either a file or IDL
;;   variable.
;;
;; Parameters
;;   oUI   - The ui object for the session this is working in.
;;
;;   oTarget - The target object for this action. Information
;;             determined by this wizard is placed in this object.

function IDLitwdExportWizard, oUI, oTarget
    compile_opt idl2,hidden

    xsize=500
    ysize=300

    ; Retrieve previous settings.
    oTarget->GetProperty, DESTINATION=dest, $
        SCALE_FACTOR=scale, $
        ITEM_ID=idSrc, $
        WRITER_ID=idWriter
    if (scale eq 0) then scale = 1.0

    pSubState = ptrarr(2, /allocate)
    ;; Define our state:
    state = {  iDstType    : dest , $ ;; The destination type 0-file, 1-cl
               idSrc       : idSrc, $    ;; ID/Name of the src
               dstName     : '', $    ;; Name of the destination
               strType     : '', $    ;; Type of the source item
               idWriter    : idWriter, $    ;; ID for the writer
               scale       : scale,$    ;; scale factor for images
               wPages      : lonarr(3), $
               w2Subs      : lonarr(2), $ ;; ids of the page 2 sub pages
               pSubState   : pSubState, $ ;; states of sub-pages for pg. 3
               oTool       : oUI->GetTool(), $  ; The tool object
               oUI         : oUI $    ;; The UI object
            }
    pState = ptr_new(state,/no_copy)

    oUI->GetProperty, GROUP_LEADER=groupLeader
    ;; Buid our wizard.
    success = DIALOG_WIZARD('IDLitwdExportWizard_' + ['1', '2', '3'],$
                            GROUP_LEADER=groupLeader, $
                            HELP_PRO='_idlitwdEW_help', $
                            TITLE=IDLitLangCatQuery('UI:wdExportWiz:Title'), $
                            UVALUE=pState, $
                            SPACE=0, XPAD=0, YPAD=0, $
                            XSIZE=xsize, YSIZE=ysize)

    if (success) then begin ;; set the values in the underlying service.
        ; Set either filename or variable name but not both.
        if ((*pState).iDstType eq 0) then $
            outfilename = (*pState).dstName $
        else $
            outvariable = (*pState).dstName
        oTarget->SetProperty, DESTINATION=(*pState).iDstType, $
              ITEM_ID=(*pState).idSrc, $
              FILENAME=outfilename, $
              SCALE_FACTOR=(*pState).scale, $
              VARIABLE=outvariable, $
              WRITER_ID=(*pState).idWriter
    endif

    ptr_free, (*pState).pSubState
    ptr_free, pState
    return, success
end
