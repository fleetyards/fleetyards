<script lang="ts">
export default {
  name: "ToolCard",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelShadowsEnum } from "@/shared/components/base/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  url: string;
  name: string;
  description: string;
  image?: string;
  disabled?: boolean;
};

withDefaults(defineProps<Props>(), {
  image: undefined,
  disabled: false,
});

const { t } = useI18n();
</script>

<template>
  <Panel
    :bg-image="image"
    :bg-overlay="true"
    :shadow="PanelShadowsEnum.TOP"
    class="tool-card"
    :class="{ 'tool-card-disabled': disabled }"
  >
    <div v-if="disabled" class="tool-card-banner">
      {{ t("tools.discontinued") }}
    </div>
    <PanelHeading :level="HeadingLevelEnum.H3" class="tool-card-heading">
      <template #default>
        <a
          v-if="!disabled"
          :href="url"
          target="_blank"
          rel="noopener"
          class="tool-card-link"
        >
          {{ name }}
          <i
            class="fa-duotone fa-arrow-up-right-from-square tool-card-external-icon"
          />
        </a>
        <span v-else class="tool-card-link tool-card-link-disabled">
          {{ name }}
        </span>
      </template>
      <template #subtitle>
        <div class="tool-card-description">{{ description }}</div>
      </template>
    </PanelHeading>
  </Panel>
</template>

<style lang="scss" scoped>
.tool-card {
  cursor: pointer;
  overflow: hidden;
}

.tool-card-disabled {
  cursor: default;
  filter: grayscale(100%);
  opacity: 0.6;
  pointer-events: none;
}

.tool-card-heading {
  position: relative;
  z-index: 2;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 1.5rem;
}

.tool-card-link {
  color: white;
  text-decoration: none;
  font-weight: 600;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: color 0.3s ease;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.6);

  &:hover {
    color: $primary;
    text-decoration: none;
  }
}

.tool-card-link-disabled {
  cursor: default;

  &:hover {
    color: white;
  }
}

.tool-card-external-icon {
  width: 16px;
  height: 16px;
  opacity: 0.8;
  transition: all 0.3s ease;

  .tool-card-link:hover & {
    opacity: 1;
    transform: translateX(2px) translateY(-2px);
  }
}

.tool-card-banner {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  z-index: 3;
  padding: 0.25rem 0;
  background-color: $warning;
  color: rgba(0, 0, 0, 0.85);
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  border-radius: $panelContentBorderRadius $panelContentBorderRadius 0 0;
}

.tool-card-description {
  color: rgba(white, 0.95);
  font-size: 0.9rem;
  margin-top: 0.5rem;
  line-height: 1.4;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.6);
}

@media (max-width: 768px) {
  .tool-card {
    min-height: 150px;
  }

  .tool-card-heading {
    padding: 1rem;
  }

  .tool-card-link {
    font-size: 1rem;
  }
}
</style>
