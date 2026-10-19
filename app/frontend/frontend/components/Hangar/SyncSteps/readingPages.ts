import type { SyncStep } from "./types";

// A reading step's page line and bar. Without a total it only counts pages
// and shows that it is working. An estimated total is said to be one, and a
// run that reads past it moves it along rather than overflowing.
export const readingPages = (
  page: number,
  total?: number,
  estimated = false,
): Pick<SyncStep, "detail" | "progress"> => {
  if (!total) {
    return {
      detail: {
        key: "labels.syncExtension.stepDetails.page",
        values: { page },
      },
      progress: "indeterminate",
    };
  }

  const max = estimated ? Math.max(total, page) : total;

  return {
    detail: {
      key: estimated
        ? "labels.syncExtension.stepDetails.pageOfAbout"
        : "labels.syncExtension.stepDetails.pageOf",
      values: { page: Math.min(page, max), total: max },
    },
    progress: { value: Math.min(page, max), max },
  };
};
