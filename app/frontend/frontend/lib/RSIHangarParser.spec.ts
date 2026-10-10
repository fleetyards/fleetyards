import { describe, it, expect } from "vitest";
import { RSIHangarParser } from "./RSIHangarParser";
import { RsiPageStatus } from "./RsiPageStatus";
import { RsiPageCheckEnum } from "@/services/fyApi";

// The structure the parser reads off the pledges page; ids are made up.
const pledge = (id: string, items: string, name = "") => `
<li>
  <input type="hidden" class="js-pledge-id" value="${id}">
  <input type="hidden" class="js-pledge-name" value="${name}">
  <div class="items">${items}</div>
</li>`;

const item = (kind: string, title: string) => `
<div class="item">
  <div class="image" style="background-image:url('https://media.test/a.jpg')"></div>
  <div class="title">${title}</div>
  <div class="kind">${kind}</div>
</div>`;

const pledgesPage = (entries: string) =>
  `<title>My Hangar - Roberts Space Industries</title><div class="page-wrapper"><ul class="list-items">${entries}</ul></div>`;

const extract = (html: string) => new RSIHangarParser().extractPage(html);

describe("RSIHangarParser.extractPage", () => {
  it("reads the pledges and their items", () => {
    const page = extract(pledgesPage(pledge("101", item("Ship", "Cutter"))));

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledgeIds: ["101"],
      pledges: [{ id: "101", name: "Cutter", type: "ship" }],
    });
  });

  it("reads RSI's empty list as the end", () => {
    expect(
      extract(
        '<title>My Hangar - Roberts Space Industries</title><div class="list-items"><div class="empty-list"></div></div>',
      ),
    ).toEqual({ status: RsiPageStatus.END });
  });

  it("does not read the empty marker on another page as the end", () => {
    expect(
      extract('<title>Sign In</title><div class="empty-list"></div>'),
    ).toMatchObject({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_LIST,
      details: ['page title "Sign In"'],
    });
  });

  it("names a page title it knows without RSI's site suffix", () => {
    expect(
      extract(
        "<title>Maintenance | Roberts Space Industries</title><div></div>",
      ),
    ).toMatchObject({ details: ['page title "Maintenance"'] });
  });

  it("names a known page title followed by more of RSI's site name", () => {
    expect(
      extract(
        "<title>Sign In | Roberts Space Industries | Follow the development of Star Citizen</title><div></div>",
      ),
    ).toMatchObject({ details: ['page title "Sign In"'] });
  });

  it("reads a known kind with whitespace around it", () => {
    expect(
      extract(pledgesPage(pledge("101", item("\n  Ship\n  ", "Cutter")))),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledges: [{ id: "101", name: "Cutter", type: "ship" }],
    });
  });

  it("does not report a page title it does not know", () => {
    const page = extract(
      "<title>citizen123 - Roberts Space Industries</title><div></div>",
    );

    expect(page).toMatchObject({ details: ["an unlisted page title"] });
    expect(JSON.stringify(page)).not.toContain("citizen123");
  });

  it("does not read a page where one pledge lost its id", () => {
    expect(
      extract(
        pledgesPage(
          `${pledge("101", item("Ship", "Cutter"))}<li><div class="item"><div class="kind">Ship</div></div></li>`,
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      details: ["pledges 2, ids 1, a name missing"],
    });
  });

  it("does not read a page without the pledge list as the end", () => {
    expect(
      extract("<html><body><form id='sign-in'></form></body></html>"),
    ).toMatchObject({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_LIST,
      details: ['page title ""'],
    });
  });

  it("does not read pledges without ids", () => {
    expect(
      extract(pledgesPage(`<li><div class="item"></div></li>`)),
    ).toMatchObject({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      details: ["pledges 1, ids 0, a name missing"],
    });
  });

  it("does not read a page with a kind it does not know", () => {
    expect(
      extract(
        pledgesPage(
          pledge("101", `${item("Ship", "Cutter")}${item("Vehicle", "Ursa")}`),
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.UNKNOWN_KINDS,
        details: ['unknown kind "Vehicle"'],
      },
    });
  });

  it("still reads a pledge whose items are all of kinds it skips", () => {
    const page = extract(pledgesPage(pledge("101", item("Credits", "UEC"))));

    expect(page).toEqual({
      status: RsiPageStatus.PAGE,
      pledges: [],
      pledgeIds: ["101"],
    });
  });

  it("reads paints and hangar flair apart", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `${item("Skin", "Cutter Paint")}${item("Hangar decoration", "Poster")}`,
        ),
      ),
    );

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledges: [
        { id: "101", name: "Cutter Paint", type: "skin" },
        { id: "101", name: "Poster", type: "flair" },
      ],
    });
  });

  it("reads a page with items RSI gives no kind", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `${item("Ship", "CSV-SM")}<div class="item"><div class="image"></div><div class="text"><div class="title">Upgrade - Clipper To S-65 Stingray</div></div></div>`,
        ) +
          pledge(
            "102",
            `<div class="with-images">${item("Ship", "Cutter")}<div class="item"><div class="title">Star Citizen Digital Download</div></div><div class="item"><div class="image" style="background-image:url('https://media.test/b.jpg')"></div><div class="text"><div class="title">Top Hat</div></div></div></div><div class="without-images"><div class="item"><div class="title">Self-Land Hangar</div></div></div>`,
          ),
      ),
    );

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledgeIds: ["101", "102"],
      pledges: [
        { id: "101", name: "CSV-SM", type: "ship" },
        { id: "102", name: "Cutter", type: "ship" },
      ],
    });
  });

  it("does not read a page where a ship lost its kind", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            `${item("Ship", "Cutter")}<div class="item"><div class="text"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary (<span>DRAK</span>)</div></div></div>`,
            "Package - Drake Starter",
          ),
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner, liner "Drake Interplanetary (DRAK)", in a "Package" pledge',
        ],
      },
    });
  });

  it("reads a pledge without a category holding an item with a manufacturer and no kind", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `${item("Hangar decoration", "Statue")}<div class="item"><div class="image"></div><div class="text"><div class="title">Reward</div><div class="liner">Roberts Space Industries (<span>RSI</span>)</div></div></div>`,
          "Luminalia 2955 Day 7",
        ),
      ),
    );

    expect(page.status).toBe(RsiPageStatus.PAGE);
    expect(
      page.status === RsiPageStatus.PAGE &&
        page.pledges.map((pledge) => pledge.type),
    ).toEqual(["flair"]);
  });

  it("reports an item it could not read without its title or custom name", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          '<div class="item js-item"><div class="text"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary <span class="custom-name-text">Sir Cutsalot</span></div></div></div>',
          "Package - Cutlass Black Starter",
        ),
      ),
    );

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner custom-name-text, liner "Drake Interplanetary", in a "Package" pledge',
        ],
      },
    });
  });

  it("reads a standalone ship pledge that holds its ship", () => {
    const page = extract(
      pledgesPage(
        pledge("101", item("Ship", "Cutter"), "Standalone Ship - Cutter"),
      ),
    );

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledges: [{ id: "101", name: "Cutter", type: "ship" }],
    });
  });

  it("does not read a standalone ship pledge that holds no ship", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            '<div class="with-images"><div class="item"><div class="text"><div class="title">Cutter</div></div></div></div>',
            "Standalone Ships - Cutter",
          ),
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: ['no ship in a "Standalone Ships" pledge, kinds none'],
      },
    });
  });

  it("names each kind of a standalone pledge without a ship once", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            `${item("Insurance", "Lifetime Insurance")}${item("Insurance", "120 Month Insurance")}`,
            "Standalone Ships - Cutter",
          ),
        ),
      ),
    ).toMatchObject({
      unread: {
        details: ['no ship in a "Standalone Ships" pledge, kinds Insurance'],
      },
    });
  });

  it("reports both an item without a kind and a standalone pledge without a ship", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            '<div class="item"><div class="text"><div class="title">Cutter</div><div class="liner">Drake Interplanetary</div></div></div>',
            "Standalone Ships - Cutter",
          ),
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner, liner "Drake Interplanetary", in a "Standalone Ships" pledge',
          'no ship in a "Standalone Ships" pledge, kinds none',
        ],
      },
    });
  });

  it("takes every case in turn and names each kind once", () => {
    const withoutKind = (liner: string) =>
      `<div class="item"><div class="text"><div class="title">Cutter</div><div class="liner">${liner}</div></div></div>`;

    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            `${withoutKind("Drake Interplanetary")}${item("Insurance", "Lifetime Insurance")}${item("Insurance\n  ", "120 Month Insurance")}${item("", "Poster")}`,
            "Standalone Ships - Cutter",
          ) +
            pledge(
              "102",
              withoutKind("Anvil Aerospace"),
              "Package - Carrack Expedition",
            ),
        ),
      ),
    ).toMatchObject({
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner, liner "Drake Interplanetary", in a "Standalone Ships" pledge',
          'no ship in a "Standalone Ships" pledge, kinds none, Insurance, empty',
          'unknown kind ""',
          'item without kind, markup item text title liner, liner "Anvil Aerospace", in a "Package" pledge',
        ],
      },
    });
  });

  it("reports an unknown kind alongside an item without a kind", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            `<div class="item"><div class="text"><div class="title">Cutter</div><div class="liner">Drake Interplanetary</div></div></div>${item("Vehicle", "Cutter")}`,
            "Package - Cutter Starter",
          ),
        ),
      ),
    ).toMatchObject({
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner, liner "Drake Interplanetary", in a "Package" pledge',
          'unknown kind "Vehicle"',
        ],
      },
    });
  });

  it("reads a pledge whose title holds a dash but none of RSI's categories", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `${item("Hangar decoration", "Trophy")}<div class="item"><div class="text"><div class="title">Goodies</div><div class="liner">Roberts Space Industries (<span>RSI</span>)</div></div></div>`,
          "CitizenCon 2955 - Digital Goodies",
        ),
      ),
    );

    expect(page.status).toBe(RsiPageStatus.PAGE);
  });

  it("reads the rest of a page holding an item it could not read", () => {
    const page = extract(
      pledgesPage(
        pledge("100", item("Ship", "Cutter"), "Package - Cutter") +
          pledge("101", item("Vehicle", "Ursa"), "Package - Ursa"),
      ),
    );

    expect(page).toMatchObject({
      status: RsiPageStatus.PAGE,
      pledgeIds: ["100", "101"],
      pledges: [{ id: "100", name: "Cutter", type: "ship" }],
      unread: { check: RsiPageCheckEnum.UNKNOWN_KINDS },
    });
  });

  it("reads a page without anything it could not read as nothing unread", () => {
    const page = extract(pledgesPage(pledge("101", item("Ship", "Cutter"))));

    expect(page).toMatchObject({ status: RsiPageStatus.PAGE });
    expect(page).not.toHaveProperty("unread", expect.anything());
  });

  it("keeps titles out of the details but sends the pledges it could not read", () => {
    const unread = pledge(
      "101",
      '<div class="item"><div class="text"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary <span class="custom-name-text">Sir Cutsalot</span></div></div></div>',
      "Package - Cutlass Black Starter",
    );
    const page = extract(
      pledgesPage(
        pledge("100", item("Ship", "Cutter"), "Package - Cutter") + unread,
      ),
    );

    expect(
      JSON.stringify(
        page.status === RsiPageStatus.PAGE && page.unread?.details,
      ),
    ).not.toContain("Cutlass");
    expect(page).toMatchObject({
      unread: { markup: [expect.stringContaining('value="101"')] },
    });
    expect(page).toMatchObject({
      unread: { markup: [expect.stringContaining("Cutlass Black")] },
    });
    expect(
      JSON.stringify(page.status === RsiPageStatus.PAGE && page.unread),
    ).not.toContain("Cutter");
  });

  it("sends at most five pledges, each cut to length", () => {
    const longTitle = "x".repeat(30000);
    const unread = (id: string) =>
      pledge(
        id,
        `<div class="item"><div class="title">${longTitle}</div><div class="kind">Spaceship</div></div>`,
        "Package - Odd",
      );
    const page = extract(
      pledgesPage(["1", "2", "3", "4", "5", "6"].map(unread).join("")),
    );

    expect(
      page.status === RsiPageStatus.PAGE && page.unread?.markup,
    ).toHaveLength(5);
    const markup =
      page.status === RsiPageStatus.PAGE ? (page.unread?.markup ?? []) : [];
    expect(markup).toHaveLength(5);
    markup.forEach((pledge) => expect(Array.from(pledge)).toHaveLength(20000));
  });

  it("sends no markup for a page without the pledge list", () => {
    const page = extract(
      "<html><head><title>My Account</title></head><body>Jane</body></html>",
    );

    expect(page).toMatchObject({ status: RsiPageStatus.UNRECOGNISED });
    expect(page).not.toHaveProperty("markup");
  });

  it("reads a hangar of upgrades only", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            '<div class="with-images"><div class="item"><div class="text"><div class="title">Upgrade - Clipper To S-65 Stingray</div></div></div></div>',
            "Upgrade - Clipper To S-65 Stingray",
          ),
        ),
      ),
    ).toEqual({
      status: RsiPageStatus.PAGE,
      pledges: [],
      pledgeIds: ["101"],
    });
  });

  it("does not read an item without a kind whose liner is empty", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            '<div class="item"><div class="text"><div class="title">Upgrade - Clipper To S-65 Stingray</div><div class="liner"> </div></div></div>',
            "Package - Clipper",
          ),
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.PAGE,
      unread: {
        check: RsiPageCheckEnum.MISSING_KINDS,
        details: [
          'item without kind, markup item text title liner, liner "", in a "Package" pledge',
        ],
      },
    });
  });

  it("does not read a page where a pledge lost its name", () => {
    expect(
      extract(
        pledgesPage(
          `<li><input type="hidden" class="js-pledge-id" value="101">${item("Ship", "Cutter")}</li>`,
        ),
      ),
    ).toMatchObject({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      details: ["pledges 1, ids 1, a name missing"],
    });
  });

  it("reads the pledge's name, melt value and item count onto its items", () => {
    const valued = (value: string, items: string) =>
      pledge(
        "101",
        items,
        "Standalone Ships - CSV-SM plus Granite Paint",
      ).replace(
        "<div",
        `<input type="hidden" class="js-pledge-value" value="${value}"><div`,
      );

    const page = extract(
      pledgesPage(
        valued(
          "$1,240.00 USD",
          `${item("Ship", "CSV-SM")}${item("Skin", "CSV - Granite Paint")}${item("Insurance", "Lifetime Insurance")}`,
        ),
      ),
    );

    expect(page).toMatchObject({
      pledges: [
        {},
        {
          name: "CSV - Granite Paint",
          pledgeName: "Standalone Ships - CSV-SM plus Granite Paint",
          pledgeValue: 1240,
          pledgeItemCount: 3,
        },
      ],
    });
  });

  it("does not count a pledge's text-only extras as its items", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `<div class="with-images">${item("Skin", "Cutlass - Akuma Paint")}</div><div class="without-images"><div class="item"><div class="title">Digital Wallpaper</div></div></div>`,
        ),
      ),
    );

    expect(page).toMatchObject({ pledges: [{ pledgeItemCount: 1 }] });
  });

  it("counts an item RSI lists without an image when it has a kind", () => {
    const page = extract(
      pledgesPage(
        pledge(
          "101",
          `<div class="with-images">${item("Skin", "Cutlass - Akuma Paint")}</div><div class="without-images"><div class="item"><div class="title">Poster</div><div class="kind">Hangar decoration</div></div></div>`,
        ),
      ),
    );

    expect(page).toMatchObject({
      pledges: [{ pledgeItemCount: 2 }, { name: "Poster", pledgeItemCount: 2 }],
    });
  });

  it("reads no melt value off a pledge of in-game credits", () => {
    const page = extract(
      pledgesPage(
        pledge("101", item("Skin", "Aurora - Dark Green Paint")).replace(
          "<div",
          '<input type="hidden" class="js-pledge-value" value="¤5,000 UEC"><div',
        ),
      ),
    );

    expect(page).toMatchObject({ pledges: [{ pledgeValue: undefined }] });
  });

  it("reads when the pledge was created and whether RSI offers to melt it", () => {
    const withMeta = (id: string, meta: string) =>
      pledge(id, item("Skin", "Cutlass - Akuma Paint")).replace(
        "<div",
        `${meta}<div`,
      );

    const page = extract(
      pledgesPage(
        withMeta(
          "101",
          '<div class="date-col"><label>Created:</label> October 08, 2026 </div><a class="shadow-button js-reclaim reclaim">Exchange</a>',
        ) +
          withMeta(
            "102",
            '<div class="date-col"><label>Created:</label> Oktober 08, 2026 </div>',
          ),
      ),
    );

    expect(page).toMatchObject({
      pledges: [
        { id: "101", pledgeCreatedOn: "2026-10-08", meltable: true },
        { id: "102", pledgeCreatedOn: undefined, meltable: false },
      ],
    });
  });
});
