# RSI Buy-Back Page

**Date:** 2026-10-07
**Status:** Reference; `RSIBuybackParser` is built on it

What the RSI buy-back list (`/account/buy-back-pledges`) looks like, as read through the sync extension's `syncBuyback` action. Read this before changing the parser, or when a buy-back sync starts failing after an RSI site update.

## Markup

- Wrapper: `div.content-wrapper.pledges.buy-back > section.available-pledges > ul.pledges > li > article.pledge`, 10 entries per page (`?page=N`). The page offers 25/50/100 per page in its UI, but the extension only sends `page`.
- Name: `h1[title]`. An upgraded pledge gets a `span.upgraded` (" - upgraded") appended to the heading text, not to the attribute.
- Facts: a `dl` with `Reclaim Date` (e.g. "September 21, 2026", English because the page is `/en/`) and `Contained` ("Cutter Scout and 3 items"). Package contents are only summarised, never itemised.
- Id, package or ship: `a.holosmallbtn[href="/pledge/buyback/<id>"]`.
- Id, upgrade: `a.js-open-ship-upgrades[data-pledgeid][data-fromshipid][data-toshipid][data-toskuid]`. The ship ids are RSI's, not ours.
- Image: `figure img[src]`. Either absolute on `media.robertsspaceindustries.com` (most) or relative `/media/...` on the main host; a placeholder (`static/images/Temp/default-image.png`) when there is none. Both hosts must be in the CSP `img-src`.
- Kind is only in the title prefix: `Package`, `Standalone Ship`, `Upgrade`, `Paints`, `Add-Ons`, `Subscribers Exclusive`, and titles with no prefix at all.
- Availability is not readable: every entry renders both the "Buy Back" action and the "Not available" block, and CSS picks one.

## End of list

A page past the last one renders the full page with an empty list: no `article.pledge`, and no `empty-list`/`empy-list` marker (the pledges page uses those). So "the wrapper is there but holds no entries" means done, and "no wrapper" means the HTML is not the buy-back page, e.g. a login redirect served as 200.

Not seen: an account with no buy-backs at all. It is assumed to render the same empty wrapper as a page past the end. If it does not, the sync fails for that account without deleting anything.

## Size

One real account had 130 pages (1,293 stored pledges). At the modal's 60 requests per minute and roughly 1–1.5 s per RSI response, a full read takes 2–3 minutes.
