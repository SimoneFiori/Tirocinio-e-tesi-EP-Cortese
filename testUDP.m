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
%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000); 
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime );
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
ms = 0;
c = 0;
dim = 0;
aparray = [];
figure;
nternePrec = 0;

while 1
    fopen(UDPComIn)
    tic;
    csvdata = fscanf(UDPComIn);
    time = toc;
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
        g = 4;
        g = scan{i,1};
        g = str2num(g);
        if (isempty(g))
            g = 0;
        end
        %può capitare che un dato sia mancante, con questo controllo non
        %avvengono blocchi dell'applicazione
        aparray(i+c) = g;
    end
    c = size(aparray,2);
    resto = mod(c,3);
    c = (c-resto);
    aparray = aparray(1:c);
    alog = vec2mat (aparray,3);
    alog = alog';
    
    %verifico il periodo di campionamento
    ms = 1000*time/((c/3)-nternePrec);
    nternePrec = c/3;
   
    
    hold on;
    %asse X
    ax1 = subplot(3,2,[1 2]); 
    plot(alog(1,:),'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('acc X');
    ylim(ax1,[-5,5]);

    %asse Y
    ax2 = subplot(3,2,[3 4]);
    plot(alog(2,:),'g'); grid on; xlabel('Istanti'); ylabel('acc Y');
    ylim(ax2,[-5,5]);

    %asse Z
    ax3 = subplot(3,2,[5 6]);
    plot(alog(3,:),'b'); grid on; xlabel('Istanti'); ylabel('acc Z');
    ylim(ax3,[5,15]);

    pause(ms/1000);
end