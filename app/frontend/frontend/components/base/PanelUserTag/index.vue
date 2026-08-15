<script lang="ts">
export default {
  name: "PanelUserTag",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import PanelTag from "@/frontend/components/base/PanelTag/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

type Props = {
  label: string;
  member: MemberContact;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <BtnDropdown>
    <template #trigger="{ toggle, visible }">
      <PanelTag aria-haspopup="menu" :aria-expanded="visible" @click="toggle">
        {{ label }}
        <span class="panel-user-tag-name">{{ member.username }}</span>
        <span
          v-if="member.citizenidProfileUrl"
          v-tooltip="t('labels.user.rsiHandleVerified')"
          class="panel-user-tag-badge"
        >
          <i class="fa-duotone fa-badge-check" />
        </span>
        <i class="fa-light fa-chevron-down panel-user-tag-caret" />
      </PanelTag>
    </template>
    <MemberContactMenu :member="member" :hangar="true" />
  </BtnDropdown>
</template>

<style lang="scss" scoped>
.panel-user-tag-name {
  font-weight: 600;
}

.panel-user-tag-badge {
  font-size: 0.9em;
  line-height: 1;
}

.panel-user-tag-caret {
  font-size: 0.9em;
  opacity: 0.8;
}
</style>
