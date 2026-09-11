<script lang="ts">
export default {
  name: "FleetMemberName",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

type Props = {
  member: MemberContact;
};

const props = defineProps<Props>();

const { t } = useI18n();

const hasContactOptions = computed(
  () => !!props.member.rsiHandle || !!props.member.discordProfileUrl,
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
      <BtnDropdown :variant="BtnVariantsEnum.BARE">
        <template #label>
          <span>{{ displayName }}</span>
          <span v-if="secondaryName" class="member-name__username">
            {{ secondaryName }}
          </span>
          <span
            v-if="member.citizenidProfileUrl"
            v-tooltip="t('labels.user.rsiHandleVerified')"
            class="member-name__badge"
          >
            <i class="fa-duotone fa-badge-check text-success" />
          </span>
        </template>
        <MemberContactMenu :member="member" />
      </BtnDropdown>
    </template>
    <template v-else>
      <span>{{ displayName }}</span>
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

  &__badge {
    font-size: 0.85em;
    line-height: 1;
  }

  &__username {
    margin-left: 0.35em;
    font-size: 0.85em;
    opacity: 0.8;
  }
}
</style>
