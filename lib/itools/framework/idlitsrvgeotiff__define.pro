; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvgeotiff__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool services needed for GeoTIFF support.
;

;---------------------------------------------------------------------------
function IDLitsrvGeoTIFF::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Convert from a GeoTIFF projection (PCS) code to a
; projection name and Datum.
;
function IDLitsrvGeoTIFF::MatchProjectedCSType, pcscodeIn, datum, zone

    compile_opt idl2, hidden

@map_proj_init_commonblock

    if (pcscodeIn ge 32767) then $
        return, ''

  codes = [ $
    'utm', 'Adindan', '20137', '20138', '20100', $
    '-utm', 'Australian_Geodetic_1966', '20248', '20258', '20200', $
    '-utm', 'Australian_Geodetic_1984', '20348', '20358', '20300', $
    'utm', 'Ain_el_Abd_1970', '20437', '20439', '20400', $
    ; 20499
    'utm', 'Afgooye', '20538', '20539', '20500', $
    ; 20700
    '-utm', 'Aratu', '20822', '20824', '20800', $
    ; 20973-20995', 21100
    '-utm', 'Batavia', '21148', '21150', '21100', $
    'utm', 'Beijing_1954', '21413', '21423', '21400', $
    'utm', 'Beijing_1954', '21473', '21483', '21460', $
    ; 21500, 21790
    'utm', 'Bogota', '21817', '21818', '21800', $
    ; 21891-21894
    '-utm', 'Camacupa', '22032', '22033', '22000', $
    ; 22191-22197
    'utm', 'Carthage', '22332', '', '22300', $
    ; 22391-22392
    '-utm', 'Corrego_Alegre', '22523', '22524', '22500', $
    'utm', 'Douala', '22832', '', '22800', $
    ; 22992-22994
    'utm', 'European_1950', '23028', '23038', '23000', $
    'utm', 'Fahud', '23239', '23240', '23200', $
    'utm', 'Garoua', '23433', '', '23400', $
    'utm', 'Indonesian_1974', '23846', '23853', '23800', $
    '-utm', 'Indonesian_1974', '23886', '23894', '23840', $
    'utm', 'Indian_1954', '23947', '23948', '23900', $
    'utm', 'Indian_1975', '24047', '24048', '24000', $
    ; 24100, 24200, 24370-24384, 24500
    'utm', 'Kertau', '24547', '24548', '24500', $
    'utm', 'La_Canoa', '24720', '24721', '24700', $
    'utm', 'Provisional_S_American_1956', '24818', '24821', '24800', $
    '-utm', 'Provisional_S_American_1956', '24877', '24880', '24860', $
    ; 24891-24893, 25000
    'utm', 'Lome', '25231', '', '25200', $
    ; 25391-25395, 25700
    '-utm', 'Malongo_1987', '25932', '', '25900', $
    ; 26191, 26192, 26193
    'utm', 'Massawa', '26237', '', '26200', $
    'utm', 'Minna', '26331', '26332', '26300', $
    ; 26391-26393
    '-utm', 'Mhast', '26432', '', '26400', $
    ; 26591, 26592
    'utm', 'M_poraloko', '26632', '', '26600', $
    '-utm', 'M_poraloko', '26692', '', '26660', $
    'utm', 'nad27', '26703', '26722', '26700', $
    'sp', 'nad27', '26729', '', '101', $
    'sp', 'nad27', '26730', '', '102', $
    'sp', 'nad27', '26731', '', '5001', $
    'sp', 'nad27', '26732', '', '5002', $
    'sp', 'nad27', '26733', '', '5003', $
    'sp', 'nad27', '26734', '', '5004', $
    'sp', 'nad27', '26735', '', '5005', $
    'sp', 'nad27', '26736', '', '5006', $
    'sp', 'nad27', '26737', '', '5007', $
    'sp', 'nad27', '26738', '', '5008', $
    'sp', 'nad27', '26739', '', '5009', $
    'sp', 'nad27', '26740', '', '5010', $
    'sp', 'nad27', '26741', '', '401', $
    'sp', 'nad27', '26742', '', '402', $
    'sp', 'nad27', '26743', '', '403', $
    'sp', 'nad27', '26744', '', '404', $
    'sp', 'nad27', '26745', '', '405', $
    'sp', 'nad27', '26746', '', '406', $
    'sp', 'nad27', '26747', '', '407', $
    'sp', 'nad27', '26748', '', '201', $
    'sp', 'nad27', '26749', '', '202', $
    'sp', 'nad27', '26750', '', '203', $
    'sp', 'nad27', '26751', '', '301', $
    'sp', 'nad27', '26752', '', '302', $
    'sp', 'nad27', '26753', '', '501', $
    'sp', 'nad27', '26754', '', '502', $
    'sp', 'nad27', '26755', '', '503', $
    'sp', 'nad27', '26756', '', '600', $
    'sp', 'nad27', '26757', '', '700', $
    'sp', 'nad27', '26758', '', '901', $
    'sp', 'nad27', '26759', '', '902', $
    'sp', 'nad27', '26760', '', '903', $
    'sp', 'nad27', '26761', '', '5101', $
    'sp', 'nad27', '26762', '', '5102', $
    'sp', 'nad27', '26763', '', '5103', $
    'sp', 'nad27', '26764', '', '5104', $
    'sp', 'nad27', '26765', '', '5105', $
    'sp', 'nad27', '26766', '', '1001', $
    'sp', 'nad27', '26767', '', '1002', $
    'sp', 'nad27', '26768', '', '1101', $
    'sp', 'nad27', '26769', '', '1102', $
    'sp', 'nad27', '26770', '', '1103', $
    'sp', 'nad27', '26771', '', '1201', $
    'sp', 'nad27', '26772', '', '1202', $
    'sp', 'nad27', '26773', '', '1301', $
    'sp', 'nad27', '26774', '', '1302', $
    'sp', 'nad27', '26775', '', '1401', $
    'sp', 'nad27', '26776', '', '1402', $
    'sp', 'nad27', '26777', '', '1501', $
    'sp', 'nad27', '26778', '', '1502', $
    'sp', 'nad27', '26779', '', '1601', $
    'sp', 'nad27', '26780', '', '1602', $
    'sp', 'nad27', '26781', '', '1701', $
    'sp', 'nad27', '26782', '', '1702', $
    'sp', 'nad27', '26783', '', '1801', $
    'sp', 'nad27', '26784', '', '1802', $
    'sp', 'nad27', '26785', '', '1900', $
    'sp', 'nad27', '26786', '', '2001', $
    'sp', 'nad27', '26787', '', '2002', $
    'sp', 'nad27', '26788', '', '2111', $
    'sp', 'nad27', '26789', '', '2112', $
    'sp', 'nad27', '26790', '', '2113', $
    'sp', 'nad27', '26791', '', '2201', $
    'sp', 'nad27', '26792', '', '2202', $
    'sp', 'nad27', '26793', '', '2203', $
    'sp', 'nad27', '26794', '', '2301', $
    'sp', 'nad27', '26795', '', '2302', $
    'sp', 'nad27', '26796', '', '2401', $
    'sp', 'nad27', '26797', '', '2402', $
    'sp', 'nad27', '26798', '', '2403', $
    'sp', 'nad27', '26801', '', '2101', $
    'sp', 'nad27', '26802', '', '2102', $
    'sp', 'nad27', '26803', '', '2103', $
    'utm', 'North_American_1983', '26903', '26923', '26900', $
    ; 26929-26998 same as 26729-26798 but NAD83 instead of NAD27
    'utm', 'Nahrwan_1967', '27038', '27040', '27000', $
    'utm', 'Naparima_1972', '27120', '', '27100', $
    ; 27200, 27291, 27292
    'utm', 'Datum_73', '27429', '', '27400', $
    ; 27500, 27581-27583, 27591-27593, 27700
    '-utm', 'Pointe_Noire', '28232', '', '28200', $
    '-utm', 'Geocentric_of_Australia_1994', '28348', '28358', '28300', $
    'utm', 'Pulkovo_1942', '28404', '28432', '28400', $
    'utm', 'Pulkovo_1942', '28464', '28492', '28460', $
    ; 28600, 28991, 28992
    'utm', 'South_American_1969', '29118', '29122', '29100', $
    '-utm', 'South_American_1969', '29177', '29185', '29160', $
    '-utm', 'Sapper_Hill_1943', '29220', '29221', '29200', $
    '-utm', 'Schwarzeck', '29333', '', '29300', $
    'utm', 'Sudan', '29635', '29636', '29600', $
    ; 29700
    '-utm', 'Tananarive_1925', '29738', '29739', '29700', $
    ; 29800
    'utm', 'Timbalai_1948', '29849', '29850', '29800', $
    ; 29900, 30200
    'utm', 'Trucial_Coast_1948', '30339', '30340', '30300', $
    ; 30491, 30492, 30591, 30592, 30600
    'utm', 'Nord_Sahara_1959', '30729', '30732', '30700', $
    'utm', 'Yoff', '31028', '', '31000', $
    'utm', 'Zanderij', '31121', '', '31100', $
    ; 31291-31293, 31300, 31491-31495
    'sp', 'nad27', '32001', '', '2501', $
    'sp', 'nad27', '32002', '', '2502', $
    'sp', 'nad27', '32003', '', '2503', $
    'sp', 'nad27', '32005', '', '2601', $
    'sp', 'nad27', '32006', '', '2602', $
    'sp', 'nad27', '32007', '', '2701', $
    'sp', 'nad27', '32008', '', '2702', $
    'sp', 'nad27', '32009', '', '2703', $
    'sp', 'nad27', '32010', '', '2800', $
    'sp', 'nad27', '32011', '', '2900', $
    'sp', 'nad27', '32012', '', '3001', $
    'sp', 'nad27', '32013', '', '3002', $
    'sp', 'nad27', '32014', '', '3003', $
    'sp', 'nad27', '32015', '', '3101', $
    'sp', 'nad27', '32016', '', '3102', $
    'sp', 'nad27', '32017', '', '3103', $
    'sp', 'nad27', '32018', '', '3104', $
    'sp', 'nad27', '32019', '', '3200', $
    'sp', 'nad27', '32020', '', '3301', $
    'sp', 'nad27', '32021', '', '3302', $
    'sp', 'nad27', '32022', '', '3401', $
    'sp', 'nad27', '32023', '', '3402', $
    'sp', 'nad27', '32024', '', '3501', $
    'sp', 'nad27', '32025', '', '3502', $
    'sp', 'nad27', '32026', '', '3601', $
    'sp', 'nad27', '32027', '', '3602', $
    'sp', 'nad27', '32028', '', '3701', $
    'sp', 'nad27', '32029', '', '3702', $
    'sp', 'nad27', '32030', '', '3800', $
    'sp', 'nad27', '32031', '', '3901', $
    'sp', 'nad27', '32033', '', '3902', $
    'sp', 'nad27', '32034', '', '4001', $
    'sp', 'nad27', '32035', '', '4002', $
    'sp', 'nad27', '32036', '', '4100', $
    'sp', 'nad27', '32037', '', '4201', $
    'sp', 'nad27', '32038', '', '4202', $
    'sp', 'nad27', '32039', '', '4203', $
    'sp', 'nad27', '32040', '', '4204', $
    'sp', 'nad27', '32041', '', '4205', $
    'sp', 'nad27', '32042', '', '4301', $
    'sp', 'nad27', '32043', '', '4302', $
    'sp', 'nad27', '32044', '', '4303', $
    'sp', 'nad27', '32045', '', '4400', $
    'sp', 'nad27', '32046', '', '4501', $
    'sp', 'nad27', '32047', '', '4502', $
    'sp', 'nad27', '32048', '', '4601', $
    'sp', 'nad27', '32049', '', '4602', $
    'sp', 'nad27', '32050', '', '4701', $
    'sp', 'nad27', '32051', '', '4702', $
    'sp', 'nad27', '32052', '', '4801', $
    'sp', 'nad27', '32053', '', '4802', $
    'sp', 'nad27', '32054', '', '4803', $
    'sp', 'nad27', '32055', '', '4901', $
    'sp', 'nad27', '32056', '', '4902', $
    'sp', 'nad27', '32057', '', '4903', $
    'sp', 'nad27', '32058', '', '4904', $
    'sp', 'nad27', '32059', '', '5201', $
    'sp', 'nad27', '32060', '', '5202', $
    'sp', 'North_American_1983', '32100', '', '2500', $
    'sp', 'North_American_1983', '32104', '', '2600', $
    ; 32107-32130 same as 32007-32030 but NAD83 instead of NAD27
    'sp', 'North_American_1983', '32133', '', '3900', $
    ; 32134-32158 same as 32034-32058 but NAD83 instead of NAD27
    'sp', 'North_American_1983', '32161', '', '5201',  $
    'utm', 'WGS72', '32201', '32260', '32200', $
    '-utm', 'WGS72', '32301', '32360', '32300', $
    'utm', 'WGS72_Transit_Broadcast_Ephemeris', '32401', '32460', '32400', $
    '-utm', 'WGS72_Transit_Broadcast_Ephemeris', '32501', '32560', '32500', $
    'utm', 'WGS84', '32601', '32660', '32600', $
    '-utm', 'WGS84', '32701', '32760', '32700']

    codes = REFORM(codes, 5, N_ELEMENTS(codes)/5)
    projs = REFORM(codes[0,*])
    datums = REFORM(codes[1,*])
    code1 = LONG(REFORM(codes[2,*]))
    code2 = LONG(REFORM(codes[3,*]))
    ; Replace null strings (zeroes) with first code.
    dup = WHERE(code2 eq 0)
    code2[dup] = code1[dup]
    subcode = LONG(REFORM(codes[4,*]))

    codes = 0 ; Free up memory

    datum = ''

    ; Fix up State Plane projs, used to avoid bloating the table above.
    pcscode = pcscodeIn
    if (pcscode ge 26929 && pcscode le 26998) then begin
        datum = 'North_American_1983'
        pcscode -= 200
    endif else if ((pcscode ge 32107 && pcscode le 32130) || $
        (pcscode ge 32134 && pcscode le 32158)) then begin
        datum = 'North_American_1983'
        pcscode -= 100
    endif

    match = (WHERE(pcscode ge code1 and pcscode le code2))[0]
    if (match lt 0) then $
        return, ''

    case projs[match] of

    'utm': begin
        result = 'UTM'
        zone = pcscode - subcode[match]
        end

    '-utm': begin
        result = 'UTM'
        zone = -(pcscode - subcode[match])
        end

    'sp': begin
        result = 'State Plane'
        zone = subcode[match]
        end

    endcase

    if (datum eq '') then $
        datum = datums[match]

    if (datum eq 'nad27') then $
        datum = 'North_American_1927'

    return, result

end


;---------------------------------------------------------------------------
; Convert from a GeoTIFF projection (PCS) code to a
; projection name and Datum. Handles special projections.
;
function IDLitsrvGeoTIFF::MatchSpecialProjection, pcscode, datum, $
    CENTER_LATITUDE=centerLatitude, $
    CENTER_LONGITUDE=centerLongitude, $
    FALSE_EASTING=falseEasting, $
    FALSE_NORTHING=falseNorthing, $
    MERCATOR_SCALE=mercatorScale, $
    STANDARD_PAR1=standardPar1, $
    STANDARD_PAR2=standardPar2


    compile_opt idl2, hidden

    if (pcscode eq 21500) then begin  ; Belge 1950 (Brussels)/Belge Lambert 50
        datum = 'Reseau_National_Belge_1950'
        centerLatitude = 90.D
        centerLongitude = 0.D
        falseEasting = 150000.D
        falseNorthing = 5400000.D
        standardPar1  = 49.8333333333333D
        standardPar2  = 51.1666666666667D
        return, 'Lambert Conformal Conic'
    endif

    ; Monte Mario (Rome) / Italy zone 1 & 2
    if (pcscode eq 26591 || pcscode eq 26592) then begin
        datum = 'Monte_Mario'
        centerLatitude = 0.D
        centerLongitude = (pcscode eq 26591) ? 9 : 15
        falseEasting = (pcscode eq 26591) ? 1500000 : 2520000
        falseNorthing = 0.D
        mercatorScale = 0.9996D
        return, 'Transverse Mercator'
    endif

    if (pcscode eq 27500) then begin  ; ATF (Paris) / Nord de Guerre
        datum = 'Ancienne_Triangulation_Francaise'
        centerLatitude = 55.D
        centerLongitude = 6.D
        falseEasting = 500000.D
        falseNorthing = 300000.D
        standardPar1  = 0.99950908D
        standardPar2  = standardPar1
        return, 'Lambert Conformal Conic'
    endif

    ; NTF France Projections
    if ((pcscode ge 27581 && pcscode le 27584) || $
        (pcscode ge 27591 && pcscode le 27593)) then begin
        datum = 'Nouvelle_Triangulation_Francaise'
        falseEasting = 600000.D
        falseNorthing = 200000.D
        centerLongitude = 2.337229167D
        case (pcscode) of
        27581: begin  ; NTF (Paris) / France I
            centerLatitude = 49.5D
            falseNorthing = 1200000.D
            standardPar1 = 48.598523D
            standardPar2 = 50.395912D
            end
        27582: begin  ; NTF (Paris) / France II
            ; changed from 1SP to 2SP parameters
            centerLatitude = 46.80D
            falseNorthing = 2200000.D
            standardPar1 = 45.898919D
            standardPar2 = 47.696014D
        end
        27583: begin  ; NTF (Paris) / France III
            centerLatitude = 44.1D
            falseNorthing = 3200000.D
            standardPar1 = 43.1992889D
            standardPar2 = 44.996094D
        end
        27584: begin  ; NTF (Paris) / France IV
            centerLatitude = 42.165D
            falseEasting = 234.358D
            falseNorthing = 4185861.369D
            standardPar1 = 41.5603889D
            standardPar2 = 42.76766389D
        end
        27591: begin  ; NTF (Paris) / Nord France
            centerLatitude = 49.5D
            standardPar1 = 48.598523D
            standardPar2 = 50.395912D
        end
        27592: begin  ; NTF (Paris) / Centre France
            centerLatitude = 46.8D
            standardPar1 = 45.898919D
            standardPar2 = 47.696014D
        end
        27593: begin  ; NTF (Paris) / Sud France
            centerLatitude = 44.1D
            standardPar1 = 43.199291D
            standardPar2 = 44.996094D
            end
        endcase
        return, 'Lambert Conformal Conic'
    endif

    if (pcscode eq 27700) then begin  ; OSGB 1936 / British National Grid
        datum = "OSGB_1936"
        centerLatitude = 49.D
        centerLongitude = -2.D
        falseEasting = 400000.D
        falseNorthing = -100000.D
        mercatorScale = 0.999601272D
        return, 'Transverse Mercator'
    endif

    if (pcscode eq 28991 || pcscode eq 28992) then begin  ; RD/Netherlands Old
        datum = 'Amersfoort'
        centerLatitude = 52.1561605555556D
        centerLongitude = 5.38763888888889D
        falseEasting = (pcscode eq 28992) ? 155000 : 0
        falseNorthing = (pcscode eq 28992) ? 463000 : 0
        mercatorScale = 0.9999079D
        return, 'Stereographic'
    endif

    if (pcscode eq 29900) then begin  ; TM65 / Irish National Grid
        datum = 'TM65'
        centerLatitude = 53.5D
        centerLongitude = -8.D
        falseEasting = 200000.D
        falseNorthing = 250000.D
        mercatorScale = 1.000035D
        return, 'Transverse Mercator'
    endif

    ; MGI (Ferro) / Austria West, Center, East Zone
    if (pcscode ge 31291 && pcscode le 31293) then begin
        datum = 'Militar_Geographische_Institut'
        centerLatitude = 0.D
        centerLongitude = 28.D + 3*(pcscode - 31291)
        falseEasting = 0.D
        falseNorthing = 0.D
        mercatorScale = 1.D
        return, 'Transverse Mercator'
    endif

    if (pcscode eq 31300) then begin  ; Belge 1972 / Belge Lambert 72
        datum = 'Reseau_National_Belge_1972'
        centerLatitude = 90.D
        centerLongitude = 4.35693972222222D
        falseEasting = 150000.01256D
        falseNorthing = 5400088.4378D
        standardPar1  = 49.8333333333333D
        standardPar2  = 51.1666666666667D
        return, 'Lambert Conformal Conic'
    endif

    return, ''
end


;---------------------------------------------------------------------------
; Convert from a GeoTIFF projection coordinate transform code
; to a projection name.
;
function IDLitsrvGeoTIFF::MatchProjCoordTrans, pcoordtrans

    compile_opt idl2, hidden

@map_proj_init_commonblock

    if (pcoordtrans ge 32767) then $
        return, ''

    case pcoordtrans of
    1: return, 'Transverse Mercator'
    2: return, 'Alaska Conformal'
    3: return, 'Hotine Oblique Mercator B'
    4: return, 'Hotine Oblique Mercator B'
    5: return, 'Hotine Oblique Mercator B'
    6: return, 'Hotine Oblique Mercator B'
    7: return, 'Mercator'
    8: return, 'Lambert Conformal Conic'
    9: return, 'Lambert Conformal Conic'
    10: return, 'Lambert Azimuthal'
    11: return, 'Albers Equal Area'
    12: return, 'Azimuthal'
    13: return, 'Equidistant Conic A'
    14: return, 'Stereographic'
    15: return, 'Polar Stereographic'
    16: return, 'Stereographic'
    17: return, 'Equirectangular'
    18: return, ''  ; CT_CassiniSoldner
    19: return, 'Gnomonic'
    20: return, 'Miller Cylindrical'
    21: return, 'Orthographic'
    22: return, 'Polyconic'
    23: return, 'Robinson'
    24: return, 'Sinusoidal'
    25: return, 'Van der Grinten'
    26: return, ''  ; CT_NewZealandMapGrid
    27: return, ''  ; CT_TransvMercator_SouthOriented
    else: return, ''
    endcase

end


;---------------------------------------------------------------------------
; Convert from a GeoTIFF datum code to an IDL datum string.
;
; iDatum can either be an integer giving the code, or a string
; giving the GeoTIFF datum name.
;
;
function IDLitsrvGeoTIFF::MatchDatum, idatum, GEOTIFF_DATUM=geotiffDatum

    compile_opt idl2, hidden

; lut_datum    - is the geotiff datum number (long)
; geotiff_name - is the geotiff datum name (string)
; list_datum   - is the ENVI/iTools datum name (string)

    datums = [ $
    '4201', 'Adindan',                    'Adindan', $
    '4202', 'Australian_Geodetic_1966',   'Australian Geodetic 1966', $
    '4203', 'Australian_Geodetic_1984',   'Australian Geodetic 1984', $
    '4204', 'Ain_el_Abd_1970',            'Ain El Abd 1970', $
    '4205', 'Afgooye',                    'Afgooye', $
    '4206', 'Agadez',                     '', $
    '4207', 'Lisbon',                     '', $
    '4208', 'Aratu',                      '', $
    '4209', 'Arc_1950',                   'ARC-1950 mean', $
    '4210', 'Arc_1960',                   'ARC-1960 mean', $
    '4211', 'Batavia',                    'Djakarta(Batavia)', $
    '4212', 'Barbados',                   '', $
    '4213', 'Beduaram',                   '', $
    '4214', 'Beijing_1954',               '', $
    '4215', 'Reseau_National_Belge_1950', '', $
    '4216', 'Bermuda_1957',               'Bermuda 1957', $
    '4217', 'Bern_1898',                  '', $
    '4218', 'Bogota',                     'Bogota Observatory', $
    '4219', 'Bukit_Rimpah',               'Bukit Rimpah', $
    '4220', 'Camacupa',                   '', $
    '4221', 'Campo_Inchauspe',            'Campo Inchauspe', $
    '4222', 'Cape',                       'Cape', $
    '4223', 'Carthage',                   'Carthage', $
    '4224', 'Chua',                       'Chua Astro', $
    '4225', 'Corrego_Alegre',             'Corrego Alegre', $
    '4226', 'Cote_d_Ivoire',              '', $
    '4227', 'Deir_ez_Zor',                '', $
    '4228', 'Douala',                     '', $
    '4229', 'Egypt_1907',                 'Egypt', $
    '4230', 'European_1950',              'European 1950', $
    '4231', 'European_1987',              '', $
    '4232', 'Fahud',                      '', $
    '4233', 'Gandajika_1970',             'Gandajika Base', $
    '4234', 'Garoua',                     '', $
    '4235', 'Guyane_Francaise',           '', $
    '4236', 'Hu_Tzu_Shan',                'Hu-Tzu-Shan', $
    '4237', 'Hungarian_1972',             '', $
    '4238', 'Indonesian_1974',            '', $
    '4239', 'Indian_1954',                '', $
    '4240', 'Indian_1975',                '', $
    '4241', 'Jamaica_1875',               '', $
    '4242', 'Jamaica_1969',               '', $
    '4243', 'Kalianpur',                  '', $
    '4244', 'Kandawala',                  '', $
    '4245', 'Kertau',                     "Kertau 48", $
    '4246', 'Kuwait_Oil_Company',         '', $
    '4247', 'La_Canoa',                   '', $
    '4248', 'Provisional_S_American_1956', 'Provisional South American 1956 mean',$
    '4249', 'Lake',                       '', $
    '4250', 'Leigon',                     '', $
    '4251', 'Liberia_1964',               'Liberia 1964', $
    '4252', 'Lome',                       '', $
    '4253', 'Luzon_1911',                 'Luzon', $
    '4254', 'Hito_XVIII_1963',            '', $
    '4255', 'Herat_North',                '', $
    '4256', 'Mahe_1971',                  'Mahe 1971', $
    '4257', 'Makassar',                   '', $
    '4258', 'European_Reference_System_1989', '', $
    '4259', 'Malongo_1987',               '', $
    '4260', 'Manoca',                     '', $
    '4261', 'Merchich',                   'Merchich', $
    '4262', 'Massawa',                    'Massawa', $
    '4263', 'Minna',                      'Minna', $
    '4264', 'Mhast',                      '', $
    '4265', 'Monte_Mario',                '', $
    '4266', 'M_poraloko',                 '', $
    '4267', 'North_American_1927',        'North America 1927', $
    '4268', 'NAD_Michigan',               '', $
    '4269', 'North_American_1983',        'North America 1983', $
    '4270', 'Nahrwan_1967',               'Nahrwan', $
    '4271', 'Naparima_1972',              'Naparima BWI', $
    '4272', 'New_Zealand_Geodetic_1949',  '', $
    '4273', 'NGO_1948',                   '', $
    '4274', 'Datum_73',                   '', $
    '4275', 'Nouvelle_Triangulation_Francaise', 'Nouvelle Triangulation Francaise IGN', $
    '4276', 'NSWC_9Z_2',                  '', $
    '4277', 'OSGB_1936',                  "Ordnance Survey of Great Britain 36", $
    '4278', 'OSGB_1970_SN',               '', $
    '4279', 'OS_SN_1980',                 '', $
    '4280', 'Padang_1884',                '', $
    '4281', 'Palestine_1923',             '', $
    '4282', 'Pointe_Noire',               '', $
    '4283', 'Geocentric_of_Australia_1994', 'Geocentric Datum of Australia 1994',$
    '4284', 'Pulkovo_1942',               '', $
    '4285', 'Qatar',                      '', $
    '4286', 'Qatar_1948',                 '', $
    '4287', 'Qornoq',                     'Qornoq', $
    '4288', 'Loma_Quintana',              '', $
    '4289', 'Amersfoort',                 '', $
    '4290', 'RT38',                       '', $
    '4291', 'South_American_1969',        'SAD-69/Brazil', $
    '4292', 'Sapper_Hill_1943',           "Sapper Hill 43", $
    '4293', 'Schwarzeck',                 '', $
    '4294', 'Segora',                     '', $
    '4295', 'Serindung',                  '', $
    '4296', 'Sudan',                      '', $
    '4297', 'Tananarive_1925',            "Tananarive Observatory 25", $
    '4298', 'Timbalai_1948',              'Timbalai 1948', $
    '4299', 'TM65',                       '', $
    '4300', 'TM75',                       '', $
    '4301', 'Tokyo',                      'Tokyo mean', $
    '4302', 'Trinidad_1903',              '', $
    '4303', 'Trucial_Coast_1948',         '', $
    '4304', 'Voirol_1875',                '', $
    '4305', 'Voirol_Unifie_1960',         '', $
    '4306', 'Bern_1938',                  '', $
    '4307', 'Nord_Sahara_1959',           '', $
    '4308', 'Stockholm_1938',             '', $
    '4309', 'Yacare',                     '', $
    '4310', 'Yoff',                       '', $
    '4311', 'Zanderij',                   'Zanderij', $
    '4312', 'Militar_Geographische_Institut', '', $
    '4313', 'Reseau_National_Belge_1972', '', $
    '4314', 'Deutsche_Hauptdreiecksnetz', '', $
    '4315', 'Conakry_1905',               '', $
    '4322', 'WGS72',                      'WGS-72', $
    '4324', 'WGS72_Transit_Broadcast_Ephemeris', '', $
    '4326', 'WGS84',                      'WGS-84', $
    '4901', 'Ancienne_Triangulation_Francaise', '', $
    '4902', 'Nord_de_Guerre',             '', $
    '4001', 'Airy1830',                   '', $
    '4002', 'AiryModified1849',           '', $
    '4003', 'AustralianNationalSpheroid', '', $
    '4004', 'Bessel1841',                 '', $
    '4005', 'BesselModified',             '', $
    '4006', 'BesselNamibia',              '', $
    '4007', 'Clarke1858',                 '', $
    '4008', 'Clarke1866',                 '', $
    '4009', 'Clarke1866Michigan',         '', $
    '4010', 'Clarke1880_Benoit',          '', $
    '4011', 'Clarke1880_IGN',             '', $
    '4012', 'Clarke1880_RGS',             '', $
    '4013', 'Clarke1880_Arc',             '', $
    '4014', 'Clarke1880_SGA1922',         '', $
    '4015', 'Everest1830_1937Adjustment', '', $
    '4016', 'Everest1830_1967Definition', '', $
    '4017', 'Everest1830_1975Definition', '', $
    '4018', 'Everest1830Modified',        '', $
    '4019', 'GRS1980',                    '', $
    '4020', 'Helmert1906',                '', $
    '4021', 'IndonesianNationalSpheroid', '', $
    '4022', 'International1924',          '', $
    '4023', 'International1967',          '', $
    '4024', 'Krassowsky1960',             '', $
    '4025', 'NWL9D',                      '', $
    '4026', 'NWL10D',                     '', $
    '4027', 'Plessis1817',                '', $
    '4028', 'Struve1860',                 '', $
    '4029', 'WarOffice',                  '', $
    '4030', 'WGS84',                      'WGS-84', $
    '4031', 'GEM10C',                     '', $
    '4032', 'OSU86F',                     '', $
    '4033', 'OSU91A',                     '', $
    '4034', 'Clarke1880',                 '', $
    '4035', 'Sphere',                     '']

    datums = REFORM(datums, 3, N_ELEMENTS(datums)/3)

    isString = SIZE(idatum, /TYPE) eq 7
    match = (WHERE(datums[isString ? 1 : 0,*] eq idatum))[0]

    if (match lt 0) then begin
        geotiffDatum = ''
        return, ''
    endif

    geotiffDatum = datums[1, match]

    return, datums[2, match]

end


;---------------------------------------------------------------------------
; Convert from an IDL Datum string to an IDL ellipsoid.
;
function IDLitsrvGeoTIFF::MatchEllipsoid, datum

    compile_opt idl2, hidden

@map_proj_init_commonblock

    match = (WHERE(c_GeoDatumNames eq datum))[0]
    return, (match ge 0) ? c_GeoDatumEllipsoid[match] : ''

end


;---------------------------------------------------------------------------
function IDLitsrvGeoTIFF::GeoTIFFtoMapImage, geotiff, oVis

    compile_opt idl2, hidden

    ; Sanity checks.
    if (N_TAGS(geotiff) lt 1) then $
        return, 0
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    ; Retrieve the map register image operation.
    oDesc = oTool->GetByIdentifier('Operations/Operations/MapRegisterImage')
    if (~OBJ_VALID(oDesc)) then $
        return, 0
    oMapRegister = oDesc->GetObjectInstance()

    tagNames = TAG_NAMES(geotiff)

    success = 1

    dimensions = [0, 0]
    if (OBJ_VALID(oVis) && OBJ_ISA(oVis, '_IDLitVisGrid2D')) then begin
        oVis->GetProperty, GRID_DIMENSIONS=dimensions
    endif

    desc = ''
    if (MAX(tagNames eq 'GTCITATIONGEOKEY')) then $
        desc = [desc, 'GTCitationGeoKey: ' + geotiff.GTCitationGeoKey]
    if (MAX(tagNames eq 'GEOGCITATIONGEOKEY')) then $
        desc = [desc, 'GEOGCitationGeoKey: ' + geotiff.GEOGCitationGeoKey]


    mapProjection = ''
    datum = ''

; Grid units.
    if MAX(tagNames eq 'GTMODELTYPEGEOKEY') then begin
        model = geotiff.GTModelTypeGeoKey
    endif

    case model of
    1: gridUnits = 0 ; Projection Coordinate System (meters)
    2: begin
        gridUnits = 1 ; Geographic latitude-longitude System (degrees)
        mapProjection = 'No projection'
       end
    else: begin
        desc = [desc, 'Unknown model, defaulting to Projected Coordinate System.']
        success = 0
        gridUnits = 0
        end
    endcase


; Projection
    if (mapProjection eq '' && MAX(tagNames eq 'PROJECTEDCSTYPEGEOKEY')) then begin
        mapProjection = self->MatchProjectedCSType( $
            geotiff.ProjectedCSTypeGeoKey, geotiffDatum, zone)
        if (mapProjection eq '') then begin
            mapProjection = self->MatchSpecialProjection( $
                geotiff.ProjectedCSTypeGeoKey, geotiffDatum, $
                CENTER_LATITUDE=centerLatitude, $
                CENTER_LONGITUDE=centerLongitude, $
                FALSE_EASTING=falseEasting, $
                FALSE_NORTHING=falseNorthing, $
                MERCATOR_SCALE=mercatorScale, $
                STANDARD_PAR1=standardPar1, $
                STANDARD_PAR2=standardPar2)
        endif
        ; We should also have a datum with this projection,
        ; so find the ellipsoid.
        if (mapProjection ne '') then begin
            datum = self->MatchDatum(geotiffDatum)
            ellipsoid = self->MatchEllipsoid(datum)
        endif
    endif

    if (mapProjection eq '' && MAX(tagNames eq 'PROJCOORDTRANSGEOKEY')) then begin
        mapProjection = self->MatchProjCoordTrans(geotiff.ProjCoordTransGeoKey)
    endif

    if (mapProjection eq '') then begin
        hasKey = MAX(tagNames eq 'PCSCITATIONGEOKEY')
        desc = [desc, 'Unknown projection' + $
            (hasKey ? ': '+geotiff.PCSCitationGeoKey : '.')]
        success = 0
    endif


; Datum (we might already have the Datum from the projection).
    if (datum eq '' && MAX(tagNames eq 'GEOGRAPHICTYPEGEOKEY')) then begin
        datum = self->MatchDatum(geotiff.GeographicTypeGeoKey)
    endif

    if (datum eq '' && MAX(tagNames eq 'GEOGGEODETICDATUMGEOKEY')) then begin
        ; Geodetic have codes equal to Datum code minus 2000.
        datum = self->MatchDatum(geotiff.GeogGeodeticDatumGeoKey - 2000)
    endif

    if (datum eq '' && MAX(tagNames eq 'GEOGELLIPSOIDGEOKEY')) then begin
        ; Ellipsoids have codes equal to Datum code minus 3000.
        datum = self->MatchDatum(geotiff.GeogEllipsoidGeoKey - 3000)
    endif

    ; If still no datum, look for semimajor/minor axes.
    if ((datum eq '') && MAX(tagNames eq 'GEOGSEMIMAJORAXISGEOKEY') && $
        (MAX(tagNames eq 'GEOGSEMIMINORAXISGEOKEY') || $
        MAX(tagNames eq 'GEOGINVFLATTENINGGEOKEY'))) then begin

        semiMajor = geotiff.GeogSemiMajorAxisGeoKey

        if MAX(tagNames eq 'GEOGSEMIMINORAXISGEOKEY') then begin
            semiMinor = geotiff.GeogSemiMinorAxisGeoKey
        endif else begin
            flat = geotiff.GeogInvFlatteningGeoKey
            esquared = 2*flat - flat^2  ; eccentricity squared
            semiMinor = semiMajor*SQRT(1 - esquared)
        endelse

        ellipsoid = 'User defined'

    endif else begin

        ; Find the ellipsoid corresponding to the datum.
        ellipsoid = self->MatchEllipsoid(datum)
        if (ellipsoid eq '') then begin
            ellipsoid = 'WGS 84'   ; pick a default
            desc = [desc, $
                'Unknown datum' + (datum ne '' ? ' "'+datum+'"' : '') + $
                ', defaulting to WGS 84']
            success = 0
        endif

    endelse


; Units (needs to come after the Projection and Datum are determined).
    linearUnitCode = 9001 ; default to meters
    if (MAX(tagNames eq 'GEOGLINEARUNITSGEOKEY')) then begin
        linearUnitCode = geotiff.GeogLinearUnitsGeoKey
    endif else if (MAX(tagNames eq 'PROJLINEARUNITSGEOKEY')) then begin
        linearUnitCode = geotiff.ProjLinearUnitsGeoKey
    endif else if (mapProjection eq 'State Plane' && $
        datum eq 'North America 1927') then begin
        ; Default units for State Plane with NAD27 is "Feet".
        linearUnitCode = 9002
    endif

    feetMeters = 0.3048d
    case linearUnitCode of
    9001: scaleToMeters = 1
    9002: scaleToMeters = feetMeters
    9003: scaleToMeters = feetMeters*1.000002d
    9004: scaleToMeters = feetMeters*1.0000362d
    9005: scaleToMeters = feetMeters
    9006: scaleToMeters = feetMeters*1.0000014d
    9007: scaleToMeters = feetMeters*0.66d
    9008: scaleToMeters = feetMeters*0.66d
    9009: scaleToMeters = feetMeters*0.66d
    9010: scaleToMeters = feetMeters*66d
    9011: scaleToMeters = feetMeters*66d
    9012: scaleToMeters = feetMeters*3d
    9013: scaleToMeters = feetMeters*2.9999961d
    9014: scaleToMeters = feetMeters*6d
    9015: scaleToMeters = feetMeters*6076.11549d
    else: begin
        desc = [desc, 'Unknown linears units: LinearUnitsGeoKey = ' + $
            STRTRIM(linearUnitCode,2)]
        success = 0
        scaleToMeters = 1
        end
    endcase

    scaleToDegrees = 1
    if (MAX(tagNames eq 'GEOGANGULARUNITSGEOKEY')) then begin
        case geotiff.GeogAngularUnitsGeoKey of
        9101: scaleToDegrees = 180/!DPI  ; radians
        9102: scaleToDegrees = 1         ; degrees
        9103: scaleToDegrees = 1d/60     ; arc minutes
        9104: scaleToDegrees = 1d/3600   ; arc seconds
        9105: scaleToDegrees = 360d/400  ; grads
        else: begin
            desc = [desc, 'Unknown angular units: GeogAngularUnitsGeoKey = ' + $
                STRTRIM(geotiff.GeogAngularUnitsGeoKey,2)]
            success = 0
            end
        endcase
    endif

    scaleAzimToDegrees = 1
    if (MAX(tagNames eq 'GEOGAZIMUTHUNITSGEOKEY')) then begin
        case geotiff.GeogAzimuthUnitsGeoKey of
        9101: scaleAzimToDegrees = 180/!DPI  ; radians
        9102: scaleAzimToDegrees = 1         ; degrees
        9103: scaleAzimToDegrees = 1d/60     ; arc minutes
        9104: scaleAzimToDegrees = 1d/3600   ; arc seconds
        9105: scaleAzimToDegrees = 360d/400  ; grads
        else: begin
            desc = [desc, 'Unknown azimuth units: GeogAzimuthUnitsGeoKey = ' + $
                STRTRIM(geotiff.GeogAzimuthUnitsGeoKey,2)]
            success = 0
            end
        endcase
    endif


; Projection parameters.
    if (MAX(tagNames eq 'PROJCENTERLONGGEOKEY')) then begin
        centerLongitude = geotiff.ProjCenterLongGeoKey*scaleToDegrees
    endif else if (MAX(tagNames eq 'PROJNATORIGINLONGGEOKEY')) then begin
        centerLongitude = geotiff.ProjNatOriginLongGeoKey*scaleToDegrees
    endif else if (MAX(tagNames eq 'PROJFALSEORIGINLONGGEOKEY')) then begin
        centerLongitude = geotiff.ProjFalseOriginLongGeoKey*scaleToDegrees
    endif else if (MAX(tagNames eq 'PROJSTRAIGHTVERTPOLELONGGEOKEY')) then begin
        centerLongitude = geotiff.ProjStraightVertPoleLongGeoKey*scaleToDegrees
    endif

    if (MAX(tagNames eq 'PROJCENTERLATGEOKEY')) then begin
        centerLatitude = geotiff.ProjCenterLatGeoKey*scaleToDegrees
    endif else if (MAX(tagNames eq 'PROJNATORIGINLATGEOKEY')) then begin
        centerLatitude = geotiff.ProjNatOriginLatGeoKey*scaleToDegrees
    endif else if (MAX(tagNames eq 'PROJFALSEORIGINLATGEOKEY')) then begin
        centerLatitude = geotiff.ProjFalseOriginLatGeoKey*scaleToDegrees
    endif

    if (MAX(tagNames eq 'PROJSTDPARALLEL1GEOKEY')) then begin
        standardPar1 = geotiff.ProjStdParallel1GeoKey*scaleToDegrees
    endif

    if (MAX(tagNames eq 'PROJSTDPARALLEL2GEOKEY')) then begin
        standardPar2 = geotiff.ProjStdParallel2GeoKey*scaleToDegrees
    endif

    if (MAX(tagNames eq 'PROJFALSEEASTINGGEOKEY')) then begin
        falseEasting = geotiff.ProjFalseEastingGeoKey*scaleToMeters
    endif

    if (MAX(tagNames eq 'PROJFALSENORTHINGGEOKEY')) then begin
        falseNorthing = geotiff.ProjFalseNorthingGeoKey*scaleToMeters
    endif

    if (MAX(tagNames eq 'PROJSCALEATNATORIGINGEOKEY')) then begin
        mercatorScale = geotiff.ProjScaleAtNatOriginGeoKey
    endif

    if (MAX(tagNames eq 'PROJAZIMUTHANGLEGEOKEY')) then begin
        homAzimAngle = geotiff.ProjAzimuthAngleGeoKey*scaleAzimToDegrees
    endif


; Raster --> Model space transform
    pixelXSize = 1
    pixelYSize = 1
    if MAX(tagNames eq 'MODELPIXELSCALETAG') then begin
        pixelXSize = geotiff.ModelPixelScaleTag[0]*scaleToMeters
        pixelYSize = geotiff.ModelPixelScaleTag[1]*scaleToMeters
    endif

    if MAX(tagNames eq 'MODELTIEPOINTTAG') then begin
        ; If the first tiepoint is at [0,0] or [0.5,0.5] in raster space,
        ; then pull out the origin in model space, and mark success.
        tp = geotiff.ModelTiepointTag
        if ((tp[0] eq 0 || tp[0] eq 0.5) && $
            (tp[1] eq 0 || tp[1] eq 0.5)) then begin
            xOrigin = tp[3]*scaleToMeters
            ; The point [0,0] in raster space corresponds to the
            ; upper-left corner, so we need to move our model origin
            ; down to the lower left.
            yOrigin = tp[4]*scaleToMeters - pixelYSize*dimensions[1]
        endif else begin
            ; We can't handle multiple tiepoints.
            desc = [desc, 'Cannot handle multiple tiepoints.']
            success = 0
        endelse
    endif


    oMapRegister->GetProperty, SHOW_EXECUTION_UI=showUI

    ; First set all the grid properties.
    oMapRegister->SetProperty, GRID_UNITS=gridUnits, $
        XORIGIN=xOrigin, YORIGIN=yOrigin, $
        PIXEL_XSIZE=pixelXSize, PIXEL_YSIZE=pixelYSize, $
        UPDATE_DATASPACE=updateDataspace, $
        SHOW_EXECUTION_UI=0

    ; Now set all the projection properties.
    oMapProj = oMapRegister->_GetMapProjection()

    ; Set projection first, in case it resets other values.
    oMapProj->SetProperty, MAP_PROJECTION=mapProjection

    oMapProj->SetProperty, ELLIPSOID=ellipsoid, $
        CENTER_LONGITUDE=centerLongitude, $
        CENTER_LATITUDE=centerLatitude, $
        FALSE_EASTING=falseEasting, $
        FALSE_NORTHING=falseNorthing, $
        HOM_AZIM_ANGLE=homAzimAngle, $
        MERCATOR_SCALE=mercatorScale, $
        SEMIMAJOR_AXIS=semiMajor, $
        SEMIMINOR_AXIS=semiMinor, $
        STANDARD_PAR1=standardPar1, $
        STANDARD_PAR2=standardPar2, $
        ZONE=zone

    oCmd = oMapRegister->DoAction(oTool)

    OBJ_DESTROY, oCmd

    if (showUI) then $
        oMapRegister->SetProperty, /SHOW_EXECUTION_UI

    if (~success) then begin
        error = 'Unable to process GeoTIFF tags' + $
            ((N_ELEMENTS(desc) gt 1) ? ': ' : '.')
        if (N_ELEMENTS(desc) gt 1) then $
            error = [error, desc[1:*]]
        self->ErrorMessage, error, SEVERITY=2
    endif

    return, success

end


;---------------------------------------------------------------------------
; Given a GeoTIFF structure, return a scalar string containing
; all the tags, separated by CR/LF.
; Used by the GeoTIFF data object to display the tags.
;
function IDLitsrvGeoTIFF::DumpGeoTIFF, geotiff

    compile_opt idl2, hidden

    humanReadable = [ $
    'ModelPixelScaleTag', $
    'ModelTransformationTag', $
    'ModelTiepointTag', $
    'GTModelTypeGeoKey', $
    'GTRasterTypeGeoKey', $
    'GTCitationGeoKey', $
    'GeographicTypeGeoKey', $
    'GeogCitationGeoKey', $
    'GeogGeodeticDatumGeoKey', $
    'GeogPrimeMeridianGeoKey', $
    'GeogLinearUnitsGeoKey', $
    'GeogLinearUnitSizeGeoKey', $
    'GeogAngularUnitsGeoKey', $
    'GeogAngularUnitSizeGeoKey', $
    'GeogEllipsoidGeoKey', $
    'GeogSemiMajorAxisGeoKey', $
    'GeogSemiMinorAxisGeoKey', $
    'GeogInvFlatteningGeoKey', $
    'GeogAzimuthUnitsGeoKey', $
    'GeogPrimeMeridianLongGeoKey', $
    'ProjectedCSTypeGeoKey', $
    'PCSCitationGeoKey', $
    'ProjectionGeoKey', $
    'ProjCoordTransGeoKey', $
    'ProjLinearUnitsGeoKey', $
    'ProjLinearUnitSizeGeoKey', $
    'ProjStdParallel1GeoKey', $
    'ProjStdParallel2GeoKey', $
    'ProjNatOriginLongGeoKey', $
    'ProjNatOriginLatGeoKey', $
    'ProjFalseEastingGeoKey', $
    'ProjFalseNorthingGeoKey', $
    'ProjFalseOriginLongGeoKey', $
    'ProjFalseOriginLatGeoKey', $
    'ProjFalseOriginEastingGeoKey', $
    'ProjFalseOriginNorthingGeoKey', $
    'ProjCenterLongGeoKey', $
    'ProjCenterLatGeoKey', $
    'ProjCenterEastingGeoKey', $
    'ProjCenterNorthingGeoKey', $
    'ProjScaleAtNatOriginGeoKey', $
    'ProjScaleAtCenterGeoKey', $
    'ProjAzimuthAngleGeoKey', $
    'ProjStraightVertPoleLongGeoKey', $
    'VerticalCSTypeGeoKey', $
    'VerticalCitationGeoKey', $
    'VerticalDatumGeoKey', $
    'VerticalUnitsGeoKey']

    humanUpcase = STRUPCASE(humanReadable)

    text = STRARR(N_TAGS(geotiff))
    tagnames = TAG_NAMES(geotiff)
    maxlen = MAX(STRLEN(tagnames))
    format = '(A-' + STRTRIM(maxlen+2,2) + ')'
    for i=0,N_TAGS(geotiff)-1 do begin
        idx = WHERE(humanUpcase eq tagnames[i])
        text[i] = STRING(humanReadable[idx] + ': ', FORMAT=format)
        value = STRTRIM(STRCOMPRESS(STRING(geotiff.(i), /PRINT)), 2)
        text[i] += value
    endfor

    cr = string(13b)
    lf = string(10b)

    text = STRJOIN(text, $
        (!version.os_family eq 'Windows') ? cr + lf : lf)

    return, text

end


;---------------------------------------------------------------------------
pro IDLitsrvGeoTIFF__define

    compile_opt idl2, hidden

    struct = {IDLitsrvGeoTIFF, $
        inherits IDLitOperation}

end
