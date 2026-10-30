#!/usr/bin/env bash
# ck-harness 설치: 작업 폴더에 AGENTS.md와 역할 스킬만 넣는다.
# 실행: 작업 폴더에서 bash /tmp/ck-harness/install.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEST="$(pwd -P)"
MARK="<!-- ck-harness -->"
HOME_REAL="$(cd "${HOME:-/}" 2>/dev/null && pwd -P || true)"

if [ "$SRC" = "$DEST" ] || [ "$DEST" = "/" ]; then
  echo "[ck] 작업 폴더에서 실행하세요: bash $SRC/install.sh" >&2
  exit 1
fi

# AGENTS.md: 없으면 만들고, 있으면 기존 내용을 둔 채 표시 아래만 넣거나 바꾼다
if [ ! -e AGENTS.md ]; then
  { echo "$MARK"; cat "$SRC/AGENTS.md"; } > AGENTS.md
elif grep -qxF "$MARK" AGENTS.md; then
  { awk -v m="$MARK" '$0 == m { exit } { print }' AGENTS.md; echo "$MARK"; cat "$SRC/AGENTS.md"; } > AGENTS.md.new
  mv AGENTS.md.new AGENTS.md
else
  { echo; echo "$MARK"; cat "$SRC/AGENTS.md"; } >> AGENTS.md
fi

# 스킬: 같은 이름의 다른 스킬이 있으면 건드리지 않는다
PATHS=(AGENTS.md)
SKIPPED=()
for dir in "$SRC"/skills/*/; do
  name="$(basename "$dir")"
  to=".agents/skills/$name"
  if [ -e "$to/SKILL.md" ] && ! grep -qF "ck-harness" "$to/SKILL.md"; then
    SKIPPED+=("$name")
    continue
  fi
  mkdir -p "$to"
  cp "$dir/SKILL.md" "$to/SKILL.md"
  PATHS+=("$to/SKILL.md")
done

# git add -A에 캐시·비밀값이 섞이지 않게 이 저장소에서만 제외한다 (작업 폴더에 파일을 만들지 않는다)
exclude_noise() {
  local ex top pat
  ex="$(git rev-parse --git-path info/exclude)" || return 0
  mkdir -p "$(dirname "$ex")" || return 0
  local pats=("node_modules/" "__pycache__/" "*.pyc" ".venv/" "venv/" ".env" ".env.*")
  top="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)" || return 0
  # git 루트가 홈 폴더면 숨김 폴더(.codex 로그인 정보, .cache 등)를 뺀다
  if [ "$top" = "$HOME_REAL" ]; then pats+=("/.*" "!/.agents/" "!/.gitignore" "!/.gitattributes"); fi
  for pat in "${pats[@]}"; do
    grep -qxF -- "$pat" "$ex" 2>/dev/null || printf '%s\n' "$pat" >> "$ex" || return 0
  done
}

# 설치한 파일만 커밋한다. AI 샌드박스가 .git 쓰기를 막으면 실패할 수 있어 설치는 그대로 끝낸다.
REV="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
MSG="chore: 역할 하네스 추가 (ck-harness $REV)"
commit_harness() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -q || return 1
  git config user.name  >/dev/null 2>&1 || git config user.name  "candidate" || return 1
  git config user.email >/dev/null 2>&1 || git config user.email "candidate@localhost" || return 1
  exclude_noise
  git add -f -- "${PATHS[@]}" || return 1
  if git diff --cached --quiet -- "${PATHS[@]}"; then
    echo "[ck] 커밋할 변경이 없습니다."
  else
    git commit -q -m "$MSG" -- "${PATHS[@]}" || return 1
    echo "[ck] 커밋 완료: $(git log -1 --oneline)"
  fi
}
if ! commit_harness; then
  echo "[ck] 커밋하지 못했습니다(.git 쓰기가 막혔을 수 있음). 파일 설치는 끝났습니다."
  echo "     권한을 받아 다시 실행하거나 터미널에서: git add -f AGENTS.md .agents/skills && git commit -m \"$MSG\""
fi

if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "[ck] 같은 이름의 다른 스킬이 있어 건너뜀: ${SKIPPED[*]}"
fi
echo "[ck] 설치 끝: AGENTS.md, .agents/skills/ ($(ls "$SRC/skills" | tr '\n' ' '))"
echo "[ck] 스킬은 Codex가 시작될 때 읽힙니다. 이미 켜져 있으면 종료 후 다시 실행하거나 /new 하세요."
