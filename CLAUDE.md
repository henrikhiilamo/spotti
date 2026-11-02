# Ilmaispaikka

Verkkosovellus, joka näyttää ilmaiset pysäköintipaikat kartalla, aluksi Aalto-yliopiston Otaniemen alueella.

Harjoitusprojekti: omistaja opettelee rakentamaan ja julkaisemaan sovelluksen ja hankkimaan sille käyttäjiä.
- Selitä tekemäsi muutokset lyhyesti, omistaja haluaa oppia.
- Kysy ennen kuin asennat mitään (npm-paketit, CLI-työkalut, uudet CDN-kirjastot).

## Rakenne

- `index.html` on koko sovellus: HTML, CSS ja JavaScript samassa tiedostossa. Ei build-vaihetta eikä npm:ää.
- `supabase/schema.sql` on tietokannan rakenne ja käyttöoikeudet. Ajetaan käsin Supabasen SQL Editorissa.
- `data/osm-otaniemi.json` on Otaniemen OSM-pysäköintialueiden tilannekuva (Overpassin raakavastaus). Päivitetään komennolla `sh scripts/update-osm-snapshot.sh`.
- `.github/workflows/update-osm-snapshot.yml` ajaa saman skriptin GitHubissa maanantaisin. Jos paikat muuttuivat, se commitoi tiedoston, ja push käynnistää Pages-julkaisun. Voi ajaa myös käsin: Actions → Päivitä OSM-tilannekuva → Run workflow. Muista siksi `git pull` ennen omia muutoksia.
- Kirjastot ladataan CDN:stä tarkalla versionumerolla: Leaflet 1.9.4 (cdnjs), supabase-js 2.118.0 (jsDelivr).

## Ajaminen

```bash
python3 -m http.server 8000
```

Avaa http://localhost:8000. Sivua ei voi avata suoraan tiedostona (`file://`), koska karttapohja ja haut vaativat http-palvelimen.

Clauden esikatselu (`.claude/launch.json`) käyttää porttia 8001, ettei se törmää omistajan omaan palvelimeen portissa 8000.

## Julkaisu

- GitHub Pages: https://henrikhiilamo.github.io/ilmaispaikka/ (repo `henrikhiilamo/ilmaispaikka`, haara `main`, juurikansio).
- Päivitys: `git push`, minkä jälkeen sivu päivittyy noin minuutissa.
- Pages julkaisee kaikki repon tiedostot, myös CLAUDE.md:n ja schema.sql:n. Repoon ei saa koskaan laittaa salaisuuksia.
- `.nojekyll` kertoo GitHubille, että sivu julkaistaan sellaisenaan ilman Jekyll-käännöstä.

## Tietolähteet

- Karttapohja: OpenStreetMapin tiilet. Jos ne eivät lataudu, vaihdetaan automaattisesti Esri World Street Mapiin.
- OSM-pysäköintialueet haetaan Overpass API:lla (kaksi palvelinta, toinen varalla; kumpaakin odotetaan enintään 20 s, koska ilmaiset palvelimet välillä jumittuvat vastaamatta):
  - `amenity=parking` + `fee=no` → ilmainen
  - `amenity=parking` ilman `fee`-tagia → hinta tuntematon
  - pois suodatetaan `access` = private, customers, permit, delivery, no, residents
  - `NOT_FREE_OSM` (index.html) piilottaa alueet, jotka OSM merkitsee ilmaisiksi, vaikka ne vaativat Aalto-yliopiston pysäköintiluvan tai ovat maksullisia. Lista on tarkistettu Aallon kampuksen pysäköintikarttaa (v8) vasten 2026-11-02. Jos OSM-alue piirretään uudelleen, sen tunniste vaihtuu ja se pitää lisätä listaan uudelleen. Parempi pitkän aikavälin korjaus on korjata tagit (`access=permit`) suoraan OSM:ään paikan päällä nähtyjen kylttien perusteella. Aallon karttaa ei voi käyttää OSM:n lähteenä, koska OSM hyväksyy vain lähteet, joiden lisenssi sen sallii, eikä Aallon kartalle ole ilmoitettu lisenssiä.
  - Kadunvarsipysäköinti haetaan kaduille merkityistä tageista (`parking:left/right/both` ja vanhempi `parking:lane:*`, ehdot `:fee`, `:restriction`, `:access`, `parking:condition:*`). Logiikka on `streetSpot()`-funktiossa. Katuosuus näytetään yhtenä merkkinä keskikohdassaan. Se on ilmainen, jos jollain puolella on `fee=no`, `free` tai `disc`, ja muuten hinta on tuntematon.
  - `PAID_STREETS` (index.html) piilottaa kadut, joiden kadunvarsipysäköinnin Espoo muutti maksulliseksi lokakuussa 2026 Otaniemessä ja Tapiolassa (Espoon tiedote 16.9.2026, liitekartat). OSM merkitsee monet niistä yhä ilmaisiksi. Osittain maksulliset kadut piilotetaan kokonaan varmuuden vuoksi. Muualla Espoossa (esim. Matinkylä, Kilo, Soukka, Leppävaara) maksullisuutta laajennettiin myös vuonna 2026, mutta niitä katuja ei ole listassa.
  - `fee:conditional` näytetään ponnahdusikkunassa, esimerkiksi Otaparkki: `fee=no`, mutta "Maksullinen ma-pe 08:00-18:00". Muuten osittain maksullinen paikka näyttäisi aina ilmaiselta.
  - haku vain zoomilla ≥ 14, tulos välimuistiin localStorageen 24 tunniksi
  - käynnistyksessä näytetään välimuisti tai, jos sitä ei ole, repon tilannekuva `data/osm-otaniemi.json`. Live-haku tehdään vain Hae-napista, tai jos tilannekuvaa ei saada ladattua.
  - sama Overpass-kysely on kahdessa paikassa (`searchArea()` ja `scripts/update-osm-snapshot.sh`), joten pidä ne samoina
- Käyttäjien lisäämät paikat: Supabase-taulu `spots`, kaikki näkevät samat paikat.

## Supabase

Käyttöönotto uudessa projektissa:
1. Luo projekti osoitteessa supabase.com.
2. SQL Editor → aja `supabase/schema.sql`.
3. Authentication → Sign In / Providers → kytke päälle "Allow anonymous sign-ins".
4. Kopioi projektin URL ja publishable key `index.html`:n vakioihin `SUPABASE_URL` ja `SUPABASE_KEY`.

Miten oikeudet toimivat:
- Kuka tahansa voi katsoa paikkoja kirjautumatta.
- Kun selain lisää ensimmäisen paikkansa, se kirjautuu anonyymisti (`signInAnonymously`). Supabase muistaa tunnuksen selaimen localStoragessa. Pelkkä katselu ei luo tunnusta.
- Tietokanta täyttää `created_by`-sarakkeen itse. RLS-säännöt sallivat lisäyksen vain omissa nimissä ja poiston vain lisääjälle. Muokkausta ei ole.
- Publishable (anon) key on tarkoitettu julkiseksi ja saa olla koodissa ja Gitissä; turvallisuus tulee RLS-säännöistä. Secret- eli service_role-avainta ei saa koskaan laittaa tähän repoon.

## Koodityyli

- Vanilla JS ES5-tyyliin (`var`, `function`, `.then`-ketjut) yhden IIFE:n sisällä. Ei frameworkkia.
- OSM:n ja käyttäjien teksti näytetään aina `textContent`illa, ei koskaan `innerHTML`:llä, ettei kukaan voi syöttää sivulle HTML:ää tai skriptejä.
- Käyttöliittymän tekstit suomeksi.

## Päätökset

- 2026-11-02: Projekti Git-repoksi, päähaara `main`. Commit-nimi ja -sähköposti on asetettu vain tähän repoon (`git config`, ei `--global`). Sähköpostina on GitHubin noreply-osoite, jotta omistajan Gmail ei näy julkisessa repossa.
- 2026-11-02: Julkaisu GitHub Pagesiin, koska se on ilmainen ja päivittyy suoraan `git push` -komennolla ilman erillistä palvelua. Push tehdään SSH-avaimella (`~/.ssh/id_ed25519`, salasana macOS:n avainnipussa).
- 2026-11-02: Käyttäjien paikat localStoragesta Supabaseen, jotta kaikki näkevät samat paikat. supabase-js ladataan CDN:stä (ei npm:ää), koska anonyymi kirjautuminen on sillä helppo tehdä. Poisto-oikeus vain lisääjällä anonyymin tunnuksen avulla; vaihtoehto "kuka tahansa voi poistaa" hylättiin, koska yksi ilkivaltainen käyttäjä voisi tyhjentää kartan.
- 2026-11-02: Vanhoja localStorageen tallennettuja paikkoja ei siirretä Supabaseen automaattisesti; sovellus ei enää lue niitä.

- 2026-11-02: Valmiiksi lisättävien paikkojen lähteet tutkittiin. Mukaan otettiin vain OSM-tilannekuva, koska muut eivät sopineet:
  - Fintraffic LIIPI (liityntäpysäköinti, `parking.fintraffic.fi/api/v1/facilities`): lähellä vain yksi ilmainen paikka, Hanasaarenranta (80 paikkaa, 12 h), eikä lisenssiä löytynyt
  - Espoon pysäköintirekisteri (WFS-taso `GIS:PKSEspooPysakointialueet`): ei hintatietoa, eikä Otaniemessä ole yhtään kohdetta
  - Aalto-yliopisto: kampuksella pysäköinti on arkisin 8–18 maksullista tai vaatii henkilökunnan luvan
  - EasyPark, Parkman, Google Maps: käyttöehdot kieltävät tietojen kopioinnin
- OSM-data on ODbL-lisenssillä: lähde pitää mainita (kartan alakulmassa), ja johdettu aineisto on jaettava samalla lisenssillä (repo on julkinen).

## Tunnetut rajoitukset

- OSM:n kadunvarsitiedot ovat Otaniemessä ja Tapiolassa osin vanhentuneita Espoon lokakuun 2026 maksumuutosten takia. `PAID_STREETS` paikkaa tämän, mutta pysyvä korjaus on päivittää tagit OSM:ään. Kun se on tehty, listan voi purkaa.
- Kadunvarsimerkki on katuosuuden keskellä eikä kerro, kummalla puolella katua pysäköinti on sallittu ("vain toinen puoli"), koska OSM:n vasen/oikea riippuu siitä, mihin suuntaan katu on piirretty.

- Lisäyksiä ei ole rajoitettu: kuka tahansa voi skriptillä luoda paljon anonyymejä tunnuksia ja paikkoja. Jos roskaa alkaa tulla, lisää CAPTCHA anonyymiin kirjautumiseen.
- Haku palauttaa enintään 1000 riviä (Supabasen oletus). Kun paikkoja on enemmän, hae vain kartalla näkyvältä alueelta.
- Uudet paikat näkyvät muille vasta, kun he lataavat sivun uudelleen (ei Realtime-tilausta).
- Supabasen ilmaisprojekti menee tauolle, jos sitä ei käytetä viikkoon.
- Jos anonyymi käyttäjä tyhjentää selaimensa tiedot, hän ei voi enää poistaa omia paikkojaan. Paikat jäävät, ja ne voi poistaa hallintapaneelista.
