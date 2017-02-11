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
    olog = vec2mat (aparray,3);
    olog = olog';
    n = c/3; %numero campioni trasmessi
    
    
            
    yaw = pi*olog(1,n)/180; %rotazione lungo x
    pitch = pi*olog(2,n)/180; %rotazione lungo y
    roll = pi*olog(3, n)/180; %rotazione lungo z
    %creo la matrice di rotazione
    mRoll=rotx(roll) ;     
    mPitch=roty(pitch);     
    mYaw=rotz(yaw);        
    M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
    %creo l'animazione
    rot_solid = M*solid;
    %ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
    hold off;
    plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
    xlim([-100 100]);ylim([-100 100]);zlim([-200 200])
    pause(0.0001)
    
end