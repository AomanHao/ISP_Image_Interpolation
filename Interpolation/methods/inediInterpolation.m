function img_inedi=inediInterpolation(img_o)


img_o255=round(img_o*255);
img_result=inedi(img_o255,1);
img_result=double(img_result);
img_result=[img_result img_result(:,end)];
img_result=[img_result;
    img_result(end,:)];
img_inedi=img_result/255;