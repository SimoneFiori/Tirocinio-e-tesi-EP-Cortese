% Function to compute the Cartesian jerk by 1 
function jist1 = jerk(R)
    n = size(R,3);
    DT = 0.01; % Questo è l'intervallo di campionamento del sensore
    %preallocamento memoria
    Omega=zeros(3,3,n-1); 
    z = zeros(3,n-1);
    jnn = zeros(3,n-2); 
    jist = zeros(1,n-2); 
    %Questo è il jerk istantaneo non normalizzato (il jerk istantaneo non si può normalizzare)
    for k=2:n
        Omega(:,:,k) = (1/DT)*real(logm(R(:,:,k-1)'*R(:,:,k)));
        z(:,k) = [Omega(1,2,k),Omega(1,3,k),Omega(2,3,k)];
        if k>2, 
            jnn(:,k) = (1/DT^2)*(z(:,k) - 2*z(:,k-1) + z(:,k-2)); 
        end
        jist(k) = norm(jnn(k));
    end
    jist1=jist(7:size(jist,2)); %scarto i primi 6 valori che sono zero
end