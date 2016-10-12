;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdcommandlineimport.pro#1 $
;;
;; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;
;; Purpose:
;;   This file implements the logic that allows a user to select an
;;   item from the command line and import that value into IDL. It
;;   uses a tree view metaphore to allow the user to drill down in
;;   variables.

;;-------------------------------------------------------------------------
;; IDLitwdCommandLineImport_EVENT
;;
;; Purpose:
;;   Event handler for the command line browser.
;;
;; Parameter:
;;   sEvent  - The widget event.
;;
PRO  IDLitwdCommandLineImport_EVENT, sEvent
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
      catch, /cancel
      return
  end
  widget_control, sEvent.top, get_uvalue=pState
  message = widget_info(sEvent.id, /uname)

  case message of
      ;; Tree Event? If so, update display values
      'TREE': begin
          oItem = (*pState).oRoot->GetByIdentifier(sEvent.identifier)
          oItem->getProperty, desc=desc, shape=shape, $
            type_name=type_name, TYPE_CODE=tcode, data_types=dTypes

          ;; Make empty things look pretty
          if (desc[0] eq '') then desc = ' '
          if (type_name[0] eq '') then type_name = ' '
          if (shape[0] eq '') then shape = ' '
          if (dTypes[0] eq '') then dTypes = '                '

          ;; no containers or objects
          sensitive = ~(obj_isa(oItem, "IDLitContainer") or (tcode eq 11))
          widget_control, (*pState).wOK, $
            sensitive=sensitive

          ;; Allow double click to import variable
          if (sensitive && $
              (Tag_Names(sEvent, /STRUCTURE_NAME) eq 'CW_ITCOMPONENT_TREE') && $
                (sEvent.clicks eq 2)) then begin
            fakeEvent = {TOP:sEvent.top, ID:(*pState).wOK}
            IDLitwdCommandLineImport_EVENT, fakeEvent
            flag = 1
          endif

          Widget_Control, (*pState).wName, SET_VALUE=desc
          Widget_Control, (*pState).wType, SET_VALUE=type_name
          Widget_Control, (*pState).wValue, SET_VALUE=shape
          Widget_Control, (*pState).wData, $
            SET_VALUE=(~sensitive ? '' : desc)
          Widget_Control, (*pState).wDataType, SET_VALUE=dTypes

          ;; Clear status message
          if (N_Elements(flag) eq 0) then $
            Widget_Control, (*pState).wStatus, SET_VALUE=' '
      end
      'OK':begin ;; Import Button selected

          ;; What was selected?
          widget_control, (*pState).wTree, get_value=idSel
          if(idSel eq '')then return
          widget_control, (*pState).wData, get_value=dName
          iType = widget_info((*pState).wDataType, /droplist_select)
          oItem = (*pState).oRoot->GetByIdentifier(idSel)
          oTool = (*pState).oUI->GetTool()
          oCL = oTool->GetService("COMMAND_LINE")
          if(obj_valid(oCL))then begin
            oItem->getproperty, data_type=dType
            dType = dType[iType]
            iStatus = oCL->ImportToDMByDescriptor((*pState).oRoot,  $
                                                  oItem, name=dName, $
                                                  DATA_TYPE=dType)
            ;; Update status message
            Widget_Control, (*pState).wStatus, SET_VALUE= $
                            IDLitLangCatQuery('UI:wdCLImport:Imported')+dName[0]

            if(iStatus eq 0)then begin
              void = dialog_message(IDLitLangCatQuery('UI:wdCLImport:Error'), $
                       title=IDLitLangCatQuery('UI:wdCLImport:ErrorTitle'), $
                       /ERROR, dialog_parent=sEvent.top)
            endif
          endif
      end
      'CANCEL':widget_control, sEvent.top, /destroy;; just kill the beast
    else:
  endcase
end

;;-------------------------------------------------------------------------
;; IDLitwdCommandLineImport
;;
;; Purpose:
;;   This widget routine will present the user with the  contents of
;;   the commandline and allow them to import the values to the data
;;   manager. The command line is displayed as a tree view, allowing
;;   the user to drill down structs and pointers.
;;
;;   This widget is modal
;;
;; Parameters:
;;    oUI   - The uI object
;;
;;    GROUP_LEADER - The widgets group leader
;;
;;    XSIZE   - The xsize of this widget
;;
;;    YSIZE   - The ysize of this widget
;;
;;    All other keywords are passed to the widget system

function IDLitwdCommandLineImport, oUI, $
                                   GROUP_LEADER=GROUP_LEADER, $
                                   TITLE=TITLE, $
                                   XSIZE=XSIZE, $
                                   YSIZE=YSIZE, $
                                   _EXTRA=_extra

   compile_opt idl2, hidden

   ;; check defaults
   if(not keyword_set(TITLE))then $
     title=IDLitLangCatQuery('UI:wdCLImport:Title')

   if(not keyword_set(XSIZE))then $
     XSIZE =450

   if(not keyword_set(YSIZE))then $
     YSIZE =400

   ;; Get the needed variable information from the command line
   ;; service in the tool. This will return a component hierarchy of
   ;; the cl contents.
   oTool = Obj_Valid(oUI) ? oUI->GetTool() : Obj_New()
   oCL = Obj_Valid(oTool) ? oTool->GetService("COMMAND_LINE") : Obj_New()
   oRoot = obj_valid(oCL) ? oCL->GetCLVariableDescriptors() : Obj_New()

   ;; Build our widget. This is modal
   hasGL = Widget_Info(N_Elements(GROUP_LEADER) ? GROUP_LEADER : 0L, /VALID)
   wTLB = Widget_Base(/COLUMN, $
        FLOATING=hasGL, $
        GROUP_LEADER=GROUP_LEADER, $
        MODAL=hasGL, $
        TITLE=title, $
        _EXTRA=_extra)

   ;; Now for the tree display of the command line.
   wBCL = widget_base(wTLB, /ROW, space=8)
   wTree = cw_itComponentTree(wBCL, oUI, oRoot, $
                              /NO_CONTEXT, $
                              ysize = ysize *.7, $
                              xsize = xsize*.6, $
                              uname="TREE")

    ;; Selected item display area.
    wBDisplay = widget_base(wBCL, /column, space=6)
    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:VarName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)
    ;; Type
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, value=IDLitLangCatQuery('UI:wdCLImport:Type'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wType = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)

    ;; Value
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:Value'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wValue = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)

    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:DataName'), $
                        /align_left)
    wBImport = Widget_base(wBase,/row, xpad=10, space=5)
    wData = Widget_Text(wBImport, xsize=20, /editable, uname="DATANAME")

    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:ImType'), $
                        /align_left)
    wBImport = Widget_base(wBase,/row, xpad=10, space=5)
    wDataType = Widget_DropList(wBImport, /dynamic, /FLAT)

    ;; Status message line
    wRow = Widget_Base(wTLB, /ROW, XPAD=5)
    wStatus = Widget_Label(wRow, VALUE=' ', /ALIGN_LEFT, SCR_XSIZE=xsize*0.8)

    ;; Now the bottom, button
    wButtons = Widget_Base(wTLB, /align_right, /row, space=5)

    wOK = Widget_Button(wButtons, $
                        VALUE=IDLitLangCatQuery('UI:wdCLImport:Import'), $
                        uname='OK', sensitive=0)
    wCancel = Widget_Button(wButtons, $
                            VALUE=IDLitLangCatQuery('UI:wdCLImport:Close'), $
                            uname='CANCEL')
    geomOK = Widget_Info(wOK, /GEOMETRY)
    geomCan = Widget_Info(wCancel, /GEOMETRY)
    Widget_Control, wOK, SCR_XSIZE=geomCan.scr_xsize > geomOK.scr_xsize, $
                    SCR_YSIZE=geomCan.scr_ysize > geomOK.scr_ysize
    Widget_Control, wCancel, SCR_XSIZE=geomCan.scr_xsize > geomOK.scr_xsize, $
                    SCR_YSIZE=geomCan.scr_ysize > geomOK.scr_ysize

    ;; our state.
    state = { wName          : wName,       $
              wType          : wType,       $
              wValue         : wValue,      $
              wTree          : wTree,       $
              wOK            : wOK,         $
              wData          : wData,       $
              oUI            : oUI,         $
              wDataType      : wDataType,   $
              wStatus        : wStatus,     $
              oRoot          : oRoot}

    ;; Place state in a pointer and note that we set the cancel  button.
    pState = ptr_new(state, /no_copy)
    widget_control, wTLB, set_uvalue=pState, /realize, cancel_button=wCancel

    xmanager, 'IDLitwdCommandLineImport', wTLB, NO_BLOCK=0

    ;; We are back

    ;; Return the CL objects to the command line service for
    ;; destruction
   if(obj_valid(oCL))then $
       oCL->ReturnCLDescriptors, (*pState).oRoot

    ptr_free, pState

    return, 1

end

