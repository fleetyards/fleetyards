import { type RSIHangarItem, type RSIHangarItemKind } from "@/frontend/types";

const COMPONENT_FOR_MODELS = [
  "GreyCat Estate Geotack-X Planetary Beacon",
  "GreyCat Estate Geotack Planetary Beacon",
];

const COMPONENT_FOR_UPGRADES = ["F7A Military Hornet Upgrade"];

export class RSIHangarParser {
  parser = new DOMParser();

  extractPage(html: string): RSIHangarItem[] | undefined {
    const htmlDoc = this.parser.parseFromString(html, "text/html");

    if (this.checkForLastPage(htmlDoc)) {
      return undefined;
    }

    const pledgeList = htmlDoc.getElementsByClassName("list-items")[0];

    if (!pledgeList) {
      return undefined;
    }

    const entries = pledgeList.getElementsByTagName("li");

    const pledges: RSIHangarItem[] = [];

    Array.from(entries).forEach((entry) => {
      const id = (
        entry.getElementsByClassName("js-pledge-id")[0] as HTMLInputElement
      )?.value;

      const items = entry.getElementsByClassName("item");

      Array.from(items).forEach((item) => {
        const pledge = this.parseItem(id, item);
        if (pledge) {
          pledges.push(pledge);
        }
      });
    });

    return pledges;
  }

  parseItem(id: string, item: Element): RSIHangarItem | undefined {
    const kind = item.getElementsByClassName("kind")[0]?.textContent;

    if (!kind || !["Ship", "Component", "Skin"].includes(kind)) {
      return undefined;
    }

    const name = item.getElementsByClassName("title")[0].textContent || "";

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
    let imageUrl = imageElement.style.backgroundImage
      .slice(4, -1)
      .replace(/['"]+/g, "");

    if (!imageUrl.startsWith("https")) {
      imageUrl = `${window.RSI_ENDPOINT}${imageUrl}`;
    }

    return imageUrl.replace("subscribers_vault_thumbnail", "source");
  }

  extractMaxPage(html: string): number | undefined {
    const htmlDoc = this.parser.parseFromString(html, "text/html");
    const links = htmlDoc.querySelectorAll('a[href*="page="]');
    let maxPage: number | undefined;

    links.forEach((link) => {
      const match = link.getAttribute("href")?.match(/page=(\d+)/);
      if (match) {
        const page = parseInt(match[1], 10);
        if (maxPage === undefined || page > maxPage) {
          maxPage = page;
        }
      }
    });

    return maxPage;
  }

  checkForLastPage(htmlDoc: Document): boolean {
    const emptyList = htmlDoc.getElementsByClassName("empty-list")[0];
    const empyList = htmlDoc.getElementsByClassName("empy-list")[0];

    return !!(emptyList || empyList);
  }
}
