%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%dichiarazione variabili
LstTime = 5;
DimPacch = 30;
DimTimeStamp = 15;
timestampPrec = 0;
n = 0;
vlog = [];

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000);
%fase di calibrazione:
%calcolo il primo DT e il bias dell'acc
set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime);
%0.0.0.0 = qualunque ip che invia dati, 4000 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
while n<20
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
bias = mean(acclog,2);

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
    acclog = vec2mat(aparray,3);
    acclog = acclog';
    
    %integro mediante medoto dei trapezi, utilizzando poi il bias
    %calcolo la velocità da acclog
    if n>1
        for i=1:3    
        %ciclo per xyz
            aus = (acclog(i,n) + acclog(i,n-1))/2;
            if aus>=0
                segno = 2;
            else
                segno = 1;
            end
            aus = sqrt(abs(aus^2 - bias(i)^2));
            aus = aus*(-1)^segno;
            aus = aus*DTzero;
            
            if n==2
                vlog(i,1) = 0;
            end
            vlog(i,n) = vlog(i,n-1) +aus;
            if (abs(vlog(i,n))>1)
                cond = false;
            end
        end
    end
    
    %calcolo la posizione da vlog
    tot = 50;
    if n> tot
        bias1 = mean(vlog,2);
        for i=1:3
            aus = (vlog(i,n) + vlog(i,n-1))/2;
            if aus>=0
                segno = 2;
            else
                segno = 1;
            end
            aus = sqrt(abs(aus^2 - bias1(i)^2));
            aus = aus*(-1)^segno;
            aus = aus*DTzero;
            if n == tot+1
                poslog(i,1) = 0;
            end
            poslog(i,n-tot+1) = poslog(i,n-tot) + aus;
        end
    end
       
end

%asse X
ax1 = subplot(311); 
plot(poslog(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('acc x');
ylim(ax1,[-1,1]);

%asse Y
ax2 = subplot(312);
plot(poslog(2,:),'g'); grid on; xlabel('Istanti'); grid on; ylabel('acc y');
ylim(ax2,[-1,1]);

%asse Z
ax3 = subplot(313);
plot(poslog(3,:),'k'); grid on; xlabel('Istanti'); grid on; ylabel('acc z');
ylim(ax3,[-1,1]);