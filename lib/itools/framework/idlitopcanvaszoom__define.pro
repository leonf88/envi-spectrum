; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopcanvaszoom__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the operation for canvas zooming.
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
function IDLitopCanvasZoom::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass.
    return, self->IDLitOperation::Init(_EXTRA=_extra)
end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method preforms all cleanup on the object.
;
;pro IDLitopCanvasZoom::Cleanup
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
function IDLitopCanvasZoom::_ParseZoomString, zoomStr, initialZoom

    compile_opt hidden, idl2

    ON_IOERROR, skipzoom
    val = DOUBLE(zoomStr)

    ; Value was successfully retrieved.
    if (val le 0) then return, initialZoom   ; Disallow negative values.

    zoomFactor = DOUBLE(val) / 100.
    return, zoomFactor

skipzoom:
    ; Value was not successfully retrieved.  Revert to original.
    return, initialZoom

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method does the action of zooming a canvas.
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
;     option associated with this operation.  For canvas zooming,
;     the option is a string that indicates the percentage of
;     zoom.
;
function IDLitopCanvasZoom::DoAction, oTool, OPTION=option

    compile_opt hidden, idl2

    if (~KEYWORD_SET(option)) then begin
        self->GetProperty, IDENTIFIER=id
        option = (STRPOS(id,'%') ge 0) ? id : '100%'
    endif

    ; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; Grab the window.
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, obj_new()

    ; Retrieve previous zoom factor.
    oWin->GetProperty, CURRENT_ZOOM=initialZoom, VISIBLE_LOCATION=winLoc, $
      DIMENSIONS=winDims, VIRTUAL_DIMENSIONS=vDims

    ; Parse the new zoom factor string.
    zoomFactor = self->_ParseZoomString(option, initialZoom)

    oSetProp = oTool->GetService('SET_PROPERTY')
    if (OBJ_VALID(oSetProp)) then begin
        oCmd = oSetProp->DoAction(oTool, oWin->GetFullIdentifier(), $
            'CURRENT_ZOOM', zoomFactor)
        ; Make a pretty name for Undo/Redo.
        if (OBJ_VALID(oCmd)) then $
            oCmd->SetProperty, NAME='Canvas Zoom'
    endif
    
    ; Ensure window is in the proper location
    origWinLoc = winLoc
    winLoc <= vDims - winDims
    winLoc >= 0
    if (~ARRAY_EQUAL(winLoc, origWinLoc)) then begin
      oWin->SetProperty, VISIBLE_LOCATION=winLoc
    endif
    
    ; We don't always get a redraw event on zoom, so do it manually.
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

    return, oCmd

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitopCanvasZoom object.
;
pro IDLitopCanvasZoom__define

    compile_opt idl2, hidden

    struc = {IDLitopCanvasZoom,       $
             inherits IDLitOperation  $
    }
end

