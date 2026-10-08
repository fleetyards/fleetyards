import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { AxiosError, type AxiosResponse } from "axios";
import {
  FleetDiscordConnectionCodeEnum,
  type FilterOption,
  type Fleet,
  type FleetDiscordRoleMappings,
  type FleetMember,
  type FleetNotificationSetting,
} from "@/services/fyApi";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Component from "./discord.vue";

let setting: FleetNotificationSetting;
let roleMappings: FleetDiscordRoleMappings;
const mutateAsync = vi.fn();
const updateRoleMappings = vi.fn();
const discordStatus = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

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
    useFleetDiscordRoleMappings: () => ({
      data: ref(roleMappings),
      refetch: vi.fn(),
    }),
    useUpdateFleetDiscordRoleMappings: () => ({
      mutateAsync: updateRoleMappings,
    }),
    useFleetDiscordChannels: () => ({
      data: ref({ code: FleetDiscordConnectionCodeEnum.OK, items: [] }),
      isLoading: ref(false),
    }),
    useFleetDiscordRoles: () => ({
      data: ref({
        code: FleetDiscordConnectionCodeEnum.OK,
        items: [
          { id: "300000000000000001", name: "Member" },
          { id: "300000000000000002", name: "Officer" },
        ],
      }),
      isLoading: ref(false),
    }),
    fleetNotificationDiscordStatus: () => discordStatus(),
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  mutateAsync.mockReset().mockResolvedValue({});
  updateRoleMappings.mockReset().mockResolvedValue({});
  discordStatus.mockReset().mockResolvedValue({ ok: true });
  roleMappings = {
    items: [
      { fleetRoleId: "rank-officer", name: "Officer", discordRoleId: null },
      {
        fleetRoleId: "rank-member",
        name: "Member",
        discordRoleId: "300000000000000001",
      },
    ],
  };
  displayAlert.mockReset();
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

const mount = async (membership = {} as FleetMember) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", defaultTimezone: "Europe/Berlin" } as Fleet,
      membership,
    },
  });
  await flushPromises();

  return wrapper;
};

type SelectProps = {
  name?: string;
  modelValue?: unknown;
  options?: FilterOption[];
  disabled?: boolean;
};

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
      discordDigestTimezone:
        Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
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

  // Somebody elsewhere saving the page for another reason must not move the
  // digest into their own zone.
  it("keeps the saved zone while the day and time are left alone", async () => {
    setting.discordDigestWeekday = 1;
    setting.discordDigestTime = "18:00";
    setting.discordDigestTimezone = "Pacific/Chatham";

    const subject = await mount();

    const timeField = subject
      .findAllComponents(FormInput)
      .find(
        (input) =>
          (input.props() as { name?: string }).name === "discordDigestTime",
      )!;
    expect((timeField.props() as { info?: string }).info).toContain(
      "Pacific/Chatham",
    );
    expect(await save(subject)).toMatchObject({
      discordDigestTimezone: "Pacific/Chatham",
    });
  });

  it("takes this browser's zone once the time is changed", async () => {
    setting.discordDigestWeekday = 1;
    setting.discordDigestTime = "18:00";
    setting.discordDigestTimezone = "Pacific/Chatham";

    const subject = await mount();
    await subject.find('input[name="discordDigestTime"]').setValue("19:00");

    expect(await save(subject)).toMatchObject({
      discordDigestTime: "19:00",
      discordDigestTimezone:
        Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
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
      discordDigestTimezone: null,
    });
  });
});

describe("FleetDiscordSettingsPage save", () => {
  it("shows why the server rejected an id", async () => {
    const message =
      'Discord guild must be the numeric ID Discord copies with "Copy ID", not a name';
    mutateAsync.mockRejectedValue(
      new AxiosError("request failed", undefined, undefined, undefined, {
        status: 400,
        data: {
          code: "validation_error.fleet_notification_settings.update",
          message: "Could not update the settings",
          errors: [
            {
              attribute: "discordGuildId",
              messages: [{ code: "invalid", message }],
            },
          ],
        },
      } as AxiosResponse),
    );

    const subject = await mount();
    await subject
      .find('input[name="discordGuildId"]')
      .setValue("Stanton Haulers [SHL]");
    await save(subject);

    expect(displayAlert).toHaveBeenCalledWith({ text: message });
  });

  it("falls back to the generic failure without field errors", async () => {
    mutateAsync.mockRejectedValue(new Error("network"));

    const subject = await mount();
    await save(subject);

    expect(displayAlert).toHaveBeenCalledWith({
      text: "Could not save notification settings.",
    });
  });
});

describe("FleetDiscordSettingsPage join role", () => {
  const inviter = { capabilities: { createInvites: true } } as FleetMember;

  const joinRoleSelect = (subject: VueWrapper) =>
    subject
      .findAllComponents(BaseSelect)
      .find((select) => selectProps(select).name === "discordJoinRoleId");

  it("is hidden from a member who may not hand out invites", async () => {
    setting.discordJoinRoleId = "300000000000000001";
    const subject = await mount();

    expect(joinRoleSelect(subject)).toBeUndefined();
    expect(await save(subject)).not.toHaveProperty("discordJoinRoleId");
  });

  it("saves the role picked by a member who may hand out invites", async () => {
    const subject = await mount(inviter);

    joinRoleSelect(subject)!.vm.$emit(
      "update:modelValue",
      "300000000000000001",
    );
    await flushPromises();

    expect(await save(subject)).toMatchObject({
      discordJoinRoleId: "300000000000000001",
    });
  });

  it("clears the role", async () => {
    setting.discordJoinRoleId = "300000000000000001";
    const subject = await mount(inviter);

    joinRoleSelect(subject)!.vm.$emit("update:modelValue", null);
    await flushPromises();

    expect(await save(subject)).toMatchObject({ discordJoinRoleId: null });
  });
});

describe("FleetDiscordSettingsPage server change", () => {
  const inviter = { capabilities: { createInvites: true } } as FleetMember;

  const picker = (subject: VueWrapper, name: string) =>
    subject
      .findAllComponents(BaseSelect)
      .find((select) => selectProps(select).name === name)!;

  it("holds back the old server's channels and role until the new one is saved", async () => {
    setting.discordGuildId = "100000000000000001";
    setting.discordAnnouncementChannelId = "200000000000000001";
    setting.discordJoinRoleId = "300000000000000001";
    const subject = await mount(inviter);

    await subject
      .find('input[name="discordGuildId"]')
      .setValue("100000000000000002");
    await flushPromises();

    expect(subject.find('[data-test="save-guild-first"]').exists()).toBe(true);
    expect(selectProps(picker(subject, "discordJoinRoleId")).disabled).toBe(
      true,
    );
    expect(
      selectProps(picker(subject, "discordAnnouncementChannelId")).disabled,
    ).toBe(true);

    const data = await save(subject);
    expect(data).toMatchObject({ discordGuildId: "100000000000000002" });
    expect(data).not.toHaveProperty("discordJoinRoleId");
    expect(data).not.toHaveProperty("discordAnnouncementChannelId");
    expect(data).not.toHaveProperty("discordOfficersChannelId");
  });
});

describe("FleetDiscordSettingsPage role mapping", () => {
  const picker = (subject: VueWrapper, name: string) =>
    subject
      .findAllComponents(BaseSelect)
      .find((select) => selectProps(select).name === name)!;

  const pick = async (subject: VueWrapper, name: string, value: unknown) => {
    picker(subject, name).vm.$emit("update:modelValue", value);
    await flushPromises();
  };

  it("offers a role for the members and one per rank", async () => {
    const subject = await mount();

    expect(picker(subject, "discordMemberRoleId")).toBeDefined();
    expect(picker(subject, "rankRole-rank-officer")).toBeDefined();
    expect(picker(subject, "rankRole-rank-member")).toBeDefined();
  });

  it("saves the member role with the settings", async () => {
    const subject = await mount();

    await pick(subject, "discordMemberRoleId", "300000000000000002");

    expect(await save(subject)).toMatchObject({
      discordMemberRoleId: "300000000000000002",
    });
  });

  it("sends only the ranks that changed, clearing with null", async () => {
    const subject = await mount();

    await pick(subject, "rankRole-rank-officer", "300000000000000002");
    await pick(subject, "rankRole-rank-member", null);
    await save(subject);

    expect(updateRoleMappings).toHaveBeenCalledWith({
      fleetSlug: "maru",
      data: {
        mappings: [
          { fleetRoleId: "rank-officer", discordRoleId: "300000000000000002" },
          { fleetRoleId: "rank-member", discordRoleId: null },
        ],
      },
    });
  });

  it("leaves the ranks alone when none changed", async () => {
    const subject = await mount();

    await save(subject);

    expect(mutateAsync).toHaveBeenCalled();
    expect(updateRoleMappings).not.toHaveBeenCalled();
  });

  it("holds back the roles until a new server is saved", async () => {
    setting.discordGuildId = "100000000000000001";
    const subject = await mount();

    await pick(subject, "rankRole-rank-officer", "300000000000000002");
    await pick(subject, "discordMemberRoleId", "300000000000000002");
    await subject
      .find('input[name="discordGuildId"]')
      .setValue("100000000000000002");
    await flushPromises();

    expect(selectProps(picker(subject, "rankRole-rank-officer")).disabled).toBe(
      true,
    );
    expect(await save(subject)).not.toHaveProperty("discordMemberRoleId");
    expect(updateRoleMappings).not.toHaveBeenCalled();
  });

  it("keeps the saved settings and the rank picks when the ranks are rejected", async () => {
    const settingsSaves = mutateAsync.mock.calls.length;
    updateRoleMappings.mockRejectedValue(new Error("rejected"));
    const subject = await mount();

    await pick(subject, "rankRole-rank-officer", "300000000000000002");
    await save(subject);

    expect(mutateAsync.mock.calls.length).toBe(settingsSaves + 1);
    expect(displayAlert).toHaveBeenCalled();
    expect(discordStatus).toHaveBeenCalledTimes(2);
    expect(
      selectProps(picker(subject, "rankRole-rank-officer")).modelValue,
    ).toBe("300000000000000002");
  });

  it("names the roles the bot cannot hand out", async () => {
    discordStatus.mockResolvedValue({
      ok: true,
      rolesOk: false,
      rolesCode: "role_above_bot",
      rolesDetail: "300000000000000002, 300000000000000009",
    });
    const subject = await mount();

    const problem = subject.find('[data-test="roles-problem"]');
    expect(problem.text()).toContain("@Officer, 300000000000000009");
  });
});
