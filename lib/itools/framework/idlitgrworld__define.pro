; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrworld__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitgrWorld
;
; PURPOSE:
;    The IDLitgrWorld class represents the overall collection of
;    visualizations to be drawn within a ViewLayer.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;    IDLgrModel
;    IDLitSelectParent
;    IDLitIMessaging
;
;-

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to create our light container.
;
pro IDLitgrWorld::_CreateLightModel

    compile_opt idl2, hidden

    if OBJ_VALID(self.oLightModel) then $
        return

    self->IDLgrModel::GetProperty, PARENT=oParent

    oLightModel = OBJ_NEW('_IDLitVisualization', HIDE=0, $
        /PROPERTY_INTERSECTION, $
        TOOL=self->GetTool(), $
        DESCRIPTION="Light Container", NAME='Lights', ICON='bulb', $
        select_target=0, _PARENT=oParent)
    oLightModel->SetPropertyAttribute, $
        ["DESCRIPTION","HIDE", "NAME"], /HIDE

    ; Add an empty select box to our light container, so we can't
    ; translate or scale.
    oLightModel->SetDefaultSelectionVisual, $
        OBJ_NEW('IDLitManipVisSelect', /HIDE)

    self.oLightModel = oLightModel
    self->IDLgrModel::Add, self.oLightModel

end


;----------------------------------------------------------------------------
; Purpose:
;    Intializes the default lights for the world.
;
pro IDLitgrWorld::UpdateLights, is3D

    compile_opt idl2, hidden


    ; If necessary, create a model to contain all of the lights.
    self->_CreateLightModel

    ; If not already done, create the standard default lights.
    if (is3D && self.isInit) then begin

        self.isInit = 0b  ; Won't come thru here again.

        self.oLightModel->Add, OBJ_NEW('IDLitVisLight', $
                    LIGHT_TYPE=0, $   ; ambient
                    LOCATION=[0,0,1], $
                    NAME='Ambient Light', $
                    IDENTIFIER='LIGHT'), $
                    /AGGREGATE

        self.oLightModel->Add, OBJ_NEW('IDLitVisLight', $
                    LIGHT_TYPE=2, $   ; directional
                    LOCATION=[-1,1,1], $
                    NAME='Directional Light', $
                    IDENTIFIER='LIGHT'), $
                    /AGGREGATE

    endif

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::Init
;
; PURPOSE:
;    Initializes an IDLitgrWorld object.
;
; CALLING SEQUENCE:
;    oWorld = OBJ_NEW('IDLitgrWorld')
;
;        or
;
;    Result = oWorld->[IDLitgrWorld::]Init()
;
; KEYWORD PARAMETERS:
;    <Accepts all keywords accepted by the superclasses.>
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 if initialization
;    fails.
;
;-
function IDLitgrWorld::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitiMessaging::Init(_EXTRA=_extra)) then $
        return, 0

    if (self->IDLgrModel::Init(_EXTRA=_extra, $
        DEPTH_TEST_FUNCTION=4, $   ; "Less than or equal to"
        NAME="WORLD") ne 1) then $
        RETURN, 0

    if (self->_IDLitContainer::Init(CLASSNAME='IDLgrModel') ne 1) then begin
        self->Cleanup
        return, 0
    endif

    self.isInit = 1b
    self.geomRefCount = 0UL

    ; No property descriptors to register.

    RETURN, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::Cleanup
;
; PURPOSE:
;    Performs all cleanup for an IDLitgrWorld object.
;
; CALLING SEQUENCE:
;    OBJ_DESTROY, oWorld
;
;        or
;
;    oWorld->[IDLitgrWorld::]Cleanup
;
;-
pro IDLitgrWorld::Cleanup
    compile_opt idl2, hidden

    ; Note: Contained lights and dataspace root will be automatically
    ; cleaned up by the IDLgrModel::Cleanup.

    ; Cleanup superclasses.
    self->IDLgrModel::Cleanup
    self->_IDLitcontainer::Cleanup
    ; Note: IDLitSelectParent and IDLitIMessaging superclases do not
    ;   have a ::Cleanup method.
end

;----------------------------------------------------------------------------
; IIDLWorld Interface
;----------------------------------------------------------------------------
;; IDLitgrWorldSetProperty
;;
;; Purpose:
;;  Used to manage the _PARENT property of items this contains.

pro IDLitgrWorld::SetProperty, _PARENT=oParent, _EXTRA=_eXTRA

    compile_opt idl2, hidden

   if(n_elements(oParent) gt 0 and OBJ_VALID(oParent))then begin
       oItems = self->Get(/all, COUNT=count)
       for i=0, count-1 do $
           oItems[i]->IDLitComponent::SetProperty, _PARENT=oParent

   endif

   if(n_elements(_EXTRA) gt 0)then $
     self->IDLgrModel::SetProperty , _EXTRA=_EXTRA
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::Add
;
; PURPOSE:
;    Adds the given object(s) to the World's graphics hierarchy.
;
; CALLING SEQUENCE:
;    oWorld->Add, oObjects
;
; INPUTS:
;    oObjects: A reference (or vector of references) to the object(s)
;        to be added to the World's graphics hierarchy.
;        _IDLitVisualizations are added to the DataSpace; other objects
;        are simply added to the World.
;
;-
pro IDLitgrWorld::Add, oObjects, grParam, GROUP=groupIn, _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(oObjects) eq 0) then $
        RETURN

    group = (N_PARAMS() eq 2) ? grParam : 0
    if (N_ELEMENTS(groupIn) gt 0) then $
        group = KEYWORD_SET(groupIn)


    ; Determine where to add the objects.
    isVis = OBJ_ISA(oObjects, "_IDLitVisualization")
    isLight = OBJ_ISA(oObjects, "IDLitVisLight")
    iVis = WHERE(isVis and ~isLight, nVis)


    ; Add all visualizations to the dataspace root.
    if (nVis gt 0) then begin
        if (~OBJ_VALID(self.oDataSpaceRoot)) then begin
            if (~self->InitDataSpaces()) then $
                return
        endif
        self.oDataSpaceRoot->Add, oObjects[iVis], GROUP=group, _EXTRA=_extra
    endif


    ; Add all lights to the light container.
    iLight = WHERE(isLight, nLights)
    if (nLights gt 0) then begin
        ; If necessary, create a model to contain all of the lights.
        self->_CreateLightModel
        self.isInit = 0b  ; Don't create default lights.
        self.oLightModel->Add, oObjects[iLight], /AGGREGATE, _EXTRA=_extra
    endif


    ; Add all non-visualization objects to the model.
    iNonVis = WHERE(~isVis, nNonVis)
    if (nNonVis gt 0) then begin
        self->IDLgrModel::Add, oObjects[iNonVis], _EXTRA=_extra
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::Remove
;
; PURPOSE:
;    Removes the given object(s) from the World's graphics
;    hierarchy.
;
; CALLING SEQUENCE:
;    oWorld->Remove[, oObjects | /ALL]
;
; INPUTS:
;    oObject: A reference (or vector of references) to the
;        _IDLitVisualization(s) to be removed from the World's graphics
;        hierarchy.
;        _IDLitVisualizations are removed from the DataSpace; other objects
;        are simply removed from the World.
;
;-
pro IDLitgrWorld::Remove, oObjects, ALL=all

    compile_opt idl2, hidden

    oDataSpace = self->IDLgrModel::Get(/ALL)


    for i=0,N_ELEMENTS(oDataSpace)-1 do begin

        if (OBJ_VALID(oDataSpace[i])) then begin
            if OBJ_ISA(oDataSpace[i], 'IDL_Container') then $
                oDataSpace[i]->Remove, oObjects, ALL=all
        endif else begin
            ; Remove null objects from myself.
            self->IDLgrModel::Remove, oDataSpace[i]
        endelse

    endfor

    ; The Light Container cannot be removed from the world.
    iGood = WHERE(oObjects ne self.oLightModel, nGood, $
        NCOMPLEMENT=nLightContainer)

    if (nGood gt 0) then $
        self->IDLgrModel::Remove, oObjects[iGood], ALL=all

    if (nLightContainer gt 0) then begin
        self->ErrorMessage, $
            IDLitLangCatQuery('Error:Framework:MustHaveLight'), $
            SEVERITY=2, TITLE=IDLitLangCatQuery('Error:Delete:Title')
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::InitDataSpaces
;
; PURPOSE:
;    Initializes the dataspaces for this world.
;
; CALLING SEQUENCE:
;    Result = oWorld->[IDLitgrWorld::]InitDataSpaces()
;
; OUTPUTS:
;    This function method returns a 1 on success, or 0 otherwise.
;
;-
function IDLitgrWorld::InitDataSpaces

    compile_opt idl2, hidden

    ; If the dataspace root is already ready, return quickly with success.
    if (OBJ_VALID(self.oDataSpaceRoot)) then $
        return, 1

    ; Create the root container of dataspaces.
    self.oDataSpaceRoot = OBJ_NEW('IDLitVisDataSpaceRoot', $
                                  TOOL=self->GetTool()) ;; pass tool down

    if (~OBJ_VALID(self.oDataSpaceRoot)) then $
        return, 0

    ; Add the dataspace container to self.
    self->IDLgrModel::Add, self.oDataSpaceRoot

    ; Set the _PARENT of the dataspace container to self's parent.
    self->IDLgrModel::GetProperty, _PARENT=_worldParent
    self.oDataSpaceRoot->SetProperty, _PARENT=_worldParent

    return, 1
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::_GetDataSpaceRoot
;
; PURPOSE:
;    Undocumented method to retrieve the DataspaceRoot from within the World.
;    Required for IDLitgrLayer::Init.
;
; CALLING SEQUENCE:
;    oDataSpaceRoot = oWorld->[IDLitgrWorld::]_GetDataSpaceRoot()
;
; OUTPUTS:
;    This function method returns a reference to an object
;    that inherits from IDLitVisDataSpaceRoot.
;
;-
function IDLitgrWorld::_GetDataSpaceRoot

    compile_opt idl2, hidden

    ; Check if the dataspace root has been instantiated.  If not,
    ; create it.
    if (~OBJ_VALID(self.oDataSpaceRoot)) then begin
        if (~self->InitDataSpaces()) then $
            return, OBJ_NEW()
    endif

    return, self.oDataSpaceRoot
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::GetCurrentDataSpace
;
; PURPOSE:
;    Retrieves the currently active DataSpace from within the World.
;
; CALLING SEQUENCE:
;    oDataSpace = oWorld->[IDLitgrWorld::]GetCurrentDataSpace()
;
; OUTPUTS:
;    This function method returns a reference to an object
;    that inherits from IDLitVisIDataSpace.
;
;-
function IDLitgrWorld::GetCurrentDataSpace

    compile_opt idl2, hidden

    ; Check if the dataspace root has been instantiated.  If not,
    ; create it.
    if (~OBJ_VALID(self.oDataSpaceRoot)) then begin
        if (~self->InitDataSpaces()) then $
            return, OBJ_NEW()
    endif

    ; Return the current dataspace within the root container.
    return, self.oDataSpaceRoot->GetCurrentDataSpace()
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::SetCurrentDataSpace
;
; PURPOSE:
;    Sets the given dataspace as the currently active dataspace associated
;    with this world.
;
; CALLING SEQUENCE:
;    oWorld->[IDLitgrWorld::]SetCurrentDataspace, DataSpace
;
; INPUTS:
;    DataSpace: A reference to an IDLitVisIDataSpace that is to become
;      the current dataspace within this layer.
;-
pro IDLitGrWorld::SetCurrentDataSpace, oDataSpace

    compile_opt idl2, hidden

    ; Check if the dataspace root has been instantiated.  If not,
    ; then the dataspace must not be contained, and so cannot
    ; be set to current.
    if (~OBJ_VALID(self.oDataSpaceRoot)) then $
        return

    ; Pass along to the dataspace root.
    self.oDataSpaceRoot->SetCurrentDataSpace, oDataSpace
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::GetDataSpaces
;
; PURPOSE:
;    This function method retrieves the list of dataspaces contained by the
;    dataspace root within this world.
;
; CALLING SEQUENCE:
;    Result = oWorld->[IDLitgrWorld::]GetDataspaces()
;
; OUTPUTS:
;    This function returns a vector of references to IDLitVisIDataSpace
;    objects contained by the dataspace root within this world.
;
; KEYWORDS:
;    COUNT: Set this keyword to a named variable that upon return will
;      contain the number of dataspaces returned.
;
;-
function IDLitGrWorld::GetDataSpaces, COUNT=count

    compile_opt idl2, hidden

    count = 0
    if (OBJ_VALID(self.oDataSpaceRoot) eq 0) then $
        return, OBJ_NEW()

    ; Return list from dataspace root.
    return, self.oDataSpaceRoot->IDLgrModel::Get(/ALL, $
        ISA='IDLitVisIDataSpace', COUNT=count)
end



;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::OnDataChange
;
; PURPOSE:
;    The IDLitgrWorld::OnDataChange procedure method handles
;    notification of pending data changes within the contained
;    visualization hierarchy.
;
; CALLING SEQUENCE:
;    oWorld->[IDLitgrWorld::]OnDataChange, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
;-
pro IDLitgrWorld::OnDataChange, oNotifier

    compile_opt idl2, hidden

    ; Increment reference count.
    self.geomRefCount = self.geomRefCount + 1

    self->IDLgrModel::GetProperty, PARENT=oViewLayer
    if (OBJ_VALID(oViewLayer) ne 0) then begin
        ; If this is the first notification, notify parent view layer.
        if (self.geomRefCount eq 1) then $
            oViewLayer->OnDataChange, oNotifier
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWorld::OnDataComplete
;
; PURPOSE:
;    The IDLitgrWorld::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oWorld->[IDLitgrWorld::]OnDataComplete, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data flush.
;
;-
pro IDLitgrWorld::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    ; Decrement the reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount = self.geomRefCount - 1


    ; Return if we aren't ready to flush.
    if (self.geomRefCount gt 0) then $
        return

    ; If all children have reported in that they are ready to
    ; flush, then the reference count should be zero and the
    ; world can be flushed.

    ; Simply notify parent.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent)) then $
        oParent->OnDataComplete, oNotifier
end

;----------------------------------------------------------------------------
; Dimension Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrWorld::OnDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of a contained object has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitGrWorld::]OnDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro IDLitGrWorld::OnDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    if (oSubject eq self.oDataSpaceRoot) then begin
        ; Update lights.
        self->UpdateLights, is3D

        ; Notify parent.
        self->IDLgrModel::GetProperty, PARENT=oLayer
        oLayer->OnDimensionChange, self, is3D

        ; Send notification back down the tree that the
        ; world dimensionality has changed.
        self.oDataSpaceRoot->OnWorldDimensionChange, self, is3D
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrWorld::OnAxesRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesRequestChange implementation
;   so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitgrWorld:]OnAxesRequestChange, Subject, axesRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes request change.
;   axesRequest: new axes request setting of Subject.
;-
pro IDLitgrWorld::OnAxesRequestChange, oSubject, axesRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrWorld::OnAxesStyleRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes style request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesStyleRequestChange
;   implementation so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitGrWorld:]OnAxesStyleRequestChange, Subject, styleRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes style request change.
;   styleRequest: new style request setting of Subject.
;-
pro IDLitGrWorld::OnAxesStyleRequestChange, oSubject, styleRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLiGrWorld::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitGrWorld::]GetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::GetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitGrWorld::Init followed by the word "Get" can be retrieved
;   using IDLitGrWorld::GetProperty.
;-
pro IDLitGrWorld::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->_IDLitContainer::GetProperty, _EXTRA=_extra
        self->IDLgrModel::GetProperty, _EXTRA=_extra
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrWorld::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitGrWorld::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitGrWorld::Init followed by the word "Set" can be retrieved
;   using IDLitGrWorld::SetProperty.
;-
pro IDLitGrWorld::SetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->_IDLitContainer::SetProperty, _EXTRA=_extra
        self->IDLgrModel::SetProperty, _EXTRA=_extra
    endif
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitgrWorld__Define
;
; Purpose:
;     Defines the object structure for an IDLitgrWorld object.
;
;-
pro IDLitgrWorld__define
    compile_opt idl2, hidden

    struct = {IDLitgrWorld,         $
        inherits _IDLitContainer,   $ ; Superclass: _IDLitContainer
        inherits IDLgrModel,        $ ; Superclass: IDLgrModel
        inherits IDLitSelectParent, $ ; Superclass: IDLitSelectParent
        inherits IDLitIMessaging,   $ ; Superclass: IDLitMessaging
        oLightModel: OBJ_NEW(),     $ ; Container for lights
        isInit: 0b,                  $ ; Number of instantiated lights
        oDataSpaceRoot: OBJ_NEW(),  $ ; Root container of dataspaces
        geomRefCount: 0UL           $ ; Reference count for data changes
    }
end
