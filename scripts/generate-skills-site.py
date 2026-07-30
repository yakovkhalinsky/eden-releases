#!/usr/bin/env python3
"""Generate docs-site install guides from SKILL.md files under skills/.

Each SKILL.md must have YAML frontmatter with at least:
  name, description, version, tags
and may have:
  tools: {discoverable: bool, list: [...], inherits: str}
  install_hint: str
  related_skills: [...]

Generated pages are intentionally short install guides, not full renders of the
SKILL.md body. The raw SKILL.md files are copied to docs-site/public so they can
be downloaded as the installable artifact.
"""

import json
import re
import sys
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent.parent / "skills"
OUT_DIR = (
    Path(__file__).resolve().parent.parent
    / "docs-site"
    / "src"
    / "content"
    / "docs"
    / "eden-memory"
    / "skills"
)
PUBLIC_DIR = (
    Path(__file__).resolve().parent.parent
    / "docs-site"
    / "public"
    / "eden-memory"
    / "skills"
)


def parse_frontmatter(text: str):
    if not text.startswith("---"):
        return None, text
    end = text.find("---", 3)
    if end == -1:
        return None, text
    try:
        import yaml
        fm = yaml.safe_load(text[3:end])
        return fm, text[end + 3 :].strip("\n")
    except Exception:
        return None, text


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def title_from_name(name: str) -> str:
    parts = name.replace("_", " ").replace("-", " ").split()
    acronyms = {"mcp": "MCP", "cli": "CLI"}
    return " ".join(acronyms.get(p.lower(), p.title()) for p in parts)


def download_url(slug: str) -> str:
    return f"/eden-memory/skills/{slug}/SKILL.md"


def install_section(fm: dict, slug: str, name: str) -> str:
    harness = fm.get("harness", "")
    prefix = fm.get("tools", {}).get("prefix", "")
    mcp_config = fm.get("mcp_config", {})

    if harness == "hermes":
        server_name = mcp_config.get("server_name", "eden")
        return f"""## Install for Hermes Agent

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Add the MCP server to your active Hermes profile `config.yaml` under `mcp.servers`:

   ```yaml
   mcp:
     servers:
       {server_name}:
         command: ${{HOME}}/.local/bin/eden-memory
         args:
           - --db
           - ${{HOME}}/.eden-memory/default.db
   ```

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com{download_url(slug)} -o {name}/SKILL.md
   ```

4. Copy it into your active Hermes profile so it loads automatically:

   ```bash
   PROFILE=$(hermes profile active)
   mkdir -p ~/.hermes/profiles/${{PROFILE}}/skills/{name}
   cp {name}/SKILL.md ~/.hermes/profiles/${{PROFILE}}/skills/{name}/SKILL.md
   ```

Restart Hermes or reload the profile after changing `config.yaml`.

If `eden-memory` is on your PATH, you can use the bare command name. If you see `ModuleNotFoundError: No module named 'eden_memory'`, you have a stale Python wrapper; remove it with `rm -f ~/.local/bin/eden-memory` and re-run the install.
"""

    if harness == "claude-code":
        server_name = mcp_config.get("server_name", "eden-memory")
        return f"""## Install for Claude Code CLI

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Wire the MCP server. This command expands `$HOME` automatically:

   ```bash
   claude config set mcpServers "{{\\"{server_name}\\":{{\\"command\\":\\"$HOME/.local/bin/eden-memory\\",\\"args\\":[\\"--db\\",\\"$HOME/.eden-memory/default.db\\"]}}}}"
   ```

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com{download_url(slug)} -o {name}/SKILL.md
   ```

4. Add it as a **project instruction** in Claude Code:
   - Run `/memory` (or open **Settings → Project Instructions**) and paste the contents of `{name}/SKILL.md`.
   - The file contains the memory-first rules and tool usage patterns for Claude Code CLI.

Restart Claude Code after changing configuration. The `mcpServers` key is written to `~/.claude.json`. If `eden-memory` is not on the PATH that Claude Code sees, replace `$HOME` with the absolute path (e.g., `/home/yourname/.local/bin/eden-memory`).
"""

    if harness == "cursor":
        server_name = mcp_config.get("server_name", "eden-memory")
        return f"""## Install for Cursor

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Wire the MCP server:

   In Cursor, open **Settings** → **MCP** and add a new stdio server:

   | Field | Value |
   |-------|-------|
   | Name | `{server_name}` |
   | Command | `/home/yourname/.local/bin/eden-memory` |
   | Arguments | `--db /home/yourname/.eden-memory/default.db` |

   Replace `/home/yourname` with your actual home path. If `eden-memory` is on the PATH that Cursor sees, you can use the bare command name.

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com{download_url(slug)} -o {name}/SKILL.md
   ```

4. Add the rules to Cursor:
   - Paste the contents into a project `.cursorrules` file, **or**
   - paste it into the **Composer / project prompt** in Cursor settings.

Start a fresh chat after adding the server so the tools are discovered.
"""

    # Generic / core MCP usage skill
    return f"""## Install for any stdio MCP client

1. Install the binary:

   ```bash
   curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh
   ```

2. Register the server with your MCP client. The exact command depends on the client; the server config is:

   ```json
   {{
     "command": "/home/yourname/.local/bin/eden-memory",
     "args": ["--db", "/home/yourname/.eden-memory/default.db"]
   }}
   ```

   Replace `/home/yourname` with your actual home path. If `eden-memory` is on the client's PATH, you can use the bare command name.

3. Download the skill file:

   ```bash
   curl -fsSL https://0d3sa.com{download_url(slug)} -o {name}/SKILL.md
   ```

4. Paste the contents of the skill file into your agent's system prompt or project instructions, or load it as a custom skill if your client supports skill files.
"""


def enforce_section(fm: dict) -> str:
    return """## What this skill enforces

- **Health check first.** Call `eden_health` at the start of every session. Do not proceed with memory-dependent work until it succeeds.
- **Recall before acting.** Use `eden_recall` at task start and before decisions that touch preferences, conventions, security, or tooling.
- **Remember after learning.** After corrections, working solutions, or settled conventions, store durable takeaways with `eden_remember`.
- **Memory checkpoint.** Before finishing a task, confirm at least one recall happened at the start and at least one remember happened at the end.
- **Stop if tools are missing.** If the eden-memory tools are unavailable, tell the user to install and wire the MCP server, then stop.
- **Do not remember secrets.** Never store tokens, passwords, raw command output, ephemeral reasoning, or unvalidated guesses.
"""


def generate():
    try:
        import yaml
    except ImportError:
        print("PyYAML is required", file=sys.stderr)
        sys.exit(1)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PUBLIC_DIR.mkdir(parents=True, exist_ok=True)
    skills_dir = SKILLS_DIR
    skills_manifest_path = skills_dir / "skills.json"
    registry = []

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_file = skill_dir / "SKILL.md"
        if not skill_file.exists():
            continue

        text = skill_file.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(text)
        if not fm:
            print(f"Skipping {skill_file}: no frontmatter", file=sys.stderr)
            continue

        name = fm.get("name", skill_dir.name)
        title = title_from_name(name)
        slug = slugify(name)
        description = fm.get("description", "").strip().replace("\n", " ")
        version = fm.get("version", "")
        tags = ", ".join(fm.get("tags", []))

        tools = fm.get("tools", {})
        discoverable = tools.get("discoverable", False)
        tool_list = tools.get("list", [])
        inherits = tools.get("inherits", "")
        install_hint = fm.get("install_hint", "")
        related = fm.get("related_skills", [])

        # Copy raw SKILL.md to public/ for download
        public_skill_dir = PUBLIC_DIR / slug
        public_skill_dir.mkdir(parents=True, exist_ok=True)
        public_skill_path = public_skill_dir / "SKILL.md"
        public_skill_path.write_text(text, encoding="utf-8")
        print(f"Copied {public_skill_path}")

        front = ["---", f"title: Install {title} skill"]
        if description:
            front.append(f"description: {description}")
        front.extend(
            [
                "template: doc",
                f"skill_name: {name}",
                f"skill_version: {version}",
                f"skill_tags: {tags}",
                f"skill_discoverable: {str(discoverable).lower()}",
            ]
        )
        if tool_list:
            front.append(f"skill_tools: {', '.join(tool_list)}")
        if inherits:
            front.append(f"skill_inherits: {inherits}")
        if install_hint:
            front.append(f"skill_install_hint: '{install_hint}'")
        if related:
            front.append(f"skill_related: {', '.join(related)}")
        front.append("---")

        body_md = f"""# Install {title} skill

{description}

## Download this skill

The installable artifact is the raw `SKILL.md` file:

- [Download `{name}/SKILL.md`]({download_url(slug)})
- Or fetch it from the terminal:

  ```bash
  curl -fsSL https://0d3sa.com{download_url(slug)} -o {name}/SKILL.md
  ```

{install_section(fm, slug, name)}
{enforce_section(fm)}
## Next steps

- Browse the [skills registry](/eden-memory/skills/)
- Read the [MCP clients guide](/eden-memory/mcp-clients/)
- See the [tools reference](/eden-memory/reference/tools/)
"""

        out_path = OUT_DIR / f"{slug}.md"
        out_path.write_text("\n".join(front) + "\n\n" + body_md, encoding="utf-8")
        print(f"Generated {out_path}")

        registry_entry = {
            "name": name,
            "slug": slug,
            "title": fm.get("title", title),
            "description": description,
            "version": version,
            "tags": fm.get("tags", []),
            "tools": {
                "discoverable": discoverable,
                "list": tool_list,
            },
            "install_hint": install_hint,
            "download_url": f"https://0d3sa.com{download_url(slug)}",
        }
        if inherits:
            registry_entry["tools"]["inherits"] = inherits
        if fm.get("tools", {}).get("prefix"):
            registry_entry["tools"]["prefix"] = fm["tools"]["prefix"]
        if "harness" in fm:
            registry_entry["harness"] = fm["harness"]
        if "mcp_config" in fm:
            registry_entry["mcp_config"] = fm["mcp_config"]
        if related:
            registry_entry["related_skills"] = related
        registry.append(registry_entry)

    lines = [
        "---",
        "title: Skills registry",
        "description: Install eden-memory skills for your agent or editor.",
        "template: doc",
        "---",
        "",
        "# Install an eden-memory skill for your agent",
        "",
        "The skill files below are installable prompts and rules. Download the raw `SKILL.md` for your harness and load it into your agent.",
        "",
        "## I use…",
        "",
        "- [Install for Claude Code CLI](/eden-memory/skills/eden-memory-claude/)",
        "- [Install for Cursor](/eden-memory/skills/eden-memory-cursor/)",
        "- [Install for Hermes Agent](/eden-memory/skills/eden-memory-hermes/)",
        "- [Install for another MCP client](/eden-memory/skills/eden-memory-mcp-usage/)",
        "",
        "## Download all skills",
        "",
        "Fetch every skill as a tarball from the latest GitHub release:",
        "",
        "```bash",
        "curl -fsSL https://github.com/yakovkhalinsky/eden-releases/releases/latest/download/eden-memory-skills.tar.gz | tar -xz",
        "```",
        "",
        "| Skill | Description |",
        "|-------|-------------|",
    ]
    # Keep eden-memory-mcp-usage first, then harness-specific skills, then anything else.
    registry_sorted = sorted(
        registry,
        key=lambda e: (
            e["name"] != "eden-memory-mcp-usage",
            e.get("harness", ""),
            e["name"],
        ),
    )
    for entry in registry_sorted:
        lines.append(
            f"| [{entry['title']}](/eden-memory/skills/{entry['slug']}/) | {entry['description']} |"
        )

    lines.extend(
        [
            "",
            "## Autodiscovery",
            "",
            "Each skill file declares YAML frontmatter with `tools.discoverable: true` and a `tools.list`.",
            "A compatible agent can scan this registry, surface the right tools, and suggest the matching",
            "harness skill without the user memorizing tool names.",
            "",
            "## Install hint",
            "",
            "```bash",
            "curl -fsSL https://0d3sa.com/eden-memory/install.sh | sh",
            "```",
        ]
    )

    index_path = OUT_DIR / "index.md"
    index_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {index_path}")

    manifest = {
        "schema_version": "1.0.0",
        "package": "eden-memory-skills",
        "skills": registry,
    }
    with open(skills_manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"Generated {skills_manifest_path}")


if __name__ == "__main__":
    generate()
