# UI/UX Design System Blueprint
## Professional Accounting & Invoicing Mobile Application

**Version:** 1.0  
**Last Updated:** January 25, 2026  
**Platform:** Flutter Mobile (iOS / Android)  
**Primary Language:** Arabic (RTL)  
**Secondary Language:** English (LTR)

---

# Table of Contents

1. [Visual Identity System](#1-visual-identity-system)
2. [Color System](#2-color-system)
3. [Typography System](#3-typography-system)
4. [Layout & Grid System](#4-layout--grid-system)
5. [Component Design System](#5-component-design-system)
6. [UX Architecture & Navigation Model](#6-ux-architecture--navigation-model)
7. [Long Usage Comfort Strategy](#7-long-usage-comfort-strategy)
8. [Screen Design Guidelines](#8-screen-design-guidelines)
9. [Accessibility System](#9-accessibility-system)
10. [Flutter Implementation Guidance](#10-flutter-implementation-guidance)

---

# 1. Visual Identity System

## 1.1 Brand Personality Translation

| Personality Trait | Visual Expression |
|-------------------|-------------------|
| Trustworthy | Stable geometric shapes, consistent spacing, muted professional colors |
| Professional | Clean lines, structured layouts, minimal decoration |
| Efficient | High information density, clear hierarchy, fast scanability |
| Reliable | Consistent patterns, predictable interactions, solid foundations |
| Calm | Low-contrast backgrounds, restrained animations, neutral tones |

## 1.2 Emotional Tone Strategy

**Primary Tone:** Calm Confidence
- Interface should feel stable, not exciting
- Success states: subtle confirmation, not celebration
- Error states: helpful guidance, not alarming
- Empty states: constructive direction, not playful illustration

**Emotional Temperature:** Cool-Neutral
- Warm colors reserved for alerts and financial indicators only
- Cool blues and neutrals dominate the interface
- No bright saturated colors in core UI

## 1.3 Visual Language Principles

| Principle | Application |
|-----------|-------------|
| Geometric Precision | All elements aligned to 4px grid |
| Structured Rhythm | Consistent vertical spacing throughout |
| Contained Information | Data grouped in clear bounded areas |
| Hierarchical Clarity | Maximum 3 levels of visual emphasis per screen |
| Purposeful Contrast | Contrast used only for hierarchy, not decoration |

## 1.4 Iconography Style

**Style:** Outlined, Geometric, Consistent Stroke Weight

| Specification | Value |
|---------------|-------|
| Stroke Width | 1.5px (standard), 2px (emphasized) |
| Corner Radius | 2px on icon corners |
| Grid Size | 24x24px (standard), 20x20px (compact), 32x32px (featured) |
| Style | Rounded line icons, not filled |
| Optical Balance | Icons optically centered, not mathematically |

**Icon Categories:**
- Navigation: Simple, instantly recognizable
- Actions: Clear verb representation
- Status: Color-coded with shape differentiation
- Financial: Standardized accounting symbols

**Prohibited:**
- Filled icons in navigation
- Decorative icons without function
- Icons without labels in primary actions
- Inconsistent stroke weights

## 1.5 Shape System

### Corner Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radius-none` | 0px | Tables, data cells |
| `radius-xs` | 2px | Chips, tags, badges |
| `radius-sm` | 4px | Buttons, inputs, small cards |
| `radius-md` | 8px | Cards, dialogs, sheets |
| `radius-lg` | 12px | Modal containers, large cards |
| `radius-xl` | 16px | Bottom sheets, page-level containers |
| `radius-full` | 9999px | Avatars, circular buttons |

### Geometry Principles

- **Primary shapes:** Rectangles with consistent radius
- **Secondary shapes:** Rounded rectangles for containers
- **Accent shapes:** Circles only for avatars and FAB
- **Prohibited:** Irregular shapes, skewed elements, decorative geometry

## 1.6 Elevation & Shadow System

### Light Mode Shadows

| Level | Elevation | Shadow Specification | Usage |
|-------|-----------|---------------------|-------|
| `elevation-0` | 0dp | None | Flat elements, disabled states |
| `elevation-1` | 1dp | `0 1px 2px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.10)` | Cards, inputs |
| `elevation-2` | 2dp | `0 2px 4px rgba(0,0,0,0.06), 0 4px 6px rgba(0,0,0,0.10)` | Raised cards, dropdowns |
| `elevation-3` | 4dp | `0 4px 6px rgba(0,0,0,0.07), 0 10px 15px rgba(0,0,0,0.10)` | Dialogs, popovers |
| `elevation-4` | 8dp | `0 10px 15px rgba(0,0,0,0.10), 0 20px 25px rgba(0,0,0,0.10)` | Bottom sheets, modals |

### Dark Mode Shadows

- Reduced shadow opacity by 50%
- Replace shadows with subtle border (1px) where appropriate
- Use background color layering instead of shadows for hierarchy

### Elevation Principles

- Maximum 2 elevation levels visible simultaneously
- No nested elevated elements
- Elevation indicates interactivity level
- Floating elements always cast shadow

---

# 2. Color System

## 2.1 Color Psychology Justification

| Color Role | Psychological Intent |
|------------|---------------------|
| Primary Blue | Trust, stability, professionalism, calm authority |
| Neutral Grays | Sophistication, balance, reduces visual fatigue |
| Success Green | Growth, positive financial movement, confirmation |
| Warning Amber | Attention without alarm, pending states |
| Error Red | Critical issues, financial losses, requires action |
| Info Blue | Neutral information, guidance, help |

## 2.2 Primary Brand Colors

### Primary Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `primary-50` | #EEF4FF | #0D1A2D | Subtle backgrounds |
| `primary-100` | #DCE8FF | #152640 | Hover states |
| `primary-200` | #C2D6FF | #1D3456 | Active backgrounds |
| `primary-300` | #96B8FF | #2B4A75 | Borders, dividers |
| `primary-400` | #6494FF | #4A7CC9 | Secondary actions |
| `primary-500` | #3B6FE8 | #5A8FE8 | Primary brand color |
| `primary-600` | #2855C5 | #7AA8F5 | Primary buttons |
| `primary-700` | #1E429F | #9EC3FF | Pressed states |
| `primary-800` | #1A3578 | #B8D4FF | Text on light backgrounds |
| `primary-900` | #152952 | #D4E6FF | Headings |

## 2.3 Secondary Palette

### Accent Colors (Sparingly Used)

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `accent-teal-500` | #0D9488 | #2DD4BF | Positive trends, growth indicators |
| `accent-indigo-500` | #6366F1 | #818CF8 | Selected states, focus rings |
| `accent-slate-500` | #64748B | #94A3B8 | Secondary text, icons |

## 2.4 Neutral Grayscale Scale

### 12-Step Neutral Scale

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `neutral-0` | #FFFFFF | #0A0A0B | Pure backgrounds |
| `neutral-50` | #FAFAFA | #111113 | Page backgrounds |
| `neutral-100` | #F4F4F5 | #18181B | Card backgrounds |
| `neutral-150` | #ECECEE | #1F1F23 | Subtle backgrounds |
| `neutral-200` | #E4E4E7 | #27272A | Borders, dividers |
| `neutral-300` | #D4D4D8 | #3F3F46 | Disabled backgrounds |
| `neutral-400` | #A1A1AA | #52525B | Placeholder text |
| `neutral-500` | #71717A | #71717A | Secondary text |
| `neutral-600` | #52525B | #A1A1AA | Body text |
| `neutral-700` | #3F3F46 | #D4D4D8 | Headings |
| `neutral-800` | #27272A | #E4E4E7 | Primary text |
| `neutral-900` | #18181B | #FAFAFA | Highest emphasis |
| `neutral-950` | #0A0A0B | #FFFFFF | Maximum contrast |

## 2.5 Background Layering System

### Light Mode Layers

| Layer | Color | Usage |
|-------|-------|-------|
| `bg-base` | #FAFAFA | App background |
| `bg-surface` | #FFFFFF | Cards, sheets |
| `bg-elevated` | #FFFFFF | Modals, dialogs |
| `bg-overlay` | rgba(0,0,0,0.5) | Scrim behind modals |
| `bg-subtle` | #F4F4F5 | Section backgrounds |
| `bg-muted` | #E4E4E7 | Disabled, inactive areas |

### Dark Mode Layers

| Layer | Color | Usage |
|-------|-------|-------|
| `bg-base` | #0A0A0B | App background |
| `bg-surface` | #18181B | Cards, sheets |
| `bg-elevated` | #1F1F23 | Modals, dialogs |
| `bg-overlay` | rgba(0,0,0,0.7) | Scrim behind modals |
| `bg-subtle` | #111113 | Section backgrounds |
| `bg-muted` | #27272A | Disabled, inactive areas |

## 2.6 Status Colors

### Semantic Status Palette

| Status | Light Mode | Dark Mode | Background (Light) | Background (Dark) |
|--------|------------|-----------|-------------------|-------------------|
| `success` | #059669 | #34D399 | #ECFDF5 | #064E3B |
| `warning` | #D97706 | #FBBF24 | #FFFBEB | #78350F |
| `error` | #DC2626 | #F87171 | #FEF2F2 | #7F1D1D |
| `info` | #2563EB | #60A5FA | #EFF6FF | #1E3A5F |

### Status Color Usage Rules

- Status colors used only for semantic meaning
- Never use status colors for decoration
- Always pair status color with icon for accessibility
- Maintain 4.5:1 contrast ratio minimum

## 2.7 Financial Semantic Colors

| Financial State | Light Mode | Dark Mode | Usage |
|-----------------|------------|-----------|-------|
| `money-positive` | #059669 | #34D399 | Income, profit, credits |
| `money-negative` | #DC2626 | #F87171 | Expense, loss, debits |
| `money-neutral` | #3F3F46 | #A1A1AA | Totals, balances |
| `money-pending` | #D97706 | #FBBF24 | Unpaid, pending amounts |
| `money-overdue` | #BE123C | #FB7185 | Overdue payments |

### Financial Color Rules

- Positive values: green text, no background
- Negative values: red text, optional subtle red background
- Large negative amounts: red background with white text
- Pending amounts: amber/yellow indicator
- Overdue: red with urgency indicator

## 2.8 Complete Light Mode Palette

```
Background System:
- App Background: #FAFAFA
- Surface: #FFFFFF
- Surface Elevated: #FFFFFF
- Surface Subtle: #F4F4F5

Text System:
- Text Primary: #18181B
- Text Secondary: #52525B
- Text Tertiary: #71717A
- Text Disabled: #A1A1AA
- Text Inverse: #FFFFFF

Border System:
- Border Default: #E4E4E7
- Border Strong: #D4D4D8
- Border Subtle: #F4F4F5

Interactive:
- Primary: #3B6FE8
- Primary Hover: #2855C5
- Primary Pressed: #1E429F
- Primary Disabled: #C2D6FF
```

## 2.9 Complete Dark Mode Palette

```
Background System:
- App Background: #0A0A0B
- Surface: #18181B
- Surface Elevated: #1F1F23
- Surface Subtle: #111113

Text System:
- Text Primary: #FAFAFA
- Text Secondary: #A1A1AA
- Text Tertiary: #71717A
- Text Disabled: #52525B
- Text Inverse: #18181B

Border System:
- Border Default: #27272A
- Border Strong: #3F3F46
- Border Subtle: #1F1F23

Interactive:
- Primary: #5A8FE8
- Primary Hover: #7AA8F5
- Primary Pressed: #9EC3FF
- Primary Disabled: #2B4A75
```

## 2.10 Contrast & Accessibility Compliance

| Combination | Contrast Ratio | WCAG Level |
|-------------|----------------|------------|
| Primary Text on Background | 15.8:1 | AAA |
| Secondary Text on Background | 7.2:1 | AAA |
| Primary Button Text | 8.1:1 | AAA |
| Error Text on Background | 6.5:1 | AA |
| Success Text on Background | 5.8:1 | AA |
| Disabled Text | 3.2:1 | Intentional |

### Contrast Requirements

- Body text: minimum 7:1 (targeting AAA)
- Large text (18px+): minimum 4.5:1
- Interactive elements: minimum 4.5:1
- Non-text elements: minimum 3:1
- Focus indicators: minimum 3:1 against adjacent colors

---

# 3. Typography System

## 3.1 Primary Arabic Font Family

**Primary Font:** IBM Plex Sans Arabic

| Weight | Usage |
|--------|-------|
| Regular (400) | Body text, labels |
| Medium (500) | Subheadings, emphasis |
| SemiBold (600) | Headings, buttons |
| Bold (700) | Page titles, critical data |

**Fallback Stack:** `'IBM Plex Sans Arabic', 'Noto Sans Arabic', 'Segoe UI', system-ui, sans-serif`

**Justification:**
- Excellent Arabic glyph coverage
- Optimized for screen readability
- Consistent stroke width
- Clear numeral distinction
- Free and open source

## 3.2 Secondary English Font Family

**Secondary Font:** IBM Plex Sans

| Weight | Usage |
|--------|-------|
| Regular (400) | Body text, labels |
| Medium (500) | Subheadings, emphasis |
| SemiBold (600) | Headings, buttons |
| Bold (700) | Page titles, critical data |

**Fallback Stack:** `'IBM Plex Sans', 'Inter', 'Segoe UI', system-ui, sans-serif`

**Justification:**
- Pairs perfectly with Arabic variant
- Excellent legibility at small sizes
- Tabular numerals available
- Comprehensive character support

## 3.3 Type Scale Hierarchy

### Mobile Type Scale (Base: 16px)

| Token | Size | Line Height | Weight | Letter Spacing | Usage |
|-------|------|-------------|--------|----------------|-------|
| `display-lg` | 32px | 40px (1.25) | Bold | -0.5px | Dashboard totals |
| `display-md` | 28px | 36px (1.28) | Bold | -0.4px | Page titles |
| `display-sm` | 24px | 32px (1.33) | SemiBold | -0.3px | Section headers |
| `heading-lg` | 20px | 28px (1.4) | SemiBold | -0.2px | Card titles |
| `heading-md` | 18px | 26px (1.44) | SemiBold | -0.1px | Subsection titles |
| `heading-sm` | 16px | 24px (1.5) | Medium | 0 | List headers |
| `body-lg` | 16px | 26px (1.62) | Regular | 0 | Primary body text |
| `body-md` | 14px | 22px (1.57) | Regular | 0.1px | Secondary body text |
| `body-sm` | 13px | 20px (1.54) | Regular | 0.1px | Dense content |
| `label-lg` | 14px | 20px (1.43) | Medium | 0.1px | Form labels |
| `label-md` | 13px | 18px (1.38) | Medium | 0.2px | Button text |
| `label-sm` | 12px | 16px (1.33) | Medium | 0.2px | Tags, badges |
| `caption` | 12px | 16px (1.33) | Regular | 0.3px | Helper text |
| `overline` | 11px | 16px (1.45) | Medium | 0.5px | Category labels |

## 3.4 Line Height & Spacing Rules

### Line Height Guidelines

| Content Type | Line Height Ratio |
|--------------|-------------------|
| Headings | 1.25 - 1.35 |
| Body text | 1.5 - 1.62 |
| Dense data | 1.4 - 1.5 |
| Single-line labels | 1.0 |
| Multi-line fields | 1.5 |

### Paragraph Spacing

| Element | Margin Bottom |
|---------|---------------|
| Heading before body | 8px |
| Body paragraph | 16px |
| List items | 8px |
| Section break | 24px |

## 3.5 Numeric Typography Strategy

### Tabular Numerals

- All financial data uses tabular (monospaced) numerals
- Decimal points aligned in columns
- Negative numbers: parentheses or minus sign, consistent per context

### Number Formatting

| Format | Arabic | English |
|--------|--------|---------|
| Thousands separator | ٬ or , | , |
| Decimal separator | ٫ or . | . |
| Currency position | After number | Before number |
| Negative format | (1,234.56) | (1,234.56) |

### Numeric Font Settings

```
font-feature-settings: 'tnum' on, 'lnum' on;
```

## 3.6 Financial Data Typography

### Amount Display Hierarchy

| Amount Type | Style |
|-------------|-------|
| Grand totals | display-lg, Bold, Primary text |
| Subtotals | heading-lg, SemiBold, Primary text |
| Line items | body-md, Regular, Secondary text |
| Tax/discounts | body-sm, Regular, Tertiary text |
| Currency symbols | Same size, Regular weight |

### Currency Display Rules

- Currency symbol always adjacent to number (no space in English)
- Arabic: Number + Space + Currency (١٢٣٤ ر.س)
- Large amounts: abbreviated with suffix (1.2M, 500K)
- Decimals: always show 2 decimal places for currency

## 3.7 Readability Optimization

### Long Session Readability

| Optimization | Implementation |
|--------------|----------------|
| Optimal line length | 45-75 characters per line |
| Text contrast | 15:1 minimum for body text |
| Anti-aliasing | Subpixel rendering enabled |
| Font smoothing | Grayscale for OLED screens |
| Dynamic type | Support system font scaling 85%-200% |

### Arabic-Specific Optimizations

- Minimum Arabic text size: 14px
- Increased line height for Arabic: +10% vs Latin
- Kashida justification disabled (uneven spacing)
- Right-aligned paragraph text
- Proper RTL punctuation handling

---

# 4. Layout & Grid System

## 4.1 Spacing Scale

### 4px Base Unit System

| Token | Value | Usage |
|-------|-------|-------|
| `space-0` | 0px | No spacing |
| `space-0.5` | 2px | Hairline gaps |
| `space-1` | 4px | Tight internal padding |
| `space-2` | 8px | Related element spacing |
| `space-3` | 12px | Standard internal padding |
| `space-4` | 16px | Card padding, list spacing |
| `space-5` | 20px | Section spacing |
| `space-6` | 24px | Large component padding |
| `space-8` | 32px | Section breaks |
| `space-10` | 40px | Major section divisions |
| `space-12` | 48px | Page-level spacing |
| `space-16` | 64px | Maximum spacing |

### Spacing Application Rules

| Context | Spacing |
|---------|---------|
| Between form fields | 16px |
| Between list items | 8px |
| Card internal padding | 16px |
| Section margin | 24px |
| Page edge margin | 16px |
| Button internal padding | 12px horizontal, 8px vertical |

## 4.2 Responsive Breakpoints

### Mobile-First Breakpoints

| Breakpoint | Width | Target |
|------------|-------|--------|
| `mobile-sm` | < 360px | Small phones |
| `mobile-md` | 360px - 389px | Standard phones |
| `mobile-lg` | 390px - 427px | Large phones |
| `mobile-xl` | 428px+ | Extra large phones |
| `tablet` | 600px+ | Tablets portrait |
| `tablet-lg` | 900px+ | Tablets landscape |

### Layout Adjustments Per Breakpoint

| Breakpoint | Grid Columns | Margin | Gutter |
|------------|--------------|--------|--------|
| mobile-sm | 4 | 12px | 8px |
| mobile-md | 4 | 16px | 12px |
| mobile-lg | 4 | 16px | 16px |
| mobile-xl | 6 | 20px | 16px |
| tablet | 8 | 24px | 20px |
| tablet-lg | 12 | 32px | 24px |

## 4.3 RTL-First Grid System

### Grid Principles

- All layouts designed RTL-first
- Logical properties used (start/end, not left/right)
- Mirrored layouts for LTR mode
- Icons with directionality flip in LTR

### Logical Property Mapping

| Physical (Avoid) | Logical (Use) |
|------------------|---------------|
| margin-left | margin-inline-start |
| margin-right | margin-inline-end |
| padding-left | padding-inline-start |
| padding-right | padding-inline-end |
| text-align: left | text-align: start |
| text-align: right | text-align: end |

### RTL-Specific Considerations

- Navigation flows from right to left
- Back button on right side
- Action buttons on left side (primary) or right (secondary)
- Lists start from right
- Numeric data maintains LTR reading for numbers
- Icons that imply direction are mirrored

## 4.4 Data Density Strategy

### Density Levels

| Level | Row Height | Padding | Usage |
|-------|------------|---------|-------|
| Compact | 40px | 8px | Data tables, long lists |
| Standard | 48px | 12px | Default lists |
| Comfortable | 56px | 16px | Primary navigation, featured items |

### Density Contexts

| Screen Type | Recommended Density |
|-------------|---------------------|
| Invoice list | Compact |
| Product grid | Standard |
| Customer list | Standard |
| Dashboard cards | Comfortable |
| Settings | Comfortable |
| Reports tables | Compact |

### Information Hierarchy in Dense Layouts

- Primary info: Full opacity, standard size
- Secondary info: 70% opacity, smaller size
- Tertiary info: 50% opacity, smallest size
- Maximum 3 information levels per row

## 4.5 Form Layout Strategy

### Single Column Forms

- Maximum width: 600px
- Full-width inputs on mobile
- Labels above inputs (not inline)
- Required indicator: asterisk after label

### Form Field Spacing

| Element | Spacing |
|---------|---------|
| Label to input | 6px |
| Input to helper text | 4px |
| Field to next field | 16px |
| Section to section | 24px |
| Form to action buttons | 32px |

### Form Group Layout

```
[Label + Required Indicator]
[Input Field]
[Helper Text / Error Message]
[16px spacing]
[Next Field Group]
```

### Multi-Column Forms (Tablet)

- 2 columns maximum
- Related fields grouped horizontally
- Full-width for text areas and large inputs
- Maintain top-aligned labels

## 4.6 Table & List Density Rules

### Table Layout

| Component | Specification |
|-----------|---------------|
| Header height | 44px |
| Row height (compact) | 40px |
| Row height (standard) | 48px |
| Cell padding | 12px horizontal, 8px vertical |
| Column min-width | 80px |
| Sticky header | Yes |
| Horizontal scroll | Allowed with fixed first column |

### Table Column Alignment

| Data Type | Alignment |
|-----------|-----------|
| Text | Start (RTL: Right) |
| Numbers | End (RTL: Left) |
| Currency | End with decimal alignment |
| Dates | Start |
| Actions | Center |
| Status | Center |

### List Item Layout

```
┌─────────────────────────────────────────────────┐
│ [Avatar/Icon] [Primary Text]      [Amount/Data] │
│               [Secondary Text]    [Status/Meta] │
│               [Tertiary Text]                   │
└─────────────────────────────────────────────────┘
```

## 4.7 Dashboard Layout Patterns

### Card Grid System

| Screen Width | Columns | Card Min-Width |
|--------------|---------|----------------|
| < 390px | 1 | 100% |
| 390px - 599px | 2 | 170px |
| 600px - 899px | 3 | 180px |
| 900px+ | 4 | 200px |

### Dashboard Sections (Top to Bottom)

1. Summary Cards (KPIs)
2. Quick Actions
3. Recent Activity
4. Charts/Trends (collapsible)
5. Pending Items

### Widget Sizing

| Widget Type | Height | Span |
|-------------|--------|------|
| KPI Card | 100px | 1 column |
| Quick Action | 56px | Full width |
| Recent List | Auto (max 5 items) | Full width |
| Chart | 200px | Full width |

---

# 5. Component Design System

## 5.1 Buttons

### Button Types

| Type | Usage | Priority |
|------|-------|----------|
| Primary | Main actions, submit, confirm | Highest |
| Secondary | Alternative actions, cancel | Medium |
| Tertiary | Low-emphasis actions | Low |
| Ghost | Inline actions, navigation | Lowest |
| Destructive | Delete, remove, dangerous actions | Context-specific |

### Button Sizes

| Size | Height | Padding H | Font Size | Icon Size |
|------|--------|-----------|-----------|-----------|
| Large | 52px | 24px | 16px | 24px |
| Medium | 44px | 20px | 14px | 20px |
| Small | 36px | 16px | 13px | 18px |
| Compact | 32px | 12px | 12px | 16px |

### Button States

| State | Visual Change |
|-------|---------------|
| Default | Base styling |
| Hover | 10% darker background |
| Pressed | 20% darker background |
| Focused | 2px focus ring, 2px offset |
| Disabled | 40% opacity, no interaction |
| Loading | Spinner replaces text/icon |

### Primary Button Specification

```
Background: primary-600
Text: white
Border: none
Radius: 4px
Shadow: elevation-1
Font: label-md, SemiBold
Min-width: 88px

Hover: primary-700
Pressed: primary-800
Disabled: primary-300, 60% opacity
```

### Button Layout Rules

- Icon + Text: 8px gap
- Icon-only: Square aspect ratio
- Full-width on mobile forms
- Right-aligned in dialogs (RTL: left-aligned)
- Primary action on leading side

## 5.2 Inputs

### Text Input Types

| Type | Usage |
|------|-------|
| Standard | Single-line text entry |
| Number | Numeric input with steppers |
| Currency | Amount input with currency display |
| Search | Search with clear button |
| Password | Obscured with toggle |
| Multiline | Text area, auto-growing |

### Input Anatomy

```
┌─────────────────────────────────────────────────┐
│ [Label*] [Optional Badge]                       │
├─────────────────────────────────────────────────┤
│ [Prefix] [Input Text                 ] [Suffix] │
├─────────────────────────────────────────────────┤
│ [Helper text or Error message]                  │
└─────────────────────────────────────────────────┘
```

### Input Sizes

| Size | Height | Font Size | Label Size |
|------|--------|-----------|------------|
| Large | 52px | 16px | 14px |
| Medium | 44px | 14px | 13px |
| Small | 36px | 13px | 12px |

### Input States

| State | Border | Background | Label |
|-------|--------|------------|-------|
| Default | neutral-300 | neutral-0 | neutral-600 |
| Hover | neutral-400 | neutral-0 | neutral-600 |
| Focused | primary-500 (2px) | neutral-0 | primary-600 |
| Filled | neutral-300 | neutral-0 | neutral-600 |
| Error | error-500 | error-50 | error-600 |
| Disabled | neutral-200 | neutral-100 | neutral-400 |
| Read-only | neutral-200 | neutral-50 | neutral-500 |

### Currency Input Specification

```
Structure: [Currency Symbol] [Amount Input] [.] [Decimals]
Currency position: Prefix (configurable)
Decimal places: 2 (configurable)
Thousand separators: Auto-formatted
Keyboard: Numeric
Alignment: End (right in RTL)
```

## 5.3 Dropdowns / Select

### Dropdown Types

| Type | Usage |
|------|-------|
| Single Select | Choose one option |
| Multi Select | Choose multiple with chips |
| Searchable | Large option lists |
| Grouped | Categorized options |

### Dropdown Specifications

```
Trigger height: Same as input size
Menu max-height: 300px
Option height: 44px
Option padding: 12px 16px
Checkbox/Radio size: 20px
Search input: Sticky at top
```

### Dropdown States

- Closed: Chevron down icon
- Open: Chevron up icon, elevated menu
- Selected: Checkmark on selected option
- Disabled: Grayed out, no interaction

## 5.4 Tables

### Table Structure

```
┌─────────────────────────────────────────────────┐
│ [Checkbox] [Header 1] [Header 2] [...] [Actions]│ <- Sticky
├─────────────────────────────────────────────────┤
│ [Checkbox] [Cell 1  ] [Cell 2  ] [...] [Actions]│
│ [Checkbox] [Cell 1  ] [Cell 2  ] [...] [Actions]│
│ [Checkbox] [Cell 1  ] [Cell 2  ] [...] [Actions]│
├─────────────────────────────────────────────────┤
│ [Pagination / Load More]                        │
└─────────────────────────────────────────────────┘
```

### Table Specifications

| Component | Value |
|-----------|-------|
| Header background | neutral-50 |
| Header text | neutral-700, SemiBold |
| Row background | neutral-0 |
| Row hover | neutral-50 |
| Row selected | primary-50 |
| Border | 1px neutral-200 |
| Sort indicator | Arrow icon |

### Mobile Table Adaptation

- Convert to card list below 600px
- Show 3-4 most important fields
- Expand for full details
- Swipe actions for quick operations

## 5.5 Cards

### Card Types

| Type | Usage |
|------|-------|
| Basic | Simple content container |
| Interactive | Clickable, navigates |
| Expandable | Shows more on interaction |
| Actionable | Has action buttons |

### Card Specifications

```
Background: surface (neutral-0)
Border: 1px neutral-200
Radius: 8px
Shadow: elevation-1
Padding: 16px
Gap between cards: 12px
```

### Card Anatomy

```
┌─────────────────────────────────────────────────┐
│ [Header with Title]              [Menu/Actions] │
├─────────────────────────────────────────────────┤
│                                                 │
│ [Card Content]                                  │
│                                                 │
├─────────────────────────────────────────────────┤
│ [Footer with Secondary Info or Actions]         │
└─────────────────────────────────────────────────┘
```

### Interactive Card States

| State | Visual Change |
|-------|---------------|
| Default | elevation-1 |
| Hover | elevation-2, subtle background |
| Pressed | elevation-1, darker background |
| Focused | 2px primary focus ring |
| Selected | Primary border, primary-50 background |

## 5.6 Lists

### List Item Structure

```
Standard:
┌─────────────────────────────────────────────────┐
│ [Leading] [Content Area]              [Trailing]│
└─────────────────────────────────────────────────┘

Detailed:
┌─────────────────────────────────────────────────┐
│ [Avatar] [Title]                        [Value] │
│          [Subtitle]                    [Status] │
│          [Meta info]              [Timestamp]   │
└─────────────────────────────────────────────────┘
```

### List Specifications

| Component | Value |
|-----------|-------|
| Item min-height | 48px |
| Leading width | 40px (icon) / 48px (avatar) |
| Content padding | 12px |
| Trailing width | Auto |
| Divider | 1px neutral-100, inset |

### List Interactions

- Tap: Navigate or select
- Long press: Context menu
- Swipe right (RTL: left): Primary action
- Swipe left (RTL: right): Secondary/Delete action

## 5.7 Filters

### Filter Bar Layout

```
┌─────────────────────────────────────────────────┐
│ [Search Input                           ] [Icon]│
├─────────────────────────────────────────────────┤
│ [Chip] [Chip] [Chip] [+ More Filters]          │
└─────────────────────────────────────────────────┘
```

### Filter Chip Specifications

```
Height: 32px
Padding: 8px 12px
Radius: 16px (pill shape)
Font: label-sm, Medium
Background (unselected): neutral-100
Background (selected): primary-100
Border (selected): 1px primary-300
Close icon: 16px, on selected chips
```

### Filter Panel (Advanced)

- Bottom sheet on mobile
- Slide-in panel on tablet
- Grouped by category
- Apply/Clear all buttons
- Active filter count badge

## 5.8 Dialogs

### Dialog Types

| Type | Usage |
|------|-------|
| Alert | Simple message, 1-2 actions |
| Confirmation | Destructive action confirmation |
| Form | Quick data entry |
| Full-screen | Complex multi-step flows |

### Dialog Specifications

```
Max-width: 400px (mobile), 480px (tablet)
Min-width: 280px
Radius: 12px
Padding: 24px
Background: surface
Shadow: elevation-4
Overlay: 50% black
```

### Dialog Anatomy

```
┌─────────────────────────────────────────────────┐
│ [Title]                                    [X]  │
├─────────────────────────────────────────────────┤
│                                                 │
│ [Dialog Content]                                │
│                                                 │
├─────────────────────────────────────────────────┤
│                      [Secondary] [Primary]      │
└─────────────────────────────────────────────────┘
```

### Dialog Button Placement (RTL)

- Primary action: Left side
- Secondary action: Right of primary
- Destructive: Left, red styled
- Cancel: Text button, far right

## 5.9 Bottom Sheets

### Bottom Sheet Types

| Type | Height | Usage |
|------|--------|-------|
| Compact | Auto (max 40%) | Quick actions, confirmations |
| Standard | 50% | Forms, selections |
| Expanded | 90% | Complex content |
| Full | 100% | Full-screen alternative |

### Bottom Sheet Specifications

```
Radius: 16px (top corners)
Handle: 32px x 4px, centered, neutral-300
Padding: 16px (sides), 8px (top), 24px (bottom)
Shadow: elevation-4
Safe area: Bottom padding for home indicator
```

### Bottom Sheet Behavior

- Drag to dismiss
- Snap points: collapsed, half, expanded
- Scrim tap to dismiss
- Keyboard pushes content up

## 5.10 App Bars

### Top App Bar Specifications

```
Height: 56px (standard), 64px (large)
Background: surface
Elevation: elevation-1 or 0 (flat)
Title: heading-md, centered or start-aligned
```

### Top App Bar Anatomy

```
┌─────────────────────────────────────────────────┐
│ [Nav Icon]  [Title]              [Action Icons] │
└─────────────────────────────────────────────────┘

RTL Layout:
┌─────────────────────────────────────────────────┐
│ [Action Icons]              [Title]  [Nav Icon] │
└─────────────────────────────────────────────────┘
```

### App Bar Variants

| Variant | Behavior |
|---------|----------|
| Fixed | Always visible |
| Scroll | Hides on scroll down, shows on scroll up |
| Collapsing | Large title collapses to standard |
| Search | Transforms to search input |

## 5.11 Navigation Bars

### Bottom Navigation Specifications

```
Height: 64px + safe area
Background: surface
Border top: 1px neutral-200
Items: 3-5 maximum
Active indicator: Pill shape, primary-100
Icon size: 24px
Label: caption, Medium
```

### Bottom Navigation States

| State | Icon | Label | Background |
|-------|------|-------|------------|
| Inactive | neutral-500 | neutral-500 | none |
| Active | primary-600 | primary-600 | primary-100 pill |
| Pressed | primary-700 | primary-700 | primary-200 pill |

### Navigation Structure

```
┌─────────────────────────────────────────────────┐
│   [Icon]    [Icon]    [Icon]    [Icon]    [Icon]│
│   Label     Label     Label     Label     Label │
└─────────────────────────────────────────────────┘
```

## 5.12 Floating Action Buttons

### FAB Specifications

| Size | Dimensions | Icon Size |
|------|------------|-----------|
| Standard | 56px | 24px |
| Small | 40px | 20px |
| Extended | 56px height, auto width | 24px + text |

### FAB Styling

```
Background: primary-600
Icon/Text: white
Shadow: elevation-3
Radius: 16px (standard), 28px (pill for extended)
Position: 16px from edges
```

### FAB Behavior

- Single primary action per screen
- Hide on scroll down (optional)
- Speed dial for multiple related actions
- Never more than 6 speed dial options

## 5.13 Empty States

### Empty State Anatomy

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              [Illustration/Icon]                │
│                                                 │
│                [Title]                          │
│             [Description]                       │
│                                                 │
│              [Action Button]                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Empty State Specifications

```
Icon/Illustration size: 120px
Icon color: neutral-300
Title: heading-md, neutral-700
Description: body-md, neutral-500, center-aligned
Max-width: 280px
Action: Primary button or text link
```

### Empty State Content Guidelines

| Screen | Title | Action |
|--------|-------|--------|
| Invoice list | لا توجد فواتير | إنشاء فاتورة جديدة |
| Customer list | لا يوجد عملاء | إضافة عميل |
| Product list | لا توجد منتجات | إضافة منتج |
| Search results | لا توجد نتائج | تعديل البحث |

## 5.14 Error States

### Error Message Types

| Type | Visual | Location |
|------|--------|----------|
| Inline | Red text below input | Attached to field |
| Banner | Full-width alert | Top of form/screen |
| Toast | Temporary notification | Bottom of screen |
| Dialog | Modal alert | Center of screen |

### Error State Specifications

```
Inline Error:
- Text: caption, error-600
- Icon: 16px error icon
- Input border: error-500

Banner Error:
- Background: error-50
- Border-left: 4px error-500
- Icon: 24px, error-500
- Title: label-md, error-700
- Message: body-sm, error-600
- Dismiss: X button
```

### Error Content Guidelines

- State what went wrong clearly
- Provide actionable solution
- Never blame the user
- Use simple, non-technical language
- Arabic example: "يرجى إدخال رقم صحيح" not "خطأ في التنسيق"

## 5.15 Loading States

### Loading Types

| Type | Usage |
|------|-------|
| Spinner | Button actions, small areas |
| Progress bar | Known duration, file uploads |
| Skeleton | Page/content loading |
| Shimmer | List and card placeholders |

### Loading Specifications

```
Spinner:
- Size: 20px (inline), 32px (centered)
- Color: primary-500 or current text color
- Animation: 800ms rotation

Progress Bar:
- Height: 4px
- Track: neutral-200
- Fill: primary-500
- Radius: 2px

Skeleton:
- Background: neutral-200
- Animation: shimmer left-to-right (RTL: right-to-left)
- Duration: 1.5s
- Radius: match actual content
```

### Skeleton Patterns

```
Text skeleton:
████████████████████ 100% width
████████████ 60% width

Card skeleton:
┌─────────────────────────────────────────────────┐
│ ██ ████████████████              ████           │
│    ██████████                    ██             │
└─────────────────────────────────────────────────┘
```

---

# 6. UX Architecture & Navigation Model

## 6.1 Information Architecture

### Primary Structure

```
App Root
├── Dashboard (Home)
│   ├── Summary KPIs
│   ├── Quick Actions
│   ├── Recent Activity
│   └── Alerts/Notifications
│
├── Invoices
│   ├── Invoice List (All/Filtered)
│   ├── Create Invoice
│   ├── Invoice Detail
│   └── Invoice Actions (Send, Print, etc.)
│
├── Products & Services
│   ├── Product List
│   ├── Product Detail
│   ├── Categories
│   └── Inventory Status
│
├── Customers
│   ├── Customer List
│   ├── Customer Detail
│   ├── Customer Statement
│   └── Customer Groups
│
├── Reports
│   ├── Sales Reports
│   ├── Financial Reports
│   ├── Tax Reports
│   └── Custom Reports
│
└── Settings
    ├── Business Profile
    ├── Invoice Settings
    ├── Tax Configuration
    ├── User Management
    ├── Integrations
    └── App Preferences
```

## 6.2 Navigation Hierarchy

### Primary Navigation (Bottom Bar)

| Position | Item | Icon | Shortcut |
|----------|------|------|----------|
| 1 | الرئيسية (Dashboard) | Home | Default |
| 2 | الفواتير (Invoices) | Receipt | Most used |
| 3 | + إنشاء (Create) | Plus | FAB alternative |
| 4 | المنتجات (Products) | Box | Inventory |
| 5 | المزيد (More) | Menu | Settings, Reports |

### Secondary Navigation (More Menu)

```
المزيد
├── العملاء (Customers)
├── التقارير (Reports)
├── الإعدادات (Settings)
├── المساعدة (Help)
└── تسجيل الخروج (Logout)
```

## 6.3 Tab & Drawer Logic

### When to Use Tabs

- Parallel content of same type (e.g., Invoice status: All, Paid, Pending)
- Maximum 4 tabs
- Swipeable navigation
- Tab indicator visible

### When to Use Drawer

- Secondary navigation
- User profile access
- Business switching (multi-business)
- Less frequent features

### Tab Specifications

```
Tab bar height: 48px
Tab indicator: 2px, primary color
Tab text: label-md, SemiBold
Active: primary-600
Inactive: neutral-500
Min-width: 90px per tab
```

## 6.4 Shortcut Flows

### Quick Invoice Creation

```
Dashboard → FAB → Quick Invoice → Done
Total taps: 3
Time target: <15 seconds for repeat item
```

### Quick Customer Add

```
Invoice → Add Customer → Quick Form → Save
Total taps: 4
Inline creation without leaving context
```

### Keyboard Shortcuts (Connected Keyboard)

| Action | Shortcut |
|--------|----------|
| New Invoice | Ctrl/Cmd + N |
| Search | Ctrl/Cmd + K |
| Save | Ctrl/Cmd + S |
| Print | Ctrl/Cmd + P |
| Close | Escape |

## 6.5 One-Hand Usability

### Thumb Zone Optimization

```
┌─────────────────────┐
│     Hard to reach   │ <- Critical actions avoid
├─────────────────────┤
│     Reachable       │ <- Secondary actions
├─────────────────────┤
│     Easy reach      │ <- Primary actions
├─────────────────────┤
│     [Navigation]    │ <- Always accessible
└─────────────────────┘
```

### One-Hand Design Rules

- Primary actions in bottom 60% of screen
- FAB positioned for right-thumb (RTL: left-thumb)
- Swipe gestures for common actions
- No critical actions in top corners
- Pull-to-refresh for lists

### Gesture Support

| Gesture | Action |
|---------|--------|
| Swipe down | Refresh list |
| Swipe right (RTL) | Go back |
| Swipe item left | Delete/Archive |
| Swipe item right | Primary action |
| Long press | Context menu |

## 6.6 High-Speed Workflows

### Invoice Creation Optimization

1. **Smart Defaults**: Last-used customer, current date, sequential number
2. **Product Search**: Instant search with barcode support
3. **Quick Add**: +/- buttons for quantity
4. **Auto-Calculate**: Real-time totals, tax, discounts
5. **One-Tap Send**: Direct to WhatsApp/Email

### Workflow Time Targets

| Task | Target Time |
|------|-------------|
| Create simple invoice | <30 seconds |
| Add existing customer | <5 seconds |
| Add existing product | <3 seconds |
| Repeat last invoice | <10 seconds |
| Search and find invoice | <5 seconds |

### Speed Features

- Recent items list (last 5 customers, products)
- Barcode scanning for products
- Voice input for notes
- Copy invoice function
- Templates for recurring invoices

## 6.7 Error Prevention Patterns

### Input Validation Strategy

| Timing | Validation Type |
|--------|-----------------|
| Real-time | Format validation (phone, email) |
| On blur | Required field, business rules |
| On submit | Full form validation |

### Prevention Techniques

- Disable submit until valid
- Confirm before destructive actions
- Auto-save drafts
- Warn on unsaved changes
- Validate business rules (e.g., stock check)

### Confirmation Required For

- Delete invoice
- Void invoice
- Delete customer with history
- Delete product with stock
- Change invoice status
- Bulk operations

### Confirmation Dialog Pattern

```
Title: Clear action description
Body: Consequence explanation
Primary: Confirm with specific verb (Delete, not OK)
Secondary: Cancel
Destructive: Red primary button
```

## 6.8 Undo / Recovery Patterns

### Undo Support

| Action | Undo Method | Duration |
|--------|-------------|----------|
| Delete draft | Toast with Undo button | 8 seconds |
| Archive item | Toast with Undo button | 8 seconds |
| Status change | Toast with Undo button | 5 seconds |
| Bulk delete | Confirmation first, no undo | - |

### Recovery Features

- Draft auto-save every 30 seconds
- Invoice version history
- Deleted items in trash (30 days)
- Export data backup
- Offline queue for sync failures

### Undo Toast Pattern

```
┌─────────────────────────────────────────────────┐
│ تم الحذف                              [تراجع]   │
└─────────────────────────────────────────────────┘
Duration: 8 seconds
Position: Bottom, above navigation
Action: Single tap to undo
```

---

# 7. Long Usage Comfort Strategy

## 7.1 Eye Strain Reduction Techniques

### Color Temperature

- Avoid pure white (#FFFFFF) as main background
- Light mode background: #FAFAFA (warm white)
- Dark mode: True dark (#0A0A0B), not pure black
- Reduce blue light emission in dark mode

### Contrast Management

- Body text: 15:1 contrast (exceeds AA)
- Large text: 10:1 contrast
- Avoid maximum contrast for large areas
- Use neutral-800 for text, not neutral-950

### Visual Techniques

| Technique | Implementation |
|-----------|----------------|
| Soft edges | Subtle borders, avoid harsh lines |
| Muted backgrounds | Off-white, not pure white |
| Reduced saturation | Pastels for status colors where possible |
| Ambient dark mode | True dark, not gray |

## 7.2 Cognitive Load Minimization

### Information Chunking

- Maximum 7 items in any list without grouping
- Group related information visually
- Progressive disclosure for complex data
- Default collapsed for secondary information

### Decision Reduction

- Smart defaults reduce choices
- Recommend options based on history
- Limit options in dropdowns (show common first)
- Auto-complete where possible

### Visual Hierarchy Rules

- One primary action per screen
- Maximum 3 levels of text hierarchy
- Clear section separation
- Consistent placement of actions

## 7.3 Visual Rhythm

### Consistent Spacing

- Vertical rhythm based on 8px baseline
- Consistent margins and padding
- Predictable section breaks
- Aligned grid across screens

### Repetition Patterns

- Same component styles throughout
- Consistent icon sizes and styles
- Predictable layout patterns
- Familiar interaction models

### Rhythm Specifications

```
Section spacing: 24px
Card spacing: 12px
List item spacing: 8px
Form field spacing: 16px
Page margin: 16px
```

## 7.4 Session Fatigue Prevention

### Break Indicators

- Optional break reminders (every 2 hours)
- Daily summary at session end
- Progress indicators for long tasks

### Session Continuity

- Remember scroll position
- Preserve filter state
- Quick resume to last screen
- Draft persistence

### Micro-Break Opportunities

- Natural pauses after completing tasks
- Success states that don't demand immediate action
- Non-intrusive notifications

## 7.5 Micro-Interaction Restraint

### Animation Guidelines

| Context | Animation | Duration |
|---------|-----------|----------|
| Button press | Subtle scale | 100ms |
| Page transition | Slide/fade | 200ms |
| Modal open | Fade + scale | 200ms |
| Success state | Checkmark appear | 300ms |
| Loading | Continuous spinner | Infinite |

### Prohibited Animations

- Bouncing elements
- Continuous pulsing (except loading)
- Celebratory confetti
- Complex path animations
- Parallax effects

### Animation Principles

- Functional, not decorative
- Convey state change
- Guide attention
- Respect reduced motion preference

## 7.6 Contrast Balancing

### Light Mode Contrast

| Element | Foreground | Background | Ratio |
|---------|------------|------------|-------|
| Primary text | neutral-800 | neutral-50 | 15:1 |
| Secondary text | neutral-600 | neutral-50 | 7.5:1 |
| Placeholder | neutral-400 | neutral-0 | 4.5:1 |
| Borders | neutral-200 | neutral-0 | 1.5:1 |

### Dark Mode Contrast

| Element | Foreground | Background | Ratio |
|---------|------------|------------|-------|
| Primary text | neutral-100 | neutral-950 | 15:1 |
| Secondary text | neutral-400 | neutral-950 | 6:1 |
| Placeholder | neutral-500 | neutral-900 | 4:1 |
| Borders | neutral-700 | neutral-900 | 1.8:1 |

### Balance Techniques

- Avoid high contrast for large areas
- Use medium contrast for dense data
- Reserve high contrast for critical elements
- Soften disabled state contrast

## 7.7 Motion Economy

### Motion Budget Per Screen

- Maximum 2 simultaneous animations
- Maximum 1 attention-grabbing animation
- Prefer opacity over movement
- Prefer short over long durations

### Motion Hierarchy

| Priority | Animation Type | Example |
|----------|----------------|---------|
| Essential | State feedback | Button press |
| Important | Orientation | Page transition |
| Optional | Delight | Success checkmark |
| Avoid | Decoration | Floating elements |

### Reduced Motion Support

- Respect `prefers-reduced-motion`
- Instant state changes (no animation)
- Static alternatives for all animated content
- No auto-playing animations

---

# 8. Screen Design Guidelines

## 8.1 Dashboard

### Purpose
Central hub for business overview and quick actions

### Layout Structure

```
┌─────────────────────────────────────────────────┐
│ [App Bar: Business Name]      [Notifications]   │
├─────────────────────────────────────────────────┤
│ [Date Range Selector]                           │
├─────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐│
│ │ إجمالي  │ │ مستحق   │ │  مدفوع  │ │ متأخر   ││
│ │ المبيعات│ │ التحصيل │ │         │ │         ││
│ │  12,500 │ │  4,200  │ │  8,300  │ │   450   ││
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────────────────┤
│ الإجراءات السريعة                               │
│ [فاتورة جديدة] [عميل جديد] [منتج جديد]         │
├─────────────────────────────────────────────────┤
│ النشاط الأخير                           [المزيد]│
│ ├─ فاتورة #1234 - أحمد محمد          1,200 ر.س│
│ ├─ فاتورة #1233 - شركة الوفاء          850 ر.س│
│ └─ فاتورة #1232 - محل السلام           300 ر.س│
├─────────────────────────────────────────────────┤
│ تنبيهات                                         │
│ ├─ 3 فواتير متأخرة تحتاج متابعة                │
│ └─ مخزون منخفض: 5 منتجات                       │
└─────────────────────────────────────────────────┘
```

### KPI Card Specifications

| Metric | Color Indicator | Trend |
|--------|-----------------|-------|
| Total Sales | Primary | Arrow up/down |
| Receivables | Warning (amber) | - |
| Collected | Success (green) | - |
| Overdue | Error (red) | Count badge |

### UX Guidelines

- KPIs update in real-time
- Pull to refresh entire dashboard
- Tap KPI card to see detail breakdown
- Quick actions limited to 3 most used
- Recent activity shows last 5 items
- Alerts are dismissible

## 8.2 Invoice Creation

### Purpose
Efficient creation of professional invoices

### Flow Steps

```
Step 1: Customer Selection
↓
Step 2: Add Items (Products/Services)
↓
Step 3: Review & Adjustments
↓
Step 4: Preview & Send
```

### Screen Layout

```
┌─────────────────────────────────────────────────┐
│ [←] فاتورة جديدة                      [مسودة]  │
├─────────────────────────────────────────────────┤
│ العميل *                                        │
│ ┌─────────────────────────────────────────────┐ │
│ │ اختر عميلاً                          [+]   │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ التاريخ: 25/01/2026        رقم: INV-2026-0125  │
├─────────────────────────────────────────────────┤
│ المنتجات                               [+ إضافة]│
│ ┌─────────────────────────────────────────────┐ │
│ │ منتج 1                    2 × 150 = 300 ر.س│ │
│ │ منتج 2                    1 × 200 = 200 ر.س│ │
│ └─────────────────────────────────────────────┘ │
│ [+ أضف منتجاً أو خدمة]                          │
├─────────────────────────────────────────────────┤
│ ملاحظات (اختياري)                               │
│ ┌─────────────────────────────────────────────┐ │
│ │                                             │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│                           المجموع الفرعي  500.00│
│                           الضريبة (15%)    75.00│
│                           ─────────────────────│
│                           الإجمالي       575.00│
├─────────────────────────────────────────────────┤
│ [إلغاء]                    [معاينة] [حفظ وإرسال]│
└─────────────────────────────────────────────────┘
```

### UX Guidelines

- Auto-save draft every 30 seconds
- Customer field: search + recent + add new inline
- Product add: search, barcode scan, or quick add
- Quantity adjustment: +/- buttons or direct input
- Real-time total calculation
- Swipe to delete line items
- Preview before sending (required)

### Quick Add Product Flow

```
[+ أضف منتجاً]
     ↓
┌─────────────────────────────────────────────────┐
│ [Search: ابحث عن منتج]              [Barcode]  │
├─────────────────────────────────────────────────┤
│ الأخيرة                                         │
│ ├─ منتج أ                              150 ر.س│
│ ├─ منتج ب                              200 ر.س│
│ └─ منتج ج                               80 ر.س│
├─────────────────────────────────────────────────┤
│ [+ إنشاء منتج جديد]                             │
└─────────────────────────────────────────────────┘
```

## 8.3 Invoice List

### Purpose
Browse, search, and manage all invoices

### Screen Layout

```
┌─────────────────────────────────────────────────┐
│ الفواتير                        [Search] [Filter]│
├─────────────────────────────────────────────────┤
│ [الكل] [مدفوعة] [معلقة] [متأخرة] [مسودات]       │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ INV-2026-0125              25 يناير 2026   │ │
│ │ أحمد محمد                                  │ │
│ │ 575.00 ر.س                     [● مدفوعة]  │ │
│ └─────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────┐ │
│ │ INV-2026-0124              24 يناير 2026   │ │
│ │ شركة الوفاء للتجارة                        │ │
│ │ 1,200.00 ر.س                   [● معلقة]   │ │
│ └─────────────────────────────────────────────┘ │
│                    ...                          │
├─────────────────────────────────────────────────┤
│ [Load More / Infinite Scroll]                   │
└─────────────────────────────────────────────────┘
│ [+] FAB: فاتورة جديدة                          │
```

### Filter Options

| Filter | Type | Options |
|--------|------|---------|
| Status | Multi-select chips | All, Paid, Pending, Overdue, Draft |
| Date Range | Date picker | Today, Week, Month, Custom |
| Customer | Search select | All customers |
| Amount | Range slider | Min - Max |

### List Item Actions (Swipe)

- Swipe Left (RTL: Right): Delete/Archive
- Swipe Right (RTL: Left): Mark as Paid
- Tap: Open details
- Long press: Context menu

### UX Guidelines

- Default sort: Newest first
- Show status with color badge
- Overdue items highlighted
- Pull to refresh
- Infinite scroll or pagination (50 items)
- Empty state with "Create First Invoice" CTA

## 8.4 Invoice Details

### Purpose
View complete invoice information and take actions

### Screen Layout

```
┌─────────────────────────────────────────────────┐
│ [←] فاتورة INV-2026-0125            [⋮ المزيد] │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ [● مدفوعة]                    575.00 ر.س   │ │
│ │ 25 يناير 2026                              │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ بيانات العميل                                   │
│ أحمد محمد                                       │
│ +966 50 123 4567                               │
│ ahmed@email.com                                 │
├─────────────────────────────────────────────────┤
│ البنود                                          │
│ ├─ منتج 1              2 × 150.00 = 300.00 ر.س│
│ └─ منتج 2              1 × 200.00 = 200.00 ر.س│
│ ───────────────────────────────────────────────│
│ المجموع الفرعي                        500.00   │
│ الضريبة (15%)                          75.00   │
│ الإجمالي                              575.00   │
├─────────────────────────────────────────────────┤
│ سجل الدفعات                                     │
│ └─ 575.00 ر.س - 25 يناير - نقدي                │
├─────────────────────────────────────────────────┤
│ [طباعة]  [مشاركة]  [تسجيل دفعة]                │
└─────────────────────────────────────────────────┘
```

### Action Menu (⋮)

```
├─ تعديل الفاتورة
├─ نسخ الفاتورة
├─ تحويل لعرض سعر
├─ إرسال تذكير
├─ تحميل PDF
├─ إلغاء الفاتورة
└─ حذف
```

### UX Guidelines

- Status prominently displayed
- Customer info tappable (call, email, WhatsApp)
- Line items expandable for details
- Payment history chronological
- Actions relevant to status
- Share generates PDF or link

## 8.5 Product Management

### Purpose
Manage product catalog and inventory

### List View Layout

```
┌─────────────────────────────────────────────────┐
│ المنتجات                        [Search] [Filter]│
├─────────────────────────────────────────────────┤
│ [الكل] [متوفر] [منخفض] [نفد]                    │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ [Img] منتج 1                                │ │
│ │       SKU: PRD-001         الكمية: 45      │ │
│ │       150.00 ر.س             [● متوفر]     │ │
│ └─────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────┐ │
│ │ [Img] منتج 2                                │ │
│ │       SKU: PRD-002         الكمية: 3       │ │
│ │       200.00 ر.س             [● منخفض]     │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
│ [+] FAB: منتج جديد                             │
```

### Product Detail Layout

```
┌─────────────────────────────────────────────────┐
│ [←] منتج 1                            [تعديل]  │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │              [Product Image]                │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ 150.00 ر.س                                      │
│ SKU: PRD-001                                    │
│ التصنيف: إلكترونيات                             │
├─────────────────────────────────────────────────┤
│ المخزون                                         │
│ الكمية المتاحة: 45                              │
│ حد إعادة الطلب: 10                              │
│ [تعديل المخزون]                                 │
├─────────────────────────────────────────────────┤
│ حركة المخزون                           [المزيد]│
│ ├─ -2 فاتورة INV-0125           25 يناير     │
│ └─ +50 شراء PO-0089             20 يناير     │
└─────────────────────────────────────────────────┘
```

### UX Guidelines

- Image thumbnail in list view
- Stock status color-coded
- Quick stock adjustment
- Barcode display and scan
- Movement history tracked
- Low stock alerts

## 8.6 Customer Management

### Purpose
Manage customer database and relationships

### List View Layout

```
┌─────────────────────────────────────────────────┐
│ العملاء                         [Search] [Filter]│
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ [Avatar] أحمد محمد                          │ │
│ │          +966 50 123 4567                   │ │
│ │          إجمالي المشتريات: 12,500 ر.س      │ │
│ └─────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────┐ │
│ │ [Avatar] شركة الوفاء للتجارة                │ │
│ │          +966 11 234 5678                   │ │
│ │          إجمالي المشتريات: 45,000 ر.س      │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
│ [+] FAB: عميل جديد                             │
```

### Customer Detail Layout

```
┌─────────────────────────────────────────────────┐
│ [←] أحمد محمد                         [تعديل]  │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │ [Avatar]  أحمد محمد                         │ │
│ │           +966 50 123 4567                  │ │
│ │           ahmed@email.com                   │ │
│ │ [اتصال] [واتساب] [إيميل]                    │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ ملخص الحساب                                     │
│ إجمالي المشتريات    الرصيد المستحق    المدفوع │
│ 12,500 ر.س          1,200 ر.س      11,300 ر.س│
├─────────────────────────────────────────────────┤
│ الفواتير                               [المزيد]│
│ ├─ INV-0125    575.00 ر.س         [● مدفوعة] │
│ └─ INV-0089  1,200.00 ر.س         [● معلقة]  │
├─────────────────────────────────────────────────┤
│ [كشف حساب]  [فاتورة جديدة]                     │
└─────────────────────────────────────────────────┘
```

### UX Guidelines

- Alphabetical sort by name
- Quick contact actions
- Account balance summary
- Invoice history
- Statement generation
- Notes and tags support

## 8.7 Reports

### Purpose
Business analytics and financial insights

### Report Categories

```
┌─────────────────────────────────────────────────┐
│ التقارير                                        │
├─────────────────────────────────────────────────┤
│ تقارير المبيعات                                 │
│ ├─ [→] ملخص المبيعات                           │
│ ├─ [→] المبيعات حسب العميل                     │
│ ├─ [→] المبيعات حسب المنتج                     │
│ └─ [→] المبيعات حسب الفترة                     │
├─────────────────────────────────────────────────┤
│ تقارير مالية                                    │
│ ├─ [→] تقرير التحصيلات                         │
│ ├─ [→] الذمم المدينة                           │
│ └─ [→] تقرير الضرائب                           │
├─────────────────────────────────────────────────┤
│ تقارير المخزون                                  │
│ ├─ [→] حركة المخزون                            │
│ └─ [→] تقرير المنتجات منخفضة المخزون           │
└─────────────────────────────────────────────────┘
```

### Report View Layout

```
┌─────────────────────────────────────────────────┐
│ [←] ملخص المبيعات               [Filter] [Export]│
├─────────────────────────────────────────────────┤
│ [هذا الشهر ▼]                                   │
├─────────────────────────────────────────────────┤
│ إجمالي المبيعات                                 │
│ 45,600.00 ر.س                         ↑ 12%    │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │           [Sales Chart]                     │ │
│ │                                             │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ التفاصيل                                        │
│ ├─ عدد الفواتير             45               │
│ ├─ متوسط قيمة الفاتورة      1,013 ر.س        │
│ ├─ أعلى يوم مبيعات          15 يناير         │
│ └─ أفضل منتج مبيعاً         منتج 1           │
└─────────────────────────────────────────────────┘
```

### UX Guidelines

- Date range selector prominent
- Comparison with previous period
- Visual charts (simple bar/line)
- Drill-down capability
- Export to PDF/Excel
- Shareable reports

## 8.8 Settings

### Purpose
Application configuration and preferences

### Settings Structure

```
┌─────────────────────────────────────────────────┐
│ الإعدادات                                       │
├─────────────────────────────────────────────────┤
│ الملف التجاري                                   │
│ ├─ [→] بيانات المنشأة                          │
│ ├─ [→] الشعار والهوية                          │
│ └─ [→] بيانات الاتصال                          │
├─────────────────────────────────────────────────┤
│ إعدادات الفواتير                                │
│ ├─ [→] قالب الفاتورة                           │
│ ├─ [→] التسلسل الرقمي                          │
│ ├─ [→] الشروط والأحكام                         │
│ └─ [→] الضرائب                                 │
├─────────────────────────────────────────────────┤
│ التفضيلات                                       │
│ ├─ اللغة                              [العربية]│
│ ├─ المظهر                         [تلقائي]    │
│ ├─ العملة                              [ر.س]  │
│ └─ الإشعارات                          [→]     │
├─────────────────────────────────────────────────┤
│ الحساب                                          │
│ ├─ [→] إدارة المستخدمين                        │
│ ├─ [→] النسخ الاحتياطي                         │
│ └─ [→] تسجيل الخروج                            │
├─────────────────────────────────────────────────┤
│ حول التطبيق                                     │
│ ├─ الإصدار 1.0.0                               │
│ ├─ [→] سياسة الخصوصية                          │
│ └─ [→] الشروط والأحكام                         │
└─────────────────────────────────────────────────┘
```

### UX Guidelines

- Grouped by function
- Inline toggles for simple settings
- Navigation for complex settings
- Current value shown inline
- Search within settings
- Changes save automatically

---

# 9. Accessibility System

## 9.1 Contrast Ratios

### Required Contrast Levels

| Element Type | WCAG Level | Minimum Ratio |
|--------------|------------|---------------|
| Body text | AAA | 7:1 |
| Large text (18px+) | AA | 4.5:1 |
| UI components | AA | 3:1 |
| Focus indicators | AA | 3:1 |
| Disabled elements | Exempt | 2:1 (intentional) |

### Measured Contrasts

| Light Mode Combination | Ratio |
|------------------------|-------|
| neutral-800 on neutral-50 | 15.8:1 |
| neutral-600 on neutral-0 | 7.5:1 |
| primary-600 on neutral-0 | 5.2:1 |
| error-600 on neutral-0 | 6.5:1 |
| success-600 on neutral-0 | 5.8:1 |

| Dark Mode Combination | Ratio |
|-----------------------|-------|
| neutral-100 on neutral-950 | 15.2:1 |
| neutral-400 on neutral-900 | 6.8:1 |
| primary-400 on neutral-950 | 5.6:1 |

## 9.2 Text Scaling Strategy

### Scaling Support

| Scale | Font Size Range | Support |
|-------|-----------------|---------|
| 85% | 11px - 27px | Full |
| 100% | 13px - 32px | Default |
| 115% | 15px - 37px | Full |
| 130% | 17px - 42px | Full |
| 150% | 20px - 48px | Full |
| 200% | 26px - 64px | Adapted |

### Scaling Behavior

- Text scales with system preference
- Containers expand to fit content
- No text truncation at 200%
- Icons scale proportionally
- Touch targets remain minimum 44px

### Implementation Rules

- Use relative units (sp for text, dp for layout)
- Test at minimum and maximum scales
- Ensure no horizontal scroll at 200%
- Allow multi-line wrapping

## 9.3 Touch Target Sizing

### Minimum Touch Targets

| Element | Minimum Size | Recommended |
|---------|--------------|-------------|
| Buttons | 44 x 44px | 48 x 48px |
| List items | 44px height | 48px height |
| Checkboxes | 44 x 44px | 48 x 48px |
| Icons (interactive) | 44 x 44px | 48 x 48px |
| Links in text | 44px height | - |

### Spacing Between Targets

- Minimum 8px between adjacent targets
- Recommended 12px for frequently used
- No overlapping touch areas

### Touch Target Exceptions

- Inline text links (compensate with adequate line height)
- Dense data tables (provide alternative view)

## 9.4 Screen Reader Compatibility

### Semantic Structure

| Element | Semantic Role |
|---------|---------------|
| Page title | Heading level 1 |
| Section title | Heading level 2 |
| Card title | Heading level 3 |
| Buttons | Button role |
| Links | Link role |
| Inputs | Form control |
| Lists | List/listitem |
| Images | Image with alt |

### Accessibility Labels

```
Button with icon:
accessibilityLabel: "إضافة فاتورة جديدة"

Status indicator:
accessibilityLabel: "الحالة: مدفوعة"

Amount:
accessibilityLabel: "المبلغ: خمسمائة وخمسة وسبعون ريالاً"
```

### Announcements

| Event | Announcement |
|-------|--------------|
| Page load | Page title |
| Form error | Error message |
| Success action | Confirmation message |
| Loading | "جاري التحميل" |
| List update | "تم تحديث القائمة" |

### Focus Management

- Logical focus order (RTL flow)
- Focus trap in modals
- Focus return after modal close
- Skip navigation link
- No focus loss on dynamic updates

## 9.5 Dyslexia-Friendly Options

### Typography Adjustments

| Setting | Default | Dyslexia Mode |
|---------|---------|---------------|
| Letter spacing | Normal | +5% |
| Word spacing | Normal | +10% |
| Line height | 1.5 | 1.8 |
| Paragraph spacing | 16px | 24px |
| Font weight | Regular | Medium |

### Layout Adjustments

- Left-aligned text (no justification)
- Shorter line lengths (max 60 characters)
- Increased contrast option
- Reduced motion

### Optional Features

- OpenDyslexic font option
- Reading ruler/focus line
- Text-to-speech integration
- Customizable background color

## 9.6 Motor Accessibility

### Large Touch Mode

| Element | Standard | Large Mode |
|---------|----------|------------|
| Button height | 44px | 56px |
| List item height | 48px | 64px |
| Input height | 44px | 56px |
| Spacing | 8px | 16px |

### Interaction Alternatives

| Standard | Alternative |
|----------|-------------|
| Swipe to delete | Long press menu |
| Double tap | Single tap with confirmation |
| Drag and drop | Move via menu |
| Pinch zoom | Button zoom controls |

### Timing Adjustments

- Extended timeout for toasts (12 seconds vs 8)
- No auto-advancing content
- Pause option for any animations
- Extended session timeout with warning

### One-Switch Navigation

- All functions reachable via sequential navigation
- Clear focus indicators
- No gesture-only features
- Keyboard shortcut alternatives

---

# 10. Flutter Implementation Guidance

## 10.1 Design Tokens Structure

### Token File Organization

```
lib/
├── core/
│   └── theme/
│       ├── tokens/
│       │   ├── colors.dart
│       │   ├── typography.dart
│       │   ├── spacing.dart
│       │   ├── radius.dart
│       │   ├── elevation.dart
│       │   └── breakpoints.dart
│       ├── theme_data.dart
│       ├── light_theme.dart
│       ├── dark_theme.dart
│       └── app_theme.dart
```

### Color Tokens Example

```dart
// lib/core/theme/tokens/colors.dart

abstract class AppColors {
  // Primary Palette
  static const Color primary50 = Color(0xFFEEF4FF);
  static const Color primary100 = Color(0xFFDCE8FF);
  static const Color primary200 = Color(0xFFC2D6FF);
  static const Color primary300 = Color(0xFF96B8FF);
  static const Color primary400 = Color(0xFF6494FF);
  static const Color primary500 = Color(0xFF3B6FE8);
  static const Color primary600 = Color(0xFF2855C5);
  static const Color primary700 = Color(0xFF1E429F);
  static const Color primary800 = Color(0xFF1A3578);
  static const Color primary900 = Color(0xFF152952);

  // Neutral Palette
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF4F4F5);
  static const Color neutral200 = Color(0xFFE4E4E7);
  static const Color neutral300 = Color(0xFFD4D4D8);
  static const Color neutral400 = Color(0xFFA1A1AA);
  static const Color neutral500 = Color(0xFF71717A);
  static const Color neutral600 = Color(0xFF52525B);
  static const Color neutral700 = Color(0xFF3F3F46);
  static const Color neutral800 = Color(0xFF27272A);
  static const Color neutral900 = Color(0xFF18181B);
  static const Color neutral950 = Color(0xFF0A0A0B);

  // Semantic Colors
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Financial Semantic
  static const Color moneyPositive = Color(0xFF059669);
  static const Color moneyNegative = Color(0xFFDC2626);
  static const Color moneyPending = Color(0xFFD97706);
  static const Color moneyOverdue = Color(0xFFBE123C);
}

// Dark mode colors
abstract class AppColorsDark {
  static const Color primary500 = Color(0xFF5A8FE8);
  static const Color primary600 = Color(0xFF7AA8F5);
  // ... complete dark palette
}
```

### Spacing Tokens Example

```dart
// lib/core/theme/tokens/spacing.dart

abstract class AppSpacing {
  static const double space0 = 0;
  static const double space05 = 2;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // Semantic spacing
  static const double pagePadding = space4;
  static const double cardPadding = space4;
  static const double sectionSpacing = space6;
  static const double formFieldSpacing = space4;
  static const double listItemSpacing = space2;
}
```

### Radius Tokens Example

```dart
// lib/core/theme/tokens/radius.dart

abstract class AppRadius {
  static const double none = 0;
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;

  // Semantic radius
  static const double button = sm;
  static const double input = sm;
  static const double card = md;
  static const double dialog = lg;
  static const double bottomSheet = xl;
  static const double chip = full;
}
```

## 10.2 Theme Configuration Strategy

### Light Theme Configuration

```dart
// lib/core/theme/light_theme.dart

import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/typography.dart';
import 'tokens/spacing.dart';
import 'tokens/radius.dart';

ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary600,
      onPrimary: AppColors.neutral0,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.neutral600,
      onSecondary: AppColors.neutral0,
      surface: AppColors.neutral0,
      onSurface: AppColors.neutral900,
      surfaceContainerHighest: AppColors.neutral100,
      error: AppColors.error,
      onError: AppColors.neutral0,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.neutral50,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.neutral0,
      foregroundColor: AppColors.neutral900,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
      ),
    ),
    
    // Cards
    cardTheme: CardTheme(
      color: AppColors.neutral0,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.neutral0,
        elevation: 1,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space5,
          vertical: AppSpacing.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary600,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        textStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 14,
        color: AppColors.neutral600,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 14,
        color: AppColors.neutral400,
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.neutral0,
      selectedItemColor: AppColors.primary600,
      unselectedItemColor: AppColors.neutral500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Dialogs
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.neutral0,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
      ),
    ),
    
    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.neutral0,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral200,
      thickness: 1,
      space: 0,
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.neutral100,
      selectedColor: AppColors.primary100,
      labelStyle: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary600,
      foregroundColor: AppColors.neutral0,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // List Tile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      minLeadingWidth: 40,
      horizontalTitleGap: AppSpacing.space3,
    ),
  );
}
```

## 10.3 Typography Configuration

```dart
// lib/core/theme/tokens/typography.dart

import 'package:flutter/material.dart';
import 'colors.dart';

abstract class AppTypography {
  static const String arabicFontFamily = 'IBM Plex Sans Arabic';
  static const String englishFontFamily = 'IBM Plex Sans';
  
  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: -0.4,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.3,
  );
  
  // Heading Styles
  static const TextStyle headingLarge = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
    letterSpacing: -0.1,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.62,
    letterSpacing: 0,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.57,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.54,
    letterSpacing: 0.1,
  );
  
  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: 0.2,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.2,
  );
  
  // Caption & Overline
  static const TextStyle caption = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.3,
  );
  
  static const TextStyle overline = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  // Numeric Styles (Tabular figures)
  static const TextStyle numericLarge = TextStyle(
    fontFamily: englishFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle numericMedium = TextStyle(
    fontFamily: englishFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle numericSmall = TextStyle(
    fontFamily: englishFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

// Text Theme for ThemeData
TextTheme appTextTheme() {
  return const TextTheme(
    displayLarge: AppTypography.displayLarge,
    displayMedium: AppTypography.displayMedium,
    displaySmall: AppTypography.displaySmall,
    headlineLarge: AppTypography.headingLarge,
    headlineMedium: AppTypography.headingMedium,
    headlineSmall: AppTypography.headingSmall,
    bodyLarge: AppTypography.bodyLarge,
    bodyMedium: AppTypography.bodyMedium,
    bodySmall: AppTypography.bodySmall,
    labelLarge: AppTypography.labelLarge,
    labelMedium: AppTypography.labelMedium,
    labelSmall: AppTypography.labelSmall,
  );
}
```

## 10.4 Component Reuse Strategy

### Component Library Structure

```
lib/
├── presentation/
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   ├── app_dialog.dart
│       │   ├── app_bottom_sheet.dart
│       │   ├── app_loading.dart
│       │   ├── app_empty_state.dart
│       │   └── app_error_state.dart
│       ├── lists/
│       │   ├── app_list_tile.dart
│       │   ├── invoice_list_item.dart
│       │   ├── product_list_item.dart
│       │   └── customer_list_item.dart
│       ├── inputs/
│       │   ├── app_search_field.dart
│       │   ├── app_currency_field.dart
│       │   ├── app_date_picker.dart
│       │   └── app_dropdown.dart
│       └── layout/
│           ├── app_scaffold.dart
│           ├── app_app_bar.dart
│           ├── app_bottom_nav.dart
│           └── responsive_builder.dart
```

### Reusable Button Component Example

```dart
// lib/presentation/widgets/common/app_button.dart

import 'package:flutter/material.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../core/theme/tokens/radius.dart';

enum AppButtonVariant { primary, secondary, tertiary, ghost, destructive }
enum AppButtonSize { large, medium, small, compact }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonHeight = _getButtonHeight();
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();
    
    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_getForegroundColor()),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize),
          const SizedBox(width: AppSpacing.space2),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.space2),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
    
    return SizedBox(
      height: buttonHeight,
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(child, buttonStyle),
    );
  }
  
  Widget _buildButton(Widget child, ButtonStyle style) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.tertiary:
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
    }
  }
  
  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.large: return 52;
      case AppButtonSize.medium: return 44;
      case AppButtonSize.small: return 36;
      case AppButtonSize.compact: return 32;
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case AppButtonSize.large: return 24;
      case AppButtonSize.medium: return 20;
      case AppButtonSize.small: return 18;
      case AppButtonSize.compact: return 16;
    }
  }
  
  double _getFontSize() {
    switch (size) {
      case AppButtonSize.large: return 16;
      case AppButtonSize.medium: return 14;
      case AppButtonSize.small: return 13;
      case AppButtonSize.compact: return 12;
    }
  }
  
  Color _getForegroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.neutral0;
      case AppButtonVariant.secondary:
      case AppButtonVariant.tertiary:
      case AppButtonVariant.ghost:
        return AppColors.primary600;
      case AppButtonVariant.destructive:
        return AppColors.neutral0;
    }
  }
  
  ButtonStyle _getButtonStyle(BuildContext context) {
    final horizontalPadding = size == AppButtonSize.large 
        ? AppSpacing.space6 
        : AppSpacing.space5;
    
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: AppColors.neutral0,
          elevation: 1,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
      case AppButtonVariant.secondary:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary600,
          side: const BorderSide(color: AppColors.primary600),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
      case AppButtonVariant.tertiary:
        return TextButton.styleFrom(
          foregroundColor: AppColors.primary600,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
      case AppButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: AppColors.neutral600,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
      case AppButtonVariant.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.neutral0,
          elevation: 1,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
    }
  }
}
```

## 10.5 Theming Architecture

### Theme Provider Setup

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

enum AppThemeMode { light, dark, system }

class AppTheme extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;
  
  AppThemeMode get mode => _mode;
  
  ThemeData getTheme(Brightness platformBrightness) {
    switch (_mode) {
      case AppThemeMode.light:
        return lightTheme();
      case AppThemeMode.dark:
        return darkTheme();
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark
            ? darkTheme()
            : lightTheme();
    }
  }
  
  void setMode(AppThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
  
  void toggleTheme() {
    _mode = _mode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    notifyListeners();
  }
}
```

### RTL Configuration

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice App',
      
      // Localization
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Theme
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      
      // Directionality handled by locale
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      home: const HomePage(),
    );
  }
}
```

### Extension Methods for Theme Access

```dart
// lib/core/theme/theme_extensions.dart

import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/typography.dart';
import 'tokens/spacing.dart';

extension ThemeExtensions on BuildContext {
  // Colors
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  // Typography
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Brightness
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // Semantic colors based on theme
  Color get surfaceColor => isDarkMode 
      ? AppColorsDark.surface 
      : AppColors.neutral0;
  
  Color get textPrimary => isDarkMode 
      ? AppColorsDark.textPrimary 
      : AppColors.neutral900;
  
  // Responsive helpers
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  
  // Safe area
  EdgeInsets get safeArea => MediaQuery.of(this).padding;
}
```

---

# Appendix A: Design Token Reference

## Complete Token List

| Category | Token | Light Value | Dark Value |
|----------|-------|-------------|------------|
| **Colors** | | | |
| | primary-500 | #3B6FE8 | #5A8FE8 |
| | primary-600 | #2855C5 | #7AA8F5 |
| | neutral-50 | #FAFAFA | #111113 |
| | neutral-900 | #18181B | #FAFAFA |
| | success | #059669 | #34D399 |
| | error | #DC2626 | #F87171 |
| **Spacing** | | | |
| | space-1 | 4px | 4px |
| | space-2 | 8px | 8px |
| | space-4 | 16px | 16px |
| | space-6 | 24px | 24px |
| **Radius** | | | |
| | radius-sm | 4px | 4px |
| | radius-md | 8px | 8px |
| | radius-lg | 12px | 12px |
| **Typography** | | | |
| | body-md | 14px/1.57 | 14px/1.57 |
| | heading-md | 18px/1.44 | 18px/1.44 |
| | display-md | 28px/1.28 | 28px/1.28 |

---

# Appendix B: Accessibility Checklist

## Pre-Release Checklist

- [ ] All interactive elements have minimum 44x44px touch targets
- [ ] Color contrast meets WCAG AA (4.5:1 for text)
- [ ] All images have appropriate alt text
- [ ] Screen reader can navigate all content
- [ ] Focus order is logical
- [ ] Focus indicators are visible
- [ ] Forms have proper labels
- [ ] Error messages are descriptive
- [ ] Dynamic content updates are announced
- [ ] Reduced motion preference is respected
- [ ] Text scales to 200% without loss
- [ ] No information conveyed by color alone

---

# Appendix C: RTL Considerations

## Elements That Mirror

- Navigation icons (back, forward)
- Progress indicators
- Sliders
- Checkmarks (position)
- List bullet alignment
- Form layouts
- Tab order

## Elements That Do NOT Mirror

- Video/audio controls
- Phone number format
- Numeric data (1234 stays 1234)
- Brand logos
- Mathematical operators
- Directional icons (upload, download)

---

**Document End**

*This design system blueprint serves as the foundational reference for all UI/UX decisions in the Invoice App. All implementations should adhere to these specifications for consistency and quality.*
