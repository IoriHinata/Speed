import {cp, mkdir, rm} from 'node:fs/promises';
const output = new URL('../android/app/src/main/assets/', import.meta.url);
await rm(output, {recursive: true, force: true});
await mkdir(new URL('./src/', output), {recursive: true});
await Promise.all([
  cp(new URL('../index.html', import.meta.url), new URL('./index.html', output)),
  cp(new URL('../src/main.js', import.meta.url), new URL('./src/main.js', output)),
  cp(new URL('../src/styles.css', import.meta.url), new URL('./src/styles.css', output))
]);
console.log('Polya Android assets prepared (writer app only).');
