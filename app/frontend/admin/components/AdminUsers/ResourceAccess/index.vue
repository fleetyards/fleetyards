<script lang="ts">
export default {
  name: "AdminUsersResourceAccess",
};
</script>

<script lang="ts" setup>
import {
  type AdminUserResourceAccessEnum,
  useResourceAccessCatalog,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  modelValue?: AdminUserResourceAccessEnum[];
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
});

const emit = defineEmits(["update:modelValue"]);

const { t } = useI18n();

const { data: resourceAccessCatalog } = useResourceAccessCatalog();

const hasPrivilege = (privilege: AdminUserResourceAccessEnum) =>
  props.modelValue.includes(privilege);

const togglePrivilege = (privilege: AdminUserResourceAccessEnum) => {
  emit(
    "update:modelValue",
    hasPrivilege(privilege)
      ? props.modelValue.filter((entry) => entry !== privilege)
      : [...props.modelValue, privilege],
  );
};
</script>

<template>
  <div v-if="resourceAccessCatalog" class="resource-access">
    <h3 class="resource-access-title">
      {{ t("labels.admin.resourceAccess.title") }}
    </h3>
    <div class="resource-access-groups">
      <div
        v-for="group in resourceAccessCatalog"
        :key="group.key"
        class="resource-access-group"
      >
        <h4 class="resource-access-group-name">
          {{ t(`labels.admin.resourceAccess.groups.${group.key}`) }}
        </h4>
        <label
          v-for="privilege in group.privileges"
          :key="privilege"
          class="resource-access-item"
        >
          <input
            type="checkbox"
            :checked="hasPrivilege(privilege)"
            @change="togglePrivilege(privilege)"
          />
          {{ t(`labels.admin.resourceAccess.privileges.${privilege}`) }}
        </label>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.resource-access {
  margin-top: 20px;
}

.resource-access-title {
  margin: 0 0 12px;
}

.resource-access-groups {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 20px;
}

.resource-access-group-name {
  margin: 0 0 8px;
  font-size: 0.9em;
  text-transform: uppercase;
  opacity: 0.7;
}

.resource-access-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  cursor: pointer;
}
</style>
