function NiiConvert_MPM_Computation_parallel(PathsPipelineConfigFile,NiFti_OutputFolder)

%% Lester Melie-Garcia
% LREN, CHUV. 
% Lausanne, May 18th, 2014

%%  For Nifti Conversion Initializing ...

if ~exist('NiFti_OutputFolder','var')
    %NiFti_OutputFolder = 'M:\CRN\LREN\SHARE\VBQ_Output_All\DataNifti_All\';
    NiFti_OutputFolder ='D:\Users DATA\Users\lester\ZZZ_Nifti_Data_MPMs\';
end;
if ~strcmp(NiFti_OutputFolder(end),filesep)
    NiFti_OutputFolder = [NiFti_OutputFolder,filesep];
end;

NiFti_Server_OutputFolder = 'M:\CRN\LREN\SHARE\VBQ_Output_All\DataNifti_All';
ServerDataFolder = '\\filearc\data\CRN\LREN\IRMMP16\prisma\2014\';

Subj_IDs = make_list_MRI_studies01(ServerDataFolder);

Subj_IDs_MPM = getListofFolders(NiFti_Server_OutputFolder);
BlackList = {'PR01100_AL060680';'PR00298_BD290679';'PR00303_LL030379';'PR00306_LK030379';'`DELETEIT'; ...
             'TEST_LIQUID';'DELETEIT';'deleteit';'PR011195_DC080165';'DELETE IT'}; % Problems for converting Diffusion data ...
         % 'PR01539_ER160503' : subject is repeated , check
Subj_IDs_MPM = vertcat(Subj_IDs_MPM,BlackList);

ind = not(ismember(Subj_IDs(:,1),Subj_IDs_MPM));
Subj_IDs2Compute = Subj_IDs(ind,:);

SubjectFolders = Subj_IDs2Compute(:,1);

Ns = length(SubjectFolders);  % Number of subjects ...

%% For MPMs Computation Initializing ...

if ~exist('PathsPipelineConfigFile','var')
    PathsPipelineConfigFile = which('Preproc_mpm_maps_pipeline_config_paths.txt');
    if isempty(PathsPipelineConfigFile)
        disp('pipeline config file does not exist ! Please specify ...');
        return;
    end;
end;
%[~,ProtocolsFile,MPM_OutputFolder,MPM_Template,ServerFolder,doUNICORT] = Read_Preproc_mpm_maps_config(PipelineConfigFile); %#ok<*STOUT>
[~,ProtocolsFile,PipelineParmsConfigFile,MPM_OutputFolder,ServerFolder] = Read_Preproc_mpm_maps_paths(PathsPipelineConfigFile);
%%
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

%%
jm = findResource('scheduler','type','local'); %#ok
%NiiConvert_MPM_Computation(SubjectFolder,SubjID,NiFti_OutputFolder,NiFti_Server_OutputFolder,ProtocolsFile,PipelineParmsConfigFile,OutputFolder,ServerFolder)
PipelineFunction = 'NiiConvert_MPM_Computation';
for i=1:Ns
    SubjID = SubjectFolders{i};
    JobID = ['job_',check_clean_IDs(SubjID)];
    SubjectFolder = Subj_IDs2Compute{i,2};
    InputParametersF = horzcat({SubjectFolder},{SubjID},{NiFti_OutputFolder},{NiFti_Server_OutputFolder},{ProtocolsFile},{PipelineParmsConfigFile}, ...
                               {MPM_OutputFolder},{ServerFolder}); %#ok
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