; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegendsurfaceitem__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendSurfaceItem class is the component wrapper
;   for the surface item subcomponent of the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;




;----------------------------------------------------------------------------
;pro IDLitVisLegendContourItem::_RegisterProperties, $
;    UPDATE_FROM_VERSION=updateFromVersion
;
;    compile_opt idl2, hidden
;
;    registerAll = ~KEYWORD_SET(updateFromVersion)
;
;    if (registerAll) then begin
;
;
;    endif
;
;end


;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendSurfaceItem::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisLegendItem::Init( $
        NAME="Surface Legend Item", $
        DESCRIPTION="A Surface Legend Entry", $
        _EXTRA=_extra)) then $
        return, 0

;    self->IDLitVisLegendSurfaceItem::_RegisterProperties

    return, 1 ; Success
end




;----------------------------------------------------------------------------
; IDLitVisLegendSurfaceItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
;pro IDLitVisLegendSurfaceItem::Restore
;    compile_opt idl2, hidden
;
;    ; Call superclass restore.
;    self->IDLitVisLegendItem::Restore
;
;    ; Register new properties.
;    self->IDLitVisLegendSurfaceItem::_RegisterProperties, $
;        UPDATE_FROM_VERSION=self.idlitcomponentversion
;end


;----------------------------------------------------------------------------
pro IDLitVisLegendSurfaceItem::RecomputeLayout

    compile_opt idl2, hidden

    oTool = self->GetTool()
    self->GetProperty, PARENT=oParent
    if (OBJ_VALID(oTool) && OBJ_VALID(oParent)) then begin
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
            return
        textDimensions = oWindow->GetTextDimensions(self._oText, DESCENT=descent)
        if (OBJ_VALID(self._oSurface)) then begin
            SurfacItemScaleFactor = 4.0
            self._oSurface->SetProperty, $
                XCOORD_CONV=[0, self._sampleWidth/SurfacItemScaleFactor], $
                YCOORD_CONV=[-descent, (textDimensions[1]+descent)/SurfacItemScaleFactor]

            self._oText->SetProperty, $
                LOCATIONS=[[self._sampleWidth+self._horizSpacing, -descent]]
        endif
    endif

    ; Draw required for UpdateSelectionVisual to get valid RANGE of text
    if (N_ELEMENTS(descent) gt 0) && (descent ne self._textDescent) then begin
        self->GetProperty, HIDE=hideOrig
        self->SetProperty, /HIDE
        oTool->RefreshCurrentWindow
        self._textDescent = descent
        self->SetProperty, HIDE=hideOrig
    endif
    self->UpdateSelectionVisual

    ; Update the upper level legend
    self->GetProperty, PARENT=oLegend
    if OBJ_VALID(oLegend) then oLegend->RecomputeLayout

end

;----------------------------------------------------------------------------
PRO IDLitVisLegendSurfaceItem::BuildItem

    compile_opt idl2, hidden

    ; Call our superclass first to set our properties.
    self->IDLitVisLegendItem::BuildItem

    self->AddOnNotifyObserver, self->GetFullIdentifier(), $
        self._oVisTarget->GetFullIdentifier()

    self->IDLitVisLegendItem::GetProperty, PARENT=oParent

    self._oVisTarget->GetProperty, $
        COLOR=color, $
        STYLE=style, $
        NAME=name

    if (n_elements(name) eq 0) then $
        name=''

    self._oSurface = OBJ_NEW('IDLgrSurface', $
        intarr(5,5), $
        COLOR=color, $
        STYLE=style, $
        NAME=name, $
        /PRIVATE)

    self->Add, self._oSurface

    self._oText->SetProperty, STRINGS=name

    self->RecomputeLayout

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitVisLegend::OnNotify
;;
;;
;;  strItem - The item being observed
;;
;;  strMessage - What happend. For properties this would be
;;               "SETPROPERTY"
;;
;;  strUser    - Message related data. For SETPROPERTY, this is the
;;               property that changed.
;;
;;
pro IDLitVisLegendSurfaceItem::OnNotify, strItem, StrMessage, strUser

   compile_opt idl2, hidden

    ; Let superclass handle other messages.
    if (strMessage ne 'SETPROPERTY') then begin
        ; Call our superclass.
        self->IDLitVisLegendItem::OnNotify, $
            strItem, StrMessage, strUser
        return
    endif

    oTool = self->GetTool()
    oSubject=oTool->GetByIdentifier(strItem)

    case STRUPCASE(strUser) OF

        'COLOR': begin
            oSubject->GetProperty, COLOR=color
            if (N_ELEMENTS(color) gt 0) then begin
                self._oSurface->SetProperty, $
                    COLOR=color
            endif
            end

        'STYLE': begin
            oSubject->GetProperty, STYLE=style
            if (N_ELEMENTS(style) gt 0) then begin
                self._oSurface->SetProperty, $
                    STYLE=style
            endif
            end

;        'NAME': ;Note that the ITEM_TEXT property of the legend item
;                ;is set on creation to the NAME of the visualization,
;                ;but this is not updated if the vis name is changed
;                ;after creation.  Users may change the text property
;                ;in the legend and this should not be overwritten.

        else: ; ignore unknown parameters

    endcase

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegendSurfaceItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendSurfaceItem object.
;
;-
pro IDLitVisLegendSurfaceItem__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegendSurfaceItem,           $
        inherits IDLitVisLegendItem, $
        _oSurface: OBJ_NEW()        $
    }
end
