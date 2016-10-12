; $Id: //depot/idl/releases/IDL_80/idldir/lib/eos_query.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   HDF_EOS_QUERY
;
; PURPOSE:
;   Read the header of an HDF file and report on the number of EOS
;   extensions as well as their names.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   Result = EOS_QUERY(File [, Info])
;
; INPUTS:
;   File:   Scalar string giving the name of the HDF file to query.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the query was successful (and the
;   file type was correct) or 0 on failure.
;
;   Info: (optional)  An anonymous structure containing information about
;		the file.  This structure is valid only when the return value of
;       the function is 1.  The Info structure has the following fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;           GRID_NAMES	String array	Names of grids
;			NUM_GRIDS	Long			Number of grids in file
;			NUM_POINTS	Long			Number of points in file
;			NUM_SWATHS	Long			Number of swaths in file
;			POINT_NAMES	String array	Names of points
;			SWATH_NAMES	String array	Names of swaths
;
; RESTRICTIONS:
;   None.
;
; EXAMPLE:
;   To retrieve information from the HDF file named "foo.hdf"
;   in the current directory, enter:
;
;       result = EOS_QUERY("foo.hdf", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'HDF file not found or file does not contain EOS extensions.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written December 1998, Scott J. Lasica
;
;-
;

function is_hdf_eos,filename
 ;
 ;; Swallow all errors since we return status
 CATCH, errorStatus
 if errorStatus ne 0 then begin
     RETURN, 0L
 endif

 valid_hdf=HDF_ISHDF(filename)
 valid_eos=(valid_sds=0)
 ;
 ; It could be a netcdf file, check the sd_id interface
 ;
 files=FILE_SEARCH(filename,count=count)
 if count eq 1 then begin
  inquiet=!quiet & !quiet=1
  sd_id=HDF_SD_START(filename)
  if sd_id ne -1 then begin
        valid_sds=1
        if HDF_SD_ATTRFIND(sd_id,'StructMetadata.0') ne -1 then valid_eos=1
        HDF_SD_END,sd_id
  endif
  !quiet=inquiet
 endif
 return,valid_eos
end

function EOS_QUERY, filename, info

;; Swallow all errors since we return status
CATCH, errorStatus
if errorStatus ne 0 then begin
    RETURN, 0L
endif

;; First see if it's an HDF file with EOS extensions
if (is_hdf_eos(filename) lt 1) then return, 0L

;; If we've made it here, then we're in business
num_points=EOS_PT_inqpoint(filename,point_names)
num_grids=EOS_GD_inqgrid(filename,grid_names)
num_swaths=EOS_SW_inqswath(filename,swath_names)

info = {	GRID_NAMES: grid_names, $
			NUM_GRIDS: num_grids, $
			NUM_POINTS: num_points, $
			NUM_SWATHS: num_swaths, $
			POINT_NAMES: point_names, $
			SWATH_NAMES: swath_names $
		  }

return, 1L  ;success

end
