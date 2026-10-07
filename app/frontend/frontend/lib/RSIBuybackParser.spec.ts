import { describe, it, expect, beforeEach } from "vitest";
import { extractBuybackPage } from "./RSIBuybackParser";
import { RsiPageStatus } from "./RsiPageStatus";
import { RsiPageCheckEnum } from "@/services/fyApi";

// Trimmed from the live buy-back page; ids are made up.
const buybackPage = (articles: string) => `
<div class="content-wrapper content-block1 pledges buy-back">
  <section class="available-pledges">
    <ul class="pledges">${articles}</ul>
  </section>
</div>`;

const packageArticle = `
<li>
  <article class="pledge">
    <div class="information no-countdown">
      <figure>
        <img src="/media/s1pzv94jrc3jhr/heap_infobox/cutter.jpg" alt="Standalone Ship - Cutter plus Groundswell Paint">
      </figure>
      <div>
        <div class="pledge-title-row no-countdown">
          <h1 title="Standalone Ship - Cutter plus Groundswell Paint">Standalone Ship - Cutter plus Groundswell Paint<span class="upgraded"> - upgraded</span></h1>
        </div>
        <dl>
          <dt>Reclaim Date</dt>
          <dd>November 26, 2023</dd>
          <dt>Contained</dt>
          <dd>Cutter Scout and 3 items</dd>
        </dl>
        <div class="buyback-action">
          <a class="holosmallbtn" href="/pledge/buyback/1000001?page=6"><span class="js-label">Buy Back</span></a>
        </div>
        <div class="unavailable"><div class="caption">Not available</div></div>
      </div>
    </div>
  </article>
</li>`;

const upgradeArticle = `
<li>
  <article class="pledge">
    <div class="information no-countdown">
      <figure>
        <img src="https://cdn.robertsspaceindustries.com/static/images/Temp/default-image.png" alt="Upgrade - Clipper to S-65 Stingray Standard Edition">
      </figure>
      <div>
        <div class="pledge-title-row no-countdown">
          <h1 title="Upgrade - Clipper to S-65 Stingray Standard Edition">Upgrade - Clipper to S-65 Stingray Standard Edition</h1>
        </div>
        <dl>
          <dt>Reclaim Date</dt>
          <dd>September 21, 2026</dd>
          <dt>Contained</dt>
          <dd>Upgrade - Clipper to S-65 Stingray Standard Edition</dd>
        </dl>
        <a href="" class="holosmallbtn js-open-ship-upgrades" data-apiurl="/pledge-store/api/upgrade/v2" data-pledgeid="1000002" data-fromshipid="308" data-toshipid="322" data-toskuid="19461"><span class="js-label">Buy Back</span></a>
      </div>
    </div>
  </article>
</li>`;

const titledArticle = (title: string, id: string) => `
<li>
  <article class="pledge">
    <div class="information no-countdown">
      <figure><img src="https://media.robertsspaceindustries.com/abc/heap_infobox.jpg" alt=""></figure>
      <div>
        <h1 title="${title}">${title}</h1>
        <dl><dt>Reclaim Date</dt><dd>January 2, 2025</dd></dl>
        <div class="buyback-action"><a class="holosmallbtn" href="/pledge/buyback/${id}">Buy Back</a></div>
      </div>
    </div>
  </article>
</li>`;

// A page the parser reads, narrowed so a test can look at its entries.
const readPage = (html: string) => {
  const result = extractBuybackPage(html);
  if (result.status !== RsiPageStatus.PAGE) {
    throw new Error(`expected a page, got ${JSON.stringify(result)}`);
  }

  return result;
};

describe("extractBuybackPage", () => {
  beforeEach(() => {
    window.RSI_ENDPOINT = "https://robertsspaceindustries.com";
  });

  it("reads a package entry", () => {
    const page = readPage(buybackPage(packageArticle));

    expect(page.pledgeIds).toEqual(["1000001"]);
    expect(page.pledges[0]).toEqual({
      id: "1000001",
      name: "Standalone Ship - Cutter plus Groundswell Paint",
      kind: "ship",
      upgraded: true,
      available: true,
      reclaimedOn: "2023-11-26",
      contained: "Cutter Scout and 3 items",
      image:
        "https://robertsspaceindustries.com/media/s1pzv94jrc3jhr/heap_infobox/cutter.jpg",
      upgradeFromShipId: undefined,
      upgradeToShipId: undefined,
      upgradeToSkuId: undefined,
    });
  });

  it("reads an upgrade entry with its ship ids", () => {
    const page = readPage(buybackPage(upgradeArticle));

    expect(page.pledges[0]).toMatchObject({
      id: "1000002",
      kind: "upgrade",
      upgraded: false,
      reclaimedOn: "2026-09-21",
      upgradeFromShipId: 308,
      upgradeToShipId: 322,
      upgradeToSkuId: 19461,
    });
    expect(page.pledges[0].image).toBeUndefined();
  });

  it("derives the kind from the title prefix", () => {
    const page = readPage(
      buybackPage(
        [
          titledArticle("Package - Aurora MR Starter", "1"),
          titledArticle("Paints - Sabre - Beyond Paint", "2"),
          titledArticle("Add-Ons - Giocoso Helmet Triple Pack", "3"),
          titledArticle("Subscribers Exclusive - Locker", "4"),
          titledArticle("Origin 325a Fighter", "5"),
        ].join(""),
      ),
    );

    expect(page.pledges.map((pledge) => pledge.kind)).toEqual([
      "package",
      "paint",
      "addon",
      "other",
      "other",
    ]);
  });

  it("skips an entry without a pledge id", () => {
    const page = readPage(
      buybackPage(
        `<li><article class="pledge"><h1 title="Gear - Helmet">Gear - Helmet</h1></article></li>${packageArticle}`,
      ),
    );

    expect(page.pledgeIds).toEqual(["1000001"]);
  });

  it("reads RSI's empty list as the end", () => {
    expect(extractBuybackPage(buybackPage(""))).toEqual({
      status: RsiPageStatus.END,
    });
  });

  it("does not read a page that is not the buy-back page", () => {
    expect(
      extractBuybackPage(
        "<html><body><form id='sign-in'></form></body></html>",
      ),
    ).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_LIST,
    });
  });

  it("does not read renamed entries as the end of the list", () => {
    expect(
      extractBuybackPage(
        buybackPage(
          `<li><div class="pledge-card"><a href="/pledge/buyback/1000001">Buy Back</a></div></li>`,
        ),
      ),
    ).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_ENTRIES,
    });
  });

  it("does not read rows whose markup and links both changed as the end", () => {
    expect(
      extractBuybackPage(
        buybackPage(`<li><div class="card">Cutter</div></li>`),
      ),
    ).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_ENTRIES,
    });
  });

  it("reads a link to buy-backs outside the list as nothing", () => {
    expect(
      extractBuybackPage(
        `<a href="/pledge/buyback/1">Banner</a>${buybackPage("")}`,
      ),
    ).toEqual({ status: RsiPageStatus.END });
  });

  it("does not read entries none of which it could read", () => {
    const page = extractBuybackPage(
      buybackPage(`<li><article class="pledge"><h1>Gear</h1></article></li>`),
    );

    expect(page).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.UNPARSED_ENTRIES,
    });
  });

  it("leaves the upgraded marker out of a name read from the text", () => {
    const page = readPage(
      buybackPage(
        `<li><article class="pledge"><h1>Standalone Ship - Cutlass Black<span class="upgraded"> - upgraded</span></h1><a href="/pledge/buyback/7">Buy Back</a></article></li>`,
      ),
    );

    expect(page.pledges[0]).toMatchObject({
      name: "Standalone Ship - Cutlass Black",
      upgraded: true,
    });
  });

  it("reads an entry RSI marks as not available", () => {
    const page = extractBuybackPage(
      buybackPage(
        `<li><article class="pledge" data-disabled="1"><h1 title="Package - Limited Edition">Package - Limited Edition</h1><a class="holosmallbtn" href="/pledge/buyback/8">Buy Back</a></article></li>`,
      ),
    );

    expect(page?.pledges[0]?.available).toBe(false);
  });
});
