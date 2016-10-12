; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitvisvertex__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    _IDLitVisVertex
;
; PURPOSE:
;    The _IDLitVisVertex class is a helper class for viz objects with
;    vertex data, such as IDLitVisPolyline and IDLitVisPolygon.
;
; MODIFICATION HISTORY:
;     Written by:   Chris, August 2002
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    _IDLitVisVertex::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('_IDLitVisVertex')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   POINTS_NEEDED: The number of points required by the object before
;        a data change update should be issued. For example, polylines
;        require 2 points, while polygons require 3 points.
;        The default is 1 point.
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function _IDLitVisVertex::Init, POINTS_NEEDED=needed

    compile_opt idl2, hidden

    ; Register the parameters we are using for data
    self->RegisterParameter, 'VERTICES', DESCRIPTION='Vertex data', $
        /INPUT, TYPES=['IDLVERTEX'], /OPTARGET

    self->RegisterParameter, 'CONNECTIVITY', $
        DESCRIPTION='Connectivity array', $
        TYPES='IDLCONNECTIVITY', $
        /INPUT, /OPTIONAL

    self._ptsNeeded = (N_ELEMENTS(needed) gt 0) ? needed : 1

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
;pro _IDLitVisVertex::Cleanup
;    compile_opt idl2, hidden
;end


;---------------------------------------------------------------------------
; _IDLitVisVertex::AddVertex
;
; Purpose:
;    Used to set the location of a vertex.
;
; Parameters:
;   x   - X location
;   y   - Y location
;   z   - Z location
;
; Keywords:
;  WINDOW    - If set, the provided values are in Window coordinates
;              and need to be  converted into visualization coords.
;
pro _IDLitVisVertex::AddVertex, xyz, WINDOW=WINDOW, INITIAL=INITIAL

    compile_opt hidden, idl2

    if(keyword_set(WINDOW))then begin
        self->_IDLitVisualization::WindowToVis, xyz, Pt
    endif else $
        Pt=xyz

    ; Tack on a zero if necessary.
    if (N_ELEMENTS(Pt) eq 2) then $
        Pt = [Pt, 0]

    ; Reset the point list if desired.
    ptsStored = KEYWORD_SET(initial) ? 0 : $
        self->_IDLitVisVertex::CountVertex()

    ; Store the new data.
    oDataObj = self->GetParameter('VERTICES')
    success = oDataObj->GetData(pData, /POINTER)
    *pData = (ptsStored eq 0) ? Pt : [[*pData], [Pt]]
    ptsStored++

    ; Notify our observers if we have enough points.
    if (ptsStored ge self._ptsNeeded) then begin
        oDataObj->NotifyDataChange
        oDataObj->NotifyDataComplete
    endif

end


;---------------------------------------------------------------------------
; _IDLitVisVertex::RemoveVertex
;
; Purpose:
;    Used to remove a vertex.
;
; Parameters:
;   Index: The zero-based vertex index. If not provided, then the last
;   vertex is removed.
;
pro _IDLitVisVertex::RemoveVertex, index

    compile_opt hidden, idl2

    ; If not provided, fill in zero for _CheckVertex, but change below.
    if (N_PARAMS() eq 0) then $
        index = 0

    ; Retrieve the data pointer and check the indices.
    if (~self->_IDLitVisVertex::_CheckVertex(oDataObj, pData, index)) then $
        return

    ; Number of vertices.
    ptsStored = (SIZE(*pData, /N_DIM) eq 1) ? 1 : $
        (SIZE(*pData, /DIMENSIONS))[1]

    ; Note that we are directly modifying the data pointer.
    if (N_PARAMS() eq 0) || (index eq (ptsStored-1)) then begin
        ; Remove the last vertex.
        *pData = (ptsStored gt 1) ? (*pData)[*, 0:ptsStored-2] : 0
    endif else begin
        ; Remove a vertex.
        *pData = (index eq 0) ? (*pData)[*, 1:*] : $
             [[ (*pData)[*, 0:index-1] ], [ (*pData)[*, index+1:*] ]]
    endelse

    ; We removed it.
    ptsStored--

    ; Notify our observers if we have enough points.
    ; NOTE: What happens if we don't have enough? Then our vertex list
    ; is out of sync with what is stored in the graphics object.
    if (ptsStored ge self._ptsNeeded) then begin
        oDataObj->NotifyDataChange
        oDataObj->NotifyDataComplete
    endif

end


;---------------------------------------------------------------------------
; Internal routine to verify that the indices are within the vertex list.
; Returns 1 for success, 0 for failure.
;
function _IDLitVisVertex::_CheckVertex, oDataObj, pData, index

    compile_opt hidden, idl2

    oDataObj = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oDataObj) || $
        ~oDataObj->GetData(pData, /POINTER)) then $
        return, 0

    ; Fail if we don't have a single vertex.
    if (N_ELEMENTS(*pData) lt 3) then $
        return, 0

    ; Number of vertices.
    ptsStored = (SIZE(*pData, /N_DIM) eq 1) ? 1 : $
        (SIZE(*pData, /DIMENSIONS))[1]

    if (N_ELEMENTS(index) eq 0) then begin
        ; If no index was provided, set it to the final vertex.
        index = ptsStored-1
        status = 1
    endif else begin
        ; Check provided index array.
        status = ((MAX(index, MIN=minn) lt ptsStored) && (minn ge 0))
    endelse

    return, status
end


;---------------------------------------------------------------------------
; _IDLitVisVertex::CountVertex
;
; Purpose:
;   Retrieve the number of vertices within the data object.
;   Assumes vertices are always 3 dimensional (x,y,z).
;
function _IDLitVisVertex::CountVertex

    compile_opt hidden, idl2

    oDataObj = self->GetParameter('VERTICES')
    if (OBJ_VALID(oDataObj) eq 0) || $
        (oDataObj->GetData(pData, /POINTER) eq 0) then $
        return, 0

    ; Zero vertices?
    if (N_ELEMENTS(*pData) lt 3) then $
        return, 0

    ; Number of vertices.
    return, $
        (SIZE(*pData, /N_DIM) eq 1) ? 1 : (SIZE(*pData, /DIM))[1]

end


;---------------------------------------------------------------------------
; _IDLitVisVertex::GetVertex
;
; Purpose:
;   Used to retrieve the location of a data point.
;
; Parameters:
;   Index: A scalar or vector giving the indices of the vertices to return.
;
; Keywords:
;  WINDOW    - If set, the values should be converted from
;              visualization coordinates to Window coords.
;
function _IDLitVisVertex::GetVertex, index, WINDOW=WINDOW

    compile_opt hidden, idl2

    ; Retrieve the data pointer and check the indices.
    if (~self->_IDLitVisVertex::_CheckVertex(oDataObj, pData, index)) then $
        return, -1

    if (not KEYWORD_SET(window)) then $
        return, (*pData)[*, index]

    self->_IDLitVisualization::VisToWindow, (*pData)[*, index], dataOut

    return, dataOut
end


;---------------------------------------------------------------------------
; _IDLitVisVertex::MoveVertex
;
; Purpose:
;    Used to move the location of a data vertex.
;
; Parameters:
;   XYZ: An array of dimensions (2,n) or (3,n) giving the vertices.
;
; Keywords:
;  INDEX:   Set this keyword to a scalar or vector representing the
;    indices of the of the vertices to be moved.  By default, the final
;    vertex is moved.
;
;  WINDOW    - If set, the provided values are in Window coordinates
;              and need to be  converted into visualization coords.
;
pro _IDLitVisVertex::MoveVertex, xyz, INDEX=index, WINDOW=WINDOW

    compile_opt hidden, idl2

    ; Retrieve the data pointer and check the indices.
    if (~self->_IDLitVisVertex::_CheckVertex(oDataObj, pData, index)) then $
        return

    ; Number of vertices.
    ptsStored = (SIZE(*pData, /N_DIM) eq 1) ? 1 : $
        (SIZE(*pData, /DIMENSIONS))[1]

    nDim = (SIZE(xyz, /DIMENSIONS))[0]

    if(keyword_set(WINDOW))then $
        self->_IDLitVisualization::WindowToVis, xyz, visXYZ $
    else $
        visXYZ = xyz

    ; Note that we are directly modifying the data pointer.
    (*pData)[0:nDim-1, index] = TEMPORARY(visXYZ)

    ; If only 2D vertices, then zero out the Z values.
    if (nDim eq 2) then $
        (*pData)[2, index] = 0

    ; Notify our observers if we have enough points.
    if (ptsStored ge self._ptsNeeded) then begin
        oDataObj->NotifyDataChange
        oDataObj->NotifyDataComplete
    endif

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; _IDLitVisVertex__Define
;
; PURPOSE:
;    Defines the object structure for an _IDLitVisVertex object.
;
;-
pro _IDLitVisVertex__Define

    compile_opt idl2, hidden

    struct = { _IDLitVisVertex,           $
               _ptsNeeded: 0 $
             }
end
