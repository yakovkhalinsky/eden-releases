#!/usr/bin/env node
/**
 * Keep the Agentic Team Protocol version in sync across all SKILL.md files.
 *
 * The single source of truth is agentic_team_protocol/VERSION.
 * This script reads that file and rewrites the `version:` frontmatter key in
 * every ATP SKILL.md so the installer, the live site, and local clones all report
 * the same number.
 *
 * Usage:
 *   node scripts/set-atp-version.js
 *   node scripts/set-atp-version.js --check   # exit non-zero on mismatch
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const versionFile = path.join(repoRoot, 'agentic_team_protocol', 'VERSION');
const skillFiles = [
  path.join(repoRoot, 'agentic_team_protocol', 'SKILL.md'),
  path.join(
    repoRoot,
    'agentic_team_protocol',
    'templates',
    'skills',
    'agentic-team-protocol',
    'SKILL.md'
  ),
];

function readVersion() {
  if (!fs.existsSync(versionFile)) {
    console.error(`Missing version file: ${versionFile}`);
    process.exit(1);
  }
  const version = fs.readFileSync(versionFile, 'utf8').trim();
  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    console.error(`Invalid version in ${versionFile}: ${version}`);
    process.exit(1);
  }
  return version;
}

function setVersions(version) {
  for (const file of skillFiles) {
    if (!fs.existsSync(file)) {
      console.error(`Missing SKILL.md: ${file}`);
      process.exit(1);
    }
    const content = fs.readFileSync(file, 'utf8');
    const updated = content.replace(/^version: .+$/m, `version: ${version}`);
    if (updated === content) {
      console.log(`OK: ${path.relative(repoRoot, file)} is already ${version}`);
    } else {
      fs.writeFileSync(file, updated);
      console.log(
        `Updated: ${path.relative(repoRoot, file)} -> version ${version}`
      );
    }
  }
}

function checkVersions(version) {
  let ok = true;
  for (const file of skillFiles) {
    if (!fs.existsSync(file)) {
      console.error(`Missing SKILL.md: ${file}`);
      ok = false;
      continue;
    }
    const match = fs.readFileSync(file, 'utf8').match(/^version: (.+)$/m);
    const found = match ? match[1].trim() : '(missing)';
    if (found !== version) {
      console.error(
        `MISMATCH: ${path.relative(repoRoot, file)} has ${found}, expected ${version}`
      );
      ok = false;
    } else {
      console.log(
        `OK: ${path.relative(repoRoot, file)} matches version ${version}`
      );
    }
  }
  return ok;
}

const version = readVersion();
if (process.argv.includes('--check')) {
  const ok = checkVersions(version);
  process.exit(ok ? 0 : 1);
}

setVersions(version);
