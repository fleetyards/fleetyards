import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Announcement } from "@/services/fyAdminApi";

/**
 * The sorts the list offers above its rows.
 *
 * A row list has no column headings to hang them off, so the sort line is the
 * whole control. It lives beside the list rather than inside it: `FilteredList`
 * renders its results slot only once the first page has arrived, and a control
 * that disappears while the thing it controls is loading is the wrong way round.
 */
export const useAnnouncementSortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<Announcement>[]>(() => [
    {
      name: "title",
      label: t("labels.admin.announcements.columns.title"),
      sortable: true,
    },
    {
      name: "publishedAt",
      label: t("labels.admin.announcements.columns.publishedAt"),
      sortable: true,
    },
  ]);
};
