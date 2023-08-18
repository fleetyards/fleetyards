/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ModelPaintMinimal } from '../models/ModelPaintMinimal';
import type { ModelPaintQuery } from '../models/ModelPaintQuery';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class ModelPaintsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Model Paints List
     * @returns ModelPaintMinimal successful
     * @throws ApiError
     */
    public paints({
        page = '1',
        perPage = '30',
        q,
    }: {
        page?: string,
        perPage?: string,
        q?: ModelPaintQuery,
    }): CancelablePromise<Array<ModelPaintMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/model-paints',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
            },
        });
    }

}
