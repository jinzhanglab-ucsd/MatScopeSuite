classdef LEDArduino < handle
    properties(Access=private)
        serialobj
        valid_commands
    end
    
    methods(Access=private)
        %> send command 'cmd'
        function send_command(s, cmd)
            assert(ismember(cmd, s.valid_commands));
            fprintf(s.serialobj, cmd);
        end
    end
    
    methods
         % constructor
        function s=LEDArduino(comPort)
            if nargin < 1
                comPort = '/dev/ttyACM0';
            end
            
            
            s.valid_commands='grbswcLRTBO'; %g-->get state, r-->reset state, b-->blink, s-->sets built-in LED, w-->white LED, c-->colored LED
            
            
            s.serialobj = serial(comPort,'BaudRate',115200);
            try
                fopen(s.serialobj);
            catch ME
                disp(ME.message)
                fclose(s.serialobj);
                error(['Could not open port: ' comPort]);
            end

            % get the state. It must be 0 (IDLE) state
            v = s.get_state(); 
            if(v ~= 0)
                fclose(s.serialobj);
                error('Unable to connect to the serial port');
            end
            
        end
        
        % destructor
        function delete(s)
            fclose(s.serialobj);
        end
        
        
        function turn_leds(s,led_array, power)
           if nargin < 3
               power=100;
           end
           s.reset_state();
           
           sz = 50;
           n=length(led_array);
           num_times = ceil(n/sz);
           for i = 1:num_times
               ind = (i-1)*sz+1:min(n,i*sz);
               if ~isempty(ind) > 0
                   sub_array = led_array(ind);
                   %disp(sub_array);
                   fwrite(s.serialobj,['A' uint8(length(sub_array)) power uint8(sub_array)],'uint8');
               end
           end
        end
        
        function turn_left_leds(s, power)
            s.reset_state();
            fwrite(s.serialobj,['L' power],'uint8');
        end
        
        function turn_right_leds(s, power)
            s.reset_state();
            fwrite(s.serialobj,['R' power],'uint8');
        end
        
        function turn_top_leds(s, power)
            s.reset_state();
            fwrite(s.serialobj,['T' power],'uint8');
        end
        
        function turn_bottom_leds(s, power)
            s.reset_state();
            fwrite(s.serialobj,['B' power],'uint8');
        end
        
        function turn_central_leds(s, power)
            s.reset_state();
            fwrite(s.serialobj,['C' power],'uint8');
%             s.turn_leds(uint8([253:-1:235]),power);
        end
        
        
        function turn_outer_ring(s, power)
            s.reset_state();
            fwrite(s.serialobj,['O' power],'uint8');
        end
        
        %> turns built-in LED on
        function turn_led_on(s)
            s.send_command('s');
        end
        
        
        %> get state
        function v = get_state(s)
            s.send_command('g');
            v = fscanf(s.serialobj,'%d');
        end
                
        %> resets the state
        function reset(s)
            s.send_command('r');
        end
        
        function reset_state(s)
            s.send_command('r');
        end
        
        %> sends command to turn a LED ON or OFF
        function white_LED(s,LED, on_off)
            assert(LED>=0 && LED<=255);
            assert(on_off == 0 || on_off==1);
            s.reset_state();
            fwrite(s.serialobj,['w' LED on_off],'uint8')
        end
        
        
        
        %> blinks the built-in LED
        function blink(s,num, delay)
            assert(num>=0 && num<=255);
            assert(delay>=0 && delay<=255);
            s.reset_state();
            fwrite(s.serialobj,['b' num delay],'uint8')
        end
        
        %> controls RGB of a given LED
        function color_LED(s, LED, R, G, B)
            assert(LED>=0 && LED<=255);
            assert(R>=0 && R<=255);
            assert(G>=0 && G<=255);
            assert(B>=0 && B<=255);
            s.reset_state();
            fwrite(s.serialobj,['c' LED R G B],'uint8');
        end
        
        function parseChannel(LEDarray,chnl)
            if strcmp(chnl(1:3),'LED')
                LED = uint8(str2double(chnl(4:end)));
                R=250; %Scp.LEDpower;
                if LED <= 255
                    G=R;
                    B=R;
                   LEDarray.color_LED(LED, R, G, B);
                else
                    error('Invalid LED number %d',LED);
                end
            elseif length(chnl)>8 && strcmp(chnl(1:7),'CUSTOM_') %CUSTOM_001_005
                str=chnl(8:end);
                start_led=str2double(str(1:3));
                end_led = str2double(str(5:end));
                assert(start_led >=0 && start_led <=254);
                assert(end_led >=0 && end_led <=254);
                pwr=250;
                LEDarray.turn_leds([start_led:end_led],pwr);
            elseif length(chnl)>7 && strcmp(chnl(1:6),'ARRAY_')
                str = chnl(7:end);
                pwr=100;%Scp.LEDpower;
                switch str
                    case 'left'
                        LEDarray.turn_left_leds(pwr);
                    case 'right'
                        LEDarray.turn_right_leds(pwr);
                    case 'top'
                        LEDarray.turn_top_leds(pwr);
                    case 'bottom'
                        LEDarray.turn_bottom_leds(pwr);
                    case 'ring'
                        pwr=50;
                        LEDarray.turn_outer_ring(pwr);
                    case 'central'
%                         pwr=100;
                        LEDarray.turn_central_leds(pwr);
                    otherwise
                        error('Unsupported LED array type');
                end
            end
        end
    end
end

% % % classdef LEDArduino < handle
% % %     properties(Access=private)
% % %         serialobj
% % %         valid_commands
% % %     end
% % %     
% % %     methods(Access=private)
% % %         %> send command 'cmd'
% % %         function send_command(s, cmd)
% % %             assert(ismember(cmd, s.valid_commands));
% % %             fprintf(s.serialobj, cmd);
% % %             pause(0.01);
% % %         end
% % %     end
% % %     
% % %     methods
% % %          % constructor
% % %         function s=LEDArduino(comPort)
% % %             if nargin < 1
% % %                 comPort = '/dev/ttyACM0';
% % %             end
% % %             
% % %             
% % %             s.valid_commands='grbswc'; %g-->get state, r-->reset state, b-->blink, s-->sets built-in LED, w-->white LED, c-->colored LED
% % %             
% % %             
% % %             s.serialobj = serial(comPort,'BaudRate',115200);
% % %             try
% % %                 fopen(s.serialobj);
% % %             catch ME
% % %                 disp(ME.message)
% % %                 fclose(s.serialobj);
% % %                 error(['Could not open port: ' comPort]);
% % %             end
% % % 
% % %             % get the state. It must be 0 (IDLE) state
% % %             v = s.get_state(); 
% % %             if(v ~= 0)
% % %                 fclose(s.serialobj);
% % %                 error('Unable to connect to the serial port');
% % %             end
% % %             
% % %         end
% % %         
% % %         % destructor
% % %         function delete(s)
% % %             fclose(s.serialobj);
% % %         end
% % %         
% % %         %> turns built-in LED on
% % %         function turn_led_on(s)
% % %             s.send_command('s');
% % %         end
% % %         
% % %         
% % %         %> get state
% % %         function v = get_state(s)
% % %             s.send_command('g');
% % %             v = fscanf(s.serialobj,'%d');
% % %         end
% % %                 
% % %         %> resets the state
% % %         function reset_state(s)
% % %             s.send_command('r');
% % %         end
% % %         
% % %         %> sends command to turn a LED ON or OFF
% % %         function white_LED(s,LED, on_off)
% % %             assert(LED>=0 && LED<=255);
% % %             assert(on_off == 0 || on_off==1);
% % %             s.reset_state();
% % %             fwrite(s.serialobj,['w' LED on_off],'uint8')
% % %         end
% % %         
% % %         
% % %         
% % %         %> blinks the built-in LED
% % %         function blink(s,num, delay)
% % %             assert(num>=0 && num<=255);
% % %             assert(delay>=0 && delay<=255);
% % %             s.reset_state();
% % %             fwrite(s.serialobj,['b' num delay],'uint8')
% % %         end
% % %         
% % %         %> controls RGB of a given LED
% % %         function color_LED(s, LED, R, G, B)
% % %             assert(LED>=0 && LED<=255);
% % %             assert(R>=0 && R<=255);
% % %             assert(G>=0 && G<=255);
% % %             assert(B>=0 && B<=255);
% % %             s.reset_state();
% % %             fwrite(s.serialobj,['c' LED R G B],'uint8');
% % %         end
% % %         
% % %         
% % %     end
% % % end