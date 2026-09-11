import { describe, it, expect, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useScDataSourceStore } from "./scDataSource";

const live = { environment: "live", version: "1.0.0", default: true };
const ptu = { environment: "ptu", version: "1.1.0", default: false };

describe("scDataSource store", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("selects the server's default until somebody chooses", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live, ptu]);

    expect(store.selected).toEqual(live);
    expect(store.requestParam).toBeUndefined();
  });

  // Nothing is sent for the default, so a reader who has not chosen sends
  // exactly what it always sent.
  it("sends no parameter for the default and the environment otherwise", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live, ptu]);

    store.select("ptu");
    expect(store.requestParam).toBe("ptu");

    store.select(undefined);
    expect(store.requestParam).toBeUndefined();
  });

  it("offers no switch when there is nothing to switch to", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live]);

    expect(store.hasChoice).toBe(false);

    store.setAvailable([live, ptu]);
    expect(store.hasChoice).toBe(true);
  });

  // The switch has two states and stays that way: a second preview channel
  // makes it offer the newer of them rather than turn into a list.
  it("offers the newest preview build", () => {
    const store = useScDataSourceStore();
    store.setAvailable([
      live,
      { environment: "eptu", version: "1.9.0", default: false },
      { environment: "ptu", version: "1.10.0", default: false },
    ]);

    expect(store.previewSource?.environment).toBe("ptu");
  });

  it("has no preview when the server offers the default alone", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live]);

    expect(store.previewSource).toBeUndefined();
  });

  // A source that has gone away must not stay selected, or every request would
  // carry a parameter the server ignores while the switch claims otherwise.
  it("drops a selection the server stopped offering", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live, ptu]);
    store.select("ptu");

    store.setAvailable([live]);

    expect(store.environment).toBeUndefined();
    expect(store.requestParam).toBeUndefined();
    expect(store.selected).toEqual(live);
  });

  it("keeps a selection the server still offers", () => {
    const store = useScDataSourceStore();
    store.setAvailable([live, ptu]);
    store.select("ptu");

    store.setAvailable([live, ptu]);

    expect(store.requestParam).toBe("ptu");
  });

  it("has nothing selected before the server has answered", () => {
    const store = useScDataSourceStore();

    expect(store.selected).toBeUndefined();
    expect(store.requestParam).toBeUndefined();
    expect(store.hasChoice).toBe(false);
  });

  // The boot requests go out before the list can arrive, so a rehydrated choice
  // has to answer on its own -- otherwise the first paint is the default's data
  // under the other build's label.
  it("sends a rehydrated choice before the list has arrived", () => {
    const store = useScDataSourceStore();
    store.select("ptu");

    expect(store.available).toEqual([]);
    expect(store.requestParam).toBe("ptu");
  });

  it("still sends nothing before the list arrives when nothing was chosen", () => {
    const store = useScDataSourceStore();

    expect(store.requestParam).toBeUndefined();
  });

  it("stops sending a rehydrated choice the server does not offer", () => {
    const store = useScDataSourceStore();
    store.select("ptu");

    store.setAvailable([live]);

    expect(store.requestParam).toBeUndefined();
  });
});
