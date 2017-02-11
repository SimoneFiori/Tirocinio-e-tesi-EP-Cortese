%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%carico figura 3D
load david0; 
solid = [surface.X(1:100:end)'; surface.Y(1:100:end)'; surface.Z(1:100:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%variabili
LstTime = 5;
R = [ ];
campionamento = 4;
update = 59;
updateJ = 14;
ausJerk = [];
DT = 0.01; % Questo ? l'intervallo di campionamento del sensore (100ms = 0.1s)
RSup = [];
OmegaSup = [];
zSup = [];
n=0;
ngraf=0;
c=0;
matgraf=[];
time=[];
grandezza=0;
oldtime=0;

risp = menu('Desideri avviare la trasmissione dei dati o caricare un file precedentemente salvato?','Avvia trasmissione','Carica file');
m=mobiledev;

if risp == 1,
    rispdev = menu('Stai usando un dispositivo Android o Apple? Ricorda che per stoppare il programma bisogna chiudere la app sul dispositivo mobile','Android','Apple');
    if rispdev ==1,
      m.SampleRate='high';
    else 
      m.SampleRate='medium';
      DT=0.1;
    end 
       m.OrientationSensor=1; 
       m.logging=1;
        while 1  
            while n==0                c=c+1;
                [datiorient,t]=orientlog(m);
                n=grandezza-size(datiorient,1);
            if c>25000 break; end;
            pause(0.001);
            end 
            if c>25000 break; end;
            n=0;
            c=0;
            grandezza=size(datiorient,1);         
            DT=t(size(t,1))-oldtime;
            oldtime=t(size(t,1));
            time=[time,DT];
            %discardlogs(m);
            datiorient=datiorient*pi/180;
            datiorient=datiorient';
            matgraf=[matgraf,datiorient(:,size(t,1))];
            ngraf=size(matgraf,2); 
                %ottengo la matrice di rotazione
             if ngraf<4 %mi servono 4 campioni per avere 3'z' e quindi 1'jnn'
                RSup(:,:,ngraf) = rotz(matgraf(1,ngraf))*roty(matgraf(2,ngraf))*rotx(matgraf(3,ngraf));
                if ngraf>1
                    OmegaSup(:,:,ngraf-1) = (1/DT)*real(logm(RSup(:,:,ngraf-1)'*RSup(:,:,ngraf)));
                    zSup(:,ngraf-1) = [OmegaSup(1,2,ngraf-1),OmegaSup(1,3,ngraf-1),OmegaSup(2,3,ngraf-1)];
                end
            else 
                R = rotz(matgraf(1,ngraf))*roty(matgraf(2,ngraf))*rotx(matgraf(3,ngraf)); %R(ngraf)
                Omega = (1/DT)*real(logm(RSup(:,:,3)'*R)); %Omega(ngraf)
                %Omega ? una matrice 3x3
                z = [Omega(1,2),Omega(1,3),Omega(2,3)]; %z(ngraf)
                z = z';
                %z ? un vettore 3x1
                jnn = (1/DT^2)*(z - 2*zSup(:,2) + zSup(:,1)); %jnn n
                %jnn ? un vettore 3x1
                jist = norm(jnn);
                %jist ? 1x1
                ausJerk = [ausJerk,jist];
                %salvo i valori per il ciclo successivo
                RSup(:,:,1) = RSup(:,:,2);
                RSup(:,:,2) = RSup(:,:,3);
                RSup(:,:,3) = R;
                OmegaSup(:,:,1) = OmegaSup(:,:,2);
                OmegaSup(:,:,2) = Omega;
                zSup(:,1) = zSup(:,2);
                zSup(:,2) = z;
            end %end if         
                %GRAFICO DEGLI ANGOLI
            hold on;
            %asse X
            ax1 = subplot(5,5,[1 2]); 
            %plot(ngraf*DT,matgraf(1,:),'r');
            plot(180*matgraf(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[-10,370]);
            if ngraf<=update
                xlim(ax1,[1,update]);
            else
                xlim(ax1,[ngraf-update,ngraf]);
            end %end if
            %asse Y
            ax2 = subplot(5,5,[6 7]);
            %plot(ngraf*DT,matgraf(2,:),'g');
            plot(180*matgraf(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-190,190]);
            if ngraf<=update
                xlim(ax2,[1,update]);
            else
                xlim(ax2,[ngraf-update,ngraf]);
            end %end if
            %asse Z
            ax3 = subplot(5,5,[11 12]);
            %plot(ngraf*DT,matgraf(3,:),'b');
            plot(180*matgraf(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-100,100]);
            if ngraf<=update
                xlim(ax3,[1,update]);
            else
                xlim(ax3,[ngraf-update,ngraf]);
            end %end if
            
            %DT
            ax6 = subplot(5,5,[21,25]);
            %DT
            plot(time,'b'); grid on; xlabel('Istanti'); ylabel('DT');
            ylim(ax6,[0,1]);
            if ngraf<=update
                xlim(ax6,[1,update]);
            else
                xlim(ax6,[ngraf-update,ngraf]);
            end %end if

            %GRAFICO DEL JERK
            ax4 = subplot(5,5,[16,20]);
            %semilogy(ngraf*DT,ausJerk,'b');
            semilogy(ausJerk,'b'); grid on;  ylabel('Jerk[log scale]');
            ylim (ax4,[10^(-5),10^5])
            if ngraf<=update
                xlim(ax4,[1,update])
            else
                xlim(ax4,[ngraf-update,ngraf])
            end %end if
           
            %ANIMAZIONE
            yaw = datiorient(1,(size(t,1)))*180/pi; %rotazione lungo x
            pitch = datiorient(2,(size(t,1)))*180/pi; %rotazione lungo y
            roll = datiorient(3,(size(t,1)))*180/pi; %rotazione lungo z
            %creo la matrice di rotazione
            mRoll=rotx(roll);      %z
            mPitch=roty(pitch);     %  y
            mYaw=rotz(yaw);        % x
            M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
            %creo l'animazione
            rot_solid = M*solid;
            ax5 = subplot(5,5,[3 4 5 8 9 10 13 14 15]);
            hold off;
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            
        end
       risp2 = menu('Vuoi salvare questa sessione?','Si','No');
    if risp2 == 1
        prompt = 'Con che nome vuoi salvare il file di acquisizione?       ';
        fName = input (prompt, 's');
        save(fName,'matgraf');
        save(strcat(fName,'time'),'time');%salvo i dati
        close all;
        
    end;
    else if risp == 2 %CARICA SESSIONE
        prompt = 'Quale file di acquisizione vuoi caricare?    ';
        fName = input (prompt, 's');
        time=load(strcat(fName,'time'));
        time=struct2cell(time);
        time=time{1,1};
        matgrafl=load(fName);
        matgrafl=struct2cell(matgrafl);
        matgrafl=matgrafl{1,1};
        matgrafl=matgrafl*180/pi;
        n=1;
        while n<size(matgrafl,2)
            datiorient=matgrafl(:,n);
            
            DT=time(n);
            datiorient=datiorient*pi/180;
            matgraf=[matgraf,datiorient];
            ngraf=size(matgraf,2); 
                %ottengo la matrice di rotazione
             if ngraf<4 %mi servono 4 campioni per avere 3'z' e quindi 1'jnn'
                RSup(:,:,ngraf) = rotz(matgraf(1,ngraf))*roty(matgraf(2,ngraf))*rotx(matgraf(3,ngraf));
                if ngraf>1
                    OmegaSup(:,:,ngraf-1) = (1/DT)*real(logm(RSup(:,:,ngraf-1)'*RSup(:,:,ngraf)));
                    zSup(:,ngraf-1) = [OmegaSup(1,2,ngraf-1),OmegaSup(1,3,ngraf-1),OmegaSup(2,3,ngraf-1)];
                end
            else 
                R = rotz(matgraf(1,ngraf))*roty(matgraf(2,ngraf))*rotx(matgraf(3,ngraf)); %R(ngraf)
                Omega = (1/DT)*real(logm(RSup(:,:,3)'*R)); %Omega(ngraf)
                %Omega ? una matrice 3x3
                z = [Omega(1,2),Omega(1,3),Omega(2,3)]; %z(ngraf)
                z = z';
                %z ? un vettore 3x1
                jnn = (1/DT^2)*(z - 2*zSup(:,2) + zSup(:,1)); %jnn n
                %jnn ? un vettore 3x1
                jist = norm(jnn);
                %jist ? 1x1
                ausJerk = [ausJerk,jist];
                %salvo i valori per il ciclo successivo
                RSup(:,:,1) = RSup(:,:,2);
                RSup(:,:,2) = RSup(:,:,3);
                RSup(:,:,3) = R;
                OmegaSup(:,:,1) = OmegaSup(:,:,2);
                OmegaSup(:,:,2) = Omega;
                zSup(:,1) = zSup(:,2);
                zSup(:,2) = z;
            end %end if         
                %GRAFICO DEGLI ANGOLI
            hold on;
            %asse X
            ax1 = subplot(5,5,[1 2]); 
            %plot(ngraf*DT,matgraf(1,:),'r');
            plot(180*matgraf(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[-10,370]);
            if ngraf<=update
                xlim(ax1,[1,update]);
            else
                xlim(ax1,[ngraf-update,ngraf]);
            end %end if
            %asse Y
            ax2 = subplot(5,5,[6 7]);
            %plot(ngraf*DT,matgraf(2,:),'g');
            plot(180*matgraf(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-190,190]);
            if ngraf<=update
                xlim(ax2,[1,update]);
            else
                xlim(ax2,[ngraf-update,ngraf]);
            end %end if
            %asse Z
            ax3 = subplot(5,5,[11 12]);
            %plot(ngraf*DT,matgraf(3,:),'b');
            plot(180*matgraf(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-100,100]);
            if ngraf<=update
                xlim(ax3,[1,update]);
            else
                xlim(ax3,[ngraf-update,ngraf]);
            end %end if
            
            %DT
            ax6 = subplot(5,5,[21,25]);
            %DT
            plot(time,'b'); grid on; xlabel('Istanti'); ylabel('DT');
            ylim(ax6,[0,1]);
            if ngraf<=update
                xlim(ax6,[1,update]);
            else
                xlim(ax6,[ngraf-update,ngraf]);
            end %end if

            %GRAFICO DEL JERK
            ax4 = subplot(5,5,[16,20]);
            %semilogy(ngraf*DT,ausJerk,'b');
            semilogy(ausJerk,'b'); grid on;  ylabel('Jerk[log scale]');
            ylim (ax4,[10^(-5),10^5])
            if ngraf<=update
                xlim(ax4,[1,update])
            else
                xlim(ax4,[ngraf-update,ngraf])
            end %end if
           
            %ANIMAZIONE
            yaw = datiorient(1)*180/pi; %rotazione lungo x
            pitch = datiorient(2)*180/pi; %rotazione lungo y
            roll = datiorient(3)*180/pi; %rotazione lungo z
            %creo la matrice di rotazione
            mRoll=rotx(roll);      %z
            mPitch=roty(pitch);     %  y
            mYaw=rotz(yaw);        % x
            M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
            %creo l'animazione
            rot_solid = M*solid;
            ax5 = subplot(5,5,[3 4 5 8 9 10 13 14 15]);
            hold off;
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            n=n+1;
            pause(0.01);
            end
        end
end %end if (menu)

risp3 = menu('Premi per terminare','ESCI');
if risp3 == 1
    close all
end
clearvars
clc