import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { useForm } from "vee-validate";
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

describe("FormInput standalone", () => {
  // A field inside a form that is not one of the form's own -- the address
  // box of an editor's link button -- must not end up in what the form saves.
  const mountInForm = async (standalone: boolean) => {
    let values: Record<string, unknown> = {};

    const Host = defineComponent({
      setup() {
        const form = useForm({ initialValues: { name: "Maru" } });
        values = form.values;

        return () =>
          h(Component, {
            name: "linkUrl",
            modelValue: "https://x.test",
            standalone,
          });
      },
    });

    await mountWithDefaults(Host);

    return values;
  };

  it("keeps its value out of the surrounding form", async () => {
    expect(await mountInForm(true)).toEqual({ name: "Maru" });
  });

  it("is one of the form's values by default", async () => {
    expect(await mountInForm(false)).toHaveProperty(
      "linkUrl",
      "https://x.test",
    );
  });
});
