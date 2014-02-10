% Plot CCNSim output data that has been loaded into
% the current MATLAB workspace.
% Run "ccnsimloaddata" before this script.
% For convenience, the generated plots are saved in a PDF file.

% set the folder name to be used at
foldername = pwd;
foldername = [foldername, '\'];

% % start data recording
% profile on

% clear main screen
clc;

% display start time
display(['Start Time: ' datestr(now)]);

fprintf('\nPlotting data...');

% get selected policy 
policy = paramsMap('[GENERAL]:policy');

% initialize vector of time steps corresponding to log entries
simulationDuration = str2double(paramsMap('[GENERAL]:simulation.duration'));
loggingInterval = str2double(paramsMap('[GENERAL]:logging.interval'));

% get number of objects and nodes
numberOfObjects = str2double(paramsMap('[GENERAL]:numberOfObjects'));
numberOfNodes = str2double(paramsMap('[GENERAL]:numberOfNodes'));

% used for figure count
figureCount = 1;
totalRowsNodes = (simulationDuration/loggingInterval+1)*numberOfNodes;
totalRowsObjects = (simulationDuration/loggingInterval+1)*numberOfObjects;

% for finding a good resolution
startInterval = 0;
stopInterval = 5000;
if (startInterval < 0) || (stopInterval > simulationDuration + 1)
    display('Illegal interval range. Please check your values')
elseif mod(startInterval,loggingInterval) ~= 0 || mod(stopInterval,loggingInterval) ~= 0
    display('Logging range must be a multiple of the logging interval')
    display(['The current logging interval is ' num2str(loggingInterval)])
end

pdflist = cell(numberOfNodes+numberOfObjects+numberOfNodes*numberOfObjects+1,1);

intervalLength = length(startInterval/numberOfObjects+1:stopInterval/numberOfObjects);
test = cell(totalRowsNodes,1);

for temp = 1 : totalRowsNodes/numberOfNodes
    if mod(temp,2)
       test{temp,1} = 1;
    else 
       test{temp,1} = 0;
    end
end

% set figure size
scrsz = get(0,'ScreenSize');

% h = figure('OuterPosition',[0,0.1*scrsz(4),scrsz(3)/2,0.9*scrsz(4)]); % left,bottom,width,height
% bar(times(startInterval/numberOfObjects+1:stopInterval/numberOfObjects),[test{1:1:intervalLength,1}],'histc')
% set(gca,'XLim',[1 max(times(startInterval/numberOfObjects+1:stopInterval/numberOfObjects))]);
% 
% reply = input('Do you see the transitions? Y/N [Y]: ', 's');
% if isempty(reply)
%     close();
% elseif reply == 'Y' || 'y'
%     close();
% else
%     display('Hardcode in new start and stop intervals');
%     return;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) MAKE PLOT FOR ACTUAL REQUESTS (AR) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h = figure('OuterPosition',[0,0.1*scrsz(4),scrsz(3)/2,0.9*scrsz(4)]); % left,bottom,width,height

% save plot
set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');

if strfind(policy,'VIRTUAL')
    subplot(4,1,1);
else
    subplot(3,1,1);
end
% plot(times,AR_raw(:,1)./times,...
% 	times,AR_raw(:,2)./times);
% legend('VolumeRequestsCreated(t)/t',...
% 	'VolumeRequestsFulfilled(t)/t');
plot(times,AR_raw(:,1),times,AR_raw(:,2));
legend(['VolumeRequestsCreated(t)= ' num2str(mean(AR_raw(:,1)))],['VolumeRequestsFulfilled(t)= ' num2str(mean(AR_raw(:,2)))]);
xlabel('Time');
ylabel('Volume');
title('Actual Requests (AR): Volume of Requests Created & Fulfilled',...
	'interpreter','None');

if strfind(policy,'VIRTUAL')
    subplot(4,1,2);
else
    subplot(3,1,2);
end
% plot(times,AR_raw(:,3)./times);
% legend('DelayRequestsFulfilled(t)/t');
plot(times,AR_raw(:,3));
legend(['DelayRequestsFulfilled(t)= ' num2str(mean(AR_raw(:,3)))]);
xlabel('Time');
ylabel('Delay');
title('Actual Requests (AR): Delay for Fulfilled Requests',...
	'interpreter','None');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2) MAKE PLOT FOR ACTUAL CACHES (AC) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strfind(policy,'VIRTUAL')
    subplot(4,1,3);
else
    subplot(3,1,3);
end
% plot(times,AC_raw(:,1)./times,...
% 	times,AC_raw(:,2)./times);
% legend('VolumeCacheHits(t)/t',...
% 	'VolumeCacheEvictions(t)/t');
plot(times,AC_raw(:,1),times,AC_raw(:,2));
legend(['VolumeCacheHits(t)= ' num2str(mean(AC_raw(:,1)))],['VolumeCacheEvictions(t)= ' num2str(mean(AC_raw(:,2)))]);
xlabel('Time');
ylabel('Volume');
title('Actual Caches (AC): Volume of Cache Hits & Evictions',...
	'interpreter','None');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (3) MAKE PLOT FOR VIRTUAL QUEUES (VQ) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
	subplot(4,1,4);
	plot(times,VQ_raw(:,1));
	legend(['VolumeVIPsQueued(t)= ' num2str(mean(VQ_raw(:,1)))]);
	xlabel('Time');
	ylabel('Volume');
	title('Virtual Queues (VQ): Volume of VIPs Queued',...
		'interpreter','None');
end
if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
	subplot(4,1,4);
	plot(times,VQ_raw(:,1));
	legend(['VolumeVIPsQueued(t)= ' num2str(mean(VQ_raw(:,1)))]);
	xlabel('Time');
	ylabel('Volume');
	title('Virtual Queues (VQ): Volume of VIPs Queued',...
		'interpreter','None');
end
if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
	subplot(4,1,4);
	plot(times,VQ_raw(:,1));
	legend(['VolumeVIPsQueued(t) ' num2str(mean(VQ_raw(:,1)))]);
	xlabel('Time');
	ylabel('Volume');
	title('Virtual Queues (VQ): Volume of VIPs Queued',...
		'interpreter','None');
end

% print parameters
if exist('totalHops') == 0
        paramsSummary = {'CCNSim Parameters:',...
        ['  [GENERAL] description="', paramsMap('[GENERAL]:description'), '"'],...
        ['  [GENERAL] policy="', paramsMap('[GENERAL]:policy'), '"']};
else
        paramsSummary = {'CCNSim Parameters:',...
        ['  [GENERAL] description="', paramsMap('[GENERAL]:description'), '"'],...
        ['  [GENERAL] policy="', paramsMap('[GENERAL]:policy'), '"'],...
        ['  Total Hops=', totalHops]};
end

if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
	paramsSummary = {paramsSummary{:},...
		['  [VIRTUAL.BACKPRESSURE.A] virtual.plane.time.speedup.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.A]:virtual.plane.time.speedup.factor')],...
		['  [VIRTUAL.BACKPRESSURE.A] vip.averaging.window.size=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.A]:vip.averaging.window.size')],...
		['  [VIRTUAL.BACKPRESSURE.A] cached.vip.queue.length.scaling.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.A]:cached.vip.queue.length.scaling.factor')]};		
end
if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
	paramsSummary = {paramsSummary{:},...
		['  [VIRTUAL.BACKPRESSURE.B] virtual.plane.time.speedup.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.B]:virtual.plane.time.speedup.factor')],...
		['  [VIRTUAL.BACKPRESSURE.B] vip.averaging.window.size=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.B]:vip.averaging.window.size')],...
		['  [VIRTUAL.BACKPRESSURE.B] cached.vip.queue.length.scaling.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.B]:cached.vip.queue.length.scaling.factor')]};		
end
if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
	paramsSummary = {paramsSummary{:},...
		['  [VIRTUAL.BACKPRESSURE.C] virtual.plane.time.speedup.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.C]:virtual.plane.time.speedup.factor')],...
		['  [VIRTUAL.BACKPRESSURE.C] vip.averaging.window.size=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.C]:vip.averaging.window.size')],...
		['  [VIRTUAL.BACKPRESSURE.C] cached.vip.queue.length.scaling.factor=',...
		paramsMap('[VIRTUAL.BACKPRESSURE.C]:cached.vip.queue.length.scaling.factor')]};		
end
if strcmp('LFU', policy)
% 	paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=', paramsMap('[GENERAL]:upstream.neighbor.selection.criteria')]};
    paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=SHORTEST']};
end
if strcmp('LRU', policy)
% 	paramsSummary = {paramsSummary{:}, ['  [LRU] upstream.Neighbor.Selection.Criteria=', paramsMap('[GENERAL]:upstream.neighbor.selection.criteria')]};
    paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=SHORTEST']};
end

text(-0.05,-0.4,...
	paramsSummary,...
	'units','normalized',...
	'interpreter','None',...
	'FontSize',7);

% create title for entire figure
[ax4,h3]=suplabel('All Nodes All Objects','t');
set(h3,'FontSize',24);

% save plot
set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');

tempTime = datestr(now,0);
currentTime = strrep(tempTime, ':', '-');

if exist([outputfile,' ',currentTime]) ~= 0
    rmdir([foldername, outputfile,' ',currentTime],'s');
end

% make directory for files to be saved into
mkdir([outputfile,' ',currentTime]);

%saveas(h,[outputfile, '.fig']);
print('-dpdf','All Nodes All Objects.pdf');
pdflist{1}=('All Nodes All Objects.pdf');
movefile([foldername, 'All Nodes All Objects.pdf'],[foldername, outputfile,' ',currentTime,'\']);
close();
%print('-depsc2',[outputfile, '.eps']);

% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % (4) MAKE PLOT FOR NODES AND OBJECTS(NCOs) %
% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prints pdf and moves to specific folder a pdf of every object at every node
for nodeNumber = 1 : numberOfNodes
    for objectNumber = 1 : numberOfObjects
        close all
        
% % %         % save plot
% % %         set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
% % %     
% % %     subplot(5,1,1);
% % % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,2}]'./times,...
% % % %         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,3}]'./times);
% % % %     legend('VolumeRequestsCreated(t)/t',...
% % % %         'VolumeRequestsFulfilled(t)/t');
% % % % % %     bar(times(startInterval/numberOfObjects+1:stopInterval/numberOfObjects),[nodeMap{nodeNumber+(startInterval/numberOfObjects)*numberOfNodes:numberOfNodes:(stopInterval/numberOfObjects)*numberOfNodes,objectNumber + 1}],'histc')
% % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,2}]',...
% % %         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,3}]');
% % %     legend('VolumeRequestsCreated(t)','VolumeRequestsFulfilled(t)');
% % %     xlabel('Time');
% % %     ylabel('Volume');
% % %     title('Actual Requests (AR): Volume of Requests Created & Fulfilled',...
% % %         'interpreter','None');
% % % 
% % %     subplot(5,1,2);
% % % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,4}]'./times);
% % % %     legend('DelayRequestsFulfilled(t)/t');
% % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,4}]');
% % %     legend('DelayRequestsFulfilled(t)');
% % %     xlabel('Time');
% % %     ylabel('Delay');
% % %     title('Actual Requests (AR): Delay for Fulfilled Requests',...
% % %         'interpreter','None');

% % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %     % MAKE PLOT FOR ACTUAL CACHES (AC) %
% % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % %     subplot(5,1,3);
% % % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,5}]'./times,...
% % % %         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,6}]'./times);
% % % %     legend('VolumeCacheHits(t)/t',...
% % % %         'VolumeCacheEvictions(t)/t');
% % %     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,5}]',...
% % %         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,6}]');
% % %     legend('VolumeCacheHits(t)','VolumeCacheEvictions(t)');
% % %     xlabel('Time');
% % %     ylabel('Volume');
% % %     title('Actual Caches (AC): Volume of Cache Hits & Evictions',...
% % %         'interpreter','None');
% % % 
% % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %     % MAKE PLOT FOR VIRTUAL QUEUES (VQ) %
% % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % %     if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
% % %         subplot(5,1,4);
% % %         plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]');
% % %         legend('VolumeVIPsQueued(t)');
% % %         xlabel('Time');
% % %         ylabel('Volume');
% % %         title('Virtual Queues (VQ): Volume of VIPs Queued',...
% % %             'interpreter','None');
% % %     end
        
        figureCount = figureCount + 1; % start on 2
        figure(figureCount);
        set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
        bar(times(startInterval/numberOfObjects+1:stopInterval/numberOfObjects),[nodeMap{nodeNumber+(startInterval/numberOfObjects)*numberOfNodes:numberOfNodes:(stopInterval/numberOfObjects)*numberOfNodes,objectNumber + 1}],'histc')
        legend('1 if cached, 0 if not');
        xlabel('Logging Intervals');
        ylabel('Cached Status');
        axis([startInterval stopInterval 0 1])
%         title(['Object ', num2str(objectNumber),' at ', nodeMap{nodeNumber,1}],'interpreter','None');
        
        % create title for entire figure
        [ax4,h3]=suplabel(['Object ', num2str(objectNumber),' at ', nodeMap{nodeNumber,1}],'t');
        set(h3,'FontSize',24);
        
        % save plot
        set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
        
        if objectNumber < 10
            objectText = ['0' num2str(objectNumber)];
        else
            objectText = num2str(objectNumber);
        end
        
        print('-dpdf',['Object ', objectText,' at ', nodeMap{nodeNumber,1},'.pdf']);
        pdflist{figureCount}=(['Object ', objectText,' at ', nodeMap{nodeNumber,1},'.pdf']);
        movefile([foldername,'Object ', objectText,' at ', nodeMap{nodeNumber,1},'.pdf'],[foldername, outputfile,' ',currentTime,'\'])
        close();
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (5) MAKE PLOT FOR NODES AND ALL OBJECTS(NCOs) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for nodeListNumber = 1 : numberOfNodes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR ACTUAL REQUESTS (AR) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    figureCount = figureCount + 1;
    figure(figureCount);
    
    % save plot
    set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
    if strfind(policy,'VIRTUAL')
        subplot(4,1,1);
    else
        subplot(3,1,1);
    end
%     plot(times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,2}]'./times,...
%         times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,3}]'./times);
%     legend('VolumeRequestsCreated(t)/t',...
%         'VolumeRequestsFulfilled(t)/t');
    plot(times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,2}]',...
        times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,3}]');
    legend(['VolumeRequestsCreated(t)= ' num2str(mean([specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,2}]))],['VolumeRequestsFulfilled(t)= ' num2str(mean([specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,3}]))]);
    xlabel('Time');
    ylabel('Volume');
    title('Actual Requests (AR): Volume of Requests Created & Fulfilled',...
        'interpreter','None');

    if strfind(policy,'VIRTUAL')
        subplot(4,1,2);
    else
        subplot(3,1,2);
    end
%     plot(times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,4}]'./times);
%     legend('DelayRequestsFulfilled(t)/t');
    plot(times,[specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,4}]');
    legend(['DelayRequestsFulfilled(t)= ' num2str(mean([specificAR{nodeListNumber:numberOfNodes:totalRowsNodes,4}]))]);
    xlabel('Time');
    ylabel('Delay');
    title('Actual Requests (AR): Delay for Fulfilled Requests',...
        'interpreter','None');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR ACTUAL CACHES (AC) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strfind(policy,'VIRTUAL')
    subplot(4,1,3);
else
    subplot(3,1,3);
end
%     plot(times,[specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,2}]'./times,...
%         times,[specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,3}]'./times);
%     legend('VolumeCacheHits(t)/t',...
%         'VolumeCacheEvictions(t)/t');
    plot(times,[specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,2}]',...
        times,[specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,3}]');
    legend(['VolumeCacheHits(t)= ' num2str(mean([specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,2}]))],['VolumeCacheEvictions(t)= ' num2str(mean([specificAC{nodeListNumber:numberOfNodes:totalRowsNodes,3}]))]);
    xlabel('Time');
    ylabel('Volume');
    title('Actual Caches (AC): Volume of Cache Hits & Evictions',...
        'interpreter','None');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR VIRTUAL QUEUES (VQ) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
        subplot(4,1,4);
        plot(times,[specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end
    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
        subplot(4,1,4);
        plot(times,[specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end
    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
        subplot(4,1,4);
        plot(times,[specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificVQ{nodeListNumber:numberOfNodes:totalRowsNodes,2}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end

    % print parameters
    paramsSummary = {'CCNSim Parameters:',...
        ['  [GENERAL] description="', paramsMap('[GENERAL]:description'), '"'],...
        ['  [GENERAL] policy="', paramsMap('[GENERAL]:policy'), '"']};

    if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
        paramsSummary = {paramsSummary{:},...
            ['  [VIRTUAL.BACKPRESSURE.A] virtual.plane.time.speedup.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.A]:virtual.plane.time.speedup.factor')],...
            ['  [VIRTUAL.BACKPRESSURE.A] vip.averaging.window.size=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.A]:vip.averaging.window.size')],...
            ['  [VIRTUAL.BACKPRESSURE.A] cached.vip.queue.length.scaling.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.A]:cached.vip.queue.length.scaling.factor')]};		
    end
    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
        paramsSummary = {paramsSummary{:},...
            ['  [VIRTUAL.BACKPRESSURE.B] virtual.plane.time.speedup.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.B]:virtual.plane.time.speedup.factor')],...
            ['  [VIRTUAL.BACKPRESSURE.B] vip.averaging.window.size=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.B]:vip.averaging.window.size')],...
            ['  [VIRTUAL.BACKPRESSURE.B] cached.vip.queue.length.scaling.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.B]:cached.vip.queue.length.scaling.factor')]};		
        end
    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
        paramsSummary = {paramsSummary{:},...
            ['  [VIRTUAL.BACKPRESSURE.C] virtual.plane.time.speedup.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.C]:virtual.plane.time.speedup.factor')],...
            ['  [VIRTUAL.BACKPRESSURE.C] vip.averaging.window.size=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.C]:vip.averaging.window.size')],...
            ['  [VIRTUAL.BACKPRESSURE.C] cached.vip.queue.length.scaling.factor=',...
            paramsMap('[VIRTUAL.BACKPRESSURE.C]:cached.vip.queue.length.scaling.factor')]};		
    end
    if strcmp('LFU', policy)
%         paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=', paramsMap('[GENERAL]:upstream.neighbor.selection.criteria')]};
          paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=SHORTEST']};
    end
    if strcmp('LRU', policy)
%         paramsSummary = {paramsSummary{:}, ['  [LRU] upstream.Neighbor.Selection.Criteria=', paramsMap('[GENERAL]:upstream.neighbor.selection.criteria')]};
          paramsSummary = {paramsSummary{:}, ['  [LFU] upstream.Neighbor.Selection.Criteria=SHORTEST']};
    end

    text(-0.05,-0.4,...
        paramsSummary,...
        'units','normalized',...
        'interpreter','None',...
        'FontSize',7);
    
    % create title for entire figure
    [ax4,h3]=suplabel(['All Objects at ', specificAC{nodeListNumber,1}],'t');
    set(h3,'FontSize',24);

    % save plot
    set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');

    %saveas(h,[outputfile, '.fig']);
    print('-dpdf',['All Objects at ', specificAC{nodeListNumber,1}, '.pdf']);
    pdflist{figureCount}=(['All Objects at ', specificAC{nodeListNumber,1}, '.pdf']);
    movefile([foldername, 'All Objects at ', specificAC{nodeListNumber,1}, '.pdf'],[foldername, outputfile,' ',currentTime,'\']);
    close();
    %print('-depsc2',[outputfile, '.eps']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (6) MAKE PLOT FOR OJBECTS AND ALL NODES(SOs) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for nodeListNumber = 1 : numberOfObjects
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR ACTUAL REQUESTS (AR) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    figureCount = figureCount + 1;
    figure(figureCount);
    
    %'OuterPosition',[0,0.1*scrsz(4),scrsz(3)/2,0.9*scrsz(4)]
    
    % save plot
    set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
    
if strfind(policy,'VIRTUAL')    
    subplot(5,1,1);
else
    subplot(4,1,1);
end
%     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,2}]'./times,...
%         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,3}]'./times);
%     legend('VolumeRequestsCreated(t)/t',...
%         'VolumeRequestsFulfilled(t)/t');
    plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,2}]',...
        times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,3}]');
    legend(['VolumeRequestsCreated(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,2}]))],['VolumeRequestsFulfilled(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,3}]))]);
    xlabel('Time');
    ylabel('Volume');
    title('Actual Requests (AR): Volume of Requests Created & Fulfilled',...
        'interpreter','None');

if strfind(policy,'VIRTUAL')
    subplot(5,1,2);
else
    subplot(4,1,2);
end
%     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,4}]'./times);
%     legend('DelayRequestsFulfilled(t)/t');
    plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,4}]');
    legend(['DelayRequestsFulfilled(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,4}]))]);
    xlabel('Time');
    ylabel('Delay');
    title('Actual Requests (AR): Delay for Fulfilled Requests',...
        'interpreter','None');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR ACTUAL CACHES (AC) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(policy,'VIRTUAL')
    subplot(5,1,3);
else
    subplot(4,1,3);
end
%     plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,5}]'./times,...
%         times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,6}]'./times);
%     legend('VolumeCacheHits(t)/t',...
%         'VolumeCacheEvictions(t)/t');
    plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,5}]',...
        times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,6}]');
    legend(['VolumeCacheHits(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,5}]))],['VolumeCacheEvictions(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,6}]))]);
    xlabel('Time');
    ylabel('Volume');
    title('Actual Caches (AC): Volume of Cache Hits & Evictions',...
        'interpreter','None');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR VIRTUAL QUEUES (VQ) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp('VIRTUAL.BACKPRESSURE.A', policy)
        subplot(5,1,4);
        plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end
    if strcmp('VIRTUAL.BACKPRESSURE.B', policy)
        subplot(5,1,4);
        plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end
    if strcmp('VIRTUAL.BACKPRESSURE.C', policy)
        subplot(5,1,4);
        plot(times,[specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]');
        legend(['VolumeVIPsQueued(t)= ' num2str(mean([specificObject{nodeListNumber:numberOfObjects:totalRowsObjects,7}]))]);
        xlabel('Time');
        ylabel('Volume');
        title('Virtual Queues (VQ): Volume of VIPs Queued',...
            'interpreter','None');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAKE PLOT FOR CACHED OBJECTS (NCOs) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if strfind(policy,'VIRTUAL')
        subplot(5,1,5);
    else
        subplot(4,1,4);
    end
    
    plot(times,[objectSummation{1:(simulationDuration/loggingInterval+1),nodeListNumber}])
    xlabel('Time');
    ylabel('Number Of Cached Nodes');
    title('Cached Status','interpreter','None');
        
    % save plot
    set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8],'Visible','off');
    
    % create title for entire figure
    [ax4,h3]=suplabel(['All nodes for ', specificObject{nodeListNumber,1}],'t');
    set(h3,'FontSize',24);

    % save plot
    set(gcf,'Visible','off');

    %saveas(h,[outputfile, '.fig']);
    print('-dpdf',['All nodes for ', specificObject{nodeListNumber,1}, '.pdf']);
    pdflist{figureCount}=(['All nodes for ', specificObject{nodeListNumber,1}, '.pdf']);
    movefile([foldername, 'All nodes for ', specificObject{nodeListNumber,1}, '.pdf'],[foldername, outputfile,' ',currentTime,'\']);
    close();
    %print('-depsc2',[outputfile, '.eps']);
end

clear cd
cd([foldername, outputfile,' ',currentTime,'\']);
append_pdfs('CombinedFile.pdf',pdflist{:});
cd(foldername);

fprintf('\nDone!');
fprintf('\n\n');

% display end time
display(['End Time: ' datestr(now)])

% % end profile recording
% profile viewer
% profile off
