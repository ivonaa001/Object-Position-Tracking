%% Track an Occluded Object
% Detect and track a ball using Kalman filtering, foreground detection, and 
% blob analysis.
% 
% Create System objects to read the video frames, detect foreground physical 
% objects, and display results.

%foregroundDetector = vision.ForegroundDetector('NumTrainingFrames',10,...
 %               'InitialVariance',0.05);

videoReader = VideoReader('video1.avi');

videoPlayer = vision.VideoPlayer('Position',[100,100,500,400]);
foregroundDetector = vision.ForegroundDetector('NumTrainingFrames',10,...
               'InitialVariance',0.05);
blobAnalyzer = vision.BlobAnalysis('AreaOutputPort',false,...
                'MinimumBlobArea',70);

%release(videoPlayer);

%while hasFrame(videoReader)

 %   frame = readFrame(videoReader); % read the next video frame

    % Detect the foreground in the current video frame
  %  foreground = step(foregroundDetector, frame);

    % Use morphological opening to remove noise in the foreground
   % filteredForeground = imopen(foreground, se);

    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    %bbox = step(blobAnalysis, filteredForeground);

    % Draw bounding boxes around the detected cars
    %result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

     %   step(videoPlayer, result);  % display the results

   % pause(0.1);
%end

%% 
% Process each video frame to detect and track the ball. After reading the 
% current video frame, the example searches for the ball by using background subtraction 
% and blob analysis. When the ball is first detected, the example creates a Kalman 
% filter. The Kalman filter determines the ball?s location, whether it is detected 
% or not. If the ball is detected, the Kalman filter first predicts its state 
% at the current video frame. The filter then uses the newly detected location 
% to correct the state, producing a filtered location. If the ball is missing, 
% the Kalman filter solely relies on its previous state to predict the ball's 
% current location.
%%
  kalmanFilter = []; isTrackInitialized = false;
   while hasFrame(videoReader)
     colorImage  = readFrame(videoReader);
  
     foregroundMask = step(foregroundDetector,im2gray(im2single(colorImage)));
     detectedLocation = step(blobAnalyzer,foregroundMask);
     isObjectDetected = size(detectedLocation, 1) > 0;
  
     if ~isTrackInitialized
       if isObjectDetected
         kalmanFilter = configureKalmanFilter('ConstantAcceleration',...
                  detectedLocation(1,:), [1 1 1]*1e5, [25, 10, 10], 25);
         isTrackInitialized = true;
       end
       label = ''; circle = zeros(0,3);
     else 
       if isObjectDetected 
         predict(kalmanFilter);
         trackedLocation = correct(kalmanFilter, detectedLocation(1,:));
         label = 'Corrected';
       else
         trackedLocation = predict(kalmanFilter);
         label = 'Predicted';
       end
       circle = [trackedLocation, 5];
     end
  
     colorImage = insertObjectAnnotation(colorImage,'circle',...
                circle,label,'AnnotationColor','red');
     step(videoPlayer,colorImage);
     pause(0.1);
   end
%% 
% Release resources.
%%
release(videoPlayer);

%% 
% Copyright 2012 The MathWorks, Inc.