; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; 
; :Description:
;   Object has the responsibility of exporting itool graphics to
;   the java IDL workbench
;-


;------------------------------------------------------------------------
;+
; :Description:
;    Initialize the object.
;
; :Params:
;    Tooltype : In, Type=String
;
; :Keywords:
;    RENDERER
;    _EXTRA
;
;-
FUNCTION GraphicsWin::Init, Tooltype, $
    EXTERNAL_WINDOW=hwnd, $
    RENDERER=renderer, $
    _EXTRA=_extra
    
  compile_opt idl2, hidden
  
  void = HEAP_REFCOUNT(self, /DISABLE)

  ; Remember our tool type
  self.tooltype = ISA(Tooltype) ? Tooltype : 'Graphic'
  
  if (~self->Graphic::Init(self)) then return, 0
  IF (~self->IDLitGrWinScene::Init(RENDERER=renderer, $
      IDENTIFIER='WINDOW', $
      EXTERNAL_WINDOW=hwnd, $
      _EXTRA=_extra)) THEN RETURN, 0

  self->GetProperty, DIMENSIONS=d
  self->IDLitWindow::SetProperty, VIRTUAL_DIMENSIONS=d

  ; If this is an external window, we need to manually do an initial
  ; OnExpose, to get the graphics up & running.
  if (ISA(hwnd)) then begin
    self->_CreateTool
    self->OnExpose, 0,0, d[0], d[1]
  endif
    
  RETURN, 1
  
END


;------------------------------------------------------------------------
;+
; :Description:
;    Cleanup method.
;
;-
pro GraphicsWin::Cleanup
  compile_opt idl2, hidden
  
  self->IDLitGrWinScene::Cleanup
  obj_destroy, self.tool
end


;------------------------------------------------------------------------
pro GraphicsWin::_CreateTool

  compile_opt idl2, hidden

  ; This creates the itool that we are wrapping.
  ; We don't want this tool to create any user interface elements
  ; because we will do that in the Java Code.
  identifier = IDLitSys_CreateTool(self.tooltype, $
    USER_INTERFACE='itwindow', $
    INITIAL_DATA=null, $
    WINDOW_TITLE='IDL', $
    /NO_SAVEPROMPT, $
    /FIT_TO_VIEW)
    
  tool_id = iGetCurrent(TOOL=oTool)
  self->_SetTool, oTool

  oTool->_SetCurrentWindow, self

  ; Start with our own UI tool object
  oUI = obj_new('GraphicsUI', oTool)
  self.oUI = oUI

  ; Register the status bar with the UI object.
  ; The UI will get notified, and then send the probe status
  ; to the Workbench to update the graphic window.
  oUI->AddOnNotifyObserver, "/", tool_id + '/STATUS_BAR/PROBE'
  ; For now, swallow status bar "messages".
;  oUI->AddOnNotifyObserver, "/", tool_id + '/STATUS_BAR/MESSAGE'

  ; Register all manipulators and annotations with the UI object.
  ; That way, if IDL switches manipulators, the UI will get notified,
  ; which will then notify the Workbench to update the graphic window.
  oManip = oTool->GetManipulators()
  foreach oSubject, oManip do begin
    if (ISA(oSubject)) then $
      oUI->AddOnNotifyObserver, "/", oSubject->GetFullIdentifier()
  endforeach
  oAnnot = oTool->GetAnnotation(/ALL)
  foreach oSubject, oAnnot do begin
    if (ISA(oSubject)) then $
      oUI->AddOnNotifyObserver, "/", oSubject->GetFullIdentifier()
  endforeach

  ; Register for visualization notifications, such as SELECTIONCHANGED.
  oUI->AddOnNotifyObserver, '/', 'Visualization'

end


;------------------------------------------------------------------------
;+
; :Description:
;    Given a notification id, setup our eclipse adaptor as
;    an observer of the action.
;
; :Params:
;    notification_id : In, Type=String
;    
;-
pro GraphicsWin::AddOnNotifyObserver, notification_id
  compile_opt idl2, hidden
  
  ; CT, June 2010: Do we need this method?!
  if (ISA(self.tool) && ISA(self.oUI)) then begin
    tool_id = self.tool->GetFullIdentifier()
    self.oUI->AddOnNotifyObserver, "/", tool_id + notification_id
  endif
end

;------------------------------------------------------------------------
;+
; :Description:
;    Activate the manipulator with the given id.
;
; :Params:
;    strManipID : In, Type=String
;    
;-
pro GraphicsWin::ActivateManipulator, strManipID
  compile_opt idl2, hidden
  if (ISA(self.tool)) then $
    success = self.tool->DoAction(strManipID)
end


;------------------------------------------------------------------------
pro GraphicsWin::SetViewZoom, stringZoom
  compile_opt idl2, hidden

  if (ISA(self.tool)) then begin
    idTool = self.tool->GetFullIdentifier()
    strPath = idTool + '/TOOLBAR/VIEW/VIEWZOOM'
    success = self.tool->DoAction(strPath, OPTION=stringZoom)
  endif
end


;------------------------------------------------------------------------
pro GraphicsWin::DoAction, strActionID
  compile_opt idl2, hidden
  if (ISA(self.tool)) then $
    success = self.tool->DoAction(strActionID)
end


;------------------------------------------------------------------------
;+
; :Description:
;    Return the selection properties, given a selectionID
;
; :Returns: an xml formatted string of properties.
;-
function GraphicsWin::GetSelectionProperties, selectionID
  compile_opt idl2, hidden
  
  if (ISA(self.tool)) then begin
    oTool = self->GetTool()
    oTarget = oTool->GetByIdentifier(selectionID)
    return, self->makePropXml(oTarget)
  endif
  
end


function GraphicsWin::getPropValue, propType, strPropValue

  ; TODO: need to flesh out this conversion of the strPropValue
  ; to the correct type expected by the property.
  
  switch (propType) of
    9:       ;; enumlist
    1: begin ;; boolean
      ; convert the string integer into a real integer
      propValue = FIX(strPropValue, TYPE=2, /PRINT)
      break
    end
    5: begin ;; color
      propValue = self->ConvertStringToColor(strPropValue)
      break
    end
    else: begin
      propValue = strPropValue
    end
  endswitch
  
  return, propValue
end

;------------------------------------------------------------------------
;+
; :Description:
;    The Workbench calls this method when a property value in
;    the property sheet changes.  This routine will change the
;    property value on the real IDL object.
;
; :Params:
;    objectID     : In , required, Type= string
;    propID       : In , required, Type= string
;    propType     : In , required, Type= int
;    strpropValue : In , required, Type= string
;    strOrigValue : In , optional, Type= string
;    bCommit      : In , optional, Type= int
;
;-
pro GraphicsWin::SetObjectPropertyValue, objectID, propID, propType, strPropValue, strOrigValue, bCommit
  compile_opt idl2, hidden
  
  oTool = self->GetTool()
  oTarget = oTool->GetByIdentifier(objectID)
  if ( oTarget eq !null ) then return

  propValue = self->getPropValue(propType, strPropValue)

  if ( ISA(strOrigValue) ) then begin
    
    ; First, set the property to its original value
    origValue = self->getPropValue(propType, strOrigValue) 
    oTarget->SetPropertyByIdentifier, propID, origValue
    
    ; Now, set the property to the new value
    success = oTool->DoSetProperty(objectID, propID, propValue)  
    
    ; Now, commit the new property value to the undo/redo buffer
    if ( KEYWORD_SET(bCommit) ) then oTool->CommitActions
    
    
  endif else begin
  
    oTarget->SetPropertyByIdentifier, propID, propValue
    ; Be sure to notify, so things like Legends get updated properly.
    oTool->DoOnNotify, oTarget->GetfullIdentifier(), "SETPROPERTY", propID
    
  endelse

  oTool->RefreshCurrentWindow
     
end


;------------------------------------------------------------------------
function GraphicsWin::MakePropXml, oTarget
   compile_opt idl2, hidden

   if (~OBJ_VALID(oTarget)) then begin
     return, ""
   endif
   
   if (OBJ_ISA(oTarget, '_IDLitPropertyAggregate')) then begin
     props = oTarget->_IDLitPropertyAggregate::_GetAllPropertyDescriptors( $
       /INCLUDE_NAME, COUNT=count)
   endif else begin
     props = oTarget->_GetAllPropertyDescriptors(COUNT=count)
   endelse


   oDocument = OBJ_NEW('IDLffXMLDOMDocument')
   oProperties = oDocument->CreateElement('properties')
   oVoid = oDocument->AppendChild(oProperties)  
   
   length = N_ELEMENTS(props)
   for index = 0L, length-1 do begin
      props[index]->getProperty, PROPERTY_IDENTIFIER=propID, $
                                 NAME=propName, $
                                 DESCRIPTION=desc, $
                                 TYPE=propType, $
                                 ENUMLIST=elist, $
                                 SENSITIVE=sensitive, $
                                 HIDE=hide, $
                                 UNDEFINED=undefined, $
                                 VALID_RANGE=vRange, $
                                 ADVANCED_ONLY=advanced, $
                                 USERDEF=userdef
      
      res = oTarget->GetPropertyByIdentifier(propID,propValue)
      stringPropValue=""
      nElements = n_elements(propValue)
      switch (nElements) of
        1: begin
          stringPropValue = self->ConvertSingleValToString(propValue,propType)
          break
        end
        3: begin
          if (propType eq 5) then begin
            stringPropValue = self->ConvertColorToString(propValue)
          end
          break
        end
        else: begin
        end
      endswitch
 
      oProp = oDocument->CreateElement('prop')
      oVoid = oProperties->AppendChild(oProp)
      
      oId = oDocument->CreateElement('id')
      oText = oDocument->CreateTextNode(propID);
      oVoid = oId->AppendChild(oText)
      oVoid = oProp->AppendChild(oId)
      
      oValue = oDocument->CreateElement('value')
      oText = oDocument->CreateTextNode(stringPropValue);
      oVoid = oValue->AppendChild(oText)
      oVoid = oProp->AppendChild(oValue)
            
      oName = oDocument->CreateElement('name')
      oText = oDocument->CreateTextNode(propName);
      oVoid = oName->AppendChild(oText)
      oVoid = oProp->AppendChild(oName)  
      
      oDesc = oDocument->CreateElement('desc')
      oText = oDocument->CreateTextNode(desc);
      oVoid = oDesc->AppendChild(oText)
      oVoid = oProp->AppendChild(oDesc)
      
      oType = oDocument->CreateElement('type')
      oText = oDocument->CreateTextNode(STRTRIM(propType,2));
      oVoid = oType->AppendChild(oText)
      oVoid = oProp->AppendChild(oType) 
      
      oSensitive = oDocument->CreateElement('sensitive')
      oText = oDocument->CreateTextNode(STRTRIM(sensitive,2));
      oVoid = oSensitive->AppendChild(oText)
      oVoid = oProp->AppendChild(oSensitive)  
      
      oHide = oDocument->CreateElement('hide')
      oText = oDocument->CreateTextNode(STRTRIM(hide,2));
      oVoid = oHide->AppendChild(oText)
      oVoid = oProp->AppendChild(oHide)  
      
      oAdvanced = oDocument->CreateElement('advanced_only')
      oText = oDocument->CreateTextNode(STRTRIM(advanced,2));
      oVoid = oAdvanced->AppendChild(oText)
      oVoid = oProp->AppendChild(oAdvanced)  
      
;      oUndefined = oDocument->CreateElement('undefined')
;      oText = oDocument->CreateTextNode(STRTRIM(undefined,2));
;      oVoid = oUndefined->AppendChild(oText)
;      oVoid = oProp->AppendChild(oUndefined)   
      
      if (N_ELEMENTS(elist) gt 1) then begin
      
        ;; Make the elements of the elist a comma separated string
        ;; for transmission across to the workbench.
        
        enames = elist + [REPLICATE(',', N_ELEMENTS(elist)-1), '']
        joined_enames = strjoin(enames)
        
        oEnumList = oDocument->CreateElement('enumlist')
        oText = oDocument->CreateTextNode(joined_enames);
        oVoid = oEnumList->AppendChild(oText)
        oVoid = oProp->AppendChild(oEnumList)
      end            
   endfor
 

  oDocument->Save, /PRETTY_PRINT, STRING=xml
  OBJ_DESTROY, oDocument 
     
  return, xml
   
end

;------------------------------------------------------------------------
;+
; :Description:
;    Convert a color rgb array to a string.
;
; :Params:
;    propValue: In, Type=[r,g,b] 3 element byte array
;-
function GraphicsWin::ConvertColorToString, propValue
  compile_opt idl2, hidden
   sR = FIX(propValue[0], TYPE=7, /PRINT)
   sG = FIX(propValue[1], TYPE=7, /PRINT)
   sB = FIX(propValue[2], TYPE=7, /PRINT)
   return, sR+','+sG+','+sB
end

;------------------------------------------------------------------------
;+
; :Description:
;    Convert a string rgb value, to a color rgb byte array
;
; :Params:
;    propValue : In, Type=String
;       Of the form r,g,b
;
;-
function GraphicsWin::ConvertStringToColor, propValue
    compile_opt idl2, hidden
    
    sc = strsplit(propValue,',',/EXTRACT)

    ; The value might be something like "-1" if it is a default value.
    ; In this case just return the value converted to a number.
    if (N_ELEMENTS(sc) ne 3) then return, LONG(propValue)

    c = BYTARR(3)
    c[0]=FIX(sc[0], TYPE=7)
    c[1]=FIX(sc[1], TYPE=7)
    c[2]=FIX(sc[2], TYPE=7)
    
    return, c
end

;------------------------------------------------------------------------
;+
; :Description:
;    Convert a single value to a string.
;
; :Params:
;    propValue
;    inPropType
;
;-
function GraphicsWin::ConvertSingleValToString, propValue, inPropType
   compile_opt idl2, hidden
   
   ; see itcomp_property.c

   propType = SIZE(propValue,/TYPE)

   switch (propType) of
     0: begin ; IDL_PROP_USERDEF
          return, 'dont do user defined yet'
       break
     end
     
     1: begin  ;byte
         return, FIX(propValue, TYPE=7, /PRINT)
       break
     end 
     
     2:        ; int
     3:        ; long   
     4:        ; float    
     5: begin  ; double
         if (finite(propValue) && abs(propValue) lt 1d-30) then propValue = 0
         return, STRING(propValue, FORMAT='(g0)')
       break
     end 
     6: begin ; complex
         return, 'dont do complex yet'
       break
     end
     
     7: begin  ; string
         return,propValue    
       break
     end 
     
     8: begin  ; struct
         return, 'dont do struct yet'   
       break
     end 
     9: begin ; dcomplex
          return, 'dont do dcomplex yet'  
       break
     end
     
     10: begin  ; pointer
          return, 'dont do pointer yet'     
       break
     end 
     
     11: begin  ; OBJREF
          return, 'dont do objref yet'     
       break
     end 
     12: begin  ; uint
          return, 'dont do uint yet'     
       break
     end 
     13: begin  ; ulong
          return, 'dont do ulong yet'     
       break
     end  
     14: begin  ; long64
          return, 'dont do long64 yet'     
       break
     end 
     15: begin  ; ulong64
          return, 'dont do ulong64 yet'     
       break
     end                                         
     else: begin
        return, ""
     end
     
   endswitch


end


;---------------------------------------------------------------------------
pro GraphicsWin::Select, _EXTRA=_extra
  compile_opt idl2, hidden

  ; Notify the workbench to bring the window to the front
  !NULL = IDLNotify('IDLitSetCurrent', self.tool->GetFullIdentifier(), '')

end


;---------------------------------------------------------------------------
; GraphicsWin::OnResize
;
; Purpose:
;   Called on a resize event. Performs a resize.
;
pro GraphicsWin::OnResize, width, height
  compile_opt idl2, hidden

  self->IDLitgrWinScene::OnResize, width, height
  self->GetProperty, DIMENSIONS=dims
  self->SetProperty, VIRTUAL_DIMENSIONS=dims
end



;pro GraphicsWin::OnKeyboard,  IsASCII, Character, KeySymbol, X, Y, Press, Release, Modifiers
;  print, IsASCII, Character, KeySymbol, X, Y, Press, Release, Modifiers
;  self->idlitgrwinscene::OnKeyboard, IsASCII, Character, KeySymbol, X, Y, Press, Release, Modifiers
;end

;---------------------------------------------------------------------------
pro GraphicsWin::GetProperty, UI=ui, _REF_EXTRA=ex
  compile_opt idl2, hidden
  ON_ERROR, 2
  if (ARG_PRESENT(ui)) then ui = self.oUI
  self->Graphic::GetProperty, _EXTRA=ex
  self->IDLitGrWinScene::GetProperty, _EXTRA=ex
end

;---------------------------------------------------------------------------
pro GraphicsWin::SetProperty, UI=ui, _EXTRA=ex
  compile_opt idl2, hidden
  ON_ERROR, 2
  if (ISA(ui)) then self.oUI = ui
  self->Graphic::SetProperty, _EXTRA=ex
  self->IDLitGrWinScene::SetProperty, _EXTRA=ex
end

;------------------------------------------------------------------------
pro GraphicsWin__define
  compile_opt idl2, hidden
  
  void = {GraphicsWin, $
    inherits Graphic, $
    inherits IDLitGrWinScene, $
    tooltype:'', $
    oUI:obj_new() $
    }
    
end
