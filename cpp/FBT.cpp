//###############################################################################
//#                                                                             #
//#                Fast Bessel Transform (FBT) for TMDs                         #
//#     Zhongbo Kang, Alexei Prokudin, Nobuo Sato, John Terry                   #
//#                   Please cite ArXiv:1906.05949                              #
//#                  N is number of function calls                              #
//#                  nu is Bessel function order                                #
//###############################################################################
#define _USE_MATH_DEFINES // using M_PI for pi

#include <cmath> // abs
#include <math.h>
#include <stdio.h>
#include <iostream>
#include "FBT.h"


//acknowledgement
void FBT::acknowledgement(){
    std::cout << "###############################################################################" << std::endl;
    std::cout << "#                                                                             #" << std::endl;
    std::cout << "#                Fast Bessel Transform (FBT) for TMDs                         #" << std::endl;
    std::cout << "#     Zhongbo Kang, Alexei Prokudin, Nobuo Sato, John Terry                   #" << std::endl;
    std::cout << "#                   Please cite Kang:2019ctl                                  #" << std::endl;
    std::cout << "#                  N is number of function calls                              #" << std::endl;
    std::cout << "#                  nu is Bessel function order                                #" << std::endl;
    std::cout << "#                                                                             #" << std::endl;
    std::cout << "###############################################################################" << std::endl;
};




// Deconstructor
FBT::~FBT(){
  //jn_zeros0.~vector<double>();
};


// Constructor
FBT::FBT(double _nu, int _N, double _Q){
  if( _nu >= 0.){
    this->nu     = _nu;
  } else {
    std::cerr << " The value of nu = " << _nu << " is not supported." << std::endl;
    std::cerr << " Falling back to default  nu = " << FBT::nu_def << std::endl;
    this->nu     = FBT::nu_def;
  }

  if( _N >= 1){
    this->N     = _N;
  } else {
    std::cerr << " The value of N = " << _N << " is not supported." << std::endl;
    std::cerr << " Falling back to default  N = "  << FBT::N_def <<std::endl;
    this->N     = FBT::N_def;
  }


  if( _Q > 0){
    this->Q     = _Q;
  } else {
    std::cerr << " The value of Q = " << _Q << " is not supported." << std::endl;
    std::cerr << " Falling back to default  Q = "  << FBT::Q_def <<std::endl;
    this->Q     = FBT::Q_def;
  }

  // Sets maximum number of nodes to about 2^15:
  const int maxN = 32769;

  //Imports zeros of the Bessel function. Initializing this way speeds up calls
  try
  {
    boost::math::cyl_bessel_j_zero(this->nu, 1, maxN, std::back_inserter(jn_zeros0));
  }
  catch (std::exception& ex)
  {
    std::cout << "Thrown exception " << ex.what() << std::endl;
  }

  acknowledgement();

};

double get_psi( double t){
  return ( t )*tanh( M_PI/2.* sinh( t ) );
};

double get_psip( double t){
  return M_PI*t*( -pow(tanh( M_PI*sinh(t)/2.),2) + 1.)*cosh(t)/2. + tanh(M_PI*sinh(t)/2.);
};


double f_for_ogata(double x, double (*g)(double), double q){
  return g(x/q)/q;
};


//Transformed Ogata quadrature sum. Equation ? in the reference.
double FBT::ogatat(double (*f)(double), double q, double h){
  double nu = this->nu;
  int N = this->N;

  std::vector<double> zeros;
  zeros.resize(N); // Allocate N elements and copy from jn_zeros

  std::vector<double> xi;
  xi.resize(N);


  std::vector<double> Jp1;
  Jp1.resize(N);

  std::vector<double> w;
  w.resize(N);

  std::vector<double> knots;
  knots.resize(N);

  std::vector<double> Jnu;
  Jnu.resize(N);

  std::vector<double> psip;
  psip.resize(N);


  std::vector<double> F;
  F.resize(N);

  double val = 0;

  try{
    for (size_t i = 0; i < N; i++) {
      zeros[i] = jn_zeros0[i];
      xi[i] = zeros[i]/M_PI;
      Jp1[i] = boost::math::cyl_bessel_j(nu+1.,M_PI*xi[i]); //The functions cyl_bessel_j and cyl_neumann return the result of the Bessel functions of the first and second kinds respectively
      w[i] = boost::math::cyl_neumann(nu,M_PI*xi[i])/Jp1[i];
      knots[i] = M_PI/h*get_psi( h*xi[i] );
      Jnu[i] = boost::math::cyl_bessel_j(nu,knots[i]);
      double temp =  get_psip(h*xi[i]);

      if( isnan(temp) )
      {
        psip[i] = 1.;
      }
      else
      {
        psip[i] = temp;
      };
      F[i] = f_for_ogata(knots[i], f, q);
      val += M_PI*w[i]*F[i]*Jnu[i]*psip[i];


    }
  }
  catch (std::exception& ex)
  {
    std::cout << "Thrown exception " << ex.what() << std::endl;
  }

  return val;
};


//"""Untransformed Ogata quadrature sum. Equation ? in the reference."""
double FBT::ogatau(double (*f)(double), double q, double h){
  double nu = this->nu;
  int N = this->N;

  std::vector<double> zeros;
  zeros.resize(N); // Allocate N elements and copy from jn_zeros

  std::vector<double> xi;
  xi.resize(N);

  std::vector<double> Jp1;
  Jp1.resize(N);

  std::vector<double> w;
  w.resize(N);

  std::vector<double> knots;
  knots.resize(N);

  std::vector<double> F;
  F.resize(N);

  double val = 0;

  try
  {
    for (size_t i = 0; i < N; i++) {
      zeros[i] = jn_zeros0[i];
      xi[i] = zeros[i]/M_PI;
      Jp1[i]=boost::math::cyl_bessel_j(nu+1,M_PI*xi[i]);
      w[i]=boost::math::cyl_neumann(nu,M_PI*xi[i])/Jp1[i];
      knots[i] = xi[i]*h;
      F[i]=f_for_ogata(knots[i], f, q)*boost::math::cyl_bessel_j(nu,knots[i]);
      val+=h*w[i]*F[i];
    }
  }
  catch(std::exception& ex)
  {
    std::cout << "Thrown exception " << ex.what() << std::endl;
  }

  return val;
};

double f_for_get_hu(double x, double (*g)(double), double q){
   return -abs(x*g(x/q));
};

//"""Determines the untransformed hu by maximizing contribution to first node. Equation ? in ref."""
double FBT::get_hu(double (*f)(double), double q){
  double Q = this->Q;

  double zero1 = jn_zeros0[0];
  const int double_bits = std::numeric_limits<double>::digits;
  std::pair<double, double> r = boost::math::tools::brent_find_minima(std::bind(f_for_get_hu, std::placeholders::_1, f, q), Q/10., 10.*Q, double_bits);

  double hu = r.first/zero1;
  if(hu >= 3.){
    hu = 3.;
    std::cerr<< "Warning: Number of nodes is too small " << this->N << std::endl;
  }

  return hu;
};


double f_for_get_ht(double x, double hu, double zeroN){
  return hu-M_PI*tanh(M_PI/2.*sinh(x*zeroN/M_PI));
};

//"""Determine transformed ht from untransformed hu. Equation ? in ref."""
double FBT::get_ht(double hu){
  int N = this->N;

  double zeroN = double(jn_zeros0[N-1]);

  //ht = fsolve(lambda h: hu-np.pi*np.tanh(np.pi/2*np.sinh(h*zeroN/np.pi)),2*hu/np.pi/zeroN)[0]
  // double guess = 2.*hu/M_PI/zeroN;              // Rough guess is to divide the exponent by three.
  // double factor = 3.;                                 // How big steps to take when searching.
  //
  // const boost::uintmax_t maxit = 100;            // Limit to maximum iterations.
  // boost::uintmax_t it = maxit;                  // Initally our chosen max iterations, but updated with actual.
  // bool is_rising = true;                        // So if result if guess^3 is too low, then try increasing guess.
  // int digits = std::numeric_limits<double>::digits;  // Maximum possible binary digits accuracy for type T.
  //   // Some fraction of digits is used to control how accurate to try to make the result.
  // int get_digits = digits - 3;                  // We have to have a non-zero interval at each step, so
  //                                                 // maximum accuracy is digits - 1.  But we also have to
  //                                                 // allow for inaccuracy in f(x), otherwise the last few
  //                                                 // iterations just thrash around.
  // boost::math::tools::eps_tolerance<double> tol(get_digits);             // Set the tolerance.
  //
  //
  // try
  // {
  //   std::pair<double, double> r = boost::math::tools::bracket_and_solve_root(std::bind(f_for_get_ht, std::placeholders::_1, hu, zeroN), guess, factor, is_rising, tol, it);
  //   std::cout << "x is = " << r.first
  //   << ", f(" << r.first << ") = " << r.second << std::endl;
  //   double ht = r.first;
  //   return ht;
  // }
  // catch (std::exception& ex)
  // {
  //   std::cout << "Thrown exception " << ex.what() << std::endl;
  // }

  return 1./M_PI/zeroN*asinh(2./M_PI*atanh(hu/M_PI));


};



//"""Untransformed optimized Ogata."""
double FBT::fbtu(double (*g)(double), double q){
  double hu = get_hu(g,q);
  return ogatau(g,q,hu);
};




//"""Transformed optimized Ogata."""
double FBT::fbt(double (*g)(double), double q){
  double hu = get_hu(g,q);
  //std::cout << "hu= " << hu << std::endl;
  //ht = self.get_ht(hu,nu,N)
  double ht = get_ht(hu);
  //std::cout << "ht= " << ht << std::endl;
  //ht = 0.017708098719671984;
  return ogatat(g,q,ht);
};
