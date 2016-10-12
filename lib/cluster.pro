; $Id: //depot/idl/releases/IDL_80/idldir/lib/cluster.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CLUSTER
;
; PURPOSE:
;       This function computes the classification of an M-column, N-row 
;       array, where M is the number of variables and N is the number of 
;       observations or samples. The classification is based upon a cluster
;       analysis of sample-based distances. The result is a 1-column, N-row
;       array of cluster number assignments that correspond to each sample.  
;
; CATEGORY:
;       Statistics
;
; CALLING SEQUENCE:
;       Result = Cluster(Array, Weights)
;
; INPUTS:
;       Array:    An M-column, N-row array of type float or double.
;
;     Weights:    An array of weights (the cluster centers) computed using 
;                 the CLUST_WTS function. The dimensions of this array vary 
;                 according to keyword values.
;
; KEYWORD PARAMETERS:
;             DOUBLE:  If set to a non-zero value, computations are done in
;                      double precision arithmetic.
;
;         N_CLUSTERS:  Use this keyword to specify the number of clusters.
;                      The default is based upon the row dimension of the
;                      Weights array.
;
; EXAMPLE:  
;       Define an array with 4 variables and 10 observations.
;         array = $
;           [[ 1.5, 43.1, 29.1,  1.9], $
;            [24.7, 49.8, 28.2, 22.8], $
;            [30.7, 51.9,  7.0, 18.7], $
;            [ 9.8,  4.3, 31.1,  0.1], $
;            [19.1, 42.2,  0.9, 12.9], $
;            [25.6, 13.9,  3.7, 21.7], $
;            [ 1.4, 58.5, 27.6,  7.1], $
;            [ 7.9,  2.1, 30.6,  5.4], $
;            [22.1, 49.9,  3.2, 21.3], $
;            [ 5.5, 53.5,  4.8, 19.3]]
;
;       Compute the cluster weights.
;         IDL> Weights = Clust_Wts(array)
;
;       Compute the classification of each sample.
;         IDL> result = CLUSTER(array, weights)
;
;       Print each sample (each row) of the array and its corresponding 
;       cluster assignment.
;       IDL> for k = 0, N_ELEMENTS(result)-1 do PRINT, $
;       IDL>   array(*,k), result(k), FORMAT = '(4(f4.1, 2x), 5x, i1)'
;
; REFERENCE:
;       CLUSTER ANALYSIS (Third Edition)
;       Brian S. Everitt
;       ISBN 0-340-58479-3
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, June 1996
;                    Adapted from an algorithm written by Robb Habbersett
;                    of Los Alamos National Laboratory.
;-

FUNCTION Cluster, Array, Weights, Double = Double, N_clusters = N_clusters

  ON_ERROR, 2

  Dimension = SIZE(Array)
  if Dimension[0] ne 2 then MESSAGE, "Input array must be a two-dimensional." 
 
  if N_ELEMENTS(Double) eq 0 then Double = (Dimension[Dimension[0]+1] eq 5)
  if Double eq 0 then Zero = 0.0 else Zero = 0.0d ;Type casting constant.

  if KEYWORD_SET(N_Clusters) eq 0 then N_Clusters = ((SIZE(Weights))[2])

  ;Work arrays.
  WorkRow = REPLICATE(1.0, 1, Dimension[1]) + Zero
  WorkCol = REPLICATE(1.0, 1, N_Clusters) + Zero

  ClusterNumber = LONARR(Dimension[2])

  for Sample = 0L, Dimension[2]-1 do begin
    Vector = Array[*,Sample] # WorkCol - Weights
    Metric = WorkRow # ABS(Vector)
    ClusterNumber[Sample] = (WHERE(Metric eq MIN(Metric)))[0]
  endfor 

  RETURN, TRANSPOSE(ClusterNumber)

END
