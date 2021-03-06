
function [P,p,M,K,N,L,D,R,Rj,RRj,a,b,SigJ,EE]  = MOAFLorenz(P,p,M,K,D,N,L,R,Rj,RRj,a,b,e1,e2,H,tol,binmax,dimx,dimX,dimu,dimuj,jlag,jlead1,jlead0,SigJ,theta)
EE=1;
 try
% rho1=theta(1); %persistence of technology
% rho2=theta(2); %persistence of demand
% sigu=theta(3);  %s.d. of state innov
% sigud=theta(4); %s.d. "demand" shock
% sigur=theta(5);  %s.d. of m.p. shock
% sigaj=theta(6);  %s.d. of island tech
% sigzj1=theta(7);  %s.d. of private info noise
% sigzj2=theta(8);  %s.d. of private info noise
% sigdj=theta(9);  %s.d. of island demand shock
% sigmbd=theta(10); %s.d. of m-b-d signal
varphi=theta(11); %labour supply curvature
delta=theta(12); %elasticity of demand
fir=theta(13);%Interest inertia
fipi=(1-fir)*theta(14); %Taylor param;
fiy=(1-fir)*theta(15); %Taylor rule param
stick=theta(16); %Calvo parameter
beta=theta(17); %discount rate


%MBD params
omega=theta(18);  %unconditional prob of S=1, i.e. of observing pub signal
% gamma=theta(19);    %s.d. multiplier of u when S=1

lambda=(1-stick)*(1-stick*beta)/stick;

Mst=M;
Nst=N;
Kst=K;
ast=a;
bst=b;



EE=1;


Step=ones(5,1)*0.5;Hstep=0.5;
Diff=ones(1,5);DiffOld=ones(1,5);iter=0;
while max(Diff) >= tol;
    
    iter=iter+1;
    
    for j=1:binmax
        
        if abs(max(max(eig(Mst(:,:,jlead1(j)+1)*H)))) && abs(max(max(eig(Mst(:,:,jlead0(j)+1)*H)))) <=1;
        a(:,:,j)=lambda*(bst(:,:,j)-e1)+lambda*delta*varphi*(bst(:,:,j)-e1) +  omega*( beta*ast(:,:,jlead1(j)+1)*Mst(:,:,jlead1(j)+1)*H) + (1-omega)*( beta*ast(:,:,jlead0(j)+1)*Mst(:,:,jlead0(j)+1)*H);
         b(:,:,j)=e2-fipi*ast(:,:,j)-fiy*bst(:,:,j)+...
            omega*((0.5*ast(:,:,jlead1(j)+1)+bst(:,:,jlead1(j)+1))*Mst(:,:,jlead1(j)+1)*H) +...
            (1-omega)*((0.5*ast(:,:,jlead0(j)+1)+bst(:,:,jlead0(j)+1))*Mst(:,:,jlead0(j)+1)*H);
      

       
        else
          a(:,:,j)=ast(:,:,j)  ;
          b(:,:,j)=bst(:,:,j)  ;

          
        end
             
        
        D(3,:,j)=a(:,:,j);
        D(4,:,j)=delta*a(:,:,j) + b(:,:,j);
        D(5,:,j)=(1-fir)*fipi*a(:,:,j) + (1-fir)*fiy*b(:,:,j);
    
        
    
        P(:,:,j)=M(:,:,j)*p(:,:,jlag(j)+1)*M(:,:,j)' + N(:,:,j)*N(:,:,j)';
        L(:,:,j)=(D(:,:,j)*M(:,:,j))*p(:,:,jlag(j)+1)*(D(:,:,j)*M(:,:,j))'+(D(:,:,j)*N(:,:,j) + RRj(:,:,j))*(D(:,:,j)*N(:,:,j)+RRj(:,:,j))';
        K(:,:,j)=(M(:,:,j)*p(:,:,jlag(j)+1)*(D(:,:,j)*M(:,:,j))'+N(:,:,j)*N(:,:,j)'*D(:,:,j)'+N(:,:,j)*RRj(:,:,j)')/(L(:,:,j));
        p(:,:,j)=P(:,:,j)-K(:,:,j)*L(:,:,j)*K(:,:,j)';
    
        KDM=K(:,:,j)*D(:,:,j)*M(:,:,j);
        M(dimx+1:end,:,j)=[KDM(1:end-dimx,1:end-dimx) zeros(dimX-dimx,dimx)] + [zeros(dimX-dimx,dimx) M(1:end-dimx,1:end-dimx,j)] - [zeros(dimX-dimx,dimx) KDM(1:end-dimx,1:end-dimx)];
        
        KDN=K(:,:,j)*D(:,:,j)*N(:,:,j);
        KR=K(:,:,j)*[R(:,:,j) Rj(:,:,j)*0];%Impose that cross sectional average of idiosyncratic signals is zero
        N(dimx+1:dimX,:,j)=KDN(1:end-dimx,:) + KR(1:end-dimx,:) ;

        SigJ(:,:,j)=(eye(dimX)-K(:,:,j)*D(:,:,j))*SigJ(:,:,jlag(j)+1)*(eye(dimX)-K(:,:,j)*D(:,:,j))'+K(:,:,j)*Rj(:,:,j)*Rj(:,:,j)'*K(:,:,j)';
 
       
    end
    
    DiffM=max(max(max(abs(M-Mst))));
    DiffN=max(max(max(abs(N-Nst))));
    Diffa=max(max(max(abs(a-ast))));
    Diffb=max(max(max(abs(b-bst))));
    DiffK=max(max(max(abs(K-Kst))));
    Diff=([max(Diffa),max(Diffb),max(DiffM),max(DiffN),max(DiffK)]);
  
    
    Step=(1-Hstep)*Step+Hstep*Step.*(DiffOld./Diff)';
    Step(1)=max([Step(1),0.001;]);
    Step(2)=max([Step(2),0.001;]);
    Step(3)=max([Step(3),0.001;]);
    Step(4)=max([Step(4),0.001;]);
    Step(5)=max([Step(5),0.001;]);
    
    
    Step(1)=min([Step(1),1;]);
    Step(2)=min([Step(2),1;]);
    Step(3)=min([Step(3),1;]);
    Step(4)=min([Step(4),1;]);
    Step(5)=min([Step(5),1;]);
   
    
    DiffOld=Diff;
    
    ast=Step(1)*a+(1-Step(1))*ast;a=ast;
    bst=Step(2)*b+(1-Step(2))*bst;b=bst;
    Mst=Step(3)*M+(1-Step(3))*Mst;M=Mst;
    Nst=Step(4)*N+(1-Step(4))*Nst;N=Nst;
    Kst=Step(5)*K+(1-Step(5))*Kst;K=Kst;
    
    if iter > 3000
        iter
        EE=0;
        M=[];
        Diff=Diff*0;
    end
end

catch
    display('No solution to MOAF')
   EE=0;
end