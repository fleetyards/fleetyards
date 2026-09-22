import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import {
  AnnouncementStatusEnum,
  getAnnouncementQueryKey,
  getAnnouncementsQueryKey,
  type Announcement,
  type Announcements,
} from "@/services/fyAdminApi";
import { useAnnouncementInvalidation } from "./useAnnouncementUpdates";

const ID = "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c";

const announcement = (attrs: Partial<Announcement> = {}) =>
  ({
    id: ID,
    title: "Commodities are live",
    body: "Something new just landed.",
    discordParts: [],
    socialParts: [],
    icon: "fa-duotone fa-bullhorn",
    status: AnnouncementStatusEnum.DRAFT,
    notifyUsers: true,
    postDiscord: false,
    postBluesky: false,
    postX: false,
    publishable: true,
    deliveries: [],
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Announcement;

const list = (...items: Announcement[]) =>
  ({
    meta: { pagination: { totalCount: items.length } },
    items,
  }) as unknown as Announcements;

const render = () => {
  const queryClient = new QueryClient();

  let patchCached: (value: Announcement) => void = () => {};

  mount(
    defineComponent({
      setup() {
        ({ patchCached } = useAnnouncementInvalidation());

        return () => h("div");
      },
    }),
    { global: { plugins: [[VueQueryPlugin, { queryClient }]] } },
  );

  return {
    queryClient,
    patchCached: (value: Announcement) => patchCached(value),
  };
};

const LIST_KEY = getAnnouncementsQueryKey({ page: "1" });

describe("useAnnouncementInvalidation", () => {
  it("swaps the broadcast row into the cached list", () => {
    const { queryClient, patchCached } = render();

    queryClient.setQueryData(LIST_KEY, list(announcement()));

    patchCached(announcement({ status: AnnouncementStatusEnum.PUBLISHING }));

    expect(
      queryClient.getQueryData<Announcements>(LIST_KEY)?.items[0].status,
    ).toBe(AnnouncementStatusEnum.PUBLISHING);
  });

  it("leaves the rest of the page alone", () => {
    const { queryClient, patchCached } = render();
    const other = announcement({ id: "other", title: "Older" });

    queryClient.setQueryData(LIST_KEY, list(other, announcement()));

    patchCached(announcement({ status: AnnouncementStatusEnum.PUBLISHED }));

    const items = queryClient.getQueryData<Announcements>(LIST_KEY)?.items;

    expect(items?.[0]).toEqual(other);
    expect(items?.[1].status).toBe(AnnouncementStatusEnum.PUBLISHED);
  });

  // The row belongs on a page this reader is not on. Inserting it would put it
  // in the wrong place in the sort and give the page one row too many.
  it("does not insert a row the page never held", () => {
    const { queryClient, patchCached } = render();

    queryClient.setQueryData(LIST_KEY, list(announcement({ id: "other" })));

    patchCached(announcement());

    expect(
      queryClient.getQueryData<Announcements>(LIST_KEY)?.items,
    ).toHaveLength(1);
  });

  it("patches the detail query the edit form reads", () => {
    const { queryClient, patchCached } = render();

    queryClient.setQueryData(getAnnouncementQueryKey(ID), announcement());

    patchCached(announcement({ status: AnnouncementStatusEnum.FAILED }));

    expect(
      queryClient.getQueryData<Announcement>(getAnnouncementQueryKey(ID))
        ?.status,
    ).toBe(AnnouncementStatusEnum.FAILED);
  });

  // `['announcements']` is a prefix of `['announcements', id]`, so the list's
  // own setQueriesData matches the detail query too - and its payload is a bare
  // announcement with no `items` to map over.
  it("does not maul the detail query while patching the lists", () => {
    const { queryClient, patchCached } = render();

    queryClient.setQueryData(
      getAnnouncementQueryKey("other"),
      announcement({ id: "other" }),
    );

    patchCached(announcement());

    expect(
      queryClient.getQueryData<Announcement>(getAnnouncementQueryKey("other"))
        ?.id,
    ).toBe("other");
  });

  // A record nobody has loaded must not be conjured into the cache: the detail
  // query would then resolve from a payload that never went through its own
  // fetch, and `AsyncData` would show it without ever having asked.
  it("does not seed a detail query that was never loaded", () => {
    const { queryClient, patchCached } = render();

    patchCached(announcement());

    expect(
      queryClient.getQueryData<Announcement>(getAnnouncementQueryKey(ID)),
    ).toBeUndefined();
  });
});
