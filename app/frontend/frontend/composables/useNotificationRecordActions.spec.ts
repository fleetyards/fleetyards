import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

type QueryStub = {
  data: ReturnType<typeof ref>;
  isLoading: ReturnType<typeof ref<boolean>>;
  isError: ReturnType<typeof ref<boolean>>;
  refetch: ReturnType<typeof vi.fn>;
};

const stub = (): QueryStub => ({
  data: ref(undefined),
  isLoading: ref(false),
  isError: ref(false),
  refetch: vi.fn(),
});

const queries = {
  ownMembership: stub(),
  member: stub(),
  event: stub(),
  vehicle: stub(),
  sync: stub(),
};

const mutations = {
  acceptFleetMembership: vi.fn(),
  declineFleetMembership: vi.fn(),
  acceptFleetMember: vi.fn(),
  declineFleetMember: vi.fn(),
  signupFleetEvent: vi.fn(),
  syncRsiHangar: vi.fn(),
  updateVehicle: vi.fn(),
};

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useFleetMembership: () => queries.ownMembership,
  useFleetMember: () => queries.member,
  useFleetEvent: () => queries.event,
  useShowVehicle: () => queries.vehicle,
  useSyncRsiHangarStatus: () => queries.sync,
  ...mutations,
}));

const { useNotificationRecordActions } =
  await import("./useNotificationRecordActions");
const {
  NotificationRecordTypeEnum,
  NotificationTypeEnum,
  FleetEventSignupStatusEnum,
} = await import("@/services/fyApi");

type AnyRecord = Record<string, unknown>;

const notificationRef = (notificationType: string, record: AnyRecord) =>
  ref({
    id: "notification-1",
    notificationType,
    title: "A notification",
    read: false,
    archived: false,
    expiresAt: "2026-09-01T00:00:00Z",
    createdAt: "2026-08-01T00:00:00Z",
    updatedAt: "2026-08-01T00:00:00Z",
    record,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } as any);

const membershipRecord = {
  type: NotificationRecordTypeEnum.FLEET_MEMBERSHIP,
  id: "membership-1",
  fleetSlug: "test-fleet",
  username: "newcomer",
};

const eventRecord = {
  type: NotificationRecordTypeEnum.FLEET_EVENT,
  id: "event-1",
  fleetSlug: "test-fleet",
  eventSlug: "mining-run",
};

beforeEach(() => {
  Object.values(queries).forEach((query) => {
    query.data.value = undefined;
    query.isLoading.value = false;
    query.isError.value = false;
  });
  Object.values(mutations).forEach((mutation) => mutation.mockReset());
});

describe("useNotificationRecordActions", () => {
  it("offers an answer while the invite is still open", async () => {
    queries.ownMembership.data.value = { status: "invited" };

    const { actions } = useNotificationRecordActions(
      notificationRef(NotificationTypeEnum.FLEET_INVITE, membershipRecord),
    );

    expect(actions.value.map((action) => action.key)).toEqual([
      "accept",
      "decline",
    ]);

    await actions.value[0].run();

    expect(mutations.acceptFleetMembership).toHaveBeenCalledWith("test-fleet");
  });

  it("offers nothing once the invite has been answered elsewhere", () => {
    queries.ownMembership.data.value = { status: "accepted" };

    const { actions } = useNotificationRecordActions(
      notificationRef(NotificationTypeEnum.FLEET_INVITE, membershipRecord),
    );

    expect(actions.value).toEqual([]);
  });

  it("answers a join request through the member endpoint", async () => {
    queries.member.data.value = { status: "requested" };

    const { actions } = useNotificationRecordActions(
      notificationRef(
        NotificationTypeEnum.FLEET_MEMBER_REQUESTED,
        membershipRecord,
      ),
    );

    await actions.value[1].run();

    expect(mutations.declineFleetMember).toHaveBeenCalledWith(
      "test-fleet",
      "newcomer",
    );
  });

  it("only offers a sign-up while sign-ups are open and the event is ahead", async () => {
    const notification = notificationRef(
      NotificationTypeEnum.FLEET_EVENT_PUBLISHED,
      eventRecord,
    );

    const { actions } = useNotificationRecordActions(notification);

    queries.event.data.value = { signupsOpen: false, past: false };
    expect(actions.value).toEqual([]);

    queries.event.data.value = { signupsOpen: true, past: true };
    expect(actions.value).toEqual([]);

    queries.event.data.value = { signupsOpen: true, past: false };
    expect(actions.value.map((action) => action.key)).toEqual(["signUp"]);

    await actions.value[0].run();

    expect(mutations.signupFleetEvent).toHaveBeenCalledWith(
      "test-fleet",
      "mining-run",
      { status: FleetEventSignupStatusEnum.CONFIRMED },
    );
  });

  it("withdraws through the same upsert rather than hunting for the slot", async () => {
    queries.event.data.value = { signupsOpen: true, past: false };

    const { actions } = useNotificationRecordActions(
      notificationRef(
        NotificationTypeEnum.FLEET_EVENT_SIGNUP_CONFIRMED,
        eventRecord,
      ),
    );

    await actions.value[0].run();

    expect(mutations.signupFleetEvent).toHaveBeenCalledWith(
      "test-fleet",
      "mining-run",
      { status: FleetEventSignupStatusEnum.WITHDRAWN },
    );
  });

  it("does not offer a second sync while one is running", () => {
    const notification = notificationRef(
      NotificationTypeEnum.HANGAR_SYNC_FAILED,
      { type: NotificationRecordTypeEnum.HANGAR_SYNC, id: "import-1" },
    );

    const { actions } = useNotificationRecordActions(notification);

    queries.sync.data.value = { active: true };
    expect(actions.value).toEqual([]);

    queries.sync.data.value = { active: false };
    expect(actions.value.map((action) => action.key)).toEqual(["syncAgain"]);
  });

  it("moves a wished-for ship into the hangar and links the store", async () => {
    queries.vehicle.data.value = {
      id: "vehicle-1",
      wanted: true,
      model: { links: { storeUrl: "https://robertsspaceindustries.com/x" } },
    };

    const { actions, externalLink } = useNotificationRecordActions(
      notificationRef(NotificationTypeEnum.MODEL_ON_SALE, {
        type: NotificationRecordTypeEnum.VEHICLE,
        id: "vehicle-1",
      }),
    );

    await actions.value[0].run();

    expect(mutations.updateVehicle).toHaveBeenCalledWith("vehicle-1", {
      wanted: false,
    });
    expect(externalLink.value?.href).toBe(
      "https://robertsspaceindustries.com/x",
    );
  });

  it("says the record is gone rather than offering buttons that cannot work", () => {
    queries.ownMembership.isError.value = true;

    const { actions, isUnavailable } = useNotificationRecordActions(
      notificationRef(NotificationTypeEnum.FLEET_INVITE, membershipRecord),
    );

    expect(isUnavailable.value).toBe(true);
    expect(actions.value).toEqual([]);
  });
});
