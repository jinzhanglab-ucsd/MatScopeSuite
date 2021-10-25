%% Import data
clear all
close all

v=uiimport
%% Save data in a matrix [time y y' y'']
x=v.data(:,1);
y=v.data(:,2);
entries = length(x)
data=zeros(entries,4)
data(:,1) = x
data(:,2) = y

%% Calculate and save y' and y''
dx= x(2)-x(1) %time interval is constant
dyI=diff(y)./dx
dyII= diff(y,2)./(dx)^2

data(2:entries,3) = dyI
data(3:entries,4) = dyII
%% Plot first derivative
plot(data(:,1),data(:,3))
title('First derivative')
grid on
%% Determine second peak
lower = input('Enter lower bound for range of the 2nd peak as a multiple of 0.5:');
upper = input ('Enter upper bound for range of the 2nd peak as a multiple of 0.5:');

while k <= upper
    
    
range1 = range1*2
range2 = range2*2
range = data(range1:range2,:)
%max2 = max(range(:))

