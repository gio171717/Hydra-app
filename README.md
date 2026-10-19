# Hydra 💧

App per iPhone (SwiftUI, iOS 17+) per contare quanta acqua bevi ogni giorno.

## Funzioni

- **Obiettivo giornaliero in litri**: da 0,5 a 6 L, a passi di 0,1 L (slider, pulsanti +/− o scorciatoie 1,5 / 2 / 2,5 / 3 L).
- **Aggiunta rapida con misure standard**: bicchiere di plastica (200 ml), bicchiere di vetro (250 ml),
  bottiglietta di plastica (500 ml), bottiglia (1 L), bottiglia grande (1,5 L), bottiglia maxi (2 L).
  Tieni premuto un contenitore per aggiungerne solo **metà** o **un quarto**.
  Le capienze si possono cambiare nelle impostazioni.
- **Inserimento manuale** dei ml, con tastierino numerico, pulsanti ±50 ml e valori rapidi.
- **Promemoria**: notifiche a intervalli regolari (es. ogni 90 minuti dalle 8:00 alle 22:00) che ti dicono
  quanto bere per arrivare all'obiettivo. La quantità è calcolata su quello che ti manca diviso i
  promemoria rimasti: se ne salti uno, i successivi ti chiedono un po' di più; quando raggiungi
  l'obiettivo i promemoria del giorno si fermano.
  Tenendo premuta la notifica puoi registrare subito un bicchiere o una bottiglietta senza aprire l'app.
- Cerchio animato che si riempie d'acqua, elenco delle bevute di oggi (scorri a sinistra per eliminare),
  pulsante "Annulla" dopo ogni aggiunta, storico degli ultimi 7 giorni con grafico.

## Installarla sul tuo iPhone

Serve un **Mac con Xcode 16 o successivo** (gratuito dal Mac App Store) e un Apple ID.

1. Scarica il progetto sul Mac (`git clone` oppure "Code → Download ZIP" su GitHub).
2. Apri `Hydra.xcodeproj` con Xcode.
3. Seleziona il progetto **Hydra** → target **Hydra** → scheda **Signing & Capabilities**:
   - in **Team** scegli il tuo Apple ID (se non c'è: *Add an Account…*);
   - se Xcode segnala che il *Bundle Identifier* è già in uso, cambialo in qualcosa di unico,
     ad esempio `com.tuonome.hydra`.
4. Collega l'iPhone al Mac con il cavo, sbloccalo e selezionalo in alto come destinazione.
5. Premi ▶︎ (Run).
6. La prima volta, sull'iPhone:
   - attiva **Impostazioni → Privacy e sicurezza → Modalità sviluppatore** (l'iPhone si riavvia);
   - vai in **Impostazioni → Generali → VPN e gestione dispositivi**, tocca il tuo Apple ID e scegli **Autorizza**.

Con un Apple ID gratuito l'app resta installata per **7 giorni**: dopo basta ricollegare l'iPhone e premere
di nuovo ▶︎ (i dati restano). Con l'Apple Developer Program (99 €/anno) dura un anno e si può distribuire
tramite TestFlight.

## Struttura

```
Hydra/
  App/HydraApp.swift                     avvio app e gestione delle notifiche
  Models/                                contenitori, bevute, impostazioni, formattazione
  Store/HydrationStore.swift             dati e salvataggio (UserDefaults)
  Notifications/ReminderScheduler.swift  calcolo e pianificazione dei promemoria
  Views/                                 schermate (principale, manuale, impostazioni, storico, benvenuto)
```

`index.html` è il prototipo web iniziale.
