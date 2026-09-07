# contrast.md — The expressive power of light and dark

Motion is the language of **time**: where a thing came from, where it went.
Luminance is the language of **space**: what is on top, what is alive, where to look right now.

Each does half a job alone. **"Lifting" is not moving something up 8px. It is up 4px + a larger,
softer shadow + a brighter surface — three things at once, which is when the brain finally reads
*it came closer to me*.** This file is about wiring luminance into motion.

The optics here are not platform-specific. Only §6 mentions concrete properties, and only as
examples of a cost hierarchy every renderer has.

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

The beginner error is deepening the black of the shadow to express "higher", which just reads as
*dirtier*. The correct move increases **blur** and **y-offset** while **lowering** alpha.

A four-tier ladder, as offset / blur / alpha — these are the numbers, whatever you express them in:

| Tier | Meaning | Contact layer | Ambient layer |
|---|---|---|---|
| **e1** | resting on the surface | `0 1px 2px  / 8%` | — |
| **e2** | card | `0 1px 2px  / 5%` | `0 2px 6px  / 7%` |
| **e3** | popover, dropdown | `0 2px 6px  / 5%` | `0 8px 20px / 6%` |
| **e4** | modal, mid-drag | `0 4px 12px / 4%` | `0 20px 48px / 5%` |

The two-layer structure is the point: one tight layer (the **contact shadow**, which says the object
has thickness) and one wide, diffuse layer (**ambient occlusion**, which says how far away it is). A
single-layer shadow always looks like a sticker.

**If your renderer has no shadow primitive** — most game and 3D UI runtimes do not — you get the
same two layers from two stacked nine-slice images behind the element: a small, tight one at the
element's own rect plus a few pixels, and a large, blurred one inset well beyond it. Animate their
*alpha*, never their size. Everything else in this file applies unchanged.

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
| Surface / card | `#FFFFFF` + e2 | `#17171A` (≈5% lighter) |
| Popover / dropdown | `#FFFFFF` + e3 | `#1F1F23` (≈8% lighter) |
| Modal | `#FFFFFF` + e4 | `#26262B` (≈12% lighter) |

**So switching themes is not swapping a palette — it is swapping the mechanism that expresses
layering.** A correct token set changes both things at once:

| Token | Light | Dark |
|---|---|---|
| `surface` | `#FFFFFF` | `#0E0E10` |
| `elevated` | `#FFFFFF` (same — height comes from the shadow) | `#1F1F23` (**different** — height comes from here) |
| `shadow-e2` | `0 2px 6px / 7%` + `0 1px 2px / 5%` | `0 2px 8px / 50%` — still anchors the object, no longer carries layering |
| `rim` | inset top `1px` white `60%` | inset top `1px` white `7%` — **far weaker** |

That `rim` row is the one people forget. A bright top edge tuned for a light theme becomes a glowing
white hairline on a dark surface.

Three more practical rules for dark themes:

- **Do not use pure black.** On OLED the boundary between content and background smears, and white
  text on pure black is harsh at high contrast. Something in the `#0E–#14` range is easier to sit
  with.
- **Do not use pure white for body text.** Drop to around `#E8E8EA`; long-form reading gets much
  easier.
- **Desaturate and lighten saturated colours.** A brand colour tuned for a light theme usually
  fluoresces against a dark one.

---

## 3. Three jobs for contrast — do not mix them

| Job | Technique | Not this |
|---|---|---|
| **Layering** (what is on top) | surface brightness + shadow | borders (a border says *partition*, not *height*) |
| **Focus** (where to look) | dim everything else (scrim) | making the target brighter (an arms race that ends with everything bright) |
| **State** (alive / disabled / selected) | explicit colour tokens | opacity alone (see below) |

**Focus works by dimming the surroundings, not brightening the target.** A screen can only support
so many bright things, so the brightening approach fails quickly. Dimming always works, because
contrast is relative.

**Do not express disabled with 50% opacity.** A translucent element picks up whatever is behind it,
so it renders differently on different backgrounds, and it drags text contrast below legibility. Use
a dedicated `text-disabled` token.

---

## 4. Wiring luminance into motion: composite expression

This is what "reinforced expression" actually means — a single property carries too little
information, and **only same-direction, multi-property change reads as one physical event.**

Each of these is written as a spec you can hand to any runtime.

### Lift (card hover)

| Channel | From → To | Timing |
|---|---|---|
| `y` | `0 → −4px` | `spring(0.2, 0)` |
| `scale` | `1 → 1.01` | `spring(0.2, 0)` |
| shadow | `e2 → e3` (larger and softer, **not darker**) | `dur 0.2  curve out` |
| surface | `surface → surface-hover` (light: barely moves / dark: **brighter**) | `dur 0.2  curve out` |

Movement wants a spring, because it can be interrupted by the cursor leaving. Luminance does not —
a plain tween is correct there, and splitting the two along that line is the least work in most
runtimes. Where your platform has a cheap declarative layer for state changes (CSS `:hover`, a style
sheet, a UI state machine) put the luminance there and keep only the movement in code.

### Press (recess)

| Channel | From → To | Timing |
|---|---|---|
| `scale` | `1 → 0.97` | `spring(0.15, 0)` |
| shadow | `e2 → e1` **plus** an inner shadow, top, `1–2px`, black `12%` | `dur 0.1  curve out` |
| brightness | `1 → 0.96` | `dur 0.1  curve out` |

**Shrink + darken + shadow contraction** together mean *pushed in*. Shrinking alone just means
*got smaller* — a completely different statement.

### Dragging (picked up)

| Channel | From → To | Timing |
|---|---|---|
| `scale` | `1 → 1.04` | `spring(0.2, 0)` |
| shadow | `e2 → e4`, exaggerated: `0 24px 48px / 18%` | `dur 0.15  curve out` |
| depth order | raised above siblings | immediate |

Dragging is the one place a theatrical shadow is right — the object has to visibly leave the plane,
or the user is not sure they have hold of it.

### Modal opening (focus)

The dim and the content start together, but **the background lands first**:

| Channel | From → To | Timing |
|---|---|---|
| scrim opacity | `0 → 1` | `dur 0.2  curve out` ← finishes first |
| dialog opacity | `0 → 1` | `dur 0.2  curve out` |
| dialog `scale` | `0.96 → 1` | `spring(0.28, 0.1)` |
| dialog `y` | `+8px → 0` | `spring(0.28, 0.1)` |

Exit reverses it with the asymmetry from `feel.md` §5: `dur 0.15`, `scale → 0.98`, `y → +4px`, and
the scrim leaves **last**.

Scrim value: black at `40–50%` in a light theme. In a dark theme it must work **differently** — 50%
black over near-black achieves nothing, so either push the opacity much higher or pull the contrast
by brightening the dialog itself.

A backdrop blur is expensive everywhere (it repaints or re-samples the whole layer beneath).
Fine over a small area; measure it full-screen, and consider shipping a flat scrim on low-end
devices.

---

## 5. Luminance changes faster than movement

Luminance is a **state signal**; displacement is a **process**. State should confirm immediately;
process is allowed to take its time.

| Change | Duration |
|---|---|
| brightness / colour swap | `0.1 – 0.15s` |
| shadow tier change | `0.15 – 0.2s` |
| scrim fade-in | `0.15 – 0.2s` (lands before the content) |
| concurrent movement | `0.2 – 0.35s` |

If luminance runs as slowly as movement, it reads as *the colour chasing the object*.
**Let brightness arrive first and position arrive second.**

---

## 6. Performance: which luminance properties can actually animate

The hierarchy is the same everywhere, even when the property names are not:

| Kind of change | Cost | Guidance |
|---|---|---|
| opacity of an existing layer | ✅ composite | always safe |
| a brightness/tint filter on a layer | ✅ usually composite | the first choice for animated brightness |
| fill or background colour | ⚠️ paint | fine on small areas, measure full-screen |
| a shadow, especially a blurred one | ⚠️ paint, cost scales with blur radius **and** area | see the workaround below |
| a backdrop / behind-layer blur | ❌ expensive | small areas only, or switch it rather than animate it |
| corner radius, stroke width | ⚠️ paint, often re-tessellates | prefer a clip or a pre-rendered mask |

**The standard workaround, and it generalises:** never animate the expensive property. Pre-render
**both** states as stacked layers and cross-fade their opacity.

For a shadow that means an overlay behind the element carrying the *higher* tier, resting at
opacity 0, fading to 1 on hover. The shadow itself never repaints; only one alpha value changes. On
a long list — dozens of cards hovered in sequence — the difference is dramatic.

**One precondition, and it is the reason this technique usually fails: the element must not clip.**
A shadow paints outside its own box, so any `overflow: hidden` — the reflex for a rounded card with
an image at the top — erases the overlay entirely, and erases it silently, because the cross-fade
still runs on a layer nobody can see. Clip the media instead of the card. → `errata.md` §A1

The same move works for corner radius (two pre-rendered masks), for a colour ramp (two fills), and
for a blur (two pre-blurred copies). It costs memory and buys frames.

---

## 7. Accessibility floors

Luminance is a means of expression, but it **cannot be the only carrier of information**, and it has
numeric limits you may not cross.

- Body text against its background: **≥ 4.5:1**. Large text (18.66px bold, or 24px) and the
  boundaries of interactive components: **≥ 3:1**.
- **Never signal state with brightness alone.** "The selected one is brighter" does not exist for
  users with low vision or colour vision differences — always pair it with shape, an icon, a border,
  or text.
- The focus indicator must reach **3:1** against its surroundings and **must not rely on brightness
  alone**. The common dark-theme failure is a pale grey focus ring that vanishes entirely on a dark
  surface. Verify the focus ring separately in both themes.
- Intermediate states during an animation must stay legible. Text fading in at 2:1 contrast is, for
  part of your audience, blank for that whole duration. **Starting an entry at opacity 0 is fine —
  what to avoid is parking at a "half-readable" value like `0.3` as a resting state.**
- **Keep luminance changes under reduced motion.** This is exactly where they earn their place: with
  movement and scaling switched off, brightness and colour still communicate *the state changed*,
  without inducing vertigo.

---

## 8. Checklist

Run through this after building anything with layering or state:

- [ ] Have you looked at it in a **dark theme**? Is the layering still visible? (Usually not — switch to surface brightness.)
- [ ] Are shadows two-layer (tight + diffuse)? A single layer looks like a sticker.
- [ ] Is "higher" expressed as larger and softer, rather than darker?
- [ ] Is the rim light weakened for the dark theme, rather than carried over?
- [ ] Do hover and press change **movement and luminance together**? One alone halves the expression.
- [ ] Does brightness change faster than displacement?
- [ ] Is disabled a dedicated colour token rather than 50% opacity?
- [ ] Does the focus ring hit 3:1 in *both* themes?
- [ ] Is any state distinguished by brightness **only**?
- [ ] In long lists, is the hover shadow a cross-faded overlay rather than an animated shadow?
- [ ] Is the backdrop-blur area bounded?
