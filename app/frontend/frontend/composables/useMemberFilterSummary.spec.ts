import { describe, expect, it, vi } from "vitest";
import {
  createRouter,
  createMemoryHistory,
  type LocationQuery,
} from "vue-router";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { useMemberFilterSummary } from "./useMemberFilterSummary";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useFleetRoles: () => ({
    data: ref([{ slug: "officer", name: "Officer" }]),
  }),
}));

const summarize = async (
  query: LocationQuery,
  applied: (query: LocationQuery) => LocationQuery = (value) => value,
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/fleets/spro/members", component: { template: "<div />" } },
    ],
  });
  await router.push({ path: "/fleets/spro/members", query });

  let summary: ReturnType<typeof useMemberFilterSummary> | undefined;
  const component = defineComponent({
    setup() {
      const route = useRoute();
      summary = useMemberFilterSummary("spro", () => applied(route.query));
      return () => h("div");
    },
  });
  const wrapper = await mountWithDefaults(component, { plugins: [router] });

  return { router, wrapper, activeFilters: summary!.activeFilters };
};

describe("useMemberFilterSummary", () => {
  it("shows a verification filter that arrived with a link", async () => {
    const { activeFilters, wrapper } = await summarize({
      verifiedEq: "false",
      squadronSlugIn: ["operations"],
    });

    expect(activeFilters.value.map((item) => item.label)).toEqual([
      "labels.filters.fleets.members.verified: labels.filters.fleets.members.verifiedNo",
    ]);
    wrapper.unmount();
  });

  it("names roles and states, and labels a ticked box by itself", async () => {
    const { activeFilters, wrapper } = await summarize({
      roleIn: ["officer"],
      stateIn: ["invited"],
      withoutDiscord: "true",
      acceptedAtGteq: "2026-01-01",
    });

    expect(activeFilters.value.map((item) => item.label)).toEqual([
      "labels.filters.fleets.members.role: Officer",
      "labels.filters.fleets.members.state: labels.fleet.members.invited",
      "labels.filters.fleets.members.withoutDiscord",
      "labels.fleet.members.joined: ≥ 2026-01-01",
    ]);
    wrapper.unmount();
  });

  it("names a key the form has no field for, and a box left unticked by its value", async () => {
    const { activeFilters, wrapper } = await summarize({
      nicknameCont: "kudl",
      withoutDiscord: "false",
    });

    expect(activeFilters.value.map((item) => item.label)).toEqual([
      "Nickname: kudl",
      "labels.filters.fleets.members.withoutDiscord: labels.false",
    ]);
    wrapper.unmount();
  });

  it("removes a filter nested under q", async () => {
    const { activeFilters, router, wrapper } = await summarize({
      q: { verifiedEq: "false" },
    } as unknown as LocationQuery);

    await activeFilters.value[0].remove();

    expect(router.currentRoute.value.query).toEqual({});
    wrapper.unmount();
  });

  it("leaves out the search and the squadron, which have controls of their own", async () => {
    const { activeFilters, wrapper } = await summarize({
      searchCont: "kudl",
      squadronSlugIn: ["operations"],
      view: "invites",
    });

    expect(activeFilters.value).toEqual([]);
    wrapper.unmount();
  });

  it("shows only the filters the list is asked", async () => {
    const { activeFilters, wrapper } = await summarize(
      { verifiedEq: "false", stateIn: ["invited"] },
      ({ verifiedEq: _, ...rest }) => rest,
    );

    expect(activeFilters.value.map((item) => item.id)).toEqual(["stateIn"]);
    wrapper.unmount();
  });

  it("removes a filter and keeps the squadron, the view and the page size", async () => {
    const { activeFilters, router, wrapper } = await summarize({
      verifiedEq: "false",
      squadronSlugIn: ["operations"],
      view: "invites",
      perPage: "48",
      page: "2",
    });

    await activeFilters.value[0].remove();

    expect(router.currentRoute.value.query).toEqual({
      squadronSlugIn: ["operations"],
      view: "invites",
      perPage: "48",
    });
    wrapper.unmount();
  });
});
