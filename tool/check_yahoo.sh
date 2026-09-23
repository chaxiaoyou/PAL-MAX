#!/usr/bin/env bash
# Checks the Yahoo Finance endpoints this app depends on, from whatever network
# you run it on.
#
# Why this exists: the endpoints are region-blocked from mainland China, so they
# could not be exercised from the machine this app was built on. Everything the
# app parses is pinned by unit tests against recorded payloads, but the live
# shapes have not been seen. Run this from the network your users are on (a US
# connection, or a working VPN) and paste the output.
#
# Usage:  ./tool/check_yahoo.sh [symbol]

set -u

SYMBOL="${1:-AAPL}"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
JAR="$(mktemp -d)/cookies.txt"

say() { printf '\n=== %s ===\n' "$1"; }
code() { curl -s -m 20 -o /dev/null -w '%{http_code}' "$@"; }

say "1. crumb bootstrap (quotes need cookies + crumb)"
curl -s -m 20 -c "$JAR" -A "$UA" "https://fc.yahoo.com" -o /dev/null
CRUMB="$(curl -s -m 20 -b "$JAR" -c "$JAR" -A "$UA" "https://query1.finance.yahoo.com/v1/test/getcrumb")"
if [ -z "$CRUMB" ] || [ "${#CRUMB}" -gt 64 ]; then
  echo "FAILED: no crumb. Yahoo is blocking this network; nothing below will work."
  echo "        (first 80 chars: $(printf '%s' "$CRUMB" | head -c 80))"
  exit 1
fi
echo "OK: crumb length ${#CRUMB}"

say "2. v7 quote — what the watchlist and portfolio read"
curl -s -m 20 -b "$JAR" -A "$UA" \
  "https://query1.finance.yahoo.com/v7/finance/quote?format=json&symbols=${SYMBOL}&crumb=${CRUMB}" \
  | head -c 600
echo
echo "expected fields: symbol, shortName, regularMarketPrice, regularMarketChange,"
echo "                 regularMarketChangePercent, currency, marketState"

say "3. v8 chart with events=div — what price history AND dividends read"
curl -s -m 20 -b "$JAR" -A "$UA" \
  "https://query1.finance.yahoo.com/v8/finance/chart/${SYMBOL}?range=2y&interval=1mo&events=div" \
  | head -c 900
echo
echo "expected: chart.result[0].timestamp + indicators.quote[0].close (the chart),"
echo "          chart.result[0].events.dividends['<ts>'].{amount,date} (the dividends)"

say "4. symbol search — what the add-symbol and alert pickers use"
curl -s -m 20 -b "$JAR" -A "$UA" \
  "https://query2.finance.yahoo.com/v1/finance/search?q=${SYMBOL}&quotesCount=5&newsCount=0" \
  | head -c 400
echo
echo "expected: quotes[] with symbol / shortname / exchDisp / typeDisp"

say "5. HTTP status summary"
for path in \
  "https://query1.finance.yahoo.com/v7/finance/quote?format=json&symbols=${SYMBOL}&crumb=${CRUMB}" \
  "https://query1.finance.yahoo.com/v8/finance/chart/${SYMBOL}?range=1d&interval=1d" \
  "https://query2.finance.yahoo.com/v1/finance/search?q=${SYMBOL}&quotesCount=5" \
  "https://feeds.finance.yahoo.com/rss/2.0/headline?s=${SYMBOL}&region=US&lang=en-US"
do
  printf '%s -> %s\n' "$(code -b "$JAR" -A "$UA" "$path")" "$(printf '%s' "$path" | cut -c1-72)"
done

rm -rf "$(dirname "$JAR")"
