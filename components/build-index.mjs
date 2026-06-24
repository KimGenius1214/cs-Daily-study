// Design Inspiration Daily — components 인덱스 자동 생성기
// 사용법: node components/build-index.mjs  (cs-daily 폴더 어디서 실행해도 됨)
// components/*.html (index.html, build-index.mjs 제외)을 스캔해 날짜 역순 index.html 생성.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));

const files = readdirSync(DIR)
  .filter(f => f.endsWith('.html') && f !== 'index.html')
  .filter(f => /^\d{4}-\d{2}-\d{2}\.html$/.test(f)) // YYYY-MM-DD.html 만
  .sort()
  .reverse(); // 최신 먼저

const DOW = ['일','월','화','수','목','금','토'];
const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

function parse(file){
  const html = readFileSync(join(DIR, file), 'utf8');
  // 각 섹션 <h2>…</h2> 안의 텍스트(태그·이모지 제거 전 원문)를 모아 '오늘 다룬 항목'으로
  const items = [];
  const re = /<h2[^>]*>([\s\S]*?)<\/h2>/g;
  let m;
  while ((m = re.exec(html))) {
    let t = m[1]
      .replace(/<span[^>]*class="tag"[^>]*>[\s\S]*?<\/span>/g, '') // 태그 칩 제거
      .replace(/<[^>]+>/g, '')                                     // 남은 태그 제거
      .replace(/\s+/g, ' ').trim();
    if (t) items.push(t);
  }
  const date = file.replace('.html','');
  const d = new Date(date + 'T00:00:00');
  const dow = isNaN(d) ? '' : DOW[d.getDay()];
  return { file, date, dow, items };
}

const entries = files.map(parse);

const cards = entries.map(e => `
    <a class="entry" href="./${e.file}">
      <div class="date">${e.date}${e.dow ? ` <span class="dow">(${e.dow})</span>` : ''}</div>
      <ul class="items">${e.items.map(i => `<li>${esc(i)}</li>`).join('')}</ul>
    </a>`).join('\n');

const html = `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Design Inspiration Daily — 라이브 예시 인덱스</title>
<style>
  :root{--bg:#f7f8fa;--surface:#fff;--surface-2:#f0f2f5;--border:#e3e6ea;--text:#1a1d21;--muted:#6b7280;--brand:#4f46e5;--radius:14px;--shadow:0 1px 2px rgba(16,24,40,.06),0 1px 3px rgba(16,24,40,.1)}
  html[data-theme="dark"]{--bg:#0c0e12;--surface:#15181e;--surface-2:#1d2129;--border:#272c35;--text:#e7eaf0;--muted:#9aa3b2;--brand:#7c79ff;--shadow:0 1px 2px rgba(0,0,0,.4)}
  *{box-sizing:border-box}
  body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",Roboto,"Apple SD Gothic Neo","Malgun Gothic",sans-serif;background:var(--bg);color:var(--text);line-height:1.6}
  .wrap{max-width:860px;margin:0 auto;padding:32px 20px 80px}
  header.top{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;flex-wrap:wrap}
  h1{font-size:1.5rem;margin:0 0 4px}
  .sub{color:var(--muted);font-size:.9rem}
  .theme-btn{cursor:pointer;background:var(--surface);border:1px solid var(--border);color:var(--text);border-radius:999px;padding:8px 14px;font-size:.85rem;font-family:inherit}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px;margin-top:26px}
  a.entry{display:block;text-decoration:none;color:inherit;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);padding:18px;transition:border-color .18s,transform .18s}
  a.entry:hover{border-color:var(--brand);transform:translateY(-2px)}
  .date{font-weight:700;font-size:1.05rem;margin-bottom:8px}
  .dow{color:var(--muted);font-weight:500}
  ul.items{margin:0;padding-left:18px;font-size:.85rem;color:var(--muted)}
  ul.items li{margin:2px 0}
  .empty{color:var(--muted);margin-top:30px}
  footer{color:var(--muted);font-size:.8rem;text-align:center;margin-top:40px}
</style>
</head>
<body>
<div class="wrap">
  <header class="top">
    <div>
      <h1>🎨 Design Inspiration Daily — 라이브 예시</h1>
      <div class="sub">컴포넌트·패턴 동작 데모 모음 · 총 ${entries.length}일치 · 갱신 ${new Date().toISOString().slice(0,10)}</div>
    </div>
    <button class="theme-btn" id="themeBtn" aria-label="라이트/다크 전환">🌓 테마</button>
  </header>
  ${entries.length ? `<div class="grid">${cards}\n  </div>` : `<p class="empty">아직 생성된 예시가 없습니다.</p>`}
  <footer>이 페이지는 build-index.mjs가 components 폴더를 스캔해 자동 생성합니다.</footer>
</div>
<script>
  var root=document.documentElement;
  root.setAttribute('data-theme','light');
  document.getElementById('themeBtn').addEventListener('click',function(){
    root.setAttribute('data-theme', root.getAttribute('data-theme')==='dark'?'light':'dark');
  });
</script>
</body>
</html>`;

writeFileSync(join(DIR, 'index.html'), html, 'utf8');
console.log(`index.html generated: ${entries.length} entries`);
