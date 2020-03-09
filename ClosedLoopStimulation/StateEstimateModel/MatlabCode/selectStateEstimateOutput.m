function [variantConfig] = selectStateEstimateOutput(stateOutput, variantConfig)

if isempty(stateOutput)
    return;
end

switch upper(regexprep(stateOutput,'\W*',''))
    case 'MEAN'
        variantConfig.STATEOUTPUT = 1;
    case 'UPPERBOUND'
        variantConfig.STATEOUTPUT = 2;
    case 'LOWERBOUND'
        variantConfig.STATEOUTPUT = 3;
    otherwise
        disp(['No Valid STATEOUTPUT specified. Using default: ', num2str(variantConfig.STATEOUTPUT)]);
end
