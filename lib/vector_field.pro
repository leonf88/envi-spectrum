; $Id: //depot/idl/releases/IDL_80/idldir/lib/vector_field.pro#1 $
; Copyright (c) 1991-2010. ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	VECTOR_FIELD
;
; PURPOSE:
;
;	This procedure is used to place colored, orientated vectors of
;	specified length at each vertex in an input vertex array.  The output
;	can be sent directly to an IDLgrPolyline object.  The generated
;	display is generally referred to as a hedgehog display and is used to
;	convey various aspects of a vector field.
;
;
; CATEGORY:
;	3D Toolkit
;
; CALLING SEQUENCE:
;
;	VECTOR_FIELD, field, outverts, outcolors [,ANISOTROPY = a] [,SCALE=sc]
;	    [,VERTICES=verts]
;
;
; INPUTS:
;
; Field:	Input vector field array. This can be a [3,x,y,z] array or a
;		[2,x,y] array.  The leading dimension is the vector quantity 
;		to be displayed.
;
; OUTPUTS:
;
;
; Outverts:	Output vertex array ([3,N] or [2,N] array of floats).  Useful 
;		if the routine is to be used with Direct Graphics or the user 
;		wants to manipulate the data directly.
; Outcolors:	Output color array.  Useful if the routine is to be used with 
;		Direct Graphics or the user wants to manipulate the data 
;		directly.
;
;
; OPTIONAL KEYWORD PARAMETERS:
;
;
; VERTICES:	Set this input keyword to a [3,n] or [3n] ([2,n]
;               or[2n] if 2D) array of points. If this keyword is set, the
;               vector field is interpolated at these points. The resulting
;               interpolated vectors are displayed as line segments at these
;               locations.  If the keyword is not set, each spatial sample
;               point in the input Field grid is used as the base point for a
;               line segment.
; ANISOTROPY:	Set this input keyword to a two or three element array 
;		describing the distance between grid points in each dimension.
;  		The default value is [1.0, 1.0, 1.0]
; SCALE:	Set this keyword to a scalar scaling factor.  All vector 
;		lengths are multiplied by this value.  The default is 1.0.
;
;
; PROCEDURE/EXAMPLES: 
;
;
; VECTOR_FIELD, field, outverts, outconn, ANISOTROPY=anisotropy,
;     SCALE=2.0, VERTICES=vertices
;
; oHedgeHog = OBJ_NEW('IDLgrPolyline',outverts,POLYLINES=outconn)
;
;
; MODIFICATION HISTORY: 
; 	KB, 	written Feb 1999.  
;-

PRO VECTOR_FIELD ,field,outverts,outconn, ANISOTROPY=anisotropy,SCALE=scale $
    ,VERTICES=vertices

    dims = SIZE(field,/DIMENSIONS)

    IF(N_ELEMENTS(scale) EQ 0) then scale = 1.0
    IF(N_ELEMENTS(anisotropy) EQ 0) then anisotropy=[1,1,1]
    if(N_ELEMENTS(dims) EQ 4) then begin
	if(dims[0] NE 3) then MESSAGE,'3D grid must contain 3-vectors.'
	Nx=dims[1]
	Ny=dims[2]
	Nz=dims[3]
	if(N_ELEMENTS(vertices) NE 0) then begin
            ndims = SIZE(vertices, /N_DIMENSIONS)
            if(ndims ne 2) then begin
                nv = N_ELEMENTS(vertices)
                if((nv mod 3) eq 0) then vertices = REFORM(vertices, 3, nv/3) $
                else MESSAGE,'VERTICES must be [3,n] or [3n].'
            end
	    outverts=FLTARR(3,2,N_ELEMENTS(vertices)/3)       
	    outverts[0,0,*] = vertices[0,*]*anisotropy[0]
	    outverts[1,0,*] = vertices[1,*]*anisotropy[1]
	    outverts[2,0,*] = vertices[2,*]*anisotropy[2]
            vertX = REFORM(vertices[0,*],N_ELEMENTS(vertices)/3)
            vertY = REFORM(vertices[1,*],N_ELEMENTS(vertices)/3)
            vertZ = REFORM(vertices[2,*],N_ELEMENTS(vertices)/3)
	    vecint = INTERPOLATE(field,vertX, vertY, vertZ)
	    outverts[0,1,*] = outverts[0,0,*]+vecint[0,*]*scale
	    outverts[1,1,*] = outverts[1,0,*]+vecint[1,*]*scale
	    outverts[2,1,*] = outverts[2,0,*]+vecint[2,*]*scale
	    outverts = REFORM(outverts,3,2*N_ELEMENTS(vertices)/3)	
	end else begin
	    outverts=FLTARR(3,2,Nx,Ny,Nz)
	    for i=0UL,Nx-1 do $
		for j=0UL,Ny-1 do $
		    outverts[2,0,i,j,*]=FINDGEN(Nz)

	    for k=0UL,Nz-1 do $
		for j=00UL,Ny-1 do $
		    outverts[0,0,*,j,k]=FINDGEN(Nx)

	    for i=0UL,Nx-1 do $
		for k=00UL,Nz-1 do $
		    outverts[1,0,i,*,k]=FINDGEN(Ny)

	    outverts[0,0,*,*,*] = outverts[0,0,*,*,*]*anisotropy[0]
	    outverts[1,0,*,*,*] = outverts[1,0,*,*,*]*anisotropy[1]
	    outverts[2,0,*,*,*] = outverts[2,0,*,*,*]*anisotropy[2]

	    outverts[0,1,*,*,*] = outverts[0,0,*,*,*]+field[0,*,*,*]*scale
	    outverts[1,1,*,*,*] = outverts[1,0,*,*,*]+field[1,*,*,*]*scale
	    outverts[2,1,*,*,*] = outverts[2,0,*,*,*]+field[2,*,*,*]*scale

	    outverts = REFORM(outverts,3,2*Nx*Ny*Nz)
	end

    end else if(N_ELEMENTS(dims) EQ 3) then begin
	if(dims[0] NE 2) then MESSAGE,'2D grid must contain 2-vectors.'
	Nx=dims[1]
	Ny=dims[2]
	if(N_ELEMENTS(vertices) NE 0) then begin
            ndims = SIZE(vertices, /N_DIMENSIONS)
            if(ndims ne 2) then begin
                nv = N_ELEMENTS(vertices)
                if((nv mod 2) eq 0) then vertices = REFORM(vertices, 2, nv/2) $
                else MESSAGE,'VERTICES must be [2,n] or [2n].'
            end
	    outverts=FLTARR(2,2,N_ELEMENTS(vertices)/2)       
	    outverts[0,0,*] = vertices[0,*]*anisotropy[0]
	    outverts[1,0,*] = vertices[1,*]*anisotropy[1]
            vertX = REFORM(vertices[0,*],N_ELEMENTS(vertices)/2)
            vertY = REFORM(vertices[1,*],N_ELEMENTS(vertices)/2)
	    vecint = INTERPOLATE(field,vertX, vertY)

	    outverts[0,1,*] = outverts[0,0,*]+vecint[0,*]*scale
	    outverts[1,1,*] = outverts[1,0,*]+vecint[1,*]*scale

	    outverts = REFORM(outverts,2,2*N_ELEMENTS(vertices)/2)	
	end else begin
	    outverts=FLTARR(2,2,Nx,Ny)
	    for i=0UL,Nx-1 do $
		    outverts[1,0,i,*]=FINDGEN(Ny)

	    for j=0UL,Ny-1 do $
		    outverts[0,0,*,j]=FINDGEN(Nx)

	    outverts[0,0,*,*] = outverts[0,0,*,*]*anisotropy[0]
	    outverts[1,0,*,*] = outverts[1,0,*,*]*anisotropy[1]

	    outverts[0,1,*,*] = outverts[0,0,*,*]+field[0,*,*]*scale
	    outverts[1,1,*,*] = outverts[1,0,*,*]+field[1,*,*]*scale

	    outverts = REFORM(outverts,2,2*Nx*Ny)
	end    
    
    end else MESSAGE,'Only [3,x,y,z] and [2,x,y] data allowed.'

    ;Generate connectivity of hedgehog lines
    ndims = N_ELEMENTS(dims)-1
    nv = N_ELEMENTS(outverts)/ndims
    outconn = LONARR(3,nv/2)
    outconn[0,*]=2L
    currv=0UL
    for v=0UL,nv/2-1 do begin
	outconn[1,v]=currv
	currv = currv+1
	outconn[2,v]=currv
	currv = currv+1
    end
    outconn=REFORM(outconn,3*nv/2)

END








