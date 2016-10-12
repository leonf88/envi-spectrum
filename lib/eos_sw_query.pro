; $Id: //depot/idl/releases/IDL_80/idldir/lib/eos_sw_query.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   EOS_SW_QUERY
;
; PURPOSE:
;   Read the header of an HDF file and report on the EOS swath
;   extensions.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   Result = EOS_SW_QUERY(Filename, SwathName [, Info])
;
; INPUTS:
;	Filename:  The filename of the HDF-EOS file.
;
;   SwathName:   The EOS Swath Name.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the file contains swath extentions,
;	0 otherwise.
;
;   Info: (optional)  An anonymous structure containing information about
;		the file.  This structure is valid only when the return value of
;       the function is 1.  The Info structure has the following fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;		ATTRIBUTES	String array	Array of attribute names
;		DIMENSION_NAMES	String array	Names of dimensions
;		DIMENSION_SIZES	Long array	Sizes of dimensions
;		FIELD_NAMES	String array	Names of fields
;		FIELD_RANKS	Long array	Ranks (dimensions) of fields
;		FIELD_TYPES	Long array	IDL types of fields
;		GEO_FIELD_NAMES	String array	Names of geolocation fields
;		GEO_FIELD_RANKS	Long array	Ranks (dimensions) of geolocation fields
;		GEO_FIELD_TYPES	Long array	IDL types of geolocation fields
;		IDX_MAP_NAMES	String array	Names of index maps
;		IDX_MAP_SIZES	Long array	Sizes of index map arrays
;		NUM_ATTRIBUTES	Long	Number of attributes
;		NUM_DIMS	Long	Number of dimensions
;		NUM_FIELDS	Long	Number of fields
;		NUM_GEO_FIELDS	Long	Number of geolocation fields
;		NUM_IDX_MAPS	Long	Number of indexed dimension mapping entries
;		NUM_MAPS	Long	Number of mapping entries
;		MAP_INCREMENTS	Long array	Increment of each geolocation relation
;		MAP_NAMES	String array	Names of maps
;		MAP_OFFSETS	Long array	Offset of each geolocation relation
;		MAP_SIZES	Long array	Sizes of index map arrays
;
; RESTRICTIONS:
;   None.
;
; EXAMPLE:
;   To retrieve information from the HDF-EOS swath name mySwath enter:
;
;       result = EOS_SW_QUERY("foo.hdf", 'mySwath', info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'HDF file not found or file does not contain EOS SW extensions.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written February 1999, Scott J. Lasica
;
;-
;

function EOS_SW_QUERY, Filename, SwathName, info

	;; Swallow all errors since we return status
	CATCH, errorStatus
	if errorStatus ne 0 then begin
	    RETURN, 0L
	endif

	;; First verify that the file contains points
	status = EOS_QUERY(Filename, info_general)
	if ((status eq 0) or (info_general.num_swaths eq 0)) then return, 0L

	;; Now open it up and try to find the given point ID
	file_id=EOS_SW_OPEN(filename,/read)

	if (file_id ne -1) then begin
		swath_id=EOS_SW_ATTACH(file_id,SwathName)
		num_attributes = EOS_SW_INQATTRS(swath_id, attributes)
		num_fields = EOS_SW_INQDATAFIELDS(swath_id, field_names, field_ranks, $
			field_types)
		num_dims = EOS_SW_INQDIMS(swath_id, dimension_names, dimension_sizes)
		num_geo_fields = EOS_SW_INQGEOFIELDS(swath_id, geofield_names, $
			geofield_ranks, geofield_types)
		num_idx_maps = EOS_SW_INQIDXMAPS(swath_id, idxmap_names, idxmap_sizes)
		num_maps = EOS_SW_INQMAPS(swath_id, map_names, map_offsets, map_increments)
		status=EOS_SW_DETACH(swath_id)
 		status=EOS_SW_close(file_id)
	endif else return, 0L

	info = {ATTRIBUTES: attributes, $
			DIMENSION_NAMES: dimension_names, $
			DIMENSION_SIZES: dimension_sizes, $
			FIELD_NAMES: field_names, $
			FIELD_RANKS: field_ranks, $
			FIELD_TYPES: field_types, $
			GEO_FIELD_NAMES: geofield_names, $
			GEO_FIELD_RANKS: geofield_ranks, $
			GEO_FIELD_TYPES: geofield_types, $
			IDX_MAP_NAMES: idxmap_names, $
			IDX_MAP_SIZES: idxmap_sizes, $
			NUM_ATTRIBUTES: num_attributes, $
			NUM_DIMS: num_dims, $
			NUM_FIELDS: num_fields, $
			NUM_GEO_FIELDS:	num_geo_fields, $
			NUM_IDX_MAPS: num_idx_maps, $
			NUM_MAPS: num_maps, $
			MAP_INCREMENTS: map_increments, $
			MAP_NAMES: map_names, $
			MAP_OFFSETS: map_offsets $
			}

	return, 1L  ;success

end
