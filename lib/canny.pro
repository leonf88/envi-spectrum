;; $Id: //depot/idl/releases/IDL_80/idldir/lib/canny.pro#1 $
;;
;; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
;; Canny
;;
;; Purpose:
;;   This function implements the Canny edge detection algorithm
;;
;; Parameters:
;;   IMAGE - A 2D image
;;
;; Keywords:
;;   HIGH - The high value to be used during edge detection.  Given as
;;          a factor of the histgram of the magnitude array.  Input
;;          range : [0 - 1]
;;
;;   LOW - The low value to be used during edge detection.  Given as a
;;         factor of the HIGH value.  Input range : [0 - 1]
;;
;;   SIGMA - The sigma value to be used when creating the gaussian kernel.
;;
;-

;;---------------------------------------------------------------------------
;; Canny_Follow
;;
;; Purpose:
;;   Recursive routine that follows edges from until they drop below
;;   the lower threshold
;;
;; Parameters:
;;   I - index into nms and marked arrays
;;
;;   J - index into nms and marked arrays
;;
;;   NMS - array of locations where the non-maxima supression values
;;         are above the low threshold
;;
;;   MARKED - array keeping track of which pixels are marked as edges
;;
;; Keywords:
;;   NONE
;;
PRO canny_follow, i, j, nms, marked

  marked[i,j] = 1b
  ;; check point x-1, y-1
  IF (nms[i-1, j-1] && ~marked[i-1, j-1]) THEN $
    canny_follow, i-1, j-1, nms, marked
  ;; check point x, y-1
  IF (nms[i, j-1] && ~marked[i, j-1]) THEN $
    canny_follow, i, j-1, nms, marked
  ;; check point x+1, y-1
  IF (nms[i+1, j-1] && ~marked[i+1, j-1]) THEN $
    canny_follow, i+1, j-1, nms, marked
  ;; check point x-1, y
  IF (nms[i-1, j] && ~marked[i-1, j]) THEN $
    canny_follow, i-1, j, nms, marked
  ;; check point x+1, y
  IF (nms[i+1, j] && ~marked[i+1, j]) THEN $
    canny_follow, i+1, j, nms, marked
  ;; check point x-1, y+1
  IF (nms[i-1, j+1] && ~marked[i-1, j+1]) THEN $
    canny_follow, i-1, j+1, nms, marked
  ;; check point x, y+1
  IF (nms[i, j+1] && ~marked[i, j+1]) THEN $
    canny_follow, i, j+1, nms, marked
  ;; check point x+1, y+1
  IF (nms[i+1, j+1] && ~marked[i+1, j+1]) THEN $
    canny_follow, i+1, j+1, nms, marked

END


;;---------------------------------------------------------------------------
;; Canny_Track
;;
;; Purpose:
;;   Call the follow function on all non-maxima points greater than
;;   the high threshold.
;;
;; Parameters:
;;   NMS - non maxima values
;;
;;   LOW - low threshold
;;
;;   HIGH - high threshold
;;
;; Keywords:
;;   NONE
;;
FUNCTION canny_track, nms, low, high

  sz = size(nms)
  ;; make byte array to hold result
  marked = make_array(size=sz, type=1)
  ;; find locations where non-maxima is greater than high threshold
  wh = where(nms GE high, cnt)
  ;; no longer need real values, just where nms is greater than the
  ;; low threshold
  nms GT= low
  ;; run through each high point and follow it, that is unless a
  ;; previous follow has already marked it
  FOR i=0l,cnt-1 DO $
    IF ~marked[wh[i]] THEN $
    canny_follow, wh[i] MOD sz[1], wh[i] / sz[1], nms, marked

  return, marked

END


;;---------------------------------------------------------------------------
;; Canny_sector
;;
;; Purpose:
;;   Determines which sector a given angle falls into.  Angles are
;;   grouped as follows (degrees):
;;   -180   - -157.5 : sector 0
;;   -157.5 - -112.5 : sector 1
;;   -112.5 -  -67.5 : sector 2
;;    -67.5 -  -22.5 : sector 3
;;    -22.5 -   22.5 : sector 0
;;     22.5 -   67.5 : sector 1
;;     67.5 -  112.5 : sector 2
;;    112.5 -  157.5 : sector 3
;;    157.5 -  180   : sector 0
;;
;; Parameters:
;;   THETA - an array of angles (-pi : pi)
;;
;; Keywords:
;;   NONE
;;
FUNCTION canny_sector, theta

  ;; make array to hold result
  sector = make_array(size=size(theta), type=1)

  ;; group angles in bins of 22.5 degrees
  hist = histogram(theta, min=-!pi, max=!pi, $
                   binsize=!dtor*45/2, reverse_indices=rev)

  ;; assign sector value to all angles
  FOR i=0,15 DO $
    IF (hist[i] NE 0) THEN sector[rev[rev[i]:rev[i+1]-1]] = (i+1)/2 MOD 4

  return, sector

END


;;---------------------------------------------------------------------------
;; Canny_gaussian
;;
;; Purpose:
;;   Create a guassian kernal for smoothing
;;
;; Parameters:
;;   SIGMA - sigma value
;;
;;   WIDTH - desired width of the kernel
;;
;; Keywords:
;;   NONE
;;
FUNCTION canny_gaussian, sigma, width

  IF n_elements(sigma) NE 1 THEN sigma = 1.0d
  ;; if not specified create a 5x5 kernel
  IF (n_elements(width) EQ 0) THEN width = 5

  ;; create X and Y indices
  x = (dindgen(width)-width/2) # replicate(1, width)
  y = transpose(x)

  ;; create kernel
  kernel = exp(-((x^2)+(y^2))/(2*double(sigma)^2)) / (sqrt(2.0*!pi) * double(sigma))
  ;; give it an appropriate scale factor
  scale = 1/min(kernel) < 16384
  kernel = TEMPORARY(kernel)*scale + 1d-6

  return, long(kernel)

END


;;---------------------------------------------------------------------------
;; Canny
;;
;; Purpose:
;;   Main routine
;;
FUNCTION canny, image, low=t1, high=t2, sigma=sigma

  ;; verify we do have a grayscale image
  IF (size(image, /n_dimensions) NE 2) THEN $
    return, 0
  ;; verify that cols and rows are greater than 3
  ;; (3 needed for sobel operator)
  IF ~min((size(image, /dimensions))[0:1] GE replicate(3, 2)) THEN $
    return, 0

  tname = size(image, /tname)

  ;; weed out inappropriate input types
  IF ((tname EQ 'STRING') || (tname EQ 'STRUCT') || (tname EQ 'POINTER') || $
      (tname EQ 'OBJREF')) THEN $
    return, 0

  ;; ensure that image type is something that will be properly
  ;; processed
  CASE tname OF
    ;; image data cannot be less than 4 bytes or else convol might
    ;; clip results
    'BYTE' : im = long(image)
    'INT' : im = long(image)
    'UINT' : im = long(image)
    ;; image data cannot be complex
    'COMPLEX' : im = float(image)
    'DCOMPLEX' : im = double(image)
    ;; image data cannot be unsigned or else the sobel convol will
    ;; return huge numbers instead of negative values
    'ULONG' : im = long(image)
    'ULONG64' : im = long64(image)
    ELSE : im = image
  ENDCASE

  sz = size(im,/dimensions)

  IF n_elements(t1) NE 1 THEN t1 = 0.4
  IF n_elements(t2) NE 1 THEN t2 = 0.8
  IF n_elements(sigma) NE 1 THEN sigma = 0.6

  ;; Ensure inputs fall within realistic values
  ((t1 >= 0.01)) <= 0.99
  ((t2 >= (t1+0.01))) <= 1.00
  ((sigma >= 0.1)) <= 99.9

  ;; step 1 : apply gaussian smoothing
  gaussKernel = canny_gaussian(sigma, 5 < min(sz))
  smoothIm = convol(im, gaussKernel, total(gaussKernel))

  ;; step 2 : find gradient of image
  ;; use Sobel convolution masks
  gxKern = [[-1, 0, 1],[-2, 0, 2],[-1, 0, 1]]
  gyKern = [[-1,-2,-1],[ 0, 0, 0],[ 1, 2, 1]]
  gx = convol(smoothIm, gxKern, total(gxKern))
  gy = convol(smoothIm, gyKern, total(gyKern))

  ;; step 3 : find edge direction and magnitude
  mag = sqrt(gx^2 + gy^2)
  ;; zero the 3-pixel edges left over from boundary conditions from
  ;; the smoothing and the convolution

  ;; left
  mag[0:2, 0:sz[1]-1] = 0
  ;; right
  mag[sz[0]-3:sz[0]-1, 0:sz[1]-1] = 0
  ;; bottom
  mag[0:sz[0]-1, 0:2] = 0
  ;; top
  mag[0:sz[0]-1, sz[1]-3:sz[1]-1] = 0
  ;; calculate angles of gradient
  theta = atan(gy, gx)
  ;; get sector of angle : 0-3
  sector = canny_sector(theta)

  ;; step 4 : nonmaxima suppression
  ;; create arrays of current x|y locations
  xloc = lindgen(sz[0]) #  replicate(1, sz[1])
  yloc = lindgen(sz[1]) ## replicate(1, sz[0])
  ;; get arrays of x|y offsets based on sector
  xoffset = ((tmp=(indgen(4)-2)*(-1))/(tmp>1))[sector]
  yoffset = (indgen(4) GT 0)[sector]
  ;; special case where magnitude equals 0.  No magnitude means no
  ;; offsets.
  wh = where(~mag, cnt)
  IF (cnt NE 0) THEN BEGIN
    xoffset[wh] = 0
    yoffset[wh] = 0
  ENDIF
  ;; get points immedieatly up and down gradient
  side1 = mag[xloc+xoffset, yloc+yoffset]
  side2 = mag[xloc-xoffset, yloc-yoffset]
  ;; only accept points that are local maximum in direction of the
  ;; gradient
  nmsupp_mask = (mag GT side1) AND (mag GT side2)
  ;; get special mask to account for smooth steps, e.g., 0 0 0 1 1 1
  ;; this sort of edge fails the above test but it is nice to return
  ;; them as edges.
  step = (mag EQ side1) AND (mag GT side2)
  ;; get suppressed magnitudes
  suppMag = nmsupp_mask * mag
  ;; update mask with step edges.  The suppressed magnitude array is
  ;; not yet updated because the original values are needed below when
  ;; calculating thigh and tlow.  suppMag will be recalculated later
  ;; if needed.
  nmsupp_mask OR= step

  ;; if no edges found then return an empty array
  IF ~max(nmsupp_mask) THEN return, nmsupp_mask

  ;; calculate high and low based on input t1 and t2
  ;; take cumulative histogram of nonzero magnitude values.
  ;; if no normal edges have been found but we have reached this
  ;; point then recalculate suppMag to take in 'step' edges.
  IF ~max(suppMag) THEN BEGIN
    suppMag = nmsupp_mask * mag
    ;; set flag to indicate that suppMag has been recalculated.
    stepflag = 1b
  ENDIF

  ;; Finding the histogram values may cause floating-point errors if all
  ;; input values are the same.  These are harmless but annoying. So check
  ;; the error status before we go in, and swallow the errors if none are
  ;; currently pending.  If !EXCEPT is set to 2 then all errors will be
  ;; reported regardless.
  mathError = CHECK_MATH(/NOCLEAR)

  cum = total(histogram(suppMag[where(suppMag)],nbins=100,locations=locs), $
              /cumulative)

  ;; If no errors are pending, then clear all exceptions.
  IF (mathError EQ 0) THEN $
    dummy = CHECK_MATH()

  ;; high value is percentage point in the histogram
  thigh = locs[(where(cum GE (cum[[-1ull]]*t2)[0]))[0]]
  ;; low value is a percentage of high value
  tlow = thigh * t1

  ;; step 5 : edge thresholding (hysteresis)
  ;; special case to account for smooth steps, e.g., 0 0 0 1 1 1
  ;; recalculate suppMag.  This must be done after determining thigh
  ;; and tlow above in order not to throw off edges that need to be
  ;; detected.
  IF (max(step) && ~n_elements(stepflag)) THEN $
    suppMag = nmsupp_mask * mag
  tracked = canny_track(suppMag, tlow, thigh)

  return, tracked NE 0

END
