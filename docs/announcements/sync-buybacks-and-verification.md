# FleetYards Sync 1.4: buy-backs and one-click verification — announcement copy

Ready-to-post copy for what the sync extension's 1.3.0 and 1.4.0 releases unlock on FleetYards:

- the buy-back page with its own sync ([#5463](https://github.com/fleetyards/fleetyards/pull/5463)), plus links, availability,
  prices and insurance ([#5473](https://github.com/fleetyards/fleetyards/pull/5473), [#5475](https://github.com/fleetyards/fleetyards/pull/5475))
- RSI handle verification through the extension ([#5464](https://github.com/fleetyards/fleetyards/pull/5464))
- fleet (RSI org) verification through the extension ([#5474](https://github.com/fleetyards/fleetyards/pull/5474))
- the extension popup showing the RSI sign-in, and both sync modals naming the RSI account
- syncs that stop on an RSI page they do not recognise instead of submitting half a hangar ([#5469](https://github.com/fleetyards/fleetyards/pull/5469))

Things the copy deliberately does not claim:

- **Hold until fleet verification is live.** The copy announces it, and it was still an open PR (#5474) when
  this was written. Post only once it is merged and deployed.
- **Prices are the original purchase price, in USD before tax.** They are read once from the pledge page and
  never refreshed, and upgrade prices are computed from our ship prices. The copy says "what you paid", not
  "what it costs now".
- **Store review lag.** 1.4.0 was released on 2026-10-07. Chrome and Firefox review can take a few days, and
  until then the buy-back list syncs but prices and insurance do not. Post once the stores serve 1.4.0, or
  keep the "update the extension" line, which is true either way.

## In-app (notification + mail)

Published through **Admin → Announcements**. The rendering constraints from
[fleet-ops-beta.md](fleet-ops-beta.md#in-app-notification--mail) apply: bold, hyphen lists and absolute inline
links only, no headings, and `link` is a path that becomes the "Read more" button.

### Title

*79 characters of 255.*

```
Buy-backs in your hangar, and one-click RSI verification for you and your fleet
```

### Link

```
/hangar/buybacks
```

### Body

```
The FleetYards Sync extension just got three new jobs.

- **Buy-backs** — your RSI buy-back pledges now have their own page in your hangar. Sync them once and search by name, filter by kind, and see which ones RSI still lets you reclaim. Each pledge shows what you originally paid (in USD before tax, so it compares with every other price on FleetYards), its insurance, and a direct "Buy back on RSI" link. Upgrades show the price difference between the two ships.
- **RSI verification in one click** — no more pasting a token into your RSI bio by hand. Under [Settings → Profile](https://fleetyards.net/settings/profile), "Verify with extension" adds the token, runs the check and takes the token out again.
- **Fleet verification too** — fleet managers can verify their RSI organisation the same way under Fleet → Settings → Fleet ID & RSI. The extension writes the token into the org page, the check reads it, and the token comes out again. It needs an RSI account that can edit the org, and it will not publish another officer's unsaved changes.

**Also new**
The extension popup shows which RSI account your browser is signed in to, and the sync windows name it too, so you know whose hangar you are about to read. If RSI changes a page the sync does not recognise, it now stops without changing anything and tells us, instead of syncing half a hangar.

**Update the extension**
All of this needs FleetYards Sync 1.4.0. Your browser updates it on its own; if it has not yet, FleetYards will tell you and link to the store. It is available for [Chrome, Edge and Opera](https://chrome.google.com/webstore/detail/fleetyards-sync/glchfaleieoljcimjjkdkeifnejbcokg) and [Firefox](https://addons.mozilla.org/firefox/addon/fleetyards-sync/).

Found something the sync gets wrong? Tell us in the feedback channel on Discord. o7
```

## Discord (#announcements)

One message: *1799 characters of 2000.* Store links sit in `<>` so Discord does not unfurl two store cards.

```
## 🔄 FleetYards Sync 1.4: buy-backs in your hangar, and one-click RSI verification

**♻️ Buy-backs, finally in one place**
Your RSI buy-back pledges now have their own page in your hangar: <https://fleetyards.net/hangar/buybacks>
Hit **Sync RSI Buy-Backs** once and you can search by name, filter by kind, and see which pledges RSI still lets you reclaim. Each one shows what you originally paid, its insurance, and a direct **Buy back on RSI** link. Upgrades show the price difference between the two ships.
Prices are in USD before tax, whatever currency your RSI account uses, so they compare with every other price on FleetYards. The sync never touches your hangar.

**✅ RSI verification in one click, for you and your fleet**
No more pasting tokens into RSI by hand. Under **Settings → Profile**, **Verify with extension** adds the token to your bio, runs the check and takes it out again.
Fleet managers get the same for their org under **Fleet → Settings → Fleet ID & RSI**. It needs an RSI account that can edit the org, and it won't publish another officer's unsaved changes.

**👤 Know whose account you're syncing**
The extension popup shows which RSI account your browser is signed in to, and the sync windows name it too.

**🛡️ Safer syncs**
If RSI changes a page the sync doesn't recognise, it now stops without changing anything and tells us, instead of syncing half a hangar.

**Update the extension**
All of this needs **FleetYards Sync 1.4.0**. Your browser updates it on its own; if it hasn't yet, FleetYards will tell you.
Chrome / Edge / Opera: <https://chrome.google.com/webstore/detail/fleetyards-sync/glchfaleieoljcimjjkdkeifnejbcokg>
Firefox: <https://addons.mozilla.org/firefox/addon/fleetyards-sync/>

Spot something the sync gets wrong? Drop it in the feedback channel. o7
```

## X / Bluesky

*244 characters on X (limit 280, every link billed as 23), 259 on Bluesky (limit 300).* Re-measure after any edit.

```
FleetYards Sync 1.4 is out 🔄

♻️ Buy-backs get their own hangar page: what you paid, insurance, and a direct link to reclaim
✅ One-click RSI verification for handles and orgs
🛡️ Syncs stop safely when RSI changes a page

https://fleetyards.net/hangar/buybacks
```
