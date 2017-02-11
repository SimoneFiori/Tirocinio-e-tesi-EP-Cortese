%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

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
acclog = [];
vlog = [];
vlograw = [];
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
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime, 'InputBufferSize', 51);
%0.0.0.0 = qualunque ip che invia dati, 4000 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
while n<500
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
%             DT(1,n) = (timestamp - timestampPrec)/1000;
%             if (DT>=1)
%                 DT(1,n) = 0.02;
%             end
%             timestampPrec = timestamp;
            if (n==1)
                timestampZERO = timestamp;
                DT(1,n) = 0;
            else
                DT(1,n) = (timestamp - timestampZERO)/1000;
            end
        else
            g = 4;
            g = scan{i,1};
            g = str2num(g);
            if (isempty(g))
                g = 0;
            end
            %c = (n-1)*(dim-1) + i-1
            c = i-1;
            aparray(1,c) = g;
        end
    end
    acclograw(:,n) = aparray';
    for i=1:3
        if n>2
            acclog(i,n-2) = (acclograw(i,n)+acclograw(i,n-1)+acclograw(i,n-2))/3;
            if abs(acclog(i,n-2)) <= 0.125 %meanACC(i)
                acclog(i,n-2) = 0;
            else
                acclog(i,n-2) = acclog(i,n-2);% - offsetACC(i);
            end
        end
        n1 = size(acclog,2);
        if n1==1
            vlograw(i,n1) = acclog(i,n1)*0.02;
        end
        if n1==2
            vlograw(i,n1) = vlograw(i,n1-1) + acclog(i,n1)*0.02;
        end
        if n1>2
            vlograw(i,n1) = vlograw(i,n1-1) + acclog(i,n1)*0.02; %DT(n1-2)   
            vlog(i,n1-2) = (vlograw(i,n1)+vlograw(i,n1-1)+vlograw(i,n1-2))/3;
            if abs(vlog(i,n1-2)) <= 0.125 %meanVEL(i)
                vlog(i,n1-2) = 0;
            else
                vlog(i,n1-2) = vlog(i,n1-2); %- offsetVEL(i);
            end
            n2 = size(vlog,2);
            if n2==1
                poslog(i,n2) = vlog(i,n2)*0.02;
            end
            if n2>1
                poslog(i,n2) = poslog(i,n2-1) + vlog(i,n2)*0.02;
            end
            
        end
    end        
end

figure(1)
subplot(311)
plot(acclog(1,:)); title('accelerometro');
subplot(312)
plot(acclog(2,:))
subplot(313)
plot(acclograw(3,:))

figure(2)
subplot(311)
plot(vlog(1,:)); title('velocità');
subplot(312)
plot(vlog(2,:))
subplot(313)
plot(vlog(3,:))

figure(3)
subplot(311)
plot(poslog(1,:)); title('posizione');
subplot(312)
plot(poslog(2,:))
subplot(313)
plot(poslog(3,:))