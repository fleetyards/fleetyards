// RSI's account lists share one pager under the list. It links every page it
// shows and, while there are more, the last one ("»"); the highest of them is
// the list's length. A script-driven pager elsewhere on a page links by `rel`,
// not `href`.
export const rsiLastPage = (htmlDoc: Document): number | undefined => {
  const pages = Array.from(
    htmlDoc.querySelectorAll<HTMLAnchorElement>(".pager a[href*='page=']"),
  )
    .map((link) =>
      Number(
        new URL(
          link.getAttribute("href") || "",
          "https://robertsspaceindustries.com",
        ).searchParams.get("page"),
      ),
    )
    .filter((page) => Number.isInteger(page) && page > 0);

  return pages.length ? Math.max(...pages) : undefined;
};
