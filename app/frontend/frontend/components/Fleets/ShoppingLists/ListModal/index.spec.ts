import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { flushPromises } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { max, required } from "@vee-validate/rules";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type CartList, type Fleet } from "@/services/fyApi";

const create = vi.fn();
const update = vi.fn();
const emit = vi.fn();

const lists = ref<CartList[]>([]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useCreateFleetShoppingList: () => ({ mutateAsync: create }),
  useUpdateFleetShoppingList: () => ({ mutateAsync: update }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

// A stand-in that takes a value the way the real select emits one, without
// the dropdown machinery none of this is about.
vi.mock("@/shared/components/base/Select/index.vue", () => ({
  default: {
    name: "BaseSelect",
    props: ["modelValue", "name", "options"],
    emits: ["update:modelValue"],
    render: () => null,
  },
}));

beforeAll(() => {
  defineRule("required", required);
  defineRule("max", max);
});

const Component = (await import("./index.vue")).default;

const fleet = { slug: "merc", features: [] } as unknown as Fleet;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(Component, {
    props: { fleet, ...props } as never,
  });

  return wrapper;
};

const source = (subject: VueWrapper) =>
  subject
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "cartId")!;

const submit = (subject: VueWrapper) =>
  subject.find("[data-test='fleet-shopping-list-submit']");

describe("FleetShoppingListModal", () => {
  beforeEach(() => {
    lists.value = [
      { id: "a", name: "Uniform", active: true, itemsCount: 3 } as CartList,
      { id: "b", name: "Armour", active: false, itemsCount: 1 } as CartList,
      { id: "c", name: "Empty", active: false, itemsCount: 0 } as CartList,
    ];
    create.mockReset().mockResolvedValue({ id: "new", name: "Uniform" });
    update.mockReset().mockResolvedValue({ id: "kit", name: "Kit" });
    emit.mockClear();
  });

  it("offers only lists with something on them", async () => {
    const subject = await mount();

    expect(
      (source(subject).props("options") as { value: string }[]).map(
        (option) => option.value,
      ),
    ).toEqual(["a", "b"]);
  });

  it("cannot publish until one of the user's lists is picked", async () => {
    const subject = await mount();

    expect(submit(subject).attributes("disabled")).toBeDefined();

    source(subject).vm.$emit("update:modelValue", "a");
    await flushPromises();

    expect(submit(subject).attributes("disabled")).toBeUndefined();
  });

  it("names the new list after the one it is published from", async () => {
    const subject = await mount();

    source(subject).vm.$emit("update:modelValue", "a");
    await flushPromises();

    expect(
      (
        subject.find("[data-test='fleet-shopping-list-name'] input")
          .element as HTMLInputElement
      ).value,
    ).toBe("Uniform");
  });

  it("follows a change of source until a name is typed", async () => {
    const subject = await mount();
    const input = () =>
      subject.find("[data-test='fleet-shopping-list-name'] input")
        .element as HTMLInputElement;

    source(subject).vm.$emit("update:modelValue", "a");
    await flushPromises();
    source(subject).vm.$emit("update:modelValue", "b");
    await flushPromises();

    expect(input().value).toBe("Armour");

    await subject
      .find("[data-test='fleet-shopping-list-name'] input")
      .setValue("Merc kit");
    source(subject).vm.$emit("update:modelValue", "a");
    await flushPromises();

    expect(input().value).toBe("Merc kit");
  });

  it("publishes the picked list to the fleet", async () => {
    const subject = await mount();

    source(subject).vm.$emit("update:modelValue", "a");
    await flushPromises();
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(create).toHaveBeenCalledWith({
      fleetSlug: "merc",
      data: {
        name: "Uniform",
        description: null,
        visibility: "members_only",
        fleetSquadronIds: [],
        cartId: "a",
      },
    });
    expect(emit).toHaveBeenCalledWith("close-modal", true);
  });

  it("leaves the lines alone on an edit with no list picked", async () => {
    const subject = await mount({
      list: {
        id: "kit",
        name: "Kit",
        description: null,
        visibility: "members_only",
        fleetSquadrons: [],
      },
    });

    expect(submit(subject).attributes("disabled")).toBeUndefined();

    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(update).toHaveBeenCalledWith({
      fleetSlug: "merc",
      id: "kit",
      data: {
        name: "Kit",
        description: null,
        visibility: "members_only",
        fleetSquadronIds: [],
      },
    });
  });
});
