import type { InternalAxiosRequestConfig } from "axios";
import { AXIOS_INSTANCE } from "@/services/axiosClient";

export type VisualApiRoute = {
  method: "GET" | "POST" | "PUT" | "DELETE";
  path: RegExp;
  respond: (config: InternalAxiosRequestConfig) => unknown;
};

/*
 * Answers the API requests a visual test page's modal makes, so pressing its
 * buttons sends nothing: the page is not signed in, and a demo must not act on
 * real data either way. Only the listed routes are answered; the page shell's
 * own requests go through.
 */
export const useVisualApiMock = (routes: VisualApiRoute[]) => {
  let interceptor: number | undefined;

  onMounted(() => {
    interceptor = AXIOS_INSTANCE.interceptors.request.use((config) => {
      const method = (config.method ?? "get").toUpperCase();
      const route = routes.find(
        (candidate) =>
          candidate.method === method && candidate.path.test(config.url ?? ""),
      );
      if (!route) return config;

      return {
        ...config,
        adapter: async (request) => ({
          data: route.respond(request),
          status: 200,
          statusText: "OK",
          headers: {},
          config: request,
        }),
      };
    });
  });

  onBeforeUnmount(() => {
    if (interceptor !== undefined) {
      AXIOS_INSTANCE.interceptors.request.eject(interceptor);
    }
  });
};
