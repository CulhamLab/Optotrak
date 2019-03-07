%Select one or more Step1 output files to plot.
%One image will be created for each file.
%The image contains the plots of each contained trial in a grid.
function OptoPreview

%% Select Step 1 File(s)
[filenames,directory] = uigetfile('*.mat','Step 1 File(s)','MultiSelect','on');

%% Handle single file
if ~iscell(filenames)
    filenames = {filenames};
end
number_files = length(filenames);

%% Process Each File
for fid = 1:number_files
    %open figure to use
    fig = figure('Position',[1 1 1000 1000]);
    
    %disp
    fn = filenames{fid};
    fprintf('\nFile %d of %d: %s\n', fid, number_files, fn);
    
    %load
    fprintf('-Loading...\n');
    clear odat
    load([directory fn]);
    
    %count
    [number_frames, number_IRED, number_trials] = size(odat.X);
    number_rows = ceil(sqrt(number_trials));
    number_cols = floor(sqrt(number_trials));
    if (number_rows * number_cols) < number_trials
        number_cols = number_cols + 1;
    end
    
    %ranges
    range_x = [nanmin(odat.X(:)) nanmax(odat.X(:))];
    range_y = [nanmin(odat.Y(:)) nanmax(odat.Y(:))];
    range_z = [nanmin(odat.Z(:)) nanmax(odat.Z(:))];
    
    %draw trials
    fprintf('-Plotting trials...\n');
    img = [];
    col = 1;
    row = 1;
    for trial = 1:number_trials
        clf
        
        plot3(odat.X(:,:,trial), odat.Y(:,:,trial), odat.Z(:,:,trial));
        hold on
        for ired = 1:number_IRED
            first_frame = find(odat.X(:,ired,trial), 1, 'first');
            if ~isempty(first_frame)
                text(odat.X(first_frame,ired,trial), odat.Y(first_frame,ired,trial), odat.Z(first_frame,ired,trial),num2str(ired));
            end
        end
        hold off
        
        axis([range_x range_y range_z]);
        axis equal
        
        grid minor
        
        xlabel('X')
        ylabel('Y')
        zlabel('Z')
        
        title(sprintf('Trial %d', trial))
        
        frame = getframe(gcf);
        img_trial = frame2im(frame);
        
        %initialize image on first trial
        if isempty(img)
            img = repmat(zeros(size(img_trial),'uint8'), [number_rows number_cols 1]);
            img_trial_y = 1:size(img_trial,1);
            img_trial_x = 1:size(img_trial,2);
        end
        
        %place in image
        x = img_trial_x + ((col-1) * img_trial_x(end));
        y = img_trial_y + ((row-1) * img_trial_y(end));
        img(y,x,:) = img_trial;
        
        %row col
        col = col + 1;
        if col > number_cols
            col = 1;
            row = row + 1;
        end
    end
    
    %close figure during save
    close(fig)
    
    %save
    fprintf('-Saving image...\n');
    fn_out = strrep(fn, '.mat', '.png');
    imwrite(img, fn_out)
end

%% Done
disp Complete!