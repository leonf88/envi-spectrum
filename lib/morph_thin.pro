; $Id: //depot/idl/releases/IDL_80/idldir/lib/morph_thin.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MORPH_THIN
;
; PURPOSE:
;	This function applies a thinning operator to a binary image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;
;	Result = MORPH_THIN(Image, HitStructure, MissStructure)
;
; INPUTS:
;	Image:	A one-, two-, or three-dimensional array upon which the
;		thinning operation is to be performed.  The image is treated
;		as a binary image with all nonzero pixels considered as 1.
;		If the image is not of type byte, a temporary byte copy is
;		obtained.
;	HitStructure: A one-, two-, or three-dimensional array to be used
;		as the hit structuring element.  The elements are interpreted
;		as binary values -- either zero or nonzero.  The structuring
;		element must have the same number of dimensions as the
;		Image argument.
;	MissStructure: A one-, two-, or three-dimensional array to be used
;		as the miss structuring element.  The elements are interpreted
;		as binary values -- either zero or nonzero.  The structuring
;		element must have the same number of dimensions as the
;		Image argument.
;
;          NOTE: It is assumed that the HitStructure and MissStructure are
;                disjoint.
;
; KEYWORD PARAMETERS:
;	<None>
;
; OUTPUTS:
;	This function returns an array (of the same dimensions as the
;	input Image parameter) that represents the result of the thinning
;	operation.
;
; PROCEDURE:
;	The thinning operator is implemented by first applying a hit-or-miss
;	operator to the original image (using a pair of structuring elements),
;	and subtracting the result from the original image.
;
; REFERENCE:
;	Edward R. Dougherty
;	AN INTRODUCTION TO MORPHOLOGICAL IMAGE PROCESSING
;       The Society of Photo-Optical Instrumentation Engineers, 1992.
;
; EXAMPLE:
;
;	Apply the thinning operator to a sample image:
;
;               ; Load an image.
;               img = BYTARR(256,256)
;		filename = FILEPATH('galaxy.dat',SUBDIR=['examples','data'])
;		OPENR, lun, filename, /GET_LUN
;		READU, lun, img
;		CLOSE, lun
;
;               ; Map to binary.
;               bimg = img
;               bimg[WHERE(img lt 128)] = 0
;
;               ; Apply thinning operator.
;               hit =  [[0,0,0,0,0],$
;                       [0,0,0,0,0],$
;                       [0,0,1,0,0],$
;                       [0,0,0,0,0],$
;                       [0,0,0,0,0]]
;               miss = [[1,1,1,1,1],$
;                       [1,0,0,0,1],$
;                       [1,0,0,0,1],$
;                       [1,0,0,0,1],$
;                       [1,1,1,1,1]]
;		oimg = MORPH_THIN(bimg, hit, miss)
;
; MODIFICATION HISTORY:
; 	Written by:	David Stern, July 1999.
;   Modified: CT, RSI, Oct 2003: Add ON_ERROR
;-

FUNCTION MORPH_THIN, Image, HitStructure, MissStructure
    ON_ERROR, 2  ; return to caller
    ; Ensure image is binary.
    IF (MAX(Image) GT 1) THEN BEGIN
        binImage = Image
        binImage[WHERE(Image) NE 0] = 1
        RETURN, binImage - MORPH_HITORMISS(Image, HitStructure, MissStructure)
    ENDIF ELSE $
        RETURN, Image - MORPH_HITORMISS(Image, HitStructure, MissStructure)
END
