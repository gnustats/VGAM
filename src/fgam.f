c 24/8/99
c This is the original fgam.f file
c It needs to be compiled and loaded into R in order to smooth.

c All of this is automatically in Splus 


      subroutine vbsplvd ( t, k, x, left, a, dbiatx, nderiv )
      implicit double precision(a-h,o-z) 
calls bsplvb
calculates value and deriv.s of all b-splines which do not vanish at x
c
c******  i n p u t  ******
c  t     the knot array, of length left+k (at least)
c  k     the order of the b-splines to be evaluated
c  x     the point at which these values are sought
c  left  an integer indicating the left endpoint of the interval of
c        interest. the  k  b-splines whose support contains the interval
c               (t(left), t(left+1))
c        are to be considered.
c  a s s u m p t i o n  - - -  it is assumed that
c               t(left) .lt. t(left+1)
c        division by zero will result otherwise (in  b s p l v b ).
c        also, the output is as advertised only if
c               t(left) .le. x .le. t(left+1) .
c  nderiv   an integer indicating that values of b-splines and their
c        derivatives up to but not including the  nderiv-th  are asked
c        for. ( nderiv  is replaced internally by the integer in (1,k)
c        closest to it.)
c
c******  w o r k   a r e a  ******
c  a     an array of order (k,k), to contain b-coeff.s of the derivat-
c        ives of a certain order of the  k  b-splines of interest.
c
c******  o u t p u t  ******
c  dbiatx   an array of order (k,nderiv). its entry  (i,m)  contains
c        value of  (m-1)st  derivative of  (left-k+i)-th  b-spline of
c        order  k  for knot sequence  t , i=m,...,k; m=1,...,nderiv.
c
c******  m e t h o d  ******
c  values at  x  of all the relevant b-splines of order k,k-1,...,
c  k+1-nderiv  are generated via  bsplvb  and stored temporarily
c  in  dbiatx .  then, the b-coeffs of the required derivatives of the
c  b-splines of interest are generated by differencing, each from the
c  preceding one of lower order, and combined with the values of b-
c  splines of corresponding order in  dbiatx  to produce the desired
c  values.
c
      integer k,left,nderiv,   i,ideriv,il,j,jlow,jp1mid,kp1,kp1mm,
     *        ldummy,m,mhigh
      double precision a(k,k),dbiatx(k,nderiv),t(*),x
      double precision factor,fkp1mm,sum
      mhigh = max0(min0(nderiv,k),1)
c     mhigh is usually equal to nderiv.
      kp1 = k+1
      call bsplvb(t,kp1-mhigh,1,x,left,dbiatx)
      if (mhigh .eq. 1)                 go to 99
c     the first column of  dbiatx  always contains the b-spline values
c     for the current order. these are stored in column k+1-current
c     order  before  bsplvb  is called to put values for the next
c     higher order on top of it.
      ideriv = mhigh
      do 15 m=2,mhigh
         jp1mid = 1
         do 11 j=ideriv,k
            dbiatx(j,ideriv) = dbiatx(jp1mid,1)
            jp1mid = jp1mid + 1
   11    continue
         ideriv = ideriv - 1
         call bsplvb(t,kp1-ideriv,2,x,left,dbiatx)
   15    continue
c
c     at this point,  b(left-k+i, k+1-j)(x) is in  dbiatx(i,j) for
c     i=j,...,k and j=1,...,mhigh ('=' nderiv). in particular, the
c     first column of  dbiatx  is already in final form. to obtain cor-
c     responding derivatives of b-splines in subsequent columns, gene-
c     rate their b-repr. by differencing, then evaluate at  x.
c
      jlow = 1
      do 20 i=1,k
         do 19 j=jlow,k
            a(j,i) = 0d0
   19    continue
         jlow = i
         a(i,i) = 1d0
   20 continue
c     at this point, a(.,j) contains the b-coeffs for the j-th of the
c     k  b-splines of interest here.
c
c
c
c 20161111: was originally
c     do 40 m=2,mhigh
      do 400 m=2,mhigh
         kp1mm = kp1 - m
         fkp1mm = dble(kp1mm)
         il = left
         i = k
c
c        for j=1,...,k, construct b-coeffs of  (m-1)st  derivative of
c        b-splines from those for preceding derivative by differencing
c        and store again in  a(.,j) . the fact that  a(i,j) = 0  for
c        i .lt. j  is used.sed.
         do 25 ldummy=1,kp1mm
            factor = fkp1mm/(t(il+kp1mm) - t(il))
c           the assumption that t(left).lt.t(left+1) makes denominator
c           in  factor  nonzero.
            do 24 j=1,i
               a(i,j) = (a(i,j) - a(i-1,j))*factor
   24       continue
            il = il - 1
            i = i - 1
   25    continue
c
c        for i=1,...,k, combine b-coeffs a(.,i) with b-spline values
c        stored in dbiatx(.,m) to get value of  (m-1)st  derivative of
c        i-th b-spline (of interest here) at  x , and store in
c        dbiatx(i,m). storage of this value over the value of a b-spline
c        of order m there is safe since the remaining b-spline derivat-
c        ive of the same order do not use this value due to the fact
c        that  a(j,i) = 0  for j .lt. i .


c Originally:
c  30    do 40 i=1,k

         do 40 i=1,k
            sum = 0.
            jlow = max0(i,m)
            do 35 j=jlow,k
               sum = a(j,i)*dbiatx(j,m) + sum
   35       continue
            dbiatx(i,m) = sum
   40    continue
c 20161111: twyee added this line (expanded 40  to two lines).
  400 continue
   99                                   return
      end
      subroutine bsplvb ( t, jhigh, index, x, left, biatx )
      implicit double precision(a-h,o-z) 
calculates the value of all possibly nonzero b-splines at  x  of order
c
c               jout  =  dmax( jhigh , (j+1)*(index-1) )
c
c  with knot sequence  t .
c
c******  i n p u t  ******
c  t.....knot sequence, of length  left + jout  , assumed to be nonde-
c        creasing.  a s s u m p t i o n . . . .
c                       t(left)  .lt.  t(left + 1)   .
c   d i v i s i o n  b y  z e r o  will result if  t(left) = t(left+1)
c  jhigh,
c  index.....integers which determine the order  jout = max(jhigh,
c        (j+1)*(index-1))  of the b-splines whose values at  x  are to
c        be returned.  index  is used to avoid recalculations when seve-
c        ral columns of the triangular array of b-spline values are nee-
c        ded (e.g., in  bvalue  or in  vbsplvd ). precisely,
c                     if  index = 1 ,
c        the calculation starts from scratch and the entire triangular
c        array of b-spline values of orders 1,2,...,jhigh  is generated
c        order by order , i.e., column by column .
c                     if  index = 2 ,
c        only the b-spline values of order  j+1, j+2, ..., jout  are ge-
c        nerated, the assumption being that  biatx , j , deltal , deltar
c        are, on entry, as they were on exit at the previous call.
c           in particular, if  jhigh = 0, then  jout = j+1, i.e., just
c        the next column of b-spline values is generated.
c
c  w a r n i n g . . .  the restriction   jout .le. jmax (= 20)  is im-
c        posed arbitrarily by the dimension statement for  deltal  and
c        deltar  below, but is  n o w h e r e  c h e c k e d  for .
c
c  x.....the point at which the b-splines are to be evaluated.
c  left.....an integer chosen (usually) so that
c                  t(left) .le. x .le. t(left+1)  .
c
c******  o u t p u t  ******
c  biatx.....array of length  jout , with  biatx(i)  containing the val-
c        ue at  x  of the polynomial of order  jout  which agrees with
c        the b-spline  b(left-jout+i,jout,t)  on the interval (t(left),
c        t(left+1)) .
c
c******  m e t h o d  ******
c  the recurrence relation
c
c                       x - t(i)              t(i+j+1) - x
c     b(i,j+1)(x)  =  -----------b(i,j)(x) + ---------------b(i+1,j)(x)
c                     t(i+j)-t(i)            t(i+j+1)-t(i+1)
c
c  is used (repeatedly) to generate the (j+1)-vector  b(left-j,j+1)(x),
c  ...,b(left,j+1)(x)  from the j-vector  b(left-j+1,j)(x),...,
c  b(left,j)(x), storing the new values in  biatx  over the old. the
c  facts that
c            b(i,1) = 1  if  t(i) .le. x .lt. t(i+1)
c  and that
c            b(i,j)(x) = 0  unless  t(i) .le. x .lt. t(i+j)
c  are used. the particular organization of the calculations follows al-
c  gorithm  (8)  in chapter x of the text.
c
      parameter(jmax = 20)
      integer index,jhigh,left,   i,j,jp1
      double precision biatx(jhigh),t(*),x,   deltal(jmax)
      double precision deltar(jmax),saved,term
c     dimension biatx(jout), t(left+jout)
current fortran standard makes it impossible to specify the length of
c  t  and of  biatx  precisely without the introduction of otherwise
c  superfluous additional arguments.
      data j/1/
c     save j,deltal,deltar (valid in fortran 77)
c
c
c
c 20161111; originally: 
c                                       go to (10,20), index
c See https://www.obliquity.com/computer/fortran/control.html
      if (index .eq. 1) then
        go to 10
      else if (index .eq. 2) then
        go to 20
      end if
c
c
c
c
   10 j = 1
      biatx(1) = 1d0
      if (j .ge. jhigh)                 go to 99
c
   20    jp1 = j + 1
         deltar(j) = t(left+j) - x
         deltal(j) = x - t(left+1-j)
         saved = 0d0
         do 26 i=1,j
            term = biatx(i)/(deltar(i) + deltal(jp1-i))
            biatx(i) = saved + deltar(i)*term
            saved = deltal(jp1-i)*term
   26    continue
         biatx(jp1) = saved
         j = jp1
         if (j .lt. jhigh)              go to 20
c
   99                                   return
      end



c 20090105; converted bvalue into a subroutine.
      subroutine wbvalue ( t, bcoef, n, k, x, jderiv, bvalue)
      implicit double precision(a-h,o-z) 
      double precision bvalue
calls  vinterv
c
calculates value at  x  of  jderiv-th derivative of spline from b-repr.
c  the spline is taken to be continuous from the right.
c
c******  i n p u t ******
c  t, bcoef, n, k......forms the b-representation of the spline  f  to
c        be evaluated. specifically,
c  t.....knot sequence, of length  n+k, assumed nondecreasing.
c  bcoef.....b-coefficient sequence, of length  n .
c  n.....length of  bcoef  and dimension of s(k,t),
c        a s s u m e d  positive .
c  k.....order of the spline .
c
c  w a r n i n g . . .   the restriction  k .le. kmax (=20)  is imposed
c        arbitrarily by the dimension statement for  aj, dm, dm  below,
c        but is  n o w h e r e  c h e c k e d  for.
c
c  x.....the point at which to evaluate .
c  jderiv.....integer giving the order of the derivative to be evaluated
c        a s s u m e d  to be zero or positive.
c
c******  o u t p u t  ******
c  bvalue.....the value of the (jderiv)-th derivative of  f  at  x .
c
c******  m e t h o d  ******
c     the nontrivial knot interval  (t(i),t(i+1))  containing  x  is lo-
c  cated with the aid of  vinterv . the  k  b-coeffs of  f  relevant for
c  this interval are then obtained from  bcoef (or taken to be zero if
c  not explicitly available) and are then differenced  jderiv  times to
c  obtain the b-coeffs of  (d**jderiv)f  relevant for that interval.
c  precisely, with  j = jderiv, we have from x.(12) of the text that
c
c     (d**j)f  =  sum ( bcoef(.,j)*b(.,k-j,t) )
c
c  where
c                   / bcoef(.),                     ,  j .eq. 0
c                   /
c    bcoef(.,j)  =  / bcoef(.,j-1) - bcoef(.-1,j-1)
c                   / ----------------------------- ,  j .gt. 0
c                   /    (t(.+k-j) - t(.))/(k-j)
c
c     then, we use repeatedly the fact that
c
c    sum ( a(.)*b(.,m,t)(x) )  =  sum ( a(.,x)*b(.,m-1,t)(x) )
c  with
c                 (x - t(.))*a(.) + (t(.+m-1) - x)*a(.-1)
c    a(.,x)  =    ---------------------------------------
c                 (x - t(.))      + (t(.+m-1) - x)
c
c  to write  (d**j)f(x)  eventually as a linear combination of b-splines
c  of order  1 , and the coefficient for  b(i,1,t)(x)  must then
c  be the desired number  (d**j)f(x). (see x.(17)-(19) of text).
c
      parameter(kmax = 20)
      integer jderiv,k,n,   i,ilo,imk,j,jc,jcmin,jcmax,jj,km1,mflag,nmi
      double precision bcoef(n),t(*),x
      double precision aj(kmax),dm(kmax),dp(kmax),fkmj
c     dimension t(n+k)
current fortran standard makes it impossible to specify the length of
c  t  precisely without the introduction of otherwise superfluous
c  additional arguments.
      bvalue = 0.0d0
      if (jderiv .ge. k)                go to 99
c
c  *** find  i  s.t.  1 .le. i .lt. n+k  and  t(i) .lt. t(i+1) and
c      t(i) .le. x .lt. t(i+1) . if no such i can be found,  x  lies
c      outside the support of  the spline  f  and  bvalue = 0.
c      (the asymmetry in this choice of  i  makes  f  rightcontinuous)
      if( (x.ne.t(n+1)) .or. (t(n+1).ne.t(n+k)) )  go to 700
      i = n
                                        go to 701
  700 call vinterv ( t, n+k, x, i, mflag )
      if (mflag .ne. 0)                 go to 99
  701 continue
c  *** if k = 1 (and jderiv = 0), bvalue = bcoef(i).
      km1 = k - 1
      if (km1 .gt. 0)                   go to 1
      bvalue = bcoef(i)
                                        go to 99
c
c  *** store the k b-spline coefficients relevant for the knot interval
c     (t(i),t(i+1)) in aj(1),...,aj(k) and compute dm(j) = x - t(i+1-j),
c     dp(j) = t(i+j) - x, j=1,...,k-1 . set any of the aj not obtainable
c     from input to zero. set any t.s not obtainable equal to t(1) or
c     to t(n+k) appropriately.
    1 jcmin = 1
      imk = i - k
      if (imk .ge. 0)                   go to 8
      jcmin = 1 - imk
      do 5 j=1,i
         dm(j) = x - t(i+1-j)
    5 continue
      do 6 j=i,km1
         aj(k-j) = 0.
         dm(j) = dm(i)
    6 continue
                                        go to 10
    8 do 9 j=1,km1
         dm(j) = x - t(i+1-j)
    9 continue
c
   10 jcmax = k
      nmi = n - i
      if (nmi .ge. 0)                   go to 18
      jcmax = k + nmi
      do 15 j=1,jcmax
         dp(j) = t(i+j) - x
   15 continue
      do 16 j=jcmax,km1
         aj(j+1) = 0.
         dp(j) = dp(jcmax)
   16 continue
                                        go to 20
   18 do 19 j=1,km1
         dp(j) = t(i+j) - x
   19 continue
c
   20 do 21 jc=jcmin,jcmax
         aj(jc) = bcoef(imk + jc)
   21 continue
c
c               *** difference the coefficients  jderiv  times.
      if (jderiv .eq. 0)                go to 30
c 20161111; was:
c     do 23 j=1,jderiv
      do 233 j=1,jderiv
         kmj = k-j
         fkmj = dble(kmj)
         ilo = kmj
         do 23 jj=1,kmj
            aj(jj) = ((aj(jj+1) - aj(jj))/(dm(ilo) + dp(jj)))*fkmj
            ilo = ilo - 1
   23    continue
  233 continue
c
c  *** compute value at  x  in (t(i),t(i+1)) of jderiv-th derivative,
c     given its relevant b-spline coeffs in aj(1),...,aj(k-jderiv).
   30 if (jderiv .eq. km1)              go to 39
      jdrvp1 = jderiv + 1
c 20161111: was:
c     do 33 j=jdrvp1,km1
      do 34 j=jdrvp1,km1
         kmj = k-j
         ilo = kmj
         do 33 jj=1,kmj
            aj(jj) = (aj(jj+1)*dm(ilo) + aj(jj)*dp(jj))/(dm(ilo)+dp(jj))
            ilo = ilo - 1
   33    continue
   34 continue
   39 bvalue = aj(1)
c
   99                                   return
      end


      subroutine vinterv ( xt, lxt, x, left, mflag )
      implicit double precision(a-h,o-z) 
computes  left = max( i ; 1 .le. i .le. lxt  .and.  xt(i) .le. x )  .
c
c******  i n p u t  ******
c  xt.....a double precision sequence, of length  lxt , assumed to be nondecreasing
c  lxt.....number of terms in the sequence  xt .
c  x.....the point whose location with respect to the sequence  xt  is
c        to be determined.
c
c******  o u t p u t  ******
c  left, mflag.....both integers, whose value is
c
c   1     -1      if               x .lt.  xt(1)
c   i      0      if   xt(i)  .le. x .lt. xt(i+1)
c  lxt     1      if  xt(lxt) .le. x
c
c        in particular,  mflag = 0 is the 'usual' case.  mflag .ne. 0
c        indicates that  x  lies outside the halfopen interval
c        xt(1) .le. y .lt. xt(lxt) . the asymmetric treatment of the
c        interval is due to the decision to make all pp functions cont-
c        inuous from the right.
c
c******  m e t h o d  ******
c  the program is designed to be efficient in the common situation that
c  it is called repeatedly, with  x  taken from an increasing or decrea-
c  sing sequence. this will happen, e.g., when a pp function is to be
c  graphed. the first guess for  left  is therefore taken to be the val-
c  ue returned at the previous call and stored in the  l o c a l  varia-
c  ble  ilo . a first check ascertains that  ilo .lt. lxt (this is nec-
c  essary since the present call may have nothing to do with the previ-
c  ous call). then, if  xt(ilo) .le. x .lt. xt(ilo+1), we set  left =
c  ilo  and are done after just three comparisons.
c     otherwise, we repeatedly double the difference  istep = ihi - ilo
c  while also moving  ilo  and  ihi  in the direction of  x , until
c                      xt(ilo) .le. x .lt. xt(ihi) ,
c  after which we use bisection to get, in addition, ilo+1 = ihi .
c  left = ilo  is then returned.
c
      integer left,lxt,mflag,   ihi,ilo,istep,middle
      double precision x,xt(lxt)
      data ilo /1/
c     save ilo  (a valid fortran statement in the new 1977 standard)
      ihi = ilo + 1
      if (ihi .lt. lxt)                 go to 20
         if (x .ge. xt(lxt))            go to 110
         if (lxt .le. 1)                go to 90
         ilo = lxt - 1
         ihi = lxt
c
   20 if (x .ge. xt(ihi))               go to 40
      if (x .ge. xt(ilo))               go to 100
c
c              **** now x .lt. xt(ilo) . decrease  ilo  to capture  x .
c
c
c Originally:
c  30 istep = 1
      istep = 1
c
c
   31    ihi = ilo
         ilo = ihi - istep
         if (ilo .le. 1)                go to 35
         if (x .ge. xt(ilo))            go to 50
         istep = istep*2
                                        go to 31
   35 ilo = 1
      if (x .lt. xt(1))                 go to 90
                                        go to 50
c              **** now x .ge. xt(ihi) . increase  ihi  to capture  x .
   40 istep = 1
   41    ilo = ihi
         ihi = ilo + istep
         if (ihi .ge. lxt)              go to 45
         if (x .lt. xt(ihi))            go to 50
         istep = istep*2
                                        go to 41
   45 if (x .ge. xt(lxt))               go to 110
      ihi = lxt
c
c           **** now xt(ilo) .le. x .lt. xt(ihi) . narrow the interval.
   50 middle = (ilo + ihi)/2
      if (middle .eq. ilo)              go to 100
c     note. it is assumed that middle = ilo in case ihi = ilo+1 .
      if (x .lt. xt(middle))            go to 53
         ilo = middle
                                        go to 50
   53    ihi = middle
                                        go to 50
c**** set output and return.
   90 mflag = -1
      left = 1
                                        return
  100 mflag = 0
      left = ilo
                                        return
  110 mflag = 1
      left = lxt
                                        return
      end


c =====================================================================
c These two subroutines, dpbfa8 and dpbsl8, are called by sslvrg.
c Note: a rational cholesky version of these functions are available,
c called vdpbfa7 and vdpbsl7
c T.Yee 7/10/99 

c 1/7/02 
c T.Yee has renamed dbpbfa to dbpbfa8 and dpbsl to dpbsl8, to ensure uniqueness

      subroutine  dpbfa8(abd,lda,n,m,info)
      integer          lda,n,m,info
      double precision abd(lda,*)
c
c
c 20130419; Originally:
c     double precision abd(lda,1)
c
c
c
c
c     dpbfa8 factors a double precision symmetric positive definite
c     matrix stored in band form.
c
c     dpbfa8 is usually called by dpbco, but it can be called
c     directly with a saving in time if  rcond  is not needed.
c
c     on entry
c
c        abd     double precision(lda, n)
c                the matrix to be factored.  the columns of the upper
c                triangle are stored in the columns of abd and the
c                diagonals of the upper triangle are stored in the
c                rows of abd .  see the comments below for details.
c
c        lda     integer
c                the leading dimension of the array  abd .
c                lda must be .ge. m + 1 .
c
c        n       integer
c                the order of the matrix  a .
c
c        m       integer
c                the number of diagonals above the main diagonal.
c                0 .le. m .lt. n .
c
c     on return
c
c        abd     an upper triangular matrix  r , stored in band
c                form, so that  a = trans(r)*r .
c
c        info    integer
c                = 0  for normal return.
c                = k  if the leading minor of order  k  is not
c                     positive definite.
c
c     band storage
c
c           if  a  is a symmetric positive definite band matrix,
c           the following program segment will set up the input.
c
c                   m = (band width above diagonal)
c                   do 20 j = 1, n
c                      i1 = max0(1, j-m)
c                      do 10 i = i1, j
c                         k = i-j+m+1
c                         abd(k,j) = a(i,j)
c                10    continue
c                20 continue
c
c     linpack.  this version dated 08/14/78 .
c     cleve moler, university of new mexico, argonne national lab.
c
c     subroutines and functions
c
c     blas ddot
c     fortran max0,dsqrt
c
c     internal variables
c
      double precision ddot8,t
      double precision s
      integer          ik,j,jk,k,mu
c     begin block with ...exits to 40
c
c
         do 30 j = 1, n
            info = j
            s = 0.0d0
            ik = m + 1
            jk = max0(j-m,1)
            mu = max0(m+2-j,1)
            if (m .lt. mu) go to 20
            do 10 k = mu, m
               t = abd(k,j) - ddot8(k-mu,abd(ik,jk),1,abd(mu,j),1)
               t = t/abd(m+1,jk)
               abd(k,j) = t
               s = s + t*t
               ik = ik - 1
               jk = jk + 1
   10       continue
   20       continue
            s = abd(m+1,j) - s
c     ......exit
            if (s .le. 0.0d0) go to 40
            abd(m+1,j) = dsqrt(s)
   30    continue
         info = 0
   40 continue
      return
      end

      subroutine  dpbsl8(abd,lda,n,m,b)
      integer lda,n,m
      double precision abd(lda,*),b(*)
c
c
c 20130419; originally:
c     double precision abd(lda,1),b(1)
c
c
c     dpbsl8 solves the double precision symmetric positive definite
c     band system  a*x = b
c     using the factors computed by dpbco or dpbfa8.
c
c     on entry
c
c        abd     double precision(lda, n)
c                the output from dpbco or dpbfa8.
c
c        lda     integer
c                the leading dimension of the array  abd .
c
c        n       integer
c                the order of the matrix  a .
c
c        m       integer
c                the number of diagonals above the main diagonal.
c
c        b       double precision(n)
c                the right hand side vector.
c
c     on return
c
c        b       the solution vector  x .
c
c     error condition
c
c        a division by zero will occur if the input factor contains
c        a zero on the diagonal.  technically this indicates
c        singularity but it is usually caused by improper subroutine
c        arguments.  it will not occur if the subroutines are called
c        correctly and  info .eq. 0 .
c
c     to compute  inverse(a) * c  where  c  is a matrix
c     with  p  columns
c           call dpbco(abd,lda,n,rcond,z,info)
c           if (rcond is too small .or. info .ne. 0) go to ...
c           do 10 j = 1, p
c              call dpbsl8(abd,lda,n,c(1,j))
c        10 continue
c
c     linpack.  this version dated 08/14/78 .
c     cleve moler, university of new mexico, argonne national lab.
c
c     subroutines and functions
c
c     blas daxpy,ddot
c     fortran min0
c
c     internal variables
c
      double precision ddot8,t
      integer k,kb,la,lb,lm
c
c     solve trans(r)*y = b
c
      do 10 k = 1, n
         lm = min0(k-1,m)
         la = m + 1 - lm
         lb = k - lm
         t = ddot8(lm,abd(la,k),1,b(lb),1)
         b(k) = (b(k) - t)/abd(m+1,k)
   10 continue
c
c     solve r*x = y
c
      do 20 kb = 1, n
         k = n + 1 - kb
         lm = min0(k-1,m)
         la = m + 1 - lm
         lb = k - lm
         b(k) = b(k)/abd(m+1,k)
         t = -b(k)
         call daxpy8(lm,t,abd(la,k),1,b(lb),1)
   20 continue
      return
      end





