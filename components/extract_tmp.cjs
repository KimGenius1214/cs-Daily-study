const fs=require('fs');
const h=fs.readFileSync('2026-07-21.html','utf8');
const i=h.lastIndexOf('<script>'), j=h.lastIndexOf('</script>');
const js=h.slice(i+8,j);
fs.writeFileSync('/tmp/pg2.js', js);
console.log('extracted bytes', js.length);
