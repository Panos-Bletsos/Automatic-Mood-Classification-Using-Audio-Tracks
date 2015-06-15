function [Y,p,m,S,c] = isp_ifchromagram(d,sr,fftlen,nbin,f_ctr,f_sd,semisoff,dgth,whiwin)
%ISP_IFCHROMAGRAM  Compute chromagram from instantaneous frequency
%
% SYNTAX
%   [Y,p,m,S,c] = isp_ifchromagram(d,sr,fftlen,nbin,f_ctr,f_sd,centsoff,dgth,whiwin)
%
% DESCRIPTION
%   Calculate the "chromagram" of the sound in d. Use instantaneous
%   frequency to keep only real harmonics. The first time this function
%   is called, it attempts to compile some C code to speed things up. If
%   this fails, a MATLAB version is used instead.
%
% INPUT
%   d:
%     Wave signal.
%   sr:
%     Sampling rate.
%   fftlen:
%     Window length.
%   ffthop:
%     Hop length.
%   nbin:
%     Number of steps to divide the octave into.
%   f_ctr, f_sd:
%     Weight with center frequency f_ctr (in Hz) and gaussian SD f_sd (in
%     octaves).
%   semisoff:
%     If specified, center the chroma bins this far sharp relative
%     to A440 (negative value means center bins flat).  Value is 
%     in semitones (2^(1/12)), so a value of +1.0 centers an A bin
%     at concert A#4, or 440*2^(1.0/12) = 
%   dgth:
%     threshold on IF difference between adjacent bands for
%     filtering tonal peaks in ifptrack.  Default is 0.4, smaller
%     for more conservative tonal peak picking.
%   whiwin 
%     magnitude whitening window in octaves (default 0 = none).
%
% OUTPUT
%   Y:
%     Chromagram 
%   p:
%     Frequencies of instantaneous frequency gram
%   m:
%     Magnitudes of instantaneous frequency gram
%   S:
%     Complex STFT
%   c:
%     The actual tuning offset used, in semitones.  Equal to
%     semisoff if specified, else estimated from histogram of frequencies.
%
% SEE ALSO
%   isp_ifgram, isp_ifptrack.
% 
% HISTORY
%   2006-09-26: dpwe@ee.columbia.edu
%   2007-10-11: Heavily optimized by Jesper Højvang Jensen (jhj@es.aau.dk)

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 as published
% by the Free Software Foundation.


% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 as published
% by the Free Software Foundation.


% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 as published
% by the Free Software Foundation.




%   Copyright (c) 2006 Columbia University.
% 
%   This file is part of LabROSA-coversongID
% 
%   LabROSA-coversongID is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License version 2 as
%   published by the Free Software Foundation.
% 
%   LabROSA-coversongID is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with LabROSA-coversongID; if not, write to the Free Software
%   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
%   02110-1301 USA
% 
%   See the file "COPYING" for the text of the license.

if nargin < 3;   fftlen = 2048; end
if nargin < 4;   nbin = 12; end
if nargin < 5;   f_ctr = 400; end  % was 1000, but actually I used 400
if nargin < 6;   f_sd = 1; end
if nargin < 7;   semisoff = []; end
if nargin < 8;   dgth = 0.4; end
if nargin < 9;   whiwin = 0; end

% dgth
%        ex filt  simple filtx`
% .3  ->          0.73491
% .35 ->          0.73686
% .4  -> 0.73223  0.74192 ** (verified on macbook and boar 2010-04-06)
% .45 ->          0.73922
% .5  -> 0.73833  0.73906
% .6  -> 0.73813  (crashed)
% .7  -> 0.73696  0.73436
% .75 -> 0.73718
% .8  -> 0.73315 (some crashing)
% old .75 -> 0.74207

fminl = octs2hz(hz2octs(f_ctr)-2*f_sd);
fminu = octs2hz(hz2octs(f_ctr)-f_sd);
fmaxl = octs2hz(hz2octs(f_ctr)+f_sd);
fmaxu = octs2hz(hz2octs(f_ctr)+2*f_sd);

ffthop = fftlen/4;
nchr = nbin;

% Compile mex file if necessary
mexname = [mfilename '_helper'];
if ~(exist(mexname)==3)
    if exist('OCTAVE_VERSION')
        npname = fullfile(isp_toolboxpath, mexname);
        mkoctfile([npname '.c'], '--mex', '--output', [npname '.' mexext])
    else
        cfile=which([mexname '.c']);
        try
            mex(cfile, '-outdir', fileparts(cfile))
        catch
            warning('Unable to compile mex file')
        end
    end
end


% Calculate spectrogram and IF gram pitch tracks...
[p,m,S]=isp_ifptrack(d,fftlen,sr,fminl,fminu,fmaxl,fmaxu,dgth,whiwin);

if exist('isp_ifchromagram_helper')==3
    [Y,c] = isp_ifchromagram_helper(p, m, nchr, semisoff);
else
    fprintf(1, 'Couldn''t find mex-file. Using matlab version for %s.\n', mfilename);

    [nbins,ncols] = size(p);

    % chroma-quantized IF sinusoids
    nzp = (p(:)>0);
%%%% dpwe modified 2009-09-29
    gmm = (m(:) > median(m(nzp)));
    nzp = nzp .* gmm;
%%%% not sync'd to C-code
    nzp = find(nzp);
    Pocts=p;
    Pocts(nzp) = hz2octs(p(nzp));

    % Figure best tuning alignment
    if length(semisoff) == 0
hist(nchr*Pocts(nzp)-round(nchr*Pocts(nzp)),[-0.5:.01:.5]);
      [hn,hx] = hist(nchr*Pocts(nzp)-round(nchr*Pocts(nzp)),[-0.5:.01:.5]);
      semisoff = hx(find(hn == max(hn)));
    end
    disp(['isp_ifchromagram: semisoff=',num2str(semisoff)]);
    % return value
    c = semisoff;
    
    % Adjust tunings to align better with chroma
    Pocts(nzp) = Pocts(nzp) - semisoff(1)/nchr;

    % Quantize to chroma bins
    PoctsQ = Pocts;
    PoctsQ(nzp) = round(nchr*Pocts(nzp))/nchr;

    % map IF pitches to chroma bins
    Pmapc = round(nchr*(PoctsQ - floor(PoctsQ)));
    Pmapc(p(:) == 0) = -1; 
    Pmapc(Pmapc(:) == nchr) = 0;

    Y = zeros(nchr,ncols);
    tmp=(0:(nchr-1))';
    for t = 1:ncols;
        Y(:,t)=(tmp(:, ones(1,size(Pmapc,1)))==Pmapc(:,t*ones(nchr,1))')*m(:,t);
    end

end
function octs = hz2octs(freq, A440)
% octs = hz2octs(freq, A440)
% Convert a frequency in Hz into a real number counting 
% the octaves above A0. So hz2octs(440) = 4.0
% Optional A440 specifies the Hz to be treated as middle A (default 440).
% 2006-06-29 dpwe@ee.columbia.edu for fft2chromamx

if nargin < 2;   A440 = 440; end

% A4 = A440 = 440 Hz, so A0 = 440/16 Hz
octs = log(freq./(A440/16))./log(2);

function hz = octs2hz(octs,A440)
% hz = octs2hz(octs,A440)
% Convert a real-number octave 
% into a frequency in Hzfrequency in Hz into a real number counting 
% the octaves above A0. So hz2octs(440) = 4.0.
% Optional A440 specifies the Hz to be treated as middle A (default 440).
% 2006-06-29 dpwe@ee.columbia.edu for fft2chromamx

if nargin < 2;   A440 = 440; end

% A4 = A440 = 440 Hz, so A0 = 440/16 Hz

hz = (A440/16).*(2.^octs);


