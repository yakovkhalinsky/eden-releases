---
name: 0d3sa
description: Obsidian command center design system for the 0d3sa docs and site.
colors:
  obsidian: "#132322"
  abyss: "#0e1a19"
  charcoal: "#070f0f"
  neon: "#3ddc91"
  mint: "#97ddbc"
  yellow: "#ffcd48"
  white: "#ffffff"
  slate: "#828786"
  graphite: "#424f4f"
  fog: "#d0d3d3"
  mint-frost: "#edf7f5"
  neon-soft: "rgba(61, 220, 145, 0.12)"
  neon-border: "rgba(61, 220, 145, 0.3)"
typography:
  display:
    fontFamily: "Chakra Petch, Saira, -apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 700
    letterSpacing: "-0.03em"
  body:
    fontFamily: "Saira, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontWeight: 400
    lineHeight: 1.6
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontWeight: 400
rounded:
  sm: "10px"
  md: "20px"
  lg: "60px"
  pill: "56px"
spacing:
  section: "80px"
  gap: "18px"
  gap-lg: "24px"
  max-width: "1200px"
---

# Design System: 0d3sa

## Overview

**Creative North Star: "Obsidian command center"**

The 0d3sa site is built on a dark developer-tool surface: an obsidian ground, deep-abyss nested cards, neon green signal, and generous rounding. The visual world is internally named "Obsidian command center" because the interface reads like a high-end engineering console — every green pulse marks a live signal.

The system is dark by default. The light-mode toggle is removed so every visitor sees the same obsidian world. The palette is restrained: one neon green primary for CTAs and active states, one mint whisper for softer highlights, one signal yellow reserved for illustration accents, and near-white text on dark surfaces.

**Key Characteristics:**
- Dark obsidian ground with layered deep-abyss and charcoal panels.
- Subtle or no shadows; depth comes from flat luminance layers.
- Generous rounding: 56 px pill buttons, 60 px large cards, 20 px nested cards, 10 px small elements.
- Saira carries body and UI type; Chakra Petch carries display and headings; JetBrains Mono is reserved for commands and labels.
- Status chips with colored dots communicate readiness.
- The install/setup steps panel is the dominant compositional unit on entry surfaces.
- Product imagery is built with inline SVG isometric module illustrations.
- No gradients, no glass, no decorative blur, no emoji or Unicode glyph icons.

## Colors

The palette is built around a dark surface with a neon green primary accent.

### Primary
- **Neon Pulse** (`#3ddc91`): The primary action color. Used for main CTAs, active states, links, and stat highlights. It is the main identity signal on the dark surface.
- **Mint Whisper** (`#97ddbc`): Hover and soft highlight state for the primary action.
- **Neon Soft** (`rgba(61, 220, 145, 0.12)`): Tinted background for ready status chips, active sidebar items, and hover panels.
- **Neon Border** (`rgba(61, 220, 145, 0.3)`): Border color for neon-tinted chips and asides.

### Accent
- **Signal Yellow** (`#ffcd48`): Reserved for illustration accents and module highlights. Not used for primary actions.

### Surface
- **Obsidian Shell** (`#132322`): The page background and header.
- **Deep Abyss** (`#0e1a19`): Nested dark cards, sidebar, code blocks.
- **Charcoal** (`#070f0f`): Overlays, max-contrast panels, and role cards.
- **Graphite** (`#424f4f`): Borders, dividers, icon strokes.
- **Mint Frost** (`#edf7f5`): Rare light card surface for alternating sections.
- **Fog** (`#d0d3d3`): Dividers on mint-frost cards.

### Text
- **Pure White** (`#ffffff`): Headings, primary body text, button text on dark.
- **Slate** (`#828786`): Muted body, captions, secondary labels.

### Named Rules
**The One Green Rule.** Neon green is reserved for primary actions and positive status. Do not use it for decorative accents unrelated to action or status.

**The Status Dot Rule.** Every status chip must carry a solid dot in its text color.

## Typography

**Display Font:** Chakra Petch, with Saira and system sans fallback.
**Body / UI Font:** Saira, with system sans fallback.
**Label / Mono Font:** JetBrains Mono, with system monospace fallback.

**Character:** Chakra Petch gives headings a geometric, tech-forward confidence. Saira keeps body text neutral and readable at UI sizes. JetBrains Mono is used only for commands, paths, and production labels.

### Hierarchy
- **Display** (500, `clamp(2.6rem, 6vw, 4.2rem)`, line-height 1.05, letter-spacing -0.03em): The product title. Used once per page, left-aligned, uppercase.
- **Headline** (500, `clamp(1.5rem, 3vw, 2.4rem)`, line-height 1.1): Section titles.
- **Title** (500, 1.15–1.25rem): Card names.
- **Body** (400, 1rem, line-height 1.6): Paragraphs and list items.
- **Lead** (400, `clamp(1.05rem, 1.8vw, 1.25rem)`, line-height 1.55): Hero lead paragraphs.
- **UI** (500, 0.92rem, line-height 1): Buttons and interactive labels.
- **Caption** (400, 0.82rem): Step captions and secondary metadata.
- **Label** (700, 0.72rem, letter-spacing 0.05em, uppercase): Block labels and status chips. Uses JetBrains Mono.

### Named Rules
**The Monospace Is For Commands Rule.** JetBrains Mono appears only for shell commands, file paths, tool names, and production labels.

## Layout

The layout is a single centered column with a max-width of 1200px. Major sections are separated by 80px vertical padding. Inside sections, content is arranged in tight grids with 18–24px gaps.

- **Header:** sticky, 64px height, graphite bottom border. Brand on the left, navigation on the right.
- **Hero:** split layout. Left-aligned headline + CTAs (~50%), right-aligned isometric SVG illustration.
- **Install panel:** the dominant panel. Large abyss card with charcoal step blocks, copyable commands, and status chips.
- **Role grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.
- **Component grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.

**Spacing rhythm:** tight internal groups (8–16px), generous separation between sections (80px).

## Elevation & Depth

The system is flat and dark. Depth comes from tonal layering (obsidian → abyss → charcoal) rather than shadows. When shadows are used, they are subtle (`rgba(0, 0, 0, 0.04)`) and functional.

## Shapes

Corners are generous and consistent with the Refero guide:
- **10px radius:** buttons (small), code blocks, status chips, inputs.
- **20px radius:** nested cards, panels, asides.
- **56px radius:** pill buttons and tabs.
- **60px radius:** large cards and hero panels.

Borders are always 1px, solid, and use `--graphite` on dark surfaces or `--fog` on mint-frost cards.

### Named Rules
**The Hairline Rule.** All dividing lines are 1px. If a separator feels too weak, increase the space around it rather than the stroke weight.

## Components

### Buttons
- **Shape:** 56px pill radius, 14px 28px padding, 500 weight.
- **Primary:** neon green background, obsidian text. Hover brightens to mint whisper.
- **Secondary:** transparent background, 1.5px white border, white text. Hover adds a subtle white tint.
- **Small button:** reduced padding (8px 16px), abyss background, graphite border, slate text. Hover turns neon green.

### Status Chips
- **Shape:** pill (999px radius), 4px 10px padding, uppercase 0.72rem label weight, JetBrains Mono.
- **Ready:** neon-tint background, neon green text, neon green dot.
- **Dot:** 6px circle in current text color.

### Cards / Containers
- **Shape:** 20px radius on dark cards, 60px radius on large light cards, 1px border.
- **Padding:** 20–40px.
- **Depth:** flat tonal layers; no heavy shadows.

### Code Blocks
- **Shape:** 10px radius on inline, 20px radius on blocks, 1px border graphite.
- **Typography:** JetBrains Mono, 0.82rem.
- **Background:** deep abyss.

### Navigation
- **Header:** sticky, obsidian background, graphite border, 64px height.
- **Links:** slate by default, white on hover. No underline until hover.

### Signature Component: The Install Panel
- **Structure:** large abyss card, eyebrow label, step blocks in charcoal, command blocks with copy buttons, status chip.
- **Columns:** up to two on desktop, single column on mobile.

## Do's and Don'ts

### Do:
- **Do** lead entry surfaces with the install panel.
- **Do** use Saira for body/UI, Chakra Petch for headings, and JetBrains Mono only for commands and labels.
- **Do** communicate status with a colored dot plus uppercase label.
- **Do** keep the obsidian ground and deep-abyss panels across every page, including Starlight docs.
- **Do** alternate dark obsidian bands with rare mint-frost cards for rhythm.

### Don't:
- **Don't** use gradient text, glass, or blur for decoration.
- **Don't** add colored left or right borders thicker than 1px on cards or callouts.
- **Don't** use emoji or Unicode glyphs as icons; use inline SVG or simple shapes.
- **Don't** use heavy drop shadows as decoration.
- **Don't** duplicate a page's frontmatter title with a markdown `#` heading in Starlight docs.
