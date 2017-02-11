%gyroscopic log per calcolo jerk
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%variabili
LstTime = 5;
update = 59;
Sjerk = [];
ologses = [];
campionamento = 7;
ausJerk = [];
%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',1710); 
set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime)
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=true;
while 1
    fopen(UDPComIn); 
    %apro la connessione
    csvdata=fscanf(UDPComIn);
    if isempty(csvdata)==1  break; end;
    %ricevo i dati
    scandata=textscan(csvdata,'%s', 'Delimiter',', ,#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %' ' significa che i dati sono divisi da uno spazio
    scan=scandata{1,1}; 
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan)); 
    %elimino le righe vuote; 
    %creo un vettore per ospitare i dati
    for x=1:3
        g=4; 
        %memorizzo 4 nella variabile a per assegnarle il valore DOUBLE. 
        %Senza questa istrzione, a sarebbe CELL
        g=scan{x}; 
        %memorizzo dentro a il valore contenuto in scan
        g=str2num(g);
        g = g*pi/180; %converto in radianti
        %converto a in un double
        apparray1(x)=g; 
        %memorizzo a nell'array
    end
    olog=vec2mat(apparray1,3); 
    %creo una matrice partendo dall'array. 
    %ogni riga della matrice è composta da 3 righe dell'array
    olog=olog';
    ologses = [ologses,olog] ;  %vettore d'appoggio per il grafico e per il salvataggio della sessione
    n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
    %QUESTA PARTE SI OCCUPA DEL GRAFICO
    %ottengo la matrice di rotazione
    if mod(n,campionamento) == 0
        R = zeros(3,3,n); % Array che contiene la sequenza delle rotazioni
        for i=1:n,
            R(:,:,i) = rotz(ologses(1,i))*roty(ologses(2,i))*rotx(ologses(3,i));
        end
        R1 = R(:,:,n-campionamento+1:n);
        ausJerk = [ausJerk,jerk(R1)];
    end;
    %faccio il grafico 
    semilogy(ausJerk,'b') 
    grid on; 
    xlabel('Istanti'); 
    ylabel('Jerk [log scale]');
    m = size(ausJerk,2); %effetto scorrimento
    if m<=update
        xlim([1,update]);
    else
        xlim([m-update,m]);
    end %end if
    ylim ([10^(-6),10^6]);
    drawnow;
    fclose(UDPComIn);
end;
clearvars;