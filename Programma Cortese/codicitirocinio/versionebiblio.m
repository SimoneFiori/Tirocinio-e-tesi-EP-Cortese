%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')
format long

%dichiarazione variabili
LstTime = 5;
DimPacch = 30;
DimTimeStamp = 15;
timestampPrec = 0;
n = 0;
vlog = [];
calib_acc=0;
calib_vel =0;
calib_pos =0;
vcalib = 0;
DTlog = [];
vlograw_prec = [0;0;0];
poslograw_prec = [0;0;0];

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000);

%fase di calibrazione:
%calcolo il primo DT e il bias dell'accelerometro
set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime);
%0.0.0.0 = qualunque ip che invia dati, 4000 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
while n<100
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    n = n+1;  %numero campione 
    
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
    
    %immagazino i dati
    for i=1:4
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            DT(1,n) = (timestamp - timestampPrec)/1000;
            if (DT>=1)
                DT(1,n) = 0.02;
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
        c = (n-1)*3 + i-1;
        aparray(1,c) = g; %voglio immagazzinare e lavorare su tutto
        end
    end
    acclog = vec2mat(aparray,3);
    acclog = acclog';

end
DT = DT(2:n);
DTzero = mean(DT);
thresold = mean(acclog,2);

n = 0; %azzero il numero di campioni

%avvio la raccolta dati
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime, 'InputBufferSize', DimTimeStamp+DimPacch);
%0.0.0.0 = qualunque ip che invia dati, 4000 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
while cond
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    n = n+1;  %numero campione 
    
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
    for i=1:4
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            DT(1,n) = (timestamp - timestampPrec)/1000;
            if (DT>=1)
                DT(1,n) = DTzero;
            end
            timestampPrec = timestamp;
            %non lo uso, utilizzo quello ottenuto in fase di calibrazione
        else
            g = 4;
            g = scan{i,1};
            g = str2num(g);
            if (isempty(g))
                g = 0;
            end
        %può capitare che un dato sia mancante, con questo controllo non
        %avvengono blocchi dell'applicazione
        c = (n-1)*3 + i-1;
        aparray(1,c) = g; %voglio immagazzinare e lavorare su tutto
        end
    end
    %ottengo i dati grezzi dell'accelerometro
    acclograw = vec2mat(aparray,3);
    acclograw = acclograw';
    
    for i = 1:3
        %filtro passa alto
        if abs(acclograw(i,n)) < abs(thresold(i))
            acclograw(i,n) = 0;
        else
            if thresold(i)>0
                if  acclograw(i,n) > 0
                    acclograw(i,n) = acclograw(i,n)-thresold(i);
                else
                    acclograw(i,n) = acclograw(i,n)+thresold(i);
                end
            else
                if  acclograw(i,n) > 0
                    acclograw(i,n) = acclograw(i,n)+thresold(i);
                else
                    acclograw(i,n) = acclograw(i,n)-thresold(i);
                end
            end
        end
        %media mobile
        window = 5;
        k = n-window+1;
        if k>0
            if (calib_acc==0)
                disp('calibrazione dati di accelerazione ok');
                calib_acc = 1;
            end
            %acclog è sempre più indietro di 4 rispetto a acclograw
            acclog(i,k) = (acclograw(i,k)+acclograw(i,k+1)+...
            acclograw(i,k+2)+acclograw(i,k+3)+acclograw(i,k+4))...
            /window;
            
            
            %integro l'accelerometro filtrato nelle velocità grezze
            vlograw(i,k) = vlograw_prec(i)+acclog(i,k)*DTzero;
            vlograw_prec(i) = vlograw(i,k);
            if k==100 && i == 3
                threshold_vel =  mean(vlograw,2);
                calib_vel = 1;
                disp('calibrazione dati di velocità ok');
            end
            %filtro la velocità: parte1
            if (calib_vel == 1)
                if abs(vlograw(i,k)) < abs(threshold_vel(i))
                    vlograw(i,k) = 0;
                else
                    if threshold_vel(i)>0
                        if  vlograw(i,k) > 0
                            vlograw(i,k) = vlograw(i,k)-threshold_vel(i);
                        else
                            vlograw(i,k) = vlograw(i,k)+threshold_vel(i);
                        end
                    else
                        if  vlograw(i,k) > 0
                            vlograw(i,k) = vlograw(i,k)+threshold_vel(i);
                        else
                            vlograw(i,k) = vlograw(i,k)-threshold_vel(i);
                        end
                    end
                end
                k1 = k-window+1;
                a = k1-100;
                if a>0   
                    %vlog è sempre più indietro di 4 rispetto a vlograw
                    vlog(i,a) = (vlograw(i,k1)+vlograw(i,k1+1)+...
                    vlograw(i,k1+2)+vlograw(i,k1+3)+vlograw(i,k1+4))...
                    /window;
                
                    %integro la velocità filtrata nella posizione grezza
                    poslograw(i,a) = poslograw_prec(i)+vlog(i,a)*DTzero;
                    poslograw_prec(i) = poslograw(i,a);
                    if a==100 && i == 3
                        threshold_pos =  mean(poslograw,2)
                        calib_pos = 1;
                        disp('calibrazione dati di posizione ok');
                    end
                    %filtro la velocità: parte1
                    if (calib_pos == 1)
                        if abs(poslograw(i,a)) < abs(threshold_pos(i))
                            poslograw(i,a) = 0;
                        else
                            if threshold_pos(i)>0
                                if  poslograw(i,a) > 0
                                    poslograw(i,a) = poslograw(i,a)-threshold_pos(i);
                                else
                                    poslograw(i,a) = poslograw(i,a)+threshold_pos(i);
                                end
                            else
                                if  poslograw(i,a) > 0
                                    poslograw(i,a) = poslograw(i,a)+threshold_pos(i);
                                else
                                    poslograw(i,a) = poslograw(i,a)-threshold_pos(i);
                                end
                            end
                        end
                        %filtro la velocità parte2
                        k2 = a-window+1;
                        b = k2-100;
                        if b>0   
                        %poslog è sempre più indietro di 4 rispetto a poslograw
                        poslog(i,b) = (poslograw(i,k2)+poslograw(i,k2+1)+...
                        poslograw(i,k2+2)+poslograw(i,k2+3)+poslograw(i,k2+4))...
                        /window;
                        end
                    end
                end
            end
        end %end condizione if
    end %end ciclo for per ogni terna
    
end %end while

%hold on; 
%asse X
ax1 = subplot(331); 
plot(acclog(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('acc x');
ylim(ax1,[-0.5,0.5]);
%asse Y
ax2 = subplot(332);
plot(acclog(2,:),'g'); grid on; xlabel('Istanti'); grid on; ylabel('acc y');
ylim(ax2,[-0.5,0.5]);
%asse Z
ax3 = subplot(333);
plot(acclog(3,:),'k'); grid on; xlabel('Istanti'); grid on; ylabel('acc z');
ylim(ax3,[-0.5,0.5]);
%pause(0.001);
ax4 = subplot(334); 
plot(vlog(1,:),'r');  grid on; xlabel('Istanti'); ylabel('vel x');
ylim(ax4,[-0.5,0.5]);
%asse Y
ax5 = subplot(335);
plot(vlog(2,:),'g'); grid on; xlabel('Istanti'); grid on; ylabel('vel y');
ylim(ax5,[-0.5,0.5]);
%asse Z
ax6 = subplot(336);
plot(vlog(3,:),'k'); grid on; xlabel('Istanti'); grid on; ylabel('vel z');
ylim(ax6,[-0.5,0.5]);
%pause(0.001);
ax7 = subplot(337); 
plot(poslog(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('pos x');
%ylim(ax7,[-0.5,0.5]);
%asse Y
ax8 = subplot(338);
plot(poslog(2,:),'g'); grid on; xlabel('Istanti'); grid on; ylabel('pos y');
%ylim(ax8,[-0.5,0.5]);
%asse Z
ax9 = subplot(339);
plot(poslog(3,:),'k'); grid on; xlabel('Istanti'); grid on; ylabel('pos z');
%ylim(ax9,[-0.5,0.5]);
%pause(0.001);