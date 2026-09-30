import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, provide, ref, type Ref } from "vue";
import { catalogueLookup } from "@/services/fyApi";
import Markdown from "./index.vue";
import { MARKDOWN_CATALOGUE_TOKEN } from "./catalogueTokens";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  catalogueLookup: vi.fn(),
}));

const lookup = vi.mocked(catalogueLookup);

// Stands in for the frontend's link-with-stats-card.
const ItemLink = defineComponent({
  props: { item: { type: Object, required: true } },
  setup: (props) => () =>
    h(
      "a",
      { class: "item-link", "data-slug": props.item.slug },
      props.item.name,
    ),
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

let source: Ref<string>;

const mount = async (initial: string, withLink = true) => {
  source = ref(initial);

  const Host = defineComponent({
    setup() {
      if (withLink) provide(MARKDOWN_CATALOGUE_TOKEN, ItemLink);

      return () => h(Markdown, { source: source.value });
    },
  });

  wrapper = await mountWithDefaults(Host, { attachTo: document.body });
  await flushPromises();

  return wrapper;
};

describe("Markdown catalogue tokens", () => {
  beforeEach(() => {
    lookup.mockReset();
    lookup.mockResolvedValue({
      items: [
        {
          token: "Attrition-3 Repeater",
          name: "Attrition-3 Repeater",
          type: "Component",
          slug: "attrition-3-repeater",
        },
      ],
    } as never);
  });

  it("asks once for every item a text names", async () => {
    await mount(
      "[*Attrition-3 Repeater*], [*Unknown Thing*] and [*Attrition-3 Repeater*] again",
    );

    expect(lookup).toHaveBeenCalledOnce();
    expect(lookup).toHaveBeenCalledWith({
      names: ["Attrition-3 Repeater", "Unknown Thing"],
    });
  });

  it("links a resolved token in place of its name", async () => {
    const subject = await mount("Fit an [*Attrition-3 Repeater*]");

    const links = subject.findAll(".item-link");
    expect(links).toHaveLength(1);
    expect(links[0].attributes("data-slug")).toBe("attrition-3-repeater");
    expect(subject.find("[data-catalogue-token] .item-link").exists()).toBe(
      true,
    );
  });

  it("leaves a token nothing resolves as its name", async () => {
    const subject = await mount("A [*Unknown Thing*] here");

    expect(subject.find(".item-link").exists()).toBe(false);
    expect(subject.text()).toBe("A Unknown Thing here");
  });

  it("puts a class and a test hook the caller passes on the text", async () => {
    const Host = defineComponent({
      setup: () => () =>
        h(Markdown, {
          source: "Hi",
          class: "description",
          "data-test": "body",
        }),
    });

    wrapper = await mountWithDefaults(Host);

    expect(wrapper.find(".markdown.description").exists()).toBe(true);
    expect(wrapper.find('[data-test="body"]').text()).toBe("Hi");
  });

  it("asks nothing where no link is provided", async () => {
    const subject = await mount("Fit an [*Attrition-3 Repeater*]", false);

    expect(lookup).not.toHaveBeenCalled();
    expect(subject.text()).toBe("Fit an Attrition-3 Repeater");
  });

  it("links the tokens of a text that changes", async () => {
    const subject = await mount("First [*Unknown Thing*]");

    source.value = "Now [*Attrition-3 Repeater*]";
    await nextTick();
    await flushPromises();

    expect(subject.findAll(".item-link")).toHaveLength(1);
  });
});
