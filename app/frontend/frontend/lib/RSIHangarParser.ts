const VALID_COMPONENT_NAMES = ["Galaxy", "Endeavor", "Retaliator"];

const COMPONENT_FOR_MODELS = [
  "GreyCat Estate Geotack-X Planetary Beacon",
  "GreyCat Estate Geotack Planetary Beacon",
];

const COMPONENT_FOR_UPGRADES = ["F7A Military Hornet Upgrade"];

export class RSIHangarParser {
  parser = new DOMParser();

  extractPage(html: string): TRSIHangarItem[] | undefined {
    const htmlDoc = this.parser.parseFromString(html, "text/html");

    if (this.checkForLastPage(htmlDoc)) {
      return undefined;
    }

    const pledgeList = htmlDoc.getElementsByClassName("list-items")[0];

    if (!pledgeList) {
      return [];
    }

    const entries = pledgeList.getElementsByTagName("li");

    const pledges: TRSIHangarItem[] = [];

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

  parseItem(id: string, item: Element): TRSIHangarItem | undefined {
    const kind = item.getElementsByClassName("kind")[0]?.textContent;

    if (!kind || !["Ship", "Component", "Skin"].includes(kind)) {
      return undefined;
    }

    const name = item.getElementsByClassName("title")[0].textContent || "";

    let kindOverride: TRSIHangarItemKind | undefined;
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

    if (
      !VALID_COMPONENT_NAMES.some((validName) => name.includes(validName)) &&
      kind === "Component" &&
      !kindOverride
    ) {
      return undefined;
    }

    return {
      id,
      name,
      customName:
        item.getElementsByClassName("custom-name-text")[0]?.textContent ||
        undefined,
      type: kindOverride || (kind.toLowerCase() as TRSIHangarItemKind),
    };
  }

  checkForLastPage(htmlDoc: Document): boolean {
    const emptyList = htmlDoc.getElementsByClassName("empty-list")[0];
    const empyList = htmlDoc.getElementsByClassName("empy-list")[0];

    return !!(emptyList || empyList);
  }
}
