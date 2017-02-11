%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
load david0; 
solid = [surface.X(1:25:end)'; surface.Y(1:25:end)'; surface.Z(1:25:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));
warning('off','all')

%variabili
LstTime = 5;
R = [ ];
Sjerk = [ ];
aus=0;
aus1=0;
v = [0];
update = 59;

%menù
risp = menu('Cosa desideri fare?','Crea una nuova sessione','Carica sessione precedente');
if risp == 1, %NUOVA SESSIONE
    risp1 = menu('Premi OK quando sei pronto','OK');
    if risp1 == 1,
        gyrses = [ ];
        ologses = [ ];
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
            for i=1:3 %ciclo for per il gyr
                a=4; 
                %memorizzo 4 nella variabile a per assegnarle il valore DOUBLE. 
                %Senza questa istrzione, a sarebbe CELL
                a=scan{i}; 
                %memorizzo dentro a il valore contenuto in scan
                a=str2num(a);
                %a=a*pi/180;
                %converto a in un double
                apparray(i)=a;
            end
            %memorizzo a nell'array
            for x=1:3 %ciclo for per l'olog
                g=4; 
                %memorizzo 4 nella variabile a per assegnarle il valore DOUBLE. 
                %Senza questa istrzione, a sarebbe CELL
                g=scan{x+3}; 
                %memorizzo dentro a il valore contenuto in scan
                g=str2num(g);
                %g=g*pi/180;
                %converto a in un double
                apparray1(x)=g; 
                %memorizzo a nell'array
            end
            gyr=vec2mat(apparray,3);
            olog=vec2mat(apparray1,3); 
            %creo una matrice partendo dall'array. 
            %ogni riga della matrice è composta da 3 righe dell'array
            gyr=gyr'; %traspongo la matrice
            olog=olog';
            gyrses = [gyrses,gyr];
            ologses = [ologses,olog];   %vettore d'appoggio per il grafico e per il salvataggio della sessione
            %ottengo gli angoli da plottare da ologses
            n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
            Syaw=1*ologses(1,1:n); %se mettessi unwrap, il grafico sarebbe piatto
            Spitch=1*ologses(2,1:n);
            Sroll=1*ologses(3,1:n);
            %ottengo la matrice di rotazione da gyrses
            m = size(gyrses,2);
            Jyaw=1*gyrses(1,1:m); %se mettessi unwrap, il grafico sarebbe piatto
            Jpitch=1*gyrses(2,1:m);
            Jroll=1*gyrses(3,1:m);
            RJyaw = rotx(Jyaw(m));
            RJpitch = roty(Jpitch(m));
            RJroll = rotz(Jroll(m));
            R=[R,RJyaw*RJpitch*RJroll]; %mdr
            %trasformo la matrice di rotazione in un array multidim 3x3xn
            R1 = reshape(R,3,3,m);
            %cerco di ottenere un numero che rappresenti la variazione di jerk nel
            %tempo
            Sjerk = [Sjerk,jerk(R1,1)];
            aus = ederivation(Sjerk,size(Sjerk,2),1);
            aus1=aus(1,:);
            %inserisco un if di controllo in quanto la dimensione del
            %vettore non può essere negativa
            if size(aus1,2)>1
                aus1=aus1(1:size(aus1,2)-1);
                if size(aus1,2)>1
                    pre = aus1(size(aus1,2))-aus1(size(aus1,2)-1);
                    v=[v,pre];
                end %endfor
            end %end for
            %faccio il grafico
            hold on;
            %asse X
            ax1 = subplot(4,2,1); 
            plot(Syaw,'r');   title('Dati da Udp'); grid on;   xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[0,360]);
            if n<=update
                xlim(ax1,[1,update]);
            else
                xlim(ax1,[n-update,n]);
            end %end if
            %asse Y
            ax2 = subplot(4,2,3); 
            plot(Spitch,'g');   grid on;   xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-180,180]);
            if n<=update
                xlim(ax2,[1,update]);
            else
                xlim(ax2,[n-update,n]);
            end %end if
            %asse Z
            ax3 = subplot(4,2,5); 
            plot(Sroll,'b');   grid on;   xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-90,90]);
            if n<=update
                xlim(ax3,[1,update]);
            else
                xlim(ax3,[n-update,n]);
            end %end if)
            %Jerk
            ax4 = subplot(4,2,7); 
            grid on; plot(v,'b');   xlabel('Istanti'); ylabel('Jerk');
            ylim(ax4,[-1000,1000]);
            if n<=update
                xlim(ax4,[1,update]);
            else
                xlim(ax4,[n-update,n]);
            end %end if
            drawnow;
            %fine grafico
            %QUESTA PARTE SI OCCUPA DELL'ANIMAZIONE
            yaw = unwrap(olog(1,:)); %rotazione lungo x
            pitch = unwrap(olog(2,:)); %rotazione lungo y
            roll = unwrap(olog(3, :)); %rotazione lungo z
            %creo la matrice di rotazione
            mRoll=rotx(roll);      %z
            mPitch=roty(pitch);     %  y
            mYaw=rotz(yaw);        % x
            M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
            %creo l'animazione
            rot_solid = M*solid;
            ax5 = subplot(4,2,[2 4 6 8]);
            hold off;
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            pause(0.01)
            fclose(UDPComIn);
        end %end while
    end;
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
            n=size(ologses,2); %recupero il numero di colonne dai dati  di acquisizione
            Syaw=1*ologses(1,1:n); %se mettessi unwrap, il grafico sarebbe piatto
            Spitch=1*ologses(2,1:n);
            Sroll=1*ologses(3,1:n);
            %ottengo la matrice di rotazione da gyrses
            m = size(gyrses,2);
            Jyaw=1*gyrses(1,1:m); %se mettessi unwrap, il grafico sarebbe piatto
            Jpitch=1*gyrses(2,1:m);
            Jroll=1*gyrses(3,1:m);
            for i=1:m
                RJyaw = rotx(Jyaw(i));
                RJpitch = roty(Jpitch(i));
                RJroll = rotz(Jroll(i));
                R=[R,RJyaw*RJpitch*RJroll]; %mdr
            end %end for
            %trasformo la matrice di rotazione in un array multidim 3x3xm
            R1 = reshape(R,3,3,2*m);
            %cerco di ottenere un numero che rappresenti la variazione di jerk nel
            %tempo
            Sjerk = [Sjerk,jerk(R1,1)];
            aus = ederivation(Sjerk,size(Sjerk,2),1);
            aus1=aus(1,:);
            if size(aus1,2)>1
                aus1=aus1(1:size(aus1,2)-1);
                if size(aus1,2)>1
                    pre = aus1(size(aus1,2))-aus1(size(aus1,2)-1);
                    v=[v,pre];
                end %endfor
            end %end for
        %faccio il grafico
            hold on;
            %asse X
            ax1 = subplot(4,2,1); 
            plot(Syaw,'r');   title('Dati da Udp'); grid on;   xlabel('Istanti'); ylabel('Yaw (X)');
            ylim(ax1,[0,360]);
            %asse Y
            ax2 = subplot(4,2,3); 
            plot(Spitch,'g');   grid on;   xlabel('Istanti'); ylabel('Pitch (Y)');
            ylim(ax2,[-180,180]);
            %asse Z
            ax3 = subplot(4,2,5); 
            plot(Sroll,'b');   grid on;   xlabel('Istanti'); ylabel('Roll (Z)');
            ylim(ax3,[-90,90]);
            %Jerk
            ax4 = subplot(4,2,7); 
            grid on; plot(v,'b');   xlabel('Istanti'); ylabel('Jerk');
            ylim(ax4,[-1000,1000]);
            drawnow;
            %fine grafico
        %ANIMAZIONE
        for i=1:n
            olog = ologses(:,i);
            yaw = unwrap(olog(1,:)); %rotazione lungo z
            pitch = unwrap(olog(2,:)); %rotazione lungo y
            roll = unwrap(olog(3, :)); %rotazione lungo x
            %creo la matrice di rotazione
            mRoll=rotx(roll);      %x
            mPitch=roty(pitch);     %  y
            mYaw=rotz(yaw);        % z
            M=mYaw*mPitch*mRoll; %matrice di rotazione definitiva
            %creo l'animazione
            rot_solid = M*solid;
            ax5 = subplot(4,2,[2 4 6 8]);
            hold off;
            plot3(rot_solid(1,:),rot_solid(2,:),rot_solid(3,:),'b.');
            xlim(ax5,[-100 100]);ylim(ax5,[-100 100]);zlim(ax5,[-200 200])
            pause(0.2) %dovendo fare meno calcoli, l'animazione senza pause è più veloce
        end %end for
    end %end if
end; %end if
clearvars
clc