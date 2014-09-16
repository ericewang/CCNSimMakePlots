% Load data from a specified CCNSim output file into the current
% MATLAB workspace. This script obtains the name of the output file
% from the variable "outputfile" in the current workspace.
% Run "ccnsimplotdata" after this script to plot the loaded data.
% For convenience, the variables used for generating the plots are
% saved in a MAT file.

% % monitor run times
% profile on

% clears home window
%clc

% display start time
display(['Start Time: ' datestr(now)])

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

% count used in nodeMap
NCOcount = 0;

% count used in AR mapping
ARcount = 0;

% count used in AC mapping
ACcount = 0;

% count used in VQ mapping
VQcount = 0;

% count used in SO mapping
SOcount = 0;

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
            numberOfObjects = str2double(paramsMap('[GENERAL]:numberOfObjects'));
            numberOfNodes = str2double(paramsMap('[GENERAL]:numberOfNodes'));

            % initialize nodeMap with Object and Node data to all zeros
            nodeMap = cell((simulationDuration/loggingInterval+1)*numberOfNodes,numberOfObjects+1);
            for row = 1: (simulationDuration/loggingInterval+1)*numberOfNodes
                for col = 2: numberOfObjects+1
                    nodeMap{row,col} = 0;
                end
            end
            
            % initialize specificAR with node data to all zeros
            specificAR = cell((simulationDuration/loggingInterval+1)*numberOfNodes,4);
            for row = 1: (simulationDuration/loggingInterval+1)*numberOfNodes
                for col = 2 : 4
                    specificAR{row,col} = 0;
                end
            end
            
            % initialize specificAC with node data to all zeros
            specificAC = cell((simulationDuration/loggingInterval+1)*numberOfNodes,3);
            for row = 1: (simulationDuration/loggingInterval+1)*numberOfNodes
                for col = 2 : 3
                    specificAC{row,col} = 0;
                end
            end
            
            % initialize specificVQ with node data to all zeros
            specificVQ = cell((simulationDuration/loggingInterval+1)*numberOfNodes,2);
            for row = 1: (simulationDuration/loggingInterval+1)*numberOfNodes
                for col = 2 : 2
                    specificVQ{row,col} = 0;
                end
            end
            
            % initialize specificObject to all zeros
            specificObject = cell((simulationDuration/loggingInterval+1)*numberOfObjects,7);
            for row = 1: (simulationDuration/loggingInterval+1)*numberOfObjects
                for col = 2 : 7
                    specificObject{row,col} = 0;
                end
            end
            
            % initialize objectSummation to all zeros
            objectSummation = cell((simulationDuration/loggingInterval+1),numberOfObjects);
            for row = 1: (simulationDuration/loggingInterval+1)
                for col = 1 : numberOfObjects
                    objectSummation{row,col} = 0;
                end
            end
            
			% get selected policy
			policy = paramsMap('[GENERAL]:policy');
            
            % Gets upstream neighbor selection criteria: Should be either ALL or BEST
            %if strcmp('LRU',policy) || strcmp('LFU',policy)
            %    upstreamNeighborSelectionCriteria = paramsMap('[GENERAL]:upstream.neighbor.selection.criteria');
            %end

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
			if strcmp('MODIFIED.VBP', policy)
				VQ_raw = zeros(length(times), 1);
				VQ_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step
            end
            
            % initialize matrix for Virtual Queues (VQ):
			%   column 1: VolumeVIPsQueued(t)
			if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
				VQ_raw = zeros(length(times), 1);
				VQ_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step
            end
            
            % initialize matrix for Virtual Queues (VQ):
			%   column 1: VolumeVIPsQueued(t)
			if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
				VQ_raw = zeros(length(times), 1);
				VQ_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step
            end
            
            % initialize matrix for Node Cached Objects (NCO):
			%   Column for each object possible 
 			NCO_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step
            
            % initialize matrix for Specific Objects (SO):
			%   Column for each object possible 
 			SO_parsedNodes = java.util.HashSet(); % nodes already parsed for the current time step

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
                    NCO_parsedNodes.clear();
                    SO_parsedNodes.clear();

					if strcmp('MODIFIED.VBP', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
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
            
            % increase count for plotting
            ARcount = ARcount + 1;
            
            % plot specific AR entry node data
            specificAR{ARcount,1} = entryNode;

			fresh = AR_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
            end

			% parse log entry value: VolumeRequestsCreated(v,t)
			[entryAR1, remain] = strtok(remain, ',');
			entryAR1 = str2double(strtrim(entryAR1));
            specificAR{ARcount,2} = entryAR1;
            
			% parse log entry value: VolumeRequestsFulfilled(v,t)
			[entryAR2, remain] = strtok(remain, ',');
			entryAR2 = str2double(strtrim(entryAR2));
            specificAR{ARcount,3} = entryAR2;

			% parse log entry value: DelayRequestsFulfilled(v,t)
			[entryAR3, remain] = strtok(remain, ',');
			entryAR3 = str2double(strtrim(entryAR3));
            specificAR{ARcount,4} = entryAR3;

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
                    NCO_parsedNodes.clear();
                    SO_parsedNodes.clear();

					if strcmp('MODIFIED.VBP', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
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
            
            % increase count for plotting
            ACcount = ACcount + 1;
            
            % plot specific AC entry node data
            specificAC{ACcount,1} = entryNode;

			fresh = AC_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
			end

			% parse log entry value: VolumeCacheHits(v,t)
			[entryAC1, remain] = strtok(remain, ',');
			entryAC1 = str2double(strtrim(entryAC1));
            specificAC{ACcount,2} = entryAC1;

			% parse log entry value: VolumeCacheEvictions(v,t)
			[entryAC2, remain] = strtok(remain, ',');
			entryAC2 = str2double(strtrim(entryAC2));
            specificAC{ACcount,3} = entryAC2;

			% add to cumulative statistics
			AC_raw(times==timeStep,:) = AC_raw(times==timeStep,:) ...
				+ [entryAC1,entryAC2];

		elseif strcmp('VQ', entryType) && (strcmp('MODIFIED.VBP', policy) || strcmp('VIRTUAL.BACKPRESSURE.B', policy) || strcmp('VIRTUAL.BACKPRESSURE.C', policy)) 

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
                    NCO_parsedNodes.clear();
                    SO_parsedNodes.clear();

					if strcmp('MODIFIED.VBP', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
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
            
            % increase count for plotting
            VQcount = VQcount + 1;
            
            % plot specific VQ entry node data
            specificVQ{VQcount,1} = entryNode;

			fresh = VQ_parsedNodes.add(entryNode);

			if ~fresh
				error('ERROR: Duplicate log entry for node "%s" on line %d.',...
						entryNode, lineNumber);
			end

			% parse log entry value: VolumeVIPsQueued(v,t)
			[entryVQ1, remain] = strtok(remain, ',');
			entryVQ1 = str2double(strtrim(entryVQ1));
            specificVQ{VQcount,2} = entryVQ1;

			% add to cumulative statistics
			VQ_raw(times==timeStep,:) = VQ_raw(times==timeStep,:)...
				+ [entryVQ1];

        elseif strcmp('NCO', entryType)

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.4) PARSE NODE CACHED OBJECTS (NCO) ENTRY %
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                    NCO_parsedNodes.clear();
                    SO_parsedNodes.clear();

					if strcmp('MODIFIED.VBP', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
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
            
            NCOcount = NCOcount + 1;
            nodeMap{NCOcount,1} = entryNode;

            fresh = NCO_parsedNodes.add(entryNode);

            if ~fresh
                error('ERROR: Duplicate log entry for node "%s" on line %d.',...
                        entryNode, lineNumber);
            end

                [entryNCO, remain] = strtok(remain, ']');
                temp = strtrim(entryNCO);
                ObjectList = regexp(temp(3:end),',','split');

            for entry = 1 : length(ObjectList)
                % parse log entry value: cached objects(v,t)
                if length(ObjectList) == 1 && isempty(ObjectList{1,1}) == 1
                    % do nothing
                else
                        ObjectNumber = str2double(strrep(ObjectList{1,entry},'object',''));
                        nodeMap{NCOcount,(ObjectNumber + 1)} = 1;
                end
            end
        elseif strcmp('TotalHops',entryType)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.5) PARSE TOTAL HOPS (TotalHops) ENTRY %
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [totalHops, remain] = strtok(remain, ',');
			totalHops = strtrim(totalHops);             
        elseif strcmp('SO', entryType)

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% (2.6) PARSE SPECIFIC OBJECT (SO) ENTRY %
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
                    NCO_parsedNodes.clear();
                    SO_parsedNodes.clear();

					if strcmp('MODIFIED.VBP', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
						VQ_parsedNodes.clear();
                    end
                    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
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
            
            SOcount = SOcount + 1;
            specificObject{SOcount,1} = entryNode;

            fresh = SO_parsedNodes.add(entryNode);

            if ~fresh
                error('ERROR: Duplicate log entry for node "%s" on line %d.',...
                        entryNode, lineNumber);
            end

            % parse log entry value: VolumeRequestsCreated(v,t)
			[entryAR1, remain] = strtok(remain, ',');
			entryAR1 = str2double(strtrim(entryAR1));
            specificObject{SOcount,2} = entryAR1;
            
			% parse log entry value: VolumeRequestsFulfilled(v,t)
			[entryAR2, remain] = strtok(remain, ',');
			entryAR2 = str2double(strtrim(entryAR2));
            specificObject{SOcount,3} = entryAR2;

			% parse log entry value: DelayRequestsFulfilled(v,t)
			[entryAR3, remain] = strtok(remain, ',');
			entryAR3 = str2double(strtrim(entryAR3));
            specificObject{SOcount,4} = entryAR3;
            
            % parse log entry value: VolumeCacheHits(v,t)
			[entryAC1, remain] = strtok(remain, ',');
			entryAC1 = str2double(strtrim(entryAC1));
            specificObject{SOcount,5} = entryAC1;

			% parse log entry value: VolumeCacheEvictions(v,t)
			[entryAC2, remain] = strtok(remain, ',');
			entryAC2 = str2double(strtrim(entryAC2));
            specificObject{SOcount,6} = entryAC2;
            
            % parse log entry value: VolumeVIPsQueued(v,t)
			[entryVQ1, remain] = strtok(remain, ',');
			entryVQ1 = str2double(strtrim(entryVQ1));
            specificObject{SOcount,7} = entryVQ1;           
        end
    end
end

for row = 1: (simulationDuration/loggingInterval+1)
    for col = 1 : numberOfObjects
        objectSummation{row,col} = sum([nodeMap{1+numberOfNodes*(row-1):numberOfNodes*row,col+1}]);
    end
end

fclose(fid);
fprintf('\nSaving Variables...');
fprintf('\n\n');

% save workspace variables
vars = {'outputfile','paramsMap',...
	'times','AR_raw','AC_raw','nodeMap','specificAR','specificAC','specificVQ','specificObject'};

if strcmp('MODIFIED.VBP', policy)
	vars = {vars{:}, 'VQ_raw'};
end
if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
	vars = {vars{:}, 'VQ_raw'};
end
if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
	vars = {vars{:}, 'VQ_raw'};
end
	
save([outputfile, '.mat'], vars{:});

fprintf('Done!\n');

% display end time
display(['End Time: ' datestr(now)])

% profile viewer
% profile off

%clear fid a key value hashIndex equalsIndex fresh remain
%clear lineNumber section timeStep
%clear AR_parsedNodes AC_parsedNodes VQ_parsedNodes
%clear entryType entryTimeStep entryNode
%clear entryAR1 entryAR2 entryAR3 entryAC1 entryAC2 entryVQ1


%
infoVolumeRequestsCreated = mean(AR_raw(:,1));
infoVolumeRequestsFulfilled = mean(AR_raw(:,2));
infoDelaysRequestsFulfilled = mean(AR_raw(:,3));

infoVolumeCacheHits = mean(AC_raw(:,1));
infoVolumeCacheEvictions = mean(AC_raw(:,2));

