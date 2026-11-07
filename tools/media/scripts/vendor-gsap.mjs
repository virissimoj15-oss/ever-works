// Copies GSAP from node_modules into the HyperFrames demo so renders work offline
// (headless Chrome does not always reach CDNs, e.g. behind a proxy).
import { copyFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = join(dirname(require.resolve('gsap/package.json')), 'dist', 'gsap.min.js');
const destDir = join(root, 'hyperframes-demo', 'assets', 'vendor');

mkdirSync(destDir, { recursive: true });
copyFileSync(src, join(destDir, 'gsap.min.js'));
console.log(`gsap.min.js -> ${destDir}`);
