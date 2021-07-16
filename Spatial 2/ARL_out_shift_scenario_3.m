clc;clear;
b1=csvread('wang_beta_historical.csv');
t1=csvread('wang_theta_historical.csv');
t1=t1(:,2:3);
t=mean(t1);
bm=mean(b1);
%%%%%%%%%%%%%%
n = 2^8;c=10;a=2;
m=n;
G=d_maker(n,c,a);
Ga = fft2(G);
Z= iso_Exp(Ga,n);
[resy0,resx0]=size(Z);
[p0,n0]=variogram_maker1(resx0);
np=n0(2:resx0/2+1);
hs=[1:resx0/2];
%%%%%%%%%%%%%%%
tmp=zeros(2,2);
S2=zeros(2,2);
l=length(t1);
for k=1:l-1
    tmp=(1/(2*(l-1)))*(t1(k+1,:)-t1(k,:))'*(t1(k+1,:)-t1(k,:));
    S2=S2+tmp;
end
iS2=inv(S2);
%%%%%%%%%%%%%%
r=16;
index=[1:(n/r):n];
x=index;
x=repmat(x,1,r);
y=index;
y=repmat(y,r,1);
y=reshape(y,1,numel(y));
B=[ones(r^2,1) x' y'];
%%%%%%%%%%%%%%%%%%%%%
options = optimoptions(@fmincon,'GradObj','on','Display','off');
nos=10000s;
f=[0.5,1,1.5,2];
d=[4 2;-1 -0.5];
fault=combvec(f,d);
UCL1=[17];
UCL2=[22]; 
ARL=zeros(1,size(fault,2));
Z=zeros(n,n);
%%%%%%%%%%%%%%%%%%%%%

tic
 for j=1:size(fault,2)
     cd GMRF
   [idx,D,condk,mu,C,Qcond]= GMRF_input(m,fault(2,j),fault(3,j));
    yk=fault(1,j).*ones(m,1);
    mucond=mu(idx)+(Qcond\(-D(idx,condk)*(yk-mu(condk))));
    cd ../
    counter=zeros(1,nos);
   for i=1:nos
       flag =0;
      [j,i]
         while flag == 0
              z1=zeros(r,r);
              theta=zeros(1,3);
              beta=zeros(1,3);
              cd GMRF
                 Z=MRF(m,mucond,C, idx, D, condk,yk);
                 cd ../
%               Z= iso_Exp(Ga,n);  %image generating
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              for jj=1:r
                z1(jj,:)=Z(((jj-1)*(n/r))+1,index); %downsampling
              end
              z=reshape(z1,r^2,1);
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              [gam]=emprical_variogram_mex(Z,resy0,resx0,p0,n0);  %estimating parameters
              fun=@(x)fun2(x,np,gam,hs);
              theta= fmincon(fun,[.5,1,12],[],[],[],[],[0 0 0],[],[],options);
              sf = fit([x', y'],z,'poly11');
              beta= coeffvalues(sf);
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              covert=wang_exp(r,theta(1),theta(2),theta(3),n);
              icovert=inv(covert);
              fisher1=B'*icovert*B;
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               T1=(beta-bm)*fisher1*(beta-bm)';
               T2=(theta(2:3)-t)*iS2*(theta(2:3)-t)';
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               counter(i)=counter(i)+1;
                    if T1 > UCL1 || T2> UCL2
                    flag=1;
                   end
        end
 end

   ARL(1,j)=sum(counter)/nos;
   
end
toc



    