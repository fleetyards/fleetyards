import { QueryClient } from "@tanstack/vue-query";

// Owned here rather than left to VueQueryPlugin so the router guards can read
// the same cache the components do — a guard runs outside any setup context and
// cannot inject the client.
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      placeholderData: (prev: unknown) => prev,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});
