import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { defineComponent } from "vue";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { useDepositTargets } from "./useDepositTargets";

const api = vi.hoisted(() => ({
  features: ["hangar_inventories", "fleet_logistics"],
  hangar: { items: [] as unknown[] } as { items: unknown[] } | Error,
  fleets: [] as { slug: string; name: string }[],
  memberships: {} as Record<
    string,
    { status: string; capabilities: object } | Error
  >,
  inventories: {} as Record<string, { items: unknown[] } | Error>,
  inventoryRequests: [] as string[],
}));

const answer = <T>(value: T | Error) =>
  value instanceof Error ? Promise.reject(value) : Promise.resolve(value);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) => api.features.includes(feature),
    isFleetFeatureEnabled: (_fleet: unknown, feature: string) =>
      api.features.includes(feature),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { useQuery } = await import("@tanstack/vue-query");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useHangarInventories: (
      _params: unknown,
      options: { query: { enabled: unknown } },
    ) =>
      useQuery({
        queryKey: ["hangar-inventories"],
        queryFn: () => answer(api.hangar),
        retry: false,
        enabled: options.query.enabled as never,
      }),
    useMyFleets: (options: { query: { enabled: unknown } }) =>
      useQuery({
        queryKey: ["my-fleets"],
        queryFn: () => Promise.resolve(api.fleets),
        retry: false,
        enabled: options.query.enabled as never,
      }),
    getFleetMembershipQueryOptions: (slug: string) => ({
      queryKey: ["membership", slug],
      queryFn: () => answer(api.memberships[slug]),
      retry: false,
    }),
    getFleetInventoriesQueryOptions: (slug: string) => ({
      queryKey: ["fleet-inventories", slug],
      queryFn: () => {
        api.inventoryRequests.push(slug);

        return answer(api.inventories[slug]);
      },
      retry: false,
    }),
  };
});

let wrapper: VueWrapper | undefined;
let targets: ReturnType<typeof useDepositTargets>;

const mount = async () => {
  wrapper = await mountWithDefaults(
    defineComponent({
      setup() {
        targets = useDepositTargets(true);

        return () => null;
      },
    }),
  );
  await flushPromises();
  await flushPromises();

  return targets;
};

beforeEach(() => {
  api.features = ["hangar_inventories", "fleet_logistics"];
  api.hangar = {
    items: [
      { id: "inv-1", slug: "cargo-hold", name: "Cargo Hold" },
      {
        id: "inv-2",
        slug: "cargo",
        name: "Ironclad Cargo",
        vehicle: { id: "ironclad" },
      },
    ],
  };
  api.fleets = [
    { slug: "crew", name: "Crew" },
    { slug: "guests", name: "Guests" },
    { slug: "applied", name: "Applied" },
  ];
  api.memberships = {
    crew: { status: "accepted", capabilities: { updateInventories: true } },
    guests: { status: "accepted", capabilities: { updateInventories: false } },
    applied: {
      status: "requested",
      capabilities: { updateInventories: true },
    },
  };
  api.inventories = {
    crew: {
      items: [
        { id: "inv-4", slug: "vault", name: "Vault" },
        { id: "inv-3", slug: "depot", name: "Depot" },
      ],
    },
  };
  api.inventoryRequests = [];
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("useDepositTargets", () => {
  it("lists the reader's own inventories, then each fleet's", async () => {
    const { options } = await mount();

    expect(options.value).toEqual([
      {
        value: "inv-1",
        label: "Cargo Hold",
        category: "labels.logistics.personalInventory",
      },
      {
        value: "inv-2",
        label: "Ironclad Cargo",
        category: "labels.logistics.personalInventory",
      },
      { value: "inv-3", label: "Depot", category: "Crew" },
      { value: "inv-4", label: "Vault", category: "Crew" },
    ]);
  });

  it("files each inventory through its owner", async () => {
    const { targetFor } = await mount();

    expect(targetFor("inv-1")).toEqual({ kind: "hangar", slug: "cargo-hold" });
    expect(targetFor("inv-2")).toEqual({
      kind: "vehicle",
      vehicleId: "ironclad",
    });
    expect(targetFor("inv-3")).toEqual({
      kind: "fleet",
      fleetSlug: "crew",
      slug: "depot",
    });
  });

  // The select sorts each group by label; the first option has to be the one
  // it shows on top, since that is the one preselected.
  it("sorts each group by label", async () => {
    api.hangar = {
      items: [
        { id: "inv-1", slug: "zeta", name: "Zeta Hold" },
        { id: "inv-2", slug: "alpha", name: "Alpha Store" },
      ],
    };

    const { options } = await mount();

    expect(options.value.map((option) => option.label)).toEqual([
      "Alpha Store",
      "Zeta Hold",
      "Depot",
      "Vault",
    ]);
  });

  it("asks only the fleets the reader may deposit into", async () => {
    await mount();

    expect(api.inventoryRequests).toEqual(["crew"]);
  });

  // A fleet without logistics or the subscription refuses; the rest stand.
  it("leaves out a fleet that refuses", async () => {
    api.inventories = { crew: new Error("403") };

    const { options, empty } = await mount();

    expect(options.value.map((option) => option.value)).toEqual([
      "inv-1",
      "inv-2",
    ]);
    expect(empty.value).toBe(false);
  });

  it("is empty when every list answered with nothing", async () => {
    api.hangar = { items: [] };
    api.inventories = { crew: { items: [] } };

    const { empty } = await mount();

    expect(empty.value).toBe(true);
  });

  // A failed request says nothing about whether there are any.
  it("does not claim there are none when the own list failed", async () => {
    api.hangar = new Error("500");
    api.inventories = { crew: { items: [] } };

    const { options, empty } = await mount();

    expect(options.value).toEqual([]);
    expect(empty.value).toBe(false);
  });

  it("does not claim there are none when a membership lookup failed", async () => {
    api.hangar = { items: [] };
    api.memberships = { ...api.memberships, crew: new Error("500") };

    const { empty } = await mount();

    expect(empty.value).toBe(false);
  });

  it("asks no fleet without fleet logistics", async () => {
    api.features = ["hangar_inventories"];

    const { options } = await mount();

    expect(api.inventoryRequests).toEqual([]);
    expect(options.value).toHaveLength(2);
  });
});
