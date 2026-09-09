# recipes.md — 26 patterns, as specifications

Each recipe states its **intent** first, then a spec you can implement in any runtime, then the one
thing that usually goes wrong. No recipe here names an API; take the numbers to your adapter.

Notation is `SKILL.md` §1: `dur` in seconds, `curve` is `out`/`in`/`inout`/`linear`,
`spring(Dv, b)` is visual duration and bounce, `travel` in px.

---

## 0. The foundation

Before any of the rest: define the token set once, per `feel.md` §11.

```
feedback :  dur 0.12   curve out
micro    :  dur 0.2    curve out
enter    :  spring(0.3,  0.15)
exit     :  dur 0.15   curve in
layout   :  spring(0.35, 0)
page     :  spring(0.5,  0.1)
stagger  :  0.04
lumin    :  dur 0.13   curve out
```

Every recipe below is written in these tokens where one fits. **If you find yourself typing a
duration that is not in this list, ask why this case is special** — usually it is not.

---

## 1. Element entry

**Intent:** something new appeared, and it came from slightly below.

| Channel | From → To | Timing |
|---|---|---|
| opacity | `0 → 1` | `dur 0.25  curve out` |
| `y` | `+8px → 0` | `enter` |

Exit is the mirror at `dur 0.15  curve in`, `y → +4px`.

**Watch out:** `y: +8px` and not `+40px`. The distance is a claim about where the thing came from,
and 40px claims it came from off-screen.

---

## 2. List stagger

**Intent:** these items are a sequence, read top to bottom.

Per item: recipe 1. Interval `stagger` (`0.04`). Container fades first, `dur 0.15`.

Reverse the direction and halve the interval on exit (`0.02`, from last) so the list rolls back up.

**Watch out:** do the arithmetic. `interval × count ≤ 0.5s`. Past 20 items, stop staggering
individually and fade the block.

---

## 3. Scroll-triggered fade

**Intent:** this section is arriving as you reach it.

| Channel | From → To | Timing |
|---|---|---|
| opacity | `0 → 1` | `dur 0.4  curve out` |
| `y` | `+12px → 0` | `dur 0.4  curve out` |

Trigger at **30% visible**. Fire **once** and never again.

**Watch out:** the two defaults most libraries give you are both wrong here — they fire at one pixel
of visibility, and they replay on every pass. Set both explicitly.

---

## 4. Button: movement and luminance together

**Intent:** it responds to the pointer, and it depresses when pressed.

| State | Channels | Timing |
|---|---|---|
| hover | `scale 1.02` + surface one step brighter | `spring(0.15, 0)` / `lumin` |
| press | `scale 0.97` + brightness `0.96` + shadow `e2 → e1` + inner shadow top | `feedback` |
| focus | ring, ≥ 3:1 against surroundings | `feedback` |

**Watch out:** press must shrink, not grow. And the press state must fire on keyboard activation
too, not just pointer.

---

## 5. Card hover lift (that survives a long list)

**Intent:** this card came closer to me.

| Channel | From → To | Timing |
|---|---|---|
| `y` | `0 → −4px` | `spring(0.2, 0)` |
| `scale` | `1 → 1.01` | `spring(0.2, 0)` |
| shadow | `e2 → e3` | `lumin` |
| surface | one step brighter | `lumin` |

**Watch out:** do not animate the shadow itself on a list of cards. Stack a second layer carrying
`e3` at opacity 0 behind the card and cross-fade that — `contrast.md` §6. Also keep the scale at
`1.01`, not `1.05`: on a 400px card, 5% is 20px of growth shoving its neighbours.

---

## 6. Modal (scrim + content)

**Intent:** everything else stopped mattering.

Spec in `contrast.md` §4 "Modal opening". Summary: scrim `dur 0.2 curve out` and lands **first**;
dialog `spring(0.28, 0.1)` from `scale 0.96`, `y +8px`. Exit at `dur 0.15`, scrim leaves last.

**Watch out:** the dialog must not start at `scale 0`. And check the scrim in the dark theme — 45%
black over `#0E0E10` separates nothing.

---

## 7. Card expanding into a modal (shared element)

**Intent:** this modal *is* that card.

Use the measure-and-invert procedure in `feel.md` §4:

```
1. measure the card's rect
2. mount the dialog at its final position and size
3. measure it
4. transform the dialog back onto the card's rect (translate + scale)
5. animate that transform to identity with `layout`
```

Cross-fade the card's content out and the dialog's in over the first 60% of the movement.

**Watch out:** scaling a rect distorts its corner radius and its text. Counter-scale the inner
content by the inverse factor, or animate position only and let size change by layout. If your
runtime has a built-in shared-element mechanism, prefer it — it does this counter-scaling for you.

---

## 8. Dropdown / popover (grown from the trigger)

**Intent:** this came out of that button.

| Channel | From → To | Timing |
|---|---|---|
| transform origin | the corner nearest the trigger | — |
| `scale` | `0.95 → 1` | `spring(0.25, 0.1)` |
| opacity | `0 → 1` | `dur 0.15  curve out` |
| `y` | `−4px → 0` | `spring(0.25, 0.1)` |

Items inside: `stagger 0.03`, beginning only once the container has finished opening — the
container-before-children rule in `feel.md` §6.

**Watch out:** the transform origin is the entire recipe. A popover that grows from its own centre
while sitting under a button reads as unrelated to the button.

---

## 9. Accordion (height without layout thrash)

**Intent:** the panel unrolled.

Measure the content's natural height, then animate the container from `0` to that height — but do it
as a **transform**, not as a height, wherever the runtime allows: scale a wrapper on Y and
counter-scale the content, or clip with a mask whose extent is a transform.

Content inside: opacity `0 → 1`, `dur 0.2`, delayed to the last 40% of the open.

**Watch out:** if you must animate real height, at least measure once and cache it; measuring every
frame is where accordions go to die. Set the height back to `auto` when the animation completes, or
the panel will not respond to content changes.

---

## 10. Tab underline (it slides, it doesn't blink)

**Intent:** the selection moved from there to here.

One underline element, shared. On selection change, animate its `x` and `width` to the new tab's
rect with `layout` — `spring(0.35, 0)`.

**Watch out:** `width` is a layout property. Use `scaleX` on a fixed-width bar with a left transform
origin, and counter nothing (an underline has no content to distort). This is the one place scaling
a rect is free.

---

## 11. Toast stack

**Intent:** a message arrived at the corner it lives in.

| Channel | From → To | Timing |
|---|---|---|
| `x` (for a right-side stack) | `+24px → 0` | `enter` |
| opacity | `0 → 1` | `dur 0.2 curve out` |
| existing toasts | shift down by the new one's height | `layout` |

Exit: `x → +16px`, opacity `→ 0`, `exit` token, and the remaining toasts close the gap with `layout`.

**Watch out:** the *gap closing* is the part that makes a stack feel real. Toasts that vanish and
leave the others teleporting into place undo the whole effect.

---

## 12. Drag to reorder

**Intent:** I am holding this, and the others are making room.

| Channel | Value |
|---|---|
| held item | `scale 1.03`, shadow `e4`, raised above siblings, follows the pointer **1:1** |
| other items | shift by one slot with `layout` — `spring(0.35, 0)` |
| release | spring to the target slot, seeded with the pointer's release velocity |
| past the edges | elastic resistance, half the input, springs back |

**Watch out:** the held item must track the pointer exactly, with no easing at all. Any smoothing
between finger and object destroys the illusion of holding it — the spring belongs on the *other*
items, and on the release.

---

## 13. Scroll progress bar

**Intent:** how far through am I.

`scaleX` from `0 → 1`, transform origin left, bound directly to scroll progress, `curve linear`,
smoothed with `spring(0.2, 0)`.

**Watch out:** this is the one animation that should be `linear`. It is a measurement, not a
movement.

---

## 14. Parallax

**Intent:** that layer is further away.

Background `y` moves at `0.3–0.5×` the scroll delta of the foreground. Smooth the scroll input with
`spring(0.35, 0)`.

**Watch out:** initialise the spring at the current scroll position on mount, or the page sweeps
from the top on load. And branch this off entirely under reduced motion — parallax is the single
worst offender for vestibular discomfort.

---

## 15. Horizontal scroll section

**Intent:** vertical scrolling drives horizontal travel.

Pin the section with the platform's native sticky mechanism. Map the pinned region's scroll progress
`0 → 1` onto the track's `x`, `0 → −(trackWidth − viewportWidth)`, `curve linear`, smoothed with
`spring(0.3, 0)`.

**Watch out:** the pin must be native. Writing a position every frame from a scroll handler is one
frame behind the compositor and visibly judders.

---

## 16. Scroll image reveal

**Intent:** the image is being uncovered as you scroll.

Animate a **clip** from `inset 100% 0 0 0` to `inset 0`, mapped to scroll progress across the
element's entry, `curve linear`. Optionally scale the image `1.1 → 1` over the same range so the
content moves at a different rate from the mask.

**Watch out:** clip is cheap; animating the element's height is not. Also cap the counter-scale — a
`1.3` start is visibly soft at the beginning.

---

## 17. Split text

**Intent:** the sentence assembled itself.

Split into characters or words, then apply recipe 1 per fragment with `stagger 0.02` (characters) or
`0.04` (words).

| Count | Split by |
|---|---|
| ≤ 40 characters | characters |
| more | words |
| a paragraph | lines, or don't split |

**Watch out:** accessibility. The container carries the full text as its accessible label and the
fragments are hidden from assistive technology, or a screen reader will read your headline one
letter at a time. Also: splitting inflates the element count once, which is fine — but re-splitting
on every resize is not.

---

## 18. Word-by-word scroll reveal

**Intent:** the paragraph is being read to me as I scroll.

Each word's opacity goes `0.2 → 1`, mapped to scroll progress across the paragraph, with each word's
range offset by its index so a wave passes through the text.

**Watch out:** the resting value is `0.2`, not `0`, so the paragraph's shape is visible before it
resolves. But see `contrast.md` §7 — `0.2` is a *transient* state here, passing in under a second.
Never leave text parked at a half-readable opacity.

---

## 19. Typewriter with human rhythm

**Intent:** someone is typing this.

Base interval `0.045s` per character, with:
- `× 0.5` for a repeated character
- `+ 0.12s` after a comma, `+ 0.3s` after a full stop
- `± 30%` random jitter per character

A perfectly regular typewriter reads as a machine, which is the opposite of the intent.

**Watch out:** rewriting the text content every frame forces a text re-layout every frame. Reserve
the final size up front (a fixed height, or a hidden full-text copy setting the box) so the
surrounding layout does not reflow 40 times.

---

## 20. Animated number

**Intent:** the value went up.

Tween the number, `dur 0.6  curve out`, rounding for display. Format with a **tabular / monospaced
figure style** so digit widths do not change.

For a per-digit roll, translate a strip of `0–9` vertically per digit place with `spring(0.4, 0.1)`,
staggered `0.03` from the least significant digit.

**Watch out:** without tabular figures the number visibly jitters in width as it counts, which reads
as broken rather than lively.

---

## 21. Line drawing

**Intent:** the stroke is being drawn.

Animate the stroke's dash offset from "fully hidden" to "fully drawn" — `dur 0.8  curve out`, or
mapped to scroll. Multiple paths: `stagger 0.1`.

**Watch out:** you need the path's total length. Measure it rather than guessing, and re-measure if
the path is responsive.

---

## 22. Skeleton shimmer

**Intent:** still here, still working.

A gradient band sweeping across the placeholder, `dur 1.5–2s`, `curve linear`, repeating, with the
band at very low contrast against the placeholder — around a 4% luminance difference.

**Watch out:** high-contrast or fast shimmer competes with the content it is standing in for. And
show nothing at all under 1 second — a skeleton that flashes is worse than a still moment.

---

## 23. Route / screen transition

**Intent:** I moved to a different place.

Outgoing: opacity `1 → 0`, `y → −8px`, `dur 0.15  curve in`.
Incoming: opacity `0 → 1`, `y +8px → 0`, `page` token — **after** the outgoing has finished.

**Watch out:** running both at once cross-fades two full screens, which is muddy at any duration.
Sequence them. And if the transition mechanism your platform provides snaps to the end state when
interrupted, do not use it for a back button people press twice.

---

## 24. Elastic boundary

**Intent:** you have reached the edge, and the edge is a rule rather than a wall.

Past the limit, apply **half** the input delta (`offset = overshoot × 0.5`), with resistance rising
as the overshoot grows if you want to be fancy. On release, `spring(0.4, 0)` back to the limit,
seeded with the release velocity.

**Watch out:** the resistance factor is the whole feel. At `1.0` there is no boundary; at `0.1` it
feels broken. `0.5` is the value nearly every platform converged on.

---

## 26. First-sight highlight

**Intent:** this phrase is the point of the paragraph, and you are meeting it for the first time.

A solid block of the accent colour wipes across the phrase, holds, and then drops to a light tint
that stays. The words are not there during the wipe — they arrive with the fade.

| Phase | Channel | From → To | Timing |
|---|---|---|---|
| wipe | block width | `0% → 100%`, from the left | `dur 0.36  curve out` |
| hold | — | solid accent, no text | `0.08s` — a beat, not a pause |
| settle | block | accent → accent at `20–30%` — still obviously the accent colour, not a grey | `dur 0.56  curve inout` |
| settle | text | transparent → ink | `dur 0.48`, finishing at ~92% of the whole |

**On the total.** One second is above the `0.4–0.8s` narrative tier in `SKILL.md` §3.4, and that is
deliberate rather than an oversight: the phrase arriving is the payoff, and hurrying it wastes the
wipe that set it up. The tier's ceiling exists to stop people waiting — this animation fires once,
blocks nothing, and is over before a reader finishes the sentence around it. **If you need the
budget back, take it from the wipe and the hold, not from the reveal.** That is the direction this
recipe was retuned in, and the reveal is the last thing that should get shorter.

The resting state — light tint plus emphasised text — is the **base** style. The animation is
additive, so a reader with no script, no `IntersectionObserver` or reduced motion still gets the
emphasis and loses only the stroke.

Fire once, per `recipes.md` §3. At most four or five phrases in a whole page: this animation carries
no information, it only directs attention, and attention directed everywhere is directed nowhere.

**Watch out:** four things, and every one of them has bitten this pack's own reference
implementation.

- **Never animate the font weight.** Weight changes advance widths and reflow the line. Set the
  emphasis weight once, statically, and animate only the block.
- **A solid block hides ink text.** Either knock the text out to the page's background token — which
  is light in a light theme and near-dark in a dark one, so one token is correct in both — or, as
  specified above, do not show text during the solid phase at all. What you may not do is leave
  dark text sitting on a dark block, even for 200ms.
- **If the resting state hides the text, a phrase that never gets its animation is simply missing
  from the sentence.** Guard it: if the observer has not fired within a few seconds and the phrase
  is on screen, run it anyway → `errata.md` §A7.
- **A phrase inside a section that fades in must wait for it** → `errata.md` §A6.
- **Ease every segment, including the settle.** A multi-phase animation is usually written as one
  shorthand with one timing function, and if that function is `linear` the whole thing crawls at
  constant speed except wherever a keyframe overrides it. The wipe is the segment people remember to
  ease; the settle is the one they forget, and a settle that stops dead is what "the fade looks
  wrong" means. Set the curve per segment, in the keyframes.
- **A hold is a beat, not a pause, and the settle must ease out of it.** Two mistakes that produce
  the same complaint — *it sticks, then vanishes*. A hold long enough to be fully static (much past
  `0.15s`) stops reading as emphasis and starts reading as a hitch. And `curve out` on the settle is
  wrong here even though it is right almost everywhere else: easeOut front-loads its change, so the
  colour dumps in the first fifth of the segment and the block appears to disappear rather than
  calm down. Use `curve inout` — it leaves the hold gently and decelerates into rest.
- **Let the words land before the block finishes.** A state signal arrives faster than the surface
  carrying it (`contrast.md` §5): finish the text at about 85% of the animation and let the block
  keep easing to 100%. Cross-fading both at the same rate reads as mush.

## 25. Branching on reduced motion

**Intent:** the same information, without the vestibular cost.

| Normal | Reduced |
|---|---|
| `y`, `x`, `scale` changes | dropped entirely |
| opacity, colour, brightness | **kept**, at the same durations |
| parallax, scroll-linked movement | dropped; show the end state |
| infinite loops, autoplaying video | stopped, with a control to start them |
| shared-element transitions | replaced by a cross-fade |

**Watch out:** "reduced" does not mean "none". Removing every transition leaves the user with no
signal that the screen changed, which is its own accessibility failure. Keep the fade.
