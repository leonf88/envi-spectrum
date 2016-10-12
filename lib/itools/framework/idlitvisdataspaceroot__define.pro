; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisdataspaceroot__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisDataSpaceRoot
;
; PURPOSE:
;   The IDLitVisDataSpaceRoot class is a container for "overlapping"
;   dataspaces that are manipulated as a group.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   _IDLitVisualization
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::Init
;
; PURPOSE:
;   The IDLitVisDataSpaceRoot::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   oDataSpaceRoot = OBJ_NEW('IDLitVisDataSpaceRoot')
;
;   or
;
;   Obj->[IDLitVisDataSpaceRoot::]Init
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;   This function method returns a 1 on success, or a 0 otherwise.
;
;-
function IDLitVisDataSpaceRoot::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    if (self->IDLitIMessaging::Init(_EXTRA=_extra) ne 1) then $
        return, 0

    if (~self->_IDLitVisualization::Init($;/MANIPULATOR_TARGET, $
        NAME="Data Space Root", $
        TYPE="DATASPACE_ROOT_2D", $
        ICON='dataspace', $
        DESCRIPTION="Data Space Root Component", $
        /REGISTER_PROPERTIES, $
        SELECTION_PAD=30, $ ; pixels
        _EXTRA=_extra)) then begin
        self->Cleanup
        return, 0
    endif

    return, 1
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpaceRoot::Cleanup
;
; PURPOSE:
;      The IDLitVisDataSpaceRoot::Cleanup procedure method preforms all
;      cleanup on the object.
;
;      NOTE: Cleanup methods are special lifecycle methods, and as such
;      cannot be called outside the context of object destruction.  This
;      means that in most cases, you cannot call the Cleanup method
;      directly.  There is one exception to this rule: If you write
;      your own subclass of this class, you can call the Cleanup method
;      from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, oDataSpaceRoot
;
;   or
;
;   Obj->[IDLitVisDataSpaceRoot::]Cleanup
;
;-
;pro IDLitVisDataSpaceRoot::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclasses.
;    self->_IDLitVisualization::Cleanup
;end


;----------------------------------------------------------------------------
; IDLitVisDataSpaceRoot::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisDataSpaceRoot::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; In IDL60 the DataspaceRoot used to be the _PARENT for our
        ; contained dataspaces. Now, the Layer should be the _PARENT.
        self->IDLitComponent::GetProperty, _PARENT=oParent
        oDataSpace = self->IDLgrModel::Get(/ALL, COUNT=count, $
            ISA="IDLitVisIDataSpace")
        for i=0,count-1 do begin
            oDataSpace[i]->IDLitComponent::SetProperty, _PARENT=oParent
        endfor
    endif
end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
pro IDLitVisDataSpaceRoot::SetProperty, $
    TRANSFORM=transform, $
    NO_NOTIFY=noNotify, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    bNotifyScale = 0b

    if (N_ELEMENTS(transform) eq 16) then begin
        ; If the transform only includes scales and/or translates,
        ; then:
        ;    transform = [sx  0  0  tx
        ;                  0 sy  0  ty
        ;                  0  0 sz  tz
        ;                  0  0  0   1]
        izero = [1,2,4,6,8,9,12,13,14]
        inonzero = WHERE(ABS(transform[izero]) ge 1e-10, count)

        if (count eq 0) then begin
            ; Also check if either (or both) of the x or y scale
            ; factors is negative.  If so, then claim a "rotation".
            iscale = [0,5]
            ineg = WHERE(transform[iscale] lt 0.0, count)
        endif

        if (count gt 0) then begin
            if (~self._b2dRotated) then begin
                self._b2dRotated = 1b
		if (self.is3D eq 0) then $
                    self->_IDLitVisualization::On2DRotate, self, $
                        self._b2dRotated, NO_NOTIFY=noNotify
            endif
        endif else begin
            if (self._b2dRotated) then begin
                self._b2dRotated = 0b
		if (self.is3D eq 0) then $
                    self->_IDLitVisualization::On2DRotate, self, $
                        self._b2dRotated, NO_NOTIFY=noNotify
            endif
        endelse

        ; If 2D, and the scale factors have changed, set flag
        ; to indicate that notification is appropriate.
        if ((~self.is3D) && (~self._b2DRotated)) then begin
            ; Check the entire upper 2x2 so that sheers can be
            ; caught as well.
            if ((self.transform[0] ne transform[0]) || $
                (self.transform[1] ne transform[1]) || $
                (self.transform[4] ne transform[4]) || $
                (self.transform[5] ne transform[5])) then begin

                bNotifyScale = 1b
            endif
        endif
    endif

    self->_IDLitVisualization::SetProperty, TRANSFORM=transform, $
        _EXTRA=_extra

    ; If appropriate, notify observers that the 2D scale has
    ; changed.
    if ((~KEYWORD_SET(noNotify)) && bNotifyScale) then $
        self->DoOnNotify, self->GetFullIdentifier(), $
            'SCALE2D', transform
end

;----------------------------------------------------------------------------
; IIDLContainer Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::Add
;
; PURPOSE:
;   This procedure method adds the given objects to the data space root.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot::]Add, Objects
;
; INPUTS:
;   Objects:    A reference (or vector of references) to the
;     Object(s) to add to the dataspace root.
;
; KEYWORD PARAMETERS:
;   This procedure method accepts all keywords accepted by the
;   superclass's ::Add method.
;-
pro IDLitVisDataSpaceRoot::Add, oObjects, _EXTRA=_EXTRA

    compile_opt idl2, hidden

    ; Determine which of the objects to be added are visualizations.
    isVis = OBJ_ISA(oObjects, "_IDLitVisualization")
    iVis = WHERE(isVis, nVis, COMPLEMENT=iNonVis, NCOMPLEMENT=nNonVis)

    ; Issue message about non-visualization objects.
    if (nNonVis gt 0) then begin
        self->ErrorMessage, $
            IDLitLangCatQuery('Error:DataSpaceRoot:Text'), $
	    title=IDLitLangCatQuery('Error:DataSpaceRoot:Title'), $
            SEVERITY=2
        return
    endif

    if (nVis gt 0) then begin
        ; Among the visualizations, seek out any dataspaces.
        oVis = oObjects[iVis]
        isDS = OBJ_ISA(oVis, "IDLitVisIDataSpace")
        iDS = WHERE(isDS, nDS, COMPLEMENT=iNonDS, NCOMPLEMENT=nNonDS)

        if (nNonDS gt 0) then begin
            ; Among the non-dataspace objects, seek out any manipulator
            ; visuals.
            oNonDSVis = oVis[iNonDS]
            isManipVis = OBJ_ISA(oNonDSVis, "IDLitManipulatorVisual")
            iManipVis = WHERE(isManipVis, nManipVis, $
                COMPLEMENT=iNonManipVis, NCOMPLEMENT=nNonManipVis)

            ; Add manipulator visuals to self directly.
            if (nManipVis gt 0) then begin
                self->IDLgrModel::Add, oNonDSVis[iManipVis], _EXTRA=_extra
            endif

            ; Add non-manipulator-visual objects to the current dataspace.
            if (nNonManipVis gt 0) then begin
                oDataSpace = self->GetCurrentDataSpace()
                oDataSpace->Add, oNonDSVis[iNonManipVis], _EXTRA=_extra

                ; If this dataspace root is currently rotated, notify
                ; newly added visualizations so that they can adjust
                ; as necessary (see, for example, IDLitVisImage).
                if (self._b2DRotated) then begin
                    for i=0,nNonManipVis-1 do $
                        oNonDSVis[iNonManipVis[i]]->On2DRotate, self, 1b
                endif
            endif
        endif

        if (nDS gt 0) then begin
            ; Allow the dataspace root to be the manipulator target;
            ; disable manipulator target settings for all added dataspaces.
;            for i=0,nDS-1 do $
;                oVis[iDS[i]]->SetProperty, MANIPULATOR_TARGET=0

            ; Add dataspace objects to self.
            ; Use /USE__PARENT so we skip over ourself up to the Layer.
            self->_IDLitVisualization::Add, oVis[iDS], $
                /USE__PARENT, _EXTRA=_extra
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::Remove
;
; PURPOSE:
;   This procedure method removes the given objects from the data space root.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot::]Remove, Objects
;
; INPUTS:
;   Objects:    A reference (or vector of references) to the
;     object(s) to add to the dataspace root.
;
; KEYWORD PARAMETERS:
;   This procedure method accepts all keywords accepted by the
;   superclass's ::Remove method.
;-
pro IDLitVisDataSpaceRoot::Remove, oObjects, ALL=all

    compile_opt idl2, hidden

    isDS = OBJ_ISA(oObjects, "IDLitVisIDataSpace")
    iDS = WHERE(isDS, nDS, COMPLEMENT=iNonDS, NCOMPLEMENT=nNonDS)
    if(nNonDS gt 0)then begin   ;non data space
        oNonDS = oObjects[iNonDS]
        oChildren = self->IDLgrModel::Get(/ALL)

        for i=0,N_ELEMENTS(oChildren)-1 do begin
            if (OBJ_VALID(oChildren[i])) then begin
                if OBJ_ISA(oChildren[i], 'IDL_Container') then $
                  oChildren[i]->Remove, oNonDS, ALL=all
            endif else begin
                                ; Remove null objects from myself.
                self->IDLgrModel::Remove, oChildren[i]
            endelse
        endfor
    endif
    if (nDS gt 0)then begin
      iCurrent = WHERE(oObjects[iDS] eq self.oCurrDataSpace, nCurrent)
      self->_IDLitVisualization::Remove, oObjects[iDS], ALL=all
      if nCurrent gt 0 then $
        self.oCurrDataSpace = OBJ_NEW()
    endif
end

;---------------------------------------------------------------------------
; IIDLVisualization Interface
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::Set3D
;
; PURPOSE:
;   This procedure method marks this dataspace root as being either 3D
;   or not 3D.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot::]Set3D[, Is3D]
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
pro IDLitVisDataSpaceRoot::Set3D, is3D, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute

    compile_opt idl2, hidden

    old3D = self.is3D

    ; Call superclass.
    self->_IDLitVisualization::Set3D, is3D

    ; Check for change in own dimensionality.
    if (self.is3D ne old3D) then begin

        ; Change our type! Is this dangerous?
        self->IDLitVisDataSpaceRoot::SetProperty, $
            TYPE=self.is3D ? 'DATASPACE_ROOT_3D' : 'DATASPACE_ROOT_2D'

        ; Modify transform if appropriate.
;        self->IDLgrModel::Reset
;        if (self.is3D) then begin
;            self->IDLgrModel::Rotate, [1, 0, 0], -90
;            self->IDLgrModel::Rotate, [0, 1, 0], 30
;            self->IDLgrModel::Rotate, [1, 0, 0], 30
;        endif
    endif
end

;---------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::IsIsotropic
;
; PURPOSE:
;   This function method returns a flag indicating whether this dataspace root
;   is isotropic.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitVisDataspaceRoot::]IsIsotropic()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is isotropic,
;   or 0 otherwise.
;
;-
function IDLitVisDataSpaceRoot::IsIsotropic

    compile_opt idl2, hidden

    oDS = self->GetCurrentDataSpace()
    if (OBJ_VALID(oDS)) then $
       return, oDS->IsIsotropic()

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpaceRoot::OnAxesRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesRequestChange implementation
;   so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot:]OnAxesRequestChange, Subject, axesRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes request change.
;   axesRequest: new axes request setting of Subject.
;-
pro IDLitVisDataSpaceRoot::OnAxesRequestChange, oSubject, axesRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitDataSpaceRoot::OnAxesStyleRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes style request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesStyleRequestChange
;   implementation so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot:]OnAxesStyleRequestChange, Subject,styleRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes style request change.
;   styleRequest: new style request setting of Subject.
;-
pro IDLitVisDataSpaceRoot::OnAxesStyleRequestChange, oSubject, styleRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitvisDataSpaceRoot::OnDataComplete
;
; PURPOSE:
;    The IDLitvisDataSpaceRoot::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oDataSpaceRoot->[IDLitvisDataSpaceRoot::]OnDataComplete, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data flush.
;
;-
pro IDLitvisDataSpaceRoot::OnDataComplete, oNotifier
    compile_opt idl2, hidden

    ; Decrement the reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount = self.geomRefCount - 1

    ; Return if more children have yet to report in.
    if (self.geomRefCount gt 0) then $
        return

    ; Determine if any of my contained dataspaces need
    ; double precision.
    oDS = self->_IDLitVisualization::Get(/ALL, ISA='IDLitVisIDataSpace', $
        COUNT=nDS)
    doDouble = 0b
    for i=0,nDS-1 do begin
        if (oDS[i]->RequiresDouble()) then begin
            doDouble = 1b
            break
        endif
    endfor

    ; Report need for double to the layer.
    oLayer = self->_GetLayer()
    if (OBJ_VALID(oLayer)) then $
        oLayer->IDLgrView::SetProperty, DOUBLE=doDouble

    ; Notify parent.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if OBJ_VALID(oParent) then begin
        ;; KDB 4/03 Only call UpdateSelectionVisual if the parent
        ;; is valid, otherwise issue can arise during tool destruction.
        self->UpdateSelectionVisual
        oParent->OnDataComplete, oSubject
    endif
end

;---------------------------------------------------------------------------
; DataSpace Root Interface
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataSpaceRoot::GetCurrentDataSpace
;
; PURPOSE:
;   This function method returns a reference to the currently active
;   dataspace contained by this root.
;
; CALLING SEQUENCE:
;   oDataSpace = Obj->[IDLitVisDataSpaceRoot::]GetCurrentDataSpace()
;
; OUTPUTS:
;   This function method returns a reference to an object that inherits
;   from IDLitVisIDataSpace.
;
; SIDE EFFECTS:
;   If no dataspace is active, the first contained dataspace is
;   returned.  If no dataspace is contained, then it is created and
;   returned.
;-
function IDLitVisDataSpaceRoot::GetCurrentDataSpace

    compile_opt idl2, hidden

    ; If no current dataspace, then retrieve all contained dataspaces,
    ; and set the first as current.
    if (OBJ_VALID(self.oCurrDataSpace) eq 0) then begin

        oDataSpace = self->IDLgrModel::Get(/ALL, COUNT=count, $
            ISA="IDLitVisIDataSpace")

        if (count eq 0) then begin
            ; If no contained dataspaces, create one and add it.
            oLayer = self->_GetLayer()
            if (OBJ_ISA(oLayer, "IDLitgrAnnotateLayer")) then begin
                oDataSpace = OBJ_NEW('IDLitVisNormDataSpace', $
                  /NO_AXES, /NO_PROPERTIES, $
                  TOOL=self->GetTool())
            endif else begin
                oTool = self->GetTool()
                if (OBJ_VALID(oTool)) then begin
                    oVisDesc = oTool->GetVisualization('Data space')
                    if (~OBJ_VALID(oVisDesc)) then $
                        return, OBJ_NEW()
                    oDataSpace = oVisDesc->GetObjectInstance()
                endif else $
                    oDataSpace = OBJ_NEW('IDLitVisNormDataSpace')
            endelse
            if (~OBJ_VALID(oDataSpace)) then $
                return, OBJ_NEW()
            self->Add, oDataSpace
        endif

        self.oCurrDataSpace = oDataSpace[0]

    endif

    return, self.oCurrDataSpace
end

;----------------------------------------------------------------------------
;+
; IDLitVisDataSpaceRoot::SetCurrentDataSpace
;
; PURPOSE:
;   This procedure method sets the currently active dataspace within
;   this root container to the given dataspace.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpaceRoot::]SetCurrentDataSpace, DataSpace
;
; INPUTS:
;   DataSpace:  A reference to an IDLitVisIDataSpace object that is
;     to become the current dataspace.
;
pro IDLitVisDataSpaceRoot::SetCurrentDataSpace, oDataSpace

   compile_opt hidden, idl2

    ; Verify that the given DataSpace is contained within this root.
    if (self->IsContained(oDataSpace) eq 0) then begin
        ;; Don't change from the present.
        return
    endif

    self.oCurrDataSpace = oDataSpace
end

;----------------------------------------------------------------------------
; IDLitVisDataSpaceRoot::Reset
;
; Purpose:
;   This procedure method resets the transform matrix for this
;   dataspace root to identity.
;
; Keywords:
;   NO_NOTIFY: Set this keyword to indicate that notification should
;     not be broadcast to observers.
;
pro IDLitVisDataSpaceRoot::Reset, NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    t = [[1.0,0,0,0], $
         [0.0,1,0,0], $
         [0.0,0,1,0], $
         [0.0,0,0,1]]
    self->SetProperty, TRANSFORM=t, NO_NOTIFY=noNotify
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataSpaceRoot__Define
;
; Purpose:
;   Defines the object structure for an IDLitVisDataSpaceRoot object.
;-
PRO IDLitVisDataSpaceRoot__Define

    compile_opt idl2, hidden

    struct = { IDLitVisDataSpaceRoot,  $
        inherits _IDLitVisualization,  $ ; Superclass: _IDLitVisualization
        oCurrDataSpace: OBJ_NEW(),     $ ; Currently active dataspace
        _b2DRotated: 0b                $ ; If 2D, has the dataspace been
                                       $ ;  rotated?
    }
END
