function NeuroMorphometric_pipeline_xls_only_parallel(PipelineConfigFile)


%% Lester Melie-Garcia
% LREN, CHUV. 
% Lausanne, May 18th, 2014

if ~exist('PipelineConfigFile','var')
    PipelineConfigFile = which('Neuromorphic_pipeline_config.txt');
    if isempty(PipelineConfigFile)
        disp('pipeline config file does not exist ! Please specify ...');
        return;
    end;
end;

[MPMInputFolder,LocalFolder,AtlasingServerFolder,ProtocolsFile] = Read_NeuroMorphometric_pipeline_config(PipelineConfigFile); %#ok<*STOUT>

if ~strcmp(MPMInputFolder(end),filesep)
     MPMInputFolder = [MPMInputFolder,filesep];
end;
if ~strcmp(AtlasingServerFolder(end),filesep)
     AtlasingServerFolder = [AtlasingServerFolder,filesep];
end;
s = which('spm.m');
if  ~isempty(s)
    spm_path = fileparts(s);
else
    disp('Please add SPM toolbox in the path .... ');
    return;
end;
s = which([mfilename,'.m']);  % pipeline daemon path.
pipeline_daemon_path = fileparts(s);
path_dependencies = {spm_path,pipeline_daemon_path}; %#ok

SubjectFolders = getListofFolders(MPMInputFolder);
% SubjectFolders_Atlasing = getListofFolders(AtlasingServerFolder);
% ind = not(ismember(SubjectFolders,SubjectFolders_Atlasing));
% SubjectFolders = SubjectFolders(ind);

%SubjectFolders = SubjectFolders(1:floor(length(SubjectFolders)/2));

%SubjectFolders = {'PR00393_EL121149';'PR01341_MF140765';'PR01464_AR270257'};
Ns = length(SubjectFolders);  % Number of subjects ...
disp(['Number of Subjects to Run: ',num2str(length(SubjectFolders))]);

%% Sequentially ...
% for i=1:Ns
%     SubjID = SubjectFolders{i};
%     disp([SubjID,' :  ',num2str(i),' of ',num2str(Ns)]);
%     NeuroMorphometric_pipeline_xls_only(SubjID,MPMInputFolder,AtlasingServerFolder,ProtocolsFile);
% end;

%% In parallel
jm = findResource('scheduler','type','local'); %#ok
PipelineFunction = 'NeuroMorphometric_pipeline_xls_only';
for i=1:Ns
    SubjID = SubjectFolders{i};
    JobID = ['job_',check_clean_IDs(SubjID)];
    InputParametersF = horzcat({SubjID},{MPMInputFolder},{AtlasingServerFolder},{ProtocolsFile}); %#ok
    NameField = 'Name'; %#ok
    PathDependenciesField = 'PathDependencies'; %#ok
    createJob_cmd = [JobID,' = createJob(jm,NameField,SubjID);']; % create Job command
    setpathJob_cmd = ['set(',JobID,',','PathDependenciesField',',path_dependencies);']; % set spm path as dependency
    createTask_cmd = ['createTask(',JobID,',@',PipelineFunction,',0,','InputParametersF',');']; % create Task command
    submitJob_cmd = ['submit(',JobID,');']; % submit a job command
    eval(createJob_cmd); eval(setpathJob_cmd); eval(createTask_cmd); eval(submitJob_cmd);
end;
                                            
end

%% ======= Internal Functions ======= %%
function IDout = check_clean_IDs(IDin)

IDout= IDin(isstrprop(IDin,'alphanum'));

end