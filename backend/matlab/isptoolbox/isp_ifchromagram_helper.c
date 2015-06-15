#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void hz2octs(double *p, int len);
double quantize(double *p, double *p_org, int len, int nchr, int havesemisoff, double semisoff);
void chromagram_IF(double *oct, double *p, double *m, int xlen, int ylen, int nchr, int havesemisoff, double semisoff, double *pcout);


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, 
		 const mxArray *prhs[]) {

  /*
    [Y,c] = chromagram_IF_helper(p, m, nchr, semisoff);
  */

    double *oct, *p, *m, *pcout;
    double semisoff;
    int xlen, ylen, slen, nchr, havesemisoff;

  if (nrhs != 4 && nrhs != 3)
    mexErrMsgTxt("Wrong number of inputs.");

  if (nlhs != 2 && nlhs != 1)
    mexErrMsgTxt("One or two outputs required.");

  p=mxGetPr(prhs[0]);
  xlen=mxGetM(prhs[0]);
  ylen=mxGetN(prhs[0]);
  m=mxGetPr(prhs[1]);
  if (xlen != mxGetM(prhs[1]) || ylen != mxGetN(prhs[1]))
    mexErrMsgTxt("Sizes of argument one and two do not match.");
    
  havesemisoff = 0;
  if (nrhs == 4) {
    slen = mxGetM(prhs[3]) * mxGetN(prhs[3]);
    if (slen > 0) {
      semisoff = *mxGetPr(prhs[3]);
      havesemisoff = 1;
    }
  }

  nchr=mxGetScalar(prhs[2]);

  plhs[0] = mxCreateDoubleMatrix(nchr, ylen, mxREAL);
  if (plhs[0]==NULL)
    mexErrMsgTxt("Unable to allocate space for output matrix.");

  if (xlen*ylen == 0)
    return;

  oct = mxGetPr(plhs[0]);
  if (nlhs == 2) {
    plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);
    if (plhs[1]==NULL)
      mexErrMsgTxt("Unable to allocate space for output matrix.");
    pcout = mxGetPr(plhs[1]);
  } else {
    pcout = NULL;
  }

  chromagram_IF(oct, p, m, xlen, ylen, nchr, havesemisoff, semisoff, pcout);
}

void chromagram_IF(double *oct, double *p_org, double *m, int xlen, int ylen, int nchr, int havesemisoff, double semisoff, double *pcout) {

  int x,y;

  /* The next four lines of code were added 'cause it isn't nice to
     alter the input arguments */
  double *p;
  double c;
  p = malloc(xlen*ylen*sizeof(*p));
  for (x=0; x<xlen*ylen; x++)
    p[x] = p_org[x];

  hz2octs(p, xlen*ylen);
  c = quantize(p, p_org, xlen*ylen, nchr, havesemisoff, semisoff);

  if (pcout != NULL) {
    *pcout = c;
  }

  double *pp=p;
  double *mp=m;
  double *octp=oct;
  for (y=0; y<ylen; y++) {
    for (x=0; x<xlen; x++) {
      if (*(p_org++)) {
	octp[((int) pp[x]) % nchr] += mp[x];
      }
    }
    mp += xlen;
    pp += xlen;
    octp += nchr;
  }
  free(p);
}


double quantize(double *p, double *p_org, int len, int nchr, int havesemisoff, double semisoff) {
  int hist[101];
  int i;
  double correction = -semisoff;

  for (i=0; i<=100; i++) 
    hist[i]=0;

  for (i=0; i<len; i++) {
    if (p_org[i]) {
      p[i] *= nchr;
      hist[(int) floor(50+0.5+100*(p[i]-floor(0.5+p[i])))]++;
    }
  }

  if (havesemisoff == 0) {

    int best=0;
    for (i=1; i<=100; i++) {
      if (hist[i]>hist[best])
	best=i;
    }

    correction=-(((double) best)/100 - 0.5);

  }

  /*  mexPrintf("isp_ifchromagram_helper: semisoff(%s)=%f\n", 
	    havesemisoff?"given":"estimated", -correction);  */

  for (i=len-1; i--;)
    if (p[i]) 
      p[i] = floor(p[i]+correction+0.5);

  return -correction;
}

void hz2octs(double *p, int len) {
  int i;
  double c = 1.0/(440.0/16.0);
  /* double c = 1.0/(435.45/16.0); */
  /* beatles data tends to be a little flat - use a flatter reference
     2009-10-02 */
  for (i=len-1; i--;) {
    if (p[i])
      p[i]=log(c*p[i])/M_LN2;
  }
}
