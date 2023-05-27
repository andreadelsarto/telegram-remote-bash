# Telegram Remote Bash for KDE Neon

Questo è uno script basato su Bash che funge da bot di Telegram, permettendoti di monitorare e controllare un computer remoto attraverso comandi inviati via Telegram. È stato progettato per KDE Neon.

## Licenza

Questo software è distribuito sotto la licenza [GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.html).

## Prerequisiti

Questo script ha bisogno dei seguenti pacchetti per funzionare correttamente:

- curl: per fare le richieste HTTP a Telegram API
- jq: per analizzare le risposte JSON di Telegram API
- bc: per fare calcoli con numeri decimali
- xrandr, upower, df, free, uptime, top, ps, qdbus, spectacle, speedtest-cli, ping, lsb_release, sed, ip, nmcli, pkcon, amixer: per i vari comandi

Per installare le dipendenze su un sistema Debian-based come KDE Neon, esegui il seguente comando:

```bash
sudo apt update && sudo apt install curl jq bc xrandr upower df free uptime top ps qdbus spectacle speedtest-cli ping lsb-release sed ip nmcli pkcon amixer
```

## Creazione del Bot Telegram
Apri Telegram e cerca "BotFather".
Avvia una chat con BotFather e segui le istruzioni per creare un nuovo bot.
Una volta creato il bot, BotFather ti fornirà un token di accesso. Salva questo token per dopo.
Per ottenere l'ID del canale o dell'utente a cui vuoi inviare il messaggio, consulta questo [link](https://stackoverflow.com/questions/33858927/how-to-obtain-the-chat-id-of-a-private-telegram-channel) per le istruzioni dettagliate.

## Configurazione
Clona questo repository sul tuo sistema.
Esegui lo script telegram_remote_bash.sh.
Al primo avvio, lo script chiederà il tuo token di accesso del bot di Telegram e l'ID del canale o dell'utente a cui vuoi inviare il messaggio. Inserisci queste informazioni quando richiesto.

## Uso
Dopo aver avviato lo script, il bot risponderà ai seguenti comandi (copia e incolla questi comandi su botfather):

/battery: mostra lo stato della batteria.

/brightness <valore>: imposta la luminosità dello schermo al <valore> percentuale specificato.

/shutdown: spegne il computer.

/status: mostra l'uso del disco, l'uso della memoria e l'uptime.

/uptime: mostra l'uptime del computer.

/memory: mostra l'uso della memoria.

/disk: mostra l'uso del disco.

/cpu_usage: mostra l'utilizzo della CPU.

/top_processes: mostra i primi 5 processi per l'utilizzo della CPU.

/active_window: mostra la finestra attiva.

/screenshot: prende uno screenshot dello schermo e lo invia.

/speedtest: esegue uno speedtest e invia i risultati.

/ping <indirizzo>: esegue il ping all'<indirizzo> specificato e invia i risultati.

/version: mostra la versione del sistema operativo.

/log: invia il file di log del sistema.

/ip: mostra l'indirizzo IP del computer.

/network: mostra l'elenco delle reti wifi disponibili.

/update: mostra l'elenco degli aggiornamenti disponibili.

/upgrade: esegue gli aggiornamenti disponibili.

/processes: mostra i primi 10 processi con il maggiore utilizzo di memoria.

/volume <valore>: imposta il volume al <valore> percentuale specificato.

## Limitazioni
Questo script funziona solo su sistemi basati su Linux con Bash. 
Lo script deve essere eseguito con i privilegi di root per alcuni comandi, come /shutdown.

## Contribuzione
Sto cercando feedback e suggerimenti su come migliorare questo script. Se riscontri un bug o vuoi proporre una nuova funzionalità, sentiti libero di aprire una issue su GitHub.
