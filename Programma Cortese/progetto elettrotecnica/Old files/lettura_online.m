function olog = lettura_online (csvdata)
%funzione che legge i dati dal flusso in entrata e restituisce la terna di
%angoli
    %ricevo i dati
    scandata=textscan(csvdata,'%s','Delimiter',',#');
    %vado a leggere la stringa ricevuta. %s significa che i dati sono stringhe, 
    %i delimiter possibili sono virgola e cancelletto
    scan=scandata{1,1} ;
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
end
