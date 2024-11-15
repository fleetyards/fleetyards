/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';
import { ComponentsService } from './services/ComponentsService';
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
import { PasswordService } from './services/PasswordService';
import { PublicHangarService } from './services/PublicHangarService';
import { PublicHangarGroupsService } from './services/PublicHangarGroupsService';
import { PublicHangarStatsService } from './services/PublicHangarStatsService';
import { PublicUserService } from './services/PublicUserService';
import { PublicWishlistService } from './services/PublicWishlistService';
import { RoadmapService } from './services/RoadmapService';
import { SearchService } from './services/SearchService';
import { SessionsService } from './services/SessionsService';
import { StatsService } from './services/StatsService';
import { UsersService } from './services/UsersService';
import { VehiclesService } from './services/VehiclesService';
import { VersionsService } from './services/VersionsService';
import { WishlistService } from './services/WishlistService';
type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;
export class FyApi {
    public readonly components: ComponentsService;
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
    public readonly password: PasswordService;
    public readonly publicHangar: PublicHangarService;
    public readonly publicHangarGroups: PublicHangarGroupsService;
    public readonly publicHangarStats: PublicHangarStatsService;
    public readonly publicUser: PublicUserService;
    public readonly publicWishlist: PublicWishlistService;
    public readonly roadmap: RoadmapService;
    public readonly search: SearchService;
    public readonly sessions: SessionsService;
    public readonly stats: StatsService;
    public readonly users: UsersService;
    public readonly vehicles: VehiclesService;
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
        this.components = new ComponentsService(this.request);
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
        this.password = new PasswordService(this.request);
        this.publicHangar = new PublicHangarService(this.request);
        this.publicHangarGroups = new PublicHangarGroupsService(this.request);
        this.publicHangarStats = new PublicHangarStatsService(this.request);
        this.publicUser = new PublicUserService(this.request);
        this.publicWishlist = new PublicWishlistService(this.request);
        this.roadmap = new RoadmapService(this.request);
        this.search = new SearchService(this.request);
        this.sessions = new SessionsService(this.request);
        this.stats = new StatsService(this.request);
        this.users = new UsersService(this.request);
        this.vehicles = new VehiclesService(this.request);
        this.versions = new VersionsService(this.request);
        this.wishlist = new WishlistService(this.request);
    }
}

