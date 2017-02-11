%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%carico figura 3D
load david0; 
solid = [surface.X(1:150:end)'; surface.Y(1:150:end)'; surface.Z(1:150:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%variabili
LstTime = 5;
R = [ ];
campionamento = 4;
update = 59;
updateJ = 14;
ausJerk = [];
DT = 0.1; % Questo è l'intervallo di campionamento del sensore (100ms = 0.1s)
RSup = [];
OmegaSup = [];
zSup = [];

%menù
risp = menu('Cosa desideri fare?','Crea una nuova sessione','Carica sessione precedente');
if risp == 1, 
    %NUOVA SESSIONE (online)
    risp1 = menu('Premi OK quando sei pronto','OK');
    if risp1 == 1,
        figure
        ologses = [ ]; %vettore in cui vengono salvate tutte le terne
        %Creo nuovo oggetto UDP
        UDPComIn=udp('0.0.0.0','LocalPort',4000); 
        set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime );
        %0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
        %vengono trasmessi. È possibile deciderne una arbitrariamente
        cond=true;
        while 1
            fopen(UDPComIn); 
            %apro la connessione
            csvdata=fscanf(UDPComIn);
            fclose(UDPComIn);
            if isempty(csvdata)==1  break; end;
            %ricevo i dati
            scandata=textscan(csvdata,'%s','Delimiter',',#');
            %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
            %i delimiter possibili sono virgola e cancelletto
            scan=scandata{1,1};
            %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
            scan=scan(~cellfun('isempty',scan)); 
            %elimino le righe vuote; 
            %creo un vettore per ospitare i dati
            for x=1:3 %ciclo for per l'olog
                g=4; 
                %memorizzo 4 nella variabile a per assegnarle il valore DOUBLE. 
                %Senza questa istrzione, a sarebbe CELL
                g=scan{x}; 
                %memorizzo dentro a il valore contenuto in scan
                g=str2num(g);
                g=g*pi/180;
                %converto a in un double
                apparray1(x)=g; 
                %memorizzo a nell'array
            end
            olog=vec2mat(apparray1,3);
            %creo una matrice partendo dall'array. 
            %ogni riga della matrice è composta da 3 righe dell'array
            olog=olog';
            ologses = [ologses,olog]; %vettore d'appoggio per il grafico e per il salvataggio della sessione
            n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
            %ottengo la matrice di rotazione
            if n<4 %mi servono 4 campioni per avere 3'z' e quindi 1'jnn'
                RSup(:,:,n) = rotz(ologses(1,n))*roty(ologses(2,n))*rotx(ologses(3,n));
                if n>1
                    OmegaSup(:,:,n-1) = (1/DT)*real(logm(RSup(:,:,n-1)'*RSup(:,:,n)));
                    zSup(:,n-1) = [OmegaSup(1,2,n-1),OmegaSup(1,3,n-1),OmegaSup(2,3,n-1)];
                end
            else 
                R = rotz(ologses(1,n))*roty(ologses(2,n))*rotx(ologses(3,n)); %R(n)
                Omega = (1/DT)*real(logm(RSup(:,:,3)'*R)); %Omega(n)
                %Omega è una matrice 3x3
                z = [Omega(1,2),Omega(1,3),Omega(2,3)]; %z(n)
                z = z';
                %z è un vettore 3x1
                jnn = (1/DT^2)*(z - 2*zSup(:,2) + zSup(:,1)); %jnn n
                %jnn è un vettore 3x1
                jist = norm(jnn);
                %jist è 1x1
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
            ax1 = subplot(4,5,[1 2]); 
            %plot(n*DT,180*ologses(1,:)/pi,'r');
            plot(180*ologses(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[-10,370]);
            if n<=update
                xlim(ax1,[1,update]);
            else
                xlim(ax1,[n-update,n]);
            end %end if
            %asse Y
            ax2 = subplot(4,5,[6 7]);
            %plot(n*DT,180*ologses(2,:)/pi,'g');
            plot(180*ologses(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-190,190]);
            if n<=update
                xlim(ax2,[1,update]);
            else
                xlim(ax2,[n-update,n]);
            end %end if
            %asse Z
            ax3 = subplot(4,5,[11 12]);
            %plot(n*DT,180*ologses(3,:)/pi,'b');
            plot(180*ologses(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-100,100]);
            if n<=update
                xlim(ax3,[1,update]);
            else
                xlim(ax3,[n-update,n]);
            end %end if
            %GRAFICO DEL JERK
            ax4 = subplot(4,5,[16,20]);
            %semilogy(n*DT,ausJerk,'b');
            semilogy(ausJerk,'b'); grid on; xlabel('Istanti'); ylabel('Jerk [log scale]');
            ylim (ax4,[10^(-5),10^5])
            if n<=update
                xlim(ax4,[1,update])
            else
                xlim(ax4,[n-update,n])
            end %end if
            %ANIMAZIONE
            yaw = olog(1,:)*180/pi; %rotazione lungo x
            pitch = olog(2,:)*180/pi; %rotazione lungo y
            roll = olog(3, :)*180/pi; %rotazione lungo z
            %creo la matrice di rotazione
            mRoll=rotx(roll);      %z
            mPitch=roty(pitch);     %  y
            mYaw=rotz(yaw);        % x
            M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
            %creo l'animazione
            rot_solid = M*solid;
            ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
            hold off;
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            pause(0.01)
        end %end while
    end %end if (button)
    risp2 = menu('Vuoi salvare questa sessione?','Si','No');
    if risp2 == 1
        prompt = 'Con che nome vuoi salvare il file di acquisizione?       ';
        fName = input (prompt, 's');
        save(fName,'ologses'); %salvo i dati
    end;
    else if risp == 2 %CARICA SESSIONE
        prompt = 'Quale file di acquisizione vuoi caricare?     ';
        fName = input (prompt, 's');
        load(fName,'ologses');
        %ottengo gli angoli da plottare da ologses
        %per fare il grafico, è necessario avere dei vettori già pronti
        n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
        ologses = ologses*180/pi;
        %ottengo la matrice di rotazione
        R = zeros(3,3,n); % Array che contiene la sequenza delle rotazioni
        for i=1:n,
          R(:,:,i) = rotz(ologses(1,i))*roty(ologses(2,i))*rotx(ologses(3,i)); 
        end 
        DT = 0.1; % Questo è l'intervallo di campionamento del sensore
        Omega=zeros(3,3,n-1); 
        z = zeros(3,n-1);
        jnn = zeros(3,n-2); 
        jist = zeros(1,n-2); % Questo è il jerk istantaneo non normalizzato (il jerk istantaneo non si può normalizzare)
        for k=2:n
            Omega(:,:,k) = (1/DT)*real(logm(R(:,:,k-1)'*R(:,:,k)));
            z(:,k) = [Omega(1,2,k),Omega(1,3,k),Omega(2,3,k)];
            if k>2, 
                jnn(:,k) = (1/DT^2)*(z(:,k) - 2*z(:,k-1) + z(:,k-2)); 
            end
            jist(k) = norm(jnn(k));
        end
        % Grafico degli angoli in gradi
        hold on;
        %ASSE X
        ax1 = subplot(4,5,[1 2]);
        plot(DT*(1:n),ologses(1,:),'r');
        hold on
        puntoX =  plot(DT,-10:370,'k.');
        title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
        xlim(ax1,[DT,DT*n]);
        ylim(ax1,[-10,370]);
        %ASSE Y
        ax2 = subplot(4,5,[6 7]);
        plot(DT*(1:n),ologses(2,:),'g');
        hold on
        puntoY =  plot(DT,-190:190,'k.'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
        xlim(ax2,[DT,DT*n]);
        ylim(ax2,[-190,190]);
        %ASSE Z
        ax3 = subplot(4,5,[11,12]);
        plot(DT*(1:n),ologses(3,:),'b');
        hold on
        puntoZ =  plot(DT,-100:100,'k.'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
        xlim(ax3,[DT,DT*n]);
        ylim(ax3,[-100,100]); 
        %Jerk
        ax4 = subplot(4,5,[16,20]);
        semilogy(DT*(1:size(jist,2)),jist,'b');
        hold on;
        %puntoJ =  plot(1,10^(-5):10^(5),'k.'); 
        grid on; xlabel('Istanti'); ylabel('Jerk [log scale]');
        xlim(ax4,[DT,DT*n]);
        ylim(ax4,[10^(-5),10^(5)]);
        drawnow;
        %ANIMAZIONE scrolling e figura 3D
        for i=2:n
        rot_solid = R(:,:,i)*solid;
        ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
        plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
        xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
        drawnow
        %asse X
        ax1 = subplot(4,5,[1 2]);
        hold on
        delete (puntoX);
        puntoX = plot(i*DT,-10:20:370,'k.');
        %asse y
        ax2 = subplot(4,5,[6 7]); 
        hold on
        delete (puntoY);
        puntoY =  plot(i*DT,-190:20:190,'k.');
        %asse z
        ax3 = subplot(4,5,[11,12]);
        hold on
        delete (puntoZ);
        puntoZ = plot(i*DT,-100:20:100,'k.');
        %jerk
        %ax4 = subplot(4,5,[16,20]);
        %hold on
        %delete (puntoJ);
        %puntoJ = plot(i*DT,10^(-5):20000:10^(5),'k.');
        drawnow
        pause(0.075)
        end
    end %end if
end %end if (menu)
risp3 = menu('Premi per terminare','ESCI');
if risp3 == 1
    close all
end
clearvars
clc