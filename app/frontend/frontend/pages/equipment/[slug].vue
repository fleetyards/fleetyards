<script lang="ts">
export default {
  name: "EquipmentItemPage",
};
</script>

<script lang="ts" setup>
import ExternalLinks from "@/shared/components/ExternalLinks/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Availability from "@/frontend/components/Availability/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import EquipmentStatsCard from "@/frontend/components/StatsCard/Equipment/index.vue";
import ItemHero from "@/frontend/components/ItemHero/index.vue";
import ItemViews from "@/frontend/components/ItemViews/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { useCraftedFromRoute } from "@/frontend/composables/useCraftedFromRoute";
import { craftedEquipment } from "@/frontend/composables/craftedComponent";
import {
  BlueprintCraftableTypeEnum,
  EquipmentTypeEnum,
  type EquipmentAttachment,
  useBlueprints as useBlueprintsQuery,
  useEquipmentItem as useEquipmentItemQuery,
  useEquipmentItemAttachments as useEquipmentItemAttachmentsQuery,
  useEquipmentItemVersions as useEquipmentItemVersionsQuery,
  useEquipmentItemWeapons as useEquipmentItemWeaponsQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: stock, ...asyncStatus } = useEquipmentItemQuery(slug);

// A crafted part, where the address names its recipe and grades: the page
// shows the figures they leave, marked against the catalogue's.
const {
  crafted,
  recipe: craftedRecipe,
  gradesLabel: craftedGradesLabel,
  stockRoute,
} = useCraftedFromRoute(stock, craftedEquipment);

const equipment = computed(() => crafted.value ?? stock.value);

// Which recipes make this. Looked up by id, so only once the item has arrived.
const { data: blueprints, isPending: recipesPending } = useBlueprintsQuery(
  computed(() => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.EQUIPMENT,
      craftableIdEq: equipment.value?.id,
    },
  })),
  {
    query: { enabled: computed(() => Boolean(equipment.value?.id)) },
  },
);

const recipes = computed(() => blueprints.value?.items || []);

const { data: versionsData } = useEquipmentItemVersionsQuery(slug);

const versions = computed(() => versionsData.value || []);

// A hand-held weapon or tool has attachment ports; an attachment has the
// weapons it fits. Read off the catalogue item, not a crafted lot of it.
const takesAttachments = computed(
  () =>
    stock.value?.equipmentType === EquipmentTypeEnum.WEAPON ||
    stock.value?.equipmentType === EquipmentTypeEnum.TOOL,
);

const isAttachment = computed(
  () => stock.value?.equipmentType === EquipmentTypeEnum.WEAPON_ATTACHMENT,
);

const { data: attachmentsData } = useEquipmentItemAttachmentsQuery(slug, {
  query: { enabled: takesAttachments },
});

const { data: weaponsData } = useEquipmentItemWeaponsQuery(slug, {
  query: { enabled: isAttachment },
});

const weapons = computed(() => (isAttachment.value && weaponsData.value) || []);

// The game's subtype names; a port of any other kind reads as "Other".
const LABELLED_PORT_TYPES = [
  "Magazine",
  "IronSight",
  "Barrel",
  "BottomAttachment",
  "Utility",
  "Missile",
];

// Already ordered by the API, magazine first, so the groups keep that order.
// Grouped by label, so two kinds of port without one share a single card.
const ports = computed(() => {
  if (!takesAttachments.value) return [];

  const groups = new Map<string, EquipmentAttachment[]>();

  (attachmentsData.value || []).forEach((fit) => {
    const key = LABELLED_PORT_TYPES.includes(fit.portType)
      ? fit.portType
      : "other";

    groups.set(key, [...(groups.get(key) || []), fit]);
  });

  return [...groups].map(([key, fits]) => ({
    key,
    label: t(`labels.equipment.ports.${key}`),
    fits,
  }));
});

// One crumb: `/catalogue/` is a redirect rather than a page of its own.
const crumbs = computed<Crumb[]>(() => [
  { to: { name: "equipment" }, label: t("nav.catalogue.equipment") },
]);

const details = computed(() => {
  const value = equipment.value;
  if (!value) return [];

  return [
    {
      label: t("labels.equipment.equipmentType"),
      value: value.equipmentTypeLabel,
    },
    { label: t("labels.equipment.itemType"), value: value.itemTypeLabel },
    { label: t("labels.equipment.subType"), value: value.subTypeLabel },
    {
      label: t("labels.equipment.manufacturer"),
      value: value.manufacturer?.name,
    },
  ].filter((entry) => entry.value);
});

watch(
  equipment,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: t("title.equipmentItem", { name: value.name }),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="equipment" class="equipment-page">
        <BreadCrumbs :crumbs="crumbs" />

        <div class="equipment-page__masthead">
          <EquipmentIcon :equipment="equipment" class="equipment-page__icon" />

          <div class="equipment-page__title">
            <h1 class="equipment-page__name">{{ equipment.name }}</h1>
            <div v-if="equipment.manufacturer" class="equipment-page__sub">
              {{ equipment.manufacturer.name }}
            </div>
          </div>

          <div class="equipment-page__badges">
            <span v-if="equipment.slotLabel" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.slot") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.slotLabel }}
              </span>
            </span>
            <span v-if="equipment.size" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.size") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.size }}
              </span>
            </span>
            <span v-if="equipment.grade" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.grade") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.grade }}
              </span>
            </span>
            <!-- An item the current build no longer describes. It stays
                 reachable because a ledger entry points at it, so it says so
                 rather than serving the last build's figures as current. -->
            <Chip v-if="equipment.retired" :state="ChipStatesEnum.EXCLUDED">
              {{ t("labels.equipment.retired") }}
            </Chip>
          </div>
        </div>

        <ExternalLinks :title="equipment.name" />

        <p v-if="equipment.description" class="equipment-page__description">
          {{ equipment.description }}
        </p>

        <Alert
          v-if="crafted && craftedRecipe"
          :title="t('labels.logistics.crafted.lot')"
          size="compact"
          data-test="equipment-crafted"
        >
          {{
            t("labels.logistics.crafted.page", {
              recipe: craftedRecipe.name,
              grades: craftedGradesLabel,
            })
          }}
          <template #actions>
            <router-link :to="stockRoute">
              {{ t("labels.logistics.crafted.showStock") }}
            </router-link>
          </template>
        </Alert>

        <div class="equipment-page__columns">
          <div class="equipment-page__main">
            <EquipmentStatsCard
              :equipment="equipment"
              :stock="crafted ? stock : undefined"
            />

            <!-- Keyed: its gallery binds once, to the grid it mounts with. -->
            <ItemViews
              :key="equipment.id"
              :media="equipment.media"
              :name="equipment.name"
            />
          </div>

          <div class="equipment-page__rail">
            <ItemHero
              :image="equipment.storeImage"
              :holo="equipment.media?.holo"
              :name="equipment.name"
              test-id="equipment-image"
            />

            <MetricsCard
              v-if="details.length"
              :title="t('headlines.equipment.identity')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <div
                  v-for="entry in details"
                  :key="entry.label"
                  class="metrics-card__row"
                >
                  <span class="metrics-card__row__label">{{
                    entry.label
                  }}</span>
                  <span class="metrics-card__row__value">{{
                    entry.value
                  }}</span>
                </div>
              </div>
            </MetricsCard>

            <Availability
              :availability="equipment.availability"
              :retired="equipment.retired"
              scope="equipment"
              :craftable="recipes.length > 0"
              :loading="recipesPending"
            />

            <MetricsCard
              v-if="recipes.length"
              :title="t('headlines.equipment.craftedFrom')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="recipe in recipes"
                  :key="recipe.id"
                  :to="{ name: 'blueprint', params: { slug: recipe.slug } }"
                  class="metrics-card__row metrics-card__row--stack equipment-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    <CatalogueItemPopover
                      :item="{
                        type: 'Blueprint',
                        slug: recipe.slug,
                        name: recipe.name,
                      }"
                      :record="recipe"
                      :link="false"
                      :focusable="false"
                    />
                  </span>
                  <span class="metrics-card__row__value">
                    {{
                      (recipe.materials || []).map((m) => m.name).join(" · ")
                    }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>

            <MetricsCard
              v-if="versions.length"
              :title="t('headlines.equipment.versions')"
              variant="slim"
              data-test="equipment-versions"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="version in versions"
                  :key="version.id"
                  :to="{
                    name: 'equipment-item',
                    params: { slug: version.slug },
                  }"
                  class="metrics-card__row equipment-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    <CatalogueItemPopover
                      :item="{
                        type: 'Equipment',
                        slug: version.slug,
                        name: version.name,
                      }"
                      :record="version"
                      :link="false"
                      :focusable="false"
                    />
                  </span>
                </router-link>
              </div>
            </MetricsCard>

            <MetricsCard
              v-if="weapons.length"
              :title="t('headlines.equipment.fits')"
              variant="slim"
              data-test="equipment-weapons"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="weapon in weapons"
                  :key="weapon.id"
                  :to="{
                    name: 'equipment-item',
                    params: { slug: weapon.slug },
                  }"
                  class="metrics-card__row equipment-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    <CatalogueItemPopover
                      :item="{
                        type: 'Equipment',
                        slug: weapon.slug,
                        name: weapon.name,
                      }"
                      :record="weapon"
                      :link="false"
                      :focusable="false"
                    />
                  </span>
                  <span class="metrics-card__row__value">
                    {{ weapon.itemTypeLabel }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>
          </div>
        </div>

        <section
          v-if="ports.length"
          class="equipment-page__attachments"
          data-test="equipment-attachments"
        >
          <Heading level="h2" size="lg" mt mb>
            {{ t("headlines.equipment.attachments") }}
          </Heading>

          <div class="equipment-page__ports">
            <MetricsCard
              v-for="port in ports"
              :key="port.key"
              :title="port.label"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="fit in port.fits"
                  :key="fit.attachment.id"
                  :to="{
                    name: 'equipment-item',
                    params: { slug: fit.attachment.slug },
                  }"
                  class="metrics-card__row equipment-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    <CatalogueItemPopover
                      :item="{
                        type: 'Equipment',
                        slug: fit.attachment.slug,
                        name: fit.attachment.name,
                      }"
                      :record="fit.attachment"
                      :link="false"
                      :focusable="false"
                    />
                  </span>
                  <span v-if="fit.default" class="metrics-card__row__value">
                    {{ t("labels.equipment.standard") }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>
          </div>
        </section>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
