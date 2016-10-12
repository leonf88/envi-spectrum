; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritepdf__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWritePDF class.
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
function IDLitWritePDF::Init, $
    _EXTRA=_extra
    
    
  compile_opt idl2, hidden
  
  ; Init superclass
  ; The only properties that can be set at INIT time can be set
  ; in the superclass Init method.
  if(self->IDLitWriter::Init('pdf', $
    NAME='Portable Document Format', $
    TYPES=["IDLDEST"], $
    DESCRIPTION="Portable Document Format", $
    ICON='demo', $
    _EXTRA=_extra) eq 0) then $
    return, 0
    
  self->RegisterProperty, 'GRAPHICS_FORMAT', $
    NAME='Graphics format', $
    DESCRIPTION='Render graphics using bitmap or vector output', $
    ENUMLIST=['Bitmap','Vector']
    
  self._graphicsFormat = 1
  
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitWritePDF::SetProperty, _EXTRA=_extra
    
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
pro IDLitWritePDF::Cleanup
  compile_opt idl2, hidden
  self->IDLitWriter::Cleanup
end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitWritePDF::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;    TYPES   - The data types supported by this writer
;
;    All keywords are passed to the superclasses
;
pro IDLitWritePDF::GetProperty, $
    _REF_EXTRA=_super
    
  compile_opt idl2, hidden
  
  if(N_ELEMENTS(_super) gt 0) then begin
    self->IDLitWriter::GetProperty, _EXTRA=_super
  endif
  
end


;---------------------------------------------------------------------------
; IDLitWritePDF::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;   All properties are passed to the super-class
;
pro IDLitWritePDF::SetProperty, $
    RESOLUTION=resolution, $
    CENTIMETERS=centimeters, $
    HEIGHT=height, $
    LANDSCAPE=landscape, $
    PAGE_SIZE=pageSize, $
    WIDTH=width, $
    XMARGIN=xmargin, $
    YMARGIN=ymargin, $
    _EXTRA=_super
    
  compile_opt idl2, hidden
  
  if (N_ELEMENTS(resolution) eq 1) then $
    self._resolution = resolution
    
  if (N_ELEMENTS(centimeters) eq 1) then $
    self._centimeters = centimeters
    
  if (N_ELEMENTS(height) eq 1) then $
    self._height = height
    
  if (N_ELEMENTS(landscape) eq 1) then $
    self._landscape = landscape
    
  if (N_ELEMENTS(pageSize) gt 0) then begin
    if (ISA(pageSize, 'STRING')) then begin
      case (STRUPCASE(pageSize)) of
      'LETTER': self._pageSize = [8.5d,11]
      'LEGAL': self._pageSize = [8.5d,14]
      'A4': self._pageSize = [8.3d,11.7]
      'A5': self._pageSize = [5.8d,8.3]
      else: MESSAGE, /NONAME, 'Unknown page size: ' + pageSize
      endcase
    endif else begin
      if N_ELEMENTS(pageSize) ne 2 then $
        MESSAGE, /NONAME, 'PAGE_SIZE must be a string or two-element array.'
      self._pageSize = pageSize
    endelse
  endif
    
  if (N_ELEMENTS(width) eq 1) then $
    self._width = width
    
  if (N_ELEMENTS(xmargin) eq 1) then begin
    self._xmargin = xmargin
    self._hasXmargin = 1b
  endif
  
  if (N_ELEMENTS(ymargin) eq 1) then begin
    self._ymargin = ymargin
    self._hasYmargin = 1b
  endif
    
  if (N_ELEMENTS(_super) gt 0) then $
    self->IDLitWriter::SetProperty, _EXTRA=_super
end


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
function IDLitWritePDF::SetData, oItemIn

  compile_opt idl2, hidden
  
  strFilename = self->GetFilename()
  
  ; If we are a winscene, get the scene
  oItem = OBJ_ISA(oItemIn, "_IDLitgrDest") ? $
    oItemIn->GetScene() : oItemIn
    
  ; Do we have to rasterize this ?
  if (OBJ_ISA(oItem, "IDLitgrScene") || $
    OBJ_ISA(oItem, "IDLitgrView")) then begin
    
    oTool = self->GetTool()
    
    ; Get the system rastor service.
    oPDF = oTool->GetService("PDF")
    
    ; Do the draw
    status = oPDF->DoWindowCopy(oTool->GetCurrentWindow(), oItem, $
      RESOLUTION=self._resolution, $
      CENTIMETERS=self._centimeters, $
      HEIGHT=self._height, $
      LANDSCAPE=self._landscape, $
      PAGE_SIZE=self._pageSize, $
      WIDTH=self._width, $
      XMARGIN=self._hasXmargin ? self._xmargin : !NULL, $
      YMARGIN=self._hasYmargin ? self._ymargin : !NULL, $
      FILENAME=strFilename, $
      VECTOR=self._graphicsFormat)
      
    ; Reset all of our cached parameters.
    self._resolution = 0d
    self._centimeters = 0b
    self._landscape = 0b
    self._height = 0d
    self._width = 0d
    self._pageSize = [0d,0d]
    self._xmargin = 0d
    self._ymargin = 0d
    self._hasXmargin = 0b
    self._hasYmargin = 0b
    
    return, 1
    
  endif
  
  return, 0  ; failure
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWritePDF__Define

  compile_opt idl2, hidden
  
  void = {IDLitWritePDF, $
    inherits IDLitWriter, $
    _resolution: 0d, $
    _height: 0d, $
    _width: 0d, $
    _pageSize: [0d,0d], $
    _xmargin: 0d, $
    _ymargin: 0d, $
    _centimeters: 0b, $
    _landscape: 0b, $
    _hasXmargin: 0b, $
    _hasYmargin: 0b $
    }
end
