import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import SavedLayouts from "./index.vue";
import type { FleetchartPlacement } from "@/services/fyApi";

const mutations = {
  create: vi.fn(),
  update: vi.fn(),
  destroy: vi.fn(),
  share: vi.fn(),
  unshare: vi.fn(),
};

const layouts = ref([
  {
    id: "1",
    name: "Parade",
    colored: true,
    shareToken: null,
    placements: [],
  },
  {
    id: "2",
    name: "Shared one",
    colored: true,
    shareToken: "token",
    placements: [],
  },
]);

const hook = (run: ReturnType<typeof vi.fn>) => () => ({
  mutate: run,
  mutateAsync: run,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", () => ({
  getFleetchartLayoutsQueryKey: () => ["layouts"],
  useFleetchartLayouts: () => ({ data: layouts }),
  useCreateFleetchartLayout: () => hook(mutations.create)(),
  useUpdateFleetchartLayout: () => hook(mutations.update)(),
  useDestroyFleetchartLayout: () => hook(mutations.destroy)(),
  useShareFleetchartLayout: () => hook(mutations.share)(),
  useUnshareFleetchartLayout: () => hook(mutations.unshare)(),
}));

vi.mock("@tanstack/vue-query", () => ({
  useQueryClient: () => ({ invalidateQueries: vi.fn() }),
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRouter: () => ({
    resolve: ({ params }: { params: { token: string } }) => ({
      href: `/hangar/fleetchart/shared/${params.token}/`,
    }),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert: vi.fn(),
    displaySuccess: vi.fn(),
  }),
}));

const placements: FleetchartPlacement[] = [{ vehicleId: "a", x: 1, y: 2 }];

const mountPanel = () =>
  mount(SavedLayouts, {
    props: { placements, colored: false },
    global: {
      directives: { tooltip: {} },
      stubs: {
        Btn: {
          props: ["disabled"],
          template: "<button :disabled='disabled'><slot /></button>",
        },
        BtnConfirm: {
          emits: ["confirm"],
          template: "<button @click=\"$emit('confirm')\"><slot /></button>",
        },
        FormInput: {
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template:
            "<input :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
        },
        ShareBtn: {
          props: ["url"],
          template: "<a data-test='share-link' :href='url' />",
        },
      },
    },
  });

describe("FleetchartCanvasSavedLayouts", () => {
  beforeEach(() => {
    Object.values(mutations).forEach((run) => run.mockReset());
  });

  it("saves the current arrangement under a new name", async () => {
    const wrapper = mountPanel();

    await wrapper.get("input").setValue("  New one  ");
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(mutations.create).toHaveBeenCalledWith({
      data: { name: "New one", colored: false, placements },
    });
    expect((wrapper.get("input").element as HTMLInputElement).value).toBe("");
  });

  it("does not save without a name", async () => {
    const wrapper = mountPanel();

    await wrapper.get("input").setValue("   ");
    await wrapper.get("form").trigger("submit");

    expect(mutations.create).not.toHaveBeenCalled();
  });

  it("overwrites a layout with the current arrangement, keeping its name", async () => {
    const wrapper = mountPanel();

    await wrapper
      .get("[data-test='fleetchart-update-layout']")
      .trigger("click");
    await flushPromises();

    expect(mutations.update).toHaveBeenCalledWith({
      id: "1",
      data: { colored: false, placements },
    });
  });

  it("hands a layout to the chart to open", async () => {
    const wrapper = mountPanel();

    await wrapper.get("[data-test='fleetchart-open-layout']").trigger("click");

    expect(wrapper.emitted("open")?.[0][0]).toMatchObject({ id: "1" });
  });

  it("shares an unshared layout and links a shared one", async () => {
    const wrapper = mountPanel();

    await wrapper.get("[data-test='fleetchart-share-layout']").trigger("click");

    expect(mutations.share).toHaveBeenCalledWith({ id: "1" });
    expect(
      wrapper.get("[data-test='share-link']").attributes("href"),
    ).toContain("/hangar/fleetchart/shared/token/");
  });

  it("stops sharing", async () => {
    const wrapper = mountPanel();

    await wrapper
      .get("[data-test='fleetchart-unshare-layout']")
      .trigger("click");

    expect(mutations.unshare).toHaveBeenCalledWith({ id: "2" });
  });

  it("deletes a layout once confirmed", async () => {
    const wrapper = mountPanel();

    await wrapper
      .get("[data-test='fleetchart-delete-layout']")
      .trigger("click");

    expect(mutations.destroy).toHaveBeenCalledWith({ id: "1" });
  });
});
