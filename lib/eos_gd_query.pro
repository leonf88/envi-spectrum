; $Id: //depot/idl/releases/IDL_80/idldir/lib/eos_gd_query.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   EOS_GD_QUERY
;
; PURPOSE:
;   Read the grid header of an HDF file and report on the EOS grid
;   extensions.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   Result = EOS_GD_QUERY(Filename, GridName [, Info])
;
; INPUTS:
;	Filename:  The filename of the HDF-EOS file.
;
;   GridName:   The EOS Grid Name.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the file contains grid extentions,
;	0 otherwise.
;
;   Info: (optional)  An anonymous structure containing information about
;		the file.  This structure is valid only when the return value of
;       the function is 1.  The Info structure has the following fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;           ATTRIBUTES	String array	Array of attribute names
;			DIMENSION_NAMES	String array	Names of dimensions
;			DIMENSION_SIZES	Long array	Sizes of dimensions
;			FIELD_NAMES	String array	Names of fields
;			FIELD_RANKS	Long array	Ranks (dimensions) of fields
;			FIELD_TYPES	Long array	IDL types of fields
;			GCTP_PROJECTION	Long	GCTP projection code
;			GCTP_PROJECTION_PARM	Double array	GCTP projection parameters
;			GCTP_SPHEROID	Long	GCTP spheroid code
;			GCTP_ZONE	Long	GCTP zone code (for UTM projection)
;			GRID_INDEX	Long	Grid index for which this structure is valid
;			GRID_NAME	String	Name of grid
;			IMAGE_LOWRIGHT	Double[2]	Location of lower right corner (meters)
;			IMAGE_UPLEFT	Double[2]	Location of upper left corner (meters)
;			IMAGE_X_DIM	Long	Number of columns in grid image
;			IMAGE_Y_DIM	Long	Number of rows in grid image
;			NUM_ATTRIBUTES	Long	Number of attributes
;			NUM_DIMS	Long	Number of dimensions
;			NUM_IDX_MAPS	Long	Number of indexed dimension mapping entries
;			NUM_MAPS	Long	Number of dimension mapping entries
;			NUM_FIELDS	Long	Number of fields
;			NUM_GEO_FIELDS	Long	Number of geolocation field entries
;			ORIGIN_CODE	Long	Origin code
;			PIX_REG_CODE	Long	Pixel registration code
;
; RESTRICTIONS:
;   None.
;
; EXAMPLE:
;   To retrieve information from the HDF-EOS grid name myGrid enter:
;
;       result = EOS_GD_QUERY("foo.hdf", 'myGrid', info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'HDF file not found or file does not contain EOS GD extensions.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written December 1998, Scott J. Lasica
;
;-
;

function EOS_GD_QUERY, Filename, GridName, info

	;; Swallow all errors since we return status
	CATCH, errorStatus
	if errorStatus ne 0 then begin
	    RETURN, 0L
	endif

	;; First verify that the file contains points
	status = EOS_QUERY(Filename, info_general)
	if ((status eq 0) or (info_general.num_grids eq 0)) then return, 0L

	;; Now open it up and try to find the given point ID
	file_id=EOS_GD_OPEN(filename,/read)

	if (file_id ne -1) then begin
		grid_id=EOS_GD_ATTACH(file_id,GridName)
		status = EOS_GD_GRIDINFO(grid_id, image_x_dim, image_y_dim, $
			image_upleft, image_lowright)
		num_attributes = EOS_GD_INQATTRS(grid_id, attributes)
		num_dims = EOS_GD_INQDIMS(grid_id, dimension_names, dimension_sizes)
		num_fields = EOS_GD_INQFIELDS(grid_id, field_names, field_ranks, $
			field_types)
		num_maps = EOS_GD_NENTRIES(grid_id, 1)
		num_idx_maps = EOS_GD_NENTRIES(grid_id, 2)
		num_geo_fields = EOS_GD_NENTRIES(grid_id, 3)
		status = EOS_GD_ORIGININFO(grid_id, origin_code)
		status = EOS_GD_PIXREGINFO(grid_id, pix_reg_code)
		status = EOS_GD_PROJINFO(grid_id, gctp_projection, gctp_zone, $
			gctp_spheroid, gctp_projection_parm)
		status=EOS_GD_DETACH(grid_id)
 		status=EOS_GD_close(file_id)
	endif else return, 0L

	info = {ATTRIBUTES: attributes, $
			DIMENSION_NAMES: dimension_names, $
			DIMENSION_SIZES: dimension_sizes, $
			FIELD_NAMES: field_names, $
			FIELD_RANKS: field_ranks, $
			FIELD_TYPES: field_types, $
			GCTP_PROJECTION: gctp_projection, $
			GCTP_PROJECTION_PARM: gctp_projection_parm, $
			GCTP_SPHEROID: gctp_spheroid, $
			GCTP_ZONE: gctp_zone, $
			IMAGE_LOWRIGHT: image_lowright, $
			IMAGE_UPLEFT: image_upleft, $
			IMAGE_X_DIM: image_x_dim, $
			IMAGE_Y_DIM: image_y_dim, $
			NUM_ATTRIBUTES: num_attributes, $
			NUM_DIMS: num_dims, $
			NUM_IDX_MAPS: num_idx_maps, $
			NUM_MAPS: num_maps, $
			NUM_FIELDS: num_fields, $
			NUM_GEO_FIELDS: num_geo_fields, $
			ORIGIN_CODE: origin_code, $
			PIX_REG_CODE: pix_reg_code $
			}

	return, 1L  ;success

end
