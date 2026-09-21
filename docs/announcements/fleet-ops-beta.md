# Fleet Ops public beta — announcement copy

Ready-to-post copy for the Events, Inventories, Contracts and Tours beta. Written against
[`premium-fleet-features.md`](../exec-plans/premium-fleet-features.md), whose D15 constrains what this
may say: **supporter features, never a purchase.** No price, no checkout, no "buy", no "licence".
Getting that wrong is a legal-form problem a later migration cannot undo, because it is what the
customer was told they were doing.

Two further constraints the copy carries, both from D3:

- **All four capabilities are named.** Fleet inventories are one of them, and an earlier draft omitted
  them entirely while the Contracts paragraph leaned on the transfer ledger twice. A fleet that read
  that draft would have been told its inventories stayed free and then lost them at enforcement.
- **Personal surfaces are called out as free.** A member's own hangar, their ships' cargo, and the
  standalone tour tool under `/tools/` are personal features and stay free permanently. Without that
  sentence "Inventories become premium" reads as a member's own hangar being paywalled.

The one "buy" in the copy is the Contracts job flavour — **buy** it from outside — which is a kind of
job a fleet posts, not a commerce claim. It is the only occurrence, and it is deliberate.

This is the **beta** announcement. It pre-announces the intent; it is not the dated transition notice
D13 requires, which is #4958 and starts the three-month grace window.

## In-app (notification + mail)

Published through **Admin → Announcements**, which writes every reader a notification and mails the
ones whose preferences ask for it. `title` and `body` are the announcement record itself; the Discord
and social blocks below are per-channel overrides of it, so this is the copy to write first.

Four things the two renderers between them constrain:

- **Bold, hyphen lists and inline links only.** The in-app renderer
  ([`Markdown/index.vue`](../../app/frontend/shared/components/Markdown/index.vue)) handles a narrow
  subset; the mailer runs Redcarpet over the same text. `*single asterisks*` and numbered lists render
  in the mail and stay literal in the app, so they are out.
- **No headings.** `#` becomes an `h3` in the app and an `h1` in the mail, which the MJML template has
  no style for. Bold lines carry the structure instead.
- **Links inside the body must be absolute.** Only the `link` field is absolutised for mail
  (`Announcement#absolute_link`); a `/settings/features` written into the body reaches a mail client
  as a relative href and resolves to nothing.
- **`link` itself is a path.** It becomes the "Read more" button in the mail and the reading pane's
  action in the app, so the body does not repeat it as a closing call to action.

The create form offers no icon field, so this carries the default `fa-duotone fa-bullhorn`.

Set on the record: **notify users** on, and the Discord and social toggles alongside it if the blocks
below go out in the same announcement.

### Title

*67 characters of 255.*

```
Fleet Ops is in public beta: Events, Inventories, Contracts & Tours
```

### Link

```
/settings/features
```

### Body

```
Four new tools for running a fleet just landed on FleetYards, and they are open to everyone as an opt-in public beta.

- **Events** — put your ops on a fleet calendar with a proper briefing, a meetup location and the right timezone. Members sign up, you build teams and fill ship slots with the ships people actually own, and it all syncs to your Discord server.
- **Inventories** — fleet stock with a deposit and withdrawal ledger: what is in the hold, who put it there, who took it out. Moving goods between two inventories is a transfer the other side has to accept.
- **Contracts** — a job board for your members: haul it between your own inventories, source it from outside, or craft it to a required quality. Progress is read straight from the transfer ledger rather than typed in by hand.
- **Tours** — track what one trip earned and what it cost, then let FleetYards work out who owes whom. Share weights handle the member who joined halfway through.

**Switching them on**
Every member can enable them for themselves under [Settings → Features](https://fleetyards.net/settings/features). Fleet admins can turn them on for a whole fleet under Fleet → Settings → Features. They are behind flags on purpose: this is a beta, and we would rather you opt in than trip over it.

**What happens after the beta**
All four are free for everyone while the beta runs. Once they leave beta, Events, fleet Inventories, Contracts and fleet Tours become **supporter features for fleets** — a supporter contribution unlocks them for the fleet you nominate.

Your **personal inventories** — your own hangar and your ships' cargo — and the **standalone tour tool** under Tools stay free for everyone, permanently. So does everything else FleetYards does today: hangars, fleets, the ship database, the tools. We will announce the details well before anything changes, and beta feedback will shape them.

FleetYards runs on donations, and that is what keeps all of it free: [every way to chip in is on one page](https://fleetyards.net/support). Any amount helps, and it stays anonymous unless you say otherwise.

Found a bug or got an idea? Drop it in the feedback channel on Discord — that is the whole point of a beta. o7
```

## Discord (#announcements)

Posted as two messages — Discord caps a message at 2000 characters.

### Message 1

*1543 characters of 2000.*

```
## 🚀 Fleet Ops is in public beta: Events, Inventories, Contracts & Tours

Four new tools for running a fleet just landed on FleetYards — and they're open to everyone as an opt-in public beta.

**📅 Events — plan the op, not the spreadsheet**
Put your ops on a fleet calendar with a proper briefing, a meetup location and the right timezone. One-off or recurring. Members sign up (directly or with approval), you build teams, and you fill ship slots with the ships people actually own. Events sync to your Discord server, and signups lock automatically before go-time so nobody joins the op five minutes after it started.

**📦 Inventories — what the fleet owns, and where it went**
Fleet inventories with a deposit/withdrawal ledger: what's in the hold, who put it there, who took it out. Stock is a running total rather than a number somebody remembers to update, and moving goods between two inventories is a transfer the other side has to accept. This is also what Contracts reads to track progress. Your own hangar and your ships' cargo are a separate, personal thing — those stay free for everyone, now and always.

**📋 Contracts — a job board your fleet's ledger keeps honest**
Post jobs for your members in three flavours: **haul** it between your own inventories, **buy** it from outside, or **craft** it to a required quality. Set a reward, a deadline, a crew limit and whether expenses get reimbursed. Progress isn't typed in by hand — it's read straight from the transfer ledger, so a contract only moves when the goods actually move.
```

### Message 2

*1981 characters of 2000.*

```
**💰 Tours — settle up after the run, without the argument**
Track everything one trip earned and everything it cost, then let FleetYards work out who owes whom. Share weights handle the member who joined halfway through, and the settlement list tells everyone exactly what to send. Run it as a fleet tour with members asking to join, or grab the standalone tool under **Tools** for an ad-hoc trip with friends — that one is free for everyone, now and always.

**How to switch them on**
Every member can enable them for themselves under **Settings → Features**. Fleet admins can turn them on for the whole fleet under **Fleet → Settings → Features**. They're behind flags on purpose: this is a beta, and we'd rather you opt in than trip over it.

**One thing to know up front**
All four are free for everyone during the public beta. Once they leave beta, Events, fleet Inventories, Contracts and fleet Tours become **supporter features for fleets** — a supporter contribution unlocks them for the fleet you nominate.

Two things are explicitly *not* part of that, and stay free for everyone, permanently: your **personal inventories** — your own hangar and your ships' cargo — and the **standalone tour tool** under Tools. So does everything else FleetYards does today: hangars, fleets, the ship database, the tools. We'll announce the details well before anything changes, and beta feedback will shape them.

**❤️ And if you want to keep the rest free**
FleetYards runs on donations. Every pledge on Patreon or Ko-fi is what pays for the servers and keeps hangars, fleets, the ship database and the tools free for everyone — it's why the supporter features are landing on a brand-new fleet-ops suite rather than on anything you already use today.
Every way to chip in is on one page: https://fleetyards.net/support
Any amount helps, and it stays anonymous unless you say otherwise.

Found a bug or got an idea? Drop it in the feedback channel — that's the whole point of a beta. o7
```

## X / Bluesky

Each block carries its measured length. X bills any link as 23 characters regardless of the real
length, which is why the two counts differ. Re-measure after any edit — all three variants sit within
a few characters of the cap, and the supporter framing is what pushed them there.

### Post 1 of 2

*259 characters on X (limit 280), 258 on Bluesky (limit 300).*

```
Fleet Ops is in public beta on FleetYards 🚀

📅 Events — calendar, signups, ship slots
📦 Inventories — fleet stock + full ledger
📋 Contracts — haul/buy/craft jobs
💰 Tours — income & costs, split fairly

Opt in under Settings → Features
https://fleetyards.net

```

### Post 2 of 2 — reply to post 1

*273 characters on X (limit 280), 280 on Bluesky (limit 300).*

```
Free in beta. After that, Events, Inventories, Contracts and Tours become supporter features.

Personal inventories (your hangar, your ships) stay free. So does the solo tour tool, and everything FleetYards does today.

Donations keep it that way ❤
https://fleetyards.net/support

```

### Alternative — a single post instead of the thread

*279 characters on X (limit 280), 278 on Bluesky (limit 300).*

```
Fleet Ops is in public beta 🚀

📅 Events — signups & ship slots
📦 Inventories — fleet stock + ledger
📋 Contracts — haul/buy/craft
💰 Tours — income & costs, split fairly

Free in beta, then supporter features.
Your hangar, ship cargo & solo tours stay free.
https://fleetyards.net
```
