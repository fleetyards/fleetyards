<script lang="ts">
export default {
  name: "FleetMemberName",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";
import { useVerifiedOrgLabel } from "@/frontend/composables/useVerifiedOrgLabel";

type Props = {
  member: MemberContact;
  // Off where the caller shows the badge on the member's avatar instead.
  orgBadge?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  orgBadge: true,
});

const hasContactOptions = computed(
  () => !!props.member.rsiHandle || !!props.member.discordProfileUrl,
);

const verifiedOrgLabel = useVerifiedOrgLabel();

const orgBadgeLabel = computed(() =>
  props.orgBadge ? verifiedOrgLabel(props.member) : undefined,
);

const displayName = computed(
  () => props.member.nickname || props.member.username,
);

// The username never goes away, only moves to second place: it is what every
// link and lookup resolves on, and a nickname the fleet chose is not identity.
const secondaryName = computed(() =>
  props.member.nickname ? props.member.username : undefined,
);
</script>

<template>
  <span class="member-name">
    <template v-if="hasContactOptions">
      <BtnDropdown :variant="BtnVariantsEnum.BARE" :clip-label="!orgBadgeLabel">
        <template #label>
          <span class="member-name__display"
            ><span class="member-name__text">{{ displayName }}</span
            ><span
              v-if="orgBadgeLabel"
              v-tooltip="orgBadgeLabel"
              :aria-label="orgBadgeLabel"
              class="member-name__badge"
              data-test="member-verified-org"
            >
              <i class="fa-duotone fa-shield-check text-success" />
            </span>
          </span>
          <span v-if="secondaryName" class="member-name__username">
            {{ secondaryName }}
          </span>
        </template>
        <MemberContactMenu :member="member" />
      </BtnDropdown>
    </template>
    <template v-else>
      <span class="member-name__display"
        ><span class="member-name__text">{{ displayName }}</span
        ><span
          v-if="orgBadgeLabel"
          v-tooltip="orgBadgeLabel"
          :aria-label="orgBadgeLabel"
          class="member-name__badge"
          data-test="member-verified-org"
        >
          <i class="fa-duotone fa-shield-check text-success" />
        </span>
      </span>
      <span v-if="secondaryName" class="member-name__username">
        {{ secondaryName }}
      </span>
    </template>
  </span>
</template>

<style lang="scss" scoped>
.member-name {
  display: inline-flex;
  align-items: center;
  min-width: 0;
  max-width: 100%;

  &__display {
    position: relative;
    display: inline-flex;
    min-width: 0;
    max-width: 100%;
  }

  // The name truncates on its own, so a long nickname still ends in an
  // ellipsis on a button that no longer clips its label for the badge.
  &__text {
    overflow: hidden;
    min-width: 0;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  // Placed like the badge on the RSI handle: past the name's right edge and
  // above it, so only its corner touches the name. The org this fleet proved
  // it runs, not the member's own handle, which is badged where it is shown.
  &__badge {
    position: absolute;
    z-index: 1;
    top: 0;
    right: 0;
    transform: translate(75%, -35%);
    font-size: 0.85em;
    line-height: 1;
    --fa-secondary-color: color-mix(
      in srgb,
      currentColor 40%,
      var(--color-background, #000)
    );
    --fa-secondary-opacity: 1;
  }

  &__username {
    margin-left: 0.35em;
    font-size: 0.85em;
    opacity: 0.8;
  }
}
</style>
