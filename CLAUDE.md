# Ilmaispaikka

Verkkosovellus, joka näyttää ilmaiset pysäköintipaikat kartalla, aluksi Aalto-yliopiston Otaniemen alueella.

Harjoitusprojekti: omistaja opettelee rakentamaan ja julkaisemaan sovelluksen ja hankkimaan sille käyttäjiä.
- Selitä tekemäsi muutokset lyhyesti, omistaja haluaa oppia.
- Kysy ennen kuin asennat mitään (npm-paketit, CLI-työkalut, uudet CDN-kirjastot).

## Rakenne

- `index.html` on koko sovellus: HTML, CSS ja JavaScript samassa tiedostossa. Ei build-vaihetta eikä npm:ää.
- Kirjastot ladataan CDN:stä tarkalla versionumerolla (Leaflet 1.9.4 cdnjs:stä).

## Ajaminen

```bash
python3 -m http.server 8000
```

Avaa http://localhost:8000. Sivua ei voi avata suoraan tiedostona (`file://`), koska karttapohja ja haut vaativat http-palvelimen.

## Tietolähteet

- Karttapohja: OpenStreetMapin tiilet. Jos ne eivät lataudu, vaihdetaan automaattisesti Esri World Street Mapiin.
- OSM-pysäköintialueet haetaan Overpass API:lla (kaksi palvelinta, toinen varalla):
  - `amenity=parking` + `fee=no` → ilmainen
  - `amenity=parking` ilman `fee`-tagia → hinta tuntematon
  - pois suodatetaan `access` = private, customers, permit, delivery, no, residents
  - haku vain zoomilla ≥ 14, tulos välimuistiin localStorageen 24 tunniksi
- Käyttäjien lisäämät paikat: localStorage (vain omassa selaimessa).

## Koodityyli

- Vanilla JS ES5-tyyliin (`var`, `function`, `.then`-ketjut) yhden IIFE:n sisällä. Ei frameworkkia.
- OSM:n ja käyttäjien teksti näytetään aina `textContent`illa, ei koskaan `innerHTML`:llä, ettei kukaan voi syöttää sivulle HTML:ää tai skriptejä.
- Käyttöliittymän tekstit suomeksi.

## Päätökset

- 2026-11-02: Projekti Git-repoksi, päähaara `main`. Commit-nimi ja -sähköposti on asetettu vain tähän repoon (`git config`, ei `--global`).
