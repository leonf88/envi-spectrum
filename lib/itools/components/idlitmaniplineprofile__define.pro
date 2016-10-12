; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniplineprofile__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipLineProfile
;
; PURPOSE:
;   Line manipulator that allows the user to draw a line in the window
;   and then use the resulting line to generate a line profile by
;   creating a plot tool with the line used as the plot data.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulator
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipLineProfile::Init
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipLineProfile::Init
;
; PURPOSE:
;       The IDLitManipLineProfile::Init function method initializes the
;       Manipulator container component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipLineProfile', <manipulator type>)
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipLineProfile::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;   strType:  not used
;
; Return Value:
;   1 or 0, boolean success flag
;
function IDLitManipLineProfile::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    if (~self->IDLitManipulator::Init(NAME='Line Manipulator', $
        TYPE=['IDLIMAGE','IDLSURFACE'], $
        NUMBER_DS='1', $
        VISUAL_TYPE="Select", $
        KEYBOARD_EVENTS=0, $
        /TRANSIENT_DEFAULT, $
        _EXTRA=_extra)) then $
        return, 0

    self->IDLitManipLineProfile::_DoRegisterCursor

    return, 1
end




;--------------------------------------------------------------------------
; IDLitManipLineProfile::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., images & surfaces) to be manipulated by this manipulator
;   (based upon the given list of visualizations currently selected).
;
; Keywords:
;   MERGE
;     If set, include the parent of the specified visualization in the
;     selection..
;
function IDLitManipLineProfile::_FindManipulatorTargets, oVisIn, $
    MERGE=merge

    compile_opt idl2, hidden

    if (not OBJ_VALID(oVisIn[0])) then $
        return, OBJ_NEW()

    oVis = oVisIn   ; make a copy
    for i=0, N_ELEMENTS(oVis)-1 do begin
        oParent = oVis[i]
        while OBJ_VALID(oParent) do begin
            if(not obj_isa(oParent, "_IDLitVisualization"))then $
              break;
            bAdd = 0
            if ((OBJ_ISA(oParent, 'IDLitVisImage')) OR $
                (OBJ_ISA(oParent, 'IDLitVisSurface'))) then begin
               bAdd = 1
            endif else if oParent->IsManipulatorTarget() then begin
               bAdd = 1
            endif

            if (bAdd) then begin
                if(keyword_set(MERGE))then begin
                    if(oParent ne oVis[i])then $
                      oVis = [oVis, oParent]
                endif else $
                   oVis[i] = oParent
                break
            endif
            oParent->GetProperty, PARENT=oTmp
            oParent = oTmp
        endwhile
        if not OBJ_VALID(oParent) then $
          continue
    endfor

    ; Remove dups. Can't use UNIQ because we need to preserve the order.
    oUniqVis = oVis[0]
    for i=1, N_ELEMENTS(oVis)-1 do begin
        if (TOTAL(oUniqVis eq oVis[i]) eq 0) then $
            oUniqVis = [oUniqVis, oVis[i]]
    endfor

    return, oUniqVis
end


;---------------------------------------------------------------------------
; IDLitManipLineProfile::DoAction
;
; Purpose:
;   Override the DoAction so we can retrieve the VisSurface and check
;   the parameters as soon as the manipulator is activated.
;
; Arguments:
;   oTool
;
function IDLitManipLineProfile::DoAction, oTool

    compile_opt idl2, hidden

    ; Get the select object.
    oSelVis = (oTool->GetSelectedItems())[0]
    IF OBJ_ISA(oSelVis,'IDLITVISSURFACE') THEN BEGIN
        ;; get xData
        oXData = oSelVis->GetParameter('X')
        IF obj_valid(oXData) THEN void = oXData->getData(xData)
        ;; get yData
        oYData = oSelVis->GetParameter('Y')
        IF obj_valid(oYData) THEN void = oYData->getData(yData)
        ;; check dimensionality of x[y]Data
        IF (size(xData,/n_dimensions) EQ 2) || $
            (size(yData,/n_dimensions) EQ 2) THEN BEGIN
            oTool->ActivateManipulator, /DEFAULT
            self->ErrorMessage, $
                [IDLitLangCatQuery('Error:DataMismatch:Text')], $
                title=IDLitLangCatQuery('Error:DataMismatch:Title'), severity=2
            return, OBJ_NEW()
        ENDIF
    ENDIF

    return, self->_IDLitManipulator::DoAction(oTool)

end

;--------------------------------------------------------------------------
; Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitManipLineProfile::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;      x   - X coordinate
;      y   - Y coordinate
;      iButton - Mask for which button pressed
;      KeyMods - Keyboard modifiers for button
;      nClicks - Number of clicks

pro IDLitManipLineProfile::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    oTool = self->GetTool()

    ; Get the select object.
    oSelVis = oTool->GetSelectedItems()
    oSelVis = OBJ_VALID(oSelVis[0]) ? oSelVis[0] : OBJ_NEW()

    IF ~obj_valid(oSelVis) THEN return

    ;; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    ;; We'll be using a line profile annotation to draw the interactive line.
    IF oSelVis->is3D() THEN BEGIN
      oDesc = oTool->GetAnnotation('Line Profile 3D')
    ENDIF ELSE BEGIN
      oDesc = oTool->GetAnnotation('Line Profile')
    ENDELSE
    self._oLine = oDesc->GetObjectInstance()
    self._oLine->SetProperty, $
        ASSOCIATED_VISUALIZATION=oSelVis[0]->getFullIdentifier()

    ;; Put the line in the window and record starting position.
    ;; Don't notify since we will be destroying and replacing this annotation
    oWin->Add, self._oLine, /NO_NOTIFY
    self._startPT = [x, y]

    pts = [[x,y,0], [x,y,0]]

    ;; Add a data object to the profile line parameters
    oDataObj = OBJ_NEW("IDLitData", NAME='Vertices', $
        TYPE='IDLVERTEX', ICON='segpoly', /PRIVATE)
    void = self._oLine->SetData(oDataObj, PARAMETER_NAME='VERTICES', $
        /BY_VALUE, /NO_UPDATE)

    IF oSelVis->is3D() THEN BEGIN
        oView = oWin->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        IF (oWin->Pickdata(oLayer, oSelVis, [x, y], xyz) EQ 1) THEN $
            pts = [[xyz],[xyz]]
        ; Should already be in window coordinates.
        self._oLine->AddVertex, pts
    ENDIF ELSE BEGIN
        self._oLine->AddVertex, pts, /WINDOW
    ENDELSE

end


;--------------------------------------------------------------------------
; IDLitManipLineProfile::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin  - Source of the event
;      x     - X coordinate
;      y     - Y coordinate
;  iButton   - Mask for which button released

pro IDLitManipLineProfile::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ;; if we never created a line then return
    IF ~obj_valid(self._oLine) THEN return

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    ; If there was a change in coordinates between MouseDown and
    ; MouseUp, then create the line profile.

    if not ARRAY_EQUAL(self._startPT, [x, y]) then begin

        ;; update the line with the final endpoint, unless the movement
        ;; was Shift constrained, in that case let the final endpoint die
        IF ~self._constrained THEN begin
            ; Use /window to convert from window coords.
            self._oLine->MoveVertex, [x, y, 0], INDEX=[1], /WINDOW
        endif

        idSrc = "Operations/Operations/Line Profile"
        oTool = self->getTool()
        oDescOpLineProfile = oTool->GetByIdentifier(idSrc)
        oOpLineProfile = oDescOpLineProfile->GetObjectInstance()

        oOpLineProfile->GetProperty, $
            SHOW_EXECUTION_UI=showUIOrig

        pt0 = self._oLine->GetVertex(0)
        pt1 = self._oLine->GetVertex(1)
        oOpLineProfile->SetProperty, SHOW_EXECUTION_UI=0, $
            x0=pt0[0], y0=pt0[1], x1=pt1[0], y1=pt1[1]

        ; destroy the original temporary line profile. do this first
        ; so naming of later line profile is correct
        obj_destroy, self._oLine

        ; create our new line profile using the line profile operation
        oCmd = oOpLineProfile->DoAction(oTool)

        ; restore singleton operation to its former values
        ; x0, y0, x1, y1 remain
        oOpLineProfile->SetProperty, $
            SHOW_EXECUTION_UI=showUIOrig

    endif else obj_destroy, self._oLine

end


;--------------------------------------------------------------------------
; IDLitManipLineProfile::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipLineProfile::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    ;; if we never created a line then return
    IF ~obj_valid(self._oLine) THEN return

    if (~self.ButtonPress) then begin
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
        return  ; we're done
    endif

    oTool = self->GetTool()
    oSelVis = (oTool->GetSelectedItems())[0]
    if (~OBJ_VALID(oSelVis)) then $
        return

    xy0 = self._startPt
    xy1 = [x, y]

    ;; <Shift> key creates a line constrained along the start line.
    if (KeyMods and 1) then begin
        self._constrained = 1
        ; Use /window to retrieve the current line endpoint in window coords.
        xyEnd = self._oLine->GetVertex(1, /WINDOW)
        if (N_ELEMENTS(xyEnd) eq 3) then begin
            lineXY = xyEnd - xy0
            ;; Project the line from the further pt to the current XY
            ;; down onto the line connecting the two points,
            ;; using the dot product.
            factor = TOTAL((xy1 - xy0)*lineXY)/TOTAL(lineXY^2)
            xy1 = xy0 + factor*lineXY
        endif
    endif ELSE BEGIN
      self._constrained = 0
    ENDELSE

    ;; <Ctrl> key creates a line symmetric about the start pt.
    if ((KeyMods and 2) ne 0) then $
        xy0 = 2*xy0 - xy1

    xy0 = [xy0,0]
    xy1 = [xy1,0]

    if (self._oLine->CountVertex() eq 0) then begin
        self._oLine->AddVertex, xy0, /WINDOW
        self._oLine->AddVertex, xy1, /WINDOW
    endif else BEGIN
        ; Use /window to convert from window coords.
        self._oLine->MoveVertex, [[xy0], [xy1]], INDEX=[0,1], /WINDOW
    ENDELSE

    ;; Convert to vis dataspace
    ; Get the select object.
    IF oSelVis->is3D() THEN BEGIN
      oView = oWin->GetCurrentView()
      oLayer = oView->GetCurrentLayer()
      void = oWin->Pickdata(oLayer, oSelVis, xy0[0:1], xy0)
      void = oWin->Pickdata(oLayer, oSelVis, xy1[0:1], xy1)
    ENDIF ELSE BEGIN
      self._oLine->_IDLitVisualization::WindowToVis, xy0, xy0
      self._oLine->_IDLitVisualization::WindowToVis, xy1, xy1
    ENDELSE

    ;; Find length and angle and report in status area.
    length = LONG(SQRT(TOTAL((xy1[0:1] - xy0[0:1])^2)))
    angle = (180/!DPI)*ATAN(xy1[1]-xy0[1], xy1[0]-xy0[0])
    angle = LONG(((angle+360) mod 360)*100)/100d
    self->ProbeStatusMessage, $
        STRING(xy1[0], xy1[1],length,angle,FORMAT='(%"[%d,%d]   %d   %g")') + $
        STRING(176b)

end

;--------------------------------------------------------------------------
pro IDLitManipLineProfile::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '                ', $
        '                ', $
        '       .        ', $
        '       .#.      ', $
        '       .#.      ', $
        '      .#.#.     ', $
        '      .#.#.     ', $
        '      .#.#.     ', $
        '     .#. .#.    ', $
        '   . .#. .#.    ', $
        '  .#.#.   .#.   ', $
        ' .##.#.   .#.   ', $
        '.$###.     .#.  ', $
        ' .##.      .#.  ', $
        '  .#.           ', $
        '   .            ']
    self->RegisterCursor, strArray, 'LINEPROFILE',/DEFAULT

end


;---------------------------------------------------------------------------
; IDLitManipLineProfile__Define
;
; Purpose:
;   Define the object instance data.
;
pro IDLitManipLineProfile__Define

    compile_opt idl2, hidden

    void = {IDLitManipLineProfile,     $
        inherits IDLitManipulator, $
        _startPt: [0, 0],          $
        _constrained: 0b,          $
        _oLine: OBJ_NEW()          $
    }

end
