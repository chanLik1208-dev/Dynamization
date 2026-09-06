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
trap 'rm -f "$tmp"' EXIT   # set -e 可能在任何一步中止,交給 trap 統一清理

code="$(curl -sL --max-time 30 -H 'Accept: text/markdown' -w '%{http_code}' -o "$tmp" "$url")"

if [ "$code" != "200" ]; then
  echo "取不到 $url (HTTP $code)" >&2
  echo "用 --list 查可用 slug。" >&2
  exit 1
fi

# 去掉行銷區塊,只留技術內容
clean() {
  python3 - "$tmp" <<'PY'
import sys, re
t = open(sys.argv[1], encoding='utf-8', errors='replace').read()

DROP = re.compile(r'(Animate faster with Motion\+|Stay in the loop|production-ready examples'
                  r'|Find & fix animation performance issues|Unlock |Get early access|Presented by)', re.I)
HEADING = re.compile(r'^(#{1,6})\s')
FENCE   = re.compile(r'^\s*(```|~~~)')
AD_LINE = re.compile(r'^\[Presented by\+?\]|^\[Advertise in this space\]')

out = []
in_fence = False       # 圍欄內的 # 是程式碼註解 / CSS 選擇器,不是標題
skip_level = None      # 正在丟棄的區塊層級;None = 不在丟棄中

for line in t.split('\n'):
    if FENCE.match(line):
        in_fence = not in_fence
        if skip_level is None:
            out.append(line)
        continue

    if not in_fence:
        m = HEADING.match(line)
        if m:
            level = len(m.group(1))
            if skip_level is not None and level <= skip_level:
                skip_level = None          # 同層或更上層的標題才結束丟棄
            if skip_level is None and DROP.search(line):
                skip_level = level         # 連同其下所有子區塊一起丟

    if skip_level is not None or (not in_fence and AD_LINE.match(line)):
        continue
    out.append(line)

# 頁尾不在任何標題底下,標題式丟棄抓不到,所以從尾端切。
# 只用 "Motion++One payment" 當截斷點 —— 已驗證它只出現在頁尾。
# 不能用 "\> Newsletter":那是內嵌小工具的標記,會出現在文件中段,
# 拿它截斷會砍掉後半部的正文。
FOOTER = re.compile(r'^Motion\+\+One payment')
NAV    = re.compile(r'^\d+\.\s+\[0\d(Docs|Examples)')
for i, line in enumerate(out):
    if FOOTER.match(line):
        out = out[:i]
        break
while out and (NAV.match(out[-1]) or not out[-1].strip()):   # 連帶去掉頁尾上方的導覽清單
    out.pop()

# 直接寫 UTF-8 bytes:Windows 上 Python 的 stdout 預設走系統 codepage(cp950 等),
# 遇到文件裡的 › — “ 等字元會 UnicodeEncodeError 並輸出空內容。
sys.stdout.buffer.write((re.sub(r'\n{3,}', '\n\n', '\n'.join(out)).rstrip() + '\n').encode('utf-8'))
PY
}

if [ $# -ge 2 ]; then
  clean > "$2"
  echo "已寫入 $2" >&2
else
  clean
fi

rm -f "$tmp"
