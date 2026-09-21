import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type GameMission } from "@/services/fyApi";

/**
 * The sorts the mission catalogue offers above its rows.
 *
 * Only the two the API accepts. `GameMission::ALLOWED_SORTING_PARAMS` is the
 * whitelist the controller sorts by, and offering a column it does not name
 * would send a request that comes back 400 rather than reordered.
 *
 * Difficulty is deliberately not among them. It is four numbers rather than
 * one, and the game combines them with per-profile weights -- a single
 * "difficulty" sort would have to pick a formula the export does not state.
 */
export const useMissionSortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<GameMission>[]>(() => [
    { name: "name", label: t("labels.gameMission.name"), sortable: true },
    { name: "orgName", label: t("labels.gameMission.org"), sortable: true },
  ]);
};
