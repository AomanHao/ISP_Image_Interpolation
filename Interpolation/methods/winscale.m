function B = winscale(A, scale, anti_alias)
% Winscale: 基于面积像素模型的图像缩放
%
%   B = winscale(A, scale)
%       A        : 输入灰度或 RGB 图像 (H×W×C)
%       scale    : 标量或 2 元素向量 [sx, sy]
%       anti_alias : (可选) 是否开启简单抗锯齿，默认 true
%
%   例：
%       I  = imread('lena.png');
%       J  = winscale(I, 1.5);        % 放大 1.5 倍
%       imshow(J);

if nargin < 3, anti_alias = true; end
if numel(scale) == 1
    sx = scale;
    sy = scale;
else                    sx = scale(1); sy = scale(2); end

[H, W, C] = size(A);
Ho = round(H * sy);  Wo = round(W * sx);
B  = zeros(Ho, Wo, C, class(A));

% 反向映射：输出像素中心坐标 -> 输入坐标
y_out = (0.5:Ho-0.5) / sy - 0.5;   % 中心对齐
x_out = (0.5:Wo-0.5) / sx - 0.5;

% 抗锯齿：对输入做轻微高斯预滤波（可选）
%     if anti_alias && (sx < 1 || sy < 1)
%         sigma = max(0.5 / sx, 0.5 / sy);
%         A = imgaussfilt(A, sigma);
%     end

% 逐通道处理
for ch = 1:C
    A_ch = double(A(:,:,ch));
    for j = 1:Wo
        x0 = x_out(j);
        for i = 1:Ho
            y0 = y_out(i);
            
            % 目标像素在输入图上的覆盖矩形 [x0, x0+1/sx] × [y0, y0+1/sy]
            x1 = x0 + 1/sx;   y1 = y0 + 1/sy;
            
            % 计算与四个相邻原像素的重叠面积
            xL = floor(x0);  xR = xL + 2;
            yT = floor(y0);  yB = yT + 2;
            
            % 实际重叠区间
            dxL = max(0, min(xR, x1) - max(xL, x0));
            dyT = max(0, min(yB, y1) - max(yT, y0));
            dxR = max(0, min(xR+1, x1) - max(xR, x0));
            dyB = max(0, min(yB+1, y1) - max(yB, y0));
            
            % 四个权重
            w00 = dxL * dyT;
            w10 = dxR * dyT;
            w01 = dxL * dyB;
            w11 = dxR * dyB;
            
            % 边界检查
            xL = max(xL, 1);  xR = min(xR, W);
            yT = max(yT, 1);  yB = min(yB, H);
            
            % 加权求和
            wALL = w00+w10+w01+w11;
            val = 0;
            if w00 > 0, val = val + w00 * A_ch(yT, xL); end
            if w10 > 0, val = val + w10 * A_ch(yT, xR); end
            if w01 > 0, val = val + w01 * A_ch(yB, xL); end
            if w11 > 0, val = val + w11 * A_ch(yB, xR); end
            val = val/wALL;
            B(i,j,ch) = val;
        end
    end
end

% 还原数据类型
B = cast(B, class(A));
end