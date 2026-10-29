type HoloChoice = {
  textured: boolean;
  paint?: string;
};

// Keeps what the full screen viewer shows in its address, so the link copied
// from it opens the same holo.
export const useHoloQuery = (choice: MaybeRefOrGetter<HoloChoice>) => {
  const route = useRoute();

  const router = useRouter();

  watch(
    () => toValue(choice),
    ({ textured, paint }) => {
      const query = {
        ...route.query,
        textured: textured ? "1" : undefined,
        paint: textured ? paint : undefined,
      };

      if (
        query.textured === route.query.textured &&
        query.paint === route.query.paint
      ) {
        return;
      }

      void router.replace({ query });
    },
  );
};
