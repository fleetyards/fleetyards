import { createRouter, createMemoryHistory } from "vue-router";
import { describe, expect, it } from "vitest";
import { routes } from "./routes";

/*
 * The friends list moved under settings. Notifications written before it did
 * carry /friends as their link and those rows outlive the move, as do the tab
 * links somebody was sent -- a redirect that dropped the tab would answer all
 * four of them with the accepted list.
 */
describe("frontend routes", () => {
  const router = createRouter({ history: createMemoryHistory(), routes });

  // `resolve` stops at the record that matched; only a navigation follows the
  // redirect it holds, which is the thing under test.
  it.each([
    ["/friends/", "settings-friends"],
    ["/friends/incoming/", "settings-friends-incoming"],
    ["/friends/outgoing/", "settings-friends-outgoing"],
    ["/friends/ignored/", "settings-friends-ignored"],
  ])("sends %s to %s", async (path, name) => {
    await router.push(path);

    expect(router.currentRoute.value.name).toBe(name);
  });

  // Every list is its own page: a tab is somewhere a reader can be sent and
  // somewhere a reload lands, which is also what lets a notification point at
  // the one list its request is in.
  it.each([
    ["/settings/friends/", "settings-friends"],
    ["/settings/friends/incoming/", "settings-friends-incoming"],
    ["/settings/friends/outgoing/", "settings-friends-outgoing"],
    ["/settings/friends/ignored/", "settings-friends-ignored"],
  ])("opens %s as %s", async (path, name) => {
    await router.push(path);

    expect(router.currentRoute.value.name).toBe(name);
  });

  it("keeps what the link carried", async () => {
    await router.push("/friends/incoming/?page=2");

    expect(router.currentRoute.value.query).toEqual({ page: "2" });
  });
});
