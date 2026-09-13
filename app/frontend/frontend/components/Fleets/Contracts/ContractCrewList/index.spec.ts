import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const member = (overrides = {}) => ({
  id: "11111111-1111-4111-8111-111111111111",
  role: "crew",
  state: "accepted",
  user: { id: "aaaa", username: "hauler" },
  requestedAt: null,
  acceptedAt: null,
  createdAt: null,
  updatedAt: null,
  ...overrides,
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: InstanceType<typeof Component>["$props"]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, { props });

  return wrapper;
};

describe("FleetContractsCrewList", () => {
  it("lists the accepted crew and leaves the withdrawn out", async () => {
    const subject = await mount({
      crew: [
        member(),
        member({ id: "2", state: "withdrawn", user: { id: "b", username: "gone" } }),
      ],
    });

    expect(subject.findAll("[data-test='contract-crew-member']")).toHaveLength(
      1,
    );
    expect(subject.text()).not.toContain("gone");
  });

  it("hides the pending requests from somebody who cannot answer them", async () => {
    const subject = await mount({
      crew: [member({ id: "3", state: "requested" })],
      canAnswer: false,
    });

    expect(subject.findAll("[data-test='contract-crew-request']")).toHaveLength(
      0,
    );
  });

  it("shows the pending requests to the lead", async () => {
    const subject = await mount({
      crew: [member({ id: "3", state: "requested" })],
      canAnswer: true,
    });

    expect(subject.findAll("[data-test='contract-crew-request']")).toHaveLength(
      1,
    );
  });

  it("emits accept with the assignment id", async () => {
    const subject = await mount({
      crew: [member({ id: "3", state: "requested" })],
      canAnswer: true,
    });

    await subject
      .find("[data-test='contract-crew-request']")
      .findAll("button")[0]
      .trigger("click");

    expect(subject.emitted("accept")?.[0]).toEqual(["3"]);
  });

  it("offers the viewer their own row as leaving rather than removing", async () => {
    const subject = await mount({
      crew: [member()],
      canAnswer: true,
      currentUserId: "aaaa",
    });

    expect(
      subject.find("[data-test='contract-crew-member']").text(),
    ).not.toContain("Remove");
  });
});
