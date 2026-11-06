function export_integrated_views
% Export every editable integrated-model hierarchy for review and report use.
projectFolder=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(projectFolder,'Materials','Integrated','ModelViews');
if ~isfolder(folder),mkdir(folder);end
model='tokamak_integrated';
scopes=[{model};find_system(model,'FollowLinks','off','LookUnderMasks','none', ...
    'BlockType','SubSystem','Mask','off')];
rows=struct('scope',{},'label',{},'file',{});
for k=1:numel(scopes)
    if k>1 && ~strcmp(get_param(scopes{k},'SFBlockType'),'NONE'),continue;end
    if k==1,name='system';else,name=['sid_' char(extractAfter(Simulink.ID.getSID(scopes{k}),':'))];end
    print(['-s' scopes{k}],'-dpng','-r180',fullfile(folder,[name '.png']));
    rows(end+1)=struct('scope',scopes{k},'label',get_param(scopes{k},'Name'), ...
        'file',[name '.png']); %#ok<AGROW>
end
writetable(struct2table(rows),fullfile(folder,'index.csv'));
end
