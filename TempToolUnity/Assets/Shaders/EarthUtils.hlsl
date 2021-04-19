#ifndef EARTH_UTILS_INCLUDED
#define EARTH_UTILS_INCLUDED

static const float EARTH_A = 6378.137;
static const float EARTH_F = 1.0/298.257223563;
static const float EARTH_B = EARTH_A * ( 1.0 - EARTH_F );
static const float EARTH_Esq = 1 - (EARTH_B * EARTH_B) / (EARTH_A * EARTH_A);
static const float EARTH_Ecc = sqrt(EARTH_Esq);

float3 radcur(float lati)
/*
compute the radii at the geodetic latitude lat (in radians)

input:
lat       geodetic latitude in radians
output:   
rrnrm     a float3
r,  rn,  rm   in km
*/
{
    float  a,b,lat;
    float  asq,bsq,eccsq,ecc,clat,slat;
    float  dsq,d,rn,rm,rho,rsq,r,z;

    a     = EARTH_A;
    b     = EARTH_B;

    asq   = a*a;
    bsq   = b*b;
    eccsq  =  1 - bsq/asq;
    ecc = sqrt(eccsq);

    lat   =  lati;

    clat  =  cos(lat);
    slat  =  sin(lat);

    dsq   =  1.0 - eccsq * slat * slat;
    d     =  sqrt(dsq);

    rn    =  a/d;
    rm    =  rn * (1.0 - eccsq ) / dsq;

    rho   =  rn * clat;
    z     =  (1.0 - eccsq ) * rn * slat;
    rsq   =  rho*rho + z*z;
    r     =  sqrt( rsq );

    return float3(r, rn, rm);
}

//        physical radius of earth from geodetic latitude
float rearth(float lati)
{
    return radcur(lati).x;
}

float  gc2gd(float flatgc, float altkm)
/*        geocentric latitude to geodetic latitude
Input:
flatgc    geocentric latitude in radians
altkm     altitide in km
ouput:
flatgd    geodetic latitude in radians
*/
{
    float  flatgr;
    float  re,rn,ecc, esq;
    float  slat,clat,tlat;
    float  altnow,ratio;
    
    ecc   =  EARTH_Ecc;
    esq   =  EARTH_Esq;

    //             approximation by stages
    //             1st use gc-lat as if is gd, then correct alt dependence

    altnow  =  altkm;

    float3 rrnrm   =  radcur(flatgc);
    rn      =  rrnrm.y;
    ratio   = 1 - esq*rn/(rn+altnow);
    tlat    = tan(flatgc) / ratio;
    flatgr  = atan(tlat);

    //        now use this approximation for gd-lat to get rn etc.

    rrnrm   =  radcur(flatgr);
    rn      =  rrnrm[1];

    ratio   =  1  - esq*rn/(rn+altnow);
    tlat    =  tan(flatgc)/ratio;
    flatgr  =  atan(tlat);

    return  flatgr;
}

float gd2gc(float flatgr, float altkm)
/*        geodetic latitude to geocentric latitude

Input:
flatgr    geodetic latitude in radians
altkm     altitide in km
ouput:
flatgc    geocentric latitude in radians

*/
{
    float flatgc;
    float re,rn,ecc, esq;
    float slat,clat,tlat;
    float altnow,ratio;
    
    ecc   =  EARTH_Ecc;
    esq   =  EARTH_Esq;

    altnow  =  altkm;

    float3 rrnrm   =  radcur(flatgr);
    rn = rrnrm.y;
    
    ratio   = 1 - esq*rn/(rn+altnow);

    tlat    = tan(flatgr) * ratio;
    flatgc  = atan(tlat);

    return  flatgc;
}

float3 llhxyz(float flat, float flon, float altkm)

/*        lat,lon,height to xyz vector

input:
flat      geodetic latitude in radians
flon      longitude in radians
altkm     altitude in km
output:
returns vector x 3 long ECEF in km

*/
{
    float  clat,clon,slat,slon;
    float  rn,esq,re,ecc;
    float  x,y,z;

    clat = cos(flat);
    slat = sin(flat);
    clon = cos(flon);
    slon = sin(flon);
    
    float3 rrnrm  = radcur (flat);
    rn     = rrnrm.y;
    re     = rrnrm.x;

    ecc    = EARTH_Ecc;
    esq    = EARTH_Esq;

    x      =  (rn + altkm) * clat * clon;
    y      =  (rn + altkm) * clat * slon;
    z      =  ( (1-esq)*rn + altkm ) * slat;

    return float3(x, y, z);
}

float3 xyzllh (float3 xvec)

/*        xyz vector  to  lat,lon,height

input:
xvec[3]   xyz ECEF location
output:

llhvec[3] with components

flat      geodetic latitude in radians (-pi/2 -> pi/2)
flon      longitude in radians (-pi -> pi)
altkm     altitude in km

*/

{
    float  flatgc,flatn,dlat;
    float  rnow,rp;
    float  x,y,z,p;
    float  tangc,tangd;

    float  testval,kount;

    float  rn,esq;
    float  clat,slat;

    float  flat,flon,altkm;

    esq    =  EARTH_Esq;

    x      = xvec.x;
    y      = xvec.y;
    z      = xvec.z;

    //rp     = sqrt( x*x + y*y + z*z );
    rp     = dot(xvec, xvec);

    flatgc = asin(z / rp);

    testval = abs(x) + abs(y);
    if ( testval < 0.0001)
    {
        flon = 0.0;
    }
    else
    {
        flon = atan2(y, x);
    }

    p =  sqrt( x*x + y*y );

    //             on pole special case

    if ( p < 0.0001 )
    {  
        flat = 1.57079632679;
        if ( z < 0.0 ) { flat = -1.57079632679; }
        altkm = rp - rearth(flat);
        return float3(flat, flon, altkm);
    }

    //        first iteration, use flatgc to get altitude 
    //        and alt needed to convert gc to gd lat.

    rnow  =  rearth(flatgc);
    altkm =  rp - rnow;
    flat  =  gc2gd (flatgc,altkm);
    
    float3 rrnrm =  radcur(flat);
    rn    =  rrnrm.y;

    for ( kount = 0; kount < 5 ; kount++ )
    {
        slat  =  sin(flat);
        tangd =  ( z + rn*esq*slat ) / p;
        flatn =  atan(tangd);

        dlat  =  flatn - flat;
        flat  =  flatn;
        clat  =  cos( flat );

        rrnrm =  radcur(flat);
        rn    =  rrnrm[1];

        altkm =  (p/clat) - rn;

        if ( abs(dlat) < 0.0001 ) { break; }

    }
    
    return float3(flat, flon, altkm);
}

float3 xyzllhSimple(float3 xyz) {
    return float3(
        atan2(xyz.z, sqrt(xyz.x * xyz.x + xyz.y * xyz.y)),
        atan2(xyz.x, xyz.y),
        length(xyz)
    );
}

float map(float value, float low1, float high1, float low2, float high2) {
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void XYZToLLH_float(float3 xyz, out float3 llh) {
    llh = xyzllhSimple(xyz);
}

void LLHToEquirectangular_float(float3 llh, out float2 xy) {
    xy = float2(
        map(llh.y, -PI, PI, 0, 1),
        map(llh.x, -PI / 2, PI / 2, 0, 1));
}

float median(float3 vec) {
    return max(min(vec.r, vec.g), min(max(vec.r, vec.g), vec.b));
}

void SDFOpacity_float(float textureValue, float2 limits, out float opacity) {
    opacity = smoothstep(limits.x, limits.y, textureValue);
}

#endif
