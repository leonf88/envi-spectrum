; $Id: //depot/idl/releases/IDL_80/idldir/lib/morph_close.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MORPH_CLOSE
;
; PURPOSE:
;	This function applies the closing operator to a binary or grayscale
;	image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;
;	Result = MORPH_CLOSE(Image, Structure)
;
; INPUTS:
;	Image:	A one-, two-, or three-dimensional array upon which the
;		closing operation is to be performed.  If the GRAY or
;		VALUES keyword is set, the image is treated as a grayscale
;		image; in this case, if the image is not of type unsigned
;		long, a temporary unsigned long copy is obtained.  If neither
;		the GRAY nor VALUES keyword is set, the image is treated
;		as a binary image with all nonzero pixels considered as 1;
;		in this case, if the image is not of type byte, a temporary
;		byte copy is obtained.
;	Structure: A one-, two-, or three-dimensional array to be used
;		as the structuring element.  The elements are interpreted
;		as binary values -- either zero or nonzero.  The structuring
;		element must have the same number of dimensions as the
;		Image argument.
;
; KEYWORD PARAMETERS:
;	GRAY:	Set this keyword to perform a grayscale, rather than binary,
;		operation.  Nonzero elements of the Structure parameter
;		determine the shape of the structuring element.
;
;	VALUES:	Set this keyword to an array providing the values of the
;		structuring element.  This array must have the same
;		dimensions as the Structure parameter.  The presence of
;		this keyword implies a grayscale operation.
;
; OUTPUTS:
;	This function returns an array (of the same dimensions as the
;	input Image parameter) that represents the result of the closing
;	operation.
;
; PROCEDURE:
;	The closing operator is implemented as a dilation followed by
;	an erosion.
;
; REFERENCE:
;	Edward R. Dougherty
;	AN INTRODUCTION TO MORPHOLOGICAL IMAGE PROCESSING
;       The Society of Photo-Optical Instrumentation Engineers, 1992.
;
; EXAMPLE:
;
;	Apply the closing operator to a sample image:
;
;               ; Load an image.
;               img = BYTARR(256,256)
;		filename = FILEPATH('galaxy.dat',SUBDIR=['examples','data'])
;		OPENR, lun, filename, /GET_LUN
;		READU, lun, img
;		CLOSE, lun
;
;               ; Apply closing operator.
;               s = [[0,0,1,0,0],$
;                    [0,1,1,1,0],$
;                    [1,1,1,1,1],$
;                    [0,1,1,1,0],$
;                    [0,0,1,0,0]]
;		oimg = MORPH_CLOSE(img, s, /GRAY)
;
; MODIFICATION HISTORY:
; 	Written by:	David Stern, July 1999.
;   Modified: CT, RSI, Oct 2003: Add ON_ERROR
;-

FUNCTION MORPH_CLOSE, Image, Structure, _EXTRA=e
    ON_ERROR, 2  ; return to caller
    RETURN, ERODE(DILATE(Image, Structure, _EXTRA=e), Structure, _EXTRA=e)
END
