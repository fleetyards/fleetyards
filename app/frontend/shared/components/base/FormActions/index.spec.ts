import { mount } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { type AppConfirmOptions } from "@/shared/components/AppConfirm/types";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const displayConfirm = vi.fn();
const dismissConfirm = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayConfirm, dismissConfirm }),
}));

const mountWith = (props: { dirty?: boolean } = {}) =>
  mount(Component, {
    props: { formId: "form", ...props },
    global: { stubs: { Btn: { template: "<button><slot /></button>" } } },
  });

const clickCancel = (wrapper: ReturnType<typeof mountWith>) =>
  wrapper.get('[data-test="submit-cancel"]').trigger("click");

const confirmOptions = (): AppConfirmOptions =>
  displayConfirm.mock.calls[0][0] as AppConfirmOptions;

describe("BaseFormActions", () => {
  beforeEach(() => {
    displayConfirm.mockClear();
    dismissConfirm.mockClear();
  });

  it("cancels straight away when the form is not dirty", async () => {
    const wrapper = mountWith();

    await clickCancel(wrapper);

    expect(displayConfirm).not.toHaveBeenCalled();
    expect(wrapper.emitted("cancel")).toHaveLength(1);
  });

  it("waits for the confirmation before cancelling a dirty form", async () => {
    const wrapper = mountWith({ dirty: true });

    await clickCancel(wrapper);

    expect(wrapper.emitted("cancel")).toBeUndefined();

    await confirmOptions().onConfirm?.();

    expect(wrapper.emitted("cancel")).toHaveLength(1);
  });

  it("dismisses a confirmation still pending at unmount", async () => {
    const wrapper = mountWith({ dirty: true });

    await clickCancel(wrapper);
    wrapper.unmount();

    expect(dismissConfirm).toHaveBeenCalled();
  });

  it("leaves the dialog alone once the confirmation was accepted", async () => {
    const wrapper = mountWith({ dirty: true });

    await clickCancel(wrapper);
    await confirmOptions().onConfirm?.();
    wrapper.unmount();

    expect(dismissConfirm).not.toHaveBeenCalled();
  });

  it("leaves the dialog alone once the confirmation was dismissed", async () => {
    const wrapper = mountWith({ dirty: true });

    await clickCancel(wrapper);
    await confirmOptions().onClose?.();
    wrapper.unmount();

    expect(dismissConfirm).not.toHaveBeenCalled();
  });
});
