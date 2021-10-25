classdef AcquisitionData
   
    properties
        Bin
        Gain
        Exposure
        Channel
        dZ
        Marker
        Fluorophore
        Skip = 1; 
        
        %%% ECG edit - don't acquire just illuminate
        illumOnly = 0;
    end
    
end