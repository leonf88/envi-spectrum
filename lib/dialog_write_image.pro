; $Id: //depot/idl/releases/IDL_80/idldir/lib/dialog_write_image.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	DIALOG_WRITE_IMAGE
;
; PURPOSE:
;       This routine creates a GUI dialog for writing images.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = DIALOG_WRITE_IMAGE, Image [,R,G,B]
;
;		Result is a 1 if Save was clicked, 0 for Cancel.
;
; INPUTS:
;       [Image] - The data array to be written to the image file.
;	    R,G,B - Optional red,green,blue color vectors.
;
; OPTIONAL KEYWORDS:
;
;  DIALOG_PARENT - The widget ID of a widget that calls DIALOG_WRITE_IMAGE.
;	When this ID is specified, a death of the caller results in the
;   death of the DIALOG_WRITE_IMAGE dialog.
;
;  FILENAME - Set this keyword to a named variable to contain the name of the initial
;   file selection.
;
;  FIX_TYPE - When this keyword is set, only files that satisfy the type can be
;   selected.  The user has no ability to modify the type and the type field
;   is grayed out.
;
;  NOWRITE - Set this keyword to prevent the dialog from writing the file when Save
;            is clicked.  No data conversions will take place when the save type is chosen.
;
;  OPTIONS - Set this keyword to a named variable to contain a structure of the chosen
;            options by the user, including the filename and image type chosen.
;
;  PATH - Set this keyword to a string that contains the initial path
;	from which to select files.  If this keyword is not set,
;	the current working directory is used.
;
;  TITLE - Set this keyword to a scalar string to be used for the dialog
;	title.  If not specified, the default title is "Save Image File".
;
;  TYPE - Set this keyword to a scalar string containing the format type the
;   Save as type field should begin with.  The default is "TIFF".  The user
;   can modify the type unless the FIX_TYPE keyword is set.  Valid values
;   are obtained from the list of supported image types returned from
;   QUERY_IMAGE.
;
;  WARN_EXIST - If set, the user is warned if a filename is chosen
;      that matches an already existing file.
;
; OUTPUTS:
;	None.
;
; EXAMPLE:
;       DIALOG_WRITE_IMAGE, myData
;
; MODIFICATION HISTORY:
; 	Written by:	Scott Lasica, October, 1998
;   CT, RSI, July 2000: Force to be modal, even if no parent.
;             Added WARN_EXIST.
;   CT, RSI, May 2004: Added JPEG2000 support. Add TIFF LZW back in.
;-
;

pro dwi_options_event,ev

	COMPILE_OPT HIDDEN, STRICTARR

	WIDGET_CONTROL, ev.id, GET_UVALUE=uval
	WIDGET_CONTROL, ev.top, GET_UVALUE=options,/NO_COPY

	catch,error_status
	if (error_status ne 0) then begin
		result = DIALOG_MESSAGE(!ERROR_STATE.MSG,/ERROR)
		return
  	endif

	case uval of
	  'okBut': begin
	  	WIDGET_CONTROL, ev.top, /destroy
	  	return
	  end

	  'bmp4': (*options).FOUR_BIT = ev.select

	  'bmp8': (*options).FOUR_BIT = 0

	  'order': (*options).ORDER = ev.select

	  'jpegProg': (*options).PROGRESSIVE = ev.select

	  'jpegQuality': (*options).QUALITY = ev.value

	  'ppmASCII': (*options).ASCII = ev.select

	  'srf32bit': (*options).WRITE_32 = ev.select

	  'tifAppend': (*options).APPEND = ev.select

	  'tifXres': (*options).XRESOL = ev.value

	  'tifYres': (*options).YRESOL = ev.value

	  'tifComp': (*options).COMPRESSION = ev.index

	  'reversible': (*options).reversible = ev.select

	  'n_levels': (*options).n_levels = ev.value

	  'n_layers': begin
	    (*options).n_layers = 1 > ev.value
	    WIDGET_CONTROL, ev.id, SET_VALUE=(*options).n_layers
	    end

	endcase

	WIDGET_CONTROL, ev.top, SET_UVALUE = options,/NO_COPY

end


;; Options dialog
function dwi_options, parent, $
    BMP=bmp, JPEG=jpeg, PPM=ppm, SRF=srf, TIFF=tiff, JP2=jpeg2000

	COMPILE_OPT HIDDEN, STRICTARR

	dwi_options_base = WIDGET_BASE(TITLE='Image Options',/COLUMN, $
		/FLOATING, /MODAL, GROUP_LEADER=parent)
	center_base = WIDGET_BASE(dwi_options_base, /COLUMN)
	bottom_base = WIDGET_BASE(dwi_options_base, /COLUMN, /ALIGN_CENTER)
	okBut = WIDGET_BUTTON(bottom_base, VALUE='OK', UVALUE='okBut')

	if (keyword_set(bmp)) then begin
		placeholder = WIDGET_LABEL(center_base, VALUE='Bits per pixel')
		base = WIDGET_BASE(center_base, /COLUMN, /EXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='4',UVALUE='bmp4')
		placeholder = WIDGET_BUTTON(base, VALUE='8',UVALUE='bmp8')
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		WIDGET_CONTROL, placeholder, /SET_BUTTON
		options = PTR_NEW({FOUR_BIT: 0})
	endif
	if (keyword_set(jpeg)) then begin
		base = WIDGET_BASE(center_base, /COLUMN, /NONEXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='Order', UVALUE='order')
		placeholder = WIDGET_BUTTON(base, VALUE='Progressive',UVALUE='jpegProg')
		placeholder = WIDGET_SLIDER(center_base, VALUE=75,TITLE='Quality',UVALUE='jpegQuality')
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		options = PTR_NEW({ORDER: 0, PROGRESSIVE: 0, QUALITY: 75})
	endif
	if (keyword_set(ppm)) then begin
		base = WIDGET_BASE(center_base, /COLUMN, /NONEXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='ASCII', UVALUE='ppmASCII')
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		options = PTR_NEW({ASCII: 0})
	endif
	if (keyword_set(srf)) then begin
		base = WIDGET_BASE(center_base, /COLUMN, /NONEXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='Order', UVALUE='order')
		placeholder = WIDGET_BUTTON(base, VALUE='32 Bit', UVALUE='srf32bit')
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		options = PTR_NEW({ORDER: 0, WRITE_32: 0})
	endif
	if (keyword_set(tiff)) then begin
		base = WIDGET_BASE(center_base, /COLUMN, /NONEXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='Append', UVALUE='tifAppend')
		placeholder = WIDGET_SLIDER(center_base, VALUE=100,TITLE='X Resolution',$
			UVALUE='tifXres')
		placeholder = WIDGET_SLIDER(center_base, VALUE=100,TITLE='Y Resolution',$
			UVALUE='tifYres')
		value = ['None','LZW','Packbits']
		placeholder=WIDGET_DROPLIST(center_base, VALUE=value, $
			TITLE='Compression',UVALUE='tifComp')
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		options = PTR_NEW({APPEND: 0, COMPRESSION: 0, XRESOL: 100, YRESOL: 100})
	endif

	if (keyword_set(jpeg2000)) then begin
		base = WIDGET_BASE(center_base, /COLUMN, /NONEXCLUSIVE)
		placeholder = WIDGET_BUTTON(base, VALUE='Reversible compression', $
		    UVALUE='reversible')
		placeholder = WIDGET_BUTTON(base, VALUE='Order top-to-bottom', $
		    UVALUE='order')
		placeholder = WIDGET_SLIDER(center_base, VALUE=5, $
		    MINIMUM=0, MAXIMUM=15, $
		    TITLE='Wavelet decomposition levels',UVALUE='n_levels')
		void = WIDGET_LABEL(center_base, VALUE=' ')
		placeholder = CW_FIELD(center_base, /INTEGER, VALUE='1', $
		    TITLE='Number of quality layers', UVALUE='n_layers', $
		    /RETURN_EVENTS)
		WIDGET_CONTROL, dwi_options_base, /REALIZE
		options = PTR_NEW({N_LAYERS: 0, N_LEVELS: 0, $
		    ORDER: 0, REVERSIBLE: 0})
	endif

	WIDGET_CONTROL, dwi_options_base, SET_UVALUE=options

	xmanager, 'dwi_options', dwi_options_base, EVENT_HANDLER='dwi_options_event'

	return,options
end

;; Event handler
pro dwi_event, ev

  COMPILE_OPT HIDDEN, STRICTARR

  catch,error_status
  if (error_status ne 0) then begin
		result = DIALOG_MESSAGE(!ERROR_STATE.MSG,/ERROR)
		return
  endif

  WIDGET_CONTROL, ev.top, GET_UVALUE=tlbStruct, /NO_COPY
  WIDGET_CONTROL, ev.id, GET_UVALUE=uval

  case uval of
    'filesel': begin
      WIDGET_CONTROL, ev.id, GET_VALUE=filenameRet

	  writeType = STRMID(ev.filter, 1)
	  stripCheck = STRPOS(ev.filter,',')
	  if (stripCheck gt 0) then writeType = STRMID(writeType, 0, (stripCheck-1))
	  (*tlbStruct).type = writeType

	  if (ev.done gt 0) then begin
	    if (ev.done eq 2) then (*tlbStruct).success=0L else begin
			if ((*tlbStruct).nowrite eq 0) then begin
      			WIDGET_CONTROL, /HOURGLASS
				;; If the called routine throws an error, we have to make sure
				;; the UVALUE pointer was secured.
				if (N_ELEMENTS(*(*tlbStruct).image) ne 0) then $
					tImage = (*(*tlbStruct).image)
				if (N_ELEMENTS(*(*tlbStruct).options) ne 0) then $
					tOptions = (*(*tlbStruct).options)
				if (N_ELEMENTS(*(*tlbStruct).red) ne 0) then $
					tRed = (*(*tlbStruct).red)
				if (N_ELEMENTS(*(*tlbStruct).green) ne 0) then $
					tGreen = (*(*tlbStruct).green)
				if (N_ELEMENTS(*(*tlbStruct).blue) ne 0) then $
					tBlue = (*(*tlbStruct).blue)
				tRGBvalid = (*tlbStruct).rgbValid
				WIDGET_CONTROL,ev.top,SET_UVALUE=tlbStruct, /NO_COPY

				if (tRGBvalid) then begin
					WRITE_IMAGE,filenameRet, writeType, tImage, tRed, tGreen, tBlue,$
						_EXTRA=tOptions
				endif else begin
					WRITE_IMAGE,filenameRet, writeType, tImage, _EXTRA=tOptions
				endelse
				WIDGET_CONTROL,ev.top,GET_UVALUE=tlbStruct, /NO_COPY
				(*tlbStruct).success=1L
                                (*tlbStruct).filename = filenameRet
			endif
		endelse
        WIDGET_CONTROL, ev.top, /destroy
        return
      endif else begin   ; done EQ 0
        IF (TAG_NAMES(ev,/STRUC) EQ 'FILESEL_EVENT') THEN BEGIN
        	SWITCH writeType OF
        	; all of the following have no options, make button insensitive
        	'GIF': ; fall thru
        	'PNG': BEGIN
        		WIDGET_CONTROL, (*tlbStruct).optionbut, SENSITIVE=0
        		BREAK
        		END
        	ELSE: $  ; anything else has an options page, make sensitive
        		WIDGET_CONTROL, (*tlbStruct).optionbut, /SENSITIVE
        	ENDSWITCH
        ENDIF
      endelse
    end
    'optionbut': begin
    	writeType = (*tlbStruct).type
    	WIDGET_CONTROL, ev.top, SET_UVALUE=tlbStruct, /NO_COPY
		case (writeType) of
			'BMP': options = dwi_options(ev.top, /BMP)
			'JPEG': options = dwi_options(ev.top, /JPEG)
			'PPM': options = dwi_options(ev.top, /PPM)
			'SRF': options = dwi_options(ev.top, /SRF)
			'TIFF': options = dwi_options(ev.top, /TIFF)
			'JP2': options = dwi_options(ev.top, /JP2)
			'': options = dwi_options(ev.top, /TIFF)
			else:
		endcase
		WIDGET_CONTROL, ev.top, GET_UVALUE=tlbStruct, /NO_COPY
		if (N_ELEMENTS(options) gt 0) then begin
			PTR_FREE, (*tlbStruct).options
			(*tlbStruct).options = options
		endif
    end
    else:
  endcase

  WIDGET_CONTROL, ev.top, SET_UVALUE=tlbStruct, /NO_COPY
end

;------------------------------------------------------------------
function DIALOG_WRITE_IMAGE, image, red, green, blue, $
                            DIALOG_PARENT = parent, $
                            FILENAME = filename, $
                            FIX_TYPE = fixt, $
                            NOWRITE = noWrite, $
                            OPTIONS = options, $
                            PATH = path, $
                            TITLE = title, $
                            TYPE = typeIn, $
                            WARN_EXIST = warn_exist
COMPILE_OPT strictarr

  ; Check input parameters
  if (N_ELEMENTS(image) eq 0) then begin
	result=DIALOG_MESSAGE('Missing image data.',/ERROR)
	return,0
  endif

  rgbTest = ((N_ELEMENTS(red) gt 0) and (N_ELEMENTS(green) gt 0) and $
  	(N_ELEMENTS(blue) gt 0))

  if (rgbTest) then begin
	sRed = red
	sGreen = green
	sBlue = blue
  endif

  if (N_ELEMENTS(noWrite) eq 0) then noWrite=0

  if (N_ELEMENTS(title) eq 0) then $
    title = 'Save Image File' $
  else $
    if (SIZE(title,/TYPE) ne 7) then $
      title = STRTRIM(STRING(title),2)


  has_parent = (N_ELEMENTS(parent) gt 0)
  if has_parent then begin
      if (not WIDGET_INFO(parent, /VALID_ID)) then $
        noth=DIALOG_MESSAGE('Invalid widget identifier.',/ERROR)
  endif else begin
  	parent = WIDGET_BASE(TITLE=title)   ; create a dummy parent base
  endelse

  base = WIDGET_BASE(TITLE=title, /COLUMN, GROUP_LEADER=parent, $
  	/FLOATING, /MODAL)

    noth = QUERY_IMAGE(SUPPORTED_WRITE=type)
    type = '.' + STRUPCASE(type)

    ; Fix up some of the type names.
    loc = where(type eq '.JPEG', nloc)
    if (nloc gt 0) then $
    	type[loc] = '.JPEG,.JPG'

    loc = where(type eq '.TIFF', nloc)
    if (nloc gt 0) then $
    	type[loc] = '.TIFF,.TIF'

    loc = where(type eq '.JPEG2000', nloc)
    if (nloc gt 0) then $
    	type[loc] = '.JP2,.JPX'

    ; See if default type was input.
    defaultType = (SIZE(typeIn, /TYPE) eq 7) ? STRUPCASE(typeIn) : 'TIFF'

    comma = Strpos(defaultType, ',')
    sType = (comma ne -1) ? Strmid(defaultType, 0, comma-1) : defaultType

    ; Make the default type be first.
    loc = (WHERE(STRPOS(type, defaultType) ge 0, nloc))[0]
    if (nloc gt 0) then begin
    	;; Make type the default by switching the first item
    	;; with the type location.
    	defaultType = type[loc]  ; in case the name is different
    	type[loc] = type[0]
    	type[0] = defaultType
    endif

  filesel = CW_FILESEL(base, FILENAME=filename, FILTER=type, $
                       FIX_FILTER=fixt, PATH=path, UVALUE='filesel',/SAVE, $
                       WARN_EXIST=KEYWORD_SET(warn_exist))

  optionBase = WIDGET_BASE(base)
  optionbut = WIDGET_BUTTON(optionBase, VALUE='Options...',UVALUE='optionbut',xoffset=185)
  if (stype eq 'GIF' || stype eq 'PNG') then WIDGET_CONTROL, optionbut, SENSITIVE=0


  WIDGET_CONTROL, base, /REALIZE

  tlbStruct = PTR_NEW({dwi_Struct, $
                       filename: '', $
                       filesel: filesel, $
                       optionbut: optionbut, $
                       nowrite: nowrite, $
                       image: PTR_NEW(image), $
                       red: PTR_NEW(sRed), $
                       green: PTR_NEW(sGreen), $
                       blue: PTR_NEW(sBlue), $
                       options: PTR_NEW(placeholder), $
                       success: 1, $
                       rgbValid: rgbTest, $
                       type: sType $
                      })

  WIDGET_CONTROL, base, SET_UVALUE = tlbStruct

  XMANAGER, 'DIALOG_WRITE_IMAGE', base, EVENT_HANDLER='dwi_event', $
  	GROUP_LEADER=parent

  IF (NOT has_parent) THEN WIDGET_CONTROL, parent, /DESTROY

  options = {FILENAME:(*tlbStruct).filename, TYPE:(*tlbStruct).type}
  ;; Grab the output info
  if (N_ELEMENTS(*((*tlbStruct).options)) gt 0) then $
    options = create_struct(options, *((*tlbStruct).options))

  retVal = (*tlbStruct).success

  if (PTR_VALID((*tlbStruct).image)) then $
	  PTR_FREE, (*tlbStruct).image
  if (PTR_VALID((*tlbStruct).red)) then $
	  PTR_FREE, (*tlbStruct).red
  if (PTR_VALID((*tlbStruct).green)) then $
	  PTR_FREE, (*tlbStruct).green
  if (PTR_VALID((*tlbStruct).blue)) then $
	  PTR_FREE, (*tlbStruct).blue
  if (PTR_VALID((*tlbStruct).options)) then $
	  PTR_FREE, (*tlbStruct).options
  if (PTR_VALID(tlbStruct)) then $
	  PTR_FREE, tlbStruct

  return,retVal
end
