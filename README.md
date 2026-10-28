# ck — Codex 작업 하네스 스타트킷

AI 협업 과제(Cofa-Probe) 응시 당일, 작업 환경에 **작업 절차·역할·규칙·문서 템플릿**을 빠르게 깔기 위한 개인 공개 저장소입니다.

- 들어 있는 것: 공통 규칙(AGENTS.md), 세션별 역할 지시문 3종, Skill 7종, 읽기 전용 서브에이전트 1종, 문서 템플릿, 범용 점검 스크립트, 빈 검증 뼈대
- 들어 있지 않은 것: 과제 문제·해답·도메인 로직·앱 코드
- 운영팀 안내에 따라 이 저장소는 2차 예선 결과 통지 전까지 공개 상태를 유지합니다.
- 내용 확정일: 2026-10-30 (이후 수정하지 않음)

## 사용법

작업 폴더 루트에서 설치한 뒤, 터미널마다 역할을 골라 Codex를 실행합니다.

```bash
git clone -q --depth 1 https://github.com/Junseo5/ck .ck && bash .ck/boot.sh
```

| 터미널 | 실행 | 역할 |
|---|---|---|
| 1 | `bin/dev` | 시니어 개발자: 승인된 계획을 한 단계씩 구현 (`src/`) |
| 2 (0:00~) | `bin/analyst` | 요구 분석: 담당자 질문 준비, 답을 범위·기준·가정으로 정리 (`docs/`) |
| 2 (1:30~) | `bin/reviewer` | 독립 검증과 두 단계 리뷰: 요구 충족 → 코드 품질 (`verify/`) |

## 역할을 세션별로 나누는 방식

- `AGENTS.md`: 모든 세션이 읽는 공통 규칙 (과제 맥락, 파일 소유권, 문서, 환경)
- `.codex/roles/<역할>.md`: `bin/<역할>`이 `codex -c developer_instructions=...`로 **그 세션에만** 넣는 역할 지시문

한 컨텍스트에 모든 역할을 섞지 않기 위한 구조입니다. Codex 내장 시스템 프롬프트는 바꾸지 않습니다.

## 구성

| 경로 | 역할 |
|---|---|
| `AGENTS.md` | 공통 규칙 |
| `roles/` | 역할 지시문 → 설치 시 `.codex/roles/` |
| `bin/` | 역할별 실행 스크립트 |
| `.agents/skills/` | 단계별 절차 (`$이름`으로 호출) |
| `.codex/agents/explorer.toml` | 읽기 전용 조사 서브에이전트 |
| `.codex/config.toml` | 동시 서브에이전트 수 제한 (신뢰한 프로젝트에서만 적용) |
| `templates/docs/` | PLAN · COLLAB · DECISIONS · VERIFY · HANDOFF → 설치 시 `docs/` |
| `templates/verify/` | 빈 검증 뼈대 (Python / Node) → 설치 시 `verify/` |
| `scripts/` | `preflight.sh` 환경 점검, `smoke.sh` 테스트·응답 확인, `codex-role.sh` 역할 실행 |
| `cards/CARDS.md` | 사람용 시간표·프롬프트 카드 (설치되지 않음) |

`boot.sh`는 기존 파일을 덮어쓰지 않고, 설치 출처(URL·커밋)를 `docs/HARNESS.md`에 남깁니다.

## 참고한 오픈소스

아래 프로젝트의 아이디어를 3시간 과제에 맞게 줄여 직접 다시 썼습니다. 원문을 복사하지 않았습니다.

- [obra/superpowers](https://github.com/obra/superpowers) (MIT): 완료 주장 전 증명, 4단계 디버깅, 두 단계 리뷰(요구 충족 → 품질), 리뷰 피드백을 검토 후 반영
- [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex): 인터뷰 단계의 명확도 점수, 계획에 대한 비판(critic) 점검
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD): 분석·개발·QA 역할 분리
- [OpenAI, Harness engineering](https://openai.com/index/harness-engineering/): AGENTS.md는 긴 설명서가 아니라 짧은 지도로
