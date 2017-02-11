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
%0.0.0.0 = qualunque ip che invia dati, 4000 � la porta in cui i dati
%vengono trasmessi. � possibile deciderne una arbitrariamente
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
    %campionamento indicato significa che la perdit� di campioni � minima
    scandata=textscan(csvdata,'%s','Delimiter',',#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %i delimiter possibili sono virgola e cancelletto
    scan=scandata{1,1};
    %inserisco il risultato di scandata in una variabile. NB: scan � di tipo CELL
    scan=scan(~cellfun('isempty',scan));
    %elimino le righe vuote;
    
    %verifico che ci sia una terna in arrivo
    %se s�, elaboro la terna e ripeto
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
    acclog(:,n) = aparray';
end

%manipolazione polinomiale per ottenere posizione
DT1 = 0:DT(n)/(n-1):DT(n);
for i=1:3
    accpoly = polyfit(DT1,acclog(i,:),8);
    accsym = poly2sym(accpoly); 
    vsym = int(accsym); 
    vpoly = sym2poly(vsym); 
    vlog(i,:) = polyval(vpoly,DT1); 
    possym = int(vsym);
    pospoly = sym2poly(possym);
    poslog(i,:) = polyval(pospoly,DT1);
    clear accpoly accsym vsym vpoly possym pospoly
end

subplot(311)
plot(poslog(1,:))
subplot(312)
plot(poslog(2,:))
subplot(313)
plot(poslog(3,:))