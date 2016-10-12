;$Id: //depot/idl/releases/IDL_80/idldir/lib/primes.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       PRIMES
;
; PURPOSE:
;       This function computes the first K prime numbers. The result is a 
;       K-element vector of type long integer.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = Primes(K)
;
; INPUTS:
;       K:    A scalar of type integer or long integer that specifies the 
;             number of primes to be computed.
;
; EXAMPLE:
;       Compute the first 25 prime numbers.
;         result = primes(25)
;
;       The result should be:
;         [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, $
;          53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
;
; REFERENCE:
;       PROBABILITY and STATISTICS for ENGINEERS and SCIENTISTS (3rd edition)
;       Ronald E. Walpole & Raymond H. Myers
;       ISBN 0-02-424170-9
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, November 1994
;                    S. Lett, RSI, December 1997, added support for k=1
;-

function primes, k

  ;Compute the first k prime numbers.

  IF (k EQ 1) THEN RETURN, [2L]
  prm = lonarr(k)

  prm[0] = 2L
  n = 3L
  count = 1L
  prm[count] = 3L

  case2: count = count + 1L

  while(count lt k) do begin
    case1:
    n = n + 2L

    for ip = 1L, count do begin
      q = n / prm[ip]
      r = n mod prm[ip]
      if r eq 0 then goto, case1  ;n is not prime.

      if q le prm[ip] then begin  ;n is prime.
        prm[count] = n
        goto, case2               ;compute next prime.
      endif

    endfor 

  endwhile

  return, prm
  prm = 0

end
