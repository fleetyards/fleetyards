import { parse, format, isValid } from "date-fns";
import {
  BuybackPledgeKindEnum,
  RsiPageCheckEnum,
  type RsiBuybackItemInput,
} from "@/services/fyApi";
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";

const KIND_PREFIXES: [string, BuybackPledgeKindEnum][] = [
  ["Package", BuybackPledgeKindEnum.PACKAGE],
  ["Standalone Ship", BuybackPledgeKindEnum.SHIP],
  ["Upgrade", BuybackPledgeKindEnum.UPGRADE],
  ["Paint", BuybackPledgeKindEnum.PAINT],
  ["Add-On", BuybackPledgeKindEnum.ADDON],
];

const DEFAULT_IMAGE = "default-image";

const BUYBACK_LIST = "section.available-pledges, .buy-back";

// Only RSI's own empty list ends the list, the same three answers the hangar
// parser gives. A page past the last one renders with an empty list; anything
// else that is not a readable buy-back page stops the sync, since submitting
// the list read so far would delete every buy-back after it.
export type RSIBuybackPage =
  | {
      status: RsiPageStatus.PAGE;
      pledges: RsiBuybackItemInput[];
      pledgeIds: string[];
    }
  | { status: RsiPageStatus.END }
  | { status: RsiPageStatus.UNRECOGNISED; check: RsiPageCheckEnum };

const BUYBACK_LINK = "a[href*='/pledge/buyback/']";

export const extractBuybackPage = (html: string): RSIBuybackPage => {
  const htmlDoc = new DOMParser().parseFromString(html, "text/html");

  // A login redirect or an error page arrives as a 200 too.
  const list = htmlDoc.querySelector(BUYBACK_LIST);

  if (!list) {
    return {
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.MISSING_LIST,
    };
  }

  const entries = Array.from(list.querySelectorAll("article.pledge"));

  // Links to buy-backs inside the list without entries around them is what
  // renamed entries look like.
  if (entries.length === 0) {
    return list.querySelector(BUYBACK_LINK)
      ? {
          status: RsiPageStatus.UNRECOGNISED,
          check: RsiPageCheckEnum.MISSING_ENTRIES,
        }
      : { status: RsiPageStatus.END };
  }

  const pledges = entries
    .map(parseBuybackEntry)
    .filter((pledge): pledge is RsiBuybackItemInput => !!pledge);

  if (pledges.length === 0) {
    return {
      status: RsiPageStatus.UNRECOGNISED,
      check: RsiPageCheckEnum.UNPARSED_ENTRIES,
    };
  }

  return {
    status: RsiPageStatus.PAGE,
    pledges,
    pledgeIds: pledges.map((pledge) => pledge.id),
  };
};

export const parseBuybackEntry = (
  entry: Element,
): RsiBuybackItemInput | undefined => {
  const heading = entry.querySelector("h1");
  const name = (heading?.getAttribute("title") || headingText(heading))
    .trim()
    .replace(/\s+/g, " ");

  const upgradeLink = entry.querySelector<HTMLElement>(
    ".js-open-ship-upgrades",
  );
  const id = upgradeLink?.dataset.pledgeid || extractBuybackLinkId(entry);

  if (!id || !name) {
    return undefined;
  }

  return {
    id,
    name,
    kind: upgradeLink ? BuybackPledgeKindEnum.UPGRADE : kindFromName(name),
    upgraded: !!heading?.querySelector(".upgraded"),
    // RSI renders the "Not available" block on every entry and shows it only
    // on one marked like this.
    available: !entry.hasAttribute("data-disabled"),
    reclaimedOn: parseReclaimDate(definition(entry, "Reclaim Date")),
    contained: definition(entry, "Contained"),
    image: extractImage(entry),
    upgradeFromShipId: toInteger(upgradeLink?.dataset.fromshipid),
    upgradeToShipId: toInteger(upgradeLink?.dataset.toshipid),
    upgradeToSkuId: toInteger(upgradeLink?.dataset.toskuid),
  };
};

// The text carries an appended " - upgraded" span that is not part of the
// pledge's name.
const headingText = (heading: Element | null) => {
  if (!heading) {
    return "";
  }

  const copy = heading.cloneNode(true) as Element;
  copy.querySelector(".upgraded")?.remove();

  return copy.textContent || "";
};

const extractBuybackLinkId = (entry: Element) =>
  entry
    .querySelector<HTMLAnchorElement>("a[href*='/pledge/buyback/']")
    ?.getAttribute("href")
    ?.match(/\/pledge\/buyback\/(\d+)/)?.[1];

const kindFromName = (name: string): BuybackPledgeKindEnum =>
  KIND_PREFIXES.find(([prefix]) => name.startsWith(prefix))?.[1] ||
  BuybackPledgeKindEnum.OTHER;

const definition = (entry: Element, label: string) => {
  const term = Array.from(entry.querySelectorAll("dt")).find(
    (dt) => dt.textContent?.trim().replace(/:$/, "") === label,
  );

  const value = term?.nextElementSibling?.textContent?.trim();

  return value || undefined;
};

const parseReclaimDate = (value?: string) => {
  if (!value) {
    return undefined;
  }

  const date = parse(value, "MMMM d, yyyy", new Date());

  return isValid(date) ? format(date, "yyyy-MM-dd") : undefined;
};

const extractImage = (entry: Element) => {
  const src = entry.querySelector("figure img")?.getAttribute("src");

  if (!src || src.includes(DEFAULT_IMAGE)) {
    return undefined;
  }

  return src.startsWith("http") ? src : `${window.RSI_ENDPOINT}${src}`;
};

const toInteger = (value?: string) => {
  const number = Number.parseInt(value || "", 10);

  return Number.isNaN(number) ? undefined : number;
};
