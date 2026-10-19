import type { LocationQuery, LocationQueryRaw } from "vue-router";
import type { ActiveFilter } from "@/shared/components/ActiveFilters/types";
import { useI18n } from "@/shared/composables/useI18n";
import { HANGAR_VIEW_KEYS } from "./useHangarFilters";

const ignoredKeys = new Set([
  "s",
  "sorts",
  "page",
  "perPage",
  "tab",
  "view",
  "direction",
  "fleetchart",
  ...HANGAR_VIEW_KEYS,
]);
const present = (value: unknown) =>
  value != null && value !== "" && (!Array.isArray(value) || value.length > 0);

const isNested = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

// Keys are paths: legacy links and Sorting.ts still nest filters under `q`, so
// a nested key comes back as `q.manufacturerIn`.
export const summarizeShipFilters = (
  query: LocationQuery,
  label: (key: string) => string,
  formatValue: (value: string) => string = (value) => value,
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
          value = values.map((item) => formatValue(String(item))).join(", ");
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

export const useShipFilterSummary = () => {
  const route = useRoute();
  const router = useRouter();
  const { t, tExists } = useI18n();
  const label = (key: string) => {
    if (key === "cargo") return "SCU";
    const aliases: Record<string, string> = {
      searchCont: "models.name",
      nameCont: "models.name",
      modelNameCont: "models.name",
      modelNameOrModelDescriptionCont: "models.name",
      nameOrDescriptionCont: "models.name",
      loanerEq: "vehicles.loaner",
      bundledEq: "vehicles.bundled",
      hiddenByUserEq: "vehicles.hiddenByUser",
      publicEq: "vehicles.public",
      boughtViaEq: "vehicles.boughtVia",
      memberIn: "vehicles.owner",
      hangarGroupsIn: "vehicles.group",
      hangarGroupsNotIn: "vehicles.group",
    };
    const stem = key.replace(/(?:NotIn|In|Eq|Cont)$/, "");
    const path = `labels.filters.${aliases[key] || "models." + stem}`;
    if (tExists(path)) return t(path);
    const rangePath = `labels.filters.models.${stem}Gt`;
    if (tExists(rangePath)) return t(rangePath).replace(/\s*>=?$/, "");
    return stem
      .replace(/([A-Z])/g, " $1")
      .replace(/^./, (char) => char.toUpperCase());
  };
  const formatValue = (value: string) => {
    if (value === "true" || value === "false") return t(`labels.${value}`);
    if (!/^[a-z][a-z0-9-]*$/.test(value)) return value;
    return value
      .split("-")
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
          query[parent] = nested as unknown as LocationQueryRaw[string];
        });
        delete query.page;
        await router.push({ path: route.path, query, hash: route.hash });
      },
    })),
  );
  return { activeFilters };
};
