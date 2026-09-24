import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mountTextarea = (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults(Component, { props });

const counter = (wrapper: Awaited<ReturnType<typeof mountTextarea>>) =>
  wrapper.find('[data-test="counter-description"]');

/*
 * The count is the API's limit made visible while the text is being written,
 * so it has to agree with the validator about what a character is -- and about
 * when the limit has been passed, which is the only thing the colour says.
 */
describe("FormTextarea", () => {
  it("draws no counter without a limit", async () => {
    const wrapper = await mountTextarea({ name: "description" });

    expect(counter(wrapper).exists()).toBe(false);
  });

  it("counts what is in the field against the limit", async () => {
    const wrapper = await mountTextarea({
      name: "description",
      maxlength: 255,
      modelValue: "A crew",
    });

    expect(counter(wrapper).text()).toBe("6 / 255");
  });

  // Ruby counts code points; JavaScript's `.length` counts UTF-16 units, so a
  // naive count would read 2 for one rocket and disagree with the server.
  it("counts an astral character once", async () => {
    const wrapper = await mountTextarea({
      name: "description",
      maxlength: 255,
      modelValue: "🚀",
    });

    expect(counter(wrapper).text()).toBe("1 / 255");
  });

  it("marks the count once the limit is passed", async () => {
    const wrapper = await mountTextarea({
      name: "description",
      maxlength: 3,
      modelValue: "four",
    });

    expect(counter(wrapper).classes()).toContain(
      "base-textarea__counter--over",
    );
  });

  it("leaves it unmarked at exactly the limit", async () => {
    const wrapper = await mountTextarea({
      name: "description",
      maxlength: 4,
      modelValue: "four",
    });

    expect(counter(wrapper).classes()).not.toContain(
      "base-textarea__counter--over",
    );
  });
});
