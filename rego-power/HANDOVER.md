# REGO Power — developer handover

A single-file HTML5 game. No build step, no framework, no dependencies, no network calls at
runtime. Open `index.html` in a browser and it runs.

Written for PATtech as a public-facing explainer of 24/7 carbon-free energy matching. It is
finished enough to publish and rough enough to want a developer's pass — that is what this
document is for.

---

## 1. What you are getting

| File | Notes |
|---|---|
| `index.html` | ~2,390 lines. The entire game: markup, CSS and JS in one file. |
| `sw.js` | Service worker. Network-first for the page, cache-first for assets. |
| `manifest.webmanifest` | PWA manifest — installable to a phone home screen. |
| `icon-192/512/maskable-512.png`, `apple-touch-icon.png` | App icons. |
| `og-image.png` | 1200×630 link preview card. |
| `README.md` | Product-side documentation: rules, tuning, hosting, promo. |
| `promo/` | Videos, stills, carousel, copy, poster. Not needed to run the game. |

Target: modern mobile Safari and Chrome, portrait. Desktop works and is keyboard-playable, but
the layout is designed phone-first (`max-width: 520px`).

---

## 2. Architecture in one page

Everything is one IIFE-free global scope inside a single `<script>`. Deliberate — it made the
thing fast to iterate on and trivial to email around. It is also the first thing you may want to
change.

**Rendering** is a single `<canvas id="board">`, redrawn every frame from `draw()`.
**Interface chrome** (HUD, buttons, cards, overlays) is DOM and CSS, updated on events, not per
frame. The two never overlap: nothing in the canvas is clickable except the board itself.

The main loop is `loop(t)` at line ~2218. Order per frame:

```
loop()
 ├─ advance weather (clouds drift, wind field shifts, rain, lake)
 ├─ tempo = f(level, day progress)      ← weather and drop speed share this clock
 ├─ if !paused && !tutGate(): drop timer → stepDown()
 ├─ step particles, pops, ring flashes, tips
 └─ draw()
      ├─ cached sky bitmap (stars, skyline, gradient)
      ├─ aurora, sun/moon, clouds, wind streaks, rain
      ├─ demand shading + availability scrim
      ├─ placed blocks (sprite blits)
      ├─ ghost + live piece + landing guides
      ├─ REGO seals, flashes, rings
      ├─ demand line
      ├─ particles, score pops
      ├─ bloom()          ← downscale, blur, additive composite
      ├─ drawTips(), drawCoach()
      └─ drawGauges(), scanlines() + vignette
```

### Code map (`index.html`)

| Line | Section |
|---|---|
| ~297 | `BRAND_SRCS` — logo fallback chain |
| ~358 | Constants: `COLS/ROWS/DAWN/DUSK`, `MODES`, `SRC`, `NAMES`, `AWARDS` |
| ~374 | `glyphSVG()` — the six source symbols as SVG, for DOM use |
| ~420 | Mutable game state (all `let`, module-scope) |
| ~429 | Audio — WebAudio oscillator blips, no files |
| ~460 | Canvas sizing, DPR cap, sky bitmap |
| ~525 | Weather model |
| ~549 | Game model: demand curve, pieces, collision, lock, battery, gas |
| ~877 | Particle effects |
| ~891 | Drawing: glyphs, sprite cache, all scene layers, `draw()` |
| ~1353 | First-run coach and just-in-time tips |
| ~1578 | Flow: `newDay`, cards, summary, `endDay`, `gameOver`, streak, `intro` |
| ~1918 | Animated how-to-play (its own canvas + scene renderer) |
| ~2136 | Intro card looping demo (another small canvas) |
| ~2206 | Pause, main loop |
| ~2266 | Input: keyboard, drag/tap, hold-repeat |
| ~2364 | Boot |

---

## 3. Data model

### Board
`board[row][col]` — `null` or a source key (`'solar' | 'wind' | 'hydro' | 'geo' | 'batt' | 'gas'`).
Row 0 is the top. `COLS = 24` and **must stay 24** — the columns are the hours of the day, which
the entire concept rests on. `ROWS = 16` is free to change.

`demand[col]` — integer block height each hour must reach, from `makeDemand(day)`.

### Piece
```js
piece = { src:'wind', m:[[0,1,1],[1,1,0]], x:10, y:0 }
```
`m` is a row-major grid, row 0 on top. `rotCW(m)` returns a new rotated grid; `rotate()` tries wall
kicks `[0,-1,+1,-2,+2]` then two floor kicks. Shapes come from `SHAPES[src][tier]` where tier is
`big|mid|low`, chosen by how strong that resource currently is.

### Non-obvious rule
After a piece locks, `settleCols()` compacts every column downward, so blocks fall into gaps.
This is **not** Tetris behaviour and it is deliberate: rotation creates overhangs, and in a game
whose goal is filling all 24 hours an unfillable hole would poison a day the player could no
longer win. Scoring therefore measures the *change in column heights* before and after, not
individual cells — see `lock()` at ~741. If you change settling, you must change scoring.

### Persistence
`window.storage` (an artifact-host API) wrapped in try/catch, key `regopower:save`:
```json
{ "best":0, "lifetimeRego":0, "bestDay":0, "badges":[],
  "seenTut":false, "streakDays":0, "lastPlayed":"YYYY-MM-DD", "daysPowered":0 }
```
Written and read through a small `STORE` shim (~1766) that tries the artifact host's
`window.storage` first, falls back to `localStorage`, and no-ops silently if both are blocked
(private browsing). It never throws. On your website it will use `localStorage`, so progress and
the daily streak persist per browser, per origin — which is worth knowing before you move domains.

---

## 4. Domain rules worth not breaking

The game is an argument, so some rules carry meaning beyond play balance:

- **An hour served entirely by renewables earns a REGO** (gold seal). Any gas anywhere in that
  column and it earns nothing — `certified(c)`, line ~596. This is the whole point of the game;
  it should stay a hard binary.
- **Battery output counts as clean.** It stored renewable overflow, so it does.
- **Gas always works.** It is never blocked or rationed beyond a per-day count. The cost is the
  certificate and the clean percentage, not the ability to finish. Making gas unavailable would
  break the argument.
- **Intermittency is real, not decorative.** Solar is limited to `DAWN..DUSK` and its piece size
  scales with cloud cover; wind is blocked where `wind[c] < 0.22`; hydro drains `lake`. If you
  optimise these away the game stops meaning anything.

---

## 5. Known issues and rough edges

Honest list. None are blockers; all are things a developer will trip over.

1. **Progress is per-browser, not per-user.** `localStorage`, no accounts. Clearing site data
   loses the streak, and it does not follow anyone to another device. Fine as shipped; a real
   backend is a product decision, not a bug.
2. **One global scope, one file.** ~2,390 lines. Fine to ship, awkward to maintain. If you split
   it, keep `index.html` self-contained as a build output — being emailable as one file has been
   genuinely useful.
3. **The PATtech logo is not embedded.** `BRAND_SRCS` (~297) tries a local
   `PATtechLogoWhite.svg`, then two Webflow CDN URLs read off pattech.com, then hnz.app, then
   falls back to a drawn arrow-and-wordmark. **I was never able to open those CDN files to check
   them** and Webflow rewrites those URLs on republish. Drop the real SVG into the folder and
   delete the remote entries.
4. **Fonts load from Google Fonts.** First offline load falls back to system sans. Self-host DM
   Sans and DM Mono if you care.
5. **No pause on blur, only on `visibilitychange`.** Switching windows on desktop keeps it running.
6. **Bloom uses `ctx.filter`**, guarded by a capability check (`bloomOK`). Safari 16.4+. Set
   `bloomOK = false` if an old device struggles; costs ~1.4ms/frame.
7. **Audio needs a user gesture** — it starts on the first tap, which is always the PLAY button.
   Fine in practice, but there is no explicit unlock.
8. **Landscape is unhandled.** The layout assumes portrait; it does not break, it just wastes space.
9. **No analytics.** Nothing is tracked. If you add any, say so publicly — it has been promoted
   as no sign-up, no ads, no tracking.
10. **Difficulty is barely tuned.** Two modes, hand-set constants, no telemetry behind them.
11. **`sw.js` caches by a manual `VERSION` string.** Bump it on every deploy or returning players
    keep the old build. Automate this in your pipeline.

---

## 6. Suggested first tasks, in order

1. **Embed the real logo** and regenerate `icon-*.png` and `og-image.png` from it.
2. **Self-host the fonts.**
3. **Automate the `sw.js` version bump** in whatever deploy step you use.
4. Then, if you want to restructure: split into `game.js`, `ui.js`, `render.js`, `tutorial.js`
   with a tiny bundler, keeping a single-file output.

---

## 7. Tuning constants

All near the top of the `<script>` unless noted.

| Symbol | Line | Effect |
|---|---|---|
| `COLS` | 359 | 24. Do not change — they are the hours. |
| `ROWS` | 359 | Board height in blocks. |
| `DAWN`, `DUSK` | 359 | Daylight window for solar. |
| `MODES` | 360 | Easy/normal: battery capacity, gas uses, drop-speed multiplier, demand lift and peak, weather rate. |
| `BATT_CAP` | 364 | Set from `MODE`; lower is harder. |
| `SRC` | 365 | Colours per source. |
| `AWARDS` | 407 | Badges and the predicates that earn them. |
| `SHAPES` | 572 | The piece bag per source per strength tier. |
| `makeDemand()` | 550 | The demand curve — morning shoulder, evening peak, daily lift. |
| `TUT_STEPS` | 1356 | The coach's gated steps. |
| `HOWTO` | 1919 | The animated guide's scene captions. |
| `dropBase` | in `newDay()` | Falling speed per day. |
| `VERSION` | `sw.js:3` | Cache bust. Bump on every deploy. |
| `SAVE_KEY` | ~1766 | localStorage key for saved progress. |

---

## 8. Testing

There is no test suite. What I used, and what I would keep, is a headless bot: drive the page with
Playwright, and each turn evaluate every rotation × column, score placements by
`gained*10 − wasted*28`, then `hardDrop()`. It plays a full day in seconds and catches almost
every regression — stuck pieces, unreachable days, scoring drift, crashes.
`promo/video/record-gameplay.py` contains a working version of exactly this bot; it was written to
record the promo video but it doubles as a smoke test.

Worth checking manually after any change: the coach (`HOW TO PLAY → ▶ TRY IT`) completes all five
steps; a day can still be finished 24/24; the summary numbers total 100% and 24 hours.

---

## 9. Deploy

Static hosting, nothing to build. Serve the folder; `index.html` is the entry point. HTTPS is
required for the service worker and home-screen install.

Bump `VERSION` in `sw.js`, upload, done. The page is fetched network-first so a deploy lands on the
next visit, and the page reloads itself once when a new worker takes over.

---

## 11. Rewards layer (added in the September build)

Five features were added because playtesters said the game did not pay them back
enough for playing well. All five are **deterministic**. None of them roll dice.

That was a deliberate constraint. The obvious way to make a game feel more
exciting is a variable-ratio random reward — the slot-machine loop. It is also
the mechanic regulators in NZ and Australia keep circling in games aimed at
children, and it would sit very badly under a brand whose entire argument is that
you cannot fake clean energy with favourable averaging. The escalation in Tetris
(single, double, triple, tetris) is not random either, and it is the thing people
actually remember. Everything below follows that model: announced in advance,
earned by skill, repeatable.

**Do not replace any of this with a random payout.** It would take about ten
minutes and it would be the wrong ten minutes.

### Golden hour — `pickGolden()`, `isGolden()`
At the start of every day one evening hour (16–20, weighted by that day's demand)
is flagged, announced by toast and sound, and drawn with a gold column wash and a
floating crown. Certifying it pays `REWARD.goldenMult` times a normal certificate
with a full cascade. This is the one mechanic that is *literally* the domain
argument: a REGO minted at 6pm is worth vastly more than the same certificate
minted at midday, because that is the hour the grid struggles to cover cleanly.
The `crown` milestone adds a second golden hour in the morning peak (6–9).

### Clean run — `chain`
Counts consecutive certified hours. Never reset by a bad piece; reset **only** by
gas. Each step raises the pitch of the certificate sound through a pentatonic
scale, brightens the seal and increases screen shake. `REWARD.chainMarks` are the
lengths that get a fanfare. Breaking a run of 3+ plays a distinct descending
sound — the point is that the gas button should feel like it costs something.

### REGO vault — `vaultCard()`
Every certificate is stored as `{d: date, h: hour, g: golden}`, capped at the last
400 (`vaultHours[]` keeps the full lifetime tally per hour, uncapped). The card
shows a 24-bar histogram of certificates by hour with the evening peak in gold,
and states how many of the player's lifetime certificates came from that peak.
This is the most quietly useful screen in the game: it is a personal version of
the same chart the Scope 3 analysis makes.

`vaultHours` is sparse until every hour has been certified at least once. Densify
before taking a maximum — `Math.max` over an array hole returns `NaN`, which
silently collapsed every bar to its minimum height during development.

### Milestones — `UNLOCKS`, `checkUnlocks()`, `unlockLadder()`
Fixed lifetime-certificate thresholds, every rung visible from the start on the
intro card and in the vault. `unlockSeen[]` persists which have been announced;
`newUnlocks[]` is the transient list for the current summary card and is cleared
in `newDay()`, **not** at the end of `endDay()` — on a perfect day the summary
card is built asynchronously after the finale, so clearing it early loses the
unlock rows.

Effects are wired at: `buildSky()` (harbour cranes, taller skyline, lit windows),
`seedWeather()` (offshore wind base), `aurora()` (alpha), `pickGolden()` (second
golden hour).

### Perfect day — `runFinale()`
24/24 no longer goes straight to a summary card. Each hour lights in turn on a
72ms timer with a rising pentatonic note, then a white flash, a seven-note chord
and a 1.5s hold before the card appears. `finale` is read by `draw()`; the render
loop keeps running because `running=false` only stops physics, not drawing.

## 12. Audio

The old engine was a single `beep()` — one oscillator, one exponential ramp. It
has been replaced with a small synth in the same place:

- `audio()` builds the context lazily, plus a `MASTER` gain and a `VERB`
  convolver whose impulse response is generated from decaying noise. Nothing is
  loaded from the network.
- `tone({f,to,dur,type,v,atk,lp,detune,verb,at})` — one voice with a real
  attack/decay envelope, optional pitch glide and optional lowpass.
- `noise({f,to,dur,v,q,type,verb})` — filtered noise for percussive hits.
- `seq()` / `chord()` schedule on the **audio clock**, not `setTimeout`, so
  fanfares stay in time when the frame rate drops.
- `S` is the named sound table. `S.rego(n)` takes the chain length and picks its
  root from `PENT`.

`unlockAudio()` is bound to the first `pointerdown`/`keydown`/`touchstart`. iOS
and Chrome both start the context suspended, and without this the first few
sounds of a session are silently dropped.

Muting is one gain node, so the 🔊 button is instant and cannot leave a voice
ringing.

## 13. Reward tuning

All of it is in the `REWARD` block next to `REGO_GOLD`:

```js
const REWARD={ rego:40, goldenMult:6, chainStep:.15, chainCap:10,
               chainMarks:[3,6,10,16] };
```

**Scores are now much larger than in the previous build** — a good day roughly
triples. Any high score saved by the old version will look small next to a new
one. If that matters more than the headline number, drop `goldenMult` to 3 and
`chainStep` to .08. `goldenMult` is the number carrying the lesson, so I would
lower `chainStep` first.

## 14. Layout: phone, landscape and desktop

There is one breakpoint, applied by JS rather than a media query so the render
code and the CSS can never disagree about which layout is live:

```js
const wide = window.innerWidth>=720 && window.innerWidth/window.innerHeight>=1.25;
document.body.classList.toggle('wide', wide);
```

A portrait phone never matches and is completely untouched by this work. Desktop
windows and phones held sideways both match and get the same layout: the board in
the left column, everything that used to stack underneath it moved into a 272px
rail on the right, plus a keyboard legend that only appears in wide mode. Nothing
sits below the board and nothing scrolls.

### The board sizes on both axes now

It used to be `cell = floor(width / (COLS+GUT))` and nothing else, so the board's
height was a function of its width. That is right in a tall phone column and
wrong everywhere else — a 844x390 landscape viewport produced a 617px page.

`sizeCanvas()` now takes the smaller of the width-derived and height-derived cell
sizes, and writes an explicit pixel width onto the canvas so it is never
stretched off its aspect ratio.

Two traps here, both hit during development:

**Do not shrink-wrap `#boardWrap` on both axes.** If the container sizes to the
canvas while the canvas sizes to the container, the board loses a few pixels on
every resize and collapses. It stretches horizontally (`justify-self:stretch`,
`width:100%`) so `clientWidth` is a stable measurement, and wraps vertically.

**Do not measure available height from the board's own `getBoundingClientRect()`
.top.** The board is vertically centred in wide mode, so its top moves when it
resizes — same oscillation. Height is measured from the hour bar's bottom edge,
which does not move.

### Results

| viewport | before | after |
|---|---|---|
| 390x844 phone | 192px board, fits | unchanged |
| 844x390 landscape | 272px board, **617px page in a 390px viewport** | 272px board, fits |
| 1440x900 desktop | 272px board in a 520px column | 608px board |

Verified stable: six consecutive `relayout()` calls at 1440x900 all settle on
`cell = 38`, and rotating 390x844 to 844x390 and back twice produces no overflow
and no drift.

## 15. Bug fixed: drag was broken on every platform

`down()` recorded `col0: piece.col`. Pieces have `.x`; there is no `.col`
anywhere in the file. So `col0` was `undefined` and every drag called
`moveTo(NaN)`.

`Math.max(0, Math.min(COLS-w, NaN))` is `NaN`. `NaN !== piece.x` is always true,
so the walk loop always ran, and `NaN > piece.x` is always false, so the
direction was always `-1`. **Dragging in either direction walked the piece left
until it hit the wall or an illegal column.**

Measured before the fix, on a phone viewport: dragging from column 5 to column 18
moved the piece from x=11 to x=6 — right gesture, left result.

This is the control the README calls "the main control". Tap-to-column was
unaffected, which is presumably why it survived: `up()` handles taps on a
separate path.

Two reasons the test bot never caught it, worth knowing before trusting that bot
again: it drives `move()` and `hardDrop()` directly and never issues a pointer
gesture, and a piece slammed to the left wall still produces a plausible-looking
game. `moveTo()` now also returns early on a non-finite target.

**If you add controls, test them with real pointer events**, not by calling the
movement functions. `/tmp`-style gesture tests are in §8.

## 10. Licence and credit

Built for PATtech. The line to keep visible is **"REGO Power — by PATtech"**; it appears on the
intro card, in the header, on the results card and as a watermark on the board.

No third-party code. No fonts bundled (loaded from Google Fonts by URL). All artwork is drawn in
code — there are no image assets in the game itself beyond the icons.
