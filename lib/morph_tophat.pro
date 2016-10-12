; $Id: //depot/idl/releases/IDL_80/idldir/lib/morph_tophat.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MORPH_TOPHAT
;
; PURPOSE:
;	This function applies the top-hat operator to a grayscale image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;
;	Result = MORPH_TOPHAT(Image, Structure)
;
; INPUTS:
;	Image:	A one-, two-, or three-dimensional array upon which the
;		top-hat operation is to be performed.  The image is treated
;		as a grayscale	image.  If the image is not of type unsigned
;		long, a temporary unsigned long copy is obtained.
;	Structure: A one-, two-, or three-dimensional array to be used
;		as the structuring element.  The elements are interpreted
;		as binary values -- either zero or nonzero.  The structuring
;		element must have the same number of dimensions as the
;		Image argument.
;
; KEYWORD PARAMETERS:
;	VALUES:	Set this keyword to an array providing the values of the
;		structuring element.  This array must have the same
;		dimensions as the Structure parameter.
;
; OUTPUTS:
;	This function returns an array (of the same dimensions as the
;	input Image parameter) that represents the result of the top-hat
;	operation.
;
; PROCEDURE:
;	The top-hat operator is implemented as the subtraction of an opened
;	version of the original image from the original image.
;
; REFERENCE:
;	Edward R. Dougherty
;	AN INTRODUCTION TO MORPHOLOGICAL IMAGE PROCESSING
;       The Society of Photo-Optical Instrumentation Engineers, 1992.
;
; EXAMPLE:
;
;	Apply the top-hat operator to a sample image:
;
;               ; Load an image.
;               img = BYTARR(256,256)
;		filename = FILEPATH('galaxy.dat',SUBDIR=['examples','data'])
;		OPENR, lun, filename, /GET_LUN
;		READU, lun, img
;		CLOSE, lun
;
;               ; Apply closing operator.
;               s = REPLICATE(1,3,3)
;		oimg = MORPH_TOPHAT(img, s)
;
; MODIFICATION HISTORY:
; 	Written by:	David Stern, July 1999.
;   Modified: CT, RSI, Oct 2003: Add ON_ERROR
;-

FUNCTION MORPH_TOPHAT, Image, Structure, _EXTRA=e
    ON_ERROR, 2  ; return to caller
    RETURN, Image - MORPH_OPEN(Image, Structure, /GRAY, _EXTRA=e)
END
