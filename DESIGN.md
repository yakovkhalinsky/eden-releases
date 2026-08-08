---
name: 0d3sa
description: Local-first product design system for the 0d3sa docs and site.
colors:
  board: "#fafafa"
  panel: "#ffffff"
  panel-raised: "#f3f4f6"
  panel-soft: "#f0fdf4"
  border: "#e5e7eb"
  border-subtle: "#f3f4f6"
  text: "#111827"
  text-secondary: "#4b5563"
  text-muted: "#6b7280"
  text-dim: "#9ca3af"
  primary: "#16a34a"
  primary-dark: "#15803d"
  primary-soft: "rgba(22, 163, 74, 0.08)"
  primary-border-soft: "rgba(22, 163, 74, 0.2)"
  accent: "#2563eb"
  accent-soft: "rgba(37, 99, 235, 0.08)"
  ready: "#16a34a"
  ready-soft: "rgba(22, 163, 74, 0.08)"
  ready-border-soft: "rgba(22, 163, 74, 0.2)"
  restricted: "#d97706"
  restricted-soft: "rgba(217, 119, 6, 0.08)"
  restricted-border-soft: "rgba(217, 119, 6, 0.2)"
  blocked: "#dc2626"
  blocked-soft: "rgba(220, 38, 38, 0.05)"
typography:
  display:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(2.4rem, 5vw, 3.8rem)"
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: "-0.03em"
  headline:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.6rem"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.15rem"
    fontWeight: 700
    lineHeight: 1.2
  subtitle:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 700
    lineHeight: 1.1
  body:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
  lead:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(1.05rem, 1.6vw, 1.2rem)"
    fontWeight: 400
    lineHeight: 1.55
  ui:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.92rem"
    fontWeight: 600
    lineHeight: 1
  caption:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.82rem"
    fontWeight: 400
    lineHeight: 1.45
  small:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, sans-serif"
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
  lg: "16px"
  pill: "999px"
spacing:
  section: "80px"
  section-sm: "64px"
  gap: "18px"
  gap-sm: "12px"
  max-width: "1100px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    rounded: "{rounded.sm}"
    padding: "12px 20px"
  button-primary-hover:
    backgroundColor: "{colors.primary-dark}"
  button-secondary:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.sm}"
    padding: "12px 20px"
    border: "1px solid {colors.border}"
  button-secondary-hover:
    borderColor: "{colors.primary}"
    textColor: "{colors.primary}"
  status-chip-ready:
    backgroundColor: "{colors.ready-soft}"
    textColor: "{colors.ready}"
    border: "1px solid {colors.ready-border-soft}"
  status-chip-restricted:
    backgroundColor: "{colors.restricted-soft}"
    textColor: "{colors.restricted}"
    border: "1px solid {colors.restricted-border-soft}"
  card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.md}"
    border: "1px solid {colors.border}"
    padding: "20px"
---

# Design System: 0d3sa

## Overview

**Creative North Star: "Local-first product"**

The 0d3sa site is built on a clean, light product surface: an off-white ground, white panels, soft gray hairlines, and a single green primary action color. The visual world is internally named "Local-first product" because the interface reads like a modern developer tool or SaaS product — friendly, fast, and focused on the install path.

The system is light by default. The dark-mode toggle is removed so every visitor, regardless of system preference, sees the same white/green product surface. The palette is restrained: one green primary for CTAs and status, one blue accent for links and information, and a small set of status colors that read immediately.

**Key Characteristics:**
- Light product ground with layered white and off-white panels.
- Soft shadows and rounded corners give cards a tangible, product feel.
- Hairline borders separate regions without adding visual weight.
- Manrope carries display and body type; JetBrains Mono is reserved for commands and labels.
- Status chips with colored dots communicate readiness, restriction, or closure.
- The install/setup steps panel is the dominant compositional unit on entry surfaces.
- Product-style imagery is built with inline SVG terminal mockups rather than stock photos.
- No gradients, no glass, no decorative blur, no emoji or Unicode glyph icons.

## Colors

The palette is built around a light surface with a green primary accent and a blue information accent.

### Primary
- **Product Green** (`#16a34a`): The primary action color. Used for the main CTA button, the brand mark, active status, and success signals. It is the main identity color on the light surface.
- **Product Green Dark** (`#15803d`): Hover states for the primary button and links.
- **Product Green Soft** (`rgba(22, 163, 74, 0.08)`): Tinted background for ready status chips, install-foot reminders, and tip asides.
- **Product Green Border Soft** (`rgba(22, 163, 74, 0.2)`): Border color for green-tinted chips and asides.

### Secondary
- **Action Blue** (`#2563eb`): The link and information color. Used for inline links, note asides, and component tags.
- **Action Blue Soft** (`rgba(37, 99, 235, 0.08)`): Tinted background for note asides.

### Status
- **Ready Green** (`#16a34a`): Active, proceeding, or successful states.
- **Ready Green Soft** (`rgba(22, 163, 74, 0.08)`): Tinted background for ready status chips and asides.
- **Ready Green Border Soft** (`rgba(22, 163, 74, 0.2)`): Border color for ready status chips and asides.
- **Restricted Amber** (`#d97706`): Gated or charter-dependent states, such as the Runtime role.
- **Restricted Amber Soft** (`rgba(217, 119, 6, 0.08)`): Tinted background for restricted status chips and asides.
- **Restricted Amber Border Soft** (`rgba(217, 119, 6, 0.2)`): Border color for restricted status chips and asides.
- **Blocked Red** (`#dc2626`): Errors and danger states (reserved, rarely used).
- **Blocked Red Soft** (`rgba(220, 38, 38, 0.05)`): Tinted background for danger asides.

### Neutral
- **Board** (`#fafafa`): The page background. Soft, warm white.
- **Panel** (`#ffffff`): Primary surface for cards, blocks, and sidebars.
- **Panel Raised** (`#f3f4f6`): Elevated inputs, code blocks, and secondary button backgrounds.
- **Panel Soft** (`#f0fdf4`): Tinted green surface for highlighted blocks and status panels.
- **Border** (`#e5e7eb`): The standard 1px hairline border.
- **Border Subtle** (`#f3f4f6`): Divider lines that separate major sections without competing.
- **Text** (`#111827`): Primary body and heading text.
- **Text Secondary** (`#4b5563`): Secondary descriptions and component metadata.
- **Text Muted** (`#6b7280`): Captions, step notes, and footer copy.
- **Text Dim** (`#9ca3af`): Labels, IDs, and least-emphasis metadata.

### Named Rules
**The One Green Rule.** Product green is reserved for primary actions and positive status. Do not use it for decorative accents unrelated to action or status.

**The Status Dot Rule.** Every status chip must carry a solid dot in its text color. The dot is the quickest signal; the text confirms it.

## Typography

**Display Font:** Manrope, with system sans fallback.
**Body Font:** Manrope, with system sans fallback.
**Label / Mono Font:** JetBrains Mono, with system monospace fallback.

**Character:** The pairing is clean and modern rather than editorial. Manrope gives headings a confident, product-friendly weight without becoming decorative. JetBrains Mono is used only for commands, paths, and production labels.

### Hierarchy
- **Display** (800, `clamp(2.4rem, 5vw, 3.8rem)`, line-height 1.05, letter-spacing -0.03em): The product title. Used once per page, left-aligned.
- **Headline** (700, 1.6rem, line-height 1.1, letter-spacing -0.02em): Section titles such as "Install in minutes" and "Six roles, one lifecycle".
- **Subtitle** (700, 1.25rem, line-height 1.1): Larger card names, such as component names.
- **Title** (700, 1.15rem, line-height 1.2): Card and role names.
- **Body** (400, 1rem, line-height 1.6): Paragraphs and list items. Keep line length comfortable; the max content width is 1100px.
- **Lead** (400, `clamp(1.05rem, 1.6vw, 1.2rem)`, line-height 1.55): Hero lead paragraphs.
- **UI** (600, 0.92rem, line-height 1): Buttons and interactive labels.
- **Caption** (400, 0.82rem, line-height 1.45): Step captions and secondary metadata.
- **Small** (400, 0.78rem, line-height 1.45): Fine metadata.
- **Label** (700, 0.72rem, letter-spacing 0.04em, uppercase): Block labels and status chips.
- **Mono Small** (700, 0.7rem, letter-spacing 0.03em, uppercase): Step marks and stage IDs.

### Named Rules
**The Monospace Is For Commands Rule.** JetBrains Mono appears only for shell commands, file paths, tool names, and production labels. Headings and body copy never use it for atmosphere.

## Layout

The layout is a single centered column with a max-width of 1100px (`--max`). Major sections are separated by 80px vertical padding and a 1px subtle border. Inside sections, content is arranged in tight grids with 18px gaps.

- **Header:** sticky, 64px height, hairline bottom border. Brand on the left, navigation on the right.
- **Hero:** left-aligned with a product terminal illustration on the right. Production meta line above the display title, lead paragraph below, then actions.
- **Install panel:** the dominant panel. On desktop the install steps span two columns; on mobile they stack.
- **Role grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.
- **Stage lanes:** 4 columns on desktop, 2 on tablet, 1 on mobile.
- **Component grid:** 3 columns on desktop, 2 on tablet, 1 on mobile.

**Spacing rhythm:** tight internal groups (8–14px), generous separation between sections (64–80px). There is more space above a section heading than below it.

## Elevation & Depth

The system is light and product-like. Depth is conveyed through a combination of tonal layering (board → panel → panel-raised) and soft, restrained shadows. Cards sit slightly above the ground with a subtle shadow; hover adds a slightly larger shadow and a small lift on linked cards.

### Named Rules
**The Soft Shadow Rule.** Shadows are subtle and functional. Use `0 1px 3px 0 rgba(0, 0, 0, 0.08)` for resting cards and `0 4px 6px -1px rgba(0, 0, 0, 0.06)` for hover. Do not use heavy or colored drop shadows.

## Shapes

Corners are restrained and consistent.
- **Small radius (8px):** buttons, inputs, status chips, code blocks, step marks.
- **Medium radius (12px):** cards, panels, asides, and larger containers.
- **Large radius (16px):** hero cards and major feature panels.

Borders are always 1px, solid, and use either `--border` or `--border-subtle`. There are no left or right accent stripes on cards or callouts.

### Named Rules
**The Hairline Rule.** All dividing lines are 1px. If a separator feels too weak, increase the space around it rather than the stroke weight.

## Components

### Buttons
- **Shape:** 8px radius, 12px 20px padding, 600 weight.
- **Primary:** product green background, white text. Hover darkens to product green dark.
- **Secondary:** white background, border color `--border`, text color `--text-secondary`. Hover shifts border and text to product green.
- **Small button:** reduced padding (8px 14px), panel-raised background, used in header navigation.

### Status Chips
- **Shape:** pill (999px radius), 4px 10px padding, uppercase 0.72rem label weight.
- **Ready:** green tint background, green text, green dot.
- **Restricted:** amber tint background, amber text, amber dot.
- **Dot:** 6px circle in current text color.

### Cards / Containers
- **Shape:** 12px radius, 1px border `--border`, panel background.
- **Padding:** 20–24px.
- **Shadow:** subtle resting shadow; linked cards lift slightly on hover.

### Code Blocks
- **Shape:** 8px radius, 1px border `--border`, panel-raised background.
- **Typography:** JetBrains Mono, 0.82rem.
- **Inline code:** 2px 6px padding, panel-raised background.

### Navigation
- **Header:** sticky, panel background, hairline border, 64px height.
- **Links:** secondary text by default, primary text on hover. No underline until hover.
- **Mobile:** nav links collapse into a hamburger menu on Starlight docs pages; custom landing pages reflow to stacked buttons.

### Signature Component: The Install Panel
- **Structure:** block label (uppercase mono), step list with numbered marks, command blocks with copy buttons, and captions.
- **Columns:** up to two on desktop, single column on mobile.
- **Foot:** optional green-tinted reminder strip below the panel.

## Do's and Don'ts

### Do:
- **Do** lead entry surfaces with the install panel.
- **Do** use Manrope for headings and body, and JetBrains Mono only for commands and labels.
- **Do** communicate status with a colored dot plus uppercase label.
- **Do** keep the light board background and white panel surfaces across every page, including Starlight docs.
- **Do** use soft shadows on cards to give the product surface depth.

### Don't:
- **Don't** use gradient text, glass, or blur for decoration.
- **Don't** add colored left or right borders thicker than 1px on cards or callouts.
- **Don't** use emoji or Unicode glyphs as icons; use inline SVG or simple shapes.
- **Don't** split the install hierarchy into generic feature cards with icon + heading + text.
- **Don't** duplicate a page's frontmatter title with a markdown `#` heading in Starlight docs.
