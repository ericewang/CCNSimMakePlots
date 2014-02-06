% Plot CCNSim output data that has been loaded into
% the current MATLAB workspace.
% Run "ccnsimloaddata" before this script.
% For convenience, the generated plots are saved in a PDF file.

fprintf('\nPlotting data...');

% get selected policy 
policy = paramsMap('[GENERAL]:policy');

% set figure size
scrsz = get(0,'ScreenSize');
h = figure('OuterPosition',[0,0.1*scrsz(4),scrsz(3)/2,0.9*scrsz(4)]); % left,bottom,width,height

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) MAKE PLOT FOR ACTUAL REQUESTS (AR) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(4,1,1);
plot(times,AR_raw(:,1)./times,...
	times,AR_raw(:,2)./times);
legend('VolumeRequestsCreated(t)/t',...
	'VolumeRequestsFulfilled(t)/t');
xlabel('Time');
ylabel('Volume');
title('Actual Requests (AR): Volume of Requests Created & Fulfilled',...
	'interpreter','None');

subplot(4,1,2);
plot(times,AR_raw(:,3)./times);
legend('DelayRequestsFulfilled(t)/t');
xlabel('Time');
ylabel('Delay');
title('Actual Requests (AR): Delay for Fulfilled Requests',...
	'interpreter','None');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2) MAKE PLOT FOR ACTUAL CACHES (AC) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(4,1,3);
plot(times,AC_raw(:,1)./times,...
	times,AC_raw(:,2)./times);
legend('VolumeCacheHits(t)/t',...
	'VolumeCacheEvictions(t)/t');
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
	legend('VolumeVIPsQueued(t)');
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

text(-0.05,-0.4,...
	paramsSummary,...
	'units','normalized',...
	'interpreter','None',...
	'FontSize',7);

% save plot
set(gcf,'PaperPosition',[0.1 0.1 8.3 10.8]);
%saveas(h,[outputfile, '.fig']);
print('-dpdf',[outputfile, '.pdf']);
%print('-depsc2',[outputfile, '.eps']);

fprintf('\nDone!');
fprintf('\n\n');
