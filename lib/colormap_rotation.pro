; $Id: //depot/idl/releases/IDL_80/idldir/lib/colormap_rotation.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	COLORMAP_ROTATION
;
; PURPOSE:
;	Map pixels within a given hue range to another hue range, using the
;   HSV hue component.  The HSV color model describes the hue component
;   as a circular value from 0 to 360 degrees where red is located at
;   0 degrees, green is 120 degrees, and blue is 240 degrees.
;
;   A hue range is specified as a pair of start and stop angles and a
;   direction indicator.  The angles increase in a counter-clockwise direction.
;   The default direction is counter-clockwise, which describes the direction
;   of the hue range as it is mapped from the start angle to the stop angle.
;
;	Examples:
;   start: 350  stop:  10  Dir: CCW - 20-degree range starting on the blue side
;   start:  10  stop: 350  Dir:  CW - 20-degree range starting on the green side
;   start: 350  stop   10  Dir:  CW - 340-degree range starting on the blue side
;   start:  10  stop  350  Dir: CCW - 340-degree range starting on the green side
;
;   The source range is linearly mapped to the destination range.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = COLORMAP_ROTATION(Image, SrcAngleStart, SrcAngleStop, $
;                              DstAngleStart, DstAngleStop $
;                              [, /SOURCE_CW][, /DEST_CW])
;
; INPUTS:
;	Image: A 3D array of any basic type containing the input image with data range [0-255].
;          The image must contain RGB data and be of the form [3,m,n].
;
;   SrcAngleStart: A scalar float indicating the source angle start in degrees [0,360].
;
;   SrcAngleStop: A scalar float indicating the source angle stop in degrees [0,360].
;
;   DstAngleStart: A scalar float indicating the dest angle start in degrees [0,360].
;
;   DstAngleStop: A scalar float indicating the dest angle stop in degrees [0,360].
;
; KEYWORDS:
;   SOURCE_CW: Set the source angle direction to clockwise.
;   DEST_CW: Set the destination angle direction to clockwise.
;
; OUTPUTS:
;   The result is a byte array of the same dimensions as the input Array.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;
; EXAMPLE CALLING SEQUENCE:
;
;	The following sequence will change the red hues in a rose to cyan:
;
;	fn = FILEPATH('rose.jpg', SUBDIR=['examples', 'data'])
;	READ_JPEG, fn, rose
;	result = COLORMAP_ROTATION(rose, 310, 50, 160, 185)
;   TV, result, /TRUE
;
;   These values map all hues to magenta hues:
;
;   result = COLORMAP_ROTATION(rose, 0, 360, 300, 300)
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-


function colormap_rotation, in_arr, src_angle_start, src_angle_stop, $
						    dst_angle_start, dst_angle_stop, $
	                        SOURCE_CW=src_cw, DEST_CW=dst_cw

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)

	;; Check arguments
	if n_dims ne 3 then $
		MESSAGE, 'Image array must have 3 dimensions'
	if dims[0] ne 3 then $
		MESSAGE, 'Image array must be RGB and in the form [3,m,n]'

	;; Keywords
	from_cw = KEYWORD_SET(src_cw)
	to_cw = KEYWORD_SET(dst_cw)

	;; Map incoming angles to [0,360] and check for valid range
	from1 = FLOAT(src_angle_start[0])
	from2 = FLOAT(src_angle_stop[0])
	to1 = FLOAT(dst_angle_start[0])
	to2 = FLOAT(dst_angle_stop[0])
	if from1 lt 0 or from1 gt 360 then $
		MESSAGE, 'SrcAngleStart is out of the range [0,360]'
	if from2 lt 0 or from2 gt 360 then $
		MESSAGE, 'SrcAngleStop is out of the range [0,360]'
	if to1 lt 0 or to1 gt 360 then $
		MESSAGE, 'DstAngleStart is out of the range [0,360]'
	if to2 lt 0 or to2 gt 360 then $
		MESSAGE, 'DstAngleStop is out of the range [0,360]'

	;; Sort out angles
	if  from_cw then if from1 lt from2 then from1 += 360
	if NOT from_cw then if from2 lt from1 then from2 += 360
	if  to_cw then if to1 lt to2 then to1 += 360
	if NOT to_cw then if to2 lt to1 then to2 += 360

	;; Convert to HSV - now floating point, H is in terms of degrees
	COLOR_CONVERT, in_arr, hsv, /RGB_HSV
	;; Extract the Hue channel.
	h = REFORM(hsv[0,*,*], dims[1] * dims[2])
	tmp = h + 360.
	;; Get the indices that are in the From range
	if from2 gt from1 then begin
		ind1 = WHERE(from1 le h and h le from2)
		ind2 = WHERE(from1 le tmp and tmp le from2)
	endif else begin
		ind1 = WHERE(from2 le h and h le from1)
		ind2 = WHERE(from2 le tmp and tmp le from1)
	endelse
	;; Compute a common subexpression
	tmp = to2-to1
	if from1 ne from2 then $
		tmp = tmp / (from2-from1)
	;; Apply the conversion to the To range
	if ind1[0] ne -1 then h[ind1] = to1 + tmp * (h[ind1]-from1)
	if ind2[0] ne -1 then h[ind2] = to1 + tmp * (h[ind2]+360-from1)
	;; Stuff the Hue channel back into the image
	hsv[0,0,0] = REFORM(TEMPORARY(h), 1, dims[1], dims[2])
	;; Convert back to RGB and return
	COLOR_CONVERT, TEMPORARY(hsv), result, /HSV_RGB
	RETURN, result
end

