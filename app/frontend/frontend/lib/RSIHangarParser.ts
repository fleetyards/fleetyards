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

    entries.forEach((entry) => {
      const id = (
        entry.getElementsByClassName("js-pledge-id")[0] as HTMLInputElement
      )?.value;

      if (id) {
        pledgeIds.push(id);
      }

      const items = entry.getElementsByClassName("item");

      Array.from(items).forEach((item) => {
        const pledge = this.parseItem(id, item);
        if (pledge) {
          pledges.push(pledge);
        }
      });
    });

    // Every pledge row, not just one: a row that no longer reads would drop
    // its ships out of the sync, and the unmatched action would act on them.
    if (pledgeIds.length === 0 || pledgeIds.length < entries.length) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      };
    }

    const items = Array.from(pledgeList.getElementsByClassName("item"));

    if (items.some((item) => !item.getElementsByClassName("kind")[0])) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_KINDS,
      };
    }

    const known = [...READ_KINDS, ...SKIPPED_KINDS];

    if (items.some((item) => !known.includes(this.itemKind(item)))) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.UNKNOWN_KINDS,
      };
    }

    return { status: RsiPageStatus.PAGE, pledges, pledgeIds };
  }

  parseItem(id: string, item: Element): RSIHangarItem | undefined {
    const kind = this.itemKind(item);

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

  itemKind(item: Element): string {
    return item.getElementsByClassName("kind")[0]?.textContent || "";
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
