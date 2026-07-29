#!/usr/bin/env node
/**
 * Sync skills from the repo root into the docs-site content tree.
 *
 * Reads skills/<name>/SKILL.md and writes docs-site/src/content/docs/eden-memory/skills/<name>.md
 * so Starlight serves them as docs pages.
 *
 * Run manually:
 *   node scripts/sync-skills-to-docs.js
 *
 * It is also invoked automatically by the build command in package.json.
 */

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const sourceDir = path.join(repoRoot, 'skills');
const targetDir = path.join(repoRoot, 'docs-site', 'src', 'content', 'docs', 'eden-memory', 'skills');

const frontmatterPattern = /^---\n[\s\S]*?\n---\n/;

function syncSkill(name) {
  const sourcePath = path.join(sourceDir, name, 'SKILL.md');
  const targetPath = path.join(targetDir, `${name}.md`);

  if (!fs.existsSync(sourcePath)) {
    console.warn(`Source not found: ${sourcePath}`);
    return false;
  }

  let content = fs.readFileSync(sourcePath, 'utf8');

  // SKILL.md frontmatter contains skill registry metadata. Docs frontmatter should be minimal.
  const fmMatch = content.match(frontmatterPattern);
  let title = name;
  if (fmMatch) {
    const explicitTitle = fmMatch[0].match(/^title:\s*(.+)$/m);
    if (explicitTitle) {
      title = explicitTitle[1].trim();
    } else {
      const titleMatch = fmMatch[0].match(/^name:\s*(.+)$/m);
      if (titleMatch) title = titleMatch[1].trim();
    }
    content = content.slice(fmMatch[0].length).trimStart();
  }

  const targetContent = `---\ntitle: ${title}\ndescription: Agent skill for working with eden-memory.\n---\n\n${content}`;

  fs.mkdirSync(targetDir, { recursive: true });
  fs.writeFileSync(targetPath, targetContent);
  console.log(`Synced ${sourcePath} -> ${targetPath}`);
  return true;
}

const skillNames = fs.readdirSync(sourceDir, { withFileTypes: true })
  .filter(entry => entry.isDirectory())
  .map(entry => entry.name)
  .filter(name => name.startsWith('eden-memory-'));

let synced = 0;
for (const name of skillNames) {
  if (syncSkill(name)) synced++;
}

console.log(`Synced ${synced} skill page(s).`);
