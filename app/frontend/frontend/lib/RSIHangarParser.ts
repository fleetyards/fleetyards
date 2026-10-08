import { type RSIHangarItem, type RSIHangarItemKind } from "@/frontend/types";
import { RsiPageCheckEnum } from "@/services/fyApi";
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";

// Only RSI's own empty-list markup ends the list. Anything else that does not
// look like a pledge page is a page this parser no longer understands: read as
// the end, it would cut the sync short and leave every ship after it unmatched.
export type RSIHangarPage =
  | {
      status: RsiPageStatus.PAGE;
      pledges: RSIHangarItem[];
      pledgeIds: string[];
    }
  | { status: RsiPageStatus.END }
  | { status: RsiPageStatus.UNRECOGNISED; check: RsiPageCheckEnum };

const READ_KINDS = new Map<string, RSIHangarItemKind>([
  ["Ship", "ship"],
  ["Component", "component"],
  ["Skin", "skin"],
  ["Hangar decoration", "flair"],
]);

// Kinds that never become a vehicle. Any other label may be a ship RSI has
// relabelled: skipped, it would drop out of the sync and the unmatched action
// would act on it.
const SKIPPED_KINDS = ["Insurance", "Credits", "FPS Equipment"];

const KNOWN_KINDS = [...READ_KINDS.keys(), ...SKIPPED_KINDS];

const COMPONENT_FOR_MODELS = [
  "GreyCat Estate Geotack-X Planetary Beacon",
  "GreyCat Estate Geotack Planetary Beacon",
];

const COMPONENT_FOR_UPGRADES = ["F7A Military Hornet Upgrade"];

// "$1,234.00 USD". A pledge of in-game credits reads "¤5,000 UEC", which is no
// melt value at all.
const PLEDGE_VALUE = /^\$([\d,]+\.\d{2}) USD$/;

// "Created: October 08, 2026". A date in any other form is left out; the
// pledge id still orders the hangar without it.
const PLEDGE_CREATED_ON = /([A-Z][a-z]+) (\d{1,2}), (\d{4})/;

const MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

type RSIPledgeInfo = Pick<
  RSIHangarItem,
  | "pledgeName"
  | "pledgeValue"
  | "pledgeItemCount"
  | "pledgeCreatedOn"
  | "meltable"
>;

export class RSIHangarParser {
  parser = new DOMParser();

  extractPage(html: string): RSIHangarPage {
    const htmlDoc = this.parser.parseFromString(html, "text/html");

    if (this.checkForLastPage(htmlDoc)) {
      return { status: RsiPageStatus.END };
    }

    const pledgeList = htmlDoc.getElementsByClassName("list-items")[0];

    if (!pledgeList) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_LIST,
      };
    }

    const entries = Array.from(pledgeList.children).filter(
      (child) => child.tagName === "LI",
    );

    const pledges: RSIHangarItem[] = [];
    const pledgeIds: string[] = [];
    let missingPledgeName = false;
    let shipWithoutKind = false;
    let unknownKind = false;
    let standaloneShipWithoutShip = false;

    entries.forEach((entry) => {
      const id = (
        entry.getElementsByClassName("js-pledge-id")[0] as HTMLInputElement
      )?.value;

      if (id) {
        pledgeIds.push(id);
      }

      const name = this.pledgeName(entry);

      if (name === undefined) {
        missingPledgeName = true;
      }

      const items: RSIHangarItem[] = [];

      const elements = Array.from(entry.getElementsByClassName("item"));

      const pledgeInfo: RSIPledgeInfo = {
        pledgeName: name || undefined,
        pledgeValue: this.parsePledgeValue(
          this.hiddenValue(entry, "js-pledge-value"),
        ),
        pledgeItemCount: elements.filter(
          (item) =>
            this.itemKind(item) !== undefined ||
            !item.closest(".without-images"),
        ).length,
        pledgeCreatedOn: this.parseCreatedOn(
          entry.getElementsByClassName("date-col")[0]?.textContent,
        ),
        // RSI's "Exchange" button, the one that melts the pledge.
        meltable: !!entry.getElementsByClassName("js-reclaim")[0],
      };

      elements.forEach((item) => {
        const kind = this.itemKind(item);

        if (kind === undefined) {
          // RSI gives no kind to ship upgrades, the game download or old
          // merchandise, but none of those names a manufacturer. Every ship
          // does: one with a manufacturer and no kind would drop out of the
          // sync, and the unmatched action would act on it.
          if (this.hasManufacturer(item)) {
            shipWithoutKind = true;
          }
          return;
        }

        if (!KNOWN_KINDS.includes(kind)) {
          unknownKind = true;
          return;
        }

        if (READ_KINDS.has(kind)) {
          items.push(this.parseItem(id, item, kind, pledgeInfo));
        }
      });

      // Every standalone ship pledge holds its ship. One that reads none has
      // lost both its kind and its manufacturer.
      if (
        name?.startsWith("Standalone Ship") &&
        !items.some((item) => item.type === "ship")
      ) {
        standaloneShipWithoutShip = true;
      }

      pledges.push(...items);
    });

    // Every pledge row, not just one: a row that no longer reads would drop
    // its ships out of the sync, and the unmatched action would act on them.
    // Without its name, the standalone ship check below would pass unseen.
    if (
      pledgeIds.length === 0 ||
      pledgeIds.length < entries.length ||
      missingPledgeName
    ) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      };
    }

    if (shipWithoutKind) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_KINDS,
      };
    }

    if (unknownKind) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.UNKNOWN_KINDS,
      };
    }

    if (standaloneShipWithoutShip) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_KINDS,
      };
    }

    return { status: RsiPageStatus.PAGE, pledges, pledgeIds };
  }

  parseItem(
    id: string,
    item: Element,
    kind: string,
    pledgeInfo: RSIPledgeInfo = {},
  ): RSIHangarItem {
    const name = item.getElementsByClassName("title")[0]?.textContent || "";

    let kindOverride: RSIHangarItemKind | undefined;
    if (
      COMPONENT_FOR_MODELS.some((validName) => name.includes(validName)) &&
      kind === "Component"
    ) {
      kindOverride = "ship";
    }

    if (
      COMPONENT_FOR_UPGRADES.some((validName) => name.includes(validName)) &&
      kind === "Component"
    ) {
      kindOverride = "upgrade";
    }

    const image = this.extractImage(item);

    return {
      id,
      name,
      image,
      customName:
        item.getElementsByClassName("custom-name-text")[0]?.textContent ||
        undefined,
      type: kindOverride || (READ_KINDS.get(kind) as RSIHangarItemKind),
      ...pledgeInfo,
    };
  }

  hiddenValue(entry: Element, className: string): string | undefined {
    return (
      (entry.getElementsByClassName(className)[0] as HTMLInputElement)?.value ||
      undefined
    );
  }

  parsePledgeValue(value: string | undefined): number | undefined {
    const match = value?.trim().match(PLEDGE_VALUE);

    return match ? Number(match[1].replaceAll(",", "")) : undefined;
  }

  parseCreatedOn(text: string | undefined | null): string | undefined {
    const match = text?.match(PLEDGE_CREATED_ON);
    const month = match ? MONTHS.indexOf(match[1]) + 1 : 0;

    if (!match || month === 0) {
      return undefined;
    }

    return `${match[3]}-${String(month).padStart(2, "0")}-${match[2].padStart(2, "0")}`;
  }

  pledgeName(entry: Element): string | undefined {
    return (
      entry.getElementsByClassName("js-pledge-name")[0] as
        HTMLInputElement | undefined
    )?.value;
  }

  // Present but empty still counts: a stop that should not have happened is
  // reported, a ship dropped from the sync is acted on.
  hasManufacturer(item: Element): boolean {
    return !!item.getElementsByClassName("liner")[0];
  }

  itemKind(item: Element): string | undefined {
    const kind = item.getElementsByClassName("kind")[0];

    return kind ? kind.textContent || "" : undefined;
  }

  extractImage(item: Element): string | undefined {
    const imageElement = item.getElementsByClassName(
      "image",
    )[0] as HTMLDivElement;

    if (!imageElement?.style?.backgroundImage) {
      return undefined;
    }

    let imageUrl = imageElement.style.backgroundImage
      .slice(4, -1)
      .replace(/['"]+/g, "");

    if (!imageUrl.startsWith("https")) {
      imageUrl = `${window.RSI_ENDPOINT}${imageUrl}`;
    }

    return imageUrl.replace("subscribers_vault_thumbnail", "source");
  }

  // An empty hangar shows this marker. Past the last page RSI repeats the
  // last one instead, which the sync reads as nothing new. Only on the hangar
  // page itself: another page using the class is not the end of anything.
  checkForLastPage(htmlDoc: Document): boolean {
    const emptyList = htmlDoc.getElementsByClassName("empty-list")[0];
    const empyList = htmlDoc.getElementsByClassName("empy-list")[0];

    return !!(emptyList || empyList) && /^\s*My Hangar\b/.test(htmlDoc.title);
  }
}
