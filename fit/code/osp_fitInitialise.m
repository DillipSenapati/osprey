function [MRSCont] = osp_fitInitialise(MRSCont)
%% [MRSCont] = osp_fitInitialise(MRSCont)
%   This function initialises default basis sets and decides which
%   metabolites to include in the modeling process carried out by OspreyFit.
%
%   USAGE:
%       [MRSCont] = osp_fitInitialise(MRSCont);
%
%   INPUTS:
%       MRSCont     = Osprey MRS data container.
%
%   OUTPUTS:
%       MRSCont     = Osprey MRS data container.
%
%   AUTHOR:
%       Dr. Georg Oeltzschner (Johns Hopkins University, 2019-02-24)
%       goeltzs1@jhmi.edu
%
%   HISTORY:
%       2019-02-24: First version of the code.

seq = lower(MRSCont.raw{1}.seq);
seq = seq(~ismember(seq, char([10 13]))); % remove return or carriage return

ext = 0; % Set external flag to zero

if strcmp(MRSCont.vendor,'GE') % Still need to find a way to destinguish GE sequences
    seq = 'press';
end
if contains(seq,'gaba_par') || contains(seq,'gaba par')
    seq = 'press';
end
if contains(seq,'press')
    seq = 'press';
end
if contains(seq,'slaser')
    seq = 'slaser';
end

if ~strcmp(seq,'press') && ~strcmp(seq,'slaser') && ~strcmp(seq,'special') %Unable to find the localization type we will assume it is PRESS
    warning('Unable to detect the localization type. We will assume it is PRESS')
    seq = 'press';
end

% Find the right basis set (provided as *.mat file in Osprey basis set
% format)
if ~(isfield(MRSCont.opts.fit,'basisSetFile') && ~isempty(MRSCont.opts.fit.basisSetFile) && ~isfolder(MRSCont.opts.fit.basisSetFile))

    % Extract TE, B0, and sequence from first dataset
    te = num2str(MRSCont.raw{1}.te);
    Bo = MRSCont.raw{1}.Bo;
    if (Bo >= 2.8 && Bo < 3.1)
        Bo = '3T';
    else
        Bo = '7T';
    end
    % Intercept non-integer echo times and replace the decimal point with
    % an underscore to avoid file extension problems
    if contains(te, '.')
        te = strrep(te, '.', '_');
    end
    if (ismcc || isdeployed)
        if isempty(MRSCont.opts.fit.basissetFolder)
            info = 'Select the folder that contains all basis set files';           
            ndata = 1;
            MRSCont.opts.fit.basissetFolder  = spm_select(ndata,'dir',info,{},pwd);
        end
        if MRSCont.flags.isUnEdited
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/philips/unedited/' seq '/' te '/basis_philips_' seq te '.mat'];
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/ge/unedited/' seq '/' te '/basis_ge_' seq te '.mat'];
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/unedited/' seq '/' te '/basis_siemens_' seq te '.mat'];
            end
        elseif MRSCont.flags.isMEGA
            editTarget = lower(MRSCont.opts.editTarget{1});
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/philips/mega/' seq '/' editTarget te '/basis_philips_megapress_' editTarget te '.mat'];
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/ge/mega/' seq '/' editTarget te '/basis_ge_megapress_' editTarget te '.mat'];
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/mega/' seq '/' editTarget te '/basis_siemens_megapress_' editTarget te '.mat'];
            end
        elseif MRSCont.flags.isHERMES
            editTarget1 = lower(MRSCont.opts.editTarget{1});
            editTarget2 = lower(MRSCont.opts.editTarget{2});
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat'];
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat'];
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat'];
            end
        elseif MRSCont.flags.isHERCULES
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/philips/hercules-press/basis_philips_hercules-press.mat'];
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/ge/hercules-press/basis_ge_hercules-press.mat'];
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = [MRSCont.opts.fit.basissetFolder '/' Bo '/siemens/hercules-press/basis_siemens_hercules-press.mat'];
            end
        end
    else
        if MRSCont.flags.isUnEdited
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/philips/unedited/' seq '/' te '/basis_philips_' seq te '.mat']);
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/ge/unedited/' seq '/' te '/basis_ge_' seq te '.mat']);
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = which(['fit/basissets/' Bo '/siemens/unedited/' seq '/' te '/basis_siemens_' seq te '.mat']);
            end
        elseif MRSCont.flags.isMEGA
            editTarget = lower(MRSCont.opts.editTarget{1});
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/philips/mega/' seq '/' editTarget te '/basis_philips_megapress_' editTarget te '.mat']);
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/ge/mega/' seq '/' editTarget te '/basis_ge_megapress_' editTarget te '.mat']);
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/siemens/mega/' seq '/' editTarget te '/basis_siemens_megapress_' editTarget te '.mat']);
            end
        elseif MRSCont.flags.isHERMES
            editTarget1 = lower(MRSCont.opts.editTarget{1});
            editTarget2 = lower(MRSCont.opts.editTarget{2});
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat']);
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat']);
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/siemens/hermes/' editTarget1 editTarget2 '/basis_siemens_hermes.mat']);
            end
        elseif MRSCont.flags.isHERCULES
            switch MRSCont.vendor
                case 'Philips'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/philips/hercules-press/basis_philips_hercules-press.mat']);
                case 'GE'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/ge/hercules-press/basis_ge_hercules-press.mat']);
                case 'Siemens'
                    MRSCont.opts.fit.basisSetFile        = which(['/basissets/' Bo '/siemens/hercules-press/basis_siemens_hercules-press.mat']);
            end
        end
    end
else
    ext = 1;
end
% Clear existing basis set
MRSCont.fit.basisSet = [];

% Check if automated basis set pick worked, otherwise the basis set from
% the user folder is loaded.
if isfield(MRSCont.opts.fit, 'basisSetFile') && ~strcmpi(MRSCont.opts.fit.method, 'LCModel')
    if isempty(MRSCont.opts.fit.basisSetFile)
        if ~(ismcc || isdeployed)
            addpath(which('/basissets'));
        end
        if (ismcc || isdeployed)
            MRSCont.opts.fit.basisSetFile = which([MRSCont.opts.fit.basissetFolder '/user/BASIS_noMM.mat']);
        else
            MRSCont.opts.fit.basisSetFile = which('/basissets/user/BASIS_noMM.mat');
        end
        if isempty(MRSCont.opts.fit.basisSetFile)
            error('There is no appropriate basis set to model your data. Please supply a sufficient basis set in Osprey .mat format in the fit/basissets/user/BASIS_MM.mat file! Or supply a .BASIS file for LCModel ');
        else
            ext = 1;
        end
        
    end
end

% The workflow will differ depending on whether we fit entirely within
% Osprey, or whether we are wrapping the LCModel binaries.
switch MRSCont.opts.fit.method

    % ------ OPTION OSPREY -----
    case 'Osprey'

        % Load the specified basis set or the user basis set file
        basisSet = load(MRSCont.opts.fit.basisSetFile);
        basisSet = basisSet.BASIS;

        % Add basis spectra (if they were removed to reduce thhe file size)
        if ~isfield(basisSet,'specs')
            [basisSet]=osp_recalculate_basis_specs(basisSet);
        end

        % Generate the list of basis functions that are supposed to be included in
        % the basis set
        if ext
            % Sort basis set file according to Osprey conventions
            basisSet = fit_sortBasisSet(basisSet);

            % To do: Interface with interactive user input
            metabList = fit_createMetabList(MRSCont.opts.fit.includeMetabs);
            % Collect MMfit flag from the options determined in the job file
            fitMM = MRSCont.opts.fit.fitMM;
            % Create the modified basis set
            basisSet = fit_selectMetabs(basisSet, metabList, fitMM);
        else
            % To do: Interface with interactive user input
            basisSet = fit_sortBasisSet(basisSet);
            metabList = fit_createMetabList(MRSCont.opts.fit.includeMetabs);
            % Collect MMfit flag from the options determined in the job file
            fitMM = MRSCont.opts.fit.fitMM;
            % Create the modified basis set
            basisSet = fit_selectMetabs(basisSet, metabList, fitMM);
        end

        % Determine the scaling factor between data and basis set for each dataset
        for kk = 1:MRSCont.nDatasets(1)
            if ~MRSCont.flags.isMRSI  && ~MRSCont.flags.isPRIAM
                if ~MRSCont.flags.isUnEdited
                    dataToScale   = op_takesubspec(MRSCont.processed.metab{kk},1);
                else
                    dataToScale   = MRSCont.processed.metab{kk};
                end
                MRSCont.fit.scale{kk} = max(real(dataToScale.specs)) / max(max(max(real(basisSet.specs))));
            else
                MRSCont.fit.scale{kk} = max(max(max(real(MRSCont.processed.A{kk}.specs)))) / max(max(max(real(basisSet.specs))));
            end
        end


        % Save the modified basis set
        MRSCont.fit.basisSet = basisSet;



    % ------ OPTION LCMODEL -----
    case 'LCModel'
        %Write a sequence name into the fit struct as it is needed for some
        %downstream functions
        MRSCont.fit.basisSet.seq{1} = seq;
        % For now, the user needs to EXPLICITLY specify a basis set. We
        % will weave in the automatic selection as we convert more and more
        % basis sets to LCModel format.
        % (GO 07/08/2021)


        if ~(isfield(MRSCont.opts.fit,'basisSetFile') && ~isempty(MRSCont.opts.fit.basisSetFile))

            % The only exception are LCModel sptype settings (like lipid-8)
            % which don't use external basis functions at all.
            % These modes, however, still require a dummy basis set to be
            % input.
            %
            % Intercept these cases here
            % Read in the user-supplied control file (if there is one)
            if isfield(MRSCont.opts.fit,'controlFile')
                if ~isempty(MRSCont.opts.fit.controlFile)
                    % Load all control parameters
                    LCMparam = osp_readlcm_control(MRSCont.opts.fit.controlFile);

                    if isfield(LCMparam, 'sptype')
                        switch LCMparam.sptype
                            case {'''lipid-8''', '''liver-11''', '''breast-8''', '''only-cho-2'''}
                                % Use any .basis file that comes with Osprey. It
                                % doesn't matter which - we only need a dummy
                                % input. (LCModel manual, Sec 9.3)
                                basisSetFile = which('3T_PRESS_Philips_35ms_noMM.BASIS');
                            otherwise
                                basisSetFile = LCMparam.filbas;
                        end
                    end

                end
            else
                error('For LCModel fitting, please explicitly specify a .BASIS file in the job file (opts.fit.basisSetFile = ''FILE'').');
            end

        else
            
            % If a basis set file is supplied, use it.
            % We need to determine whether the basis set is already
            % provided in .BASIS format, or whether it is supplied in
            % Osprey format (.mat), in which case we'll convert it.
            [path, ~, exten] = fileparts(MRSCont.opts.fit.basisSetFile);
            if strcmpi(exten,'.mat')
                % If it has the .mat extension, convert from Osprey format
                % to LCModel format (.basis)
                basisSet = load(MRSCont.opts.fit.basisSetFile);
                basisSet = basisSet.BASIS;
                % Add basis spectra (if they were removed to reduce thhe file size)
                if ~isfield(basisSet,'specs')
                    [basisSet]=osp_recalculate_basis_specs(basisSet);
                end
                [~]      = io_writelcmBASIS(basisSet,[path filesep Bo '_' seq '_' MRSCont.vendor '_' te 'ms_noMM.BASIS'], MRSCont.vendor, seq);
                % Save the newly generated .basis file back into the
                % container.
                MRSCont.opts.fit.basisSetFile = [path filesep Bo '_' seq '_' MRSCont.vendor '_' te 'ms_noMM.BASIS'];
            elseif strcmpi(exten, '.basis')
                % If it has the .basis extension, we don't have to change
                % anything.
            else
                error('For LCModel fitting, please explicitly specify a .BASIS or .MAT file in the job file (opts.fit.basisSetFile = ''FILE'').');
            end
            basisSetFile = MRSCont.opts.fit.basisSetFile;


        end

        % Read in the user-supplied control file (if there is one)
        if isfield(MRSCont.opts.fit,'controlFile')
            if ~isempty(MRSCont.opts.fit.controlFile)
                % Load all control parameters
                LCMparam = osp_readlcm_control(MRSCont.opts.fit.controlFile);

                % Make some changes to the control file that will apply to
                % ALL control files
                LCMparam = osp_editControlParameters(LCMparam, 'lprint', '6');
                LCMparam = osp_editControlParameters(LCMparam, 'lcoord', '9');
                LCMparam = osp_editControlParameters(LCMparam, 'ltable', '7');
                LCMparam = osp_editControlParameters(LCMparam, 'lcsv', '11');
                LCMparam = osp_editControlParameters(LCMparam, 'neach', '99');
                LCMparam = osp_editControlParameters(LCMparam, 'chcomb', {'''PCh+GPC''','''Cr+PCr''','''NAA+NAAG''','''Glu+Gln''','''Glc+Tau'''});
                LCMparam = osp_editControlParameters(LCMparam, 'filraw', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filtab', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filps', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filcsv', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filcoo', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filbas', ['''' basisSetFile '''']);
                LCMparam = osp_editControlParameters(LCMparam, 'savdir', '');
                LCMparam = osp_editControlParameters(LCMparam, 'lcsi_sav_1', '');
                LCMparam = osp_editControlParameters(LCMparam, 'lcsi_sav_2', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filcsi_sav_1', '');
                LCMparam = osp_editControlParameters(LCMparam, 'filcsi_sav_2', '');
                LCMparam = osp_editControlParameters(LCMparam, 'ndslic', '');
                LCMparam = osp_editControlParameters(LCMparam, 'ndrows', '');
                LCMparam = osp_editControlParameters(LCMparam, 'ndcols', '');
                LCMparam = osp_editControlParameters(LCMparam, 'islice', '');
                LCMparam = osp_editControlParameters(LCMparam, 'irowst', '');
                LCMparam = osp_editControlParameters(LCMparam, 'irowen', '');
                LCMparam = osp_editControlParameters(LCMparam, 'icolst', '');
                LCMparam = osp_editControlParameters(LCMparam, 'icolen', '');
                
                % Add water-scaling-related flags only if water reference
                % data has been provided
                if MRSCont.flags.hasRef || MRSCont.flags.hasWater
                    LCMparam = osp_editControlParameters(LCMparam, 'dows', 'T');
                    LCMparam = osp_editControlParameters(LCMparam, 'atth2o', '1.0');
                    LCMparam = osp_editControlParameters(LCMparam, 'attmet', '1.0');
                    LCMparam = osp_editControlParameters(LCMparam, 'wconc', '55556');
                    LCMparam = osp_editControlParameters(LCMparam, 'doecc', 'F');
                end
                
                % Now loop over all datasets
                for kk = 1:MRSCont.nDatasets
                    
                    % Write control file
                    MRSCont = osp_writelcm_control(MRSCont, kk, 'A', LCMparam);

                end

            else
                error('The field ''opts.fit.controlFile'' in the job file is specified, but empty.')
            end

        else

            % If the field does not exist, write default control parameters
            for kk = 1:MRSCont.nDatasets
                
                LCMparam = [];
                LCMparam = osp_editControlParameters(LCMparam, 'srcraw', ['''' MRSCont.files{kk} '''']);
                LCMparam = osp_editControlParameters(LCMparam, 'lprint', '6');
                LCMparam = osp_editControlParameters(LCMparam, 'lcoord', '9');
                LCMparam = osp_editControlParameters(LCMparam, 'ltable', '7');
                LCMparam = osp_editControlParameters(LCMparam, 'lcsv', '11');
                LCMparam = osp_editControlParameters(LCMparam, 'key', '210387309');
                LCMparam = osp_editControlParameters(LCMparam, 'owner', '''Osprey processed spectra''');
                LCMparam = osp_editControlParameters(LCMparam, 'filbas', ['''' basisSetFile '''']);
                LCMparam = osp_editControlParameters(LCMparam, 'dkntmn', '0.15');
                LCMparam = osp_editControlParameters(LCMparam, 'neach', '99');
                %LCMparam = osp_editControlParameters(LCMparam, 'wdline', '0');
                LCMparam = osp_editControlParameters(LCMparam, 'nsimul', '12');
                LCMparam = osp_editControlParameters(LCMparam, 'chcomb', {'''PCh+GPC''','''Cr+PCr''','''NAA+NAAG''','''Glu+Gln''','''Glc+Tau'''});
                LCMparam = osp_editControlParameters(LCMparam, 'chomit', {'''Gly''','''Ser'''});
                LCMparam = osp_editControlParameters(LCMparam, 'namrel', '''Cr+PCr''');
                LCMparam = osp_editControlParameters(LCMparam, 'ppmst',  ['' sprintf('%4.2f', MRSCont.opts.fit.range(2)) '']);
                LCMparam = osp_editControlParameters(LCMparam, 'ppmend', ['' sprintf('%4.2f', MRSCont.opts.fit.range(1)) '']);

                % Add water-scaling-related flags only if water reference
                % data has been provided
                if MRSCont.flags.hasRef || MRSCont.flags.hasWater
                    LCMparam = osp_editControlParameters(LCMparam, 'dows', 'T');
                    LCMparam = osp_editControlParameters(LCMparam, 'atth2o', '1.0');
                    LCMparam = osp_editControlParameters(LCMparam, 'attmet', '1.0');
                    LCMparam = osp_editControlParameters(LCMparam, 'wconc', '55556');
                    LCMparam = osp_editControlParameters(LCMparam, 'doecc', 'F');
                end
                
                % Write control file
                MRSCont = osp_writelcm_control(MRSCont, kk, 'A', LCMparam);
                
            end
        end



end

end
function [basisSet]=osp_recalculate_basis_specs(basisSet)
    % This function recalculates the basis spectra and ppm-axis of the
    % basis set

    basisSet.specs = fftshift(fft(basisSet.fids,[],1),1);

    % Calcualte ppm-axis
    f = [(-basisSet.spectralwidth/2)+(basisSet.spectralwidth/(2*basisSet.sz(1))):basisSet.spectralwidth/(basisSet.sz(1)):(basisSet.spectralwidth/2)-(basisSet.spectralwidth/(2*basisSet.sz(1)))];
    basisSet.ppm = f/(basisSet.Bo*42.577);
    basisSet.ppm=basisSet.ppm + basisSet.centerFreq;
end