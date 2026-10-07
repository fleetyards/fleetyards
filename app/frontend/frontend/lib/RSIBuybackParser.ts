import { parse, format, isValid } from "date-fns";
import {
  BuybackPledgeKindEnum,
  type RsiBuybackItemInput,
} from "@/services/fyApi";

export type RSIBuybackPage = {
  pledges: RsiBuybackItemInput[];
  pledgeIds: string[];
  entryCount: number;
};

const KIND_PREFIXES: [string, BuybackPledgeKindEnum][] = [
  ["Package", BuybackPledgeKindEnum.PACKAGE],
  ["Standalone Ship", BuybackPledgeKindEnum.SHIP],
  ["Upgrade", BuybackPledgeKindEnum.UPGRADE],
  ["Paint", BuybackPledgeKindEnum.PAINT],
  ["Add-On", BuybackPledgeKindEnum.ADDON],
];

const DEFAULT_IMAGE = "default-image";

const BUYBACK_LIST = "section.available-pledges, .buy-back";

// `undefined` when the HTML is not a buy-back page at all -- a login redirect
// or an error page arrives as a 200 too. RSI renders a page past the last one
// as the page with an empty list, so `entryCount: 0` is the end-of-list signal.
export const extractBuybackPage = (
  html: string,
): RSIBuybackPage | undefined => {
  const htmlDoc = new DOMParser().parseFromString(html, "text/html");

  if (!htmlDoc.querySelector(BUYBACK_LIST)) {
    return undefined;
  }

  const entries = Array.from(htmlDoc.querySelectorAll("article.pledge"));

  const pledges = entries
    .map(parseBuybackEntry)
    .filter((pledge): pledge is RsiBuybackItemInput => !!pledge);

  return {
    pledges,
    pledgeIds: pledges.map((pledge) => pledge.id),
    entryCount: entries.length,
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
