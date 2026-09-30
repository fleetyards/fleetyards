import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { WebPushStatusEnum } from "@/shared/composables/useWebPush";

const status = ref<WebPushStatusEnum>(WebPushStatusEnum.OFF);
const subscriptionId = ref<string>();
const enable = vi.fn().mockResolvedValue(true);
const disable = vi.fn().mockResolvedValue(undefined);
const destroy = vi.fn().mockResolvedValue(undefined);
const devices = ref([
  { id: "this", browser: "Firefox", os: "Linux x86_64" },
  { id: "other", browser: "Chrome", os: "Android 14" },
  { id: "bare", browser: null, os: null },
]);

vi.mock("@/shared/composables/useWebPush", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useWebPush: () => ({
    status,
    busy: ref(false),
    subscriptionId,
    refresh: vi.fn().mockResolvedValue(undefined),
    enable,
    disable,
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  usePushSubscriptions: () => ({ data: devices }),
  useDestroyPushSubscription: () => ({ mutateAsync: destroy }),
}));

import PushDevices from "./index.vue";

const mount = async (next: WebPushStatusEnum, current?: string) => {
  status.value = next;
  subscriptionId.value = current;
  const wrapper = await mountWithDefaults(PushDevices);
  await flushPromises();
  return wrapper;
};

describe("NotificationsPushDevices", () => {
  it("explains a browser that cannot receive push", async () => {
    const wrapper = await mount(WebPushStatusEnum.UNSUPPORTED);

    expect(
      wrapper.find('[data-test="push-devices-unsupported"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="push-devices-enable"]').exists()).toBe(
      false,
    );
  });

  // Nothing on the page can undo a denial, so there is no button to press.
  it("points a reader who blocked notifications at the browser", async () => {
    const wrapper = await mount(WebPushStatusEnum.DENIED);

    expect(wrapper.find('[data-test="push-devices-denied"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="push-devices-enable"]').exists()).toBe(
      false,
    );
  });

  it("offers to turn push on for this device", async () => {
    const wrapper = await mount(WebPushStatusEnum.OFF);

    await wrapper.find('[data-test="push-devices-enable"]').trigger("click");

    expect(enable).toHaveBeenCalled();
  });

  it("offers to turn it off again once on", async () => {
    const wrapper = await mount(WebPushStatusEnum.ON, "this");

    await wrapper.find('[data-test="push-devices-disable"]').trigger("click");

    expect(disable).toHaveBeenCalled();
  });

  it("lists every device and marks this one", async () => {
    const wrapper = await mount(WebPushStatusEnum.ON, "this");
    const rows = wrapper.findAll('[data-test="push-devices-device"]');

    expect(rows.map((row) => row.text())).toEqual([
      expect.stringContaining("Firefox on Linux x86_64"),
      expect.stringContaining("Chrome on Android 14"),
      expect.stringContaining("Unknown browser"),
    ]);
    expect(rows[0].text()).toContain("(this device)");
    expect(rows[0].find('[data-test="push-devices-remove"]').exists()).toBe(
      false,
    );
  });

  it("removes another device", async () => {
    const wrapper = await mount(WebPushStatusEnum.ON, "this");

    await wrapper
      .findAll('[data-test="push-devices-device"]')[1]
      .find('[data-test="push-devices-remove"]')
      .trigger("click");

    expect(destroy).toHaveBeenCalledWith({ id: "other" });
  });
});
