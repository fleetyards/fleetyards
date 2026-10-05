import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import type { PayoutParticipant } from "@/services/fyApi";
import { useI18nStore } from "@/shared/stores/i18n";
import Component from "./index.vue";

const createEntry = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useCreatePayoutEntry: () => ({ mutateAsync: createEntry }),
  };
});

beforeAll(() => {
  defineRule("required", required);
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  createEntry.mockReset();
  useI18nStore().locale = "en";
});

const participant = {
  id: "participant-1",
  payoutLedgerId: "ledger-1",
  displayName: "Mal",
  guest: false,
  weight: "1.0",
} as PayoutParticipant;

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { payoutLedgerId: "ledger-1", participants: [participant] },
  });

  return wrapper;
};

const fill = async (subject: VueWrapper, amount = "1500") => {
  await subject.find('[data-test="input-amount"]').setValue(amount);
  await subject.find('[data-test="input-description"]').setValue("Cargo");
};

const exposedDirty = (subject: VueWrapper) =>
  (subject.vm as unknown as { dirty: boolean }).dirty;

describe("PayoutEntryModal", () => {
  it("is clean until something is typed, so closing asks nothing", async () => {
    const subject = await mount();

    expect(exposedDirty(subject)).toBe(false);

    await subject.find('[data-test="input-description"]').setValue("Cargo");
    await flushPromises();

    expect(exposedDirty(subject)).toBe(true);
  });

  it("submits on enter from a text field", async () => {
    createEntry.mockResolvedValue({});
    const subject = await mount();
    await fill(subject);

    await subject
      .find('[data-test="input-description"]')
      .trigger("keydown", { key: "Enter" });
    await flushPromises();

    expect(createEntry).toHaveBeenCalledTimes(1);
  });

  it("keeps enter in the notes a newline, and submits on cmd+enter", async () => {
    createEntry.mockResolvedValue({});
    const subject = await mount();
    await fill(subject);

    const notes = subject.find("textarea");
    await notes.trigger("keydown", { key: "Enter" });
    await flushPromises();

    expect(createEntry).not.toHaveBeenCalled();

    await notes.trigger("keydown", { key: "Enter", metaKey: true });
    await flushPromises();

    expect(createEntry).toHaveBeenCalledTimes(1);
  });

  it("reads an amount typed the German way", async () => {
    useI18nStore().locale = "de";
    createEntry.mockResolvedValue({});
    const subject = await mount();
    await fill(subject, "1.500,50");

    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(createEntry).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ amount: "1500.50" }),
      }),
    );
  });
});
