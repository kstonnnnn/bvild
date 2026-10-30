# itch.io page kit — Lost Luggage

Everything below is ready to paste into the itch.io project editor.

## Basics

- **Title:** Lost Luggage
- **Project URL:** `lost-luggage`
- **Short description / tagline:** Bid blind on unclaimed airport luggage, unpack it, and flip the finds before rent is due.
- **Classification:** Games
- **Kind of project:** HTML (playable in the browser). Also upload the Android `.apk` as a downloadable file.
- **Release status:** In development (switch to Released when you are happy with it)
- **Pricing:** No payments, or "$0 or donate"
- **Genre:** Simulation
- **Tags (up to 10):** tycoon, management, economy, trading, auction, casual, singleplayer, mobile, touch-friendly, short
- **AI generation disclosure:** set this according to how you built the game (itch asks about AI-generated content in the project settings).

## Embed options (Uploads section)

- Upload `lost-luggage-web-N.zip` from the latest GitHub release and tick **This file will be played in the browser**.
- **Viewport:** 420 × 860
- Tick **Mobile friendly**, orientation **Portrait**
- Tick **Fullscreen button**
- Upload `lost-luggage-N.apk` as a second file, platform **Android**.

## Images

| Where | File |
|---|---|
| Cover image | `itch/cover-1260x1000.png` (same 630×500 ratio, sharper on big screens) |
| Header / banner (Edit theme → Banner) | `itch/banner-1920x600.png` |
| Screenshots | 4–5 portrait phone screenshots, see list below |

**Screenshots to take** (phone, light or dark theme, keep the same theme for all):

1. The auction list on day 3–4 with a few colorful tags on the lots
2. A live bidding moment: the timer bar red, "Going once… going twice…"
3. Unpacking with a rare or legendary item glowing
4. Storage with the filter chips and a few listed items
5. The Collection screen with some rare finds unlocked

## Theme (Edit theme)

- **Layout:** Banner on top, content left, sidebar right
- **Background:** `#15171B`
- **Inner background:** `#1C1F25`
- **Text:** `#E7E2D6`
- **Links:** `#FFC72C`
- **Buttons:** `#FFC72C`, button text dark
- **Embed background:** `#15171B`
- **Header font:** a heavy sans (Inter, Lato Black or Roboto Black work well)
- **Body font:** Inter or Lato

## Description (paste into the main description box)

---

**Every day, the airport auctions off the bags nobody came back for. You buy them blind.**

Lost Luggage is a short-session trading sim about bidding on unclaimed suitcases, unpacking them and flipping whatever is inside. Some bags hold socks and expired snacks. Some hold a Swiss watch. Some hold a *fake* Swiss watch.

### How it plays

- **Read the clues.** Departure city, weight, and tags like *Business class*, *Diplomatic tag* or *Taped shut* hint at what is inside. Pay for an X-ray to see categories, but not authenticity.
- **Bid live.** Four rival flippers, each with a personality. Every bid resets the timer. Set an auto-bid and let it ride.
- **Unpack, one item at a time.** Rare and legendary finds light up. Undocumented caviar gets seized by customs.
- **Check before you sell.** Authenticate watches and bags, repair broken electronics, or pawn everything for half price right now.
- **Sell overnight.** Buyers browse your listings while you sleep, send offers, and sometimes come back angry with a fake you sold as real.
- **Grow the business.** Shelving, an X-ray scanner, a workshop, an online store, a second warehouse and a cargo van for whole shipping containers.

### Features

- Real-time auctions against rivals with different strategies
- 60+ items from odd socks to an imperial-style jeweled egg, with fakes and broken gear
- Story events: owners looking for their grandma's jewelry box, collectors with cash, a phone maker who wants their prototype back
- A collection book for rare and legendary finds
- Three difficulty levels, three auction speeds, light and dark themes, six accent colors
- Autosave, no ads, no account

**Goal:** reach a net worth of $100,000. Then keep going.

Plays in the browser on desktop and mobile. Android APK available below.

---

## First devlog post

**Title:** Lost Luggage is out

**Body:**

Lost Luggage is now playable in the browser and on Android.

It's a small trading sim: bid on unclaimed airport luggage, unpack it, check what's real, and flip it. This first release has 60+ items, four rival bidders, overnight sales, story events, upgrades, and a collection book.

I'd love to hear what you found in your best bag, and where the balance feels off. Comments are open.

## Automatic uploads from GitHub (optional)

Once the itch project exists, every push to `main` can upload the new build automatically:

1. Get an API key: https://itch.io/user/settings/api-keys → Generate new API key
2. GitHub repo → Settings → Secrets and variables → Actions:
   - **Secret** `BUTLER_API_KEY` = the key
   - **Variable** `ITCH_GAME` = `yourname/lost-luggage`
   - **Variable** `ITCH_URL` = `https://yourname.itch.io/lost-luggage` (adds a link to the page inside the game's Settings)
3. The build pushes two channels: `android` (the APK) and `web` (the browser build). In the itch uploads list, mark the `web` channel as **played in the browser**.
