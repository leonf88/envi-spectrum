; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitthumbresize.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; IDLitTool::_Thumb_Downsize
;
; Purpose:
;   Downsizes an image plane.  Used by GetThumbnail.
;
; Parameters:
;   IMAGEIN - A 2D image array
;
;   TSIZE - The size of the square thumbnail to return
;
; Keywords:
;   NONE
;
function _IDLitThumb_Downsize, imageIn, tSize

  compile_opt idl2, hidden

  on_error, 2
  
  kernel = [[ 0, -1,  0], $
            [-1,  8, -1], $
            [ 0, -1,  0]]

  image = imageIn
  origdims = SIZE(image, /DIMENSIONS)
  ;; Calculate new X and Y sizes for image, keeping aspect ratio
  aspect = FLOAT(origdims[0])/origdims[1]
  if (aspect gt 1.0) then begin
    newX = tSize
    newY = FIX(tSize/aspect)
  endif else begin
    newY = tSize
    newX = FIX(tSize*aspect)
  endelse
  scale = MAX(origdims)/tSize

  for i=0,(ALOG(scale)/ALOG(2))-1 do begin
    dims = SIZE(image, /dimensions)
    ;; Ensure even sizes
    odd = dims mod 2
    if (MAX(odd)) then $
      image = image[0:dims[0]-1-odd[0], 0:dims[1]-1-odd[1]]
    ;; Cut image in half then sharpen
    image = REBIN(image, dims/2)
    image = CONVOL(image, kernel, 4, /EDGE_TRUNCATE)
  end

  ;; Put into proper size
  image = CONGRID(image, newX, newY, /INTERP, /MINUS_ONE)

  return, image
  
end


;---------------------------------------------------------------------------
; _IDLitThumbResize
;
; Purpose:
;   Converts a large truecolor image to a 3xMxM thumbnail.
;
; Parameters:
;   NONE
;
; Keywords:
;   THUMBSIZE : The size of the thumbnail to return.  The thumbnail is always
;               returned as a square image.  If not supplied a default value
;               of 32 is used.  THUMBSIZE must be greather than 3 and must 
;               be smaller than the original image dimensions.
;
;   THUMBBACKGROUND : The colour of the excess background to use in the 
;                     thumbnail.  This only has effect if the aspect ratio of
;                     the tool window is not equal to 1.  If set to a scalar
;                     value the colour of the lower left pixel of the window
;                     is used as the background colour.  If set to an RGB
;                     triplet the supplied colour will be used.  If not
;                     specified a value of [255,255,255] (white) is used.
;
;   THUMBORDER : Set this keyword to return the thumbnail in top-to-bottom order
;            rather than the IDL default of bottom-to-top order.
;
FUNCTION _IDLitThumbResize, bits, HEIGHT=heightIn, $
                                  WIDTH=widthIn, $ 
                                  THUMBSIZE=tSizeIn, $
                                  THUMBBACKGROUND=tColourIn, $
                                  THUMBORDER=tOrder
  compile_opt idl2, hidden

  on_error, 2
  
  ;; Return a scalar if something fails
  thumb = 0b

  ;; Default background colour is white
  tColour = [255b, 255b, 255b]
  ;; If THUMBBACKGROUND is set use lower left corner of image
  if (N_ELEMENTS(tColourIn) eq 1) then $
    tColour = bits[*,0,0]
  ;; If THUMBBACKGROUND is RGB use it
  if (N_ELEMENTS(tColourIn) eq 3) then $
    tColour = tColourIn

  dims = SIZE(bits, /DIMENSIONS)
  bitAspect = FLOAT(dims[-1])/dims[-2]

  tSize = N_ELEMENTS(tSizeIn) gt 0 ? FIX(tSizeIn[0]) : 32
  newSize = (ISA(heightIn) && ISA(widthIn)) ? [widthIn, heightIn] : $
    (ISA(heightIn) ? [heightIn/bitAspect, heightIn] : $
     (ISA(widthIn) ? [widthIn, widthIn*bitAspect] : [tSize, tSize]))
  newAspect = FLOAT(newSize[1])/newSize[0]
  
  ;; Thumbsize must be smaller than original image
  if ((tSize lt MIN(dims[1:2])) && (tSize ge 4)) then begin
    ;; Create output thumbnail image
    thumb = BYTARR(3,newSize[0],newSize[1])
    ;; Set background colour of thumbnail
    for i=0,2 do $
      thumb[i,*,*] = tColour[i]
    ;; Calculate size of image to be produced
    if (newAspect gt bitAspect) then begin
      newX = newSize[0]
      newY = FIX(newSize[0]*bitAspect)
      x1 = 0
      x2 = newSize[0]-1
      y1 = newSize[1]/2 - newY/2
      y2 = y1+newY-1
    endif else begin
      newY = newSize[1]
      newX = FIX(newSize[1]/bitAspect)
      x1 = newSize[0]/2 - newX/2
      x2 = x1+newX-1
      y1 = 0
      y2 = newSize[1]-1
    endelse
    ;; Downsample each image plane
    for i=0,2 do begin
      thumb[i,x1:x2,y1:y2] = $
        CONGRID(_IDLitThumb_Downsize(REFORM(bits[i,*,*]), MAX([newX,newY])), $
                newX, newY)
    endfor
    if (KEYWORD_SET(tOrder)) then begin
      thumb = thumb[*,*,tSize-1-LINDGEN(tSize)]
    endif
  endif
  
  return, thumb
  
end
