import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import AddShips from "./index.vue";

const models = ref<{ items: unknown[] }>({ items: [] });
const views = vi.fn();
const lastParams = ref<{ q: { searchCont?: string } }>();

vi.mock("@/services/fyApi", () => ({
  useModels: (params: { value: { q: { searchCont?: string } } }) => {
    watchEffect(() => {
      lastParams.value = params.value;
    });

    return { data: models, isFetching: ref(false) };
  },
  modelsFleetchartViews: (...args: unknown[]) => views(...args),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const ship = (slug: string) => ({
  id: slug,
  slug,
  name: slug,
  manufacturer: { code: "RSI" },
  metrics: { fleetchartOffsetLength: 20 },
  media: {},
});

const view = {
  url: "port.png",
  mediumUrl: "port-medium.png",
  largeUrl: "port-large.png",
  width: 1000,
  height: 500,
};

const mountPanel = async () => {
  const wrapper = mount(AddShips, {
    global: {
      stubs: {
        Btn: { template: "<button><slot /></button>" },
        FormInput: {
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template:
            "<input :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
        },
      },
    },
  });

  await flushPromises();

  return wrapper;
};

describe("FleetchartCanvasAddShips", () => {
  beforeEach(() => {
    views.mockReset();
    models.value = { items: [ship("hornet"), ship("no-pictures")] };
    views.mockResolvedValue([
      { slug: "hornet", media: { portView: view } },
      { slug: "no-pictures", media: {} },
    ]);
  });

  it("offers only the ships the chart can draw", async () => {
    const wrapper = await mountPanel();

    expect(
      wrapper.find("[data-test='fleetchart-add-ship-hornet']").exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='fleetchart-add-ship-no-pictures']").exists(),
    ).toBe(false);
    expect(wrapper.get("img").attributes("src")).toBe("port-medium.png");
  });

  it("hands over the ship that was picked", async () => {
    const wrapper = await mountPanel();

    await wrapper
      .get("[data-test='fleetchart-add-ship-hornet']")
      .trigger("click");

    expect(wrapper.emitted("add")?.[0][0]).toMatchObject({ slug: "hornet" });
  });

  it("says so when nothing was found", async () => {
    models.value = { items: [] };

    const wrapper = await mountPanel();

    expect(
      wrapper.find("[data-test='fleetchart-add-ships-empty']").exists(),
    ).toBe(true);
  });

  it("searches once typing has stopped", async () => {
    vi.useFakeTimers();

    const wrapper = await mountPanel();

    await wrapper.get("input").setValue(" hornet ");

    expect(lastParams.value?.q.searchCont).toBeUndefined();

    vi.advanceTimersByTime(300);
    await nextTick();

    expect(lastParams.value?.q.searchCont).toBe("hornet");

    vi.useRealTimers();
  });
});
