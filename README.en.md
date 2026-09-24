# Haerin Skin for DeepSeek Harness

A two-state (light + dark) skin for the **DeepSeek Harness (DSH)** web client, switchable
from inside the client. The palette is sampled from two photos of Haerin (해린):
cool snow-blue with a denim floral hoodie, and ink black with a crimson flower.
Backgrounds are original SVG + pixel-art collage; panels are frosted glass.

English | [中文](README.md)

![day](screenshots/day.jpg)

![night](screenshots/night.jpg)

> Just want to use it? See **Install**.
> Want to make it yours (recolour / swap art / rename)? See
> **[docs/CUSTOMIZE.md](docs/CUSTOMIZE.md)** — it is 3 files plus one art folder, no build step.

## Install

Windows + DSH Desktop. The skin hooks the front-end `dist`; **no plugin is modified**.

```powershell
git clone https://github.com/<you>/dsh-skin-haerin.git
cd dsh-skin-haerin
install.cmd
```

Then reload the client UI once: tray icon → **Reload Interface** (or restart DSH Desktop).
A cat-eared pill shows up in the bottom-right corner.

```powershell
install.cmd status      # where is it installed
install.cmd uninstall   # removes the block + skin folder, index.html restored byte-for-byte
```

The installer finds every `@deepseek-ai/dsh-web-frontend/dist` on the machine (the one in
your DSH profile and the one inside the app), rebuilds `dist\skin\haerin\` from scratch,
and injects a marked `<link>`/`<script>` block before `</head>` in `index.html`
(idempotent; the first run keeps an `index.html.haerin-orig` backup).

## Switching

| Action | Result |
| --- | --- |
| Click the pill | day ⇄ night (instant, remembered) |
| Right-click the pill | follow the client's own appearance setting again |
| Shift + click | hide the skin (leaves a small cat icon, click to bring it back) |
| Drag the pill | park it in any corner, position is remembered |
| `Alt + H` / `Alt + Shift + H` | toggle day/night ／ show/hide |

State lives in `localStorage` (`haerin.skin`, `haerin.mode`, `haerin.pos`). You can also
drive it from the console:

```js
haerinSkin.state      // { skin, mode, night, pos }
haerinSkin.day(); haerinSkin.night(); haerinSkin.auto();
haerinSkin.hide(); haerinSkin.show(); haerinSkin.toggle();
```

## What is inside

- **5 background layers** painted on `<html>` (fixed, does not scroll with the thread):
  wash → optional photo plate → 4px dither → pixel stickers → film grain.
- **Pixel art** in the spirit of the NewJeans × Murakami × Powerpuff Girls 8-bit collages:
  every shape is authored on an integer grid, scaled by whole numbers and rendered with
  `shape-rendering="crispEdges"`, so edges are hard blocks instead of anti-aliased curves.
  The pixel animal near the left edge is deliberately placed *under* the sidebar: inside it
  is blurred into a soft glow, outside it stays crisp — that is how you can see the glass.
- **Frosted glass** via `backdrop-filter` at four thicknesses (24 / 30 / 20 / 16 px), with an
  inner highlight and a 1px bright edge on each frosted surface. It targets the client's
  hashed CSS-module class names by **stable suffix** (`[class*="_sidebarCol"]`), because the
  hash prefix changes on every build.
- **Palette from the photos**: day = snow blue-grey / denim / blush `#C97F8E`; night =
  warm ink / bone `#F3EBE7` / crimson `#D2555F`.

## Customizing

No build step: `haerin-skin/` is the shipped artifact. Edit, re-run `install.cmd`, reload.

| What | Where |
| --- | --- |
| Whole colour cast | the `--dsw-static-*` ramps at the top of each mode block in `haerin.css` |
| Accent / link / brand button | the "语义层微调" section of the same blocks |
| Wash, pixel stickers, dither | `haerin-skin/art/*.svg` (and the `--hj-wall` URLs in the CSS) |
| Your own photos | `tools/prepare-photos.ps1 -Day a.jpg -Night b.jpg`, then `install.cmd` |
| The pill itself | `.hj-*` rules in `haerin.css`; labels/icons in the `LABEL` / `SVG` maps in `haerin.js` |
| Rename the skin | search for `haerin` (folder, `data-haerin-*`, `.hj-`, `localStorage` keys) |

Full walkthrough: **[docs/CUSTOMIZE.md](docs/CUSTOMIZE.md)** (Chinese; the code comments are
Chinese too).

## Layout

```
install.cmd / install.ps1    installer: install / uninstall / status
haerin-skin/                 the skin itself (no build step)
  haerin.css                 palettes + wallpaper + glass + pill
  haerin-boot.js             synchronous head bootstrap (no first-paint flash)
  haerin.js                  the pill: switch, follow, drag, hotkeys, persistence
  preview.html               offline preview that reuses the client's class names
  art/                       wash / pixel stickers / dither / grain (+ your photos)
  _upstream/                 upstream token sheets, preview only
docs/CUSTOMIZE.md            customizing & renaming guide
screenshots/                 the two states
tools/                       photo baking, upstream re-extraction, selector notes
```

## Preview page

Open `haerin-skin/preview.html` directly (no client needed) and click the pill:

```
preview.html?skinmode=night          force night
preview.html?skinmode=auto&appdark=1 follow client, client is dark
preview.html?skinmode=day&nohint=1   clean screenshot mode
```

## How it works

DSH colours everything through layered `--dsw-*` tokens: `static-*` primitives →
`alias-*` / `specific-*` semantics. The skin (1) re-tints the three primitive ramps,
(2) copies both of upstream's mode-specific `alias` + `specific` maps into its own scope so
they point at the re-tinted ramps, and (3) makes the surface tokens translucent while the
wallpaper is painted on `html` and the glass comes from `backdrop-filter`.

Step 2 is the load-bearing one: upstream decides *which end of a ramp* a semantic token takes
based on `body` vs `body[data-ds-dark-theme]`. Re-tint only the ramps and, whenever the skin
mode disagrees with the client mode, text lands on the wrong end (dark text on a dark
surface). With the maps copied over, both skin states are self-contained and **not a single
component style has to change**.

## Known limits

- Not a plugin — a client update overwrites `dist`; re-run `install.cmd`.
- One reload is required for the new `index.html` to be picked up; every switch after that
  is instant.
- Frosting needs `backdrop-filter`; surfaces stay translucent without it.
- The pixel layer is a fixed `1600×1000` (so the pixels stay crisp); on wider windows the
  edges only show the wash.
- The two photos are **not** in this repository.

## License & disclaimer

- Code and original vector art: **MIT** (see [LICENSE](LICENSE)).
- `haerin-skin/_upstream/*.css`: token sheets extracted from `@deepseek-ai/dsh-client-ui-theme`
  (MIT, © DeepSeek), used only so the preview page matches the client's base colours.
- Photos are user-supplied and git-ignored; the screenshots here are the photo-less default.
- Fan-made third-party skin, **not affiliated with NewJeans / ADOR / HYBE or DeepSeek**,
  and it ships no official assets.
