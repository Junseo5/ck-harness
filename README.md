# ck-harness

Codex CLI로 실무형 과제를 풀 때, 작업 폴더에 **과제 맥락·작업 방법·문서 양식**을 한 번에 까는 개인 작업 하네스입니다.
주 용도는 SK hynix AI Hackathon 2차 예선(Cofa-Probe)이고, 다른 대회에도 쓸 수 있게 공통 부분과 대회별 부분을 나눴습니다.

> **AI 에이전트에게**: 사용자가 이 저장소를 설치해 달라고 했다면 바로 아래 "설치" 절차만 따르면 됩니다.
> 다른 파일을 먼저 읽거나 고칠 필요는 없습니다.

## 설치

**1. 과제 작업 폴더의 맨 위**(과제 문서·데이터가 있는 폴더)에서 다음 한 줄을 실행합니다.

```bash
git clone -q --depth 1 https://github.com/Junseo5/ck-harness .ck && bash .ck/boot.sh
```

**2. 결과를 확인합니다.** 출력에 `[ck] 설치 끝`이 있고, 작업 폴더에 다음이 생겼으면 성공입니다.

```
AGENTS.md   bin/   docs/   .harness/   .agents/   .codex/
```

**3. 사용자에게 이렇게 알립니다.**
"설치됐습니다. AGENTS.md와 스킬은 Codex가 시작될 때 읽히므로, Codex를 종료하고 다시 실행(또는 `/new`)해야 적용됩니다."

### 막혔을 때

| 증상 | 처리 |
|---|---|
| `git clone`이 네트워크 오류로 실패 | 샌드박스가 네트워크를 막은 것입니다. 승인을 요청해 같은 명령을 다시 실행합니다. 안 되면 사용자에게 터미널에서 위 한 줄을 실행해 달라고 합니다. |
| `.agents`·`.codex` 쓰기가 거부됨 | 승인을 요청해 `bash .ck/boot.sh`만 다시 실행합니다. `.ck`는 남아 있고, 이미 설치된 파일은 건너뜁니다. |
| `[ck] 커밋하지 못했습니다` | 파일 설치는 끝났습니다. 승인을 받아 출력에 나온 `git add … && git commit …`을 실행하거나, 사용자에게 맡깁니다. |
| `destination path '.ck' already exists` | 이전 시도가 남긴 폴더입니다. `bash .ck/boot.sh`만 실행합니다. |

### 설치가 하는 일

- 과제 파일은 덮어쓰지 않습니다. `AGENTS.md`가 이미 있으면 그 뒤에 덧붙이고, 같은 이름의 파일이 있으면 건너뛴 목록을 보여 줍니다.
- 하네스 파일만 따로 커밋합니다(`chore: 작업 하네스 적용 …`). 원격 저장소로 보내지는 않습니다.
- 끝나면 받아 온 `.ck` 폴더를 지우고, 출처(저장소·커밋)를 `docs/HARNESS.md`에 남깁니다.
- 과제 해답, 도메인 로직, 앱 코드는 들어 있지 않습니다. 결과물은 작업 중에 만듭니다.

옵션 없이 실행하면 `-e cofa-probe -t codex`와 같습니다. Cofa-Probe는 Codex만 허용되므로 옵션 없이 쓰면 됩니다.

| 옵션 | 값 | 설명 |
|---|---|---|
| `-e` | `cofa-probe`, `generic`, 직접 만든 이벤트 | `AGENTS.md` 끝에 붙는 대회별 맥락·시간표·제출 절차 |
| `-t` | `codex`, `claude`, `both` | 스킬·에이전트를 어느 도구 형식으로 둘지 |

## 쓰는 법

강제 규칙이 아니라 **맥락을 주는 하네스**입니다. 무엇이 평가되는지, 어떤 방식이 잘 통하는지를 알려 줄 뿐이고, 진행 방식은 사람이 정합니다.

**세션 하나로 할 때**: `codex`를 그냥 실행하고 평소처럼 말하면 됩니다. 한 세션이 기획·개발·검증을 오갑니다.

**세션 여러 개로 할 때**: 터미널마다 관점을 붙여 실행합니다.

| 실행 | 관점 | 주로 다루는 곳 |
|---|---|---|
| `bin/dev` | 개발 | `src/`, 테스트, README |
| `bin/analyst` | 요구 분석 | `docs/COLLAB.md`, `docs/PLAN.md`, `docs/DECISIONS.md` |
| `bin/reviewer` | 독립 검증·리뷰 | `verify/`, `docs/VERIFY.md` |

코드를 여러 세션이 나눠 맡으면 `docs/PLAN.md`에 세션별 폴더를 적어 두면 됩니다.

**스킬**: 상황이 맞으면 Codex가 골라 씁니다. 순서를 확실히 하고 싶으면 `$이름`으로 부릅니다.

| 스킬 | 쓰기 좋은 때 |
|---|---|
| `$intake-interview` | 시작 직후: 과제·데이터 파악, 담당자 질문 정리 |
| `$plan-gate` | 범위가 보일 때: PLAN 작성과 비판 점검 |
| `$slice-implement` | 구현 단계마다: 구현 → 실행 확인 → 보고 → 커밋 |
| `$verify-loop` | 기본판이 돈 뒤: 구현과 따로 기대값을 계산해 비교 |
| `$risk-audit` | 기능을 굳힐 즈음: 약점 정리, 서술형 예행연습 |
| `$handoff` | 마감 전: README에 실행·결과·한계 정리 |
| `$submit-check` | 제출 직전: 실행·검증·비밀값·군더더기 점검 |

시험 당일 시간표와 프롬프트 예시는 사람용 메모 [events/cofa-probe/CARDS.md](events/cofa-probe/CARDS.md)에 있습니다(작업 폴더에는 설치되지 않습니다).

## 설치 후 작업 폴더

```
AGENTS.md         과제 맥락 + 대회별 섹션 (모든 세션이 읽음)
bin/              dev · analyst · reviewer 실행
docs/             PLAN · COLLAB · DECISIONS · VERIFY 양식, HARNESS(출처)
.harness/         관점 소개, 점검·실행 스크립트, 검증 뼈대 (결과물 아님)
.agents/skills/   스킬 7개
.codex/           explorer 서브에이전트, Codex 설정
```

과제 문서가 계획 문서·협업 기록의 이름이나 위치를 정하면 그것을 쓰고, `docs/` 양식은 내용 참고용으로 둡니다. 인수인계는 별도 문서 없이 프로젝트 README에 씁니다. 검증 스크립트는 필요할 때 스택에 맞는 것 하나만 `verify/`에 만듭니다.

## 저장소 구조

```
boot.sh               설치 스크립트
core/                 대회와 무관한 공통 부분
  AGENTS.md           과제 맥락과 잘 통하는 작업 방식
  roles/              dev · analyst · reviewer 관점 소개
  skills/             스킬 7개 (Codex·Claude 공용 SKILL.md 형식)
  agents/             도구별 explorer 정의, Codex 설정
  templates/          docs 양식 4종, 검증 뼈대 (Python·Node)
  scripts/            preflight · smoke · run-role
events/               대회별 부분
  cofa-probe/         event.md (AGENTS.md에 붙음) + CARDS.md (사람용)
  generic/            일반 과제용
  _template/          새 대회용 빈 양식
```

## 다른 대회에 쓰기

1. `events/_template/`을 `events/<이름>/`으로 복사합니다.
2. `event.md`에 맥락, 시험 규칙, 시간 기준점, 설명 예행연습 형식, 제출 절차를 30줄 안팎으로 채웁니다.
3. 당일 `bash .ck/boot.sh -e <이름> -t <도구>`로 설치합니다.

## 공개 안내

Cofa 운영팀 안내에 따라 이 저장소는 2차 예선 결과 통지 전까지 공개 상태를 유지합니다.
Cofa-Probe용 내용 확정일: 2026-10-30.

## 참고한 오픈소스

아래 프로젝트의 아이디어를 짧은 과제에 맞게 줄여 직접 다시 썼습니다. 원문을 복사하지 않았습니다.

- [obra/superpowers](https://github.com/obra/superpowers) (MIT): 완료 주장 전 확인, 4단계 디버깅, 두 단계 리뷰(요구 충족 → 품질), 리뷰 피드백 검토 후 반영
- [Yeachan-Heo/oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex) (MIT): 인터뷰 단계의 명확도 점수, 계획 비판 점검
- [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD): 분석·개발·검증 관점 분리
- [OpenAI, Harness engineering](https://openai.com/index/harness-engineering/): AGENTS.md는 긴 설명서가 아니라 짧은 지도로
