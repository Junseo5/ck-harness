// 독립 검증 뼈대: 원본 입력으로 기대값을 직접 계산해 결과물과 비교한다.
// src/ 의 코드를 import 하지 않는다. 근거는 docs/PLAN.md, docs/COLLAB.md, 원본 데이터뿐.
// 실행: node verify/check.mjs
import { readFileSync } from 'node:fs';

const results = [];

function check(name, expected, actual) {
  const ok = JSON.stringify(expected) === JSON.stringify(actual);
  results.push(ok);
  console.log(`[${ok ? 'PASS' : 'FAIL'}] ${name}: 기대=${JSON.stringify(expected)} 실제=${JSON.stringify(actual)}`);
}

async function main() {
  // 1. 원본 입력 읽기 (예: JSON.parse(readFileSync('data/input.json', 'utf8')))
  // 2. 결과물 읽기 (출력 파일 또는 await fetch('http://127.0.0.1:PORT/...'))
  // 3. 항목별 비교
  // check('개수 대사', rows.length, included + excluded + review);
}

await main();
if (results.length === 0) {
  console.log('검증 항목이 없습니다. main()을 채우세요.');
  process.exit(1);
}
const passed = results.filter(Boolean).length;
console.log(`\n${passed}/${results.length} PASS`);
process.exit(results.every(Boolean) ? 0 : 1);
