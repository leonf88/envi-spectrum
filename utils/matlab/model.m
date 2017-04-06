function model
% data start from column 2 and row 1

%%%%%%%%%%%%%%%%%%%%%%%%%
%% ATTENTION: modify the model_file and test_file parameter as you need
% user define data to train model 
model_file = 'data/demo/model-mini.csv'
% user define data to test the model
test_file  = 'data/demo/test-mini.csv'

% model_file = 'data/model.csv';
% test_file = 'data/test.csv';
%%%%%%%%%%%%%%%%%%%%%%%%%


fid = fopen(model_file);
tline = fgetl(fid);
names = strsplit(tline, ',');
ns = size(names);
names = names(:, 3:ns(2));
m_dat = csvread(model_file, 1, 2);
t_dat = csvread(test_file, 1, 2);

m_size = size(m_dat);
t_size = size(t_dat);

if m_size(2) ~= t_size(2)
    error('the dimension is not correct.')
end

m_out = fopen('model-func.csv','wt');
fprintf(m_out, 'type, function, r square for model, f statistic for model, p value of F statistic for model, estimate of the error variance for model, r square for test, mec for test, rmse for test, A0, A1, A2, A3\n');
m_y = m_dat(:, 1);
t_y = t_dat(:, 1);

m_row = m_size(1);
m_col = m_size(2);
t_row = t_size(1);
t_col = t_size(2);

for i = 2:1:m_col
%    m_dat = sortrows(m_dat, i);
%    m_y = m_dat(:, 1);
    fname = char(names(i));

%%%%%%%%%%%%%%%%%%%%%
%  if strcmp(fname, 'NDVI') == 0 && strcmp(fname, 'redSAI') == 0
%      continue
%  end
%%%%%%%%%%%%%%%%%%%%%

    fdir = fullfile('figures', fname);
    mkdir(fdir);

    m_x = m_dat(:, i);
    t_x = t_dat(:, i);

    % y=a+bx
    Y = m_y;
    X = [ones(m_row, 1), m_x];

    % stats: [R2 statistic, F statistic, p value of F statistic, estimate of the error variance]
    [b, bint, r, rint, stats] = regress(Y, X);
    m_ny = b(1) + b(2) * m_x;
    t_ny = b(1) + b(2) * t_x;

    % errs: [r_square, mec, rmse]
    [r_square, mec, rmse] = errors(t_y, t_ny);

    fprintf(m_out,'%s, y=A0 + A1*x, %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);
    xfit = linspace(0, max(m_x)*1.1, 50);
    yfit = b(1) + b(2) * xfit;
    plotmodel(m_x, m_y, xfit, yfit, 'Linear Fitting Curve', 'FAPAR', [ ...
        cellstr(sprintf('F = %.3f', stats(2))), ... 
        cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
        cellstr(funcformat(b', [cs(''), cs('x')]))], fullfile(fdir, 'model_linear'));
        %cellstr(sprintf('y= %.2f + %.2f x', b(1), b(2)))], fullfile(fdir, 'model_linear'));
    plottest(t_y, t_ny, [ ... 
        cellstr(sprintf('MEC= %.3f', mec)), ...
        cellstr(sprintf('RMSE = %.3f', rmse)), ...
        cellstr(sprintf('R^{2} = %.3f', r_square)), ...
        cellstr(funcformat(b', [cs(''), cs('x')]))], fullfile(fdir, 'test_linear'));
        %cellstr(sprintf('y= %.2f + %.2f x', b(1), b(2)))], fullfile(fdir, 'test_linear'));

    % y=a+bx+cx^2
    Y = m_y;
    X = [ones(m_row, 1) , m_x , (m_x .^ 2)];
    [b, bint, r, rint, stats] = regress(Y, X);
    m_ny = b(1) + b(2) * m_x + b(3) * (m_x .^ 2);
    t_ny = b(1) + b(2) * t_x + b(3) * (t_x .^ 2);
    [r_square, mec, rmse] = errors(t_y, t_ny);
    fprintf(m_out,'%s, Y=A0 + A1 * x + A2 * x^2, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);

    xfit = linspace(0, max(m_x)*1.1, 50);
    yfit = b(1) + b(2) * xfit + b(3) * (xfit .^ 2);
    plotmodel(m_x, m_y, xfit, yfit, 'Quadratic Fitting Curve', 'FAPAR', [ ...
        cellstr(sprintf('F = %.3f', stats(2))), ... 
        cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
        cellstr(funcformat(b', [cs(''), cs('x'), cs('x^2')]))], fullfile(fdir, 'model_quad'));
        %cellstr(sprintf('y= %.2f + %.2f x + %.2f x^2', b(1), b(2), b(3)))], fullfile(fdir, 'model_quad'));
    plottest(t_y, t_ny, [ ... 
        cellstr(sprintf('MEC= %.3f', mec)), ...
        cellstr(sprintf('RMSE = %.3f', rmse)), ...
        cellstr(sprintf('R^{2} = %.3f', r_square)), ...
        cellstr(funcformat(b', [cs(''), cs('x'), cs('x^2')]))], fullfile(fdir, 'test_quad'));
        %cellstr(sprintf('y= %.2f + %.2f x + %.2f x^2', b(1), b(2), b(3)))], fullfile(fdir, 'test_quad'));

    % y=a+bx+cx^2+dx^3
    Y = m_y;
    X = [ones(m_row, 1), m_x, (m_x .^ 2), (m_x .^ 3)];
    [b, bint, r, rint, stats] = regress(Y, X);
    m_ny = b(1) + b(2) * m_x + b(3) * (m_x .^ 2) + b(4) * (m_x .^ 3);
    t_ny = b(1) + b(2) * t_x + b(3) * (t_x .^ 2) + b(4) * (t_x .^ 3);
    [r_square, mec, rmse] = errors(t_y, t_ny);
    fprintf(m_out,'%s, Y=A0 + A1 * x + A2 * x^2 + A3 * x^3, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);
    
    xfit = linspace(0, max(m_x)*1.1, 50);
    yfit = b(1) + b(2) * xfit + b(3) * (xfit .^ 2) + b(4) * (xfit .^ 3);
    plotmodel(m_x, m_y, xfit, yfit, 'Cubic Fitting Curve', 'FAPAR', [ ...
        cellstr(sprintf('F = %.3f', stats(2))), ... 
        cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
        cellstr(funcformat(b', [cs(''), cs('x'), cs('x^2'), cs('x^3')]))], fullfile(fdir, 'model_curve'));
        %cellstr(sprintf('y= %.2f + %.2f x + %.2f x^2 + %.2f x^3', b(1), b(2), b(3), b(4)))], fullfile(fdir, 'model_curve'));
    plottest(t_y, t_ny, [ ... 
        cellstr(sprintf('MEC= %.3f', mec)), ...
        cellstr(sprintf('RMSE = %.3f', rmse)), ...
        cellstr(sprintf('R^{2} = %.3f', r_square)), ...
        cellstr(funcformat(b', [cs(''), cs('x'), cs('x^2'), cs('x^3')]))], fullfile(fdir, 'test_curve'));
        %cellstr(sprintf('y= %.2f + %.2f x + %.2f x^2 + %.2f x^3', b(1), b(2), b(3), b(4)))], fullfile(fdir, 'test_curve'));

   try
   % 1/y=a+b/x
   Y = m_y;
   X = m_x;
   b0 = [1, 1];
   b = nlinfit(X, Y, @(b, x)(b(1) + b(2) ./ x), b0);
   m_ny = b(1) + b(2) ./ m_x;
   t_ny = b(1) + b(2) ./ t_x;
   % m_ny = 0.069 * exp(3.0797 * m_x);
   [r_square, mec, rmse] = errors(m_y, m_ny);
   stats = qr0([ones(m_row, 1), (m_x)], m_y, m_ny);
   [r_square, mec, rmse] = errors(t_y, t_ny);
   fprintf(m_out,'%s, Y=A0 + (A1 / x), %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);
   
   xfit = linspace(0, max(m_x)*1.1, 50);
   yfit = b(1) + b(2) ./ xfit;
   plotmodel(m_x, m_y, xfit, yfit, 'Reciprocal Fitting Curve', 'FAPAR', [ ...
       cellstr(sprintf('F = %.3f', stats(2))), ... 
       cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
       cellstr(funcformat(b, [cs(''), cs('/x')]))], fullfile(fdir, 'model_recip'));
       %cellstr(sprintf('y= %.2f + %.2f / x', b(1), b(2)))], fullfile(fdir, 'model_recip'));
   plottest(t_y, t_ny, [ ... 
       cellstr(sprintf('MEC= %.3f', mec)), ...
       cellstr(sprintf('RMSE = %.3f', rmse)), ...
       cellstr(sprintf('R^{2} = %.3f', r_square)), ...
       cellstr(funcformat(b, [cs(''), cs('/x')]))], fullfile(fdir, 'test_recip'));
       %cellstr(sprintf('y= %.2f + %.2f / x', b(1), b(2)))], fullfile(fdir, 'test_recip'));
   catch 
       disp(sprintf('%s error in recip model.', fname))
   end;

    % y=a+bln(x)
    Y = m_y;
    X = [ones(m_row, 1), log(m_x)];
    [b, bint, r, rint, stats] = regress(Y, X);
    m_ny = b(1) + b(2) * log(m_x);
    t_ny = b(1) + b(2) * log(t_x);
    [r_square, mec, rmse] = errors(t_y, t_ny);
    fprintf(m_out,'%s, Y=A0 + A1 * ln(x), %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);
    
    xfit = linspace(0, max(m_x)*1.1, 50);
    yfit = b(1) + b(2) * log(xfit);
    plotmodel(m_x, m_y, xfit, yfit, 'Logarithmic Fitting Curve', 'FAPAR', [ ...
        cellstr(sprintf('F = %.3f', stats(2))), ... 
        cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
        cellstr(funcformat(b', [cs(''), cs('ln(x)')]))], fullfile(fdir, 'model_log'));
        %cellstr(sprintf('y= %.2f + %.2f ln(x)', b(1), b(2)))], fullfile(fdir, 'model_log'));
    plottest(t_y, t_ny, [ ... 
        cellstr(sprintf('MEC= %.3f', mec)), ...
        cellstr(sprintf('RMSE = %.3f', rmse)), ...
        cellstr(sprintf('R^{2} = %.3f', r_square)), ...
        cellstr(funcformat(b', [cs(''), cs('ln(x)')]))], fullfile(fdir, 'test_log'));
        %cellstr(sprintf('y= %.2f + %.2f ln(x)', b(1), b(2)))], fullfile(fdir, 'test_log'));

    % y=a*e^(b*x)
    Y = m_y;
    X = m_x;
    b0 = [0, 0];
    b = nlinfit(X, Y, @(b, x)(b(1) * exp(b(2) * x)), b0);
    m_ny = b(1) * exp(b(2) * m_x);
    t_ny = b(1) * exp(b(2) * t_x);
    % m_ny = 0.069 * exp(3.0797 * m_x);
    [r_square, mec, rmse] = errors(m_y, m_ny);
    stats = qr0([ones(m_row, 1), (m_x)], m_y, m_ny);
    [r_square, mec, rmse] = errors(t_y, t_ny);
    fprintf(m_out,'%s, Y=A0 * exp(A1 * x), %f, %f, %f, %f, %f, %f, %f, %f, %f\n', fname, stats, r_square, mec, rmse, b);
    fprintf(m_out,'\n');
    
    xfit = linspace(0, max(m_x)*1.1, 50);
    yfit = b(1) * exp(b(2) * xfit);
    plotmodel(m_x, m_y, xfit, yfit, 'Exponent Fitting Curve', 'FAPAR', [ ...
        cellstr(sprintf('F = %.3f', stats(2))), ... 
        cellstr(sprintf('R^{2} = %.3f', stats(1))), ...
        cellstr(sprintf('y= %.2f e^{%.2f x}', b(1), b(2)))], fullfile(fdir, 'model_exp'));
    plottest(t_y, t_ny, [ ... 
        cellstr(sprintf('MEC= %.3f', mec)), ...
        cellstr(sprintf('RMSE = %.3f', rmse)), ...
        cellstr(sprintf('R^{2} = %.3f', r_square)), ...
        cellstr(sprintf('y= %.2f e^{%.2f x}', b(1), b(2)))], fullfile(fdir, 'test_exp'));

end

fclose(m_out);
end 

function plotmodel(x, y, xfit, yfit, xl, yl, finfo, fpath)
    width = 6;     % Width in inches
    height = 4;    % Height in inches
    alw = 0.75;    % AxesLineWidth
    fsz = 14;      % Fontsize
    lw = 1;      % LineWidth
    msz = 6;       % MarkerSize

    clc
    figure(1);
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
    set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties

    plot(x, y,'b+', xfit, yfit,'r-','LineWidth',lw,'MarkerSize',msz);
    ylim([0 1]);
    xlabel(xl);
    ylabel(yl);
    xtic = get(gca,'XTick');
    % xpos = (max(xtic) - min(xtic)) * 0.35 + min(xtic);
    xpos = (max(xtic) - min(xtic)) * 0.05 + min(xtic);
    i = 0;
    for subInfo = finfo
        % ypos = 0.1 + 0.06 * i;
        ypos = 0.7 + 0.06 * i;
        text(xpos, ypos, subInfo, 'FontSize', fsz);
        i = i + 1;
    end
    legend({'Sample Data','Fitting Curve'},'FontSize', fsz,'Location','northwest');
    legend('boxoff');

    print(fpath,'-depsc2','-r300');
    % saveas(fh, fpath);
end

function plottest(yorig, yfit, finfo, fpath)
    width = 6;     % Width in inches
    height = 4;    % Height in inches
    alw = 0.75;    % AxesLineWidth
    fsz = 14;      % Fontsize
    lw = 1;      % LineWidth
    msz = 6;       % MarkerSize
    clc
    figure(1);
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
    set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties

    x = linspace(0,1);
    y = x;
    plot(yorig, yfit,'b+', x, y, 'r-','LineWidth',lw,'MarkerSize',msz);
    ylim([0 1]);
    xlim([0 1]);
    set(gca, 'YTick', [0 0.2 0.4 0.6 0.8 1.0])
    xlabel('Real FAPAR');
    ylabel('Predict FAPAR');
    xtic = get(gca,'XTick');
    xpos = 0.05;
    i = 0;
    for subInfo = finfo
        ypos = 0.75 + 0.06 * i;
        text(xpos, ypos, subInfo, 'FontSize', fsz);
        i = i + 1;
    end

    print(fpath,'-depsc2','-r300');
end

function stats = qr0(X, y, yhat)
    % Check that matrix (X) and left hand side (y) have compatible dimensions
    [n,ncolX] = size(X);

    % Remove missing values, if any
    wasnan = any(isnan(X),2);
    havenans = any(wasnan);
    if havenans
       X(wasnan,:) = [];
    end

    % Use the rank-revealing QR to remove dependent columns of X.
    [Q,R,perm] = qr(X,0);

    if isempty(R)
        p = 0;
    elseif isvector(R)
        p = double(abs(R(1))>0);
    else
        p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
    end
    if p < ncolX
        warning(message('stats:regress:RankDefDesignMat'));
        R = R(1:p,1:p);
        Q = Q(:,1:p);
        perm = perm(1:p);
    end

    nu = max(0,n-p);                % Residual degrees of freedom
    r = y-yhat;                     % Residuals.
    normr = norm(r);
    if nu ~= 0
        rmse = normr/sqrt(nu);      % Root mean square error.
    else
        rmse = NaN;
    end
    s2 = rmse^2;                    % Estimator of error variance.

    SSE = normr.^2;              % Error sum of squares.
    RSS = norm(yhat-mean(y))^2;  % Regression sum of squares.
    TSS = norm(y-mean(y))^2;     % Total sum of squares.
    % r2 = 1 - SSE/TSS;            % R-square statistic.
    % excel use RSQ to calculate the R2, 
    % https://support.office.com/en-us/article/RSQ-function-d7161715-250d-4a01-b80d-a8364f2be08f
    r2 = corr(y, yhat, 'type', 'Pearson'); % from excel 

    if p > 1
        F = (RSS/(p-1))/s2;      % F statistic for regression
    else
        F = NaN;
    end
    prob = fpval(F,p-1,nu); % Significance probability for regression
    stats = [r2 F prob s2];

end

function funcstr = funcformat(p_term, x_term)
% p1*x1 (+ or -) p2*x2 ...

    if ~ isequal(size(p_term), size(x_term))
        error('sizes of parameters and x terms are not equal')
    end

    pl = length(p_term);
    if pl <= 0
        funcstr = ''
    end

    sfunc = [];
    for i = 1:pl
        if i == 1
            if p_term(i) < 0
                sfunc = ['-', sprintf('%.2f', abs(p_term(i))), x_term(i)];
            else
                sfunc = [sprintf('%.2f', abs(p_term(i))), x_term(i)];
            end
        else
            if p_term(i) < 0
                sfunc = [sfunc, '-', sprintf('%.2f', abs(p_term(i))), x_term(i)];
            else
                sfunc = [sfunc, '+', sprintf('%.2f', abs(p_term(i))), x_term(i)];
            end
        end
    end

    funcstr = 'y= ';
    for s = sfunc
        funcstr = strcat(funcstr, char(s));
    end
end

function s = cs(ss)
    s = cellstr(ss)
end
