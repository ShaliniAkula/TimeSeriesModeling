clear all;

% First we define an exponentially 
% decaying time signal and plot it
dt = 0.1;  % Time step width 
t  = 0:dt:1000;

p  = exp(-0.01 .* t) .* sin(10.*t);
q  = exp(-0.014 .* t) .* sin(8.*t);
r  = exp(-0.021 .* t) .* sin(6.*t);
%p  = exp(-0.028 .* t) .* sin(4.*t);


k = p + q + r;
%q = y1 + z + r + p;

y = k;
plot(t,y, 'r');

% Now we extract a portion of the data
% for building the model
data = y(1:100);
predictionLength = size(y,2)-size(data,2);

% We build a system model based on the data
% to be fitted
dataFit = iddata(data', [], dt);

% Here comes the actual AR fitting. The second
% parameter determines the number of poles
% For one pole ie only y1, AR is 5.
% For 2 poles i.e. y1 and z, AR is 8
% For 3 poles i.e. y1, z and r, AR is 23
sys = ar(dataFit,23)

% We now use the created model to predict the 
% data for the remaining number of samples
p = forecast(sys, dataFit, predictionLength);

% Plot the prediction results on top of the 
% original data
hold on
plot(p, 'g');
hold off