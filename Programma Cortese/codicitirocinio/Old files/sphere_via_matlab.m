%operazioni preliminari
%digitare nella barra di comando: connector on 'password'
%connettere il telefono al computer con la password usata
%abilitare nell'app il sensore orientazione

%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;

%creo la figura 3D
fx=[0 2 2 2.2 2 2 0; 
0 0 -0.1 0 0.1 0 0;
0 0 0 0 0 0 0];
[X,Y,Z] = sphere(30);
fy(1,:)=X(:); fy(2,:)=Y(:); fy(3,:)=Z(:);
fz=[0 0 0.1 0 -0.1 0 0;0 0 0 0 0 0 0 ; 0 2 2 2.2 2 2 0];
fx1=fx;
fy1=fy;
fz1=fz;

%creo l'oggetto m a cui si riferisce il telefono ed abilito la ricezione
%dei dati dai sensori
m = mobiledev
m.Logging = 1;
m.OrientationSensorEnabled = 1;

%impostando il ciclo while in questo modo, è necessario fermare la
%ricezione dal telefono (stop sending) o mediante il comando ctrl/cmd + c
while m.Logging == 1
    pause(0.1)	
    try
        %raccolgo i dati
        [o, to] = orientlog(m);
        yaw = o(end,1); %rotazione lungo z
        pitch = o(end,2); %rotazione lungo y
        roll = o(end, 3); %rotazione lungo x
        %traslo i valori affinchè corrispondano alla realtà
        yaw = -yaw-180;
        roll = -roll-180;
        pitch = -pitch-180;
        
        %creo la matrice di rotazione
        mRoll=rotx(roll);      %x
        mPitch=roty(pitch);     %  y
        mYaw=rotz(yaw);        % z
        M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva

        %creo l'animazione
        fx1=M*fx;
        fy1=M*fy;
        fz1=M*fz;
            %vettore asse x
    	plot3(fx1(1,:),fx1(2,:),fx1(3,:),'k');
        hold on;
            %vettore asse y
     	plot3(fy1(1,:),fy1(2,:),fy1(3,:),'r');
        hold on;
            %vettore asse z
     	plot3(fz1(1,:),fz1(2,:),fz1(3,:),'b');
        hold off;
    catch
    end
end;
clear m;