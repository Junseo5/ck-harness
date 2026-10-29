---
name: submit-check
description: 제출 직전 최종 점검. 테스트·검증 재실행, git 상태, 비밀값, 서버 바인딩, 문서 완결성, 쓰지 않은 템플릿·임시 파일을 확인하고 체크리스트로 보고한다. 마감 직전이라 새 기능보다 점검이 목적이다.
---

# submit-check

마감 직전에 새 기능을 넣으면 검증·문서와 어긋나기 쉽다. 금방 고칠 수 있는 문제는 제안하고, 나머지는 README의 "한계와 위험"에 적는다.

## 점검 (실행하고 결과를 표로)
| 항목 | 방법 |
|---|---|
| 테스트 | `bash .harness/smoke.sh` |
| 독립 검증 | `verify/` 아래 검증 스크립트 실행 |
| 실행 방법 | README의 실행 명령을 그대로 실행해 동작 확인 |
| 서버 바인딩 | 코드에서 `0.0.0.0` 사용 확인, `127.0.0.1`/`localhost` 고정 여부 검색 |
| 비밀값 | `grep -rInE "(api[_-]?key|secret|token|password)\s*[:=]" --exclude-dir={node_modules,.git,.venv} .` |
| 남은 TODO | `grep -rn "TODO\|FIXME" --exclude-dir={node_modules,.git,.venv,.harness} .` |
| 디버그 출력 | 불필요한 대량 print/console.log 여부 |
| 군더더기 | 쓰지 않는 파일·함수·의존성, 임시 스크립트, 내용 없이 남은 문서 템플릿 |
| git | `git status --short` 깨끗한지, 마지막 커밋이 최신 상태인지 |
| 문서 | PLAN·COLLAB·DECISIONS·VERIFY·README가 실제 내용으로 채워졌는지 |
| 정리 | 실행 중인 불필요한 서버·프로세스 종료 |

군더더기와 빈 템플릿은 목록으로 보여 주면 사람이 지울지 정할 수 있다(삭제는 되돌리기 어렵다).

## 보고
- 항목별 OK / 문제 / 미확인.
- 마지막 커밋: `chore: 제출 전 점검` (변경이 있을 때만).
- 사람에게 남은 일 안내: AGENTS.md 이벤트 섹션의 "제출 절차"를 그대로 알려준다. 제출 행위 자체는 사람이 한다.
