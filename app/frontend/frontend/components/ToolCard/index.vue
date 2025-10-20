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

type Props = {
  url: string;
  name: string;
  description: string;
  image?: string;
};

defineProps<Props>();
</script>

<template>
  <Panel :bg-image="image" :shadow="PanelShadowsEnum.TOP" class="tool-card">
    <PanelHe
    ading :level="HeadingLevelEnum.H3" class="tool-card-heading">
      <template #default>
        <a :href="url" target="_blank" rel="noopener" class="tool-card-link">
          {{ name }}
          <i
            class="fad fa-arrow-up-right-from-square tool-card-external-icon"
          />
        </a>
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
  position: relative;
  overflow: hidden;

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(
      to top,
      rgba(0, 0, 0, 0.85) 0%,
      rgba(0, 0, 0, 0.6) 40%,
      rgba(0, 0, 0, 0.3) 70%,
      transparent 100%
    );
    z-index: 1;
  }
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

  &:hover {
    color: $primary;
    text-decoration: none;
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

.tool-card-description {
  color: rgba(white, 0.9);
  font-size: 0.9rem;
  margin-top: 0.5rem;
  line-height: 1.4;
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
