// A section a link points at may not exist yet when the page opens: the ship
// page's paints, modules and upgrades each render once their own request
// returns. So the hash is watched for until its element turns up, within a
// limit, rather than looked for once and forgotten.
export const useScrollToHash = (timeoutMs = 5000) => {
  const route = useRoute();

  let observer: MutationObserver | undefined;
  let timer: ReturnType<typeof setTimeout> | undefined;

  const stop = () => {
    observer?.disconnect();
    observer = undefined;

    if (timer) clearTimeout(timer);
    timer = undefined;
  };

  const scrollTo = (hash: string) => {
    stop();

    const id = decodeURIComponent(hash.replace(/^#/, ""));
    if (!id) return;

    const tryScroll = () => {
      const el = document.getElementById(id);
      if (!el) return false;

      stop();
      el.scrollIntoView({ behavior: "instant", block: "start" });

      return true;
    };

    if (tryScroll()) return;

    observer = new MutationObserver(tryScroll);
    observer.observe(document.body, { childList: true, subtree: true });
    timer = setTimeout(stop, timeoutMs);
  };

  onMounted(() => scrollTo(route.hash));

  watch(
    () => route.hash,
    (hash) => scrollTo(hash),
  );

  onBeforeUnmount(stop);

  return { scrollTo };
};
