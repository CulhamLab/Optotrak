function [opto_info] = InitOptotrak(debug_no_hardware_mode)

%% Constants

%% default to use hardware
if ~exist('debug_no_hardware_mode', 'var')
	debug_no_hardware_mode = false;
end

%% Setup
