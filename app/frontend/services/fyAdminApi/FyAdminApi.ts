/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';

import { CommotitiesService } from './services/CommotitiesService';
import { ComponentsFiltersService } from './services/ComponentsFiltersService';
import { ImagesService } from './services/ImagesService';
import { ModelsService } from './services/ModelsService';
import { ShopCommoditiesService } from './services/ShopCommoditiesService';
import { ShopsService } from './services/ShopsService';
import { StationsService } from './services/StationsService';

type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;

export class FyAdminApi {

    public readonly commotities: CommotitiesService;
    public readonly componentsFilters: ComponentsFiltersService;
    public readonly images: ImagesService;
    public readonly models: ModelsService;
    public readonly shopCommodities: ShopCommoditiesService;
    public readonly shops: ShopsService;
    public readonly stations: StationsService;

    public readonly request: BaseHttpRequest;

    constructor(config?: Partial<OpenAPIConfig>, HttpRequest: HttpRequestConstructor = AxiosHttpRequest) {
        this.request = new HttpRequest({
            BASE: config?.BASE ?? 'http://admin.fleetyards.test/api/v1',
            VERSION: config?.VERSION ?? '1',
            WITH_CREDENTIALS: config?.WITH_CREDENTIALS ?? false,
            CREDENTIALS: config?.CREDENTIALS ?? 'include',
            TOKEN: config?.TOKEN,
            USERNAME: config?.USERNAME,
            PASSWORD: config?.PASSWORD,
            HEADERS: config?.HEADERS,
            ENCODE_PATH: config?.ENCODE_PATH,
        });

        this.commotities = new CommotitiesService(this.request);
        this.componentsFilters = new ComponentsFiltersService(this.request);
        this.images = new ImagesService(this.request);
        this.models = new ModelsService(this.request);
        this.shopCommodities = new ShopCommoditiesService(this.request);
        this.shops = new ShopsService(this.request);
        this.stations = new StationsService(this.request);
    }
}

