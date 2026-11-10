import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import CodeExample from "@/docs/components/CodeExample/index.vue";
import Component from "./index.vue";

const ICON = "https://fleetyards.test/media/fleetyards-icon-128.png";

const mountBuilder = () =>
  mountWithDefaults(Component, {
    props: { frontendEndpoint: "https://fleetyards.test", iconUrl: ICON },
  });

const snippet = (wrapper: Awaited<ReturnType<typeof mountBuilder>>) =>
  wrapper.findComponent(CodeExample).props("code");

describe("LinkBuilder", () => {
  it("starts with a hangar link holding a placeholder", async () => {
    const wrapper = await mountBuilder();

    expect(snippet(wrapper)).toContain(
      'href="https://fleetyards.test/hangar/<username>/"',
    );
    expect(snippet(wrapper)).toContain(`src="${ICON}"`);
  });

  it("puts what is typed into the link and the preview", async () => {
    const wrapper = await mountBuilder();

    await wrapper.find("input").setValue("torlekmaru");

    expect(snippet(wrapper)).toContain(
      'href="https://fleetyards.test/hangar/torlekmaru/"',
    );
    expect(
      wrapper.find('[data-test="link-builder-preview"] a').attributes("href"),
    ).toBe("https://fleetyards.test/hangar/torlekmaru/");
  });

  it("escapes characters that would break out of the address", async () => {
    const wrapper = await mountBuilder();

    await wrapper.find("input").setValue('a"b/c');

    expect(snippet(wrapper)).toContain("/hangar/a%22b%2Fc/");
  });

  it("turns a fleet ID or ship name into the slug the page is found by", async () => {
    const wrapper = await mountBuilder();

    await wrapper
      .find('[data-test="link-builder-target-fleet"]')
      .trigger("click");
    await wrapper.find("input").setValue("MARU");

    expect(snippet(wrapper)).toContain("/fleets/maru/");

    await wrapper
      .find('[data-test="link-builder-target-ship"]')
      .trigger("click");
    await wrapper.find("input").setValue("  600i  Touring ");

    expect(snippet(wrapper)).toContain("/ships/600i-touring/");
  });

  it("uses the address table's placeholders while a field is empty", async () => {
    const wrapper = await mountBuilder();

    await wrapper
      .find('[data-test="link-builder-target-ship"]')
      .trigger("click");

    expect(snippet(wrapper)).toContain("/ships/<slug>/");

    await wrapper
      .find('[data-test="link-builder-target-fleet"]')
      .trigger("click");

    expect(snippet(wrapper)).toContain("/fleets/<fleet-id>/");
  });

  it("keeps a value per target", async () => {
    const wrapper = await mountBuilder();

    await wrapper.find("input").setValue("torlekmaru");
    await wrapper
      .find('[data-test="link-builder-target-fleet"]')
      .trigger("click");
    await wrapper.find("input").setValue("maru");
    await wrapper
      .find('[data-test="link-builder-target-hangar"]')
      .trigger("click");

    expect(snippet(wrapper)).toContain("/hangar/torlekmaru/");
  });

  it("writes Markdown and plain URLs", async () => {
    const wrapper = await mountBuilder();

    await wrapper
      .find('[data-test="link-builder-target-ship"]')
      .trigger("click");
    await wrapper.find("input").setValue("600i-touring");
    await wrapper
      .find('[data-test="link-builder-format-markdown"]')
      .trigger("click");

    expect(snippet(wrapper)).toBe(
      `[![FleetYards.net](${ICON})](https://fleetyards.test/ships/600i-touring/) [View on FleetYards.net](https://fleetyards.test/ships/600i-touring/)`,
    );

    await wrapper
      .find('[data-test="link-builder-format-url"]')
      .trigger("click");

    expect(snippet(wrapper)).toBe(
      "https://fleetyards.test/ships/600i-touring/",
    );
  });
});
