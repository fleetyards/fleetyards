import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import type { AxiosAdapter, InternalAxiosRequestConfig } from "axios";
import { AXIOS_INSTANCE, axiosClient } from "./axiosClient";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";

const live = { environment: "live", version: "1.0.0", default: true };
const ptu = { environment: "ptu", version: "1.1.0", default: false };

describe("axiosClient", () => {
  const originalAdapter = AXIOS_INSTANCE.defaults.adapter;
  let sent: InternalAxiosRequestConfig;

  const adapter: AxiosAdapter = (config) => {
    sent = config;

    return Promise.resolve({
      data: [],
      status: 200,
      statusText: "OK",
      headers: {},
      config,
    });
  };

  beforeEach(() => {
    setActivePinia(createPinia());
    useScDataSourceStore().setAvailable([live, ptu]);
    AXIOS_INSTANCE.defaults.adapter = adapter;
  });

  afterEach(() => {
    AXIOS_INSTANCE.defaults.adapter = originalAdapter;
  });

  it("sends nothing extra for the default build", async () => {
    await axiosClient({ url: "/commodities", params: { page: 2 } });

    expect(sent.params).toEqual({ page: 2 });
  });

  it("leaves an endpoint's own source alone when a build is selected", async () => {
    useScDataSourceStore().select("ptu");

    await axiosClient({
      url: "/models/gladius/hardpoints",
      params: { source: "game_files" },
    });

    expect(sent.params).toEqual({
      source: "game_files",
      scDataSource: "ptu",
    });
  });
});
