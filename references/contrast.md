# contrast.md — The expressive power of light and dark

Motion is the language of **time**: where a thing came from, where it went.
Luminance is the language of **space**: what is on top, what is alive, where to look right now.

Each does half a job alone. **"Lifting" is not moving something up 8px. It is up 4px + a larger,
softer shadow + a brighter surface — three things at once, which is when the brain finally reads
*it came closer to me*.** This file is about wiring luminance into motion.

---

## 1. The mental model: light comes from above

Human vision assumes the light source is overhead. Every luminance decision rests on that, and
violating it looks uncanny or cheap.

| To express | Luminance arrangement |
|---|---|
| **Raised** (button, card, popover) | faint bright top edge (rim light) + shadow below |
| **Recessed** (input, slot, pressed state) | inner shadow at the top + faint brightness at the bottom |
| **Flush** (background, dividers) | no shadow at all, only a difference in surface value |
| **Floating high** (modal, mid-drag) | a wide, low-opacity, heavily blurred shadow |

Higher elevation means a shadow that is **larger, softer and fainter** — not darker.

The beginner error is deepening the black of `box-shadow` to express "higher", which just reads as
*dirtier*. The correct move increases `blur` and `y-offset` while **lowering** alpha.

```css
--shadow-1: 0 1px 2px  rgb(0 0 0 / .08);                              /* resting on the surface */
--shadow-2: 0 2px 6px  rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);  /* card */
--shadow-3: 0 8px 20px rgb(0 0 0 / .06), 0 2px 6px rgb(0 0 0 / .05);  /* popover */
--shadow-4: 0 20px 48px rgb(0 0 0 / .05), 0 4px 12px rgb(0 0 0 / .04);/* modal */
```

The two-layer structure is the point: one tight layer (the contact shadow, which says the object has
thickness) and one wide, diffuse layer (ambient occlusion, which says how far away it is). A
single-layer shadow always looks like a sticker.

---

## 2. Dark themes express elevation by a different mechanism — this is what gets done wrong

**On a dark surface, shadows are invisible.** A black shadow cast onto near-black has no contrast to
work with.

Porting a light theme's shadows straight into a dark theme produces *every layer disappearing, and
the screen going flat*.

Dark themes use the opposite mechanism: **higher surfaces are brighter.** (The physical intuition:
a surface closer to the light receives more of it.)

| Layer | Light theme | Dark theme |
|---|---|---|
| Background | `#FFFFFF` | `#0E0E10` |
| Surface / card | `#FFFFFF` + shadow-2 | `#17171A` (≈5% lighter) |
| Popover / dropdown | `#FFFFFF` + shadow-3 | `#1F1F23` (≈8% lighter) |
| Modal | `#FFFFFF` + shadow-4 | `#26262B` (≈12% lighter) |

**So switching themes is not swapping a palette — it is swapping the mechanism that expresses
layering.** A correct token set changes both things at once:

```css
:root {
  --surface:   #ffffff;
  --elevated:  #ffffff;
  --shadow-e2: 0 2px 6px rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);
  --rim:       inset 0 1px 0 rgb(255 255 255 / .6);   /* bright top edge */
}
:root:not([data-theme="light"]) {
  @media (prefers-color-scheme: dark) {
    --surface:   #0e0e10;
    --elevated:  #1f1f23;                              /* elevation via brightness */
    --shadow-e2: 0 2px 8px rgb(0 0 0 / .5);            /* shadow still anchors, but no longer carries layering */
    --rim:       inset 0 1px 0 rgb(255 255 255 / .07); /* the rim must be far weaker */
  }
}
[data-theme="dark"] { /* repeat, so an explicit toggle wins in both directions */ }
```

Three more practical rules for dark themes:

- **Do not use pure black `#000`.** On OLED the boundary between content and background smears, and
  white text on pure black is harsh at high contrast. Something in the `#0E–#14` range is easier to
  sit with.
- **Do not use pure white `#FFF` for body text.** Drop to around `#E8E8EA`; long-form reading gets
  much easier.
- **Desaturate and lighten saturated colours.** A brand colour tuned for a light theme usually
  fluoresces against a dark one.

---

## 3. Three jobs for contrast — do not mix them

| Job | Technique | Not this |
|---|---|---|
| **Layering** (what is on top) | surface brightness + shadow | borders (a border says *partition*, not *height*) |
| **Focus** (where to look) | dim everything else (scrim) | making the target brighter (an arms race that ends with everything bright) |
| **State** (alive / disabled / selected) | explicit colour tokens | `opacity` alone (see below) |

**Focus works by dimming the surroundings, not brightening the target.** A screen can only support
so many bright things, so the brightening approach fails quickly. Dimming always works, because
contrast is relative.

**Do not express disabled with `opacity: 0.5`.** A translucent element picks up whatever is behind
it, so it renders differently on different backgrounds, and it drags text contrast below legibility.
Use a dedicated `--text-disabled` token.

---

## 4. Wiring luminance into motion: composite expression

This is what "reinforced expression" actually means — a single property carries too little
information, and **only same-direction, multi-property change reads as one physical event.**

### Lift (card hover)

```jsx
<motion.article
  initial={false}
  whileHover={{ y: -4, scale: 1.01 }}
  transition={{ type: "spring", visualDuration: 0.2, bounce: 0 }}
  className="card"     // CSS handles the shadow and brightness transition
/>
```
```css
.card {
  background: var(--surface);
  box-shadow: var(--shadow-2);
  transition: box-shadow .2s ease-out, background-color .2s ease-out;
}
.card:hover {
  box-shadow: var(--shadow-3);          /* larger and softer, not darker */
  background: var(--surface-hover);     /* light theme: barely moves / dark theme: brighter */
}
```
Movement goes to Motion (it must be interruptible and spring-driven); luminance goes to CSS (a plain
transition, no interruption logic needed). That division is the least work in most cases.

### Press (recess)

```jsx
whileTap={{ scale: 0.97 }}
```
```css
.btn:active {
  box-shadow: var(--shadow-1), inset 0 1px 2px rgb(0 0 0 / .12);  /* shadow tightens + inner shadow */
  filter: brightness(0.96);                                        /* and it darkens */
}
```
**Shrink + darken + shadow contraction** together mean *pushed in*. Shrinking alone just means
*got smaller* — a completely different statement.

### Dragging (picked up)

```jsx
whileDrag={{ scale: 1.04, boxShadow: "0 24px 48px rgb(0 0 0 / .18)" }}
```
Dragging is the one place a theatrical shadow is right — the object has to visibly leave the plane,
or the user is not sure they have hold of it.

### Modal opening (focus)

The dim and the content start together, but **the background lands first**:

```jsx
<AnimatePresence>
  {open && (
    <>
      <motion.div className="scrim"
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        transition={{ duration: 0.2, ease: "easeOut" }} />
      <motion.div className="dialog"
        initial={{ opacity: 0, scale: 0.96, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 4 }}
        transition={{ type: "spring", visualDuration: 0.28, bounce: 0.1 }} />
    </>
  )}
</AnimatePresence>
```
```css
.scrim { background: rgb(0 0 0 / .45); backdrop-filter: blur(2px); }
```
Scrim opacity: `0.4–0.5` in a light theme. In a dark theme it must work **differently** — 50% black
over near-black achieves nothing, so either push the opacity much higher or pull the contrast by
brightening the dialog itself.

`backdrop-filter: blur()` is expensive (it repaints the whole layer). Fine over a small area;
measure it full-screen, and consider shipping a flat scrim on low-end devices.

---

## 5. Luminance changes faster than movement

Luminance is a **state signal**; displacement is a **process**. State should confirm immediately;
process is allowed to take its time.

| Change | Duration |
|---|---|
| `filter: brightness` / colour swap | `0.1 – 0.15s` |
| `box-shadow` elevation change | `0.15 – 0.2s` |
| Scrim fade-in | `0.15 – 0.2s` (lands before the content) |
| Concurrent movement | `0.2 – 0.35s` |

If luminance runs as slowly as movement, it reads as *the colour chasing the object*.
**Let brightness arrive first and position arrive second.**

---

## 6. Performance: which luminance properties can actually animate

| Property | Cost | Guidance |
|---|---|---|
| `opacity` | ✅ compositor | always safe |
| `filter: brightness / drop-shadow` | ✅ compositor in Chrome/Firefox | the first choice for animated brightness |
| `background-color` | ⚠️ paint; Chrome is adding compositor support | fine on small areas, measure full-screen |
| `box-shadow` | ⚠️ paint, cost scales with blur radius and area | see the standard workaround below |
| `backdrop-filter` | ❌ expensive | small areas only, or don't animate it (switch it) |

**The standard workaround for animated shadows** — pre-render a shadowed pseudo-element and animate
only its `opacity`:

```css
.card { position: relative; box-shadow: var(--shadow-2); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: var(--shadow-4);
  opacity: 0; transition: opacity .2s ease-out;
  pointer-events: none;
}
.card:hover::after { opacity: 1; }
```
The shadow itself never repaints; only one alpha value changes. On a long list — dozens of cards
hovered in sequence — the difference is dramatic.

---

## 7. Accessibility floors

Luminance is a means of expression, but it **cannot be the only carrier of information**, and it has
numeric limits you may not cross.

- Body text against its background: **≥ 4.5:1**. Large text (18.66px bold, or 24px) and UI component
  boundaries: **≥ 3:1** (WCAG 2.2 AA).
- **Never signal state with brightness alone.** "The selected one is brighter" does not exist for
  users with low vision or colour vision differences — always pair it with shape, an icon, a border,
  or text.
- The focus indicator (`:focus-visible`) must reach **3:1** against its surroundings and **must not
  rely on brightness alone**. The common dark-theme failure is a pale grey focus ring that vanishes
  entirely on a dark surface. Verify the focus ring separately in both themes.
- Intermediate states during an animation must stay legible. Text fading in at 2:1 contrast is, for
  part of your audience, blank for that whole duration. **Starting an entry at `opacity: 0` is fine
  — what to avoid is parking at a "half-readable" value like `0.3` as a resting state.**
- **Keep luminance changes under reduced motion.** This is exactly where they earn their place: with
  movement and scaling switched off, brightness and colour still communicate *the state changed*,
  without inducing vertigo. That is also what `MotionConfig reducedMotion="user"` does — it disables
  transform and layout while preserving opacity and colour.

---

## 8. Checklist

Run through this after building anything with layering or state:

- [ ] Have you looked at it in a **dark theme**? Is the layering still visible? (Usually not — switch to surface brightness.)
- [ ] Are shadows two-layer (tight + diffuse)? A single layer looks like a sticker.
- [ ] Is "higher" expressed as larger and softer, rather than darker?
- [ ] Do hover and press change **movement and luminance together**? One alone halves the expression.
- [ ] Does brightness change faster than displacement?
- [ ] Is disabled a dedicated colour token rather than `opacity: 0.5`?
- [ ] Does the focus ring hit 3:1 in *both* themes?
- [ ] Is any state distinguished by brightness **only**?
- [ ] In long lists, does the hover shadow go through `::after` opacity rather than animating `box-shadow` directly?
- [ ] Is the `backdrop-filter` area bounded?
