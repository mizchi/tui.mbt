#!/usr/bin/env node
/**
 * Hot Reload Development Server for MoonBit TUI
 *
 * Usage: node scripts/dev.js [example] [--target js|native]
 *
 * Examples:
 *   node scripts/dev.js chat --target js
 *   just dev chat
 */

const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Parse arguments
const args = process.argv.slice(2);
let example = 'chat';
let target = 'js';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--target' && args[i + 1]) {
    target = args[i + 1];
    i++;
  } else if (!args[i].startsWith('-')) {
    example = args[i];
  }
}

const examplePath = `examples/${example}`;
const rootDir = process.cwd();

// Directories to ignore
const IGNORE_DIRS = new Set([
  '_build',
  '.mooncakes',
  'node_modules',
  '.git',
  '.jj',
  'target',
  '__snapshots__',
]);

// File extensions to watch
const WATCH_EXTENSIONS = new Set(['.mbt', '.pkg', '.mod.json']);

let child = null;
let buildTimeout = null;
let isBuilding = false;

// ANSI colors
const colors = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
};

function log(msg, color = colors.reset) {
  const time = new Date().toLocaleTimeString('en-US', { hour12: false });
  console.log(`${colors.dim}[${time}]${colors.reset} ${color}${msg}${colors.reset}`);
}

function build() {
  if (isBuilding) return false;
  isBuilding = true;

  log('Building...', colors.yellow);

  try {
    execSync(`moon build --target ${target}`, {
      cwd: rootDir,
      stdio: 'pipe',
      encoding: 'utf-8',
    });
    log('Build successful', colors.green);
    isBuilding = false;
    return true;
  } catch (e) {
    log('Build failed:', colors.red);
    console.error(e.stderr || e.message);
    isBuilding = false;
    return false;
  }
}

function startChild() {
  if (child) {
    child.kill('SIGTERM');
    child = null;
  }

  log(`Starting ${examplePath}...`, colors.cyan);

  child = spawn('moon', ['run', examplePath, '--target', target], {
    cwd: rootDir,
    stdio: 'inherit',
    env: { ...process.env, FORCE_COLOR: '1' },
  });

  child.on('exit', (code, signal) => {
    if (signal !== 'SIGTERM') {
      log(`Process exited with code ${code}`, code === 0 ? colors.green : colors.red);
    }
    child = null;
  });

  child.on('error', (err) => {
    log(`Process error: ${err.message}`, colors.red);
    child = null;
  });
}

function restart() {
  if (buildTimeout) {
    clearTimeout(buildTimeout);
  }

  // Debounce builds
  buildTimeout = setTimeout(() => {
    if (build()) {
      startChild();
    }
  }, 100);
}

function shouldWatch(filePath) {
  const ext = path.extname(filePath);
  const basename = path.basename(filePath);

  // Check extension
  if (!WATCH_EXTENSIONS.has(ext) && basename !== 'moon.pkg' && basename !== 'moon.mod.json') {
    return false;
  }

  // Check if in ignored directory
  const parts = filePath.split(path.sep);
  for (const part of parts) {
    if (IGNORE_DIRS.has(part)) {
      return false;
    }
  }

  return true;
}

function watchDirectory(dir) {
  const watcher = fs.watch(dir, { recursive: true }, (eventType, filename) => {
    if (!filename) return;

    const fullPath = path.join(dir, filename);
    if (shouldWatch(fullPath)) {
      log(`Changed: ${filename}`, colors.dim);
      restart();
    }
  });

  watcher.on('error', (err) => {
    log(`Watch error: ${err.message}`, colors.red);
  });

  return watcher;
}

// Main
console.log(`
${colors.cyan}╔═══════════════════════════════════════════╗
║  MoonBit TUI Hot Reload Dev Server        ║
╚═══════════════════════════════════════════╝${colors.reset}
  Example: ${colors.green}${examplePath}${colors.reset}
  Target:  ${colors.green}${target}${colors.reset}

  ${colors.dim}Press Ctrl+C to stop${colors.reset}
`);

// Initial build and start
if (build()) {
  startChild();
}

// Watch for changes
const watchers = [
  watchDirectory(path.join(rootDir, 'src')),
  watchDirectory(path.join(rootDir, 'core')),
  watchDirectory(path.join(rootDir, 'components')),
  watchDirectory(path.join(rootDir, 'io')),
  watchDirectory(path.join(rootDir, 'events')),
  watchDirectory(path.join(rootDir, 'ai')),
  watchDirectory(path.join(rootDir, 'input')),
  watchDirectory(path.join(rootDir, 'examples')),
];

// Cleanup on exit
process.on('SIGINT', () => {
  log('Shutting down...', colors.yellow);

  watchers.forEach(w => w.close());

  if (child) {
    child.kill('SIGTERM');
  }

  process.exit(0);
});

process.on('SIGTERM', () => {
  if (child) {
    child.kill('SIGTERM');
  }
  process.exit(0);
});
