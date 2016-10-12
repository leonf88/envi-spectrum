; $Id: //depot/idl/releases/IDL_80/idldir/lib/idlgrshaderconvol3__define.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; CLASS_NAME:
;       IDLgrShaderConvol3
;
; PURPOSE:
;       This class uses the IDL shader support to implement
;       image convolution operations on the graphics card GPU.
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
;       See IDLgrShaderConvol3::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;       IDLgrShaderConvol3::Init
;       IDLgrShaderConvol3::Cleanup
;       IDLgrShaderConvol3::SetProperty
;       IDLgrShaderConvol3::GetProperty
;       IDLgrShaderConvol3::Filter (called by IDLgrImage)
;
; PROPERTIES:
;	This class has the following properties:
;
;       BASE_BLEND_FACTOR
;          A scalar FLOAT in the range [0.0, 1.0] that controls the
;          amount of the base image to be added to the kernel output.
;          The default is 0.0, meaning that no part of the base image
;          contributes to the output.
;       CONVOL_BLEND_FACTOR
;          A scalar FLOAT in the range [0.0, 1.0] that controls the
;          amount of the kernel output to be added to the base image.
;          The default is 1.0, meaning that all of the kernel output
;          contributes to the output.
;       KERNEL
;          A scalar integer for one the predefned kernels listed below
;          or a 3x3 FLOAT array containing a custom kernel.
;
;		   0 - Identity
;		   1 - Smooth
;          2 - Sharpen
;          3 - Edge Detect
;
; MODIFICATION HISTORY:
;   Original Version:  6/2006
;-

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderConvol3::Init
;
; PURPOSE:
;       The IDLgrShaderConvol3::Init function method initializes the
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

FUNCTION IDLgrShaderConvol3::Init, _EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if not self->IDLgrShader::Init(_EXTRA=_extra) then $
	    RETURN, 0

	;; Set default props and process properties
	self->SetProperty, KERNEL=0, CONVOL_BLEND_FACTOR=1.0, _FROM_INIT=1, _EXTRA=_extra

	;; Store vertex and fragment programs.
	;; Using newlines helps the compiler return
	;; line numbers in any error messages.

	vertexProgram = $
	    [ $
	        'void main (void) {', $
	        '  gl_TexCoord[0] = gl_MultiTexCoord0;', $
	        '  gl_Position = ftransform();', $
	        '}' ]

	fragmentProgram = $
	    [ $
	        'uniform sampler2D _IDL_ImageTexture;', $
	        'uniform float BaseBlend;', $
	        'uniform float ConvolBlend;', $
	        'uniform vec2 _IDL_ImageStep;', $
	        'uniform mat3 kernel;', $
	        'void main(void) {', $
	        '  vec4 sum = vec4(0.0);', $
	        '  vec2 ox = vec2(_IDL_ImageStep.x, 0.0);', $
	        '  vec2 oy = vec2(0.0, _IDL_ImageStep.y);', $
	        '  vec2 tc = gl_TexCoord[0].st - oy;', $
	        '  sum += kernel[0][0] * texture2D(_IDL_ImageTexture, tc - ox);', $
	        '  sum += kernel[0][1] * texture2D(_IDL_ImageTexture, tc     );', $
	        '  sum += kernel[0][2] * texture2D(_IDL_ImageTexture, tc + ox);', $
	        '  tc = gl_TexCoord[0].st;', $
	        '  sum += kernel[1][0] * texture2D(_IDL_ImageTexture, tc - ox);', $
	        '  sum += kernel[1][1] * texture2D(_IDL_ImageTexture, tc     );', $
	        '  sum += kernel[1][2] * texture2D(_IDL_ImageTexture, tc + ox);', $
	        '  tc = gl_TexCoord[0].st + oy;', $
	        '  sum += kernel[2][0] * texture2D(_IDL_ImageTexture, tc - ox);', $
	        '  sum += kernel[2][1] * texture2D(_IDL_ImageTexture, tc     );', $
	        '  sum += kernel[2][2] * texture2D(_IDL_ImageTexture, tc + ox);', $
	        '  gl_FragColor = vec4(ConvolBlend) * sum + ' + $
	        '    vec4(BaseBlend) * texture2D(_IDL_ImageTexture, gl_TexCoord[0].st);', $
	        '}' ]

	self->IDLgrShader::SetProperty, $
	    VERTEX_PROGRAM_STRING=STRJOIN(vertexProgram, STRING(10B)), $
	    FRAGMENT_PROGRAM_STRING=STRJOIN(fragmentProgram, STRING(10B))

	return, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderConvol3::Cleanup
;
; PURPOSE:
;       The IDLgrShaderConvol3::Cleaup procedure method terminates the
;       object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleaup method
;       from within the Cleanup method of the subclass.
;
;-

PRO IDLgrShaderConvol3::Cleanup

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Call superclass
	self->IDLgrShader::Cleanup
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderConvol3::SetProperty
;
; PURPOSE:
;       The IDLgrShaderBytscl::SetProperty procedure method
;       sets the object properties.
;-

PRO IDLgrShaderConvol3::SetProperty, $
						BASE_BLEND_FACTOR=base_blend, $
						CONVOL_BLEND_FACTOR=convol_blend, $
						FORCE_FILTER=force_filter, $
						KERNEL=kernel, $
						_FROM_INIT=_from_init, $
						_EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if N_ELEMENTS(base_blend) gt 0 then begin
		bb = FLOAT(base_blend[0])
		if bb le 1.0 && bb ge 0.0 then begin
			self.base_blend = bb
			self->IDLgrShader::SetUniformVariable, 'BaseBlend', bb
		endif $
		else begin
	    	if N_ELEMENTS(_from_init) gt 0 then self->Cleanup
			MESSAGE, 'Invalid value for BASE_BLEND_FACTOR property.'
		endelse
	endif

	if N_ELEMENTS(convol_blend) gt 0 then begin
		cb = FLOAT(convol_blend[0])
		if cb le 1.0 && cb ge 0.0 then begin
			self.convol_blend = cb
			self->IDLgrShader::SetUniformVariable, 'ConvolBlend', cb
		endif $
		else begin
	    	if N_ELEMENTS(_from_init) gt 0 then self->Cleanup
			MESSAGE, 'Invalid value for CONVOL_BLEND_FACTOR property.'
		endelse
	endif

	if N_ELEMENTS(force_filter) gt 0 && N_ELEMENTS(_from_init) eq 0 then $
		MESSAGE, 'FORCE_FILTER', 'IDLGRSHADERCONVOL3::SETPROPERTY', $
			NAME='IDL_M_KEYWORD_BAD'

	if N_ELEMENTS(kernel) gt 0 then begin
		if N_ELEMENTS(kernel) eq 1 then begin
			case FIX(kernel) of
			0: begin ; identity
				self.predefined = 0
				self.kernel = FLTARR(3,3)
				self.kernel[1,1] = 1.0
			end
			1: begin ; smooth
				self.predefined = 1
				self.kernel = (FLTARR(3,3) + 1.0) / 9.0
			end
			2: begin ; sharpening
				self.predefined = 2
				self.kernel = FLOAT([[0,-1,0],[-1,4,-1],[0,-1,0]])
			end
			3: begin ; edge detect
				self.predefined = 3
				self.kernel = FLOAT([[0,1,0],[1,-4,1],[0,1,0]])
			end
			else: begin
	    	if N_ELEMENTS(_from_init) gt 0 then self->Cleanup
				MESSAGE, 'Invalid value for KERNEL property'
			end
			endcase
		endif else if N_ELEMENTS(kernel) eq 9 then begin
			self.predefined = -1
			self.kernel = FLOAT(kernel)
		endif else begin
	    	if N_ELEMENTS(_from_init) gt 0 then self->Cleanup
			MESSAGE, 'Invalid value for KERNEL property'
		endelse
		self->IDLgrShader::SetUniformVariable, 'kernel', self.kernel
	endif

	;; Set Superclass properties
	self->IDLgrShader::SetProperty, _EXTRA=_extra
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderConvol3::GetProperty
;
; PURPOSE:
;       The IDLgrShaderBytscl::GetProperty procedure method
;       gets the object properties.
;-
PRO IDLgrShaderConvol3::GetProperty, $
						BASE_BLEND_FACTOR=base_blend, $
						CONVOL_BLEND_FACTOR=convol_blend, $
						KERNEL=kernel, $
						_REF_EXTRA=_extra

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	if ARG_PRESENT(base_blend) then $
		base_blend = self.base_blend

	if ARG_PRESENT(convol_blend) then $
		convol_blend = self.convol_blend

	if ARG_PRESENT(kernel) then begin
		kernel = (self.predefined eq -1) ? self.kernel : self.predefined
	endif

	;; Get Superclass properties
	self->IDLgrShader::GetProperty, _EXTRA=_extra

END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrShaderConvol3::Filter
;
; PURPOSE:
;       The IDLgrShaderConvol3::Filter function method
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

FUNCTION IDLgrShaderConvol3::Filter, Image

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	dims = SIZE(Image, /DIMENSIONS)
	newImage = FLTARR(dims)
	for i=0, 3 do $
		newImage[i,*,*] = CONVOL(REFORM(Image[i,*,*]), self.kernel, /EDGE_TRUNCATE)
	if self.base_blend gt 0.0  || self.convol_blend lt 1.0 then begin
		newImage = self.convol_blend * newImage + self.base_blend * Image
	endif
	RETURN, newImage
END


;+
;----------------------------------------------------------------------------
; IDLgrShaderConvol3__Define
;
; Purpose:
;  Defines the object structure for an IDLgrShaderConvol3 object.
;
;-

PRO IDLgrShaderConvol3__Define

COMPILE_OPT hidden

struct = { IDLgrShaderConvol3, $
           INHERITS IDLgrShader, $
           predefined: 0L, $
           base_blend: 0.0, $
           convol_blend: 0.0, $
           kernel: FLTARR(3,3), $
           IDLgrShaderConvol3Version: 1.0 $
         }
END
