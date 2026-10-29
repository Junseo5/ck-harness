"""독립 검증 뼈대: 원본 입력으로 기대값을 직접 계산해 결과물과 비교한다.

기대값은 src/ 코드와 따로 계산한다. 근거는 docs/PLAN.md, docs/COLLAB.md, 원본 데이터.
실행: python3 verify/check.py
"""
import sys

results = []


def check(name, expected, actual):
    ok = expected == actual
    results.append(ok)
    print(f"[{'PASS' if ok else 'FAIL'}] {name}: 기대={expected!r} 실제={actual!r}")


def main():
    # 1. 원본 입력 읽기 (예: csv.DictReader, json.load)
    # 2. 결과물 얻기: 프로그램을 subprocess 로 다시 실행하거나 urllib.request 로 API 호출 (예전 출력 파일은 코드 변경을 놓친다)
    # 3. 항목별 비교
    # check("개수 대사", len(rows), included + excluded + review)
    pass


if __name__ == "__main__":
    main()
    if not results:
        print("검증 항목이 없습니다. main()을 채우세요.")
        sys.exit(1)
    print(f"\n{sum(results)}/{len(results)} PASS")
    sys.exit(0 if all(results) else 1)
