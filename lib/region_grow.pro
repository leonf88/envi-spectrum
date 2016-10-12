; $Id: //depot/idl/releases/IDL_80/idldir/lib/region_grow.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	REGION_GROW
;
; PURPOSE:
;	This function performs region growing for a given region within
;	an N-dimensional array.  REGION_GROW finds all pixels within the
;	array that are connected neighbors to the region pixels and that
;       fall within provided constraints.
;
;	The constraints are specified either as a threshold range (a
;       minimum and maximum pixel value) or as a multiple of the standard
;       deviation of the region pixel values.
;
;	If the threshold is used, the region is grown to include all
;       connected neighboring pixels that fall within the given threshold.
;
;	If the standard deviation multiple is used, the region is grown
;	to include all connected neighboring pixels that fall within the
;	range of the mean (of the region's pixel values) plus or minus the
;	multiple times the standard deviation.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = REGION_GROW(Array, ROIPixels)
;
; INPUTS:
;	Array:	An N-dimensional array of data values.  The region will
;		be grown according to the data values within this array.
;
;	ROIPixels:	A vector of indices into Array that represent
;		the initial region that is to be grown.
;
; KEYWORD PARAMETERS:
;	ALL_NEIGHBORS:	Set this keyword to indicate that all adjacent
;		neighbors to a given pixel should be considered during
;		region growing.  (This is sometimes called 8-neighbor
;		searching when the array is 2-dimensional.)  The default
;		is to search only the neighbors	that are exactly one unit
;		in distance from the current pixel (sometimes called
;		4-neighbor searching when the array is 2-dimensional).
;
;	NAN:	Set this keyword to a non-zero value to cause the routine
;		to check for occurrences of the IEEE floating-point value,
;		NaN, in the input array.  Elements with the value NaN are
;		treated as missing data.
;
;	STDDEV_MULTIPLIER:	Set this keyword to a scalar value that
;		serves as the multiplier of the standard deviation of the
;		original region pixel values.  The pixel values of the
;		grown region must fall within the range of:
;
;			Mean +/- StdDevMultiplier*StdDev
;
;		This keyword is mutually exclusive of THRESHOLD.
;
;	THRESHOLD:	Set this keyword to a two-element vector, [min,max],
;		of the inclusive range within which the pixel values of the
;		grown region must fall.  The default is the range of pixel
;		values within the initial region.  This keyword is mutually
;		exclusive of STDDEV_MULTIPLIER.
;
; OUTPUTS:
;	This function returns the vector of indices into Array that represent
;	pixels within the grown region.  (Note: the grown region will not
;       include pixels at the edges of the input array.)  If no pixels fall
;       within the grown region, this function returns the value -1.
;
; EXAMPLE:
;	Grow a pre-defined region within an image of human red blood cells.
;
;		; Load an image.
;		fname = FILEPATH('rbcells.jpg', SUBDIR=['examples','data'])
;		READ_JPEG, fname, img
;		imgDims = SIZE(img, /DIMENSIONS)
;
;		; Define original region pixels.
;		x = FINDGEN(16*16) MOD 16 + 276.
;		y = LINDGEN(16*16) / 16 + 254.
;		roiPixels = x + y * imgDims[0]
;
;		; Grow the region.
;		newROIPixels = REGION_GROW(img, roiPixels)
;
;		; Load a greyscale color table.
;		LOADCT, 0
;
;		; Set the topmost color table entry to red.
;		topClr = !D.TABLE_SIZE-1
;		TVLCT, 255, 0, 0, topClr
;
;		; Show the results.
;		tmpImg = BYTSCL(img, TOP=(topClr-1))
;		tmpImg[rOIPixels] = topClr
;		WINDOW, 0, XSIZE=imgDims[0], YSIZE=imgDims[1], $
;                     TITLE='Original Region'
;		TV, tmpImg
;
;		tmpImg = BYTSCL(img, TOP=(topClr-1))
;		tmpImg[newROIPixels] = topClr
;		WINDOW, 2, XSIZE=imgDims[0], YSIZE=imgDims[1], $
;                     TITLE='Grown Region'
;		TV, tmpImg
;
; MODIFICATION HISTORY:
; 	Written by:	DLD, February 2001.
;
;-
function REGION_GROW, array, roiPixels, $
    ALL_NEIGHBORS=allNeighbors, $
    NAN=nan, $
    STDDEV_MULTIPLIER=stdDevMult, $
    THRESHOLD=threshold

    ulong = 0
    CATCH, iErr
    if (iErr ne 0) then begin
        if ((!ERROR_STATE.CODE eq -512) && (ulong eq 0)) then begin
            ; The array may have more regions than fit within a UINT.
            ; If this is the case, use the ULONG keyword.
            ulong = 1
            MESSAGE, /RESET
            goto, doLabelRegion
        endif else begin
            CATCH, /CANCEL
            ON_ERROR, 2
            MESSAGE, /REISSUE_LAST
            return, -1L
        endelse
    endif

    arrDims = SIZE(array, /DIMENSIONS)

    ; Extract the image pixel values that fall within the input region.
    roiPixelData = array[roiPixels]
    nROIPixels = N_ELEMENTS(roiPixels)

    if (TOTAL(FINITE(roiPixelData)) eq 0) then $
        MESSAGE, $
            'Unable to grow region that consists entirely of missing data.'

    ; Set the initial threshold range for the grown region.
    if (N_ELEMENTS(threshold) eq 2) then begin
        thresh_lo = threshold[0]
        thresh_hi = threshold[1]
    endif else $
        thresh_lo = MIN(roiPixelData, MAX=thresh_hi, NAN=nan)

    ; If requested, compute a threshold range based on the standard
    ; deviation and mean.
    if (N_ELEMENTS(stdDevMult) ne 0) then begin
        if (N_ELEMENTS(threshold) eq 2) then begin
            errStr = 'STDDEV_MULTIPLIER and THRESHOLD are mutually ' + $
                     'exclusive.  Using the THRESHOLD value.'
            MESSAGE, /CONTINUE, errStr
        endif else begin
            if (nROIPixels gt 1) then begin
                mean = MEAN(roiPixelData, /DOUBLE, NAN=nan)
                sdev = STDDEV(roiPixelData, /DOUBLE, NAN=nan)
            endif else begin
                mean = roiPixelData
                sdev = 0.0d
            endelse
            offset = stdDevMult * sdev
            if (SIZE(array, /TYPE) le 3) then begin
                thresh_lo = ROUND(mean - offset)
                thresh_hi = ROUND(mean + offset)
            endif else begin
                thresh_lo = mean - offset
                thresh_hi = mean + offset
            endelse
        endelse
    endif

    ; Threshold the original image.
    if (KEYWORD_SET(nan)) then begin
        ; Temporarily overwrite array NaN values with 0s.
        iNan = WHERE(~FINITE(array), nNan)
        if (nNan gt 0) then begin
            oldNanVals = array[iNan]
            array[iNan] = 0
        endif
    endif else $
        nNan = 0

    threshArray = (array ge thresh_lo and array le thresh_hi)

    ; Replace NaN values in input array, and set result of threshArray
    ; accordingly.
    if (nNan gt 0) then begin
        array[iNan] = oldNanVals
        threshArray[iNan] = 0b
    endif

    ; Label the regions within the thresholded image.
doLabelRegion:
    labelArray = LABEL_REGION(threshArray, ALL_NEIGHBORS=allNeighbors, $
        ULONG=ulong)

    ; Determine which labels fall within the ROI.
    if (nROIPixels gt 1) then begin
        labels = WHERE(HISTOGRAM(labelArray[roiPixels], MIN=0) ne 0, nLabels)
    endif else begin
        nLabels = 1
        labels = labelArray[roiPixels]
    endelse

    ; Compute a total of all labeled pixels for the labels within the ROI
    ; (excluding pixels with a label of 0).
    labelHist = HISTOGRAM(labelArray, REVERSE=r, MIN=0)
    nPixels = TOTAL(labelHist[labels]) - (labelHist[labels[0]] * $
                    (labels[0] eq 0))

    ; Create a new array of pixel indices for the labeled pixels.
    if (nPixels gt 0) then begin
        growROIPixels = LONARR(nPixels)
        j = 0
        for i=0L, nLabels-1 do begin
            if (r[labels[i]+1] le N_ELEMENTS(r) and labels[i] ne 0) then begin
                growROIPixels[j] = r[r[labels[i]]:r[labels[i]+1]-1]
                j = j + labelHist[labels[i]]
            endif
        endfor
    endif else $
        growROIPixels = -1L

    return, growROIPixels
end
