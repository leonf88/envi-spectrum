; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_dicom.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;
;       Return the first datum reference in iref before the reference imgid.
;
FUNCTION ReadDicomGetFirstBefore, oDicom, iref, imgid

	COMPILE_OPT hidden, strictarr

	iIndex = iref[0]

	parent = oDicom->GetParent(imgid)
	par_iref = oDicom->GetParent(iref)
	v = WHERE(par_iref EQ parent)
	IF (v[0] NE -1) THEN BEGIN
		v_iref = iref[v]
		w = WHERE(v_iref LT imgid)
		IF (w[0] NE -1) THEN BEGIN
			iIndex = v_iref[w[N_ELEMENTS(w)-1]]
		END
	END

	p = oDicom->GetValue(REFERENCE=iIndex,/NO_COPY)

	RETURN, p[0]
END

;+
; NAME:
;	READ_DICOM
;
; PURPOSE:
; 	This function reads an image from a DICOM format file using
;	the IDLffDICOM object interface.
;
; CATEGORY:
;   	Input/Output
;
; CALLING SEQUENCE:
;   	Result = READ_DICOM(File)
;
; INPUTS:
; 	File: The full path name of the file to read.
;       [Red, Green, Blue] = Vectors which return the color palette
;                            (if any)
;
; OPTIONAL KEYWORDS:
;       IMAGE_INDEX - Set this keyword to the index of the image to
;                     read from the file.
;
;       DICOMEX - Set this keyword to zero to force the use of the
;                 IDLffDicom object regardless of the availability of
;                 IDLffDicomEX.
;
; OUTPUTS:
;	This function returns a 2D array containing the image data
;	from the file.
;
; KEYWORDS:
;	None
;
; SIDE EFFECTS:
;   	IO is performed.
;
; RESTRICTIONS:
;       Only uncompressed data format is supported (as per current DICOM obj).
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   RJF, RSI.   Sep, 1998. Original version.
;   RJF, RSI.   Jan, 1999. Filter searches by sequence value.
;   AGEH, RSI, February, 2005: Use IDLffDicomEx object if licensed.
;   CT, July 2008: Add check for DICM magic cookie. Fix error handling.
;-
FUNCTION READ_DICOM, file, red, green, blue, $
                     IMAGE_INDEX = iIndex, DICOMEX=useDicomexIn, _EXTRA=ex

  COMPILE_OPT strictarr, hidden

  on_error, 2

  ;; verify that the file exists
  IF ~file_test(file) THEN BEGIN
    message, 'The system cannot find the file specified'
    return, 0l
  ENDIF

  ;; DICOM has a fatal error in accessing zero-length files
  ;; Avoid the problem by checking in advance
  OPENR, unit, file, /get_lun
  stat = FSTAT(unit)
  FREE_LUN, unit
  IF (stat.size EQ 0) THEN RETURN, 0L

  IF (n_elements(useDicomexIn) EQ 1) THEN $
    useDicomex = keyword_set(useDicomexIn) $
  ELSE $
    useDicomex = 1

  ;; only use dicomex if licensed
  catch, errorStatus
  IF (errorStatus NE 0) THEN BEGIN
    catch, /cancel
    MESSAGE, /RESET
    useDicomex = 0
  ENDIF ELSE BEGIN
    useDicomex = useDicomex && IDLffDicomExIsLicensed()
  ENDELSE

  IF (N_ELEMENTS(iIndex) EQ 0) THEN iIndex=0
  IF (iIndex LT 0) THEN iIndex = 0

  ;; Set up error handling specifically for reading non-dicom files
  ;; with the DicomEx object
  CATCH, errorStatus
  IF (errorStatus NE 0) THEN BEGIN
    CATCH,/CANCEL
    ;; If DICOM is not supported, throw catchable error - Fixes CR 51957
    IF !ERROR_STATE.NAME EQ 'IDL_M_DLM_UNAVAILABLE' $
      THEN MESSAGE, 'DICOM', NAME=!ERROR_STATE.NAME, BLOCK='IDL_MBLK_CORE'
    MESSAGE, /RESET
    IF (OBJ_VALID(oDicom)) THEN OBJ_DESTROY, oDicom
    RETURN, 0L
  ENDIF

  ;; be sure to destroy before return
  oDicom = useDicomex ? obj_new('idlffDicomEx', file, _EXTRA=ex) : $
           OBJ_NEW('IDLffDICOM', _EXTRA=ex)

  ;; Fail if object cannot be created.
  IF ~obj_valid(oDicom) THEN return, 0l

  ;; Set up error handling
  CATCH, errorStatus
  IF (errorStatus NE 0) THEN BEGIN
    CATCH,/CANCEL
    MESSAGE, /RESET
    if (N_Elements(lun) gt 0) then FREE_LUN, lun, /FORCE
    IF (OBJ_VALID(oDicom)) THEN OBJ_DESTROY, oDicom
    RETURN, 0L
  ENDIF

  IF obj_isa(oDicom, 'IDLffDicom') THEN BEGIN
    ;; use IDLffDicom object

    ; Our free DICOM reader can only handle files with the correct preamble.
    ; Do a quick check for the magic cookie.
    OPENR, lun, file, /GET_LUN
    x = BYTARR(132)
    READU, lun, x
    FREE_LUN, lun, /FORCE
    if (STRING(x[128:131]) ne 'DICM') then begin
      OBJ_DESTROY, oDicom
      CATCH,/CANCEL
      MESSAGE,'The file '+file+' is missing the DICOM preamble.'
    endif
    
    ;; Open the file
    IF (oDicom->Read(file) NE 1) THEN BEGIN
      OBJ_DESTROY, oDicom
      CATCH,/CANCEL
      MESSAGE,'The file '+file+' is not in a supported DICOM format.'
    ENDIF

    ;; Get a list of the images
    ref = oDicom->GetReference('7FE0'x,'0010'x)
    IF (SIZE(ref,/N_DIMENSIONS) EQ 0) THEN BEGIN
      OBJ_DESTROY, oDicom
      CATCH,/CANCEL
      MESSAGE,'No images could be found in the DICOM file.'
    ENDIF
    IF (iIndex GE N_ELEMENTS(ref)) THEN BEGIN
      OBJ_DESTROY, oDicom
      CATCH,/CANCEL
      MESSAGE,'There are only '+STRING(N_ELEMENTS(ref))+ $
              ' images in the DICOM file.'
    ENDIF

    ;; Get the image in question
    img = oDicom->GetValue(REFERENCE=ref[iIndex],/NO_COPY)
    ret = *(img[0])

    ;; Get additional image info (samples/pixel and palette)
    iSamp = 1
    iref = oDicom->GetReference('0028'x,'0002'x)
    IF (SIZE(iref,/N_DIMENSIONS) NE 0) THEN BEGIN
      p = ReadDicomGetFirstBefore(oDicom,iref,ref[iIndex])
      IF (PTR_VALID(p)) THEN iSamp = *p
    ENDIF

    iPlanar = 0
    IF (iSamp GT 1) THEN BEGIN
      iref = oDicom->GetReference('0028'x,'0006'x)
      IF (SIZE(iref,/N_DIMENSIONS) NE 0) THEN BEGIN
        p = ReadDicomGetFirstBefore(oDicom,iref,ref[iIndex])
        IF (PTR_VALID(p)) THEN iPlanar = *p
      ENDIF
    ENDIF

    ;;	This interface always returns pixel interleaved data...

    IF (iPlanar NE 0) THEN BEGIN
      ret = TRANSPOSE(ret,[2,0,1]) ; planar to pixel interleave
    ENDIF

    iPalette = 0
    iref = oDicom->GetReference('0028'x,'0004'x)
    IF (SIZE(iref,/N_DIMENSIONS) NE 0) THEN BEGIN
      p = ReadDicomGetFirstBefore(oDicom,iref,ref[iIndex])
      IF ((PTR_VALID(p)) AND (STRPOS(*p,"PALETTE COLOR") NE -1)) THEN BEGIN

        ;; Read the palette vectors
        FOR i=0,2 DO BEGIN

          ;;	Get the offset value
          iOffset = 0
          iref = oDicom->GetReference('0028'x,'1101'x+i)
          IF (SIZE(iref,/N_DIMENSIONS) NE 0) THEN BEGIN
            p = ReadDicomGetFirstBefore(oDicom,iref,ref[iIndex])
            IF (PTR_VALID(p)) THEN iOffset = (*p)[1]
          END

          ;;	Get the actual palette
          iref = oDicom->GetReference('0028'x,'1201'x+i)
          IF (SIZE(iref,/N_DIMENSIONS) NE 0) THEN BEGIN
            p = ReadDicomGetFirstBefore(oDicom,iref,ref[iIndex])
            IF (PTR_VALID(p)) THEN BEGIN
              v = REPLICATE((*p)[0],iOffset+N_ELEMENTS(*p))
              v[iOffset:*] = *p
              CASE i OF
                0 : red = v
                1 : green = v
                2 : blue = v
              ENDCASE
            ENDIF
          ENDIF

        ENDFOR
      ENDIF
    ENDIF
  ENDIF ELSE BEGIN
    ;; use IDLffDicomEx object
    ret = oDicom->GetPixelData(FRAME=iIndex, /ORDER)
    oDicom->GetProperty, PHOTOMETRIC_INTERPRETATION=photo, $
                         SAMPLES_PER_PIXEL=channels
    IF (channels GT 1) THEN BEGIN
      oDicom->GetProperty, PLANAR_CONFIGURATION=planar
      IF planar THEN $
        ret = TRANSPOSE(ret,[2,0,1])
    ENDIF
    IF (photo EQ 'PALETTE COLOR') THEN BEGIN
      red = oDicom->GetValue('0028,1201')
      green = oDicom->GetValue('0028,1202')
      blue = oDicom->GetValue('0028,1203')
    ENDIF
  ENDELSE

  ;; Done!!
  OBJ_DESTROY, oDicom

  RETURN, ret

END
