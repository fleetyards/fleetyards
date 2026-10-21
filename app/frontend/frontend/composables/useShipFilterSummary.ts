import { toValue, type MaybeRefOrGetter } from "vue";
import type { LocationQuery, LocationQueryRaw } from "vue-router";
import type { ActiveFilter } from "@/shared/components/ActiveFilters/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { FILTER_EXCLUDE_KEYS } from "@/shared/composables/useFilters";
import { hasFilterValue } from "@/shared/utils/Filters";
import { HANGAR_VIEW_KEYS } from "./useHangarFilters";

const ignoredKeys = new Set([...FILTER_EXCLUDE_KEYS, ...HANGAR_VIEW_KEYS]);
const present = hasFilterValue;

// Values that are catalogue slugs, so title-casing them gives the name. Any
// other value - a username, a search term, an id - is shown as it is.
const SLUG_KEYS = [
  "manufacturerIn",
  "classificationIn",
  "focusIn",
  "sizeIn",
  "productionStatusIn",
];

const isNested = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

// Keys are paths: legacy links and Sorting.ts still nest filters under `q`, so
// a nested key comes back as `q.manufacturerIn`.
export const summarizeShipFilters = (
  query: LocationQuery,
  label: (key: string) => string,
  formatValue: (value: string, key: string) => string = (value) => value,
): { id: string; label: string; keys: string[] }[] => {
  const summarize = (
    source: Record<string, unknown>,
    prefix: string,
  ): { id: string; label: string; keys: string[] }[] => {
    const consumed = new Set<string>();
    return Object.keys(source)
      .filter((key) => !ignoredKeys.has(key) && present(source[key]))
      .flatMap((key) => {
        if (isNested(source[key])) {
          return prefix ? [] : summarize(source[key], `${key}.`);
        }
        if (consumed.has(key)) return [];
        const base = key.replace(/(?:Gteq|Lteq)$/, "");
        const range = /(?:Gteq|Lteq)$/.test(key);
        const keys = range ? [base + "Gteq", base + "Lteq"] : [key];
        keys.forEach((item) => consumed.add(item));
        let value: string;
        if (range) {
          const min = source[keys[0]],
            max = source[keys[1]];
          value =
            present(min) && present(max)
              ? `${String(min)}–${String(max)}`
              : present(min)
                ? `≥ ${String(min)}`
                : `≤ ${String(max)}`;
        } else {
          const raw = source[key];
          const values = Array.isArray(raw) ? raw : [raw];
          value = values
            .map((item) => formatValue(String(item), key))
            .join(", ");
          if (key.endsWith("NotIn")) value = `≠ ${value}`;
        }
        return [
          {
            id: prefix + base,
            label: `${label(range ? base : key)}: ${value}`,
            keys: keys.map((item) => prefix + item),
          },
        ];
      });
  };
  return summarize(query, "");
};

// Group filters hold ids; a page that has the groups passes their names.
export const hangarGroupLabels = (
  groups: { id: string; name: string }[] | undefined,
) => {
  const labels = Object.fromEntries(
    (groups || []).map((group) => [group.id, group.name]),
  );
  return { hangarGroupsIn: labels, hangarGroupsNotIn: labels };
};

export const useShipFilterSummary = (
  valueLabels: MaybeRefOrGetter<Record<string, Record<string, string>>> = {},
) => {
  const route = useRoute();
  const router = useRouter();
  const { t, tExists } = useI18n();
  const { priceOptions, pledgePriceOptions } = useFilterOptions();
  const optionLabels = (options: { label: string; value: string }[]) =>
    Object.fromEntries(options.map((option) => [option.value, option.label]));
  const label = (key: string) => {
    if (key === "cargo") return "SCU";
    const aliases: Record<string, string> = {
      searchCont: "labels.filters.models.name",
      nameCont: "labels.filters.models.name",
      modelNameCont: "labels.filters.models.name",
      modelNameOrModelDescriptionCont: "labels.filters.models.name",
      nameOrDescriptionCont: "labels.filters.models.name",
      loanerEq: "labels.filters.vehicles.loaner",
      bundledEq: "labels.filters.vehicles.bundled",
      hiddenByUserEq: "labels.filters.vehicles.hiddenByUser",
      publicEq: "labels.filters.vehicles.public",
      boughtViaEq: "labels.filters.vehicles.boughtVia",
      memberIn: "labels.filters.fleets.member",
      squadronSlugIn: "labels.fleet.members.card.squadrons",
      hangarGroupsIn: "labels.filters.vehicles.group",
      hangarGroupsNotIn: "labels.filters.vehicles.group",
    };
    const stem = key.replace(/(?:NotIn|In|Eq|Cont)$/, "");
    const path = aliases[key] || `labels.filters.models.${stem}`;
    if (tExists(path)) return t(path);
    const rangePath = `labels.filters.models.${stem}Gt`;
    if (tExists(rangePath)) return t(rangePath).replace(/\s*>=?$/, "");
    return stem
      .replace(/([A-Z])/g, " $1")
      .replace(/^./, (char) => char.toUpperCase());
  };
  const formatValue = (value: string, key: string) => {
    const labels: Record<string, Record<string, string>> = {
      priceIn: optionLabels(priceOptions),
      pledgePriceIn: optionLabels(pledgePriceOptions),
      ...toValue(valueLabels),
    };
    const known = labels[key]?.[value];
    if (known) return known;
    if (value === "true" || value === "false") return t(`labels.${value}`);
    if (!SLUG_KEYS.includes(key.replace(/NotIn$/, "In"))) return value;
    return value
      .split(/[-_]/)
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");
  };
  const activeFilters = computed<ActiveFilter[]>(() =>
    summarizeShipFilters(route.query, label, formatValue).map((item) => ({
      id: item.id,
      label: item.label,
      remove: async () => {
        const query: LocationQueryRaw = { ...route.query };
        item.keys.forEach((path) => {
          const [parent, child] = path.split(".");
          if (child === undefined) {
            delete query[parent];
            return;
          }
          const nested = {
            ...(query[parent] as unknown as Record<string, unknown>),
          };
          delete nested[child];
          // The URL drops an empty `q` but `route.query` keeps it, and an
          // empty object still counts as a selected filter.
          if (Object.keys(nested).length) {
            query[parent] = nested as unknown as LocationQueryRaw[string];
          } else {
            delete query[parent];
          }
        });
        delete query.page;
        await router.push({ path: route.path, query, hash: route.hash });
      },
    })),
  );
  return { activeFilters };
};
