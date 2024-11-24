foregroundDetector = vision.ForegroundDetector('NumGaussians', 10, ...
    'NumTrainingFrames', 300, 'LearningRate', 0.001, 'MinimumBackgroundRatio', 0.2);

videoReader = VideoReader('igracka.mp4');
for i = 1:150
    frame = readFrame(videoReader); % read the next video frame
    foreground = step(foregroundDetector, frame);
end

figure; imshow(frame); title('Video Frame');

figure; imshow(foreground); title('Foreground');

se = strel('square', 3);
filteredForeground = imopen(foreground, se);
figure; imshow(filteredForeground); title('Clean Foreground');

blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MinimumBlobArea', 150);
bbox = step(blobAnalysis, filteredForeground);

result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

numObjects = size(bbox, 1);
result = insertText(result, [10 10], numObjects, 'BoxOpacity', 1, ...
    'FontSize', 14);
figure; imshow(result); title('Detected Objects');

videoPlayer = vision.VideoPlayer('Name', 'Detected Objects');
videoPlayer.Position(3:4) = [650,400];  % window size: [width, height]
se = strel('square', 3); % morphological filter for noise removal

while hasFrame(videoReader)

    frame = readFrame(videoReader); % read the next video frame

    % Detect the foreground in the current video frame
    foreground = step(foregroundDetector, frame);

    % Use morphological opening to remove noise in the foreground
    filteredForeground = imopen(foreground, se);

    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis, filteredForeground);

    % Draw bounding boxes around the detected cars
    result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

    % Display the number of cars found in the video frame
    numObjects = size(bbox, 1);
    result = insertText(result, [10 10], numObjects, 'BoxOpacity', 1, ...
        'FontSize', 14);

    step(videoPlayer, result);  % display the results

    pause(0.1);
end

param = getDefaultParameters();  % get Kalman configuration that works well
                                 % for this example

trackSingleObject(param);  % visualize the results

function trackSingleObject(param)
    utilities = createUtilities(param);
    isTrackInitialized = false;
    trajectory = {};  % Čuvanje trajektorije

    while hasFrame(utilities.videoReader)
        frame = readFrame(utilities.videoReader);
        [detectedLocation, isObjectDetected] = detectObject(frame);

        if ~isTrackInitialized
            if isObjectDetected
                initialLocation = computeInitialLocation(param, detectedLocation);
                kalmanFilter = configureKalmanFilter(param.motionModel, ...
                    initialLocation, param.initialEstimateError, ...
                    param.motionNoise, param.measurementNoise);

                isTrackInitialized = true;
                trackedLocation = correct(kalmanFilter, detectedLocation);
                label = 'Initial';
                trajectory{end+1} = trackedLocation;
            else
                trackedLocation = [];
                label = '';
            end

        else
            if isObjectDetected
                predict(kalmanFilter);
                trackedLocation = correct(kalmanFilter, detectedLocation);
                label = 'Corrected';
            else
                trackedLocation = predict(kalmanFilter);
                label = 'Predicted';
            end
            trajectory{end+1} = trackedLocation;
        end

        annotateTrackedObject(frame, trackedLocation, label);
    end

    showTrajectory(trajectory);
end


function utilities = createUtilities(param)
  % Create a structure to hold video reader and other utilities.
  utilities.videoReader = VideoReader(param.videoFile);
  % Add other utilities as needed.
end

function [detectedLocation, isObjectDetected] = detectObject(frame)
    % Ova funkcija treba da implementira logiku detekcije objekta.
    % Ovo je primer za detekciju krugova pomoću Hough transformacije.
    
    % Konvertovanje slike u sivi nivo
    grayImage = rgb2gray(frame);
    
    % Detekcija krugova
    [centers, radii] = imfindcircles(grayImage, [20 50]);  % Prilagodite opseg radiusa prema potrebama

    if ~isempty(centers)
        detectedLocation = centers(1, :);  % Uzimanje prve detektovane lokacije
        isObjectDetected = true;
    else
        detectedLocation = [];
        isObjectDetected = false;
    end
end


function initialLocation = computeInitialLocation(param, detectedLocation)
  % Compute the initial location of the object for Kalman filter initialization.
  initialLocation = detectedLocation;  % Adjust as needed based on `param`
end

function annotateTrackedObject(frame, trackedLocation, label)
    if ~isempty(trackedLocation)
        position = [trackedLocation, 10, 10];  % Prilagodite veličinu i poziciju
        frame = insertText(frame, position, label, 'FontSize', 12, 'BoxColor', 'yellow', 'BoxOpacity', 0.6);
        frame = insertShape(frame, 'Circle', [trackedLocation, 5], 'Color', 'red');
    end
    imshow(frame);  % Prikazivanje anotiranog frejma
    drawnow;  % Osvježavanje figure
end


function showTrajectory(trajectory)
    figure; hold on;
    for i = 1:length(trajectory)
        plot(trajectory{i}(1), trajectory{i}(2), 'ro');  % Prikaz tačke na trajektoriji
    end
    hold off;
end


function param = getDefaultParameters()
  % Define default parameters for Kalman filter and other configurations.
  param.motionModel = 'ConstantVelocity';  % Example motion model
  param.initialEstimateError = 1E5 * ones(1, 2);  % Initial estimate error
  param.motionNoise = [25, 10];  % Motion noise
  param.measurementNoise = 25;  % Measurement noise
  param.videoFile = 'igracka.mp4';  % Example video file
end




