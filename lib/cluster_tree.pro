; $Id: //depot/idl/releases/IDL_80/idldir/lib/cluster_tree.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CLUSTER_TREE
;
; PURPOSE:
;   This function computes the hierarchical clustering for a set of
;   m items in an n-dimensional space.
;
; CATEGORY:
;   Statistics.
;
; CALLING SEQUENCE:
;   Result = CLUSTER_TREE(Pairdistance, Linkdistance)
;
; INPUTS:
;   Pairdistance: An input vector containing the pairwise distance matrix
;       in compact form, usually created by the DISTANCE_MEASURE function.
;       Given a set of m items, with the distance between items i and j
;       denoted by D(i, j), Pairdistance should be an m*(m-1)/2 element
;       vector, ordered as:
;       [D(0, 1),  D(0, 2), ..., D(0, m-1), D(1, 2), ..., D(m-2, m)].
;
; OUTPUTS:
;   Linkdistance: Set this argument to a named variable in which the
;       cluster distances will be returned as an (m-1)-element single
;       or double-precision vector. Each element of Linkdistance
;       corresponds to the distance between the two items of the
;       corresponding row in Result. If Pairdistance is double precision
;       then Linkdistance will be double precision, otherwise Linkdistance
;       will be single precision.
;
;   The Result is a 2-by-(m-1) integer array containing the cluster
;       indices. Each row of Result contains the indices of the two
;       items that were clustered together. The distance between the
;       two items is contained in the corresponding element of the
;       Linkdistance output argument.
;
; KEYWORD PARAMETERS:
;   DATA: If LINKAGE=3 (centroid), then the DATA keyword must be
;       set to the array of original data as input to the
;       DISTANCE_MEASURE function. The data array is necessary
;       for computing the centroid of newly-created clusters.
;   Note - DATA does not need to be supplied if LINKAGE is not equal to 3.
;
;   LINKAGE: Set this keyword to an integer giving the method used to
;       link clusters together. Possible values are:
;       LINKAGE=0 (the default): Use single linkage (nearest neighbor).
;           The distance between two clusters is defined as the
;           smallest distance between items in the two clusters.
;           This method tends to string items together and is useful
;           for non-homogeneous clusters.
;       LINKAGE=1: Use complete linkage (furthest neighbor).
;           The distance between two clusters is defined as the
;           largest distance between items. This method is useful
;           for homogeneous, compact, clusters but is not useful
;           for long chain-like clusters.
;       LINKAGE=2: Use weighted pairwise average. The distance between
;           two clusters is defined as the average distance for all
;           pairs of objects between each cluster, weighted by the
;           number of objects in each cluster. This method works
;           fairly well for both homogeneous clusters and for
;           chain-like clusters.
;       LINKAGE=3: Use weighted centroid. The distance between two
;           clusters is defined as the distance between the centroids
;           of each cluster. The centroid of a cluster is the average
;           position of all the subclusters, weighted by the number of
;           objects in each subcluster.
;
;   MEASURE: If LINKAGE=3 (centroid), then set this keyword to an
;           integer giving the distance measure (the metric) to use.
;           Possible values are:
;           MEASURE=0 (the default): Euclidean distance.
;           MEASURE=1: CityBlock (Manhattan) distance.
;           MEASURE=2: Chebyshev distance.
;           MEASURE=3: Correlative distance.
;           MEASURE=4: Percent disagreement.
;       For consistent results, the MEASURE value should match the
;       value used in the original call to DISTANCE_MEASURE.
;       This keyword is ignored if LINKAGE is not equal to 3,
;           or if POWER_MEASURE is set.
;
;       Note - See DISTANCE_MEASURE for a detailed description of
;           the various metrics.
;
;   POWER_MEASURE: If LINKAGE=3 (centroid), then set this keyword to a
;       scalar or a two-element vector giving the parameters p and r
;       to be used in the power distance metric.
;       If POWER_MEASURE is a scalar then the same value is used for both
;       p and r.
;       For consistent results, the POWER_MEASURE value should match the
;       value used in the original call to DISTANCE_MEASURE.
;       This keyword is ignored if LINKAGE is not equal to 3.
;
;       Note - See DISTANCE_MEASURE for a detailed description of
;           the power distance metric.
;
; EXAMPLE:
;        ; Given a set of points in two-dimensional space.
;        data = [ $
;            [1, 1], $
;            [1, 3], $
;            [2, 2.2], $
;            [4, 1.75], $
;            [4, 4], $
;            [5, 1], $
;            [5.5, 3]]
;
;        ; Compute the Euclidean distance between each point.
;        distance = DISTANCE_MEASURE(data)
;
;        ; Now compute the cluster analysis.
;        clusters = CLUSTER_TREE(distance, linkdistance)
;
;        PRINT, 'Item#  Item#  Distance'
;        PRINT, [clusters, TRANSPOSE(linkdistance)], $
;            FORMAT='(I3, I7, F10.2)'
;
; REFERENCE:
;   Portions of the linkage code were adapted from:
;       "The C Clustering Library",
;       Michiel de Hoon, Seiya Imoto, Satoru Miyano
;       The University of Tokyo, Institute of Medical Science,
;       Human Genome Center.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, August 2003
;   Modified:
;
;-

;-------------------------------------------------------------------------
; For LINKAGE=3 (centroid), compute the distance between two clusters.
; For speed, this assumes that all error checking has been done.
;
; Power argument is only required for Measure=-1 (Power measure).
; Otherwise it is ignored.
;
function cluster_tree_distance, vec1, vec2, measure, power

    compile_opt idl2, hidden

    case measure of

        0: $  ; Euclidean
         return, SQRT(TOTAL((vec1 - vec2)^2))

        1: $  ; CityBlock
         return, TOTAL(ABS(vec1 - vec2))

        2: $  ; Chebyshev
         return, MAX(ABS(vec1 - vec2))

        3: $  ; Correlative distance
         return, SQRT(0.5*(1 - CORRELATE(vec1, vec2)))

        4: $  ; Percent disagreement
         return, TOTAL(vec1 ne vec2)/N_ELEMENTS(vec1)

        -1: $ ; Power
         return, TOTAL(ABS(vec1 - vec2)^power[0])^(1/power[1])

        else: MESSAGE, 'Illegal keyword value for MEASURE.'

    endcase

end


;-------------------------------------------------------------------------
function cluster_tree_centroid, distmatrix, data, linkdistance, $
    measure, power

    compile_opt idl2, hidden

    ; All argument checking is done in the main routine.
    dataDims = SIZE(data, /DIMENSIONS)
    m = dataDims[1]
    n = dataDims[0]

    dbl = SIZE(distmatrix, /TYPE) eq 5

    result = LONARR(2, m-1)
    linkdistance = dbl ? DBLARR(m-1, /NOZERO) : FLTARR(m-1, /NOZERO)

    clusterid = LINDGEN(m)
    nodedata = dbl ? DBLARR(n, m-1) : FLTARR(n, m-1)
    nodecount = LONARR(n, m-1)

    huge = dbl ? 1d300 : 1e30

    dim = m

    for inode=0, m-2 do begin

        ; Given all of the distances between items (or clusters),
        ; find the smallest distance and join them. This doesn't
        ; depend upon the linkage method.
        linkdistance[inode] = MIN(distmatrix, locmin)
        im = locmin/dim
        jm = locmin mod dim

        result[0, inode] = clusterid[im]
        result[1, inode] = clusterid[jm]

        ; Combine im and jm and move into jm.
        nodedata[*, inode] = 0
        nodecount[*, inode] = 0

        for ij=0,1 do begin   ; do both im and jm
            mm = ij ? jm : im
            if (clusterid[mm] ge m) then begin
                noderow = clusterid[mm] - m
                count = nodecount[*, noderow]
                nodecount[*, inode] += count
                nodedata[*, inode] += nodedata[*, noderow] * count
            endif else begin
                datarow = clusterid[mm]
                nodecount[*, inode]++
                nodedata[*, inode] += data[*, datarow]
            endelse
        endfor

        nodedata[*, inode] /= (nodecount[*, inode] > 1)


        ; The im row/col has been combined with jm,
        ; so now shift the last row/col into the im slot
        ; and shrink the matrix by 1 row/col.
        if (im ne m-inode-1) then $
            distmatrix[0:im-1, im] = distmatrix[0:im-1, m-inode-1]
        if (im+1 le m-inode-2) then $
            distmatrix[im, im+1:m-inode-2] = distmatrix[im+1:m-inode-2, m-inode-1]

        ; New cluster numbers.
        clusterid[jm] = m + inode
        clusterid[im] = clusterid[m - 1 - inode]

        nodedata1 = nodedata[*, inode]
        for i=0, jm-1 do begin
            if (clusterid[i] ge m) then begin
                distmatrix[i, jm] = CLUSTER_TREE_DISTANCE( $
                    nodedata1, nodedata[*, clusterid[i]-m], $
                    measure, power)
            endif else begin
                distmatrix[i, jm] = CLUSTER_TREE_DISTANCE( $
                    nodedata1, data[*, clusterid[i]], $
                    measure, power)
            endelse
        endfor
        for i=jm+1, m-inode-2 do begin
            if (clusterid[i] ge m) then begin
                distmatrix[jm, i] = CLUSTER_TREE_DISTANCE( $
                    nodedata1, nodedata[*, clusterid[i]-m], $
                    measure, power)
            endif else begin
                distmatrix[jm, i] = CLUSTER_TREE_DISTANCE( $
                    nodedata1, data[*, clusterid[i]], $
                    measure, power)
            endelse
        endfor

        ; We no longer need the last row/column of distmatrix.
        if (m-inode le 0.707*dim) then begin    ; shrink the array
            distmatrix = distmatrix[0:m-inode-2, 0:m-inode-2]
            dim = m - inode - 1
        endif else begin    ; fill in big value
            distmatrix[0:m-inode-2, m-inode-1] = huge
        endelse

    endfor

    return, result
end


;-------------------------------------------------------------------------
function cluster_tree, pairdistance, linkdistance, $
    DATA=data, $
    LINKAGE=linkageIn, $
    MEASURE=measureIn, $
    POWER_MEASURE=powerIn

    compile_opt idl2

    ON_ERROR, 2

    linkage = (N_ELEMENTS(linkageIn) eq 1) ? linkageIn : 0
    if ((linkage lt 0) || (linkage gt 3)) then $
        MESSAGE, 'Illegal keyword value for LINKAGE.'

    ndim = SIZE(pairdistance, /N_DIMENSIONS)
    dims = SIZE(pairdistance, /DIMENSIONS)
    if (ndim lt 1) || (ndim gt 2) || $
        (ndim eq 2 && dims[0] ne dims[1]) then $
        MESSAGE, 'Pairdistance must be a vector or a 2D symmetric array.'


    m = (ndim eq 1) ? LONG((1 + SQRT(8*dims[0] + 1))/2) : dims[0]


    dbl = SIZE(pairdistance, /TYPE) eq 5

    ; If "0,1" indicates the distance between items 0 and 1,
    ; then distmatrix has the following form:
    ;
    ; [  1e30                                    ]
    ; [  0,1    1e30                             ]
    ; [  0,2    1,2    1e30                      ]
    ; [  0,3    1,3    2,3    1e30               ]
    ; [   .      .      .      .     .           ]
    ; [ 0,m-1  1,m-1  2,m-1   ...  m-2,m-1  1e30 ]
    ;
    ; The 1e30 are used so that the MIN doesn't return them.
    ;
    huge = dbl ? 1d300 : 1e30
    mx = MAX(pairdistance)
    if (mx gt huge) then $
        MESSAGE, 'Pairdistance values must be less than ' + STRTRIM(huge, 2)

    if (ndim eq 1) then begin
        ; Convert from compact vector form to matrix.
        distmatrix = REPLICATE(huge, m, m)
        ii = 0L
        for j=0,m-2 do begin
            nn = m - j - 1
            distmatrix[j,j+1:*] = pairdistance[ii:ii + nn - 1]
            ii += nn
        endfor
    endif else begin   ; already an array
        ; Replace upper half of matrix (and diagonal) with huge value.
        distmatrix = dbl ? DOUBLE(pairdistance) : FLOAT(pairdistance)
        for i=0,m-1 do $
            distmatrix[i:*, i] = huge
    endelse


    if (linkage eq 3) then begin
        dataDims = SIZE(data, /DIMENSIONS)
        if (N_ELEMENTS(dataDims) ne 2) || (dataDims[1] ne m) then $
            MESSAGE, 'For LINKAGE=3, DATA must be an n-by-m array, ' + $
            'where m is the number of items.'
        measure = (N_ELEMENTS(measureIn) eq 1) ? measureIn : 0
        if (N_ELEMENTS(powerIn) gt 0) then begin
            power = (N_ELEMENTS(powerIn) eq 1) ? $
                [powerIn, powerIn] : powerIn
            power = dbl ? DOUBLE(power) : FLOAT(power)
            measure = -1
        endif
        return, CLUSTER_TREE_CENTROID(distmatrix, data, linkdistance, $
            measure, power)
    endif


    result = LONARR(2, m-1)
    linkdistance = dbl ? DBLARR(m-1, /NOZERO) : FLTARR(m-1, /NOZERO)

    clusterid = LINDGEN(m)

    if (linkage eq 2) then $
        number = REPLICATE(1L, m)

    dim = m

    for node = m, 2, -1 do begin

        ; Given all of the distances between items (or clusters),
        ; find the smallest distance and join them. This doesn't
        ; depend upon the linkage method.
        linkdistance[m - node] = MIN(distmatrix, locmin)
        im = locmin/dim
        jm = locmin mod dim

        ; Compute the new distances between each cluster.
        ; This replaces the jm row/col with a combination of the
        ; jm and im row/col, using the selected linkage method.
        case linkage of

            0: begin   ; nearest-neighbor
                ; Find distance of the two closest objects in each cluster.
                if (jm gt 0) then $
                    distmatrix[0:jm-1, jm] <= distmatrix[0:jm-1, im]
                if (jm+1 le im-1) then $
                    distmatrix[jm, jm+1:im-1] <= distmatrix[jm+1:im-1, im]
                if (im+1 le node-1) then $
                    distmatrix[jm, im+1:node-1] <= distmatrix[im, im+1:node-1]
               end

            1: begin   ; furthest-neighbor
                ; Find distance of the two furthest objects in each cluster.
                if (jm gt 0) then $
                    distmatrix[0:jm-1, jm] >= distmatrix[0:jm-1, im]
                if (jm+1 le im-1) then $
                    distmatrix[jm, jm+1:im-1] >= distmatrix[jm+1:im-1, im]
                if (im+1 le node-1) then $
                    distmatrix[jm, im+1:node-1] >= distmatrix[im, im+1:node-1]
               end

            2: begin   ; weighted pairwise-average
                ; Find the average distance for all pairs of objects
                ; between each cluster, weighted by the number of
                ; objects in each cluster.
                sum = number[im] + number[jm]
                if (jm gt 0) then begin
                    distmatrix[0:jm-1, jm] = $
                        (distmatrix[0:jm-1, im]*number[im] + $
                        distmatrix[0:jm-1, jm]*number[jm])/sum
                endif
                if (jm+1 le im-1) then begin
                    distmatrix[jm, jm+1:im-1] = $
                        (distmatrix[jm+1:im-1, im]*number[im] + $
                        distmatrix[jm, jm+1:im-1]*number[jm])/sum
                endif
                if (im+1 le node-1) then begin
                    distmatrix[jm, im+1:node-1] = $
                        (distmatrix[im, im+1:node-1]*number[im] + $
                        distmatrix[jm, im+1:node-1]*number[jm])/sum
                endif
                ; Update number of elements in the clusters
                number[jm] = sum
                number[im] = number[node-1]
               end

        endcase

        ; The im row/col has been combined with jm,
        ; so now shift the last row/col into the im slot
        ; and shrink the matrix by 1 row/col.
        if (im ne node-1) then $
            distmatrix[0:im-1, im] = distmatrix[0:im-1, node-1]
        if (im+1 le node-2) then $
            distmatrix[im, im+1:node-2] = distmatrix[im+1:node-2, node-1]

        ; We no longer need the last row/column of distmatrix.
        ; There are two options: either resize the array,
        ; or fill in the last row with a huge value. Tests show
        ; that doing just one of these options is slower than a
        ; combined approach.
        ; 0.707 for each dim corresponds to 1/2 the amount of memory.
        if (node le 0.707*dim) then begin    ; shrink the array
            distmatrix = distmatrix[0:node-2, 0:node-2]
            dim = node - 1
        endif else begin    ; fill in big value
            distmatrix[0:node-2, node-1] = huge
        endelse

        result[0, m - node] = clusterid[im]
        result[1, m - node] = clusterid[jm]
        clusterid[jm] = 2*m - node
        clusterid[im] = clusterid[node - 1]

    endfor

    return, result
end

