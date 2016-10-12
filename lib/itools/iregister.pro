; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iregister.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iRegister
;
; PURPOSE:
;   A procedural method that allows the user to register an item with
;   the system. This can include tools (the default), visualizations
;   and user interfaces
;
; PARAMETERS
;   strName       - The name to associate with the class
;
;   strClassName  - The class name of the tool or if a UI is being
;                   registered, the routine to call.
;
; Keywords:
;   ANNOTATION: Register an annotation
;
;   FILE_READER: Register a File Reader
;
;   FILE_WRITER: Register a File Writer
;
;   TOOL <default>: Register a tool with the system
;
;   VISUALIZATION: Register a Visualization
;
;   USER_INTERFACE: Register user interface style
;
;   UI_PANEL: Register a UI panel routine and type
;
;   UI_SERVICE: Register a UI service with the system.
;
;   All keywords are passed to the underlying tool registration system.
;
; MODIFICATION HISTORY:
;   Modified: CT, RSI, Jan 2004: Added ANNOTATION, FILE_READER,
;       FILE_WRITER, USER_INTERFACE keywords.
;   Modified: AGEH, RSI, August 2008: Rename it->i
;
;-

;-------------------------------------------------------------------------
PRO iRegister, strName, strClassName, $
                ANNOTATION=annotation, $
                FILE_READER=file_reader, $
                FILE_WRITER=file_writer, $
                VISUALIZATION=visualization, $
                USER_INTERFACE=user_interface, $
                UI_PANEL=ui_panel, $
                UI_SERVICE=ui_service, $
                TOOL=tool, $
                _EXTRA=_EXTRA


   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return
   endif

   ;; Basically Get the system object and register
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
     return

   ;; Just determine what to do and register.
   case 1 of

       keyword_set(visualization):$
         oSystem->RegisterVisualization, strName, strClassName, _EXTRA=_extra

       keyword_set(annotation):$
         oSystem->RegisterAnnotation, strName, strClassName, _EXTRA=_extra

       keyword_set(user_interface): $
          oSystem->RegisterUserInterface, strName, strClassName, _EXTRA=_extra

       keyword_set(ui_panel): $
          oSystem->RegisterUIPanel, strName, strClassName, _EXTRA=_extra

       keyword_set(ui_service): $
          oSystem->RegisterUIService, strName, strClassName, _EXTRA=_extra

       keyword_set(file_reader):$
         oSystem->RegisterFileReader, strName, strClassName, _EXTRA=_extra

       keyword_set(file_writer):$
         oSystem->RegisterFileWriter, strName, strClassName, _EXTRA=_extra

       else: $
          oSystem->RegisterTool, strName, strClassName, _EXTRA=_extra

   endcase
end


