; $Id: //depot/idl/releases/IDL_80/idldir/lib/dendrogram.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   DENDROGRAM
;
; PURPOSE:
;   Given a hierarchical tree cluster, as created by CLUSTER_TREE, the
;   DENDROGRAM procedure constructs a dendrogram and returns a set of
;   vertices and connectivity that can be used to visualize the dendrite plot.
;
; CALLING SEQUENCE:
;   DENDROGRAM, Clusters, Linkdistance, Outverts, Outconn
;
; INPUTS:
;   Clusters: A 2-by-(m-1) input array containing the cluster indices,
;       where m is the number of items in the original dataset.
;       This array is usually the result of the CLUSTER_TREE function.
;
;   Linkdistance: An (m-1)-element input vector containing the distances
;       between cluster items, as returned by the Linkdistance argument
;       to the CLUSTER_TREE function.
;
; OUTPUTS:
;   Outverts: Set this argument to a named variable which will contain
;       the [2, *] array of floating-point vertices making up the
;       dendrogram.
;
;   Outconn: Set this argument to a named variable which will contain
;       an output array of connectivity values.
;
; KEYWORD PARAMETERS:
;   LEAFNODES: Set this keyword to a named variable in which to return
;       a vector of integers giving the order of leaf nodes within the
;       dendrogram. The LEAFNODES keyword is useful for labeling the
;       nodes in a dendrite plot.
;
;
; EXAMPLE:
;    ; Given a set of points in two-dimensional space.
;    m = 20
;    data = 7*RANDOMN(-1, 2, m)
;
;    ; Compute the Euclidean distance between each point.
;    distance = DISTANCE_MEASURE(data)
;
;    ; Compute the cluster analysis.
;    clusters = CLUSTER_TREE(distance, linkdistance, LINKAGE=2)
;
;    ; Create the dendrogram.
;    DENDROGRAM, clusters, linkdistance, outverts, outconn, $
;        LEAFNODES=leafnodes
;
;    PRINT, STRTRIM(leafnodes, 2)
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Sept 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
; Recursive procedure used to reorder clusters.
;
; Cluster is a (2, m-1) array containing the cluster indices.
; Reorder is a m-element work array containing the current indices.
; Index is an integer giving the current index within Cluster.
;
; This algorithm starts from the end of the Cluster array (which is
; assumed to contain the topmost branch) and descends into the tree.
; Each time it finds a leaf node it stores its index within the Reorder
; array and increments the counter.
;
pro _cluster_reorder, cluster, reorder, index

    compile_opt idl2, hidden

    m = (SIZE(cluster, /DIM))[1] + 1

    c1 = cluster[0, index]
    c2 = cluster[1, index]

    ; Be sure the leftmost node in each cluster has the larger index,
    ; except if both are leaf nodes.
    ; This creates better-looking trees, where they tend to increase
    ; in height as one goes from left to right.
    iswitch = (c1 ge m || c2 ge m) ? (c2 gt c1) : (c1 gt c2)
    if (iswitch) then begin
        c1 = cluster[1, index]
        c2 = cluster[0, index]
    endif

    for i=0,1 do begin   ; Do left and right half
        clusId = (i ? c2 : c1)
        if (clusId ge m) then begin   ; This is a cluster
            ; Recursively call ourself on the cluster.
            _CLUSTER_REORDER, cluster, reorder, clusId - m
        endif else begin  ; This is a leaf node
            ; If we havn't already touched this node, set its reorder index.
            ; By using MAX + 1 we automatically increment our counter.
            if (reorder[clusId] lt 0) then $
                reorder[clusId] = MAX(reorder) + 1
        endelse
    endfor

end


;-------------------------------------------------------------------------
; Given an initial (2, m-1) array of cluster indices, calculate the
; permutation array needed to avoid any crossings in the dendrogram.
;
; On completion, Result will be an m-element vector containing
; the permutations. Result[i] contains an integer giving the new
; "location" of the i-th leaf node.
;
; This function also modifies Cluster to ensure that the leftmost
; node in each cluster has the smaller index.
;
; Example:
;   Assume we have 5 items, with cluster given by:
;   Cluster = [[ 4, 0 ]
;              [ 1, 5 ]
;              [ 2, 3 ]
;              [ 7, 6 ]]
;
;   After running this function,
;   Cluster = [[ 0, 4 ]
;              [ 1, 5 ]
;              [ 2, 3 ]
;              [ 6, 7 ]]
;   Result = [ 3, 4, 1, 0, 2 ]
;
;   The Result indicates that leaf node 0 should be placed at location 3,
;   node 1 should be placed at location 4, node 2 at location 1,
;   node 3 at location 0, and node 4 at location 2.
;
;   print, SORT(Result) will print out the node list in the
;   correct order to avoid crossings:
;          3           2           4           0           1
;
function cluster_reorder, cluster

    compile_opt idl2, hidden

    m = (SIZE(cluster, /DIM))[1] + 1
    reorder = REPLICATE(-1L, m)

    _CLUSTER_REORDER, cluster, reorder, m - 2

    return, reorder

end


;-------------------------------------------------------------------------
pro dendrogram, clusters, distance, outverts, outconn, $
    LEAFNODES=leafnodes

    compile_opt idl2

    ON_ERROR, 2

    if (N_PARAMS() lt 2) then $
        MESSAGE, 'Incorrect number of arguments.'

    dimC = SIZE(clusters, /DIMENSIONS)
    if (dimC[0] ne 2) then $
        MESSAGE, 'Clusters must be a 2-by-(m-1) array.'

    m = dimC[1] + 1

    mx = MAX(clusters, MIN=mn)
    if (mn lt 0) || (mx gt 2*m-3) then $
        MESSAGE, 'Cluster indices must be >= 0 and <= (2*m-3).'

    if (N_ELEMENTS(distance) lt (m-1)) then $
        MESSAGE, 'Linkdistance does not have enough elements.'
    dims = SIZE(distance, /DIMENSIONS)
    if (N_ELEMENTS(dims) gt 2) || $
        ((N_ELEMENTS(dims) eq 2) && (dims[0] ne 1)) then $
        MESSAGE, 'Linkdistance must be a vector or a one-column array.'

    dbl = SIZE(distance, /TYPE) eq 5

    ; Permutation array needed to avoid crossings in the dendrogram.
    reorder = CLUSTER_REORDER(clusters)
    if (ARG_PRESENT(leafnodes)) then $
        leafnodes = SORT(reorder)

    ; All leaf nodes start out at height=0.
    height = dbl ? DBLARR(2*m-1) : FLTARR(2*m-1)
    xlocation = height
    xlocation[0:m-1] = reorder
    outverts = dbl ? DBLARR(2, 4, m-1) : FLTARR(2, 4, m-1)

    for i=0,m-2 do begin
        ; Y location of each cluster.
        height[m + i] = distance[i]
        ; X location of each vertical line is the average of the
        ; two member locations.
        xlocation[m + i] = 0.5*TOTAL(xlocation[clusters[*,i]])
        outverts[0, *, i] = xlocation[clusters[[0, 0, 1, 1], i]]
        outverts[1, *, i] = [height[clusters[0,i]], height[m + i], $
            height[m + i], height[clusters[1,i]]]
    endfor

    ; Reform vertices to be a 2-by-nverts array.
    outverts = REFORM(outverts, 2, 4*(m-1))

    ; Each polyline is a set of 4 vertices.
    ; [4,0,1,2,3,  4,4,5,6,7,  4,8,9,10,11,  ...]
    outconn = REFORM([LONARR(1, m-1) + 4, LINDGEN(4, m-1)], 5*(m-1))

end

