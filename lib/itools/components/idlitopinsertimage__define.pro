; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertimage__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertImage
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the Operations/Image action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertImage::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopInsertImage::Init
;   IDLitopInsertImage::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopInsertImage::Init
;;
;; Purpose:
;; The constructor of the IDLitopInsertImage object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertImage::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(TYPES=["IDLARRAY2D"], _EXTRA=_extra)
end

;;---------------------------------------------------------------------------
;; IDLitopInsertImage::_MoveBehind
;;
;; Purpose:
;;  Ensure that the image appears behind the creating contour
;;
;; Parameters:
;;  idTarget - The identifier of the visContour behind which the image
;;             vis is to be placed
;;
;;  idVis - The identifier of the image vis
;;
FUNCTION IDLitopInsertImage::_MoveBehind,idTarget,idVis
  compile_opt idl2, hidden

  oTool = self->getTool()
  oTarget = oTool->GetByIdentifier(idTarget)
  oVisImage = oTool->GetByIdentifier(idVis)

  if (OBJ_ISA(oTarget, 'IDLitVisContour')) then begin
    oTarget->GetProperty, PLANAR=planar, FILL=fill
    if (planar eq 1) && (fill eq 0) then begin
      ;; Move image behind contour.
      oVisImage->GetProperty, PARENT=oParent
      visList = oParent->Get(/ALL, count=nCount)
      imagePosition = WHERE(visList eq oVisImage, count1)
      contourPosition = WHERE(visList eq oTarget, count2)
      if (count1 gt 0) && (count2 gt 0) then begin
        oParent->Move, imagePosition[0], contourPosition[0]
        return, 1
      endif
    endif
  endif

  return, 0

END

;;---------------------------------------------------------------------------
;; IDLitopInsertImage::RedoOperation
;;
;; Purpose:
;;  Ensure that the image appears behind the creating contour
;;
;; Parameters:
;;  oCommand - A valid command object
;;
FUNCTION IDLitopInsertImage::RedoOperation, oCommand
  compile_opt idl2, hidden

  IF (~oCommand->GetItem('REDO_INSERT_IMAGE',idContour)) THEN $
    return, 1

  oCommand->GetProperty, TARGET_IDENTIFIER=idImage
  void = self->_MoveBehind(idContour,idImage)

  return, 1

END

;;---------------------------------------------------------------------------
;; IDLitopInsertImage::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertImage::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(COUNT=nTarg)

    if (nTarg eq 0) then $
        return, OBJ_NEW()

    ; Retrieve the service used to create visualizations.
    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreate)) then $
        return, OBJ_NEW()

    nData=0
    oCmdSetList = OBJ_NEW()
    bNeedRedraw = 0b
    for i=0, nTarg-1 do begin

        if (~OBJ_VALID(oTargets[i])) then $
            continue

        if (~OBJ_ISA(oTargets[i], 'IDLitParameter')) then $
            continue

        ; Look for data objects of the appropriate type.
        nData = oTargets[i]->GetParameterDataByType($
            ['IDLARRAY2D'], oDataObj)

        if (nData eq 0) then $
            continue

        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME='Image parameters', $
            ICON='demo', $
            DESCRIPTION='Image parameters')


        ; Just use the first matching parameter that we found.
        oParmSet->Add, oDataObj[0], PARAMETER_NAME="IMAGEPIXELS", $
            /PRESERVE_LOCATION

        ; Look for X and Y parameters.
        if (OBJ_ISA(oTargets[i],'IDLitVisSurface') || $
            OBJ_ISA(oTargets[i],'IDLitVisContour')) then $
            oTargets[i]->EnsureXYParameters
        oX = oTargets[i]->GetParameter('X')
        if OBJ_VALID(oX) then $
            oParmSet->Add, oX, PARAMETER_NAME="X", /PRESERVE_LOCATION

        oY = oTargets[i]->GetParameter('Y')
        if OBJ_VALID(oY) then $
            oParmSet->Add, oY, PARAMETER_NAME="Y", /PRESERVE_LOCATION

        oPalette = oTargets[i]->GetParameter('PALETTE')
        if OBJ_VALID(oPalette) then $
            oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE", $
                /PRESERVE_LOCATION

        oCmdSet = oCreate->CreateVisualization( $
            oParmSet, $
            ID_VISUALIZATION=idVis, $
            "IMAGE")

        oParmSet->Remove,/ALL
        obj_destroy,oParmSet

        oCmdSetList = OBJ_VALID(oCmdSetList[0]) ? $
            [oCmdSetList, oCmdSet] : oCmdSet

    endfor


    if (~OBJ_VALID(oCmdSetList[0])) then begin
        self->ErrorMessage, $
         [IDLitLangCatQuery('Error:InsertViz:IncorrectType'), $
          IDLitLangCatQuery('Error:InsertImage:CannotCreate')], severity=0, $
         TITLE=IDLitLangCatQuery('Error:DataUnavailable:Title')
        return, OBJ_NEW()
    endif

    ;; if target vis is a contour make sure the image goes behind the
    ;; contour
    IF (OBJ_ISA(oTargets[0], 'IDLitVisContour')) THEN BEGIN

      ; Retrieve name from last command.
      nCommands = N_ELEMENTS(oCmdSetList)
      if (nCommands gt 0) then begin
          oCmdSetList[nCommands-1]->GetProperty, NAME=name

      bNeedRedraw = $
        self->_MoveBehind(oTargets[0]->GetFullIdentifier(),idVis[0])
      ;; add an item to the command set to ensure that the image gets
      ;; moved behind the contour if a redo operation is performed
      oCmd = OBJ_NEW('IDLitCommand', $
                     OPERATION_IDENTIFIER=self->GetFullIdentifier(), $
                     TARGET_IDENTIFIER=idVis[0])
      void = oCmd->AddItem('REDO_INSERT_IMAGE', $
                           oTargets[0]->GetFullIdentifier())

      ; Copy the name to the new command so it appears nicely in
      ; the undo/redo tooltips.
      if (nCommands gt 0) then $
          oCmd->SetProperty, NAME=name

      oCmdSetList = [oCmdSetList,oCmd]

      endif

    ENDIF

    if (bNeedRedraw) then begin
        ; Update the graphics hierarchy.
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif

    return, oCmdSetList
end


;-------------------------------------------------------------------------
pro IDLitopInsertImage__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertImage, $
        inherits IDLitOperation}

end

