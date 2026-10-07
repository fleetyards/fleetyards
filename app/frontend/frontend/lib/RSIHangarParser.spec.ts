import { describe, it, expect } from "vitest";
import { RSIHangarParser } from "./RSIHangarParser";
import { RsiPageStatus } from "./RsiPageStatus";
import { RsiPageCheckEnum } from "@/services/fyApi";

// The structure the parser reads off the pledges page; ids are made up.
const pledge = (id: string, items: string) => `
<li>
  <input type="hidden" class="js-pledge-id" value="${id}">
  <div class="items">${items}</div>
</li>`;

const item = (kind: string, title: string) => `
<div class="item">
  <div class="image" style="background-image:url('https://media.test/a.jpg')"></div>
  <div class="title">${title}</div>
  <div class="kind">${kind}</div>
</div>`;

const pledgesPage = (entries: string) =>
  `<div class="page-wrapper"><ul class="list-items">${entries}</ul></div>`;

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
      extract('<div class="list-items"><div class="empty-list"></div></div>'),
    ).toEqual({ status: RsiPageStatus.END });
  });

  it("does not read a page without the pledge list as the end", () => {
    expect(
      extract("<html><body><form id='sign-in'></form></body></html>"),
    ).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_LIST,
    });
  });

  it("does not read pledges without ids", () => {
    expect(extract(pledgesPage(`<li><div class="item"></div></li>`))).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
    });
  });

  it("does not read items that no longer say what they are", () => {
    expect(
      extract(
        pledgesPage(
          pledge(
            "101",
            '<div class="item"><div class="title">Cutter</div></div>',
          ),
        ),
      ),
    ).toEqual({
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_KINDS,
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
});
