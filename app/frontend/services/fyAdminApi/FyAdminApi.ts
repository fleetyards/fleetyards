/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest';
import type { OpenAPIConfig } from './core/OpenAPI';
import { AxiosHttpRequest } from './core/AxiosHttpRequest';
import { AdminUsersService } from './services/AdminUsersService';
import { ComponentsService } from './services/ComponentsService';
import { ImagesService } from './services/ImagesService';
import { ImportsService } from './services/ImportsService';
import { ItemPricesService } from './services/ItemPricesService';
import { ManufacturersService } from './services/ManufacturersService';
import { ModelsService } from './services/ModelsService';
import { SessionsService } from './services/SessionsService';
import { StatsService } from './services/StatsService';
import { UsersService } from './services/UsersService';
type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest;
export class FyAdminApi {
    public readonly adminUsers: AdminUsersService;
    public readonly components: ComponentsService;
    public readonly images: ImagesService;
    public readonly imports: ImportsService;
    public readonly itemPrices: ItemPricesService;
    public readonly manufacturers: ManufacturersService;
    public readonly models: ModelsService;
    public readonly sessions: SessionsService;
    public readonly stats: StatsService;
    public readonly users: UsersService;
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
        this.adminUsers = new AdminUsersService(this.request);
        this.components = new ComponentsService(this.request);
        this.images = new ImagesService(this.request);
        this.imports = new ImportsService(this.request);
        this.itemPrices = new ItemPricesService(this.request);
        this.manufacturers = new ManufacturersService(this.request);
        this.models = new ModelsService(this.request);
        this.sessions = new SessionsService(this.request);
        this.stats = new StatsService(this.request);
        this.users = new UsersService(this.request);
    }
}

