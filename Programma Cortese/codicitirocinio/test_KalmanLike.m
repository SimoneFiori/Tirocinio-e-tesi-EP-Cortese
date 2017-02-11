%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')
load david0; 
solid = [surface.X(1:100:end)'; surface.Y(1:100:end)'; surface.Z(1:100:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%dichiarazione variabili
c=0;
LstTime = 5;
aparray = [];
DimPacch = 34;
DimTimeStamp = 13;
timestampPrec = 0;

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000); 
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime, 'InputBufferSize', DimTimeStamp+2*DimPacch);
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
ms = 0;
c = 0;
dim = 0;
aparray = [];
figure;
nternePrec = 0;
time = 0.02;
olog = [];
deg = [];
K = 0;
psi_gyr = [];

while 1
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    
    %ricevo i dati
    if isempty(csvdata)==1  break; end; 
    %periodo di campionameno effettivo in ms
    %il fatto che ms sia prossimo (per segnale stabile) al periodo di
    %campionamento indicato significa che la perdità di campioni è minima
    scandata=textscan(csvdata,'%s','Delimiter',',#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %i delimiter possibili sono virgola e cancelletto
    scan=scandata{1,1};
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan));
    %elimino le righe vuote;
    
    %verifico che ci sia una terna in arrivo
    %se sì, elaboro la terna e ripeto
    %se no, mi fermo
    dim = size(scan,1);
    for i=1:dim
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            DT = (timestamp - timestampPrec)/1000;
            if (DT>=1)
                DT = 0.02;
            end
            timestampPrec = timestamp;
        else
            g = 4;
            g = scan{i,1};
            g = str2num(g);
            if (isempty(g))
                g = 0;
            end
%             if (i>4)
%                 g = g*(180/pi);
%             end
        %può capitare che un dato sia mancante, con questo controllo non
        %avvengono blocchi dell'applicazione
        
        aparray(i+c-1) = g; %se voglio immagazzinare e lavorare su tutto
        %aparray(i) = g; %se voglio lavorare un campione alla volta
        end
    end
    c = size(aparray,2);
    resto = mod(c,6);
    c = (c-resto);
    n = c/6;
    aparray = aparray(1:c);
    acclog(:,n) = aparray(c-5:c-3);
    gyrlog(:,n) = aparray(c-2:c);

     for i=1:n
     %ciclo per il campione n
         psi_acc(1,n) = (atan(acclog(1,i)/sqrt(acclog(2,i)^2 + acclog(3,i)^2)))*(180/pi); %pitch da acc
         psi_acc(2,n) = (atan(acclog(2,i)/sqrt(acclog(1,i)^2 + acclog(3,i)^2)))*(180/pi); %roll da acc
         psi_acc(3,n) = (atan(sqrt(acclog(2,i)^2 + acclog(1,i)^2)/acclog(3,i)))*(180/pi); %yaw da acc
         for x=1:3
         %ciclo per l'angolo x y z
             if (i<2)
                 %inizializzo da acc
                 psi_gyr(x,n) = psi_acc(x,n);
                 psi(x,n) = psi_acc(x,n);
             else
                %previsione modello
                psi_gyr(x,n) = psi_gyr(x,n-1) + gyrlog(x,n)*DT;
                %calcolo del guadagno come funzione dello scarto tra
                %previsione e misura
                DELTAgyr = gyrlog(x,n)*DT;
                DELTAacc = acclog(x,n) - acclog(x,n-1);
                DELTA = abs(DELTAgyr - DELTAacc);
                if (DELTA <= 5)
                     K = 0.95;
                 end
                 if (DELTA >= 15)
                     K = 0.99;
                 end
                 if (DELTA > 5 || DELTA < 15)
                     K = ((0.99-0.95)/(15-5))*DELTA + 0.95;
                 end
                 %aggiorno la stima con guadagno calcolato
                 psi_acc(x,n) + K*(psi_gyr(x,n) - psi_acc(x,n));
                 psi(x,n) = psi_acc(x,n) + K*(psi_gyr(x,n) - psi_acc(x,n));
             end %end if
         end %end for xyz
     end %end for campione
     
     hold on;
     %asse X
     ax1 = subplot(3,2,[1 2]); 
     plot(psi_acc(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('deg X');
     %ylim(ax1,[-5,5]);
 
     %asse Y
     ax2 = subplot(3,2,[3 4]);
     plot(psi_acc(2,:),'g'); grid on; xlabel('Istanti'); ylabel('deg Y');
     %ylim(ax2,[-5,5]);
 
     %asse Z
     ax3 = subplot(3,2,[5 6]);
     plot(psi_acc(3,:),'k'); grid on; xlabel('Istanti'); ylabel('deg Z');
     %ylim(ax3,[5,15]);

     pause(0.001);

%     yaw = psi(1,n); %rotazione lungo x
%     pitch = psi(2,n); %rotazione lungo y
%     roll = psi(3, n); %rotazione lungo z
%     %creo la matrice di rotazione
%     mRoll=rotx(roll) ;     
%     mPitch=roty(pitch);     
%     mYaw=rotz(yaw);        
%     M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
%     %creo l'animazione
%     rot_solid = M*solid;
%     %ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
%     hold off;
%     plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
%     xlim([-100 100]);ylim([-100 100]);zlim([-200 200])
%     pause(0.001)
end