import { axiosClient } from "@/services/axiosClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export interface UserFeature {
  name: string;
  enabled: boolean;
}

const USER_FEATURES_QUERY_KEY = ["userFeatures"];

export const fetchUserFeatures = () =>
  axiosClient<UserFeature[]>({ url: "/user-features", method: "GET" });

export const enableUserFeature = (name: string) =>
  axiosClient<UserFeature>({
    url: `/user-features/${name}/enable`,
    method: "PUT",
  });

export const disableUserFeature = (name: string) =>
  axiosClient<UserFeature>({
    url: `/user-features/${name}/disable`,
    method: "PUT",
  });

export const useUserFeatures = () =>
  useQuery({
    queryKey: USER_FEATURES_QUERY_KEY,
    queryFn: fetchUserFeatures,
  });

export const useInvalidateUserFeatures = () => {
  const queryClient = useQueryClient();
  return () =>
    queryClient.invalidateQueries({ queryKey: USER_FEATURES_QUERY_KEY });
};
