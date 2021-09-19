% This code generates Global Isotropic Nonstationary Correlation shift
% by using the Gaussian Markov random field (GMRF).
%%%%%%%%%%%%%%%%
clc;clear;
m = 256; % size of simulated surface n*n
c=10; a=2; % parameters of covarince function
fm=2;% magnitude of conditional mean shift
lambda2=-1;lambda1=4; % weights of adjacency matrix
cd GMRF % contain codes for generating GMRF
[idx,D,condk,mu,C,Qcond]=GMRF_input(m,lambda1,lambda2);%generate correlation function by using the Cholesky decomposition of the precision matrix 
yk=fm.*ones(m,1); 
mucond=mu(idx)+(Qcond\(-D(idx,condk)*(yk-mu(condk)))); % the condistional mean surface
x=MRF(m,mucond,C, idx, D, condk,yk); % generate the simulated surface
imagesc(x); colormap(bone);colorbar;
%%%%%%%%%%%%%%%%%%%%Functions%%%%%%%%%%%%%%%%%%%%%%%%%

function [y1]= MRF(m,mucond,C, idx, D, condk,yk);
 y1=zeros(m,m);
 z=zeros(length(idx),1);
 x=zeros(length(idx),1);
z = randn(m^2-length(condk),1); % z is N(0,I)
x = mucond+C'\z;
y=zeros(m^2,1);
y(idx)=x;
y(condk)=yk;
y1=reshape(y,m,m);
end

function [idx,D,condk,mu,C,Qcond]= GMRF_input(m,d1,d2);
% clc;clear all
% m = 256; % Grid is m x m
% d1 = 1; % Central stencil weight
% d2 = -0.25; % Neighbour weight

% Elements conditioned on and their values
cond=[ones(m,1),(1:1:m)'];
condk=zeros(size(cond,1),1);

for i=1:size(cond,1)
    condk(i)=ij2k(cond(i,1),cond(i,2),m);
end

% yk=1.*ones(m,1);
nels = m*(5*m-4); % Number of non-zero elements on grid

% Pre-allocate memory to form the sparse precision matrix

a = zeros(1,nels);
b = zeros(1,nels);
c = zeros(1,nels);

% Compute the links and weights for precision matrix
k=0;
for i=1:m
    for j=1:m
        A = findneigh(i,j,m);
        nnb = size(A,1);
        for h=1:nnb
            a(k+h)= ij2k(i,j,m);
            b(k+h)= ij2k(A(h,1),A(h,2),m);
            if h==1
                c(k+h) = d1;
            else
                c(k+h) = d2;
            end
        end
        k = k+nnb;
    end  
end
% Construct the precision matrix

D = sparse(a,b,c,m^2,m^2);
% Construct mean vector

mu=sparse([],[],[],m^2,1,0);
% Obtain remaining indices
idx=(1:1:m^2)';
idx(condk)=[];
% Conditional Precision matrix
Qcond = D(idx,idx);

% mucond=mu(idx)+(Qcond\(-D(idx,condk)*(yk-mu(condk)))); 
C = chol(Qcond,'lower'); 
end


