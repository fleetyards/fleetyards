import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";
import Component from "./contracts.vue";

// Stands in for whichever contracts page the route resolves to, so what the
// shell hands down is readable as this component's attrs.
const Page = defineComponent({
  name: "ContractsPageStub",
  // Declared, so they arrive as props rather than falling through to the DOM
  // as stringified attributes.
  props: {
    fleet: { type: Object, default: undefined },
    membership: { type: Object, default: undefined },
    resourceAccess: { type: Array, default: undefined },
  },
  render: () => h("div"),
});

const pageOf = (subject: VueWrapper) =>
  subject.findComponent({ name: "ContractsPageStub" });

const routerWithPage = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "fleet-contracts", component: Page },
      // The refusal block links home, and every app defines that route.
      { path: "/home", name: "home", component: Page },
    ],
  });

  await router.push("/");
  await router.isReady();

  return router;
};

const fleet = (
  features: string[] = [FeatureFlagName.FLEET_CONTRACTS],
  subscribed?: boolean,
) =>
  ({
    slug: "test-fleet",
    name: "Test Fleet",
    features,
    ...(subscribed === undefined ? {} : { subscribed }),
  }) as never;

const upsellOf = (subject: VueWrapper) =>
  subject.findComponent({ name: "SubscriptionRequired" });

const membership = (resourceAccess: string[] = ["fleet:contracts:manage"]) =>
  ({ fleetRole: { resourceAccess } }) as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: InstanceType<typeof Component>["$props"]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
    plugins: [await routerWithPage()],
  });

  return wrapper;
};

describe("FleetContractsRouterView", () => {
  // Every privilege-gated control on the pages below reads `resourceAccess`.
  // Forget to forward it and `checkAccess(undefined, …)` is false for all of
  // them: the board renders with no create button and a contract with no
  // publish, edit, fulfil or cancel — and nothing fails.
  it("forwards the member's privileges to the page", async () => {
    const subject = await mount({
      fleet: fleet(),
      membership: membership(["fleet:contracts:manage"]),
    });

    expect(pageOf(subject).props("resourceAccess")).toEqual([
      "fleet:contracts:manage",
    ]);
  });

  it("forwards the fleet and the membership too", async () => {
    const subject = await mount({ fleet: fleet(), membership: membership() });
    const page = pageOf(subject);

    expect(page.props("fleet")).toMatchObject({ slug: "test-fleet" });
    expect(page.props("membership")).toBeTruthy();
  });

  it("renders nothing while the fleet does not have the feature", async () => {
    const subject = await mount({ fleet: fleet([]), membership: membership() });

    expect(pageOf(subject).exists()).toBe(false);
  });

  // Whole page, not the list inside it: the filters, the toolbar and the
  // create button all belong to a feature this fleet has not got.
  it("replaces the whole section for an unsubscribed fleet", async () => {
    const subject = await mount({
      fleet: fleet(
        [FeatureFlagName.FLEET_CONTRACTS, FeatureFlagName.FLEET_SUBSCRIPTIONS],
        false,
      ),
      membership: membership(),
    });

    expect(upsellOf(subject).exists()).toBe(true);
    expect(pageOf(subject).exists()).toBe(false);
  });

  it("lets a subscribed fleet through to the page", async () => {
    const subject = await mount({
      fleet: fleet(
        [FeatureFlagName.FLEET_CONTRACTS, FeatureFlagName.FLEET_SUBSCRIPTIONS],
        true,
      ),
      membership: membership(),
    });

    expect(pageOf(subject).exists()).toBe(true);
    expect(upsellOf(subject).exists()).toBe(false);
  });

  // D10: a capability that is off is unavailable to subscribed and
  // unsubscribed fleets alike, and must never be answered with an upsell.
  it("does not sell a capability the fleet has not been given", async () => {
    const subject = await mount({
      fleet: fleet([FeatureFlagName.FLEET_SUBSCRIPTIONS], false),
      membership: membership(),
    });

    expect(upsellOf(subject).exists()).toBe(false);
    expect(pageOf(subject).exists()).toBe(false);
  });

  // Nothing above this line passes `subscribed` at all, and none of them
  // changed: while the flag is off the section behaves as it always did.
  it("is untouched while enforcement is not rolled out", async () => {
    const subject = await mount({
      fleet: fleet([FeatureFlagName.FLEET_CONTRACTS], false),
      membership: membership(),
    });

    expect(pageOf(subject).exists()).toBe(true);
    expect(upsellOf(subject).exists()).toBe(false);
  });
});
