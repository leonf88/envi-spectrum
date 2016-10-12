; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopplotprofile__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopPlotProfile
;
; PURPOSE:
;   This file implements the operation that takes endpoints supplied
;   by the line profile manipulator and operation and creates a plot.
;   The plot represents the data of the selected visualization at the
;   location specified by the manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopPlotProfile::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopPlotProfile::Init
;   IDLitopPlotProfile::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopPlotProfile::Init
;;
;; Purpose:
;; The constructor of the IDLitopPlotProfile object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopPlotProfile::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Plot Profile", $
                                       DESCRIPTION='Plot Profile', $
                                       TYPE=['IDLLINEPROFILE'], $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'LINEPROFILEOP_INVOCATION', /BOOLEAN, $
        NAME='line Profile invocation', $
        DESCRIPTION='Invoked by Line Profile operation', $
        /HIDE

    ; default is menu invocation on existing line profile annotation
    ; line profile operation will clear this flag prior to invoking
    self._lineProfileOpInvocation = 0;

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopPlotProfile::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopPlotProfile::GetProperty,        $
    LINEPROFILEOP_INVOCATION=lineProfileOpInvocation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(lineProfileOpInvocation)) then $
        lineProfileOpInvocation = self._lineProfileOpInvocation

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopPlotProfile::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopPlotProfile::SetProperty,      $
    LINEPROFILEOP_INVOCATION=lineProfileOpInvocation, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(lineProfileOpInvocation) ne 0) then begin
        self._lineProfileOpInvocation = lineProfileOpInvocation
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopPlotProfile::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopPlotProfile object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopPlotProfile::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end



;---------------------------------------------------------------------------
; IDLitopPlotProfile::_encode
;
; Purpose:
;  Utility function for _clipLine.
;
; Parameters:
;   pt:  two element vector specifying a point
;
;   rect: four element vector for the rectangle [xmin,xmax,ymin,ymax]
;
; Return Value:
;   bitmask denoting whether x and/or y fall outside of rectangle
;
function IDLitopPlotProfile::_encode, pt, rect

    compile_opt idl2, hidden

    code = 0b
    if pt[0] lt rect[0] then code = code + 1b
    if pt[0] gt rect[1] then code = code + 2b
    if pt[1] lt rect[2] then code = code + 4b
    if pt[1] gt rect[3] then code = code + 8b
    return, code

end

;---------------------------------------------------------------------------
; IDLitopPlotProfile::_clipLine
;
; Purpose:
;  Implementation of Cohen-Sutherland line clipping algorithm
;
; Parameters: (should all be of the same type)
;  p1, p2 - Line end points.  The clipped line is returned in these parameters.
;           The parameters are passed as [x, y].
;  rect - The clipping rectangle, passed in the array:
;         [left, right, bottom, top]
;
; Return Value:
;  Returns 1 if any part of the line is within the clip rect after clipping.
;  Returns 0 if no part of the line is within the clip rect after clipping.
;
function IDLitopPlotProfile::_clipLine, p1, p2, rect

    compile_opt idl2, hidden

    done = 0b
    repeat begin
        ;; Compute clip codes
        code1 = self->_encode(p1, rect)
        code2 = self->_encode(p2, rect)
        ;; trivial accept
        if (code1 or code2) eq 0 then $
            return, 1
        ;; trivial reject
        if (code1 and code2) ne 0 then $
            return, 0
        ;; At least one point is outside
        ;; Swap to ensure that p1 is outside
        swap = 0b
        if code1 eq 0 then begin
            tmp = code1 & code1 = code2 & code2 = tmp
            tmp = p1 & p1 = p2 & p2 = tmp
            swap = 1b
        endif
        ;; Check for vertical
        if p1[0] eq p2[0] then begin
            p1[1] = (p1[1] > rect[2]) < rect[3]
        endif $
        ;; Compute intersection with rect
        else begin
            slope = DOUBLE(p2[1]-p1[1]) / DOUBLE(p2[0]-p1[0])
            if (code1 and 1) ne 0 then begin
                p1[1] = p1[1] + (rect[0] - p1[0]) * slope
                p1[0] = rect[0]
            endif else $
            if (code1 and 2) ne 0 then begin
                p1[1] = p1[1] + (rect[1] - p1[0]) * slope
                p1[0] = rect[1]
            endif else $
            if (code1 and 4) ne 0 then begin
                p1[0] = p1[0] + (rect[2] - p1[1]) / slope
                p1[1] = rect[2]
            endif else $
            if (code1 and 8) ne 0 then begin
                p1[0] = p1[0] + (rect[3] - p1[1]) / slope
                p1[1] = rect[3]
            endif
        endelse
        ;; Swap back to keep the line direction invariant
        if swap then begin
            tmp = code1 & code1 = code2 & code2 = tmp
            tmp = p1 & p1 = p2 & p2 = tmp
        endif
    endrep until done

end

;---------------------------------------------------------------------------
; IDLitopPlotProfile::_CreatePlotProfile
;
; Purpose:
;  Create Line Profile Plot
;
; Parameters:
;  oTool: iTool object reference
;
;  pt0/pt1:  endpoints of the line
;
pro IDLitopPlotProfile::_CreatePlotProfile, oTool, oLine, oSelVis, $
                                RECURSE=recurse

    compile_opt idl2, hidden

    ;; Make sure we have a tool.
    if not OBJ_VALID(oTool) then $
        return

    ;; Check the selected object.
    if not OBJ_VALID(oSelVis) then $
        return

    ; alternate case is for an image (~isSurface)
    isSurface = obj_isa(oSelVis, 'IDLITVISSURFACE')

    pt0 = oLine->GetVertex(0)
    pt1 = oLine->GetVertex(1)
    IF ~isSurface THEN BEGIN
        pt0[2] = 0
        pt1[2] = 0
    ENDIF

    nData = oSelVis->GetParameterDataByType(['IDLARRAY2D'], oDataObjs)
    if nData eq 0 then $
        return

    ;; Adjust points for image origin and size
    if ~isSurface then begin
        oSelVis->GetProperty, XORIGIN=XOrigin, YORIGIN=YOrigin, $
            PIXEL_XSIZE=pixelXSize, PIXEL_YSIZE=pixelYSize
        pt0[0] = (pt0[0]-XOrigin)/pixelXSize
        pt0[1] = (pt0[1]-YOrigin)/pixelYSize
        pt1[0] = (pt1[0]-XOrigin)/pixelXSize
        pt1[1] = (pt1[1]-YOrigin)/pixelYSize
    endif

    ;; get xData
    oXData = oSelVis->GetParameter('X')
    xSuccess = (obj_valid(oXData) ? oXData->getData(xData) : 0)
    ;; get yData
    oYData = oSelVis->GetParameter('Y')
    ySuccess = (obj_valid(oYData) ? oYData->getData(yData) : 0)

    ;; Take a quick look to see if any lines are not clipped out.
    ;; We don't want to create a plot tool with all the lines clipped out.
    vis = 0
    for iData=0, nData-1 do begin
        success = oDataObjs[iData]->GetData(pData, /POINTER)
        if success eq 0 then continue
        dims = SIZE(*pData, /DIMENSIONS)
        p0 = DOUBLE(pt0)
        p1 = DOUBLE(pt1)
        rect = dblarr(4)
        ;; if X and Y vectors exist use them, else use data dimensions
;        rect[0:1] = [0,dims[0]-1]
;        rect[2:3] = [0,dims[1]-1]
        rect[0:1] = ((xSuccess && isSurface) ? [min(xData,max=max),max] : [0,dims[0]-1])
        rect[2:3] = ((ySuccess && isSurface) ? [min(yData,max=max),max] : [0,dims[1]-1])
        vis = self->_clipLine( p0, p1, rect )
        if vis gt 0 then $
            break
    endfor
    if vis eq 0 then $
        return

    ;; Create/Get our Plot Profile tool as needed.
    oNewTool = oTool->GetByIdentifier(self._strToolID)
    if not OBJ_VALID(oNewTool) then begin
        self._strToolID = IDLitSys_CreateTool("Plot Tool", $
                                              NAME="Plot Profile",$
                                              TITLE='IDL Plot Profile')
        oNewTool = oTool->GetByIdentifier(self._strToolID)
    endif

    ;; Get the create viz operation.
    oCreateVis = oNewTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreateVis)) then $
        return

    colorTab = [ [255,0,0], [0,255,0], [0,0,255],$
                 [255,255,0], [255,0,255], [0,255,255] ]

    ;; Get manip line's OUTPUT LINE parameter so we can wire it to
    ;; each Plot Line's INPUT LINE parameter
    oLineParm = oLine->GetParameter('LINE')
    oLine3DParm = oLine->GetParameter('LINE3D')

    ;; If the assoc vis is a surface, then we really only want the
    ;; surface data, not any associated texture map planes.
    ;; A good thought for the future is to create two plot profile tools,
    ;; one with the surface data, and another with the texture map planes.
    if isSurface then $
        nData = 1

    ;; for each channel
    for iData=0, nData-1 do begin

        success = oDataObjs[iData]->GetData(pData, /POINTER)
        if success eq 0 then continue

        ;; Need to clip
        dims = SIZE(*pData, /DIMENSIONS)
        p0 = DOUBLE(pt0)
        p1 = DOUBLE(pt1)
        rect = DBLARR(4)
        ;; if X and Y vectors exist use them, else use data dimensions
;        rect[0:1] = [0,dims[0]]
;        rect[2:3] = [0,dims[1]]
        rect[0:1] = ((xSuccess && isSurface) ? [min(xData,max=max),max] : [0,dims[0]])
        rect[2:3] = ((ySuccess && isSurface) ? [min(yData,max=max),max] : [0,dims[1]])
        vis = self->_clipLine( p0, p1, rect )
        if vis eq 0 then continue

        ;; Build Parm Set
        oParmSet = OBJ_NEW('IDLitParameterSet', $
                           DESCRIPTION='Plot Profile', NAME='Plot Profile',$
                           TYPE='Plot', ICON='plot')

        ;; Wire up Image parm
        oParmSet->Add, oDataObjs[iData], PARAMETER_NAME='IMAGE', /PRESERVE_LOCATION

        ;; Set the line data and wire up the Line Parm
        if ~isSurface then begin
            p0[0] = p0[0] * pixelXSize + XOrigin
            p0[1] = p0[1] * pixelYSize + YOrigin
            p1[0] = p1[0] * pixelXSize + XOrigin
            p1[1] = p1[1] * pixelYSize + YOrigin
        endif
        line = [[p0[0], p0[1], 0], [p1[0], p1[1], 0]]
        success = oLineParm->SetData(line)
        oParmSet->Add, oLineParm, PARAMETER_NAME='LINE'

        ;; if associated visualization is a surface then handle the 3D case
        if isSurface THEN BEGIN
            oLine->create3DLine,[[pt0], [pt1]],outdata=outdata
            success = oLine3DParm->SetData(outdata)
            oParmSet->Add, oLine3DParm, PARAMETER_NAME='LINE3D'
        endif $
        else begin
            ;; Update the line visualization with the clipped version of the line.
            oLine->SetProperty, _DATA=line
        endelse

        ;; Dummy parm for the plot data
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', NAME='X', /NULL), $
            PARAMETER_NAME='X'
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', NAME='Y', /NULL), $
            PARAMETER_NAME='Y'

        ;; Figure out the color
        if nData gt 1 then $
            color = colorTab[*, iData mod N_ELEMENTS(colorTab[0,*])]
        ; Otherwise leave COLOR undefined so it picks up the current style.

        ;; Give the data a reasonable name
        lineName = "Plot Profile" + STRCOMPRESS(STRING(iData))
        oLineParm->SetProperty, NAME=lineName+" Data"

        ;; Create the plot line profile visualization
        oCommandSet = oCreateVis->CreateVisualization(oParmSet, $
            "PLOT PROFILE", $
            COLOR=color, $
            NAME=lineName, $
            ID_VISUALIZATION=idVis)
        OBJ_DESTROY, oCommandSet    ; not undoable

        ;; remove duplicate items
        oParmSet->Remove,oParmSet->GetByName('IMAGE')
        ;; Add to Data Manager so that Paste Special works
        oTool->AddByIdentifier, "/Data Manager", oParmSet

        ;; Set the associated vis prop in the plot profile
        oPlotProfile = oTool->GetByIdentifier(idVis)
        oPlotProfile->SetProperty, $
            ASSOCIATED_VISUALIZATION=oSelVis->GetFullIdentifier(), $
            LINE_PROFILE=oLine->GetFullIdentifier()

        ;; Tell the line profile about the plot profile we just created
        oLine->AddPlotProfile, idVis

        ;; This is needed to get the plot profile up to date after setting the
        ;; associated vis above
        oPlotProfile->OnDataChangeUpdate, self, 'LINE'
        oPlotProfile->OnDataChangeUpdate, self, 'LINE3D'

        ;; Make the line and plot profiles observers of the image.
        if ~isSurface then begin
            oLine->AddOnNotifyObserver, oLine->GetFullIdentifier(), $
                oSelVis->GetFullIdentifier()
            oLine->AddOnNotifyObserver, idVis, oSelVis->GetFullIdentifier()
        endif
    endfor ;; each channel

    ;; Now see if we create any plot profiles for any line profiles that
    ;; do not have plot profiles.  This can happen if the user destroys
    ;; the plot profile tool with line profiles still on target.
    if N_ELEMENTS(recurse) eq 0 then begin
        oPlotDataspace = oPlotProfile->GetDataspace()
        oLineDataspace = oLine->GetDataspace()
        oPlots = oPlotDataspace->Get(/ALL, ISA='IDLITVISPLOTPROFILE')
        oLines = oLineDataspace->Get(/ALL, ISA='IDLITVISLINEPROFILE')
        ;; See if there are any lines that don't have plots.
        for iLine=0, N_ELEMENTS(oLines)-1 do begin
            idLine = oLines[iLine]->GetFullIdentifier()
            match = 0
            for iplt=0, N_ELEMENTS(oPlots)-1 do begin
                oPlots[iplt]->GetProperty, LINE_PROFILE=idPlotLine
                if idPlotline eq idLine then begin
                    match = 1
                    break
                endif
            endfor
            if match eq 0 then begin
                self->_CreatePlotProfile, oTool, oLines[iLine], oSelVis, /RECURSE
            endif
        endfor
    endif
end

;;---------------------------------------------------------------------------
;; IDLitopPlotProfile::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopPlotProfile::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; get the line profile annotations
    oSelVis = oTool->GetSelectedItems()
    for i=0, n_elements(oSelVis)-1 do begin
        valid = obj_isa(oSelVis[i], 'IDLitVisLineProfile')
        if valid then $
            oLineProfiles = n_elements(oLineProfiles) gt 0 ? $
                [oLineProfiles, oSelVis[i]] : oSelVis[i]
    endfor

    for i=0, n_elements(oLineProfiles)-1 do begin
        oLineProfiles[i]->GetProperty, $
            ASSOCIATED_VISUALIZATION=idSelVis

        self->_CreatePlotProfile, oTool, $
            oLineProfiles[i], $
            oTool->getByIdentifier(idSelVis)
    endfor

    return, OBJ_NEW()   ; not undoable
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopPlotProfile__define

    compile_opt idl2, hidden

    void = {IDLitopPlotProfile, $
            inherits IDLitOperation, $
            _lineProfileOpInvocation: 0b, $
            _strToolID: ''            $
                        }
end

