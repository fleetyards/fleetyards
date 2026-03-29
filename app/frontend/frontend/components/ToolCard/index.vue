<script lang="ts">
export default {
  name: "ToolCard",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  url: string;
  name: string;
  description: string;
  image?: string;
  disabled?: boolean;
  featured?: boolean;
  category?: string;
};

withDefaults(defineProps<Props>(), {
  image: undefined,
  disabled: false,
  featured: false,
  category: undefined,
});

const { t } = useI18n();
</script>

<template>
  <a
    v-if="!disabled"
    :href="url"
    target="_blank"
    rel="noopener"
    class="tool-card"
    :class="{ 'tool-card-featured': featured }"
    data-test="tool-card"
  >
    <div v-if="image" class="tool-card-bg">
      <img :src="image" :alt="name" loading="lazy" />
    </div>
    <div class="tool-card-overlay" />
    <div v-if="category" class="tool-card-category">
      {{ category }}
    </div>
    <div class="tool-card-content">
      <h3 class="tool-card-title">
        {{ name }}
        <i class="fa-duotone fa-arrow-up-right-from-square tool-card-icon" />
      </h3>
      <p class="tool-card-description">{{ description }}</p>
    </div>
  </a>
  <div v-else class="tool-card tool-card-disabled" data-test="tool-card">
    <div v-if="image" class="tool-card-bg">
      <img :src="image" :alt="name" loading="lazy" />
    </div>
    <div class="tool-card-overlay" />
    <div class="tool-card-banner">
      {{ t("tools.discontinued") }}
    </div>
    <div class="tool-card-content">
      <h3 class="tool-card-title">{{ name }}</h3>
      <p class="tool-card-description">{{ description }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.tool-card {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  min-height: 180px;
  border-radius: 12px;
  overflow: hidden;
  text-decoration: none;
  color: white;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
  margin-bottom: 20px;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
    color: white;
    text-decoration: none;

    .tool-card-icon {
      opacity: 1;
      transform: translateX(2px) translateY(-2px);
    }

    .tool-card-overlay {
      background: linear-gradient(
        to top,
        rgba(0, 0, 0, 0.9) 0%,
        rgba(0, 0, 0, 0.4) 60%,
        rgba(0, 0, 0, 0.2) 100%
      );
    }
  }
}

.tool-card-featured {
  min-height: 260px;

  .tool-card-title {
    font-size: 1.2rem;
  }
}

.tool-card-disabled {
  cursor: default;
  filter: grayscale(100%);
  opacity: 0.5;
  pointer-events: none;
}

.tool-card-bg {
  position: absolute;
  inset: 0;
  z-index: 0;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.tool-card-overlay {
  position: absolute;
  inset: 0;
  z-index: 1;
  background: linear-gradient(
    to top,
    rgba(0, 0, 0, 0.85) 0%,
    rgba(0, 0, 0, 0.3) 50%,
    rgba(0, 0, 0, 0.15) 100%
  );
  transition: background 0.3s ease;
}

.tool-card-category {
  position: absolute;
  top: 0.75rem;
  left: 0.75rem;
  z-index: 3;
  padding: 0.15rem 0.5rem;
  background-color: rgba(0, 0, 0, 0.5);
  border: 1px solid rgba(white, 0.15);
  border-radius: 4px;
  color: rgba(white, 0.75);
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.tool-card-content {
  position: relative;
  z-index: 2;
  padding: 1rem 1.25rem;
}

.tool-card-title {
  font-size: 1rem;
  font-weight: 600;
  margin: 0 0 0.25rem;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.6);
}

.tool-card-icon {
  width: 14px;
  height: 14px;
  opacity: 0.6;
  font-size: 0.8rem;
  transition: all 0.2s ease;
}

.tool-card-description {
  font-size: 0.8rem;
  line-height: 1.4;
  margin: 0;
  color: rgba(white, 0.85);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}

.tool-card-banner {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  z-index: 3;
  padding: 0.2rem 0;
  background-color: $warning;
  color: rgba(0, 0, 0, 0.85);
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  text-align: center;
}
</style>
