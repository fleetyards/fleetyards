import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

/*
 * The save queue and the refetch reconciliation, with the sort request and the
 * groups prop under the test's control. The e2e specs cover the same paths
 * against a real server, but cannot order a refetch around a save: the test
 * environment's cable adapter never reaches the browser.
 */

type Deferred = {
  sorting: string[];
  resolve: () => void;
  reject: () => void;
};

const requests: Deferred[] = [];

const mutateAsync = vi.fn(
  ({ data }: { data: { sorting: string[] } }) =>
    new Promise<void>((resolve, reject) => {
      requests.push({
        sorting: data.sorting,
        resolve,
        reject: () => reject(new Error("Sort failed")),
      });
    }),
);

const invalidateQueries = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useHangarGroupSort: () => ({ mutateAsync }),
}));

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@tanstack/vue-query")>()),
  useQueryClient: () => ({ invalidateQueries }),
}));

// jsdom reads as a phone to the breakpoint check; the row, not the dropdown.
vi.mock("@/shared/composables/useMobile", async () => {
  const { ref } = await import("vue");
  return { useMobile: () => ref(false) };
});

// jsdom has no drag and drop to offer; the keyboard route is what this drives.
vi.mock("sortablejs", () => ({
  default: { create: () => ({ destroy: () => undefined }) },
}));

const group = (id: string, name = id) =>
  ({ id, slug: id, name, color: "#fff" }) as never;

const A = group("a", "Alpha");
const B = group("b", "Bravo");
const C = group("c", "Charlie");

let wrapper: VueWrapper | undefined;

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { hangarGroups: [A, B, C], editable: true },
    attachTo: document.body,
  });

  await wrapper.find("[data-test='group-labels-edit']").trigger("click");

  return wrapper;
};

const names = () =>
  wrapper!.findAll("[data-test='chip'] .chip__label").map((el) => el.text());

// Presses an arrow on the named chip's grip.
const move = async (name: string, key: "ArrowLeft" | "ArrowRight") => {
  const chip = wrapper!
    .findAll("[data-test='chip']")
    .find((el) => el.text().includes(name));

  await chip!.find("[data-test='chip-handle']").trigger("keydown", { key });
  await flushPromises();
};

beforeEach(() => {
  requests.length = 0;
  mutateAsync.mockClear();
  invalidateQueries.mockClear();
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("HangarGroupLabels save queue", () => {
  it("keeps one request in flight and sends only the latest order", async () => {
    await mount();

    await move("Bravo", "ArrowLeft");
    await move("Charlie", "ArrowLeft");
    await move("Charlie", "ArrowLeft");

    expect(mutateAsync).toHaveBeenCalledTimes(1);
    expect(requests[0].sorting).toEqual(["b", "a", "c"]);

    requests[0].resolve();
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledTimes(2);
    expect(requests[1].sorting).toEqual(["c", "b", "a"]);
  });

  it("takes a refetch's contents mid-save, in the order on screen", async () => {
    await mount();

    await move("Bravo", "ArrowLeft");

    // A refetch the first write broadcast: still the old order, one rename,
    // one group added elsewhere.
    await wrapper!.setProps({
      hangarGroups: [A, group("b", "Bravo 2"), C, group("d", "Delta")],
    });

    expect(names()).toEqual(["Bravo 2", "Alpha", "Charlie", "Delta"]);
  });

  it("falls back to the last saved order when the last request fails", async () => {
    await mount();

    await move("Bravo", "ArrowLeft");
    await move("Bravo", "ArrowRight");

    requests[0].resolve();
    await flushPromises();
    requests[1].reject();
    await flushPromises();

    // The server holds the first request's order; the prop still predates it.
    expect(names()).toEqual(["Bravo", "Alpha", "Charlie"]);

    // Only the order this tab knows of. Another tab may have reordered while
    // the request failed, so the server's order is fetched again as well.
    expect(invalidateQueries).toHaveBeenCalledTimes(1);
  });

  it("invalidates the groups once the queue settles", async () => {
    await mount();

    await move("Bravo", "ArrowLeft");
    await move("Charlie", "ArrowLeft");

    requests[0].resolve();
    await flushPromises();

    // Not between the two requests: a refetch then would read the first order.
    expect(invalidateQueries).not.toHaveBeenCalled();

    requests[1].resolve();
    await flushPromises();

    expect(invalidateQueries).toHaveBeenCalledTimes(1);
    expect(invalidateQueries).toHaveBeenCalledWith({
      queryKey: ["hangar", "groups"],
    });
  });

  it("takes the server's order again once nothing is saving", async () => {
    await mount();

    await move("Bravo", "ArrowLeft");
    requests[0].resolve();
    await flushPromises();

    await wrapper!.setProps({ hangarGroups: [C, A, B] });

    expect(names()).toEqual(["Charlie", "Alpha", "Bravo"]);
  });
});
