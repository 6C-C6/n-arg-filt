extended_wi=2420;
valid_start=393;valid_end=1528;
valid_wi=valid_end-valid_start+1;
img_ts=[200:440,565:920,960:1445,1595:2550]; %frames that are trustable for original image extraction
img_total=1:2565;
lr=0.03; %#ok<NASGU> %learning rate
batch_size=16; %since 2k images will eat all the mem space; value won't affect the result much
detRest=false; %determine the shift values of rest frames beside trustable ones
if detRest
    img_ts=[img_total(~ismember(img_total,img_ts(1:(end-batch_size+1)))),1:(batch_size-1)]; %#ok<UNRCH>
    lr=0;
end
batch_num=floor(size(img_ts)/batch_size);
batch_num=batch_num(2);
tmp_imgs=zeros(1080,1920,3,batch_size);
batch_imgs=zeros(1080,valid_wi,batch_size);
shift_space=zeros(1080,extended_wi);
diffs=zeros(1080,valid_wi);

%init
if ~detRest %#ok<NOPTS>
    shifts=zeros(1080,2,2565);
    prev_shifts=shifts;
    tar_img=randn(1080,valid_wi)*0.05+0.4; %init from random
    % tar_img=randn(1080,valid_wi)*0.05+tar_img; %init from certain img
end
run_index=1;
scan_step=128; %initial scan step, will take a lot of time, even more with smaller step

%--init

%<!-->if you're in the initial run, enable init--init part; change the code
%to start with certain image, if you know what you're doing!

%<!-->to resume from a certain run, disabe init--init part,keep run_index, 
% let shifts=prev_shifts and tar_img=prev_tar_img, then start the program.

%<!-->to finish the rest, let detRest=true, enable init--init and start.
shift_vals=zeros(1080,batch_size,2);

while scan_step>=1
    downscale=scan_step;
    downscale_num=floor(valid_wi/downscale);
    err_downsc=zeros(1080,downscale_num);
    diffs_downsc=err_downsc;
    downsc_start=floor((valid_wi-downscale*downscale_num)/2)+1;
    if run_index==1
        scan_num=floor(2*valid_wi/scan_step);
        scan_start=floor(-scan_step*scan_num/2);
        scan_end=valid_wi;
        %only for the 1st run
    else
        scan_start=-scan_step*2;
        scan_end=scan_step*2;
    end
    for ba_n=1:batch_num

        for im_n=1:batch_size
            tmp_imgs(:,:,:,im_n)=imread(sprintf("filtered\\f%.4d.png",img_ts((ba_n-1)*batch_size+im_n)));
            if img_ts((ba_n-1)*batch_size+im_n)<192 %linear opacity raise
                tmp_imgs(:,:,:,im_n)=tmp_imgs(:,:,:,im_n).*192.0./img_ts((ba_n-1)*batch_size+im_n);
            end
        end
        batch_imgs=reshape(tmp_imgs(:,valid_start:valid_end,1,:),1080,valid_wi,batch_size)./256;
        
        tar_img_modif=zeros(1080,valid_wi);
        ext_tar_img=[tar_img,zeros(1080,extended_wi-valid_wi)];
        for im_n=1:batch_size
            viber=randi([0,scan_step-1],1,2);
            min_uve=zeros(1080,3+downscale_num);
            min_uve(:,3)=1e64;
            for u=(scan_start-viber(1)):scan_step:scan_end
                for v=(scan_end+viber(2)):(-scan_step):scan_start
                    for line=1:1080
                        shift_space(line,:)=circshift(ext_tar_img(line,:),u+prev_shifts(line,1,img_ts((ba_n-1)*batch_size+im_n)))+circshift(ext_tar_img(line,:),v+prev_shifts(line,2,img_ts((ba_n-1)*batch_size+im_n)));
                    end
                    diffs=batch_imgs(:,:,im_n)-shift_space(:,1:valid_wi);
                    for scan_n=1:downscale_num
                        diffs_downsc(:,scan_n)=mean(diffs(:,downsc_start-1+(scan_n-1)*downscale+(1:downscale)),2);
                    end
                    err_downsc=diffs_downsc.^2;
                    % err_downsc=(diff([batch_imgs(:,:,im_n),zeros(1080,1)],[],2)-diff([shift_space(:,1:valid_wi),zeros(1080,1)],[],2)).^2;
                    for line=1:1080
                        if(sum(err_downsc(line,:))*(1+1e-6)<min_uve(line,3))
                            min_uve(line,:)=[u+prev_shifts(line,1,img_ts((ba_n-1)*batch_size+im_n)),v+prev_shifts(line,2,img_ts((ba_n-1)*batch_size+im_n)),sum(err_downsc(line,:)),diffs_downsc(line,:)];
                        end
                    end
                end
            end
            min_uve(:,1:2)=mod(min_uve(:,1:2)+valid_wi,extended_wi)-valid_wi;
            %learn tar_img
            if lr>1e-7
                for scan_shift=1:downscale
                    occu=zeros(1080,extended_wi);
                    for line=1:1080
                        occu(line,downsc_start-1+((1:downscale_num)-1).*downscale+scan_shift)=min_uve(line,4-1+(1:downscale_num));
                        occu(line,:)=circshift(occu(line,:),-min_uve(line,1))+circshift(occu(line,:),-min_uve(line,2));
                    end
                    tar_img_modif=tar_img_modif+occu(:,1:valid_wi);
                end
            end
            shifts(:,:,img_ts((ba_n-1)*batch_size+im_n))=min_uve(:,1:2); %#ok<SAGROW>
        end
        tar_img=max(min(tar_img+tar_img_modif.*lr,0.5),0);
        imshow(tar_img);
        tar_img(1:1080,1100:1136)=max(tar_img(1:1080,1100:1136),0.3);
        tar_img(1:1080,1:20)=max(tar_img(1:1080,1:20),0.3);
    end
    scan_step=floor(scan_step/2);
    run_index=run_index+1;
    prev_shifts=shifts;
    prev_tar_img=tar_img;
end