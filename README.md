# FoundationChat

Eine schlanke macOS-Chat-App, die **ausschließlich** Apples `FoundationModels`-Framework
nutzt (kein OpenAI, keine eigenen Server, keine API-Keys).

## Voraussetzungen

- macOS 26 ("Tahoe") oder neuer, mit aktivierter **Apple Intelligence**
  (Systemeinstellungen → Apple Intelligence & Siri)
- Xcode 26 oder neuer
- Ein Mac, der von Apple Intelligence unterstützt wird

Ist Apple Intelligence nicht aktiviert oder das Modell noch nicht heruntergeladen,
zeigt die App das klar an (Hinweisbanner + Grund) und deaktiviert die Eingabe,
statt abzustürzen.

## Öffnen & Ausführen

```bash
open FoundationChat.xcodeproj
```

Danach in Xcode einmal ein Team für die Codesignierung auswählen
(Target „FoundationChat" → Signing & Capabilities → Team), dann ⌘R.

Das Projekt wird mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus
`project.yml` erzeugt. Nach Änderungen an `project.yml` (z. B. neue Dateien,
andere Einstellungen) einfach neu generieren:

```bash
xcodegen generate
```

## Funktionsumfang

- **Modell-Erkennung**: Beim Start prüft `ModelCatalog`, welche Foundation-Models-
  Modelle auf diesem Mac verfügbar sind (On-Device immer ab macOS 26, dazu
  Private Cloud Compute ab macOS 27, falls das Gerät es unterstützt). Ist nur
  eines verfügbar, wird es automatisch verwendet; sind mehrere verfügbar, kann
  pro Chat über ein Menü in der Titelleiste gewählt werden.
- **Persistente Chats**: Alle Chats und Nachrichten werden über SwiftData lokal
  gespeichert (`~/Library/Containers/…/Application Support`, bzw. ohne Sandbox
  im Standard-Application-Support-Verzeichnis der App). Der komplette
  Gesprächskontext (`Transcript`) wird pro Chat mitgespeichert, sodass ein Chat
  nach einem Neustart der App nahtlos fortgesetzt werden kann.
- **Löschen ohne Rückfrage**: Jeder Chat in der Seitenleiste hat einen
  Papierkorb-Button (beim Hovern sichtbar, alternativ Kontextmenü oder Swipe),
  der sofort und ohne Bestätigungsdialog löscht.
- **Antworten im Stream**: Antworten werden Wort für Wort eingeblendet
  (`LanguageModelSession.streamResponse`), wie man es von Claude/ChatGPT kennt.
- **Einfache, robuste Architektur**: Keine externen Abhängigkeiten, nur
  SwiftUI + SwiftData + FoundationModels. Fehler (z. B. Kontextlimit erreicht,
  Guardrail-Verstoß) werden als Fehler-Bubble im Chatverlauf angezeigt statt
  die App abstürzen zu lassen.

## Projektstruktur

```
Sources/
  App/        App-Einstieg, SwiftData-Container
  Models/     SwiftData-Modelle (Chat, ChatMessage)
  Services/   ModelCatalog (Geräte-/Modellerkennung), ChatEngine (Sessions, Streaming)
  Views/      SwiftUI-Oberfläche (Sidebar, Chat-Detail, Bubbles, Eingabefeld)
```

## Bekannte Einschränkungen

- Private Cloud Compute ist Teil der Foundation-Models-API ab macOS 27 und wird
  automatisch nur angeboten, wenn das Betriebssystem und Gerät es unterstützen.
- Es werden keine Bilder/Dateianhänge unterstützt (reiner Text-Chat).
