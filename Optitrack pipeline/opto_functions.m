function [a] = opto_functions(varargin)

if ~nargin
    error('Requires at least one parameter specifying subfunction!')
end

% switch varargin{1}
%     case 'measure_getList'
%         a = measure_getList(varargin{2:end});
%     case 'measure_getValue'
%         a = measure_getValue(varargin{2:end});
%     case 'measure_getIndAbsAllow'
%         a = measure_getIndAbsAllow(varargin{2:end});
%     case 'measure_getShortform'
%         a = measure_getShortform(varargin{2:end});
%     case 'measure_getIndNoIRED'
%         a = measure_getIndNoIRED(varargin{2:end});
%     otherwise
%         a = nan;
% end

try
    subname = varargin{1};
    if ~ischar(subname) | ~length(subname)
        error('Invalid subfunction name!')
    end
    eval(sprintf('a = %s(varargin{2:end});',varargin{1}))
catch err
    if any(strfind(err.identifier,'UndefinedFunction'))
        err
        error('See above error summary. The most common cause for this error is an incorrect subfunction name or incorrect parameter types.')
    else
        if exist('rethrow','builtin')
            rethrow(err)
        else
            err
            error('See above error summary.')
        end
    end
end

return

function [a] = measure_getList(varargin)
% a = {'X' 'Y' 'Z' 'Velocity' 'Acceleration' 'X-Velocity' ... 
%      'Y-Velocity' 'Z-Velocity' 'Grip Aperture 1' 'Grip Aperture 1 Velocity' ...
%      'Grip Aperture 2' 'Grip Aperture 2 Velocity' 'Grip Aperture 3' 'Grip Aperture 3 Velocity'};
a = {'X' 'Y' 'Z' 'Velocity' 'Acceleration' 'X-Velocity' ... 
     'Y-Velocity' 'Z-Velocity'};
 for ga = 1:3
     for measure = {'' 'Velocity' 'Angle XY' 'Angle XZ' 'Angle YZ'}
         if length(measure{1}), measure{1} = [' ' measure{1}];, end
         a{end+1} = sprintf('Grip Aperture %d%s',ga,measure{1});
     end
 end

function [a] = measure_getValue(varargin)
if nargin < 6
    error('Too few arguments.')
end
odat = varargin{1};
ocalc = varargin{2};
pairsToUse = varargin{3};
name = varargin{4};
ired = varargin{5};
trial = varargin{6};

numFrame = size(odat.X,1);

if any(strfind(name,'Grip Aperture'))
    num = str2num(name(length('Grip Aperture ')+1));
    
    if ~any(pairsToUse==num)
        %error(sprintf('No grip aperture %d was defined!',num))
        a = nan(numFrame,1);
        return
    end
    
    if length(name)==length('Grip Aperture #')
        a = ocalc.gripap.ga{trial}(:,num);
        
    elseif any(strfind(name,'Velocity'))
        a = [0; diff(ocalc.gripap.ga{trial}(:,num))];
        
    elseif any(strfind(name,'Angle XY'))
        [IRED1,IRED2] = parseGripApIRED(ocalc.gripap.IREDs{num});
        dx = odat.X(:,IRED1,trial) - odat.X(:,IRED2,trial);
        dy = odat.Y(:,IRED1,trial) - odat.Y(:,IRED2,trial);
        a = atand(dx./dy);
        a(a<0) = a(a<0) + 360;
        
    elseif any(strfind(name,'Angle XZ'))
        [IRED1,IRED2] = parseGripApIRED(ocalc.gripap.IREDs{num});
        dx = odat.X(:,IRED1,trial) - odat.X(:,IRED2,trial);
        dz = odat.Z(:,IRED1,trial) - odat.Z(:,IRED2,trial);
        a = atand(dx./dz);
        a(a<0) = a(a<0) + 360;
        
    elseif any(strfind(name,'Angle YZ'))
        [IRED1,IRED2] = parseGripApIRED(ocalc.gripap.IREDs{num});
        dy = odat.Y(:,IRED1,trial) - odat.Y(:,IRED2,trial);
        dz = odat.Z(:,IRED1,trial) - odat.Z(:,IRED2,trial);
        a = atand(dy./dz);
        a(a<0) = a(a<0) + 360;
        
    else
        a = nan;
    end
    
else

    switch name
        case 'X'
            a = odat.X(:,ired,trial);
        case 'Y'
            a = odat.Y(:,ired,trial);
        case 'Z'
            a = odat.Z(:,ired,trial);
        case 'Velocity'
            a = odat.V(:,ired,trial);
        case 'Acceleration'
            a = odat.A(:,ired,trial);
        case 'X-Velocity';
            a = [0; diff(odat.X(:,ired,trial))];
        case 'Y-Velocity'
            a = [0; diff(odat.Y(:,ired,trial))];
        case 'Z-Velocity'
            a = [0; diff(odat.Z(:,ired,trial))];
%         case 'Grip Aperture 1'
%             if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
%             a = ocalc.gripap.ga{trial}(:,1);
%         case 'Grip Aperture 1 Velocity'
%             if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
%             a = [0; diff(ocalc.gripap.ga{trial}(:,1))];
%         case 'Grip Aperture 2'
%             if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
%             a = ocalc.gripap.ga{trial}(:,2);
%         case 'Grip Aperture 2 Velocity'
%             if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
%             a = [0; diff(ocalc.gripap.ga{trial}(:,2))];
%         case 'Grip Aperture 3'
%             if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
%             a = ocalc.gripap.ga{trial}(:,3);
%         case 'Grip Aperture 3 Velocity'
%             if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
%             a = [0; diff(ocalc.gripap.ga{trial}(:,3))];
        otherwise
            a = nan;
    end
end
%set infitine values to nan
a(isinf(a)) = nan;

function [a] = measure_getIndAbsAllow(varargin)
a = [];
list = measure_getList;
absAllow = {'Acceleration' 'X-Velocity' 'Y-Velocity' 'Z-Velocity'};
for i = 1:length(absAllow)
    ind = find(strcmp(list,absAllow{i}));
    if ~isempty(ind)
        a(end+1) = ind;
    end
end

function [a] = measure_getShortform(varargin)
if ~length(varargin)
    error('Too few arguments.')
end
name = varargin{1};

if any(strfind(name,'Grip Aperture'))
    name = strrep(name,'Grip Aperture','GA');
    name = strrep(name,'Velocity','Vel');
    name = strrep(name,'Angle','angle');
    name = strrep(name,' ','');
    a = name;
else

    switch name
        case 'X-Velocity';
            a = 'XV';
        case 'Y-Velocity'
            a = 'YV';
        case 'Z-Velocity'
            a = 'ZV';
%         case 'Grip Aperture 1'
%             a = 'GA1';
%         case 'Grip Aperture 1 Velocity'
%             a = 'GA1Vel';
%         case 'Grip Aperture 2'
%             a = 'GA2';
%         case 'Grip Aperture 2 Velocity'
%             a = 'GA2Vel';
%         case 'Grip Aperture 3'
%             a = 'GA3';
%         case 'Grip Aperture 3 Velocity'
%             a = 'GA3Vel';
        otherwise
            if length(name)
                a = name(1);
            else
                a = nan;
            end
    end
    
end


function [a] = measure_getIndNoIRED(varargin)
a = [];
list = measure_getList;
for i = 1:length(list)
    if any(strfind(list{i},'Grip Aperture'))
        a(end+1) = i;
    end
end

%requires 2 inputs:
%1. filepath including extension (.xls or .xlsx)
%2. "xls" struct containing
%   xls.sheet(#).name            *can be string or numeric
%   xls.sheet(#).contents        *must be cell matrix
%
function [a] = xls_write(varargin)
%default returns
a.success = false;
a.message = 'Error: Default Unknown';

%parse
filepath = varargin{2};
xls = varargin{1};

%check: fields (does not check type/contents of fields)
if ~any(strcmp(fields(xls),'sheet'))
    a.message = 'ERROR: xls struct is missing "sheet" field';
    return
elseif ~any(strcmp(fields(xls.sheet),'name'))
    a.message = 'ERROR: xls.sheet struct is missing "name" field';
    return
elseif ~any(strcmp(fields(xls.sheet),'content'))
    a.message = 'ERROR: xls.sheet struct is missing "content" field';
    return    
end

%remove prior excel
if exist(filepath,'file')
    delete(filepath)
end

%create new excel
blankPages = {'Sheet1' 'Sheet2' 'Sheet3'}; %most versions of excel create Sheet1, Sheet2, and Sheet3 by default - will remove these unless they are in use
pageNames = cell(0);
numSheet = length(xls.sheet);
for sheet = 1:numSheet
    
    name = xls.sheet(sheet).name;
    if isempty(name), name = 'Sheet1';, end
    if isnumeric(name), name = num2str(name);, end
    
    ind = find(strcmp(blankPages,name));
    if length(ind)
        blankPages(ind) = [];
    end
    
    if any(strcmp(pageNames,name))
        a.message = 'ERROR: all xls.sheet.name must be unique';
        return    
    end
    
    content = xls.sheet(sheet).content;
    if ~iscell(content)
        a.message = 'ERROR: xls.sheet.content must be a cell matrix';
        return    
    elseif isempty(content)
        a.message = 'ERROR: xls.sheet.content must not be empty';
        return    
    end
    
    pageNames{end+1} = name;
    xlswrite(filepath,content,name);
    
end

%remove extra sheets
try
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(filepath);

    for pageName = blankPages
        try
            objExcel.ActiveWorkbook.Worksheets.Item(pageName{1}).Delete;
        catch
        end
    end
    
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
catch
    warning('An error occured with Excel actxserver when trying to delete unused sheets.')
end

%complete
a.success = true;
a.message = 'Success';

%not meant for external calls
function [IRED1,IRED2] = parseGripApIRED(string)
ind = find(string=='-');
if length(ind)~=1
    IRED1 = nan;
    IRED2 = nan;
else
    IRED1 = str2num(string(1:ind-1));
    if isempty(IRED1), IRED1 = nan;, end
    IRED2 = str2num(string(ind+1:end));
    if isempty(IRED2), IRED2 = nan;, end
end