import {
  BuybackPledgeKindEnum,
  type BuybackPledge,
  type HangarPledgeItem,
} from "@/services/fyApi";

// RSI gives neither list's entries an address of their own, except a
// non-upgrade buy-back, so a link goes to the page the pledge was last read
// from. Pledges added or bought back since can shift it by a page.
const listPage = (path: string, page?: number) =>
  page && page > 1
    ? `${window.RSI_ENDPOINT}/account/${path}?page=${page}`
    : `${window.RSI_ENDPOINT}/account/${path}`;

// An upgrade's buy-back is a modal on RSI's list page.
export const buybackRsiUrl = (
  buyback: Pick<BuybackPledge, "kind" | "rsiPledgeId" | "rsiPage">,
) =>
  buyback.kind === BuybackPledgeKindEnum.UPGRADE
    ? listPage("buy-back-pledges", buyback.rsiPage)
    : `${window.RSI_ENDPOINT}/pledge/buyback/${buyback.rsiPledgeId}`;

// A CCU is applied in the hangar.
export const rsiHangarUrl = (item?: Pick<HangarPledgeItem, "rsiPage">) =>
  listPage("pledges", item?.rsiPage);
