# Vehicle pages, captain's log, ship pictures and dedication plaques — announcement copy

Ready-to-post copy for the vehicle overview release:

- the vehicle overview page and the captain's log ([#5617](https://github.com/fleetyards/fleetyards/pull/5617)),
  with the tidied vehicle menu ([#5635](https://github.com/fleetyards/fleetyards/pull/5635))
- vehicle pages addressed by username, serial and name ([#5640](https://github.com/fleetyards/fleetyards/pull/5640))
- uploading a ship picture, or picking one from the model's gallery ([#5617](https://github.com/fleetyards/fleetyards/pull/5617),
  [#5632](https://github.com/fleetyards/fleetyards/pull/5632))
- dedication plaques ([#5639](https://github.com/fleetyards/fleetyards/pull/5639), with fixes in 9.3.1 and 9.3.2)

Things the copy deliberately does not claim:

- **No opt-in step.** `vehicle_overview` is enabled for everyone, so the copy says nothing about Settings → Features.
- **Only brass is free.** The other nine plaque styles, including the manufacturer's own style, are a thank-you to
  supporters. The copy calls them a perk for supporters and never something to buy, the same rule as the Fleet Ops
  copy. When someone stops supporting, the plaque stays and is drawn in brass again.
- **Log entries are private by default.** An entry stays private until the owner makes it public, and public entries
  only show for ships that are public in the hangar. The copy says this, so nobody worries that their notes are on show.
- **The ship's location stays private.** The overview shows it, but only to the owner.
- **Grouped fleet rows keep the stock render.** A custom picture shows in the owner's hangar, on the vehicle page, in
  the public hangar, and in fleet lists that show individual ships. The copy says "fleets you share it with" and
  doesn't claim more than that.

## In-app (notification + mail)

Published through **Admin → Announcements**. The rendering rules from
[fleet-ops-beta.md](fleet-ops-beta.md#in-app-notification--mail) apply: only bold, hyphen lists and absolute inline
links, no headings, and `link` is a path that becomes the "Read more" button.

### Title

*65 characters of 255.*

```
Every ship gets its own page: a captain's log, pictures & plaques
```

### Link

```
/hangar
```

### Body

```
Every ship in your hangar now has a page of its own. Open one from your hangar by clicking its name.

- **Overview** — everything about the ship in one place: name and serial, how you got it, paint, modules, upgrades, groups, the fleets it serves with, how full its hold is, and where you left it (only you can see that). You can change the paint and edit the ship right from the page.
- **Captain's Log** — keep a journal for each ship. Every entry has a title, a date you can backdate, and Markdown text. Entries are private until you make one public. Public entries appear with the ship in your public hangar, and you can make new entries public by default.
- **Your own picture** — upload a screenshot of your ship, or pick one from the ship's gallery, and it replaces the stock render in your hangar, your public hangar and the fleets you share the ship with. Use **Change picture** in the ship's menu.
- **Dedication plaque** — give your ship a plaque modelled on the starship plaques of old: the maker's logo, the ship's name and registry, the shipyard it was commissioned from, the date and port it launched from, its captain and your dedication. Anyone can see it in your public hangar while the ship is public, you can save it as an image, and a shared plaque link shows the plaque itself in its preview.

**Plaque styles**
Brass is free for everyone. Nine more styles, from Frosted glass to Pyro neon to the manufacturer's own look, are a thank-you to the supporters who keep FleetYards running: [every way to chip in is on one page](https://fleetyards.net/support).

**New addresses**
Ship pages now live at your username plus the ship's serial and name, for example https://fleetyards.net/hangar/yourname/l8-4261-ha-uscs-tanngnjostr/. Old links still work. A new or changed serial now uses the game's XX-XXXX-XX format.

Found something off? Tell us in the feedback channel on Discord. o7
```

## Discord (#announcements)

One message: *1668 characters of 2000.* The support link sits in `<>` so Discord doesn't unfurl it.

```
## 🛸 Every ship gets its own page

Click a ship's name in your hangar and it opens on a page of its own.

**📋 Overview**
Everything about the ship in one place: name and serial, how you got it, paint, modules, upgrades, groups, the fleets it serves with, how full its hold is, and where you left it (only you see that). You can swap the paint and edit the ship right there.

**📖 Captain's Log**
Keep a journal for every ship. Each entry has a title, a date you can backdate, and Markdown text. Entries are private until you make one public. Public ones show up with the ship in your public hangar.

**🖼️ Your own picture**
Upload a screenshot of *your* ship, or pick one from its gallery, and it replaces the stock render in your hangar, your public hangar and the fleets you share it with. Use **Change picture** in the ship's menu.

**🏅 Dedication plaques**
Give your ship a plaque inspired by the starship plaques of old: the maker's logo, the ship's name and registry, the shipyard that built it, when and where it launched, its captain and your dedication.
It shows in your public hangar while the ship is public, you can save it as an image, and a shared plaque link previews as the plaque itself.
Brass is free for everyone. Nine more styles, from Frosted glass to Pyro neon to the manufacturer's own look, are a thank-you to our supporters: <https://fleetyards.net/support>

**🔗 Nicer addresses**
Ship pages now use your username, the serial and the ship's name, like `/hangar/yourname/l8-4261-ha-uscs-tanngnjostr/`. Old links still work. A new or changed serial now uses the game's `XX-XXXX-XX` format.

Spot something off? Drop it in the feedback channel. o7
```

## X / Bluesky

*244 characters on X (limit 280, every link counts as 23), 250 on Bluesky (limit 300).* Re-measure after any edit.

```
Every ship in your FleetYards hangar now gets its own page 🛸

📋 An overview of the ship
📖 A captain's log, private until you share it
🖼️ Your own picture, uploaded or from the gallery
🏅 A dedication plaque for your ship

https://fleetyards.net/hangar
```
