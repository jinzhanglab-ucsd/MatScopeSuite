function [em_wheel_pos, vf_code, dichro_pos, scopeSettings, led] = channelMapping(dyename)
    % Return a decimal bytecode to sent to 10-3 controller
    % with a VF-5 and emission filter wheel by serial port
    
    % Should return values for set.channel to communicate
    % the proper 10-3 batch code and code to send to umanager
    % to change the reflector turret of the Zeiss Axio to the
    % correct dichroic filter position.
    
    % Calling should first change filter wheel then to 10-3 wait 
    % for 10-3 to confirm then wait for filter wheel then proceed.
    
    % Switch for special
    led = (0);
    if ischar(dyename)
        switch dyename(1:2)
            case 'XL'
                % If dye is long stoke shift+
                % use special code
                if strcmp(dyename, 'XL480')
                    vf_code = [218 1 wlen2code(505)];
                    em_wheel_pos = 5;
                    em_name = 'bp_630';
                    dichro_pos = 3;
                    dichro_name = '59003bs';
                elseif strcmp(dyename, 'XL395')
                    vf_code = [218 1 wlen2code(395)];
                    em_wheel_pos = 5;
                    em_name = 'bp_590_650';
                    dichro_pos = 3;
                    dichro_name = '59003bs';
                end
            case 'sp'
                % Trigger for special case
                % codes
            case 'cy'
                if strcmp(dyename, 'cy5.5')
                vf_code = [222 1 100 0];
                em_wheel_pos = 7;
                em_name = 'bp_695_745';
                dichro_pos = 4;
                dichro_name = 'FF700-Di01';
                led = (1);
%                 elseif
%                     strcmp(dyename, 'cy7')
%                     vf_code = [222 1 100 0];
%                     em_wheel_pos = 6;
%                     dichro_pos = 1;
%                     dichro_name = '408_504_581_667_762';
%                     led = (2);
                elseif strcmp(dyename, 'cy7')
                    vf_code = [222 1 100 0];
                em_wheel_pos = 7;
                em_name = 'pbp_440_521_607_694_809_empty';
                dichro_pos = 1;
                dichro_name = 'pbp_440_521_607_694_809';
                led = (2);
                end
                
            otherwise
                wlen = str2num(dyename);
                wlen = int16(wlen)
                if wlen > 700
                    led = (2);
                    vf_code = [222 1 100 0];
                elseif wlen >= 630
                    led = (1);
                    vf_code = [218 1 wlen2code(wlen)];
                elseif wlen <630
                    led = 0;
                    vf_code = [218 1 wlen2code(wlen)];
                end
                [em_wheel_pos, em_name, dichro_pos, dichro_name] = lookupEmissionFilter(str2num(dyename));
                  %start_batch    %VF-5   %Wheel-speed-pos %end_batch

        end
    else
        msg = 'dyename should be a char class';
        error(msg)
    end
    scopeSettings = struct('wavelength', dyename, 'emission', em_name, 'dichroic', dichro_name);
end
        

function [em_pos, em_code, dichroic_pos, dichroic_name] = lookupEmissionFilter(wlen)
    %filterMapping = struct('bp_450', 3, 'lp_530', 1, 'lp_570', 9, 'lp_660', 4, 'bp_630', 5, 'open', 2);
%     filterMapping = struct('dbp_440.475_600.650', 0, 'bp_590.650', 1, 'bp_695.745', 2, ...
%         'tbp_425_527_615lp', 3, 'lp_570', 4, 'Empty', 5, 'lp_530', 6, 'Empty', 7, ...
%         'lp_665', 8, 'bp_665.715', 9);
    filterMapping = struct('dbp_440_475_600_650', 5, 'pbp_440_521_607_694_809_empty', 6, 'bp_695_745', 7, ...
        'tbp_425_527_615lp', 8, 'lp_570', 9, 'lp_776', 0, 'Empty1', 1, ...
        'lp_542', 2, 'lp_665', 3, 'lp_520', 4);
    if wlen < 420
        em_code = 'pbp_440_521_607_694_809_empty'; % Wheel position of correct filter
        dichroic_pos = 1;
        dichroic_name = '408_504_581_667_762';
%         
%     elseif wlen >= 470 && wlen <=520
%         em_code = 'tbp_425_527_615lp';
%         dichroic_pos = 5;
%         dichroic_name = '62HE';
        
    elseif wlen >= 470 && wlen <=491
        em_code = 'pbp_440_521_607_694_809_empty';
        dichroic_pos = 1;
        dichroic_name = '408_504_581_667_762';
%         dichroic_name = 'Di02-R514';
        
%     elseif wlen > 490 && wlen <= 522
%         em_code = 'lp_542';
%         dichroic_pos = 6;
%         dichroic_name = 'zt532/600';

    elseif wlen >= 492 && wlen <= 550
        em_code = 'lp_570';
        dichroic_pos = 2;
        dichroic_name = '59007bs';

%     elseif wlen > 550 && wlen <= 568
%         em_code = 'lp_570';
%         dichroic_pos = 1;
%         dichroic_name = '408_504_581_667_762';
        
    elseif wlen > 551 && wlen <= 567
        em_code = 'pbp_440_521_607_694_809_empty';
        dichroic_pos = 1;
        dichroic_name = '408_504_581_667_762';
        
%     elseif wlen > 568 && wlen <= 584
%         em_code = 'dbp_440_475_600_650';
%         dichroic_pos = 3;
%         dichroic_name = '59003bs';
    
    elseif wlen > 584 && wlen <= 636
        em_code = 'lp_665';
        dichroic_pos = 2;
        dichroic_name = '59007bs';
        
    elseif wlen >= 638 && wlen <= 700
        em_code = 'pbp_440_521_607_694_809_empty';
        dichroic_pos = 1;
        dichroic_name = 'unsure';
        led = (1);
    else
    
        msg = 'No known emission filter for that channel';
        error(msg)
    end
    em_pos = getfield(filterMapping, em_code);
end

function code = wlen2code(wlen)
    word = decimal2binary(wlen, 16, 'left-msb');
    low_order = binary2decimal(word(9:16), 'left-msb');
    high_order = binary2decimal(word(1:8), 'left-msb');
    code = [low_order high_order];
end