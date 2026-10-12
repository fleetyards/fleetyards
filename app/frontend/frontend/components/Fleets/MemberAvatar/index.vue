<script lang="ts">
export default {
  name: "FleetMemberAvatar",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import type { FleetMember } from "@/services/fyApi";
import { useVerifiedOrgLabel } from "@/frontend/composables/useVerifiedOrgLabel";

type Props = {
  member: Pick<
    FleetMember,
    "avatar" | "squadrons" | "verifiedOrgSid" | "verificationCheckedAt"
  >;
  online?: boolean;
  showSquadrons?: boolean;
  // A roster row's bubble, or a card's: the larger one draws a sharper image
  // and a squadron mark that is still legible beside it.
  size?: "small" | "medium";
};

const props = withDefaults(defineProps<Props>(), {
  online: undefined,
  showSquadrons: false,
  size: "small",
});

const avatarUrl = computed(() =>
  props.size === "medium"
    ? (props.member.avatar?.mediumUrl ?? props.member.avatar?.smallUrl)
    : props.member.avatar?.smallUrl,
);

const verifiedOrgLabel = useVerifiedOrgLabel();

const orgBadgeLabel = computed(() => verifiedOrgLabel(props.member));

const squadronNames = computed(() =>
  (props.member.squadrons ?? [])
    .map((squadron) =>
      squadron.role
        ? `${squadron.name} · ${squadron.role.name}`
        : squadron.name,
    )
    .join(", "),
);
</script>

<template>
  <span class="member-avatar">
    <Avatar :avatar="avatarUrl" :size="size" :online="online" />
    <span
      v-if="orgBadgeLabel"
      v-tooltip="orgBadgeLabel"
      :aria-label="orgBadgeLabel"
      class="member-avatar__verified"
      data-test="member-verified-org"
    >
      <i class="fa-duotone fa-shield-check text-success" />
    </span>
    <SquadronEmblem
      v-if="showSquadrons && member.squadrons?.length"
      v-tooltip="squadronNames"
      :squadron="member.squadrons[0]"
      :size="size === 'medium' ? 20 : 14"
      class="member-avatar__squadron"
    />
  </span>
</template>

<style lang="scss" scoped>
.member-avatar {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
}

// The top-right corner, the one neither the squadron nor the presence dot
// takes. Centred where the dot is centred below it -- the dot is 10px and sits
// flush in its corner -- so the two line up whatever the badge's size. Opaque
// in the colour the default 40% duotone layer shows over the page, so the
// avatar does not show through it.
.member-avatar__verified {
  position: absolute;
  top: 5px;
  right: 5px;
  transform: translate(50%, -50%);
  font-size: 14px;
  line-height: 1;
  --fa-secondary-color: color-mix(
    in srgb,
    currentColor 40%,
    var(--color-background, #000)
  );
  --fa-secondary-opacity: 1;
}

// The bottom-left corner, mirroring the presence dot on the bottom-right:
// centred 5px in from both edges, as the dot is, and as small as the verified
// badge above it.
.member-avatar__squadron {
  position: absolute;
  left: 5px;
  bottom: 5px;
  transform: translate(-50%, 50%);
}
</style>
