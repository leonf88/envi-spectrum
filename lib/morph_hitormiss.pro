; $Id: //depot/idl/releases/IDL_80/idldir/lib/morph_hitormiss.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MORPH_HITORMISS
;
; PURPOSE:
;	This function applies the hit-or-miss operator to a binary image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;
;	Result = MORPH_HITORMISS(Image, HitStructure, MissStructure)
;
; INPUTS:
;	Image:	A one-, two-, or three-dimensional array upon which the
;		hit-or-miss operation is to be performed.  The image is treated
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
;	input Image parameter) that represents the result of the hit-or-miss
;	operation.
;
; PROCEDURE:
;	The hit-or-miss operator is implemented by first applying an erosion
;	operator to the original image (using a 'hit' structuring element),
;	then applying an erosion operator to the complement of the original
;	image (using a secondary 'miss' structuring element), and computing
;	the intersection of the two results.
;
; REFERENCE:
;	Edward R. Dougherty
;	AN INTRODUCTION TO MORPHOLOGICAL IMAGE PROCESSING
;       The Society of Photo-Optical Instrumentation Engineers, 1992.
;
; EXAMPLE:
;
;	Apply the hit-or-miss operator to a sample image:
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
;               ; Apply hit-or-miss operator.
;               hit = [[0,0,0],[0,1,0],[0,0,0]]
;               miss = 1 - hit
;		oimg = MORPH_HITORMISS(bimg, hit, miss)
;
; MODIFICATION HISTORY:
; 	Written by:	David Stern, July 1999.
;   Modified: CT, RSI, Oct 2003: Add ON_ERROR
;-

FUNCTION MORPH_HITORMISS, Image, HitStructure, MissStructure
    ON_ERROR, 2  ; return to caller
    RETURN, ERODE(Image, HitStructure) AND ERODE(Image EQ 0b, MissStructure)
END
