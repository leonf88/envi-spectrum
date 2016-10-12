; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdprompttext.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdPromptText
;
; PURPOSE:
;   Creates a modal dialog that prompts the user for a line of text.
;
; CALLING SEQUENCE:
;    status = IDLitwdPromptText(otarget, wLeader, strVars)
;
; INPUTS:
;     oTarget - Target operation object.
;
;     wLeader - Group leader for this modal widget
;
; OUTPUTS
;
;
; RETURN VALUE
;     1 - Success
;     0 - Cancel
;
; KEYWORD PARAMETERS:
;    Standard Widget keywords.
;
; MODIFICATION HISTORY:
;   KDB July 02
;   Modified:
;
;-


;;-------------------------------------------------------------------------
;; IDLitwdPromptText__event
;;
;; Purpose:
;;    Event handler for this interface
;;
;; Parameters:
;;   event   - The event from the widget interface.
;;
pro IDLitwdPromptText_event, event

    compile_opt idl2, hidden

    ;; Error trapping
@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        if(n_elements(state) gt 0)then $
          Widget_Control, event.top, set_uvalue=state,/no_copy
        return
    end
    ;; Grab our state an control uvalue
    Widget_Control, event.top, get_uvalue=state,/no_copy
    Widget_control, event.id, get_uvalue=uval


    switch uval of
    'close': begin
           widget_control, state.wText, get_value=strText
           *state.pData = strText[0]
       end ;; fall through
    'cancel':begin  ; The user is done, destroy and exit.
         widget_control, event.top, /destroy
         return
         end
    'TEXT': if(event.type eq 0)then begin
        if(event.ch eq 10b)then begin ;; CR entered
           widget_control, state.wText, get_value=strText
           *state.pData = strText[0]
           widget_control, event.top, /destroy
           return
        endif
        break
       endif
     else: ;; nothing.
    endswitch
    Widget_Control, event.top, set_uvalue=state,/no_copy

end

;;-------------------------------------------------------------------------
;; See file header for API
;;
function IDLitwdPromptText, wLeader, strPrompt, strOutput, $
                         TITLE=titleIn, $
                         XSIZE=xsizeIn, $
                         YSIZE=ysizeIn, $
                         VALUE=VALUE, $
                         _REF_EXTRA=_extra

   compile_opt idl2, hidden

   ;; Keyword Validation
   title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
           IDLitLangCatQuery('UI:wdPromptTxt:Title')

   if(WIDGET_INFO(wLeader, /valid) eq 0)then $
     Message, IDLitLangCatQuery('UI:NeedGroupLeader')

   xsize = (N_ELEMENTS(xsizeIn) gt 0) ? xsizeIn[0] : 200
   ysize = (N_ELEMENTS(ysizeIn) gt 0) ? ysizeIn[0] : 150

   ;; Okay, create our modal TLB
   wTLB = Widget_Base( /MODAL, GROUP_LEADER=wLeader, $
                       TLB_FRAME_ATTR=1, $
                       /BASE_ALIGN_RIGHT, $
                       /COLUMN, $
                       SPACE=2, $
                       TITLE=title,  $
                       _EXTRA=_extra)

   wBase = Widget_Base(wTLB, /column)
   ;; Make the prompt using lots o labels
   for i=0, n_elements(strPrompt)-1 do $
       wVoid = widget_label(wBase, /align_left, value=strPrompt[i])


   wText = Widget_Text(wBase, /ysize, /editable, xsize=20, uvalue='TEXT', value=value)

   ;; Add a Close button.
   wBBase = Widget_base(wTLB, /row, /base_align_right, space=3)
   wOK = Widget_Button(wBBase, VALUE=IDLitLangCatQuery('UI:OK'), UVALUE="close")
   wCan = Widget_Button(wBBase, VALUE=IDLitLangCatQuery('UI:Cancel'), UVALUE="cancel")
   sGeom = Widget_info(wCan,/geom)
   widget_control ,wOK, scr_xsize = sGeom.scr_xsize ; buttons same size

   pData = ptr_new(/Allocate_Heap) ;used to communicate values.
   widget_control, wTLB, /REALIZE,  SET_UVALUE= $
                 {pData:pData, wText:wText}, $
                 DEFAULT_BUTTON=wOK
   widget_control, wText, /input_focus
   ;; Highlight the value
   if(keyword_set(value))then $
     widget_control, wText, set_text_select=[0, strlen(value)]

    ;; Call xmanager, which will block until the dialog is closed
    xmanager, 'IDLitwdPromptText', wTLB

    ;; Okay, what do we have ..look at pdata
    if(n_elements(*pData) eq 0)then $
      status = 0 $
    else begin
        strOutput = *pData;
        status = 1
    endelse
    ptr_free, pData

    return, status
end
