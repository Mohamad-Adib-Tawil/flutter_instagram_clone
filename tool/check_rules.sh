#!/usr/bin/env bash
# Halalgram static rule checks. Prints OK or the violations; exit 1 on violation.
set -u
shopt -s nullglob
cd "$(dirname "$0")/.."
fail=0
scan() { # $1 description, $2 extended regex, $3.. paths
  local desc="$1" pattern="$2"; shift 2
  [ "$#" -eq 0 ] && return 0
  local out
  out=$(grep -rEn --include='*.dart' --exclude='*.g.dart' --exclude='*.freezed.dart' "$pattern" "$@" 2>/dev/null || true)
  if [ -n "$out" ]; then echo "VIOLATION: $desc"; echo "$out"; fail=1; fi
}
DOMAIN=(lib/features/*/domain)
PRES=(lib/features/*/presentation)
UI=(lib/features/*/presentation lib/core/widgets lib/core/shell)
NO_SUPA=("${DOMAIN[@]}" "${PRES[@]}" lib/core/widgets lib/core/theme lib/core/router lib/core/shell lib/core/utils lib/core/media lib/core/errors lib/core/pagination)
scan "supabase import outside data/di/core-network" "package:supabase_flutter" "${NO_SUPA[@]}"
scan "flutter import in domain" "package:flutter/" "${DOMAIN[@]}"
scan "data layer imported from presentation/domain" "import 'package:halalgram/features/[a-z_]+/data/" "${DOMAIN[@]}" "${PRES[@]}"
scan "hardcoded Text string" "Text\(\s*['\"]" "${UI[@]}"
scan "hardcoded color" "Color\(0x|Colors\.(red|green|blue|white|black|grey|amber|orange|purple|pink|yellow|teal|cyan|indigo|lime|brown|deepOrange|deepPurple|lightBlue|lightGreen|blueGrey)" "${UI[@]}"
scan "numeric literal in EdgeInsets/Gap/SizedBox/radius/fontSize" "EdgeInsets[A-Za-z]*\.[a-zA-Z]+\([^)]*[0-9]|Gap\([0-9]|SizedBox\((width|height): [0-9]|BorderRadius\.circular\([0-9]|fontSize: [0-9]" "${UI[@]}"
scan "non-directional layout" "EdgeInsets\.(only|fromLTRB)\(|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)" "${UI[@]}"
scan "print/debugPrint" "(^|[^a-zA-Z_])(print|debugPrint)\(" lib/core lib/features lib/app.dart lib/bootstrap.dart
if [ -f assets/translations/ar.json ] && [ -f assets/translations/en.json ]; then
  python3 - <<'PY' || fail=1
import json, sys
def keys(d, p=""):
    out = set()
    for k, v in d.items():
        out |= keys(v, f"{p}{k}.") if isinstance(v, dict) else {f"{p}{k}"}
    return out
ar = keys(json.load(open("assets/translations/ar.json", encoding="utf-8")))
en = keys(json.load(open("assets/translations/en.json", encoding="utf-8")))
if ar != en:
    print("VIOLATION: translation keys differ")
    print("missing in en:", sorted(ar - en)); print("missing in ar:", sorted(en - ar))
    sys.exit(1)
PY
fi
[ "$fail" -eq 0 ] && echo "OK"
exit "$fail"
