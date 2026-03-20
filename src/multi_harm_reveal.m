function [curve,freqs]=multi_harm_det(center,span,res,order,data)
freqs=(center-span/2.0):res:(center+span/2.0);
ls=length(freqs);
czts=zeros(ls,order);
for v=1:order
czts(:,v)=czt(data',ls,exp(-2j*pi*res/1080.0*v),exp(2j*pi*freqs(1)/1080.0*v));
end
curve=sum(abs(czts),2)';
% curve=sum(abs(czts)./sqrt(sum(abs(czts),1)),2)';
end

function part_freqs=track_side(st,ed,pos0,k0,mr,mr2,ord,tot_data)
sig=sign(ed-st);
curr_pos=pos0;
curr_k=k0*sig;
prev_k=curr_k;
part_freqs=zeros(1,abs(ed-st)+1);
for u=1:(abs(ed-st)+1)
    m=st+(u-1)*sig;
    ldata=permute(sum(tot_data(:,:,m),2),[1,3,2])/750/2;

    [cv,fq]=multi_harm_det(curr_pos,2,0.1,ord,ldata);
    [~,det_pos_itr]=max(cv);
    det_pos=fq(det_pos_itr);

    part_freqs(u)=det_pos;

    tmp_k=curr_k;
    curr_k=curr_k+(det_pos-curr_pos)*mr+mr2*(curr_k-prev_k)^3;
    prev_k=prev_k+(tmp_k-prev_k)*0.8;
    curr_pos=det_pos+curr_k;
end
end
%%
% trace

paras=[
    1,451,155,129,0.2;
    560,653,620,165,-1.5;
    654,923,786,194,1.0;
    953,1115,1013,314,-2;
    1116,1266,1193,162,-.3;
    1267,1450,1377,257,2;
    1592,1720,1650,427,-1.5;
    1721,2087,1915,321,-.4;
    2088,2305,2200,175,-.7;
    2306,2565,2420,134,.3;
    ];
% each trace part 
% [left end, right end, starting frame, starting pos, curvature]
% starting pos read from fft image

mix_rate=0.1;
mix_rate2=0.2;
order=6;
tr_freqs=zeros(1,2565);
for n=1:10
    L=paras(n,1);R=paras(n,2);tm=paras(n,3);pos0=paras(n,4)-1;k0=paras(n,5);
    tr_freqs(tm:R)=track_side(tm,R,pos0,k0,mix_rate,mix_rate2,order,shifts);
    tr_freqs(tm:-1:L)=track_side(tm,L,pos0,k0,mix_rate,mix_rate2,order,shifts);
end

%% 
% fine tune
order=50;
ft_freqs=zeros(1,2565);
for n=1:2565
    [cv,fq]=multi_harm_det(tr_freqs(n),2,0.001,order,permute(sum(shifts(:,:,n),2),[1,3,2])/750/2);
    [~,det_pos_itr]=max(cv);
    ft_freqs(n)=fq(det_pos_itr);
end