/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';

import { CelestialObjectsService } from './services/CelestialObjectsService';
import { CommoditiesService } from './services/CommoditiesService';
import { ComponentsService } from './services/ComponentsService';
import { CurrentUserService } from './services/CurrentUserService';
import { EquipmentService } from './services/EquipmentService';
import { FleetsService } from './services/FleetsService';
import { FleetsInviteUrlsService } from './services/FleetsInviteUrlsService';
import { FleetsMembersService } from './services/FleetsMembersService';
import { FleetsMembershipsService } from './services/FleetsMembershipsService';
import { FleetsStatsService } from './services/FleetsStatsService';
import { FleetsVehiclesService } from './services/FleetsVehiclesService';
import { HangarService } from './services/HangarService';
import { HangarGroupsService } from './services/HangarGroupsService';
import { ImagesService } from './services/ImagesService';
import { ManufacturersService } from './services/ManufacturersService';
import { ModelsService } from './services/ModelsService';
import { PasswordsService } from './services/PasswordsService';
import { RoadmapService } from './services/RoadmapService';
import { SearchService } from './services/SearchService';
import { SessionsService } from './services/SessionsService';
import { SettingsTwoFactorService } from './services/SettingsTwoFactorService';
import { ShopCommoditiesService } from './services/ShopCommoditiesService';
import { ShopsService } from './services/ShopsService';
import { StarsystemsService } from './services/StarsystemsService';
import { StationsService } from './services/StationsService';
import { StatsService } from './services/StatsService';
import { UsersService } from './services/UsersService';
import { VehiclesService } from './services/VehiclesService';
import { VehiclesPublicService } from './services/VehiclesPublicService';
import { VehiclesStatsService } from './services/VehiclesStatsService';

type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;

export class FyApi {

    public readonly celestialObjects: CelestialObjectsService;
    public readonly commodities: CommoditiesService;
    public readonly components: ComponentsService;
    public readonly currentUser: CurrentUserService;
    public readonly equipment: EquipmentService;
    public readonly fleets: FleetsService;
    public readonly fleetsInviteUrls: FleetsInviteUrlsService;
    public readonly fleetsMembers: FleetsMembersService;
    public readonly fleetsMemberships: FleetsMembershipsService;
    public readonly fleetsStats: FleetsStatsService;
    public readonly fleetsVehicles: FleetsVehiclesService;
    public readonly hangar: HangarService;
    public readonly hangarGroups: HangarGroupsService;
    public readonly images: ImagesService;
    public readonly manufacturers: ManufacturersService;
    public readonly models: ModelsService;
    public readonly passwords: PasswordsService;
    public readonly roadmap: RoadmapService;
    public readonly search: SearchService;
    public readonly sessions: SessionsService;
    public readonly settingsTwoFactor: SettingsTwoFactorService;
    public readonly shopCommodities: ShopCommoditiesService;
    public readonly shops: ShopsService;
    public readonly starsystems: StarsystemsService;
    public readonly stations: StationsService;
    public readonly stats: StatsService;
    public readonly users: UsersService;
    public readonly vehicles: VehiclesService;
    public readonly vehiclesPublic: VehiclesPublicService;
    public readonly vehiclesStats: VehiclesStatsService;

    public readonly request: BaseHttpRequest;

    constructor(config?: Partial<OpenAPIConfig>, HttpRequest: HttpRequestConstructor = AxiosHttpRequest) {
        this.request = new HttpRequest({
            BASE: config?.BASE ?? 'https://api.fleetyards.net/v1',
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
        this.commodities = new CommoditiesService(this.request);
        this.components = new ComponentsService(this.request);
        this.currentUser = new CurrentUserService(this.request);
        this.equipment = new EquipmentService(this.request);
        this.fleets = new FleetsService(this.request);
        this.fleetsInviteUrls = new FleetsInviteUrlsService(this.request);
        this.fleetsMembers = new FleetsMembersService(this.request);
        this.fleetsMemberships = new FleetsMembershipsService(this.request);
        this.fleetsStats = new FleetsStatsService(this.request);
        this.fleetsVehicles = new FleetsVehiclesService(this.request);
        this.hangar = new HangarService(this.request);
        this.hangarGroups = new HangarGroupsService(this.request);
        this.images = new ImagesService(this.request);
        this.manufacturers = new ManufacturersService(this.request);
        this.models = new ModelsService(this.request);
        this.passwords = new PasswordsService(this.request);
        this.roadmap = new RoadmapService(this.request);
        this.search = new SearchService(this.request);
        this.sessions = new SessionsService(this.request);
        this.settingsTwoFactor = new SettingsTwoFactorService(this.request);
        this.shopCommodities = new ShopCommoditiesService(this.request);
        this.shops = new ShopsService(this.request);
        this.starsystems = new StarsystemsService(this.request);
        this.stations = new StationsService(this.request);
        this.stats = new StatsService(this.request);
        this.users = new UsersService(this.request);
        this.vehicles = new VehiclesService(this.request);
        this.vehiclesPublic = new VehiclesPublicService(this.request);
        this.vehiclesStats = new VehiclesStatsService(this.request);
    }
}

