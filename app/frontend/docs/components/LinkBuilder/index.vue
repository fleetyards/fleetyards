<script lang="ts">
export default {
  name: "DocsLinkBuilder",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import CodeExample from "@/docs/components/CodeExample/index.vue";
import { useCopy } from "@/docs/composables/useCopy";

type Target = "hangar" | "fleet" | "ship";
type Format = "html" | "markdown" | "url";

type Props = {
  frontendEndpoint: string;
  iconUrl: string;
};

const props = defineProps<Props>();

const targets: {
  key: Target;
  label: string;
  icon: string;
  field: string;
  example: string;
  path: (value: string) => string;
  text: string;
}[] = [
  {
    key: "hangar",
    label: "Hangar",
    icon: "fa-light fa-warehouse",
    field: "Username",
    example: "torlekmaru",
    path: (value) => `/hangar/${value}/`,
    text: "My hangar on FleetYards.net",
  },
  {
    key: "fleet",
    label: "Fleet",
    icon: "fa-light fa-users",
    field: "Fleet ID",
    example: "maru",
    path: (value) => `/fleets/${value}/`,
    text: "Our fleet on FleetYards.net",
  },
  {
    key: "ship",
    label: "Ship",
    icon: "fa-light fa-rocket",
    field: "Ship slug",
    example: "600i-touring",
    path: (value) => `/ships/${value}/`,
    text: "View on FleetYards.net",
  },
];

const formats: { key: Format; label: string }[] = [
  { key: "html", label: "HTML" },
  { key: "markdown", label: "Markdown" },
  { key: "url", label: "Plain URL" },
];

const target = ref<Target>("hangar");

const format = ref<Format>("html");

const values = ref<Record<Target, string>>({
  hangar: "",
  fleet: "",
  ship: "",
});

const currentTarget = computed(
  () => targets.find((entry) => entry.key === target.value) || targets[0],
);

const value = computed({
  get: () => values.value[target.value],
  set: (newValue: string) => {
    values.value = { ...values.value, [target.value]: newValue };
  },
});

const url = computed(() => {
  const segment = value.value.trim()
    ? encodeURIComponent(value.value.trim())
    : `<${currentTarget.value.field.toLowerCase().replace(" ", "-")}>`;

  return `${props.frontendEndpoint}${currentTarget.value.path(segment)}`;
});

const snippet = computed(() => {
  const text = currentTarget.value.text;

  if (format.value === "markdown") {
    return `[![FleetYards.net](${props.iconUrl})](${url.value}) [${text}](${url.value})`;
  }

  if (format.value === "url") {
    return url.value;
  }

  return `<a href="${url.value}">
  <img src="${props.iconUrl}" alt="FleetYards.net" width="32" height="32" />
  ${text}
</a>`;
});

const snippetLanguage = computed(() => {
  if (format.value === "html") {
    return "html";
  }

  if (format.value === "markdown") {
    return "markdown";
  }

  return "plaintext";
});

const { copy } = useCopy();
</script>

<template>
  <div class="link-builder" data-test="link-builder">
    <div class="link-builder__controls">
      <div>
        <div class="link-builder__label">Link to</div>
        <BtnGroup segmented aria-label="Link to">
          <Btn
            v-for="entry in targets"
            :key="entry.key"
            :active="entry.key === target"
            :data-test="`link-builder-target-${entry.key}`"
            @click="target = entry.key"
          >
            <i :class="entry.icon" aria-hidden="true"></i>
            <span>{{ entry.label }}</span>
          </Btn>
        </BtnGroup>
      </div>

      <FormInput
        :key="target"
        v-model="value"
        name="linkBuilderValue"
        :label="currentTarget.field"
        :placeholder="currentTarget.example"
        data-test="link-builder-value"
      />

      <div>
        <div class="link-builder__label">Preview</div>
        <div class="link-builder__preview">
          <div
            class="link-builder__ground link-builder__ground--dark"
            data-test="link-builder-preview"
          >
            <a
              class="link-builder__badge"
              :href="url"
              target="_blank"
              rel="noopener"
            >
              <img :src="iconUrl" alt="" width="32" height="32" />
              {{ currentTarget.text }}
            </a>
          </div>
          <div class="link-builder__ground link-builder__ground--light">
            <a
              class="link-builder__badge"
              :href="url"
              target="_blank"
              rel="noopener"
            >
              <img :src="iconUrl" alt="" width="32" height="32" />
              {{ currentTarget.text }}
            </a>
          </div>
        </div>
      </div>
    </div>

    <div class="link-builder__output">
      <div class="link-builder__output-bar">
        <BtnGroup segmented aria-label="Snippet format">
          <Btn
            v-for="entry in formats"
            :key="entry.key"
            :active="entry.key === format"
            :data-test="`link-builder-format-${entry.key}`"
            @click="format = entry.key"
          >
            {{ entry.label }}
          </Btn>
        </BtnGroup>
        <Btn data-test="link-builder-copy" @click="copy(snippet)">
          <i class="fa-light fa-copy" aria-hidden="true"></i>
          <span>Copy</span>
        </Btn>
      </div>
      <CodeExample
        :code="snippet"
        :language="snippetLanguage"
        flush
        data-test="link-builder-snippet"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/rowLabel";

.link-builder {
  display: flex;
  flex-wrap: wrap;
  gap: 2rem;
}

.link-builder__controls {
  flex: 1 1 320px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.link-builder__output {
  flex: 1 1 420px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.link-builder__output-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}

.link-builder__label {
  @include row-label;
  margin-bottom: 0.5rem;
}

.link-builder__preview {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  border: 1px solid var(--color-edge-soft);
  border-radius: 8px;
  overflow: hidden;
}

.link-builder__ground {
  display: flex;
  justify-content: center;
  padding: 1.5rem 0.75rem;
}

.link-builder__ground--dark {
  background: var(--color-gray-black);
}

.link-builder__ground--light {
  background: #e9eaec;

  .link-builder__badge,
  .link-builder__badge:hover {
    color: #1a1d21;
  }
}

.link-builder__badge {
  display: inline-flex;
  align-items: center;
  gap: 0.625rem;
  font-weight: 600;
  text-decoration: none;
}
</style>
