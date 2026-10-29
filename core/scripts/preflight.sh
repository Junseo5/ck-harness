#!/usr/bin/env bash
# 환경 점검: 런타임·패키지 도구·서버 바인딩·자원 상태를 한 번에 확인한다.
# 실행: bash .harness/preflight.sh
set -u

ver() {
  local name="$1"; shift
  if command -v "$name" >/dev/null 2>&1; then
    printf '  %-8s %s\n' "$name" "$("$@" 2>&1 | head -n 1)"
  else
    printf '  %-8s (없음)\n' "$name"
  fi
}

echo "[preflight] 런타임·도구"
ver python3 python3 --version
ver pip     pip --version
ver node    node --version
ver npm     npm --version
ver git     git --version
ver codex   codex --version
ver curl    curl --version

echo "[preflight] OpenAI 환경 변수 (값은 출력하지 않음)"
if env | grep -qi '^openai'; then echo "  있음"; else echo "  없음"; fi

echo "[preflight] 0.0.0.0 바인딩 테스트 (포트 8765)"
if command -v python3 >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  python3 -m http.server 8765 --bind 0.0.0.0 >/dev/null 2>&1 &
  PID=$!
  sleep 1
  CODE="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8765/ || echo 000)"
  kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
  echo "  응답 코드: $CODE (200이면 정상)"
else
  echo "  python3 또는 curl이 없어 건너뜀"
fi

echo "[preflight] 자원"
if command -v free >/dev/null 2>&1; then
  free -m | awk 'NR==2 {printf "  메모리: 사용 %sMB / 전체 %sMB\n", $3, $2}'
fi
df -h . 2>/dev/null | awk 'NR==2 {printf "  디스크: 남은 %s / 전체 %s\n", $4, $2}'
echo "  CPU 코어: $(nproc 2>/dev/null || echo '?')"

echo "[preflight] git"
git config user.name  >/dev/null 2>&1 && echo "  user.name: $(git config user.name)" || echo "  user.name 없음"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "  저장소: $(git log -1 --oneline 2>/dev/null || echo '커밋 없음')" || echo "  git 저장소 아님"
