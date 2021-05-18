function leglocalizer (expname)

% Setup acquisition parameters (modify according to the scanner)
AcquisitionParameters(30, 2000/30, 2000);

% Read Excel worksheet
E = excelfile.open('leglocalizer.xls');
v = readtable(E, expname);
setup = v(find(strcmp({v.name}, 'Setup'),1)).contents;
trial = v(find(strcmp({v.name}, 'Trials'),1)).contents;
if isempty(v) || isempty(trial)
	error('Invalid Excel worksheet');
end
try
	setup = cell2struct({setup.Value}', {setup.Variable});
catch
	error('Invalid setup table in Excel worksheet');
	
end
clear E v

% Setup fonts and colors
UseDegrees;
TextFont('Arial', 2);
PenColor('white');
BackgroundColor('black');

% Draw fixation point
Transparency(101, 'ON');
PenColor(101, 'white');
FixCross(101, 1);

% Draw fixation for movement
Transparency(103, 'ON');
PenColor(103, 'green');
FixCross(103, 1);

% Draw go signal
Transparency(102, 'ON');
PenColor(102, 'red');
FixCross(102, 1);

% Draw cue for task 1
Transparency(1, 'ON');
PenColor(1, 'green');
FillEllipse(1, [0 0], [0.9 0.9]);

% Draw cue for task 2
Transparency(2, 'ON');
PenColor(2, 'white');
FillRect(2, [-0.45 -0.45 0.45 0.45]);


CopyStimulus(101,0);	% Show fixation point
StartExperiment;	% Start experiment

for i=1:length(trial)	% Repeat for every trial in the list

		% Show instruction if InstructionOnset provided
	if ~isempty(trial(i).InstructionOnset)
		DrawText(0, trial(i).Task, [0 0]);					        % Draw instruction
		t = Present(trial(i).InstructionOnset, visual);		        % Show instruction
		Present(t + setup.InstructionDuration, visual(101));	    % Show fixation point
	end
	
	if trial(i).DelayDuration	                                    % If delayed response...
		t = Present(trial(i).TargetOnset, visual(101));             % Show fixation point      
 		t = Present(t + setup.GoDuration, visual(102));	                % ... show prepare signal with delay    
		t = Present(t + trial(i).DelayDuration, visual(103));       % ... show go signal
        DefineResponse(t, 2000, 0, [], trial(i));                   % Define response
		Present(t + trial(i).ITIDuration, visual(101));	            % Show fixation point
	end
end

WaitUntil(trial(end).TrialEnd);


			
			
			