import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";
import Component from "./index.vue";

const mountName = (member: MemberContact) =>
  mountWithDefaults(Component, { props: { member } });

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
});
