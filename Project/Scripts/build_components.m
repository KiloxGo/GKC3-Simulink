function build_components
% Rebuild the portable Simscape component library from its checked-in source.
projectFolder=fileparts(fileparts(mfilename('fullpath')));
componentFolder=fullfile(projectFolder,'Components');
originalFolder=pwd;
cleanup=onCleanup(@()cd(originalFolder));
cd(componentFolder);
ssc_build('gkc');
addpath(componentFolder);
end
