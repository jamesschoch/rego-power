# REGO Power — a PATtech game

**24 hours. 24 certificates.**

A single-page HTML5 game about matching clean power to every hour of the day. No build step, no
dependencies, no tracking, no accounts.

## What's in the pack
```
rego-power/
├── index.html              the whole game — this is the only file that has to be served
├── manifest.webmanifest    makes it installable as a phone app
├── sw.js                   service worker — offline play (bump VERSION on every deploy)
├── icon-*.png              app icons: 192, 512, maskable, apple-touch
├── og-image.png            1200×630 link preview card
├── README.md               this file
└── promo/
    ├── copy.md                     ready-to-post text — LinkedIn ×3, X, Slack, email,
    │                               store descriptions, alt text
    ├── rego-power-carousel.pdf     5-page LinkedIn document post
    ├── carousel/page-1..5.png      the same pages as images
    ├── video/
    │   ├── rego-power-promo-4x5.mp4        1080×1350, 19s — the main post video
    │   ├── rego-power-promo-1x1.mp4        1080×1080 square
    │   ├── rego-power-promo-9x16.mp4       1080×1920 stories / Reels
    │   ├── rego-power-promo-20s-4x5.mp4    the 20s cut, 4:5
    │   ├── rego-power-promo-20s-1x1.mp4    the 20s cut, square
    │   ├── rego-power-promo-20s-9x16.mp4   the 20s cut, vertical
    │   ├── rego-power-loop.gif         8s silent loop for Slack and email
    │   ├── cta.png plate.png plate9x16.png   cards and frames, to re-cut
    │   └── record-gameplay.py          records a fresh run
    ├── social/
    │   ├── post-4x5.png · post-1x1.png · story-9x16.png   static posts
    ├── stills/01..06.png           screenshots at 3× — intro, how-to, coach, play,
    │                               storm, summary. For decks and press.
    └── print/
        ├── poster-a4.png           A4 300dpi poster with a QR code
        └── poster-qr.py            regenerate it with your own URL
```

## Posting it — the short version
1. Host the folder (see below) and get your URL.
2. `python3 promo/print/poster-qr.py https://your-url` to rebuild the poster with a live QR.
3. Post `promo/video/rego-power-promo-4x5.mp4` with the first block of text from `promo/copy.md`.
   Both a 19s and a 20s cut are included in each aspect ratio — same edit, the 20s simply holds a
   little longer on gameplay and the results card.
4. Put the link in the **first comment**, not the post body.
5. Keep `promo/rego-power-carousel.pdf` for a second post a few days later — LinkedIn treats
   document posts as a separate format and they reach a different slice of the feed.

## The game in one paragraph
The board is 24 columns — one per hour. A white line across it is the demand you must meet. Solar,
wind, hydro and geothermal fall as pieces; stack them until every hour reaches the line. Solar only
lands in daylight and shrinks under cloud, wind only lands where the wind is blowing, hydro drains a
lake that refills when it rains. Fill an hour entirely from renewables and it earns a **REGO** — a
gold seal. Touch it with gas and it earns nothing.

## How to play — the animated guide
**? HOW TO PLAY** on the intro card opens a seven-scene animated guide. Every rule is shown
happening rather than described, with one short caption each, auto-advancing every 3.6 seconds.
Tap the picture to skip ahead, and the dots show where you are.

1. **FILL EVERY HOUR TO THE LINE** — blocks stack up under a dashed line, then the row flashes green
2. **SUN: DAYTIME ONLY** — a solar block is refused in the dark, then accepted in the lit band
3. **WIND: ONLY WHERE IT BLOWS** — streaks move on one side, a wind block is refused on the still side
4. **HYDRO: THE LAKE RUNS DOWN** — the tank drains as blocks come out, then rain refills it
5. **SPARE POWER GOES TO THE BATTERY** — an overflow block flies into the battery and comes back out
6. **GAS FILLS THE GAP — BUT NO SEAL** — eight columns earn gold seals, the gas one gets a red cross
7. **EVERY CLEAN HOUR EARNS A REGO** — the day fills and seals stamp along the top

**▶ TRY IT** on that screen starts easy mode with the coach walking you through it. **BACK** returns
to the intro.

## Getting started — the coach
**EASY and PLAY always go straight into the game.** The coach is never forced on anyone — it runs
only when asked for, via **▶ TRY IT** on the how-to-play screen. First-timers get a soft glow on the
HOW TO PLAY button and the one-shot drag marker on their first piece; that is the whole nudge.

When it does run, the coach is built the way children's games do it: one action at a time, everything
else dimmed, and the game will not advance until you have done the thing. Gravity is frozen while it
waits, so nothing can go wrong while a child works it out.

**Five gated steps**, with progress dots along the bottom and a SKIP for grown-ups:

| Step | What happens |
|---|---|
| **FILL TO THE LINE** | Board dims, the demand line pulses, green arrows point up at it. Tap. |
| **DRAG** | One hour glows gold, a hand slides sideways. Frozen until you move the piece there. |
| **DROP** | The hand pushes down. Frozen until you drop. |
| **REGO** | The moment an hour is certified, everything stops and the seal fills the screen: *one clean hour*. This is the point of the game, so it gets taught rather than left to be noticed. |
| **TURN** | The hand traces a circle. Frozen until you rotate. |
| **GO!** | Coach clears, normal play begins. |

**Then just-in-time tips**, non-blocking, one at a time, each fired the first time it is relevant —
a dashed ring around the thing being talked about and two or three words:

- first solar piece → **DAYLIGHT ONLY**, ringing the daylight band
- first wind piece → **NO WIND HERE**, ringing the calm hours it cannot enter
- first hydro piece → **THE LAKE**, ringing the water gauge

Each shows once, on day one only, never overlapping each other or a gated step. Combo shouts and
score pops are muted while a lesson is on screen.

The practice day also uses a flatter demand (2–4 blocks an hour) so hours fill quickly and the first
seal arrives within a few pieces — early reward matters more than early challenge.

It can be run any number of times — **HOW TO PLAY → ▶ TRY IT** — so a second child can be handed
the phone and get the same walkthrough.

## Golden hour

Every day, one hour of the evening peak is marked with a crown before you start.
Fill it entirely with renewables and the certificate is worth six normal ones,
with a cascade to match.

This is the real thing, not a game invention. A certificate for a megawatt hour
generated at 6pm is worth many times one generated at midday, because midday is
when clean power is abundant and 6pm is when it is not. Same scheme, same
megawatt hour — the only difference is the hour stamped on it.

## Clean runs

Certify hours back to back and the sound climbs a scale, the seals brighten and
the board shakes harder. Nothing breaks a run except the gas button. Which is the
point.

## The REGO vault

Every certificate you have ever earned, kept and stamped with the hour it was made
in. The vault draws them as a chart by hour of the day, with the evening peak
picked out in gold, and tells you how many of yours came from that peak.

It is worth looking at after a week. The shape of that chart is the argument the
game is making.

## Milestones

Fixed thresholds on your lifetime certificate count — 15, 40, 90, 175, 300 — that
unlock a harbour behind the skyline, stronger offshore wind, an aurora, a second
golden hour each morning, and a bigger city. Every rung is visible from the start
on the front card and in the vault, so you always know what is next and exactly
how far away it is.

Nothing in this game is a random reward. There is no spin, no crate, no roll. If
you got something, you earned it, and you could see it coming.

## Perfect day

24 out of 24 does not just show you a summary. The board lights hour by hour up a
rising scale, then everything goes white. Getting there is genuinely hard.

## Sound

Turn it on. Half the reward is audio: the pitch of a certificate rises with your
clean run, the gas button sounds like something going wrong, and a perfect day
gets a proper chord.

The 🔊 button in the header mutes everything instantly.

## Difficulty
**EASY** and **PLAY** (normal). Easy halves the drop speed, flattens demand peaks, gives five gas
uses instead of three and a bigger battery. Hand that one to a seven-year-old.

## Daily streak — power a year
Finish a day and today's square lights up on a 52 × 7 grid: one cell per real calendar day, 365 to
fill. Come back tomorrow and the streak grows; miss a day and it resets to one. The flame and the
counter sit on the intro card and again on the results card the moment the streak advances.

Only the first completed day of each calendar day counts, so grinding ten rounds in an evening
still fills one square. The goal is the habit, not the session.

Milestones become permanent badges: 🔥 at 7 days, ⚡ at 30, 🏆 at 365.

## Progress that sticks
Best score, lifetime REGO count, furthest day, streak, days powered and every badge earned persist
between sessions and appear on the intro card.

## Pieces and rotation
Proper Tetris shapes on a cell grid — S, Z, T, L, J, O, I and some peaked forms — with 90° rotation
and wall kicks off the sides and the floor. Each source has its own bag: hydro gets the dependable
blocks, wind the awkward ones, solar the peaks, geothermal flat bars. Resource strength sets piece
size, so a clouded sun still gives you something, just smaller.

**One departure from the original:** after a piece locks, blocks settle into any gap in their own
hour. Rotation creates overhangs, and an unfillable hole would sour a day you could no longer win.

## Controls
- **Drag anywhere on the board** — the piece follows your finger. The main control.
- **Tap a column** — the piece jumps there.
- **Flick down** — hard drop. **Flick up** — rotate.
- **Arrows** — hold to repeat.
- **Keyboard** — ← → move, ↑ rotate, ↓ soft drop, space hard drop, B battery, G gas, P pause.
- **Pause** — ⏸ in the header, and it pauses itself when the phone locks or the tab hides.

On the very first piece a pulsing touch marker shows the drag gesture, then never returns.

## The symbols
One definition drives every rendering — intro card, status strip, falling block, summary rows.

| | |
|---|---|
| **Solar** | a sun |
| **Wind** | a three-bladed turbine, spinning faster the harder the wind blows in that hour |
| **Hydro** | a droplet |
| **Geothermal** | steam curling from the ground — deliberately *not* a volcano, which younger players read as burning |
| **Battery** | a bolt |
| **Gas** | smoke |

## The battery
Any block landing above the demand line flies into the battery instead of being wasted. Press 🔋 to
pour it back into whichever hour is furthest short. Once the battery is full, overflow is real spill.
One sentence covers it: *extra power goes in the battery, press to use it later.*

## The hour bar
The strip under the HUD is 24 segments — one per hour, live. Dark means unfilled, green means
served, gold means certified. You can see the day filling without looking away from the falling
piece, and the combo multiplier sits on the right of the same row.

## The end-of-day summary
- **Two numbers.** `CLEAN` — share of energy that wasn't gas. `USED` — share of what you generated
  that actually got delivered rather than spilled. Efficiency, in a word.
- **Three stars**, each labelled: DAY DONE, CLEAN, NO WASTE. Every star maps to a number on screen.
- **A 24-cell strip** — each hour coloured by whichever source did most of the work in it.
- **A row per source** — percentage of energy and hours carried. Percentages total 100, hours 24.
- **The REGO ledger** — 24 seals, gold where the hour was certified.

## The look
- **Bloom.** The board is downscaled a third, blurred and composited back additively, so every
  glowing thing — the live piece, the seals, the sun, score pops — throws real light. Guarded by a
  capability check and skipped where `ctx.filter` is unsupported.
- **A city behind the board.** A faint skyline with lit windows, a pylon and a turbine sits along the
  base, drawn once into the cached sky. The demand line now has somewhere to come from.
- **Seals catch the light.** Each earned REGO gets a slow shine sweep, staggered per hour, so a
  finished day shimmers across.
- **Gauges are glass.** Tick marks, a specular highlight and an inset shadow on the lake and battery.
- **Depth in the interface.** Inset highlights and drop shadows on the board frame, buttons and stat
  cards; buttons press in properly; cards spring in on a cubic curve with a gradient hairline across
  the top; each HUD stat carries a small accent bar in its own colour.

## Performance
Blocks, clouds, scanlines and the vignette are pre-rendered to sprites once per resize and blitted;
device pixel ratio is capped at 2. Frame cost went from 2.4ms to 0.4ms on a full board in rain and high wind. The bloom pass spends
about 1.4ms of that back, landing at ~2.1ms — still an eighth of the 16ms budget. If it ever
struggles on an old device, set `bloomOK=false`.

## The logo
`index.html` looks for the PATtech mark in this order and uses the first that loads:
1. **`PATtechLogoWhite.svg` in this folder** — do this; the only option that works offline
2. `hnz.app/pattech/assets/logo/PATtechLogoWhite.svg` — the brand-guidelines copy
3. A drawn arrow-and-wordmark, so a broken image never shows

Two Webflow CDN URLs used to sit in the middle of that list. Neither could be opened to
verify, and Webflow rewrites those URLs on republish, so they were two guaranteed-slow
failures on every load for any machine without a local copy. They have been removed.

Drop the SVG next to `index.html` and the chain never leaves the machine. The list is
`BRAND_SRCS` near the top of the script.

## Phones, tablets and desktops
Portrait phones get the layout they always had. Turn a phone sideways, or open the game on
a laptop, and the controls move into a rail down the right-hand side and the board grows to
fill the height — about twice the size it used to be in a desktop window. There is a
keyboard legend in the rail on desktop.

## Updating a live site
1. Netlify → your site → **Deploys** → drag the `rego-power` folder onto the drop area. Same URL,
   new version, about twenty seconds.
2. **Open `sw.js` and bump `VERSION` first.** One character. Without it, returning players keep the
   old cached copy and you will swear the deploy failed.

The service worker is now update-safe: the page itself is fetched network-first, so a new deploy
lands on the next visit; everything else is served from cache and refreshed behind the scenes. When
a new version installs, the page reloads itself once, automatically. An open tab also re-checks
hourly.

If you dropped the folder without signing in, Netlify never gave you a site you can manage and
every drop makes a fresh URL. Claim it once (**Deploys → Claim site**, or sign in before dropping)
and the URL is yours for good.

Testing an update on your phone: pull down to refresh once. If you installed it to the home screen,
close it fully and reopen.

## Put it online
Drag this folder onto **app.netlify.com/drop**. GitHub Pages, Cloudflare Pages and Vercel work the
same way. HTTPS is required for install and offline, and all of them provide it.

## Phone app
Once hosted: **iPhone** — Safari → Share → *Add to Home Screen*. **Android** — Chrome → menu →
*Install app*. It launches fullscreen with its own icon and works with no signal.

For a real App Store / Play listing, run the URL through **pwabuilder.com**. That needs developer
accounts (US$99/yr Apple, US$25 once Google) and a couple of weeks of review.

## LinkedIn
LinkedIn will not run a game inside a post — the feed takes text, images, video, PDFs and links
only. So the post is the trailer and the link is the game: post the 19-second video, put the URL in
the body or first comment. `og-image.png` is what renders if you post the bare link.

## Tuning
Near the top of the `<script>` block:
- `MODES` — the easy/normal parameters
- `BATT_CAP` — battery size. Lower is harder.
- `COLS` must stay 24; they are the hours.
- `AWARDS` — badges and what earns them
- `certified(c)` — what disqualifies an hour from a REGO
- `SHAPES` — the piece bag for each source

## Before you publish
1. Drop `PATtechLogoWhite.svg` in this folder and check it reads light against the dark header.
2. Re-cut `icon-*.png` and `og-image.png` with the real mark.
3. Re-record the promo — it currently shows the drawn fallback.
