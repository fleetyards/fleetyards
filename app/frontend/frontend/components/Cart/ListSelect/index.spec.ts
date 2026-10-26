import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type CartList } from "@/services/fyApi";

const replace = vi.fn();
const query = { strategy: "stops" };

const lists = ref<CartList[]>([]);

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRoute: () => ({ query }),
  useRouter: () => ({ replace }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
}));

const Component = (await import("./index.vue")).default;

const list = (id: string, active = false): CartList => ({
  id,
  name: `List ${id}`,
  active,
  itemsCount: 0,
  createdAt: "2026-10-26T10:00:00Z",
  updatedAt: "2026-10-26T10:00:00Z",
});

const mount = (listId = "a") =>
  mountWithDefaults<typeof Component>(Component, { props: { listId } });

const pick = (wrapper: Awaited<ReturnType<typeof mount>>, id: string) =>
  wrapper
    .findComponent({ name: "BaseSelect" })
    .vm.$emit("update:modelValue", id);

describe("CartListSelect", () => {
  beforeEach(() => {
    lists.value = [list("a", true), list("b")];
    replace.mockClear();
  });

  it("shows a picked list, keeping the plan", async () => {
    const wrapper = await mount();

    pick(wrapper, "b");

    expect(replace).toHaveBeenCalledWith({
      name: "cart",
      query: { strategy: "stops", list: "b" },
    });
  });

  it("shows the active list at the page's own address", async () => {
    const wrapper = await mount("b");

    pick(wrapper, "a");

    expect(replace).toHaveBeenCalledWith({
      name: "cart",
      query: { strategy: "stops", list: undefined },
    });
  });

  it("does nothing when the shown list is picked again", async () => {
    const wrapper = await mount("a");

    pick(wrapper, "a");

    expect(replace).not.toHaveBeenCalled();
  });

  it("is not shown before any list exists", async () => {
    lists.value = [];
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-list-select']").exists()).toBe(false);
  });
});
