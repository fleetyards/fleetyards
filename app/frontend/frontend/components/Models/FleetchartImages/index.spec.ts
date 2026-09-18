import { describe, it, expect, vi, beforeEach } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { MediaFile, Model, ModelMedia } from "@/services/fyApi";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
  }),
}));

import FleetchartImages from "./index.vue";

// jsdom reports a width of 0, which reads as a phone and picks the medium
// variant of every image. The views are a desktop grid, so the specs state the
// width they are asserting against.
const setViewportWidth = (value: number) => {
  Object.defineProperty(document.documentElement, "clientWidth", {
    value,
    configurable: true,
  });
};

beforeEach(() => {
  setViewportWidth(1400);
});

const file = (name: string): MediaFile =>
  ({
    name,
    url: `https://cdn.test/${name}`,
    mediumUrl: `https://cdn.test/${name}?medium`,
    largeUrl: `https://cdn.test/${name}?large`,
  }) as MediaFile;

const RETRACTED_VIEWS: Partial<ModelMedia> = {
  angledView: file("angled"),
  topView: file("top"),
  frontView: file("front"),
  sideView: file("side"),
};

const model = (media: Partial<ModelMedia>): Model =>
  ({
    media: { ...media },
    metrics: { length: 30, beam: 20, height: 10, fleetchartOffsetLength: 32 },
  }) as Model;

const mountViews = (media: Partial<ModelMedia>, state?: ModelStateEnum) =>
  mountWithDefaults<typeof FleetchartImages>(FleetchartImages, {
    props: { model: model(media), state },
  });

describe("the state switch over the views", () => {
  it("is absent for a model that only has the retracted set", async () => {
    const wrapper = await mountViews(RETRACTED_VIEWS);

    expect(wrapper.find('[data-test="model-states"]').exists()).toBe(false);
  });

  it("offers one segment per state the model carries", async () => {
    const wrapper = await mountViews({
      ...RETRACTED_VIEWS,
      landedTopView: file("landed-top"),
    });

    expect(
      wrapper
        .findAll('[data-test="model-states"] button')
        .map((btn) => btn.text()),
    ).toEqual(["labels.model.state.retracted", "labels.model.state.landed"]);
  });

  it("asks its parent for the state rather than holding one", async () => {
    const wrapper = await mountViews({
      ...RETRACTED_VIEWS,
      landedTopView: file("landed-top"),
    });

    await wrapper.find('[data-test="model-state-landed"]').trigger("click");

    expect(wrapper.emitted("update:state")).toEqual([[ModelStateEnum.LANDED]]);
  });
});

describe("the views themselves", () => {
  const sources = (wrapper: Awaited<ReturnType<typeof mountViews>>) =>
    wrapper.findAll("img").map((img) => img.attributes("src"));

  it("draws the retracted set by default", async () => {
    const wrapper = await mountViews(RETRACTED_VIEWS);

    expect(sources(wrapper)).toEqual([
      "https://cdn.test/angled?large",
      "https://cdn.test/top?large",
      "https://cdn.test/front?large",
      "https://cdn.test/side?large",
    ]);
  });

  it("draws the chosen state, and the retracted image for a view it lacks", async () => {
    const wrapper = await mountViews(
      {
        ...RETRACTED_VIEWS,
        landedAngledView: file("landed-angled"),
        landedTopView: file("landed-top"),
        landedSideView: file("landed-side"),
      },
      ModelStateEnum.LANDED,
    );

    expect(sources(wrapper)).toEqual([
      "https://cdn.test/landed-angled?large",
      "https://cdn.test/landed-top?large",
      // No landed front view uploaded, so the retracted one stands in.
      "https://cdn.test/front?large",
      "https://cdn.test/landed-side?large",
    ]);
  });

  it("takes the medium variant on a phone", async () => {
    setViewportWidth(500);

    const wrapper = await mountViews(RETRACTED_VIEWS);

    expect(sources(wrapper)[0]).toBe("https://cdn.test/angled?medium");
  });

  it("prefers the coloured image where the state has one", async () => {
    const wrapper = await mountViews(
      {
        ...RETRACTED_VIEWS,
        landedTopView: file("landed-top"),
        landedTopViewColored: file("landed-top-colored"),
      },
      ModelStateEnum.LANDED,
    );

    expect(sources(wrapper)[1]).toBe(
      "https://cdn.test/landed-top-colored?large",
    );
  });
});

describe("while the next set of images is loading", () => {
  const settleAll = async (wrapper: Awaited<ReturnType<typeof mountViews>>) => {
    for (const img of wrapper.findAll("img")) {
      await img.trigger("load");
    }
  };

  it("holds the loader until every view has reported", async () => {
    const wrapper = await mountViews(RETRACTED_VIEWS);

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(true);

    await wrapper.findAll("img")[0].trigger("load");

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(true);

    await settleAll(wrapper);

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(false);
  });

  it("comes back when the state switches to images not seen yet", async () => {
    const wrapper = await mountViews({
      ...RETRACTED_VIEWS,
      landedTopView: file("landed-top"),
    });
    await settleAll(wrapper);

    await wrapper.setProps({ state: ModelStateEnum.LANDED });

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(true);
  });

  // Three of the four views fall back to the retracted image, which the browser
  // has already: only the one that actually changed is waited on.
  it("does not wait again on an image the switch reuses", async () => {
    const wrapper = await mountViews({
      ...RETRACTED_VIEWS,
      landedTopView: file("landed-top"),
    });
    await settleAll(wrapper);

    await wrapper.setProps({ state: ModelStateEnum.LANDED });
    await wrapper
      .findAll("img")
      .find((img) => img.attributes("src")?.includes("landed-top"))
      ?.trigger("load");

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(false);
  });

  it("settles a view that fails rather than waiting forever", async () => {
    const wrapper = await mountViews(RETRACTED_VIEWS);

    for (const img of wrapper.findAll("img")) {
      await img.trigger("error");
    }

    expect(wrapper.find('[data-test="loader"]').exists()).toBe(false);
  });
});
