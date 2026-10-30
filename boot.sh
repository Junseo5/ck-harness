#!/usr/bin/env bash
# ck 하네스 설치: 작업 폴더 루트에서 실행한다.
#   bash .ck/boot.sh                      # 기본: 이벤트 cofa-probe, 도구 codex
#   bash .ck/boot.sh -e generic -t claude # 다른 대회·도구
#   -e <이벤트>  events/ 아래 폴더 이름 (cofa-probe, generic, ...)
#   -t <도구>    codex | claude | both
# 기존 파일은 덮어쓰지 않는다 (AGENTS.md는 뒤에 덧붙임).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
MARK="<!-- ck-harness -->"
EVENT="cofa-probe"
TOOL="codex"

while getopts "e:t:h" opt; do
  case "$opt" in
    e) EVENT="$OPTARG" ;;
    t) TOOL="$OPTARG" ;;
    *) sed -n '2,7p' "$0"; exit 0 ;;
  esac
done

if [ "$SRC" = "$DEST" ]; then
  echo "[ck] 작업 폴더 루트에서 실행하세요: bash .ck/boot.sh" >&2
  exit 1
fi
EVENT_FILE="$SRC/events/$EVENT/event.md"
if [ ! -f "$EVENT_FILE" ]; then
  echo "[ck] 이벤트가 없습니다: $EVENT  (있는 것: $(ls "$SRC/events" | grep -v '^_' | tr '\n' ' '))" >&2
  exit 1
fi
case "$TOOL" in codex|claude|both) ;; *) echo "[ck] -t 는 codex | claude | both" >&2; exit 1 ;; esac
use() { [ "$TOOL" = "$1" ] || [ "$TOOL" = both ]; }

SKIPPED=()
INSTALLED=()
# 시험 환경처럼 홈 폴더가 작업 폴더나 git 루트일 수 있다. ~/.codex에는 로그인 정보와 플랫폼 설정이 있다.
HOME_REAL="$(cd "${HOME:-/}" 2>/dev/null && pwd -P || true)"
AT_HOME=0; [ "$(pwd -P)" = "$HOME_REAL" ] && AT_HOME=1

# 파일 하나 복사 (대상이 있으면 건너뜀)
copy_file() {
  local from="$1" to="$2"
  if [ -e "$to" ]; then
    # 같은 내용이면 이전 설치분으로 보고 커밋 대상에 넣는다 (다시 실행할 때)
    if cmp -s "$from" "$to"; then INSTALLED+=("${to#"$DEST"/}"); else SKIPPED+=("${to#"$DEST"/}"); fi
    return
  fi
  mkdir -p "$(dirname "$to")"
  cp "$from" "$to"
  INSTALLED+=("${to#"$DEST"/}")
}

# 디렉터리 안의 파일을 같은 구조로 복사
copy_tree() {
  local from="$1" to="$2"
  [ -d "$from" ] || return 0
  while IFS= read -r -d '' f; do
    copy_file "$f" "$to/${f#"$from"/}"
  done < <(find "$from" -type f -print0)
}

# 1. AGENTS.md = 공통 규칙 + 이벤트 섹션 (없으면 생성, 있으면 표식과 함께 덧붙임)
build_agents() { echo "$MARK"; cat "$SRC/core/AGENTS.md"; echo; cat "$EVENT_FILE"; }
if [ ! -e AGENTS.md ]; then
  build_agents > AGENTS.md
elif ! grep -qF "$MARK" AGENTS.md; then
  { echo; build_agents; } >> AGENTS.md
  echo "[ck] 기존 AGENTS.md 뒤에 하네스 규칙을 덧붙였습니다."
fi

# 2. 도구 공통: 역할, 스크립트, 실행 스크립트, 문서 템플릿, 검증 뼈대
copy_tree "$SRC/core/roles"            "$DEST/.harness/roles"
copy_tree "$SRC/core/scripts"          "$DEST/.harness"
copy_tree "$SRC/core/templates/docs"   "$DEST/docs"
copy_tree "$SRC/core/templates/verify" "$DEST/.harness/templates"
if use codex; then echo codex > .harness/tool; else echo claude > .harness/tool; fi
mkdir -p bin
for role in dev analyst reviewer; do
  if [ -e "bin/$role" ]; then
    if grep -qF "run-role.sh" "bin/$role"; then INSTALLED+=("bin/$role"); else SKIPPED+=("bin/$role"); fi
    continue
  fi
  INSTALLED+=("bin/$role")
  printf '#!/usr/bin/env bash\n# %s 역할로 AI CLI 실행 (.harness/run-role.sh)\nexec bash "$(dirname "${BASH_SOURCE[0]}")/../.harness/run-role.sh" %s "$@"\n' "$role" "$role" > "bin/$role"
done
chmod +x .harness/*.sh bin/* 2>/dev/null || true

# 3. 도구별 배치
if use codex; then
  copy_tree "$SRC/core/skills"                    "$DEST/.agents/skills"
  # 홈 폴더의 .codex는 전역 설정 폴더이므로 건드리지 않는다
  if [ "$AT_HOME" = 0 ]; then
    copy_file "$SRC/core/agents/codex/explorer.toml" "$DEST/.codex/agents/explorer.toml"
    copy_file "$SRC/core/agents/codex/config.toml"   "$DEST/.codex/config.toml"
  fi
fi
if use claude; then
  copy_tree "$SRC/core/skills"                    "$DEST/.claude/skills"
  copy_file "$SRC/core/agents/claude/explorer.md"  "$DEST/.claude/agents/explorer.md"
  # CLAUDE.md는 AGENTS.md를 가져오기만 한다 (내용은 한 곳에서 관리)
  if [ ! -e CLAUDE.md ]; then
    echo "@AGENTS.md" > CLAUDE.md
  elif ! grep -qxF "@AGENTS.md" CLAUDE.md; then
    { echo; echo "@AGENTS.md"; } >> CLAUDE.md
  fi
fi

# 4. 출처 기록
URL="$(git -C "$SRC" remote get-url origin 2>/dev/null || echo unknown)"
REV="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
cat > docs/HARNESS.md <<EOF
# 하네스 출처

- 저장소: $URL
- 커밋: $REV
- 이벤트: $EVENT · 도구: $TOOL
- 설치 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')
- 내용: 공통 규칙과 이벤트 규칙(AGENTS.md), 역할 지시문 3종(dev·analyst·reviewer), Skill 7종, 읽기 전용 서브에이전트 1종, 문서 템플릿, 점검 스크립트, 빈 검증 뼈대
- 과제 해답·도메인 로직·앱 코드는 포함하지 않음
EOF

# 5. 사람용 카드는 작업 폴더에 넣지 않고 경로만 안내한다
CARDS="$SRC/events/$EVENT/CARDS.md"
HAS_CARDS=0; [ -f "$CARDS" ] && HAS_CARDS=1

# 6. git 커밋 (하네스 파일만). AI 샌드박스가 .git 쓰기를 막으면 실패할 수 있어 설치는 계속한다.
PATHS=(AGENTS.md docs/HARNESS.md .harness/tool .harness/installed.txt "${INSTALLED[@]}")
[ -e CLAUDE.md ] && PATHS+=(CLAUDE.md)
printf '%s
' "${PATHS[@]}" > .harness/installed.txt
MSG="chore: 작업 하네스 적용 (ck $REV, $EVENT, $TOOL)"
# 나중에 git add -A를 해도 캐시·비밀값이 섞이지 않게, 작업 폴더에 파일을 만들지 않고 이 저장소에서만 제외한다.
exclude_noise() {
  local ex top
  ex="$(git rev-parse --git-path info/exclude)" || return 0
  mkdir -p "$(dirname "$ex")" || return 0
  local pats=(".ck/" "node_modules/" "__pycache__/" "*.pyc" ".venv/" "venv/" ".env" ".env.*")
  top="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)" || return 0
  # git 루트가 홈 폴더면 숨김 폴더(.codex, .cache 등)를 뺀다
  [ "$top" = "$HOME_REAL" ] && pats+=("/.*" "!/.agents/" "!/.harness/" "!/.gitignore" "!/.gitattributes")
  local pat
  for pat in "${pats[@]}"; do
    grep -qxF -- "$pat" "$ex" 2>/dev/null || printf '%s
' "$pat" >> "$ex" || return 0
  done
}
commit_harness() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -q || return 1
  git config user.name  >/dev/null 2>&1 || git config user.name  "candidate" || return 1
  git config user.email >/dev/null 2>&1 || git config user.email "candidate@localhost" || return 1
  exclude_noise
  git add -f -- "${PATHS[@]}" || return 1
  if git diff --cached --quiet; then
    echo "[ck] 커밋할 변경이 없습니다."
  else
    git commit -q -m "$MSG" || return 1
    echo "[ck] 커밋 완료: $(git log -1 --oneline)"
  fi
}
COMMIT_OK=0
commit_harness && COMMIT_OK=1
if [ "$COMMIT_OK" = 0 ]; then
  echo "[ck] 커밋하지 못했습니다(.git 쓰기가 막혔을 수 있음). 파일 설치는 끝났습니다."
  echo "     권한을 받아 다시 실행하거나 터미널에서: git add -f --pathspec-from-file=.harness/installed.txt && git commit -m \"$MSG\""
fi

# 7. 클론 폴더 정리 (작업 폴더 바로 아래의 .ck 일 때만)
if [ "$(basename "$SRC")" = ".ck" ] && [ "$(dirname "$SRC")" = "$DEST" ]; then
  rm -rf "$SRC"
fi

if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "[ck] 이미 있어서 건너뛴 파일:"
  printf '  - %s\n' "${SKIPPED[@]}"
fi

# 8. 환경 점검
bash .harness/preflight.sh || true

if use codex; then P='$'; else P='/'; fi
echo
echo "[ck] 설치 끝 (이벤트: $EVENT, 도구: $TOOL)"
echo "  터미널 1: bin/dev"
echo "  터미널 2: bin/analyst → ${P}intake-interview  (기본판 이후 bin/reviewer → ${P}verify-loop)"
[ "$HAS_CARDS" = 1 ] && echo "  사람용 카드: 저장소의 events/$EVENT/CARDS.md"
[ "$AT_HOME" = 1 ] && echo "  작업 폴더가 홈 폴더라 ~/.codex(로그인·플랫폼 설정)는 건드리지 않았습니다."
echo
echo "[ck] 중요: AGENTS.md와 스킬은 AI 세션이 시작될 때 읽힙니다."
echo "     이미 켜져 있는 Codex라면 종료 후 다시 실행해야(또는 /new) 적용됩니다."
exit 0
