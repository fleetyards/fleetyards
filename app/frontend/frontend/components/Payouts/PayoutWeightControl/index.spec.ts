import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import Component from "./index.vue";

// A wrapper left mounted keeps its pinia store alive, which makes the next
// test assert against a second store and pass either way.
const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (props: Record<string, unknown> = {}) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { weight: "1.0", ...props },
  });
  wrappers.push(wrapper);
  return wrapper;
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("PayoutWeightControl", () => {
  it("marks the preset the participant is on", async () => {
    const wrapper = await mount({ weight: "0.5" });

    expect(wrapper.find("[data-test='payout-weight-0.5']").classes()).toContain(
      "active",
    );
  });

  // "0.50" and "0.5" are the same share, and the API may answer with either.
  it("matches a preset regardless of how the decimal is written", async () => {
    const wrapper = await mount({ weight: "0.50" });

    expect(wrapper.find("[data-test='payout-weight-0.5']").classes()).toContain(
      "active",
    );
  });

  it("emits the picked preset", async () => {
    const wrapper = await mount({ weight: "1.0" });

    await wrapper.find("[data-test='payout-weight-0.25']").trigger("click");

    expect(wrapper.emitted("update")?.[0]).toEqual(["0.25"]);
  });

  // Nothing changed, so nothing should be sent -- a request per click on the
  // share somebody is already on would churn the ledger for everyone watching.
  it("stays quiet when the picked preset is the current one", async () => {
    const wrapper = await mount({ weight: "0.5" });

    await wrapper.find("[data-test='payout-weight-0.5']").trigger("click");

    expect(wrapper.emitted("update")).toBeUndefined();
  });

  it("only marks a reduced share", async () => {
    const full = await mount({ weight: "1.0" });
    const reduced = await mount({ weight: "0.5" });

    expect(full.find(".payout-weight__preset--reduced").exists()).toBe(false);
    expect(reduced.find(".payout-weight__preset--reduced").exists()).toBe(true);
  });

  // A weight no preset can express has to be visible without being hunted for.
  it("opens the field for a weight no preset can express", async () => {
    const wrapper = await mount({ weight: "0.6" });

    expect(wrapper.find("[data-test='payout-weight-field']").exists()).toBe(
      true,
    );
    expect(
      wrapper.find("[data-test='payout-weight-custom']").classes(),
    ).toContain("active");
  });

  it("keeps the field closed on a preset weight", async () => {
    const wrapper = await mount({ weight: "1.0" });

    expect(wrapper.find("[data-test='payout-weight-field']").exists()).toBe(
      false,
    );
  });

  it("emits a typed weight to two decimals", async () => {
    const wrapper = await mount({ weight: "0.6" });

    const field = wrapper.find("[data-test='payout-weight-field']");
    await field.setValue("1.25");
    await field.trigger("change");

    expect(wrapper.emitted("update")?.[0]).toEqual(["1.25"]);
  });

  // The API refuses these too; declining here saves a round trip and a toast.
  it.each(["0", "-1", "abc"])(
    "refuses %s and resets the field",
    async (value) => {
      const wrapper = await mount({ weight: "0.6" });

      const field = wrapper.find("[data-test='payout-weight-field']");
      await field.setValue(value);
      await field.trigger("change");

      expect(wrapper.emitted("update")).toBeUndefined();
    },
  );

  it("sends nothing while disabled", async () => {
    const wrapper = await mount({ weight: "1.0", disabled: true });

    await wrapper.find("[data-test='payout-weight-0.5']").trigger("click");

    expect(wrapper.emitted("update")).toBeUndefined();
  });
});
