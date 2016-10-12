; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_proj_init_commonblock.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Undocumented "include" routine to construct the common block needed
; for MAP_PROJ_INIT.
;
; Use this code at your own risk. RSI reserves the right to modify or
; remove this routine.
;
; CT, RSI, April 2004.
;

    ; This is initialized once with all read-only projections parameters.
    common IDLmapProjectionCommon, $
        c_ProjNames, c_ProjCompressNames, $
        c_ProjNumber, c_ProjNumToGCTP, $
        c_ProjParameters, c_keywordNames, $
        c_ParamIsAngle, c_ProjParam_p0, $
        c_EllipsoidNames, c_EllipsoidMajor, c_EllipsoidMinor, $
        c_StatePlane_NAD27names, c_StatePlane_NAD27numbers, $
        c_StatePlane_NAD27proj, c_StatePlane_NAD27params, $
        c_StatePlane_NAD83names, c_StatePlane_NAD83numbers, $
        c_StatePlane_NAD83proj, c_StatePlane_NAD83params, $
        c_GeoDatumNames, c_GeoDatumEllipsoid, c_GeoDatumParams

    ; Call our initialization routine.
    if (~N_ELEMENTS(c_ProjNames) && ~KEYWORD_SET(inMapProjInitCommon)) then $
        MAP_PROJ_INIT_COMMON


