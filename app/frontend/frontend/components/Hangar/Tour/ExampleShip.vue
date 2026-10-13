<script lang="ts">
export default {
  name: "HangarTourExampleShip",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Panel class="tour-example-ship" data-test="tour-example-ship">
    <div class="tour-example-ship__heading">
      <span data-tour="vehicle-overview" class="tour-example-ship__title">
        {{ t("texts.hangarTour.exampleShip.title") }}
      </span>
      <div data-tour="vehicle-menu">
        <button type="button" disabled :aria-label="t('actions.more')">
          <i class="fa-solid fa-ellipsis-v" />
        </button>
      </div>
    </div>
    <div class="tour-example-ship__image">
      <DuotoneGlyph :glyph="SHIP_GLYPH" />
    </div>
    <p>{{ t("texts.hangarTour.exampleShip.text") }}</p>
  </Panel>
</template>

<style lang="scss" scoped>
.tour-example-ship {
  width: min(100%, 380px);
  padding: 18px;

  &__heading {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  &__title {
    font-size: 18px;
    font-weight: 600;
  }

  button {
    padding: 8px 12px;
    border: 0;
    background: transparent;
    color: inherit;
  }

  &__image {
    display: flex;
    justify-content: center;
    padding: 24px;
    font-size: 100px;
    color: var(--color-primary);
  }

  p {
    margin: 0;
  }
}
</style>
