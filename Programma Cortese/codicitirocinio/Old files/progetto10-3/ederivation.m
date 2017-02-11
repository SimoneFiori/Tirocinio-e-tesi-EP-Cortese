%ederivation - Civita & Romani
function V = ederivation(Z,L,T)
%ederivation calcola la derivata euclidea di un vettore.
%Richiede come parametri il vettore da derivare (Z), il limite L (numero
%di colonne) e la frequenza di campionamento (T)
V=zeros(3,size(Z,2));
    for k=2:L,
        V(:,k-1)=(Z(:,k) - Z(:,k-1))/T;
        
    end    
end

