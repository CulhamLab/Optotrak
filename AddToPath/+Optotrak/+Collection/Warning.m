%Warning(message)
%
%Display and record a warning message 
function Warning(message)
warning(message);
global opto
opto.warnings{end+1} = {GetSecs, message};