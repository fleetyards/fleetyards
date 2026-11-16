import {
  BuybackPledgeKindEnum,
  type BuybackPledge,
  type HangarPledgeItem,
} from "@/services/fyApi";

// RSI gives neither list's entries an address of their own, except a
// non-upgrade buy-back, so a link goes to the page the pledge was last read
// from. Pledges added or bought back since can shift it by a page.
const listPage = (
  path: string,
  page?: number,
  filters: Record<string, string> = {},
) => {
  const query = new URLSearchParams({
    ...(page && page > 1 ? { page: String(page) } : {}),
    ...filters,
  }).toString();

  return `${window.RSI_ENDPOINT}/account/${path}${query ? `?${query}` : ""}`;
};

// An upgrade's buy-back is a modal on RSI's list page.
export const buybackRsiUrl = (
  buyback: Pick<BuybackPledge, "kind" | "rsiPledgeId" | "rsiPage">,
) =>
  buyback.kind === BuybackPledgeKindEnum.UPGRADE
    ? listPage("buy-back-pledges", buyback.rsiPage)
    : `${window.RSI_ENDPOINT}/pledge/buyback/${buyback.rsiPledgeId}`;

// A CCU is applied in the hangar. One last read from the list of upgrades alone
// is found on that list's page.
export const rsiHangarUrl = (
  item?: Partial<Pick<HangarPledgeItem, "rsiPage" | "rsiPageUpgradesOnly">>,
) =>
  listPage(
    "pledges",
    item?.rsiPage,
    item?.rsiPageUpgradesOnly ? { "product-type": "upgrade" } : {},
  );
