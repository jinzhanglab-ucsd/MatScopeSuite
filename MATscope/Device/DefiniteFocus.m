classdef DefiniteFocus < Device
    % VFilter is an interface between the VF5 hardware, and the Scope class
    %
    
    properties (Transient = true)
        ard
        status
        arduinoTriggerPin
        referenceFocus
        camera
        pixel_size
        
    end
    
    methods
        %% initialize the device as a serial interface
        function initialize(self, comport, arduinoTriggerPin)
            self.ard = arduino(comport);
            self.camera = videoinput('gentl')
            src = getselectedsource(self.camera);
            src.ExposureTime = 50*1000; %microseconds units
            triggerconfig(self.camera, 'manual');
            start(self.camera);
            self.arduinoTriggerPin = arduinoTriggerPin;
            self.ard.configurePin(self.arduinoTriggerPin, 'DigitalOutput');
            self.ard.writeDigitalPin(self.arduinoTriggerPin, 0);
            self.referenceFocus = 0;
            self.pixel_size = 0.12 % um
        end
        
        function [scans z_s, maxCor]= calibrateReferenceFocus(self, scope)
            current_z = scope.Z;
            z_s = [];
            lines = {};
            for z = linspace(-30, 40, 101)
                scope.Z = current_z+z;
                l = self.snapFocus(1);
                l = self.processLineScan(l);
                lines = cat(1, lines, l);
                z_s = [z_s scope.Z];
                figure(10)
                plot(l)
            end
            self.ard.writeDigitalPin(self.arduinoTriggerPin, 0);
            scope.Z = current_z;
            scans = cat(1, lines{:});
            scope.Z = current_z;
            range = 1:1200;
            Nbef = 50;
            %tic
            maxCor = [];
            maxFit = [];
            opts = optimset('Display','off');
            
            flt = GaussianFit([1, 0, 4], -30:30);%sum(fspecial('gauss', 150, 50));
            %tic
            before.fr = 1000*scans(Nbef,range)./sum(scans(Nbef,range));
            before.fr = sqrt((before.fr - filtfilt(flt, 1, before.fr)).^2);%get fluctuations
            before.fr = filtfilt(flt, 1, before.fr);%remove ~10 component
            before.r = 1:length(before.fr);
            befq = FourierTransform(before);%calculate FTs
            
            for Naft = 1:101;
                after.fr = 1000*scans(Naft,range)./sum(scans(Naft,range));
                after.fr = sqrt((after.fr - filtfilt(flt, 1, after.fr)).^2);
                after.fr = filtfilt(flt, 1, after.fr);
                after.r = 1:length(after.fr);
                aftq = FourierTransform(after);%calculate FTs
                
                
                
                SF.r = aftq.q;
                SF.fr = aftq.fq.*conj(befq.fq);%Calculate structure factor
                CorrFun = FourierTransform(SF);%Calculate correlation function
                subplot(3,1,1)
                semilogy(aftq.q, abs(aftq.fq))
                ylabel('FT(after)')
                set(gca,'xlim',[0,2]);
                subplot(3,1,2)
                maxCor(Naft) = CorrFun.q((abs(CorrFun.fq) == max(abs(CorrFun.fq))));
                % beta = lsqcurvefit(@GaussianWithBackgroundFit,[3000 maxCor(Naft), 50, 100], crsFT.q, abs(crsFT.fq),[],[],opts);
                
                %maxFit(Naft) = beta(2);
                %x = -300:0.1:300;
                %p = GaussianWithBackgroundFit(beta, x);
                %                 plot(CorrFun.q,abs(CorrFun.fq))
                %                 ylabel('Corr. Fun.')
                %
                %                 shg
            end;
            %toc
            %             subplot(3,1,3)
            %
            %             plot(z_s, maxCor)%, 1:101, maxFit
            
            %%
            coeffs = polyfit(maxCor(7:64), z_s(7:64), 1)
            pixel_size = coeffs(1); % um units
            
        end
        
        function setReferenceFocus(self, focus_type, scope)
            switch focus_type
                case 'scan_z'
                    current_z = scope.Z;
                    lines = {};
                    for z = linspace(-10, 10, 51)
                        scope.Z = current_z+z;
                        l = self.snapFocus(0);
                        l = self.processLineScan(l);
                        lines = cat(1, lines, l);
                    end
                    self.ard.writeDigitalPin(self.arduinoTriggerPin, 0);
                    self.referenceFocus = lines;
                    scope.Z = current_z;
                case 'single'
                    l = self.snapFocus(1);
                    l = self.processLineScan(l);
                    [m mi] = max(l);
                    self.referenceFocus = mi;
            end
            figure(99)
            plot(l);
            shg
        end
        
        function line = processLineScan(self, line)
            flt = GaussianFit([1, 0, 4], -30:30);
            fr = 1000.*line./sum(line);
            fr = sqrt((fr - filtfilt(flt, 1, fr)).^2);
            line = filtfilt(flt, 1, fr);
        end
        
        function [movement confidence, mi, ref] = checkFocus(self)
            tic
            [linescan img] = self.snapFocus(1);
            
            line = self.processLineScan(linescan);
            figure(99)
            subplot(1,2,1)
            plot(line);
            subplot(1,2,2)
            imagesc(img)
            shg
            [m mi] = max(line);
            confidence = m/median(line);
            ref = self.referenceFocus;
            movement = (self.referenceFocus-mi)*-self.pixel_size;
            toc
            
        end
        
        %         function [movement confidence] = findFocus(self, current)
        %
        %             switch focus_type
        %                 case 'scan_z'
        %                     for i = 1:size(self.referenceFocus)
        %                     end
        %                 case 'gauss'
        %                     coeffs = [10.2175 98.4356];
        %
        %                 otherwise
        %
        %                     disp('Not implemented')
        %             end
        %         end
        
        function [linescan img] = snapFocus(self, single_snap)
            self.ard.writeDigitalPin(self.arduinoTriggerPin, 1);
            pause(0.13)
            [img finfo] = getsnapshot(self.camera);
            linescan = mean(img(499:550, :));
            if single_snap
                self.ard.writeDigitalPin(self.arduinoTriggerPin, 0);
            end
        end
        
        
        function close(Dev)
            delete(self.camera)
        end
    end
    
end

