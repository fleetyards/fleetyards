/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';

import { CelestialObjectsService } from './services/CelestialObjectsService';
import { CommoditiesService } from './services/CommoditiesService';
import { CommodityFiltersService } from './services/CommodityFiltersService';
import { CommodityPriceFiltersService } from './services/CommodityPriceFiltersService';
import { CommodityPricesService } from './services/CommodityPricesService';
import { ComponentFiltersService } from './services/ComponentFiltersService';
import { ComponentsService } from './services/ComponentsService';
import { EquipmentService } from './services/EquipmentService';
import { FeaturesService } from './services/FeaturesService';
import { FleetInviteUrlsService } from './services/FleetInviteUrlsService';
import { FleetMembersService } from './services/FleetMembersService';
import { FleetMembershipService } from './services/FleetMembershipService';
import { FleetsService } from './services/FleetsService';
import { FleetStatsService } from './services/FleetStatsService';
import { HangarService } from './services/HangarService';
import { HangarGroupsService } from './services/HangarGroupsService';
import { HangarStatsService } from './services/HangarStatsService';
import { ImagesService } from './services/ImagesService';
import { ManufacturersService } from './services/ManufacturersService';
import { ModelPaintsService } from './services/ModelPaintsService';
import { ModelsService } from './services/ModelsService';
import { PublicHangarService } from './services/PublicHangarService';
import { PublicHangarGroupsService } from './services/PublicHangarGroupsService';
import { PublicHangarStatsService } from './services/PublicHangarStatsService';
import { PublicWishlistService } from './services/PublicWishlistService';
import { RoadmapService } from './services/RoadmapService';
import { SearchService } from './services/SearchService';
import { ShopCommodityFiltersService } from './services/ShopCommodityFiltersService';
import { ShopFiltersService } from './services/ShopFiltersService';
import { ShopsService } from './services/ShopsService';
import { StarsystemsService } from './services/StarsystemsService';
import { StationsService } from './services/StationsService';
import { StatsService } from './services/StatsService';
import { TradeRoutesService } from './services/TradeRoutesService';
import { UsersService } from './services/UsersService';
import { VehiclesService } from './services/VehiclesService';
import { VehiclesPublicService } from './services/VehiclesPublicService';
import { VehiclesStatsService } from './services/VehiclesStatsService';
import { VersionsService } from './services/VersionsService';
import { WishlistService } from './services/WishlistService';

type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;

export class FyApi {

    public readonly celestialObjects: CelestialObjectsService;
    public readonly commodities: CommoditiesService;
    public readonly commodityFilters: CommodityFiltersService;
    public readonly commodityPriceFilters: CommodityPriceFiltersService;
    public readonly commodityPrices: CommodityPricesService;
    public readonly componentFilters: ComponentFiltersService;
    public readonly components: ComponentsService;
    public readonly equipment: EquipmentService;
    public readonly features: FeaturesService;
    public readonly fleetInviteUrls: FleetInviteUrlsService;
    public readonly fleetMembers: FleetMembersService;
    public readonly fleetMembership: FleetMembershipService;
    public readonly fleets: FleetsService;
    public readonly fleetStats: FleetStatsService;
    public readonly hangar: HangarService;
    public readonly hangarGroups: HangarGroupsService;
    public readonly hangarStats: HangarStatsService;
    public readonly images: ImagesService;
    public readonly manufacturers: ManufacturersService;
    public readonly modelPaints: ModelPaintsService;
    public readonly models: ModelsService;
    public readonly publicHangar: PublicHangarService;
    public readonly publicHangarGroups: PublicHangarGroupsService;
    public readonly publicHangarStats: PublicHangarStatsService;
    public readonly publicWishlist: PublicWishlistService;
    public readonly roadmap: RoadmapService;
    public readonly search: SearchService;
    public readonly shopCommodityFilters: ShopCommodityFiltersService;
    public readonly shopFilters: ShopFiltersService;
    public readonly shops: ShopsService;
    public readonly starsystems: StarsystemsService;
    public readonly stations: StationsService;
    public readonly stats: StatsService;
    public readonly tradeRoutes: TradeRoutesService;
    public readonly users: UsersService;
    public readonly vehicles: VehiclesService;
    public readonly vehiclesPublic: VehiclesPublicService;
    public readonly vehiclesStats: VehiclesStatsService;
    public readonly versions: VersionsService;
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
        this.commodities = new CommoditiesService(this.request);
        this.commodityFilters = new CommodityFiltersService(this.request);
        this.commodityPriceFilters = new CommodityPriceFiltersService(this.request);
        this.commodityPrices = new CommodityPricesService(this.request);
        this.componentFilters = new ComponentFiltersService(this.request);
        this.components = new ComponentsService(this.request);
        this.equipment = new EquipmentService(this.request);
        this.features = new FeaturesService(this.request);
        this.fleetInviteUrls = new FleetInviteUrlsService(this.request);
        this.fleetMembers = new FleetMembersService(this.request);
        this.fleetMembership = new FleetMembershipService(this.request);
        this.fleets = new FleetsService(this.request);
        this.fleetStats = new FleetStatsService(this.request);
        this.hangar = new HangarService(this.request);
        this.hangarGroups = new HangarGroupsService(this.request);
        this.hangarStats = new HangarStatsService(this.request);
        this.images = new ImagesService(this.request);
        this.manufacturers = new ManufacturersService(this.request);
        this.modelPaints = new ModelPaintsService(this.request);
        this.models = new ModelsService(this.request);
        this.publicHangar = new PublicHangarService(this.request);
        this.publicHangarGroups = new PublicHangarGroupsService(this.request);
        this.publicHangarStats = new PublicHangarStatsService(this.request);
        this.publicWishlist = new PublicWishlistService(this.request);
        this.roadmap = new RoadmapService(this.request);
        this.search = new SearchService(this.request);
        this.shopCommodityFilters = new ShopCommodityFiltersService(this.request);
        this.shopFilters = new ShopFiltersService(this.request);
        this.shops = new ShopsService(this.request);
        this.starsystems = new StarsystemsService(this.request);
        this.stations = new StationsService(this.request);
        this.stats = new StatsService(this.request);
        this.tradeRoutes = new TradeRoutesService(this.request);
        this.users = new UsersService(this.request);
        this.vehicles = new VehiclesService(this.request);
        this.vehiclesPublic = new VehiclesPublicService(this.request);
        this.vehiclesStats = new VehiclesStatsService(this.request);
        this.versions = new VersionsService(this.request);
        this.wishlist = new WishlistService(this.request);
    }
}

