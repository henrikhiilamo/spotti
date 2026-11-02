#!/bin/sh
# Hakee Otaniemen pysäköintialueet OpenStreetMapista tiedostoon
# data/osm-otaniemi.json. Sovellus näyttää ne heti käynnistyessään, joten
# kartta ei ole tyhjä silloinkaan, kun Overpass-palvelimet eivät vastaa.
#
# Aja projektin juuresta:  sh scripts/update-osm-snapshot.sh
# Kysely vastaa index.html:n searchArea()-funktion kyselyä: jos muutat
# toista, muuta myös toista.
set -e

BBOX='60.175,24.800,60.195,24.850' # etelä,länsi,pohjoinen,itä
QUERY="[out:json][timeout:60];(nwr[\"amenity\"=\"parking\"][\"fee\"=\"no\"]($BBOX);nwr[\"amenity\"=\"parking\"][!\"fee\"]($BBOX););out center tags;"
OUT='data/osm-otaniemi.json'
TMP="$OUT.tmp"

mkdir -p data
for URL in https://overpass-api.de/api/interpreter https://overpass.private.coffee/api/interpreter; do
  echo "Haetaan: $URL"
  if curl -sf -m 90 -A 'Ilmaispaikka/1.0 (https://henrikhiilamo.github.io/ilmaispaikka/)' \
       --data-urlencode "data=$QUERY" "$URL" -o "$TMP" \
     && grep -q '"elements"' "$TMP"; then
    mv "$TMP" "$OUT"
    echo "Tallennettu $OUT ($(grep -o '"type": *"\(node\|way\|relation\)"' "$OUT" | wc -l | tr -d ' ') kohdetta)"
    exit 0
  fi
  echo "Ei vastausta, kokeillaan seuraavaa palvelinta."
done
rm -f "$TMP"
echo "Kumpikaan Overpass-palvelin ei vastannut. Yritä myöhemmin uudelleen." >&2
exit 1
