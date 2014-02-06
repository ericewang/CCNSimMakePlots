% Load data from a specified CCNSim output file into the current
% MATLAB workspace. This script obtains the name of the output file
% from the variable "outputfile" in the current workspace.
% Run "ccnsimplotdata" after this script to plot the loaded data.
% For convenience, the variables used for generating the plots are
% saved in a MAT file.

% check variable "outputfile"
if ~exist('outputfile', 'var')
	error(['ERROR: Variable "outputfile" not found in the current workspace. ',...
		'Please set "outputfile" to the name of the CCNSim output file.']);
end

fprintf('\nCCNSim Output File: "%s"\n', outputfile);

% open output file for reading
fid = fopen(outputfile, 'r', 'n', 'US-ASCII');

% key-value map for simulation parameters
paramsMap = containers.Map;

% current section
section = '';

% current time step
timeStep = 0;

% current line number
lineNumber = 0;

fprintf('\nLoading data...');

while true
	a = fgetl(fid); % read one line

	if ~ischar(a)
		break; % reached EOF
	end

	lineNumber = lineNumber + 1;

	% strip comments, and leading and trailing whitespace
	hashIndex = strfind(a, '#');

	if ~isempty(hashIndex)
		a = a(1:hashIndex(1)-1);
	end

	a = strtrim(a);

	if isempty(a)
		continue;
	end

	% section change
	if (a(1) == '[') && (a(end) == ']')
		section = a;

		% start of the [LOG] section
		if strcmp('[LOG]', section)
			% initialize data structures for the simulation statistics

			% initialize vector of time steps corresponding to log entries
			simulationDuration = str2double(paramsMap('[GENERAL]:simulation.duration'));
			loggingInterval = str2double(paramsMap('[GENERAL]:logging.interval'));
			times = (0:loggingInterval:simulationDuration)';

			% get selected policy
			policy = paramsMap('[GENERAL]:policy');

			% initialize matrix for Actual Requests (AR):
			%   column 1: VolumeRequestsCreated(t)
			%   column 2: VolumeRequestsFulfilled(t)
			%   column 3: DelayRequestsFulfilled(t)
			AR_raw = zeros(length(times), 3);
			AR_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step

			% initialize matrix for Actual Caches (AC):
			%   column 1: VolumeCacheHits(t)
			%   column 2: VolumeCacheEvictions(t)
			AC_raw = zeros(length(times), 2);
			AC_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step

			% initialize matrix for Virtual Queues (VQ):
			%   column 1: VolumeVIPsQueued(t)
			if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
				VQ_raw = zeros(length(times), 1);
				VQ_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step
			end

		end

		continue;
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% (1) PARSE ENTRY OUTSIDE THE [LOG] SECTION %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if ~strcmp('[LOG]', section)

		% parse key-value pair
		equalsIndex = strfind(a, '=');

		if isempty(equalsIndex)
			error('ERROR: Invalid key-value pair "%s" on line %d.',...
				a, lineNumber);
		end

		key = [section, ':', strtrim(a(1:equalsIndex(1)-1))]; % add section prefix
		value = strtrim(a(equalsIndex(1)+1:end));

		% remove quotes from strings
		if (length(value) >= 2) && (value(1) == '"') && (value(end) == '"')
			value = value(2:end-1);
		end

		% add entry to params map
		paramsMap(key) = value;

	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% (2) PARSE ENTRY IN [LOG] SECTION %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if strcmp('[LOG]', section)

		% parse log entry value: log entry type
		[entryType, remain] = strtok(a, ',');
		entryType = strtrim(entryType);

		if strcmp('AR', entryType)

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.1) PARSE ACTUAL REQUESTS (AR) ENTRY %
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			% parse log entry value: time step
			[entryTimeStep, remain] = strtok(remain, ',');
			entryTimeStep = str2double(strtrim(entryTimeStep));

			if entryTimeStep < timeStep
				error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
			elseif entryTimeStep > timeStep
				if entryTimeStep == (timeStep + loggingInterval)
					% advance the current time step
					timeStep = entryTimeStep;

					% reset parsed nodes for the current time step
					AR_parsedNodes.clear();
					AC_parsedNodes.clear();

					if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
						VQ_parsedNodes.clear();
					end
				else
					error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
				end
			end

			% parse log entry value: node name
			[entryNode, remain] = strtok(remain, ',');
			entryNode = strtrim(entryNode);

			fresh = AR_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
			end

			% parse log entry value: VolumeRequestsCreated(v,t)
			[entryAR1, remain] = strtok(remain, ',');
			entryAR1 = str2double(strtrim(entryAR1));

			% parse log entry value: VolumeRequestsFulfilled(v,t)
			[entryAR2, remain] = strtok(remain, ',');
			entryAR2 = str2double(strtrim(entryAR2));

			% parse log entry value: DelayRequestsFulfilled(v,t)
			[entryAR3, remain] = strtok(remain, ',');
			entryAR3 = str2double(strtrim(entryAR3));

			% add to cumulative statistics
			AR_raw(times==timeStep,:) = AR_raw(times==timeStep,:) ...
				+ [entryAR1,entryAR2,entryAR3];

		elseif strcmp('AC', entryType)

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.2) PARSE ACTUAL CACHES (AC) ENTRY %
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			% parse log entry value: time step
			[entryTimeStep, remain] = strtok(remain, ',');
			entryTimeStep = str2double(strtrim(entryTimeStep));

			if entryTimeStep < timeStep
				error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
			elseif entryTimeStep > timeStep
				if entryTimeStep == (timeStep + loggingInterval)
					% advance the current time step
					timeStep = entryTimeStep;

					% reset parsed nodes for the current time step
					AR_parsedNodes.clear();
					AC_parsedNodes.clear();

					if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
						VQ_parsedNodes.clear();
					end
				else
					error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
				end
			end

			% parse log entry value: node name
			[entryNode, remain] = strtok(remain, ',');
			entryNode = strtrim(entryNode);

			fresh = AC_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
			end

			% parse log entry value: VolumeCacheHits(v,t)
			[entryAC1, remain] = strtok(remain, ',');
			entryAC1 = str2double(strtrim(entryAC1));

			% parse log entry value: VolumeCacheEvictions(v,t)
			[entryAC2, remain] = strtok(remain, ',');
			entryAC2 = str2double(strtrim(entryAC2));

			% add to cumulative statistics
			AC_raw(times==timeStep,:) = AC_raw(times==timeStep,:) ...
				+ [entryAC1,entryAC2];

		elseif strcmp('VQ', entryType)

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.3) PARSE VIRTUAL QUEUES (VQ) ENTRY %
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			% parse log entry value: time step
			[entryTimeStep, remain] = strtok(remain, ',');
			entryTimeStep = str2double(strtrim(entryTimeStep));

			if entryTimeStep < timeStep
				error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
			elseif entryTimeStep > timeStep
				if entryTimeStep == (timeStep + loggingInterval)
					% advance the current time step
					timeStep = entryTimeStep;

					% reset parsed nodes for the current time step
					AR_parsedNodes.clear();
					AC_parsedNodes.clear();

					if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
						VQ_parsedNodes.clear();
					end
				else
					error('ERROR: Unexpected time step %d encountered on line %d.',...
						entryTimeStep, lineNumber);
				end
			end

			% parse log entry value: node name
			[entryNode, remain] = strtok(remain, ',');
			entryNode = strtrim(entryNode);

			fresh = VQ_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
			end

			% parse log entry value: VolumeVIPsQueued(v,t)
			[entryVQ1, remain] = strtok(remain, ',');
			entryVQ1 = str2double(strtrim(entryVQ1));

			% add to cumulative statistics
			VQ_raw(times==timeStep,:) = VQ_raw(times==timeStep,:)...
				+ [entryVQ1];

		end

	end

end

fclose(fid);
fprintf('\nDone!');
fprintf('\n\n');

% save workspace variables
vars = {'outputfile','paramsMap',...
	'times','AR_raw','AC_raw'};

if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
	vars = {vars{:}, 'VQ_raw'};
end
	
save([outputfile, '.mat'], vars{:});

%clear fid a key value hashIndex equalsIndex fresh remain
%clear lineNumber section timeStep
%clear AR_parsedNodes AC_parsedNodes VQ_parsedNodes
%clear entryType entryTimeStep entryNode
%clear entryAR1 entryAR2 entryAR3 entryAC1 entryAC2 entryVQ1