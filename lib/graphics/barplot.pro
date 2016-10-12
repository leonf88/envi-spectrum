; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/barplot.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create IDL BarPlot graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
;-----------------------------------------------------------------------
; Helper routine to construct the parameter set.
; If no parameters are supplied then oParmSet will be undefined.
;
function iBarPlot_GetParmSet, oParmSet, parm1, parm2, parm3, $
    TEST=test, $
    _EXTRA=_EXTRA
    
  compile_opt idl2, hidden
  
  nParams = N_Params()
  if (Keyword_Set(test)) then begin
    parm1 = INDGEN(20)
    parm2 = RANDOMU(s,20)
    nParams = 3
  endif
  
  if (nParams le 1) then return, ''
  
  oParmSet = OBJ_NEW('IDLitParameterSet', $
    NAME='Plot parameters', $
    ICON='plot', $
    DESCRIPTION='Plot parameters')
  oParmSet->SetAutoDeleteMode, 1b
  
  case (nParams) of
    2: begin
      ; Check for undefined variables.
      if (N_ELEMENTS(parm1) eq 0) then $
        MESSAGE, 'First argument is an undefined variable.'
        
      ; eliminate leading dimensions of 1
      parm1 = reform(parm1)
      
      ; y only for 2D plot
      case (SIZE(parm1, /N_DIMENSIONS)) of
        1: begin
          ; 2D plot, y in a vector
          visType = 'PLOT'
          oDataY = obj_new('idlitDataIDLVector', parm1, NAME='Y')
          oParmSet->add, oDataY, PARAMETER_NAME='Y'
        end
        2: begin
          dims = SIZE(parm1, /DIMENSIONS)
          case dims[0] of
            2: begin
              ; 2D plot, x,y in one 2xN array
              visType = 'PLOT'
              oDataXY = OBJ_NEW('IDLitDataIDLArray2D', $
                NAME='VERTICES', $
                parm1)
              oParmSet->Add, oDataXY, PARAMETER_NAME='VERTICES'
            end
            else: MESSAGE, 'First argument has invalid dimensions'
          endcase
        end
        else: MESSAGE, 'First argument has invalid dimensions'
      endcase
    end
    3: begin
      ; Check for undefined variables.
      if (N_ELEMENTS(parm1) eq 0) then $
        MESSAGE, 'First argument is an undefined variable.'
        
      ; Check for undefined variables.
      if (N_ELEMENTS(parm2) eq 0) then $
        MESSAGE, 'Second argument is an undefined variable.'
        
      ; eliminate leading dimensions of 1
      parm1 = reform(parm1)
      parm2 = reform(parm2)
      
      ; x and y for 2D plot
      if ((SIZE(parm1, /N_DIMENSIONS) eq 1) AND $
        (SIZE(parm2, /N_DIMENSIONS) eq 1) AND $
        (N_ELEMENTS(parm1) eq N_ELEMENTS(parm2))) then begin
        visType = 'PLOT'
        oDataX = obj_new('idlitDataIDLVector', parm1, NAME='X')
        oDataY = obj_new('idlitDataIDLVector', parm2, NAME='Y')
        oParmSet->add, oDataX, PARAMETER_NAME='X'
        oParmSet->add, oDataY, PARAMETER_NAME='Y'
      endif else begin
        MESSAGE, 'Arguments have invalid dimensions'
      endelse
      
    end
    
  endcase
  
  ; Set the appropriate visualization type.
  oParmSet->SetProperty, TYPE=visType
  
  return, visType
end

;-------------------------------------------------------------------------
; Needed because Graphic calls 'i'+graphicname
pro ibarplot, parm1, parm2, parm3, $
    DEBUG=debug, $
    IDENTIFIER=identifier, $
    _EXTRA=_extra
    
  compile_opt hidden, idl2
  
  ; Note: The error handler will clean up the oParmSet container.
  @idlit_itoolerror.pro
  
  nParams = N_Params()

  case (nParams) of
    0: visType = iBarPlot_GetParmSet(oParmSet, RGB_TABLE=rgbTableIn, $
      _EXTRA=_extra)
    1: visType = iBarPlot_GetParmSet(oParmSet, parm1, RGB_TABLE=rgbTableIn, $
      _EXTRA=_extra)
    2: visType = iBarPlot_GetParmSet(oParmSet, parm1, parm2, $
      RGB_TABLE=rgbTableIn, _EXTRA=_extra)
  endcase
  
  identifier = IDLitSys_CreateTool("Plot Tool", $
    INITIAL_DATA=oParmSet, $
    WINDOW_TITLE='IDL Bar Plot', $
    VISUALIZATION_TYPE='BarPlot', $
    _EXTRA=_extra)
    
end

;-------------------------------------------------------------------------
function barplot, arg1, arg2, arg3, $
                  LAYOUT=layoutIn, _REF_EXTRA=ex
  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'
  
  switch (nparams) of
  3: if ~ISA(arg3, 'STRING') then MESSAGE, 'Format argument must be a string.'
  2: if (~ISA(arg2, /ARRAY) && ~ISA(arg2, 'STRING')) then $
    MESSAGE, 'Input must be an array or a Format string.'
  1: if ~ISA(arg1, /ARRAY) then MESSAGE, 'Input must be an array.'
  endswitch
  
  if (isa(arg1, 'STRING')) then begin
    if (~hasTestKW) then $
      MESSAGE, 'Format argument must be passed in after data.'
    style = arg1
    nparams--
  endif
  if (isa(arg2, 'STRING'))  then begin
    if (isa(arg3)) then $
      MESSAGE, 'Format argument must be passed in after data.'
    style = arg2
    nparams--
  endif
  if (isa(arg3, 'STRING')) then begin
    style = arg3
    nparams--
  endif
  
  if (n_elements(style)) then $
    style_convert, style, COLOR=color, LINESTYLE=linestyle, THICK=thick
  
  layout = N_ELEMENTS(layoutIn) eq 3 ? layoutIn : [1,1,1]
  
  name = 'BarPlot'
  case nparams of
    0: Graphic, name, $
      LAYOUT=layout, _EXTRA=ex, GRAPHIC=graphic, $
      LINESTYLE=linestyle, THICK=thick, COLOR=color
    1: Graphic, name, arg1, $
      LAYOUT=layout, _EXTRA=ex, GRAPHIC=graphic, $
      LINESTYLE=linestyle, THICK=thick, COLOR=color
    2: Graphic, name, arg1, arg2, $
      LAYOUT=layout, _EXTRA=ex, GRAPHIC=graphic, $
      LINESTYLE=linestyle, THICK=thick, COLOR=color
    3: Graphic, name, arg1, arg2, arg3, $
      LAYOUT=layout, _EXTRA=ex, GRAPHIC=graphic, $
      LINESTYLE=linestyle, THICK=thick, COLOR=color
  endcase

  return, graphic
  
end
