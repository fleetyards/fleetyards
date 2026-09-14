import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const route = ref<{ name: string; params: object; query: object }>({
  name: "friends",
  params: {},
  query: {},
});
const push = vi.fn();

vi.mock("vue-router", () => ({
  useRoute: () => route.value,
  useRouter: () => ({ push }),
}));

const { useRelationshipTab } = await import("./useRelationshipTab");

const ROUTES = {
  accepted: "friends",
  incoming: "friends-incoming",
  outgoing: "friends-outgoing",
  ignored: "friends-ignored",
};

describe("useRelationshipTab", () => {
  beforeEach(() => {
    push.mockClear();
    route.value = { name: "friends", params: {}, query: {} };
  });

  it("reads the open tab from the route", () => {
    route.value = { name: "friends-outgoing", params: {}, query: {} };

    expect(useRelationshipTab(ROUTES).tab.value).toBe("outgoing");
  });

  it("falls back to the accepted list for an unknown route", () => {
    route.value = { name: "something-else", params: {}, query: {} };

    expect(useRelationshipTab(ROUTES).tab.value).toBe("accepted");
  });

  // The tab is also the query, so these two have to stay in step with the
  // routes rather than being decided separately at each call site.
  it("turns each tab into the state and direction it means", () => {
    const cases = {
      friends: ["accepted", undefined],
      "friends-incoming": ["pending", "incoming"],
      "friends-outgoing": ["pending", "outgoing"],
      "friends-ignored": ["ignored", undefined],
    };

    Object.entries(cases).forEach(([name, [state, direction]]) => {
      route.value = { name, params: {}, query: {} };

      const tab = useRelationshipTab(ROUTES);

      expect([tab.state.value, tab.direction.value]).toEqual([
        state,
        direction,
      ]);
    });
  });

  it("navigates when the tab changes, and drops the page number", () => {
    route.value = {
      name: "friends",
      params: { slug: "crew" },
      query: { page: "3", q: "x" },
    };

    useRelationshipTab(ROUTES).tab.value = "incoming";

    expect(push).toHaveBeenCalledWith({
      name: "friends-incoming",
      params: { slug: "crew" },
      query: { q: "x" },
    });
  });

  it("does not navigate to the tab that is already open", () => {
    useRelationshipTab(ROUTES).tab.value = "accepted";

    expect(push).not.toHaveBeenCalled();
  });

  // Never first: an ignored request is one the reader turned away, and putting
  // it back in front of them by default would undo the point of ignoring it.
  it("never offers ignored as the default", () => {
    const { tabs, tab } = useRelationshipTab(ROUTES);

    expect(tabs[0]).toBe("accepted");
    expect(tabs.at(-1)).toBe("ignored");
    expect(tab.value).not.toBe("ignored");
  });
});
