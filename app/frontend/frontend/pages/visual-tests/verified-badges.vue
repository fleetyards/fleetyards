<script lang="ts">
export default {
  name: "VisualTestsVerifiedBadgesPage",
};
</script>

<script lang="ts" setup>
import MemberAvatar from "@/frontend/components/Fleets/MemberAvatar/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import type { FleetMember, FleetSquadronRef } from "@/services/fyApi";

// Every place a verified mark is drawn, on the page and on a panel: the
// badges are opaque in the page's colour, so a panel is where they would
// show it.
const surfaces = ["page", "panel"] as const;

const citizenidProfileUrl = "https://citizenid.space/profile/example";

const squadron: FleetSquadronRef = {
  id: "squadron",
  name: "Combat Wing",
  slug: "combat-wing",
  color: "#c0392b",
  team: false,
};

type AvatarCase = {
  label: string;
  member: Pick<FleetMember, "avatar" | "squadrons" | "verifiedOrgSid">;
  online?: boolean;
};

const avatarCases: AvatarCase[] = [
  { label: "Not verified", member: {} },
  { label: "Verified member", member: { verifiedOrgSid: "MARU" } },
  {
    label: "Verified, online",
    member: { verifiedOrgSid: "MARU" },
    online: true,
  },
  {
    label: "Verified, offline",
    member: { verifiedOrgSid: "MARU" },
    online: false,
  },
  {
    label: "Verified, online, in a squadron",
    member: { verifiedOrgSid: "MARU", squadrons: [squadron] },
    online: true,
  },
];
</script>

<template>
  <template v-for="surface in surfaces" :key="surface">
    <Heading :level="HeadingLevelEnum.H2" mt>
      {{ surface === "page" ? "On the page" : "On a panel" }}
    </Heading>
    <component
      :is="surface === 'page' ? 'div' : Panel"
      :data-test="`verified-badges-${surface}`"
    >
      <component :is="surface === 'page' ? 'div' : PanelBody">
        <Heading :level="HeadingLevelEnum.H3">Fleet organisation</Heading>
        <p class="verified-badges__row">
          <RsiProfileLink sid="MARU" verified icon-only large />
          <RsiProfileLink sid="MARU" icon-only large />
          <RsiProfileLink sid="MARU" verified icon-only />
          <RsiProfileLink sid="MARU" verified />
        </p>

        <Heading :level="HeadingLevelEnum.H3">RSI handle</Heading>
        <p class="verified-badges__row">
          <RsiProfileLink
            handle="TorlekMaru"
            :citizenid-profile-url="citizenidProfileUrl"
          />
          <RsiProfileLink handle="TorlekMaru" />
          <RsiProfileLink
            handle="TorlekMaru"
            :citizenid-profile-url="citizenidProfileUrl"
            icon-only
          />
          <RsiProfileLink handle="TorlekMaru" icon-only />
        </p>

        <Heading :level="HeadingLevelEnum.H3">Member name</Heading>
        <p class="verified-badges__row">
          <MemberName
            :member="{
              username: 'torlek',
              rsiHandle: 'TorlekMaru',
              verifiedOrgSid: 'MARU',
            }"
          />
          <MemberName
            :member="{
              username: 'torlek',
              nickname: 'Torlek',
              rsiHandle: 'TorlekMaru',
              verifiedOrgSid: 'MARU',
            }"
          />
          <MemberName :member="{ username: 'torlek' }" />
        </p>
        <p class="verified-badges__narrow">
          <MemberName
            :member="{
              username: 'torlek',
              nickname:
                'Torlek of the Long Watch, Keeper of the Outer Beacons and Pilot of Last Resort',
              rsiHandle: 'TorlekMaru',
              verifiedOrgSid: 'MARU',
            }"
          />
        </p>

        <Heading :level="HeadingLevelEnum.H3">Member avatar</Heading>
        <div class="verified-badges__row">
          <span
            v-for="avatarCase in avatarCases"
            :key="avatarCase.label"
            class="verified-badges__avatar"
          >
            <MemberAvatar
              :member="avatarCase.member"
              :online="avatarCase.online"
              show-squadrons
            />
            <small>{{ avatarCase.label }}</small>
          </span>
        </div>

        <Heading :level="HeadingLevelEnum.H3">Member row</Heading>
        <div class="verified-badges__member">
          <MemberAvatar
            :member="{ verifiedOrgSid: 'MARU', squadrons: [squadron] }"
            online
            show-squadrons
          />
          <span class="verified-badges__member-name">
            <MemberName
              :member="{
                username: 'torlek',
                rsiHandle: 'TorlekMaru',
                verifiedOrgSid: 'MARU',
              }"
              :org-badge="false"
            />
            <RsiProfileLink
              handle="TorlekMaru"
              :citizenid-profile-url="citizenidProfileUrl"
            />
          </span>
        </div>
      </component>
    </component>
  </template>
</template>

<style lang="scss" scoped>
.verified-badges__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 2em;
}

// A column as narrow as the members table gives a name on a phone.
.verified-badges__narrow {
  max-width: 220px;
}

.verified-badges__avatar {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.verified-badges__member {
  display: flex;
  align-items: center;
  gap: 10px;
}

.verified-badges__member-name {
  display: flex;
  flex-direction: column;
}
</style>
