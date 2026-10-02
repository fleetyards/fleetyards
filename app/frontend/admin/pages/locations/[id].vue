<script lang="ts">
export default {
  name: "AdminLocationPage",
};
</script>

<script lang="ts" setup>
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import { useLocation } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { isGlobeKind, sunStyle } from "@/shared/utils/LocationGlobe";

const { t } = useI18n();

const route = useRoute();

const locationId = computed(() => route.params.id as string);

const { data: location, ...asyncStatus } = useLocation(locationId);

const { updateMetaInfo } = useMetaInfo();

watch(
  () => location.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({ title: value.name || value.scKey });
  },
  { immediate: true },
);

const crumbs = computed(() => [
  {
    to: { name: "admin-locations", hash: `#${locationId.value}` },
    label: t("nav.admin.locations.index"),
  },
  {
    to: { name: "admin-location", params: { id: locationId.value } },
    label: location.value?.name || location.value?.scKey || "",
  },
]);

const dash = "—";

const isBody = computed(() => isGlobeKind(location.value?.kind));

const isStar = computed(() => location.value?.kind === "star");

const yesNo = (value?: boolean) =>
  value ? t("labels.admin.locations.yes") : t("labels.admin.locations.no");

const details = computed((): Detail[] => {
  const record = location.value;

  if (!record) return [];

  return [
    { label: t("labels.location.name"), value: record.name },
    {
      label: t("labels.location.kind"),
      value: t(`labels.location.kinds.${record.kind}`),
    },
    { label: t("labels.admin.locations.gameType"), value: record.gameType },
    { label: t("labels.admin.locations.parent"), value: record.parent?.name },
    // The game's own parent where it is not the place this one sits in:
    // what the in-game map draws, beside where the place is.
    {
      label: t("labels.location.mapParent"),
      value: record.mapParent?.name || dash,
    },
    { label: t("labels.admin.locations.system"), value: record.system?.name },
    {
      label: t("labels.location.starmapVisibility"),
      value: yesNo(record.shownOnStarmap),
    },
    {
      label: t("labels.admin.locations.shownWithParentOnly"),
      value: yesNo(record.shownWithParentOnly),
    },
    {
      label: t("labels.location.alwaysShown"),
      value: yesNo(record.alwaysShown),
    },
    {
      label: t("labels.location.quantumTravel"),
      value: yesNo(record.quantumTravelDestination),
    },
    { label: t("labels.admin.locations.slug"), value: record.slug },
    { label: t("labels.admin.locations.scKey"), value: record.scKey },
    // More than one where the overrides merged copies, or a namesake child
    // folded in.
    {
      label: t("labels.admin.locations.scRefs"),
      value: record.scRefs.join(", ") || dash,
    },
    {
      label: t("labels.admin.locations.build"),
      value: record.version || t("labels.location.retired"),
    },
    {
      label: t("labels.admin.locations.children"),
      value: record.childrenCount,
    },
    {
      label: t("labels.admin.locations.missions"),
      value: record.gameMissionsCount,
    },
    {
      label: t("labels.admin.locations.missionTemplates"),
      value: record.missionTemplateRefs?.length,
    },
    {
      label: t("labels.location.terminals"),
      value:
        (record.terminals || [])
          .map((terminal) =>
            terminal.available
              ? terminal.name
              : `${terminal.name} (${t("labels.admin.locations.unavailable")})`,
          )
          .join(", ") || dash,
    },
  ];
});
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="locationId" />

      <div class="admin-location__head">
        <Heading hero>
          {{ location?.name || location?.scKey }}
        </Heading>

        <Btn
          :to="{ name: 'admin-location-edit', params: { id: locationId } }"
          :size="BtnSizesEnum.MD"
          data-test="location-edit"
        >
          <i class="fa-light fa-pen" aria-hidden="true" />
          {{ t("actions.edit") }}
        </Btn>
      </div>

      <section
        class="admin-location__appearance"
        data-test="location-appearance"
      >
        <LocationGlobe
          v-if="isBody && location"
          class="admin-location__globe"
          :location="location"
        />
        <span
          v-else-if="isStar"
          class="admin-location__globe admin-location__globe--star"
          :style="sunStyle(location)"
          aria-hidden="true"
        />
        <img
          v-if="location?.image"
          :src="location.image.smallUrl ?? location.image.url"
          alt=""
          class="admin-location__thumb"
        />
        <dl class="admin-location__appearance-facts">
          <div v-if="isBody || isStar">
            <dt>{{ t("labels.admin.locations.color") }}</dt>
            <dd>
              <span
                v-if="location?.color"
                class="admin-location__swatch"
                :style="{ backgroundColor: location.color }"
                aria-hidden="true"
              />
              {{ location?.color || dash }}
            </dd>
          </div>
          <div>
            <dt>{{ t("labels.admin.locations.image") }}</dt>
            <dd>
              <a
                v-if="location?.image"
                :href="location.image.url"
                target="_blank"
                rel="noopener"
              >
                {{ location.image.name }}
              </a>
              <template v-else>{{ dash }}</template>
            </dd>
          </div>
        </dl>
      </section>

      <!-- A wrong place is a parser or override fix; only its look is edited. -->
      <DetailList :details="details" data-test="location-details" />
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Locations/sun";

.admin-location {
  &__head {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 24px;
  }

  &__appearance {
    display: flex;
    align-items: center;
    gap: 20px;
    margin-bottom: 24px;
  }

  &__globe {
    display: block;
    flex-shrink: 0;
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background-color: #1d2329;
    border: 1px solid
      var(--globe-border, var(--color-edge-soft, rgb(122 130 136 / 0.55)));

    &--star {
      @include location-sun;
    }
  }

  &__appearance-facts {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin: 0;

    dt {
      font-size: 12px;
      color: var(--color-text-dim, #959595);
    }

    dd {
      display: flex;
      align-items: center;
      gap: 6px;
      margin: 0;
    }
  }

  &__thumb {
    display: block;
    flex-shrink: 0;
    width: 160px;
    height: 90px;
    object-fit: cover;
    border-radius: 8px;
  }

  &__swatch {
    display: inline-block;
    width: 14px;
    height: 14px;
    border-radius: 3px;
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.55));
  }
}
</style>
