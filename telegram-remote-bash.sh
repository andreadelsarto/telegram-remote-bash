#!/bin/bash

CONFIG_DIR="$HOME/.config/telegram-bot"
CONFIG_FILE="$CONFIG_DIR/config"

# Creare la directory di configurazione se non esiste già
mkdir -p "$CONFIG_DIR"

# Se il file di configurazione non esiste, chiedere le informazioni all'utente
if [[ ! -f "$CONFIG_FILE" ]]; then
  read -p "Inserisci il tuo token di accesso del bot di Telegram: " TOKEN
  read -p "Inserisci l'ID del canale o dell'utente a cui vuoi inviare il messaggio: " CHAT_ID

  # Salva queste informazioni nel file di configurazione
  echo "TOKEN=$TOKEN" > "$CONFIG_FILE"
  echo "CHAT_ID=$CHAT_ID" >> "$CONFIG_FILE"

# Se il file di configurazione esiste, leggilo per ottenere le informazioni
else
  source "$CONFIG_FILE"
fi

# Inizializza la variabile che tiene traccia dello stato del bot
STATE="WAITING"

# Inizializza le variabili per tenere traccia dell'ultimo messaggio ricevuto e dell'ultimo messaggio inviato dal bot
LAST_MESSAGE_ID=0
LAST_MESSAGE_TIMESTAMP=0
LAST_BOT_MESSAGE_ID=0
LAST_BOT_MESSAGE_TIMESTAMP=0
VOLUME_LEVEL=0
CPU_LIMIT=90


# Invia un messaggio di benvenuto quando il bot viene avviato
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Bot avviato con successo!"

# Funzione che legge i messaggi inviati al bot utilizzando "curl"
function read_messages() {
    curl -s -X POST https://api.telegram.org/bot$TOKEN/getUpdates | jq '.result[-1]'
}
# Loop infinito che legge costantemente i messaggi inviati al bot
while true; do
    # Legge il messaggio più recente inviato al bot
    MESSAGE=$(read_messages)

    # Estrae l'ID, il testo e il timestamp del messaggio
    MESSAGE_ID=$(echo $MESSAGE | jq -r '.message.message_id')
    MESSAGE_TEXT=$(echo $MESSAGE | jq -r '.message.text')
    MESSAGE_TIMESTAMP=$(echo $MESSAGE | jq -r '.message.date')

    # Verifica se il messaggio ha un timestamp valido
    if [ "$MESSAGE_TIMESTAMP" == "null" ]; then
        MESSAGE_TIMESTAMP=0
    fi

    # Verifica se il messaggio è stato inviato dopo l'ultimo messaggio ricevuto
    if [ $MESSAGE_TIMESTAMP -gt $LAST_MESSAGE_TIMESTAMP ]; then
        # Aggiorna l'ID e il timestamp dell'ultimo messaggio ricevuto
        LAST_MESSAGE_ID=$MESSAGE_ID
        LAST_MESSAGE_TIMESTAMP=$MESSAGE_TIMESTAMP

        # Verifica lo stato del bot e invia messaggi solo quando viene inviato un comando
        if [ "$MESSAGE_TEXT" != "" ] && [ "$STATE" == "WAITING" ]; then
            # Imposta lo stato del bot su "PROCESSING"
            STATE="PROCESSING"

            # Analizza il contenuto del messaggio e esegue i comandi appropriati
            case "$MESSAGE_TEXT" in
                "/battery")
                    LEVEL="$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "percentage" | awk '{print $2}' | tr -d '%')"
                    STATE="$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state" | awk '{print $2}')"
                    if [ "$STATE" == "charging" ]; then
                        EMOJI="🔌"
                    elif [ "$LEVEL" -gt "99" ]; then
                        EMOJI="💯"
                    elif [ "$LEVEL" -gt "80" ]; then
                        EMOJI="🔋🔋🔋🔋"
                    elif [ "$LEVEL" -gt "60" ]; then
                        EMOJI="🔋🔋🔋"
                    elif [ "$LEVEL" -gt "40" ]; then
                        EMOJI="🔋🔋"
                    elif [ "$LEVEL" -gt "20" ]; then
                        EMOJI="🔋"
                    else
                        EMOJI="🔴"
                    fi
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Il livello di batteria del PC è del $LEVEL% $EMOJI"
                    ;;
                "/brightness "*)
                    # Estrae il valore della luminosità dal messaggio
                    BRIGHTNESS=$(echo "$MESSAGE_TEXT" | sed 's|/brightness ||')
                    # Controlla che il valore della luminosità sia un numero compreso tra 0 e 100
                    if [[ "$BRIGHTNESS" =~ ^[0-9]+$ ]] && [ "$BRIGHTNESS" -ge 0 ] && [ "$BRIGHTNESS" -le 100 ]; then
                        # Imposta la luminosità sul valore specificato
                        xrandr --output $(xrandr | grep " connected" | cut -f1 -d" ") --brightness $(bc <<< "scale=2; $BRIGHTNESS/100")
                        # Invia un messaggio di conferma dell'impostazione della luminosità
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Luminosità impostata a ${BRIGHTNESS}%"
                    else
                        # Invia un messaggio di errore se il valore della luminosità non è valido
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Il valore della luminosità non è valido. Deve essere un numero intero compreso tra 0 e 100."
                    fi
                    ;;
                "/shutdown")
                    sudo shutdown -h now
                    ;;
                "/status")
                    DISK=$(df -h | grep "/dev/sda1" | awk '{print $5}')
                    MEMORY=$(free -h | awk '/^Mem/ {print $3 "/" $2}')
                    UPTIME=$(uptime -p)
                    MESSAGE="Uso disco: $DISK\nUso memoria: $MEMORY\nUptime: $UPTIME"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/uptime")
                    UPTIME=$(uptime -p)
                    MESSAGE="Uptime: $UPTIME"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/memory")
                    MEMORY=$(free -h | awk '/^Mem/ {print $3 "/" $2}')
                    MESSAGE="Uso memoria: $MEMORY"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/disk")
                    DISK=$(df -h | grep "/dev/sda1" | awk '{print $5}')
                    MESSAGE="Uso disco: $DISK"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/cpu_usage")
                    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
                    MESSAGE="Utilizzo CPU: $CPU_USAGE"
                    curl -s -X POST https://api.telegram.org
                    ;;
                "/top_processes")
                    TOP_PROCESSES=$(ps -eo pcpu,pid,user,args --no-headers | sort -t. -nk1,2 -k4,4 -r | head -n 5)
                    MESSAGE="Top 5 processi:\n$TOP_PROCESSES"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/active_window")
                    # Ottiene l'ID della finestra attiva
                    ACTIVE_WINDOW_ID=$(qdbus org.kde.KWin /KWin/ActiveWindow org.kde.KWin.getActiveWindow)
                    # Ottiene il titolo della finestra attiva
                    ACTIVE_WINDOW_TITLE=$(qdbus org.kde.KWin /KWin/ActiveWindow org.kde.KWin.WindowCaption)
                    MESSAGE="Finestra attiva: $ACTIVE_WINDOW_TITLE"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/screenshot")
                    SCREENSHOT_FILE="/tmp/screenshot_$(date +%Y%m%d_%H%M%S).png"
                    spectacle --nonotify -b -o "$SCREENSHOT_FILE"
                    curl -s -X POST -F "chat_id=$CHAT_ID" -F "photo=@$SCREENSHOT_FILE" "https://api.telegram.org/bot$TOKEN/sendPhoto"
                    rm "$SCREENSHOT_FILE"
                    ;;
                "/speedtest")
                    # Invia un messaggio di avvio dello speedtest
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Speedtest in corso... $target..."
                    SPEEDTEST_RESULT=$(speedtest-cli)
                    MESSAGE="Risultato del test di velocità:\n$SPEEDTEST_RESULT"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
               "/ping"*)
                    # Estrae il target dal messaggio
                    target=$(echo "$MESSAGE_TEXT" | sed 's|/ping ||')
                    if [ -z "$target" ]; then
                        # Se non è stato specificato un indirizzo IP, richiedi di usare il comando /ip
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Per favore specifica un indirizzo IP. Usa /ip <indirizzo IP>."
                    else
                        # Invia un messaggio di conferma del ping in corso
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Ping in corso verso $target..."
                        # Esegue il ping e salva il risultato
                        ping_result=$(ping -c 4 "$target")
                        # Invia un messaggio con il risultato del ping
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Risultato del ping per $target:\n$ping_result"
                    fi
                    ;;
               "/version")
                    VERSION=$(lsb_release -a | grep "Description" | awk '{$1=""; print $0}')
                    MESSAGE="<b>Versione di KDE Neon:</b>\n$VERSION"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d parse_mode="HTML" -d text="$MESSAGE"
                    ;;
                "/log")
                    LOG_FILE=/var/log/syslog
                    PLAIN_TEXT=$(sed 's/<[^>]*>//g' $LOG_FILE)
                    curl -s -F chat_id=$CHAT_ID -F document=@<(echo -e "$PLAIN_TEXT") https://api.telegram.org/bot$TOKEN/sendDocument
                    ;;
                "/ip")
                    IP="$(ip addr show | grep -E "inet " | head -n 1 | awk '{print $2}')"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="L'indirizzo IP del PC è $IP"
                    ;;
                "/network")
                    NETWORK="$(nmcli device wifi list)"
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$NETWORK"
                    ;;
                "/update")
                    MESSAGE_TEXT="$(pkcon refresh)"
                    UPDATE_COUNT="$(echo "$MESSAGE_TEXT" | grep -c "Available updates")"
                    if [ $UPDATE_COUNT -gt 0 ]; then
                        UPDATE_LIST="$(echo "$MESSAGE_TEXT" | grep -A $UPDATE_COUNT "Available updates" | tail -n $UPDATE_COUNT)"
                        MESSAGE="Sono disponibili $UPDATE_COUNT pacchetti per l'aggiornamento: \n\n $UPDATE_LIST"
                    else
                        MESSAGE="Non ci sono pacchetti disponibili per l'aggiornamento."
                    fi
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"
                    ;;
                "/upgrade")
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Aggiornamento in corso... attendere."
                    pkcon update -y
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Aggiornamento completato!"
                    ;;
                "/processes")
                    PROCESSES=$(ps -eo pid,ppid,user,cmd,%mem,%cpu --sort=-%mem | head | awk '{print $1, $2, $3, $4, $5, $6}')
                    MESSAGE="*I primi 10 processi con il maggiore utilizzo di memoria:*\n\n"
                    MESSAGE+=$(echo "$PROCESSES" | awk 'BEGIN{print "```"} {print $0} END{print "```"}')
                    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=MarkdownV2"
                    ;;
                "/volume "*)
                    # Estrae il valore del volume dal messaggio
                    volume=$(echo "$MESSAGE_TEXT" | sed 's|/volume ||')
                    # Controlla che il valore del volume sia un numero compreso tra 0 e 100
                    if [[ "$volume" =~ ^[0-9]+$ ]] && [ "$volume" -ge 0 ] && [ "$volume" -le 100 ]; then
                        # Imposta il volume sul valore specificato
                        amixer -D pulse sset Master "${volume}%"
                        # Invia un messaggio di conferma dell'impostazione del volume
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Volume impostato a ${volume}%"
                    else
                        # Invia un messaggio di errore se il valore del volume non è valido
                        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Il valore del volume non è valido. Deve essere un numero intero compreso tra 0 e 100."
                    fi
                    ;;
                "/lock_failed")
                    # Invia un messaggio di avviso se ci sono stati errori di accesso allo schermo bloccato
                    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Qualcuno ha tentato di accedere al tuo PC ma ha inserito una password errata."
                    ;;


                *)
                    ;;
            esac

            # Aggiorna l'ID e il timestamp dell'ultimo messaggio inviato dal bot
            LAST_BOT_MESSAGE_ID=$(curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Attendo..." | jq -r '.result.message_id')
            LAST_BOT_MESSAGE_TIMESTAMP=$(date +%s)
            STATE="WAITING"
        fi
    fi

    # Verifica se il bot ha inviato un messaggio dopo l'ultimo


            # Verifica se il bot ha inviato un messaggio dopo l'ultimo messaggio inviato dal bot
        if [ $LAST_BOT_MESSAGE_TIMESTAMP -lt $MESSAGE_TIMESTAMP ] && [ $LAST_BOT_MESSAGE_ID -lt $MESSAGE_ID ]; then
            # Invia un messaggio di conferma di ricezione al bot
            curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Messaggio ricevuto!"

            # Aggiorna l'ID e il timestamp dell'ultimo messaggio inviato dal bot
            LAST_BOT_MESSAGE_ID=$(curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="Messaggio ricevuto!" | jq -r '.result.message_id')
            LAST_BOT_MESSAGE_TIMESTAMP=$(date +%s)
        fi

    # Attende un secondo prima di leggere il prossimo messaggio
    sleep 1
done

