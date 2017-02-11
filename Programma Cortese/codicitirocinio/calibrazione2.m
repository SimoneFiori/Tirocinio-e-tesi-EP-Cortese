%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%dichiarazione variabili
LstTime = 5;
DimPacch = 30;
DimTimeStamp = 15;
timestampPrec = 0;
n = 0;
vlog = [];

%struttura
f1 = 'tipo';
f2 = 'calibrazione';
calib = struct(f1,{},f2,{});
calib(1).calibrazione = 0;

%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000);
%Creo nuovo oggetto UDP
UDPComIn=udp('0.0.0.0','LocalPort',4000);
set(UDPComIn,'DatagramTerminateMode','on', 'TimeOut', LstTime);
%0.0.0.0 = qualunque ip che invia dati, 4000 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente
cond=false;
while (calib(1).calibrazione == 0)
    
    fopen(UDPComIn)
    csvdata = fscanf(UDPComIn);
    fclose(UDPComIn)
    n = n+1;  %numero campione 
    
    %ricevo i dati
    if isempty(csvdata)==1  break; end; 
    scandata=textscan(csvdata,'%s','Delimiter',',#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %i delimiter possibili sono virgola e cancelletto
    scan=scandata{1,1};
    %inserisco il risultato di scandata in una variabile. NB: scan è di tipo CELL
    scan=scan(~cellfun('isempty',scan));
    %elimino le righe vuote;
    dim = size(scan,1);
    if (n==1)
        switch(dim)
           case 7
               disp('linear accelerometer + orientation sensor');
               calib(1).tipo = 1;
           case 10
               disp('terna MAG');
               calib(1).tipo = 2;
           otherwise
               disp('terna non riconosciuta');
        end
    end
   
   %immagazzino i dati in un array di appoggio
   for i=1:dim
        if (i == 1)
            timestamp = scan{1,1};
            timestamp = str2num(timestamp);
            DT(1,n) = (timestamp - timestampPrec)/1000;
            if (DT>=1)
                DT(1,n) = 0.02;
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
   
   %elaboro l'array a seconda del tipo di dati ricevuto in array di array
   switch(calib(1).tipo)
       case 1
           pos=1;
           while(aparray(pos)>0.05 && aparray(pos+1)>0.05 && aparray(pos+2)>0.05)
               pos = pos+1;
           end
           acclog(:,n) = aparray(1,pos:pos+2)';
           if(pos==1)
               olog(:,n) = aparray(1,pos+3:pos+5)';
           elseif(pos==4)
               olog(:,n) = aparray(1,pos-3:pos-1)';
           end
       case 2
           pos=1;
           while(abs(aparray(pos)-9.8)>0.1)
               pos = pos+1;
           end
           acclog(:,n) = aparray(1,1:pos)';
           if(aparray(pos+1)>1)
               maglog(:,n) = aparray(1,pos+1:pos+3)';
               gyrlog(:,n) = aparray(1,pos+4:pos+6)';
           else
               gyrloglog(:,n) = aparray(1,pos+1:pos+3)';
               maglog(:,n) = aparray(1,pos+4:pos+6)';
           end
   end
   
   %calibrazione passo 1
   switch(calib(1).tipo)
       case 1
           if n>20
               DT = DT(2:n);
               DTzero = mean(DT)
               mean_acc = mean(acclog,2);
               err_acc = var(acclog,0,2);
               err_o = var(olog,0,2);
               calib(1).calibrazione = 0;
           end
       case 2
           if n>20
               DT = DT(2:n);
               DTzero = mean(DT);
               err_acc = var(acclog,0,2);
               err_mag = var(maglog,0,2);
               err_gyr = var(gyrlog,0,2);
               calib(1).calibrazione = 1;
           end
   end
   
end