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

    const entries = Array.from(pledgeList.getElementsByTagName("li"));

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

    if (pledgeIds.length === 0) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_PLEDGE_IDS,
      };
    }

    const items = Array.from(pledgeList.getElementsByClassName("item"));

    if (
      items.length > 0 &&
      !items.some((item) => item.getElementsByClassName("kind")[0])
    ) {
      return {
        status: RsiPageStatus.UNRECOGNISED,
        check: RsiPageCheckEnum.MISSING_KINDS,
      };
    }

    return { status: RsiPageStatus.PAGE, pledges, pledgeIds };
  }

  parseItem(id: string, item: Element): RSIHangarItem | undefined {
    const kind = item.getElementsByClassName("kind")[0]?.textContent;

    if (!kind || !["Ship", "Component", "Skin"].includes(kind)) {
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

  checkForLastPage(htmlDoc: Document): boolean {
    const emptyList = htmlDoc.getElementsByClassName("empty-list")[0];
    const empyList = htmlDoc.getElementsByClassName("empy-list")[0];

    return !!(emptyList || empyList);
  }
}
