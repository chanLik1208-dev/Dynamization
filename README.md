# Dynamization

**A language pack for interfaces that move and read like the physical world.**

An [Agent Skill](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code — and a
readable design document for anyone else. It distills the [Motion](https://motion.dev) library
(formerly Framer Motion) into working judgment, in five languages.

<sub>
<a href="SKILL.md">English</a> ·
<a href="i18n/zh-TW/SKILL.md">繁體中文</a> ·
<a href="i18n/ja/SKILL.md">日本語</a> ·
<a href="i18n/ko/SKILL.md">한국어</a> ·
<a href="i18n/es/SKILL.md">Español</a>
</sub>

---

## Why

Most animation documentation tells you *what the API does*. Almost none tells you **what makes an
animation feel real** — and that is where the work actually goes wrong.

Dynamization is built on two pillars:

- **Motion** — the language of **time**: where a thing came from, where it went, whether you can
  touch it yet.
- **Luminance contrast** — the language of **space**: what is on top, what is alive, where to look
  right now.

Used separately, each does half a job. *Lifting* is not moving something up 4px — it is
**displacement + a larger, softer shadow + a brighter surface, all at once.** Only then does the
brain read it as *that came closer to me*.

Interfaces that feel "stiff" or "flat" almost never suffer from an inelegant curve. They violate
physical intuition, or they change one property where they should change three.

## What's inside

```
SKILL.md                  Five golden rules, runtime decision table, routing table
references/
  feel.md                 The time axis — what makes motion read as real
  contrast.md             The space axis — the expressive power of light and dark
  react.md                Motion for React: props, hooks, components
  javascript.md           Vanilla JS: animate(), scroll(), motion values
  vue.md                  Motion for Vue, and a React→Vue porting checklist
  recipes.md              25 ready-to-paste patterns, each stating its intent
  pitfalls.md             Symptom → cause → fix
  doc-index.md            131 official doc slugs
i18n/<locale>/            Full translations of the judgment chapters
scripts/fetch-doc.sh      Fetch the current official text for any slug
```

The judgment chapters — `SKILL`, `feel`, `contrast`, `recipes`, `pitfalls` — are fully translated
into every supported locale. The API references stay English-only by design: they are mostly code and
API identifiers, where translation adds noise and invites drift.

## A sample of the content

**On springs** — most people think spring means bouncy. The property that actually matters is that
*when an animation is interrupted, it continues from the current position at the current velocity.*
That is the line between "feels like an object" and "feels like a slideshow".

**On dark mode** — on a dark surface, shadows are invisible. Porting a light theme's shadows straight
across makes every layer disappear. Dark themes express elevation with the opposite mechanism:
higher surfaces are brighter. Switching themes swaps the mechanism, not just the palette.

**On stagger** — the total duration is a hard ceiling. `stagger(0.1)` across 20 items is 2 seconds;
by the time the last one lands, the user is doing something else.

## A correction to the official docs

Motion's documentation pages state that the spring `stiffness` default is `1`. **It is `100`** — as
verified in the `motion-dom` source (`springDefaults`). Following the docs there produces a spring
that barely moves.

This pack also documents Motion's actual per-value default-selection logic from
`getDefaultTransition()`, which is itself a calibrated set of taste worth reading:

| What animates | What Motion picks |
|---|---|
| `x` `y` `rotate` `skew` | spring, `stiffness: 500, damping: 25` |
| `scale` family | spring, `stiffness: 550, damping: 30` — critically damped, no overshoot |
| `opacity` `color` `filter` | tween, `ease: [0.25, 0.1, 0.35, 1]`, `duration: 0.3` |
| 3+ keyframes | tween, `duration: 0.8` |

## Install as a Claude Code skill

```bash
git clone https://github.com/chanLik1208-dev/Dynamization.git \
  ~/.claude/skills/dynamization
```

Then just describe the work — "add a page transition", "this hover feels stiff", "elevation
disappears in dark mode" — and the skill loads itself. It triggers on animation vocabulary in every
supported language.

For project scope, clone into `.claude/skills/` inside the repo instead.

## Not a Claude Code user?

Read it as a document. Start with [`references/feel.md`](references/feel.md) and
[`references/contrast.md`](references/contrast.md) — those two carry the argument. The rest is
reference material.

## No paid dependencies

Every recipe is self-contained. Where an effect would normally require a paid Motion+ component
(`splitText`, `Typewriter`, `ScrambleText`, `AnimateNumber`), a free replacement is provided —
including a typewriter that models real human typing cadence (faster mid-word, slower at boundaries,
a genuine pause after punctuation) rather than a robotic fixed interval.

## Keeping current

motion.dev supports content negotiation, so the authoritative text is always one command away:

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/react-transitions
# or
scripts/fetch-doc.sh react-transitions
scripts/fetch-doc.sh --list          # every available slug
```

Where this pack and the official docs disagree, the official text wins — except for the `stiffness`
default noted above.

## Credits & licence

Built on [Motion](https://motion.dev) by Matt Perry, an excellent library. This pack is independent
documentation and is not affiliated with or endorsed by Motion.

MIT — see [LICENSE](LICENSE).
