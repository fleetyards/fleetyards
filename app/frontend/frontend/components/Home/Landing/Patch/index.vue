<script lang="ts">
export default {
  name: "HomeLandingPatch",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import Loader from "@/shared/components/Loader/index.vue";
import {
  useScDataPatchSummary,
  type ScDataPatchSummaryNewShipsItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useImageViewer } from "@/shared/composables/useImageViewer";
import fallbackArt from "@/images/bg-3.webp";
import { usePatchLoadingScreens } from "@/frontend/composables/usePatchLoadingScreens";
import {
  FIELD_UNITS,
  byMovement,
  fieldKey,
  movement,
  type PatchField,
} from "@/frontend/components/Home/Landing/Patch/patchFields";

const { t, tExists, toNumber } = useI18n();

const { data: summary, isLoading } = useScDataPatchSummary();

const release = (version?: string) => (version || "").split("-")[0];

const { pick, screenAt } = usePatchLoadingScreens();

const { openImage } = useImageViewer();

const bannerScreen = computed(() => screenAt(1));

// The banner shows a crop of the loading screen; a click opens the whole
// picture, full size rather than the representation behind the banner.
const openBanner = async () => {
  const screen = bannerScreen.value;
  if (!screen) return;

  const image = new Image();
  image.src = screen.url || screen.largeUrl || "";
  await image.decode().catch(() => undefined);

  void openImage(
    image,
    t("home.landing.patch.loadingScreen", {
      version: release(summary.value?.to.version),
    }),
  );
};

// The section shows this visit's screen behind it, so the banner takes the
// next one along when the patch shipped more than one.
const banner = computed(() => pick(1, fallbackArt));

const counts = computed(() => {
  const all = summary.value?.counts;
  if (!all) return [];

  return [
    { key: "newShips", value: all.newShips },
    { key: "changedShips", value: all.changedShips },
    { key: "newComponents", value: all.newComponents },
    { key: "newEquipment", value: all.newEquipment },
  ].filter((count) => count.value > 0);
});

type ChangeCard = {
  key: string;
  kind: string;
  name: string;
  to?: RouteLocationRaw;
  image?: string;
  fields: PatchField[];
};

const shipCards = computed<ChangeCard[]>(() =>
  (summary.value?.shipChanges || []).map((change) => ({
    key: change.model.id,
    kind: "models",
    name: change.model.name,
    to: { name: "ship", params: { slug: change.model.slug } },
    image: change.model.storeImage?.mediumUrl,
    fields: byMovement(change.fields),
  })),
);

const itemRoute = (
  kind: string,
  slug?: string,
): RouteLocationRaw | undefined => {
  if (!slug) return undefined;

  return kind === "equipment"
    ? { name: "equipment-item", params: { slug } }
    : { name: "component", params: { slug } };
};

const itemCards = computed<ChangeCard[]>(() =>
  (summary.value?.itemChanges || []).map((change) => ({
    key: change.id,
    kind: change.kind,
    name: change.name || "",
    to: itemRoute(change.kind, change.slug || undefined),
    fields: byMovement(change.fields),
  })),
);

const newShips = computed(() => summary.value?.newShips || []);

const biggest = computed(() => summary.value?.shipChanges[0]);

// Three cards: the new ships lead, the biggest change follows. A patch
// without new ships leads with what moved most instead.
const layout = computed(() => {
  if (newShips.value.length) {
    return {
      kind: "new" as const,
      ships: newShips.value.slice(0, biggest.value ? 2 : 3),
    };
  }

  const changes = [...shipCards.value, ...itemCards.value].slice(0, 3);
  if (changes.length) {
    return { kind: "changes" as const, changes };
  }

  return {
    kind: "quiet" as const,
    ships: (summary.value?.latestArrivals || []).slice(0, 2),
  };
});

const fieldLabel = (field: string) => {
  const key = `home.landing.patch.fields.${fieldKey(field)}`;
  if (tExists(key)) return t(key);

  const words = field.replace(/[._]/g, " ");

  return words.charAt(0).toUpperCase() + words.slice(1);
};

const formatValue = (field: string, value: PatchField["from"]) => {
  if (value === null || value === undefined) return "—";
  if (typeof value === "boolean") {
    return t(value ? "home.landing.patch.yes" : "home.landing.patch.no");
  }
  if (typeof value === "string") return value;

  return String(toNumber(value, FIELD_UNITS[field] || ""));
};

const percent = (field: PatchField) => {
  const moved = movement(field);
  if (moved === undefined) return undefined;

  const rounded = Math.round(moved * 100);
  if (rounded === 0) return undefined;

  return `${rounded > 0 ? "+" : "−"}${Math.abs(rounded)}%`;
};

// How much of the larger side the smaller one is, so a halving draws a half
// bar whichever way it went.
const share = (field: PatchField) => {
  if (typeof field.from !== "number" || typeof field.to !== "number") {
    return 100;
  }
  const larger = Math.max(Math.abs(field.from), Math.abs(field.to));
  if (!larger) return 100;

  return Math.round(
    (Math.min(Math.abs(field.from), Math.abs(field.to)) / larger) * 100,
  );
};

const shipRoute = (ship: ScDataPatchSummaryNewShipsItem): RouteLocationRaw => ({
  name: "ship",
  params: { slug: ship.slug },
});

type DiffLine = {
  key: string;
  sign: "+" | "~" | "−";
  name: string;
  text: string;
  to?: RouteLocationRaw;
};

const summaryOf = (fields: PatchField[]) => {
  const [first, ...rest] = fields;
  if (!first) return "";

  const head = `${fieldLabel(first.field)} ${formatValue(first.field, first.from)} → ${formatValue(first.field, first.to)}`;
  if (!rest.length) return head;

  return `${head}, ${t("home.landing.patch.moreFields", { count: rest.length })}`;
};

const shipLines = computed<DiffLine[]>(() => [
  ...newShips.value.map((ship) => ({
    key: `new-${ship.id}`,
    sign: "+" as const,
    name: ship.name,
    text: [t("home.landing.patch.newShip"), ship.manufacturerName]
      .filter(Boolean)
      .join(" · "),
    to: shipRoute(ship),
  })),
  ...shipCards.value.map((card) => ({
    key: `changed-${card.key}`,
    sign: "~" as const,
    name: card.name,
    text: summaryOf(card.fields),
    to: card.to,
  })),
]);

const itemLines = computed<DiffLine[]>(() => {
  const all = summary.value?.counts;
  const lines: DiffLine[] = itemCards.value.map((card) => ({
    key: `changed-${card.key}`,
    sign: "~" as const,
    name: card.name,
    text: summaryOf(card.fields),
    to: card.to,
  }));

  if (all?.newComponents) {
    lines.push({
      key: "new-components",
      sign: "+",
      name: t("home.landing.patch.appeared.components", {
        count: all.newComponents,
      }),
      text: "",
    });
  }
  if (all?.newEquipment) {
    lines.push({
      key: "new-equipment",
      sign: "+",
      name: t("home.landing.patch.appeared.equipment", {
        count: all.newEquipment,
      }),
      text: "",
    });
  }
  if (all?.vanishedEquipment) {
    lines.push({
      key: "vanished-equipment",
      sign: "−",
      name: t("home.landing.patch.vanished.equipment", {
        count: all.vanishedEquipment,
      }),
      text: "",
    });
  }

  return lines;
});

// Six lines a column keeps the section to one screen; the rest is a link away.
const MAX_LINES = 6;

const diffColumns = computed(() => {
  const counted = itemLines.value.filter(
    (line) => line.key.startsWith("new-") || line.key.startsWith("vanished-"),
  );
  const changed = itemLines.value.filter((line) => !counted.includes(line));

  return [
    shipLines.value.slice(0, MAX_LINES),
    [...changed.slice(0, Math.max(0, MAX_LINES - counted.length)), ...counted],
  ].filter((lines) => lines.length);
});
</script>

<template>
  <section data-test="home-landing-patch">
    <Heading :level="HeadingLevelEnum.H2" hero>
      {{ t("home.landing.patch.title") }}
    </Heading>
    <p class="home-landing-patch__subline">
      {{ t("home.landing.patch.subline") }}
    </p>
    <div class="relative">
      <Transition name="fade-quick" appear>
        <div v-if="summary" class="home-landing-patch">
          <component
            :is="bannerScreen ? 'button' : 'div'"
            :type="bannerScreen ? 'button' : undefined"
            class="home-landing-patch__card home-landing-patch__banner"
            :class="{ 'home-landing-patch__banner--open': bannerScreen }"
            :style="{ backgroundImage: `url(${banner})` }"
            :aria-label="
              bannerScreen
                ? t('home.landing.patch.openLoadingScreen')
                : undefined
            "
            data-test="home-landing-patch-banner"
            @click="openBanner"
          >
            <div class="home-landing-patch__banner-inner">
              <div class="home-landing-patch__version">
                <span class="home-landing-patch__micro">
                  {{
                    t("home.landing.patch.comparedWith", {
                      version: release(summary.from.version),
                    })
                  }}
                </span>
                <div class="home-landing-patch__version-row">
                  <span class="home-landing-patch__version-name">
                    {{
                      t("home.landing.patch.version", {
                        version: release(summary.to.version),
                      })
                    }}
                  </span>
                  <Pill :variant="PillVariantsEnum.SUCCESS" uppercase>
                    {{ summary.to.environment }}
                  </Pill>
                </div>
              </div>
              <dl v-if="counts.length" class="home-landing-patch__counts">
                <div v-for="count in counts" :key="count.key">
                  <dt>{{ t(`home.landing.patch.counts.${count.key}`) }}</dt>
                  <dd>{{ count.value }}</dd>
                </div>
              </dl>
            </div>
          </component>

          <div
            class="home-landing-patch__row"
            :class="`home-landing-patch__row--${layout.kind}`"
          >
            <template v-if="layout.kind === 'new' || layout.kind === 'quiet'">
              <div
                v-if="layout.kind === 'quiet'"
                class="home-landing-patch__card home-landing-patch__note"
              >
                <span class="home-landing-patch__micro">
                  {{ t("nav.ships.index") }}
                </span>
                <h3>{{ t("home.landing.patch.noShipChanges") }}</h3>
                <p>{{ t("home.landing.patch.noShipChangesText") }}</p>
                <router-link
                  :to="{ name: 'ships' }"
                  class="home-landing-patch__link"
                >
                  {{ t("home.landing.patch.browseShips") }}
                  <i class="fa-light fa-arrow-right" />
                </router-link>
              </div>
              <router-link
                v-for="ship in layout.ships"
                :key="ship.id"
                :to="shipRoute(ship)"
                class="home-landing-patch__card home-landing-patch__ship"
              >
                <img
                  v-if="ship.storeImage"
                  :src="ship.storeImage.largeUrl || ship.storeImage.url"
                  alt=""
                  loading="lazy"
                />
                <span class="home-landing-patch__ship-caption">
                  <Pill :variant="PillVariantsEnum.DEFAULT" uppercase>
                    {{
                      layout.kind === "new"
                        ? t("home.landing.patch.newThisPatch")
                        : t("home.landing.patch.newIn", {
                            version: release(
                              summary.latestArrivalsVersion || "",
                            ),
                          })
                    }}
                  </Pill>
                  <span class="home-landing-patch__ship-name">
                    {{ ship.name }}
                  </span>
                  <span class="home-landing-patch__dim">
                    {{ ship.manufacturerName }}
                  </span>
                </span>
              </router-link>
              <router-link
                v-if="layout.kind === 'new' && biggest"
                :to="{ name: 'ship', params: { slug: biggest.model.slug } }"
                class="home-landing-patch__card home-landing-patch__biggest"
              >
                <span class="home-landing-patch__biggest-head">
                  <img
                    v-if="biggest.model.previewImage"
                    :src="
                      biggest.model.previewImage.mediumUrl ||
                      biggest.model.previewImage.url
                    "
                    alt=""
                    loading="lazy"
                  />
                  <span>
                    <span class="home-landing-patch__micro">
                      {{ t("home.landing.patch.biggestChange") }}
                    </span>
                    <span class="home-landing-patch__biggest-name">
                      {{ biggest.model.name }}
                    </span>
                  </span>
                </span>
                <span class="home-landing-patch__deltas">
                  <span
                    v-for="field in byMovement(biggest.fields).slice(0, 4)"
                    :key="field.field"
                    class="home-landing-patch__delta"
                  >
                    <span>{{ fieldLabel(field.field) }}</span>
                    <span class="home-landing-patch__delta-values">
                      <span class="home-landing-patch__dim">
                        {{ formatValue(field.field, field.from) }}
                      </span>
                      <i class="fa-light fa-arrow-right" aria-hidden="true" />
                      {{ formatValue(field.field, field.to) }}
                    </span>
                    <span class="home-landing-patch__delta-percent">
                      {{ percent(field) }}
                    </span>
                    <span class="home-landing-patch__delta-bar">
                      <span :style="{ width: `${share(field)}%` }" />
                    </span>
                  </span>
                </span>
              </router-link>
            </template>
            <template v-else>
              <component
                :is="card.to ? 'router-link' : 'div'"
                v-for="card in layout.changes"
                :key="card.key"
                :to="card.to"
                class="home-landing-patch__card home-landing-patch__change"
              >
                <span
                  class="home-landing-patch__change-visual"
                  :class="{
                    'home-landing-patch__change-visual--icon': !card.image,
                  }"
                >
                  <img v-if="card.image" :src="card.image" alt="" />
                  <i
                    v-else
                    :class="
                      card.kind === 'equipment'
                        ? 'fa-duotone fa-person-rifle'
                        : 'fa-duotone fa-microchip'
                    "
                    aria-hidden="true"
                  />
                </span>
                <span class="home-landing-patch__change-body">
                  <span class="home-landing-patch__micro">
                    {{ t(`home.landing.patch.kinds.${card.kind}`) }}
                  </span>
                  <span class="home-landing-patch__change-name">
                    {{ card.name }}
                  </span>
                  <span
                    v-for="field in card.fields.slice(0, 2)"
                    :key="field.field"
                    class="home-landing-patch__delta"
                  >
                    <span>{{ fieldLabel(field.field) }}</span>
                    <span class="home-landing-patch__delta-values">
                      <span class="home-landing-patch__dim">
                        {{ formatValue(field.field, field.from) }}
                      </span>
                      <i class="fa-light fa-arrow-right" aria-hidden="true" />
                      {{ formatValue(field.field, field.to) }}
                    </span>
                    <span class="home-landing-patch__delta-percent">
                      {{ percent(field) }}
                    </span>
                  </span>
                </span>
              </component>
            </template>
          </div>

          <div
            v-if="diffColumns.length"
            class="home-landing-patch__card home-landing-patch__diff"
          >
            <div class="home-landing-patch__diff-head">
              <span>
                {{ release(summary.from.version) }}
                <i class="fa-light fa-arrow-right" aria-hidden="true" />
                {{ release(summary.to.version) }}
              </span>
              <router-link
                :to="{ name: 'stats' }"
                class="home-landing-patch__link"
              >
                {{ t("home.landing.patch.seeEveryChange") }}
                <i class="fa-light fa-arrow-right" />
              </router-link>
            </div>
            <div
              class="home-landing-patch__diff-columns"
              :class="{
                'home-landing-patch__diff-columns--single':
                  diffColumns.length === 1,
              }"
            >
              <ul
                v-for="(lines, index) in diffColumns"
                :key="index"
                class="home-landing-patch__lines"
              >
                <li
                  v-for="line in lines"
                  :key="line.key"
                  class="home-landing-patch__line"
                  :class="{
                    'home-landing-patch__line--added': line.sign === '+',
                  }"
                >
                  <span
                    class="home-landing-patch__line-sign"
                    aria-hidden="true"
                  >
                    {{ line.sign }}
                  </span>
                  <router-link
                    v-if="line.to"
                    :to="line.to"
                    class="home-landing-patch__line-name"
                  >
                    {{ line.name }}
                  </router-link>
                  <span v-else class="home-landing-patch__line-name">
                    {{ line.name }}
                  </span>
                  <span class="home-landing-patch__line-text">
                    {{ line.text }}
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </Transition>
      <Loader :loading="isLoading" />
    </div>
  </section>
</template>

<style lang="scss" scoped>
.home-landing-patch {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.home-landing-patch__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim);
}

.home-landing-patch__card {
  position: relative;
  display: block;
  overflow: hidden;
  color: inherit;
  text-decoration: none;
  background: rgb(39 43 48 / 92%);
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
}

a.home-landing-patch__card {
  transition: border-color 0.2s ease;

  &:hover,
  &:focus-visible {
    color: inherit;
    text-decoration: none;
    border-color: var(--color-edge);
  }
}

.home-landing-patch__micro {
  display: block;
  font-family: Orbitron, sans-serif;
  font-size: 10px;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.16em;
}

.home-landing-patch__dim {
  color: var(--color-text-dim);
}

.home-landing-patch__link {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-family: "Open Sans", sans-serif;
  font-size: 13px;
  color: var(--color-lifted);
  text-decoration: none;

  &:hover {
    color: var(--color-lifted);
    text-decoration: underline;
  }
}

.home-landing-patch__banner {
  width: 100%;
  height: 112px;
  padding: 0;
  font: inherit;
  text-align: left;
  background-position: center 30%;
  background-size: cover;
  // The picture stops at the frame, or its bright edge reads as a coloured
  // border under the scrim.
  background-clip: padding-box;

  &::before {
    position: absolute;
    inset: 0;
    content: "";
    background: linear-gradient(
      90deg,
      rgb(10 14 19 / 94%) 0%,
      rgb(10 14 19 / 55%) 45%,
      rgb(10 14 19 / 60%) 65%,
      rgb(10 14 19 / 90%) 100%
    );
  }
}

.home-landing-patch__banner--open {
  cursor: zoom-in;

  &:hover,
  &:focus-visible {
    border-color: var(--color-edge);
  }
}

.home-landing-patch__banner-inner {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  height: 100%;
  padding: 0 24px;
}

.home-landing-patch__version {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-landing-patch__version-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.home-landing-patch__version-name {
  font-family: Orbitron, sans-serif;
  font-size: 28px;
  color: var(--color-lifted);
}

.home-landing-patch__counts {
  display: flex;
  gap: 28px;
  margin: 0;

  div {
    display: flex;
    flex-direction: column-reverse;
    align-items: flex-end;
  }

  dt {
    font-size: 12px;
    font-weight: 400;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-family: Orbitron, sans-serif;
    font-size: 26px;
    color: var(--color-lifted);
  }
}

.home-landing-patch__row {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.home-landing-patch__row--new {
  grid-template-columns: 1fr 1fr 1.1fr;
}

.home-landing-patch__row--quiet {
  grid-template-columns: 1.1fr 1fr 1fr;
}

.home-landing-patch__ship {
  height: 236px;

  img {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  &::after {
    position: absolute;
    inset: 0;
    content: "";
    background: linear-gradient(180deg, transparent 40%, rgb(10 14 19 / 94%));
  }
}

.home-landing-patch__ship-caption {
  position: absolute;
  right: 18px;
  bottom: 14px;
  left: 18px;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  font-size: 12.5px;
}

.home-landing-patch__ship-name {
  margin-top: 6px;
  font-family: Orbitron, sans-serif;
  font-size: 18px;
  color: var(--color-lifted);
}

.home-landing-patch__note {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 10px;
  height: 236px;
  padding: 22px;
  box-sizing: border-box;

  h3 {
    margin: 0;
    font-family: Orbitron, sans-serif;
    font-size: 18px;
    font-weight: 400;
    color: var(--color-lifted);
  }

  p {
    margin: 0;
    font-size: 13.5px;
    line-height: 20px;
    color: var(--color-text-dim);
  }
}

.home-landing-patch__biggest {
  display: flex;
  flex-direction: column;
  height: 236px;
}

.home-landing-patch__biggest-head {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 18px 6px;

  img {
    width: 130px;
    height: 64px;
    object-fit: contain;
  }
}

.home-landing-patch__biggest-name {
  display: block;
  margin-top: 3px;
  font-family: Orbitron, sans-serif;
  font-size: 15px;
  color: var(--color-lifted);
}

.home-landing-patch__deltas {
  display: flex;
  flex: 1;
  flex-direction: column;
  justify-content: center;
  gap: 8px;
  padding: 0 18px 14px;
}

.home-landing-patch__delta {
  display: grid;
  grid-template-columns: 1fr auto 44px;
  gap: 3px 10px;
  align-items: baseline;
  font-size: 12.5px;
  color: var(--color-text);
}

.home-landing-patch__delta-values {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
  color: var(--color-lifted);
  font-variant-numeric: tabular-nums;

  i {
    color: var(--color-muted);
  }
}

.home-landing-patch__delta-percent {
  font-weight: 600;
  color: var(--color-lifted);
  text-align: right;
}

.home-landing-patch__delta-bar {
  grid-column: 1 / -1;
  height: 3px;
  background: rgb(122 130 136 / 20%);
  border-radius: 2px;

  span {
    display: block;
    height: 100%;
    background: var(--color-primary);
    border-radius: 2px;
  }
}

.home-landing-patch__change {
  display: flex;
  flex-direction: column;
  height: 236px;
}

.home-landing-patch__change-visual {
  flex: none;
  height: 104px;
  overflow: hidden;
  background: #0e141b;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.home-landing-patch__change-visual--icon {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  color: var(--color-muted);
}

.home-landing-patch__change-body {
  display: flex;
  flex-direction: column;
  gap: 7px;
  padding: 12px 16px 14px;
}

.home-landing-patch__change-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--color-lifted);
}

.home-landing-patch__diff {
  font:
    12.5px/19px ui-monospace,
    Menlo,
    monospace;
  background: rgb(5 7 12 / 92%);
}

.home-landing-patch__diff-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  color: var(--color-text-dim);
  border-bottom: 1px solid var(--color-edge-soft);
}

.home-landing-patch__diff-columns {
  display: grid;
  grid-template-columns: 1fr 1fr;

  > ul + ul {
    border-left: 1px solid rgb(122 130 136 / 12%);
  }
}

.home-landing-patch__diff-columns--single {
  grid-template-columns: 1fr;
}

.home-landing-patch__lines {
  margin: 0;
  padding: 0;
  list-style: none;
}

.home-landing-patch__line {
  display: grid;
  grid-template-columns: 18px minmax(0, 220px) minmax(0, 1fr);
  gap: 10px;
  padding: 6px 16px;
  border-bottom: 1px solid rgb(122 130 136 / 8%);
}

.home-landing-patch__line-sign {
  color: #e0b45a;
}

.home-landing-patch__line--added {
  background: rgb(111 207 122 / 6%);

  .home-landing-patch__line-sign {
    color: #6fcf7a;
  }
}

.home-landing-patch__line-name {
  overflow: hidden;
  color: var(--color-lifted);
  text-decoration: none;
  white-space: nowrap;
  text-overflow: ellipsis;
}

a.home-landing-patch__line-name:hover {
  color: var(--color-lifted);
  text-decoration: underline;
}

.home-landing-patch__line-text {
  overflow: hidden;
  color: var(--color-text-dim);
  white-space: nowrap;
  text-overflow: ellipsis;
}

@media (max-width: 1199px) {
  .home-landing-patch__counts {
    gap: 18px;
  }

  .home-landing-patch__diff-columns {
    grid-template-columns: 1fr;

    > ul + ul {
      border-left: 0;
    }
  }
}

@media (max-width: 991px) {
  .home-landing-patch__banner {
    height: auto;
  }

  .home-landing-patch__banner-inner {
    flex-direction: column;
    align-items: flex-start;
    padding: 18px 20px;
  }

  .home-landing-patch__counts div {
    align-items: flex-start;
  }

  .home-landing-patch__row,
  .home-landing-patch__row--new,
  .home-landing-patch__row--quiet {
    grid-template-columns: minmax(0, 1fr);
  }

  .home-landing-patch__line {
    grid-template-columns: 18px minmax(0, 1fr);
  }

  .home-landing-patch__line-text {
    grid-column: 2;
  }
}
</style>
