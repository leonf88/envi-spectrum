;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdfileimport.pro#1 $
;;
;; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;
;; Purpose:
;;   Presents a dialog that allows the user to select a file and then
;;   import it into the data manager.
;;
;;---------------------------------------------------------------------------
;; File Selection section
;;---------------------------------------------------------------------------
;; IDLitwdFileImport_CheckFileName
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

function IDLitwdFileImport_CheckFileName, pState, id

   compile_opt idl2, hidden

   widget_control, (*pState).wName, get_value=value
   if(strtrim(value[0], 2) eq '')then $
     return, 0 ;; no string, but no error needed.

   if(not file_test(value[0], /read))then begin
     okay = dialog_message(title= $
                           IDLitLangCatQuery('UI:wdFileImport:BadFile'), $
                           /Error, dialog_parent=id,$
                           IDLitLangCatQuery('UI:wdFileImport:NoFile'))
       widget_control, (*pState).wName, $
         set_text_select=[0,strlen(value[0])],/input_focus
       widget_control, (*pState).wData, set_value=''
       widget_control, (*pState).wOK, sensitive=0
       widget_control, (*pState).wProps, set_value=''
       return, 0
   endif
   widget_control, (*pState).wOK, sensitive=1
   return,1
end
;;-------------------------------------------------------------------------
;; IDLitwdFileImport_EVENT
;;
;; Purpose:
;;   Event handler for the file import dialog
;;
;; Parameter:
;;   sEvent  - The widget event.
;;
PRO  IDLitwdFileImport_EVENT, sEvent
   compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return
   end

    widget_control, sEvent.top, get_uvalue=pState

    ; Manually handle our kill to prevent flashing on Windows.
    if (TAG_NAMES(sEvent, /STRUCT) eq 'WIDGET_KILL_REQUEST') then begin
        (*pState).filename = '' ;; no import
        WIDGET_CONTROL, sEvent.top, /DESTROY
        return
    endif

   message = widget_info(sEvent.id, /uname)

   bUpdate=0 ;; Flag for update of the file type text area

   case message of

       ;; The go select a file button was selected.
       'FILE_SEL': begin
           if(obj_valid((*pState).oRead))then begin
             ext = (*pState).oRead->GetFilterList(count=nExt)
             ; On Motif, the filters cannot have spaces between them.
             if (nExt gt 0) then $
                 ext[*,0] = STRCOMPRESS(ext[*,0], /REMOVE_ALL)
           endif else $
             nExt = 0
           if(nExt eq 0)then ext='*'

            oTool = OBJ_ISA((*pState).oTool, 'IDLitSystem') ? $
                (*pState).oTool->GetCurrentTool() : (*pState).oTool
            ; Retrieve working directory.
            if (OBJ_VALID(oTool)) then begin
                oTool->GetProperty, $
                    CHANGE_DIRECTORY=changeDirectory, $
                    WORKING_DIRECTORY=workingDirectory
            endif

           file = dialog_pickfile(dialog_parent=sEvent.top, /READ, $
                GET_PATH=newDirectory, $
                PATH=workingDirectory, $
                FILE=(*pState).filename, $
                FILTER=ext, $
                /MUST_EXIST)

           if(file ne '')then begin
               (*pState).filename=file[0]
               widget_control, (*pState).wName, set_value=file[0]
               bUpdate=1
               widget_control, (*pSTate).wOK, /sensitive
                ; Set the new working directory if change_directory is enabled.
                if (OBJ_VALID(oTool) && KEYWORD_SET(changeDirectory)) then $
                    oTool->SetProperty, $
                        WORKING_DIRECTORY=newDirectory
           endif
       end

       'FILENAME': begin
           ;; A file name was entered at the command line
           if(sEvent.type eq 0)then begin
               if(sEvent.ch eq 10)then $
                 bUpdate = IDLitwdFileImport_CheckFileName( pState, sEvent.top ) $
               else $
                 widget_control, (*pState).wOK, /sensitive
           endif
       end

       'CANCEL': begin
           (*pState).filename = '' ;; no import
           widget_control, sEvent.top, /destroy
       end

       'OK':begin
           widget_control, (*pState).wData, get_value=val
           (*pState).name = val[0]
           widget_control, sEvent.top, /destroy;; just kill the beast
       end

       else:

   endcase

   ;; Should we update the file type box?
   if(bUpdate)then begin
       if(obj_valid((*pState).oRead))then begin
           (*pState).idMatch = (*pState).oRead->FindMatchingReader((*pState).filename)
           if((*pState).idMatch ne '')then begin
               oRead  = (*pState).oTool->GetByIdentifier((*pState).idMatch)
               oRead->GetProperty, description=desc
           endif else begin
                (*pState).idMatch = ''
           endelse
       endif
       ;; Update the name box.
       names= strsplit((*pState).filename, "\/", /extract)
       (*pState).name = names[n_elements(names)-1]
       widget_control,(*pState).wData, set_value=(*pState).name
       ;; options property sheet
       widget_control, (*pState).wProps, set_value=(*pState).idMatch
   endif

end


;;-------------------------------------------------------------------------
;; IDLitwdFileImport
;;
;; Purpose:
;;   This widget routine will present the user with an interface that
;;   allows the selection of a file that is then imported and placed
;;   in the data manger.
;;
;;   This widget is modal
;;
;; Parameters:
;;    oUI   - The uI objec    wBCL = widget_base(wTLB, /ROW, space=8)
;;
;;    GROUP_LEADER - The widgets group leader
;;
;;    XSIZE   - The xsize of this widget
;;
;;    YSIZE   - The ysize of this widget
;;
;;    All other keywords are passed to the widget system

function IDLitwdFileImport, oUI, $
                            GROUP_LEADER=GROUP_LEADER, $
                            TITLE=TITLE, $
                            XSIZE=XSIZE, $
                            YSIZE=YSIZE, $
                            _EXTRA=_extra

   compile_opt idl2, hidden

   ;; check defaults
   if(not keyword_set(TITLE))then $
     title=IDLitLangCatQuery('UI:wdFileImport:Title')

   if(not keyword_set(XSIZE))then $
     XSIZE =450

   if(not keyword_set(YSIZE))then $
     YSIZE =400

   ;; Build our widget. This is modal
   hasGL = Widget_Info(N_Elements(GROUP_LEADER) ? GROUP_LEADER : 0L, /VALID)
   wTLB = Widget_Base(/COLUMN, $
        FLOATING=hasGL, $
        MODAL=hasGL, $
        GROUP_LEADER=GROUP_LEADER, $
        /TLB_KILL_REQUEST_EVENTS, $
        /base_align_left, $
        space=10, xpad=8, ypad=8, $
        title=title, $
        _extra=_extra)

    wText = Widget_Label(wTLB, value= $
                         IDLitLangCatQuery('UI:wdFileImport:SelectFile'))

    wBase = widget_base(wTLB, /COLUMN, xpad=0, ypad=0)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdFileImport:FileName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Text(wTmp, value='', /EDITABLE, /all_events, $
                        uname="FILENAME",$
                        scr_xsize=xsize*.8, /align_left)

    fileName = FILEPATH('open.bmp', SUBDIR=['resource','bitmaps'])
    bThere = file_test(fileName, /read)
    if(bThere)then $
      wButton = widget_button(wTmp, value=filename, /bitmap, /FLAT, uname='FILE_SEL') $
    else $
      wButton = widget_button(wTmp, value="...", uname='FILE_SEL')


    wBase = widget_base(wTLB, /COLUMN, xpad=0, ypad=0)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdFileImport:ImportOpt'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wProps = CW_ITPROPERTYSHEET(wTmp, oUI, $
        SCR_XSIZE=xsize*.8, YSIZE=4, $
        /SUNKEN_FRAME)


    wBase = widget_base(wTLB, /COLUMN, xpad=0, ypad=0)
    wTmp = Widget_Label(wBase, value= $
                        IDLitLangCatQuery('UI:wdFileImport:ImportName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wData = Widget_Text(wTmp, value='', /EDITABLE, /all_events, $
                        uname="DATAIMPORT",$
                        scr_xsize=xsize*.8, /align_left)

    ;; Now the bottom, button
    wButtons = Widget_Base(wTLB, /align_right, /row, space=5)
    wOK = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:OK'), $
                        uname='OK', sensitive=0)
    wCancel = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:Cancel'), $
                            uname='CANCEL')
    geomCan=widget_info(wCancel, /geometry)
    widget_control, wOK, scr_xsize=geomCan.scr_xsize, $
      scr_ysize=geomCan.scr_ysize

    ;; Get our reader services.
    oTool =oUI->getTool()
    oRead  = oTool->GetService("READ_FILE")
    state = { wName          : wName,       $
              bNext          : 0,           $
              wProps         : wProps,      $
              oUI            : oUI,         $
              oTool          : oTool,       $
              wOK            : wOK,         $
              wData          : wData,       $
              oRead          : oRead,       $
              name           : '',          $
              filename       : '', $
              idMatch: ''}

    ;; Place state in a pointer and note that we set the cancel  button.
    pState = ptr_new(state, /no_copy)
    widget_control, wTLB, set_uvalue=pState, /realize, cancel_button=wCancel


    xmanager, 'IDLitwdFileImport', wTLB, NO_BLOCK=1

    ;; We are back
    ;; Import the file if one was selected
    if((*pstate).filename ne '')then begin
        iStatus = oRead->ReadFileandImport((*pState).filename, $
                                           name=(*pState).name)
        if(iStatus eq 0)then begin
            oTool->GetLastErrorInfo,  description=desc
            status = dialog_message(desc, /error, dialog_parent=group_leader)
        endif
    endif

    ptr_free, pState
    return,1

end

