#!/usr/bin/env bash
# 스모크 테스트: 프로젝트 유형을 감지해 테스트를 돌리고, URL을 주면 응답 코드를 확인한다.
# 실행: bash scripts/smoke.sh [http://127.0.0.1:포트/경로 ...]
set -u
FAIL=0

if [ -f package.json ]; then
  if grep -q '"test"' package.json; then
    echo "[smoke] npm test"
    npm test --silent || FAIL=1
  else
    echo "[smoke] package.json에 test 스크립트 없음"
  fi
fi

if [ -f pyproject.toml ] || [ -f requirements.txt ] || ls tests/*.py test_*.py >/dev/null 2>&1; then
  if python3 -c 'import pytest' >/dev/null 2>&1; then
    echo "[smoke] pytest"
    python3 -m pytest -q || FAIL=1
  else
    echo "[smoke] pytest 없음 → unittest"
    python3 -m unittest discover -q || FAIL=1
  fi
fi

for url in "$@"; do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' "$url" || echo 000)"
  echo "[smoke] $url → $CODE"
  case "$CODE" in 2*|3*) ;; *) FAIL=1 ;; esac
done

if [ "$FAIL" -eq 0 ]; then echo "[smoke] OK"; else echo "[smoke] 실패 있음"; fi
exit "$FAIL"
