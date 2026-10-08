// A share link carries its token as `?share=` on the public hangar URL. Every
// request the page makes has to send it along, and every link between the
// hangar's pages has to keep it, or a private hangar answers 404 one click in.
export const usePublicHangarShare = () => {
  const route = useRoute();

  const share = computed(() =>
    typeof route.query.share === "string" && route.query.share.length > 0
      ? route.query.share
      : undefined,
  );

  const shareQuery = computed(() => {
    const query: Record<string, string> = {};

    if (share.value) {
      query.share = share.value;
    }

    return query;
  });

  return { share, shareQuery };
};
