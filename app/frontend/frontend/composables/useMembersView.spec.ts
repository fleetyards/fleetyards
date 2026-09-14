import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const route = ref<{ query: Record<string, unknown> }>({ query: {} });

vi.mock("vue-router", () => ({
  useRoute: () => route.value,
}));

const { useMembersView } = await import("./useMembersView");

describe("useMembersView", () => {
  beforeEach(() => {
    route.value = { query: {} };
  });

  it("reads the open view from the query", () => {
    route.value = { query: { view: "invites" } };

    expect(useMembersView(true).view.value).toBe("invites");
  });

  // The invites are a list not everybody in a fleet may read.
  it("falls back to the roster for a reader who may not read the invites", () => {
    route.value = { query: { view: "invites" } };

    expect(useMembersView(false).view.value).toBe("members");
  });

  it("falls back to the roster for a view that is not one", () => {
    route.value = { query: { view: "everybody" } };

    expect(useMembersView(true).view.value).toBe("members");
  });

  // The name searched for, the roles and the sort are the same question of
  // either list, so switching between them is no reason to lose the answer.
  it("carries what both lists share, and drops the page number", () => {
    route.value = {
      query: {
        usernameCont: "mo",
        roleIn: ["admin"],
        sorts: "username",
        page: "3",
      },
    };

    expect(useMembersView(true).viewQuery("invites")).toEqual({
      usernameCont: "mo",
      roleIn: ["admin"],
      sorts: "username",
      view: "invites",
    });
  });

  it("leaves the roster's own filters behind on the way to the invites", () => {
    route.value = {
      query: {
        usernameCont: "mo",
        acceptedAtGteq: "2026-01-01",
        acceptedAtLteq: "2026-02-01",
      },
    };

    expect(useMembersView(true).viewQuery("invites")).toEqual({
      usernameCont: "mo",
      view: "invites",
    });
  });

  it("leaves the invites' own filters behind on the way back", () => {
    route.value = {
      query: {
        view: "invites",
        usernameCont: "mo",
        stateIn: ["declined"],
        invitedAtGteq: "2026-01-01",
        requestedAtLteq: "2026-02-01",
        declinedAtGteq: "2026-03-01",
      },
    };

    expect(useMembersView(true).viewQuery("members")).toEqual({
      usernameCont: "mo",
    });
  });

  /*
   * A query nobody built here: an old link, or the 301 off the invite list's
   * former path, can arrive carrying the roster's filters. Applied, they would
   * narrow the invites from a field that list never renders.
   */
  it("keeps the other list's filters out of the query the API is asked", () => {
    route.value = { query: { view: "invites" } };

    const { scopedFilters } = useMembersView(true);

    expect(
      scopedFilters({
        usernameCont: "mo",
        acceptedAtGteq: "2026-01-01",
        stateIn: ["invited"],
      }),
    ).toEqual({ usernameCont: "mo", stateIn: ["invited"] });
  });

  it("leaves the open list's own filters alone", () => {
    const { scopedFilters } = useMembersView(true);

    expect(
      scopedFilters({ acceptedAtGteq: "2026-01-01", stateIn: ["invited"] }),
    ).toEqual({ acceptedAtGteq: "2026-01-01" });
  });
});
