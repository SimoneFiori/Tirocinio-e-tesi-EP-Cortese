% Calcolo del jerk online (real time)
function jist = jerk(R)
    n = size(R,3); %%%% supponiamo = 4
    DT = 0.01; % Questo è l'intervallo di campionamento del sensore
    %preallocamento memoria
    Omega=zeros(3,3,3); %%%size(omega,3) = 3
    z = zeros(3,3); %%%size(z,2) = 3
    jnn = zeros(3,1); %%%size(jnn,2) = 2
    jist = zeros(1,1); %%%size(jist,2) = 2 
    %Questo è il jerk istantaneo non normalizzato (il jerk istantaneo non si può normalizzare)
    for k=1:n-1
        Omega(:,:,k) = (1/DT)*real(logm(R(:,:,k)'*R(:,:,k+1)))
        %%% k=1 omega(:,:,1) = f(R(1),R(2))
        %%% k=2 omega(:,:,2) = f(R(2),R(3))
        %%% k=3 omega(:,:,3) = f(R(3),R(4))
        z(:,k) = [Omega(1,2,k),Omega(1,3,k),Omega(2,3,k)]
        %%% k=1 z(:,1) = f(omega(:,:,1))
        %%% k=2 z(:,2) = f(omega(:,:,2))
        %%% k=3 z(:,3) = f(omega(:,:,3))
        if k == 2, 
            jnn(:,k-1) = (1/DT^2)*(z(:,k+1) - 2*z(:,k) + z(:,k-1))
            %%% k=2 jnn(:,1) = f(z(:,3),z(:,2),z(:,1))
            %%%!!! k=3 jnn(:,2) = f(z(:,4),z(:,3),z(:,2)) non è possibile,
            %%%!!! quindi if k=2
            jist(k-1) = norm(jnn(:,k-1))
            %%% k=2 jist(1) = norm(jnn(:,1))
        end
    end
end