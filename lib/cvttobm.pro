; $Id: //depot/idl/releases/IDL_80/idldir/lib/cvttobm.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME: Cvttobm
;
; PURPOSE:
;	Converts a byte array in which each byte represents one pixel
;       into a bitmap byte array in which each bit represents one
;       pixel. This is useful when creating bitmap labels for buttons
;       created with the WIDGET_BUTTON function.
;
;       Bitmap byte arrays are monochrome; by default, CVTTOBM converts
;       pixels that are darker than the median value to black and pixels
;       that are lighter than the median value to white. You can supply
;       a different threshold value via the THRESHOLD keyword.
;
;       Most of IDL's image file format reading functions (READ_BMP,
;       READ_PICT, etc.) return a byte array which must be converted
;       before use as a button label. Note that there is one exception
;       to this rule; the READ_X11_BITMAP routine returns a bitmap
;       byte array that needs no conversion before use.
;
; CATEGORY:
;
;       Widgets, button bitmaps
;
; CALLING SEQUENCE:
;
;	bitmap = Cvttobm(array [,THRESHOLD = Threshold])
;
; INPUTS:
;	array - A 2-dimensional pixel array, one byte per pixel
;
;
; OPTIONAL INPUTS:
;       None
;
;
; KEYWORD PARAMETERS:
;
;	THRESHOLD - A byte value (or an integer value between 0 and 255)
;                   to be used as a threshold value when determining if
;                   a particular pixel is black or white. If not specified,
;                   the threshold is calculated to be the average of the
;                   input array.
;
; OUTPUTS:
;	bitmap - bitmap byte array, in which each bit represents one pixel
;
;
; OPTIONAL OUTPUTS:
;       None
;
;
; COMMON BLOCKS:
;       None
;
;
; SIDE EFFECTS:
;       None
;
;
; RESTRICTIONS:
;       None
;
;
; PROCEDURE:
; 1. Creates mask from input array, where values are 0/1 based on threshold.
; 2. Calculates the size of the output array.
; 3. Calculates the bitmap array from byte array based on mask.
;
; EXAMPLE:
;
; IDL> image=bytscl(dist(100))
; IDL> base=widget_base(/column)
; IDL> button=widget_button(base,value=Cvttobm(image))
; IDL> widget_control,base,/realize
;
;
; MODIFICATION HISTORY:
;       Created: Mark Rehder, 10/96
;       Modified: Lubos Pochman, 10/96
;   CT, RSI, Sept 2003: Added ON_ERROR.
;-

function Cvttobm, array, THRESHOLD=threshold

    compile_opt idl2, hidden

    ON_ERROR, 2

    s = size(array)
    if s[0] ne 2 then message, "Input array is not a 2D array!"
    ;
    ; Check the THRESHOLD keyword
    ;
    mask=bytscl(reverse(array,2))
    if (N_ELEMENTS(THRESHOLD) eq 0) then threshold=total(mask)/n_elements(mask)
    ;
    ; Calculate mask based on threshold
    ;
    mask[where(mask lt threshold)]=0b
    mask[where(mask ge threshold)]=1b
    ;
    ; Calculate the new size of the bitmap array
    ;
    s=size(mask) & cols=((s[1]-1)/8+1) & rows=s[2]
    bmp=bytarr(cols,rows)
    mult=[[1],[2],[4],[8],[16],[32],[64],[128]]
    ;
    ; Calculate the bitmap array from byte array based on mask
    ;
    vect=intarr(8)
    for i=0,cols-1 do begin
        for j=0,rows-1 do begin
            temp=reform(mask[i*8:min([s[1]-1,i*8+7]),j])
            vect[0:N_ELEMENTS(temp)-1]=temp
            bmp[i,j]=byte(vect##mult)
        endfor
    endfor

    return,bmp
end
