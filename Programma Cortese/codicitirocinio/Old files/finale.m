%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%carico figura 3D
load david0; 
solid = [surface.X(1:25:end)'; surface.Y(1:25:end)'; surface.Z(1:25:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));

%variabili
LstTime = 5;
R = [ ];
campionamento = 4;
update = 59;
updateJ = 14;
ausJerk = [];

%menù
risp = menu('Cosa desideri fare?','Crea una nuova sessione','Carica sessione precedente');
if risp == 1, 
    %NUOVA SESSIONE (online)
    risp1 = menu('Premi OK quando sei pronto','OK');
    if risp1 == 1,
        figure
        ologses = [ ]; %vettore in cui vengono salvate tutte le terne
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
            fclose(UDPComIn);
            if isempty(csvdata)==1  break; end;
            olog = lettura_online(csvdata);
            ologses = [ologses,olog]; %vettore d'appoggio per il grafico e per il salvataggio della sessione
            n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
            %ottengo la matrice di rotazione
            if mod(n,campionamento) == 0
                R = zeros(3,3,n); % Array che contiene la sequenza delle rotazioni
                for i=1:n,
                    R(:,:,i) = rotz(ologses(1,i))*roty(ologses(2,i))*rotx(ologses(3,i));
                end
                R1 = R(:,:,n-campionamento+1:n);
                ausJerk = [ausJerk,jerk_online(R1)];
            end;
            m = size(ausJerk,2); %effetto scorrimento del jerk
            %GRAFICO DEGLI ANGOLI
            hold on;
            %asse X
            ax1 = subplot(4,5,[1 2]); 
            plot(180*ologses(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[-10,370]);
            if n<=update
                xlim(ax1,[1,update]);
            else
                xlim(ax1,[n-update,n]);
            end %end if
            %asse Y
            ax2 = subplot(4,5,[6 7]); 
            plot(180*ologses(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-190,190]);
            if n<=update
                xlim(ax2,[1,update]);
            else
                xlim(ax2,[n-update,n]);
            end %end if
            %asse Z
            ax3 = subplot(4,5,[11 12]); 
            plot(180*ologses(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-100,100]);
            if n<=update
                xlim(ax3,[1,update]);
            else
                xlim(ax3,[n-update,n]);
            end %end if
            %GRAFICO DEL JERK
            ax4 = subplot(4,5,[16,20]);
            semilogy(ausJerk,'b'); grid on; xlabel('Istanti'); ylabel('Jerk [log scale]');
            ylim (ax4,[10^(-2),10^8])
            if m<=updateJ
                xlim(ax4,[1,updateJ])
            else
                xlim(ax4,[m-updateJ,m])
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
        save(fName); %salvo i dati
    end;
    else if risp == 2 %CARICA SESSIONE
        prompt = 'Quale file di acquisizione vuoi caricare?     ';
        fName = input (prompt, 's');
        load(fName);
        %ottengo gli angoli da plottare da ologses
        %per fare il grafico, è necessario avere dei vettori già pronti
        n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
        ologses = pi*ologses/180; %converto in radianti
        %ottengo la matrice di rotazione
        R = zeros(3,3,n); % Array che contiene la sequenza delle rotazioni
        for i=1:n,
          R(:,:,i) = rotz(ologses(1,i))*roty(ologses(2,i))*rotx(ologses(3,i)); 
        end 
        Sjerk = jerk_offline(R);
        % Grafico degli angoli in gradi
        figure; hold on;
        %asse X
        ax1 = subplot(4,5,[1 2]);
        plot(180*ologses(1,:)/pi,'r');  title('Dati da smartphone'); grid on; xlabel('Istanti'); ylabel('Yaw (X)');
        xlim(ax1,[0,n]);
        %asse Y
        ax2 = subplot(4,5,[6 7]); 
        plot(180*ologses(2,:)/pi,'g'); grid on; xlabel('Istanti'); ylabel('Pitch (Y)');
        xlim(ax2,[0,n]);
        %asse Z
        ax3 = subplot(4,5,[11,12]); 
        plot(180*ologses(3,:)/pi,'b'); grid on; xlabel('Istanti'); ylabel('Roll (Z)');
        xlim(ax3,[0,n]);
        %Jerk
        ax4 = subplot(4,5,[16,20]); 
        grid on; semilogy(Sjerk,'b'); xlabel('Istanti'); ylabel('Jerk [log scale]');
        xlim(ax4,[0,n]);
        drawnow;
        %ANIMAZIONE
        for i=1:n,
            rot_solid = R(:,:,i)*solid;
            ax5 = subplot(4,5,[3 4 5 8 9 10 13 14 15]);
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            pause(0.1) % Dovendo fare meno calcoli, l'animazione senza pause è più veloce
            drawnow;
        end %end for
    end %end if
    clearvars
    clc
end %end if (menu)
risp3 = menu('Premi per terminare','ESCI');
if risp3 == 1
    close all
end
