#!/usr/bin/env node
/**
 * Sync agentic_team_protocol primitives into the docs-site public tree.
 *
 * Copies the canonical agentic_team_protocol/ directory into
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
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const sourceDir = path.join(repoRoot, 'agentic_team_protocol');
const targetDir = path.join(repoRoot, 'docs-site', 'public', 'agentic-team-protocol');
const tarballName = 'agentic-team-protocol.tar.gz';

// The version lives in agentic_team_protocol/VERSION. Sync it into every
// SKILL.md before publishing so the live installer reports the same number as
// the source tree.
execFileSync('node', [path.join(__dirname, 'set-atp-version.js')], {
  stdio: 'inherit',
});

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
    // Defensive: shell scripts must remain executable in the public tree so that
    // consumers who download and run them directly (not via curl | sh) do not hit
    // a permission-denied error. Preserve the source mode explicitly.
    if (dest.endsWith('.sh')) {
      const srcMode = fs.statSync(src).mode;
      fs.chmodSync(dest, srcMode);
    }
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

// Package the synced tree into a tarball so the curl installer can download
// a single archive instead of individual files. Build the archive outside the
// target directory to avoid including the tarball inside itself.
const tarballPath = path.join(targetDir, tarballName);
const tmpTarball = path.join(os.tmpdir(), tarballName);
try {
  execFileSync(
    'tar',
    ['-czf', tmpTarball, '-C', path.dirname(targetDir), path.basename(targetDir)],
    { stdio: ['ignore', 'pipe', 'pipe'] }
  );
  fs.mkdirSync(path.dirname(tarballPath), { recursive: true });
  fs.copyFileSync(tmpTarball, tarballPath);
} catch (err) {
  console.error(`Failed to create tarball: ${err.message}`);
  process.exit(1);
} finally {
  try {
    fs.unlinkSync(tmpTarball);
  } catch {
    // ignore cleanup failure
  }
}

// Quick sanity checks that the install script and tarball are present.
if (!fs.existsSync(path.join(targetDir, 'install.sh'))) {
  console.error('Sync completed but install.sh is missing.');
  process.exit(1);
}
if (!fs.existsSync(tarballPath)) {
  console.error('Sync completed but tarball is missing.');
  process.exit(1);
}

console.log(`Synced ${sourceDir} -> ${targetDir}`);
console.log(`Packaged ${tarballPath}`);
