# ck — AI 협업 과제용 작업 하네스

대회·과제 당일, 작업 폴더에 **역할·규칙·절차·문서 템플릿**을 한 줄로 까는 개인 공개 저장소입니다.
현재 주 용도는 Cofa-Probe(Codex CLI) 과제이고, 다른 대회·도구에도 쓸 수 있도록 공통 부분과 대회별 부분을 나눴습니다.

- 들어 있는 것: 공통 규칙, 세션별 역할 지시문 3종, Skill 7종, 읽기 전용 서브에이전트, 문서 템플릿, 범용 점검 스크립트, 빈 검증 뼈대
- 들어 있지 않은 것: 과제 문제·해답·도메인 로직·앱 코드
- Cofa 운영팀 안내에 따라 이 저장소는 2차 예선 결과 통지 전까지 공개 상태를 유지합니다.
- Cofa-Probe 용 내용 확정일: 2026-10-30

## 설치

작업 폴더 루트에서:

```bash
git clone -q --depth 1 https://github.com/Junseo5/ck .ck && bash .ck/boot.sh
```

옵션 없이 실행하면 `-e cofa-probe -t codex` 와 같습니다.

| 옵션 | 값 | 설명 |
|---|---|---|
| `-e` | `cofa-probe`, `generic`, 직접 만든 이벤트 | AGENTS.md 끝에 붙는 대회별 맥락·규칙·기준점·제출 절차 |
| `-t` | `codex`, `claude`, `both` | 스킬·에이전트를 어느 도구 형식으로 둘지 |

## 세션 실행

| 터미널 | 실행 | 역할 |
|---|---|---|
| 1 | `bin/dev` | 시니어 개발자: 승인된 계획을 한 단계씩 구현 (`src/`) |
| 2 (초반) | `bin/analyst` | 요구 분석: 질문 준비, 답을 범위·기준·가정으로 정리 (`docs/`) |
| 2 (기본판 이후) | `bin/reviewer` | 독립 검증과 두 단계 리뷰: 요구 충족 → 코드 품질 (`verify/`) |

`AGENTS.md`(공통 + 이벤트)는 모든 세션이 읽고, 역할 지시문은 그 세션에만 들어갑니다.

| 도구 | 공통 규칙 | 역할 주입 | 스킬 | 서브에이전트 |
|---|---|---|---|---|
| Codex CLI | `AGENTS.md` | `-c developer_instructions` | `.agents/skills/` (`$이름`) | `.codex/agents/explorer.toml` |
| Claude Code | `CLAUDE.md` → `@AGENTS.md` | `--append-system-prompt` | `.claude/skills/` (`/이름`) | `.claude/agents/explorer.md` |

`-t both`로 설치하면 `CK_TOOL=claude bin/dev`처럼 세션마다 도구를 바꿀 수 있습니다.

## 저장소 구조

```
core/                 # 대회와 무관한 공통 부분
  AGENTS.md           # 공통 규칙
  roles/              # dev · analyst · reviewer 역할 지시문
  skills/             # 7종 (Codex·Claude 공용 SKILL.md 형식)
  agents/codex|claude # 도구별 explorer 정의, Codex 설정
  templates/          # docs/ 문서 템플릿 4종, verify/ 검증 뼈대 (Python·Node 중 하나만 사용)
  scripts/            # preflight · smoke · run-role → 설치 시 .harness/
events/               # 대회별 부분
  cofa-probe/         # event.md (AGENTS.md에 붙음) + CARDS.md (사람용, 설치 안 됨)
  generic/            # 시간 비율 기준의 일반 과제
  _template/          # 새 대회용 빈 양식
boot.sh
```

## 설치 후 작업 폴더

결과물과 작업 도구가 섞이지 않도록, 하네스는 아래만 남깁니다.

```
AGENTS.md            공통 규칙 + 이벤트 (Claude 설치 시 CLAUDE.md 추가)
bin/                 dev · analyst · reviewer 실행
docs/                PLAN · COLLAB · DECISIONS · VERIFY (+ HARNESS 출처)
.harness/            역할 지시문, 점검·실행 스크립트, 검증 뼈대
.agents/ .codex/     스킬, explorer, Codex 설정 (Claude는 .claude/)
```

인수인계는 별도 문서 없이 프로젝트 README에 쓰고, 검증 스크립트는 필요할 때 스택에 맞는 것 하나만 `verify/`에 만듭니다.
제출 전 `$submit-check`가 쓰지 않은 파일과 빈 템플릿을 찾아 정리합니다.

## 새 대회에 쓰기

1. `events/_template/`을 `events/<이름>/`으로 복사합니다.
2. `event.md`에 맥락, 추가 규칙, 기준점, 설명 예행연습 형식, 제출 절차를 30줄 안팎으로 채웁니다.
3. 필요하면 사람용 `CARDS.md`를 둡니다.
4. 당일 `bash .ck/boot.sh -e <이름> -t <도구>`로 설치합니다.

공통 규칙·역할·스킬은 이벤트 섹션의 "기준점", "설명 예행연습 형식", "제출 절차"를 참조하도록 만들어 두었습니다.

## 참고한 오픈소스

아래 프로젝트의 아이디어를 짧은 과제에 맞게 줄여 직접 다시 썼습니다. 원문을 복사하지 않았습니다.

- [obra/superpowers](https://github.com/obra/superpowers) (MIT): 완료 주장 전 증명, 4단계 디버깅, 두 단계 리뷰(요구 충족 → 품질), 리뷰 피드백을 검토 후 반영
- [Yeachan-Heo/oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex) (MIT): 인터뷰 단계의 명확도 점수, 계획에 대한 비판(critic) 점검
- [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD): 분석·개발·QA 역할 분리
- [OpenAI, Harness engineering](https://openai.com/index/harness-engineering/): AGENTS.md는 긴 설명서가 아니라 짧은 지도로
