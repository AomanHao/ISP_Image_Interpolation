%% 程序分享
% 个人博客 www.aomanhao.top
% Github https://github.com/AomanHao
% CSDN https://blog.csdn.net/Aoman_Hao
%--------------------------------------

%% ISP处理之 Interpolation
clear
close all
clc
addpath('./methods');
%% load data
I=imread('.\data\kodim19.png');

%% pre para
d = 2; % downscaling factor
method_hub = {'2newton','bicubic'};%,'bicubic'

for i_me = 1:numel(method_hub)
    scaler_type =  method_hub{i_me};
    [row, col, chan] = size(I);
    row_out = floor(row*d);
    col_out = floor(col*d);
    result = zeros(row_out, col_out, chan);
    
    for ch = 1:chan
        img = I(:,:,ch);
        
        %% image scaler
        tic;
        switch scaler_type
            case 'nearest'
                result(:,:,ch) = imresize(img,d,'nearest');
            case 'bilinear'
                result(:,:,ch) = imresize(img,d,'bilinear');
                
            case '2newton'
                result(:,:,ch) = fun_scaler_2newton(img,d);
                
            case 'bicubic'
                result(:,:,ch) = imresize(img,d,'bicubic');
                
            case 'dpid'
                Lambda = 2;  % tuning parameter
                result(:,:,ch) = dpid(img, col_out, row_out, Lambda);
                
            case 'inedi'
                result(:,:,ch)=inedi(img,d);
                
                
        end
    end
    toc;
    t=toc;
    %% save result%%%%%%%%%%%%%%
    imwrite(uint8(result),strcat('.\result\',scaler_type,'.png'));
end

