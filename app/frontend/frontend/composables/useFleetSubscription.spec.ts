import { beforeEach, describe, expect, it, vi } from "vitest";
import { FeatureFlagName } from "@/services/fyApi/models/FeatureFlagName";

const viewerFeatures = ref<string[]>([]);

vi.mock("@/services/fyApi", async () => {
  const flags = await vi.importActual(
    "@/services/fyApi/models/FeatureFlagName.ts",
  );

  return {
    ...flags,
    useFeatures: () => ({ data: viewerFeatures }),
    getFeaturesQueryOptions: () => ({}),
  };
});

vi.mock("@/shared/composables/usePrefetch", () => ({
  usePrefetch: () => ({ fetchData: () => undefined }),
}));

const { useFleetSubscription } = await import("./useFleetSubscription");

const rolledOut = (subscribed?: boolean) => ({
  features: [FeatureFlagName.FLEET_SUBSCRIPTIONS as string],
  ...(subscribed === undefined ? {} : { subscribed }),
});

describe("useFleetSubscription", () => {
  beforeEach(() => {
    viewerFeatures.value = [];
  });

  // The whole of D16 as a surface sees it: until the flag is on for a fleet,
  // entitlement is never asked about and nothing changes for anybody.
  it("asks nothing while enforcement is not rolled out", () => {
    const fleet = { features: [], subscribed: false };

    expect(useFleetSubscription(fleet).subscriptionRequired.value).toBe(false);
  });

  it("refuses an unsubscribed fleet once it is rolled out", () => {
    expect(
      useFleetSubscription(rolledOut(false)).subscriptionRequired.value,
    ).toBe(true);
  });

  it("lets a subscribed fleet through", () => {
    expect(
      useFleetSubscription(rolledOut(true)).subscriptionRequired.value,
    ).toBe(false);
  });

  // A payload that predates the field, or a public fleet read signed out,
  // carries no answer. The safe reading of that is "not subscribed".
  it("treats a missing subscribed field as unsubscribed", () => {
    expect(useFleetSubscription(rolledOut()).subscriptionRequired.value).toBe(
      true,
    );
  });

  it("asks nothing about a fleet it has not got", () => {
    expect(useFleetSubscription(undefined).subscriptionRequired.value).toBe(
      false,
    );
  });

  // The check below ORs in the viewer's own flags, so with the rollout enabled
  // for the viewer an absent fleet passed it and the missing `subscribed` then
  // read as unsubscribed. The case above misses it by clearing the viewer.
  it("asks nothing about an absent fleet even when the viewer is rolled out", () => {
    viewerFeatures.value = [FeatureFlagName.FLEET_SUBSCRIPTIONS];

    expect(useFleetSubscription(undefined).subscriptionRequired.value).toBe(
      false,
    );
  });

  // Matches `Flipper.enabled?(flag, current_resource_owner, fleet)`: rolled out
  // to the viewer counts too, which is how it is tried on one account first.
  it("reads the enforcement flag from the viewer as well", () => {
    viewerFeatures.value = [FeatureFlagName.FLEET_SUBSCRIPTIONS];

    expect(
      useFleetSubscription({ features: [], subscribed: false })
        .subscriptionRequired.value,
    ).toBe(true);
  });
});
