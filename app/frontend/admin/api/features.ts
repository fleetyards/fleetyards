import { axiosClient } from "@/services/axiosAdminClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export interface FeatureActor {
  type: string;
  id: string;
  name: string;
}

export interface Feature {
  name: string;
  state: string;
  selfService: boolean;
  groups: string[];
  actors: FeatureActor[];
}

const FEATURES_QUERY_KEY = ["admin", "features"];

export const fetchFeatures = () =>
  axiosClient<Feature[]>({ url: "/features", method: "GET" });

export const fetchFeature = (name: string) =>
  axiosClient<Feature>({ url: `/features/${name}`, method: "GET" });

export const enableFeature = (name: string) =>
  axiosClient<Feature>({ url: `/features/${name}/enable`, method: "PUT" });

export const disableFeature = (name: string) =>
  axiosClient<Feature>({ url: `/features/${name}/disable`, method: "PUT" });

export const enableFeatureActor = (
  name: string,
  actorType: string,
  actorId: string,
) =>
  axiosClient<Feature>({
    url: `/features/${name}/enable-actor`,
    method: "PUT",
    data: { actor_type: actorType, actor_id: actorId },
  });

export const disableFeatureActor = (
  name: string,
  actorType: string,
  actorId: string,
) =>
  axiosClient<Feature>({
    url: `/features/${name}/disable-actor`,
    method: "PUT",
    data: { actor_type: actorType, actor_id: actorId },
  });

export const enableFeatureGroup = (name: string, group: string) =>
  axiosClient<Feature>({
    url: `/features/${name}/enable-group`,
    method: "PUT",
    data: { group },
  });

export const disableFeatureGroup = (name: string, group: string) =>
  axiosClient<Feature>({
    url: `/features/${name}/disable-group`,
    method: "PUT",
    data: { group },
  });

export const toggleSelfService = (name: string) =>
  axiosClient<Feature>({
    url: `/features/${name}/toggle-self-service`,
    method: "PUT",
  });

export const useFeatures = () =>
  useQuery({
    queryKey: FEATURES_QUERY_KEY,
    queryFn: fetchFeatures,
  });

export const useFeature = (name: Ref<string>) =>
  useQuery({
    queryKey: [...FEATURES_QUERY_KEY, name],
    queryFn: () => fetchFeature(name.value),
    enabled: computed(() => !!name.value),
  });

export const useInvalidateFeatures = () => {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: FEATURES_QUERY_KEY });
};
