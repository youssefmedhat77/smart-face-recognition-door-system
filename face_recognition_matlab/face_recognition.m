clc; clear; close all;

% Initialize Camera
cam = webcam;
detector = vision.CascadeObjectDetector;

% Serial Communication with Arduino
arduinoObj = serialport("COM3", 9600); % Change "COM3" to match your port
flush(arduinoObj);
pause(2);

% Variables
trustedFeatures = [];
threshold = 0.8; % Cosine similarity threshold
doorOpen = false;
faceNotDetectedCount = 0;
faceMustLeave = false; % Prevent immediate reopening
running = true;

fprintf("Press 'S' to save the trusted face.\n");
fprintf("Press 'C' to close the door.\n");
fprintf("Press 'X' to exit the program.\n");

figure;
while running
    % Capture Frame
    img = snapshot(cam);
    bbox = step(detector, img); % Detect faces

    if ~isempty(bbox)
        face = imcrop(img, bbox(1, :)); % Crop face region
        face = imresize(face, [100 100]); % Resize for consistency
        faceGray = rgb2gray(face); % Convert to grayscale
        faceGray = histeq(faceGray); % Normalize lighting
        faceFeatures = extractLBPFeatures(faceGray); % Extract LBP features

        imshow(img); hold on;
        rectangle('Position', bbox(1, :), 'EdgeColor', 'g', 'LineWidth', 2);

        % Check Key Press
        k = get(gcf, 'CurrentCharacter');
        set(gcf, 'CurrentCharacter', ' ');

        if k == 's' % Save Trusted Face Features
            trustedFeatures = faceFeatures;
            doorOpen = false;
            faceNotDetectedCount = 0;
            faceMustLeave = false;
            fprintf("Trusted face saved!\n");

        elseif k == 'c' % Close Door
            if doorOpen
                writeline(arduinoObj, "CLOSE");
                flush(arduinoObj);
                fprintf("Door closed.\n");
                doorOpen = false;
                faceMustLeave = true; % Require face to leave before reopening
            end
        
        elseif k == 'x' % Exit
            running = false;
            writeline(arduinoObj, "EXIT");
            fprintf("Exiting...\n");
        end

        % Compare Face if Trusted Face Exists
        if ~isempty(trustedFeatures) && ~faceMustLeave
            % Compute Cosine Similarity
            similarity = dot(trustedFeatures, faceFeatures) / (norm(trustedFeatures) * norm(faceFeatures));
            
            if similarity > threshold % Trusted face detected
                if ~doorOpen
                    writeline(arduinoObj, "OPEN");
                    flush(arduinoObj);
                    fprintf("Trusted person recognized. Door opened!\n");
                    doorOpen = true;
                    faceNotDetectedCount = 0;
                    pause(1); % Small delay to prevent rapid opening-closing
                end
            else
                fprintf("Unrecognized face. Similarity: %.2f\n", similarity);
            end
        end
    else
        imshow(img);
        
        % If no face detected, increment counter
        faceNotDetectedCount = faceNotDetectedCount + 1;

        % Face leaves → allow reopening
        if faceMustLeave && faceNotDetectedCount > 10
            fprintf("Face left. Door can open again.\n");
            faceMustLeave = false;
        end
    end
    pause(0.5); % Prevents excessive looping
    drawnow;
end

% Cleanup
clear cam;
delete(arduinoObj);
close all;