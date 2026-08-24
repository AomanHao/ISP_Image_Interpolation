% Copyright (c) 2016 Nicolas Weber and Sandra C. Amend / GCC / TU-Darmstadt. All rights reserved. 
% Use of this source code is governed by the BSD 3-Clause license that can be
% found in the LICENSE file.
function [ oImage] = dpid(iImage, oWidth, oHeight, lambda)
	fprintf('## Rapid, Detail-Preserving Image Downscaling ##\n');
	fprintf('--> http://www.gcc.tu-darmstadt.de/home/proj/dpid\n');
	fprintf('\n');
	
    % set default parameters
    if nargin < 1
		fprintf('usage: dpid(<input-filename>[, output-width=128][, output-height=0][, lambda=1.0]);\n');
		fprintf('  <required> [optional]\n\n');
		fprintf('examples:\n');
		fprintf('  dpid(''myImage.jpg'');              // downscales using default values\n');
		fprintf('  dpid(''myImage.jpg'', 256);         // downscales to 256px width, keeping aspect ratio\n');
		fprintf('  dpid(''myImage.jpg'', 0, 256);      // downscales to 256px height, keeping aspect ratio\n');
		fprintf('  dpid(''myImage.jpg'', 128, 0, 0.5); // downscales to 128px width, keeping aspect ratio, using lamdba=0.5\n');
		fprintf('  dpid(''myImage.jpg'', 128, 128);    // downscales to 128x128px, ignoring aspect ratio\n');
		return;
    end
    if nargin < 2; oWidth = 128; end;
    if nargin < 3; oHeight = 0; end;
    if nargin < 4; lambda = 1.0; end;

    % print error
    if (oWidth == 0) && (oHeight == 0); error('either width or height has to be non-zero!'); end;
    
    % read image
    [iHeight, iWidth, channels] = size(iImage);    
    
    % calc target sizes
    if oWidth  == 0; oWidth  = round(iWidth  * oHeight/iHeight); end;
    if oHeight == 0; oHeight = round(iHeight * oWidth /iWidth);  end;
    
    % set outputFilename
    outputFilename = strcat( '_', num2str(oWidth), 'x', num2str(oHeight), '_', num2str(lambda), '.png');
       
    % allocate average image
    avgImage = zeros(oHeight, oWidth, channels);
    oImage   = zeros(oHeight, oWidth, channels);
 
    % calc patch size
    pWidth  = iWidth  / oWidth;
    pHeight = iHeight / oHeight;
    
    % calc average image
    for py = 0 : (oHeight - 1)
        for px = 0 : (oWidth - 1)
            % calc indizies
            sx = max(px * pWidth, 0);
            ex = min((px+1) * pWidth, iWidth);
            sy = max(py * pHeight, 0);
            ey = min((py+1) * pHeight, iHeight);
            
            % calc final indizies
            sxr = floor(sx);
            syr = floor(sy);
            exr = ceil(ex);
            eyr = ceil(ey);
            
            % init color
            avgF = 0;
            
            % iterate pixels
            for iy = syr : (eyr-1)
                for ix = sxr : (exr-1)
                    f = 1;
                    
                    if(ix < sx);        f = f * (1.0 - (sx - ix)); end;
                    if((ix+1) > ex);    f = f * (1.0 - ((ix+1) - ex)); end;
                    if(iy < sy);        f = f * (1.0 - (sy - iy)); end;
                    if((iy+1) > ey);    f = f * (1.0 - ((iy+1) - ey)); end;
                    
                    avgImage(py + 1, px + 1, :) = avgImage(py + 1, px + 1, :) + (iImage(iy + 1, ix + 1, :) .* f);
                    avgF = avgF + f;
                end
            end
            
            avgImage(py + 1, px + 1, :) = avgImage(py + 1, px + 1, :) ./ avgF;
        end
    end
    
    % calc output image
    for py = 0 : (oHeight - 1)
        for px = 0 : (oWidth - 1)
            % calc average patch color
            avg = zeros(1, channels + 1);
            
            % top
            if(py > 0)
                if(px > 0);         avg = avg + [reshape(avgImage(py, px,   :), [1 channels]) * 1 1]; end
                                    avg = avg + [reshape(avgImage(py, px+1, :), [1 channels]) * 2 2];
                if((px+1) < oWidth);avg = avg + [reshape(avgImage(py, px+2, :), [1 channels]) * 1 1]; end
            end
            
            % left
            if(px > 0);             avg = avg + [reshape(avgImage(py+1, px,   :), [1 channels]) * 2 2]; end
                                    avg = avg + [reshape(avgImage(py+1, px+1, :), [1 channels]) * 4 4];
            if((px+1) < oWidth);    avg = avg + [reshape(avgImage(py+1, px+2, :), [1 channels]) * 2 2]; end
            
            % bottom
            if((py+1) < oHeight)
               if(px > 0);          avg = avg + [reshape(avgImage(py+2, px,   :), [1 channels]) * 1 1]; end
                                    avg = avg + [reshape(avgImage(py+2, px+1, :), [1 channels]) * 2 2];     
               if((px+1) < oWidth); avg = avg + [reshape(avgImage(py+2, px+2, :), [1 channels]) * 1 1]; end
            end
                        
            % normalize
            avg = avg / avg(channels + 1);
            avg = avg(1:channels); % remove 4th element
                        
            % calc indizies
            sx = max(px * pWidth, 0);
            ex = min((px+1) * pWidth, iWidth);
            sy = max(py * pHeight, 0);
            ey = min((py+1) * pHeight, iHeight);
            
            % calc final indizies
            sxr = floor(sx);
            syr = floor(sy);
            exr = ceil(ex);
            eyr = ceil(ey);
            
            % init color
            oF = 0;
            
            % iterate pixels
            for iy = syr : (eyr-1)
                for ix = sxr : (exr-1)
                    if lambda == 0
                        f = 1;
                    else
                        f = norm(avg - reshape(iImage(iy + 1, ix + 1, :), [1 channels]));
                        % f = f / sqrt(255^2 * 3);
                        f = f ^ lambda;
                    end
                    
                    if(ix < sx);        f = f * (1.0 - (sx - ix)); end;
                    if((ix+1) > ex);    f = f * (1.0 - ((ix+1) - ex)); end;
                    if(iy < sy);        f = f * (1.0 - (sy - iy)); end;
                    if((iy+1) > ey);    f = f * (1.0 - ((iy+1) - ey)); end;
                    
                    oImage(py + 1, px + 1, :) = oImage(py + 1, px + 1, :) + (iImage(iy + 1, ix + 1, :) * f);
                    oF = oF + f;
                end
            end
            
            if oF == 0
                oImage(py + 1, px + 1, :) = avg;
            else
                oImage(py + 1, px + 1, :) = oImage(py + 1, px + 1, :) / oF;
            end
        end
    end
    
%     imwrite(uint8(oImage), outputFilename);
end
