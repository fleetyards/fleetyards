/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';

import { CelestialObjectsService } from './services/CelestialObjectsService';
import { HangarService } from './services/HangarService';
import { HangarGroupsService } from './services/HangarGroupsService';
import { HangarStatsService } from './services/HangarStatsService';
import { ImagesService } from './services/ImagesService';
import { ManufacturersService } from './services/ManufacturersService';
import { ModelsService } from './services/ModelsService';
import { PublicHangarService } from './services/PublicHangarService';
import { PublicHangarGroupsService } from './services/PublicHangarGroupsService';
import { PublicHangarStatsService } from './services/PublicHangarStatsService';
import { PublicWishlistService } from './services/PublicWishlistService';
import { ShopsService } from './services/ShopsService';
import { StarsystemsService } from './services/StarsystemsService';
import { StationsService } from './services/StationsService';
import { StatsService } from './services/StatsService';
import { VehiclesService } from './services/VehiclesService';
import { VehiclesPublicService } from './services/VehiclesPublicService';
import { VehiclesStatsService } from './services/VehiclesStatsService';
import { WishlistService } from './services/WishlistService';

type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;

export class FyApi {

    public readonly celestialObjects: CelestialObjectsService;
    public readonly hangar: HangarService;
    public readonly hangarGroups: HangarGroupsService;
    public readonly hangarStats: HangarStatsService;
    public readonly images: ImagesService;
    public readonly manufacturers: ManufacturersService;
    public readonly models: ModelsService;
    public readonly publicHangar: PublicHangarService;
    public readonly publicHangarGroups: PublicHangarGroupsService;
    public readonly publicHangarStats: PublicHangarStatsService;
    public readonly publicWishlist: PublicWishlistService;
    public readonly shops: ShopsService;
    public readonly starsystems: StarsystemsService;
    public readonly stations: StationsService;
    public readonly stats: StatsService;
    public readonly vehicles: VehiclesService;
    public readonly vehiclesPublic: VehiclesPublicService;
    public readonly vehiclesStats: VehiclesStatsService;
    public readonly wishlist: WishlistService;

    public readonly request: BaseHttpRequest;

    constructor(config?: Partial<OpenAPIConfig>, HttpRequest: HttpRequestConstructor = AxiosHttpRequest) {
        this.request = new HttpRequest({
            BASE: config?.BASE ?? 'http://api.fleetyards.test/v1',
            VERSION: config?.VERSION ?? '1',
            WITH_CREDENTIALS: config?.WITH_CREDENTIALS ?? false,
            CREDENTIALS: config?.CREDENTIALS ?? 'include',
            TOKEN: config?.TOKEN,
            USERNAME: config?.USERNAME,
            PASSWORD: config?.PASSWORD,
            HEADERS: config?.HEADERS,
            ENCODE_PATH: config?.ENCODE_PATH,
        });

        this.celestialObjects = new CelestialObjectsService(this.request);
        this.hangar = new HangarService(this.request);
        this.hangarGroups = new HangarGroupsService(this.request);
        this.hangarStats = new HangarStatsService(this.request);
        this.images = new ImagesService(this.request);
        this.manufacturers = new ManufacturersService(this.request);
        this.models = new ModelsService(this.request);
        this.publicHangar = new PublicHangarService(this.request);
        this.publicHangarGroups = new PublicHangarGroupsService(this.request);
        this.publicHangarStats = new PublicHangarStatsService(this.request);
        this.publicWishlist = new PublicWishlistService(this.request);
        this.shops = new ShopsService(this.request);
        this.starsystems = new StarsystemsService(this.request);
        this.stations = new StationsService(this.request);
        this.stats = new StatsService(this.request);
        this.vehicles = new VehiclesService(this.request);
        this.vehiclesPublic = new VehiclesPublicService(this.request);
        this.vehiclesStats = new VehiclesStatsService(this.request);
        this.wishlist = new WishlistService(this.request);
    }
}

