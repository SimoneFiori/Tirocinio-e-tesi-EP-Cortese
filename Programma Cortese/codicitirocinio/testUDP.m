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
cond=true;
ms = 0;
c = 0;
dim = 0;
aparray = [];
DimPacch = 32;
DimTimeStamp = 13;
nternePrec = 0;
timestampPrec = 0;
timestamp = 4;


%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000); 
set(UDPComIn,'DatagramTerminateMode','off', 'TimeOut', LstTime, 'InputBufferSize', DimPacch+DimTimeStamp);

%0.0.0.0 = qualunque ip che invia dati, 400 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
%ogni terna contiene 32byte, il timestamp 13


figure;

while 1
    
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    
    
    %ricevo i dati
    if isempty(csvdata)==1  break; end; 
    scandata=textscan(csvdata,'%s','Delimiter',',#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %i delimiter possibili sono virgola e cancelletto
    scan=scandata{1,1};
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan));
    %elimino le righe vuote;
    
    for i=1:4
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            dt = (timestamp - timestampPrec)/1000;
            if (dt>=1)
                dt = 0.02;
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
        aparray(i+c-1) = g;
        end
    
    end
    c = size(aparray,2);
    resto = mod(c,3);
    c = (c-resto);
    aparray = aparray(1:c);
    alog = vec2mat (aparray,3);
    alog = alog'; 
    
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

    pause(0.02);
    %aggiorno il grafico
    
end