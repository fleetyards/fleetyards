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

export const summarizeShipFilters = (
  query: LocationQuery,
  label: (key: string) => string,
): { id: string; label: string; keys: string[] }[] => {
  const consumed = new Set<string>();
  return Object.keys(query)
    .filter((key) => !ignoredKeys.has(key) && present(query[key]))
    .flatMap((key) => {
      if (consumed.has(key)) return [];
      const base = key.replace(/(?:Gteq|Lteq)$/, "");
      const range = /(?:Gteq|Lteq)$/.test(key);
      const keys = range ? [base + "Gteq", base + "Lteq"] : [key];
      keys.forEach((item) => consumed.add(item));
      let value: string;
      if (range) {
        const min = query[keys[0]],
          max = query[keys[1]];
        value =
          present(min) && present(max)
            ? `${String(min)}–${String(max)}`
            : present(min)
              ? `≥ ${String(min)}`
              : `≤ ${String(max)}`;
      } else {
        const values = Array.isArray(query[key]) ? query[key] : [query[key]];
        value = values.map(String).join(", ");
      }
      return [
        { id: base, label: `${label(range ? base : key)}: ${value}`, keys },
      ];
    });
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
  const activeFilters = computed<ActiveFilter[]>(() =>
    summarizeShipFilters(route.query, label).map((item) => ({
      id: item.id,
      label: item.label,
      remove: async () => {
        const query: LocationQueryRaw = { ...route.query };
        item.keys.forEach((key) => delete query[key]);
        delete query.page;
        await router.push({ path: route.path, query, hash: route.hash });
      },
    })),
  );
  return { activeFilters };
};
