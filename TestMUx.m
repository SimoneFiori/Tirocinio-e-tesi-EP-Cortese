%Reset ambiente Matlab
instrreset
clear
clc
close all;
clear all;
warning('off','all')

%dichiarazione variabili
LstTime = 5;
cond=true;

%Creo nuovo oggetto UDP
UDPComIn1=udp('0.0.0.0','LocalPort',4000);
UDPComIn2=udp('0.0.0.0','LocalPort',2055);
set(UDPComIn1,'DatagramTerminateMode','off', 'TimeOut', LstTime );
set(UDPComIn2,'DatagramTerminateMode','off', 'TimeOut', LstTime );
%0.0.0.0 = qualunque ip che invia dati, 1710 è la porta in cui i dati
%vengono trasmessi. È possibile deciderne una arbitrariamente




while 1
    fopen(UDPComIn1)
    fopen (UDPComIn2)
    csvdata1 = fscanf(UDPComIn1)
    csvdata2 = fscanf(UDPComIn2)
    fclose(UDPComIn1)
    fclose(UDPComIn2)
end