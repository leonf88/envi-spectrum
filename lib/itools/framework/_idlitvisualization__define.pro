; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitvisualization__define.pro#2 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitVisualization
;
; PURPOSE:
;   This class represents a collection of graphics and/or other
;   visualizations that as a group serve as a visual
;   representation for data.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Init
;
; PURPOSE:
;   This function method initializes the component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('_IDLitVisualization')
;
;    or
;
;   Obj->[_IDLitVisualization::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses. In addtion, the following keywords
;   are supported:
;
;   CENTER_OF_ROTATION (Get, Set): Set this keyword to a 2- or 3-element
;     vector ([x,y] or [x,y,z]) to indicate this object's center of
;     rotation.  By default, the center of rotation is automatically
;     computed as the center of this object's bounding box.
;
;   IMPACTS_RANGE (Get, Set): Set this keyword to a zero value to indicate
;     that this object should not impact the range of any dataspace that
;     contains it.  By default, this object will impact the range.
;
;   ISOTROPIC (Get, Set): Set this keyword to a nonzero value to indicate
;     that this object should have isotropic scaling applied to it.  By
;     default, isotropic scaling is not enforced.
;
;   MANIPULATOR_TARGET (Get, Set): Set this keyword to a nonzero value
;     to indicate that this object should be treated as the target for
;     manipulations.  By default, this object is not a target for
;     manipulations.
;
;   _PARENT (Set): Set this keyword to a reference to the object to
;     be treated as the logical parent of this object.
;
;   TYPE (Set): Set this keyword to a string or vector of strings
;     representing the type(s) of visualization that this object
;     represents.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function _IDLitVisualization::Init, $
                            REGISTER_PROPERTIES=registerIn, $
                            _REF_EXTRA=_extra

    compile_opt idl2, hidden

    status = self->IDLitIMessaging::Init(_extra=_extra)

    register = N_ELEMENTS(registerIn) ? KEYWORD_SET(registerIn) : 1

    ; Initialize superclasses.
    if (self->_IDLitPropertyAggregate::Init(_EXTRA=_extra) ne 1) then $
        return, 0
    if (self->IDLgrModel::Init(REGISTER_PROPERTIES=register, LIGHTING=0) $
        ne 1) then begin
        self->Cleanup
        return, 0
    endif
    if (self->_IDLitContainer::Init(CLASSNAME='IDLgrModel') ne 1) then begin
        self->Cleanup
        return, 0
    endif

    ; Set my defaults.
    self.geomRefCount = 0
    self.impactsRange = 1
    self.dimMethod = 2  ; auto-compute 3D setting based on contents
    self.axesMethod = 1 ; always request axes
    self.axesRequest = 1b
    self.doRequestAxesStyle = 0b ; Do not request a particular axes style.
    self.axesStyleRequest = 0 ; If a particular axes style were requested,
                              ; request style 0 (None).
    self._pStrType = PTR_NEW('')
    self->SetPropertyAttribute, 'DESCRIPTION', /HIDE

    ; Set any properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Cleanup
;
; PURPOSE:
;   This procedure method performs all cleanup on the object.
;
;   NOTE: Cleanup methods are special lifecycle methods, and as such
;   cannot be called outside the context of object destruction.  This
;   means that in most cases, you cannot call the Cleanup method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Cleanup method
;   from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[_IDLitVisualization::]Cleanup
;
;-
pro _IDLitVisualization::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->_IDLitPropertyAggregate::Cleanup
    self->IDLgrModel::Cleanup
    self->_IDLitContainer::Cleanup

    PTR_FREE, self._pStrType

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Create
;
; PURPOSE:
;   This function method initializes any heavyweight portions of this
;   visualization.  [Note: the bare essentials for the object are initialized
;   within the ::Init method.]
;
; CALLING SEQUENCE:
;   status = Obj->[_IDLitVisualization::]Create()
;
; OUTPUTS:
;   This function returns a 1 on success, or 0 on failure.
;
;-
function _IDLitVisualization::Create
    compile_opt idl2, hidden
    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Shutdown
;
; PURPOSE:
;   This procedure method cleans up the the heavyweight portion of the
;   object, leaving only the bare essential portions of the object
;   (that may be cleaned up via the ::Cleanup method).
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Shutdown
;
;-
pro _IDLitVisualization::Shutdown
    compile_opt idl2, hidden
end

;----------------------------------------------------------------------------
; _IDLitVisualization::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro _IDLitVisualization::Restore
    compile_opt idl2, hidden

    ; Call superclass' restores.

    ; self->_IDLitContainer::Restore
    ; self->_IDLitPropertyAggregate::Restore
    ; self->IDLgrModel::Restore
    ; self->IDLitSelectParent::Restore
    ; self->IDLitIMessaging::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request axes by default.
        self.axesRequest = 1 ; Request axes
        self.axesMethod = 1 ; Always request axes
        self.doRequestAxesStyle = 0b ; Do not request a particular axes style.
        self.axesStyleRequest = 0 ; If a particular axes style were requested,
                                  ; request style 0 (None).
    endif
end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]GetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::GetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   _IDLitVisualization::Init followed by the word "Get" can be retrieved
;   using _IDLitVisualization::GetProperty.  In addition, the following
;   keywords are accepted:
;
;   GROUP_PARENT:   Set this keyword to a named variable that upon
;   return will contain a reference to the IDLitVisualization object
;       that serves as the group parent for this visualization.
;
;-
pro _IDLitVisualization::GetProperty, $
    CENTER_OF_ROTATION=centerRotation, $
    IMPACTS_RANGE=impactsRange, $
    GROUP_PARENT=groupParent, $
    ISOTROPIC=isotropic, $
    MANIPULATOR_TARGET=manipulatorTarget, $
    SELECTION_PAD=selectionPad, $
    NAME=name, $  ; specify these explicitely so we don't get in Aggregate
    DESCRIPTION=description, $
    HIDE=hide, $
    ICON=iconType, $
    IDENTIFIER=identifier, $
    LIGHTING=lighting, $
    MOUSE_MOTION_HANDLER=mMotionHandler, $
    MOUSE_BUTTON_HANDLER=mButtonHandler, $
    PARENT=parent, $
    SELECT_TARGET=selectTarget, $
    TRANSFORM=transform, $
    TYPE=type, $
    _CREATED_IN_INIT=_created_in_init, $ ;; flag to mark this created during init
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    if ARG_PRESENT(centerRotation) then $
        centerRotation = self->GetCenterRotation(/NO_TRANSFORM)

    if ARG_PRESENT(impactsRange) then $
        impactsRange = self.impactsRange

    if ARG_PRESENT(isotropic) then $
        isotropic = self.isotropic

    if ARG_PRESENT(groupParent) then $
        groupParent = self.oGroupParent

    if ARG_PRESENT(selectionPad) then $
        selectionPad = self._selectionPad

    if ARG_PRESENT(type) then $
        type = *self._pStrType

    ; Look these up directly, so we don't do thru aggregate.
    if ARG_PRESENT(name) then $
        self->IDLgrModel::GetProperty, NAME=name

    if ARG_PRESENT(description) then $
        self->IDLgrModel::GetProperty, DESCRIPTION=description

    if ARG_PRESENT(hide) then $
        self->IDLgrModel::GetProperty, HIDE=hide

    if ARG_PRESENT(iconType) then $
        self->IDLgrModel::GetProperty, ICON=iconType

    if ARG_PRESENT(identifier) then $
        self->IDLgrModel::GetProperty, IDENTIFIER=identifier

    if ARG_PRESENT(lighting) then $
        self->IDLgrModel::GetProperty, LIGHTING=lighting

    if (ARG_PRESENT(mMotionHandler)) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then $
        oTool->GetProperty, MOUSE_MOTION_HANDLER=mMotionHandler
    endif
    
    if (ARG_PRESENT(mButtonHandler)) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then $
        oTool->GetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler
    endif
    
    if ARG_PRESENT(parent) then $
        self->IDLgrModel::GetProperty, PARENT=parent

    if ARG_PRESENT(selectTarget) then $
        self->IDLgrModel::GetProperty, SELECT_TARGET=selectTarget

    if ARG_PRESENT(transform) then $
        self->IDLgrModel::GetProperty, TRANSFORM=transform

    if (ARG_PRESENT(manipulatorTarget)) then $
        manipulatorTarget = self.isManipulatorTarget

    ;; This is an internal flag to mark visualizations that are
    ;; created in the init method of other visualizations. This is
    ;; used by the clipboard to determine what to replicate.
    if (ARG_PRESENT(_created_in_init))then $
      _created_in_init = self._createdDuringInit

    ; Get superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->GetAggregateProperty, _EXTRA=_extra
        self->IDLgrModel::GetProperty, _EXTRA=_extra
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   _IDLitVisualization::Init followed by the word "Set" can be retrieved
;   using _IDLitVisualization::SetProperty.
;-
pro _IDLitVisualization::SetProperty, $
    CENTER_OF_ROTATION=center_of_rotation, $
    IMPACTS_RANGE=impactsRange, $
    GROUP_PARENT=groupParent, $
    ISOTROPIC=isotropic, $
    MANIPULATOR_TARGET=manipulatorTarget, $
    SELECTION_PAD=selectionPad, $
    NAME=name, $  ; specify these explicitely so we don't set in Aggregate
    _PARENT=_parent, $
    DESCRIPTION=description, $
    HELP=help, $
    HIDE=hide, $
    ICON=iconType, $
    IDENTIFIER=identifier, $
    LIGHTING=lighting, $
    MOUSE_MOTION_HANDLER=mMotionHandler, $
    MOUSE_BUTTON_HANDLER=mButtonHandler, $
    SELECT_TARGET=selectTarget, $
    TRANSFORM=transform, $
    TYPE=type, $
    TOOL=swallow, $  ; should only be set in Init or via _SetTool
    _CREATED_IN_INIT=_created_in_init, $ ;; flag to mark this created during init
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

; @idlit_on_error2

    nRot = N_ELEMENTS(center_of_rotation)
    if (nRot gt 0) then begin
        if ((nRot lt 2) or (nRot gt 3)) then begin
            self->ErrorMessage, $
              IDLitLangCatQuery('Error:Framework:CORInvalid'), $
              severity=1
            return
        endif
        self.centerRotation = DOUBLE(center_of_rotation)
        self.iHaveCenterRotation = 1
    endif

    if (N_ELEMENTS(impactsRange) gt 0) then $
        self.impactsRange = KEYWORD_SET(impactsRange)

    if (N_ELEMENTS(isotropic) gt 0) then $
        self.isotropic = KEYWORD_SET(isotropic)

    if (N_ELEMENTS(groupParent) gt 0) then $
        self.oGroupParent = groupParent

    if (N_ELEMENTS(manipulatorTarget) gt 0) then $
        self.isManipulatorTarget = KEYWORD_SET(manipulatorTarget)

    if (N_ELEMENTS(mMotionHandler) eq 1) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then $
        oTool->SetProperty, MOUSE_MOTION_HANDLER=mMotionHandler
    endif
    
    if (N_ELEMENTS(mButtonHandler) eq 1) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then $
        oTool->SetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler
    endif
    
    if N_ELEMENTS(selectionPad) then $
        self._selectionPad = selectionPad

    if (N_ELEMENTS(type) ne 0) then begin
        ; Only allow non-empty strings.
        nValid = 0
        for i=0,N_ELEMENTS(type)-1 do begin
            if (type[i]) then begin
                validTypes = (nValid gt 0) ? [validTypes, type[i]] : [type[i]]
                nValid++
            endif
        endfor
        *self._pStrType = (nValid gt 0) ? validTypes : ''
    endif

    ;; This is an internal flag to mark visualizations that are
    ;; created in the init method of other visualizations. This is
    ;; used by the clipboard to determine what to replicate.
    if(n_elements(_created_in_init) gt 0)then $
      self._createdDuringInit = keyword_set(_created_in_init)

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->SetAggregateProperty, _EXTRA=_extra

    self->IDLgrModel::SetProperty, $
        _PARENT=_parent, $
        NAME=name, $
        HIDE=hide, $
        DESCRIPTION=description, $
        HELP=help, $
        ICON=iconType, $
        IDENTIFIER=identifier, $
        LIGHTING=lighting, $
        SELECT_TARGET=selectTarget, $
        TRANSFORM=transform, $
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Container Interface
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Add
;
; PURPOSE:
;   This procedure method adds the given object(s) to this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Add, Object
;
; INPUTS:
;   Object: A reference (or vector of references) to the object(s)
;     to be added to this visualization.
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Add methods
;   of this object's superclasses.  In addition, the following keywords
;   are supported:
;
;   AGGREGATE:  Set this keyword to a non-zero value to indicate that
;     the object(s) being added should become part of this visualization's
;     property aggregate.   The properties of all aggregated objects are
;     exposed as properties of this visualization (accessible via the
;     ::GetProperty and ::SetProperty methods).  By default, the added
;     objects does not become part of this visualization's property aggregate.
;
;   GROUP:  Set this keyword to a non-zero value to indicate that
;     the added object is to be considered part of the group that is
;     rooted at this visualization.  By default, the added objects are
;     not considered to be part of the group.
;
;   NO_UPDATE:   Set this keyword to a nonzero value to indicate that
;     an update of the overall scene should not occur after the addition
;     of the object(s).  By default, an update of the overall scene is
;     performed.
;
;   USE__PARENT:    Set this keyword to a non-zero value to indicate
;     that the _PARENT property of the added objects should be set
;     to the value of the _PARENT property of this visualization.
;
; SIDE EFFECTS:
;   If any of the added objects is isotropic, the isotropy setting for
;   this visualization is set accordingly.
;
;   The _PARENT property for each added object will be set (refer to
;   the USE__PARENT keyword).
;
;   Unless the NO_UPDATE keyword is set, the scene will be updated after
;   the object(s) have been added.
;-
pro _IDLitVisualization::Add, oVis, $
    AGGREGATE=aggregate, $
    GROUP=GROUP, $
    NO_UPDATE=noUpdate, $
    POSITION=position, $
    USE__PARENT=USE__PARENT, $
    _EXTRA=_EXTRA

    compile_opt idl2, hidden

    ; Keep all the manipulator visuals at the end.
    if (N_ELEMENTS(position) eq 0) then begin
        ; If not a manipulator visual, insert near the end of the container,
        ; but before all of the manipulator visuals.
        ; If it is a manipulator visual, just insert at the end.
        if (~OBJ_ISA(oVis[0], "IDLitManipulatorVisual")) then begin
            oManipVis = self->_IDLitContainer::Get( $
                ISA='IDLitManipulatorVisual', /ALL, COUNT=count)
            if (count gt 0) then begin
                ; Using Add with position equal to the first manipulator
                ; visual will insert the new vis just before the manip visual.
                dummy = self->IsContained(oManipVis[0], POSITION=position)
                position = LINDGEN(N_ELEMENTS(oVis)) + position
            endif
        endif
    endif


    ; Add to our container (actually to IDLgrModel)
    self->_IDLitContainer::Add, oVis, POSITION=position, $
        _EXTRA=_EXTRA, USE__PARENT=USE__PARENT

    if (keyword_set(GROUP)) then $
        self->_IDLitVisualization::Group, oVis

    if (KEYWORD_SET(aggregate)) then $
        self->Aggregate, oVis

    ; Update the 3D flag as necessary.
    if (self.dimMethod eq 2) then $
        self->_CheckDimensionChange

    ; Update axes request as necessary.
    if (self.axesMethod eq 2) then $
        self->_CheckAxesRequestChange

    bHaveAxesStyle = 0b
    oTool = self->GetTool()

    for i=0,N_ELEMENTS(oVis)-1 do begin

        if (OBJ_ISA(oVis[i],"_IDLitVisualization")) then begin

            ; Sanity check. Set the tool for all our children.
            ; This is useful if the children have been "manually" created
            ; with obj_new() and added to ourself.
            if (OBJ_VALID(oTool)) then $
                oVis[i]->_SetTool, oTool

            ; If our child is private, add to GROUP automatically.
            if (~keyword_set(GROUP)) then begin
                oVis[i]->IDLitComponent::GetProperty, PRIVATE=private
                if (private) then $
                    self->_IDLitVisualization::Group, oVis[i]
            endif

            ; Determine if any of the added items requests a particular type
            ; of axes style,
            if (~bHaveAxesStyle) then begin
                axesStyle = oVis[i]->GetRequestedAxesStyle()
                if (axesStyle ge 0) then begin
                    oAxesStyleVis = oVis[i]
                    bHaveAxesStyle = 1b
                endif
            endif

            ; Update the isotropy flag.
            if oVis[i]->IsIsotropic() then $
              self.isotropic = 1b
        endif
    endfor

    ; Send notification of any potential axes style change.
    if (bHaveAxesStyle) then $
        self->OnAxesStyleRequestChange, oAxesStyleVis, axesStyle

    if (~KEYWORD_SET(noUpdate)) then $
        self->UpdateScene

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Move
;
; PURPOSE:
;   Override the move method so we can keep the
;   manipulator visuals at the end.
;
pro _IDLitVisualization::Move, oldPosition, newPositionIn

    compile_opt idl2, hidden

    newPosition = newPositionIn

    ; If not a manipulator visual, be sure to in all of the manipulator visuals.
    ; If it is a manipulator visual, just insert at the end.
    oManipVis = self->_IDLitContainer::Get( $
        ISA='IDLitManipulatorVisual', /ALL, COUNT=count)
    if (count gt 0) then begin
        dummy = self->IsContained(oManipVis[0], POSITION=position)
        oMove = self->_IDLitContainer::Get(POSITION=oldPosition)
        if (OBJ_ISA(oMove, 'IDLitManipulatorVisual')) then begin
            newPosition = newPosition > position
        endif else begin
            newPosition = 0 > newPosition < (position - 1)
        endelse
    endif

    if (oldPosition eq newPosition) then $
        return

    ; Move within our container.
    self->_IDLitContainer::Move, oldPosition, newPosition

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Remove
;
; PURPOSE:
;   This procedure method removes the given object(s) from this
;   visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Remove, Object
;
; INPUTS:
;   Object: A reference (or vector of references) to the object(s)
;     to be removed from this visualization.
;
; KEYWORD PARAMETERS:
;   NO_UPDATE:   Set this keyword to a nonzero value to indicate that
;     an update of the overall scene should not occur after the removal
;     of the object(s).  By default, an update of the overall scene is
;     performed.
;
;   This method accepts all keywords supported by the ::Remove methods
;   of this object's superclasses.
;
; SIDE EFFECTS:
;   Unless the NO_UPDATE keyword is set, the scene will be updated after
;   the object(s) have been removed.
;-
pro _IDLitVisualization::Remove, oVis, $
    NO_UPDATE=noUpdate, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Luckily, IDL_Container::Remove doesn't complain if the objrefs
    ; aren't actually contained. So just blindly call our superclasses.
    ;
    if (N_PARAMS() eq 1) then begin
        self->RemoveAggregate, oVis, _EXTRA=_extra
        self->_IDLitContainer::Remove, oVis, _EXTRA=_extra
    endif else begin
        self->RemoveAggregate, _EXTRA=_extra
        self->_IDLitContainer::Remove, _EXTRA=_extra
    endelse


    if (~KEYWORD_SET(noUpdate)) then begin

        ; Update the 3D flag as necessary.
        if (self.dimMethod eq 2) then $
            self->_CheckDimensionChange

        ; Update the axes request flag as necessary.
        if (self.axesMethod eq 2) then $
            self->_CheckAxesRequestChange

        self->UpdateScene
    endif

end

;---------------------------------------------------------------------------
; Grouping Interface
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Group
;
; PURPOSE:
;   This procedure method marks the given object(s) as being part of
;   the group that is rooted at this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Group, Object
;
; INPUTS:
;   Object: A reference (or vector of references) to the object(s)
;     to be marked as being part of the group that is rooted at this
;     visualization.
;
;-
pro _IDLitVisualization::Group, oVis

    compile_opt idl2, hidden

    for i=0, n_elements(oVis)-1 do begin
        if (OBJ_VALID(oVis[i])) then $
            oVis[i]->_IDLitVisualization::SetProperty, GROUP_PARENT=self
    endfor

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::UnGroup
;
; PURPOSE:
;   This procedure method marks the given object(s) as no longer
;   belonging to the group that is rooted at this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]UnGroup, Object
;
; INPUTS:
;   Object: A reference (or vector of references) to the object(s)
;     that are no longer to be considered part of the group that is rooted
;     at this visualization.
;
;-
pro _IDLitVisualization::UnGroup, oVis

    compile_opt idl2, hidden

    isContained = self->IsContained(oVis)
    iOK = WHERE(isContained eq 1, nGood)

    for i=0, nGood-1 do $
        oVis[iOk[i]]->_IDLitVisualization::SetProperty, GROUP_PARENT=obj_new()
end


;---------------------------------------------------------------------------
; Property Aggregation Interface
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Aggregate
;
; PURPOSE:
;   This procedure method adds the given object(s) to this visualization's
;   property aggregate.  The properties of all aggregated objects are
;     exposed as properties of this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Aggregate, Object
;
; INPUTS:
;   Object: A reference (or vector of references) to the object(s)
;     to be added to this visualization's property aggregate.
;
;-
pro _IDLitVisualization::Aggregate, oVis

    compile_opt idl2, hidden

    isValid = WHERE(OBJ_VALID(oVis) ne 0, nValid)
    if (nValid eq 0) then return
    oValid = oVis[isValid]

    self->AddAggregate, oValid
end


;----------------------------------------------------------------------------
; _Visualization Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::_GetWindowandViewG
;
; PURPOSE:
;   This function method is used to retrieve the IDLitgrView and IDLitWindow
;   within which this visualization appears.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]_GetWindowandViewG, Win, View
;
; INPUTS:
;   Win:    A named variable that upon return will contain a reference
;     to the window object within which this visualization appears.
;   View:   A named variable that upon return will contain a reference
;     to the view object within which this visualization appears.
;
; OUTPUTS:
;   This function returns 1 if retrieval of the view and window were
;   successful, or 0 otherwise.
;
;-
function  _IDLitVisualization::_GetWindowandViewG, oWin, oView

   ; Pragmas
   compile_opt idl2, hidden

   ;; Walk our up our tree until you hit the view and scene
   ;; We depend on the fact that the object hiearchy looks like:
   ;;     [IDLitWindow]
   ;;          |
   ;;     [IDLitgrScene]
   ;;          |
   ;;     [IDLitgrView]

    oParent = self
    while (not OBJ_ISA(oParent, "IDLitgrView")) do begin
        oParent[0]->IDLgrComponent::GetProperty, PARENT=oParent  ; use [0] to force temp
        if (not OBJ_VALID(oParent)) then $
            return, 0
    endwhile

    oView = oParent

    ; Get the IDLitgrScene
    oView->GetProperty, PARENT=oParent
    ; Check in case the view was removed from the scene.
    if (not OBJ_VALID(oParent)) then $
        return, 0

    ; Now the Window
    oParent->GetProperty, DESTINATION=oWin

    return, 1
end

;---------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::_GetLayer
;
; PURPOSE:
;   This function method retrieves the layer within which this
;   visualization appears.
;
; OUTPUTS:
;   This function returns a reference to the layer object within which
;   this visualization appears, or a null object if this visualization
;   is not currently within a layer.
;-
function  _IDLitVisualization::_GetLayer

    ; pragmas
    compile_opt idl2, hidden

    ; Walk our up the visualization tree until a layer is found.
    oParent = self
    while (~OBJ_ISA(oParent, "IDLitgrLayer")) do begin
        oParent[0]->IDLgrComponent::GetProperty, PARENT=oParent  ; use [0] to force temp
        if (~OBJ_VALID(oParent)) then $
            return, obj_new()
    endwhile

    return, oParent
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetCenterRotation
;
; PURPOSE:
;   This function method retrieves the center of rotation for this
;   visualization.
;
;   This function is provided for efficiency in the case that both the
;   center of rotation and the bounding box for this visualization
;   is needed.  (The default center of rotation depends upon the bounding
;   box.)
;
; CALLING SEQUENCE:
;   status = Obj->[_IDLitVisualization::]GetCenterRotation()
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by this object's
;   ::GetXYZRange method.  In addition, the following keywords are
;   supported:
;
;   XRANGE: Set this keyword to a named variable that upon return
;     will contain a 2-element vector, [xmin, xmax], representing the
;     X range of the bounding box for this visualization.
;   YRANGE: Set this keyword to a named variable that upon return
;     will contain a 2-element vector, [ymin, ymax], representing the
;     Y range of the bounding box for this visualization.
;   ZRANGE: Set this keyword to a named variable that upon return
;     will contain a 2-element vector, [zmin, zmax], representing the
;     Z range of the bounding box for this visualization.
;
; OUTPUTS:
;   This function returns a 2- or 3-element vector ([x,y] or [x,y,z])
;   representing the center of rotation.
;
;-
function _IDLitVisualization::GetCenterRotation, $
    XRANGE=xRange, $
    YRANGE=yRange, $
    ZRANGE=zRange, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; We will need to retrieve the Volume ranges if they are requested,
    ; or if we need to calculate the center of rotation ourself.
    if (ARG_PRESENT(xRange) or ARG_PRESENT(yRange) or ARG_PRESENT(zRange) $
        or (not self.iHaveCenterRotation)) then begin
        xRange = [0d, 0d]
        yRange = [0d, 0d]
        zRange = [0d, 0d]
        ; Retrieve the XYZ range. Be sure to use NO_TRANSFORM so
        ; we get the actual data range, rather than the transformed
        ; data range.
        success = self->GetXYZRange(xRange, yRange, zRange, $
            _EXTRA=_extra)
    endif

    ; Either return the stored center of rotation, or compute it.
    if self.iHaveCenterRotation then begin
        centerRotation = self.centerRotation
    endif else begin
        ; Center of rotation is just the centroid of the data range.
        centerRotation = $
            0.5*[xRange[0]+xRange[1], $
                 yRange[0]+yRange[1], $
                 zRange[0]+zRange[1]]
    endelse

    return, centerRotation
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::UpdateScene
;
; PURPOSE:
;   This procedure method triggers a notification that the scene
;   (in which this visualization appears) needs to be updated.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]UpdateScene
;
;-
pro _IDLitVisualization::UpdateScene
    compile_opt idl2, hidden
    self->IDLgrModel::GetProperty, PARENT=oParent
    if OBJ_VALID(oParent) then begin
       self->OnDataChange, oParent
       self->OnDataComplete, oParent
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::_AccumulateXYZRange
;
; PURPOSE:
;   This procedure method acumulates the given XYZ ranges into
;   the given XYZ ranges (if available).
;
;   This is an internal routine used by ::GetXYZRange.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]_AccumulateXYZRange, HaveAccum, $
;       OutXRange, OutYRange, OutZRange,
;       InXRange, InYRange, InZRange
;
; INPUTS:
;   HaveAccum:  A boolean indicating whether the input ranges are
;     to be accumulated with the given output ranges.  If this argument
;     is zero, then the output ranges will simply be set to the input
;     ranges (without accumulation).
;   OutXRange:  A named variable that upon return will contain a
;     2-element vector, [xmin, xmax], representing the accumulated
;     X range.
;   OutYRange:  A named variable that upon return will contain a
;     2-element vector, [ymin, ymax], representing the accumulated
;     Y range.
;   OutZRange:  A named variable that upon return will contain a
;     2-element vector, [zmin, zmax], representing the accumulated
;     Z range.
;   InXRange:   A 2-element vector, [xmin, xmax], representing the
;     X range to be accumulated into the OutXRange values.
;   InYRange:   A 2-element vector, [ymin, ymax], representing the
;     Y range to be accumulated into the OutXRange values.
;   InZRange:   A 2-element vector, [zmin, zmax], representing the
;     Z range to be accumulated into the OutXRange values.
;
; KEYWORD PARAMETERS:
;   TRANSFORM:  Set this keyword to a 4x4 transformation matrix that
;     will be used to transform the InX/Y/ZRange points.  By default,
;     the InX/Y/ZRange points are not transformed.
;-
pro _IDLitVisualization::_AccumulateXYZRange, $
    bHaveAccum, $
    outXRange, outYRange, outZRange, $
    inXRangeIn, inYRangeIn, inZRangeIn, $
    TRANSFORM=transform

    compile_opt idl2, hidden

    ; Sanity check for NaNs or Infinities.
    inXRange = inXRangeIn
    isFinite = FINITE(inXRange)
    if (~isFinite[0]) then $
        inXRange[0] = isFinite[1] ? inXRange[1] : 0
    if (~isFinite[1]) then $
        inXRange[1] = isFinite[0] ? inXRange[0] : 0

    inYRange = inYRangeIn
    isFinite = FINITE(inYRange)
    if (~isFinite[0]) then $
        inYRange[0] = isFinite[1] ? inYRange[1] : 0
    if (~isFinite[1]) then $
        inYRange[1] = isFinite[0] ? inYRange[0] : 0

    inZRange = inZRangeIn
    isFinite = FINITE(inZRange)
    if (~isFinite[0]) then $
        inZRange[0] = isFinite[1] ? inZRange[1] : 0
    if (~isFinite[1]) then $
        inZRange[1] = isFinite[0] ? inZRange[0] : 0

    if (N_ELEMENTS(transform) gt 0) then begin
        ; Apply model transform.
        p1 = [[inXRange[0],inXRange[1],inXRange[1],inXRange[0],  $
               inXRange[0],inXRange[1],inXRange[1],inXRange[0]], $
              [inYRange[0],inYRange[0],inYRange[1],inYRange[1],  $
               inYRange[0],inYRange[0],inYRange[1],inYRange[1]], $
              [inZRange[0],inZRange[0],inZRange[0],inZRange[0],  $
               inZRange[1],inZRange[1],inZRange[1],inZRange[1]], $
              [1.0,1.0,1.0,1.0, $
               1.0,1.0,1.0,1.0]]

        p1 = p1 # transform

        tmin = MIN(p1[*,0], MAX=tmax)
        inXRange = [tmin, tmax]
        tmin = MIN(p1[*,1], MAX=tmax)
        inYRange = [tmin, tmax]
        tmin = MIN(p1[*,2], MAX=tmax)
        inZRange = [tmin, tmax]
    endif

    ; Sanity check to prevent viz items which havn't had their
    ; data set yet from contributing to the data range.
    ; Prevents useless data range updates, where we set the data
    ; range based upon a zero range, and then set the range again
    ; once the data has been added.
    if (~inXRange[0] && ~inXRange[1] && ~inYRange[0] && $
        ~inYRange[1] && ~inZRange[0] && ~inZRange[1]) then $
        return

    ; Accumulate in overall  XYZ range.
    if (bHaveAccum eq 0) then begin
        outXRange = inXRange
        outYRange = inYRange
        outZRange = inZRange
        bHaveAccum = 1
    endif else begin
        outXRange = [(outXRange[0] < inXRange[0]), $
            (outXRange[1] > inXRange[1])]
        outYRange = [(outYRange[0] < inYRange[0]), $
            (outYRange[1] > inYRange[1])]
        outZRange = [(outZRange[0] < inZRange[0]), $
            (outZRange[1] > inZRange[1])]
    endelse
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetXYZRange
;
; PURPOSE:
;   This function method overrides the IDLgrModel::GetXYZRange function,
;   taking into account whether this Visualization impacts the ranges.
;
; CALLING SEQUENCE:
;   Success = Obj->[_IDLitVisualization::]GetXYZRange( $
;    xRange, yRange, zRange [, /DATA] [, /NO_TRANSFORM])
;
; INPUTS:
;   xRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [xmin, xmax], representing the
;     X range of the objects that impact the ranges.
;   yRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [ymin, ymax], representing the
;     Y range of the objects that impact the ranges.
;   zRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [zmin, zmax], representing the
;     Z range of the objects that impact the ranges.
;
; KEYWORD PARAMETERS:
;    DATA:  Set this keyword to a nonzero value to indicate that
;   the ranges should be computed for the full datasets of the
;   contents of this visualization.  By default (if the keyword is
;   not set), the ranges are computed for the visualized portions
;   of the data sets.
;    NO_TRANSFORM:  Set this keyword to indicate that this Visualization's
;       model transform should not be applied when computing the XYZ ranges.
;       By default, the transform is applied.
;
; OUTPUTS:
;   This function returns a 1 if retrieval of the XYZ ranges was
;   successful, or 0 otherwise.
;-
function _IDLitVisualization::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=bDataRange, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    ; Flags to indicate whether we have successfully retrieved ranges.
    success = 0

    ; Default return values.
    outxRange = [0.0d, 0.0d]
    outyRange = [0.0d, 0.0d]
    outzRange = [0.0d, 0.0d]

    ; Grab the transformation matrix.
    if (~KEYWORD_SET(noTransform)) then $
        self->IDLgrModel::GetProperty, TRANSFORM=transform

    ; Grab children.
    oObjList = self->IDL_Container::Get(/all, count=nObjs)

    ; Step through children, accumulating XYZ ranges.
    for i=0, nObjs-1 do begin
        oObj = oObjList[i]

        if OBJ_ISA(oObj, '_IDLitVisualization') then begin

            ; Determine whether these ranges should be counted.
            oObj->_IDLitVisualization::GetProperty, $
                IMPACTS_RANGE=impactsRange

            if (impactsRange) then begin
                impactsRange = oObj->GetXYZRange(xRange, yRange, zRange, $
                    DATA=bDataRange)
            endif

        endif else if OBJ_ISA(oObj, 'IDLgrModel') then begin

            impactsRange = oObj->GetXYZRange( xRange, $
                yRange, zRange, DATA=bDataRange )

        endif else if OBJ_ISA(oObj, 'IDLgrGraphic') then begin

            if (KEYWORD_SET(bDataRange)) then begin
                impactsRange = oObj->GetDataXYZRange(xRange, yRange, zRange)
                ; CT Note: Do not change this to IDLgrGraphic::GetProperty.
                ; Some objects (such as IDLgrContour) need the call
                ; to GetProperty to recompute ranges.
                oObj->GetProperty, $
                    XCOORD_CONV=xcc, YCOORD_CONV=ycc, ZCOORD_CONV=zcc
            endif else begin
                ; CT Note: Do not change this to IDLgrGraphic::GetProperty.
                ; Some objects (such as IDLgrContour) need the call
                ; to GetProperty to recompute ranges.
                oObj->GetProperty, $
                    XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange, $
                    XCOORD_CONV=xcc, YCOORD_CONV=ycc, ZCOORD_CONV=zcc

                ; Assume these ranges should be counted.
                impactsRange = 1
            endelse

            if (impactsRange) then begin
                ; Apply coordinate conversion.
                xRange = xRange * xcc[1] + xcc[0]
                yRange = yRange * ycc[1] + ycc[0]
                zRange = zRange * zcc[1] + zcc[0]
            endif

        endif

        ; For each XYZRange, apply transform if requested and
        ; accumulate into overall XYZ range if this object has any impact.

        ; -- XYZ Range -----------------------------------------------
        if (impactsRange) then begin
            self->_AccumulateXYZRange, success, $
                outxRange, outyRange, outzRange, $
                xRange, yRange, zRange, $
                TRANSFORM=transform
        endif

    endfor  ; children loop

    return, success
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetLonLatRange
;
; PURPOSE:
;   This function method retrieves the LonLat range of
;   contained visualizations.
;
; CALLING SEQUENCE:
;   Success = Obj->[_IDLitVisualization::]GetLonLatRange( $
;    lonRange, latRange)
;
; INPUTS:
;   lonRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [lonmin, lonmax], representing the
;     longitude range of the objects that impact the ranges.
;   latRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [latmin, latmax], representing the
;     latitude range of the objects that impact the ranges.
;
; KEYWORD PARAMETERS:
;    MAP_STRUCTURE: Optional input keyword that contains the current map
;       projection for the dataspace. This is just for efficiency.
;
; OUTPUTS:
;   This function returns a 1 if retrieval of the range was
;   successful, or 0 otherwise.
;-
function _IDLitVisualization::GetLonLatRange, lonRange, latRange, $
    MAP_STRUCTURE=sMap

    compile_opt idl2, hidden

    success = 0

    oVis = self->Get(/ALL, ISA='IDLitVisualization', COUNT=nVis)

    for i=0,nVis-1 do begin
        if (oVis[i]->GetLonLatRange(lonRange1, latRange1, $
            MAP_STRUCTURE=sMap)) then begin
            ; Success will be set to 1 if accum succeeded.
            self->_AccumulateXYZRange, success, $
                lonRange, latRange, outzRange, $
                lonRange1, latRange1, [0, 0]
        endif
    endfor

    return, success

end


;----------------------------------------------------------------------------
; _IDLitVisualization::SeekPixelatedVisualization
;
; Purpose:
;   This function method returns a reference to the first object
;   contained by this visualization that is a pixelated visualization.
;
function _IDLitVisualization::SeekPixelatedVisualization
    compile_opt idl2, hidden

    ; Step through children, seeking a pixelated visualization.
    oObjList = self->IDL_Container::Get(/all, count=nObjs)
    for i=0, nObjs-1 do begin
        oObj = oObjList[i]

        ; For now, only IDLitVisImage classes are pixelated.
        if (OBJ_ISA(oObj, 'IDLitVisImage')) then $
            return, oObj

        if (OBJ_ISA(oObj, '_IDLitVisualization')) then begin
            oPixelatedObj = oObj->SeekPixelatedVisualization()
            if (OBJ_VALID(oPixelatedObj)) then $
                return, oPixelatedObj
        endif
    endfor

    ; No pixelated objects found.
    return, OBJ_NEW()
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetDataSpace
;
; PURPOSE:
;   This function method returns a reference to the nearest
;   dataspace object in the graphics hierarchy in which this
;   visualization is contained.  If no dataspace objects are
;   found by walking up the hierarchy, then a NULL object reference
;   is returned.
;
; CALLING SEQUENCE:
;   oDataSpace = Obj->[_IDLitVisualization::]GetDataSpace()
;
; KEYWORD PARAMETERS:
;   UNNORMALIZED:   Set this keyword to a non-zero value to indicate
;     that the returned dataspace should subclass from 'IDLitVisDataSpace'
;     rather than 'IDLitVisNormDataSpace'.
;
; OUTPUTS:
;   This function returns a reference to the dataspace associated
;   with this visualization, or a null object reference if no dataspace
;   is found.
;-
function _IDLitVisualization::GetDataSpace, $
    UNNORMALIZED=unNormalized

    compile_opt idl2, hidden

    ; Assume this visualization is not a dataspace.
    ; Dataspace object classes should implement their own version
    ; of this method.

    ; Retrieve parent.
    self->IDLgrComponent::GetProperty, PARENT=oParent

    ; No need to look past the world.
    if (~OBJ_VALID(oParent) || OBJ_ISA(oParent, 'IDLitgrWorld')) then $
        return, OBJ_NEW()

    ; Ask the parent to get the dataspace.
    return, oParent->GetDataSpace(UNNORMALIZED=unNormalized)

end


;---------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::IsIsotropic
;
; PURPOSE:
;   This function method returns a flag indicating whether this visualization
;   is isotropic.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]IsIsotropic()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is isotropic,
;   or 0 otherwise.
;
;-
function _IDLitVisualization::IsIsotropic

    compile_opt idl2, hidden

    ; Shortcut.
    return, self.isotropic

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Is3D
;
; PURPOSE:
;   This function method returns a flag indicating whether this visualization
;   is 3D (or not 3D).
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]Is3D()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is 3D, or 0 otherwise.
;
;-
function _IDLitVisualization::Is3D

    compile_opt idl2, hidden

    return, self.is3D
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Set3D
;
; PURPOSE:
;   This procedure method marks this visualization as being either 3D
;   or not 3D.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Set3D[, Is3D]
;
; INPUTS:
;   Is3D:   A boolean indicating whether this visualization should
;     be marked as being 3D.  If this argument is not present, the
;     visualization will be marked as 3D.
;
; KEYWORDS:
;   ALWAYS: Set this keyword to a non-zero value to indicate
;     that the given 3D setting always applies (as opposed to being
;     temporary).
;
;   AUTO_COMPUTE:   Set this keyword to a non-zero value to
;     indicate that the 3D value for this visualization should be
;     auto-computed based upon the dimensionality of its contents.
;     This keyword is mutually exclusive of the ALWAYS keyword, and
;     if set, the Is3D argument is ignored.
;-
pro _IDLitVisualization::Set3D, is3D, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute

    compile_opt idl2, hidden

    if (KEYWORD_SET(autocompute)) then begin
        self.dimMethod = 2
        self->_CheckDimensionChange
    endif else begin
        ; If parameter not provided, assume 3D.
        if (N_PARAMS() lt 1) then $
            is3D = 1

        if (KEYWORD_SET(always)) then $
            self.dimMethod = (is3D ? 1 : 0)

        ; If dimensionality changed, perform appropriate updates.
        if (is3D ne self.is3D) then begin
            self.is3D = is3D

            ; Update lighting:
            ;   for 2D: no lighting
            ;   for 3D: double-sided lighting.
            self->IDLgrModel::SetProperty, LIGHTING=2*is3D

            ; Notify parent of change.
            self->IDLgrModel::GetProperty, PARENT=oParent
            if (OBJ_VALID(oParent)) then $
                oParent->OnDimensionChange, self, self.is3D
        endif
    endelse
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetDataString
;
; PURPOSE:
;   This function method returns a string that describes this
;   visualization's data at the given XYZ location.
;
; CALLING SEQUENCE:
;   DataString = Obj->[_IDLitVisualization::]GetDataString( XYZLocation )
;
; INPUTS:
;   XYZLocation:    A 3-element vector, [x,y,z], indicating the
;     location for which a corresponding data string is being requested.
;
; OUTPUTS:
;   This function returns a string describing the data at the given
;   location.
;
;-
function _IDLitVisualization::GetDataString, xyz
    compile_opt idl2, hidden

    ; No-op.  Subclasses may need to override and do more work.
    return, ''
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetManipulatorTarget
;
; PURPOSE:
;   This function method retrieves the manipulator target associated
;   with this visualization.  (The manipulator target may be this
;   visualization itself.)
;
; CALLING SEQUENCE:
;   ManipTarget = Obj->[_IDLitVisualization::]GetManipulatorTarget()
;
; OUTPUTS:
;   This function returns a reference to the manipulator target, or
;   a null object reference if none is found.
;-
function _IDLitVisualization::GetManipulatorTarget

    compile_opt idl2, hidden

    ; Look up the parent chain for a manipulator target.
    ; No need to look past the World.
    oParent = self
    while OBJ_VALID(oParent) do begin
        if OBJ_ISA(oParent, "IDLitgrWorld") then $
            RETURN, OBJ_NEW()
        if (oParent->IsManipulatorTarget()) then $
            return, oParent
        oParent[0]->IDLgrComponent::GetProperty, PARENT=oParent
    endwhile

    ; ran out of parents
    RETURN, OBJ_NEW()
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::IsManipulatorTarget
;
; PURPOSE:
;   This function method returns a flag indicating whether this
;   visualization is a manipulator target.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]IsManipulatorTarget()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is a manipulator
;   target, or a 0 otherwise.
;
;-
function _IDLitVisualization::IsManipulatorTarget
    compile_opt idl2, hidden

    return, self.isManipulatorTarget
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetTypes
;
; PURPOSE:
;   This function method returns a vector of strings that name
;   the types that this visualization represents, including base types
;   and any specializations.
;
; CALLING SEQUENCE:
;   Types = Obj->[_IDLitVisualization::]GetTypes()
;
; OUTPUTS:
;   This function returns a vector of strings, each of which
;   corresponds to a type that this visualization represents.
;-
function _IDLitVisualization::GetTypes

    ;; Pragmas
    compile_opt idl2, hidden

    return, ["_VISUALIZATION", *self._pStrType]
end

;----------------------------------------------------------------------------
; _IDLitVisualization::MatchesTypes
;
; Purpose:
;   This function method returns a flag indicating whether this visualization
;   matches any of the given types.
;
; Arguments:
;   targetTypes: A vector of strings representing the visualization types
;     to be matched.
;
; Return value:
;   This function returns a 1 if any of this visualization's types matches
;   any of the given types.
;
function _IDLitVisualization::MatchesTypes, targetTypes
    compile_opt idl2, hidden

    if (N_ELEMENTS(targetTypes) eq 0) then $
        return, 0

    visTypes = self->GetTypes()
    nt = N_ELEMENTS(visTypes)
    for i=0,nt-1 do begin
        if (MAX(targetTypes eq visTypes[i]) eq 1) then $
            return, 1
    endfor

    ; No matches found.
    return, 0
end

;----------------------------------------------------------------------------
; Selection Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetDefaultSelectionVisual
;
; PURPOSE:
;   This function method retrieves the default selection visual
;   for this visualization.
;
; CALLING SEQUENCE:
;   ManipVis = Obj->[_IDLitVisualization::]GetDefaultSelectionVisual()
;
; OUTPUTS:
;   This function returns a reference to the IDLitManipulatorVisual
;   that serves as the default selection visual for this visualization.
;
;-
function _IDLitVisualization::GetDefaultSelectionVisual

    compile_opt idl2, hidden

    ; If user has not manually set the default select visual,
    ; then create our own default, depending upon manipulator target.
    if (~OBJ_VALID(self._oSelectionVisual)) then begin
        self._oSelectionVisual = OBJ_NEW(self.isManipulatorTarget ? $
            'IDLitManipVisScale' : 'IDLitManipVisSelectBox', /HIDE, $
            TOOL=self.tool)
        self->Add, self._oSelectionVisual, /GROUP, /NO_NOTIFY
    endif

    return, self._oSelectionVisual
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::SetDefaultSelectionVisual
;
; PURPOSE:
;   This procedure method sets the default selection visual to be
;   associated with this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]SetDefaultSelectionVisual, SelectionVisual
;
; INPUTS:
;   SelectionVisual:    A reference to the IDLitManipulatorVisual object
;     that is to serve as the default selection visual for this
;     visualization.
;
;-
pro _IDLitVisualization::SetDefaultSelectionVisual, oSelectionVisual, $
    POSITION=position

    compile_opt idl2, hidden

    if (~OBJ_VALID(oSelectionVisual)) then $
        return

    ; Remove and destroy the current default select visual.
    if (OBJ_VALID(self._oSelectionVisual)) then begin
        self->Remove, self._oSelectionVisual
        OBJ_DESTROY, self._oSelectionVisual
    endif

    ; Set the new default select visual.
    self._oSelectionVisual = oSelectionVisual
    self->Add, self._oSelectionVisual, POSITION=position, /GROUP, /NO_NOTIFY
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetCurrentSelectionVisual
;
; PURPOSE:
;   This function method retrieves the current selection visual
;   for this visualization.
;
; CALLING SEQUENCE:
;   ManipVis = Obj->[_IDLitVisualization::]GetCurrentSelectionVisual()
;
; OUTPUTS:
;   This function returns a reference to the IDLitManipulatorVisual
;   that serves as the current selection visual for this visualization,
;   or a null object it has no current select visual.
;
;-
function _IDLitVisualization::GetCurrentSelectionVisual

    compile_opt idl2, hidden

    return, self.oCurrSelectionVisual
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::UpdateSelectionVisual
;
; PURPOSE:
;   This procedure method transforms this visualization's current
;   selection visual to match the visualization's geometry.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]UpdateSelectionVisual
;
;-
pro _IDLitVisualization::UpdateSelectionVisual

    compile_opt idl2, hidden

    if (OBJ_VALID(self.oCurrSelectionVisual)) then $
        self.oCurrSelectionVisual->_TransformToVisualization, self
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetSelectionVisual
;
; PURPOSE:
;   This function method retrieves the selection visual that corresponds
;   to a given manipulator.
;
; CALLING SEQUENCE:
;   ManipVis = Obj->[_IDLitVisualization::]GetSelectionVisual( $
;       Manipulator)
;
; INPUTS:
;   Manipulator: A reference to an IDLitManipulator for which the
;     corresponding selection visual (associated with this visualization)
;     is to be retrieved.
;
; OUTPUTS:
;   This function returns a reference to an IDLitManipulatorVisual that
;   corresponds the the given manipulator, or a null object if this
;   visualization has no selection visual for the given manipulator.
;
;-
function _IDLitVisualization::GetSelectionVisual, oManipulator

    compile_opt idl2, hidden

    ; If we are not a manipulator target, then return our gray box.
    if (~self->IsManipulatorTarget()) then $
        return, self->GetDefaultSelectionVisual()

    ; Retrieve the manipulator visual class.
    oManipulator->GetProperty, VISUAL_TYPE=visualType

    ; Retrieve all selection visuals.
    oSelectionVisuals = self->IDL_Container::Get(/ALL, $
        ISA='IDLitManipulatorVisual', COUNT=count)

    ; Try to find a type match.
    for i=0,count-1 do begin

        if (~OBJ_VALID(oSelectionVisuals[i])) then $
            continue

        oSelectionVisuals[i]->GetProperty, VISUAL_TYPE=type

        if STRCMP(type, visualType, /FOLD_CASE) then $
            return, oSelectionVisuals[i]   ; found a match
    endfor

    ; Do we need to create a new selection visual and store it?
    oSelectionVisual = oManipulator->BuildDefaultVisual()

    ; Add to our visualization hierarchy.
    if (OBJ_VALID(oSelectionVisual)) then $
        self->Add, oSelectionVisual, /GROUP, /NO_NOTIFY

    return, oSelectionVisual

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::UpdateSelectionVisualVisibility
;
; PURPOSE:
;   This procedure method hides or shows the current selection visual
;   associated with this visualization according to the visualization's
;   selection state.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]UpdateSelectionVisualVisibility
;
;-
pro _IDLitVisualization::UpdateSelectionVisualVisibility

    compile_opt idl2, hidden

   isSelected = self->IsSelected()

   ; If this visualization is a manipulator target, determine whether
   ; any of the contained items is selected (and have ourself as
   ; their manip target).
   if (~isSelected && self->IsManipulatorTarget()) then $
       isSelected = self->_ChildrenSelected(self)

   ; Ensure that a current selection visual is available.
   if (not obj_valid(self.oCurrSelectionVisual)) then begin
       self.oCurrSelectionVisual = self->GetDefaultSelectionVisual()

       ;; If no current selection visual, then bail.
       if (not obj_valid(self.oCurrSelectionVisual)) then $
           return
       self->UpdateSelectionVisual
   endif

   ; If necessary, change the hide property.
   self.oCurrSelectionVisual->IDLgrComponent::GetProperty, HIDE = oldHide
   if (oldHide xor ~isSelected) then begin
       self.oCurrSelectionVisual->SetProperty, HIDE = ~isSelected
       oTool = self->GetTool()
       if (OBJ_VALID(oTool)) then $
           oTool->RefreshCurrentWindow
   endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::SetCurrentSelectionVisual
;
; PURPOSE:
;   This procedure method sets the selection visual corresponding to
;   the given manipulator to be this visualization's current selection
;   visual.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]SetCurrentSelectionVisual, Manipulator
;
; INPUTS:
;   Manipulator: A reference to an IDLitManipulator for which the
;     corresponding selection visual is to become current for this
;     visualization.
;
;-
pro _IDLitVisualization::SetCurrentSelectionVisual, oManipulator

    compile_opt idl2, hidden

    if not OBJ_VALID(oManipulator) then $
      return

    ; Retrieve the selection visual corresponding to the manipulator.
    oSelectionVisual = self->GetSelectionVisual(oManipulator)

    ; Pass along the request to this visualization's manipulator target.
    oManipTarget = self->GetManipulatorTarget()
    if (OBJ_VALID(oManipTarget) && (oManipTarget ne self)) then $
      oManipTarget->SetCurrentSelectionVisual, oManipulator

    if (oSelectionVisual eq self.oCurrSelectionVisual) then $
        return

    ; Sanity check.
    if (not OBJ_VALID(oSelectionVisual)) then $
        return

    oldVisual = self.oCurrSelectionVisual
    self.oCurrSelectionVisual = oSelectionVisual

    ; Transform the selection visual to the size and location of
    ; this visualization.
    self->UpdateSelectionVisual

    ; If currently selected, hide the former selection visual.
    if (OBJ_VALID(oldVisual)) then $
      oldVisual->SetProperty, /HIDE

    ;; Now have the object update the visual's visiblity.
    self->UpdateSelectionVisualVisibility

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Select
;
; PURPOSE:
;   This procedure method handles notification that this object
;   has been selected.
;
;   If a parameter is not passed in, the mode is determined by
;   the keyword values.
;
;   If no keywords are set, a select operation is used.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Select, Mode
;
; INPUTS:
;    Mode     - An integer representing the type of selection to perform.
;      Valid values include:
;                    0 - Unselect
;                    1 - Select
;                    2 - Toggle    (control key)
;                    3 - Additive  (shift key)
;
; KEYWORD PARAMETERS:
;   ADDITIVE:   Set this keyword to a nonzero value to indicate that
;     this visualization should be selected as an addition to the
;     current selection list.  Setting this keyword is equivalent to
;     setting the mode argument to 3.
;
;   NO_NOTIFY:  Set this keyword to a nonzero value to indicate that
;     this visualization's parent should not be notified of the selection.
;     By default, the parent is notified.
;
;   SELECT: Set this keyword to a nonzero value to indicate that
;     this visualization should be selected (in isolation).  Setting this
;     keyword is equivalent to setting the mode argument to 1.
;
;   TOGGLE: Set this keyword to a nonzero value to indicate that
;     the selection status of this visualization should be toggled.
;     Setting this keyword is equivalent to setting the mode argument to 2.
;
;   UNSELECT:   Set this keyword to a nonzero value to indicate that
;     this visualization should be unselected. Setting this keyword is
;     equivalent to setting the mode argument to 0.
;
;-
pro _IDLitVisualization::Select, iMode, $
    ADDITIVE=ADDITIVE, $
    NO_NOTIFY=NO_NOTIFY, $
    SELECT=SELECT, $
    SKIP_MACRO=skipMacro, $
    TOGGLE=TOGGLE, $
    UNSELECT=UNSELECT

    ; pragmas
    compile_opt idl2, hidden

    ; Convert keywords to a mode parameter.
    if (N_PARAMS() ne 1) then begin
        case 1 of
            KEYWORD_SET(UNSELECT) : iMode = 0
            KEYWORD_SET(SELECT)   : iMode = 1
            KEYWORD_SET(ADDITIVE) : iMode = 3
            KEYWORD_SET(TOGGLE)   : iMode = 2
            else                  : iMode = 1  ;; default SELECT
        endcase
    endif else if (iMode lt 0 or iMode gt 3) then $
        return

    ; Check our toggle.
    if (iMode eq 2) then $
        iMode = (self.isSelected ? 0 : 3)

    isSelected = iMode and 1     ; first bit set, we are going to select

    wasSelected = self.isSelected
    self.isSelected = isSelected

    ; Seek the nearest IDLitSelectParent, if any.
    self->IDLgrModel::GetProperty, PARENT=oParent
    while (OBJ_ISA(oParent, 'IDLitSelectParent') eq 0) do begin
        if (OBJ_VALID(oParent)) then begin
            oSkip = oParent
            oSkip->IDLgrComponent::GetProperty, PARENT=oParent
        endif else $
            break
    endwhile

    ; If the selection mode not changing, return.
    if (wasSelected eq isSelected) then begin
        if (OBJ_VALID(oParent)) then $
            oParent->SetPrimarySelectedItem, self
        return
    endif

    ; If this visualization is not a manipulator target, then
    ; ensure its manipulator target is also selected.
    oManipTarget = self->GetManipulatorTarget()
    ; Ensure tool is set on manipulator target
    if (~oManipTarget->GetTool()) then $
      oManipTarget->_SetTool, self->GetTool()
    if (OBJ_VALID(oManipTarget) && (oManipTarget ne self)) then $
        oManipTarget->UpdateSelectionVisualVisibility

    ; Update our selection visual status.
    self->UpdateSelectionVisualVisibility

    ; If notification is enabled, notify the parent.
    if (OBJ_VALID(oParent)) then begin
       if (not KEYWORD_SET(NO_NOTIFY))then begin
           case iMode of
               0: oParent->RemoveSelectedItem, self
               1: oParent->SetSelectedItem, self
               3: oParent->AddSelectedItem, self
           endcase

            if ~keyword_set(skipMacro) then begin
                oTool = self->GetTool()
                if (OBJ_VALID(oTool)) then begin
                    oSrvMacro = oTool->GetService('MACROS')
                    if OBJ_VALID(oSrvMacro) then begin
                        case iMode of
                           0: macroMode = 2
                           1: macroMode = 0
                           3: macroMode = 1
                        endcase
                        ; SELECTION_TYPE=1, position in container
                        oSrvMacro->AddSelectionChange, self, $
                            MODE=macroMode,   $
                            SELECTION_TYPE=1
                    endif
                endif
            endif

       endif
   endif

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method reports whether any of the contained visualizations
;   within this visualization is selected.
;
; Result:
;   This function returns a 1 if any of the children of this visualization
;   is selected (and have the correct manip target), or 0 otherwise.
;
; Arguments:
;   ManipTarget: An object reference to the manipulator target that we
;   are trying to test against.
;
; Keywords:
;   None.
;
function _IDLitVisualization::_ChildrenSelected, oManipTarget

    compile_opt idl2, hidden

    oChildren = self->Get(/ALL, COUNT=nVis, ISA="_IDLitVisualization")

    for i=0, nVis-1 do begin
        ; If one of our children is selected, and its manip target
        ; is the one we are looking for (usually ourself), then return 1.
        if (oChildren[i]->IsSelected() && $
            (oChildren[i]->GetManipulatorTarget() eq oManipTarget)) then $
                return, 1b
        ; Otherwise, recurse down the hierarchy to see if any of our
        ; grandchildren are selected. As soon as we find one,
        ; we are done.
        if (oChildren[i]->_ChildrenSelected(oManipTarget)) then $
            return, 1b
    endfor

    ; If we reach this point, either none of our children are selected,
    ; or if they are, then their manip target is not the one we wanted.
    return, 0b

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::IsSelected
;
; PURPOSE:
;   This function method reports whether this visualization is currently
;   selected.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]IsSelected()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is currently
;   selected, or 0 otherwise.
;-
function _IDLitVisualization::IsSelected

    compile_opt idl2, hidden

    return, self.isSelected
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetHitVisualization
;
; PURPOSE:
;   This function method retrieves the current sub-hit for this
;   visualization, taking into account any logical grouping.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]GetHitVisualization(oSubHitList)
;
; INPUTS:
;   oSubHitList - An ordered vector of references to the objects
;     (SELECT_TARGETs) that are descendents of this visualization and
;     were sub-hit when this visualization was hit.  (This argument
;     is typically set to the value returned via the SUB_HIT keyword
;     of IDLitWindow::DoHitTest.)
;
; OUTPUTS:
;   This function returns a reference to the first sub-hit that is
;   not part of a logical group, or this visualization (otherwise).
;
;-
function  _IDLitVisualization::GetHitVisualization, oSubHitList

    compile_opt idl2, hidden

    ; If nothing supplied, just return ourself.
    nSubHits = N_ELEMENTS(oSubHitList)
    if (nSubHits eq 0) then $
        return, self

    ; Assume we will return ourself, as the top level of the group.
    result = self

    iSub = 0
    oSubHit = oSubHitList[iSub]

    ;;   Step 1: Is this a Viz?
    while (OBJ_ISA(oSubHit, "_IDLitVisualization")) do begin
        oSubHit->_IDLitVisualization::GetProperty, GROUP_PARENT=oGParent
        if (not OBJ_VALID(oGParent)) then begin
            ;; Step 2a: If not in the logical selection group (LSG), return
            ;;          the sub-vis.
            result = oSubHit
            break
        endif
        ;; Step 2b: If the sub-viz is in the logical group, see if it
        ;;          has any sub-selections? ...call down the tree.
        iSub++
        if (iSub ge nSubHits) then $
            break
        oSubHit = oSubHitList[iSub]
    endwhile

    return, result
end

;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnDataChange
;
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnDataChange, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro _IDLitVisualization::OnDataChange, oSubject

    compile_opt idl2, hidden

    ; Increment the reference count.
    self.geomRefCount++

    ; If this is the first notification, notify the parent.
    if (self.geomRefCount eq 1) then begin
        self->IDLgrModel::GetProperty, PARENT=oParent
        if OBJ_VALID(oParent) then $
            oParent->OnDataChange, oSubject
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnDataComplete
;
; PURPOSE:
;   This procedure method handles notification that recently changed
;   data is ready to be flushed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnDataComplete, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data flush.
;-
pro _IDLitVisualization::OnDataComplete, oSubject

    compile_opt idl2, hidden

    ; Decrement reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount--

    ; If all children have reported in that they are ready to flush,
    ; then the reference count should be zero and the parent
    ; can be notified.
    if (~self.geomRefCount) then begin
        ; Notify parent.
        self->IDLgrModel::GetProperty, PARENT=oParent
        if OBJ_VALID(oParent) then begin
            ;; KDB 4/03 Only call UpdateSelectionVisual if the parent
            ;; is valid, otherwise issue can arise during tool destruction.
            self->UpdateSelectionVisual
            oParent->OnDataComplete, oSubject
        endif
    endif
end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnDataDelete
;
; PURPOSE:
;   This procedure method handles notification that the data is Deleted
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnDataDelete, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro _IDLitVisualization::OnDataDelete, oSubject

    compile_opt idl2, hidden
    self->OnDataChange, oSubject
    self->OnDataComplete, oSubject
end

;----------------------------------------------------------------------------
; Data Range Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnDataRangeChange
;
; PURPOSE:
;   This procedure method handles notification that the data
;   range has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnDataRangeChange, Subject, $
;     XRange, YRange, ZRange
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the data range change.
;   XRange: The new xrange, [xmin, xmax].
;   YRange: The new yrange, [ymin, ymax].
;   ZRange: The new zrange, [zmin, zmax].
;-
pro _IDLitVisualization::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

   ; Notify all children.
   oChildren = self->Get(/ALL, COUNT=nChildren)

   ; Notify in reverse order so any axes get updated first.
   for i=nChildren-1,0,-1 do begin
       if (OBJ_ISA(oChildren[i], '_IDLitVisualization')) then $
           oChildren[i]->OnDataRangeChange, oSubject, XRange, YRange, ZRange
   endfor

end


;----------------------------------------------------------------------------
; Axes Request Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; METHODNAME:
;   _IDLitVisualization::_CheckAxesRequestChange
;
; PURPOSE:
;   This procedure method determines whether the axes request for
;   this visualization needs to be changed.  If so, the ::SetAxesRequest
;   method will be called with the new setting.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]_CheckAxesRequestChange
;
; SIDE EFFECTS:
;   If the axes request has changed, the ::SetAxesRequest method will
;   be called, causing the self.axesRequest field to be modified.
;-
pro _IDLitVisualization::_CheckAxesRequestChange

    compile_opt idl2, hidden

    case self.axesMethod of
        0: begin
            axesRequest = 0   ; Do NOT request axes.
        end

        1: begin
            axesRequest = 1   ; DO request axes.
        end

        2: begin      ; Auto-compute based on contents.
            ; Walk the hierarchy searching for axes requests.
            axesRequest = 0
            oChildren = self->Get(/ALL, COUNT=nChild)
            for i=0,nChild-1 do begin
                oChild = oChildren[i]
                if (OBJ_ISA(oChild, '_IDLitVisualization')) then begin
                    childAxesRequest = oChild->RequestsAxes()
                endif else begin
                    ; Assume IDLgrModels and IDLgrGraphics do NOT
                    ; request axes.
                    childAxesRequest = 0
                endelse
                if (childAxesRequest) then begin
                    axesRequest = 1
                    break
                endif
            endfor
        end
    endcase

    ; If necessary, update axes request.
    if (axesRequest ne self.axesRequest) then $
        self->SetAxesRequest, axesRequest
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnAxesRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes request
;   of a contained object has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnAxesRequestChange, Subject, axesRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes request change.
;   axesRequest: new axes request setting of Subject.
;-
pro _IDLitVisualization::OnAxesRequestChange, oSubject, axesRequest

    compile_opt idl2, hidden

    ; The change only matters if auto-computing.
    if (self.axesMethod eq 2) then begin
        ; If the child now requests axes, then so does this visualization.
        ; If the child now does NOT request axes, then need to re-test
        ; axes request.
        if (axesRequest) then $
            self->SetAxesRequest, axesRequest $
        else $
            self->_CheckAxesRequestChange
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnAxesStyleRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes style request
;   of a contained object has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnAxesRequestStyleChange, Subject, styleRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes style request change.
;   styleRequest: new style request setting of Subject.
;-
pro _IDLitVisualization::OnAxesStyleRequestChange, oSubject, styleRequest

    compile_opt idl2, hidden

    ; Pass along to parent.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent)) then $
        oParent->OnAxesStyleRequestChange, self, styleRequest
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::SetAxesRequest
;
; PURPOSE:
;   This procedure method marks this visualization as either requesting
;   axes, or not.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]SetAxesRequest[, axesRequest]
;
; INPUTS:
;   axesRequest:   A boolean indicating whether this visualization should
;     be marked as requesting axes.  If this argument is not present, the
;     visualization will be marked as requesting axes.
;
; KEYWORDS:
;   ALWAYS: Set this keyword to a non-zero value to indicate
;     that the given axes request always applies (as opposed to being
;     temporary).
;
;   AUTO_COMPUTE:   Set this keyword to a non-zero value to
;     indicate that the axes request for this visualization should be
;     auto-computed based upon the axes requests of its contents.
;     This keyword is mutually exclusive of the ALWAYS keyword, and
;     if set, the axesRequest argument is ignored.
;
;   NO_NOTIFY: Set this keyword to a non-zero value to indicate
;     that the parent should not be notified of a change in axes
;     request.  By default, the parent is notified.
;-
pro _IDLitVisualization::SetAxesRequest, inAxesRequest, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    if (KEYWORD_SET(autoCompute)) then begin
        self.axesMethod = 2
        self->_CheckAxesRequestChange
    endif else begin
        ; If parameter not provided, assume axes are requested.
        axesRequest = (N_PARAMS() lt 1) ? 1 : (inAxesRequest ne 0)

        if (KEYWORD_SET(always)) then $
            self.axesMethod = (axesRequest ? 1 : 0)

        ; If axes request changed, perform appropriate updates.
        if (axesRequest ne self.axesRequest) then begin
            self.axesRequest = axesRequest

            if (~KEYWORD_SET(noNotify)) then begin
                ; Notify parent of change.
                self->IDLgrModel::GetProperty, PARENT=oParent
                if (OBJ_VALID(oParent)) then $
                    oParent->OnAxesRequestChange, self, self.axesRequest
            endif
        endif
    endelse
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::SetAxesStyleRequest
;
; PURPOSE:
;   This procedure method sets the axes style request for this
;   visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]SetAxesStyleRequest[, styleRequest]
;
; INPUTS:
;   styleRequest:   A scalar representing the requested axes style.
;     Valid values include:
;       -1: this visualization no longer requests a particular axes style.
;       0-N: this visualization requests the corresponding style supported
;          by the IDLitVisDataAxes class.
;
; KEYWORDS:
;   NO_NOTIFY: Set this keyword to a non-zero value to indicate
;     that the parent should not be notified of a change in axes
;     style request.  By default, the parent is notified.
;-
pro _IDLitVisualization::SetAxesStyleRequest, styleRequest, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    oldRequest = self.axesStyleRequest
    oldDoRequest = self.doRequestAxesStyle

    self.doRequestAxesStyle = (styleRequest lt 0) ? 0b : 1b
    self.axesStyleRequest = styleRequest > 0

    ; If axes request changed, perform appropriate updates.
    if ((self.doRequestAxesStyle ne oldDoRequest) || $
        (self.axesStyleRequest ne oldRequest)) then begin

        if (~KEYWORD_SET(noNotify)) then begin
            ; Notify parent of change.
            self->IDLgrModel::GetProperty, PARENT=oParent
            if (OBJ_VALID(oParent)) then $
                oParent->OnAxesStyleRequestChange, self, self.axesStyleRequest
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::RequestsAxes
;
; PURPOSE:
;   This function method returns a flag indicating whether this visualization
;   requests axes (or not).
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]RequestsAxes()
;
; OUTPUTS:
;   This function returns a 1 if this visualization requests axes, or 0
;   otherwise.
;
;-
function _IDLitVisualization::RequestsAxes

    compile_opt idl2, hidden

    return, self.axesRequest
end



;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::GetRequestedAxesStyle
;
; PURPOSE:
;   This function method returns a scalar indicating the style
;   requested by this visualization.  If none of the visualizations
;   in the hierarchy rooted at this visualization requested a particular
;   style, then -1 is returned.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]GetRequestedAxesStyle()
;
; OUTPUTS:
;   This function returns a scalar representing any of the values
;   supported by the IDLitVisDataAxes STYLE property, or
;   -1 to indicate that no specific request has been made.
;
;-
function _IDLitVisualization::GetRequestedAxesStyle

    compile_opt idl2, hidden

    if (self.doRequestAxesStyle) then $
        return, self.axesStyleRequest

    axesStyleRequest = -1
    oChildren = self->Get(/ALL, COUNT=nChild)
    for i=0,nChild-1 do begin
        oChild = oChildren[i]
        if (OBJ_ISA(oChild, '_IDLitVisualization')) then begin
            childRequest = oChild->GetRequestedAxesStyle()
        endif else $
            childRequest = -1

        ; Stop at first child with a request.
        if (childRequest ge 0) then begin
            axesStyleRequest = childRequest
            break
        endif
    endfor

    return, axesStyleRequest
end



;----------------------------------------------------------------------------
; Dimension Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; METHODNAME:
;   _IDLitVisualization::_CheckDimensionChange
;
; PURPOSE:
;   This procedure method determines whether the dimensionality of
;   this visualization needs o be changed.  If so, the ::Set3D
;   method will be called with the appropriate new 3D setting.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]_CheckDimensionChange
;
; SIDE EFFECTS:
;   If the dimensionality has changed, the ::Set3D method will
;   be called, causing the self.is3D field to be modified.
;-
pro _IDLitVisualization::_CheckDimensionChange

    compile_opt idl2, hidden

    case self.dimMethod of
        0: begin
            is3D = 0   ; Always 2D.
        end

        1: begin
            is3D = 1   ; Always 3D.
        end

        2: begin      ; Auto-compute based on contents.
            ; Walk the hierarchy searching for 3-dimensionality.
            is3D = 0
            oChildren = self->Get(/ALL, COUNT=nChild)
            for i=0,nChild-1 do begin
                oChild = oChildren[i]
                childIs3D = 0
                if (OBJ_ISA(oChild, '_IDLitVisualization')) then begin
                    ; Do not allow manipulator visuals to impact dimensionality.
                    if (~OBJ_ISA(oChild, 'IDLitManipulatorVisual')) then $
                        childIs3D = oChild->Is3D()
                endif else begin
                    if (OBJ_ISA(oChild, 'IDLgrModel')) then begin
                        success = oChild->GetXYZRange(xRange, yRange, zRange)
                        if (success) then childIs3D = (zRange[0] ne zRange[1])
                    endif else begin
                        oChild->IDLgrGraphic::GetProperty, ZRANGE=zRange
                        childIs3D = (zRange[0] ne zRange[1])
                    endelse
                endelse
                if (childIs3D) then begin
                    is3D = 1
                    break
                endif
            endfor
        end
    endcase

    ; If necessary, update dimensionality.
    if (is3D ne self.is3D) then $
        self->Set3D, is3D
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of a contained object has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro _IDLitVisualization::OnDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    ; The change only matters if auto-computing.
    if (self.dimMethod eq 2) then begin
        ; If the child is now 3D, then this visualization is 3D.
        ; If the child is now 2D, then need to re-test dimensionality.
        if (is3D) then $
            self->Set3D, is3D $
        else $
            self->_CheckDimensionChange
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::OnWorldDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]OnWorldDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro _IDLitVisualization::OnWorldDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

   ; Notify all children.
   oChildren = self->IDLgrModel::Get(/ALL, ISA='_IDLitVisualization', $
       COUNT=nChildren)
   for i=0,nChildren-1 do $
       oChildren[i]->OnWorldDimensionChange, oSubject, is3D
end


;---------------------------------------------------------------------------
; Convert coordinates using the dataspace containing this visualization
;
function _IDLitVisualization::ConvertCoord, X, Y, Z, _EXTRA=_extra
  compile_opt idl2, hidden

  case N_PARAMS() of
    1 : return, iConvertCoord(X, $
                  TARGET_IDENTIFIER=self->GetFullIdentifier(), $
                  _EXTRA=_extra)
    2 : return, iConvertCoord(X, Y, $
                  TARGET_IDENTIFIER=self->GetFullIdentifier(), $
                  _EXTRA=_extra)
    3 : return, iConvertCoord(X, Y, Z, $
                  TARGET_IDENTIFIER=self->GetFullIdentifier(), $
                  _EXTRA=_extra)
    else : return, -1
  endcase
  
end


;---------------------------------------------------------------------------
; Retrieve the current Projection from our Dataspace.
; Returns either a !MAP structure or a scalar 0.
;
function _IDLitVisualization::GetProjection

    compile_opt idl2, hidden

    oDataspace = self->GetDataspace(/UNNORMALIZED)
    return, OBJ_VALID(oDataspace) ? oDataspace->GetProjection() : 0

end


;----------------------------------------------------------------------------
pro _IDLitVisualization::OnProjectionChange, sMap

    compile_opt idl2, hidden

    ; Just call all my children.
    oVis = self->Get(/ALL, ISA='_IDLitVisualization', COUNT=nvis)
    for i=0,nvis-1 do $
        oVis[i]->OnProjectionChange, sMap
end


;----------------------------------------------------------------------------
; _IDLitVisualization::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport has
;   changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     dimensions (in pixels) of the viewport.
;
;   normViewDims: A 2-element vector, [w,h], representing the new
;     width and height of the visibile view (normalized relative to
;     the virtual canvas).
;
pro _IDLitVisualization::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    ; Notify all children.
    oChildren = self->IDLgrModel::Get(/ALL, ISA='_IDLitVisualization', $
        COUNT=nChildren)
    for i=0,nChildren-1 do $
        oChildren[i]->OnViewportChange, oSubject, oDestination, $
            viewportDims, normViewDims
end

;----------------------------------------------------------------------------
; _IDLitVisualization::OnViewZoom
;
; Purpose:
;   This procedure method handles notification that the view's
;   zoom factor has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   newZoomFactor: A scalar representing the new zoom factor.
;
pro _IDLitVisualization::OnViewZoom, oSubject, oDestination, newZoomFactor

    compile_opt idl2, hidden

    ; Notify all children.
    oChildren = self->IDLgrModel::Get(/ALL, ISA='_IDLitVisualization', $
        COUNT=nChildren)
    for i=0,nChildren-1 do $
        oChildren[i]->OnViewZoom, oSubject, oDestination, newZoomFactor
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::On2DRotate
;
; PURPOSE:
;   This procedure method handles notification that a parent
;   dataspace's rotation status has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]On2DRotate, Subject, isRotated
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the rotation change.
;   isRotated: new flag indicating whether the subject is rotated or not.
;-
pro _IDLitVisualization::On2DRotate, oSubject, isRotated, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

   ; Notify all children.
   oChildren = self->IDLgrModel::Get(/ALL, ISA='_IDLitVisualization', $
       COUNT=nChildren)
   for i=0,nChildren-1 do $
       oChildren[i]->On2DRotate, oSubject, isRotated, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::BeginManipulation
;
; PURPOSE:
;   This procedure method handles notification that a manipulator
;   is about to modify this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]BeginManipulator, Manipulator
;
; INPUTS:
;   Manipulator:    A reference to the manipulator object sending
;     notification.
;-
pro _IDLitVisualization::BeginManipulation, oManipulator

    compile_opt idl2, hidden

    ; No-op.
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::EndManipulation
;
; PURPOSE:
;   This procedure method handles notification that a manipulator
;   is finished modifying this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]EndManipulator, Manipulator
;
; INPUTS:
;   Manipulator:    A reference to the manipulator object sending
;     notification.
;-
pro _IDLitVisualization::EndManipulation, oManipulator

    compile_opt idl2, hidden

    ; No-op.
end

;----------------------------------------------------------------------------
; Simple  Coordinate Transformation routines.
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::VisToWindow
;
; PURPOSE:
;   This procedure method transforms the given points from
;   visualization space into Window device coordinates.
;
; CALLING SEQUENCE:
;      Obj->[_IDLitVisualization::]VisToWindow, inX, inY, inZ, $
;                                              outX, outY, OutZ
;   or
;      Obj->[_IDLitVisualization::]VisToWindow, inX, inY, outX, outY
;   or
;      Obj->[_IDLitVisualization::]VisToWindow, vertIn, vertOut
;
; INPUTS:
;   Like other IDL routines that work with verticies, this method
;   has two input formats: individual vectors of verticies and
;   one vector for all information.
;
;   Individual Vectors
;     inX       - Vector of input x coordinates
;     inY       - Vector of input y coordinates
;     inZ       - Vector of input z coordinates [optional]
;     outX      - Vector of output x coordinates
;     outY      - Vector of output y coordinates
;     outZ      - Vector of output z coordinates [optional]
;
;  Single coordinate array:
;
;   vertIn      - A [3,n] or [2,n] array of verticies.
;   vertOut     - A [3,n] or [2,n] array of verticies. Same shape
;                 as input array.
;
; Keywords:
;   NO_TRANSFORM: If set, then do not include the current transform
;       matrix in the computation.
;-
pro _IDLitVisualization::VisToWindow, inX, inY, inZ, outX, outY, outZ, $
    NO_TRANSFORM=noTransform

    ; Pragmas
    compile_opt idl2, hidden

    ; Get our points in a form we can use. If inX is not a vector, it
    ; is assumed to contain all the coordinates we want.
    ; Since homogeneous coords are needed, copies of the data are used.
    ndim = SIZE(inX, /N_DIMENSIONS)
    dims = [SIZE(inX, /DIMENSIONS), 1]

    ; Retrieve the view and window within which this visualization
    ; appears.
    success = self->_GetWindowandViewG(oWin, oViewG)
    if (~success) then $
        self->ErrorMessage, "Invalid graphics tree.", severity=2
    if (~success || ~OBJ_VALID(oWin)) then begin
        verts = DBLARR(4, dims[1])
        goto, skipover
    endif

    if (N_PARAMS() eq 2) then $   ; vertIn, vertOut args
        ndim = 2

    case ndim of
        0 : begin   ; inX, inY [, inZ], outX, outY [, outZ]
            verts = [inX, inY, ((N_PARAMS() eq 6) ? inZ: 0), 1d]
            end
        1 : begin   ; inX, inY [, inZ], outX, outY [, outZ]
            verts = DBLARR(4, dims[0])
            verts[0,*] = inX      ; X coordinates
            verts[1,*] = inY      ; Y coordinates
            if (N_PARAMS() eq 6) then $
                verts[2,*] = inZ  ; Z coordinates
            end
        2 : begin   ; vertIn, vertOut args
            verts = DBLARR(4, dims[1])
            verts[0:dims[0]-1,*] = inX    ; X, Y [, Z] coordinates
            end
        else:  begin
            self->ErrorMessage, "Incorrectly formatted coordinate arguments", $
              severity=2
            return
        end
    endcase

    verts[3,*] = 1.0

    iDimensions = oViewG->GetViewport(oWin, LOCATION=iLocation)

    doTransform = ~KEYWORD_SET(noTransform)
    if (doTransform) then $
        matrix = self->GetCTM(DESTINATION=oWin)

    for i=0,N_ELEMENTS(verts[0,*])-1 do begin
        vert1 = verts[*,i]

        ; Convert points to normalized [-1,1]  window values.
        if (doTransform) then $
            vert1 #= matrix

        if (vert1[3] ne 0.0) then $
            vert1 = vert1 / vert1[3]

        ; Expand the normalized points into device coordinates.
        vert1[0:1] = ((vert1[0:1] + 1.0) / 2.0) * iDimensions + iLocation
        verts[*,i] = vert1
    endfor

skipover:

    ; Convert back to original format.
    if (ndim le 1) then begin
        if (N_PARAMS() eq 6) then begin
            outX = REFORM(verts[0,*])
            outY = REFORM(verts[1,*])
            outZ = REFORM(verts[2,*])
        endif else begin ;; no input Z, need to shift output values
            ; inZ is really outX.
            inZ = REFORM(verts[0,*])

            ; outX is really outY.
            outX = REFORM(verts[1,*])
        endelse
    endif else $
        inY = temporary(verts[0:(dims[0]-1), *] )
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::WindowToVis
;
; PURPOSE:
;   This procedure method transforms the given points from
;   a given Window (device) location to visualization coordinates.
;
; CALLING SEQUENCE:
;      Obj->[_IDLitVisualization::]WindowToVis, inX, inY, inZ, $
;                                              outX, outY, OutZ
;   or
;      Obj->[_IDLitVisualization::]WindowToVis, inX, inY, outX, outY
;   or
;      Obj->[_IDLitVisualization::]WindowToVis, vertIn, vertOut
;
; INPUTS:
;   Like other IDL routines that work with verticies, this method
;   has two input formats: individual vectors of verticies and
;   one vector for all information.
;
;   Individual Vectors
;     inX       - Vector of input x coordinates
;     inY       - Vector of input y coordinates
;     inZ       - Vector of input z coordinates, in [-1,1] range [optional]
;     outX      - Vector of output x coordinates
;     outY      - Vector of output y coordinates
;     outZ      - Vector of output z coordinates [optional]
;
;  Single coordinate array:
;
;   vertIn      - A [3,n] or [2,n] array of verticies.
;   vertOut     - A [3,n] or [2,n] array of verticies. Same shape
;                 as input array.
;-
pro _IDLitVisualization::WindowToVis, inX, inY, inZ, outX, outY, outZ

    ; Pragmas
    compile_opt idl2, hidden

    ; Retrieve the view and window within which this visualization
    ; Get our points in a form we can use. If inX is not a vector, it
    ; is assumed to contain all the coordinates we want.
    ; Since homogeneous coords are needed, copies of the data are used.
    ndim = SIZE(inX, /N_DIMENSIONS)
    dims = [SIZE(inX, /DIMENSIONS), 1]

    ; appears.
    success = self->_GetWindowandViewG(oWin, oViewG)
    if (~success) then $
        self->ErrorMessage, "Invalid graphics tree.", severity=2
    if (~success || ~OBJ_VALID(oWin)) then begin
        verts = DBLARR(4, dims[1])
        goto, skipWindowToVis
    endif

    ; If the user passes in a [3] array for [3,1] (or a [2] for [2,1])
    if ((N_PARAMS() eq 2) and (ndim eq 1)) then $
        ndim = 2

    case (ndim) of
        0 : begin   ; inX, inY [, inZ], outX, outY [, outZ]
            verts = [inX, inY, ((N_PARAMS() eq 6) ? inZ: 0), 1.0]
            end
        1 : begin   ; inX, inY [, inZ], outX, outY [, outZ]
            verts = dblarr(4, dims[0], /nozero)
            verts[0,*] = inX
            verts[1,*] = inY
            verts[2,*] = ((N_PARAMS() eq 6) ? inZ : 0.)
            end
        2 : begin
            verts = dblarr(4, dims[1], /nozero)
            verts[0,*] = inX[0,*]
            verts[1,*] = inX[1,*]
            verts[2,*] = (dims[0] ge 3 ? inX[2,*]  : 0.)
            end
        else:  begin
            self->ErrorMessage, IDLitLangCatQuery('Error:Framework:BadFormatArgs'), $
              severity=2
        end
    endcase
    verts[3,*] = 1.0

    ; Retrieve viewport dimensions and location.
    iDimensions = oViewG->GetViewport(oWin, LOCATION=iLocation)
    imatrix = INVERT(self->GetCTM(DESTINATION=oWin))

    for i=0,N_ELEMENTS(verts[0,*])-1 do begin
        vert1 = verts[*,i]

        ; Convert from window coordinates to [-1,1] normalized view space.
        vert1[0:1] = ((vert1[0:1] - DOUBLE(iLocation))/iDimensions)*2.0 - 1.0

        ; Convert points from [-1,1] to viz data space.
        vert1 = TEMPORARY(vert1) # imatrix
        if (vert1[3] ne 0.0) then $
            vert1 = vert1 / vert1[3]
        verts[*,i] = vert1
    endfor

skipWindowToVis:

    ; Convert back to original format.
    if (ndim le 1) then begin
        if (N_PARAMS() eq 6) then begin
            outX = verts[0,*]
            outY = verts[1,*]
            outZ = verts[2,*]
        endif else begin ;; no input Z, need to shift output values
            ; inZ is really outX.
            inZ = verts[0,*]

            ; outX is really outY.
            outX = verts[1,*]
        endelse
    endif else $
        inY =  verts[0:(dims[0]-1), *]
end

;---------------------------------------------------------------------------
; Transformation Interface
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Rotate
;
; PURPOSE:
;   This procedure method rotates this visualization about the
;   given axis by the given angle.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Rotate, Axis, Angle
;
; INPUTS:
;   Axis: A three-element vector, [x,y,z], representing the axis
;     about which the visualization is to be rotated.
;
;   Angle: A scalar representing the angle of rotation (measured
;     in degrees).
;
; KEYWORD PARAMETERS:
;   CENTER_OF_ROTATION: Set this keyword to a 3-element vector, [x,y,z],
;     representing the center of the rotation.  By default, the
;     visualization's own center of rotation will be used.
;
;   PREMULTIPLY:    Set this keyword to cause the rotation matrix
;     specified by Axis and Angle to be pre-multiplied to this
;     visualization's transformation matrix.   By default, it is
;     post-multiplied.
;
;-
pro _IDLitVisualization::Rotate, axis, angle, $
                                CENTER_OF_ROTATION=rotCenterIn, $
                                PREMULTIPLY=premultiply, $
                                _EXTRA=_extra
    compile_opt idl2, hidden

    self->IDLgrModel::GetProperty, TRANSFORM=origTransform

    ; Convert CENTER_OF_ROTATION from 2-element to 3-element,
    ; or just set a -1 flag if not provided.
    rotCenter = (N_ELEMENTS(rotCenterIn) eq 3) ? rotCenterIn : $
        ((N_ELEMENTS(rotCenterIn) eq 2) ? [rotCenterIn, 0] : -1)

    if (N_ELEMENTS(rotCenter) ne 3) then begin
        self->_IDLitVisualization::GetProperty, CENTER_OF_ROTATION=cr

        ; In the premultiply case, the rotate is being
        ; applied to the visualization before it has been
        ; transformed by its CTM, so simply use the center
        ; of rotation (as is).
        ;
        ; In the postmultiply case, the rotate is being
        ; applied to the visualization after it has been
        ; transformed by its CTM.  In this case, presumably
        ; it makes more sense to use the transformed center
        ; of rotation.
        rotCenter = KEYWORD_SET(premultiply) ? $
            cr : [cr, 1.0d] # origTransform
    endif

    ; Temporarily reset this visualization's model transform to
    ; identity.
    self->IDLgrModel::Reset

    ; Use this visualization's model to compute the new
    ; transformation.
    self->IDLgrModel::Translate, -rotCenter[0], -rotCenter[1], -rotCenter[2]
    self->IDLgrModel::Rotate, axis, angle
    self->IDLgrModel::Translate, rotCenter[0], rotCenter[1], rotCenter[2]
    self->IDLgrModel::GetProperty, TRANSFORM=newTransform

    ;Restore original transform.
    ;
    ; Note: do NOT skip this step for optimization.  Some classes
    ; (such as IDLitVisROI) impelemnt special handling for the
    ; TRANSFORM property, and need their IDLgrModel TRANSFORM property
    ; to remain untouched.
    self->IDLgrModel::SetProperty, TRANSFORM=origTransform

    ; Multiply the original transform by the rotation transform.
    ctm = KEYWORD_SET(premultiply) ? $
        newTransform # origTransform : $
        origTransform # newTransform

    ; Store the result.
    ;
    ; Note: do NOT explicitly call the SetProperty on the IDLgrModel
    ; superclass, because some classes (such as IDLitVisDataSpaceRoot)
    ; implement special handling for the TRANSFORM property.
    self->SetProperty, TRANSFORM=ctm
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::Scale
;
; PURPOSE:
;   This procedure method scales this visualization by the given scaling
;   factors.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisualization::]Scale, Sx, Sy, Sz
;
; INPUTS:
;   Sx, Sy, Sz: The scaling factors in the x, y, and z dimensions by
;     which this visualization is to be scaled.
;
; KEYWORD PARAMETERS:
;   CENTER_OF_ROTATION: Set this keyword to a 3-element vector, [x,y,z],
;     representing the center of the scale.  By default, the visualization's
;     center of rotation will be used as the center of scale.
;
;   PREMULTIPLY:    Set this keyword to cause the scaling matrix
;     specified by Sx, Sy, and Sz to be pre-multiplied to this
;     visualization's transformation matrix.   By default, it is
;     post-multiplied.
;
;-
pro _IDLitVisualization::Scale, scaleX, scaleY, scaleZ, $
                                CENTER_OF_ROTATION=scaleCenterIn, $
                                PREMULTIPLY=premultiply, $
                                _EXTRA=_extra
    compile_opt idl2, hidden

    self->IDLgrModel::GetProperty, TRANSFORM=oldTransform

    ; Convert CENTER_OF_ROTATION from 2-element to 3-element,
    ; or just set a -1 flag if not provided.
    scaleCenter = (N_ELEMENTS(scaleCenterIn) eq 3) ? scaleCenterIn : $
        ((N_ELEMENTS(scaleCenterIn) eq 2) ? [scaleCenterIn, 0] : -1)

    ;; By default, use the visualization's center of rotation.
    if (N_ELEMENTS(scaleCenter) ne 3) then begin
        self->_IDLitVisualization::GetProperty, CENTER_OF_ROTATION=cr

        ; In the premultiply case, the scale is being
        ; applied to the visualization before it has been
        ; transformed by its CTM, so simply use the center
        ; of rotation (as is) for the center of scale.
        ;
        ; In the postmultiply case, the scale is being
        ; applied to the visualization after it has been
        ; transformed by its CTM.  In this case, presumably
        ; it makes more sense to use the transformed center
        ; of rotation for the center of scale.
        scaleCenter = KEYWORD_SET(premultiply) ? $
            cr : [cr, 1.0d] # oldTransform
    endif

    ;; Build single transform matrix to scale object.
    ;; Translate so the center is at the origin, apply
    ;; scale, and then translate back.

    mat2 = IDENTITY(4)
    mat2[0,0] = scaleX & mat2[1,1]=scaleY & mat2[2,2]=scaleZ

    mat2[3,0] = -scaleCenter[0] * scaleX + scaleCenter[0]
    mat2[3,1] = -scaleCenter[1] * scaleY + scaleCenter[1]
    mat2[3,2] = -scaleCenter[2] * scaleZ + scaleCenter[2]
    if keyword_set(premultiply) then $
        transform = mat2 # oldTransform $
     else $
         transform = oldTransform # mat2

    ; Note: do NOT explicitly call the SetProperty on the IDLgrModel
    ; superclass, because some classes (such as IDLitVisDataSpaceRoot)
    ; implement special handling for the TRANSFORM property.
    self->SetProperty, TRANSFORM=transform
end


;---------------------------------------------------------------------------
; _IDLitVisualization::GetVisualizations
;
; Purpose:
;   This routine will return all objects of type IDLitVisualization
;   contained in ourself. This doesn't include the axis container.
;
; Keywords:
;    COUNT   - The number of items returned.
;
;    FULL_TREE - Set this keyword to a non-zero value to indicate that
;      the visualization retrieval should recurse, thereby returning
;      all visualizations at all levels of the graphics tree (rooted at
;      this visualization).  By default, only visualizations contained
;      one level deep within this visualization are returned.
;
; Return Value:
;   An array of the visualizations contained in this container. If no
;   visualizations are contained, a null is returned.
;
function _IDLitVisualization::GetVisualizations, $
    COUNT=COUNT, $
    FULL_TREE=fullTree

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, COUNT=count, ISA="IDLitVisualization")
    if (~count) then $
        return, obj_new()

    if (KEYWORD_SET(fullTree)) then begin
        for i=0,count-1 do begin
            oSubItems = oItems[i]->GetVisualizations(COUNT=subcount, $
                /FULL_TREE)
            if (subcount gt 0) then $
                oItems = [TEMPORARY(oItems), oSubItems]
        endfor
    endif

    count = N_ELEMENTS(oItems)

    return, oItems

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; _IDLitVisualization__Define
;
; PURPOSE:
;   Defines the object structure for an _IDLitVisualization object.
;-
pro _IDLitVisualization__Define

    compile_opt idl2, hidden

    struct = { _IDLitVisualization,       $
        inherits _IDLitContainer,         $ ; Superclass.
        inherits _IDLitPropertyAggregate, $ ; Must come before IDLgrModel
        inherits IDLgrModel,              $ ; Superclass.
        inherits IDLitSelectParent,       $ ; Superclass.
        inherits IDLitIMessaging,         $
        geomRefCount: 0UL,                $ ; Reference count: geom changes.
        centerRotation: [0d, 0d, 0d],     $ ; Center of rotation.
        iHaveCenterRotation: 0,           $ ; Is center of rotation explicit?
        impactsRange: 0b,                 $ ; Does vis. impact data range?
        isSelected: 0b,                   $ ; Is vis. currently selected?
        is3D: 0b,                         $ ; Is vis. 3D?
        dimMethod: 0b,                    $ ; Method of computing
                                          $ ; dimensionality:
                                          $ ;   0=never 3D
                                          $ ;   1=always 3D
                                          $ ;   2=automatic (based on contents)
        isotropic: 0b,                    $ ; Isotropic scaling required?
        isManipulatorTarget: 0b,          $ ; Is vis. a manipulator target?
        _selectionPad: 0L,                $ ; Sel viz padding in pixels
        oGroupParent : OBJ_NEW() ,        $ ; Group parent.
        oCurrSelectionVisual: OBJ_NEW(),  $ ; Current selection visual.
        _createdDuringInit : 0b,          $ ; flag to mark vis as created during init.
        _oSelectionVisual: OBJ_NEW(),     $ ; Default selection visual.
        _pStrType : PTR_NEW(),            $ ; ^ to string(s) representing the
                                          $ ;   type(s) of the visualization
        axesRequest: 0b,                  $ ; Flag: does this visualization
                                          $ ;   request axes display?
        axesMethod: 0b,                   $ ; Method of determining axes
                                          $ ;  request:
                                          $ ;   0=do not request axes
                                          $ ;   1=do request axes
                                          $ ;   2=automatic (based on contents)
        axesStyleRequest: 0L,             $ ; Requested axes style.
        doRequestAxesStyle: 0b            $ ; Flag: does this visualization
                                          $ ;   request a particular axes
                                          $ ;   style?
    }
end
