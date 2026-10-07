# RSI Buy-Back Page

**Date:** 2026-10-07
**Status:** Reference; `RSIBuybackParser` and `RSIBuybackDetailParser` are built on it

What the RSI buy-back list (`/account/buy-back-pledges`) looks like, as read through the sync extension's `syncBuyback` action. Read this before changing the parser, or when a buy-back sync starts failing after an RSI site update.

## Markup

- Wrapper: `div.content-wrapper.pledges.buy-back > section.available-pledges > ul.pledges > li > article.pledge`, 10 entries per page (`?page=N`). The page offers 25/50/100 per page in its UI, but the extension only sends `page`.
- Name: `h1[title]`. An upgraded pledge gets a `span.upgraded` (" - upgraded") appended to the heading text, not to the attribute.
- Facts: a `dl` with `Reclaim Date` (e.g. "September 21, 2026", English because the page is `/en/`) and `Contained` ("Cutter Scout and 3 items"). Package contents are only summarised, never itemised.
- Id, package or ship: `a.holosmallbtn[href="/pledge/buyback/<id>"]`.
- Id, upgrade: `a.js-open-ship-upgrades[data-pledgeid][data-fromshipid][data-toshipid][data-toskuid]`. The ship ids are RSI's, not ours.
- Image: `figure img[src]`. Either absolute on `media.robertsspaceindustries.com` (most) or relative `/media/...` on the main host; a placeholder (`static/images/Temp/default-image.png`) when there is none. Both hosts must be in the CSP `img-src`.
- Kind is only in the title prefix: `Package`, `Standalone Ship`, `Upgrade`, `Paints`, `Add-Ons`, `Subscribers Exclusive`, and titles with no prefix at all.
- Availability: every entry renders both the "Buy Back" action and the "Not available" block. RSI's stylesheet shows the block only for `article.pledge[data-disabled]`. None of 70 sampled entries on a 130-page account carried it, so the attribute's value has not been seen. RSI's tooltip gives two reasons: the pledge holds physical items that are gone, or it was a special discounted or limited offer.
- No price and no insurance on the list.

## End of list

A page past the last one renders the full page with an empty list: no `article.pledge`, and no `empty-list`/`empy-list` marker (the pledges page uses those). So "the wrapper is there but holds no entries" means done, and "no wrapper" means the HTML is not the buy-back page, e.g. a login redirect served as 200.

An account with no buy-backs at all renders the same: the wrapper and `section.available-pledges` are there, with no entries. It also says "No pledges available" (seen 2026-10-07).

## Detail page

`/pledge/buyback/<id>` (packages, ships, paints, add-ons):

- Price: `strong.final-price[data-value][data-currency]`, e.g. `data-value="15708" data-currency="EUR"`. The value is in cents, in the currency the account shows prices in, tax included. The page carries no USD figure.
- Contents: `.package-listing.ship li` per ship, and `.package-listing.item li` for the rest, insurance included: `6 Month Insurance`, `60 Month Insurance`, `120 Month Insurance`, `Lifetime Insurance`, next to hangars, paints and name reservations.

## Upgrade price

An upgrade's buy-back opens a modal on the list page that asks `POST /pledge-store/api/upgrade/v2/graphql`:

- `price(from: <data-fromshipid>, to: <data-toskuid>) { amount nativeAmount }`. `amount` is what the modal charges (account currency, tax included, cents); `nativeAmount` is USD before tax. Example: Clipper to S-65 Stingray, `2618` / `2500`.
- `app { pricing { currencyCode } }` names the currency of `amount`.
- No CSRF token is needed. A JSON array of operations is one batch, capped at **5 operations**: a sixth fails the whole batch with `GRAPHQL_SECURITY_VIOLATION`. Aliasing `price` inside one query is capped at 5 duplicated fields as well.
- A pair RSI does not know fails only its own operation (`Ship not found`, `data: null`).

## Size

One real account had 130 pages (1,293 stored pledges). At the modal's 60 requests per minute and roughly 1–1.5 s per RSI response, a full read takes 2–3 minutes. Reading one detail page per non-upgrade pledge on top of that is about 1,000 requests, roughly 17 minutes at the same rate. So details are read once per pledge and kept; upgrades share from/to pairs, and four pairs fit in one request.
