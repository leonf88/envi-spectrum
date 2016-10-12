; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itpropertysheet.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_ITPROPERTYSHEET
;
; PURPOSE:
;   This function implements the compound widget for the IT property sheet.
;
; CALLING SEQUENCE:
;   Result = CW_ITPROPERTYSHEET(Parent)
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
; KEYWORD PARAMETERS:
;
; OUTPUT:
;   ID of the newly created widget
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-

;----------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_CALLBACK
;
; PURPOSE:
;       Callback routine
;
; INPUTS:
;       WPROP: (required) widget ID of the propertysheet
;
;       STRID: not used
;
;       MESSAGEIN: string message name
;
;       COMPONENT: identifier of object(s)
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_ITPROPERTYSHEET_CALLBACK, wProp, strID, messageIn, component
  compile_opt idl2, hidden

  IF NOT WIDGET_INFO(wProp, /VALID) THEN  return

  WIDGET_CONTROL, wProp, GET_UVALUE=pState

  switch STRUPCASE(messageIn) OF
    'SELECTIONCHANGED': BEGIN
        (*pState).withinSet = 0b
        if ((*pState).type ne 'Visualization Browser') then $
            break
        ; If nothing selected, default to the Layer.
        if (~keyword_set(component[0])) then begin
            oTool = (*pState).oUI->GetTool()
            oWin = oTool->GetCurrentWindow()
            if (~OBJ_VALID(oWin)) then $
                break
            oViewGroup = oWin->GetCurrentView()
            component = oViewGroup->GetCurrentLayer()
        endif
        WIDGET_CONTROL, (*pState).wProp, set_value=component
        break
        end

    'SETPROPERTY': BEGIN
      ; To avoid multiple callbacks, bail if within SetProp event.
      if (~WIDGET_INFO((*pState).wProp, /VALID) || $
        (*pState).withinSet) then break
        ; Retrieve the current object reference. This is more efficient
        ; than using oTool->GetByIdentifier().
        WIDGET_CONTROL, (*pState).wProp, FUNC_GET_VALUE=''
        WIDGET_CONTROL, (*pState).wProp, GET_VALUE=oObj
        WIDGET_CONTROL, (*pState).wProp, $
            FUNC_GET_VALUE='CW_ITPROPERTYSHEET_GETVALUE'
        ; Just update all the properties for now. It is possible
        ; that changing one property may force other properties
        ; to become sensitive/insensitive, and rather than trying
        ; to pass back a "refresh" list, just refresh all.
        if (OBJ_VALID(oObj[0])) then begin ;; make sure object is valid
          WIDGET_CONTROL, (*pState).wProp, $
          /REFRESH_PROPERTY     ; DON'T CHANGE to "component"
        endif
      break
    END

    ELSE :

  endswitch

END

;----------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_RESIZE
;
; PURPOSE:
;       Handle resize requests
;
; INPUTS:
;       ID: (required) widget ID of the propertysheet
;
;       DELTAX[Y]: (required) change in X[Y] size of the widget base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_ITPROPERTYSHEET_RESIZE, id, deltaX, deltaY
  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=pState

    ; Retrieve the current property sheet size.
  geom = WIDGET_INFO((*pState).wProp, /GEOMETRY)
  newScrXsize = (geom.scr_xsize + deltaX) > 0
  newScrYsize = (geom.scr_ysize + deltaY) > 0

    ; Change width of property sheet.
  WIDGET_CONTROL, (*pState).wProp, SCR_XSIZE=newScrXsize, $
                  SCR_YSIZE=newScrYsize

end

;----------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_GETVALUE
;
; PURPOSE:
;       Retrieve the current object reference
;
; INPUTS:
;       ID: (required) widget ID of the propertysheet
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       current object reference
;-
FUNCTION CW_ITPROPERTYSHEET_GETVALUE, id
  compile_opt idl2, hidden

;    ON_ERROR, 2                       ;return to caller

  WIDGET_CONTROL, id, GET_UVALUE=pState
  result = *(*pState).pComponent
  ; Return either a scalar or a vector.
  return, (N_ELEMENTS(result) eq 1) ? result[0] : result

end


;----------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_SETVALUE
;
; PURPOSE:
;       Sets the current object reference
;
; INPUTS:
;       ID: (required) widget ID of the propertysheet
;
;       IDCOMPONENT: (required) Idenfitier of the object
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_ITPROPERTYSHEET_SETVALUE, id, idComponent
  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=pState
  nComp = n_elements(idComponent)
    ; This is a shortcut to allow the user to pass in objrefs and
    ; retrieve their identifiers.
    if (SIZE(idComponent, /TYPE) eq 11) then begin
        oComponent = idComponent
        idComponent = (nComp gt 1) ? STRARR(nComp) : ''
        for i=0,nComp-1 do begin
            if (OBJ_VALID(oComponent[i])) then $
                idComponent[i] = oComponent[i]->GetFullIdentifier()
        endfor
    endif


    oTool = (*pState).oUI->GetTool()

    ; Only get the objrefs if we didn't get them above.
    if (N_ELEMENTS(oComponent) eq 0) then begin
        oComponent = (nComp gt 1) ? OBJARR(nComp) : OBJ_NEW()

        for i=0,nComp-1 do begin
            oComponent[i] = oTool->GetByIdentifier(idComponent[i])
            if (~OBJ_VALID(oComponent[i])) then $
                idComponent[i] = ''
        endfor
        good = WHERE(idComponent ne '', nComp)
        if (nComp gt 0) then begin
            idComponent = idComponent[good]
            oComponent = oComponent[good]
        endif else begin
            idComponent = ''
            oComponent = OBJ_NEW()
        endelse
    endif


  ;; No longer need notifications from the "old" component we are
  ;; observing
  for i=0,N_ELEMENTS(*(*pState).pComponent)-1 do begin
    (*pState).oUI->RemoveOnNotifyObserver, (*pState).idSelf, (*(*pState).pComponent)[i]
  endfor

  ;; Get the target component and give it to the prop sheet widget
  WIDGET_CONTROL, (*pState).wProp, PRO_SET_VALUE='',update=0


  if (nComp gt 1) then begin

    if ((*pState).type eq 'Visualization Browser') then begin

        oGroup = oTool->GetByIdentifier((*pState).idGroup)

        if (~OBJ_VALID(oGroup)) then begin
            oGroup = OBJ_NEW('IDLitPropertyAggregate', $
                NAME='Multiple selection', /PRIVATE, /PROPERTY_INTERSECTION)
            oGroup->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], /HIDE
            oTool->Add, oGroup
            (*pState).idGroup = oGroup->GetFullIdentifier()
        endif else begin
            oGroup->RemoveAggregate, /ALL
        endelse

        for i=0,nComp-1 do $
            oGroup->AddAggregate, oComponent[i]

        oGroup->_CheckIntersectAttributes

        WIDGET_CONTROL, (*pState).wProp, SET_VALUE=oGroup

    endif else begin
        WIDGET_CONTROL, (*pState).wProp, SET_VALUE=oComponent
    endelse

  endif else begin

    ; If this component is using property intersection, make sure
    ; the attributes are up to date before adding to property sheet.
    if (OBJ_ISA(oComponent[0], '_IDLitPropertyAggregate') && $
        oComponent[0]->IsAggregateIntersection()) then begin
        oComponent[0]->_CheckIntersectAttributes
    endif

    WIDGET_CONTROL, (*pState).wProp, SET_VALUE=oComponent[0]

  endelse


  WIDGET_CONTROL, (*pState).wProp, PRO_SET_VALUE='cw_itpropertysheet_setvalue', update=1

  ;; Stash our info
  *(*pState).pComponent = idComponent

  ;; Observer the new item.
  for i=0,nComp-1 do begin
    if (OBJ_VALID(oComponent[i])) then $
        (*pState).oUI->AddOnNotifyObserver, (*pState).idSelf, idComponent[i]
  endfor

END

;----------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_KILLNOTIFY
;
; PURPOSE:
;       Sets the current object reference
;
; INPUTS:
;       ID: (required) widget ID of the propertysheet
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO CW_ITPROPERTYSHEET_KILLNOTIFY, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    ; This will also remove ourself as an observer for all subjects.
    if ISA((*pState).oUI) then (*pState).oUI->UnRegisterWidget, (*pState).idSelf

    PTR_FREE, (*pState).pComponent
    PTR_FREE, pState

END


;-------------------------------------------------------------------------
;+
; NAME:
;   CW_ITPROPERTYSHEET_EVENT
;
; PURPOSE:
;       Sets the current object reference
;
; INPUTS:
;       EVENT: (required) widget event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
function CW_ITPROPERTYSHEET_EVENT, event
  compile_opt idl2, hidden

  WIDGET_CONTROL, event.id, GET_UVALUE=pState

  ret_event = 0

  case TAG_NAMES(event, /STRUCTURE_NAME) of

    'WIDGET_PROPSHEET_CHANGE': begin

      if (*pState).bChangeEvents then $
          ret_event = event

      oTool = (*pState).oUI->GetTool()

        ; Verify that the component in the event struct matches the
        ; widget_propertysheet value. In rare cases these can get out
        ; of sync.
        WIDGET_CONTROL, (*pState).wProp, FUNC_GET_VALUE=''
        WIDGET_CONTROL, (*pState).wProp, GET_VALUE=oCurrentComponent
        WIDGET_CONTROL, (*pState).wProp, $
            FUNC_GET_VALUE='CW_ITPROPERTYSHEET_GETVALUE'
        if (MAX(oCurrentComponent eq event.component) ne 1) then begin
            oTool->ErrorMessage, SEVERITY=2, $
              [IDLitLangCatQuery('UI:cwPropSheet:ObjNEComp1'), $
               IDLitLangCatQuery('UI:cwPropSheet:ObjNEComp2')]
            return, 0
        endif

      if (event.set_defined) then begin
        ; Reset my undefined flag.
        event.component->SetPropertyAttribute, $
            event.identifier, UNDEFINED=0
        ; We will handle the refresh below.
      endif

      ; If a property on an intersected container changed,
      ; or if a property on a child of an intersected container was
      ; changed, then we need to refresh the property intersection later.
      if (OBJ_ISA(event.component, '_IDLitPropertyAggregate') && $
        event.component->IsAggregateIntersection()) then begin
        oPropIntersect = event.component
      endif else begin
        if OBJ_ISA(event.component, 'IDLgrComponent') then begin
            event.component->IDLgrComponent::GetProperty, PARENT=oParent
            ; Is our parent an intersected container?
            if (OBJ_VALID(oParent) && $
                OBJ_ISA(oParent, '_IDLitPropertyAggregate') && $
                oParent->IsAggregateIntersection()) then begin
                oPropIntersect = oParent
            endif
        endif
      endelse

      ; Do we need to check our property intersection attributes?
      isPropIntersect = OBJ_VALID(oPropIntersect)

      ; To avoid multiple set_property callbacks, set our flag here.
      (*pState).withinSet = 1b

      ; If not a user-defined property, then we need to perform
      ; SetProperty ourself.
      if (event.proptype ne 0) then begin

        ; Get the value of the property that changed.
        value = WIDGET_INFO(event.id, $
                            COMPONENT=event.component, $
                            PROPERTY_VALUE=event.identifier)

        ; Use DoSetProperty so everyone gets notified (like the browser).
        ; The property sheet will be refreshed at the end.
        success = oTool->DoSetProperty( $
            event.component->GetFullIdentifier(), event.identifier, value)
        if ((*pState).bDoCommit) then begin
            oTool->CommitActions
        endif else begin
            ; If we didn't commit then we may need to refresh.
            if (success && OBJ_ISA(oTool, 'IDLitTool')) then $
                oTool->RefreshCurrentWindow
        endelse

      endif else begin    ; userdef property

        ; Retrieve our service and fire it off.
        oEditUserdef = oTool->GetService('EditUserdefProperty')
        void = oEditUserdef->DoAction(oTool, event.component, $
            event.identifier)

      endelse    ; userdef


      ; For a PropertyIntersection, we need to check if any of our
      ; hide, sensitive, or undefined flags have changed.
      ; This needs to be done after the SetProperty above.
      if (isPropIntersect) then $
        oPropIntersect->_CheckIntersectAttributes

      ; Clear our flag and refresh the property sheet.
      (*pState).withinSet = 0b
      WIDGET_CONTROL, event.id, /REFRESH_PROPERTY

    end


    'WIDGET_PROPSHEET_SELECT': BEGIN
      ret_event = event
      if ((*pState).wStatus ne 0) then begin
        ; The identifier can be null if <Ctrl> key was used to deselect
        ; all properties.
        if (event.identifier ne '') then begin
            event.component->GetPropertyAttribute, event.identifier, $
                DESCRIPTION=desc
            if (~desc) then $
                desc=' '
        endif else desc = ' '
        WIDGET_CONTROL, (*pState).wStatus, SET_VALUE=desc
      endif
    end

    'CW_PANES_RESIZE' : BEGIN
      cw_itpropertysheet_resize,event.id,event.deltaX,event.deltaY
    END

    ELSE: ret_event = event

  ENDCASE

  return, ret_event

END


;-------------------------------------------------------------------------
FUNCTION CW_ITPROPERTYSHEET, parent, oUI, $
    VALUE=idComponent, $
    COMMIT_CHANGES=COMMIT_CHANGES, $
    CHANGE_EVENTS=changeEvents, $
    TYPE=typeIn, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror


    type = N_ELEMENTS(typeIn) ? typeIn : ''

    ; For the property sheet to naturally size, it needs an object
    ; on creation. For now, just pick the first object.
    ; We will actually set the correct objects later.
    if (N_ELEMENTS(idComponent) gt 0) then begin
        oTool = oUI->GetTool()
        oComponent = oTool->GetByIdentifier(idComponent[0])
    endif

  ;; Construct the property sheet.
  wProp = WIDGET_PROPERTYSHEET(parent, $
    uname='cw_propertysheet', $
    VALUE=oComponent, $
    EVENT_FUNC='cw_itpropertysheet_event', $
    FUNC_GET_VALUE='cw_itpropertysheet_getvalue', $
    KILL_NOTIFY='cw_itpropertysheet_killnotify', $
    PRO_SET_VALUE='cw_itpropertysheet_setvalue', $
    _EXTRA=_extra)

  ;; Register ourself as a widget with the UI object.
  ;; Returns a string containing our identifier.
  idSelf = oUI->RegisterWidget(wProp, 'PropertySheet', $
    'cw_itpropertysheet_callback')

  ;; Register for viz messages.
  oUI->AddOnNotifyObserver, idSelf, 'Visualization'

  ;; Cache my state information within my child.
  state = { $
            wProp           : wProp, $
            wStatus         : 0l, $
            withinSet       : 0b, $
            idSelf          : idSelf, $
            pComponent      : PTR_NEW(/ALLOCATE), $
            bDoCommit       : keyword_Set(COMMIT_CHANGES), $
            bChangeEvents   : keyword_Set(changeEvents), $
            type            : type, $
            idGroup         : '', $
            oUI             : oUI}  ;the UI object

  WIDGET_CONTROL, wProp, SET_UVALUE=PTR_NEW(state)

  if (N_ELEMENTS(idComponent) gt 0) then $
    WIDGET_CONTROL, wProp, SET_VALUE=idComponent

  return, wProp

END
