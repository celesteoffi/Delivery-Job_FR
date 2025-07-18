# RK Job Delivery - Sistema Multi-Player

## Installazione

1. **Database Setup**
   - Esegui il file SQL `sql/jobdelivery.sql` nel tuo database MySQL
   - Assicurati di avere `mysql-async` installato e configurato

2. **Dipendenze richieste**
   - `ox_target`
   - `ox_lib`
   - `mysql-async`

3. **Installazione della risorsa**
   - Metti la cartella nella directory `resources/[rk_vario]/`
   - Aggiungi `ensure rk_jobdelivery` al tuo `server.cfg`

## Caratteristiche del sistema

### ✅ Multi-Player Support
- Ogni giocatore può avere un lavoro attivo simultaneamente
- I dati vengono salvati nel database MySQL
- Ripristino automatico del lavoro dopo disconnessione/riconnessione

### ✅ Tracciamento completo
- Stato del lavoro (attivo, completato, abbandonato)
- Progresso delle consegne in tempo reale
- Cronologia di tutti i lavori svolti

### ✅ Gestione intelligente
- Prevenzione doppi lavori per lo stesso giocatore
- Aggiornamento automatico del progresso
- Cleanup automatico delle entità quando si abbandona il lavoro

## Come funziona

1. **Inizio lavoro**: Il giocatore interagisce con il ped postino e avvia il lavoro tramite tablet
2. **Tracciamento**: Il sistema crea un record nel database con tutti i dettagli del lavoro
3. **Progresso**: Ogni consegna completata viene aggiornata nel database
4. **Ripristino**: Se il giocatore si disconnette, al rilogin il lavoro viene ripristinato automaticamente
5. **Completamento**: Al termine, il lavoro viene marcato come completato e il giocatore riceve la paga

## Struttura Database

La tabella `rk_jobdelivery` contiene:
- `player_identifier`: Identificatore univoco del giocatore
- `job_status`: Stato del lavoro (active/completed/abandoned)
- `current_delivery`: Indice della consegna attuale
- `deliveries_completed`: Numero di consegne completate
- `total_deliveries`: Totale consegne da fare
- `start_time` / `end_time`: Timestamp di inizio e fine
- `total_earnings`: Guadagni totali
