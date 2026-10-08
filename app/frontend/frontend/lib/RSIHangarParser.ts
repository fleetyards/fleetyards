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

const READ_KINDS = ["Ship", "Component", "Skin"];

// Kinds that never become a vehicle. Any other label may be a ship RSI has
// relabelled: skipped, it would drop out of the sync and the unmatched action
// would act on it.
const SKIPPED_KINDS = [
  "Insurance",
  "Credits",
  "Hangar decoration",
  "FPS Equipment",
];

const KNOWN_KINDS = [...READ_KINDS, ...SKIPPED_KINDS];

const COMPONENT_FOR_MODELS = [
  "GreyCat Estate Geotack-X Planetary Beacon",
  "GreyCat Estate Geotack Planetary Beacon",
];

const COMPONENT_FOR_UPGRADES = ["F7A Military Hornet Upgrade"];

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

      Array.from(entry.getElementsByClassName("item")).forEach((item) => {
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

        const parsed = this.parseItem(id, item, kind);

        if (parsed) {
          items.push(parsed);
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
  ): RSIHangarItem | undefined {
    if (!READ_KINDS.includes(kind)) {
      return undefined;
    }

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
      type: kindOverride || (kind.toLowerCase() as RSIHangarItemKind),
    };
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
