classdef ObjectDetectionApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        StartButton                matlab.ui.control.Button
        StopButton                 matlab.ui.control.Button
        UIAxes                     matlab.ui.control.UIAxes
        NumObjectsLabel            matlab.ui.control.Label
        NumTrainingFramesEditField matlab.ui.control.NumericEditField
        NumGaussiansEditField      matlab.ui.control.NumericEditField
        LearningRateEditField      matlab.ui.control.NumericEditField
        NumTrainingFramesLabel     matlab.ui.control.Label
        NumGaussiansLabel          matlab.ui.control.Label
        LearningRateLabel          matlab.ui.control.Label
    end

    % Properties for the object detection
    properties (Access = private)
        videoReader       % Video reader object
        foregroundDetector % Foreground detector object
        blobAnalysis      % Blob analysis object
        kalmanFilter      % Kalman filter object
        isRunning         % Logical flag to control the video processing loop
    end
    
    methods (Access = private)

        function startupFcn(app)
            % Initialization code
            app.videoReader = VideoReader('video1.avi');
            app.foregroundDetector = vision.ForegroundDetector('NumGaussians', 10, ...
                'NumTrainingFrames', 300, 'LearningRate', 0.001, 'MinimumBackgroundRatio', 0.2);
            app.blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                'AreaOutputPort', false, 'CentroidOutputPort', false, ...
                'MinimumBlobArea', 150);
        end

        function processVideo(app)
            app.isRunning = true;
            while hasFrame(app.videoReader) && app.isRunning
                frame = readFrame(app.videoReader);
                foreground = step(app.foregroundDetector, frame);
                se = strel('square', 3);
                filteredForeground = imopen(foreground, se);
                bbox = step(app.blobAnalysis, filteredForeground);
                result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
                numObjects = size(bbox, 1);
                result = insertText(result, [10 10], numObjects, 'BoxOpacity', 1, 'FontSize', 14);
                imshow(result, 'Parent', app.UIAxes);
                app.NumObjectsLabel.Text = ['Num Objects: ', num2str(numObjects)];
                pause(0.1);
            end
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            % Get user input values for the parameters
            numTrainingFrames = app.NumTrainingFramesEditField.Value;
            numGaussians = app.NumGaussiansEditField.Value;
            learningRate = app.LearningRateEditField.Value;

            % Initialize the foreground detector with user-defined parameters
            app.foregroundDetector = vision.ForegroundDetector('NumGaussians', numGaussians, ...
                'NumTrainingFrames', numTrainingFrames, 'LearningRate', learningRate, ...
                'MinimumBackgroundRatio', 0.2);

            % Process the video
            app.processVideo();
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.isRunning = false;
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Object Detection App';

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [270 420 100 30];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [380 420 100 30];
            app.StopButton.Text = 'Stop';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [50 50 400 300];

            % Create NumObjectsLabel
            app.NumObjectsLabel = uilabel(app.UIFigure);
            app.NumObjectsLabel.Position = [50 420 200 30];
            app.NumObjectsLabel.Text = 'Num Objects: 0';

            % Create NumTrainingFramesLabel
            app.NumTrainingFramesLabel = uilabel(app.UIFigure);
            app.NumTrainingFramesLabel.HorizontalAlignment = 'right';
            app.NumTrainingFramesLabel.Position = [400 330 100 22];
            app.NumTrainingFramesLabel.Text = 'NumTrainingFrames';

            % Create NumTrainingFramesEditField
            app.NumTrainingFramesEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumTrainingFramesEditField.Position = [510 330 100 22];
            app.NumTrainingFramesEditField.Value = 300;

            % Create NumGaussiansLabel
            app.NumGaussiansLabel = uilabel(app.UIFigure);
            app.NumGaussiansLabel.HorizontalAlignment = 'right';
            app.NumGaussiansLabel.Position = [400 390 100 22];
            app.NumGaussiansLabel.Text = 'NumGaussians';

            % Create NumGaussiansEditField
            app.NumGaussiansEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumGaussiansEditField.Position = [510 390 100 22];
            app.NumGaussiansEditField.Value = 10;

            % Create LearningRateLabel
            app.LearningRateLabel = uilabel(app.UIFigure);
            app.LearningRateLabel.HorizontalAlignment = 'right';
            app.LearningRateLabel.Position = [400 360 100 22];
            app.LearningRateLabel.Text = 'LearningRate';

            % Create LearningRateEditField
            app.LearningRateEditField = uieditfield(app.UIFigure, 'numeric');
            app.LearningRateEditField.Position = [510 360 100 22];
            app.LearningRateEditField.Value = 0.001;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = ObjectDetectionApp

            % Create and configure components
            createComponents(app)

            % Execute the startup function
            startupFcn(app)
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
