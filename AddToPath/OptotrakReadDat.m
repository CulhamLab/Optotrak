%Reads a dat file directly given full filepath, processes the raw data in
%the same way that OTDisplay would and returns the following data structure:
% timestamp (HH:MM:SS DD/MM/YY, time at which sample was recorded - not time of read)
% framerate (per second)
% frame_total
% duration_msec
% number_IREDs
% xyzva (same format as OTDisplay's ascii output)
% array of ired structures containing fields for X, Y, Z, Velocity, and Accelation (same information as xyzva but in another format)
%
%Adapted from: https://motorbehaviour.wordpress.com/2010/11/06/open-optotrak-files-in-matlab/
function [data] = OptotrakReadDat(filepath)

%read header
fid = fopen(filepath, 'r');
fread(fid, 1, 'char');                      % 32
number_IREDs = fread(fid, 1, 'short');      % items per frame
subitem_total = fread(fid, 1, 'short');     % subitems per frame
column_total = number_IREDs * subitem_total;
frame_total = fread(fid, 1, 'int');         % number of frames
framerate = fread(fid, 1, 'float');         % collection frame frequency
fread(fid, 60, 'char=>char');               % user comments
fread(fid, 60, 'char=>char');               % system comments
fread(fid, 30, 'char=>char');               % file description
fread(fid, 1, 'short');                     % cutoff filter frequency
time = fread(fid, 8, 'char=>char')';        % time of collection
fread(fid, 1, 'short');                     % unused?
date = fread(fid, 8, 'char=>char')';         % date of collection
fread(fid, 73, 'char');                     % extended headed and unused

%read data
raw = nan(frame_total,column_total);
for frame_num = 1:frame_total
    for column_num = 1:column_total
        d = fread(fid, 1, 'float');
        if (d < -100000) % technically, it is EE EE EE EE or -3.697314e+28
            d = NaN;
        end
        raw(frame_num,column_num) = d;
    end
end

%close connection
fclose(fid);

%rearrange date from MM/DD/YY to DD/MM/YY
date = date([4 5 3 1 2 6:8]);

%expected subitem_total is 3 for xyz
if subitem_total ~= 3
    warning('File (%s) contains more than 3 measures per IRED. This script will assume that the first 3 are X, Y, and Z but this might not be true. Proceed with caution.', filepath)
end

%store info
data.framerate = framerate;
data.timestamp = [time ' ' date];
data.frame_total = frame_total;
data.number_IREDs = number_IREDs;
data.duration_msec = frame_total / framerate * 1000;

%add vel per IRED, accel per IRED, and overall VD/VA coloumns (leave the last two nan)
%NOTE: velocity and acceleration are /sec (not /frame) (OTDisplay does the same)
number_measures = 5;
data.xyzva = nan(frame_total , (number_IREDs*number_measures) + 2);
data.ired = repmat(struct('X', nan(framerate,1), 'Y', nan(framerate,1), 'Z', nan(framerate,1), 'Velocity', nan(framerate,1), 'Accelation', nan(framerate,1)), [number_IREDs 1]);
for IRED = 1:number_IREDs
    col_in = ((IRED-1)*3)+1;
    col_out = ((IRED-1)*number_measures)+1;
    xyz_this = raw(:,col_in:col_in+2);
    data.xyzva(:,col_out:col_out+2) = round(xyz_this, 1); %accurate to ~10th of a mm (OTDisplay also rounds)
    
    %OTDisplay is doing something different for V and A, hold off on this
% % %     %until sorted out (leave as nan for now)
% % %     pos_dif_squared = (xyz_this(2:end,:) - xyz_this(1:end-1,:)) .^ 2;
% % %     v = [0; sqrt(sqrt(pos_dif_squared(:,1) + pos_dif_squared(:,2)).^2 + pos_dif_squared(:,3))] * framerate;
% % %     a = [0; diff(v)] * framerate;
% % %     data.xyzva(:,col_out+3) = v;
% % %     data.xyzva(:,col_out+4) = a;

    %alternative format
    data.ired(IRED).X = xyz_this(:, 1);
    data.ired(IRED).Y = xyz_this(:, 2);
    data.ired(IRED).Z = xyz_this(:, 3);
% % %     %see above
% % %     data.ired(IRED).Velocity = v;
% % %     data.ired(IRED).Accelation = a;

    data.notice = 'IRED Velocity and Acceleration are set NaN in this file because the method needs to be updated to match OTDisplay''s output.';
end