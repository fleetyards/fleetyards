/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { TradeRoute } from '../models/TradeRoute';
import type { TradeRouteQuery } from '../models/TradeRouteQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class TradeRoutesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Trade Routes
     * @returns TradeRoute successful
     * @throws ApiError
     */
    public tradeRoutes({
        page = '1',
        perPage = '50',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: TradeRouteQuery,
        cacheId?: string,
    }): CancelablePromise<Array<TradeRoute>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/trade-routes',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }

}
