%Display and record a warning message 
function OptotrakWarning(message)
warning(message);
global opto
opto.warnings{end+1} = {GetSecs, message};