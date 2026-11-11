---
name: Counter Precision
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#444653'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#757684'
  outline-variant: '#c4c5d5'
  surface-tint: '#3755c3'
  primary: '#00288e'
  on-primary: '#ffffff'
  primary-container: '#1e40af'
  on-primary-container: '#a8b8ff'
  inverse-primary: '#b8c4ff'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#fe932c'
  on-secondary-container: '#663500'
  tertiary: '#003d28'
  on-tertiary: '#ffffff'
  tertiary-container: '#00563a'
  on-tertiary-container: '#5bcf9e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde1ff'
  primary-fixed-dim: '#b8c4ff'
  on-primary-fixed: '#001453'
  on-primary-fixed-variant: '#173bab'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-numeric:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  display-numeric-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: 0em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-secondary-bilingual:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  numeric-keypad:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.25rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style
The design system is engineered for fast, error-free operations in busy retail, repair, and counter-service environments. Counter staff frequently operate single-handed under high ambient lighting, dust, and time pressure. The visual style merges crisp utilitarian minimalism with industrial precision: unambiguous hierarchy, high-contrast text and interactive zones, and structured layout containers that keep operators focused on workflow accuracy.

The aesthetic avoids decorative ornamentation in favor of purposeful clarity. Every touch target, badge, and typographic unit communicates instant transactional status—whether verifying a device repair state, auditing stock counts, or inputting Indian Rupee (₹) amounts. High-density data is chunked into distinct visual containers to minimize cognitive fatigue during prolonged counter shifts.

## Colors
The palette balances institutional trust, rapid scanning, and operational urgency across varied hardware displays:

- **Primary (`#1E40AF` - Deep Sapphire):** Commands key navigation headers, primary submission triggers, active filter states, and dominant focal zones.
- **Secondary (`#D97706` - Warm Amber/Saffron):** Identifies pending attention, intermediate repair progression ("Inspected", "Part Bought"), and non-blocking warnings.
- **Tertiary (`#059669` - Emerald Green):** Denotes completed states ("Done", "Delivered"), active stock availability, positive net balances, and verified payments.
- **Error (`#DC2626` - Crimson):** Signals input errors, critical parts shortages, out-of-stock flags, and overdue SLA breaches.
- **Neutrals (`#0F172A` down to `#F8FAFC`):** Slate-derived grayscale providing high-contrast text ratios exceeding WCAG AAA for key metrics, with neutral container surfaces distinguishing stacked jobs without clutter.

### Status Tonal Tokens
- **Inspected:** Amber tint background (`#FEF3C7`) with saturated border (`#F59E0B`) and dark amber text (`#92400E`).
- **Part Bought:** Indigo tint background (`#EEF2FF`) with sapphire border (`#6366F1`) and deep indigo text (`#1E40AF`).
- **Done:** Emerald tint background (`#ECFDF5`) with emerald border (`#34D399`) and deep forest text (`#065F46`).
- **Delivered:** Slate tint background (`#F1F5F9`) with neutral border (`#94A3B8`) and grounded slate text (`#1E293B`).

## Typography
Typography is tuned for split-second legibility and dual-script presentation (English and Bengali). Inter provides neutral letterforms, distinct glyph geometry, and support for tabular numeric figures essential for balance sheets, bills, and phone numbers.

- **Tabular Numerics:** All currency (`₹`), job order numbers, and quantity counters use `font-variant-numeric: tabular-nums` to ensure vertically aligned decimal points and quick tally comparisons.
- **Bilingual Stacking:** Primary information is set in English using standard headline/body tokens, paired directly with sub-labels set in `label-secondary-bilingual` for Bengali descriptive hints (e.g., "Customer Phone / গ্রাহকের ফোন"). The line-height accommodates Bengali ascenders and descenders without clipping.
- **Tactile Hierarchy:** Actionable figures and numeric totals prioritize weight over extreme size, ensuring numbers do not truncate on compact 5-inch to 7-inch rugged POS displays.

## Layout & Spacing
The layout model accommodates rapid touch interactions in portrait-held mobile terminals and landscape-anchored counter docks:

- **Thumb-Zone Prioritization:** On mobile form factors, primary interaction nodes, numeric entry pinpads, and status update bars reside in the lower 45% of the viewport.
- **Grid Architecture:** 
  - Mobile (360px - 599px): Single-column operational stack with a 4-column sub-grid, 16px outer margin, and 16px gutters.
  - Tablet / Counter Dock (600px - 1023px): Dual-pane split (40% master order list, 60% detail & repair workbench) utilizing 8 columns and 20px gutters.
  - Desktop / Management (1024px+): 12-column layout with 24px margins, housing full audit logs and inventory metrics.
- **Touch Target Standard:** Strict minimum touch bounding box of 48x48px across all clickable elements, with numeric keypad buttons elevated to a minimum height of 56px.

## Elevation & Depth
Elevation emphasizes structural clarity under high shop glare without soft, washed-out shadows:

- **Base Layer:** Canvas background (`#F8FAFC`) forms the baseline floor.
- **Surface Tier 1 (Cards & Work Panels):** Neutral white (`#FFFFFF`) with a 1px solid border (`#E2E8F0`) and an ambient anchor shadow (`box-shadow: 0 1px 3px 0 rgba(15, 23, 42, 0.06), 0 1px 2px -1px rgba(15, 23, 42, 0.04)`).
- **Surface Tier 2 (Active Touch & Input Drawers):** Used for tactile numeric input trays and selected order cards. Styled with `#FFFFFF`, a 1.5px border in `#CBD5E1` (or `#1E40AF` when focused), and an elevation lift (`box-shadow: 0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.06)`).
- **Surface Tier 3 (Modals, Fast Actions & Dropdowns):** Maximum operational contrast with crisp bounds (`box-shadow: 0 10px 15px -3px rgba(15, 23, 42, 0.12), 0 4px 6px -4px rgba(15, 23, 42, 0.08)`) and border `#94A3B8`.

## Shapes
A roundedness value of `2` yields a 0.5rem (8px) base radius. This creates robust, utilitarian interfaces that feel structural rather than decorative:

- **Inputs, Buttons, and Cards:** 0.5rem (8px) corner radius preserves spatial boundaries and touch affordance.
- **Containers and Surface Sheets (`rounded-lg`):** 1rem (16px) corner radius applied to bottom sheets, modal trays, and numeric pad dock containers.
- **Badges and Status Chips:** 0.25rem (4px) or fully pill-contained depending on context: structured repair badges utilize 4px corners to communicate technical precision, while count badges utilize circular capsules.

## Components

### Buttons
- **Primary Action (Payment, Save Ticket):** Background `#1E40AF`, text `#FFFFFF`, minimum height 48px (52px on mobile keypad trays). Hover/active state deepens to `#1D3557` with an active scale transform of 0.98 for immediate tactile feedback.
- **Secondary (Add Part, Inspect):** White surface `#FFFFFF`, 1.5px border `#1E40AF`, text `#1E40AF`.
- **Destructive/Void:** White surface with `#DC2626` border and text; fills to solid crimson with white text on explicit hold confirmation.

### Numeric Entry & Keypad
- **Tactile POS Keypad:** Grid of 12 distinct elevated buttons (0-9, decimal, backspace). Each key features a 1.5px base border `#E2E8F0`, 56px minimum height, centered tabular numbers, and active haptic visual state (`#F1F5F9`).
- **Currency Field (`₹`):** Pre-fixed with an uneditable high-contrast Indian Rupee symbol (`#64748B`), supporting large legible input numbers in `display-numeric-mobile`.

### Status Badges & Chips
- **Status Indicator Tokens:** Compact, high-visibility badges with 4px border-radius, 1px solid stroke, uppercase tracking, and secondary Bengali script subtitle underneath.
  - *Inspected:* Amber tone (`#FEF3C7` bg, `#D97706` border, `#92400E` text).
  - *Part Bought:* Sapphire tone (`#DBEAFE` bg, `#1E40AF` border, `#1E40AF` text).
  - *Done:* Emerald tone (`#D1FAE5` bg, `#059669` border, `#065F46` text).
  - *Delivered:* Slate tone (`#E2E8F0` bg, `#64748B` border, `#1E293B` text).

### Input Fields
- **Bilingual Counter Inputs:** Explicit 1.5px border (`#CBD5E1`) turning to 2px `#1E40AF` on focus. Top label in English (`label-md`), followed by a 11px Bengali translated subtitle in `#64748B`. Large internal padding (`0.75rem 1rem`) to facilitate touch targeting.

### Cards & Work Items
- **Repair Order Card:** White surface, 1px border (`#E2E8F0`), divided into:
  1. Top metadata bar: Ticket ID `#` in tabular monospace, elapsed SLA timer, and status badge.
  2. Core content: Customer name, phone, device model, and reported issue.
  3. Action footer: Direct one-tap quick actions (Call, Print Receipt, Advance Status).