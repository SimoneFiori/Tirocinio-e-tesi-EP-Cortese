%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')
addpath('quaternion_library');      % include quaternion library

%dichiarazione variabili
c=0;
LstTime = 5;
timestampPrec = 0;
dim = 0;
time = 0.02;
n = 0;
aparray = [];
Gyroscope = [];
Accelerometer = [];
Magnetometer = [];
nternePrec = 0;
quaternion = zeros(1,4);
R = [];

%dichiarazione oggetti
AHRS = MadgwickAHRS('SamplePeriod', 0.025, 'Beta', 0.1);
load david0; 
solid = [surface.X(1:100:end)'; surface.Y(1:100:end)'; surface.Z(1:100:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000);
set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime);
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
    dim = size(scan,1);
    %imposto 10: timestamp + tre terne, acc mag e gyr
    for i=1:dim
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            DT(1,n) = (timestamp - timestampPrec)/1000;
            if (DT>=1)
                DT(1,n) = 0.1;
            end
            timestampPrec = timestamp;
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
    Accelerometer(n,:) = aparray(1:3);
    Magnetometer(n,:) = aparray(4:6);
    Gyroscope(n,:) = aparray(7:9);
    
    % CI VUOLE IL FILTRO!!!!
    
%     AHRS.SamplePeriod = DT(n);
%     AHRS.Update(Gyroscope(n,:), Accelerometer(n,:), Magnetometer(n,:));	% gyroscope units must be radians
%     quaternion(n, :) = AHRS.Quaternion;
%     R(:,:,n) = quatern2rotMat(quaternion(n,:));
%     rot_solid = R(:,:,n)*solid;
%     plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
%     hold off;
%     xlim([-100 100]);ylim([-100 100]);zlim([-120 100])
%     pause (0.001)
end 