import {
  type RsiPageCheckEnum,
  type RsiPageKindEnum,
  useReportRsiPage,
} from "@/services/fyApi";

// Tells the admins a sync met an RSI page its parser no longer recognises.
// Fired and forgotten: the sync has already stopped, and a report that does not
// arrive must not turn into a second error for the user.
export const useRsiPageReport = () => {
  const mutation = useReportRsiPage();

  return (report: {
    page: RsiPageKindEnum;
    check: RsiPageCheckEnum;
    pageNumber?: number;
    extensionVersion?: string;
  }) => {
    mutation.mutateAsync({ data: report }).catch(() => undefined);
  };
};
