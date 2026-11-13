import { describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import { useForm } from "vee-validate";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  modelFocusFilters: vi.fn(async () => [
    { value: "dropship", label: "Dropship" },
    { value: "carrier", label: "Carrier" },
  ]),
}));

describe("ModelFocusSelect", () => {
  it("settles after a pick when bound to a vee-validate field", async () => {
    let formValues: () => Record<string, unknown> = () => ({});

    const Form = defineComponent({
      setup() {
        const { defineField, values } = useForm({
          initialValues: { foci: ["dropship"] },
        });
        const [foci, fociProps] = defineField("foci");
        formValues = () => values;

        return () =>
          h(Component, {
            ...fociProps.value,
            name: "foci",
            multiple: true,
            modelValue: foci.value,
            "onUpdate:modelValue": (value: string | string[] | undefined) => {
              foci.value = [value ?? []].flat();
            },
          });
      },
    });

    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const wrapper = await mountWithDefaults(Form);
    await flushPromises();

    const select = wrapper.findComponent(Component);
    const emitted = () => select.emitted("update:modelValue")?.length ?? 0;
    const before = emitted();

    wrapper
      .findComponent(BaseSelect)
      .vm.$emit("update:modelValue", ["dropship", "carrier"]);
    for (let tick = 0; tick < 10; tick += 1) await nextTick();
    await flushPromises();

    expect(formValues().foci).toEqual(["dropship", "carrier"]);
    expect(emitted() - before).toBeLessThanOrEqual(1);
    expect(
      warn.mock.calls.some((call) =>
        String(call[0]).includes("Maximum recursive updates"),
      ),
    ).toBe(false);

    warn.mockRestore();
  });
});
