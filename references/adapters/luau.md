# adapters/luau.md — Luau / Roblox

**Tier: 2 with `TweenService`, 1 with a hand-integrated spring.**

`TweenService` captures an instance's current property values at `Play()`, so re-triggering a tween
retargets from where the object actually is rather than from a declared start. That is genuine Tier
2 behaviour and it is better than people assume. What it cannot do:

- **No custom easing curves.** You get a fixed enum of `EasingStyle` × `EasingDirection`. A spring
  cannot be expressed as a tween here at all, which is the one place this runtime is meaningfully
  poorer than the web.
- **No velocity handoff.** A retarget restarts at zero speed.

So the division of labour is: **`TweenService` for everything with a fixed duration, a hand-written
spring for everything driven by a gesture.** The spring is about forty lines and is given below.

There is no DOM, no CSS, and no shadow primitive here, so `contrast.md` needs a translation layer
too — §5 of this file.

---

## Mapping the vocabulary

| Spec | Luau |
|---|---|
| `dur 0.25` | `TweenInfo.new(0.25, …)` — seconds, same as this pack |
| `curve out` | `Enum.EasingStyle.Quad, Enum.EasingDirection.Out` |
| `curve in` | `Enum.EasingStyle.Quad, Enum.EasingDirection.In` |
| `curve inout` | `Enum.EasingStyle.Quad, Enum.EasingDirection.InOut` |
| `curve linear` | `Enum.EasingStyle.Linear` |
| `spring(Dv, b)` | the integrator in §3 — not expressible as a `TweenInfo` |
| `stagger 0.04` | the `DelayTime` argument: `TweenInfo.new(d, s, dir, 0, false, i * 0.04)` |

`Quad.Out` is the closest single match to the shallow easeOut this pack is tuned against. `Sine.Out`
is gentler and reads better below `0.15s`. **Do not** reach for `Quint`, `Quart` or `Exponential`
for interface work — they are far too abrupt at the start, and they are the main reason Roblox UI
often feels like it snaps rather than settles. `Bounce` and `Elastic` are, for product UI, always
wrong; if you want liveliness, use a real spring with `b = 0.15`.

```lua
local TweenService = game:GetService("TweenService")

local OUT  = Enum.EasingDirection.Out
local QUAD = Enum.EasingStyle.Quad

local T = {
    feedback = TweenInfo.new(0.12, QUAD, OUT),
    micro    = TweenInfo.new(0.2,  QUAD, OUT),
    exit     = TweenInfo.new(0.15, QUAD, Enum.EasingDirection.In),
    lumin    = TweenInfo.new(0.13, QUAD, OUT),
    page     = TweenInfo.new(0.5,  QUAD, OUT),
}

local function tween(inst, info, goal)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end
```

`TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime)` — the last
three default to `0, false, 0`, which is what you want almost always. `Reverses = true` is a trap
for anything but a deliberate ping-pong, because it doubles the duration you thought you wrote.

---

## What to animate, and what not to

This is where Roblox differs most from the web, and getting it wrong is the usual cause of a UI that
stutters under load.

| Intent | Use | Not |
|---|---|---|
| move | `Position` with the **Offset** components (`UDim2.new(0, x, 0, y)`) | the Scale components, which re-solve against the parent |
| scale | a `UIScale` instance's `.Scale` | `Size`, which reflows every sibling under a `UIListLayout` |
| rotate | `Rotation` | — |
| fade one element | `BackgroundTransparency` / `TextTransparency` / `ImageTransparency` | — |
| fade a whole panel | a **`CanvasGroup`**'s `GroupTransparency` | tweening every descendant separately |
| tint | `BackgroundColor3` / `ImageColor3`, or a `CanvasGroup`'s `GroupColor3` | — |
| depth order | `ZIndex` (or `DisplayOrder` between `ScreenGui`s) | — |

Two of those rows carry most of the value:

**`UIScale` is your `transform: scale`.** Set the object's `AnchorPoint` to choose the origin — that
is the direct equivalent of `transform-origin`, and it is what makes `recipes.md` §8 (a popover
growing from its trigger) possible. `AnchorPoint = Vector2.new(0.5, 0.5)` scales about the centre;
`(0, 0)` about the top-left corner.

**`CanvasGroup` is the compositing layer.** It renders its descendants to one texture, so
`GroupTransparency` is a single cheap fade of an arbitrarily complex panel — instead of forty tweens
that each have to be created, played and cancelled in step. Use one for any panel that enters or
exits as a unit. The cost is a texture allocation, so do not wrap every button in one.

**Tweening `Size` is the layout tier** from `SKILL.md` §6. Under a `UIListLayout` or `UIGridLayout`
it re-solves the whole layout every frame. Use `UIScale`, or accept the cost knowingly on a single
element.

---

## Springs

No `TweenInfo` can express one, so integrate. This is `spring.md` §3 verbatim, in Luau, driven by a
single shared connection.

```lua
local RunService = game:GetService("RunService")

local Spring = {}
Spring.__index = Spring

-- Dv: visual duration in seconds.  b: bounce, 0..1.
function Spring.new(value, Dv, b)
    local zeta = 1 - b
    local w0 = 2 * math.pi / Dv
    return setmetatable({
        x = value, v = 0, target = value,
        k = w0 * w0,
        c = 2 * zeta * w0,
        restDelta = 0.001,
        restSpeed = 0.01,
        done = true,
    }, Spring)
end

function Spring:setTarget(target)
    self.target = target
    self.done = false           -- x and v are untouched: this is the velocity handoff
end

function Spring:step(dt)
    if self.done then return self.x end
    dt = math.min(dt, 1 / 30)                  -- a long frame must not explode a stiff spring
    local steps = math.ceil(dt / (1 / 240))
    local h = dt / steps
    for _ = 1, steps do
        local a = -self.k * (self.x - self.target) - self.c * self.v
        self.v += a * h                        -- semi-implicit Euler: velocity first,
        self.x += self.v * h                   -- then position with the new velocity
    end
    if math.abs(self.x - self.target) < self.restDelta and math.abs(self.v) < self.restSpeed then
        self.x, self.v, self.done = self.target, 0, true
    end
    return self.x
end
```

Drive **all** of them from one connection. A hundred springs on a hundred `Heartbeat` connections
costs far more than a hundred springs in one loop, and it makes the frame's work impossible to
budget.

```lua
local active = {}   -- [Spring] = function(x) ... end

RunService.PreRender:Connect(function(dt)
    for spring, apply in pairs(active) do
        apply(spring:step(dt))
        if spring.done then active[spring] = nil end
    end
end)
```

Use `PreRender` (formerly `RenderStepped`) for anything visual — it runs immediately before the
frame is drawn, so a value written there appears on that frame rather than the next. `PostSimulation`
(`Heartbeat`) is a frame behind for UI purposes.

**Setting `restDelta` and `restSpeed`.** The values above assume the spring is driving a normalised
`0–1` value, which is the shape to prefer: run the spring in `0–1` and map it onto pixels, scale or
colour at the point of application. If you must run it in pixel space, scale both thresholds by the
distance, per `spring.md` §3.

**Velocity handoff on release.** When a drag ends, seed `spring.v` with the pointer's velocity in the
same units per second, and the throw comes out for free. This is the entire reason to write the
forty lines rather than use a tween.

---

## Elevation without shadows

Roblox has no shadow primitive and no UI blur, so `contrast.md` needs a physical implementation.

**Shadows** are nine-sliced images behind the element. Two of them, per the contact + ambient
structure in `contrast.md` §1:

```lua
local function shadow(parent, assetId, spread, transparency)
    local s = Instance.new("ImageLabel")
    s.BackgroundTransparency = 1
    s.Image = assetId
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(64, 64, 64, 64)       -- match your asset
    s.ImageColor3 = Color3.new(0, 0, 0)
    s.ImageTransparency = transparency
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.Position = UDim2.fromScale(0.5, 0.5)
    s.Size = UDim2.new(1, spread, 1, spread)
    s.ZIndex = parent.ZIndex - 1
    s.Parent = parent
    return s
end
```

Then **animate `ImageTransparency`, never `Size`**. That is the cross-fade workaround from
`contrast.md` §6, and here it is not an optimisation but the only sane option: resizing a nine-slice
every frame re-tessellates it. Build both tiers, rest the higher one at `ImageTransparency = 1`, and
fade it in.

**Rim light** — the bright top edge that says "raised" — is a `UIStroke` with
`ApplyStrokeMode = Border`, or a one-pixel `Frame` pinned to the top edge with a `UIGradient` fading
downward. Remember `contrast.md` §2: on a dark surface the rim must be far weaker than on a light
one, typically 7% white rather than 60%.

**Elevation in a dark theme is surface brightness**, which is the easy half here — it is just
`BackgroundColor3`, and it tweens cheaply. Build the four-tier surface ladder from `contrast.md` §2
as a table of `Color3` values and index it by elevation.

**Backdrop blur does not exist for UI.** Do not design around it. A flat scrim at 45–60% black is
the whole toolkit, and per `contrast.md` §4 the dark theme needs the higher end of that range or a
brighter dialog.

---

## Exit animations

There is no keep-alive mechanism, which per `pitfalls.md` §1 means you build one: do not destroy the
instance until the tween has finished.

```lua
local function exit(gui)
    local t = tween(gui, T.exit, {
        GroupTransparency = 1,
        Position = gui.Position + UDim2.fromOffset(0, 4),
    })
    t.Completed:Connect(function()
        gui:Destroy()
    end)
    return t
end
```

**`Completed` fires with a `PlaybackState`** — `Completed` for a finished tween, `Cancelled` for an
interrupted one. Per `pitfalls.md` §7, do not hang game logic off it; and in this specific case,
destroy the instance on **either** state, or a cancelled exit leaves an invisible element in the
tree intercepting input forever.

The `GroupTransparency` in that snippet assumes the panel is a `CanvasGroup`. If it is not, you are
tweening every descendant's transparency separately and keeping them in step by hand — which is
exactly the situation `CanvasGroup` exists to remove.

---

## Input and gestures

- Hover: `GuiObject.MouseEnter` / `MouseLeave`, but gate them on
  `UserInputService.MouseEnabled` — on touch these fire from taps and produce the stuck-hover
  problem in `pitfalls.md` §6.
- Press: `InputBegan` / `InputEnded` filtered on `Enum.UserInputType.MouseButton1` and `Touch`.
  Use `GuiButton.Activated` for the actual action, so gamepad and keyboard activation work — and
  make sure the press *visual* fires for those too, per `feel.md` §8.
- Drag: `UIDragDetector` handles the common case, with `DragStyle`, `DragSpace`, `DragAxis`,
  `BoundingUI` and min/max translation covering most of what you would otherwise hand-write. Verify
  its behaviour under a scaled ancestor yourself — that is the failure in `pitfalls.md` §6 and it is
  not something the documentation promises either way. For a custom drag, take the delta from
  `InputChanged` and convert through the `GuiObject`'s `AbsolutePosition` / `AbsoluteSize` rather
  than assuming screen space; a scaled ancestor or a non-1 `UIScale` above you changes the mapping.
- Scroll: `ScrollingFrame.CanvasPosition`. There is no sticky mechanism, so a pinned element is
  driven per-frame — which is the one case `pitfalls.md` §5 says to avoid on the web, and here you
  have no choice. Read `CanvasPosition` in `PreRender`, not from a property-changed signal, or you
  will be a frame behind.

Reduced motion is exposed as `GuiService.ReducedMotionEnabled`, with a change signal:

```lua
local GuiService = game:GetService("GuiService")

local reduced = false
local ok = pcall(function() reduced = GuiService.ReducedMotionEnabled end)
if ok then
    GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
        reduced = GuiService.ReducedMotionEnabled
    end)
end
```

Per `recipes.md` §25, "reduced" means drop the movement and **keep the fade**.

Two neighbouring properties are worth honouring at the same time, since you are already reading the
service: `GuiService.PreferredTransparency` (a `float`) scales how transparent your UI should be,
and `GuiService.PreferredTextSize` reports the user's text-size preference. All three are read-only
and non-replicated, all three have change signals, and **all three want the same `pcall` guard** —
they are recent additions, and the failure mode of an unguarded read is a thrown error rather than a
default. They are not motion, but they are the same category of promise: a scrim that ignores
`PreferredTransparency` undoes the work in `contrast.md` §4, where the scrim's opacity is specified.

---

## Gotchas specific to Roblox

| Symptom | Cause |
|---|---|
| A tween "doesn't finish" | something else started a tween on the same property; the newer one wins. Keep the handle and `Cancel()` deliberately |
| The panel jumps at the start of the tween | the goal table mixes `Scale` and `Offset` in a `UDim2`; interpolating both against a resizing parent is not what you meant |
| The list shudders while one item animates | you tweened `Size` under a `UIListLayout` — use `UIScale` |
| Scaling grows from the corner | `AnchorPoint` is `(0, 0)`; it is the transform origin |
| Everything fades at slightly different rates | per-descendant transparency tweens — use a `CanvasGroup` |
| The spring never stops and the frame time creeps | no rest check, or the connection is never disconnected |
| A stiff spring explodes after a lag spike | `dt` was not clamped and substepped |
| A destroyed UI still eats clicks | the exit tween was cancelled and `Completed` never ran the `Destroy()` |
| Motion looks fine in Studio and janky in game | Studio runs at a higher, steadier frame rate; test with the client throttled |
