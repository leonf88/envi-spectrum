; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphicsui__define.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitUI
;
; PURPOSE:
;   This file implements the generic IDL Tool User Interface object
;   manages the connection between the underlying tool object and
;   the elements that comprise the user interface.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See GraphicsUI::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; GraphicsUI::Init
;
; Purpose:
; The constructor of the IDLitUI object.
;
; Parameters:
; oTool    - The IDLitTool object this UI is assciated with
;
function GraphicsUI::Init, oTool,  _REF_EXTRA=_extra
 
   compile_opt idl2, hidden

   if (~self->IDLitUI::Init(oTool, NAME="GraphicsUI", $
                                  IDENTIFIER="")) then $
      return, 0

   self->Add, obj_new("IDLitContainer", NAME="General")

   self._oTool = oTool
   self.idTool = oTool->GetFullIdentifier()
   self.oWin = oTool->GetCurrentWindow()

   self->SetProperty, _EXTRA=_extra

    ;*** Register the Error ui service.
; Note, CT, Nov 2009: Do we need these for embedded graphics?
;
;   identifier = self->RegisterUIService('IDLitErrorObjDialog',  $
;                                        'IDLitUIDisplayErrorObj')
;
;   identifier = self->RegisterUIService('IDLitPromptUserYesNo',  $
;                                        'IDLitUIPromptUser')
;   identifier = self->RegisterUIService('IDLitPromptUserText',  $
;                                        'IDLitUIPromptUserText')
;
;   identifier = self->RegisterUIService('IDLitProgressBar',  $
;                                        'IDLitUIProgressBar')
;
;   identifier = self->RegisterUIService('IDLitAboutITools',  $
;                                        'IDLitWdAbout')
  void = self->RegisterUIService('PropertySheet', 'IDLituiPropertySheet')

  return, 1

end
;---------------------------------------------------------------------------
; GraphicsUI::Cleanup
;
; Purpose:
;   Destructor of the UI Class
;
pro GraphicsUI::Cleanup
 
   compile_opt idl2, hidden

   ; Call our super class.
   self->IDLitUI::Cleanup

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro GraphicsUI::GetProperty, $
    _REF_EXTRA=super

  compile_opt idl2, hidden

  ; get superclass properties
  if (N_ELEMENTS(super) gt 0) then $
      self->IDLitUI::GetProperty, _EXTRA=super
end


;----------------------------------------------------------------------------
pro GraphicsUI::SetProperty, $
  _REF_EXTRA=super

  compile_opt idl2, hidden

  ; Set superclass properties
  if (N_ELEMENTS(super) gt 0) then $
      self->IDLitUI::SetProperty, _EXTRA=super
end


;---------------------------------------------------------------------------
; GraphicsUI::AppendChild
;
; Purpose:
;   Local utility function used to build up an XML DOM
;   with children.
;
; Parameters:
;    oDoc         - XML Document Object
;  
;    oParent      - Dom element to append to.
;
;    elementName  - Name of the XML Element to create
;
;    data         - data for the element
PRO GraphicsUI::AppendChild, oDoc, oParent, elementName, data


  compile_opt idl2, hidden

  oElem = oDoc->CreateElement(elementName)
  oVoid = oParent->AppendChild(oElem)
  oText = oDoc->CreateTextNode(data)
  oVoid = oElem->AppendChild(oText)

END


;---------------------------------------------------------------------------
;+
; :Description:
;    Intercept DoUIService calls and send some to the workbench
;    for final service.
;
; :Params:
;    strService
;    oRequester
;
;-
function GraphicsUI::DoUIService, strService, oRequester

  compile_opt idl2, hidden

@graphic_error

  case (strService) of
  
    'EditProperties': begin
;      void = IDLNotify('iToolNotification',self.idTool,'UISERVICE::'+strService)
    end
    
    'IDLitProgressBar': begin
;      void = IDLNotify('iToolNotification',self.idTool,'UISERVICE::'+strService)
    end
    
    'IDLitErrorObjDialog': begin
      ; Instead of throwing up a dialog, just print out the error message.
      oRequester->GetProperty, DESCRIPTION=msg
      MESSAGE, msg[-1]
    end
    
    else: begin
      return, self->IDLitUI::DoUIService( strService, oRequester )
    end
    
  endcase

  return, 1


end


;---------------------------------------------------------------------------
; GraphicsUI::OnNotify
;
; Purpose:
;   A notification callback that the UI object uses to monitor
;   messages from the underlying tool object.
;
; Parameters:
;   strID    - The identifier of the underlying tool
;
;   message  - The message that is being sent.

pro GraphicsUI::OnNotify, strID, message, userdata

  compile_opt hidden, idl2
  ON_ERROR, 2
  
   case message of
     'SHUTDOWN' : begin
         self.IDLitUI::OnNotify, strID, message, userdata
     end
     'FOCUS_CHANGE' : begin
     end
     'SHOW' : begin
     end

    'SETVALUE': begin
      void = IDLNotify('iToolNotification',self.idTool,strID+'::'+userdata)
    end
    
    'MESSAGE': begin
      void = IDLNotify('iToolNotification',self.idTool,strID+'::'+userdata)
    end
    
    'SELECT': begin
      selectStatus = (userdata eq 0) ? "FALSE" : "TRUE"
      void = IDLNotify('iToolNotification',self.idTool,strID+'::'+selectStatus)
    end
    
    'SELECTIONCHANGED': begin
      ; Pass the selected id's on to the workbench, separated by ; chars
      selectionID = STRJOIN(userdata, ';')
      id = strupcase(strID)+'/'+STRUPCASE(message)
      void = IDLNotify('iToolNotification',self.idTool,id+'::'+selectionID)
     end

     else :
   endcase

end

;---------------------------------------------------------------------------
; IDLitUI__Define
;
; Purpose:
;   This method defines the IDLitUI class.
;
pro GraphicsUI__Define

  compile_opt idl2, hidden

  void = { GraphicsUI,                     $
           inherits IDLitUI,       $ ; The root of the hierarchy
           idTool: '', $
           oWin: OBJ_NEW() $
           }
end
