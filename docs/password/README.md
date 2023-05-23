# Password

## POST /v1/password/request

+ Request (application/json)

    + Headers

            Accept: application/json

    + Body

            {
                "email": "me@mortik.xyz"
            }

+ Response 200 (application/json; charset=utf-8)

    + Headers

            Vary: Origin
            Set-Cookie: _app_session=UzVSRVVHcGJwOVBWMGUrRjB3UFlmd0hpTFh2ZWZ3R1VFNElNYjdIcGIrcHFoWHhCMFFOS2hxcW5TMHdISmVUYkQvcXY4aFJHMlFZWXVXdU1IMFFURGc9PS0taGhrWnpZM1Y4aUJwTEZlOFBHVXBnZz09--8612e900bab1fe556e7ff43ecb730293aed2b549; path=/; HttpOnly
            X-XSS-Protection: 1; mode=block
            Transfer-Encoding: chunked
            Cache-Control: max-age=0, private, must-revalidate
            X-Request-Id: cea4c5db-ba3f-4efd-a176-2e84bdc55341
            X-Rack-CORS: miss; no-origin
            X-Content-Type-Options: nosniff
            Etag: W/"db11adb9b5b264147b4f38c68f78d210"
            X-Frame-Options: SAMEORIGIN

    + Body

            {"code":"request_pasword.success","message":"If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."}


