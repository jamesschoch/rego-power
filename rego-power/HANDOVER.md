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

## 10. Licence and credit

Built for PATtech. The line to keep visible is **"REGO Power — by PATtech"**; it appears on the
intro card, in the header, on the results card and as a watermark on the board.

No third-party code. No fonts bundled (loaded from Google Fonts by URL). All artwork is drawn in
code — there are no image assets in the game itself beyond the icons.
