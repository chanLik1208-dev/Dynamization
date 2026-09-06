#!/usr/bin/env bash
# 抓 motion.dev 官方文件的 markdown 原文。
#
#   fetch-doc.sh react-transitions           # 印到 stdout
#   fetch-doc.sh react-transitions out.md    # 存檔
#   fetch-doc.sh --list                      # 列出所有可用 slug
#
# 原理:motion.dev 支援內容協商,Accept: text/markdown 會回傳乾淨 markdown。
set -euo pipefail

if [ $# -eq 0 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if [ "$1" = "--list" ]; then
  curl -sL --max-time 30 https://motion.dev/llms.txt \
    | grep -oE 'https://motion\.dev/docs/[a-z0-9-]+' \
    | sed 's#.*/docs/##' | sort -u
  exit 0
fi

slug="${1#https://motion.dev/docs/}"
slug="${slug#/}"
url="https://motion.dev/docs/${slug}"

tmp="$(mktemp)"
code="$(curl -sL --max-time 30 -H 'Accept: text/markdown' -w '%{http_code}' -o "$tmp" "$url")"

if [ "$code" != "200" ]; then
  echo "取不到 $url (HTTP $code)" >&2
  echo "用 --list 查可用 slug。" >&2
  rm -f "$tmp"
  exit 1
fi

# 去掉行銷區塊,只留技術內容
clean() {
  python3 - "$tmp" <<'PY'
import sys, re
t = open(sys.argv[1], encoding='utf-8', errors='replace').read()
drop = re.compile(r'^#{2,4} .*(Animate faster with Motion\+|Stay in the loop|production-ready examples'
                  r'|Find & fix animation performance issues|Unlock |Get early access|Presented by)', re.I)
out, skip = [], False
for l in t.split('\n'):
    if l.startswith('#'):
        skip = bool(drop.match(l))
    if skip or re.match(r'^\[Presented by\+?\]|^\[Advertise in this space\]', l):
        continue
    out.append(l)
sys.stdout.write(re.sub(r'\n{3,}', '\n\n', '\n'.join(out)))
PY
}

if [ $# -ge 2 ]; then
  clean > "$2"
  echo "已寫入 $2" >&2
else
  clean
fi

rm -f "$tmp"
