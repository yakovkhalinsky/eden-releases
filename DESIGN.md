---
name: 0d3sa
description: Production Call Sheet design system for the Agentic Team Protocol docs and site.
colors:
  board: "#0d1117"
  panel: "#161b22"
  panel-raised: "#21262d"
  border: "#30363d"
  border-subtle: "#21262d"
  text: "#c9d1d9"
  text-muted: "#8b949e"
  text-dim: "#6e7681"
  alert: "#f78166"
  action: "#58a6ff"
  action-high: "#79b8ff"
  ready: "#3fb950"
  ready-soft: "rgba(63, 185, 80, 0.12)"
  ready-border-soft: "rgba(63, 185, 80, 0.25)"
  restricted: "#d29922"
  restricted-soft: "rgba(210, 153, 34, 0.12)"
  restricted-border-soft: "rgba(210, 153, 34, 0.25)"
  blocked: "#f85149"
  alert-soft: "rgba(247, 129, 102, 0.12)"
  action-soft: "rgba(88, 166, 255, 0.12)"
typography:
  display:
    fontFamily: "Chakra Petch, Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(2.6rem, 7vw, 4.8rem)"
    fontWeight: 700
    lineHeight: 0.98
    letterSpacing: "-0.03em"
  headline:
    fontFamily: "Chakra Petch, Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Chakra Petch, Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.15rem"
    fontWeight: 700
    lineHeight: 1.2
  subtitle:
    fontFamily: "Chakra Petch, Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 700
    lineHeight: 1.1
  body:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
  lead:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(1.05rem, 1.8vw, 1.25rem)"
    fontWeight: 400
    lineHeight: 1.55
  ui:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.92rem"
    fontWeight: 600
    lineHeight: 1
  caption:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.82rem"
    fontWeight: 400
    lineHeight: 1.45
  small:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.78rem"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "0.72rem"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0.04em"
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "0.82rem"
    fontWeight: 400
    lineHeight: 1.5
  mono-small:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "0.7rem"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0.03em"
rounded:
  sm: "8px"
  md: "12px"
  pill: "999px"
spacing:
  section: "64px"
  gap: "16px"
  gap-lg: "18px"
  max-width: "1100px"
components:
  button-primary:
    backgroundColor: "{colors.alert}"
    textColor: "{colors.board}"
    rounded: "{rounded.sm}"
    padding: "12px 20px"
  button-primary-hover:
    backgroundColor: "#ff9a80"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.text}"
    rounded: "{rounded.sm}"
    padding: "12px 20px"
    border: "1px solid {colors.border}"
  button-secondary-hover:
    borderColor: "{colors.action}"
    textColor: "{colors.action}"
  status-chip-ready:
    backgroundColor: "rgba(63, 185, 80, 0.12)"
    textColor: "{colors.ready}"
    border: "1px solid rgba(63, 185, 80, 0.25)"
  status-chip-restricted:
    backgroundColor: "rgba(210, 153, 34, 0.12)"
    textColor: "{colors.restricted}"
    border: "1px solid rgba(210, 153, 34, 0.25)"
  card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.md}"
    border: "1px solid {colors.border}"
    padding: "18px"
---

# Design System: 0d3sa

## Overview

**Creative North Star: "The Production Call Sheet"**

The 0d3sa site is built on a dark production-board surface: a near-black ground, layered panel fills, role badges, stage lanes, and command callouts. The visual world is internally named "Production Call Sheet" because the dominant layout is a clean, scanable sequence of install and run steps — but the user-facing copy avoids film-production jargon and simply describes setup, roles, and components.

The system is dark by default because the primary use scene is a developer inside a code editor or terminal, flipping to a browser for the exact command or charter rule. The palette is restrained: one alert color for primary actions, one action color for links and information, and a small set of status colors that read immediately.

**Key Characteristics:**
- Dark production-board ground with layered panel fills.
- Hairline borders separate regions without adding visual weight.
- Chakra Petch carries display type; Saira handles body text; JetBrains Mono is reserved for commands and labels.
- Status chips with colored dots communicate readiness, restriction, or closure.
- The install/setup steps panel is the dominant compositional unit on entry surfaces.
- No gradients, no glass, no decorative shadows, no emoji or Unicode glyph icons.

## Colors

The palette is built around a dark board with a single warm alert accent and a cool action accent.

### Primary
- **Alert Coral** (`#f78166`): The primary action color. Used for the main CTA button, the brand mark, and urgent callouts. It is the warm signal on the dark board.
- **Alert Coral High** (`#ff9a80`): The hover state for the primary action button and links.

### Secondary
- **Action Blue** (`#58a6ff`): The link and information color. Used for inline links, component tags, and stage owners.
- **Action Blue High** (`#79b8ff`): The hover state for action-blue links.

### Status
- **Ready Green** (`#3fb950`): Active, proceeding, or successful states.
- **Ready Green Soft** (`rgba(63, 185, 80, 0.12)`): Tinted background for ready status chips and asides.
- **Ready Green Border Soft** (`rgba(63, 185, 80, 0.25)`): Border color for ready status chips and asides.
- **Restricted Amber** (`#d29922`): Gated or charter-dependent states, such as the Runtime role.
- **Restricted Amber Soft** (`rgba(210, 153, 34, 0.12)`): Tinted background for restricted status chips and asides.
- **Restricted Amber Border Soft** (`rgba(210, 153, 34, 0.25)`): Border color for restricted status chips and asides.
- **Blocked Red** (`#f85149`): Errors and danger states (reserved, rarely used).
- **Blocked Red Soft** (`rgba(248, 81, 73, 0.08)`): Tinted background for danger asides.
- **Blocked Red Border Soft** (`rgba(248, 81, 73, 0.35)`): Border color for danger asides.
- **Action Blue Soft** (`rgba(88, 166, 255, 0.12)`): Tinted background for component tags and note asides.
- **Action Blue Border Soft** (`rgba(88, 166, 255, 0.35)`): Border color for note asides.
- **Alert Coral Soft** (`rgba(247, 129, 102, 0.12)`): Tinted background for alert-tinted reminder strips and selected states.

### Neutral
- **Board** (`#0d1117`): The page background. Deep, near-black production board.
- **Panel** (`#161b22`): Primary surface for cards, blocks, and sidebars.
- **Panel Raised** (`#21262d`): Elevated inputs, code blocks, and button fills.
- **Border** (`#30363d`): The standard 1px hairline border.
- **Border Subtle** (`#21262d`): Divider lines that separate major sections without competing.
- **Text** (`#c9d1d9`): Primary body and heading text.
- **Text Muted** (`#8b949e`): Captions, secondary descriptions, and footer copy.
- **Text Dim** (`#6e7681`): Labels, IDs, and least-emphasis metadata.

### Named Rules
**The One Alert Rule.** Alert coral is reserved for the primary action on any surface. Do not use it for decorative accents, borders, or secondary labels.

**The Status Dot Rule.** Every status chip must carry a solid dot in its text color. The dot is the quickest signal; the text confirms it.

## Typography

**Display Font:** Chakra Petch, with Saira and system sans fallback.
**Body Font:** Saira, with system sans fallback.
**Label / Mono Font:** JetBrains Mono, with system monospace fallback.

**Character:** The pairing is technical and administrative rather than editorial. Chakra Petch gives headings a wide, industrial authority without becoming decorative. Saira keeps body copy neutral and readable. JetBrains Mono is used only for commands, paths, and production labels.

### Hierarchy
- **Display** (700, `clamp(2.6rem, 7vw, 4.8rem)`, line-height 0.98, letter-spacing -0.03em): The production title. Used once per page, left-aligned.
- **Headline** (700, 1.5rem, line-height 1.1, letter-spacing -0.02em): Section titles such as "Install and run" and "Team roles".
- **Subtitle** (700, 1.25rem, line-height 1.1): Larger card names, such as component names.
- **Title** (700, 1.15rem, line-height 1.2): Card and role names.
- **Body** (400, 1rem, line-height 1.6): Paragraphs and list items. Keep line length comfortable; the max content width is 1100px.
- **Lead** (400, `clamp(1.05rem, 1.8vw, 1.25rem)`, line-height 1.55): Hero lead paragraphs.
- **UI** (600, 0.92rem, line-height 1): Buttons and interactive labels.
- **Caption** (400, 0.82rem, line-height 1.45): Step captions, command captions, and secondary metadata.
- **Small** (400, 0.78rem, line-height 1.45): Production IDs and fine metadata.
- **Label** (700, 0.72rem, letter-spacing 0.04em, uppercase): Production IDs, block labels, and status chips.
- **Mono Small** (700, 0.7rem, letter-spacing 0.03em, uppercase): Step marks and stage IDs.

### Named Rules
**The Monospace Is For Commands Rule.** JetBrains Mono appears only for shell commands, file paths, tool names, and production labels. Headings and body copy never use it for atmosphere.

## Layout

The layout is a single centered column with a max-width of 1100px (`--max`). Major sections are separated by 64px vertical padding and a 1px subtle border. Inside sections, content is arranged in tight grids with 16px gaps.

- **Header:** sticky, 60px height, hairline bottom border. Brand on the left, navigation on the right.
- **Hero:** left-aligned, compact. Production meta line above the display title, lead paragraph below, then actions.
- **Call sheet:** the dominant panel. On desktop it spans two columns (install/configure on the left, run on the right); on mobile it stacks into a single scrolling column.
- **Role grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.
- **Stage lanes:** 4 columns on desktop, 2 on tablet, 1 on mobile.
- **Component grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.

**Spacing rhythm:** tight internal groups (8–12px), generous separation between sections (64px). There is more space above a section heading than below it.

## Elevation & Depth

The system is flat. Depth is conveyed through tonal layering (board → panel → panel-raised) and 1px hairline borders, not through shadows. Cards and panels do not cast shadows.

### Named Rules
**The No Shadow Rule.** Shadows are not used as decoration. If an element needs to feel raised, use a darker or lighter panel fill, not a drop shadow.

## Shapes

Corners are restrained and consistent.
- **Small radius (8px):** buttons, inputs, status chips, code blocks, step marks.
- **Medium radius (12px):** cards, panels, asides, and larger containers.

Borders are always 1px, solid, and use either `--border` or `--border-subtle`. There are no left or right accent stripes on cards or callouts.

### Named Rules
**The Hairline Rule.** All dividing lines are 1px. If a separator feels too weak, increase the space around it rather than the stroke weight.

## Components

### Buttons
- **Shape:** 8px radius, 12px 20px padding, 600 weight.
- **Primary:** alert coral background, board text. Hover lightens the coral to `#ff9a80`.
- **Secondary:** transparent background, border color `--border`, text color `--text`. Hover shifts border and text to action blue.
- **Small button:** reduced padding (8px 14px), panel-raised background, used in header navigation.

### Status Chips
- **Shape:** pill (999px radius), 4px 10px padding, uppercase 0.72rem label weight.
- **Ready:** green tint background, green text, green dot.
- **Restricted:** amber tint background, amber text, amber dot.
- **Dot:** 6px circle in current text color.

### Cards / Containers
- **Shape:** 12px radius, 1px border `--border`, panel background.
- **Padding:** 18–20px.
- **Hover:** border shifts to action blue for linked cards; no shadow change.

### Code Blocks
- **Shape:** 8px radius, 1px border `--border`, panel-raised or board background.
- **Typography:** JetBrains Mono, 0.82rem.
- **Inline code:** 2px 6px padding, panel-raised background.

### Navigation
- **Header:** sticky, board background, hairline border, 60px height.
- **Links:** muted text by default, full white on hover. No underline until hover.
- **Mobile:** nav links collapse into a hamburger menu on Starlight docs pages; custom landing pages reflow to stacked buttons.

### Signature Component: The Call Sheet Panel
- **Structure:** block label (uppercase mono), step list with numbered marks, command blocks with copy buttons, and captions.
- **Columns:** up to three on desktop, single column on mobile.
- **Foot:** optional alert-tinted reminder strip below the panel.

## Do's and Don'ts

### Do:
- **Do** lead entry surfaces with the install call sheet.
- **Do** use Chakra Petch for every heading, Saira for body, and JetBrains Mono only for commands and labels.
- **Do** communicate status with a colored dot plus uppercase label.
- **Do** keep the dark board background and panel surfaces across every page, including Starlight docs.

### Don't:
- **Don't** use gradient text, glass, or blur for decoration.
- **Don't** add colored left or right borders thicker than 1px on cards or callouts.
- **Don't** use emoji or Unicode glyphs as icons; use inline SVG or simple shapes.
- **Don't** split the call-sheet hierarchy into generic feature cards with icon + heading + text.
- **Don't** duplicate a page's frontmatter title with a markdown `#` heading in Starlight docs.
