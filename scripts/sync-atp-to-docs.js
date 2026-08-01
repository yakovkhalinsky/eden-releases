#!/usr/bin/env node
/**
 * Sync agentic-team-protocol primitives into the docs-site public tree.
 *
 * Copies the canonical agentic-team-protocol/ directory into
 * docs-site/public/agentic-team-protocol/ so the live site serves the
 * install script, SKILL.md, agents, commands, templates, and charter at
 * URLs the installer expects.
 *
 * Run manually:
 *   node scripts/sync-atp-to-docs.js
 *
 * It is also invoked automatically by the docs-site build and dev scripts.
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const sourceDir = path.join(repoRoot, 'agentic-team-protocol');
const targetDir = path.join(repoRoot, 'docs-site', 'public', 'agentic-team-protocol');

function copyRecursive(src, dest) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src)) {
      copyRecursive(path.join(src, entry), path.join(dest, entry));
    }
  } else {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

if (!fs.existsSync(sourceDir)) {
  console.error(`Source not found: ${sourceDir}`);
  process.exit(1);
}

// Wipe any previously-generated copy to avoid stale files.
if (fs.existsSync(targetDir)) {
  fs.rmSync(targetDir, { recursive: true, force: true });
}

copyRecursive(sourceDir, targetDir);

// Quick sanity check that the install script is present.
if (!fs.existsSync(path.join(targetDir, 'install.sh'))) {
  console.error('Sync completed but install.sh is missing.');
  process.exit(1);
}

console.log(`Synced ${sourceDir} -> ${targetDir}`);
