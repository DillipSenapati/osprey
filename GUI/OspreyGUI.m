classdef OspreyGUI < handle
%% OspreyGUI
%   This class creates a one-in-all figure with visualizations of the
%   processed data (spectra in the frequency domain), voxel coregistration
%   and segmentation, quantification tables, and results.
%
%   The figure contains several tabs, not all of which may be available at
%   all times:
%       - Data
%       - Processed
%       - Coregistration and segmentation
%       - Fit
%       - Quantification
%       - Overview
%
%   As an example, if coregistration and segmentation have not been
%   performed, the respective tab will be grayed out.
%
%   USAGE:
%       OspreyGUIapp;
%
%
%   AUTHORS:
%       Dr. Helge Zoellner (Johns Hopkins University, 2019-11-07)
%       hzoelln2@jhmi.edu
%
%   CREDITS:
%       This code is based on numerous functions from the FID-A toolbox by
%       Dr. Jamie Near (McGill University)
%       https://github.com/CIC-methods/FID-A
%       Simpson et al., Magn Reson Med 77:23-33 (2017)
%
%   HISTORY:
%       2020-01-13: First version of the code.

 %% Properties
 % Here the properties for the gui class are defined
    properties
        MRSCont % MRS container with data
        folder % all folders
        colormap % colormaps for gui and
        controls % gui control handles
        waitbar % waitbar values
        info % stores some info about the acquisition
        load % OspreyLoad infos
        process %  OspreyProcess infos
        fit % OspreyFit infos
        quant % OspreyQuant infos
        overview % OspreyOverview infos
        figure % figure handle
        layout % Layout infos
        upperBox % contains upper part of gui
        Plot % plot struct
        InfoText % info text struct (left side of fit plot)
        Results % result struct (fit results)
        flags; % Store flags 
        font; % Stores font type
    end

    methods

        function gui = OspreyGUI(MRSCont)
        % This is the "constructor" for the class
        % It runs when an object of this class is created
        %% Catch empty call
        if nargin == 0
            error('No MRS container supplied. Please call the OspreyGUI with a MRS container as argument.')
        end
        %% Initialize variables
        % Close any remaining open figures & add folders
            close all;
            font=osp_platform('fonts');
            gui.font = font.helvetica;
            [settingsFolder,~,~] = fileparts(which('OspreySettings.m'));
            gui.folder.allFolders      = strsplit(settingsFolder, filesep);
            gui.folder.ospFolder       = strjoin(gui.folder.allFolders(1:end-1), filesep); % parent folder (= Osprey folder)
            MRSCont.flags.moved = 0;
            if isfile(fullfile(MRSCont.outputFolder, 'LogFile.txt'))
                MRSCont.flags.moved = 0;
                diary(fullfile(MRSCont.outputFolder, 'LogFile.txt'));
            else %The MRSContainer has been moved, so we will store the the diary in the GUI folder
                diary(fullfile(gui.folder.ospFolder, 'LogFile.txt'));
                MRSCont.flags.moved = 1;
                if (isfield(MRSCont.flags,'addImages') && (MRSCont.flags.addImages == 0))
                    MRSCont.flags.didCoreg = 0;
                    MRSCont.flags.didSeg = 0;
                end
            end
            diary off
            
            % This is for the compiled GUI
            MRSCont.flags.hasSPM = 1; 
            
        % Toolbox check
            if isfield(MRSCont.flags,'isToolChecked')
                [MRSCont.flags.hasSPM,MRSCont.ver.CheckOsp] = osp_Toolbox_Check ('OspreyGUI',MRSCont.flags.isToolChecked);
            else
                [MRSCont.flags.hasSPM,MRSCont.ver.CheckOsp] = osp_Toolbox_Check ('OspreyGUI',0);
                MRSCont.flags.isToolChecked = 1;
            end
              
    % Show warning if the version is different
       if ~strcmp(MRSCont.ver.Osp,MRSCont.ver.CheckOsp)  
            opts.WindowStyle = 'replace';
            opts.Interpreter = 'tex';
            f = errordlg('The Osprey version of your MRS container is different from the Osprey version you are using. Please consider re-running the analysis to ensure full functionality. Osprey v.2 is not compatible with any earlier versions.','Version mismatch',opts);           
       end

           
       % Load selected colormap
        gui.colormap = MRSCont.colormap;

        % Set GM plot to on
        gui.controls.GM = 1;
        
        %Load flags
        gui.flags = MRSCont.flags;

        %Setting up inital values for the gui control variables
        %Global controls
            gui.controls.Selected = 1;
            gui.controls.Tab = 1;
            gui.controls.Number = 1;
            gui.controls.KeyPress = 0;
        %File selections for each sub function
            gui.load.Selected = 1;
            gui.process.Selected = 1;
            gui.fit.Selected = 1;
            gui.quant.Selected.Model = 1;
            gui.quant.Selected.Quant = 1;
            gui.overview.Selected.Metab = 1;
            gui.controls.act_Exp = 1;
            gui.controls.act_x = 1;
            gui.controls.act_y = 1;
            gui.controls.act_z = 1;
            gui.controls.act_basis = 1;
        %Names for each selection
            gui.load.Names.Spec = {'metabolites'};
        %Inital number of datasets
        if isfield(MRSCont, 'nDatasets')
            gui.controls.nDatasets = MRSCont.nDatasets(1);
            if size(MRSCont.nDatasets,2) > 1
                gui.controls.nExperiments = MRSCont.nDatasets(2);
            else
                gui.controls.nExperiments = 1;
            end                
        else
            gui.controls.nDatasets = 0;
            gui.controls.nExperiments = 1;
        end

        %Setting up remaining values in dependence of the conducted processing steps
            if MRSCont.flags.didLoad %Get variables regarding the loading
                if ~isempty(MRSCont.raw{1,gui.controls.Selected}.seq)
                    if strcmp(sprintf('\n'),MRSCont.raw{1,gui.controls.Selected}.seq(end)) %Clean up Sequence Name if needed
                        gui.load.Names.Seq = MRSCont.raw{1,gui.controls.Selected}.seq(1:end-1);
                    else
                        gui.load.Names.Seq = MRSCont.raw{1,gui.controls.Selected}.seq;
                    end
                else
                    if MRSCont.flags.isUnEdited
                        gui.load.Names.Seq =['Unedited ' MRSCont.vendor];
                    end
                    if MRSCont.flags.isMEGA
                        gui.load.Names.Seq =['MEGA ' MRSCont.vendor];
                    end
                    if MRSCont.flags.isHERMES
                        gui.load.Names.Seq =['HERMES ' MRSCont.vendor];
                    end
                    if MRSCont.flags.isHERCULES
                        gui.load.Names.Seq =['HERCULES ' MRSCont.vendor];
                    end
                    if MRSCont.flags.isPRIAM
                        gui.load.Names.Seq =['PRIAM ' MRSCont.vendor];
                    end
                    if MRSCont.flags.isMRSI
                        gui.load.Names.Seq =['MRSI ' MRSCont.vendor];
                    end
                end
                try
                    gui.load.Names.Geom = fieldnames(MRSCont.raw{1,1}.geometry.size); %Get variables regarding voxel geometry
                catch
                end
            end

            if MRSCont.flags.isPRIAM
                try
                    gui.info.nXvoxels = MRSCont.raw{1,gui.controls.Selected}.nXvoxels;
                    gui.info.nYvoxels = MRSCont.raw{1,gui.controls.Selected}.nYvoxels;
                    gui.info.nZvoxels = MRSCont.raw{1,gui.controls.Selected}.nZvoxels;
                catch
                end
            end
            if MRSCont.flags.isMRSI
                try
                    gui.info.nXvoxels = MRSCont.raw{1,gui.controls.Selected}.nXvoxels;
                    gui.info.nYvoxels = MRSCont.raw{1,gui.controls.Selected}.nYvoxels;
                    gui.info.nZvoxels = MRSCont.raw{1,gui.controls.Selected}.nZvoxels;
                catch
                end
            end
            
            if gui.controls.nExperiments > 1
                gui.info.nXvoxels = gui.controls.nExperiments;
                gui.info.nExperiments = gui.controls.nExperiments;
            end
            if MRSCont.flags.didProcess %Get variables regarding the processing
                gui.process.Number = length(fieldnames(MRSCont.processed));
                gui.info.nYvoxels = MRSCont.processed.metab{1, 1}.subspecs;
                gui.process.Names = fieldnames(MRSCont.processed);
            end

            if MRSCont.flags.didFit %Get variables regarding the fitting                
                if (isfield(MRSCont.flags, 'isPRIAM') || isfield(MRSCont.flags, 'isMRSI')) &&  (MRSCont.flags.isPRIAM || MRSCont.flags.isMRSI)
                    gui.fit.Names = fieldnames(MRSCont.fit.results{1});
                    gui.fit.Number = length(fieldnames(MRSCont.fit.results{1}));
                else
                    gui.fit.Names = fieldnames(MRSCont.fit.results);
                    gui.fit.Number = length(fieldnames(MRSCont.fit.results)); 
                    gui.controls.act_y = size(MRSCont.fit.results.metab.fitParams,3);
                    gui.info.nYvoxels = size(MRSCont.fit.results.metab.fitParams,3);
                    gui.info.nZvoxels = size(MRSCont.fit.results.metab.fitParams,1);
                end
            end

            if MRSCont.flags.didQuantify && ~MRSCont.flags.isMRSI %Get variables regarding the quantification
                gui.quant.Number.Model = length(fieldnames(MRSCont.quantify.tables));
                gui.quant.Names.Model = fieldnames(MRSCont.quantify.tables);
                gui.quant.Number.Quants = length(fieldnames(MRSCont.quantify.tables.(gui.quant.Names.Model{1})));
                gui.quant.Names.Quants = fieldnames(MRSCont.quantify.tables.(gui.quant.Names.Model{1}));
                gui.quant.Number.Metabs = length(MRSCont.quantify.names.(gui.quant.Names.Model{1}));
                gui.quant.Selected.Metab = find(strcmp(MRSCont.quantify.names.(gui.quant.Names.Model{1}), 'tNAA'));
                gui.quant.Selected.Model = 1;
                gui.quant.idx.GABA = find(strcmp(MRSCont.quantify.names.(gui.quant.Names.Model{1}), 'GABA'));
            elseif MRSCont.flags.didQuantify
                gui.quant.Number.Model = length(fieldnames(MRSCont.quantify.amplMets{1, 1}));
                gui.quant.Names.Model = fieldnames(MRSCont.quantify.amplMets{1, 1});
%                 gui.quant.Number.Quants = 1;
%                 gui.quant.Names.Quants = {};
                for m = 1 : gui.quant.Number.Model
                    gui.quant.Number.Metabs.(gui.quant.Names.Model{m}) = length(MRSCont.quantify.metabs.(gui.quant.Names.Model{m}));
                    gui.quant.Names.Metabs.(gui.quant.Names.Model{m}) = MRSCont.quantify.metabs.(gui.quant.Names.Model{m});
                end
                gui.quant.Selected.Metab = {'NAA'};
                gui.quant.Selected.Model = 1;
                gui.quant.idx.GABA = find(strcmp(gui.quant.Number.Metabs.(gui.quant.Names.Model{1}), 'GABA'));
            end
            if MRSCont.flags.didOverview %Get variables for the overview tab
                gui.overview.NAAnormed = 1;
                gui.overview.Number.Groups = MRSCont.overview.NoGroups;
                [gui.colormap.cb] = cbrewer('qual', 'Dark2', 12, 'pchip');
                temp = gui.colormap.cb(3,:);
                gui.colormap.cb(3,:) = gui.colormap.cb(4,:);
                gui.colormap.cb(4,:) = temp;
                if isfield(MRSCont.overview, 'corr')
                    gui.overview.Names.Corr = MRSCont.overview.corr.Names;
                    gui.overview.CorrMeas = MRSCont.overview.corr.Meas;
                end
                gui.overview.Selected.Corr = 1;
                gui.overview.Selected.CorrChoice = 1;
                gui.overview.Names.QM = {'SNR','FWHM (ppm)'};
                
                if ~MRSCont.flags.didFit %Get variables regarding the fitting
                    gui.fit.Number = length(fieldnames(MRSCont.processed));
                    gui.fit.Names = fieldnames(MRSCont.processed);
                end
                
            end
            gui.waitbar.overall = MRSCont.flags.didLoad+MRSCont.flags.didProcess+MRSCont.flags.didFit+MRSCont.flags.didCoreg+MRSCont.flags.didSeg+MRSCont.flags.didQuantify+MRSCont.flags.didOverview;
            gui.waitbar.step = 1/ gui.waitbar.overall;

            %Version check and updating log file
            MRSCont.flags.isGUI = 1;
            outputFolder = MRSCont.outputFolder;
            
            %Add cosmetics
            MRSCont.opts.cosmetics.LB = 0;
            MRSCont.opts.cosmetics.Zoom = 2.75;
            %% Create the overall figure            
            gui.figure = figure('Name', 'Osprey', 'Tag', 'Osprey', 'NumberTitle', 'off', 'Visible', 'on','Menu', 'none',...
                                'ToolBar', 'none', 'HandleVisibility', 'on', 'Renderer', 'painters', 'Color', gui.colormap.Background);
            setappdata(gui.figure,'MRSCont',MRSCont);
            % Delete old waitbar first
            h = findall(groot,'Type','figure');
            for ff = 1 : length(h)
                if ~(strcmp(h(ff).Tag, 'Osprey'))
                    close(h(ff))
                end
            end
        % Resize such that width is 1.2941 * height (1.2941 is the ratio
        % between width and height of standard US letter size (11x8.5 in).
            screenSize      = get(0,'ScreenSize');
            canvasSize      = screenSize;
            canvasSize(4)   = screenSize(4) * 1;
            canvasSize(3)   = canvasSize(3) * (0.9);
            canvasSize(2)   = (screenSize(4) - canvasSize(4))/2;
            canvasSize(1)   = (screenSize(3) - canvasSize(3))/2;
            set(gui.figure, 'Position', canvasSize);

        % Create the main horizontal box division between menu (left) and display
        % panel tabs (right)
            gui.layout.mainLayout = uix.HBox('Parent', gui.figure,'BackgroundColor',gui.colormap.Background,'Tag','MainBox');
        % Create the left-side menu
            gui.layout.leftMenu = uix.VBox('Parent',gui.layout.mainLayout, 'Padding',4,'Spacing', 2,'BackgroundColor',gui.colormap.Background,'Tag','LeftMenu');
            gui.layout.Buttonbox = uix.HBox('Parent',gui.layout.leftMenu, 'BackgroundColor',gui.colormap.Background,'Tag','LeftButtonBox');
            gui.layout.b_about = uicontrol(gui.layout.Buttonbox,'Style','PushButton','Tag','AboutButton');
            [img, ~, ~] = imread('osprey.png', 'BackgroundColor', gui.colormap.Background);
            [img2] = imresize(img, 0.08);
            set(gui.layout.b_about,'CData', img2, 'TooltipString', 'Contact developers via mail');
            set(gui.layout.b_about,'Callback',{@osp_onOsp});


           gui.layout.Infobuttons = uix.VButtonBox('Parent',gui.layout.Buttonbox,'BackgroundColor',gui.colormap.Background,'Tag','InfoButtonBox');
        % Divide into the upper panel containing the Osprey logo button

           gui.layout.b_pub = uicontrol(gui.layout.Infobuttons,'Style','PushButton','Tag','InfoButton');
           [img, ~, ~] = imread('PubMed.png', 'BackgroundColor', gui.colormap.Background);
           [img2] = imresize(img, 0.06);
           set(gui.layout.b_pub,'CData', img2, 'TooltipString', 'Cite these papers when using Osprey');
           set(gui.layout.b_pub,'Callback',{@osp_onPub});

            gui.layout.b_git = uicontrol(gui.layout.Infobuttons,'Style','PushButton','Tag','GitHubButton');
           [img, ~, ~] = imread('GitHubB.png', 'BackgroundColor', gui.colormap.Background);
           [img2] = imresize(img, 0.07);
           set(gui.layout.b_git,'CData', img2, 'TooltipString', 'Keep yourself updated and request/develop new features on GitHub');
           set(gui.layout.b_git,'Callback',{@osp_onGit});

           set(gui.layout.Infobuttons, 'ButtonSize', [150 100]);
           set(gui.layout.Buttonbox, 'Width', [-0.5 -0.5]);
        %% Create left menu
            gui.layout.p2 = uix.VButtonBox('Parent', gui.layout.leftMenu, 'Spacing', 3, ...
                            'BackgroundColor',gui.colormap.Background,'Tag','ButtonBoxModules');
            set(gui.layout.leftMenu, 'Heights', [-0.2 -0.8]);
            set(gui.layout.p2, 'ButtonSize', [300 60]);
        % Load button
            gui.layout.b_load = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Load data','Enable','on','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_load,'Units','Normalized','Position',[0.1 0.75 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','LoadButton');
            
            if  (MRSCont.flags.didLoad == 1  && isfield(MRSCont, 'raw')) 
                sz_raw = size(MRSCont.raw);
                if  (gui.controls.nDatasets(1) >= sz_raw(end))
                    gui.layout.b_load.Enable = 'off';
                end
            end
            set(gui.layout.b_load,'Callback',{@osp_onLoad,gui}, 'TooltipString', 'Call OspreyLoad');
            set(gui.layout.b_load,'Tag','Load');
        % Process button
            gui.layout.b_proc = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Process data','Enable','on','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_proc,'Units','Normalized','Position',[0.1 0.75 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','ProcButton');
            if (MRSCont.flags.didProcess == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= length(MRSCont.processed.metab)))
                gui.layout.b_proc.Enable = 'off';
            else if ~(MRSCont.flags.didLoad == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= sz_raw(end)))
                    gui.layout.b_proc.Enable = 'off';
                end
            end
            set(gui.layout.b_proc,'Callback',{@osp_onProc,gui}, 'TooltipString', 'Call OspreyProcess');
        % Fit button
            gui.layout.b_fit = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Model data','Enable','on','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_fit,'Units','Normalized','Position',[0.1 0.67 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','FitButton');
            if (MRSCont.flags.didFit == 1  && isfield(MRSCont, 'fit') && (gui.controls.nDatasets(1) >= length(MRSCont.fit.scale)))
                gui.layout.b_fit.Enable = 'off';
            else if ~(MRSCont.flags.didProcess == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= sz_raw(end)))
                    gui.layout.b_fit.Enable = 'off';
                end
            end
            set(gui.layout.b_fit,'Callback',{@osp_onFit,gui}, 'TooltipString', 'Call OspreyFit');
        % Coregister button
            gui.layout.b_coreg = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','CoRegister','Enable','off','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_coreg,'Units','Normalized','Position',[0.1 0.59 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','CoregButton');
            if MRSCont.flags.hasSPM == 1 && ~isempty(MRSCont.files_nii) && ~(MRSCont.flags.didCoreg == 1  && isfield(MRSCont, 'coreg') && (gui.controls.nDatasets(1) >= length(MRSCont.coreg.vol_image))) && (MRSCont.flags.didLoad == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= length(MRSCont.raw)))               
                if ~(isfield(MRSCont.flags,'addImages') && (MRSCont.flags.addImages == 0) && MRSCont.flags.moved)
                    gui.layout.b_coreg.Enable = 'on';
                end
            end
            set(gui.layout.b_coreg,'Callback',{@osp_onCoreg,gui}, 'TooltipString', 'Call OspreyCoreg');
            if MRSCont.flags.hasSPM == 0
                set(gui.layout.b_coreg,'String', 'Install SPM12 to CoRegister','FontSize', 12);
            end
        % Segment button
            gui.layout.b_segm = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Segment','Enable','off','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_segm,'Units','Normalized','Position',[0.1 0.51 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','SegButton');
            if MRSCont.flags.hasSPM == 1 && ~isempty(MRSCont.files_nii) && ~(MRSCont.flags.didSeg == 1  && isfield(MRSCont, 'seg') && (gui.controls.nDatasets(1) >= length(MRSCont.seg.tissue.fGM(:,1)))) && (MRSCont.flags.didCoreg == 1  && isfield(MRSCont, 'coreg') && (gui.controls.nDatasets(1) >= length(MRSCont.coreg.vol_image)))
                if ~(isfield(MRSCont.flags,'addImages') && (MRSCont.flags.addImages == 0) && MRSCont.flags.moved)
                    gui.layout.b_segm.Enable = 'on';
                end
            end
            set(gui.layout.b_segm,'Callback',{@osp_onSeg,gui}, 'TooltipString', 'Call OspreySeg');
            if MRSCont.flags.hasSPM == 0
                set(gui.layout.b_segm,'String', 'Install SPM12 to Segment','FontSize', 12);
            end
        % Quantify button
            gui.layout.b_quant = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Quantify','Enable','on','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_quant,'Units','Normalized','Position',[0.1 0.43 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','QuantifyButton');
            if MRSCont.flags.didQuantify
                gui.layout.b_quant.Enable = 'off';
            else if ~(MRSCont.flags.didFit == 1  && isfield(MRSCont, 'fit') && (gui.controls.nDatasets(1) >= length(MRSCont.fit.scale)) )
                    gui.layout.b_quant.Enable = 'off';
                end
            end
            set(gui.layout.b_quant,'Callback',{@osp_onQuant,gui}, 'TooltipString', 'Call OspreyQuantify');
        % DeIdentify button
            gui.layout.b_deid = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','DeIdentify','Enable','off','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_deid,'Units','Normalized','Position',[0.1 0.2 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','DeIndentButton');
            set(gui.layout.b_deid,'Callback',{@gui_deid,gui,MRSCont}, 'TooltipString', 'DeIndentify');
        % Save button
            gui.layout.b_save = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Save MRSCont','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_save,'Units','Normalized','Position',[0.1 0 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','SaveButton');
            set(gui.layout.b_save,'Callback',{@osp_onSave,gui}, 'TooltipString', 'Save MRSCont as .mat-file');
        % Exit button
            gui.layout.b_exit = uicontrol('Parent', gui.layout.p2,'Style','PushButton','String','Exit','ForegroundColor', gui.colormap.Foreground);
            set(gui.layout.b_exit,'Units','Normalized','Position',[0.1 0 0.8 0.08], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold','Tag','ExitButton');
            set(gui.layout.b_exit,'Callback',{@osp_onExit,gui}, 'TooltipString', 'See you next time!');
        % Create list of files for the Listbox
            gui.layout.controlPanel = uix.Panel('Parent', gui.layout.leftMenu, 'Title', 'MRS Container','BackgroundColor',gui.colormap.Background);
            set(gui.layout.controlPanel,'Units','Normalized','Position',[0.5 0 0.66 0.1], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold',...
                'ForegroundColor',gui.colormap.Foreground, 'HighlightColor',gui.colormap.Foreground, 'ShadowColor',gui.colormap.Foreground,'Tag','SubjectListPanel');
            gui.layout.fileList = MRSCont.files(1,:);
            if ~MRSCont.flags.moved
                [~, ~] = osp_detDataType(MRSCont);
            end
            SepFileList = cell(1,MRSCont.nDatasets(1));
            gui.layout.RedFileList = cell(1,MRSCont.nDatasets(1));
            gui.layout.OnlyFileList = cell(1,MRSCont.nDatasets(1));
            for i = 1 : MRSCont.nDatasets(1) %find last two subfolders and file names
                SepFileList{i} =  split(gui.layout.fileList(i), filesep);
                if length(SepFileList{i}) == 1
                    SepFileList{i} =  split(gui.layout.fileList(i), '\');
                end
                gui.layout.RedFileList{i} = [filesep SepFileList{i}{end-2} filesep SepFileList{i}{end-1} filesep SepFileList{i}{end}];
                gui.layout.OnlyFileList{i} = [SepFileList{i}{end}];
            end
            clear SepFileList
            gui.layout.ListBox = uicontrol('Style', 'list','BackgroundColor', 'w','FontName', gui.font,'BackgroundColor',gui.colormap.Background, ...
                                    'Parent', gui.layout.controlPanel, 'String',gui.layout.RedFileList(:) , ...
                                    'Value', gui.controls.Selected, 'Interruptible', 'on', 'BusyAction', 'cancel', ...
                                    'ForegroundColor',gui.colormap.Foreground, 'TooltipString', 'Select a file you want to inspect.','Tag','SubjectListBox');
            if MRSCont.flags.isMRSI
                gui.layout.MRSILocPanel = uix.Panel('Parent', gui.layout.leftMenu, 'Title', 'Voxel Location','BackgroundColor',gui.colormap.Background);
                set(gui.layout.MRSILocPanel,'Units','Normalized','Position',[0.5 0 0.66 0.1], 'FontSize', 16, 'FontName', gui.font, 'FontWeight', 'Bold',...
                    'ForegroundColor',gui.colormap.Foreground, 'HighlightColor',gui.colormap.Foreground, 'ShadowColor',gui.colormap.Foreground,'Tag','MRSIVoxelPanel');
                set(gui.layout.leftMenu,'Heights',[-.08,-.3,-0.1,-.2])
            end                        
        %% Create the display panel tab row

            gui.layout.tabs = uix.TabPanel('Parent', gui.layout.mainLayout, 'Padding', 3, 'FontName', gui.font,'Visible','on',...
                            'FontSize', 16,'BackgroundColor',gui.colormap.Background,...
                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                            'Tag','MainTabPanel');
            gui.layout.rawTab      = uix.TabPanel('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background,...
                                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                                            'FontName', gui.font, 'TabLocation','bottom','FontSize', 10,'Tag','RawTab');
            gui.layout.proTab      = uix.TabPanel('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background,...
                                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                                        'FontName', gui.font, 'TabLocation','bottom','FontSize', 10,'Tag','ProTab');
            gui.layout.fitTab      = uix.TabPanel('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background,...
                                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                                        'FontName', gui.font, 'TabLocation','bottom','FontSize', 10,'Tag','FitTab');
            gui.layout.coregTab    = uix.VBox('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background);
            gui.layout.quantifyTab = uix.TabPanel('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background,...
                                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                                        'FontName', gui.font, 'TabLocation','bottom','FontSize', 10,'Tag','QuantTab');
            gui.layout.overviewTab = uix.TabPanel('Parent', gui.layout.tabs, 'BackgroundColor',gui.colormap.Background,...
                                            'ForegroundColor', gui.colormap.Foreground, 'HighlightColor', gui.colormap.Foreground, 'ShadowColor', gui.colormap.Foreground,...
                                        'FontName', gui.font, 'TabLocation','bottom','FontSize', 10,'Tag','OverviewTab');
            gui.layout.tabs.TabTitles  = {'Raw', 'Processed', 'LC model', 'Cor/Seg', 'Quantified','Overview'};
            gui.layout.tabs.TabWidth   = 115;
            gui.layout.tabs.Selection  = 1;
            gui.layout.tabs.TabEnables = {'off', 'off', 'off', 'off', 'off', 'off'};
            set( gui.layout.mainLayout, 'Widths', [-0.2  -0.8] );
            gui.layout.EmptydataPlot = 0;
        %% Here we create the inital setup of the tabs
        % Now enable the display tabs depending on which processing steps have
        % been completed:
            gui.controls.waitbar = waitbar(0,'Start','Name','Loading your MRS Container');
            waitbar(0,gui.controls.waitbar,'Loading your raw spectra')
            if (MRSCont.flags.didLoad == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= sz_raw(end))) % Was data loaded at all that can be looked at?
                set(gui.layout.tabs, 'Visible','on');
                osp_iniLoadWindow(gui);
                if MRSCont.flags.isMRSI
                    gui.layout.LocPanel = uix.HBox('Parent', gui.layout.MRSILocPanel, 'BackgroundColor',gui.colormap.Background, 'Units', 'normalized','Tag','MRSILocPlot');
                    temp = osp_plotRawMRSIpos(MRSCont, 1, [gui.controls.act_y gui.controls.act_x gui.controls.act_z]);
                    ViewAxes = gca();
                    drawnow
                    set( ViewAxes, 'Parent', gui.layout.LocPanel );
                    close(temp)
                end
                set(gui.controls.b_save_RawTab{gui.load.Selected},'Callback',{@osp_onPrint,gui});
            end
            waitbar(gui.waitbar.step,gui.controls.waitbar,'Loading your processed spectra');
            if (MRSCont.flags.didProcess == 1  && isfield(MRSCont, 'raw') && (gui.controls.nDatasets(1) >= length(MRSCont.processed.metab))) % Has data been processed?
                set(gui.layout.tabs, 'Visible','on');
                osp_iniProcessWindow(gui);
                set(gui.controls.b_save_proTab{gui.load.Selected},'Callback',{@osp_onPrint,gui});
                set(gui.layout.tabs, 'Visible','off');
            end
            waitbar(gui.waitbar.step*2,gui.controls.waitbar,'Loading your fits');
            if (MRSCont.flags.didFit == 1  && isfield(MRSCont, 'fit') && (gui.controls.nDatasets(1) >= length(MRSCont.fit.scale)) ) % Has data fitting been run?
                osp_iniFitWindow(gui);
                set(gui.controls.b_save_fitTab{gui.load.Selected},'Callback',{@osp_onPrint,gui});
            end
            waitbar(gui.waitbar.step*3,gui.controls.waitbar,'Loading your image operations');
            if (MRSCont.flags.didCoreg == 1  && isfield(MRSCont, 'coreg') && (gui.controls.nDatasets(1) >= length(MRSCont.coreg.vol_image))) % Have coreg/segment masks been created?
                osp_iniCoregWindow(gui);
                set(gui.controls.b_save_coregTab,'Callback',{@osp_onPrint,gui});
            end
            waitbar(gui.waitbar.step*5,gui.controls.waitbar,'Loading your quantification results');
            if MRSCont.flags.didQuantify
                osp_iniQuantifyWindow(gui);
            end
            waitbar(gui.waitbar.step*7,gui.controls.waitbar,'Loading your overview');
            if MRSCont.flags.didOverview && (isfield(MRSCont, 'fit') && (gui.controls.nDatasets(1) >= length(MRSCont.fit.scale))) % Has data fitting been run?
                osp_iniOverviewWindow(gui);
                set(gui.layout.overviewTab, 'SelectionChangedFcn',{@osp_OverviewTabChangedFcn,gui});
                set(gui.controls.pop_specsOvPlot,'callback',{@osp_pop_specsOvPlot_Call,gui});
                set(gui.controls.pop_meanOvPlot,'callback',{@osp_pop_meanOvPlot_Call,gui});
                if isfield(gui.controls,'pop_quantOvPlot')
                    set(gui.controls.pop_quantOvPlot,'callback',{@osp_pop_quantOvPlot_Call,gui});
                    set(gui.controls.pop_distrOvQuant,'callback',{@osp_pop_distrOvQuant_Call,gui});
                    set(gui.controls.pop_distrOvMetab,'callback',{@osp_pop_distrOvMetab_Call,gui});
                    set(gui.controls.pop_corrOvQuant,'callback',{@osp_pop_corrOvQuant_Call,gui});
                    set(gui.controls.pop_corrOvMetab,'callback',{@osp_pop_corrOvMetab_Call,gui});
                    set(gui.controls.pop_corrOvCorr,'callback',{@osp_pop_corrOvCorr_Call,gui});
                    set(gui.controls.pop_whichcorrOvCorr,'callback',{@osp_pop_whichcorrOvCorr_Call,gui});
                    set(gui.controls.b_save_distrOvTab,'Callback',{@osp_onPrint,gui});
                    set(gui.controls.b_save_corrOvTab,'Callback',{@osp_onPrint,gui});
                    set(gui.controls.check_distrOv,'callback',{@osp_check_distrOv_Call,gui});
                end                
                set(gui.controls.check_meanOvPlot,'callback',{@osp_check_meanOvPlot_Call,gui});                
                set(gui.controls.check_specsOvPlot,'callback',{@osp_check_specsOvPlot_Call,gui});
                set(gui.controls.b_save_specOvTab,'Callback',{@osp_onPrint,gui});
                set(gui.controls.b_save_meanOvTab,'Callback',{@osp_onPrint,gui});
            end
            gui.layout.tabs.Selection  = 1;
            if ~MRSCont.flags.didLoad %Turn of Listbox if data has not been loaded
                gui.layout.ListBox.Enable = 'off';
            end
            set(gui.layout.tabs, 'Visible','on');
            waitbar(1,gui.controls.waitbar,'Finished');
            pause(1);
            close(gui.controls.waitbar);
        %% Here we add callback listeners triggered on selection changes
            set(gui.layout.tabs,'SelectionChangedFcn',{@osp_SelectionChangedFcn,gui});
            if MRSCont.flags.didLoad
                set(gui.layout.rawTab, 'SelectionChangedFcn',{@osp_RawTabChangeFcn,gui});
            end
            if MRSCont.flags.didProcess
                set(gui.layout.proTab,'SelectionChangedFcn',{@osp_ProTabChangeFcn,gui});
            end
            if MRSCont.flags.didFit
                set(gui.layout.fitTab, 'SelectionChangedFcn',{@osp_FitTabChangeFcn,gui});
            end
            if MRSCont.flags.didQuantify
                set(gui.layout.quantifyTab, 'SelectionChangedFcn',{@osp_QuantTabChangeFcn,gui});
            end
            set(gui.layout.ListBox,'Callback', {@osp_onListSelection,gui},'KeyPressFcn',{@osp_WindowKeyDown,gui}, 'KeyReleaseFcn', {@osp_WindowKeyUp,gui});
                       
        end
    end
end                                                      % End of class definition
