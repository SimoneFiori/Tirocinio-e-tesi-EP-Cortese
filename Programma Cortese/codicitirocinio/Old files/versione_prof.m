%versione di prova limitata al caricamento di una sessione precedente
%digitare, quando richiesto, il nome del file
%per interrompere prima della fine, premere ctrl+c

%Reset ambiente Matlab
close all; clc
uiopen('matlab'); clearvars -except ologses
% Recupera il numero di campioni e gli angoli in gradi
n=size(ologses,2); 
ologses = pi*ologses/180; % Conversione in radianti;
% Riga 1 = yaw, riga 2 = pitch, riga 3 = roll
%%%% Gli algoli 1 (yaw) e 2 (pitch) vanno sistemati per evitare salti %%%%
R = zeros(3,3,n); % Array che contiene la sequenza delle rotazioni
for i=1:n,
 R(:,:,i) = rotz(ologses(1,i))*roty(ologses(2,i))*rotx(ologses(3,i)); 
end 
% Calcolo del jerk istantaneo
DT = 0.01; % Questo è l'intervallo di campionamento del sensore
Omega=zeros(3,3,n-1); z = zeros(3,n-1);
jnn = zeros(3,n-2); jist = zeros(1,n-2); % Questo è il jerk istantaneo non normalizzato (il jerk istantaneo non si può normalizzare)
for k=2:n
 Omega(:,:,k) = (1/DT)*real(logm(R(:,:,k-1)'*R(:,:,k)));
 z(:,k) = [Omega(1,2,k),Omega(1,3,k),Omega(2,3,k)];
 if k>2, jnn(:,k) = (1/DT^2)*(z(:,k) - 2*z(:,k-1) + z(:,k-2)); end
 jist(k) = norm(jnn(k));
end
% Grafico degli angoli in gradi
figure; hold on;
%asse X
ax1 = subplot(4,2,1); 
plot(180*ologses(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
xlim(ax1,[0,n]);
%asse Y
ax2 = subplot(4,2,3); 
plot(180*ologses(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
xlim(ax2,[0,n]);
%asse Z
ax3 = subplot(4,2,5); 
plot(180*ologses(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
xlim(ax3,[0,n]);
%Jerk
ax4 = subplot(4,2,7); 
grid on; semilogy(jist,'b'); xlabel('Istanti'); ylabel('Jerk [log scale]');
xlim(ax4,[0,n]);
drawnow;
%Animazione 3D
% Carica solido 3D e prepara la grafica
load david0; 
solid = [surface.X(1:25:end)'; surface.Y(1:25:end)'; surface.Z(1:25:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));
for i=1:n,
 rot_solid = R(:,:,i)*solid;
 ax5 = subplot(4,2,[2 4 6 8]);
 plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
 xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
 pause(0.4) % Dovendo fare meno calcoli, l'animazione senza pause è più veloce
 drawnow;
end 
