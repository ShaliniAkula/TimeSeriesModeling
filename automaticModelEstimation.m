close all;
clear all;

testWindow           = 500;   % The length of the window for testing the model
trainingSampleFactor = 20;    % A factor for the number of training samples (factor * order)
maxModelOrderAR      = 40;    % The maximum number of poles in the ARMA model
maxRelError          = 1e-4;

% Load the dataset
S = load("reflected.csv");

% Extract the information for the time (=t) and signal (=y) axes
t = transpose(S(:,1));
y = transpose(S(:,2));

dt = t(2) - t(1);

hold off;
plot(t,y)

maxSignalLength = size(t,2);

totalWindowLength = maxModelOrderAR * trainingSampleFactor + testWindow;

relErrorMax = 1e30;

figure;
for lastTime = totalWindowLength : 0.5 * totalWindowLength : maxSignalLength
    
    testT = t(lastTime-testWindow+1 : lastTime);
    testY = y(lastTime-testWindow+1 : lastTime);
    
    for order = 10 : 10 : maxModelOrderAR

        trainingWindowLength = order * trainingSampleFactor;
        testTshifted = testT - dt * (lastTime-testWindow+1-trainingWindowLength);

        trainingT = t(lastTime-testWindow-trainingWindowLength+1 : lastTime-testWindow);
        trainingY = y(lastTime-testWindow-trainingWindowLength+1 : lastTime-testWindow);
        
        % We build a system model based on the data to be fitted
        dataFit = iddata(trainingY', [], dt);

        sys0 = n4sid(dataFit,order);
        sys = armax(dataFit,sys0);
        
        pred = forecast(sys, dataFit, testWindow);
        predY = pred.y;
        
        subplot(2,1,1);

        plot(testTshifted, predY, 'r');
        hold on;

        plot(testTshifted, testY, 'b');
        title(['Comparison, order=' num2str(order) ', last step=' num2str(lastTime)]); 
        legend('predicted signal', 'actual signal');
        hold off;
        
        % Here we need to compare the two signals: predY and testY and
        % determine a measure for the difference between the two.
        
       
        
        %  A cross-correlation based approach!

         [c,lags] = xcorr(predY, testY, 'normalized');
         [~,I] = max(abs(c));

         subplot(2,1,2);
         stem(lags,c,'filled')
         hold on
         stem(lags(I),c(I),'filled')
         hold off
         legend(["Cross-correlation",sprintf('Maximum at lag %d',lags(I))])
         

          % The easiest would be to calculate the mean square error
         error = sqrt(sum((predY - transpose(testY)).^2))/size(predY,1);
        relError = error / max(testY);
        disp(['Comparison, order=' num2str(order) ', last step=' num2str(lastTime) ', error=' num2str(relError) ',correlation value=' num2str(1-max(findpeaks(c))), ',lag value=' num2str(lags(I))])
        
        
        % Take the best so far model
        if relError < relErrorMax
            relErrorMax = relError;
            bestModel = sys;
            bestModelLastTime = lastTime;
            
            if relErrorMax < maxRelError
                break;
            end
        end
    end
    
    if relErrorMax < maxRelError
        disp('The current model satisfies the tolerance limit')
        break;
    end
end

if relErrorMax < 1e30
    % We found a suitable model, predict the remaining samples    
    pred = forecast(sys, dataFit, maxSignalLength-lastTime+1+testWindow);
    predY = pred.y;
    
    predT = t(lastTime-testWindow:maxSignalLength);
    figure;
    plot(t, y, "b")
    hold on;
    plot(predT, predY, "r")
    legend('predicted signal', 'actual signal');
    hold off;
   
end



