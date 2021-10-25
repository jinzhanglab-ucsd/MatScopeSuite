%% Get rois 

button  = 1;

xv =[];
yv=[];
hold on;
while button == 1
    [xin,yin,button]=ginput(1);
    xv = [xv,round(xin)];   
    yv = [yv,round(yin)];
    if length(xv)>1
        plot(xv(end-1:end),yv(end-1:end),'r-*','LineWidth',2)
    elseif length(xv)==1
        plot(xv(end),yv(end),'r-*','LineWidth',2)
    end
        
end
plot(xv([1,end]),yv([1,end]),'r-*','LineWidth',2)