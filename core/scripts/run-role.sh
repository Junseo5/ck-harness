#!/usr/bin/env bash
# 역할 지시문을 이 세션에만 넣어 AI CLI를 실행한다.
# 실행: bin/<dev|analyst|reviewer> [CLI 인자...]   (도구 변경: CK_TOOL=claude bin/dev)
# AGENTS.md(공통 규칙 + 이벤트)는 모든 세션에 들어가고, 역할 파일은 이 세션에만 들어간다.
#   codex  → -c developer_instructions='''...'''
#   claude → --append-system-prompt "..."
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE="${1:-}"
FILE="$ROOT/.harness/roles/$ROLE.md"
TOOL="${CK_TOOL:-$(cat "$ROOT/.harness/tool" 2>/dev/null || echo codex)}"

if [ -z "$ROLE" ] || [ ! -f "$FILE" ]; then
  echo "사용법: bin/dev | bin/analyst | bin/reviewer  (역할 파일: .harness/roles/<역할>.md)" >&2
  exit 1
fi
shift

TEXT="$(cat "$FILE")"
cd "$ROOT"
echo "[ck] 역할: $ROLE · 도구: $TOOL  (첫 질문으로 \"너의 역할과 쓸 수 있는 폴더를 한 줄로\" 확인 권장)"

case "$TOOL" in
  codex)
    if [[ "$TEXT" == *"'''"* ]]; then
      echo "[ck] 역할 파일에 ''' 가 있으면 TOML 문자열이 깨집니다: $FILE" >&2
      exit 1
    fi
    # 비대화형(exec)에서는 -c가 하위 명령 뒤에 와야 적용된다: bin/dev exec "..."
    SUB=()
    if [ "${1:-}" = "exec" ] || [ "${1:-}" = "e" ]; then SUB=("$1"); shift; fi
    exec codex ${SUB[@]+"${SUB[@]}"} -c "developer_instructions='''${TEXT}'''" "$@"
    ;;
  claude)
    exec claude --append-system-prompt "$TEXT" "$@"
    ;;
  *)
    echo "[ck] 지원하지 않는 도구: $TOOL (codex | claude)" >&2
    exit 1
    ;;
esac
