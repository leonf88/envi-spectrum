; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipsurfcontour__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipSurfContour
;
; PURPOSE:
;   This class implements a manipulator that will interactively add a
;   contour line to a surface. When the mouse is down, the user can
;   interactively adjust the level of the drawn contour line.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipAnnotation
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipSurfContour::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipSurfContour::Init
;   IDLitManipSurfContour::...
;
; INTERFACES:
; IIDLProperty
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipSurfContour::Init
;
; PURPOSE:
;       The IDLitManipSurfContour::Init function method initializes
;       the object
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipSurfContour')
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipSurfContour::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipSurfContour::Init,  _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
                                  IDENTIFIER="SURFACE CONTOUR", $
                                  KEYBOARD_EVENTS=0, $
                                  NAME='Surface Contour', $
                                  /TRANSIENT_DEFAULT, $
                                  TYPE=["IDLSURFACE"], $
                                  NUMBER_DS='1', $
                                  VISUAL_TYPE ='Select', $
                                  _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    self->IDLitManipSurfContour::SetProperty, _EXTRA=_extra

    return, 1
end


;---------------------------------------------------------------------------
; IDLitManipSurfContour::DoAction
;
; Purpose:
;   Override the DoAction so we can retrieve the VisSurface and check
;   the parameters as soon as the manipulator is activated.
;
; Arguments:
;   oTool
;
function IDLitManipSurfContour::DoAction, oTool

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
; IDLitManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitManipSurfContour::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. If object is hit of the desired
;   type, a contour is created and added to the vis tree. This single
;   level contour has it's level at the location the mouse hit in the data.
;
; Parameters
;  oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitManipSurfContour::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    if(self.nSelectionList lt 1)then return

    ;; Get the selected visualizations
    self._oSurface = (oWin->GetSelectedItems())[0]
    if(obj_isa(self._oSurface, "IDLitVisSurface") ne 1)then $
      return

;    iStatus = self->RecordUndoValues()

    ;; Create our contour
    oTool = self->GetTool()
    oDesc = OBJ_VALID(oTool) ? oTool->GetVisualization('Contour') : OBJ_NEW()
    self._oContour = OBJ_VALID(oDesc) ? oDesc->GetObjectInstance() : OBJ_NEW()
    if (~OBJ_VALID(self._oContour)) then $
        return
    self._oContour->SetProperty, NAME="Contour Object", $
        PLANAR=0

    ;; Get the data from the surface and apply it to the contour
    nData = self._oSurface->GetParameterDataByType($
                               ['IDLARRAY2D', 'IDLIMAGE'], oDataObj)
    ;; to do check data..
    void = self._oContour->SetData(oDataObj[0])

    oXData = self._oSurface->GetParameter('X')
    IF obj_valid(oXData) THEN $
        void = self._oContour->SetData(oXData, $
            PARAMETER_NAME='X', /BY_VALUE)
    oYData = self._oSurface->GetParameter('Y')
    IF obj_valid(oYData) THEN $
        void = self._oContour->SetData(oYData, $
            PARAMETER_NAME='Y', /BY_VALUE)

    ; save the contour levels for use in _CalculateAndSetLevelValue
    self._oContourLevels = (self._oContour->_GetLevels())[0]

    ;; Calculate the level
    self->_CalculateAndSetLevelValue, oWin, x, y

    oWin->Add, self._oContour, /NO_NOTIFY
end
;;---------------------------------------------------------------------------
;; IDLitManipSurfContour::_CalculateAndSetLevelValue
;;
;; Purpose:
;;   Single method used to determine the hit value on the surface and
;;   then set the level on the contour.
;;
;;   When complete, if the objects are valid, the level will be
;;   adjusted and a status message sent out.
;;
pro IDLitManipSurfContour::_CalculateAndSetLevelValue, oWin, x, y

    compile_opt idl2, hidden

    oView = oWin->GetCurrentView()
    oLayer = oView->GetCurrentLayer()

    ; Use a 9x9 pickbox to match our selection pickbox.
    result = oWin->Pickdata(oLayer, self._oSurface, [x, y], xyz, $
        DIMENSIONS=[9,9], PICK_STATUS=pickStatus)
    if (result ne 1) then $
        return

    ; Start from middle of array and work outwards to find
    ; the hit closest to the center.
    for n=0,4 do begin
        good = (WHERE(pickStatus[4-n:4+n,4-n:4+n] eq 1))[0]
        if (good ge 0) then begin
            zvalue = (xyz[2, 4-n:4+n,4-n:4+n])[good]
            break
        endif
    endfor
    if (n eq 5) then $
        return

    self._oContour->SetProperty, c_value=zvalue

    ;; update label in the visContourLevel object if labelling is on
    self._oContourLevels[0]->GetProperty, LABEL_TYPE=labelType
    if (labelType eq 1) then $
        self._oContourLevels[0]->SetProperty,LABEL_TYPE=1

    ; Update the graphics hierarchy.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

    self->ProbeStatusMessage, IDLitLangCatQuery('Status:Value:Text') + $
        string(zvalue)

end
;--------------------------------------------------------------------------
; IDLitManipSurfContour::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
;;  If in the middle of a interactive level draw, just clear out the
;;  internal values and commit the item.
;;
; Parameters
;      oWin    - Source of the event
;      x   - X coordinate
;      y   - Y coordinate
;      iButton - Mask for which button released

pro IDLitManipSurfContour::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    if(obj_valid(self._oContour))then begin
        oTool = self->GetTool()
        oSrvMacro = oTool->GetService('MACROS')
        idSrc = "OPERATIONS/OPERATIONS/CONTOUR"
        oDesc = oTool->GetByIdentifier(idSrc)

        self._oContour->GetProperty, $
            C_VALUE=c_value

        ; no longer need the temporary contour
        obj_destroy, self._oContour

        oOpInsertContour=oDesc->GetObjectInstance()

        ; retrieve current values of operation to be restored later
        oOpInsertContour->GetProperty, $
            N_LEVELS=nLevelsOrig, $
            PLANAR=planarOrig, $
            SHOW_EXECUTION_UI=showUIOrig, $
            VALUE=valueOrig

        oOpInsertContour->SetProperty, $
            VALUE=c_value, $
            N_LEVELS=1, $
            PLANAR=0, $
            SHOW_EXECUTION_UI=0

        oCmd = oOpInsertContour->DoAction(oTool)
        oTool->_TransactCommand, oCmd

        ; add to macro/history explicitly since using transactCommand
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, oOpInsertContour, currentName

        ; restore singleton operation to its former values
        oOpInsertContour->SetProperty, $
            N_LEVELS=nLevelsOrig, $
            PLANAR=planarOrig, $
            SHOW_EXECUTION_UI=showUIOrig, $
            VALUE=valueOrig


        ; done with temporary contour
        obj_destroy, self._oContour
        self._oSurface = obj_new()


    endif
    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitManipSurfContour::OnMouseMotion
;
; Purpose:
;   If performing an contour operation, will cause the contour level
;   to be adjusted.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipSurfContour::OnMouseMotion, oWin, x, y, KeyMods
   ; pragmas
   compile_opt idl2, hidden

   ;; just reset the level
   if (self.ButtonPress gt 0 and obj_valid(self._oContour)) then BEGIN
     self->_CalculateAndSetLevelValue, oWin, x, y
   ENDIF else $
     self->idlitmanipulator::OnMouseMotion, oWin, x, y, KeyMods

end

;--------------------------------------------------------------------------
; IDLitManipSurfContour::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., surfaces) to be manipulated by this manipulator
;   (based upon the given list of visualizations current selected).
;
; Keywords:
;   MERGE
;     Note: this keyword is ignored for this manipulator because
;     we only want dataspaces to be considered manipulator targets.
;
function IDLitManipSurfContour::_FindManipulatorTargets, oVisIn, $
                                                         MERGE=merge
  compile_opt idl2, hidden

  if (not OBJ_VALID(oVisIn[0])) then $
    return, OBJ_NEW()

  oVis = oVisIn                 ; make a copy
  for i=0, N_ELEMENTS(oVis)-1 do begin
    oParent = oVis[i]
    while OBJ_VALID(oParent) do begin
      if(not obj_isa(oParent, "_IDLitVisualization"))then $
        break                   ;
      bAdd = 0
      if (OBJ_ISA(oParent, 'IDLitVisSurface')) then begin
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

  ;; Remove dups. Can't use UNIQ because we need to preserve the order.
  oUniqVis = oVis[0]
  for i=1, N_ELEMENTS(oVis)-1 do begin
    if (TOTAL(oUniqVis eq oVis[i]) eq 0) then $
      oUniqVis = [oUniqVis, oVis[i]]
  endfor

  return, oUniqVis

end

;---------------------------------------------------------------------------
; IDLitManipSurfContour__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitManipSurfContour__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitManipSurfContour, $
           inherits IDLitManipulator,       $ ; I AM A COMPONENT
            _oSurface: obj_new(), $ ; our temp surface
            _oContour: OBJ_NEW(), $  ; The contour
            _oContourLevels: OBJ_NEW() $  ; The contour levels object
           }

end
