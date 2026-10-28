#!/usr/bin/env bash
# ck 하네스 설치: 작업 폴더 루트에서 `bash .ck/boot.sh` 로 실행한다.
# 기존 파일은 덮어쓰지 않는다 (AGENTS.md만 예외적으로 뒤에 덧붙임).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
MARK="<!-- ck-harness -->"

if [ "$SRC" = "$DEST" ]; then
  echo "[ck] 작업 폴더 루트에서 실행하세요: bash .ck/boot.sh" >&2
  exit 1
fi

SKIPPED=()

# 파일 하나 복사 (대상이 있으면 건너뜀)
copy_file() {
  local from="$1" to="$2"
  if [ -e "$to" ]; then
    SKIPPED+=("$to")
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

# 1. AGENTS.md: 없으면 복사, 있으면 표식과 함께 뒤에 덧붙임
if [ ! -e AGENTS.md ]; then
  { echo "$MARK"; cat "$SRC/AGENTS.md"; } > AGENTS.md
elif ! grep -qF "$MARK" AGENTS.md; then
  { echo; echo "$MARK"; cat "$SRC/AGENTS.md"; } >> AGENTS.md
  echo "[ck] 기존 AGENTS.md 뒤에 하네스 규칙을 덧붙였습니다."
fi

# 2. Codex 설정·스킬·스크립트
copy_tree "$SRC/.codex"   "$DEST/.codex"
copy_tree "$SRC/.agents"  "$DEST/.agents"
copy_tree "$SRC/scripts"  "$DEST/scripts"
chmod +x "$DEST"/scripts/*.sh 2>/dev/null || true

# 3. 문서 템플릿과 검증 뼈대
copy_tree "$SRC/templates/docs"   "$DEST/docs"
copy_tree "$SRC/templates/verify" "$DEST/verify"

# 4. 출처 기록
URL="$(git -C "$SRC" remote get-url origin 2>/dev/null || echo unknown)"
REV="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
mkdir -p docs
cat > docs/HARNESS.md <<EOF
# 하네스 출처

- 저장소: $URL
- 커밋: $REV
- 설치 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')
- 내용: 작업 규칙(AGENTS.md), Skill 7종, 커스텀 에이전트 2종, 문서 템플릿, 점검 스크립트, 빈 검증 뼈대
- 과제 해답·도메인 로직·앱 코드는 포함하지 않음
EOF

# 5. 클론 폴더 정리 (작업 폴더 바로 아래의 .ck 일 때만)
if [ "$(basename "$SRC")" = ".ck" ] && [ "$(dirname "$SRC")" = "$DEST" ]; then
  rm -rf "$SRC"
fi

# 6. git 초기화와 커밋 (하네스 파일만)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
fi
git config user.name  >/dev/null 2>&1 || git config user.name  "candidate"
git config user.email >/dev/null 2>&1 || git config user.email "candidate@localhost"

PATHS=(AGENTS.md .codex .agents scripts docs verify)
git add -- "${PATHS[@]}" 2>/dev/null || true
if git diff --cached --quiet; then
  echo "[ck] 커밋할 변경이 없습니다."
else
  git commit -q -m "chore: 작업 하네스 적용 (ck $REV)"
  echo "[ck] 커밋 완료: $(git log -1 --oneline)"
fi

if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "[ck] 이미 있어서 건너뛴 파일:"
  printf '  - %s\n' "${SKIPPED[@]}"
fi

# 7. 환경 점검
bash scripts/preflight.sh || true

echo
echo "[ck] 설치 끝. 다음: codex 실행 → /model, /status 확인 → \$intake-interview"
