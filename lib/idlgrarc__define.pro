; $Id: //depot/idl/releases/IDL_80/idldir/lib/idlgrarc__define.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	IDLgrArc
;
; PURPOSE:
;	This object serves as a graphical representation of a Circle,
;	Arc, or Ellipse, which subclasses from the IDLgr?? class.
;
; CATEGORY:
;	Object graphics.
;
; CALLING SEQUENCE:
;	To initially create:
;	       	oArc = OBJ_NEW('IDLgrArc') 
;
;	To retrieve a property value:
;		oArc->GetProperty
;
;	To set a property value:
;		oArc->SetProperty
;
;	To print to the standard output stream the current properties of 
;	the Arc:
;		oArc->Print
;
;	To destroy:
;		OBJ_DESTROY, oArc
;
; KEYWORD PARAMETERS:
;   ARC::INIT:
;	<Note that keywords accepted by IDLgrModel::Init and/or
;	 IDLgrPolyline::Init are also accepted here.>
;       ASPECT: A floating point number representing the ratio of the
;               minor axis length to the major axis length of the Arc.  
;               The default is 1.0.
;	DENSITY: A floating point number representing the density at which
;               the vertices should be generated along the path of the
;               Arc.  The default is 1.0.
;       END_ANGLE: A floating point value representing the angle (measured 
;               in degrees) at which the Arc should end.  The default is 0.0.
;       NORMAL: A three-element floating point vector representing the 
;               normal vector for the plane on which the arc should lie.  
;               The default is [0,0,1].
;	POS:	A three-element vector, [x,y,z], specifying the position
;               of the center of the Arc, measured in data units . 
;		Defaults to [0,0,0].
;	RADIUS: A floating point number representing the radius of the
;               Arc (measured in data units).  The default is 1.0.
;       START_ANGLE: A floating point value representing the angle (measured 
;               in degrees) at which the Arc should start.  The default is 0.0.
;       TILT:   A floating point value representing the angle (measured in 
;               degrees) by which the major axis of the arc is to be rotated.  
;               The default is 0.
;
;   ARC::GETPROPERTY:
;       ALL:    Set this keyword to a named variable that upon return will
;               contain an anonymous structure containing the values of all
;               of the properties associated with the Arc.
;       ASPECT: Set this keyword to a named variable that upon return will
;               contain a floating point number representing the ratio of the
;               minor axis length to the major axis length of the Arc.  
;	DENSITY: Set this keyword to a named variable that upon return will
;		contain a floating point number representing the density at 
;		which the vertices are generated along the path of the
;               Arc.
;       END_ANGLE: Set this keyword to a named variable that upon return will
;               contain a floating point number representing the angle 
;               (measured in degrees) at which the Arc ends.
;       NORMAL: Set this keyword to a named variable that upon return will
;               contain a three-element floating point vector representing 
;               the normal vector for the plane on which the arc lies.
;	POS:	Set this keyword to a named variable that upon return will
;		contain a three-element vector, [x,y,z], specifying the 
;		position of the center of the Arc, measured in data units . 
;	RADIUS: Set this keyword to a named variable that upon return will
;		contain a floating point number representing the radius of the
;               Arc (measured in data units).
;       START_ANGLE: Set this keyword to a named variable that upon return
;               will contain a floating point number representing the angle 
;               (measured in degrees) at which the Arc begins.
;       TILT:   Set this keyword to a name variable that upon return will 
;               contain a floating point number representing the angle 
;               (measured in degrees) by which the major axis of the arc is
;               rotated. 
;
;   ARC::SETPROPERTY:
;	<Note that keywords accepted by IDLgrModel::SetProperty and/or
;	 IDLgrPolyline::SetProperty are also accepted here.>
;       ASPECT: A floating point number representing the ratio of the
;               minor axis length to the major axis length of the Arc.  
;               The default is 1.0.
;	DENSITY: A floating point number representing the density at which
;               the vertices should be generated along the path of the
;               Arc.  The default is 1.0.
;       END_ANGLE: A floating point value representing the angle (measured 
;               in degrees) at which the Arc should end.  The default is 0.0.
;       NORMAL: A three-element floating point vector representing the 
;               normal vector for the plane on which the arc should lie.  
;               The default is [0,0,1].
;	POS:	A three-element vector, [x,y,z], specifying the position
;               of the center of the Arc. Defaults to [0,0,0].
;	RADIUS: A floating point number representing the radius of the
;               Arc (measured in data units).  The default is 1.0.
;       START_ANGLE: A floating point value representing the angle (measured 
;               in degrees) at which the Arc should start.  The default is 0.0.
;       TILT:   A floating point value representing the angle (measured in 
;               degrees) by which the major axis of the arc is to be rotated.  
;               The default is 0.
;
; EXAMPLE:
;	Create a circle centered at the origin with a radius of 0.5:
;		oCircle = OBJ_NEW('IDLgrArc', POS=[0,0,0], RADIUS=0.5) 
;
; MODIFICATION HISTORY:
; 	Written by:	DMS, July 2000.
;-

;----------------------------------------------------------------------------
; IDLGRARC::INIT
;
; Purpose:
;  Initializes a IDLgrArc object.
;
;  This function returns a 1 if initialization is successful, or 0 otherwise.
;
FUNCTION IDLgrArc::Init, POS=pos, RADIUS=radius, NORMAL=normal, $
               ASPECT=aspect, TILT=tilt, START_ANGLE=stang, END_ANGLE=endang, $
               DENSITY=density, _EXTRA=e

; Note: Aspect = Ratio of Minor Axis length to Major axis length.
; Aspect = sqrt(1 - eccentricity^2)
;
IF (self->IDLgrPolyline::Init(_EXTRA=e) NE 1) THEN RETURN, 0

self.pos = n_elements(pos) gt 0 ? pos : [0.0,0.0,0.0]
if n_elements(normal) eq 3 then begin
    l = sqrt(total(normal^2))   ;Normalize length
    self.normal = l ne 0 ? normal/l : [0,0,1.0]
endif else self.normal = [0.0,0.0,1.0]
self.radius = n_elements(radius) eq 1 ? radius : 1.0
self.aspect = n_elements(aspect) eq 1 ? aspect : 1.0
self.density = n_elements(density) eq 1 ? density : 1.0
self.tilt = n_elements(tilt) eq 1 ? tilt : 0.
self.stang = n_elements(stang) eq 1 ? stang : 0.
self.endang = n_elements(endang) eq 1 ? endang : 0.

; Build the Polyline vertices and connectivity based on property settings.
self->BuildPoly

RETURN, 1
END

;----------------------------------------------------------------------------
; IDLGRARC::CLEANUP
;
; Purpose:
;  Cleans up all memory associated with the IDLGRARC.
;
PRO IDLGRARC::Cleanup

; Cleanup the Polyline object used to represent the IDLGRARC.
self->IDLgrPolyline::Cleanup     ; Cleanup the superclass.

END

;----------------------------------------------------------------------------
; IDLGRARC::SETPROPERTY
;
; Purpose:
;  Sets the value of properties associated with the IDLGRARC object.
;
PRO IDLGRARC::SetProperty, POS=pos, RADIUS=radius, NORMAL=normal, $
               ASPECT=aspect, TILT=tilt, START_ANGLE=stang, END_ANGLE=endang, $
               DENSITY=density, _EXTRA=e

    ; Pass along extraneous keywords to the superclass and/or to the
    ; Polyline used to represent the IDLGRARC.
self->IDLgrPolyline::SetProperty, _EXTRA=e

if n_elements(e) gt 1 then self->IDLgrPolyline::SetProperty, _EXTRA=e

IF N_ELEMENTS(pos) eq 2 then self.pos = [pos, 0.0]
if n_elements(pos) eq 3 THEN self.pos = pos
IF (N_ELEMENTS(radius) EQ 1) THEN self.radius = radius
IF (N_ELEMENTS(aspect) EQ 1) THEN self.aspect = aspect
IF (N_ELEMENTS(tilt) EQ 1) THEN self.tilt = tilt
IF (N_ELEMENTS(density) EQ 1) THEN self.density = density
IF (N_ELEMENTS(stang) EQ 1) THEN self.stang = stang
IF (N_ELEMENTS(endang) EQ 1) THEN self.endang = endang
if n_elements(normal) eq 3 then begin
    l = sqrt(total(normal^2))   ;Normalize length
    self.normal = l ne 0 ? normal/l : [0, 0, 1.0]
endif

    ; Rebuild the Polyline according to keyword settings.
self->BuildPoly
END

;----------------------------------------------------------------------------
; IDLGRARC::GETPROPERTY
;
; Purpose:
;  Retrieves the value of properties associated with the IDLGRARC object.
;
PRO IDLGRARC::GetProperty, POS=pos, RADIUS=radius, NORMAL=normal, $
          ASPECT=aspect, TILT=tilt, START_ANGLE=stang, END_ANGLE=endang, $
          ALL=all, DENSITY=density, _REF_EXTRA=e


if arg_present(all) then begin  ;Special case
    self->IDLgrPolyline::GetProperty, ALL=all
; Combine our properties with the inherited class'.
    all = CREATE_STRUCT(all, "POS", self.pos, "RADIUS", self.radius, $
                        "NORMAL", self.normal, "ASPECT", self.aspect, $
                        "TILT", self.tilt, "STARG_ANGLE", self.stang, $
                        "END_ANGLE", self.endang, "DENSITY", self.density )

endif else begin
    self->IDLgrPolyline::GetProperty, _EXTRA=e
    pos = self.pos
    radius = self.radius 
    normal = self.normal
    aspect = self.aspect
    tilt = self.tilt
    stang = self.stang
    endang = self.endang
    density = self.density 
endelse

END

PRO IDLGRARC::Print
PRINT, self.pos
PRINT, self.radius
PRINT, self.density
END

;----------------------------------------------------------------------------
; IDLGRARC::BUILDPOLY
;
; Purpose:
;  Sets the vertex and connectivity arrays for the Polyline used to
;  represent the IDLGRARC.
;
PRO IDLgrArc::BuildPoly           ; Build the IDLGRARC.

if self.stang eq self.endang then begin
    stang = -self.tilt
    delta = 2 * !pi
endif else begin
    stang = (self.stang - self.tilt) * !dtor
    delta = self.endang - self.stang
    while delta le 0 do delta = delta + 360.
    delta = delta * !dtor
endelse

                                ;Approx 15 degree intervals
npts = CEIL(delta / (2 * !pi) * (24. * self.density)) > 4
a = stang + findgen(npts) * (delta / (npts-1))
; print, 'build ' ,npts, stang, self.endang, delta

x = cos(a) * self.radius
y = sin(a) * (self.radius * self.aspect)

if self.tilt ne 0 then begin    ;Rotate by tilt angle
    sintilt = sin(self.tilt * !dtor)
    costilt = cos(self.tilt * !dtor)
    x1 = x * costilt - y * sintilt
    y = x * sintilt + y * costilt
    x = temporary(x1)
endif

if (self.normal[0] ne 0) or (self.normal[1] ne 0) then begin
    v = self.normal
    h = sqrt(v[0]^2 + v[1]^2)
    c = [ v[0] / h, v[2], 1/sqrt(2.)]
    s = [ -v[1] / h, -h, 1/sqrt(2.)]
;
; Matrix to rotate by angle0 about the z-axis, then by angle1 about
; the y axis, and then by angle2 about the z axis.  c[i] =
; cos(anglei), s[i] = sin(anglei) 
;
    matrix = [[c[0]*c[1]*c[2] - s[0]*s[2], -s[0]*c[1]*c[2] - c[0]*s[2], $
               s[1]*c[2]], $
              [s[0]*c[2]+c[0]*c[1]*s[2], -s[0]*c[1]*s[2] + c[0]*c[2], $
               s[1]*s[2]], $
              [-c[0]*s[1], s[0]*s[1], c[1]]]
; Matrix simplified to only do the first two rotations:
;    matrix = [[c[0]*c[1], -s[0]*c[1], s[1]], $
;              [s[0], c[0], 0], $
;              [-c[0]*s[1], s[0]*s[1], c[1]]]

;    print, matrix
    data = matrix # transpose([[x], [y], [replicate(0.0,npts)]])
    self->IDLGRPOLYLINE::SetProperty,   $
      DATA= data + (self.pos # replicate(1.0, npts)) ;Add center offset
endif else begin
    self->IDLGRPOLYLINE::SetProperty,   $
      DATA=transpose([[x+self.pos[0]], [y+self.pos[1]], $
                      [replicate(self.pos[2],npts)]])
endelse

END

;----------------------------------------------------------------------------
; IDLGRARC__DEFINE
;
; Purpose:
;  Defines the object structure for a circle/ellipse/arc object.
;
PRO IDLgrArc__define
struct = { IDLgrArc, $
           INHERITS IDLgrPolyline, $
           pos: [0.0,0.0,0.0], $
           normal: [0.0,0.0,0.0], $
           Radius: 1.0, $
           Aspect: 1.0, $        ;Major radius/minor radius
           Density: 1.0, $ 
           Tilt : 0.0, $         ;Tilt of major axis from X axis, degrees.
           stang : 0.0, $        ;Starting angle, degrees.
           endang: 0.0  $        ;Ending angle, degrees.
         }
END
