# English Style Guide — Layered British Voices (Option 3)

Companion to `guion/palabros.md`. Instead of translating every villager into heavy London Cockney (which clashes with rural olive-grove life and hurts international readability), Matritellus uses **five British English voice layers** that mirror the social and generational contrast of the Spanish original.

---

## The 5 Voice Layers

1. **Village Elders (`generic_old`, `generic_old_m`, `generic_old_f`, `whisper_old*`, `luto_*`, `ouch_old`, Tía Paca, Josefa, Eusebio, Tío Gerardo)**
   - **Tone:** Warm, tart, rural/northern British villager.
   - **Lexicon:** *nowt* (nothing), *summat* (something), *aye*, *proper*, *round ’ere*, *lad / lass*, *love / pet*, *back in my day*, *give over*, *bloomin’*, *daft*, plus affectionate malapropisms (*’nalysis*, *injectium*, *clauses*, *depositories*).
   - **Spanish anchors:** Keep *Enga*, *Madre mía*, *gachas*, *migas*, *pisto*, *peña*, *Tricornios*, *pesetas* where they add Manchego flavour.

2. **Street & Nightlife Rogues (`xandro_*`, `koke_*`, `pochi`, `pochi_insultos`, `foski`, `angelus`, `vip_*`, `fiesta`)**
   - **Tone:** Cockney-light / British street slang — punchy, cheeky, sharp.
   - **Lexicon:** *oi*, *mate*, *proper mental*, *off your head*, *dodgy*, *skint*, *sorted*, *motor*, *nicked*, *mug*, *knackered*, *bang on*, *cheeky*, *sod off*, *gaffer*, *tearin’ about*, *gaff*, *punters*.
   - **Avoid:** Opaque Cockney rhyming slang (*dog and bone*, *boat race*, *apples and pears*, *me old china*) and heavy phonetic spelling (*wiv*, *fink*, *innit* in every sentence) so non-native English players never miss a joke.

3. **Village Adults (`generic`, `generic_m`, `generic_f`, `whisper`, `whisper_m`, `whisper_f`, town gossip)**
   - **Tone:** Dry, gossipy provincial British.
   - **Lexicon:** *reckon*, *bloke*, *proper*, *round ’ere*, *natter*, *cuppa*, *on tick*, *the state of you*, *dodgy*, *fair play*, *pub / bar*, *telly*, *petrol*, *kerb*, *MOT*, *trainers*.

4. **Village Kids (`generic_kid`, `whisper_kid`, `nino_negro`)**
   - **Tone:** Cheeky British schoolyard.
   - **Lexicon:** *mum*, *gran*, *grandad*, *nicked*, *proper*, *daft*, *mental*, *reckon*, *sweets*, *break*, *swap*, *telly*, *footy*.

5. **Mayor & Official UI (`alcalde_*`, menus, objectives, signs)**
   - **Mayor:** Crisp Westminster / formal official British (*"Indeed"*, *"One must uphold standards"*).
   - **Menus, objectives & HUD hints:** Clear, standard British English (*colour*, *metres*, *petrol*, *lorry*).

---

## Technical Rules (`loc.gd`)

- **Never modify `"es"` strings** when tuning `"en"`.
- Keep exact parity between `"es"` and `"en"` array lengths (both outer list and inner multi-line dialogues).
- Preserve every format specifier and custom token verbatim: `%s`, `%d`, `{a|b}`, `[[a|b]]`, `{calle}`, `{ruta}`, `{nota}`, `{pena}`.
- Preserve `Loc.PLACES["en"]` and `Loc.OBJECTS["en"]` highlight keywords (`bridge`, `signatures`, `saffron`, `fairground`, `town hall`, `Arcade`, `Galaxy Recress`, etc.) so colour mark-up in `Loc.rich()` stays intact.
- Keep `"generic_kid"` first lines (`t[0]`) free of `{...|...}` / `[[...|...]]` pairs so self-tests comparing raw `"es"`/`"en"` openers stay valid.
