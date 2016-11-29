%il programma esce da solo dopo un paio di secondi che non riceve più dati

%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;

%Creo nuovo oggetto UDP
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
UDPComIn=udp('0.0.0.0','LocalPort',1710); 
set(UDPComIn,'DatagramTerminateMode','off', 'InputBufferSize', 40) 
%Imposto la dimensione del buffer, ovvero il numero di caratteri massimo
%per ogni stringa.
%il computer legge la stringa solo dopo che si hanno 40 caratteri
%impostando il buffer a 40, si ha che ogni stringa contiene un angolo,
%più un pezzettino dell'angolo successivo, che viene scartato nella
%conversione da stringa a vettore.

cond=true;
    while 1
    fopen(UDPComIn); 
    %apro la connessione
    csvdata=fscanf(UDPComIn); 
    %ricevo i dati
    fclose(UDPComIn);
    scandata=textscan(csvdata,'%s', 'Delimiter',', ,#'); 
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %' ' significa che i dati sono divisi da uno spazio
    scan=scandata{1,1}; 
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan)); 
    %elimino le righe vuote;  
    apparray=zeros(3,1); 
    %creo un vettore per ospitare i dati
    for p=1:3
        a=4; 
        %memorizzo 4 nella variabile a per assegnarle il valore DOUBLE. 
        %Senza questa istrzione, a sarebbe CELL
        a=scan{p}; 
        %memorizzo dentro a il valore contenuto in scan
        a=str2num(a); 
        %converto a in un double
        apparray(p)=a; 
        %memorizzo a nell'array
    end
    dati=vec2mat(apparray,3); 
    %creo una matrice partendo dall'array. 
    %ogni riga della matrice è composta da 3 righe dell'array
    dati=dati';
    roll= dati(1,:);
    pitch = dati(2,:);
    yaw = dati(3,:);
    %creo la matrice di rotazione
    mRoll=rotx(roll);      %x
    mPitch=roty(pitch);     %  y
    mYaw=rotz(yaw);        % z
    M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
    end