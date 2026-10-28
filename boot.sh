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

# 파일 하나 복사 (대상이 있으면 건너뜀)
copy_file() {
  local from="$1" to="$2"
  if [ -e "$to" ]; then
    SKIPPED+=("${to#"$DEST"/}")
    return
  fi
  mkdir -p "$(dirname "$to")"
  cp "$from" "$to"
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
  [ -e "bin/$role" ] && { SKIPPED+=("bin/$role"); continue; }
  printf '#!/usr/bin/env bash\n# %s 역할로 AI CLI 실행 (.harness/run-role.sh)\nexec bash "$(dirname "${BASH_SOURCE[0]}")/../.harness/run-role.sh" %s "$@"\n' "$role" "$role" > "bin/$role"
done
chmod +x .harness/*.sh bin/* 2>/dev/null || true

# 3. 도구별 배치
if use codex; then
  copy_tree "$SRC/core/skills"                    "$DEST/.agents/skills"
  copy_file "$SRC/core/agents/codex/explorer.toml" "$DEST/.codex/agents/explorer.toml"
  copy_file "$SRC/core/agents/codex/config.toml"   "$DEST/.codex/config.toml"
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

# 6. 클론 폴더 정리 (작업 폴더 바로 아래의 .ck 일 때만)
if [ "$(basename "$SRC")" = ".ck" ] && [ "$(dirname "$SRC")" = "$DEST" ]; then
  rm -rf "$SRC"
fi

# 7. git 초기화와 커밋 (하네스 파일만)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
fi
git config user.name  >/dev/null 2>&1 || git config user.name  "candidate"
git config user.email >/dev/null 2>&1 || git config user.email "candidate@localhost"

PATHS=()
for p in AGENTS.md CLAUDE.md .harness .agents .codex .claude bin docs; do
  [ -e "$p" ] && PATHS+=("$p")
done
git add -- "${PATHS[@]}"
if git diff --cached --quiet; then
  echo "[ck] 커밋할 변경이 없습니다."
else
  git commit -q -m "chore: 작업 하네스 적용 (ck $REV, $EVENT, $TOOL)"
  echo "[ck] 커밋 완료: $(git log -1 --oneline)"
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
exit 0
