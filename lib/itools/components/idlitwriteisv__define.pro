; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwriteisv__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteISV class.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
; Keywords:
;   All superclass keywords.
;
function IDLitWriteISV::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if (self->IDLitWriter::Init('isv', $
                                TYPES="IDLISV", $
                                NAME="iTools State", $
                                DESCRIPTION="iTools State (isv)", $
                                ICON='save', $
                                _EXTRA=_extra) eq 0) then $
      return, 0

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
; The destructor for the class.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitWriteISV::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitWriter::Cleanup
;end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   ImageData: An object reference to the data to be written.
;
; Keywords:
;   None.
;
function IDLitWriteISV::SetData, oTool

    compile_opt idl2, hidden

    if (~OBJ_VALID(oTool)) then $
        return, 0
    oTool->GetProperty, _TOOL_NAME=toolName, VERSION=toolVersion

    strFilename = self->GetFilename()


    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0

    ; Retrieve the current zoom before the window dimensions.
    oWin->GetProperty, $
        CURRENT_ZOOM=currentZoom

    oWin->ClearSelections

    ; Call SetCurrentZoom directly to avoid UI updates.
    oWin->SetCurrentZoom, 1

    ; Now retrieve the window dimensions.
    oWin->GetProperty, $
        AUTO_RESIZE=autoResize, $
        LAYOUT_INDEX=layoutIndex, $
        VIEW_GRID=viewGrid, $
        MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
        DIMENSIONS=winDimensions, $
        VIEWPORT_DIMENSIONS=viewportDimensions, $
        VIRTUAL_DIMENSIONS=virtualDimensions, $
        VISIBLE_LOCATION=visibleLocation, $
        ZOOM_ON_RESIZE=zoomOnResize

    oPrintOperation = oTool->GetByIdentifier('Operations/File/Print')
    if (OBJ_VALID(oPrintOperation)) then begin
        oPrintOperation->GetProperty, PRINT_ORIENTATION=print_orientation, $
            PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
            PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
            PRINT_UNITS=print_units, PRINT_CENTER=print_center
    endif else begin
        print_orientation = 0
        print_xmargin = 0
        print_ymargin = 0
        print_width = 0
        print_height = 0
        print_units = 0
        print_center = 0
    endelse

    ; We want to save the draw widget viewport dimensions.
    ; Unfortunately, on Windows this includes the scroll bar size.
    dimensions = [0., 0.]

    ; So if there is a scroll bar (virtual > window dims)
    ; then use the window dimensions instead.
    dimensions[0] = (virtualDimensions[0] gt winDimensions[0]) ? $
        winDimensions[0] : viewportDimensions[0]
    dimensions[1] = (virtualDimensions[1] gt winDimensions[1]) ? $
        winDimensions[1] : viewportDimensions[1]

    oScene = oWin->GetScene()
    SAVE, toolName, toolVersion, $
        virtualDimensions, minVirtualDims, $
        dimensions, autoResize, $
        visibleLocation, currentZoom, $
        layoutIndex, viewGrid, $
        zoomOnResize, $
        oScene, print_orientation, print_xmargin, print_ymargin, $
        print_width, print_height, print_units, $
        FILE=strFilename, /COMPRESS

    ; Call SetCurrentZoom directly to avoid UI updates.
    oWin->SetCurrentZoom, currentZoom

    return, 1

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteISV__Define

    compile_opt idl2, hidden

    void = {IDLitWriteISV, $
        inherits IDLitWriter $
        }
end
