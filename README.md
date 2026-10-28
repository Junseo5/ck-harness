# ck — Codex 작업 하네스 스타트킷

AI 협업 과제(Cofa-Probe) 응시 당일, 작업 환경에 **작업 절차·규칙·문서 템플릿**을 빠르게 깔기 위한 개인 공개 저장소입니다.

- 들어 있는 것: Codex용 AGENTS.md, Skill 7종, 커스텀 에이전트 2종, 문서 템플릿, 범용 점검 스크립트, 빈 검증 뼈대
- 들어 있지 않은 것: 과제 문제·해답·도메인 로직·앱 코드
- 운영팀 안내에 따라 이 저장소는 2차 예선 결과 통지 전까지 공개 상태를 유지합니다.
- 내용 확정일: 2026-10-30 (이후 수정하지 않음)

## 사용법

작업 폴더 루트에서 한 줄 실행 후 Codex를 켭니다.

```bash
git clone -q --depth 1 https://github.com/Junseo5/ck .ck && bash .ck/boot.sh
codex
```

첫 지시: `$intake-interview`

## 구성

| 경로 | 역할 |
|---|---|
| `AGENTS.md` | Codex가 세션 시작 시 읽는 작업 규칙 |
| `.agents/skills/` | 단계별 절차 (`$이름`으로 호출) |
| `.codex/agents/` | explorer(읽기·요약), verifier(독립 검증) |
| `.codex/config.toml` | 동시 서브에이전트 수 제한 |
| `templates/docs/` | PLAN · COLLAB · DECISIONS · VERIFY · HANDOFF → 설치 시 `docs/` |
| `templates/verify/` | 빈 검증 뼈대 (Python / Node) → 설치 시 `verify/` |
| `scripts/` | `preflight.sh` 환경 점검, `smoke.sh` 테스트·서버 응답 확인 |
| `cards/CARDS.md` | 사람용 시간표·프롬프트 카드 (설치되지 않음) |

`boot.sh`는 기존 파일을 덮어쓰지 않고, 설치 출처(URL·커밋)를 `docs/HARNESS.md`에 남깁니다.
