import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mountInput = (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults(Component, { props });

const placeholder = (wrapper: Awaited<ReturnType<typeof mountInput>>) =>
  wrapper.find("input").attributes("placeholder");

/*
 * A name is free-form -- call sites build them per row (`container-${size}`) --
 * so most of them have no `placeholders.*` entry. i18n-js answers a missing key
 * with `[missing "en.placeholders.container-1" translation]`, and unguarded that
 * string was rendered into the field as its placeholder.
 */
describe("FormInput", () => {
  it("stays empty when the name has no placeholder of its own", async () => {
    const wrapper = await mountInput({ name: "container-1" });

    expect(placeholder(wrapper)).toBeUndefined();
  });

  it("uses the placeholder the name is translated to", async () => {
    const wrapper = await mountInput({ name: "username" });

    expect(placeholder(wrapper)).toBe("Username");
  });

  it("prefers an explicitly passed placeholder", async () => {
    const wrapper = await mountInput({
      name: "username",
      placeholder: "Your handle",
    });

    expect(placeholder(wrapper)).toBe("Your handle");
  });

  it("falls back to the translation key over the name", async () => {
    const wrapper = await mountInput({
      name: "discord",
      translationKey: "nope.missing",
    });

    expect(placeholder(wrapper)).toBeUndefined();
  });
});
