function captureStruct = getCaptureProb(sirth,scenario)
% capture probabilities for 3, 5 ,7, 10 dB
% of omni sperimentali da 1 interferente fino a 11, poi 0
% om omni teoriche
% df direzionali sperimentali
% dm direzionali teoriche
% sirth=7;
switch sirth
    case 3
        switch scenario
            case 'oe'
                captureStruct.omniExp = [0.8216 0.6440 0.4842 0.3610 0.2663 0.2013 0.1507 0.1145 0.0865 0.0643 0.0484]; % former cap_prob_of
            case 'ot'
                captureStruct.omniThe = [0.8222 0.6265 0.4762 0.3660 0.2858 0.2268 0.1829 0.1496 0.1239 0.1038]; % former cap_prob_om
            case 'de'
                captureStruct.dirExp  = [0.9220 0.8340 0.7524 0.6677 0.5808 0.5042 0.4270 0.3615 0.3014 0.2497 0.2042]; % former cap_prob_df
            case 'dt'
                captureStruct.dirThe  = [0.9301 0.8231 0.7150 0.6163 0.5301 0.4568 0.3955 0.3448 0.3029 0.2684]; % former cap_prob_dm
            otherwise
                error('Please choose one of the available modes:\nOmnidirectional Experimental (oe)\nOmnidirectional Theoretical (ot)\nDirectional Experimental (de)\nDirectional Experimental (de)',class(scenario))
        end
    case 5
        switch scenario
            case 'oe'
                captureStruct.omniExp = [0.7658 0.5448 0.3694 0.2489 0.1695 0.1141 0.0770 0.0508 0.0329 0.0212 0.0128]; % former cap_prob_of
            case 'ot'
                captureStruct.omniThe = [0.7655 0.5321 0.3723 0.2667 0.1961 0.1476 0.1134 0.0886 0.0702 0.0562]; % former cap_prob_om
            case 'de'
                captureStruct.dirExp  = [0.8926 0.7789 0.6668 0.5595 0.4576 0.3670 0.2933 0.2294 0.1775 0.1362 0.1051]; % former cap_prob_df
            case 'dt'
                captureStruct.dirThe  = [0.9065 0.7711 0.6428 0.5329 0.4432 0.3719 0.3157 0.2715 0.2366 0.2088]; % former cap_prob_dm
            otherwise
                error('Please choose one of the available modes:\nOmnidirectional Experimental (oe)\nOmnidirectional Theoretical (ot)\nDirectional Experimental (de)\nDirectional Experimental (de)',class(scenario))
        end
    case 7
        switch scenario
            case 'oe'
                captureStruct.omniExp = [0.6982 0.4287 0.2576 0.1516 0.0892 0.0505 0.0279 0.0147 0.0074 0.0033 0.0015]; % former cap_prob_of
            case 'ot'
                captureStruct.omniThe = [0.6945 0.4285 0.2712 0.1787 0.1220 0.0858 0.0616 0.0450 0.0334 0.0250]; % former cap_prob_om
            case 'de'
                captureStruct.dirExp  = [0.8563 0.7078 0.5636 0.4358 0.3283 0.2433 0.1743 0.1283 0.0934 0.0673 0.0483]; % former cap_prob_df
            case 'dt'
                captureStruct.dirThe  = [0.8765 0.7094 0.5633 0.4485 0.3620 0.2978 0.2499 0.2137 0.1858 0.1638]; % former cap_prob_dm
            otherwise
                error('Please choose one of the available modes:\nOmnidirectional Experimental (oe)\nOmnidirectional Theoretical (ot)\nDirectional Experimental (de)\nDirectional Experimental (de)',class(scenario))
        end
    case 10
        switch scenario
            case 'oe'
                captureStruct.omniExp = [0.5572 0.2584 0.1153 0.0467 0.0181 0.0057 0.0017 0.0004 0.0001 0.0000 0]; % former cap_prob_of
            case 'ot'
                captureStruct.omniThe = []; % former cap_prob_om
            case ''
                capdetureStruct.dirExp  = [0.7808 0.5714 0.3891 0.2582 0.1671 0.1095 0.0721 0.0485 0.0342 0.0242 0.0170]; % former cap_prob_df
            case ''
                captdtureStruct.dirThe  = []; % former cap_prob_dm
            otherwise
                error('Please choose one of the available modes:\nOmnidirectional Experimental (oe)\nOmnidirectional Theoretical (ot)\nDirectional Experimental (de)\nDirectional Experimental (de)',class(scenario))
        end
    otherwise
        error('Please choose one of the available sirth values: 3, 5, 7, 10.',class(sirth))
end