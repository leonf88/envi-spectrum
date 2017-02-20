function [r_square, mec, rmse] = errors(y_orig ,y_fit)
% y_orig is the original values; y_fit is the estimated values
% return 1-by-3 vector that contains r_square, mse, and rmse

    if length(y_orig) ~= length(y_fit)
        error('the dimensions of input are not equal.');
    end
    normr = norm(y_orig - y_fit);
    sse = normr.^2;
    mse = sse / length(y_orig);
    mec = sum(abs((y_orig - y_fit)./y_orig)) / length(y_orig);
    rmse = sqrt(mse);
    avg_y_orig = mean(y_orig);

    % ssr = norm(y_fit - mean(y_orig))^2;
    % sst = norm(y_orig - mean(y_orig))^2;
    % r_square = ssr / sst
    % r_square = 1 - sse/sst;            % R-square statistic.

    % excel use RSQ to calculate the R2, 
    % https://support.office.com/en-us/article/RSQ-function-d7161715-250d-4a01-b80d-a8364f2be08f
    r_square = corr(y_orig, y_fit, 'type', 'Pearson');

    % TODO may the fitlm can help to understand how to calculate the r2
    %md1 = fitlm(y_orig, y_fit);
    %r_square = md1.Rsquared.Ordinary;
end
