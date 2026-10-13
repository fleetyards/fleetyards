import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";
import Component from "./index.vue";

const mountName = (member: MemberContact, orgBadge?: boolean) =>
  mountWithDefaults(Component, { props: { member, orgBadge } });

describe("FleetMemberName", () => {
  it("badges a member verified in the fleet's verified org", async () => {
    const wrapper = await mountName({
      username: "maru_pilot",
      rsiHandle: "maru_pilot",
      verifiedOrgSid: "MARU",
    });

    expect(wrapper.find('[data-test="member-verified-org"]').exists()).toBe(
      true,
    );
  });

  it("leaves the badge to the avatar when the caller shows it there", async () => {
    const wrapper = await mountName(
      {
        username: "maru_pilot",
        rsiHandle: "maru_pilot",
        verifiedOrgSid: "MARU",
      },
      false,
    );

    expect(wrapper.find('[data-test="member-verified-org"]').exists()).toBe(
      false,
    );
  });

  it("leaves a verified handle to the handle's own badge", async () => {
    const wrapper = await mountName({
      username: "maru_pilot",
      rsiHandle: "maru_pilot",
      citizenidProfileUrl: "https://citizenid.example/profile/1",
    });

    expect(wrapper.find('[data-test="member-verified-org"]').exists()).toBe(
      false,
    );
    expect(wrapper.find(".fa-badge-check").exists()).toBe(false);
  });

  it("shows the display name, with the username second", async () => {
    const wrapper = await mountName({
      username: "maru_pilot",
      displayName: "Torlek Maru",
    });

    expect(wrapper.find(".member-name__text").text()).toBe("Torlek Maru");
    expect(wrapper.find(".member-name__username").text()).toBe("maru_pilot");
  });

  it("puts the fleet's nickname before the display name", async () => {
    const wrapper = await mountName({
      username: "maru_pilot",
      displayName: "Torlek Maru",
      nickname: "Torlek",
    });

    expect(wrapper.find(".member-name__text").text()).toBe("Torlek");
    expect(wrapper.find(".member-name__username").text()).toBe("maru_pilot");
  });

  it("shows the username once without another name", async () => {
    const wrapper = await mountName({ username: "maru_pilot" });

    expect(wrapper.find(".member-name__text").text()).toBe("maru_pilot");
    expect(wrapper.find(".member-name__username").exists()).toBe(false);
  });
});
