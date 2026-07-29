#!/usr/bin/env python3
"""Generate docs-site content pages from SKILL.md files under skills/.

Each SKILL.md must have YAML frontmatter with at least:
  name, description, version, tags
and may have:
  tools: {discoverable: bool, list: [...], inherits: str}
  install_hint: str
  related_skills: [...]
"""

import re
import sys
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent.parent / "skills"
OUT_DIR = Path(__file__).resolve().parent.parent / "docs-site" / "src" / "content" / "docs" / "eden-memory" / "skills"


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


def generate():
    try:
        import yaml
    except ImportError:
        print("PyYAML is required", file=sys.stderr)
        sys.exit(1)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
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

        front = ["---", f"title: {title}"]
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

        out_path = OUT_DIR / f"{slug}.md"
        out_path.write_text("\n".join(front) + "\n\n" + body, encoding="utf-8")
        print(f"Generated {out_path}")

        registry.append(
            {
                "name": name,
                "slug": slug,
                "title": title,
                "description": description,
                "version": version,
                "discoverable": discoverable,
                "tools": tool_list,
                "install_hint": install_hint,
                "related": related,
            }
        )

    lines = [
        "---",
        "title: Skills registry",
        "description: Discoverable agent skills and harness integrations for eden-memory.",
        "template: doc",
        "---",
        "",
        "# eden-memory skills registry",
        "",
        "These skills teach an agent how to use eden-memory. They declare which MCP tools they use,",
        "how to install the binary, and which harness-specific skills to load next.",
        "",
        "| Skill | Description |",
        "|-------|-------------|",
    ]
    for entry in registry:
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
            "curl -fsSL https://0d3sa.com/install.sh | sh",
            "```",
        ]
    )

    index_path = OUT_DIR / "index.md"
    index_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {index_path}")


if __name__ == "__main__":
    generate()
