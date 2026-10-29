import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required, min_value } from "@vee-validate/rules";
import type { Raffle } from "@/services/fyAdminApi";
import Component from "./index.vue";

beforeAll(() => {
  defineRule("required", required);
  defineRule("min_value", min_value);
});

vi.mock("@/shared/composables/useDirectUpload", () => ({
  useDirectUpload: () => ({
    uploadFile: async (file: File) => ({ signed_id: `signed-${file.name}` }),
  }),
}));

vi.mock("@/shared/components/base/FormDateTime/index.vue", () => ({
  default: {
    name: "FormDateTime",
    props: { modelValue: { type: String, default: null }, name: String },
    emits: ["update:modelValue"],
    render: () => null,
  },
}));

const raffle: Raffle = {
  id: "8d0e3c7a-0000-4000-8000-000000000002",
  title: "Win a Polaris",
  translations: [{ locale: "de", title: "Gewinne eine Polaris" }],
  codeSet: true,
  maskedCode: "********CDEF",
  images: [],
  startsAt: "2026-11-01T18:00:00.000Z",
  runDays: 7,
  endsAt: "2026-11-08T18:00:00.000Z",
  claimPeriodDays: 3,
  published: true,
  status: "upcoming",
  entriesCount: 0,
  socialPosts: { start: "", lastDay: "" },
  createdAt: "2026-10-01T00:00:00Z",
  updatedAt: "2026-10-01T00:00:00Z",
};

const submit = async (wrapper: Awaited<ReturnType<typeof mountForm>>) => {
  await wrapper.find("form#raffle-form").trigger("submit");
  await flushPromises();
  await new Promise((resolve) => setTimeout(resolve, 20));
  await flushPromises();
};

const mountForm = (props: { raffle?: Raffle } = {}) =>
  mountWithDefaults(Component, {
    props: { formId: "raffle-form", ...props },
  });

describe("RaffleForm", () => {
  it("leaves the stored code alone when the field stays empty", async () => {
    const wrapper = await mountForm({ raffle });

    await submit(wrapper);

    const payload = wrapper.emitted("submit")?.[0]?.[0];
    expect(payload).toMatchObject({
      title: "Win a Polaris",
      claimPeriodDays: 3,
      runDays: 7,
      published: true,
    });
    expect(payload).toHaveProperty("code", undefined);
  });

  it("sends back only the languages that hold text", async () => {
    const wrapper = await mountForm({ raffle });

    await submit(wrapper);

    expect(wrapper.emitted("submit")?.[0]?.[0]).toMatchObject({
      translations: [
        {
          locale: "de",
          title: "Gewinne eine Polaris",
          prize: undefined,
          description: undefined,
        },
      ],
    });
  });

  it("locks the code and dates once the raffle is drawn", async () => {
    const wrapper = await mountForm({
      raffle: { ...raffle, drawnAt: "2026-11-09T10:00:00Z", status: "drawn" },
    });

    expect(
      wrapper.find('input[name="code"]').attributes("disabled"),
    ).toBeDefined();
  });

  it("does not submit without a title", async () => {
    const wrapper = await mountForm();

    await submit(wrapper);

    expect(wrapper.emitted("submit")).toBeUndefined();
  });

  it("fills every language and the gallery from a picked folder", async () => {
    URL.createObjectURL = vi.fn(() => "blob:preview");

    const wrapper = await mountForm({ raffle });
    const input = wrapper.find('[data-test="raffle-import-input"]');

    Object.defineProperty(input.element, "files", {
      configurable: true,
      value: [
        new File(["x"], "2-interior.jpg", { type: "image/jpeg" }),
        new File(
          ["---\ntitle: Win a Centaurus\nprize: 1x Centaurus\n---\nText"],
          "en.md",
        ),
        new File(["---\nprize: 1x Centaurus mit LTI\n---\n"], "de.md"),
        new File(["x"], "1-cover.jpg", { type: "image/jpeg" }),
      ],
    });
    await input.trigger("change");
    await flushPromises();

    expect(wrapper.emitted("submit")).toBeUndefined();

    await submit(wrapper);

    expect(wrapper.emitted("submit")?.[0]?.[0]).toMatchObject({
      title: "Win a Centaurus",
      prize: "1x Centaurus",
      description: "Text",
      translations: [
        {
          locale: "de",
          title: "Gewinne eine Polaris",
          prize: "1x Centaurus mit LTI",
        },
      ],
      images: ["signed-1-cover.jpg", "signed-2-interior.jpg"],
    });
  });
});
