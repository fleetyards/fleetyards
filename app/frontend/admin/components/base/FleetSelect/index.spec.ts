import { beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import type { FleetOptions } from "@/services/fyAdminApi";

const fleetOptions = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyAdminApi", () => ({ fleetOptions }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, params?: { count?: number }) =>
      params?.count === undefined ? key : `${params.count} members`,
  }),
}));

import FleetSelect from "./index.vue";

type SelectProps = {
  queryFn: (params: { page?: number; search?: string }) => Promise<unknown>;
  queryResponseFormatter: (response: FleetOptions) => unknown;
  unsorted: boolean;
};

const response: FleetOptions = {
  items: [
    { id: "1", fid: "Test100", name: "Test", slug: "test", memberCount: 4 },
    { id: "2", fid: "1test", name: "1test", slug: "1test", memberCount: 1 },
  ],
  meta: {
    pagination: { currentPage: 1, totalPages: 1, perPage: 25, totalCount: 2 },
  },
};

const mountSelect = (props: Record<string, unknown> = {}) => {
  const wrapper = mount(FleetSelect, {
    props: { name: "fleet", ...props },
    global: {
      stubs: {
        BaseSelect: {
          name: "BaseSelect",
          props: ["queryFn", "queryResponseFormatter", "unsorted"],
          template: "<div />",
        },
      },
    },
  });

  return wrapper
    .findComponent({ name: "BaseSelect" })
    .props() as unknown as SelectProps;
};

describe("FleetSelect", () => {
  beforeEach(() => {
    fleetOptions.mockReset().mockResolvedValue(response);
  });

  it("asks the ranked search by name or SID", async () => {
    const select = mountSelect();

    await select.queryFn({ page: 2, search: " test " });

    expect(fleetOptions).toHaveBeenCalledWith({
      page: "2",
      q: { search: "test" },
    });
  });

  // The API ranks exact, then prefix, then contains; a re-sort by label would
  // put "1test" ahead of the fleet actually called "Test".
  it("keeps the order the API ranked", () => {
    expect(mountSelect().unsorted).toBe(true);
  });

  it("names each fleet with its SID and roster size", () => {
    expect(mountSelect().queryResponseFormatter(response)).toEqual([
      { label: "Test (Test100) · 4 members", value: "Test100" },
      { label: "1test (1test) · 1 members", value: "1test" },
    ]);
  });

  it("marks the fleets it is told are taken", () => {
    const select = mountSelect({
      markedFids: ["Test100"],
      markedLabel: "Enabled",
    });

    expect(select.queryResponseFormatter(response)).toEqual([
      { label: "Test (Test100) · 4 members · Enabled", value: "Test100" },
      { label: "1test (1test) · 1 members", value: "1test" },
    ]);
  });
});
