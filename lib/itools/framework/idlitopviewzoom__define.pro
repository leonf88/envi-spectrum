; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopviewzoom__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the operation for view zooming.
;

;---------------------------------------------------------------------------
; Lifecycle Methods
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   This function method initializes the component object.
;
; Arguments:
;   None.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
function IDLitopViewZoom::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass.
    return, self->IDLitOperation::Init(/SKIP_MACRO, _EXTRA=_extra)
end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method preforms all cleanup on the object.
;
;pro IDLitopViewZoom::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass.
;    self->IDLitOperation::Cleanup
;end


;----------------------------------------------------------------------------
; Purpose:
;   This internal function method parses the given string and returns a
;   corresponding zoom factor.
;
; Result:
;   This function returns a floating point value representing the
;     corresponding zoom factor.
;
; Arguments:
;   ZoomStr:    The string to be parsed.  An example would be: "200%".
;
;   InitialZoom: The initial zoom factor.  This is used as the fallback
;     in case the string is invalid.
;
; Keywords:
;   None.
;
function IDLitopViewZoom::_ParseZoomString, zoomStr, initialZoom

    compile_opt hidden, idl2

    ON_IOERROR, skipzoom

    zoomFactor = (Double(zoomStr) < 999999)/100

    ; Value was successfully retrieved.
    if (zoomFactor le 0) then return, initialZoom   ; Disallow negative values.

    return, zoomFactor

skipzoom:
    ; Value was not successfully retrieved.  Revert to original.
    return, initialZoom

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method does the action of zooming a view.
;
; Result:
;   This function returns a reference to an IDLitCommandSet object that
;     contains all commands required to perform the action.
;
; Arguments:
;   oTool:  A reference to an IDLitTool object that is
;     requesting the action to take place.
;
; Keywords:
;   OPTION: Set this keyword to a string representing the
;     option associated with this operation.  For view zooming,
;     the option is a string that indicates the percentage of
;     zoom.
;
function IDLitopViewZoom::DoAction, oTool, OPTION=option

    compile_opt hidden, idl2

    if (~KEYWORD_SET(option)) then begin
        self->GetProperty, IDENTIFIER=id
        option = (STRPOS(id,'%') ge 0) ? id : '100%'
    endif

    ; Make sure we have a tool.
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; Grab the current view.
    oWin = oTool->GetCurrentWindow()
    oScene = OBJ_VALID(oWin) ? oWin->GetScene() : OBJ_NEW()
    oView = OBJ_VALID(oScene) ? oScene->GetCurrentView() : OBJ_NEW()
    if (~OBJ_VALID(oView)) then $
        return, OBJ_NEW()

    ; Retrieve previous zoom factor.
    oView->GetProperty, CURRENT_ZOOM=initialZoom

    ; Parse the new zoom factor string.
    zoomFactor = self->_ParseZoomString(option, initialZoom)

    ; If our zoom factor didn't change, we still need to notify
    ; our toolbar, in case the user typed an illegal value.
    if (zoomFactor eq initialZoom) then begin
        ; Update the view zoom control in the toolbar.
        oTool->DoOnNotify, self->GetFullIdentifier(), 'SETVALUE', $
            STRTRIM(ULONG((initialZoom*100)+0.5),2)+'%'
        return, OBJ_NEW()
    endif


    oSetProp = oTool->GetService('SET_PROPERTY')
    if (OBJ_VALID(oSetProp)) then begin
        oCmd = oSetProp->DoAction(oTool, oView->GetFullIdentifier(), $
            'CURRENT_ZOOM', zoomFactor, $
            /SKIP_MACROHISTORY)
        ; Make a pretty name for Undo/Redo.
        if (OBJ_VALID(oCmd)) then $
            oCmd->SetProperty, NAME='View Zoom'
    endif

    ; A change in the view zoom factor can change availability,
    ; so update.
    oTool->UpdateAvailability

    oSrvMacro = oTool->GetService('MACROS')
    idSrc = "/Registry/MacroTools/Zoom"
    oDescZoom = oTool->GetByIdentifier(idSrc)
    if obj_valid(oSrvMacro) && $
        obj_valid(oDescZoom) then begin

        oDescZoom->SetProperty, ZOOM_PERCENTAGE=zoomFactor*100.
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, oDescZoom, currentName
    endif

    return, oCmd

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitopViewZoom object.
;
pro IDLitopViewZoom__define

    compile_opt idl2, hidden

    struc = {IDLitopViewZoom,       $
             inherits IDLitOperation  $
    }
end

