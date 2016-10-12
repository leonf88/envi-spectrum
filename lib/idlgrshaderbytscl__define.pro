; $Id: //depot/idl/releases/IDL_80/idldir/lib/idlgrshaderbytscl__define.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; CLASS_NAME:
;       IDLgrShaderBytscl
;
; PURPOSE:
;       This class uses the IDL shader support to implement
;       the BYTSCL operation on the graphics card GPU.
;       If the required hardware is not available, the
;       operation is performed in a software fallback.
;
; CATEGORY:
;       Graphics
;
; SUPERCLASSES:
;       IDLgrShader
;
; SUBCLASSES:
;       This class has no subclasses.
;
; CREATION:
;       See IDLgrShaderBytscl::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;       IDLgrShaderBytscl::Init
;       IDLgrShaderBytscl::Cleanup
;       IDLgrShaderBytscl::SetProperty
;       IDLgrShaderBytscl::GetProperty
;       IDLgrShaderBytscl::Filter (called by IDLgrImage)
;
; PROPERTIES:
;	This class has the following properties:
;
;       IN_RANGE
;          A [2,n] floating array, where n corresponds to
;          the number of channels in the image data.  The
;          [0,n] vector specifies the minimum value to be
;          considered in the bytscl operation, as described in
;          the IDL BYTSCL function.  The [1,n] vector specifies
;          the maximum value.  Values beyond these minimum and
;          maximum values are clamped after scaling to the values
;          specified in the OUT_RANGE property.
;          The default values for IN_RANGE are [0.0, 1.0] for
;          each channel.  Each channel's max should be greater
;          than the channel's min.
;          See the UNITS_IN_RANGE property to determine how to
;          specify the values for this property.
;
;       OUT_RANGE
;          A [2,n] byte array, where n corresponds to the
;          number of channels in the image data.  The [0,n] vector
;          specifies the value that the low value of IN_RANGE is
;          mapped to.  The [1,n] vector specifies the value that
;          the high value of OUT_RANGE is mapped to, corresponding
;          to the TOP keyword in the IDL BYTSCL function.  These
;          values are always specified as BYTE values between
;          0 and 255 to represent the min and max values in an
;          image color channel.  The default values are [0,255] for
;          each channel.  Each channel's max should be greater than
;          or equal to the channel's min.
;
;       UNITS_IN_RANGE
;          A scalar integer that represents the units used to
;          express the IN_RANGE property and usually corresponds
;          to the type of the image data provided to IDLgrImage.
;          The valid values are:
;          0: Normalized.  The IN_RANGE values are provided in
;          a range of [0.0, 1.0] for BYTE and UINT, [-1.0, 1.0]
;          for INT, and any range for FLOAT.  This is the default
;          value.
;          1: BYTE.  The IN_RANGE values are provided in the
;          range of [0, 255].
;          2: INT.  The IN_RANGE values are provided in the
;          range of [-32768, 32767].
;          4: FLOAT.  The IN_RANGE values are provded in any
;          floating-point range.
;          12: UINT.  The IN_RANGE values are provided in the
;          range of [0, 65535].
;
; MODIFICATION HISTORY:
;   Original Version:  3/2006
;-

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderBytscl::Init
;
; PURPOSE:
;       The IDLgrShaderBytscl::Init function method initializes the
;       object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
;-

FUNCTION IDLgrShaderBytscl::Init, _EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if not self->IDLgrShader::Init(_EXTRA=_extra) then $
	    RETURN, 0

	;; Alloc and set default props
	inRange = FLTARR(2,4)
	inRange[1,*] = 1.0
	outRange = BYTARR(2,4)
	outRange[1,*] = 255
	self.userInRange = PTR_NEW(inRange)
	self.userOutRange = PTR_NEW(outRange)

	;; Process properties
	self->SetProperty, _FROM_INIT=1, _EXTRA=_extra

	;; Store vertex and fragment programs.
	;; Using newlines helps the compiler return
	;; line numbers in any error messages.

	vertexProgram = $
	    [ $
	        'void main (void) {', $
	        '  gl_TexCoord[0] = gl_MultiTexCoord0;', $
	        '  gl_Position = ftransform();', $
	        '}' $
	    ]

	fragmentProgram = $
	    [ $
	        'uniform sampler2D _IDL_ImageTexture;', $
	        'uniform vec4 inRangeLow;', $
	        'uniform vec4 outRangeLow;', $
	        'uniform vec4 outRangeHigh;', $
	        'uniform vec4 scale;', $
	        'void main(void) {', $
	        '  vec4 c = texture2D(_IDL_ImageTexture, gl_TexCoord[0].xy);', $
	        '  c = ((c - inRangeLow) * scale) + outRangeLow;', $
	        '  gl_FragColor = clamp(c, outRangeLow, outRangeHigh);', $
	        '}' $
	    ]

	self->IDLgrShader::SetProperty, $
	    VERTEX_PROGRAM_STRING=STRJOIN(vertexProgram, STRING(10B)), $
	    FRAGMENT_PROGRAM_STRING=STRJOIN(fragmentProgram, STRING(10B))

	RETURN, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderBytscl::Cleanup
;
; PURPOSE:
;       The IDLgrShaderBytscl::Cleaup procedure method terminates the
;       object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleanup method
;       from within the Cleanup method of the subclass.
;
;-

PRO IDLgrShaderBytscl::Cleanup

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Call superclass
	self->IDLgrShader::Cleanup

	;; Free heap vars
	PTR_FREE, self.userInRange
	PTR_FREE, self.userOutRange

END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderBytscl::SetProperty
;
; PURPOSE:
;       The IDLgrShaderBytscl::SetProperty procedure method
;       sets the object properties.
;-

PRO IDLgrShaderBytscl::SetProperty, $
			                     FORCE_FILTER = forceFilter, $
			                     IN_RANGE = inRangeIN, $
			                     OUT_RANGE = outRangeIN, $
			                     UNITS_IN_RANGE = unitsInRange, $
			                     _FROM_INIT = _fromInit, $
			                     _EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if N_ELEMENTS(forceFilter) gt 0 && N_ELEMENTS(_fromInit) eq 0 then $
		MESSAGE, 'FORCE_FILTER', 'IDLGRSHADERBYTSCL::SETPROPERTY', $
			NAME='IDL_M_KEYWORD_BAD'

	if N_ELEMENTS(unitsInRange) gt 0 then begin
		ind = WHERE(unitsInRange[0] eq [0,1,2,4,12])
		if ind[0] ge 0 then $
	        self.unitsInRange = unitsInRange $
	    else begin
	    	if N_ELEMENTS(_fromInit) gt 0 then self->Cleanup
	        MESSAGE, "Invalid value for UNITS_IN_RANGE property."
	    endelse
	endif

	if N_ELEMENTS(inRangeIN) gt 0 then begin
		sz = SIZE(inRangeIN)
		if (sz[0] eq 1 && sz[1] eq 2) || $
	       (sz[0] eq 2 && sz[1] eq 2 && sz[2] ge 1 && sz[2] le 4) then begin
	       	ind = WHERE(FLOAT(inRangeIN[1,*]) - $
	       	            FLOAT(inRangeIN[0,*]) le 0.0, count)
	       	if count gt 0 then begin
		    	if N_ELEMENTS(_fromInit) gt 0 then self->Cleanup
		    	MESSAGE, "Invalid values for IN_RANGE property."
	       	endif
	    	*self.userInRange = FLOAT(inRangeIN)
	    endif else begin
	    	if N_ELEMENTS(_fromInit) gt 0 then self->Cleanup
	    	MESSAGE, "Invalid dimensions for IN_RANGE property."
	    endelse
	endif

	if N_ELEMENTS(outRangeIN) gt 0 then begin
		sz = SIZE(outRangeIN)
		if (sz[0] eq 1 && sz[1] eq 2) || $
	       (sz[0] eq 2 && sz[1] eq 2 && sz[2] ge 1 && sz[2] le 4) then begin
	       	ind = WHERE(FLOAT(outRangeIN[1,*]) - $
	       	            FLOAT(outRangeIN[0,*]) lt 0.0, count)
	       	if count gt 0 then begin
		    	if N_ELEMENTS(_fromInit) gt 0 then self->Cleanup
		    	MESSAGE, "Invalid values for OUT_RANGE property."
	       	endif
	    	*self.userOutRange = BYTE(outRangeIN)
	    endif else begin
	    	if N_ELEMENTS(_fromInit) gt 0 then self->Cleanup
	    	MESSAGE, "Invalid dimensions for OUT_RANGE property."
	    endelse
	endif

	;; Set Superclass properties
	self->IDLgrShader::SetProperty, _EXTRA=_extra


	;; Scale IN_RANGE to take into account image data type.

	switch self.unitsInRange of
	    0: begin
	        ;; Normalized - leave alone
	        inRange = *self.userInRange
	        break
	    end
	    1: begin
	        ;; BYTE - scale [0,255] to [0,1]
	        inRange = *self.userInRange / 255.0
	        break
	    end
	    2: begin
	        ;; INT - scale [-32768, 32767] to [-1,1]
	        inRange = (*self.userInRange * 2 + 1) / 65535.0
	        break
	    end
	    4: begin
	        ;; FLOAT - leave alone
	        inRange = *self.userInRange
	        break
	    end
	    12: begin
	        ;; UINT - scale [0, 65535] to [0,1]
	        inRange = *self.userInRange / 65535.0
	        break
	    end
	endswitch

	;; Expand IN_RANGE to 4 channels

	sz = SIZE(inRange)
	if sz[0] eq 1 && sz[1] eq 2 then begin
	    ;; User passed min/max for only one channel
	    self.inRange[*,0] = inRange
	    self.inRange[*,1] = inRange
	    self.inRange[*,2] = inRange
	    self.inRange[*,3] = [0.0, 1.0]
	endif else $
	    ;; 2D array of the form [2,n],
	    ;; where n is 1, 2, 3, or 4
	    switch sz[2] of
	        1: begin  ;; LUM
	            self.inRange[*,0] = inRange[*,0]
	            self.inRange[*,1] = inRange[*,0]
	            self.inRange[*,2] = inRange[*,0]
	            self.inRange[*,3] = [0.0, 1.0]
	            break
	        end
	        2: begin  ;; LUM ALPHA
	            self.inRange[*,0] = inRange[*,0]
	            self.inRange[*,1] = inRange[*,0]
	            self.inRange[*,2] = inRange[*,0]
	            self.inRange[*,3] = inRange[*,1]
	            break
	        end
	        3: begin ;; RGB
	            self.inRange[*,0] = inRange[*,0]
	            self.inRange[*,1] = inRange[*,1]
	            self.inRange[*,2] = inRange[*,2]
	            self.inRange[*,3] = [0.0, 1.0]
	            break
	        end
	        4: begin ;; RGB ALPHA
	            self.inRange[*,0] = inRange[*,0]
	            self.inRange[*,1] = inRange[*,1]
	            self.inRange[*,2] = inRange[*,2]
	            self.inRange[*,3] = inRange[*,3]
	            break
	        end
	    endswitch

	;; Expand OUT_RANGE to 4 channels and scale to [0,1]

	outRange = *self.userOutRange / 255.0
	sz = SIZE(outRange)
	if sz[0] eq 1 && sz[1] eq 2 then begin
	    ;; User passed min/max for only one channel
	    self.outRange[*,0] = outRange
	    self.outRange[*,1] = outRange
	    self.outRange[*,2] = outRange
	    self.outRange[*,3] = [0,1]
	endif else $
	    ;; 2D array of the form [2,n],
	    ;; where n is 1, 2, 3, or 4
	    switch sz[2] of
	        1: begin ;; LUM
	            self.outRange[*,0] = outRange[*,0]
	            self.outRange[*,1] = outRange[*,0]
	            self.outRange[*,2] = outRange[*,0]
	            self.outRange[*,3] = [0,1]
	            break
	        end
	        2: begin ;; LUM ALPHA
	            self.outRange[*,0] = outRange[*,0]
	            self.outRange[*,1] = outRange[*,0]
	            self.outRange[*,2] = outRange[*,0]
	            self.outRange[*,3] = outRange[*,1]
	            break
	        end
	        3: begin ;; RGB
	            self.outRange[*,0] = outRange[*,0]
	            self.outRange[*,1] = outRange[*,1]
	            self.outRange[*,2] = outRange[*,2]
	            self.outRange[*,3] = [0,1]
	            break
	        end
	        4: begin ;; RGB ALPHA
	            self.outRange[*,0] = outRange[*,0]
	            self.outRange[*,1] = outRange[*,1]
	            self.outRange[*,2] = outRange[*,2]
	            self.outRange[*,3] = outRange[*,3]
	            break
	        end
	    endswitch

	;; Calculate scale
    scale = (self.outRange[1,*] - self.outRange[0,*]) / $
	    (self.inRange[1,*] - self.inRange[0,*])

	;; Set Uniforms
	self->SetUniformVariable, 'inRangeLow', self.inRange[0,*]
	self->SetUniformVariable, 'scale', scale
	self->SetUniformVariable, 'outRangeLow', self.outRange[0,*]
	self->SetUniformVariable, 'outRangeHigh', self.outRange[1,*]
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderBytscl::GetProperty
;
; PURPOSE:
;       The IDLgrShaderBytscl::GetProperty procedure method
;       gets the object properties.
;-
PRO IDLgrShaderBytscl::GetProperty, $
                     IN_RANGE = inRange, $
                     OUT_RANGE = outRange, $
                     UNITS_IN_RANGE = unitsInRange, $
                     _REF_EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if ARG_PRESENT(inRange) then $
	    inRange = *self.userInRange

	if ARG_PRESENT(outRange) then $
	    outRange = *self.userOutRange

	if ARG_PRESENT(unitsInRange) then $
	    unitsInRange = self.unitsInRange

	;; Get Superclass properties
	self->IDLgrShader::GetProperty, _EXTRA=_extra

END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderBytscl::Filter
;
; PURPOSE:
;       The IDLgrShaderBytscl::Filter function method
;       implements the software shader fallback, which
;       performs the image operation in software, when
;       the graphics hardware shader support is not available.
;       This function is called during the drawing of a scene
;       graph by the instance of IDLgrImage that specifies this
;       shader in its SHADER property.
;
; ARGUMENTS:
;       Image - The input image array.  This array always is
;       of FLOAT type, RGBA format(4-channels), and is
;       pixel interleaved.
;
; RETURN VALUE:
;       Image - Array of type FLOAT with same dimensions as
;       input array.  The values in this return array should
;       be normalized to the range [0.0, 1.0].
;-

FUNCTION IDLgrShaderBytscl::Filter, Image

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Compute BYTSCL scale factor.
    scale = (self.outRange[1,*] - self.outRange[0,*]) / $
        (self.inRange[1,*] - self.inRange[0,*])

	;; Perform bytscl operation on each channel, in FLOAT space.
	for i=0, 3 do $
	    Image[i,0,0] = ((((Image[i,*,*] - self.inRange[0,i]) * $
	                    scale[i] + self.outRange[0,i])) $
	                    > self.outRange[0,i] ) < self.outRange[1,i]

	RETURN, TEMPORARY(Image)
END


;+
;----------------------------------------------------------------------------
; IDLgrShaderBytscl__Define
;
; Purpose:
;  Defines the object structure for an IDLgrShaderBytscl object.
;
;-

PRO IDLgrShaderBytscl__Define

COMPILE_OPT idl2, hidden

	struct = { IDLgrShaderBytscl, $
	           INHERITS IDLgrShader, $
	           userInRange: PTR_NEW(), $
	           userOutRange: PTR_NEW(), $
	           inRange: FLTARR(2,4), $
	           outRange: FLTARR(2,4), $
	           unitsInRange: 0B, $
	           IDLgrShaderBytsclVersion: 1.0 $
	         }
END
