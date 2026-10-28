#!/usr/bin/env bash
# 역할 지시문을 이 세션에만 넣어 Codex를 실행한다.
# 실행: bash scripts/codex-role.sh <dev|analyst|reviewer> [codex 인자...]
# AGENTS.md(공통 규칙)는 모든 세션에 들어가고, 역할 파일은 developer_instructions로 이 세션에만 들어간다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE="${1:-}"
FILE="$ROOT/.codex/roles/$ROLE.md"

if [ -z "$ROLE" ] || [ ! -f "$FILE" ]; then
  echo "사용법: bin/dev | bin/analyst | bin/reviewer  (역할 파일: .codex/roles/<역할>.md)" >&2
  exit 1
fi
shift

TEXT="$(cat "$FILE")"
if [[ "$TEXT" == *"'''"* ]]; then
  echo "[ck] 역할 파일에 ''' 가 있으면 TOML 문자열이 깨집니다: $FILE" >&2
  exit 1
fi

cd "$ROOT"
echo "[ck] 역할: $ROLE  (첫 질문으로 \"너의 역할과 쓸 수 있는 폴더를 한 줄로\" 확인 권장)"
exec codex -c "developer_instructions='''${TEXT}'''" "$@"
