%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

load david0; 
solid = [surface.X(1:150:end)'; surface.Y(1:150:end)'; surface.Z(1:150:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));


%dichiarazione variabili
c=0;
LstTime = 5;
aparray = [];
DimPacch = 30;
DimTimeStamp = 15;
timestampPrec = 0;
ms = 0;
c = 0;
dim = 0;
aparray = [];
nternePrec = 0;
time = 0.02;
olog = [];
deg = [];
deg_gyr = zeros(3,1);
gyrlog_prec = zeros(3,1);
psi_gyr = [];
psi = [];
psi_gyr_prec = [0;0];
psi_acc_prec = [0;0];
n = 0;

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000); 
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime, 'InputBufferSize', DimTimeStamp+3*DimPacch);
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente

%figure;
cond=true;
while 1
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    n = n+1; %numero campione
    
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
    %dim = size(scan,1);
    %imposto 10: timestamp + tre terne, acc mag e gyr
    for i=1:10
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
        %può capitare che un dato sia mancante, con questo controllo non
        %avvengono blocchi dell'applicazione
        
        aparray(i-1) = g; %se voglio immagazzinare e lavorare su tutto
        end
    end
    acclog = aparray(1:3)';
    maglog = aparray(4:6)';
    gyrlog = aparray(7:9)';
    
    %calcolo angolo da accelerometro
    psi_acc(1,n) = -atan(acclog(1)/sqrt(acclog(2)^2 + acclog(3)^2)); %pitch da acc
    psi_acc(2,n) = atan(acclog(2)/sqrt(acclog(1)^2 + acclog(3)^2)); %roll da acc
   
    for i=1:2
        %calcolo angolo da giroscopio come integrazione
        DELTAgyr = gyrlog(i)*DT;
        psi_gyr(i,n) = psi_gyr_prec(i) + DELTAgyr;
        %mappo nell'intervallo
        psi_gyr_hat(i,n) = map(psi_gyr(i,n));
        DELTAacc = psi_acc(i,n)-psi_acc_prec(i);
        DELTA = abs(DELTAgyr-DELTAacc);
        if (DELTA <= 5)
            K = 0.95;
        elseif (DELTA >= 15)
            K = 0.99;
        elseif (DELTA > 5 || DELTA < 15)
            K = ((0.99-0.95)/(15-5))*DELTA + 0.95;
            if K>1
                K=1;
            end
        end
        psi(i,n) = psi_acc(i,n) + K*(psi_gyr_hat(i,n) - psi_acc(i,n));
        psi_gyr_prec(i) = psi_gyr(i,n);
        psi_acc_prec(i) = psi_acc(i,n);
    end
    pitch =  psi_acc(1,n);
    roll = psi_acc(2,n);
    XH = maglog(1)*cos(abs(pitch)) + maglog(2)*sin(abs(roll))*sin(abs(pitch))... 
        + maglog(3)*sin(abs(roll))*cos(abs(pitch));
    YH = maglog(2)*cos(abs(pitch)) + maglog(3)*sin(abs(roll));
    psi(3,n) = atan2(-YH,XH) + pi;
    
    yaw = psi(3,n); %rotazione lungo x
    pitch = 2*psi(1,n); %rotazione lungo y
    roll = psi(2,n); %rotazione lungo z
    %creo la matrice di rotazione
    mRoll=rotx(roll);     
    mPitch=roty(pitch);     
    mYaw=rotz(yaw);        
    M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
    %creo l'animazione
    rot_solid = M*solid;
    %ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
    hold off;
    plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
    xlim([-100 100]);ylim([-100 100]);zlim([-200 200])
    pause(0.0000001)
    
    
% %     hold on; 
%     %asse X
%     ax1 = subplot(311); 
%     plot(poslog(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('pitch');
%     ylim(ax1,[-1,1]);
% 
%     %asse Y
%     ax2 = subplot(312);
%     plot(poslog(2,:),'g'); grid on; xlabel('Istanti'); grid on; ylabel('roll');
%     ylim(ax2,[-1,1]);
% 
%        %asse Z
%        ax3 = subplot(313);
%        plot(poslog(3,:),'k'); grid on; xlabel('Istanti'); grid on; ylabel('yaw');
%        ylim(ax3,[-1,1]);
% % 
% %     pause(0.001);
    
    
    
end