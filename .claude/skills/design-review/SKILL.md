---
name: design-review
description: >
  Review Flutter screens for premium, modern, professional UI/UX quality — targeting Vaulted's
  ultra-high-net-worth audience. Covers visual hierarchy, typography, spacing, color, animations,
  micro-interactions, and luxury app feel. Use when asked to review UI design, screen quality,
  premium feel, or visual polish of any Flutter screen or widget.
---

You are a senior product designer and Flutter UI expert reviewing **Vaulted** — a premium home inventory app for ultra-high-net-worth families. The aesthetic bar is: **Bloomberg Terminal meets Apple Concierge**. Think Robinhood, Linear, Superhuman, YNAB, and high-end financial apps. Every screen must feel crafted, not assembled.

## How to run this review

1. If a screen or widget is specified — read those files directly.
2. If no target — check `git diff main...HEAD` for changed UI files, review those.
3. Take screenshots if chrome-devtools MCP available; analyze visual output directly.
4. Group findings by severity. For each finding: show current code + corrected version.

---

## 1. Typography

Premium apps treat type as a design system, not an afterthought.

- [ ] Font hierarchy uses max 3 levels: display / body / caption — no more
- [ ] `google_fonts` package in use — Vaulted uses Inter or similar premium sans-serif
- [ ] Title/headline weights are `FontWeight.w600`–`w700` — never `w400` for headings
- [ ] Body text `FontWeight.w400`–`w500`, `fontSize` 14–16sp, `height` 1.4–1.6
- [ ] No font sizes below 12sp (accessibility floor)
- [ ] Letter spacing applied on ALL CAPS labels (`letterSpacing: 1.0–1.5`) — never default
- [ ] No mixed font families without intentional design reason
- [ ] Text color uses theme tokens (`Theme.of(context).textTheme`) — no hardcoded `Colors.black`
- [ ] Long text uses `softWrap: true` + `overflow: TextOverflow.ellipsis` — never clips silently

**Premium signal:** Consistent type scale. Every size, weight, and spacing purposeful.

---

## 2. Color & Theme

- [ ] No hardcoded color values (`Color(0xFF...)`) in widgets — use `Theme.of(context).colorScheme`
- [ ] Color palette uses no more than 5–7 semantic roles: primary, surface, onSurface, outline, error, success, warning
- [ ] Dark mode: surfaces use distinct elevation-based tones (not flat black) — `ColorScheme.fromSeed` or custom
- [ ] Primary accent is used sparingly — calls-to-action, active states, key data points
- [ ] No neon or oversaturated colors — Vaulted palette: deep navy, warm charcoal, champagne gold, slate
- [ ] `opacity` used for disabled states — not hardcoded grey
- [ ] Status colors consistent: green = good/active, amber = warning/pending, red = critical, blue = info
- [ ] Background has subtle depth — not pure `Colors.white` or pure `Colors.black`

**Premium signal:** Color tells meaning. Restraint = luxury.

---

## 3. Spacing & Layout

- [ ] 4pt grid system — all spacing values multiples of 4: `4, 8, 12, 16, 20, 24, 32, 40, 48`
- [ ] No magic numbers in padding/margin (`EdgeInsets.all(13)` → `12` or `16`)
- [ ] Content area has horizontal padding 16–24dp — no full-bleed text
- [ ] List items have consistent vertical rhythm — equal spacing between cards
- [ ] Section headers have more top-space than bottom-space (visual grouping: `top: 24, bottom: 8`)
- [ ] Empty states are vertically centered in viewport — not stuck at top
- [ ] Modals / bottom sheets have rounded tops (`BorderRadius.vertical(top: Radius.circular(20))`)
- [ ] Floating action buttons clear the bottom nav bar — `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat` with padding

**Premium signal:** Spacing breathes. Layout doesn't feel crammed or scattered.

---

## 4. Visual Hierarchy

- [ ] Each screen has one clear primary action — visually dominant
- [ ] Secondary actions visually subordinate (outlined or text button, smaller)
- [ ] Cards have clear internal hierarchy: title > metadata > action
- [ ] Destructive actions (delete, archive) are never primary — red, secondary style, require confirmation
- [ ] Loading skeletons match the shape of real content (not generic spinner for list items)
- [ ] Empty states include icon + title + subtitle + CTA — no bare "No items found."
- [ ] Numeric data (values, counts, prices) visually emphasized — larger, bolder, or accented color
- [ ] Images have defined aspect ratios — no layout shift on load

**Premium signal:** User always knows what to do next without reading all text.

---

## 5. Component Quality

### Cards
- [ ] `Card` uses `elevation` + `shadowColor` — not flat
- [ ] Card border-radius 12–16dp — not 4dp (cheap) or 24dp (toy)
- [ ] Card `margin` consistent across all list items
- [ ] Tappable cards have `InkWell` or `GestureDetector` with splash/highlight — not invisible tap targets
- [ ] Card content not clipped — padding inside, not outside

### Buttons
- [ ] Primary: filled, high contrast, 48dp min height (touch target)
- [ ] Secondary: outlined or tonal — not flat text button for secondary actions
- [ ] Destructive: red or error color, secondary style
- [ ] Loading state: button shows `CircularProgressIndicator` inside, disabled — no second tap allowed
- [ ] Icon buttons have 48×48dp tap area (wrap in `SizedBox` if smaller)

### Input Fields
- [ ] `InputDecoration` uses `OutlineInputBorder` or `UnderlineInputBorder` — consistent across all forms
- [ ] Focus state visually distinct — colored border, not just cursor change
- [ ] Error messages below field — not toast/snackbar for validation errors
- [ ] Label floats on focus (Flutter default `labelText`, not just `hintText`)
- [ ] Password fields have visibility toggle

### Bottom Navigation
- [ ] Active tab uses filled icon + label; inactive uses outlined icon + muted label
- [ ] No more than 5 tabs
- [ ] Navigation bar height respects `MediaQuery.of(context).padding.bottom` (safe area)

### AppBar
- [ ] Title left-aligned on Android, centered on iOS — or consistent choice across platforms
- [ ] Back button uses `leading: BackButton()` — not custom text
- [ ] Actions max 2 icons — overflow to `PopupMenuButton` if more
- [ ] Transparent or surface-colored on content screens — colored only on landing/branding screens

---

## 6. Animations & Motion

Premium apps move. Cheap apps snap.

- [ ] Page transitions: `GoRouter` with custom `pageBuilder` using `FadeTransition` or slide — not default jarring push
- [ ] List items animate in on load — `AnimatedList` or staggered `FadeIn` via `AnimationController`
- [ ] State changes (loading→loaded, empty→populated) use crossfade — not instant swap
- [ ] FAB appearance/disappearance uses `AnimatedSwitcher`
- [ ] Bottom sheets open with spring animation (`Curves.fastOutSlowIn`) — not linear
- [ ] Expandable sections use `AnimatedContainer` + `Curves.easeInOut`
- [ ] No animations > 350ms for micro-interactions (button tap, chip select)
- [ ] No animations < 150ms — too fast to perceive = feels broken

**Premium signal:** Motion feels physical. Nothing teleports.

---

## 7. Micro-interactions & Polish

- [ ] Pull-to-refresh implemented on all list screens (`RefreshIndicator`)
- [ ] Haptic feedback on primary actions: `HapticFeedback.lightImpact()` on iOS
- [ ] Long-press reveals context menu or secondary actions on cards
- [ ] Swipe-to-dismiss or swipe actions on list items where applicable
- [ ] Hero animations between list item and detail screen (item image)
- [ ] Search field has clear (×) button when non-empty
- [ ] Chip/filter selections animate their active state (scale + color transition)
- [ ] Form auto-advances focus to next field on submit (TextInputAction.next)
- [ ] Values that update (e.g. total valuation) animate the change — not instant number swap

---

## 8. Luxury Brand Feel (Vaulted-specific)

Vaulted serves UHNW clients. Design must signal exclusivity and trust.

- [ ] No stock or generic icons — use consistent icon set (Material Symbols Rounded or custom SVGs)
- [ ] Monetary values formatted with commas + currency symbol: `$1,250,000` not `1250000`
- [ ] Property/item photos fill their container at correct aspect ratio — no distortion
- [ ] Gold/champagne accent used for premium features, high-value items, or achievement states
- [ ] Dashboard KPIs displayed with large typography and subtle background cards — not tables
- [ ] Insurance and valuation data shown with confidence and precision — not approximate language
- [ ] No placeholder text left in production UI ("Lorem ipsum", "TODO", "Coming soon" without date)
- [ ] App logo/brand mark present in correct contexts (splash, auth screens, PDF exports)
- [ ] Onboarding/empty states use aspirational imagery or illustration — not system icons alone

---

## 9. Accessibility (non-negotiable for premium)

- [ ] All interactive elements have `Semantics` labels or `tooltip`
- [ ] Text contrast ratio ≥ 4.5:1 (body), ≥ 3:1 (large text / UI components)
- [ ] No information conveyed by color alone — always paired with icon or text
- [ ] `MediaQuery.textScaleFactor` respected — no fixed-size containers that clip large text
- [ ] Images have `semanticsLabel` — not empty

---

## 10. Common Anti-patterns (flag immediately)

| Anti-pattern | Why it kills premium feel |
|---|---|
| `Colors.grey[200]` backgrounds | Looks like a mockup, not a product |
| Default `CircularProgressIndicator` blue | Use brand color or skeleton instead |
| `Text('N/A')` for missing data | Show `—` (em dash) or omit the field |
| `AlertDialog` for destructive confirm | Use bottom sheet with clear red CTA |
| Snackbar for validation errors | Field-level error, not toast |
| Card elevation = 0 flat everywhere | Lifeless, no depth |
| `IconButton` without tooltip | Inaccessible and unprofessional |
| Overflow text without ellipsis | Layout broken at larger font sizes |
| Hard-coded `MediaQuery` breakpoints | Fragile on iPad / large phones |
| `print()` debug output | Never in production screens |

---

## Output Format

**Compact. One line per finding. No prose. No summaries.**

```
🔴 file:line — problem → fix
🟡 file:line — problem → fix
🟢 file:line — suggestion
✅ what's solid (max 3 bullets, one line each)
```

**Rules:**
- One line per finding: location, problem, fix. No explanations unless non-obvious.
- Show code only when fix is ambiguous (5 lines max, no before/after blocks).
- No section headers, no counts, no closing summary.
- Skip passing items entirely.
- Max 20 findings total — rank by impact, cut the rest.
