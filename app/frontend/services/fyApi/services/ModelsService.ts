/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FilterOption } from '../models/FilterOption';
import type { ImageMinimal } from '../models/ImageMinimal';
import type { ModelComplete } from '../models/ModelComplete';
import type { ModelHardpoint } from '../models/ModelHardpoint';
import type { ModelHardpointSourceEnum } from '../models/ModelHardpointSourceEnum';
import type { ModelMinimal } from '../models/ModelMinimal';
import type { ModelModuleMinimal } from '../models/ModelModuleMinimal';
import type { ModelModulePackageMinimal } from '../models/ModelModulePackageMinimal';
import type { ModelPaintMinimal } from '../models/ModelPaintMinimal';
import type { ModelQuery } from '../models/ModelQuery';
import type { ModelUpgradeMinimal } from '../models/ModelUpgradeMinimal';
import type { VideoMinimal } from '../models/VideoMinimal';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ModelsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Models with Docks
     * @returns any successful
     * @throws ApiError
     */
    public modelsWithDocks({
        page = '1',
        perPage = '30',
    }: {
        page?: string,
        perPage?: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/with-docks',
            query: {
                'page': page,
                'perPage': perPage,
            },
        });
    }

    /**
     * Unscheduled Models
     * @returns any successful
     * @throws ApiError
     */
    public modelsUnschduled(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/unscheduled',
        });
    }

    /**
     * Latest Models
     * @returns any successful
     * @throws ApiError
     */
    public modelsLatest(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/latest',
        });
    }

    /**
     * Available Model-Slugs
     * @returns any successful
     * @throws ApiError
     */
    public modelsSlugs(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/slugs',
        });
    }

    /**
     * Updated Models
     * @returns any successful
     * @throws ApiError
     */
    public modelsUpdated({
        from,
        to = 'now',
    }: {
        from?: string,
        to?: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/updated',
            query: {
                'from': from,
                'to': to,
            },
            errors: {
                304: `not modified`,
            },
        });
    }

    /**
     * Embed Models
     * @returns ModelMinimal successful
     * @throws ApiError
     */
    public embed({
        models,
    }: {
        models: Array<string>,
    }): CancelablePromise<Array<ModelMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/embed',
            query: {
                'models': models,
            },
        });
    }

    /**
     * Model Filters
     * @returns FilterOption successful
     * @throws ApiError
     */
    public modelFilters(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/filters',
        });
    }

    /**
     * Model classifications
     * @returns FilterOption successful
     * @throws ApiError
     */
    public modelClassifications(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/classifications',
        });
    }

    /**
     * Model Production states
     * @returns FilterOption successful
     * @throws ApiError
     */
    public modelProductionStates(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/production-states',
        });
    }

    /**
     * Model focus
     * @returns FilterOption successful
     * @throws ApiError
     */
    public modelFocus(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/focus',
        });
    }

    /**
     * Model Sizes
     * @returns FilterOption successful
     * @throws ApiError
     */
    public modelSizes(): CancelablePromise<Array<FilterOption>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/sizes',
        });
    }

    /**
     * Model Cargo options
     * @returns any successful
     * @throws ApiError
     */
    public cargoOptions({
        page = '1',
        perPage = '30',
    }: {
        page?: string,
        perPage?: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/cargo-options',
            query: {
                'page': page,
                'perPage': perPage,
            },
        });
    }

    /**
     * Models List
     * @returns ModelMinimal successful
     * @throws ApiError
     */
    public models({
        page = '1',
        perPage = '30',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: ModelQuery,
        cacheId?: string,
    }): CancelablePromise<Array<ModelMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

    /**
     * Model Detail
     * @returns ModelComplete successful
     * @throws ApiError
     */
    public model({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<ModelComplete> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Hardpoints
     * @returns ModelHardpoint successful
     * @throws ApiError
     */
    public modelHardpoints({
        slug,
        source,
    }: {
        /**
         * Model slug
         */
        slug: string,
        source?: ModelHardpointSourceEnum,
    }): CancelablePromise<Array<ModelHardpoint>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/hardpoints',
            path: {
                'slug': slug,
            },
            query: {
                'source': source,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Images
     * @returns ImageMinimal successful
     * @throws ApiError
     */
    public modelImages({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<ImageMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/images',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Videos
     * @returns VideoMinimal successful
     * @throws ApiError
     */
    public modelVideos({
        slug,
        page = '1',
        perPage = '8',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<VideoMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/videos',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Variants
     * @returns ModelMinimal successful
     * @throws ApiError
     */
    public modelVariants({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<ModelMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/variants',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Loaners
     * @returns ModelMinimal successful
     * @throws ApiError
     */
    public modelLoaners({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<ModelMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/loaners',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Snubcrafts
     * @returns ModelMinimal successful
     * @throws ApiError
     */
    public modelSnubCrafts({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<Array<ModelMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/snub-crafts',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Modules
     * @returns ModelModuleMinimal successful
     * @throws ApiError
     */
    public modelModules({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<ModelModuleMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/modules',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Module Packages
     * @returns ModelModulePackageMinimal successful
     * @throws ApiError
     */
    public modelModulePackages({
        slug,
        page = '1',
        perPage = '30',
    }: {
        /**
         * Model slug
         */
        slug: string,
        page?: string,
        perPage?: string,
    }): CancelablePromise<Array<ModelModulePackageMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/module-packages',
            path: {
                'slug': slug,
            },
            query: {
                'page': page,
                'perPage': perPage,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Upgrades
     * @returns ModelUpgradeMinimal successful
     * @throws ApiError
     */
    public modelUpgrades({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<Array<ModelUpgradeMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/upgrades',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * Model Paints
     * @returns ModelPaintMinimal successful
     * @throws ApiError
     */
    public modelPaints({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<Array<ModelPaintMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/paints',
            path: {
                'slug': slug,
            },
            errors: {
                404: `not found`,
            },
        });
    }

    /**
     * @deprecated
     * Model Storeimage
     * @returns void
     * @throws ApiError
     */
    public modelStoreImage({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/store-image',
            path: {
                'slug': slug,
            },
            errors: {
                302: `successful`,
            },
        });
    }

    /**
     * @deprecated
     * Model Fleetchart Image
     * @returns void
     * @throws ApiError
     */
    public modelFleetchartImage({
        slug,
    }: {
        /**
         * Model slug
         */
        slug: string,
    }): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/models/{slug}/fleetchart-image',
            path: {
                'slug': slug,
            },
            errors: {
                302: `successful`,
                404: `not found`,
            },
        });
    }

}
