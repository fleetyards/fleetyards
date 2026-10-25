import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { between, required, min, min_value } from "@vee-validate/rules";
import Component from "./index.vue";

// Registered one by one rather than through the app's `setupRules`, which
// reaches for a pinia store. Without them every mount throws "No such
// validator", which fails the run even when the assertions pass.
beforeAll(() => {
  defineRule("required", required);
  defineRule("min", min);
  defineRule("min_value", min_value);
  defineRule("between", between);
});

const api = vi.hoisted(() => ({
  stock: vi.fn(),
  create: vi.fn(),
}));

// The hooks, not the fetchers: a generated hook calls its own fetcher from
// inside the module, which a mocked export never reaches.
vi.mock("@/services/fyApi", async (importOriginal) => {
  const { computed } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    hangarInventoryStock: api.stock,
    useCreateHangarInventoryItem: () => ({ mutateAsync: api.create }),
    // A recipe makes the Bulwark and nothing else.
    useBlueprints: vi.fn(
      (params: { value: { q: { craftableIdEq?: string } } }) => ({
        isPlaceholderData: computed(() => false),
        data: computed(() => ({
          items:
            params.value.q.craftableIdEq === "bulwark"
              ? [{ id: "bp-1", name: "Bulwark Blueprint", slug: "bulwark-bp" }]
              : [],
          meta: {},
        })),
      }),
    ),
  };
});

// What the crafter would hand over on apply; its own page is specced with it.
const crafterDraft = vi.hoisted(() => ({
  value: {
    blueprintId: "bp-1",
    blueprintSlug: "bulwark-bp",
    qualities: { 1: 750, 2: 500 },
  } as unknown,
}));

vi.mock("@/frontend/components/Blueprints/Crafter/index.vue", async () => {
  const { defineComponent } = await import("vue");

  return {
    default: defineComponent({
      name: "BlueprintCrafter",
      props: {
        title: { type: String, default: undefined },
        item: { type: Object, default: undefined },
        craftableType: { type: String, default: undefined },
        crafted: { type: Object, default: undefined },
        embedded: { type: Boolean, default: false },
      },
      emits: ["apply", "remove", "close"],
      setup(_, { emit, expose }) {
        expose({
          canApply: true,
          apply: () => emit("apply", crafterDraft.value),
          remove: () => emit("remove"),
        });

        return () => null;
      },
    }),
  };
});

// Its upload chain reaches the 3D viewer, whose ESM build Vitest cannot load.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: { name: "FormFileInput", render: () => null },
}));

// The picker fetches its catalogues, which is not what this is about.
vi.mock("@/frontend/components/Logistics/ItemPicker/index.vue", () => ({
  default: {
    name: "LogisticsItemPicker",
    props: { category: { type: String, default: undefined } },
    emits: ["select"],
    render: () => null,
  },
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

beforeEach(() => {
  api.stock.mockResolvedValue([]);
  api.create.mockResolvedValue({});
});

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { target: { kind: "hangar", slug: "cargo-hold" } as never },
  });
  await flushPromises();

  return wrapper;
};

const select = (subject: VueWrapper, name: string) =>
  subject
    .findAllComponents({ name: "BaseSelect" })
    .find((candidate) => candidate.props("name") === name)!;

const pick = async (
  subject: VueWrapper,
  selection: Record<string, unknown>,
) => {
  await subject.find("[data-test='item-picker-field-open']").trigger("click");
  subject
    .findComponent({ name: "LogisticsItemPicker" })
    .vm.$emit("select", selection);
  await flushPromises();
};

const field = (subject: VueWrapper) =>
  subject.find("[data-test='item-picker-field-catalogueItem']");

const bulwark = {
  item: { type: "Component", id: "bulwark", name: "Bulwark" },
  name: "Bulwark",
  category: "component",
};

const gold = {
  item: { type: "Commodity", id: "gold", name: "Gold", counted: true },
  name: "Gold",
  category: "commodity",
};

describe("LogisticsInventoryItemModal", () => {
  it("opens the catalogue in place of the form", async () => {
    const subject = await mount();

    await subject.find("[data-test='item-picker-field-open']").trigger("click");

    expect(
      subject.findComponent({ name: "LogisticsItemPicker" }).exists(),
    ).toBe(true);
    expect(subject.find("form").attributes("style")).toContain("display: none");
    expect(subject.find("[data-test='inventory-item-save']").exists()).toBe(
      false,
    );
  });

  it("fills the entry in from the pick", async () => {
    const subject = await mount();

    await pick(subject, bulwark);

    expect(
      subject.findComponent({ name: "LogisticsItemPicker" }).exists(),
    ).toBe(false);
    expect(field(subject).text()).toContain("Bulwark");
    expect(field(subject).text()).toContain("Component");
  });

  // Only raw resources carry a grade; a part's worth is in what it was made of.
  it("asks for a grade on a resource only", async () => {
    const subject = await mount();

    await pick(subject, bulwark);

    expect(subject.find("[data-test='input-quality']").exists()).toBe(false);

    await pick(subject, gold);

    expect(subject.find("[data-test='input-quality']").exists()).toBe(true);
  });

  // The game hands some commodities out a piece at a time; only the picked
  // record knows, and it is what puts `units` on offer.
  it("offers units for a counted commodity", async () => {
    const subject = await mount();

    await pick(subject, gold);

    const units = select(subject, "unit").props("options") as {
      value: string;
    }[];

    expect(units.map((option) => option.value)).toEqual(["scu", "units"]);
  });

  // Goods the catalogue does not carry are filed by the picker's category,
  // with no catalogue reference to send.
  it("takes a custom item from the picker", async () => {
    const subject = await mount();

    await pick(subject, { name: "Grandma's teapot", category: "other" });

    expect(field(subject).text()).toContain("Grandma's teapot");
    expect(field(subject).text()).toContain("Other");
  });

  // Left blank rather than defaulted, so a deposit cannot slip through as a
  // 1 and a 0 nobody chose.
  it("asks for an item and a quantity before depositing", async () => {
    const subject = await mount();

    expect(
      (subject.find("[data-test='input-quantity']").element as HTMLInputElement)
        .value,
    ).toBe("");
    // Nothing is graded before the goods are named.
    expect(subject.find("[data-test='input-quality']").exists()).toBe(false);

    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(subject.find(".item-picker-field__error").exists()).toBe(true);
    expect(
      subject.find("[data-test='input-wrapper-quantity']").classes(),
    ).toContain("base-input--with-error");
  });

  it("asks for the grade of a resource", async () => {
    const subject = await mount();

    await pick(subject, gold);
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(
      subject.find("[data-test='input-wrapper-quality']").classes(),
    ).toContain("base-input--with-error");
  });

  // A resource's grade field, once shown, must not keep asking after the
  // goods change to something a grade does not apply to.
  it("deposits a part without a grade after a resource was picked", async () => {
    const subject = await mount();

    await pick(subject, gold);
    await pick(subject, bulwark);
    await subject.find("[data-test='input-quantity']").setValue("1");
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(api.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          itemId: "bulwark",
          quality: undefined,
        }),
      }),
    );
  });

  it("clears the item", async () => {
    const subject = await mount();

    await pick(subject, { name: "Grandma's teapot", category: "other" });
    await subject
      .find("[data-test='item-picker-field-clear']")
      .trigger("click");

    expect(field(subject).text()).not.toContain("Grandma's teapot");
  });

  describe("crafting", () => {
    const craftBulwark = async (subject: VueWrapper) => {
      await pick(subject, bulwark);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");

      await subject.find("[data-test='crafting-apply']").trigger("click");
      await flushPromises();
    };

    it("offers crafting only for an item a recipe makes", async () => {
      const subject = await mount();

      await pick(subject, gold);

      expect(
        subject.find("[data-test='item-picker-field-craft']").exists(),
      ).toBe(false);

      await pick(subject, bulwark);

      expect(
        subject.find("[data-test='item-picker-field-craft']").exists(),
      ).toBe(true);
    });

    // Its own page, like the picker, so the form underneath keeps its state.
    it("opens crafting as a step of its own", async () => {
      const subject = await mount();

      await pick(subject, bulwark);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");

      expect(subject.findComponent({ name: "BlueprintCrafter" }).exists()).toBe(
        true,
      );
      expect(subject.find("form").attributes("style")).toContain(
        "display: none",
      );
    });

    it("takes the recipe and grades once applied", async () => {
      const subject = await mount();

      await craftBulwark(subject);

      const field = subject.find(
        "[data-test='item-picker-field-catalogueItem']",
      );

      expect(field.text()).toContain("Crafted 750 / 500");
      expect(
        subject
          .find("[data-test='item-picker-field-craft']")
          .attributes("aria-pressed"),
      ).toBe("true");
    });

    it("sends the recipe and grades with the deposit", async () => {
      const subject = await mount();

      await craftBulwark(subject);
      await subject.find("[data-test='input-quantity']").setValue("1");
      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(api.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            itemType: "Component",
            itemId: "bulwark",
            craftedBlueprintId: "bp-1",
            craftedQualities: { 1: 750, 2: 500 },
          }),
        }),
      );
    });

    it("marks a part as not crafted again", async () => {
      const subject = await mount();

      await craftBulwark(subject);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");
      await subject.find("[data-test='crafting-clear']").trigger("click");

      expect(
        subject.find("[data-test='item-picker-field-catalogueItem']").text(),
      ).not.toContain("Crafted");
    });

    // Backing out of the step leaves the form's crafting as it was.
    it("keeps the crafting as it was when the step is left", async () => {
      const subject = await mount();

      await pick(subject, bulwark);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");
      // Changing grades in the crafter and backing out applies nothing.
      await subject.find("[data-test='item-picker-back']").trigger("click");

      expect(
        subject.find("[data-test='item-picker-field-catalogueItem']").text(),
      ).not.toContain("Crafted");
    });

    // Without the lot's recipe and grades a withdrawal would come out of stock
    // that was never crafted.
    // The step is the shared crafter, opened on the part's catalogue and on
    // how it is crafted now.
    it("opens the shared crafter on the part", async () => {
      const subject = await mount();

      await pick(subject, bulwark);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");

      const crafter = subject.findComponent({ name: "BlueprintCrafter" });

      expect(crafter.props("embedded")).toBe(true);
      expect(crafter.props("craftableType")).toBe("Component");
      expect(crafter.props("item")).toMatchObject({ id: "bulwark" });
    });

    it("withdraws a crafted lot with what it was made from", async () => {
      api.stock.mockResolvedValue([
        {
          id: "pos-1",
          name: "Bulwark",
          category: "component",
          unit: "units",
          netQuantity: 2,
          quality: null,
          item: { id: "bulwark", type: "Component" },
          crafted: {
            blueprint: {
              id: "bp-1",
              name: "Bulwark Blueprint",
              slug: "bulwark-bp",
            },
            qualities: { 1: 750, 2: 500 },
          },
        },
      ]);

      const subject = await mount();

      select(subject, "entryType").vm.$emit("update:modelValue", "withdrawal");
      await flushPromises();
      const [lot] = select(subject, "stockItem").props("options") as {
        value: string;
      }[];

      select(subject, "stockItem").vm.$emit("update:modelValue", lot.value);
      await flushPromises();
      await subject.find("[data-test='input-quantity']").setValue("1");
      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(api.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            entryType: "withdrawal",
            itemId: "bulwark",
            craftedBlueprintId: "bp-1",
            craftedQualities: { 1: 750, 2: 500 },
          }),
        }),
      );
    });
  });

  describe("a withdrawal", () => {
    const withdraw = async (row: number) => {
      api.stock.mockResolvedValue([
        {
          id: "pos-1",
          name: "Gold",
          category: "commodity",
          unit: "scu",
          netQuantity: 4,
          quality: 800,
        },
        {
          id: "pos-1",
          name: "Gold",
          category: "commodity",
          unit: "scu",
          netQuantity: 10,
          quality: null,
        },
        // Deposited before parts stopped taking a grade, which stored 0.
        {
          id: "pos-2",
          name: "Bulwark",
          category: "component",
          unit: "units",
          netQuantity: 3,
          quality: 0,
        },
      ]);

      const subject = await mount();

      select(subject, "entryType").vm.$emit("update:modelValue", "withdrawal");
      await flushPromises();

      const lots = select(subject, "stockItem").props("options") as {
        value: string;
      }[];

      select(subject, "stockItem").vm.$emit(
        "update:modelValue",
        lots[row].value,
      );
      await flushPromises();
      await subject.find("[data-test='input-quantity']").setValue("2");

      return subject;
    };

    // Stock is held per grade, and the grade of the row picked is the one the
    // withdrawal comes out of.
    it("takes the grade of the row it comes out of", async () => {
      const subject = await withdraw(0);

      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(api.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            entryType: "withdrawal",
            quality: 800,
          }),
        }),
      );
    });

    // Ungraded stock is held as NULL; an omitted grade would be stored as 0, a
    // group no deposit occupies, and the stock row would never go down.
    it("comes out of ungraded stock without a grade", async () => {
      const subject = await withdraw(1);

      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(api.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            entryType: "withdrawal",
            quality: null,
          }),
        }),
      );
    });

    // Stock is grouped by grade, so a part held at 0 has to come out at 0.
    it("comes out at exactly the grade a part is held at", async () => {
      const subject = await withdraw(2);

      expect(subject.find("[data-test='input-quality']").exists()).toBe(false);

      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(api.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            entryType: "withdrawal",
            quality: 0,
          }),
        }),
      );
    });
  });
});
