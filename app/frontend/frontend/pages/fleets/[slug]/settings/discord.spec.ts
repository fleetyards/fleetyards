import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  FleetDiscordConnectionCodeEnum,
  type FilterOption,
  type Fleet,
  type FleetMember,
  type FleetNotificationSetting,
} from "@/services/fyApi";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Component from "./discord.vue";

let setting: FleetNotificationSetting;
const mutateAsync = vi.fn();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetNotificationSetting: () => ({
      data: ref(setting),
      refetch: vi.fn(),
    }),
    useUpdateFleetNotificationSetting: () => ({ mutateAsync }),
    useFleetDiscordChannels: () => ({
      data: ref({ code: FleetDiscordConnectionCodeEnum.OK, items: [] }),
      isLoading: ref(false),
    }),
    fleetNotificationDiscordStatus: vi.fn().mockResolvedValue({ ok: true }),
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  mutateAsync.mockReset().mockResolvedValue({});
  setting = {
    id: "setting",
    fleetId: "fleet",
    enabledInAppEvents: [],
    discordWebhookConfigured: false,
    discordDigestWeekday: null,
    discordDigestTime: null,
  } as FleetNotificationSetting;
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", defaultTimezone: "Europe/Berlin" } as Fleet,
      membership: {} as FleetMember,
    },
  });
  await flushPromises();

  return wrapper;
};

type SelectProps = { name?: string; options?: FilterOption[] };

// BaseSelect is generic, so its props type narrows to nothing from outside.
const selectProps = (select: VueWrapper) => select.props() as SelectProps;

const weekdaySelect = (subject: VueWrapper) =>
  subject
    .findAllComponents(BaseSelect)
    .find((select) => selectProps(select).name === "discordDigestWeekday")!;

const timeInput = (subject: VueWrapper) =>
  subject.find('input[name="discordDigestTime"]');

const save = async (subject: VueWrapper) => {
  await subject.find("form").trigger("submit");
  await flushPromises();

  return mutateAsync.mock.calls.at(-1)?.[0].data;
};

describe("FleetDiscordSettingsPage digest", () => {
  it("offers the week Monday first, keeping Ruby's Sunday-first values", async () => {
    const subject = await mount();

    expect(
      selectProps(weekdaySelect(subject)).options?.map(
        (option) => option.value,
      ),
    ).toEqual(["1", "2", "3", "4", "5", "6", "0"]);
  });

  it("asks for a time only once a day is picked, starting from 18:00", async () => {
    const subject = await mount();

    expect(timeInput(subject).exists()).toBe(false);

    weekdaySelect(subject).vm.$emit("update:modelValue", "1");
    await flushPromises();

    expect((timeInput(subject).element as HTMLInputElement).value).toBe(
      "18:00",
    );
    expect(await save(subject)).toMatchObject({
      discordDigestWeekday: 1,
      discordDigestTime: "18:00",
    });
  });

  // Sunday is 0, which a truthiness check would read as "off".
  it("keeps Sunday as a day, not as switched off", async () => {
    setting.discordDigestWeekday = 0;
    setting.discordDigestTime = "09:00";

    const subject = await mount();

    expect(timeInput(subject).exists()).toBe(true);
    expect(await save(subject)).toMatchObject({
      discordDigestWeekday: 0,
      discordDigestTime: "09:00",
    });
  });

  it("switches the digest off with its time", async () => {
    setting.discordDigestWeekday = 1;
    setting.discordDigestTime = "18:30";

    const subject = await mount();

    weekdaySelect(subject).vm.$emit("update:modelValue", null);
    await flushPromises();

    expect(await save(subject)).toMatchObject({
      discordDigestWeekday: null,
      discordDigestTime: null,
    });
  });
});
