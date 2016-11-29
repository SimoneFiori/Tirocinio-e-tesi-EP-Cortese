% Function to compute the Cartesian jerk by 1 
% Andrea Civita, Giuseppe Romani and Simone 2 
% Fiori (Universita' Politecnica delle Marche, 3 
% October 2015) 4 
function J = jerk(R,DT) 
    L = size(R,3);
    z = zeros(3,L-1);
    for k=2:L
        Omega = (1/DT)*real(logm(R(:,:,k-1)'*R(:,:,k)));
        z(:,k-1) = [Omega(1,2),Omega(1,3),Omega(2,3)];
    end
    d = DT*sum(sqrt(sum(z.^2,1)));
    je = (1/DT^2)*diff(diff(z,1,2));
    Cj = (L-3)^2*DT^2/d;
    J = Cj*DT*sum(sqrt(sum(je.^2,1)));
    if isnan(J), J=0; end;
end