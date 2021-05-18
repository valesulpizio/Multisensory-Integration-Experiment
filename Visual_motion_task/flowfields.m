function flowfields (varargin)
% FLOWFIELDS        Rotation/dilation flow fields for V6 mapping
%
% FLOWFIELDS generates rotation/dilation flow fields. Several
% parameters can be configured by modifying the ROTDIL worksheet in the
% MAPPER.XLS workbook.
%
% For more information on these stimuli and the configuration parameters,
% see MAPPER documentation.
%
% Written by Gaspare Galati, Aug 8, 2007
% based on MAPPEROSX.C by Anders Dale and Martin Sereno
%
%  This script requires:
%      - MATLAB R2014b or later (https://www.mathworks.com)
%      - Cogent 2000 (http://www.vislab.ucl.ac.uk/cogent_2000.php)
%      - GagLab 1.7 (available upon request to gaspare.galati@uniroma1.it)
%
%  Installation:
%  place the folder containing this script under GagLab/Experiments/v1 in
%  your desktop; run "gaglab" on the MATLAB prompt and select the
%  experiment in the main GagLab window.

flags = mapper_init('ROTDIL1', 'mapper', 'ROTDIL') %#ok<NOPRT>
dots = initdots(flags);

stopat = flags.numcycles * 2 / abs(flags.twofreq);
tideal = 0;
treal = 0;

StartExperiment;
while treal(end) < stopat*1000
	tideal(end+1) = treal(end) + flags.deltat; %#ok<AGROW>
	dots = updatedots(flags, dots, tideal(end)/1000);
	treal(end+1) = Present(tideal(end), visual); %#ok<AGROW>
end
assignin('base','t', struct('real', treal', 'ideal', tideal', 'delta', flags.deltat));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dots = initdots (flags)
% DOTS is a N by 6 matrix, where N is FLAGS.NUMDOTS and the columns
% represent [DOTX, DOTY, DOTDX, DOTDY, DOTROT, DOTDILSCALE]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dots.darkcol = (flags.avgcolbright - flags.avgcolbright * flags.bwcontrast);
dots.lightcol = (flags.avgcolbright + flags.avgcolbright * flags.bwcontrast);
dots.dot = zeros(flags.numdots,2);
dots.trans = randomtrans(flags, 1);
dots.oldt = -1.0;
dots.glass = strcmp(flags.stimtype, 'GLASS1');
dots.maxgendotxy = flags.xymax(1) * 1.5 * flags.stimscale;   % 1.5 = OVERGENFACT
dots.maxdot = flags.xymax .* flags.stimscale;
BackgroundColor(0, [dots.darkcol, dots.darkcol, dots.darkcol]);
PenColor(0, [dots.lightcol, dots.lightcol, dots.lightcol]);
dots = updatedots(flags, dots, 0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dots = updatedots (flags, dots, t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scrambled = mod(floor(flags.twofreq * t), 2);
dt = t - dots.oldt;

if dt > (1 / flags.dilfreq) || dots.oldt < 0  % must update
	if scrambled ~= mod(floor(flags.twofreq * dots.oldt), 2)
		if scrambled
			fprintf('Starting a SCRAMBLED  block at t = %3.3f sec.\n', t);
		elseif dots.glass
			fprintf('Starting a GLASS      block at t = %3.3f sec.\n', t);
		else
			fprintf('Starting a FLOWFIELDS block at t = %3.3f sec.\n', t);
		end
	end
	dots.dot = computedots(flags, dots);
	dots.oldt = floor(t * flags.dilfreq) / flags.dilfreq;
	if scrambled
		dots.dot(:,3:6) = randomtrans(flags, size(dots.dot,1));
	else                  % all dots get same rotdil
		dots.trans = randomtrans(flags, 1);
	end
end

if dots.glass
	f = 0.05; % GLASSDROTDIL
	g = 2.0*f;
else
	f = (t - dots.oldt) * flags.dilfreq;
	f = floor(f * flags.flickerfreq) / flags.flickerfreq;  % 0-1
end

if scrambled          % new rotdil for each dot
	if dots.glass
		drawdots(flags, dots, dots.dot(:,3:4)*f, dots.dot(:,5)*0, 1.0+(dots.dot(:,6)-1.0)*0);
	end
	drawdots(flags, dots, dots.dot(:,3:4)*f, dots.dot(:,5)*f, 1.0+(dots.dot(:,6)-1.0)*f);
	if dots.glass
		drawdots(flags, dots, dots.dot(:,3:4)*f, dots.dot(:,5)*g, 1.0+(dots.dot(:,6)-1.0)*g);
	end
else                  % all dots get same rotdil
	if dots.glass
		drawdots(flags, dots, dots.trans(1:2)*f, dots.trans(3)*0, 1.0+(dots.trans(4)-1.0)*0);
	end
	drawdots(flags, dots, dots.trans(1:2)*f, dots.trans(3)*f, 1.0+(dots.trans(4)-1.0)*f);
	if dots.glass
		drawdots(flags, dots, dots.trans(1:2)*f, dots.trans(3)*g, 1.0+(dots.trans(4)-1.0)*g);
	end
end

CopyStimulus(1,0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dot = computedots (flags, dots)
% DOT is a N by 6 matrix, where N is FLAGS.NUMDOTS and the columns
% represent [DOTX, DOTY, DOTDX, DOTDY, DOTROT, DOTDILSCALE]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rnd = rand_float(-dots.maxgendotxy, dots.maxgendotxy, [size(dots.dot,1),2]);
d = sqrt(sum(rnd.^2,2));
j = find(d >= flags.minrad);
dot(j,1:2) = rnd(j,:);
dot(j,3:6) = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans = randomtrans (flags, N)
% TRANS is a N by 4 matrix: [DX, DY, ROT, SCALE]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trans(:,1:2) = flags.dotspeed .* rand_float(-flags.dotjittcent, flags.dotjittcent, [N 2]);
if flags.dotrotflag
	trans(:,3) = flags.dotspeed .* rand_float(-10.0, 10.0, [N 1]) .* pi ./ 180;
else
	trans(:,3) = 0.0;
end
if flags.dotdilflag
	trans(:,4) = 1.0 + flags.dotspeed .* (rand_float(0.87, 1.15, [N 1]) - 1.0);
else
	trans(:,4) = 1.0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = rand_float (L, H, siz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

val = L + rand(siz) .* (H-L);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawdots (flags, dots, delta, a, scale)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sina = sin(a);
cosa = cos(a);
xy = [scale .* dots.dot(:,1) .* cosa - scale .* dots.dot(:,2) .* sina + delta(:,1), ...  % x
	scale .* dots.dot(:,1) .* sina + scale .* dots.dot(:,2) .* cosa + delta(:,2)];   % y

xy(xy(:,1) < -dots.maxdot(1) | xy(:,1) > dots.maxdot(1) | xy(:,2) < -dots.maxdot(2) | xy(:,2) > dots.maxdot(2),:) = [];

FillRect(0, [xy - flags.dotsize, xy + flags.dotsize] .* flags.screenfactor);

