; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdimportwizard.pro#1 $
;---------------------------------------------------------------------------
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdImportWizard
;
; PURPOSE:
;   This function implements the import wizard, allowing the creation
;   of a visualization from either a file or the IDL command line.
;
; CALLING SEQUENCE:
;   Result = IDLitwdImportWizard()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, September 2002.
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro _idlitwdIW_help, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    oTool = (*pState).oTool
    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return
    oHelp->HelpTopic, oTool, 'iToolsImportWizard'

end


;;---------------------------------------------------------------------------
;; _idlitWdIW_Page3_EV
;;
;; Purpose:
;;   This routine is the event handler for page 3, select vis, page of
;;   the wizard.
;;
;;
pro _idlitwdIW_Page3_EV, sEvent

   compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       if(n_elements(state) gt 0)then $
         widget_control, sEvent.handler, set_uvalue=state,/no_copy
       return
   endif

   ;; Events are only from the list, so just update our display

   widget_control, sEvent.handler, get_uvalue=state, /no_copy

   widget_control, state.wName, set_value=state.strNames[sEvent.index]
   widget_control, state.wDesc, set_value=state.strDesc[sEvent.index]
   state.idItem = state.idVis[sEvent.index]
   state.strName= state.strNames[sEvent.index]

   dialog_wizard_setNext, state.wWizard, 1
   widget_control, sEvent.handler, set_uvalue=state,/no_copy
end

;;-------------------------------------------------------------------------
;; IDLitWdImportWizard_3_create
;;
;; Purpose:
;;   Create page 3 of the wizard. This page allows the user to select
;;   the desired visualization.
;;
;; parameters:
;;   id  - The id of our parge.

pro IDLitWdImportWizard_3_Create, id
    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    ;; Has this page already been created?
    if(widget_info((*pState).wPages[2],/valid))then begin
        widget_control, (*pState).wPages[2], /map
        return
    endif

    ;; Get a list of available visualizations
    oTool = (*pState).oTool
    oVis = oTool->GetVisualization(count=nVis, /all)

    ;; Build up a list of the visualizations. Include the default entry.
    nVis++;
    strNames = "<"+IDLitLangCatQuery('UI:wdImportWiz:Default')+">"

    strDesc  = IDLitLangCatQuery('UI:wdImportWiz:DefVis')
    idVis=''

    for i=1, nVis-1 do begin
        ;; Only include visualizations that have INPUT and OPTARGET set.
        ; Use internal _InstantiateObject so we skip the PropertyBag.
        oObj = oVis[i-1]->_InstantiateObject()
        ;; Check if vis has any parms at all
        if ~OBJ_ISA(oObj, 'IDLitParameter') then begin
            OBJ_DESTROY, oObj
            continue
        endif
        ;; Get all parm descriptors
        parameters = oObj->QueryParameter(COUNT=nparam)
        if (nparam eq 0) then begin
            OBJ_DESTROY, oObj
            continue
        endif

        ;; Look for INPUT and OPTARGET
        for d=0, nparam-1 do begin
            oObj->GetParameterAttribute, parameters[d], $
                INPUT=input, OPTARGET=optarget
            if (input && optarget) then break
        endfor
        OBJ_DESTROY, oObj

        ;; Didn't find it
        if d eq nparam then continue
        ;; Got one - add to the lists.
        oVis[i-1]->GetProperty, name=name, description=desc
        strNames = [strNames,name]
        strDesc = [strDesc,desc]
        idVis = [idVis,oVis[i-1]->GetFullIdentifier()]
    endfor


    ;; Create our display
    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                       MAP=0, SPACE=5, $
                       event_pro='_idlitwdIW_Page3_EV')
    sGeom = widget_info(id, /geometry)

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPrompt, value= $
                         IDLitLangCatQuery('UI:wdImportWiz:SelVis'))

    wBCL = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wBCL, /COLUMN)

    wList = Widget_List(wBase, value=strNames,$
                        xsize=30, ysize=14)
    ;; Selected item display area.
    wBDisplay = widget_base(wBCL, /column, space=6)
    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Name'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=strNames[0], $
                         scr_xsize=sGeom.xsize*.4,/align_left)
    ;; Description
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Desc'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wDesc = Widget_TEXT(wTmp, value=strDesc[0], /wrap, ysize=8, $
                         scr_xsize=sGeom.xsize*.4)

    ;; State
    state = { wName          : wName,       $
              wDesc          : wDesc,       $
              wWizard        : id,          $
              strNames       : strNames,    $
              strDesc        : strDesc,     $
              idVis          : idVis,       $
              strName        : '',          $
              idItem         : ''}

    ;; Set the default as selected
    widget_control, wList, set_list_select=0
    state.strName= state.strNames[0]
    widget_control, wPage, set_uvalue=state, /map

    (*pState).wPages[2] = wPage
    dialog_wizard_setNext, id, 1

end
;;-------------------------------------------------------------------------
;; IDLitWdImporrtWizard_3_destroy,
;;
;; Purpose:
;;   Wizard destroy callback function for page 3. This will capture
;;   any information from page three and unmap the page.

function IDLitWDImportWizard_3_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    widget_control, (*pState).wPages[2], get_uvalue=state
    (*pState).idDest = state.idItem
    (*pState).dstName = state.strName
    widget_control, (*pState).wPages[2], map=0

    return,1
end
;;---------------------------------------------------------------------------
;;Begin source selection section.
;;---------------------------------------------------------------------------
;; File Selection section
;;---------------------------------------------------------------------------
;; _idlitIW_CheckFileName
;;
;; Purpose:
;;   Check to determine if a valid filename is present in the name
;;   text box of the file selection page.
;;
;; Parameter
;;  The state struct (in a pointer) of the page.
;;
;; Return Value:
;;    1 - yes
;;    0 - No

function _idlitIW_CheckFileName, pState, id
   compile_opt hidden, idl2

   widget_control, (*pState).wName, get_value=value
   if(strtrim(value[0], 2) eq '')then $
     return, 0 ;; no string, but no error needed.

   bError=0
   ;; Check if the file exists
   if(not file_test(value[0], /read))then begin
       okay = dialog_message(title=IDLitLangCatQuery('UI:wdImportWiz:BadFile'), $
                             /Error, dialog_parent=id,$
                             IDLitLangCatQuery('UI:wdImportWiz:NoFile'))
       bError=1
   endif else begin
       ;; Filter out ISV files.
       isISV =strpos(strupcase(value[0]), ".ISV",/reverse_search)
       if(isISV ne -1 && isISV eq strlen(value[0])-4)then begin
         void = dialog_message([IDLitLangCatQuery('UI:wdImportWiz:NoISV'), $
                                IDLitLangCatQuery('UI:wdImportWiz:NoISVFormat')],$
                               title=IDLitLangCatQuery('UI:wdImportWiz:BadFileTitle'), $
                               /information, $
                               dialog_parent=id)
         bError =1
       endif
   endelse

   if(bError eq 1)then begin
       widget_control, (*pState).wName, $
         set_text_select=[0,strlen(value[0])],/input_focus
       dialog_wizard_setNext, (*pState).wWizard, 0
       return, 0
   endif
   return,1
end
;;---------------------------------------------------------------------------
;; _idlitwdIW_FileSel_Cleanup
;;
;; Purpose:
;;   Cleanup routine (kill_notify) for the command line page
;;
pro _idlitwdIW_FileSel_Cleanup, id
   compile_opt hidden, idl2

   widget_control, id, get_uvalue=pState

   if(ptr_valid(pState))then begin
       ptr_free, pState
   endif
end
;;---------------------------------------------------------------------------
;; _idlitwdIW_FileSel_EV
;;
;; Purpose:
;;   This is the IDL event handler for this file selection page of the
;;   wizard.
;;
pro _idlitwdIW_FileSel_EV, sEvent

   compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       return
   endif
   widget_control, sEvent.handler, get_uvalue=pSTate
   bUpdate=0 ;; Flag for update of the file type text area

   case widget_info(sEvent.id, /uname) of
       ;; Check to see if the select file button was pushed
       'FILE_SEL': begin
           oRead  = (*pState).oTool->GetService("READ_FILE")
           if(obj_valid(oRead))then begin
             ext = oRead->GetFilterList(count=nExt)
             ; On Motif, the filters cannot have spaces between them.
             if (nExt gt 0) then $
                 ext[*,0] = STRCOMPRESS(ext[*,0], /REMOVE_ALL)
           endif else $
             nExt = 0
           if(nExt eq 0)then ext='*'

            ; Retrieve working directory.
            (*pState).oTool->GetProperty, $
                CHANGE_DIRECTORY=changeDirectory, $
                WORKING_DIRECTORY=workingDirectory

           file = dialog_pickfile(dialog_parent=sEvent.top, /READ, $
                GET_PATH=newDirectory, $
                PATH=workingDirectory, $
                FILE=(*pState).idItem, $
                FILTER=ext, $
                /MUST_EXIST)

           if(file ne '')then begin
               ;; check for an isv file
               isISV =strpos(strupcase(file[0]), ".ISV",/reverse_search)
               if(isISV ne -1 && isISV eq strlen(file)-4)then begin
                 void = dialog_message([IDLitLangCatQuery('UI:wdImportWiz:NoISV'), $
                                        IDLitLangCatQuery('UI:wdImportWiz:NoISVFormat')],$
                                       title=IDLitLangCatQuery('UI:wdImportWiz:BadFileTitle'), $
                                       /information, $
                                       dialog_parent=sEvent.top)
               endif else begin
                   (*pState).idItem=file[0]
                   widget_control, (*pState).wName, set_value=file[0]
                   bUpdate=1
                   dialog_wizard_setNext, (*pState).wWizard, 1
                   (*pState).bNext = 1
                    ; Set the new working directory if change_directory is enabled.
                    if (KEYWORD_SET(changeDirectory)) then $
                        (*pState).oTool->SetProperty, $
                            WORKING_DIRECTORY=newDirectory
               endelse
           endif
       end
       'FILENAME':begin
           ;; A file name was entered at the command line
           if(sEvent.type eq 0)then begin
               if(sEvent.ch eq 10)then $
                 bUpdate = _idlitIW_CheckFileName( pState, sEvent.top ) $
               else $
                 dialog_wizard_setNext, (*pState).wWizard, 1       ;; enable next button
           endif
       end
       else:
   endcase

   ;; Should we update the file type box?
   if(bUpdate)then begin
       if(not obj_valid(oRead))then $
         oRead  = (*pState).oTool->GetService("READ_FILE")
       ;; Find a matching file reader.
       if(obj_valid(oRead))then begin
           idMatch = oRead->FindMatchingReader((*pState).idItem)
           (*pState).idReader = idMatch
       endif

       widget_control, (*pState).wProps, SET_VALUE =(*pState).idReader, /MAP, /REFRESH

       ;; Update the name box.
       names= strsplit((*pState).idItem, "\/", /extract)
       widget_control,(*pState).wData, set_value=names[n_elements(names)-1]
   endif
end
;;---------------------------------------------------------------------------
;;  _idlitWdIW_FileSel
;;
;; Purpose:
;;  Creates the page for the file selection in the wizard. This page
;;  allows the user to enter a filename, select a file and set options
;;  on the associated file reader.
;;
;  Parameters:
;;    id        - id of our parent
;;
;;    pState    - State of the wizard.
;;
function _idlitWdIW_FileSel, id, pState
    compile_opt hidden, idl2

    ;; Create our display
    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                       MAP=0, SPACE=5, $
                        kill_notify="_idlitwdIW_FileSel_Cleanup", $
                       event_pro='_idlitwdIW_FileSel_EV')
    sGeom = widget_info(id, /geometry)

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=0, YPAD=0, /base_align_left)
    wText = Widget_Label(wPrompt, value= $
                         IDLitLangCatQuery('UI:wdImportWiz:SelectData'))

    wBCL = widget_base(wPage, /ROW, space=8, xpad=0)
    wBase = widget_base(wBCL, /COLUMN, xpad=0)

    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:FileName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Text(wTmp, value='', /EDITABLE, /all_events, $
                        uname="FILENAME",$
                        scr_xsize=sGeom.xsize*.85, /align_left)

    ;; The open file/select file button
    fileName = FILEPATH('open.bmp', SUBDIR=['resource','bitmaps'])
    bThere = file_test(fileName, /read)
    if(bThere)then $
      wButton = widget_button(wTmp, value=filename, /bitmap, /FLAT, uname='FILE_SEL') $
    else $
      wButton = widget_button(wTmp, value="...", uvalue='FILE_SEL')


    ;; Options button
    wTmp = Widget_Label(wPage, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Options'), $
                        /align_left)
    wBCL = widget_base(wPage, /ROW, space=8, xpad=5)
    wProps = CW_ITPROPERTYSHEET(wBCL, (*pState).oUI, $
        SCR_XSIZE=sGeom.xsize*.8, YSIZE=4, $
        /SUNKEN_FRAME)
    WIDGET_CONTROL, wProps, MAP=0


    ;; Import name.
    wBCL = widget_base(wPage, /ROW, space=8, xpad=0)
    wBase = widget_base(wBCL, /COLUMN)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:DataName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wData = Widget_Text(wTmp, value='', /EDITABLE, /all_events, $
                        uname="DATAIMPORT",$
                        scr_xsize=sGeom.xsize*.8, /align_left)

    state = { wName          : wName,       $
              wWizard        : id,          $
              bNext          : 0,           $
              wProps         : wProps,      $
              wData          : wData,       $
              oTool          : (*pState).oTool, $
              oUI            : (*pState).oUI, $
              idReader       : '',          $ ;; id of current reader
              idItem         : ''}
   *(*pState).pSubState[0] = state
    widget_control, wPage, set_uvalue=(*pState).pSubState[0]
    dialog_wizard_setNext, id, 0
   return, wPage
end

;;---------------------------------------------------------------------------
;; command line section
;;---------------------------------------------------------------------------
;; _idlitwdIW_CommandLine_Cleanup
;;
;; Purpose:
;;   Cleanup routine for the command line page
;;
pro _idlitwdIW_CommandLine_Cleanup, id
   compile_opt hidden, idl2

   widget_control, id, get_uvalue=pState

   if(ptr_valid(pState))then begin
       if(obj_valid((*pState).oCLRoot))then $
         obj_destroy, (*pState).oCLRoot
       ptr_free, pState
   endif
end
;;---------------------------------------------------------------------------
;; _idlitwdIW_CommandLine_EV
;;
;; Purpose:
;;  Event handler for the command line selection page of this import
;;  wizard.
;;
pro _idlitwdIW_CommandLine_EV, sEvent

   compile_opt idl2, hidden

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch,/cancel
       return
   endif
   widget_control, sEvent.handler, get_uvalue=pState

   message = widget_info(sEvent.id, /uname)
   case message of
       'CLTREE': begin
           if((*pState).nVars gt 0)then begin
               ; Determine what variable was selected and update the
               ; info display.
               oItem = (*pState).oCLRoot->GetByIdentifier(sEvent.identifier) ;
               oItem->getProperty, desc=desc, shape=shape, $
                 type_name=type_name, TYPE_CODE=tcode, data_types=dTypes
               ;; no containers or objects
               sensitive = ~(obj_isa(oItem, "IDLitContainer") or (tcode eq 11))
               widget_control, (*pState).wName, set_value=desc
               widget_control, (*pState).wType, set_value=type_name
               widget_control, (*pState).wValue, set_value=shape
               widget_control, (*pState).wData, $
                 set_value=(~sensitive ? '':desc)
               widget_control, (*pState).wDataType, set_value=dTypes
               (*pState).idItem = (sensitive ? sEvent.identifier : '')
               dialog_wizard_setNext, (*pState).wWizard, sensitive
               (*pState).bNext = 1
          endif
       end
       else: begin
       end
   endcase
end
;;---------------------------------------------------------------------------
;;  _idlitWdIW_CommandLine
;;
;; Purpose:
;;   Sets up UI to allow the selection from the IDL command lne.
;;
function _idlitWdIW_CommandLine, id, pState

    compile_opt hidden, idl2

    ;; Get the needed variable information from the command line
    ;; service in the tool
    oTool = (*pState).oTool
    oCL = oTool->GetService("COMMAND_LINE")
    if(obj_valid(oCL))then begin
        oCLroot = oCL->GetCLVariableDescriptors()
        nVars=1
    endif else begin
        nVars = 0
        oCLRoot =obj_new()
    endelse

    ;; Create our display
    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                        MAP=0, SPACE=5, $
                        kill_notify="_idlitwdIW_CommandLine_Cleanup", $
                        event_pro='_idlitwdIW_CommandLine_EV')
    sGeom = widget_info(id, /geometry)

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPrompt, value= $
                         IDLitLangCatQuery('UI:wdImportWiz:SelectDataCL'))

    wBCL = widget_base(wPage, /ROW, space=8)
    wBase = widget_base(wBCL, /COLUMN)

    ;; Create a tree to display the command line
    wCLTree = cw_itComponentTree(wBase, (*pState).oUI, oCLroot, $
                                 ysize=sGeom.scr_ysize*.7, $
                                 xsize=sGeom.scr_xsize*.5, $
                                 uname="CLTREE")

    ;; Selected item display area.
    wBDisplay = widget_base(wBCL, /column, space=6)
    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Name'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=' ', $
                         scr_xsize=sGeom.xsize*.3,/align_left)
    ;; Type
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Type'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wType = Widget_Label(wTmp, value=' ', $
                         scr_xsize=sGeom.xsize*.3,/align_left)

    ;; Value
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:Value'), /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wValue = Widget_Label(wTmp, value=' ', $
                         scr_xsize=sGeom.xsize*.3,/align_left)

    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:DataName'), /align_left)
    wBImport = Widget_base(wBase,/row, xpad=10, space=5)
    wData = Widget_Text(wBImport, xsize=20, /editable, uname="DATANAME")

    ;; Import Type
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_label(wBase, $
                        value=IDLitLangCatQuery('UI:wdImportWiz:ImportType'), $
                        /align_left)
    wBImport = Widget_Base(wBase,/row,xpad=10,space=5)
    wDataType = Widget_DropList(wBImport, /dynamic, uname="DATATYPE", /FLAT)

    if(nVars gt 0)then begin
        state = { wName          : wName,       $
                  oCLRoot        : oCLRoot,     $ ;; command line tree
                  wWizard        : id,          $
                  bNext          : 0,           $
                  wType          : wType,       $
                  wValue         : wValue,      $
                  nVars          : nVars,       $
                  wData          : wData,       $ ;; for the name
                  wDataType      : wDataType,   $
                  idItem         : ''}
    endif else begin
        state = { nVars : nVars, bNext:0}
        widget_control, wBCL, sensitive=0 ;; initial value
    endelse
    ;; Stash or sub-state
   *(*pState).pSubState[1] = state
    widget_control, wPage, set_uvalue=(*pState).pSubState[1]
    dialog_wizard_setNext, id, 0
   return, wPage
end

;;-------------------------------------------------------------------------
;; IDLitWDImportWizard_2_Create
;;
;; Purpose:
;;   Constructs the 2nd page of the import wizard. This page actually
;;   contains 2 sub-pages that key off the item selected on the first
;;   page of the wizard. As such, this routine will decide which page
;;   is active and route the create execute to it's associated
;;   routine.
;;
pro IDLitWdImportWizard_2_Create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    ;; Determine where we are getting the data from
    iPage =(*pState).iSrcType ;; easier to read.

    ;; Is the page already up (ie realized)?
    if(widget_info((*pState).w2Subs[iPage],/valid))then $
      wPage = (*pState).w2Subs[iPage]       $
    else begin
        case iPage of
            1: wPage = _idlitWdIW_CommandLine(id, pState)
            0: wPage = _idlitWdIW_FileSel(id, pState)
        endcase
        (*pState).w2Subs[iPage] = wPage
    endelse
    ;; Update the next button to the current state.
    dialog_wizard_setNext, id, (*(*pState).pSubState[iPage]).bNext
    widget_control, wPage,  /map    ;; show the page
    (*pState).wPages[1] = wPage ;; Set the main page list to current sub-page
end
;;-------------------------------------------------------------------------
;; IDLitWDImportWizard_2_destroy
;;
;; Purpose:
;;  Called to destroy the page.
;;
;;  Since page 2 is actually a set of three pages, determine which
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
function IDLitWDImportWizard_2_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    if(bNext) then begin ;; moving forward
        ;; get sub page state
        widget_control, (*pState).w2Subs[(*pState).iSrcType] , get_uvalue=pSubstate
        case (*pState).iSrcType of
            1: begin ;; command line
                (*pState).idSrc = ((*pSubState).nVars gt 0 ? (*pSubState).idItem :'')
                widget_control, (*pSubstate).wData, get_value=name
                (*pState).srcName = name

                if (keyword_set((*pState).idSrc)) then begin
                    iType = widget_info((*pSubstate).wDataType, /droplist_select)
                    oItem = (*pSubstate).oCLRoot->GetByIdentifier((*pState).idSrc)
                    oItem->getProperty, data_types=dTypes
                    (*pState).dstDataType = dTypes[iType]
                endif else $
                    (*pState).dstDataType = ''
            end

            0: begin ;; file selection.
                ;; Validate the file on the page. If it is "invalid",
                ;; return 0
                if(_idlitIW_CheckFileName(pSubState, id) eq 0)then $
                  return, 0
                if(keyword_set((*pSubState).idItem))then $
                  (*pState).idSrc = (*pSubState).idItem  $
                else begin
                    widget_control, (*pSubState).wName,  get_value=name
                  (*pState).idSrc = name
                endelse
                widget_control, (*pSubstate).wData, get_value=name
                (*pState).srcName = name
            end
        endcase
    endif
    ;; Unmap the old sub-page.
    widget_control, (*pState).wPages[1], map=0
    return,1
end

;;-------------------------------------------------------------------------
;; IDLitWDImportWizard_1_Create
;;
;; Purpose:
;;   This routine is used to create the first page of the import
;;   wizard. This page allow the user to select the source of the data
;;   they are importing to.
;;
pro IDLitWdImportWizard_1_Create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    if(widget_info((*pState).wPages[0],/valid))then begin
        widget_control, (*pState).wPages[0], /map
        ; If we came back to first screen, reenable the Next button.
        dialog_wizard_setNext, id, 1
        return
    endif

    wPage = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
                       MAP=0, SPACE=5)
    ;; Make our prompt
    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    text = [IDLitLangCatQuery('UI:wdImportWiz:Prompt1'), $
            IDLitLangCatQuery('UI:wdImportWiz:Prompt2')]
    for i=0, n_elements(text)-1 do $
      wText = WIDGET_LABEL(wPrompt, VALUE=text[i])

    wPrompt = WIDGET_BASE(wPage, /column, XPAD=5, YPAD=5, /base_align_left)
    wText = Widget_Label(wPrompt, value=IDLitLangCatQuery('UI:wdImportWiz:SelectLoc'))

    ;; Okay, Time to select our destination.
    wBBase = widget_base(wPage, /column, space=5, /exclusive, $
                        /base_align_left, xpad=20)

    ;; our selection buttons
    wButtons = lonarr(2)
    wButtons[0] = widget_button(wBBase, $
                                value=IDLitLangCatQuery('UI:wdImportWiz:FromFile'), $
                        uvalue='FILE')
    wButtons[1] = widget_button(wBBase, $
                                value=IDLitLangCatQuery('UI:wdImportWiz:FromVar'), $
                        uvalue='CL')


    widget_control, wButtons[(*pState).iSrcType], /set_button
    state = {wButtons:wButtons, wWizard:id}
    widget_control, wPage,  /map, set_uvalue=state

    (*pState).wPages[0] = wPage

    dialog_wizard_setNext, id, 1
end


;;-------------------------------------------------------------------------
;; IDLItWDImportWizard_1_Destroy
;;
;; Purpose:
;;   Destroys page 1 of the wizard. This will set the source we are
;;   selected from in state and unmap this page.
;;
function IDLitWDImportWizard_1_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    wPage = widget_info(id, /child)
    widget_control, wPage , get_uvalue=state

    dex = where(widget_info(state.wButtons, /button_set))
    (*pState).iSrcType = dex[0]
    widget_control, (*pState).wPages[0], map=0
    return,1
end



;;-------------------------------------------------------------------------
;; IDLitwdImportWizard
;;
;; Purpose:
;;   Method to allow the user to select an item to import from and the
;;   how they would want the value to be displayed.
;;
;; Parameters:
;;    oUI      - The UI object
;;
;;    oTarget  - The import operation associated with this
;;
;; Keywords:
;;  GROUP_LEADER  - Leader for this wizard
function IDLitwdImportWizard, oUI, oTarget, GROUP_LEADER=GROUP_LEADER

    compile_opt idl2, hidden

    xsize=500
    ysize=300

    pSubState = ptrarr(3, /allocate)
    ;; Define our state:
    state = {  iSrcType    : 0 , $    ;; The source type 0-dm, 1-cl, 2-file
               iPage2Sub   : 0 , $    ;; page 2 actually has three pages!
               idSrc       : '', $    ;; ID/Name of the src
               srcName     : '', $    ;; Nice name
               idDest      : '', $    ;; ID for the destination type.
               dstName     : '', $    ;; Nice name for destination
               dstDataType : '', $    ;; Data type for imported data
               wPages      : lonarr(4), $
               w2Subs      : lonarr(2), $ ;; ids of the page 2 sub pages
               pSubState   : pSubState, $ ;; states of sub-pages for pg. 2
               oTool       : oUI->GetTool(), $ ; The tool object
               oUI         : oUI $    ;; The UI object
            }
    pState = ptr_new(state,/no_copy)

    ;; Call the wizard routine.
    iStatus = DIALOG_WIZARD('IDLitwdImportWizard_' + ['1', '2', '3'],$
                            GROUP_LEADER=group_Leader, $
                            HELP_PRO='_idlitwdIW_help', $
                            TITLE=IDLitLangCatQuery('UI:wdImportWiz:Title'), $
                            UVALUE=pState, $
                            SPACE=0, XPAD=0, YPAD=0, $
                            XSIZE=xsize, YSIZE=ysize)

    ;; If we have successfully returned, stash our information in the
    ;; target.
    if(iStatus ne 0)then $
      oTarget->SetImportParameters, (*pState).iSrcType, $
            (*pState).idSrc, (*pState).idDest, name=(*pState).srcName, $
            data_type=(*pState).dstDataType



    if (ptr_valid(pState)) then $
        ptr_free, (*pState).pSubState

    ptr_free, pState

    return,iStatus
end
