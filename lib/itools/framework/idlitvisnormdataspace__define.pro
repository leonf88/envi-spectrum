; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisnormdataspace__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisNormDataSpace
;
; PURPOSE:
;   The IDLitVisNormDataSpace class is a visualization that represents
;   a data space (of any XYZ range) that is normalized to a [-1...1] space.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitVisNormalizer
;   IDLitVisIDataSpace
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::Init
;
; PURPOSE:
;   The IDLitVisNormDataSpace::Init function method initializes this
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
;   oNormDataSpace = OBJ_NEW('IDLitVisNormDataSpace')
;
;   or
;
;   Obj->[IDLitVisNormDataSpace::]Init
;
;-
function IDLitVisNormDataSpace::Init, $
    DATASPACE_CLASSNAME=dataspaceClassName, $
    DESCRIPTION=inDescription, $
    NO_PROPERTIES=NO_PROPERTIES, $ ;; for range properties
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name and description.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Data Space"
    description = (N_ELEMENTS(inDescription) ne 0) ? $
        inDescription : "Normalized Data Space"

    ; Initialize superclasses.
    if (self->IDLitVisNormalizer::Init($
        /MANIPULATOR_TARGET, $
        DESCRIPTION=description, $
        NAME=name, $
        TYPE="DATASPACE_2D", $
        ICON="dataspace", $
        /REGISTER_PROPERTIES, $
        _EXTRA=_extra) NE 1) then $
        return, 0

    ; Create the dataspace.
    className = (N_ELEMENTS(dataspaceClassName) ne 0) ? $
        dataspaceClassName : "IDLitVisDataSpace"
    self._dataSpace = OBJ_NEW(className, $
                              NO_PROPERTIES=NO_PROPERTIES, _EXTRA=_extra)
    if (OBJ_VALID(self._dataSpace) eq 0) then begin
        self->Cleanup
        return, 0
    endif

    self->IDLitVisNormalizer::Add, self._dataSpace, /AGGREGATE
    self._DataSpace->SetProperty, _PARENT=self

    ; Change the target container for self so that added
    ; items are added to the contained data space.
    self->_IDLitContainer::SetProperty, CLASSNAME=className, $
        CONTAINER=self._dataSpace

    ; Change the _PARENT property for the data space contents to be
    ; this normalized data space (i.e., self) instead.
    oObjs = self._dataspace->Get(/ALL, COUNT=nObjs)
    for i=0,nObjs-1 do begin
        oChild = oObjs[i]
        if (OBJ_VALID(oChild) ne 0) then $
            oChild->SetProperty, _PARENT=self
    endfor

    ; Allow the dataspace root to be the manipulator target.
;    self->_IDLitVisualization::SetProperty, $
;        MANIPULATOR_TARGET=0
;    self._dataspace->_IDLitVisualization::SetProperty, MANIPULATOR_TARGET=0

    return, 1
end


;----------------------------------------------------------------------------
; PURPOSE:
;      The IDLitVisNormDataSpace::Cleanup procedure method preforms all cleanup
;      on the object.
;
pro IDLitVisNormDataSpace::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->IDLitVisNormalizer::Cleanup
end


;----------------------------------------------------------------------------
; IMessaging Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; IDLitVisNormDataSpace::_SetTool
;
; Purpose:
;   Called by the framework internals to set the tool that this
;   interface can communcate with. Without this connection
;   established, nothing (well, almost nothing) will operate in this
;   class.
;
;   At the object interface exposed to the user, they are not aware
;   of this method. This is normally called by the object description
;   system when framework objects are accessed/created.
;
;   This method overrides the IDLitIMessaging::_SetTool method.
;   This specialized version passes along the tool setting to the
;   contained dataspace.
;
; Parameters
;    oTool    - The operating environment for this session
PRO IDLitVisNormDataSpace::_SetTool, oTool
    compile_opt idl2, hidden

    self->_IDLitVisualization::_SetTool, oTool

    if (OBJ_VALID(self._dataspace)) then $
        self._dataspace->_SetTool, oTool
end

;----------------------------------------------------------------------------
; IIDLVisIDataSpace Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormDataSpace::SetXYZRange
;
; PURPOSE:
;      The IDLitVisNormDataSpace::SetXYZRange procedure method sets
;      the range of the axes used in the data space
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisNormDataSpace::]SetXYZRange, XRange, YRange, ZRange
;
; INPUTS:
;      XRange: A two-element vector, [xmin, xmax], representing
;              the X-axis range.
;      YRange: A two-element vector, [ymin, ymax], representing
;              the Y-axis range.
;      ZRange: A two-element vector, [zmin, zmax], representing
;              the Z-axis range.
;
;-
pro IDLitVisNormDataSpace::SetXYZRange, XRange, YRange, ZRange

    compile_opt idl2, hidden

    if (OBJ_VALID(self._dataspace) ne 0) then $
        self._dataspace->SetProperty, $
            X_MINIMUM=XRange[0], X_MAXIMUM=XRange[1], $
            Y_MINIMUM=YRange[0], Y_MAXIMUM=YRange[1], $
            Z_MINIMUM=ZRange[0], Z_MAXIMUM=ZRange[1]
end
;---------------------------------------------------------------------------
; IDLitVisNormDataSpace::GetVisualizations
;
; PURPOSE:
;   Returns the current visualizations contained in the
;   dataspace. This is just a pass through to the underlying
;   dataspace.

function IDLitVisNormDataSpace::GetVisualizations, $
    count=count, $
    FULL_TREE=fullTree

    compile_opt idl2, hidden

    count=0
    return, (OBJ_VALID(self._dataspace) ne 0 ? $
        self._dataspace->GetVisualizations( $
            count=count, FULL_TREE=fullTree) : obj_new())
end
;---------------------------------------------------------------------------
; IDLitVisNormDataSpace::GetAxes
;
; Purpose:
;   Returns the current Axes contained in the dataspace. 
;   This is just a pass through to the underlying dataspace.
;
; Keywords:
;   CONTAINER - Set this keyword to a non-zero value to indicate
;      that the axes container should be returned.  By default,
;      the axes within the container are returned.
;
;   COUNT   - The number of items returned.
;
function IDLitVisNormDataSpace::GetAxes, CONTAINER=container, COUNT=count

    compile_opt idl2, hidden

    count=0
    return, (OBJ_VALID(self._dataspace) ne 0 ? $
        self._dataspace->GetAxes(CONTAINER=container, COUNT=count) : obj_new())
end

;----------------------------------------------------------------------------
; +
; METHODNAME:
;   IDLitVisNormDataSpace::SetPixelDataSize
;
; PURPOSE:
;   This procedure method changes the current X and Y range of the
;   dataspace so that a single pixel will correspond to the given
;   data dimensions.
;
;   Note that this function assumes that the dataspace is currently
;   2D.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace::]SetPixelDataSize, PixelXSize, PixelYSize
;
; INPUTS:
;   PixelXSize: A scalar representing the requested data dimensions of
;   a single pixel in X.
;
;   PixelYSize: A scalar representing the requested data dimensions of
;   a single pixel in Y.
;-
pro IDLitVisNormDataSpace::SetPixelDataSize, pixelXSize, pixelYSize

    compile_opt idl2, hidden

    if (OBJ_VALID(self._dataspace)) then begin
        ; Turn off isotropic scaling.
        self->IDLitVisNormalizer::SetProperty, SCALE_ISOTROPIC=2

        ; Renormalize since isotropy may have changed.  This
        ; allows the following SetPixelDataSize to work properly
        ; (the window coordinates of the corners of the dataspace
        ; will be correct).
        self->Normalize

        self._dataspace->SetPixelDataSize, pixelXSize, pixelYSize

        ; Disable the automatic range updates.
        self->SetProperty, X_AUTO_UPDATE=0, Y_AUTO_UPDATE=0, Z_AUTO_UPDATE=0

    endif
end

;---------------------------------------------------------------------------
; Name:
;   IDLitVisNormDataSpace::RequiresDouble
;
; Purpose:
;   This function method reports whether this dataspace range requires
;   double precision.
;
; Return value:
;   This function method returns a 1 if the dataspace requires double
;   precision, or 0 otherwise.
;
function IDLitVisNormDataSpace::RequiresDouble
    compile_opt idl2, hidden

    ; To be implemented by subclass!

    if (OBJ_VALID(self._dataspace)) then $
        return, self._dataspace->RequiresDouble()

    return, 0b
end

;---------------------------------------------------------------------------
; IIDLVisNormalizer Interface
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormDataSpace::Normalize
;
; PURPOSE:
;      The IDLitVisNormDataSpace::Normalize procedure method applies the
;      appropriate normalization factors based upon the XYZ range of its
;      contents.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace::]Normalize
;
;-
pro IDLitVisNormDataSpace::Normalize
    compile_opt idl2, hidden

    bValidRange = self._dataspace->_GetXYZAxisRange( $
        XRange, YRange, ZRange, /NO_TRANSFORM, $
        XREVERSE=xReverse, YREVERSE=yReverse, ZREVERSE=zReverse)

    if (bValidRange ne 0) then $
        self->NormalizeToRange, $
            (xReverse ? REVERSE(XRange) : XRange), $
            (yReverse ? REVERSE(YRange) : YRange), $
            (zReverse ? REVERSE(ZRange) : ZRange)
end


;---------------------------------------------------------------------------
; IIDLVisualization Interface
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::OnDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnDimensionChange implementation
;   so that the type can be changed from DATASPACE_2D to DATASPACE_3D or
;   vise versa.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace:]OnDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro IDLitVisNormDataSpace::OnDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    ; Keep a copy of original 3D setting.
    old3D = self.is3D

    ; Call superclass.
    self->_IDLitVisualization::OnDimensionChange, oSubject, is3D

    ; Check for change in own dimensionality.
    if (self.is3D ne old3D) then begin
        ; Change our type! Is this dangerous?
        self->SetProperty, TYPE=self.is3D ? 'DATASPACE_3D' : 'DATASPACE_2D'
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::OnAxesRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesRequestChange implementation
;   so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace:]OnAxesRequestChange, Subject, axesRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes request change.
;   axesRequest: new axes request setting of Subject.
;-
pro IDLitVisNormDataSpace::OnAxesRequestChange, oSubject, axesRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::OnAxesStyleRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes style request
;   of a contained object has changed.
;
;   This override the _IDLitVisualization::OnAxesStyleRequestChange 
;   implementation so that the request is not propagated to the parent.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace:]OnAxesStyleRequestChange, Subject,styleRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes style request change.
;   styleRequest: new style request setting of Subject.
;-
pro IDLitVisNormDataSpace::OnAxesStyleRequestChange, oSubject, styleRequest

    compile_opt idl2, hidden

    ;NO-OP

    return
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::GetTargetDataSpace
;
; PURPOSE:
;   This function method retrieves the dataspace being normalized
;   within this object.
;
; CALLING SEQUENCE:
;   oDataSpace = Obj->[IDLitVisNormDataSpace::]GetTargetDataSpace()
;
; INPUTS:
;   None.
;
;-
function IDLitVisNormDataSpace::GetTargetDataSpace

    compile_opt idl2, hidden

    return, self._dataspace
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::GetDataSpace
;
; PURPOSE:
;   This function method retrieves the dataspace associated with
;   this object.  [Note: this implementation overrides the implementation
;   within the _IDLitVisualization class.]
;
; CALLING SEQUENCE:
;   oDataSpace = Obj->[IDLitVisNormDataSpace::]GetDataSpace()
;
; INPUTS:
;   None.
;
; KEYWORDS:
;   UNNORMALIZED:   Set this keyword to a non-zero value to indicate
;     that the returned dataspace should subclass from 'IDLitVisDataSpace'
;     rather than 'IDLitVisNormDataSpace'.
;
; OUTPUTS:
;   This function returns a reference to the dataspace associated
;   with this object, or a null object reference if no dataspace
;   is found.
;-
function IDLitVisNormDataSpace::GetDataSpace, $
    UNNORMALIZED=unNormalized

    compile_opt idl2, hidden

    if (KEYWORD_SET(unNormalized)) then $
        return, self._dataspace $
    else $
        return, self
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::GetDataSpaceRoot
;
; PURPOSE:
;   This function method retrieves the dataspace root that contains
;   this dataspace.
;
; CALLING SEQUENCE:
;   oDataSpaceRoot = Obj->[IDLitVisNormDataSpace::]GetDataSpaceRoot()
;
; INPUTS:
;   None.
;
; OUTPUTS:
;   This function returns a reference to the dataspace root associated
;   with this object, or a null object reference if no dataspace root
;   is found.
;-
function IDLitVisNormDataSpace::GetDataSpaceRoot

    compile_opt idl2, hidden

    ; Check the PARENT of this dataspace to see if it is a 
    ; dataspace root.
    self->GetProperty, PARENT=oParent
    if (OBJ_ISA(oParent,'IDLitVisDataSpaceRoot')) then $
        return, oParent

    ; Evidently this dataspace is not immediately contained within 
    ; a dataspace root.  
    return, OBJ_NEW()
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormDataSpace::Add
;
; PURPOSE:
;      The IDLitVisNormDataSpace::Add procedure method adds
;      the given items to this container.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisNormDataSpace::]Add, oObjects, _EXTRA=_extra
;
; INPUTS:
;      oObjects:    A reference (or array of references) to the
;       object(s) to be added to this normalized data space.
;-
pro IDLitVisNormDataSpace::Add, oObjects, _EXTRA=_extra

    compile_opt idl2, hidden

    isManipVis = OBJ_ISA(oObjects, "IDLitManipulatorVisual")
    iManipVis = WHERE(isManipVis, nManipVis, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)

    ; Manipulator Visuals are added to myself directly.
    if (nManipVis gt 0) then $
        self->IDLgrModel::Add, oObjects[iManipVis]

    ; Everything else is added to the internal data space.
    if (nOther gt 0) then $
        CALL_METHOD, self._classname+'::Add', self._dataspace, $
            oObjects[iOther], /USE__PARENT, _EXTRA=_extra
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormDataSpace::Remove
;
; PURPOSE:
;      The IDLitVisNormDataSpace::Remove procedure method removes
;      the given items from this container.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisNormDataSpace::]Remove, oObjects, _EXTRA=_extra
;
; INPUTS:
;      oObjects:    A reference (or array of references) to the
;       object(s) to be removed from this normalized data space.
;-
pro IDLitVisNormDataSpace::Remove, oObjects, _EXTRA=_extra

    compile_opt idl2, hidden

    isManipVis = OBJ_ISA(oObjects, "IDLitManipulatorVisual")
    iManipVis = WHERE(isManipVis, nManipVis, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)

    ; Manipulator Visuals are removed from myself directly.
    if (nManipVis gt 0) then $
        self->IDLgrModel::Remove, oObjects[iManipVis]

    ; Everything else is removed from the internal data space.
    if (nOther gt 0) then $
        CALL_METHOD, self._classname+'::Remove', self._dataspace, $
            oObjects[iOther], _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitVisNormDataSpace::GetByIdentifier
;
; Purpose:
;   This method emulates the Get method of the IDL container
;   class. This method will use the provided path to determine the
;   the actual container in the hierachy.
;
; Parameters:
;   strInput - The ID to the location to add the item. If an empty
;              string, the value is removed to this container.
;              Otherwise, the next entry in the path is
;              poped off, the contents are searched for a match of
;              that value and if a match is found, the search
;              continues.
;
; Return Value
;   The object being searched for. If nothing was found, a null
;   object is returned.

function IDLitVisNormDataSpace::GetByIdentifier, strInput
  compile_opt idl2, hidden
  
  oObj = self->_IDLitContainer::GetByIdentifier(strInput)
  if (OBJ_VALID(oObj)) then $
    return, oObj
    
  ; Look at items contained within the model, instead of the dataspace
  strItem  = IDLitBasename(strInput, remainder=strRemain, /reverse)

  oItems = self->IDLgrModel::Get(/ALL, COUNT=nItems)
  
  for i=0, nItems-1 do begin
    if (~obj_valid(oItems[i])) then $
      continue
    oItems[i]->IDLitComponent::GetProperty, IDENTIFIER=strTmp
    if (strItem eq strTmp) then begin
      ; If more information exists in the path and the
      ; object isa container traverse down
      if (~strRemain) then $
        return, oItems[i]
      if (obj_isa(oItems[i], "_IDLitContainer")) then $
        return, oItems[i]->GetByIdentifier(strRemain)
      break ; if we are here, this will case a null retval
    endif
  endfor
  
  return, obj_new()
  
end


;----------------------------------------------------------------------------
; METHODNAME:
;   IDLitVisNormDataSpace::_CheckDimensionChange
;
; PURPOSE:
;   This procedure method determines whether the dimensionality of
;   this dataspace needs to be changed.  If so, the ::Set3D
;   method will be called with the appropriate new 3D setting.
;
;   This overrides the _IDLitVisualization implementation of this
;   method.  In this case, it simply checks the contained dataspace.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace::]_CheckDimensionChange
;
; SIDE EFFECTS:
;   If the dimensionality has changed, the ::Set3D method will
;   be called, causing the self.is3D field to be modified.
;-
pro IDLitVisNormDataSpace::_CheckDimensionChange

    compile_opt idl2, hidden

    ; Check dimensionality of contained dataspace.
    is3D = OBJ_VALID(self._dataspace) ? self._dataspace->is3D() : 0

    if (is3D ne self.is3D) then $
        self->Set3D, is3D
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::GetXYZRange
;
; PURPOSE:
;   This function method overrides the IDLgrModel::GetXYZRange function.
;
; CALLING SEQUENCE:
;   Success = Obj->[IDLitVisNormDataSpace::]GetXYZRange( $
;    xRange, yRange, zRange [, /NO_TRANSFORM])
;
; ARGUMENTS
;    xRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [xmin, xmax], representing the
;       X range of the objects that impact the ranges.
;    yRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [ymin, ymax], representing the
;       Y range of the objects that impact the ranges.
;    zRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [zmin, zmax], representing the
;       Z range of the objects that impact the ranges.
;
; KEYWORD PARAMETERS:
;    NO_TRANSFORM:  Set this keyword to indicate that this Visualization's
;       model transform should not be applied when computing the XYZ ranges.
;       By default, the transform is applied.
;
;-
function IDLitVisNormDataSpace::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=data, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    ; Default return values.
    outxRange = [0.0d, 0.0d]
    outyRange = [0.0d, 0.0d]
    outzRange = [0.0d, 0.0d]

    bIsValid = self._dataspace->_GetXYZAxisRange($
        xRange, yRange, zRange)
    if (bIsValid eq 0) then return, 0

    ; Apply normalize model transform.
    self._normalizeModel->GetProperty, TRANSFORM=transform
    self->_AccumulateXYZRange, 0, $
        outxRange, outyRange, outzRange, $
        xRange, yRange, zRange, $
        TRANSFORM=transform

    ; If requested, apply self's transform.
    if (KEYWORD_SET(noTransform) eq 0) then begin
        self->GetProperty, TRANSFORM=transform
        xRange = outxRange
        yRange = outyRange
        zRange = outzRange
        self->_AccumulateXYZRange, 0, $
            outxRange, outyRange, outzRange, $
            xRange, yRange, zRange, $
            TRANSFORM=transform
    endif

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::SetAxesRequest
;
; PURPOSE:
;   This procedure method marks this dataspace as either requesting
;   axes, or not.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataSpace::]SetAxesRequest[, axesRequest]
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
;-
pro IDLitVisNormDataSpace::SetAxesRequest, inAxesRequest, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute

    compile_opt idl2, hidden

    ; Simply pass along to contained dataspace.
    axesRequest = (N_PARAMS() lt 1) ? 1 : inAxesRequest
    if (OBJ_VALID(self._dataspace)) then begin
        self._dataspace->SetAxesRequest, axesRequest, $
            ALWAYS=always, AUTO_COMPUTE=autoCompute
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace::SetAxesStyleRequest
;
; PURPOSE:
;   This procedure method sets the axes style request for this
;   dataspace.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormDataspace:]SetAxesStyleRequest[, styleRequest]
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
pro IDLitVisNormDataSpace::SetAxesStyleRequest, styleRequest, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    ; Simply pass along to contained dataspace.
    if (OBJ_VALID(self._dataspace)) then begin
        self._dataspace->SetAxesStyleRequest, styleRequest, $
            /NO_NOTIFY
    endif
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormDataSpace__Define
;
; PURPOSE:
;   Defines the object structure for an IDLitVisNormDataSpace object.
;-
pro IDLitVisNormDataSpace__Define
    compile_opt idl2, hidden

    struct = { IDLitVisNormDataSpace, $
        inherits IDLitVisNormalizer,  $ ; Superclass: IDLitVisNormalizer
        inherits IDLitVisIDataSpace,  $ ; Interface: IDLitVisIDataSpace
        _dataspace: OBJ_NEW()         $ ; Reference to IDLitVisDataSpace obj
    }
end

