import { describe, expect, it, vi, beforeEach } from "vitest";
import { ref, toValue } from "vue";
import { flushPromises } from "@vue/test-utils";
import {
  modelsFleetchartViews,
  type FleetchartViewsList,
} from "@/services/fyApi";
import { useFleetchartViews } from "./useFleetchartViews";

vi.mock("@/services/fyApi", () => ({
  modelsFleetchartViews: vi.fn(),
}));

const fetchViews = vi.mocked(modelsFleetchartViews);

const slugsOf = (params: Parameters<typeof modelsFleetchartViews>[0]) =>
  toValue(params)?.q?.slugIn ?? [];

describe("useFleetchartViews", () => {
  beforeEach(() => {
    fetchViews.mockReset();
    fetchViews.mockImplementation(
      async (params) =>
        slugsOf(params).map((slug) => ({
          slug,
          media: { topView: { url: `${slug}.png` } },
        })) as FleetchartViewsList,
    );
  });

  it("asks for each model once, however many ships fly it", async () => {
    const { viewsFor } = useFleetchartViews(
      ["aurora", "aurora", "carrack"],
      true,
    );

    await flushPromises();

    expect(fetchViews).toHaveBeenCalledTimes(1);
    expect(slugsOf(fetchViews.mock.calls[0][0])).toEqual(["aurora", "carrack"]);
    expect(viewsFor("carrack")?.topView?.url).toBe("carrack.png");
  });

  it("splits a whole fleet's models across requests", async () => {
    const slugs = Array.from({ length: 250 }, (_, index) => `ship-${index}`);
    const { viewsFor } = useFleetchartViews(slugs, true);

    await flushPromises();

    expect(
      fetchViews.mock.calls.map((call) => slugsOf(call[0]).length),
    ).toEqual([100, 100, 50]);
    expect(viewsFor("ship-249")).toBeDefined();
  });

  it("asks for nothing while the chart is closed", async () => {
    useFleetchartViews(["aurora"], false);

    await flushPromises();

    expect(fetchViews).not.toHaveBeenCalled();
  });

  it("keeps the chunks that arrived when another fails", async () => {
    const slugs = Array.from({ length: 150 }, (_, index) => `ship-${index}`);

    fetchViews.mockImplementationOnce(async () => {
      throw new Error("timeout");
    });

    const { viewsFor } = useFleetchartViews(slugs, true);

    await flushPromises();

    expect(viewsFor("ship-0")).toBeUndefined();
    expect(viewsFor("ship-149")?.topView?.url).toBe("ship-149.png");
  });

  it("does not ask again for a model that has no views", async () => {
    fetchViews.mockImplementation(async () => []);
    const slugs = ref(["aurora"]);

    useFleetchartViews(slugs, true);
    await flushPromises();

    slugs.value = ["aurora", "carrack"];
    await flushPromises();

    expect(fetchViews.mock.calls.map((call) => slugsOf(call[0]))).toEqual([
      ["aurora"],
      ["carrack"],
    ]);
  });
});
