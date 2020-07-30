c------------------------------------------------------------------------------
c                                                                             c
c                Fast Bessel Transform (FBT) for TMDs                         c
c     Zhongbo Kang, Alexei Prokudin, Nobuo Sato, John Terry                   c
c                   Please cite ArXiv:1906.05949                              c
c                   f(b) is a function of b                                   c
c                      qT is trans momentum                                   c
c             1/Q is initial guess for the peak of f(b)                       c
c                  nu is Bessel function order                                c
c                                                                             c
c------------------------------------------------------------------------------

c------------------------------------------------------------------------------
c     The optimized Ogata quadrature subroutine
c------------------------------------------------------------------------------
      subroutine fbt(f,qT,Q,nu,z,n,res)
      implicit none
      real*8 qT,Q,z
      integer nu,n
      real*8 h
      real*8 res
      real*8, external :: f
      real*8 get_ht
      
      h=get_ht(f,nu,n,qT,Q)
      if (nu.eq.0) then
        call ogataJ0(f,h,n,qT,z,res)
      else if (nu.eq.1) then
        call ogataJ1(f,h,n,qT,z,res)
      end if
      return      

      end

c------------------------------------------------------------------------------
c     Obtains the optimal value for the spacing parameter
c------------------------------------------------------------------------------
      real*8 function get_ht(f,nu,N,qT,Q)
      implicit none
      real*8 J0,Q,dum,ht0,hu,ht,qT
      real*8, external :: solvehu,solvehup,get_hu,f
      integer nu,n,iters
      logical debug
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1

      if (nu.eq.0) then
            J0=J0zeros(n)
      elseif (nu.eq.1) then
            J0=J1zeros(n)
      endif
      hu = get_hu(f,qT,Q,nu)
      if (hu.gt.2d0) then
          hu = 2d0
      endif
      ht0=2d0*hu/(J0**2d0)
      dum=1.0d0
      debug=.true.

      call solven(solvehu,solvehup,ht0,hu,n,dum,ht,iters,debug,nu)
      get_ht=ht
      end

c------------------------------------------------------------------------------
c     Converts b dependent function to an x dependent function
c------------------------------------------------------------------------------
      real*8 function f2xf(f,qT,b)
      implicit none
      real*8 b,qT
      real*8, external :: f
      
      f2xf = b/qT*f(b/qT)

      end

c------------------------------------------------------------------------------
c     Obtains the optimized value for the spacing parameter hu
c------------------------------------------------------------------------------
      real*8 function get_hu(f,qT,Q,nu)
      implicit none
      real*8, external :: f,f2xf
      real*8 GOLDEN
      real*8 J0,Q,X1,X2,X3,TOL,qT,hu
      integer nu,n
      real*8 pi
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1

      pi = datan(1d0)*4d0
      
      if (nu.eq.0) then
            J0=J0zeros(1)
      elseif (nu.eq.1) then
            J0=J1zeros(1)
      endif
      
      X1=qT/Q/10d0; X2=qT/Q; X3=10d0*qT/Q
      TOL=1.d-2
      hu=GOLDEN(f,f2xf,X1,X2,X3,TOL,qT)/J0*pi
      if (hu.gt.2d0) then
          hu = 2d0
      endif
      get_hu = hu
      end

c------------------------------------------------------------------------------
c     Ogata quadrature for nu = 0
c------------------------------------------------------------------------------
      subroutine ogataJ0(f,h,N,qT,z,res)
      implicit none
      integer, intent(in) :: N
      real*8, intent(in) :: h,qT,z
      real*8, intent(out) :: res
      real*8, external :: f
      real*8 pi,knots,Jnu,xi,psi,psip,bessel0
      integer j
      external psi,psip,bessel0
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1
      
      pi = 3.141592653589793d0

      res=0d0
      if (N.gt.size(J0zeros)) then
        print *, 'N exceeds zeros'
      else
        do j = 1,N
          xi=J0zeros(j)/pi
          knots = pi/h*psi(h*xi)
          Jnu=bessel0(knots)
          res = res + 1d0/2d0*f(knots/qT*z)/qT*z*wJ0(j)*Jnu*psip(h*xi)
        end do
      end if
      return
      end subroutine ogataJ0

c------------------------------------------------------------------------------
c     Ogata quadrature for nu = 1
c------------------------------------------------------------------------------
      
      subroutine ogataJ1(f,h,N,qT,z,res)
      implicit none
      integer, intent(in) :: n
      real*8, intent(in) :: h,qT,z
      real*8, intent(out) :: res
      real*8 , external :: f,psi,psip,bessel1
      real*8 pi,knots,Jnu,xi
      real*8 w
      integer j
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1
      
      pi = 3.141592653589793d0

      res=0d0
      if (N.gt.size(J1zeros)) then
        print *, N, 'N exceeds zeros'
      else
        do j = 1,N
          xi=J1zeros(j)/pi
          knots = pi/h*psi(h*xi)
          Jnu=bessel1(knots)
          res = res + 1d0/2d0*f(knots/qT*z)/qT*z*wJ1(j)*Jnu*psip(h*xi)
        end do
      end if
      return
      end subroutine ogataJ1

c------------------------------------------------------------------------------
c     Integrands for bessel functions
c------------------------------------------------------------------------------
      real*8 function funb(theta,z)
      implicit none
      real*8, intent(in) :: theta
      real*8 z
      
      funb=dcos(z*dsin(theta))
      return
      end function

      real*8 function funb1(theta,z)
      implicit none
      real*8 z,theta
      funb1=dcos(z*dsin(theta)-theta)
      return
      end function
      

c------------------------------------------------------------------------------
c     Bessel function J0,J1
c------------------------------------------------------------------------------
      real*8 function bessel0(z) 
      IMPLICIT NONE
      real*8, intent(in) :: z
      real*8 pi
      integer nbel
      real*8, external :: funb,qgauss
      
      nbel=20
      pi = 3.14159265359d0

      bessel0=qgauss(funb,0d0, pi,nbel,z)/pi
      return
      end function

      real*8 function bessel1(z) 
      IMPLICIT NONE
      real*8, intent(in) :: z
      REAL*8  pi
      integer nbel
      real*8, external :: funb1,qgauss
      
      nbel=20
      pi = 3.14159265359d0
      
      bessel1=qgauss(funb1,0d0, pi,nbel,z)/pi
      return
      end function

      
c-----------------------------------------------------------------------
c     GOLDEN SEARCH METHOD
c-----------------------------------------------------------------------
      REAL*8 FUNCTION GOLDEN(F,f2xf,AX,BX,CX,TOL,qT)
      implicit none
      REAL*8 AX,BX,CX,TOL,X0,X1,X2,X3,R,C,F0,F1,F2,F3,qT
      real*8, external :: F,f2xf
      
      R=.61803399d0
      C=1d0-R
      X0=AX 
      X3=CX 
      IF(ABS(CX-BX).GT.ABS(BX-AX)) THEN
            X1=BX; X2=BX+C*(CX-BX)
      ELSE
            X2=BX; X1=BX-C*(BX-AX)
      ENDIF
      F1=f2xf(f,qT,X1); F2=f2xf(f,qT,X2)
1     IF(ABS(X3-X0).GT.TOL*(ABS(X1)+ABS(X2))) THEN
            IF(F2.GT.F1) THEN
                  X0=X1; X1=X2
                  X2=R*X1+C*X3
                  F0=F1; F1=F2
                  F2=f2xf(f,qT,X2)
            ELSE
                  X3=X2; X2=X1
                  X1=R*X2+C*X0
                  F3=F2; F2=F1
                  F1=f2xf(f,qT,X1)
            ENDIF
            GOTO 1
      ENDIF
      IF(F1.GT.F2) THEN
            GOLDEN=X1
      ELSE
            GOLDEN=X2
      ENDIF
      RETURN
      END

c------------------------------------------------------------------------------
c     Newton's numerical method
c------------------------------------------------------------------------------      
      subroutine solven(f,fp,ht0,hu,n,dum,ht,iters,debug,nu)
      implicit none
      real*8, intent(in) :: ht0,hu,dum
      integer, intent(in) :: nu,n
      real*8, external :: f,fp
      logical, intent(in) :: debug
      real*8, intent(out) :: ht
      integer, intent(out) :: iters

      real*8 :: deltax, fx, fxprime,tol
      integer :: k,maxiter
          
      maxiter = 20
      tol = 1.d-14
      ht = ht0
      if (debug) then
            endif
      do k=1,maxiter
            fx = f(hu,n,dum,ht,nu)
            fxprime = fp(n,dum,ht,nu)
            if (abs(fx) < tol) then
                  exit
                  endif
            deltax = fx/fxprime
            ht = ht - deltax
            if (ht.LT.0d0) then
                  ht=0d0
            endif

            if (debug) then
            endif
      enddo
      if (k > maxiter) then
            fx = f(hu,n,dum,ht,nu)
            if (abs(fx) > tol) then
            endif
      endif 
      iters = k-1
      end
      
c------------------------------------------------------------------------------
c     Used to determine the spacing parameters
c------------------------------------------------------------------------------
      real*8 function solvehu(hu,n,dum,ht,nu)
      implicit none
      real*8, intent(in) :: ht,dum,hu
      integer, intent(in) :: nu,n
      real*8 J0,pi
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1

      if (nu .eq. 0) then
         J0 = J0zeros(n)
      else if (nu .eq. 1) then
         J0 = J1zeros(n)
      end if
      pi = 3.141592653589793d0
      solvehu= hu/pi-dtanh(pi/2d0*dsinh(ht*J0/pi))
      end

      real*8 function solvehup(n,dum,ht,nu)
      implicit none
      real*8, intent(in) :: ht,dum
      integer, intent(in) :: nu,n
      real*8 J0,pi
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      common /nodes/ J0zeros,J1zeros,wJ0,wJ1
        
      if (nu .eq. 0) then
         J0 = J0zeros(n)
      else if (nu .eq. 1) then
         J0 = J1zeros(n)
      end if
      pi = 3.141592653589793d0
        
      solvehup = -J0/2d0*dcosh(ht*J0/pi)*
     >    (dcosh(pi/2d0*dsinh(ht*J0/pi)))**(-2d0)

      end
      
c------------------------------------------------------------------------------
c   Auxiliary functions for ogata integration
c------------------------------------------------------------------------------
      function psi(t)
      real*8 t,psi
        psi=t*tanh(1.5707963267948966d0*sinh(t))
      end function

      function psip(t)
      real*8::psip,t,argum
        if(t>4d0) then ! Psi'(t) is basically 1 for t>4 or even less
           psip=1d0
        else    ! For smaller values we proeprly define it
           argum=3.141592653589793d0*sinh(t)
           psip=(3.141592653589793d0*t*cosh(t)+sinh(argum))
     >          /(1d0+cosh(argum))
        end if
      end function

c------------------------------------------------------------------------------
c Numerical gaussian quadrature
c------------------------------------------------------------------------------
      real*8 function qgauss(f,xi,xf,n,z)
      implicit none
      real*8 f,xi,xf,xn,value,x1,x2,z,val
      integer i,n
      external f

      if(n.le.1) then           ! same as n=1
         x1=xi
         x2=xf
         call gauss(f,x1,x2,z,val)
         qgauss=val
         return
      endif
    
      xn=(xf-xi)/float(n)
      value=0d0
      x2=xi
      Do 100 i=1,n
         x1=x2
         x2=x1+xn
         call gauss(f,x1,x2,z,val)
         value=value+val
 100  continue

      qgauss=value
      return
      end function

      subroutine gauss(f,xi,xf,z,value)
      implicit none
      real*8 f,xi,xf,value,xm,xr,dx,x(8),w(8)
      real*8 eps,z
      external f
      integer j
      data eps /1.0d-25/
      data w
     1   / 0.02715 24594 11754 09485 17805 725D0,
     2     0.06225 35239 38647 89286 28438 370D0,
     3     0.09515 85116 82492 78480 99251 076D0,
     4     0.12462 89712 55533 87205 24762 822D0,
     5     0.14959 59888 16576 73208 15017 305D0,
     6     0.16915 65193 95002 53818 93120 790D0,
     7     0.18260 34150 44923 58886 67636 680D0,
     8     0.18945 06104 55068 49628 53967 232D0 /
      DATA X
     1   / 0.98940 09349 91649 93259 61541 735D0,
     2     0.94457 50230 73232 57607 79884 155D0,
     3     0.86563 12023 87831 74388 04678 977D0,
     4     0.75540 44083 55003 03389 51011 948D0,
     5     0.61787 62444 02643 74844 66717 640D0,
     6     0.45801 67776 57227 38634 24194 430D0,
     7     0.28160 35507 79258 91323 04605 015D0,
     8     0.09501 25098 37637 44018 53193 354D0 /
      
      xm=0.5d0*(xf+xi)
      xr=0.5d0*(xf-xi)
      if (abs(xr).lt.eps) print *,
     >     'WARNING: Too high accuracy required for QGAUSS!'
 
      value=0d0

      Do 100 j=1,8
         dx=xr*x(j)
         value=value+w(j)*(f(xm+dx,z)+f(xm-dx,z))
 100  continue
	
      value=xr*value
      return
      end subroutine

      BLOCK DATA
      IMPLICIT NONE
      real*8 J0zeros(98),J1zeros(98),wJ0(98),wJ1(98)
      data J0zeros/ 2.404825557695773d0, 5.5200781102863115d0,
     >               8.653727912911013d0, 11.791534439014281d0,
     >               14.930917708487787d0, 18.071063967910924d0,
     >               21.21163662987926d0, 24.352471530749302d0,
     >               27.493479132040253d0, 30.634606468431976d0,
     >               33.77582021357357d0, 36.917098353664045d0,
     >               40.05842576462824d0, 43.19979171317673d0,
     >               46.341188371661815d0, 49.482609897397815d0,
     >               52.624051841115d0, 55.76551075501998d0,
     >               58.90698392608094d0, 62.048469190227166d0,
     >               65.18996480020687d0, 68.3314693298568d0,
     >               71.47298160359374d0, 74.61450064370183d0,
     >               77.75602563038805d0, 80.89755587113763d0,
     >               84.0390907769382d0, 87.18062984364116d0,
     >               90.32217263721049d0, 93.46371878194478d0,
     >               96.60526795099626d0, 99.7468198586806d0,
     >               102.8883742541948d0, 106.02993091645162d0,
     >               109.17148964980538d0, 112.3130502804949d0,
     >               115.45461265366694d0, 118.59617663087253d0,
     >               121.73774208795096d0, 124.87930891323295d0,
     >               128.02087700600833d0, 131.1624462752139d0,
     >               134.30401663830546d0, 137.44558802028428d0,
     >               140.58716035285428d0, 143.72873357368974d0,
     >               146.87030762579664d0, 150.01188245695477d0,
     >               153.1534580192279d0,  156.2950342685335d0,
     >               159.4366111642632d0, 162.5781886689467d0,
     >               165.719766747955d0, 168.8613453692358d0,
     >               172.0029245030782d0, 175.1445041219027d0,
     >               178.2860842000738d0, 181.427664713731d0,
     >               184.5692456406387d0, 187.7108269600494d0,
     >               190.8524086525815d0, 193.9939907001091d0,
     >               197.1355730856614d0, 200.2771557933324d0,
     >               203.4187388081986d0, 206.5603221162445d0,
     >               209.7019057042941d0, 212.8434895599495d0,
     >               215.985073671534d0, 219.1266580280406d0,
     >               222.2682426190843d0, 225.4098274348594d0,
     >               228.5514124660988d0, 231.6929977040386d0,
     >               234.8345831403832d0, 237.9761687672757d0,
     >               241.117754577268d0, 244.2593405632957d0,
     >               247.4009267186528d0, 250.5425130369699d0,
     >               253.6840995121931d0, 256.8256861385644d0,
     >               259.9672729106045d0, 263.1088598230955d0,
     >               266.2504468710659d0, 269.392034049776d0,
     >               272.5336213547049d0, 275.6752087815374d0,
     >               278.8167963261531d0, 281.9583839846149d0,
     >               285.0999717531595d0, 288.2415596281877d0,
     >               291.3831476062552d0, 294.524735684065d0,
     >               297.666323858459d0, 300.8079121264111d0,
     >               303.9495004850206d0, 307.091088931505d0 /
      data wJ0 /     0.9822341167218513d0, 0.996095171243873d0,
     >               0.9983661220824326d0, 0.9991115104807027d0,
     >               0.9994434412453229d0, 0.9996191732821181d0,
     >               0.9997232113735499d0, 0.9997898172483115d0,
     >               0.9998349989971018d0, 0.9998670439582888d0,
     >               0.9998905896964104d0, 0.9999083950665695d0,
     >               0.9999221843802542d0, 0.9999330801564746d0,
     >               0.9999418385663339d0, 0.9999489840430771d0,
     >               0.9999548895439107d0, 0.9999598261634556d0,
     >               0.9999639947771565d0, 0.999967546784798d0,
     >               0.9999705980425174d0, 0.9999732384242627d0,
     >               0.9999755385120204d0, 0.9999775543594231d0,
     >               0.9999793309376261d0, 0.9999809046641152d0,
     >               0.9999823052831136d0, 0.9999835572808426d0,
     >               0.9999846809626194d0, 0.9999856932810783d0,
     >               0.99998660847913d0, 0.9999874385935336d0,
     >               0.9999881938525907d0, 0.9999888829926477d0,
     >               0.9999895135118083d0, 0.9999900918747109d0,
     >               0.9999906236788553d0, 0.9999911137905217d0,
     >               0.9999915664564617d0, 0.9999919853961932d0,
     >               0.9999923738786343d0, 0.9999927347860547d0,
     >               0.9999930706676811d0, 0.9999933837848324d0,
     >               0.9999936761490745d0, 0.9999939495546002d0,
     >               0.9999942056058223d0, 0.9999944457409604d0,
     >               0.999994671252277d0,  0.999994883303502d0,
     >               0.999995082944868d0, 0.999995271126144d0,
     >               0.999995448707946d0, 0.999995616471599d0,
     >               0.999995775127738d0, 0.999995925323851d0,
     >               0.999996067650893d0, 0.999996202649105d0,
     >               0.999996330813154d0, 0.999996452596662d0,
     >               0.999996568416235d0, 0.999996678655019d0,
     >               0.999996783665882d0, 0.999996883774239d0,
     >               0.99999697928057d0, 0.999997070462687d0,
     >               0.999997157577747d0, 0.999997240864074d0,
     >               0.999997320542786d0, 0.999997396819268d0,
     >               0.999997469884493d0, 0.999997539916221d0,
     >               0.999997607080081d0, 0.999997671530547d0,
     >               0.999997733411836d0, 0.999997792858705d0,
     >               0.999997849997193d0, 0.999997904945284d0,
     >               0.999997957813523d0, 0.999998008705565d0,
     >               0.999998057718689d0, 0.999998104944259d0,
     >               0.999998150468157d0, 0.999998194371164d0,
     >               0.999998236729325d0, 0.99999827761428d0,
     >               0.99999831709356d0, 0.999998355230872d0,
     >               0.999998392086355d0, 0.999998427716816d0,
     >               0.99999846217595d0, 0.999998495514541d0,
     >               0.999998527780652d0, 0.999998559019795d0,
     >               0.999998589275093d0, 0.99999861858743d0,
     >               0.999998646995588d0, 0.999998674536377d0 /
      data J1zeros/ 3.831705970207515d0, 7.015586669815619d0,
     >               10.17346813506272d0, 13.32369193631422d0,
     >               16.47063005087763d0, 19.61585851046824d0,
     >               22.76008438059277d0, 25.90367208761838d0,
     >               29.04682853491686d0, 32.18967991097440d0,
     >               35.33230755008387d0, 38.47476623477162d0,
     >               41.61709421281445d0, 44.75931899765282d0,
     >               47.90146088718545d0, 51.04353518357151d0,
     >               54.18555364106132d0, 57.32752543790101d0,
     >               60.46945784534749d0, 63.61135669848123d0,
     >               66.75322673409849d0, 69.89507183749577d0,
     >               73.03689522557383d0, 76.17869958464146d0,
     >               79.32048717547630d0, 82.46225991437356d0,
     >               85.60401943635023d0, 88.74576714492631d0,
     >               91.88750425169499d0, 95.02923180804470d0,
     >               98.17095073079078d0, 101.3126618230387d0,
     >               104.4543657912828d0, 107.5960632595092d0,
     >               110.7377547808992d0, 113.8794408475950d0,
     >               117.0211218988924d0, 120.1627983281490d0,
     >               123.3044704886357d0, 126.4461386985166d0,
     >               129.5878032451040d0, 132.7294643885096d0,
     >               135.8711223647890d0, 139.0127773886597d0,
     >               142.1544296558590d0, 145.2960793451959d0,
     >               148.4377266203422d0, 151.5793716314014d0, 
     >               154.7210145162859d0, 157.8626554019303d0,
     >               161.004294405362d0, 164.1459316346496d0,
     >               167.2875671897441d0, 170.4292011632266d0,
     >               173.5708336409759d0, 176.7124647027638d0,
     >               179.8540944227884d0, 182.995722870153d0,
     >               186.1373501092955d0, 189.278976200376d0,
     >               192.4206011996257d0, 195.5622251596626d0,
     >               198.703848129777d0, 201.8454701561909d0,
     >               204.9870912822923d0, 208.1287115488501d0,
     >               211.2703309942078d0, 214.411949654462d0,
     >               217.5535675636242d0, 220.6951847537693d0,
     >               223.8368012551717d0, 226.9784170964295d0,
     >               230.1200323045791d0, 233.2616469052006d0,
     >               236.4032609225143d0, 239.5448743794699d0,
     >               242.6864872978287d0, 245.8280996982398d0,
     >               248.9697116003099d0, 252.1113230226686d0,
     >               255.2529339830282d0, 258.3945444982395d0,
     >               261.5361545843441d0, 264.6777642566215d0,
     >               267.8193735296346d0, 270.9609824172707d0,
     >               274.1025909327807d0, 277.2441990888146d0,
     >               280.3858068974556d0, 283.5274143702514d0,
     >               286.6690215182434d0, 289.8106283519944d0,
     >               292.9522348816139d0, 296.0938411167825d0,
     >               299.2354470667741d0, 302.3770527404775d0,
     >               305.5186581464156d0, 308.6602632927644d0 /

      data wJ1 /1.024227862988153d0, 1.007484900740163d0,
     >          1.003591661601918d0, 1.002101534013120d0,
     >          1.001377624501808d0, 1.000972229884043d0,
     >          1.000722609013146d0, 1.000558091359549d0,
     >          1.000443969837702d0, 1.000361581733231d0,
     >          1.000300166437122d0, 1.000253165757646d0,
     >          1.000216397983523d0, 1.000187094702657d0,
     >          1.000163364094007d0, 1.000143877784342d0,
     >          1.000127680845352d0, 1.000114072546103d0,
     >          1.000102529275468d0, 1.000092653414260d0,
     >          1.000084138632451d0, 1.000076745846615d0,
     >          1.000070286252988d0, 1.000064609152695d0,
     >          1.000059593082468d0, 1.000055139263616d0,
     >          1.000051166701738d0, 1.000047608478371d0,
     >          1.000044408914384d0, 1.000041521378558d0,
     >          1.000038906578913d0, 1.000036531218989d0,
     >          1.000034366932616d0, 1.000032389433129d0,
     >          1.000030577829061d0, 1.000028914070107d0,
     >          1.000027382495762d0, 1.000025969465459d0,
     >          1.000024663053802d0, 1.000023452798128d0,
     >          1.000022329488376d0, 1.000021284991350d0,
     >          1.000020312103081d0, 1.000019404424289d0,
     >          1.000018556254875d0, 1.000017762504217d0,
     >          1.000017018614614d0, 1.000016320495705d0,
     >          1.00001566446813d0, 1.000015047214946d0,
     >          1.000014465739621d0, 1.000013917329595d0,
     >          1.000013399524593d0, 1.000012910088977d0,
     >          1.000012446987581d0, 1.000012008364517d0,
     >          1.00001159252455d0, 1.0000111979167d0,
     >          1.000010823119756d0, 1.000010466829458d0,
     >          1.000010127847142d0, 1.00000980506964d0,
     >          1.000009497480294d0, 1.000009204140945d0,
     >          1.000008924184763d0, 1.000008656809847d0,
     >          1.000008401273464d0, 1.000008156886894d0,
     >          1.000007923010783d0, 1.000007699050954d0,
     >          1.000007484454633d0, 1.000007278707033d0,
     >          1.000007081328264d0, 1.000006891870531d0,
     >          1.000006709915595d0, 1.000006535072464d0,
     >          1.000006366975284d0, 1.000006205281428d0,
     >          1.00000604966975d0, 1.000005899838986d0,
     >          1.000005755506299d0, 1.000005616405937d0,
     >          1.000005482288016d0, 1.000005352917391d0,
     >          1.000005228072626d0, 1.000005107545051d0,
     >          1.000004991137881d0, 1.000004878665419d0,
     >          1.000004769952313d0, 1.000004664832868d0,
     >          1.000004563150422d0, 1.000004464756758d0,
     >          1.00000436951156d0, 1.00000427728192d0,
     >          1.000004187941865d0, 1.000004101371937d0,
     >          1.000004017458786d0, 1.000003936094799d0 /

      common /nodes/ J0zeros,J1zeros,wJ0,wJ1

      end



