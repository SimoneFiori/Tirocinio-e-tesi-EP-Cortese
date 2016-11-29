%il programma esce da solo dopo un paio di secondi che non riceve più dati

%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
load david0; 
solid = [surface.X(1:100:end)'; surface.Y(1:100:end)'; surface.Z(1:100:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%variabili
LstTime = 1;
DimBuffer = 40;
%Imposto la dimensione del buffer, ovvero il numero di caratteri massimo
%per ogni stringa.
% il computer legge la stringa solo dopo che si hanno n caratteri
%impostando il buffer a n, si ha che ogni stringa contiene n/40 angoli,
%più un pezzettino dell'angolo successivo, che viene scartato nella
%conversione da stringa a vettore.
%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',1710); 
set(UDPComIn,'DatagramTerminateMode','off', 'InputBufferSize', DimBuffer, 'TimeOut', LstTime)
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
 
cond=true;
    while 1
    fopen(UDPComIn); 
    %apro la connessione
    csvdata=fscanf(UDPComIn)
    %ricevo i dati
    fclose(UDPComIn);
    scandata=textscan(csvdata,'%s', 'Delimiter',', ,#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %' ' significa che i dati sono divisi da uno spazio
    scan=scandata{1,1}; 
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan)) 
    %elimino le righe vuote; 
    C=size(scan,1);
    C = C - mod (C,3);
    apparray=zeros(C,1); 
    %creo un vettore per ospitare i dati
    for p=1:C
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
    dati=dati'
    D = size(dati,2);
    for d=1:D
        yaw = dati(1,d); %rotazione lungo z
        pitch = dati(2,d); %rotazione lungo y
        roll = dati(3, d); %rotazione lungo x
        %creo la matrice di rotazione
        mRoll=rotx(roll);      %x
        mPitch=roty(pitch);     %  y
        mYaw=rotz(yaw);        % z
        M=mYaw*mPitch*mRoll %matrice di rotazione definitiva
            %creo l'animazione
        rot_solid = M*solid
        plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
        hold off;
        xlim([-100 100]);ylim([-100 100]);zlim([-100 100])
        pause (0.1)
    end %end for
end %end while