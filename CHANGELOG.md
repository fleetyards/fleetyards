# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [6.10.0](https://github.com/fleetyards/fleetyards/compare/v6.9.5...v6.10.0) (2026-04-21)


### Features

* **ci:** Upload Vite assets to Bunny Storage before deploy ([035791f](https://github.com/fleetyards/fleetyards/commit/035791f7c56b2973b0ff9f96ed0a70eee07ab7ec))


### Bug Fixes

* render HTML in confirm dialog text ([568185f](https://github.com/fleetyards/fleetyards/commit/568185f3422e99a4c8732f22a1369c62e9e47011))
* replace vue-upload-component with DirectUpload in hangar import ([9dfe9fd](https://github.com/fleetyards/fleetyards/commit/9dfe9fd15b105376d9efda5a7c744bce289c2a05))
* replace vuedraggable with sortablejs for hangar group labels ([7545a44](https://github.com/fleetyards/fleetyards/commit/7545a44305e21937a76d4991b788420763181d3a))
* resolve eslint errors in hangar group labels sortable ([5e511ac](https://github.com/fleetyards/fleetyards/commit/5e511ac26f05958d7793e30338f7f928b2c19510))
* write filter params flat to route query instead of nesting under q ([3fd3816](https://github.com/fleetyards/fleetyards/commit/3fd38160dd18e163fdeadb99fd86a7eddf860a60))

## [6.9.5](https://github.com/fleetyards/fleetyards/compare/v6.9.4...v6.9.5) (2026-04-20)


### Bug Fixes

* fix hardpoint overflow and unify module cargo grid rendering ([42016bd](https://github.com/fleetyards/fleetyards/commit/42016bd4ba1b289d3f378ec5110a8311a6c02c8f))
* pass manufacturer slug instead of full object in filter query ([a610383](https://github.com/fleetyards/fleetyards/commit/a6103833d5cbd06792d6b93322f2db7013fc01b3))
* redesign module panels to card layout with image on top ([70bf73a](https://github.com/fleetyards/fleetyards/commit/70bf73a5582f1e8b4e2914b9b2d0dc7990066d03))
* use correct key for module cargo calculation from hardpoints ([8dbe2d5](https://github.com/fleetyards/fleetyards/commit/8dbe2d55b50a8cac531702cd0ae4acb86975b412))

## [6.9.4](https://github.com/fleetyards/fleetyards/compare/v6.9.3...v6.9.4) (2026-04-20)


### Bug Fixes

* constrain front view size on mobile ([6add2e1](https://github.com/fleetyards/fleetyards/commit/6add2e1559d3a82464d2a1909bfebcc4724e3894))
* show pagination on mobile for single-page results ([6e4d0ca](https://github.com/fleetyards/fleetyards/commit/6e4d0ca67c5682f987bbeea22825398c5ab8f3ec))

## [6.9.3](https://github.com/fleetyards/fleetyards/compare/v6.9.2...v6.9.3) (2026-04-20)


### Bug Fixes

* restore correct fleetchart view order (angled first, top second) ([2d67b3b](https://github.com/fleetyards/fleetyards/commit/2d67b3bf85ce28e0617b315d40a76c8a1ad0bb44))

## [6.9.2](https://github.com/fleetyards/fleetyards/compare/v6.9.1...v6.9.2) (2026-04-20)


### Bug Fixes

* correct ship detail fleetchart view proportions and layout ([9f325ca](https://github.com/fleetyards/fleetyards/commit/9f325cac591e11416f27d64b139f5a679d88107f))
* derive module component key for ships with unlinked module hardpoints ([5a423cd](https://github.com/fleetyards/fleetyards/commit/5a423cd7119e69074a3a35b9f5e5b4cea732072b))
* prevent stale cached HTML from causing 404s on Vite assets after deploys ([3d86d74](https://github.com/fleetyards/fleetyards/commit/3d86d74dc3a38cac24204955dd511b01c04a2a1d))

## [6.9.1](https://github.com/fleetyards/fleetyards/compare/v6.9.0...v6.9.1) (2026-04-19)


### Bug Fixes

* add sc_key override field to models for SC data identifier mismatch ([8df5926](https://github.com/fleetyards/fleetyards/commit/8df5926819ca374aed6668004c009ace9f1c989b))

## [6.9.0](https://github.com/fleetyards/fleetyards/compare/v6.8.0...v6.9.0) (2026-04-19)


### Features

* add admin model modules overview page ([9c92270](https://github.com/fleetyards/fleetyards/commit/9c922706b001a2fb9a25edc805d20fcbb2cf96fc))
* add bulk actions (activate, hide, destroy) to admin modules list ([1543e3c](https://github.com/fleetyards/fleetyards/commit/1543e3cb3736d92118a70f722b58cc8a2e1352a7))
* add sc_key field to admin model modules edit page ([b9f2fcc](https://github.com/fleetyards/fleetyards/commit/b9f2fccb138b7c8b22f9c64eac8ab592e19b3b80))
* add tabbed edit form for admin modules with models and prices tabs ([678fd04](https://github.com/fleetyards/fleetyards/commit/678fd04e8c9e69b3e297489a21d5459e64571d02))
* display model count in fleet table view when grouped ([8401c41](https://github.com/fleetyards/fleetyards/commit/8401c410c03d193350bd5ffbcc3777782e756698))


### Bug Fixes

* add missing productionStatus placeholder for module form ([73d501e](https://github.com/fleetyards/fleetyards/commit/73d501ef5721d279e60c7d8f5df414a4b2d54aae))
* add missing sc_key to admin module API response and edit action to module list ([2fd0ba5](https://github.com/fleetyards/fleetyards/commit/2fd0ba50707891b80452e29d171432ecaefb3296))
* add models array to ModelModule API schema ([735469b](https://github.com/fleetyards/fleetyards/commit/735469bc5239ad4d34c00cd09c3ea4707d044b17))
* add module edit translations for es, fr, it, zh-CN, zh-TW ([0fdeff8](https://github.com/fleetyards/fleetyards/commit/0fdeff89ade0d888510ebd7bc251996c2c6b2c7d))
* attach store_image when importing new modules ([8a03186](https://github.com/fleetyards/fleetyards/commit/8a03186e3079e153aaf44be220a0bf015a632a23))
* create module hardpoints for all matching models in modules importer ([df8583b](https://github.com/fleetyards/fleetyards/commit/df8583b891eb796b27889711407f2a223c31a4f7))
* hide empty box in InlineEditableList when create form is open ([302fe3f](https://github.com/fleetyards/fleetyards/commit/302fe3f39ed1d5af4af92d99ffdcef4e376e7b18))
* optional chain on possibly undefined fleetRole in fleet member components ([ae01aa6](https://github.com/fleetyards/fleetyards/commit/ae01aa617b82439a2d3917f3c160c6d2d88b9b2d))
* optional chain on possibly undefined models array ([f729203](https://github.com/fleetyards/fleetyards/commit/f729203887dc1a55ad04045555d1caaa19c49dc5))
* prevent jbuilder deep_format_keys from camelizing model count slug keys ([df1416d](https://github.com/fleetyards/fleetyards/commit/df1416db09e1a0af0d3e54e539e45e43dcffb06e))
* remove redundant JSON.parse for jsonb input columns ([1d22aef](https://github.com/fleetyards/fleetyards/commit/1d22aefaa8d8f38ede6d2048cfc1dfe6c005b297))
* remove singular model key from module API response ([2484a82](https://github.com/fleetyards/fleetyards/commit/2484a820a6806771124d48eb0282ae7a72ff58ba))
* rename Aurora module names to match in-game names ([9ec1d8f](https://github.com/fleetyards/fleetyards/commit/9ec1d8f143be4cd49fd0c50927ac9ece0b23882f))
* replace Sentry.capture_exception with Appsignal.report_error ([d4cc27e](https://github.com/fleetyards/fleetyards/commit/d4cc27e42f9ae7590e216387085e24fe5f0faee8))
* resolve N+1 queries and unnecessary validations causing high server load ([fcfa909](https://github.com/fleetyards/fleetyards/commit/fcfa909d3acb75c6e91f30a797ff25f7e82e3c61))
* restrict DocsController#index to HTML format ([cface58](https://github.com/fleetyards/fleetyards/commit/cface58b9fba418fdcd372b7f81aa35fc9d60051))
* skip GitHub issue creation when token is not configured ([fbc48c6](https://github.com/fleetyards/fleetyards/commit/fbc48c6c377ed1779dccc3a5d8792edafa9bcb4b))
* unify module mappings and fix false positives in modules import ([#3718](https://github.com/fleetyards/fleetyards/issues/3718)) ([98e34dd](https://github.com/fleetyards/fleetyards/commit/98e34dd90dca74e12f397d27fc710e1abb65c561))
* use production status select, add German translations, set flight-ready from SC data ([39f361a](https://github.com/fleetyards/fleetyards/commit/39f361a5ccea0001dc751b31a9e794b235a244fb))

## [6.8.0](https://github.com/fleetyards/fleetyards/compare/v6.7.2...v6.8.0) (2026-04-19)


### Features

* add manufacturer codes to model URLs ([#3695](https://github.com/fleetyards/fleetyards/issues/3695)) ([aac5d00](https://github.com/fleetyards/fleetyards/commit/aac5d00dbe2f54dfe617b762d71b152b3c1381f7))
* module hardpoints and cargo grids on model detail page ([#3717](https://github.com/fleetyards/fleetyards/issues/3717)) ([bcd8597](https://github.com/fleetyards/fleetyards/commit/bcd85979643b696ea7b7a537ce18b6dc0552588f))


### Bug Fixes

* add :all to Model per_page_steps for consistent pagination options ([3a583e1](https://github.com/fleetyards/fleetyards/commit/3a583e15fc9b2a81cd69c41ebc32f1261f4cca54))
* add Aurora Mk II module mappings to importer and hangar sync ([3b349c6](https://github.com/fleetyards/fleetyards/commit/3b349c60e91b93a4b761793b1b578cdf52eed8c6))
* add set -e to pre-deploy hook to fail fast on migration errors ([c4f1f6b](https://github.com/fleetyards/fleetyards/commit/c4f1f6bdef6c5a466fa3e1ff1c13ee44af51aa46))
* ensure social login buttons render at consistent size ([2b6bbdc](https://github.com/fleetyards/fleetyards/commit/2b6bbdc7ae4bf2fbb1d4a3328e07cefe37b006af))
* hangar sync getting stuck by handling empty pages and parse errors ([de7bcbe](https://github.com/fleetyards/fleetyards/commit/de7bcbe34cce9c17d33a7c577e111e7277b36b4b))
* keep per-page dropdown visible when "all" is selected ([2f2a164](https://github.com/fleetyards/fleetyards/commit/2f2a164f57e4bf29f3e72a61a0cc3d0fbe44fb87))
* prevent hangar sync from stopping early on pages with no matching items ([cd20b39](https://github.com/fleetyards/fleetyards/commit/cd20b39d291a705c38cba948946addd7ff41a110))
* remove model_id from model_module_params to fix UnknownAttributeError ([707747e](https://github.com/fleetyards/fleetyards/commit/707747e968629c1dce283207817384c3c0529025))
* remove unused model_id column from model_modules ([aafe93d](https://github.com/fleetyards/fleetyards/commit/aafe93dae229e6b9eeccfe6a5af791475bba419f))
* touch user on omniauth connection changes to bust cache ([4552d72](https://github.com/fleetyards/fleetyards/commit/4552d720e36787a58b8e070488de13a331f7a493))
* use GithubIssueCreator in import tasks and extract issue body to importers ([2528bc7](https://github.com/fleetyards/fleetyards/commit/2528bc7276970b26c225f8c70a365e3709744dff))
* use separate query for ModelPaint without legacy_slug column ([fa03523](https://github.com/fleetyards/fleetyards/commit/fa0352351fd4186b71a4ed9d59e679803053a1b8))


### Refactorings

* remove sc_identifier, derive from slug ([#3714](https://github.com/fleetyards/fleetyards/issues/3714)) ([f8158a0](https://github.com/fleetyards/fleetyards/commit/f8158a0a8a40960e6c4f203fc199ed651b090eee))


### Chores

* apply prettier formatting fixes ([3ccef94](https://github.com/fleetyards/fleetyards/commit/3ccef9433841477adf7bd250a64da051b32c98dc))

## [6.7.2](https://github.com/fleetyards/fleetyards/compare/v6.7.1...v6.7.2) (2026-04-17)


### Bug Fixes

* **ci:** pin oasdiff version to avoid GitHub API rate limiting ([67da757](https://github.com/fleetyards/fleetyards/commit/67da75754be113dcbfb111cc2f05e9c94948d1a6))
* handle jsonb input in modules importer extract_modules ([14151e4](https://github.com/fleetyards/fleetyards/commit/14151e448b489fcee5630ad718616fd87d3e69ba))


### Chores

* **deps-dev:** bump faker from 3.7.1 to 3.8.0 ([#3710](https://github.com/fleetyards/fleetyards/issues/3710)) ([12db520](https://github.com/fleetyards/fleetyards/commit/12db5204cca752bcc4ecb59e0bfc206e839db27b))
* **deps-dev:** bump msw from 2.13.3 to 2.13.4 ([#3709](https://github.com/fleetyards/fleetyards/issues/3709)) ([eb2aa90](https://github.com/fleetyards/fleetyards/commit/eb2aa9022ddda00a30108d5189d8e7e68c87fedc))
* **deps-dev:** bump typescript from 6.0.2 to 6.0.3 ([#3712](https://github.com/fleetyards/fleetyards/issues/3712)) ([45bf45d](https://github.com/fleetyards/fleetyards/commit/45bf45de689860d1d3b5dc4e205e8aa50bc038b3))
* **deps:** bump committee from 5.6.2 to 5.6.3 ([#3711](https://github.com/fleetyards/fleetyards/issues/3711)) ([a36cb80](https://github.com/fleetyards/fleetyards/commit/a36cb80695be773def05d1d96786abb9b33fb2ad))
* **deps:** bump sidekiq from 8.1.2 to 8.1.3 ([#3708](https://github.com/fleetyards/fleetyards/issues/3708)) ([2d93ed7](https://github.com/fleetyards/fleetyards/commit/2d93ed789767f1b5a1e9bd1b2eadf0994e729af3))
* **deps:** bump three and @types/three ([#3707](https://github.com/fleetyards/fleetyards/issues/3707)) ([80f73ed](https://github.com/fleetyards/fleetyards/commit/80f73ed1839c2086a868eefcb51197dfa36c11b3))

## [6.7.1](https://github.com/fleetyards/fleetyards/compare/v6.7.0...v6.7.1) (2026-04-16)


### Bug Fixes

* pass version flag to kamal exec in pre-deploy hook ([e28170d](https://github.com/fleetyards/fleetyards/commit/e28170d3c4d2349c2d29486c1f59bb3e0623305a))
* skip non-module components silently during hangar sync ([33c182d](https://github.com/fleetyards/fleetyards/commit/33c182df8fc21715d3428a608b6bcb05c30a634c))
* use will_save_change_to_location? in before_validation callback ([c0a2745](https://github.com/fleetyards/fleetyards/commit/c0a2745b30b5e3472f28df08b1923577e35209f8))

## [6.7.0](https://github.com/fleetyards/fleetyards/compare/v6.6.1...v6.7.0) (2026-04-16)


### Features

* add bin/op wrapper for 1Password secret injection ([95aea7e](https://github.com/fleetyards/fleetyards/commit/95aea7e1ae3a6b6e9fcb4f7c7ee88e3280b2f5a4))
* add fleet member worldmap and starmap ([#3688](https://github.com/fleetyards/fleetyards/issues/3688)) ([ecb85e0](https://github.com/fleetyards/fleetyards/commit/ecb85e0520a2faad20cf087c496f9d12e4d86402))
* add persistent notification center backend ([#3689](https://github.com/fleetyards/fleetyards/issues/3689)) ([ece407f](https://github.com/fleetyards/fleetyards/commit/ece407f3f675e81c6dca0db9fac48eab27acee07))
* add public hangar stats with metrics and charts ([#3694](https://github.com/fleetyards/fleetyards/issues/3694)) ([837404e](https://github.com/fleetyards/fleetyards/commit/837404ee657d0406f8fc70c9792a6e38015595c8))
* allow all RSI components in hangar sync and schedule modules import ([5152697](https://github.com/fleetyards/fleetyards/commit/5152697558404fad686f717072fe8b4be10c3df7))
* use separate databases for worktrees ([2b1cb2f](https://github.com/fleetyards/fleetyards/commit/2b1cb2fc022063a9c67546798455adf83fdebc59))


### Bug Fixes

* add hangar import mappings for MOLE Carbon Edition and Gladius Dunlevy, create Raptor model ([9ae02bd](https://github.com/fleetyards/fleetyards/commit/9ae02bda253a4793c5190919026efbb88a2b9c21))
* disable mail delivery in download-db test account updates ([7f07e9b](https://github.com/fleetyards/fleetyards/commit/7f07e9beb968434d0d737616ce8a196d7524725d))
* disable OTP for frontend user in download-db ([a5b02cd](https://github.com/fleetyards/fleetyards/commit/a5b02cdf05c114a957381184730b482573d1c09c))
* drop and recreate database in download-db script ([6324f2d](https://github.com/fleetyards/fleetyards/commit/6324f2d8780493860a6a035ad65ed1b3ed10a346))
* include module port definitions in scdata models parser ([1933806](https://github.com/fleetyards/fleetyards/commit/1933806eb51caed961d283d93116a3dcbf540c5c))
* link member requested notification email to invites page instead of members page ([76ecc70](https://github.com/fleetyards/fleetyards/commit/76ecc70f26c64cc2bd733e9d40003e985d670581))
* move Raptor model creation from migration to seeds ([0217ad6](https://github.com/fleetyards/fleetyards/commit/0217ad680be6e331338117cbfa2e15c334c975ed))
* prevent user deletion from silently failing due to permanent fleet roles ([15b8f5a](https://github.com/fleetyards/fleetyards/commit/15b8f5a1398114ed002705dd86cbc8e8fab87a89))
* prevent user deletion from silently failing due to permanent fleet roles ([7bf08af](https://github.com/fleetyards/fleetyards/commit/7bf08af983559898c2cfe26e31a797ad49f0c67e))
* public fleet ship list not updating when toggling grouped ([572056f](https://github.com/fleetyards/fleetyards/commit/572056fb8671a50ecd6d064a3d8dafba95fcd378))
* quote %(bucket)s in s3cmd host-bucket flag to prevent shell syntax error ([f0f37b9](https://github.com/fleetyards/fleetyards/commit/f0f37b99cb0e240db92372c5a291a1a9f694c8c6))
* redirect to private hangar after OAuth login instead of public hangar ([6980cc7](https://github.com/fleetyards/fleetyards/commit/6980cc7f0c367d386c66d94e56bd71a188ed2b9a))
* refresh user data on security settings page to update OAuth button state ([0d4c039](https://github.com/fleetyards/fleetyards/commit/0d4c039df73f2b3c4685efeeac70d2356c969b67))
* replace floating-vue with custom tooltip directive and fix paint upload ([7fcf425](https://github.com/fleetyards/fleetyards/commit/7fcf4258f07732d82e207f38198abd84ff662159))
* reset FormFileInput display after file prop updates ([2154e1c](https://github.com/fleetyards/fleetyards/commit/2154e1cae6e1f66e95c441f70d4768ac851bfdb9))
* reset schema version after deleted Raptor migration ([63bf83b](https://github.com/fleetyards/fleetyards/commit/63bf83bf81b3656c1fc190b31e7cbc82e7b01770))
* resolve floating promise lint error in security settings page ([0eb59c8](https://github.com/fleetyards/fleetyards/commit/0eb59c8bec8db7ad5c21f2c6dcb6db3c743795c7))
* respect subdomain setting for admin maintenance URLs ([9195baf](https://github.com/fleetyards/fleetyards/commit/9195bafa04ce4924a22b55558f2cd5ffc4535f88))
* send removeAvatar flag when clearing avatar in profile settings ([dd81f08](https://github.com/fleetyards/fleetyards/commit/dd81f08def5eb1b8b59421a22c26e6c33ac3dbc4))
* skip download-db re-download when local dump is already up to date ([f0349fd](https://github.com/fleetyards/fleetyards/commit/f0349fd2bd4dd2d0d646cb3c57b8de082e38c4b7))
* split hangar controller into separate index and public actions ([0c03881](https://github.com/fleetyards/fleetyards/commit/0c038810e2cd568919a1927c1446bca387a38813))
* update defu to 6.1.7 to resolve prototype pollution vulnerability (CVE) ([8885026](https://github.com/fleetyards/fleetyards/commit/88850264307f642aec272cad9ebffb1f3ddbdda4))
* use deliver_later for AdminUser devise notifications ([26c9b66](https://github.com/fleetyards/fleetyards/commit/26c9b66c07ee734ed5b107780522a5a1988a73df))
* use file size instead of MD5 for download-db skip check ([52a571f](https://github.com/fleetyards/fleetyards/commit/52a571f46c2659c8a853a95382b1ab486a3cbdae))


### Refactorings

* extract shared examples for spec auth and import patterns ([#3696](https://github.com/fleetyards/fleetyards/issues/3696)) ([91a2b34](https://github.com/fleetyards/fleetyards/commit/91a2b34c0cdc4d0c9cec9cd0ce1e40553296e462))


### Chores

* **deps-dev:** bump @tanstack/vue-query-devtools from 6.1.14 to 6.1.16 ([#3679](https://github.com/fleetyards/fleetyards/issues/3679)) ([42a776c](https://github.com/fleetyards/fleetyards/commit/42a776c8ede0371e8360c2028966f5c3a08e2cf8))
* **deps-dev:** bump @typescript-eslint/eslint-plugin ([#3692](https://github.com/fleetyards/fleetyards/issues/3692)) ([60c55de](https://github.com/fleetyards/fleetyards/commit/60c55de4b7fe4e4c722d7f3690bd591343f27131))
* **deps-dev:** bump @typescript-eslint/parser from 8.58.1 to 8.58.2 ([#3683](https://github.com/fleetyards/fleetyards/issues/3683)) ([042def7](https://github.com/fleetyards/fleetyards/commit/042def7f9d1dc11b1fd96eedbf9baafdf18c8aaf))
* **deps-dev:** bump @vitejs/plugin-vue from 6.0.5 to 6.0.6 ([#3686](https://github.com/fleetyards/fleetyards/issues/3686)) ([67956fc](https://github.com/fleetyards/fleetyards/commit/67956fc35ace4e30d176b967318633686774a8ab))
* **deps-dev:** bump faker from 3.6.1 to 3.7.1 ([#3690](https://github.com/fleetyards/fleetyards/issues/3690)) ([2b99b6d](https://github.com/fleetyards/fleetyards/commit/2b99b6d31a8ebcf0252433efb0538341eb59b73a))
* **deps-dev:** bump knip from 6.4.0 to 6.4.1 ([#3678](https://github.com/fleetyards/fleetyards/issues/3678)) ([14fea78](https://github.com/fleetyards/fleetyards/commit/14fea78ff50be44659295800d7af7790caf54326))
* **deps-dev:** bump msw from 2.13.2 to 2.13.3 ([#3684](https://github.com/fleetyards/fleetyards/issues/3684)) ([c187165](https://github.com/fleetyards/fleetyards/commit/c1871655ec19a3c85e2100a45dbdbf0a150867a2))
* **deps-dev:** bump orval from 8.7.0 to 8.8.0 ([#3701](https://github.com/fleetyards/fleetyards/issues/3701)) ([ad02f9e](https://github.com/fleetyards/fleetyards/commit/ad02f9e2ffa58226ea68c18aaaaa98ad9615ad5b))
* **deps-dev:** bump prettier from 3.8.2 to 3.8.3 ([#3691](https://github.com/fleetyards/fleetyards/issues/3691)) ([9abbdad](https://github.com/fleetyards/fleetyards/commit/9abbdad0cb0d7430601d5ec242e5a0c551596a04))
* **deps-dev:** bump stylelint from 17.6.0 to 17.7.0 ([#3677](https://github.com/fleetyards/fleetyards/issues/3677)) ([0ea748c](https://github.com/fleetyards/fleetyards/commit/0ea748cc3c0cf266e747f1dc23553ecc0b2f1385))
* **deps-dev:** bump timecop from 0.9.10 to 0.9.11 ([#3675](https://github.com/fleetyards/fleetyards/issues/3675)) ([85a6faf](https://github.com/fleetyards/fleetyards/commit/85a6faf9c10e942e2b5c07915b9289f2ead9dfd8))
* **deps:** bump highcharts from 12.5.0 to 12.6.0 ([#3685](https://github.com/fleetyards/fleetyards/issues/3685)) ([3414ebb](https://github.com/fleetyards/fleetyards/commit/3414ebbe3b1fa949f3bc9c0a63037f09998fac7f))
* **deps:** bump oj from 3.16.16 to 3.16.17 ([#3676](https://github.com/fleetyards/fleetyards/issues/3676)) ([5016be8](https://github.com/fleetyards/fleetyards/commit/5016be813ce769775a0a15880125e70d4b7f2ab7))
* **deps:** bump pghero from 3.7.0 to 3.8.0 ([#3697](https://github.com/fleetyards/fleetyards/issues/3697)) ([c13b61e](https://github.com/fleetyards/fleetyards/commit/c13b61e8c3f10e4ef2d4458f97e8aa87a4ca6da4))
* **deps:** bump rollups from 0.5.0 to 0.6.0 ([#3698](https://github.com/fleetyards/fleetyards/issues/3698)) ([30249d2](https://github.com/fleetyards/fleetyards/commit/30249d214846b95b19de7b34332b157c014aeeb8))
* **deps:** bump swagger-ui-dist from 5.32.2 to 5.32.3 ([#3693](https://github.com/fleetyards/fleetyards/issues/3693)) ([e898a4a](https://github.com/fleetyards/fleetyards/commit/e898a4a552be8ab060dd90162c414561080f5006))
* **deps:** bump swagger-ui-dist from 5.32.3 to 5.32.4 ([#3699](https://github.com/fleetyards/fleetyards/issues/3699)) ([895811e](https://github.com/fleetyards/fleetyards/commit/895811e2d513c84e89e04685f1d913f1b323eeee))
* move exec-plan to docs/exec-plans directory ([5e208ec](https://github.com/fleetyards/fleetyards/commit/5e208ecd14ab7b9b553d748b6fb28f5626da9ec3))
* remove dotenv gems and .env.test in preparation for Rails 8.2 ([0f98db2](https://github.com/fleetyards/fleetyards/commit/0f98db21d190d06309615429fd9392942bd4be06))
* remove extra blank line in RSIHangarParser ([fafabc8](https://github.com/fleetyards/fleetyards/commit/fafabc8bd9700ea3aea9a7495d1520d818cd2e0b))
* remove unused nix development setup ([e3a7123](https://github.com/fleetyards/fleetyards/commit/e3a712326beb7309921aae7c9cf3d7d71bce4c25))
* simplify Vue feature flags and remove redundant env vars ([251be4e](https://github.com/fleetyards/fleetyards/commit/251be4e160d51e3b5bf4ada6940a3f6cb7ed377f))
* update ListGroup layout and local dev database/redis defaults ([dd1e46b](https://github.com/fleetyards/fleetyards/commit/dd1e46b99ad39601eb24fead64d0a780297c8763))
* update SC data version to 4.7.1-live.11638371 ([bbaa811](https://github.com/fleetyards/fleetyards/commit/bbaa811d205dd7d921199f3357c55540311e471c))
* update schema and user model annotations ([012afd6](https://github.com/fleetyards/fleetyards/commit/012afd643eca8474fada3882045dcdd9f95de7bc))
* update schema annotations for user and omniauth_connection ([70ccb78](https://github.com/fleetyards/fleetyards/commit/70ccb78a8f7c5e7325a89c1c55e4e658473c4ae9))
* use 1Password CLI for secrets and credentials management ([#3682](https://github.com/fleetyards/fleetyards/issues/3682)) ([97b9ddb](https://github.com/fleetyards/fleetyards/commit/97b9ddbe212c9d63f053afde0ad263053042383a))

## [6.6.1](https://github.com/fleetyards/fleetyards/compare/v6.6.0...v6.6.1) (2026-04-12)


### Bug Fixes

* add top margin to RSI session status in sync modal ([942a7a3](https://github.com/fleetyards/fleetyards/commit/942a7a3f25a30ef370dd3cebe846722663fdb7e8))
* **deploy:** run data migrations in Kamal pre-deploy hook ([70e7e4d](https://github.com/fleetyards/fleetyards/commit/70e7e4d1b7ca0e88c13de40f1ae2d4a63fb34daf))
* remove double JSON serialization for jsonb columns in hangar sync ([588ec65](https://github.com/fleetyards/fleetyards/commit/588ec65198f71c8cc53f0e45579aec75bd8c51f7))
* use wildcard for Twitch CSP form-action to cover full redirect chain ([6d2325d](https://github.com/fleetyards/fleetyards/commit/6d2325ddb2fe2439dea3fee09abac3a04721d0cf))

## [6.6.0](https://github.com/fleetyards/fleetyards/compare/v6.5.0...v6.6.0) (2026-04-12)


### Features

* **hangar:** prevent duplicate syncs and add status endpoint ([967cac1](https://github.com/fleetyards/fleetyards/commit/967cac140c12623fef592a9085b6b3fbf4a6bdc7))
* **hangar:** show sync status notification via WebSocket ([2318555](https://github.com/fleetyards/fleetyards/commit/23185550609261b2ba8c4330029c513d5764ea7c))
* **oauth:** add tests, wire up all providers, remove Apple, and set up Bluesky ([119995f](https://github.com/fleetyards/fleetyards/commit/119995f43cc84ad20689a6f4904431d80d8a2083))


### Bug Fixes

* add www.twitch.tv to CSP form-action for OAuth redirect chain ([a633735](https://github.com/fleetyards/fleetyards/commit/a633735de07ca11d6c9a5ec54b16d6949ea8a2f8))
* close BtnDropdown on item click ([d0cafb6](https://github.com/fleetyards/fleetyards/commit/d0cafb6e073e7776dde397b0f19f9ff88416dca6))
* handle nil user in omniauth callback when email exists but no user found ([d555c17](https://github.com/fleetyards/fleetyards/commit/d555c17fe226ceb0e66dcd9a150cf9703bee73cb))
* **hangar:** fetch sync status on startup and fix google oauth boot ([c9e8945](https://github.com/fleetyards/fleetyards/commit/c9e894586edfe7dbffade180ea11d67d6a8e8b0d))
* **hangar:** move RSI hangar sync to background job to prevent 504 timeouts ([ecfd7d9](https://github.com/fleetyards/fleetyards/commit/ecfd7d9563d73fd0c949fb1d237af00054554d1e))
* overhaul embed v2 — migrate fleetchart image, fix layout and translations ([d02dcdf](https://github.com/fleetyards/fleetyards/commit/d02dcdf4881d5bebfce66c9ec25968e93c586627))
* redirect to hangar after successful OAuth login instead of sign-up page ([286fdfd](https://github.com/fleetyards/fleetyards/commit/286fdfd17375d791e005d17e79c6aac4145f36fc))
* remove unnecessary cookie consent modal ([aee02ad](https://github.com/fleetyards/fleetyards/commit/aee02adb8a06dad8c9bcb96ac6e3fbadf031ab27))
* remove unused hangarGroupIds variable in GroupsModal ([7265beb](https://github.com/fleetyards/fleetyards/commit/7265beb428831d2ed4662061cbdbf7be445b0778))
* rename Google OAuth provider from google_oauth2 to google ([f3130db](https://github.com/fleetyards/fleetyards/commit/f3130db902300cdd9102c8af8ea549971b3a2690))
* resolve faraday-retry and sidekiq/testing deprecation warnings ([b2d1014](https://github.com/fleetyards/fleetyards/commit/b2d1014e025a1eb047d21dbbe51593a3b58f8510))
* restore missing data-test attributes in embed components ([cca0783](https://github.com/fleetyards/fleetyards/commit/cca07831db4b05f6154ce8b5f99076fea2ee5ead))
* revert sidekiq/testing require to fix test suite ([4d926bc](https://github.com/fleetyards/fleetyards/commit/4d926bc70552f1da6cc0d4059f95d645d0dde8e1))
* use flex: none for fleetchart image wrapper to prevent zero-width collapse ([986a63f](https://github.com/fleetyards/fleetyards/commit/986a63f6ec10751f71863ef6319cb3d32d71e644))
* use shared vee-validate field name in GroupsModal checkboxes ([749ffdd](https://github.com/fleetyards/fleetyards/commit/749ffdd94bf219724961dd634109fc470c07ad99))


### Chores

* add Google and Bluesky OAuth credentials for production ([efb67ad](https://github.com/fleetyards/fleetyards/commit/efb67ad20a22243afe424282b0725afbf5bd5430))
* fix prettier formatting in embed components ([3d9cfa2](https://github.com/fleetyards/fleetyards/commit/3d9cfa2b2946169766adf07be84cedac773825cb))
* formatting fixes from linter ([91f4340](https://github.com/fleetyards/fleetyards/commit/91f4340afb4b64449d295227a352169518b14b4f))

## [6.5.0](https://github.com/fleetyards/fleetyards/compare/v6.4.1...v6.5.0) (2026-04-10)


### Features

* add separate matrix and SC data reload buttons on model edit page ([64175a4](https://github.com/fleetyards/fleetyards/commit/64175a44195314acf644e87b3039d30330647fe4))


### Bug Fixes

* cast attachment ransacker UUID to text for blank predicate ([d704fe9](https://github.com/fleetyards/fleetyards/commit/d704fe90ee78bd3771e5187abf821535e46ec741))
* remove Mastodon link from footer ([8bd0742](https://github.com/fleetyards/fleetyards/commit/8bd07428480f8e10f359616d3d892cf797763535))
* update AppFooter test link count after Mastodon removal ([a4b9af3](https://github.com/fleetyards/fleetyards/commit/a4b9af36208ba5a8f5b10ef3cc5512be2e84e022))


### Chores

* replace deprecated lighten() with color.adjust() ([adc162b](https://github.com/fleetyards/fleetyards/commit/adc162b51813cc4f6516fce6646f1c9d81b5b839))
* update admin swagger schema ([b420eb6](https://github.com/fleetyards/fleetyards/commit/b420eb6f57a81a1eceeec77836ac1c38cf9d98cf))

## [6.4.1](https://github.com/fleetyards/fleetyards/compare/v6.4.0...v6.4.1) (2026-04-10)


### Bug Fixes

* preserve manually set sc_identifier in ship matrix import ([6a525b3](https://github.com/fleetyards/fleetyards/commit/6a525b3ef03183ce8b13c618398f148ba8bb3083))

## [6.4.0](https://github.com/fleetyards/fleetyards/compare/v6.3.0...v6.4.0) (2026-04-10)


### Features

* Enable AppSignal logging for production and staging ([bb80edc](https://github.com/fleetyards/fleetyards/commit/bb80edc81a8d036e7af744c638c812b4f80c217c))


### Bug Fixes

* Add missing CABLE_ENDPOINT to admin layout and sync notification ([f17e76c](https://github.com/fleetyards/fleetyards/commit/f17e76cd650215b87a2c30c138781df67aad9d39))
* Display rsiStoreImage instead of storeImage in admin models list ([2103266](https://github.com/fleetyards/fleetyards/commit/210326676d3e777eed0fa5a63297d1f66f40dd6d))
* Remove debug statements and legacy role tests ([7bfad3b](https://github.com/fleetyards/fleetyards/commit/7bfad3b9b437fe210f660ed03e936a0fc52f1eee))
* Remove legacy role enum from FleetMembership and use FleetRole for notifications ([028680d](https://github.com/fleetyards/fleetyards/commit/028680dec83be2f3feb103732e6b6b999bb5f481))
* Update FleetMembersStats schema to match actual API response ([42e8ac2](https://github.com/fleetyards/fleetyards/commit/42e8ac23f0067741ba101e18653de6da1a2c3c57))


### Chores

* **deps-dev:** bump prettier from 3.8.1 to 3.8.2 ([#3665](https://github.com/fleetyards/fleetyards/issues/3665)) ([8381acb](https://github.com/fleetyards/fleetyards/commit/8381acb05569d9b2f6b1912af959cbbcfc4b2e35))
* **deps:** bump actions/github-script from 8 to 9 ([#3666](https://github.com/fleetyards/fleetyards/issues/3666)) ([a8d62e2](https://github.com/fleetyards/fleetyards/commit/a8d62e219e7d88862b410d9f269be5e295d1963e))
* **deps:** bump qs from 6.15.0 to 6.15.1 ([#3664](https://github.com/fleetyards/fleetyards/issues/3664)) ([3c620dc](https://github.com/fleetyards/fleetyards/commit/3c620dcbda87230cd151516a48a4ab23f5381ec3))
* Format German translation messages JSON ([c9bb4b0](https://github.com/fleetyards/fleetyards/commit/c9bb4b07eb73269b61b0d22504528aea4202f794))
* update deps ([78015f9](https://github.com/fleetyards/fleetyards/commit/78015f9c2b57431c62f3eee0289085ac2bfa45c5))
* Update Ruby from 3.4.7 to 4.0.2 ([89c8131](https://github.com/fleetyards/fleetyards/commit/89c813198e098068b9dd78fbde33fcc8c4d47a48))

## [6.3.0](https://github.com/fleetyards/fleetyards/compare/v6.2.1...v6.3.0) (2026-04-09)


### Features

* Add sync command to bin/scdata for downloading SC data from Hetzner S3 ([4b1ba4d](https://github.com/fleetyards/fleetyards/commit/4b1ba4d019eee55a128f67e0ba254dcd7b8897c9))


### Bug Fixes

* Handle optional model.links in Vue templates after schema change ([b5e611c](https://github.com/fleetyards/fleetyards/commit/b5e611c7f0d8f5076458477de452409be8557b46))
* Make links optional in Model schema since jbuilder drops nil-only blocks ([7e128d0](https://github.com/fleetyards/fleetyards/commit/7e128d0c4e3d84d15bd90a67e423ad0923d25adb))
* Remove non-existent `import` attribute from imports jbuilder ([41c9018](https://github.com/fleetyards/fleetyards/commit/41c901803375dac952cec427d3359d5ff37075d4))
* Replace remote seed images with local stub to avoid bucket dependency ([5ea6821](https://github.com/fleetyards/fleetyards/commit/5ea6821dfac6dd4b1261abc68c17d035a5462a31))
* Return raw URLs in admin models jbuilder to prevent double RSI domain prepending ([9bf24d2](https://github.com/fleetyards/fleetyards/commit/9bf24d28943f45c3745a7349263c60856fcd2d06))
* Stop event propagation on BaseTable actions and selection columns ([056aea2](https://github.com/fleetyards/fleetyards/commit/056aea2ede99a53ad89cf9cc66e84ca804b213ee))
* Update items loader spec expected count for SC data 4.7.1-live.11592622 ([644afd1](https://github.com/fleetyards/fleetyards/commit/644afd186e309f872c5fa442a58e52f3763f3290))
* Update rsi_store_image sync to re-download outdated images and only persist timestamp on success ([38df91e](https://github.com/fleetyards/fleetyards/commit/38df91eb017183dc976f95f1373e6214f17c6bb1))


### Chores

* Default live console to sandbox mode and add danger script for write access ([d7c26fa](https://github.com/fleetyards/fleetyards/commit/d7c26fa1edde4caf6aa9f843b37271132b218a70))
* **deps-dev:** bump @types/three from 0.181.0 to 0.183.1 ([#3642](https://github.com/fleetyards/fleetyards/issues/3642)) ([700dc33](https://github.com/fleetyards/fleetyards/commit/700dc338fa383372ec1f06e1aaf68df38a62a04d))
* **deps-dev:** bump @typescript-eslint/eslint-plugin ([#3638](https://github.com/fleetyards/fleetyards/issues/3638)) ([4383bd6](https://github.com/fleetyards/fleetyards/commit/4383bd6f7c775383bb5b73e0176d28b4e23244dc))
* **deps-dev:** bump jsdom from 29.0.1 to 29.0.2 ([#3647](https://github.com/fleetyards/fleetyards/issues/3647)) ([d1b7390](https://github.com/fleetyards/fleetyards/commit/d1b7390bdc9615c533c8cd27824fd463f919d4f0))
* **deps:** bump @rails/actioncable and @types/rails__actioncable ([#3637](https://github.com/fleetyards/fleetyards/issues/3637)) ([493c974](https://github.com/fleetyards/fleetyards/commit/493c9741fee39be0eb6205fec603fcdf436987e1))
* **deps:** bump ahoy_matey from 5.4.2 to 5.5.0 ([#3636](https://github.com/fleetyards/fleetyards/issues/3636)) ([ddc45bc](https://github.com/fleetyards/fleetyards/commit/ddc45bceae83c296c515df9881205bb4dea1e53b))
* **deps:** bump axios from 1.14.0 to 1.15.0 ([#3644](https://github.com/fleetyards/fleetyards/issues/3644)) ([3f238bd](https://github.com/fleetyards/fleetyards/commit/3f238bdc2ab74a717ed3332d1a13641b1c6ad5ca))
* **deps:** bump core-js from 3.48.0 to 3.49.0 ([#3640](https://github.com/fleetyards/fleetyards/issues/3640)) ([73e01f7](https://github.com/fleetyards/fleetyards/commit/73e01f72d6aa2be77c7c42b63a1ae569e0b392b4))
* **deps:** bump qs from 6.15.0 to 6.15.1 ([#3641](https://github.com/fleetyards/fleetyards/issues/3641)) ([32499f1](https://github.com/fleetyards/fleetyards/commit/32499f122f4165b090501c30c2c8879c5495d74c))
* Remove AppSignal monitoring accessory from Kamal config ([e0426d1](https://github.com/fleetyards/fleetyards/commit/e0426d121a1a30f0a54d1b64198db44b67fa2cef))
* Remove setup command from bin/scdata ([6da74ee](https://github.com/fleetyards/fleetyards/commit/6da74ee8c44644a66650c66562ee4262210228b0))
* Update SC data to 4.7.1-live.11592622 ([a731bc1](https://github.com/fleetyards/fleetyards/commit/a731bc1fadb03fb993846f6db8c3cd0339651b69))

## [6.2.1](https://github.com/fleetyards/fleetyards/compare/v6.2.0...v6.2.1) (2026-04-08)


### Bug Fixes

* Add missing loaner mappings for Aurora Mk I and MXC variants ([a8a62e3](https://github.com/fleetyards/fleetyards/commit/a8a62e337af9e73f87fb31e329cba3f178d7cf24)), closes [#3522](https://github.com/fleetyards/fleetyards/issues/3522)
* Add missing paint mappings for Aurora Mk I, Hercules, Mercury, and MXC variants ([bc8b3e3](https://github.com/fleetyards/fleetyards/commit/bc8b3e36c2ae9cf907e7810e350f89d301e58319)), closes [#3521](https://github.com/fleetyards/fleetyards/issues/3521)

## [6.2.0](https://github.com/fleetyards/fleetyards/compare/v6.1.0...v6.2.0) (2026-04-08)


### Features

* Add bulk enable/disable actions for admin images ([#3616](https://github.com/fleetyards/fleetyards/issues/3616)) ([cde4434](https://github.com/fleetyards/fleetyards/commit/cde443406f6da36210b3811501e506bbf525b234))
* Add copy function for paints in admin model edit ([#3615](https://github.com/fleetyards/fleetyards/issues/3615)) ([b4f2987](https://github.com/fleetyards/fleetyards/commit/b4f2987c5d36e0948699ebed5e43af6b45908d5f))


### Bug Fixes

* **ci:** Fix Discord notification shell quoting issues ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Fix release workflow and merge_group API breaking changes check ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Pass release body via env var to avoid bash syntax errors ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Use manual GraphQL pagination in move-done-to-deployed ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* Include last page items in hangar sync ([e85eb89](https://github.com/fleetyards/fleetyards/commit/e85eb89eca2689a17510a5812adaec24b2a8f99e))
* Move db:migrate from post-deploy to pre-deploy hook ([f722a3b](https://github.com/fleetyards/fleetyards/commit/f722a3b0d684eeb0d2c244d9d4eab68af0fc4459))
* Pass wishlist prop to VehiclePanel in wishlist grid view ([#3619](https://github.com/fleetyards/fleetyards/issues/3619)) ([e8a587d](https://github.com/fleetyards/fleetyards/commit/e8a587d69c785ce56a0527c6b57aec26666c3ad8))
* Remove orphaned trade_routes and equipment routes ([6796e05](https://github.com/fleetyards/fleetyards/commit/6796e05385515d553fb42efe1fdea34b2edfa23d))
* Replace Toggle switches with icon buttons in InlineEditableList actions ([#3617](https://github.com/fleetyards/fleetyards/issues/3617)) ([64fe6d6](https://github.com/fleetyards/fleetyards/commit/64fe6d6e13adf87bdac73f9c54a570f7b61a212b))
* Update rack-session and addressable for security vulnerabilities ([#3618](https://github.com/fleetyards/fleetyards/issues/3618)) ([3a57222](https://github.com/fleetyards/fleetyards/commit/3a572228ec87ba25ab8cfa113ad939add6459075))


### Refactorings

* Replace deprecated next() callback with return-based navigation guards ([c6dbe4d](https://github.com/fleetyards/fleetyards/commit/c6dbe4de4a492d3826d428bbeb9d13a932602483))


### Chores

* Add maintenance task to touch all models for cache invalidation ([d76e82c](https://github.com/fleetyards/fleetyards/commit/d76e82ceba03d64b2be0561c2fa339b47f28ea44))
* **ci:** Add manual workflow to move Done items to Deployed ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Extract move-done-to-deployed into reusable job file ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Reintegrate move-done-to-deployed into release workflow ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Remove move-done-to-deployed from release workflow ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Show repo and issue number in move-done-to-deployed logs ([000254d](https://github.com/fleetyards/fleetyards/commit/000254d73736f06737575751ccb63ef2313cfbd4))
* **ci:** Use Playwright container image for e2e tests ([#3613](https://github.com/fleetyards/fleetyards/issues/3613)) ([d49bd3e](https://github.com/fleetyards/fleetyards/commit/d49bd3e36866960b3e945046aca5982dec1b8c8f))
* **deps-dev:** bump @faker-js/faker from 9.9.0 to 10.4.0 ([#3625](https://github.com/fleetyards/fleetyards/issues/3625)) ([94a1ba2](https://github.com/fleetyards/fleetyards/commit/94a1ba2dbb537881987a207db48490500611edb4))
* **deps-dev:** bump @tanstack/eslint-plugin-query ([#3628](https://github.com/fleetyards/fleetyards/issues/3628)) ([4376b04](https://github.com/fleetyards/fleetyards/commit/4376b040fe67993d3862637ef46e170b6cdaf337))
* **deps-dev:** bump @types/rails__activestorage from 7.1.1 to 8.0.1 ([#3620](https://github.com/fleetyards/fleetyards/issues/3620)) ([b324a27](https://github.com/fleetyards/fleetyards/commit/b324a27b8e572c56871d0dee1a21262552f7a39c))
* **deps-dev:** bump @types/uuid from 10.0.0 to 11.0.0 ([#3631](https://github.com/fleetyards/fleetyards/issues/3631)) ([c3d264c](https://github.com/fleetyards/fleetyards/commit/c3d264c03e3a9b49dc31b1cf3d6adc16c64023c8))
* **deps-dev:** bump @typescript-eslint/parser from 8.57.0 to 8.58.1 ([#3630](https://github.com/fleetyards/fleetyards/issues/3630)) ([527c924](https://github.com/fleetyards/fleetyards/commit/527c924eeb2e4f83d1af6e4a4169cd4ff353771c))
* **deps-dev:** bump knip from 5.88.1 to 6.3.1 ([#3621](https://github.com/fleetyards/fleetyards/issues/3621)) ([39c05d9](https://github.com/fleetyards/fleetyards/commit/39c05d9d57372365e5893ece2339b71b922f7ae2))
* **deps-dev:** bump stylelint-scss from 6.14.0 to 7.0.0 ([#3627](https://github.com/fleetyards/fleetyards/issues/3627)) ([32fe10c](https://github.com/fleetyards/fleetyards/commit/32fe10c1e44ae22ace8c9a8dee0f52d8bedb5854))
* **deps-dev:** bump vite from 8.0.5 to 8.0.7 ([#3624](https://github.com/fleetyards/fleetyards/issues/3624)) ([2bbbe99](https://github.com/fleetyards/fleetyards/commit/2bbbe99680ed211d5d53a886a7ccfa9dcc5dd700))
* **deps:** bump actions/github-script from 7 to 8 ([#3629](https://github.com/fleetyards/fleetyards/issues/3629)) ([47dddae](https://github.com/fleetyards/fleetyards/commit/47dddae48a52c2a2128b3ca080af1fb2602fea08))
* **deps:** bump aws-sdk-s3 from 1.218.0 to 1.219.0 ([#3623](https://github.com/fleetyards/fleetyards/issues/3623)) ([d94a0f8](https://github.com/fleetyards/fleetyards/commit/d94a0f8b440cc210852e930a8ed7daf2efad344d))
* **deps:** bump axios from 1.13.6 to 1.14.0 ([#3626](https://github.com/fleetyards/fleetyards/issues/3626)) ([82a0090](https://github.com/fleetyards/fleetyards/commit/82a009003b752f3eb856988528c666556162d444))
* **deps:** bump vue-router from 4.5.1 to 5.0.4 ([#3622](https://github.com/fleetyards/fleetyards/issues/3622)) ([5a5f90b](https://github.com/fleetyards/fleetyards/commit/5a5f90b4270103ce87b461a722c82d2673936f2a))
* Update Dependabot schedule from weekly to daily ([d301c14](https://github.com/fleetyards/fleetyards/commit/d301c149306f7cdb7966c3ed8ed9593bb634c9b1))

## [6.1.0](https://github.com/fleetyards/fleetyards/compare/v6.0.2...v6.1.0) (2026-04-07)


### Features

* **ci:** use Discord embed for release notifications ([f95b6e1](https://github.com/fleetyards/fleetyards/commit/f95b6e1448afad856690bb028a2417a1e2b8865e))
* Show labels for icon actions and toggles in InlineEditableList on mobile ([005d58e](https://github.com/fleetyards/fleetyards/commit/005d58eaa15aeee84f6a4ab468a7e48d05657574))


### Bug Fixes

* Add create group link to mobile group filter dropdown ([de6865d](https://github.com/fleetyards/fleetyards/commit/de6865d631aa54a2fda7e295a36cc9a7edcc9e15))
* Add missing monitoring accessory host for stage ([a94d4f4](https://github.com/fleetyards/fleetyards/commit/a94d4f43ace1abfec077974c6cca08f7849922d4))
* Add nullable to update input schemas for string/number fields ([df6c8d8](https://github.com/fleetyards/fleetyards/commit/df6c8d8386124a3cb259cadb64a1322fa144be84))
* Add REDIS_URL to worktree .env.local and drop rdbg from Procfile ([6ffd89a](https://github.com/fleetyards/fleetyards/commit/6ffd89a95e6ba1b3a71b9033d8bb26969cb9f84e))
* Bump vite from 8.0.3 to 8.0.5 to resolve security vulnerabilities ([56cd7fb](https://github.com/fleetyards/fleetyards/commit/56cd7fb9d2cf22db6aa81bf0db69cd8c3e0c24d1))
* **ci:** Restore API breaking changes check on push to main ([b2f5fc3](https://github.com/fleetyards/fleetyards/commit/b2f5fc3a795f9546ca199104fe321f821cd9ec06))
* **ci:** Revert workflow files move to jobs/ subdirectory ([06c2290](https://github.com/fleetyards/fleetyards/commit/06c2290b3262fc69df8aa3c13bd4ccd0b6926f8e))
* **ci:** Run API breaking changes check on push to main ([87d034d](https://github.com/fleetyards/fleetyards/commit/87d034d777ed80a7c2899fe5159448942b3d2cea))
* Drop rdbg wrapper from Procfile ([ec2333e](https://github.com/fleetyards/fleetyards/commit/ec2333ea559c2b3a23ddd8738ce572397176019f))
* Fix publicFLeet typo in fleet settings form field name ([28dcacd](https://github.com/fleetyards/fleetyards/commit/28dcacdac159558e19c843cb99f742bf8d80bd54))
* **frontend:** serialize hangar export data as JSON before creating Blob ([#3611](https://github.com/fleetyards/fleetyards/issues/3611)) ([c5f7fc5](https://github.com/fleetyards/fleetyards/commit/c5f7fc5448aa9e44f36fe5747cb1f3e34c44ead1)), closes [#3610](https://github.com/fleetyards/fleetyards/issues/3610)
* Hide social logins section when no providers are active ([aad8373](https://github.com/fleetyards/fleetyards/commit/aad83735626566b024873ea5b2b65c8f6371a3d8))
* Increase container memory limits and add host monitoring ([cc19b4d](https://github.com/fleetyards/fleetyards/commit/cc19b4d9e8d37704cbed3ed8e907c2fbdb14a7ff))
* Link mobile nav fleet entry to user's primary fleet ([71d1a50](https://github.com/fleetyards/fleetyards/commit/71d1a50262393393ab4ed25dc4d62010c6687988))
* Lower Docker memory limits for stage to fit 4g servers ([487ee2c](https://github.com/fleetyards/fleetyards/commit/487ee2ca206e7b8cef6664ec57601f90eebd96ac))
* Navigate to login page before filling credentials in e2e test ([39026f1](https://github.com/fleetyards/fleetyards/commit/39026f1b9898b0b831943d8ced48f57dba3426d6))
* Only build email assets in setup instead of full Vite build ([7786e1b](https://github.com/fleetyards/fleetyards/commit/7786e1b610532dc564839c5c3f79636be693c810))
* Override transitive vite 7.x to resolve Dependabot security alerts ([f476c55](https://github.com/fleetyards/fleetyards/commit/f476c5563e1f6a536fbe23bf4323fd7baf57c7eb))
* Raise BtnDropdown z-index above fleetchart fullscreen overlay ([ffebad4](https://github.com/fleetyards/fleetyards/commit/ffebad4252f262bf28a78c7ba83ce25e5c57e4eb))
* Remove nullable from hangar group name and color fields ([0e4cd61](https://github.com/fleetyards/fleetyards/commit/0e4cd611d2f8ddba8e818113e2fe021dafe49ee7))
* Replace mobile tab off-canvas with horizontal scrollable tabs ([434413b](https://github.com/fleetyards/fleetyards/commit/434413b369cb0c0eb83c3ae1e4df5feb696afec8))
* Replace nprogress with custom FetchProgressBar component ([235a62c](https://github.com/fleetyards/fleetyards/commit/235a62c666c2d9012c64fe50e4ad6bfe46e75379))
* Resolve multiple production frontend errors from AppSignal ([87aebff](https://github.com/fleetyards/fleetyards/commit/87aebff051d6410bef2f5f1a3c5e1a6a101a6331))
* Set node-version to lts/* explicitly in CI workflows ([7b62422](https://github.com/fleetyards/fleetyards/commit/7b62422f288ddb505e489fa6a23b48574bffc771))
* Stop RSI hangar sync from loading pages endlessly ([9f8066e](https://github.com/fleetyards/fleetyards/commit/9f8066edd38f4384966e861eefab80006e068884))
* Update CI Node.js and pnpm versions to match .tool-versions ([f581338](https://github.com/fleetyards/fleetyards/commit/f581338ea619656dd0684fef67651445965ac836))
* Update defu to 6.1.6 to fix prototype pollution vulnerability (CVE-2026-35209) ([efe941c](https://github.com/fleetyards/fleetyards/commit/efe941c040830f38c337610b64e7062a1c6e66f4))
* Upload and avatar UI improvements ([edc0a0c](https://github.com/fleetyards/fleetyards/commit/edc0a0c090b526ec328bd04c7d1ef1762cd726de))
* Use correct AppSignal standalone agent Docker image ([ee469e2](https://github.com/fleetyards/fleetyards/commit/ee469e2e7f978402666ca457c115410375ed3f3e))
* Wait for page load and API response in fleet settings e2e test ([474766d](https://github.com/fleetyards/fleetyards/commit/474766dcde75c247d67787e72c94b9314cdeccd1))


### Chores

* CI and infrastructure housekeeping ([eec89e0](https://github.com/fleetyards/fleetyards/commit/eec89e02d7fb6864c12afbe2fa8a097d325c7c8f))
* **ci:** Clean up CI workflow files ([0f6fe5f](https://github.com/fleetyards/fleetyards/commit/0f6fe5f519491413d289e4f6d31bdf106dd870f4))
* **ci:** Move reusable job workflows to jobs/ subdirectory ([1ac6033](https://github.com/fleetyards/fleetyards/commit/1ac6033747319f768fbcab1f27d6ef98b6ee67fd))
* **deps-dev:** bump @trivago/prettier-plugin-sort-imports ([#3604](https://github.com/fleetyards/fleetyards/issues/3604)) ([360b292](https://github.com/fleetyards/fleetyards/commit/360b292619220dc3898ace2badf38022460b9a67))
* **deps-dev:** bump @types/node from 25.5.0 to 25.5.2 ([#3598](https://github.com/fleetyards/fleetyards/issues/3598)) ([f6910be](https://github.com/fleetyards/fleetyards/commit/f6910be5d4ab504856d37b52a0c58da69d8f11d1))
* **deps-dev:** bump c8 from 10.1.3 to 11.0.0 ([#3599](https://github.com/fleetyards/fleetyards/issues/3599)) ([03c7165](https://github.com/fleetyards/fleetyards/commit/03c716591d4f7341df643e9537efb0d365ad77a9))
* **deps-dev:** bump jsdom from 26.1.0 to 29.0.1 ([#3606](https://github.com/fleetyards/fleetyards/issues/3606)) ([16931c9](https://github.com/fleetyards/fleetyards/commit/16931c9372a5d73ba6aeff689c19d02bad92774e))
* **deps-dev:** bump sass from 1.97.3 to 1.99.0 ([#3603](https://github.com/fleetyards/fleetyards/issues/3603)) ([628fc44](https://github.com/fleetyards/fleetyards/commit/628fc444a987f1a3e0fa1a46a2f0e6ae3687b7fe))
* **deps-dev:** bump unplugin-auto-import from 20.3.0 to 21.0.0 ([#3601](https://github.com/fleetyards/fleetyards/issues/3601)) ([a22be03](https://github.com/fleetyards/fleetyards/commit/a22be030c2789ee14dd4715c50b309ab074eae35))
* **deps:** bump @number-flow/vue from 0.4.12 to 0.5.0 ([#3600](https://github.com/fleetyards/fleetyards/issues/3600)) ([0e5fe7c](https://github.com/fleetyards/fleetyards/commit/0e5fe7c993459eb181b193146b1be88d8fe1cdea))
* **deps:** bump @tanstack/vue-query from 5.96.1 to 5.96.2 ([#3605](https://github.com/fleetyards/fleetyards/issues/3605)) ([a3656b9](https://github.com/fleetyards/fleetyards/commit/a3656b988a426121aed5c72459b678972ce70e7c))
* **deps:** bump actions/checkout from 4 to 6 ([#3607](https://github.com/fleetyards/fleetyards/issues/3607)) ([6e0898d](https://github.com/fleetyards/fleetyards/commit/6e0898dea1931f3182a3b7a72a5b7d0e97ffd3cf))
* **deps:** bump actions/download-artifact from 4 to 8 ([#3608](https://github.com/fleetyards/fleetyards/issues/3608)) ([feead41](https://github.com/fleetyards/fleetyards/commit/feead41a83f51b587d53ac24fc17603dbe627d90))
* **deps:** bump docker/metadata-action from 5 to 6 ([#3609](https://github.com/fleetyards/fleetyards/issues/3609)) ([affc227](https://github.com/fleetyards/fleetyards/commit/affc227e788dc1dab3a58d4616078ba69cf1508d))
* **deps:** bump groupdate from 6.7.0 to 6.8.0 ([#3596](https://github.com/fleetyards/fleetyards/issues/3596)) ([4be531c](https://github.com/fleetyards/fleetyards/commit/4be531c08d9b1aab295f7a680c6715323073647f))
* **deps:** bump three from 0.181.1 to 0.183.2 ([#3597](https://github.com/fleetyards/fleetyards/issues/3597)) ([ad7e8df](https://github.com/fleetyards/fleetyards/commit/ad7e8df75e56b7ae7be43bd98ea375d24b6043ad))
* **deps:** bump vue from 3.5.31 to 3.5.32 ([#3602](https://github.com/fleetyards/fleetyards/issues/3602)) ([91e15f3](https://github.com/fleetyards/fleetyards/commit/91e15f308284849bff311997fc006cfa0b6e8535))
* Format fixes from prettier ([27651ac](https://github.com/fleetyards/fleetyards/commit/27651acd555a18d5aef4e712562cbf17ec0405ab))
* Remove Carrierwave, switch to Active Storage only ([dc6872e](https://github.com/fleetyards/fleetyards/commit/dc6872e30f8e57933439b0038cfdd26a6bfaf837))
* Remove Heroku remnants, consolidate dev scripts and Procfiles ([19ee5c3](https://github.com/fleetyards/fleetyards/commit/19ee5c31e61baa24a9d86e39a7a7245e4de282b2))

## [6.0.2](https://github.com/fleetyards/fleetyards/compare/v6.0.1...v6.0.2) (2026-04-03)


### Bug Fixes

* Accept version argument in ScData::AllJob#perform ([ecf450c](https://github.com/fleetyards/fleetyards/commit/ecf450cb24c57861f2e0b66bf42ff517a3a246a1))
* Self-heal orphaned representation variants on redirect ([9cd1ce3](https://github.com/fleetyards/fleetyards/commit/9cd1ce375b48ed8ae2466430ab2f46bc7dfb6658))


### Chores

* **ci:** replace custom release workflows with release-please ([d0d078e](https://github.com/fleetyards/fleetyards/commit/d0d078e00e67c0782ddf3b747ffe9b4e1b96833c))
* Remove completed image migration tasks ([4024887](https://github.com/fleetyards/fleetyards/commit/4024887caeb5a20150a21fd94940e05cd1995bb7))

### [6.0.1](https://github.com/fleetyards/fleetyards/compare/v6.0.0...v6.0.1) (2026-04-03)


### Bug Fixes

* **deploy:** Write REVISION file during Docker build for admin UI git version ([30d33fb](https://github.com/fleetyards/fleetyards/commit/30d33fb0fd77bd71fa30b97e948b7286810ba543))

### [6.0.0](https://github.com/fleetyards/fleetyards/compare/v5.33.2...v6.0.0) (2026-04-03)


### Features

* add bin/create-hotfix script for local hotfix branch setup ([445ec73](https://github.com/fleetyards/fleetyards/commit/445ec73b10ee6919a211273664bf65db918d4f0d))
* **ci:** add hotfix support to prepare-release workflow ([8c4b0ad](https://github.com/fleetyards/fleetyards/commit/8c4b0adb05b2f201e4b002b6bda9bcbb13d3e04f))
* **ci:** auto-detect semver bump from conventional commits in prepare-release ([69b4877](https://github.com/fleetyards/fleetyards/commit/69b48774d5efec3d79fe2aa98c9fda99caad155d))

### Bug Fixes

* **frontend:** Add missing component to admin maintenance route ([09f5ebd](https://github.com/fleetyards/fleetyards/commit/09f5ebde34d405682e95aebb549b6b6515ead7ad))
* **ci:** read Ruby version from .tool-versions for Docker build ([31a5d2d](https://github.com/fleetyards/fleetyards/commit/31a5d2def419b77e026394c1aeb3ff8850a79eed))
* reset version to v5.33.2 after deleting RC releases ([b35653c](https://github.com/fleetyards/fleetyards/commit/b35653c621e7b635b9fccd5f71f54e36d5f0aaa4))
* **ci:** pass secrets to build job in release workflow ([b4d363a](https://github.com/fleetyards/fleetyards/commit/b4d363adda1c07e4eb2bf93f840e23180f4d58e6))
* **ci:** skip version bump when creating additional RCs in same cycle ([4b2c3e0](https://github.com/fleetyards/fleetyards/commit/4b2c3e099d4f5b2b66668af7408641332a0d89ab))
* **ci:** use RELEASE_TOKEN for releases and add chore commits to changelog ([d57a387](https://github.com/fleetyards/fleetyards/commit/d57a3876e80236c08c6099fc3d38530675242d5e))
* use RELEASE_TOKEN to bypass branch protection in release workflows ([6c03107](https://github.com/fleetyards/fleetyards/commit/6c0310734233d6950013160765ed1d8099fb52d6))
* handle invalid UTF-8 byte sequences in request parameter keys ([446e1aa](https://github.com/fleetyards/fleetyards/commit/446e1aa1fa23feb31edb53a3cbe3464521eeec2d))

### Refactorings

* **ci:** detect hotfix from branch name instead of manual input ([fb24f10](https://github.com/fleetyards/fleetyards/commit/fb24f1085ab7f4a4ee55921b7cc07553877539fe))

### Chores

* **release:** v6.0.0-rc.5 (Aurora) ([c853cbc](https://github.com/fleetyards/fleetyards/commit/c853cbcafa23be4a675e59e8972365fa23a6fe91))
* **release:** v6.0.0-rc.4 (Aurora) ([75bb961](https://github.com/fleetyards/fleetyards/commit/75bb961be339c1208a7d927fe0115e22d24ce324))
* **deps-dev:** bump @types/node from 24.12.0 to 25.5.0 (#3584) ([4b54d64](https://github.com/fleetyards/fleetyards/commit/4b54d6428722e2fa980b44d0d1d648baac14ee0f))
* **deps:** bump actions/setup-node from 4 to 6 (#3588) ([0995d0c](https://github.com/fleetyards/fleetyards/commit/0995d0cb9f46de65d43759698ceed3d24dc35f8d))
* **deps-dev:** bump the playwright group with 2 updates (#3590) ([e05c493](https://github.com/fleetyards/fleetyards/commit/e05c493e5dd90af69605ee51eafbae3ac49f8c65))
* **deps-dev:** bump vue-tsc from 3.2.5 to 3.2.6 (#3581) ([b1a5828](https://github.com/fleetyards/fleetyards/commit/b1a5828dacc8525e35c6b1b976d4cd8c5eee4f18))
* **deps:** bump cachix/cachix-action from 11 to 17 (#3586) ([0289cc0](https://github.com/fleetyards/fleetyards/commit/0289cc042dffecabe894a21bddf8d64e1d62879a))
* **deps:** bump actions/upload-artifact from 4 to 7 (#3587) ([a5aec78](https://github.com/fleetyards/fleetyards/commit/a5aec7883feb843bc3b005e03882ee46a96345ca))
* **deps:** bump cachix/install-nix-action from 18 to 31 (#3589) ([6fc9ceb](https://github.com/fleetyards/fleetyards/commit/6fc9cebdaad24d1401e76568a85f1af9f1ff0e36))
* **deps:** bump docker/setup-buildx-action from 3 to 4 (#3585) ([cbbc49a](https://github.com/fleetyards/fleetyards/commit/cbbc49a5fa2a0c33dc074b1f2ec23cc38ee557c7))
* **deps-dev:** bump vite-plugin-rails from 0.5.0 to 0.6.0 (#3577) ([dbc47b8](https://github.com/fleetyards/fleetyards/commit/dbc47b8c4e5af5931e8af299de48b1923618ebd4))
* **deps-dev:** bump @tanstack/vue-query-devtools from 5.91.0 to 6.1.12 (#3582) ([0806e93](https://github.com/fleetyards/fleetyards/commit/0806e936517c983e3b281823622164a8db977b86))
* **deps:** bump panzoom from 9.4.3 to 9.4.4 (#3580) ([39d0df1](https://github.com/fleetyards/fleetyards/commit/39d0df1214eab1a2b1e56b6b82389571ccdd4277))
* **deps:** bump @vueuse/core from 13.9.0 to 14.2.1 (#3583) ([093b296](https://github.com/fleetyards/fleetyards/commit/093b2961af14bc925a80d70775107353a13a6813))
* **deps-dev:** bump web-console from 4.2.1 to 4.3.0 (#3578) ([861b2c7](https://github.com/fleetyards/fleetyards/commit/861b2c7c89d8dafffed761c0f9c342721dbfe5b6))
* **deps-dev:** bump unplugin-vue-components from 29.2.0 to 32.0.0 (#3576) ([cf0b46e](https://github.com/fleetyards/fleetyards/commit/cf0b46e40998e51f9e04ed9a718a6e728afd0109))
* **deps:** bump uuid from 11.1.0 to 13.0.0 (#3573) ([158e36c](https://github.com/fleetyards/fleetyards/commit/158e36c18ae35550279cd090d92c1662e84bb37d))
* **deps:** bump sidekiq from 8.0.10 to 8.1.2 (#3575) ([e18ad4c](https://github.com/fleetyards/fleetyards/commit/e18ad4c661cfa8175c939eb120186da218ffa123))
* **deps:** bump ahoy_matey from 5.4.1 to 5.4.2 (#3572) ([9b9f73c](https://github.com/fleetyards/fleetyards/commit/9b9f73c33ecacef0b3f5fb1727f8d9b2ff28ab5e))
* **deps:** bump docker/build-push-action from 6 to 7 (#3571) ([6030ded](https://github.com/fleetyards/fleetyards/commit/6030ded2bea0ab59df5e0aa30eb4b620cba50f07))
* **deps:** bump EndBug/add-and-commit from 9 to 10 (#3570) ([216afd7](https://github.com/fleetyards/fleetyards/commit/216afd7e5969f4124c23b4c879c5074f1f45c90e))
* **deps:** bump Eeems-Org/apt-cache-action from 1.3 to 1.5 (#3569) ([11ba459](https://github.com/fleetyards/fleetyards/commit/11ba459dde66eb46779b5b4eff785526c4475480))
* **deps:** bump docker/login-action from 3 to 4 (#3567) ([e3f7fe7](https://github.com/fleetyards/fleetyards/commit/e3f7fe7921c9561be3b5127ab824e5161e5217ae))
* **deps:** bump actions/cache from 4 to 5 (#3568) ([6097c8c](https://github.com/fleetyards/fleetyards/commit/6097c8c4444c8f3dbc15557b124a67ea9095e211))
* **release:** v6.0.0-rc.3 (Aurora) ([9eb142b](https://github.com/fleetyards/fleetyards/commit/9eb142b311638789f4beaad8e0e0c97cb45fcee9))
* **release:** v6.0.0-rc.2 (Aurora) ([4e93793](https://github.com/fleetyards/fleetyards/commit/4e93793f26e4af3ec5a8bce5a738f261ee56a1a5))
* **release:** v6.0.0-rc.2 (Aurora) ([5d02ebb](https://github.com/fleetyards/fleetyards/commit/5d02ebbd3f33b9c2e9fcfd91c04741cb9b3e8795))
* **release:** v6.0.0-rc.1 (Aurora) ([1d43285](https://github.com/fleetyards/fleetyards/commit/1d432850f12ab0a2e1546296cc5f40675265616c))
* add Claude Code skills for resolving import issues ([5334239](https://github.com/fleetyards/fleetyards/commit/5334239d3cb45f78d1283f5e6917a9232397d26b))
* Migrate to Vue 3 (#2655) ([5cc1365](https://github.com/fleetyards/fleetyards/commit/5cc1365a3986d20310eee032ed2ea945c5cce634))

### [5.33.2](https://github.com/fleetyards/fleetyards/compare/v5.33.1...v5.33.2) (2026-03-26)


### Bug Fixes

* use LEGACY_SSH_KEY for legacy Capistrano deploys ([4b24d88](https://github.com/fleetyards/fleetyards/commit/4b24d88fea7c27d6e4cb696d7a8d4c847e92fe77))

### [5.33.1](https://github.com/fleetyards/fleetyards/compare/v5.33.0...v5.33.1) (2026-03-26)


### Bug Fixes

* rename deploy job to legacy and use dynamic known_hosts ([6eda803](https://github.com/fleetyards/fleetyards/commit/6eda8038c3a7701b10936eff4e660b6051fc0966))

## [5.33.0](https://github.com/fleetyards/fleetyards/compare/v5.32.12...v5.33.0) (2026-03-26)


### Features

* replace admin emails with GitHub issue creation for paints import and loaner sync ([7960c3b](https://github.com/fleetyards/fleetyards/commit/7960c3bf8afa8ef882f5433f65e9d7973a4f0bf5))


### Bug Fixes

* add .worktrees to .gitignore ([ffa0b9a](https://github.com/fleetyards/fleetyards/commit/ffa0b9ad8f9101e5bba480610c3ffa143bd0185a))
* clean up schema.rb from vue3 branch pollution ([7201c6e](https://github.com/fleetyards/fleetyards/commit/7201c6e2fcf7f13b98031794b1101c99e8be5730))

### [5.32.12](///compare/v5.32.11...v5.32.12) (2025-12-09)

### [5.32.11](///compare/v5.32.10...v5.32.11) (2025-12-09)


### Bug Fixes

* **fleetchart:** update height calculation. ea3a4fb

### [5.32.10](///compare/v5.32.9...v5.32.10) (2025-12-05)

### [5.32.9](///compare/v5.32.8...v5.32.9) (2025-12-05)

### [5.32.8](///compare/v5.32.7...v5.32.8) (2025-12-05)


### Bug Fixes

* **mailer:** update asset host bc7b526

### [5.32.7](///compare/v5.32.6...v5.32.7) (2025-12-05)


### Bug Fixes

* **cdn:** update image paths 8d0daea

### [5.32.6](///compare/v5.32.5...v5.32.6) (2025-12-05)


### Bug Fixes

* **cdn:** update csp header to allow manifest from cdn bfb2f27

### [5.32.5](///compare/v5.32.4...v5.32.5) (2025-12-05)


### Bug Fixes

* **cdn:** update csp headers 8e69339

### [5.32.4](///compare/v5.32.3...v5.32.4) (2025-12-05)

### [5.32.3](///compare/v5.32.2...v5.32.3) (2025-12-05)

### [5.32.2](///compare/v5.32.1...v5.32.2) (2025-12-05)

### [5.32.1](///compare/v5.32.0...v5.32.1) (2025-12-05)

## [5.32.0](///compare/v5.31.82...v5.32.0) (2025-12-05)


### Features

* **models:** add link to Atlas Defense Industries Map tool 650d51e

### [5.31.82](///compare/v5.31.81...v5.31.82) (2025-12-04)


### Bug Fixes

* **stats:** update fleet and hangar stats to calculate price values correctly 6ec972e

### [5.31.81](///compare/v5.31.80...v5.31.81) (2025-12-01)


### Bug Fixes

* **fleetyards-sync:** update throttling to reenable sync d4ecfa6

### [5.31.80](///compare/v5.31.79...v5.31.80) (2025-12-01)


### Bug Fixes

* **fleetyards-sync:** remove target origin to fix endless run e207cf5

### [5.31.79](///compare/v5.31.78...v5.31.79) (2025-12-01)


### Bug Fixes

* **fleetyards-sync:** resolve async call which leads to endless loading of pages 81f4510

### [5.31.78](///compare/v5.31.77...v5.31.78) (2025-12-01)


### Bug Fixes

* **fleetyards-sync:** limit requests to 50 per minute and add retry button dbc941f

### [5.31.77](///compare/v5.31.76...v5.31.77) (2025-11-28)

### [5.31.76](///compare/v5.31.75...v5.31.76) (2025-11-28)


### Bug Fixes

* **hangar-import:** import ships always into the hangar not the wishlist 9806162
* **hangar-sync:** ignore ingame bought ships df112b4

### [5.31.75](///compare/v5.31.74...v5.31.75) (2025-11-26)


### Bug Fixes

* **compare:** use bigger fleetchart images to prevent scaling issue b546c79
* **sale-notifications:** respect user settings to suppress notifications 95ac6de

### [5.31.74](///compare/v5.31.73...v5.31.74) (2025-11-14)

### [5.31.73](///compare/v5.31.72...v5.31.73) (2025-11-12)

### [5.31.72](///compare/v5.31.71...v5.31.72) (2025-11-12)


### Bug Fixes

* **paints-importer:** update mapping for current event paints cfb18ed

### [5.31.71](///compare/v5.31.70...v5.31.71) (2025-10-29)

### [5.31.70](///compare/v5.31.69...v5.31.70) (2025-10-29)

### [5.31.69](///compare/v5.31.68...v5.31.69) (2025-10-29)

### [5.31.68](///compare/v5.31.67...v5.31.68) (2025-10-29)

### [5.31.67](///compare/v5.31.66...v5.31.67) (2025-10-29)

### [5.31.66](///compare/v5.31.65...v5.31.66) (2025-09-30)


### Bug Fixes

* **paints-import:** update mapping for apollo 615b39a

### [5.31.65](///compare/v5.31.64...v5.31.65) (2025-09-10)


### Bug Fixes

* **fleet-embed:** add missing loaner filter 1f025c3

### [5.31.64](///compare/v5.31.63...v5.31.64) (2025-08-17)


### Bug Fixes

* **paints:** update importer mapping for the L-21 Wolf 3305599

### [5.31.63](///compare/v5.31.62...v5.31.63) (2025-07-27)


### Bug Fixes

* **hardpoint:** update erkul/spviewer buttons 8929b87

### [5.31.62](///compare/v5.31.61...v5.31.62) (2025-05-25)

### [5.31.61](///compare/v5.31.60...v5.31.61) (2025-05-25)

### [5.31.60](///compare/v5.31.59...v5.31.60) (2025-05-25)


### Bug Fixes

* **hangar-sync:** update mapping for best in show ships 6f5a253

### [5.31.59](///compare/v5.31.58...v5.31.59) (2025-05-22)

### [5.31.58](///compare/v5.31.57...v5.31.58) (2025-05-21)

### [5.31.57](///compare/v5.31.56...v5.31.57) (2025-05-15)


### Bug Fixes

* **loaners:** update mapping 0eb4e03

### [5.31.56](///compare/v5.31.55...v5.31.56) (2025-05-15)


### Bug Fixes

* **paints:** add mapping for idris 1d370c2

### [5.31.55](///compare/v5.31.54...v5.31.55) (2025-05-10)


### Bug Fixes

* **rsi-loader:** update price extraction for updated pledge store 36a2108
* **rsi-loader:** update prices via new graphql api 8b93f84

### [5.31.54](///compare/v5.31.53...v5.31.54) (2025-02-19)


### Bug Fixes

* **sync:** update Reclaimer BIS mapping 1f54523

### [5.31.53](///compare/v5.31.52...v5.31.53) (2025-02-14)


### Bug Fixes

* **sync:** check extension on modal open call 8482a45

### [5.31.52](///compare/v5.31.51...v5.31.52) (2024-12-22)

### [5.31.51](///compare/v5.31.50...v5.31.51) (2024-12-22)

### [5.31.50](///compare/v5.31.49...v5.31.50) (2024-12-15)


### Bug Fixes

* **paints-importer:** update mapping for new merlin and archimedes paints d42c22d

### [5.31.49](///compare/v5.31.48...v5.31.49) (2024-12-04)


### Bug Fixes

* **paints:** update mapping 5ff84a2

### [5.31.48](///compare/v5.31.47...v5.31.48) (2024-12-02)


### Bug Fixes

* **loaders:** update loaner and paints mapping for new IAE ships 64a6fdf

### [5.31.47](///compare/v5.31.46...v5.31.47) (2024-11-29)


### Bug Fixes

* **sync:** check paints after models b96efdc

### [5.31.46](///compare/v5.31.45...v5.31.46) (2024-11-28)

### [5.31.45](https://github.com/fleetyards/fleetyards/compare/v5.31.44...v5.31.45) (2024-11-04)


### Bug Fixes

* **loaners:** show loaners correctly if multiple loaners of the same are present ([9fa868d](https://github.com/fleetyards/fleetyards/commit/9fa868deae1a7fa92d3ba796af75e9838edbba26))

### [5.31.44](https://github.com/fleetyards/fleetyards/compare/v5.31.43...v5.31.44) (2024-11-03)

### [5.31.43](https://github.com/fleetyards/fleetyards/compare/v5.31.42...v5.31.43) (2024-11-03)


### Bug Fixes

* **loaners:** update script to create loaners ([632f975](https://github.com/fleetyards/fleetyards/commit/632f9757a7c59285cc2009d675a08ac32f774484))

### [5.31.42](https://github.com/fleetyards/fleetyards/compare/v5.31.41...v5.31.42) (2024-11-03)


### Bug Fixes

* **loaners:** remove typo ([fb3f168](https://github.com/fleetyards/fleetyards/commit/fb3f168c5eeeb609291c1058dc001d8d860a18bb))

### [5.31.41](https://github.com/fleetyards/fleetyards/compare/v5.31.40...v5.31.41) (2024-11-03)


### Bug Fixes

* **loaners:** unhide loaners if no visible is left ([64b8159](https://github.com/fleetyards/fleetyards/commit/64b81594e093ce806fdc70dd2a9fb7fa3cc52cf5))

### [5.31.40](https://github.com/fleetyards/fleetyards/compare/v5.31.39...v5.31.40) (2024-10-24)


### Bug Fixes

* **sync:** add additional mapping for A.T.L.S. ([4e41ca3](https://github.com/fleetyards/fleetyards/commit/4e41ca304e5cd1a5c69d567ea105b2c43b5327d7))

### [5.31.39](https://github.com/fleetyards/fleetyards/compare/v5.31.38...v5.31.39) (2024-10-20)


### Bug Fixes

* **paints:** update importer mapping for Starlancer, Zeus Mk II and CSV ([22ad7cf](https://github.com/fleetyards/fleetyards/commit/22ad7cf58500bc3f79f12f9da6d9b9d1a68fcaa5))

### [5.31.38](https://github.com/fleetyards/fleetyards/compare/v5.31.37...v5.31.38) (2024-10-14)

### [5.31.37](https://github.com/fleetyards/fleetyards/compare/v5.31.36...v5.31.37) (2024-10-14)

### [5.31.36](https://github.com/fleetyards/fleetyards/compare/v5.31.35...v5.31.36) (2024-09-28)


### Bug Fixes

* **sync:** add ATLS to mapping ([61823f9](https://github.com/fleetyards/fleetyards/commit/61823f994a38fc1314f5425822a8bf09e186ceea))

### [5.31.35](https://github.com/fleetyards/fleetyards/compare/v5.31.34...v5.31.35) (2024-09-03)


### Bug Fixes

* **mails:** update mailgun password ([ba1257d](https://github.com/fleetyards/fleetyards/commit/ba1257da576b269d887e94d93fe472b6d9274d8e))

### [5.31.34](https://github.com/fleetyards/fleetyards/compare/v5.31.33...v5.31.34) (2024-09-03)

### [5.31.33](https://github.com/fleetyards/fleetyards/compare/v5.31.32...v5.31.33) (2024-05-26)


### Bug Fixes

* **sync:** resolve issue with custom names ([1241102](https://github.com/fleetyards/fleetyards/commit/12411020c8e68b9035f79437eae3787aeb413cc1))

### [5.31.32](https://github.com/fleetyards/fleetyards/compare/v5.31.31...v5.31.32) (2024-05-26)

### [5.31.31](https://github.com/fleetyards/fleetyards/compare/v5.31.30...v5.31.31) (2024-05-25)

### [5.31.30](https://github.com/fleetyards/fleetyards/compare/v5.31.29...v5.31.30) (2024-05-25)

### [5.31.29](https://github.com/fleetyards/fleetyards/compare/v5.31.28...v5.31.29) (2024-05-24)


### Bug Fixes

* **sync:** add mapping for F7A Mk I ([81887a4](https://github.com/fleetyards/fleetyards/commit/81887a48728d28502cf16298890958b562c90dde))

### [5.31.28](https://github.com/fleetyards/fleetyards/compare/v5.31.27...v5.31.28) (2024-05-24)


### Bug Fixes

* **sync:** replace missleading - char to solve import issues for the Tali ([5a828c6](https://github.com/fleetyards/fleetyards/commit/5a828c6904ecb6f4f09e675dfd2a17f5206785a4))

### [5.31.27](https://github.com/fleetyards/fleetyards/compare/v5.31.26...v5.31.27) (2024-05-23)


### Bug Fixes

* **sync:** further update tali mapping ([728b9d4](https://github.com/fleetyards/fleetyards/commit/728b9d46db0c48bc765cdf9244706fd93af2e2dd))

### [5.31.26](https://github.com/fleetyards/fleetyards/compare/v5.31.25...v5.31.26) (2024-05-22)


### Bug Fixes

* **sync:** update mapping for idris k kit ([22e09b6](https://github.com/fleetyards/fleetyards/commit/22e09b641c27a43da96da54b19ab89213f2efcc1))

### [5.31.25](https://github.com/fleetyards/fleetyards/compare/v5.31.24...v5.31.25) (2024-05-21)


### Bug Fixes

* **sync:** add additional mapping to solve issues for Tali Modules ([fc9762a](https://github.com/fleetyards/fleetyards/commit/fc9762a4a6da2202bd707837ce5b2914c5c12346))

### [5.31.24](https://github.com/fleetyards/fleetyards/compare/v5.31.23...v5.31.24) (2024-05-21)


### Bug Fixes

* **sync:** add mapping for tali modules ([b9c77df](https://github.com/fleetyards/fleetyards/commit/b9c77df78db508b4dc42f98c0ffea15e52a43c42))

### [5.31.23](https://github.com/fleetyards/fleetyards/compare/v5.31.22...v5.31.23) (2024-05-19)

### [5.31.22](https://github.com/fleetyards/fleetyards/compare/v5.31.21...v5.31.22) (2024-05-19)


### Bug Fixes

* **sync:** update mapping for modules and upgrades ([afda651](https://github.com/fleetyards/fleetyards/commit/afda651ecca5893a13ffc52cb6650775c44c11bb))
* **sync:** update mapping for new Retaliator Modules ([f4cd6ec](https://github.com/fleetyards/fleetyards/commit/f4cd6ec4b51c6a481658f0b9c93803025c66f5ec))

### [5.31.21](https://github.com/fleetyards/fleetyards/compare/v5.31.20...v5.31.21) (2024-05-18)

### [5.31.20](https://github.com/fleetyards/fleetyards/compare/v5.31.19...v5.31.20) (2024-05-18)

### [5.31.19](https://github.com/fleetyards/fleetyards/compare/v5.31.18...v5.31.19) (2024-05-18)

### [5.31.18](https://github.com/fleetyards/fleetyards/compare/v5.31.17...v5.31.18) (2024-05-18)

### [5.31.17](https://github.com/fleetyards/fleetyards/compare/v5.31.16...v5.31.17) (2024-05-18)

### [5.31.16](https://github.com/fleetyards/fleetyards/compare/v5.31.15...v5.31.16) (2024-05-18)


### Bug Fixes

* **sync:** update mapping for hornet heartseeker ([85129f1](https://github.com/fleetyards/fleetyards/commit/85129f115040612807868efa1067fc240b28b6a0))

### [5.31.15](https://github.com/fleetyards/fleetyards/compare/v5.31.14...v5.31.15) (2024-05-17)

### [5.31.14](https://github.com/fleetyards/fleetyards/compare/v5.31.13...v5.31.14) (2024-05-17)

### [5.31.13](https://github.com/fleetyards/fleetyards/compare/v5.31.12...v5.31.13) (2024-05-17)

### [5.31.12](https://github.com/fleetyards/fleetyards/compare/v5.31.11...v5.31.12) (2024-05-17)

### [5.31.11](https://github.com/fleetyards/fleetyards/compare/v5.31.10...v5.31.11) (2024-05-17)

### [5.31.10](https://github.com/fleetyards/fleetyards/compare/v5.31.9...v5.31.10) (2024-05-17)

### [5.31.9](https://github.com/fleetyards/fleetyards/compare/v5.31.8...v5.31.9) (2024-05-17)

### [5.31.8](https://github.com/fleetyards/fleetyards/compare/v5.31.7...v5.31.8) (2024-05-16)

### [5.31.7](https://github.com/fleetyards/fleetyards/compare/v5.31.6...v5.31.7) (2024-05-16)

### [5.31.6](https://github.com/fleetyards/fleetyards/compare/v5.31.5...v5.31.6) (2024-05-16)

### [5.31.5](https://github.com/fleetyards/fleetyards/compare/v5.31.4...v5.31.5) (2024-05-16)

### [5.31.4](https://github.com/fleetyards/fleetyards/compare/v5.31.3...v5.31.4) (2024-05-15)

### [5.31.3](https://github.com/fleetyards/fleetyards/compare/v5.31.2...v5.31.3) (2024-05-14)


### Bug Fixes

* **hangar-sync:** update hornet mk i mapping ([13b5668](https://github.com/fleetyards/fleetyards/commit/13b5668f973e8977274bd6669c24962d476f7067))

### [5.31.2](https://github.com/fleetyards/fleetyards/compare/v5.31.1...v5.31.2) (2024-03-24)

### [5.31.1](https://github.com/fleetyards/fleetyards/compare/v5.31.0...v5.31.1) (2024-03-22)

## [5.31.0](https://github.com/fleetyards/fleetyards/compare/v5.30.4...v5.31.0) (2024-03-22)


### Features

* **fleet:** add public stats endpoints ([96a5c3a](https://github.com/fleetyards/fleetyards/commit/96a5c3a58eca6691a43b7e4f1fdaa31d58bf4965))
* **fleets:** add option for public stats to settings ([3bc5192](https://github.com/fleetyards/fleetyards/commit/3bc5192052bc97b2c061f8c21c385402f0b1e649))

### [5.30.4](https://github.com/fleetyards/fleetyards/compare/v5.30.3...v5.30.4) (2024-03-18)

### [5.30.3](https://github.com/fleetyards/fleetyards/compare/v5.30.2...v5.30.3) (2024-03-17)

### [5.30.2](https://github.com/fleetyards/fleetyards/compare/v5.30.1...v5.30.2) (2024-03-17)


### Bug Fixes

* **paints-importer:** update hornet mapping ([1c535f8](https://github.com/fleetyards/fleetyards/commit/1c535f84d33c754178fe78f21c3bad15316720e2))

### [5.30.1](https://github.com/fleetyards/fleetyards/compare/v5.30.0...v5.30.1) (2024-03-17)

## [5.30.0](https://github.com/fleetyards/fleetyards/compare/v5.29.3...v5.30.0) (2024-03-17)


### Features

* **scdata:** bump sc version to 3.22.1 ([f066b16](https://github.com/fleetyards/fleetyards/commit/f066b16adebec3a05c23f09c4e2284af914efed9))

### [5.29.3](https://github.com/fleetyards/fleetyards/compare/v5.29.2...v5.29.3) (2024-02-26)


### Bug Fixes

* **loaners:** update mapping for new loaner list changes ([ac0e9a0](https://github.com/fleetyards/fleetyards/commit/ac0e9a02dd9c40fb12c6bb2eab5f50f32f7e407e))

### [5.29.2](https://github.com/fleetyards/fleetyards/compare/v5.29.1...v5.29.2) (2024-02-13)

### [5.29.1](https://github.com/fleetyards/fleetyards/compare/v5.29.0...v5.29.1) (2024-02-11)

## [5.29.0](https://github.com/fleetyards/fleetyards/compare/v5.28.1...v5.29.0) (2023-12-12)


### Features

* **fleets:** add rsi handle to fleet vehicles export ([8a58bd7](https://github.com/fleetyards/fleetyards/commit/8a58bd7c3f542ab0b6a937f560829b4fa197586e))

### [5.28.1](https://github.com/fleetyards/fleetyards/compare/v5.28.0...v5.28.1) (2023-12-12)

## [5.28.0](https://github.com/fleetyards/fleetyards/compare/v5.27.44...v5.28.0) (2023-12-12)


### Features

* **fleets:** add username to fleet vehicles export ([22f08cb](https://github.com/fleetyards/fleetyards/commit/22f08cba73290686bc66acd87bb99ef0736a920c))

### [5.27.44](https://github.com/fleetyards/fleetyards/compare/v5.27.43...v5.27.44) (2023-12-01)


### Bug Fixes

* sync and importer workers to fix RSI Naming convention changes ([b7d91f3](https://github.com/fleetyards/fleetyards/commit/b7d91f325643f667a0e23f9072a2d4e4210b14cf))

### [5.27.43](https://github.com/fleetyards/fleetyards/compare/v5.27.42...v5.27.43) (2023-11-30)

### [5.27.42](https://github.com/fleetyards/fleetyards/compare/v5.27.41...v5.27.42) (2023-11-30)

### [5.27.41](https://github.com/fleetyards/fleetyards/compare/v5.27.40...v5.27.41) (2023-11-26)


### Bug Fixes

* update profile/account ([2e14ea6](https://github.com/fleetyards/fleetyards/commit/2e14ea676b86cbcd0023b5e268d3ac5c0614cd65))

### [5.27.40](https://github.com/fleetyards/fleetyards/compare/v5.27.39...v5.27.40) (2023-11-22)

### [5.27.39](https://github.com/fleetyards/fleetyards/compare/v5.27.38...v5.27.39) (2023-11-19)

### [5.27.38](https://github.com/fleetyards/fleetyards/compare/v5.27.37...v5.27.38) (2023-11-19)

### [5.27.37](https://github.com/fleetyards/fleetyards/compare/v5.27.36...v5.27.37) (2023-11-19)

### [5.27.36](https://github.com/fleetyards/fleetyards/compare/v5.27.35...v5.27.36) (2023-11-19)

### [5.27.35](https://github.com/fleetyards/fleetyards/compare/v5.27.34...v5.27.35) (2023-11-19)

### [5.27.34](https://github.com/fleetyards/fleetyards/compare/v5.27.33...v5.27.34) (2023-11-19)

### [5.27.33](https://github.com/fleetyards/fleetyards/compare/v5.27.32...v5.27.33) (2023-11-19)

### [5.27.32](https://github.com/fleetyards/fleetyards/compare/v5.27.31...v5.27.32) (2023-11-18)

### [5.27.31](https://github.com/fleetyards/fleetyards/compare/v5.27.30...v5.27.31) (2023-11-18)

### [5.27.30](https://github.com/fleetyards/fleetyards/compare/v5.27.29...v5.27.30) (2023-11-18)

### [5.27.29](https://github.com/fleetyards/fleetyards/compare/v5.27.28...v5.27.29) (2023-11-17)


### Bug Fixes

* **images:** fallback to direct cdn host ([096983b](https://github.com/fleetyards/fleetyards/commit/096983be712ae917277aeb06cb41e86a6512dc9b))

### [5.27.28](https://github.com/fleetyards/fleetyards/compare/v5.27.27...v5.27.28) (2023-11-17)

### [5.27.27](https://github.com/fleetyards/fleetyards/compare/v5.27.26...v5.27.27) (2023-11-17)

### [5.27.26](https://github.com/fleetyards/fleetyards/compare/v5.27.25...v5.27.26) (2023-11-17)

### [5.27.25](https://github.com/fleetyards/fleetyards/compare/v5.27.24...v5.27.25) (2023-11-17)

### [5.27.24](https://github.com/fleetyards/fleetyards/compare/v5.27.23...v5.27.24) (2023-11-12)

### [5.27.23](https://github.com/fleetyards/fleetyards/compare/v5.27.22...v5.27.23) (2023-11-10)

### [5.27.22](https://github.com/fleetyards/fleetyards/compare/v5.27.21...v5.27.22) (2023-11-07)


### Bug Fixes

* **compare:** update fleetchart image sizes ([825db43](https://github.com/fleetyards/fleetyards/commit/825db43b20b70c0a9659fc2eb8674dbdec8aefbb))

### [5.27.21](https://github.com/fleetyards/fleetyards/compare/v5.27.20...v5.27.21) (2023-10-30)

### [5.27.20](https://github.com/fleetyards/fleetyards/compare/v5.27.19...v5.27.20) (2023-10-30)

### [5.27.19](https://github.com/fleetyards/fleetyards/compare/v5.27.18...v5.27.19) (2023-10-30)

### [5.27.18](https://github.com/fleetyards/fleetyards/compare/v5.27.17...v5.27.18) (2023-10-29)

### [5.27.17](https://github.com/fleetyards/fleetyards/compare/v5.27.16...v5.27.17) (2023-10-29)


### Bug Fixes

* **password-reset:** dont display error message when mail was not found ([a446856](https://github.com/fleetyards/fleetyards/commit/a446856203b028f273147a6e305dac0742f1d5e0))

### [5.27.16](https://github.com/fleetyards/fleetyards/compare/v5.27.15...v5.27.16) (2023-10-25)


### Bug Fixes

* sc version in footer ([adcb221](https://github.com/fleetyards/fleetyards/commit/adcb221bed06463517c166963aa4695442c8c39c))

### [5.27.15](https://github.com/fleetyards/fleetyards/compare/v5.27.14...v5.27.15) (2023-10-23)

### [5.27.14](https://github.com/fleetyards/fleetyards/compare/v5.27.13...v5.27.14) (2023-10-23)


### Bug Fixes

* always show pride logo on start page ([bc4502f](https://github.com/fleetyards/fleetyards/commit/bc4502ff5aee0cfc4014c12a57406c82598c8a40))

### [5.27.13](https://github.com/fleetyards/fleetyards/compare/v5.27.12...v5.27.13) (2023-10-14)

### [5.27.12](https://github.com/fleetyards/fleetyards/compare/v5.27.11...v5.27.12) (2023-10-14)

### [5.27.11](https://github.com/fleetyards/fleetyards/compare/v5.27.10...v5.27.11) (2023-10-11)


### Bug Fixes

* **models:** make sure to include the base model in variants ([e585fc3](https://github.com/fleetyards/fleetyards/commit/e585fc377fc7adaacdfc471153ae61bcf738c741))

### [5.27.10](https://github.com/fleetyards/fleetyards/compare/v5.27.9...v5.27.10) (2023-10-11)

### [5.27.9](https://github.com/fleetyards/fleetyards/compare/v5.27.8...v5.27.9) (2023-10-11)


### Bug Fixes

* **model:** use base model if present instead of rsi_chassis_id for variants lookup ([638b948](https://github.com/fleetyards/fleetyards/commit/638b94848f2252885e5f241143c72af4704d471a))

### [5.27.8](https://github.com/fleetyards/fleetyards/compare/v5.27.7...v5.27.8) (2023-10-10)

### [5.27.7](https://github.com/fleetyards/fleetyards/compare/v5.27.6...v5.27.7) (2023-10-09)


### Bug Fixes

* **search:** add panels for Station and Shop Result Type ([9e9fc57](https://github.com/fleetyards/fleetyards/commit/9e9fc574236de2a341a3b458dc2aaaa20e1bcebb))

### [5.27.6](https://github.com/fleetyards/fleetyards/compare/v5.27.5...v5.27.6) (2023-10-09)


### Bug Fixes

* **search:** update result panels to display correct information ([025ea46](https://github.com/fleetyards/fleetyards/commit/025ea461857e0c4243907854fe2d263a8983d768))

### [5.27.5](https://github.com/fleetyards/fleetyards/compare/v5.27.4...v5.27.5) (2023-10-09)

### [5.27.4](https://github.com/fleetyards/fleetyards/compare/v5.27.3...v5.27.4) (2023-10-04)

### [5.27.3](https://github.com/fleetyards/fleetyards/compare/v5.27.2...v5.27.3) (2023-09-22)


### Bug Fixes

* **fleets:** resolve issue preventing members from accepting membership requests and invites ([578ab5d](https://github.com/fleetyards/fleetyards/commit/578ab5d5940ce22183b8bfa6ae93aff9863e4636))

### [5.27.2](https://github.com/fleetyards/fleetyards/compare/v5.27.1...v5.27.2) (2023-09-22)


### Bug Fixes

* **model:** update pledge price on detail page ([8e20f94](https://github.com/fleetyards/fleetyards/commit/8e20f94b501f8eac82d875b4a026f3bf85c6e8b1))

### [5.27.1](https://github.com/fleetyards/fleetyards/compare/v5.27.0...v5.27.1) (2023-09-21)


### Bug Fixes

* **fleet-invites:** update endpoint to check fleet invite urls ([18281f1](https://github.com/fleetyards/fleetyards/commit/18281f152396bfbac8ea29f343a1789e7197a535))

## [5.27.0](https://github.com/fleetyards/fleetyards/compare/v5.26.12...v5.27.0) (2023-09-21)


### Features

* **api-schema:** add commodities filters endpoints ([89aff10](https://github.com/fleetyards/fleetyards/commit/89aff107ff4a3f485c66914dd04794ea40633d8a))
* **api-schema:** add commodity-prices endpoints ([8627836](https://github.com/fleetyards/fleetyards/commit/86278368e98b3915fc20374fd994009729dd9beb))
* **api-schema:** add components endpoints ([0fffdc5](https://github.com/fleetyards/fleetyards/commit/0fffdc57aaa8669338b1407d3a2a573ee2766bc3))
* **api-schema:** add current user endpoint ([e0600f8](https://github.com/fleetyards/fleetyards/commit/e0600f8191820ae07eaa97efd33178e73d880b30))
* **api-schema:** add equipment endpoints ([26f638f](https://github.com/fleetyards/fleetyards/commit/26f638f6b96bb3f88813e51d414ab962f5d4c3e5))
* **api-schema:** add feature endpoints ([93745fc](https://github.com/fleetyards/fleetyards/commit/93745fc90dcd0bf2e7300e12f0780a2786235c55))
* **api-schema:** add fleet invite-urls endpoints ([e292fba](https://github.com/fleetyards/fleetyards/commit/e292fbaa0986c2b277c88e969ed06a1e9c2074b3))
* **api-schema:** add fleet members/membership endpoints ([c840e91](https://github.com/fleetyards/fleetyards/commit/c840e916f47afa2ae9bc783fed7aa4f281ee906d))
* **api-schema:** add fleet vehicle and stats endpoints ([aa931ed](https://github.com/fleetyards/fleetyards/commit/aa931ed4b91b614c6e01aa62efc314a05d446555))
* **api-schema:** add fleets endpoints to schema ([08a3be0](https://github.com/fleetyards/fleetyards/commit/08a3be04809a9a4b16b47709895f4df4324eee8f))
* **api-schema:** add password endpoints ([86f1982](https://github.com/fleetyards/fleetyards/commit/86f1982f2619864b2cd61898bc71aa5066a36ec7))
* **api-schema:** add roadmap endpoints ([b652741](https://github.com/fleetyards/fleetyards/commit/b652741cb3c43be24130ffbfb73ad6c36ae815a0))
* **api-schema:** add search endpoints ([6a90977](https://github.com/fleetyards/fleetyards/commit/6a9097785183d96444302082790257f467a46242))
* **api-schema:** add session endpoints ([392ac3d](https://github.com/fleetyards/fleetyards/commit/392ac3da345cdaa194a1c1c479df206a9489d297))
* **api-schema:** add shop commodity endpoints ([74606a9](https://github.com/fleetyards/fleetyards/commit/74606a97d3244921548211860a834cff9877ade2))
* **api-schema:** add trade-routes endpoints ([25591e6](https://github.com/fleetyards/fleetyards/commit/25591e666b357de442998d20b9314982eca3afaf))
* **api-schema:** add version endpoints ([629774c](https://github.com/fleetyards/fleetyards/commit/629774c6d6d4877e4ea79cc858c379f430225b25))

### [5.26.12](https://github.com/fleetyards/fleetyards/compare/v5.26.11...v5.26.12) (2023-08-14)

### Bug Fixes

* **login:** use correct params format to resolve issue with 2FA ([2bea396](https://github.com/fleetyards/fleetyards/commit/2bea3967d11af0851a0ef4f415bf35a190c07543))

### [5.26.9](https://github.com/fleetyards/fleetyards/compare/v5.26.8...v5.26.9) (2023-08-13)

### Bug Fixes

* **compare:** update speed section to format speed values correctly ([f2a8d8d](https://github.com/fleetyards/fleetyards/commit/f2a8d8dc9b7b795f18c1ff4809fed7ee46d4ba4b))

### [5.26.7](https://github.com/fleetyards/fleetyards/compare/v5.26.6...v5.26.7) (2023-08-13)


### Bug Fixes

* preview pages redirect for fleet and hangar ([6c99390](https://github.com/fleetyards/fleetyards/commit/6c99390853d08be3fd036a4108bc1574490a0bbc))

### [5.26.6](https://github.com/fleetyards/fleetyards/compare/v5.26.5...v5.26.6) (2023-08-13)


### Bug Fixes

* **compare:** switch collapse component to resolve sticky issues ([3ec829d](https://github.com/fleetyards/fleetyards/commit/3ec829de48959800e4914f4a91ef55710f28593c))

### [5.26.5](https://github.com/fleetyards/fleetyards/compare/v5.26.4...v5.26.5) (2023-07-07)


### Bug Fixes

* **fleet-members:** update actions to allow officers to accept/decline new members ([239cef9](https://github.com/fleetyards/fleetyards/commit/239cef9481a095bc4022515b8a010144fc4da204))

### [5.26.4](https://github.com/fleetyards/fleetyards/compare/v5.26.3...v5.26.4) (2023-07-05)

### [5.26.3](https://github.com/fleetyards/fleetyards/compare/v5.26.2...v5.26.3) (2023-07-05)

### [5.26.2](https://github.com/fleetyards/fleetyards/compare/v5.26.1...v5.26.2) (2023-07-03)

### [5.26.1](https://github.com/fleetyards/fleetyards/compare/v5.26.0...v5.26.1) (2023-07-03)


### Bug Fixes

* **loaners:** match G12 Variants to all G12 vehicles ([ea0b2b3](https://github.com/fleetyards/fleetyards/commit/ea0b2b30c8fe01b40a9e2718eeafad4d9532f3a4))

## [5.26.0](https://github.com/fleetyards/fleetyards/compare/v5.25.3...v5.26.0) (2023-06-29)


### Features

* **fleetchart:** show pagination in fleetchart ([517baff](https://github.com/fleetyards/fleetyards/commit/517baff738202584cca72705fdbfca5a36303667))

### [5.25.3](https://github.com/fleetyards/fleetyards/compare/v5.25.2...v5.25.3) (2023-06-27)


### Bug Fixes

* **validations:** allow @ in urls ([7acd6aa](https://github.com/fleetyards/fleetyards/commit/7acd6aaa02416ab6cbae65e9f88f6c2e1e786158))

### [5.25.2](https://github.com/fleetyards/fleetyards/compare/v5.25.1...v5.25.2) (2023-06-23)


### Bug Fixes

* **loaner:** don't count loaners into pledge total ([6b5fcab](https://github.com/fleetyards/fleetyards/commit/6b5fcab8167dd9f3f1d2281ddbdf38d777f58292))

### [5.25.1](https://github.com/fleetyards/fleetyards/compare/v5.25.0...v5.25.1) (2023-06-22)


### Bug Fixes

* **vehicle-owner:** update owner modal ([342fd5b](https://github.com/fleetyards/fleetyards/commit/342fd5b5a2f0da5016f2e251e8f564959688141b))

## [5.25.0](https://github.com/fleetyards/fleetyards/compare/v5.24.0...v5.25.0) (2023-06-21)


### Features

* **paints:** rework paint select ([2d7fdb1](https://github.com/fleetyards/fleetyards/commit/2d7fdb15c1e70a8d22d1369a99fc94b8c30dfdcf))


### Bug Fixes

* **compare:** update speed values ([0409c6b](https://github.com/fleetyards/fleetyards/commit/0409c6b9d60c1aae75efaf3a268ea84f4663ba4c))
* **owner-modal:** load owners of loaners ([4a6d8bc](https://github.com/fleetyards/fleetyards/commit/4a6d8bcd9d8f1e0543ba79e165d055ab539247f2))

## [5.24.0](https://github.com/fleetyards/fleetyards/compare/v5.23.3...v5.24.0) (2023-05-31)


### Features

* **compare:** add link to main navigation ([882c86f](https://github.com/fleetyards/fleetyards/commit/882c86f72e7370e660865d6a843e8356424d341d))
* **sync:** improve visibility of sync extension ([68492c6](https://github.com/fleetyards/fleetyards/commit/68492c657a10b51e53bed1fda373d8c4f6edb70e))


### Bug Fixes

* **icons:** update csp url ([fc5e634](https://github.com/fleetyards/fleetyards/commit/fc5e6342d7915bf33297d1b921162f829f091351))
* **loaner:** update ursa mapping ([43919b8](https://github.com/fleetyards/fleetyards/commit/43919b8064b2952a9b195f7f892eaf07b71b2cd1))

### [5.23.3](https://github.com/fleetyards/fleetyards/compare/v5.23.2...v5.23.3) (2023-05-28)


### Bug Fixes

* **speeds:** update ground vehicle flag ([a838d62](https://github.com/fleetyards/fleetyards/commit/a838d627c293dcf8465a7a75d6421bd70ee0840b))

### [5.23.2](https://github.com/fleetyards/fleetyards/compare/v5.23.1...v5.23.2) (2023-05-27)


### Bug Fixes

* **speeds:** missing translations ([e854041](https://github.com/fleetyards/fleetyards/commit/e85404156478cf1e89880dda5e5f96ea7ab2c425))

### [5.23.1](https://github.com/fleetyards/fleetyards/compare/v5.23.0...v5.23.1) (2023-05-27)

## [5.23.0](https://github.com/fleetyards/fleetyards/compare/v5.22.5...v5.23.0) (2023-05-27)


### Features

* **speeds:** update models to include speeds from gamefiles ([#2612](https://github.com/fleetyards/fleetyards/issues/2612)) ([b08f6fe](https://github.com/fleetyards/fleetyards/commit/b08f6fe729b48cc28c4d07b67a2b4fdb46cd3a25))


### Bug Fixes

* **hangar-sync:** reset pledge_id for wanted ships ([14596ff](https://github.com/fleetyards/fleetyards/commit/14596ffc67f1128ed6e3b1adbe692849f21d1a12))

### [5.22.5](https://github.com/fleetyards/fleetyards/compare/v5.22.4...v5.22.5) (2023-05-25)

### [5.22.4](https://github.com/fleetyards/fleetyards/compare/v5.22.3...v5.22.4) (2023-05-25)

### [5.22.3](https://github.com/fleetyards/fleetyards/compare/v5.22.2...v5.22.3) (2023-05-24)

### [5.22.2](https://github.com/fleetyards/fleetyards/compare/v5.22.1...v5.22.2) (2023-05-24)

### [5.22.1](https://github.com/fleetyards/fleetyards/compare/v5.22.0...v5.22.1) (2023-05-24)

## [5.22.0](https://github.com/fleetyards/fleetyards/compare/v5.21.3...v5.22.0) (2023-05-23)


### Features

* **fleetchart:** add toggle to choose colored or greyscale version ([878c1a3](https://github.com/fleetyards/fleetyards/commit/878c1a3e044cda2ba52140a458e825817627f2da))
* **model-views:** add colored views to models ([bc7b157](https://github.com/fleetyards/fleetyards/commit/bc7b157eb6dd41d9014788a3085502b8d6060cf8))


### Bug Fixes

* **loaners:** update cleanup script to use the right reference. ([4f6927b](https://github.com/fleetyards/fleetyards/commit/4f6927b6cbcc521bc5cbd7c2510f943cf7db7060))

### [5.21.3](https://github.com/fleetyards/fleetyards/compare/v5.21.2...v5.21.3) (2023-05-21)


### Bug Fixes

* **hangar-import:** update importer to better handle error cases ([e7740a4](https://github.com/fleetyards/fleetyards/commit/e7740a421566b00d9571aae7ecdb98c798d68e6a))
* **loaners:** update loaners cleanup after new import ([8ba63ea](https://github.com/fleetyards/fleetyards/commit/8ba63eab216e01c83ecdcd5c6c1cbaafabe3aeec))

### [5.21.2](https://github.com/fleetyards/fleetyards/compare/v5.21.1...v5.21.2) (2023-05-20)


### Bug Fixes

* **loaner:** update importer to correctly add loaners for wishlist and hangar ([de56bf2](https://github.com/fleetyards/fleetyards/commit/de56bf20cb105881426e7a1d98472c16e06715ef))

### [5.21.1](https://github.com/fleetyards/fleetyards/compare/v5.21.0...v5.21.1) (2023-05-19)


### Bug Fixes

* **translations:** add missing translation ([fefdae4](https://github.com/fleetyards/fleetyards/commit/fefdae425146389979e55cd6bf92db99031f79eb))

## [5.21.0](https://github.com/fleetyards/fleetyards/compare/v5.20.1...v5.21.0) (2023-05-16)


### Features

* **models:** update model detail views arrangement ([0ff2df2](https://github.com/fleetyards/fleetyards/commit/0ff2df25e4c080f7d69e4acea5890f423a01af83))

### [5.20.1](https://github.com/fleetyards/fleetyards/compare/v5.20.0...v5.20.1) (2023-05-16)

## [5.20.0](https://github.com/fleetyards/fleetyards/compare/v5.19.1...v5.20.0) (2023-05-16)


### Features

* **models:** update views section to include optional front view ([99df62c](https://github.com/fleetyards/fleetyards/commit/99df62cc214a7d8efe10903c07c0aef88eff0249))


### Bug Fixes

* **holoviewer:** update transparent mesh detection ([7ffc09b](https://github.com/fleetyards/fleetyards/commit/7ffc09b12606c3b34a625dc1c420ccc9e84fd3aa))

### [5.19.1](https://github.com/fleetyards/fleetyards/compare/v5.19.0...v5.19.1) (2023-05-15)

## [5.19.0](https://github.com/fleetyards/fleetyards/compare/v5.18.6...v5.19.0) (2023-05-15)


### Features

* **scdata:** add additional data from gamefiles ([8a7b6dc](https://github.com/fleetyards/fleetyards/commit/8a7b6dcdec4952057dfb81ae36bd6e081538ce6d))


### Bug Fixes

* **scdata:** resolve additional ship data ([f2ec810](https://github.com/fleetyards/fleetyards/commit/f2ec81067a3139905ed9fbda6f52bca757aef71f))

### [5.18.6](https://github.com/fleetyards/fleetyards/compare/v5.18.5...v5.18.6) (2023-05-15)


### Bug Fixes

* **scdata:** dont import hardpoints with invisible flags ([5ce15b9](https://github.com/fleetyards/fleetyards/commit/5ce15b9d9fc83bfd94ea33fe2d349a75bf7ade46))

### [5.18.5](https://github.com/fleetyards/fleetyards/compare/v5.18.4...v5.18.5) (2023-05-15)

### [5.18.4](https://github.com/fleetyards/fleetyards/compare/v5.18.3...v5.18.4) (2023-05-15)

### [5.18.3](https://github.com/fleetyards/fleetyards/compare/v5.18.2...v5.18.3) (2023-05-14)

### [5.18.2](https://github.com/fleetyards/fleetyards/compare/v5.18.1...v5.18.2) (2023-05-13)

### [5.18.1](https://github.com/fleetyards/fleetyards/compare/v5.18.0...v5.18.1) (2023-05-12)

## [5.18.0](https://github.com/fleetyards/fleetyards/compare/v5.17.4...v5.18.0) (2023-05-12)


### Features

* **model-detail:** add fleetchart views to detail page ([bee864e](https://github.com/fleetyards/fleetyards/commit/bee864e6e7e2e33d2b88269dc571f30af4619b14))


### Bug Fixes

* **hangar-sync:** sync custom names for ships ([f156fb4](https://github.com/fleetyards/fleetyards/commit/f156fb4001497e95e5582eadef23b9cee2a588cf))

### [5.17.4](https://github.com/fleetyards/fleetyards/compare/v5.17.3...v5.17.4) (2023-05-11)


### Bug Fixes

* **hangar-sync:** match additional ships and paints ([7c5b4a7](https://github.com/fleetyards/fleetyards/commit/7c5b4a7b524473e3556db68b0f326468290dfd1e))

### [5.17.3](https://github.com/fleetyards/fleetyards/compare/v5.17.2...v5.17.3) (2023-05-11)

### [5.17.2](https://github.com/fleetyards/fleetyards/compare/v5.17.1...v5.17.2) (2023-05-11)


### Bug Fixes

* **hangar-sync:** resolve issue when matching ships with custom paints ([95585b6](https://github.com/fleetyards/fleetyards/commit/95585b6734fca314e79daea7d2b9770252461ab4))

### [5.17.1](https://github.com/fleetyards/fleetyards/compare/v5.17.0...v5.17.1) (2023-05-10)


### Bug Fixes

* **hangar-sync:** components matching for endeavor and tali ([7e43271](https://github.com/fleetyards/fleetyards/commit/7e43271541c51b886bf4dabcde6effcb3eed67df))
* **hangar-sync:** match components and upgrades to correct models ([89c31ee](https://github.com/fleetyards/fleetyards/commit/89c31eecf132b45aecde6ccda00db908fa32e021))
* **hangar-sync:** update matching for ships with paints ([61b8834](https://github.com/fleetyards/fleetyards/commit/61b8834cfeec3c332f504e2bba14110e027605ba))

## [5.17.0](https://github.com/fleetyards/fleetyards/compare/v5.16.1...v5.17.0) (2023-05-10)


### Features

* **hangar-sync:** add output for components import ([c977937](https://github.com/fleetyards/fleetyards/commit/c977937a4a85ad26d88d76a76918d6ba196e9679))
* **hangar:** Integration with Fleetyards Sync Browser Extension ([#2594](https://github.com/fleetyards/fleetyards/issues/2594)) ([45a3081](https://github.com/fleetyards/fleetyards/commit/45a3081d4b9fd8aae9e155ee1d0094109c78cc20))


### Bug Fixes

* **hangar:** add missing translation ([0f27067](https://github.com/fleetyards/fleetyards/commit/0f270679c443af67b8c1c5ecf61dd61810d7987f))
* **holo:** update lightning intensity ([3e08027](https://github.com/fleetyards/fleetyards/commit/3e080278665445a95aeb2b85aa7c2ab580f959e8))

### [5.16.1](https://github.com/fleetyards/fleetyards/compare/v5.16.0...v5.16.1) (2023-04-26)


### Bug Fixes

* caching for new hide owner for fleets option ([1db4c86](https://github.com/fleetyards/fleetyards/commit/1db4c86da2b6c0843614fea94850c4d87009721c))

## [5.16.0](https://github.com/fleetyards/fleetyards/compare/v5.15.1...v5.16.0) (2023-04-25)


### Features

* **fleets:** hide fleet vehicle owners ([#2588](https://github.com/fleetyards/fleetyards/issues/2588)) ([f8956ad](https://github.com/fleetyards/fleetyards/commit/f8956adc3fa548e3d3b0addf393dff307e1a838e))


### Bug Fixes

* **hangar:** don't mark ships imported as wanted by default ([92e7777](https://github.com/fleetyards/fleetyards/commit/92e77775cd17975c23a8c89777dc6f1442d2c7d0)), closes [#2587](https://github.com/fleetyards/fleetyards/issues/2587)

### [5.15.1](https://github.com/fleetyards/fleetyards/compare/v5.15.0...v5.15.1) (2023-03-27)


### Bug Fixes

* **wishlist:** reload list on bulk actions ([d94dc48](https://github.com/fleetyards/fleetyards/commit/d94dc484e99e03d24773f0188814b6e558e843f3))

## [5.15.0](https://github.com/fleetyards/fleetyards/compare/v5.14.4...v5.15.0) (2023-03-27)


### Features

* **language-support:** add language select to footer ([09113d0](https://github.com/fleetyards/fleetyards/commit/09113d00e53a2003e8eec9500d570f7761c531e3))
* **purchased-ingame:** Allow Ships to be marked as purchased-ingame ([#2282](https://github.com/fleetyards/fleetyards/issues/2282)) ([4c3306b](https://github.com/fleetyards/fleetyards/commit/4c3306bcc184661cde04beea5cc77b3233a3a959))
* **vehicles:** add bought-via information ([#2563](https://github.com/fleetyards/fleetyards/issues/2563)) ([0efe318](https://github.com/fleetyards/fleetyards/commit/0efe3185d6549e05efea0b84bfbc573db864a28e))
* **vehicles:** add wipe actions for ingame bought vehicles ([#2565](https://github.com/fleetyards/fleetyards/issues/2565)) ([0fe13cb](https://github.com/fleetyards/fleetyards/commit/0fe13cb9473b166e100565cbb9ece918012d45a2))
* **wishlist:** use wishlist state for addToHangar status ([b34f82b](https://github.com/fleetyards/fleetyards/commit/b34f82b7574f8600e391a992a35b0e0795b81131))


### Bug Fixes

* load emp and qed data from gamefiles ([75006e3](https://github.com/fleetyards/fleetyards/commit/75006e3b33d08dea89c2c99c238de5455e973f11))

### [5.14.4](https://github.com/fleetyards/fleetyards/compare/v5.14.3...v5.14.4) (2023-02-22)

### [5.14.3](https://github.com/fleetyards/fleetyards/compare/v5.14.2...v5.14.3) (2023-02-09)

### [5.14.2](https://github.com/fleetyards/fleetyards/compare/v5.14.1...v5.14.2) (2023-01-26)

### [5.14.1](https://github.com/fleetyards/fleetyards/compare/v5.14.0...v5.14.1) (2023-01-26)


### Bug Fixes

* **2FA:** update user on enable 2FA page. ([396576d](https://github.com/fleetyards/fleetyards/commit/396576d3ea44c76a25d74c2834c8907add2dde69))
* **fleet:** run update fleet_vehicle callbacks after commit ([68d739c](https://github.com/fleetyards/fleetyards/commit/68d739cc079cf7a05fb8e7f2b1d86c4f76d6584c))
* **sidekiq:** Update Queues to conform with sidekiq 7 ([d6f9e6d](https://github.com/fleetyards/fleetyards/commit/d6f9e6d968e1a69381be211783d847cfd881814f))

## [5.14.0](https://github.com/fleetyards/fleetyards/compare/v5.13.6...v5.14.0) (2023-01-18)


### Features

* **Fleets:** Add Export for all Vehicles of Fleet ([#2516](https://github.com/fleetyards/fleetyards/issues/2516)) ([73407df](https://github.com/fleetyards/fleetyards/commit/73407dfc9ecfe897012cdf5a5dd4af7ff01cdc69))

### [5.13.6](https://github.com/fleetyards/fleetyards/compare/v5.13.5...v5.13.6) (2023-01-12)


### Bug Fixes

* **setup:** remove admin flag from create admin script ([10013f8](https://github.com/fleetyards/fleetyards/commit/10013f8eb3a810424b2edc8d4529f7835bc926e1))
* **setup:** update admin user setup script ([6091b6a](https://github.com/fleetyards/fleetyards/commit/6091b6ae48338cc016d4f0a428c2581d33a1ed44))

### [5.13.5](https://github.com/fleetyards/fleetyards/compare/v5.13.4...v5.13.5) (2023-01-11)


### Bug Fixes

* **docs:** update embed documentation to use embed-v2.js ([36bc68f](https://github.com/fleetyards/fleetyards/commit/36bc68f583296afb4ad23b823e1e5ff032e3d734))
* **fleet-vehicles:** reload membership before update ([94959fa](https://github.com/fleetyards/fleetyards/commit/94959fad2b56d396cbf69db408f41a6f36310950))

### [5.13.4](https://github.com/fleetyards/fleetyards/compare/v5.13.3...v5.13.4) (2022-12-25)


### Bug Fixes

* **fleet-vehicles:** update scheduling of fleet vehicle updates ([e0ec219](https://github.com/fleetyards/fleetyards/commit/e0ec219138a237fc0764997048f8799557a56a10))

### [5.13.3](https://github.com/fleetyards/fleetyards/compare/v5.13.2...v5.13.3) (2022-12-23)


### Bug Fixes

* **pagination:** readd missing pagination headers ([f49ba91](https://github.com/fleetyards/fleetyards/commit/f49ba91059ec4a58048659439cbda2607b3d8f79))

### [5.13.2](https://github.com/fleetyards/fleetyards/compare/v5.13.1...v5.13.2) (2022-12-06)


### Bug Fixes

* **2FA:** allow usage of backup codes to disable 2FA ([404fb0c](https://github.com/fleetyards/fleetyards/commit/404fb0c615f18972af633955dbb05dc708573aa3))

### [5.13.1](https://github.com/fleetyards/fleetyards/compare/v5.13.0...v5.13.1) (2022-12-06)


### Bug Fixes

* **2fa:** resolve issue which prevented backup codes from working. ([dbd8824](https://github.com/fleetyards/fleetyards/commit/dbd88242f5dee4c4efdbd3b58b70973c72bfa46e))

## [5.13.0](https://github.com/fleetyards/fleetyards/compare/v5.12.6...v5.13.0) (2022-12-05)


### Features

* **fleet-stats:** add vehicles by model bar chart ([3627a0d](https://github.com/fleetyards/fleetyards/commit/3627a0d167ba0ef41b25b138fe970a61ae30202f))

### [5.12.6](https://github.com/fleetyards/fleetyards/compare/v5.12.5...v5.12.6) (2022-12-05)

### [5.12.5](https://github.com/fleetyards/fleetyards/compare/v5.12.4...v5.12.5) (2022-12-05)

### [5.12.4](https://github.com/fleetyards/fleetyards/compare/v5.12.3...v5.12.4) (2022-12-05)

### [5.12.3](https://github.com/fleetyards/fleetyards/compare/v5.12.2...v5.12.3) (2022-12-05)


### Bug Fixes

* **pagination:** exclude zero from per_page and also allow snakecase ([8c11f3a](https://github.com/fleetyards/fleetyards/commit/8c11f3a5a50f8d0eca59fe41a68e57fb42e8f05c))

### [5.12.2](https://github.com/fleetyards/fleetyards/compare/v5.12.1...v5.12.2) (2022-12-04)


### Bug Fixes

* **fleet-vehicles:** update scheduling to prevent double update jobs ([a3e2c76](https://github.com/fleetyards/fleetyards/commit/a3e2c7601ee91f6fbac2c1ebffb3e73e79e1ef35))

### [5.12.1](https://github.com/fleetyards/fleetyards/compare/v5.12.0...v5.12.1) (2022-12-04)


### Bug Fixes

* **link-header:** prevent empty header value and add self link ([5d41063](https://github.com/fleetyards/fleetyards/commit/5d41063e60a387a12fdc990e5b55f70aeb20ea20))

## [5.12.0](https://github.com/fleetyards/fleetyards/compare/v5.11.4...v5.12.0) (2022-12-03)


### Features

* **models:** add filters for beam and height ([0b1548c](https://github.com/fleetyards/fleetyards/commit/0b1548ce261962a3c27267c43fbc15839ba609d8))
* **stations:** add filter for refinery and cargo hub ([4705f0c](https://github.com/fleetyards/fleetyards/commit/4705f0c250feae4908d4c1050f7e6e8f4cdf4cbc))

### [5.11.4](https://github.com/fleetyards/fleetyards/compare/v5.11.3...v5.11.4) (2022-12-01)


### Bug Fixes

* **fleet-ships:** add missing membership update callback ([c845c37](https://github.com/fleetyards/fleetyards/commit/c845c37aba204cb8d8c299e898666e487fc09982))
* **fleet-ships:** reenable for_members filter ([f05364f](https://github.com/fleetyards/fleetyards/commit/f05364f44042f711eaf58a3a758c440210c031d8))

### [5.11.3](https://github.com/fleetyards/fleetyards/compare/v5.11.2...v5.11.3) (2022-11-30)


### Bug Fixes

* **fleet:** model_counts group call breaks with applied filters ([8c83dcd](https://github.com/fleetyards/fleetyards/commit/8c83dcd4c92da030080b7bfa19fda6199d4bf288))

### [5.11.2](https://github.com/fleetyards/fleetyards/compare/v5.11.1...v5.11.2) (2022-11-30)

### [5.11.1](https://github.com/fleetyards/fleetyards/compare/v5.11.0...v5.11.1) (2022-11-30)

## [5.11.0](https://github.com/fleetyards/fleetyards/compare/v5.10.13...v5.11.0) (2022-11-29)


### Features

* **compare:** add starship42 button to compare page ([d5d9a94](https://github.com/fleetyards/fleetyards/commit/d5d9a949d0f87bd7d7f910c30effa8c9fa86ee35))

### [5.10.13](https://github.com/fleetyards/fleetyards/compare/v5.10.12...v5.10.13) (2022-11-27)

### [5.10.12](https://github.com/fleetyards/fleetyards/compare/v5.10.11...v5.10.12) (2022-11-27)


### Bug Fixes

* **hangar-import:** handle no data present in import file ([b75234c](https://github.com/fleetyards/fleetyards/commit/b75234cd49e8fc73b543e500bf7804f3f7b08854))
* **models:** update will_it_fit filter to return scope if parent not found ([ad2cec0](https://github.com/fleetyards/fleetyards/commit/ad2cec0adb3757fc0c34a25c54c4dc583a14ab07))

### [5.10.11](https://github.com/fleetyards/fleetyards/compare/v5.10.10...v5.10.11) (2022-11-27)


### Bug Fixes

* **loaners:** only add loaners for purchased ships ([32159ab](https://github.com/fleetyards/fleetyards/commit/32159abb9eb219d6ae643a1031c31897263ac08f)), closes [#2464](https://github.com/fleetyards/fleetyards/issues/2464)

### [5.10.10](https://github.com/fleetyards/fleetyards/compare/v5.10.9...v5.10.10) (2022-11-27)


### Bug Fixes

* **fleet-stats:** exclude loaners from statistics ([d27e5b6](https://github.com/fleetyards/fleetyards/commit/d27e5b608326267ee2a0e8bd028dba6c168f3941)), closes [#2460](https://github.com/fleetyards/fleetyards/issues/2460)
* **fleets:** memberlist styling ([88fd91c](https://github.com/fleetyards/fleetyards/commit/88fd91c3b4e89774b79021e0df7df7299d6fa515))
* **hangar-import:** Add additional mapping for Genesis Starliner and Spirit ([828ae7e](https://github.com/fleetyards/fleetyards/commit/828ae7eee599cdc10923cea0cb9835da91540d5e))

### [5.10.9](https://github.com/fleetyards/fleetyards/compare/v5.10.8...v5.10.9) (2022-11-26)


### Bug Fixes

* **hangar:** render 404 if public hangar is disabled for all relevant api endpoints ([1bd6df1](https://github.com/fleetyards/fleetyards/commit/1bd6df1fe02dfe4545a527bf3581dc745750581a))
* **metrics:** update spacing ([5b2a9b5](https://github.com/fleetyards/fleetyards/commit/5b2a9b53e82e78e17610ed792bb668534378aa84))

### [5.10.8](https://github.com/fleetyards/fleetyards/compare/v5.10.7...v5.10.8) (2022-11-25)


### Bug Fixes

* **stage:** update ON_SUBDOMAIN flag ([736dacf](https://github.com/fleetyards/fleetyards/commit/736dacf0262c84311d639e5493282e1d6b298aec))
* **styling:** update Avatar image size and grid breakpoints for tablets ([d609f52](https://github.com/fleetyards/fleetyards/commit/d609f525a50bd11f1c40688abaefb0f94aa98c2f))

### [5.10.7](https://github.com/fleetyards/fleetyards/compare/v5.10.6...v5.10.7) (2022-11-19)


### Bug Fixes

* flagship icon ([7aa4cfe](https://github.com/fleetyards/fleetyards/commit/7aa4cfe3b3ff59529dfe7ecfdb6262e4ab41f5af))

### [5.10.6](https://github.com/fleetyards/fleetyards/compare/v5.10.5...v5.10.6) (2022-11-09)


### Bug Fixes

* **stats:** update hangar stats to only count non loaner ships ([7a29142](https://github.com/fleetyards/fleetyards/commit/7a29142c7a9b5fb7930970b93abd1bdbf09e4d63))

### [5.10.5](https://github.com/fleetyards/fleetyards/compare/v5.10.4...v5.10.5) (2022-11-09)


### Bug Fixes

* **hangar:** update calculation for models by manufacturer on stats page ([d0838cb](https://github.com/fleetyards/fleetyards/commit/d0838cb13ae940d1afe3c5867430d7861f5bb9b9))
* **sc-data:** load version from s3 ([0747a19](https://github.com/fleetyards/fleetyards/commit/0747a1971185a9608de9d648e0adebe105666e89))

### [5.10.4](https://github.com/fleetyards/fleetyards/compare/v5.10.3...v5.10.4) (2022-10-11)

### [5.10.3](https://github.com/fleetyards/fleetyards/compare/v5.10.2...v5.10.3) (2022-10-11)

### [5.10.2](https://github.com/fleetyards/fleetyards/compare/v5.10.1...v5.10.2) (2022-10-11)

### [5.10.1](https://github.com/fleetyards/fleetyards/compare/v5.10.0...v5.10.1) (2022-10-10)

## [5.10.0](https://github.com/fleetyards/fleetyards/compare/v5.9.4...v5.10.0) (2022-10-10)


### Features

* **hangar:** add datetime field to show when the hangar was last updated ([bc39f15](https://github.com/fleetyards/fleetyards/commit/bc39f1514d18b6bd4b0975eece80672b5e5017d9))

### [5.9.4](https://github.com/fleetyards/fleetyards/compare/v5.9.3...v5.9.4) (2022-10-09)


### Bug Fixes

* **shop-commodities:** safeguard empty shopping lists ([58c3fa8](https://github.com/fleetyards/fleetyards/commit/58c3fa887667283c2e2ed471800a40581ba1a050))

### [5.9.3](https://github.com/fleetyards/fleetyards/compare/v5.9.2...v5.9.3) (2022-10-09)

### [5.9.2](https://github.com/fleetyards/fleetyards/compare/v5.9.1...v5.9.2) (2022-10-09)


### Bug Fixes

* link header parser in embed ([8422076](https://github.com/fleetyards/fleetyards/commit/84220768f7a33f6613783cf11bf1c00fba862304))
* **pagination:** update link header parsing ([5d4824c](https://github.com/fleetyards/fleetyards/commit/5d4824c19cf80b1790de2b02133993a8a5e09659))

### [5.9.1](https://github.com/fleetyards/fleetyards/compare/v5.9.0...v5.9.1) (2022-10-09)

## [5.9.0](https://github.com/fleetyards/fleetyards/compare/v5.8.0...v5.9.0) (2022-10-08)


### Bug Fixes

* **fleet-member-list:** add missing prefix to social links ([#2284](https://github.com/fleetyards/fleetyards/issues/2284)) ([9729d1f](https://github.com/fleetyards/fleetyards/commit/9729d1f7179958a3a3932914ae3cfac0e744b1ad))
* **routes:** resolve issue with path in api_routes ([2a5c0a8](https://github.com/fleetyards/fleetyards/commit/2a5c0a84956c033aa307b68e15dbde033539ce93))

## [5.8.0](https://github.com/fleetyards/fleetyards/compare/v5.7.1...v5.8.0) (2022-05-29)


### Bug Fixes

* **tests:** add missing attributes ([adc2dea](https://github.com/fleetyards/fleetyards/commit/adc2deaa99cbb79d3e2e1dc58472ef6b7ae5d55a))

### [5.7.1](https://github.com/fleetyards/fleetyards/compare/v5.7.0...v5.7.1) (2022-05-25)

## [5.7.0](https://github.com/fleetyards/fleetyards/compare/v5.6.5...v5.7.0) (2022-05-01)


### Features

* **sc_data:** Update Gamefiles to 3.17.0 Live ([5afb08b](https://github.com/fleetyards/fleetyards/commit/5afb08ba149118821bc40df72d5aa3dd024677f4))

### [5.6.5](https://github.com/fleetyards/fleetyards/compare/v5.6.4...v5.6.5) (2022-04-30)

### [5.6.4](https://github.com/fleetyards/fleetyards/compare/v5.6.3...v5.6.4) (2022-04-30)


### Bug Fixes

* embed widget for fleets and users ([c633c77](https://github.com/fleetyards/fleetyards/commit/c633c7733af3650b5e4fd3410a91f6f7fc7c6a64))
* loaner worker to use zendesk api ([bdb92f9](https://github.com/fleetyards/fleetyards/commit/bdb92f95d37181c5208a1859ab4f3c29affeed2c))

### [5.6.3](https://github.com/fleetyards/fleetyards/compare/v5.6.2...v5.6.3) (2022-04-06)


### Bug Fixes

* embed view ([e2b9562](https://github.com/fleetyards/fleetyards/commit/e2b95622b73657629c43a4c3b892091ac842673f))

### [5.6.2](https://github.com/fleetyards/fleetyards/compare/v5.6.1...v5.6.2) (2022-04-03)


### Bug Fixes

* sort paints, modules and upgrades ([98dc964](https://github.com/fleetyards/fleetyards/commit/98dc964b08232b149649dda49aed6e43fbb6c053))

### [5.6.1](https://github.com/fleetyards/fleetyards/compare/v5.6.0...v5.6.1) (2022-02-15)

## [5.6.0](https://github.com/fleetyards/fleetyards/compare/v5.5.2...v5.6.0) (2022-02-15)


### Features

* **sc_data:** update to version 3.16.1-LIVE.7939065 ([8436795](https://github.com/fleetyards/fleetyards/commit/8436795fa9bc759d4e690ab1b255835dc5a8dde8))

### [5.5.2](https://github.com/fleetyards/fleetyards/compare/v5.5.1...v5.5.2) (2022-02-13)


### Bug Fixes

* solve infinite loading issue for some filters ([b9246ba](https://github.com/fleetyards/fleetyards/commit/b9246ba35c353d07bce10c1040fd587d43bedbe8))

### [5.5.1](https://github.com/fleetyards/fleetyards/compare/v5.5.0...v5.5.1) (2022-02-09)

### Bugfixes

* **navigation** update sidebar height for iOS Browsers


## [5.5.0](https://github.com/fleetyards/fleetyards/compare/v5.4.0...v5.5.0) (2022-02-09)

### Features

* **hangar-import:** mark all imported ships as purchased by default ([#2057](https://github.com/fleetyards/fleetyards/issues/2057)) ([22f6a9c](https://github.com/fleetyards/fleetyards/commit/22f6a9c5b643d8664f6466475a07c41622634b28))
* **fleetchart** update image resolutions for small sizes
* **navigation** cleanup links and minor styling updates (moved user menu to the bottom)


## [5.4.0](https://github.com/fleetyards/fleetyards/compare/v5.3.4...v5.4.0) (2022-01-12)


### Features

* **fleetchart-v2:** add all option for pagination of hangar and fleetchart ([9e300d7](https://github.com/fleetyards/fleetyards/commit/9e300d71d209769a2e3df0f452ffcfb1c1036c0c))

### [5.3.4](https://github.com/fleetyards/fleetyards/compare/v5.3.3...v5.3.4) (2022-01-09)

### [5.3.3](https://github.com/fleetyards/fleetyards/compare/v5.3.2...v5.3.3) (2022-01-09)


### Bug Fixes

* **fleetchart-v2:** readd starship42 links to fleetcharts ([dcecd62](https://github.com/fleetyards/fleetyards/commit/dcecd62476458648279fb2b2428ee312c89c1d6d))
* column chart ([c2d21de](https://github.com/fleetyards/fleetyards/commit/c2d21de64bf705dd5e1c000c8aae33e799417ef4))

### [5.3.2](https://github.com/fleetyards/fleetyards/compare/v5.3.1...v5.3.2) (2022-01-06)

### [5.3.1](https://github.com/fleetyards/fleetyards/compare/v5.3.0...v5.3.1) (2022-01-05)


### Bug Fixes

* **fleetchart-v2:** screenshot for classic mode ([1b44d55](https://github.com/fleetyards/fleetyards/commit/1b44d5551c789dc8e42e130dac65b8c070e74cd6))

## [5.3.0](https://github.com/fleetyards/fleetyards/compare/v5.2.1...v5.3.0) (2022-01-05)


### Features

* **fleetchart-v2:** add classic mode with scale slider ([39801bd](https://github.com/fleetyards/fleetyards/commit/39801bd939f6e2c519449b3962e542334dc4c539))


### Bug Fixes

* **fleetchart-v2:** rerender grid on orientation change or screen resize ([b1905ad](https://github.com/fleetyards/fleetyards/commit/b1905adfc1c25cf5e59812536a98c69cc300f51b))
* pagination ([ac5e262](https://github.com/fleetyards/fleetyards/commit/ac5e26262209bc8d35ba78bcd9962d34ebd83efe))

### [5.2.1](https://github.com/fleetyards/fleetyards/compare/v5.2.0...v5.2.1) (2022-01-02)


### Bug Fixes

* main module package ([0dc6771](https://github.com/fleetyards/fleetyards/commit/0dc6771ded60aebc0e5d62bc40449009031a6783))

## [5.2.0](https://github.com/fleetyards/fleetyards/compare/v5.0.1...v5.2.0) (2022-01-02)


### Features

* **fleetchart-v2:** add views to module packages ([f5b937b](https://github.com/fleetyards/fleetyards/commit/f5b937b35772f543ae77fbf976ef6b5fd8e03e68))


### Bug Fixes

* module packages ([4c1a579](https://github.com/fleetyards/fleetyards/commit/4c1a579f56bcd9d4c02c9480c983b3d70aa212f0))
* vehicle relation to module_package ([8d2ea5e](https://github.com/fleetyards/fleetyards/commit/8d2ea5ef9ee9adb976cf976cc683b79f21c54690))

## [5.1.0](https://github.com/fleetyards/fleetyards/compare/v5.0.1...v5.1.0) (2022-01-02)


### Features

* **fleetchart-v2:** add views for module packages ([f5b937b](https://github.com/fleetyards/fleetyards/commit/f5b937b35772f543ae77fbf976ef6b5fd8e03e68))


### Bug Fixes

* vehicle relation to module_package ([8d2ea5e](https://github.com/fleetyards/fleetyards/commit/8d2ea5ef9ee9adb976cf976cc683b79f21c54690))

### [5.0.1](https://github.com/fleetyards/fleetyards/compare/v5.0.0...v5.0.1) (2021-12-29)


### Bug Fixes

* max per page check ([f75e34f](https://github.com/fleetyards/fleetyards/commit/f75e34f8217405f1095e94f7b52075a8fc9d583b))
* panel-dropdown ([4438b75](https://github.com/fleetyards/fleetyards/commit/4438b757bbe580e4f74c2cc53d8bdab32fcbee8c))

## [5.0.0](https://github.com/fleetyards/fleetyards/compare/v4.23.5...v5.0.0) (2021-12-29)

### Features

* **fleetchart-v2:** new fleetchart in modal for top, side and angled views

### Bug Fixes

* sc_data hardpoint generation ([d4888e7](https://github.com/fleetyards/fleetyards/commit/d4888e7708ac747a932b3fd1e946d6e9048dce25))

### [4.23.5](https://github.com/fleetyards/fleetyards/compare/v4.23.4...v4.23.5) (2021-11-27)


### Bug Fixes

* **sale-notifactions:** only send sale notifications if model is older than 24 ([aeba94d](https://github.com/fleetyards/fleetyards/commit/aeba94ddfbb449c45f6d6c43b4e0b877fdb0bf2d))
* model loader dont update names automatically ([f5be393](https://github.com/fleetyards/fleetyards/commit/f5be3931c6e42bdbf95e2dcccbbaf7ef2db794b0))

### [4.23.4](https://github.com/fleetyards/fleetyards/compare/v4.23.3...v4.23.4) (2021-11-27)


### Bug Fixes

* model loader for empty hardpoint names ([e1818d7](https://github.com/fleetyards/fleetyards/commit/e1818d7406d78c2c4ef3e4fc1091ea8edc140b54))

### [4.23.3](https://github.com/fleetyards/fleetyards/compare/v4.23.2...v4.23.3) (2021-11-25)


### Bug Fixes

* share buttons and fleet logo ([e34067e](https://github.com/fleetyards/fleetyards/commit/e34067e9d9d6e6b80c9eeacd0cefc4cddcad6bd5))

### [4.23.2](https://github.com/fleetyards/fleetyards/compare/v4.23.1...v4.23.2) (2021-11-19)


### Bug Fixes

* model variants endpoint ([826a9e0](https://github.com/fleetyards/fleetyards/commit/826a9e05e7dcee6cff89108299a9f6ba758d32d2))

### [4.23.1](https://github.com/fleetyards/fleetyards/compare/v4.23.0...v4.23.1) (2021-11-19)


### Bug Fixes

* variants on models ([11253ca](https://github.com/fleetyards/fleetyards/commit/11253ca3191f00e0c21f9ab24906d55a527823c7))

## [4.23.0](https://github.com/fleetyards/fleetyards/compare/v4.22.7...v4.23.0) (2021-11-19)


### Features

* **SC-Data:** update SC Data to latest 3.15.1 PTU Build ([cfd23b3](https://github.com/fleetyards/fleetyards/commit/cfd23b33d8eaa2ef129697d84174112a679b0ecf))


### Bug Fixes

* **models:** variants ([0149e7e](https://github.com/fleetyards/fleetyards/commit/0149e7e14c16f2fa4d00a186c550c030047461f3))

### [4.22.7](https://github.com/fleetyards/fleetyards/compare/v4.22.6...v4.22.7) (2021-11-17)

### [4.22.6](https://github.com/fleetyards/fleetyards/compare/v4.22.5...v4.22.6) (2021-11-16)

### [4.22.5](https://github.com/fleetyards/fleetyards/compare/v4.22.4...v4.22.5) (2021-11-16)

### [4.22.4](https://github.com/fleetyards/fleetyards/compare/v4.22.3...v4.22.4) (2021-11-16)


### Bug Fixes

* store image uploader medium size ([89331d4](https://github.com/fleetyards/fleetyards/commit/89331d476bd99b6f8db4fa8aad5dc4095f849be5))

### [4.22.3](https://github.com/fleetyards/fleetyards/compare/v4.22.2...v4.22.3) (2021-11-16)


### Bug Fixes

* sc_data loader and HangarGroupCount Struct ([9017377](https://github.com/fleetyards/fleetyards/commit/90173771f07289a65779c976d27dfe84daa7bc43))

### [4.22.2](https://github.com/fleetyards/fleetyards/compare/v4.22.1...v4.22.2) (2021-11-16)


### Bug Fixes

* store image loader ([5a168da](https://github.com/fleetyards/fleetyards/commit/5a168dafd9f58041c1c4b9c54fef29e94c17b897))
* **module-packages:** make package selected display independent from order ([202774f](https://github.com/fleetyards/fleetyards/commit/202774fff1c5afce7c11f31d1bcf75d9c88a1805))

### [4.22.1](https://github.com/fleetyards/fleetyards/compare/v4.22.0...v4.22.1) (2021-11-14)


### Bug Fixes

* module packages edit page for admin ([4064647](https://github.com/fleetyards/fleetyards/commit/4064647c5dc58aeeb9f78acac76f43b490025a72))

## [4.22.0](https://github.com/fleetyards/fleetyards/compare/v4.21.3...v4.22.0) (2021-11-14)


### Features

* **fleet:** add member filter to ship page ([91dd1af](https://github.com/fleetyards/fleetyards/commit/91dd1af52bd655b7aabbb1fd05dbba79b1123661)), closes [#1907](https://github.com/fleetyards/fleetyards/issues/1907)
* **fleets:** add filters to public ship pages ([639a3b3](https://github.com/fleetyards/fleetyards/commit/639a3b3f6e2cfe486a4ec72814abfe057126d0a9)), closes [#1909](https://github.com/fleetyards/fleetyards/issues/1909)


### Bug Fixes

* fleet description validation ([3f6c374](https://github.com/fleetyards/fleetyards/commit/3f6c374663d61672cada481131ba934eb04f5162)), closes [#1837](https://github.com/fleetyards/fleetyards/issues/1837)
* location labels for lagrange rest stops ([548e50f](https://github.com/fleetyards/fleetyards/commit/548e50fce5f0fdb88c4807fb373e8f32add8606b))

### [4.21.3](https://github.com/fleetyards/fleetyards/compare/v4.21.2...v4.21.3) (2021-11-14)


### Bug Fixes

* store image uploader ([d2adaf7](https://github.com/fleetyards/fleetyards/commit/d2adaf791e44a821c3fbf5348dcf517e69b4ca54))

### [4.21.2](https://github.com/fleetyards/fleetyards/compare/v4.21.1...v4.21.2) (2021-11-14)


### Bug Fixes

* store images for equipment ([6a27ac1](https://github.com/fleetyards/fleetyards/commit/6a27ac147ce34574aa97915dabcf105d220f8fca))

### [4.21.1](https://github.com/fleetyards/fleetyards/compare/v4.21.0...v4.21.1) (2021-11-14)


### Bug Fixes

* new field labels ([dc211df](https://github.com/fleetyards/fleetyards/commit/dc211df77a414e2ac9ba726b3ff61543c1986521))

## [4.21.0](https://github.com/fleetyards/fleetyards/compare/v4.20.0...v4.21.0) (2021-11-14)


### Features

* add missing attributes to equipment ([659b73e](https://github.com/fleetyards/fleetyards/commit/659b73e8203e3f5e824f8f0cbc6c96c49faf0ce1)), closes [#1933](https://github.com/fleetyards/fleetyards/issues/1933)


### Bug Fixes

* admin locales ([3788328](https://github.com/fleetyards/fleetyards/commit/37883281d6a310d326701265465c590d6eb7bfa8))

## [4.20.0](https://github.com/fleetyards/fleetyards/compare/v4.19.1...v4.20.0) (2021-11-12)


### Features

* **fleetchart-v2:** add fields to model paints ([ff1435f](https://github.com/fleetyards/fleetyards/commit/ff1435f7663468c5f1bcf55d00ccbdef63475011))
* **fleetchart-v2:** add new upload fields to model ([2278517](https://github.com/fleetyards/fleetyards/commit/22785174b8758e575710f4dc51c59322bbdefdf3))


### Bug Fixes

* specs ([9b34dc6](https://github.com/fleetyards/fleetyards/commit/9b34dc69ecfa3aa2cee4ca8c1c047186959c08a7))

### [4.19.1](https://github.com/fleetyards/fleetyards/compare/v4.19.0...v4.19.1) (2021-11-05)

## [4.19.0](https://github.com/fleetyards/fleetyards/compare/v4.18.3...v4.19.0) (2021-11-03)


### Features

* allow public fleets in embed view ([5a0e1a7](https://github.com/fleetyards/fleetyards/commit/5a0e1a71d35ba8a67fe4f425a80a2cb01b496c49))

### [4.18.3](https://github.com/fleetyards/fleetyards/compare/v4.18.2...v4.18.3) (2021-10-20)


### Bug Fixes

* addons and modules menu in context menu ([6259361](https://github.com/fleetyards/fleetyards/commit/62593618a7b6723204472f9ecb431137e0a40575))
* will_it_fit check ([f9f93c0](https://github.com/fleetyards/fleetyards/commit/f9f93c09d3df671aa3b2ab8588ccbcd7d83d036f))

### [4.18.2](https://github.com/fleetyards/fleetyards/compare/v4.18.1...v4.18.2) (2021-10-17)


### Bug Fixes

* starship42 redirect to fleetview for very big fleets ([c53b13d](https://github.com/fleetyards/fleetyards/commit/c53b13dc0f77b851d94f03801506058a39c020a8))
* starship42 redirect to fleetview for very big fleets ([d65e410](https://github.com/fleetyards/fleetyards/commit/d65e4108619c50923debeaf7202e8b00ea83c641))

### [4.18.1](https://github.com/fleetyards/fleetyards/compare/v4.18.0...v4.18.1) (2021-10-15)


### Bug Fixes

* variants for non rsi ships ([37de5a3](https://github.com/fleetyards/fleetyards/commit/37de5a34539aafa63c0f0ee0be1563765773af16))

## [4.18.0](https://github.com/fleetyards/fleetyards/compare/v4.17.5...v4.18.0) (2021-10-14)


### Features

* add top views to compare page ([36e9ac1](https://github.com/fleetyards/fleetyards/commit/36e9ac1a551d34d964ad387d86b64dbeb256de9d))

### [4.17.5](https://github.com/fleetyards/fleetyards/compare/v4.17.4...v4.17.5) (2021-10-13)


### Bug Fixes

* model paints for shops ([b37589f](https://github.com/fleetyards/fleetyards/commit/b37589f95d5d82253587a96199ae49881af09dab))

### [4.17.4](https://github.com/fleetyards/fleetyards/compare/v4.17.3...v4.17.4) (2021-10-13)


### Bug Fixes

* manufacturer names on search results ([292054c](https://github.com/fleetyards/fleetyards/commit/292054ca277bb5c74f0119861041d238414f360a))

### [4.17.3](https://github.com/fleetyards/fleetyards/compare/v4.17.2...v4.17.3) (2021-10-13)


### Bug Fixes

* indexing of components and equipment ([51f6173](https://github.com/fleetyards/fleetyards/commit/51f61733fb7804d6b655c9c561daeee0ec8e4191))

### [4.17.2](https://github.com/fleetyards/fleetyards/compare/v4.17.1...v4.17.2) (2021-10-13)


### Bug Fixes

* shop location listings in search result ([4d8a106](https://github.com/fleetyards/fleetyards/commit/4d8a1060a203537d7356efc9c97aaec6d748f466))
* translations ([b271205](https://github.com/fleetyards/fleetyards/commit/b271205acac3290f800dc24abea0e3941fe8741f))

### [4.17.1](https://github.com/fleetyards/fleetyards/compare/v4.17.0...v4.17.1) (2021-10-12)

## [4.17.0](https://github.com/fleetyards/fleetyards/compare/v4.16.18...v4.17.0) (2021-10-12)


### Features

* add sales page link to ship detail ([09ab2f7](https://github.com/fleetyards/fleetyards/commit/09ab2f7ee619c4bfbec159b4504bf8fec9b4e680))
* show shop locations for listed items without prices ([9761adf](https://github.com/fleetyards/fleetyards/commit/9761adf2bae2b2a80c83c49cbd5cb2842c61e7af))


### Bug Fixes

* specs ([222acd7](https://github.com/fleetyards/fleetyards/commit/222acd742276cab7ab5c2adde62ebd0d804ee4ca))
* specs ([65a5c17](https://github.com/fleetyards/fleetyards/commit/65a5c17097a852ebc280f5b5c445ae44b0eb1cce))
* specs ([eae03c9](https://github.com/fleetyards/fleetyards/commit/eae03c9ed000c68b6b13f7c101c945c7b08a2e3f))

### [4.16.18](https://github.com/fleetyards/fleetyards/compare/v4.16.17...v4.16.18) (2021-10-12)

### [4.16.17](https://github.com/fleetyards/fleetyards/compare/v4.16.16...v4.16.17) (2021-10-11)


### Bug Fixes

* components management in backend ([820b91b](https://github.com/fleetyards/fleetyards/commit/820b91b72e81bf2526fd2d62c96b166f19ddd8f5))
* fleet member leave error ([28ef860](https://github.com/fleetyards/fleetyards/commit/28ef860deb785d1a1f1df94cceeec1eb716623a2))

### [4.16.16](https://github.com/fleetyards/fleetyards/compare/v4.16.15...v4.16.16) (2021-10-10)


### Bug Fixes

* add missing safeguards on possibly undefined params ([aa638bf](https://github.com/fleetyards/fleetyards/commit/aa638bf2721d867a94419555a749693e811db1fc))
* release workflow ([0b7c018](https://github.com/fleetyards/fleetyards/commit/0b7c0189dfd5cc6318904ba049037b63867e43a4))

### [4.16.15](https://github.com/fleetyards/fleetyards/compare/v4.16.14...v4.16.15) (2021-10-09)


### Bug Fixes

* search model panel ([7607c35](https://github.com/fleetyards/fleetyards/commit/7607c358a095576105b63aae38a503990c0a487e))

### [4.16.14](https://github.com/fleetyards/fleetyards/compare/v4.16.13...v4.16.14) (2021-10-08)

### [4.16.13](https://github.com/fleetyards/fleetyards/compare/v4.16.12...v4.16.13) (2021-10-07)


### Bug Fixes

* fleet ValidationErrors ([f56101a](https://github.com/fleetyards/fleetyards/commit/f56101a2643494003a4c8b757ae08605a6c64a9a))
* validation ([5d07bd7](https://github.com/fleetyards/fleetyards/commit/5d07bd7dafe27857c928324722287f68f3f9c669))

### [4.16.12](https://github.com/fleetyards/fleetyards/compare/v4.16.11...v4.16.12) (2021-10-07)


### Bug Fixes

* validation error ([f528a23](https://github.com/fleetyards/fleetyards/commit/f528a23262c813a72d699416104fcaefdda6d15f))

### [4.16.11](https://github.com/fleetyards/fleetyards/compare/v4.16.10...v4.16.11) (2021-10-07)

### [4.16.10](https://github.com/fleetyards/fleetyards/compare/v4.16.9...v4.16.10) (2021-10-07)

### [4.16.9](https://github.com/fleetyards/fleetyards/compare/v4.16.8...v4.16.9) (2021-10-07)

### [4.16.8](https://github.com/fleetyards/fleetyards/compare/v4.16.7...v4.16.8) (2021-10-07)


### Bug Fixes

* smoke tests ([6a5a550](https://github.com/fleetyards/fleetyards/commit/6a5a550a803e3fa5aef059d7b11bd20172d97f20))

### [4.16.7](https://github.com/fleetyards/fleetyards/compare/v4.16.6...v4.16.7) (2021-10-07)


### Bug Fixes

* workflow ([0342716](https://github.com/fleetyards/fleetyards/commit/03427169979e47f9514caa48dd0826df0b931b35))

### [4.16.6](https://github.com/fleetyards/fleetyards/compare/v4.16.5...v4.16.6) (2021-10-07)

### [4.16.5](https://github.com/fleetyards/fleetyards/compare/v4.16.4...v4.16.5) (2021-10-07)

### [4.16.4](https://github.com/fleetyards/fleetyards/compare/v4.16.3...v4.16.4) (2021-10-07)


### Bug Fixes

* release workflow ([e8239d1](https://github.com/fleetyards/fleetyards/commit/e8239d17b5d48cae966d64e965653db380274b2e))

### [4.16.3](https://github.com/fleetyards/fleetyards/compare/v4.16.2...v4.16.3) (2021-10-07)

### [4.16.2](https://github.com/fleetyards/fleetyards/compare/v4.16.1...v4.16.2) (2021-10-07)


### Bug Fixes

* make sure vehicle is loaded on vehicle panel ([520b35c](https://github.com/fleetyards/fleetyards/commit/520b35c0779cb919549a69da78c042ba1e15ebde))

### [4.16.1](https://github.com/fleetyards/fleetyards/compare/v4.16.0...v4.16.1) (2021-10-05)


### Bug Fixes

* public hangar loaners hint ([00ba48e](https://github.com/fleetyards/fleetyards/commit/00ba48e528d1737517c4d27b308810c253451c72))

## [4.16.0](https://github.com/fleetyards/fleetyards/compare/v4.15.0...v4.16.0) (2021-10-05)


### Features

* add share button to model detail ([6bd00d9](https://github.com/fleetyards/fleetyards/commit/6bd00d996f69157c5bf6a514e1295b46fe5c0c23))


### Bug Fixes

* active home nav on mobile ([7c96a86](https://github.com/fleetyards/fleetyards/commit/7c96a864359976d7c25f4e3c799e968018f09f49))
* hide hangar groups until stats are loaded ([6585619](https://github.com/fleetyards/fleetyards/commit/658561918b6a4e6fba52f28799c073453f09cf0c))
* loader position ([362d76e](https://github.com/fleetyards/fleetyards/commit/362d76e45a46c975e048ff1df4b280391b7f14da))
* mobile nav ([4f7923d](https://github.com/fleetyards/fleetyards/commit/4f7923d00d140b9fb589eb474bcc513fcc92fe12))
* navigation ([1a9cdff](https://github.com/fleetyards/fleetyards/commit/1a9cdffdd7cad4c67e4ba1cc064f667b2e21f965))
* specs ([22be552](https://github.com/fleetyards/fleetyards/commit/22be552237e8b3809101e97f30d79ee52a02da22))

## [4.15.0](https://github.com/fleetyards/fleetyards/compare/v4.14.1...v4.15.0) (2021-09-27)


### Features

* **HangarGroups:** allow group bubbles to toggle filter ([f04727a](https://github.com/fleetyards/fleetyards/commit/f04727a628cb48e76fe854982e84656c0a5325ff))


### Bug Fixes

* specs ([8e1f797](https://github.com/fleetyards/fleetyards/commit/8e1f797cc6e27c29f79c23dcd7811357cbcc9330))
* update caching for hangar groups ([8c04e40](https://github.com/fleetyards/fleetyards/commit/8c04e4068120bf030b4fce97f5df5137c2d4ee71))

### [4.14.1](https://github.com/fleetyards/fleetyards/compare/v4.14.0...v4.14.1) (2021-09-26)


### Bug Fixes

* **PublicHangarGroups:** update public endpoint and fix caching for public ([5c18a9f](https://github.com/fleetyards/fleetyards/commit/5c18a9f0bc9a2c3309ea76bd8ffaa9cc3c402ace))

## [4.14.0](https://github.com/fleetyards/fleetyards/compare/v4.13.1...v4.14.0) (2021-09-26)


### Features

* public hangar groups ([#1804](https://github.com/fleetyards/fleetyards/issues/1804)) ([de6acce](https://github.com/fleetyards/fleetyards/commit/de6acce65de46323b176d44e5752c5ce803ef3bf))


### Bug Fixes

* base_uploader issue with local uploads ([8f806e6](https://github.com/fleetyards/fleetyards/commit/8f806e656744eeb61e8d8e8eaeee9f4ef8c342e2))

### [4.13.1](https://github.com/fleetyards/fleetyards/compare/v4.13.0...v4.13.1) (2021-09-19)

## [4.13.0](https://github.com/fleetyards/fleetyards/compare/v4.12.14...v4.13.0) (2021-09-19)


### Features

* add detail modal to roadmap items ([e2223d4](https://github.com/fleetyards/fleetyards/commit/e2223d4abd580ee23a2e96de634423c024498451))

### [4.12.14](https://github.com/fleetyards/fleetyards/compare/v4.12.13...v4.12.14) (2021-09-18)


### Bug Fixes

* update readme for embed view ([c37dd5c](https://github.com/fleetyards/fleetyards/commit/c37dd5cb8c56792ae021ae7c39f60bacd0aff49d))

### [4.12.13](https://github.com/fleetyards/fleetyards/compare/v4.12.12...v4.12.13) (2021-09-15)


### Bug Fixes

* parse dollar formated string ([5bae75e](https://github.com/fleetyards/fleetyards/commit/5bae75eecfa7361510240e7a798c7c9cc6a187af))

### [4.12.12](https://github.com/fleetyards/fleetyards/compare/v4.12.11...v4.12.12) (2021-09-15)


### Bug Fixes

* price detection in rsi models loader ([69181e1](https://github.com/fleetyards/fleetyards/commit/69181e195d114343a07e60b9023dfc5db1d56dbe))

### [4.12.11](https://github.com/fleetyards/fleetyards/compare/v4.12.10...v4.12.11) (2021-09-13)


### Bug Fixes

* specs ([daac298](https://github.com/fleetyards/fleetyards/commit/daac29842fec5df789a16560fb5c6acef2941615))

### [4.12.10](https://github.com/fleetyards/fleetyards/compare/v4.12.9...v4.12.10) (2021-09-07)

### [4.12.9](https://github.com/fleetyards/fleetyards/compare/v4.12.8...v4.12.9) (2021-09-06)


### Bug Fixes

* loaner icon purchased click ([b31d4a6](https://github.com/fleetyards/fleetyards/commit/b31d4a693b0e6dba0a98d1284851bcdec5dac432))

### [4.12.8](https://github.com/fleetyards/fleetyards/compare/v4.12.7...v4.12.8) (2021-09-06)


### Bug Fixes

* audit issues ([fad1ae2](https://github.com/fleetyards/fleetyards/commit/fad1ae2137fea16608b71ec2798c56a3c324ca10))
* e2e specs ([0e22586](https://github.com/fleetyards/fleetyards/commit/0e225867cacec697f6a820f790888b008b4dbcc1))

### [4.12.7](https://github.com/fleetyards/fleetyards/compare/v4.12.6...v4.12.7) (2021-09-04)


### Bug Fixes

* e2e specs for smoke test ([af3353c](https://github.com/fleetyards/fleetyards/commit/af3353cca923e311e39839ba3ead57eb42578097))

### [4.12.6](https://github.com/fleetyards/fleetyards/compare/v4.12.5...v4.12.6) (2021-09-04)

### [4.12.5](https://github.com/fleetyards/fleetyards/compare/v4.12.4...v4.12.5) (2021-09-04)


### Bug Fixes

* add some z to the support button ([36e5da2](https://github.com/fleetyards/fleetyards/commit/36e5da2e0fb02a29c19d1c60101b9e59c50fa8fc))
* specs ([4c6e743](https://github.com/fleetyards/fleetyards/commit/4c6e743c5499db0e7f54ce0788b1f63513f44890))

### [4.12.4](https://github.com/fleetyards/fleetyards/compare/v4.12.3...v4.12.4) (2021-08-31)


### Bug Fixes

* add to hangar ([a1547d9](https://github.com/fleetyards/fleetyards/commit/a1547d9a7537c4b1822bf80c48737842cd3aedf5))
* filter issue in compare hardpoints ([5c86f4a](https://github.com/fleetyards/fleetyards/commit/5c86f4a0299e8ad28a017abf4eb768e5d0c1ef08))
* middlewares ([5baa16a](https://github.com/fleetyards/fleetyards/commit/5baa16a08397da5190877d76986f5cb18a788121))

### [4.12.3](https://github.com/fleetyards/fleetyards/compare/v4.12.2...v4.12.3) (2021-08-27)


### Bug Fixes

* ahoy js tracking ([f9b5d52](https://github.com/fleetyards/fleetyards/commit/f9b5d52514b05cb1c019b4b15e124ea63118ccf2))
* downgrade webpack-dev-server ([c923dbd](https://github.com/fleetyards/fleetyards/commit/c923dbda398d70b139fa7d2f937b4433d0304725))

### [4.12.2](https://github.com/fleetyards/fleetyards/compare/v4.12.1...v4.12.2) (2021-08-17)


### Bug Fixes

* mark vehicles as public by default ([4c9f57f](https://github.com/fleetyards/fleetyards/commit/4c9f57f76124be9eb43c4f266a9a4a2cacc9a01a))
* shopping cart ([8bd0c05](https://github.com/fleetyards/fleetyards/commit/8bd0c05d617d532585894e0c356f056a6ee4dd7b))

### [4.12.1](https://github.com/fleetyards/fleetyards/compare/v4.12.0...v4.12.1) (2021-07-28)

## [4.12.0](https://github.com/fleetyards/fleetyards/compare/v4.11.17...v4.12.0) (2021-07-27)


### Features

* mobile navigation ([41bc1b7](https://github.com/fleetyards/fleetyards/commit/41bc1b7b1922dd228fb8ffb5df1d481e5f320e2f))
* update mobile navigation ([a0ee85a](https://github.com/fleetyards/fleetyards/commit/a0ee85ac29d6517727b4d36b730108ea66dca73e))


### Bug Fixes

* shopping cart mobile position ([4700de8](https://github.com/fleetyards/fleetyards/commit/4700de85a60ebf3754868b283d04d8ec5a483247))

### [4.11.17](https://github.com/fleetyards/fleetyards/compare/v4.11.16...v4.11.17) (2021-07-25)


### Bug Fixes

* e2e specs ([5639ac1](https://github.com/fleetyards/fleetyards/commit/5639ac16df76a90863cd215193b18fc1bd687780))
* model loader for snub hardpoints ([f16cd82](https://github.com/fleetyards/fleetyards/commit/f16cd826462de503f1c68ebb2e7ae815163ffe77))

### [4.11.16](https://github.com/fleetyards/fleetyards/compare/v4.11.15...v4.11.16) (2021-07-19)


### Bug Fixes

* fleetchart context menu ([6bff900](https://github.com/fleetyards/fleetyards/commit/6bff900f4219a99b0ec07683b7f692eb500852c3))
* fleetchart context menu ([0d311cc](https://github.com/fleetyards/fleetyards/commit/0d311cc690a9e1513dbeb91b5a96d2e31adff637))

### [4.11.15](https://github.com/fleetyards/fleetyards/compare/v4.11.14...v4.11.15) (2021-07-14)

### [4.11.14](https://github.com/fleetyards/fleetyards/compare/v4.11.13...v4.11.14) (2021-06-12)


### Bug Fixes

* ship naming form resets hangar groups ([49d231b](https://github.com/fleetyards/fleetyards/commit/49d231b831ae7ba696cab1fbadd366db59732450)), closes [#1580](https://github.com/fleetyards/fleetyards/issues/1580)

### [4.11.13](https://github.com/fleetyards/fleetyards/compare/v4.11.12...v4.11.13) (2021-06-10)


### Bug Fixes

* manufacturer name ([56a8a00](https://github.com/fleetyards/fleetyards/commit/56a8a002c89219e3ac7ca6a27a880cec5aa1b5a5))

### [4.11.12](https://github.com/fleetyards/fleetyards/compare/v4.11.11...v4.11.12) (2021-06-08)

### [4.11.11](https://github.com/fleetyards/fleetyards/compare/v4.11.10...v4.11.11) (2021-05-31)


### Bug Fixes

* hardpoints ([75ff1d3](https://github.com/fleetyards/fleetyards/commit/75ff1d3fc1caa3a667bd8511dbfedc0af23a77a7))

### [4.11.10](https://github.com/fleetyards/fleetyards/compare/v4.11.9...v4.11.10) (2021-05-31)


### Bug Fixes

* fleet admin abilities ([76bb693](https://github.com/fleetyards/fleetyards/commit/76bb69383334a808a0e06fc43ad7b53f57fb65ff))

### [4.11.9](https://github.com/fleetyards/fleetyards/compare/v4.11.8...v4.11.9) (2021-05-27)


### Bug Fixes

* hardpoint loadout component size ([cb9fe4f](https://github.com/fleetyards/fleetyards/commit/cb9fe4ff30891413e89606f82245fd8ab11ddafc))
* sc data ships loader ([cc8e7a4](https://github.com/fleetyards/fleetyards/commit/cc8e7a470339c403e9534a17ef5c81593b2dc123))

### [4.11.8](https://github.com/fleetyards/fleetyards/compare/v4.11.7...v4.11.8) (2021-05-25)

### [4.11.7](https://github.com/fleetyards/fleetyards/compare/v4.11.6...v4.11.7) (2021-05-25)


### Bug Fixes

* fleetchart context menu ([ad95eec](https://github.com/fleetyards/fleetyards/commit/ad95eec82eab767d8f5bfe3fc72fdfd2251e7443))
* gamefile ship data ([6b14aa9](https://github.com/fleetyards/fleetyards/commit/6b14aa9b21cb648dfb0f3249b40cfae7cdb49f0c))
* specs ([0c03cad](https://github.com/fleetyards/fleetyards/commit/0c03cadcd37bf34a9995e87f48554fd629400929))
* specs ([3f4e790](https://github.com/fleetyards/fleetyards/commit/3f4e79031387a090b96e7f6fa2f94ab05845bd96))

### [4.11.6](https://github.com/fleetyards/fleetyards/compare/v4.11.5...v4.11.6) (2021-05-20)

### [4.11.5](https://github.com/fleetyards/fleetyards/compare/v4.11.4...v4.11.5) (2021-05-20)


### Bug Fixes

* specs ([a719490](https://github.com/fleetyards/fleetyards/commit/a71949086d1d8e582e4a1bd8d09da828abfeddeb))

### [4.11.4](https://github.com/fleetyards/fleetyards/compare/v4.11.3...v4.11.4) (2021-05-19)

### [4.11.3](https://github.com/fleetyards/fleetyards/compare/v4.11.2...v4.11.3) (2021-05-16)


### Bug Fixes

* action cable allowed hosts ([d2bdd15](https://github.com/fleetyards/fleetyards/commit/d2bdd156145c0ab9afc4035a19afa3713b353cde))
* package json ([0d6c6a4](https://github.com/fleetyards/fleetyards/commit/0d6c6a40823a49a6ee998892e18d038fe6cc2063))
* search labels ([1ebb5aa](https://github.com/fleetyards/fleetyards/commit/1ebb5aa79571b27f6769b5020e45047d7c721bc9))
* service-worker ([48b8235](https://github.com/fleetyards/fleetyards/commit/48b8235401197e9b703da6b70fa9698690521aa3))

### [4.11.2](https://github.com/fleetyards/fleetyards/compare/v4.11.1...v4.11.2) (2021-05-15)


### Bug Fixes

* minor styling fixes ([be9239d](https://github.com/fleetyards/fleetyards/commit/be9239d472497be515ec18f2d48e9d510dd8909b))

### [4.11.1](https://github.com/fleetyards/fleetyards/compare/v4.11.0...v4.11.1) (2021-05-14)


### Bug Fixes

* carrierwave allow list ([34cc18b](https://github.com/fleetyards/fleetyards/commit/34cc18bb246db57179c4d0e43cd3ec46e154c8b6))
* navigation ([850eb3f](https://github.com/fleetyards/fleetyards/commit/850eb3f5dbe541a04d44940e1740666836a97455))
* navigation ([cebe841](https://github.com/fleetyards/fleetyards/commit/cebe841318bc08e8091d4ae17d8ff33a87985c9d))

## [4.11.0](https://github.com/fleetyards/fleetyards/compare/v4.10.8...v4.11.0) (2021-05-13)


### Features

* add threejs holoviewer as a replacement for the starship42 iframe ([#1500](https://github.com/fleetyards/fleetyards/issues/1500)) ([81c536b](https://github.com/fleetyards/fleetyards/commit/81c536b91682bce548a25e2a95ddb2bea0c64b8c))
* update holoViewer controls ([b8c0885](https://github.com/fleetyards/fleetyards/commit/b8c08853904b07e5ea2e30e7aaaded895430609f))


### Bug Fixes

* audit issue ([150492d](https://github.com/fleetyards/fleetyards/commit/150492df50f72942e09ab0696a6d4b162848f1fe))
* csp header for worker src ([4a98e85](https://github.com/fleetyards/fleetyards/commit/4a98e850bc58c41faed8998620980c580088ef06))
* deploy ([90488f7](https://github.com/fleetyards/fleetyards/commit/90488f73e410a574041275efe094a949a30b89e1))
* make fleet invite requests visible and add validation errors to invite form ([0bceb22](https://github.com/fleetyards/fleetyards/commit/0bceb22bb0582dab55361a8294214e4353e83e41))
* public fleet api endpoints ([bafd5ae](https://github.com/fleetyards/fleetyards/commit/bafd5ae2347bda50b23392cf2ab8737ec66e0280))
* service worker ([1eee382](https://github.com/fleetyards/fleetyards/commit/1eee382ca9ff5b944f0342d2fa5a6e62d08d946a))

### [4.10.8](https://github.com/fleetyards/fleetyards/compare/v4.10.7...v4.10.8) (2021-05-08)


### Bug Fixes

* roadmap changes week ([465827b](https://github.com/fleetyards/fleetyards/commit/465827b8485c530a61481b2ba5de8723b7445c3d))

### [4.10.7](https://github.com/fleetyards/fleetyards/compare/v4.10.6...v4.10.7) (2021-05-04)


### Bug Fixes

* admin shop commodities ([b2f4bff](https://github.com/fleetyards/fleetyards/commit/b2f4bff564c41ab39048f3873fac4fe9fa9a0977))
* admin views and shop commodities listing ([46071b6](https://github.com/fleetyards/fleetyards/commit/46071b6a4cac09132fa1aee2a8cf7b4338bb9593))

### [4.10.6](https://github.com/fleetyards/fleetyards/compare/v4.10.5...v4.10.6) (2021-05-02)


### Bug Fixes

* appsignal deploy hook ([336c2f0](https://github.com/fleetyards/fleetyards/commit/336c2f0fdea1b78393a14b509ec5452d7a393e41))

### [4.10.5](https://github.com/fleetyards/fleetyards/compare/v4.10.4...v4.10.5) (2021-05-02)

### [4.10.4](https://github.com/fleetyards/fleetyards/compare/v4.10.3...v4.10.4) (2021-05-01)

### [4.10.3](https://github.com/fleetyards/fleetyards/compare/v4.10.2...v4.10.3) (2021-04-26)


### Bug Fixes

* formInput clearable ([ba1b58c](https://github.com/fleetyards/fleetyards/commit/ba1b58cb161533a319bd7a85c6a9a9d47aa03160))

### [4.10.2](https://github.com/fleetyards/fleetyards/compare/v4.10.1...v4.10.2) (2021-04-23)


### Bug Fixes

* user and fleet urls ([97d7b36](https://github.com/fleetyards/fleetyards/commit/97d7b36180044ed7305fc5076d6da47f329adac0))

### [4.10.1](https://github.com/fleetyards/fleetyards/compare/v4.10.0...v4.10.1) (2021-04-23)


### Bug Fixes

* img metrics on home ([5912957](https://github.com/fleetyards/fleetyards/commit/5912957bdef31592fb8a27b2e6c2ff448d243f0f))
* urls for users and fleets ([216b18a](https://github.com/fleetyards/fleetyards/commit/216b18a06dffbff5fe3c97ffc71bbbd9d6dcd9ac)), closes [#1433](https://github.com/fleetyards/fleetyards/issues/1433)

## [4.10.0](https://github.com/fleetyards/fleetyards/compare/v4.9.3...v4.10.0) (2021-04-15)


### Features

* **2fa:** for frontend and admin users ([#163](https://github.com/fleetyards/fleetyards/issues/163)) ([3cb24c1](https://github.com/fleetyards/fleetyards/commit/3cb24c1a8a3f5644fe4bfe1cf84dc1f869785714))
* fleet invites ([#1400](https://github.com/fleetyards/fleetyards/issues/1400)) ([270865b](https://github.com/fleetyards/fleetyards/commit/270865b3ef8eae8019a742d218135177df49cc2a))
* public urls refactor ([e8f226e](https://github.com/fleetyards/fleetyards/commit/e8f226e2bc057c70a64f22365789de3d11543721))
* update invite url modal ([34d07a3](https://github.com/fleetyards/fleetyards/commit/34d07a32b1da977b7569a9037d58763800e3ccaf))
* update invite url modal ([82b3853](https://github.com/fleetyards/fleetyards/commit/82b3853dc7078d3617d855c0936c58199f723edc))


### Bug Fixes

* audit issue ([3a5805f](https://github.com/fleetyards/fleetyards/commit/3a5805fe897a0e648a63b6662180d223c90adb30))
* e2e specs ([1d937af](https://github.com/fleetyards/fleetyards/commit/1d937afc793d74f95070968032fe262149b1a05a))
* fid validation ([8e5922c](https://github.com/fleetyards/fleetyards/commit/8e5922c7efc0a28aea2f423e9d72f8d4982b5fc1))
* fleet check ([f5042a6](https://github.com/fleetyards/fleetyards/commit/f5042a61a4376638ed57348bb65c13ec50d3c58b))
* yarn audit issue ([5ab589e](https://github.com/fleetyards/fleetyards/commit/5ab589e200a3042b76477b5b3b45a0eeb601e125))

### [4.9.3](https://github.com/fleetyards/fleetyards/compare/v4.9.2...v4.9.3) (2021-03-13)

### [4.9.2](https://github.com/fleetyards/fleetyards/compare/v4.9.1...v4.9.2) (2021-03-13)

### [4.9.1](https://github.com/fleetyards/fleetyards/compare/v4.9.0...v4.9.1) (2021-03-13)


### Bug Fixes

* dropdown menues ([877e606](https://github.com/fleetyards/fleetyards/commit/877e60650f5a8fdd6e1f1c7d135cd1ef409dc37e))
* naming modal ([6196bbd](https://github.com/fleetyards/fleetyards/commit/6196bbdc9ab294c84aaee0597182919be7abcf69))

## [4.9.0](https://github.com/fleetyards/fleetyards/compare/v4.8.1...v4.9.0) (2021-03-12)


### Features

* vehicle context menu for list view ([6c4c0d8](https://github.com/fleetyards/fleetyards/commit/6c4c0d86b025d4476709fa0a5098f4871d6db8ea))


### Bug Fixes

* context menu ([29e8131](https://github.com/fleetyards/fleetyards/commit/29e81315ad8e26abfb8a8a1b924d7e46b1445d46))
* mail templates ([9ab67d6](https://github.com/fleetyards/fleetyards/commit/9ab67d64f04ad6254450e01dd1995a0c22e30bbf))
* model variants ([6b0dd68](https://github.com/fleetyards/fleetyards/commit/6b0dd6802f328f27083b229a65e996ecffaed2cc))

### [4.8.1](https://github.com/fleetyards/fleetyards/compare/v4.8.0...v4.8.1) (2021-03-12)


### Bug Fixes

* owners on fleet page ([310323b](https://github.com/fleetyards/fleetyards/commit/310323bf40092e60d9042a13c220d309bede2bcb))

## [4.8.0](https://github.com/fleetyards/fleetyards/compare/v4.7.3...v4.8.0) (2021-03-12)


### Features

* add new context menu for vehicles ([6daa224](https://github.com/fleetyards/fleetyards/commit/6daa22419c15eb0840f5bdcf4bcb3ff472ce52de))
* add serial to vehicles ([ffc4c4f](https://github.com/fleetyards/fleetyards/commit/ffc4c4f0d6888056f805298b663b190f47a8c37d))


### Bug Fixes

* audit issue ([e13a7cb](https://github.com/fleetyards/fleetyards/commit/e13a7cbd41088b8a6b3fd78b5f187bbda9499511))
* e2e tests ([1910eb2](https://github.com/fleetyards/fleetyards/commit/1910eb26d76d0ac2ee854c0856f8dec70f2c007b))
* email template header ([62c9566](https://github.com/fleetyards/fleetyards/commit/62c95667e00c4650fa5a790047a69291d44e6e49))
* fleet ship owners ([a550ef8](https://github.com/fleetyards/fleetyards/commit/a550ef80c2c75325ecf5a4649f98da08e8319e16))

### [4.7.3](https://github.com/fleetyards/fleetyards/compare/v4.7.2...v4.7.3) (2021-03-01)


### Bug Fixes

* committed flag ([0020300](https://github.com/fleetyards/fleetyards/commit/00203003e06ef33ba9ca742f62705335db4cd353))

### [4.7.2](https://github.com/fleetyards/fleetyards/compare/v4.7.1...v4.7.2) (2021-03-01)


### Bug Fixes

* commited flag ([5e20ca3](https://github.com/fleetyards/fleetyards/commit/5e20ca37c954c48564a511d6b45eb42f04455c5e))

### [4.7.1](https://github.com/fleetyards/fleetyards/compare/v4.7.0...v4.7.1) (2021-03-01)


### Bug Fixes

* roadmap worker ([07b801c](https://github.com/fleetyards/fleetyards/commit/07b801c13fa638b61ef5593c27f52ce1abde5415))

## [4.7.0](https://github.com/fleetyards/fleetyards/compare/v4.6.8...v4.7.0) (2021-03-01)


### Features

* add owners for grouped fleet view ([#1287](https://github.com/fleetyards/fleetyards/issues/1287)) ([c4051a9](https://github.com/fleetyards/fleetyards/commit/c4051a9b35eb346b91254fc911ba67feaeb233d4))


### Bug Fixes

* specs ([dbd9838](https://github.com/fleetyards/fleetyards/commit/dbd9838b1360ad668e8d813cc691aa08d65138d2))
* vue-router deprecations ([a12a794](https://github.com/fleetyards/fleetyards/commit/a12a794d54e52bdb02e1a262a90216cbe2b920c0))

### [4.6.8](https://github.com/fleetyards/fleetyards/compare/v4.6.6...v4.6.8) (2021-02-11)

### [4.6.7](https://github.com/fleetyards/fleetyards/compare/v4.6.6...v4.6.7) (2021-02-11)

### [4.6.6](https://github.com/fleetyards/fleetyards/compare/v4.6.5...v4.6.6) (2021-02-06)


### Bug Fixes

* admin station image upload ([9455083](https://github.com/fleetyards/fleetyards/commit/94550830360ca73858be5abe670197d2782402c4))

### [4.6.5](https://github.com/fleetyards/fleetyards/compare/v4.6.4...v4.6.5) (2021-01-31)


### Bug Fixes

* model detail image ([24cf230](https://github.com/fleetyards/fleetyards/commit/24cf230f76156f209a5a37c9a3fe206926954c7d))
* roadmap loader ([fafad58](https://github.com/fleetyards/fleetyards/commit/fafad584ffa80491b9cc24c57cc425e14135e491))

### [4.6.4](https://github.com/fleetyards/fleetyards/compare/v4.6.3...v4.6.4) (2021-01-30)


### Bug Fixes

* roadmap release description ([f4991cd](https://github.com/fleetyards/fleetyards/commit/f4991cd4eca34a45945759051a000ba787dd4762))

### [4.6.3](https://github.com/fleetyards/fleetyards/compare/v4.6.2...v4.6.3) (2021-01-27)


### Bug Fixes

* roadmap loader ([7b0c42b](https://github.com/fleetyards/fleetyards/commit/7b0c42b0a82718233cd4a8e559789f21e52b2ce5))

### [4.6.2](https://github.com/fleetyards/fleetyards/compare/v4.6.1...v4.6.2) (2021-01-27)

### [4.6.1](https://github.com/fleetyards/fleetyards/compare/v4.6.0...v4.6.1) (2021-01-24)

## [4.6.0](https://github.com/fleetyards/fleetyards/compare/v4.5.0...v4.6.0) (2021-01-24)


### Features

* update hangar header ([7d576a3](https://github.com/fleetyards/fleetyards/commit/7d576a3d68afcd522e428912535bd790e33d655b))


### Bug Fixes

* mail asset urls ([d5dbaa0](https://github.com/fleetyards/fleetyards/commit/d5dbaa0f5d50455b414d8c32463b0558fc3de01b))
* update hangar groups ([cc5251a](https://github.com/fleetyards/fleetyards/commit/cc5251ada86183c3a1768473171c816703bbb0e5))

## [4.5.0](https://github.com/fleetyards/fleetyards/compare/v4.4.18...v4.5.0) (2021-01-18)


### Features

* progress tracker ([91a0662](https://github.com/fleetyards/fleetyards/commit/91a066248d25da3bacc5c592c5fd96c56e6eae1d))
* update email templates ([a36f06e](https://github.com/fleetyards/fleetyards/commit/a36f06eb53b37f6f7d17c43d50536528734430b7))


### Bug Fixes

* typo migration ([2571e52](https://github.com/fleetyards/fleetyards/commit/2571e52aca7193bf7ad4c1515696018c40f57241))

### [4.4.18](https://github.com/fleetyards/fleetyards/compare/v4.4.17...v4.4.18) (2020-12-26)


### Bug Fixes

* compare models labels ([d417531](https://github.com/fleetyards/fleetyards/commit/d41753148d7b9643dfa370896e179d32800a1d3c))

### [4.4.17](https://github.com/fleetyards/fleetyards/compare/v4.4.16...v4.4.17) (2020-12-25)

### [4.4.16](https://github.com/fleetyards/fleetyards/compare/v4.4.15...v4.4.16) (2020-12-25)


### Bug Fixes

* add missing mailer template ([f216c29](https://github.com/fleetyards/fleetyards/commit/f216c295dc3f2383b12ed12bed29a25afb26714b))
* saveguard refs access ([765bd82](https://github.com/fleetyards/fleetyards/commit/765bd8253e3ddd463a2107a2f255d43e88da7f85))
* trade route key ([f2125d1](https://github.com/fleetyards/fleetyards/commit/f2125d1dc80dd25f0fd40262c2e0ff35473b04e5))
* try to create a unique key for progress tracker items ([6c6811b](https://github.com/fleetyards/fleetyards/commit/6c6811b93d6cc6fc1cde55aff5e7c4037e24d6c5))

### [4.4.15](https://github.com/fleetyards/fleetyards/compare/v4.4.14...v4.4.15) (2020-12-25)

### [4.4.14](https://github.com/fleetyards/fleetyards/compare/v4.4.13...v4.4.14) (2020-12-21)

### [4.4.13](https://github.com/fleetyards/fleetyards/compare/v4.4.12...v4.4.13) (2020-12-21)


### Bug Fixes

* hardpoint loader ([92b5936](https://github.com/fleetyards/fleetyards/commit/92b5936f8b89de56b2201ba1f0ab7ff0c6f140ba))
* specs ([494e3e1](https://github.com/fleetyards/fleetyards/commit/494e3e1d1fd28c82a639306d2deca9be5e89cd67))

### [4.4.12](https://github.com/fleetyards/fleetyards/compare/v4.4.11...v4.4.12) (2020-12-20)

### [4.4.11](https://github.com/fleetyards/fleetyards/compare/v4.4.10...v4.4.11) (2020-12-20)


### Bug Fixes

* sc data loader ([eb7846c](https://github.com/fleetyards/fleetyards/commit/eb7846ca78b8faab443a3aa7a8783e1d3885d2dc))
* trader routes prices ([3033926](https://github.com/fleetyards/fleetyards/commit/303392694119689bbadb07408e6165b7ae8fd9b1))

### [4.4.10](https://github.com/fleetyards/fleetyards/compare/v4.4.9...v4.4.10) (2020-12-20)


### Bug Fixes

* fleet and hangar stats for ships by manufacturer ([6b35a66](https://github.com/fleetyards/fleetyards/commit/6b35a667ebd9d5c54dd94f3db606718243dbd19f))
* trade route worker ([c7c22af](https://github.com/fleetyards/fleetyards/commit/c7c22af6a32c29f279bf0f249c3aa9d0cab437df))

### [4.4.9](https://github.com/fleetyards/fleetyards/compare/v4.4.8...v4.4.9) (2020-12-03)


### Bug Fixes

* pagination on fleets ([ba17547](https://github.com/fleetyards/fleetyards/commit/ba17547025495585d6815bb19693cd0b2d1ddfef))

### [4.4.8](https://github.com/fleetyards/fleetyards/compare/v4.4.7...v4.4.8) (2020-11-27)

### [4.4.7](https://github.com/fleetyards/fleetyards/compare/v4.4.6...v4.4.7) (2020-11-26)


### Bug Fixes

* privacy policy ([c11d14a](https://github.com/fleetyards/fleetyards/commit/c11d14a685084b3403590f947e0537fd5c9e00f6))
* window width on mobile ([9851a17](https://github.com/fleetyards/fleetyards/commit/9851a177adc4a57269a9202d73a4e512ccb7907a))

### [4.4.6](https://github.com/fleetyards/fleetyards/compare/v4.4.5...v4.4.6) (2020-11-25)


### Bug Fixes

* model detail ([d6a03ac](https://github.com/fleetyards/fleetyards/commit/d6a03ac660b95231c74755ae793213fb7aa36247))

### [4.4.5](https://github.com/fleetyards/fleetyards/compare/v4.4.4...v4.4.5) (2020-11-22)


### Bug Fixes

* basic metrics on model detail ([65b8ca4](https://github.com/fleetyards/fleetyards/commit/65b8ca49cf953702144d30ddaf54e7a5f16f9485))
* preconnect endpoint ([e913e8c](https://github.com/fleetyards/fleetyards/commit/e913e8cf7475da04dab92c90938b5bb35a402eb8))

### [4.4.4](https://github.com/fleetyards/fleetyards/compare/v4.4.3...v4.4.4) (2020-11-22)


### Bug Fixes

* contextMenu ref ([a00f2d5](https://github.com/fleetyards/fleetyards/commit/a00f2d5a039a28c10f37644be22bd4d734065954))
* fleet member settings ([e2981fd](https://github.com/fleetyards/fleetyards/commit/e2981fde79eeef1351d5fe8c6a1ca3a15e99e052))
* fleet membership settings ([d7bbb68](https://github.com/fleetyards/fleetyards/commit/d7bbb6857a1709be1375b4eb5d5b83968a0e5e71))
* guard router push navigation ([d6612d6](https://github.com/fleetyards/fleetyards/commit/d6612d6e4b6c68be4061de9458b48f79962334d4))
* hangar ([bfae7d8](https://github.com/fleetyards/fleetyards/commit/bfae7d82464e7f5aac6761ab6f6f48ee328267e9))
* hangar bulk edit ([207bd8f](https://github.com/fleetyards/fleetyards/commit/207bd8f4be8ea2bc16b450142f3dd0f8267048d7))
* pagination ([2d66524](https://github.com/fleetyards/fleetyards/commit/2d66524253613d97bdf8c8c7674d5063ee40b1f4))
* store images on commodity ([8249810](https://github.com/fleetyards/fleetyards/commit/82498106126b74ac6935dcc3d465dedeb5c56952))
* trade routes ([caf6fdc](https://github.com/fleetyards/fleetyards/commit/caf6fdc2cdde4a7c636d6bdb605dab3d9fad059d))

### [4.4.3](https://github.com/fleetyards/fleetyards/compare/v4.4.2...v4.4.3) (2020-11-21)


### Bug Fixes

* models loader ([24213cc](https://github.com/fleetyards/fleetyards/commit/24213ccce4ae4edc981d0d1578950253d89432d1))

### [4.4.2](https://github.com/fleetyards/fleetyards/compare/v4.4.1...v4.4.2) (2020-11-20)


### Bug Fixes

* models loader ([5a067c5](https://github.com/fleetyards/fleetyards/commit/5a067c5c1b34ff90100aae388a7a91c2449df6ca))

### [4.4.1](https://github.com/fleetyards/fleetyards/compare/v4.4.0...v4.4.1) (2020-11-20)


### Bug Fixes

* hangar fleetchart reload ([fbed950](https://github.com/fleetyards/fleetyards/commit/fbed9506b581dd6bcb64425b6e1093c0bc474647))

## [4.4.0](https://github.com/fleetyards/fleetyards/compare/v4.3.1...v4.4.0) (2020-11-18)


### Features

* add fuel capacities to models ([99cc5ff](https://github.com/fleetyards/fleetyards/commit/99cc5ff2a24c60eddc31ac2fb1ee025e3a579ceb))
* update hangar bulk actions ([462e258](https://github.com/fleetyards/fleetyards/commit/462e2586603adbd62a99cd05291c8ce246f98b77))


### Bug Fixes

* trade routes ([24edbe1](https://github.com/fleetyards/fleetyards/commit/24edbe1863ee93f9f696592cc71de3bfc9a3dce4))

### [4.3.1](https://github.com/fleetyards/fleetyards/compare/v4.3.0...v4.3.1) (2020-11-18)


### Bug Fixes

* prices on trade routes page ([11f4647](https://github.com/fleetyards/fleetyards/commit/11f464760ea2fb528a7bc904ea5d1eb917b9ca28))

## [4.3.0](https://github.com/fleetyards/fleetyards/compare/v4.2.0...v4.3.0) (2020-11-18)


### Features

* show shopping cart on mobile ([d7978e8](https://github.com/fleetyards/fleetyards/commit/d7978e8dc76d280dd1991b43677856a56a8d7886))


### Bug Fixes

* e2e specs ([92598e7](https://github.com/fleetyards/fleetyards/commit/92598e7297073b7c803e9db301a222af705f48ed))

## [4.2.0](https://github.com/fleetyards/fleetyards/compare/v4.1.3...v4.2.0) (2020-11-17)


### Features

* add refresh to shopping cart ([508ab58](https://github.com/fleetyards/fleetyards/commit/508ab58aba045b2152c3fe538992ce80446cbc13))


### Bug Fixes

* shops for models ([a8cb584](https://github.com/fleetyards/fleetyards/commit/a8cb584d6994d1c623094533799ad9a7c3f4b1d2))
* specs ([f31159f](https://github.com/fleetyards/fleetyards/commit/f31159fe92c9a6f20bf67e807e848ea0d6927f69))

### [4.1.3](https://github.com/fleetyards/fleetyards/compare/v4.1.2...v4.1.3) (2020-11-16)


### Bug Fixes

* shopping cart ([0ca6109](https://github.com/fleetyards/fleetyards/commit/0ca610976a21aea60c866131558e545d075fd79d))

### [4.1.2](https://github.com/fleetyards/fleetyards/compare/v4.1.1...v4.1.2) (2020-11-16)


### Bug Fixes

* shoppingCart ([995ede8](https://github.com/fleetyards/fleetyards/commit/995ede89f86495ee72c17d44559c89739454e47d))

### [4.1.1](https://github.com/fleetyards/fleetyards/compare/v4.1.0...v4.1.1) (2020-11-16)


### Bug Fixes

* admin api ([e3d7b71](https://github.com/fleetyards/fleetyards/commit/e3d7b712902be125750f36568d624afdb4a06b42))

## [4.1.0](https://github.com/fleetyards/fleetyards/compare/v4.0.6...v4.1.0) (2020-11-16)


### Features

* add shopping t0 ([9ca5586](https://github.com/fleetyards/fleetyards/commit/9ca5586edc3f548de91b8f8c1f747f9bd3eb1139))


### Bug Fixes

* admin shop_commodities ([cf3fc1a](https://github.com/fleetyards/fleetyards/commit/cf3fc1a319e278e677a44d9ea4ee4ccd06889f32))
* search_field in admin ([aa8af58](https://github.com/fleetyards/fleetyards/commit/aa8af581811c5b65fe66d530f688a5b7b7510800))
* specs ([e6ef5d7](https://github.com/fleetyards/fleetyards/commit/e6ef5d7553262f51c5ccdcbd9bcf6f8c5d451c1a))

### [4.0.6](https://github.com/fleetyards/fleetyards/compare/v4.0.5...v4.0.6) (2020-11-14)


### Bug Fixes

* stations ([9fe9a33](https://github.com/fleetyards/fleetyards/commit/9fe9a3343a754f97afefc51021ed172bfcc1b121))

### [4.0.5](https://github.com/fleetyards/fleetyards/compare/v4.0.4...v4.0.5) (2020-11-14)


### Bug Fixes

* station types and confirmables ([6fe5cf3](https://github.com/fleetyards/fleetyards/commit/6fe5cf3bd6bfbee2996aeead046d056e339c6cf0))

### [4.0.4](https://github.com/fleetyards/fleetyards/compare/v4.0.3...v4.0.4) (2020-11-14)

### [4.0.3](https://github.com/fleetyards/fleetyards/compare/v4.0.2...v4.0.3) (2020-11-13)

### [4.0.2](https://github.com/fleetyards/fleetyards/compare/v4.0.1...v4.0.2) (2020-11-12)


### Bug Fixes

* roadmap dont count inactive items ([9f01596](https://github.com/fleetyards/fleetyards/commit/9f01596deb8bbfcdae11ff88547ea680b8b1f67f))

### [4.0.1](https://github.com/fleetyards/fleetyards/compare/v4.0.0...v4.0.1) (2020-11-11)

## [4.0.0](https://github.com/fleetyards/fleetyards/compare/v3.82.12...v4.0.0) (2020-11-11)


### Features

* add admin view for confirmations ([1baeb1b](https://github.com/fleetyards/fleetyards/commit/1baeb1bc15b599b54fcf23a04aa32f321bbaba17))
* add per page selector for hangar ([374f5cf](https://github.com/fleetyards/fleetyards/commit/374f5cf75da3c9c34e018d450ed6f6608d2316bd))
* add refinery flag to shops ([647edb1](https://github.com/fleetyards/fleetyards/commit/647edb186c0051a222632f5172f9a1cd6c802840))
* add refinery info to stations ([9705ed7](https://github.com/fleetyards/fleetyards/commit/9705ed702737f1b470d571e91ba7368e19dc9b73))
* add submit prices modal and show average prices on trade routes ([d9e8c70](https://github.com/fleetyards/fleetyards/commit/d9e8c704cbe5272dba94775d26729c00fc139ac9))
* hangar list add bulk actions ([2ab0269](https://github.com/fleetyards/fleetyards/commit/2ab02698390a532b261b3f80c55c1157afa91547))
* hangar list add bulk actions ([718814e](https://github.com/fleetyards/fleetyards/commit/718814ebfe422a498e7bb48835753c424786154a))
* update microtech seeds ([23d16b2](https://github.com/fleetyards/fleetyards/commit/23d16b2d732ff6e9292b8cddbf96bb437f03a948))


### Bug Fixes

* admin styles ([02d8f91](https://github.com/fleetyards/fleetyards/commit/02d8f913461d55ddaa552217dd5675691e8e166a))
* ci config for es image ([138d893](https://github.com/fleetyards/fleetyards/commit/138d893d5547df322f9ecc3586871f9bee88c465))
* compare floating headlines ([1b8981a](https://github.com/fleetyards/fleetyards/commit/1b8981a2c08b7cf84ea90825208757fb9f98a065))
* devise settings ([697c541](https://github.com/fleetyards/fleetyards/commit/697c541ea85826f110aab02cf9668c28a6377c28))
* e2e specs ([ed3f340](https://github.com/fleetyards/fleetyards/commit/ed3f340d337e8fd852de713e173672414d4a8c0e))
* hangargroups visibility ([2954e1b](https://github.com/fleetyards/fleetyards/commit/2954e1b776fd93e9c36a16ffecc228585bcf4eb6)), closes [#1275](https://github.com/fleetyards/fleetyards/issues/1275)
* hide details button in hangar on list view ([73ea488](https://github.com/fleetyards/fleetyards/commit/73ea4882c17072570b30a5c2c8e441fd4cb54d63))
* hide price if a station has no shops ([a6fe668](https://github.com/fleetyards/fleetyards/commit/a6fe668120edcda7e48f3b55d2beab90e1b20a42))
* model loader and add hartpoint details to model detail ([7d80d27](https://github.com/fleetyards/fleetyards/commit/7d80d2739a3b820c02e7b4e22a20cc504db27b82))
* navigation ([7d64286](https://github.com/fleetyards/fleetyards/commit/7d64286580898ec5a8c07e7359c7afbffa9b7682))
* navigation ([e7ebb7e](https://github.com/fleetyards/fleetyards/commit/e7ebb7eccaf6618e692cc0d7d5c4950b1c80f732))
* pagination on public hangar ([805d9cb](https://github.com/fleetyards/fleetyards/commit/805d9cbf99dbfee6383e5324bdf78f0f105cf77d))
* photoswipe color ([dd4bebf](https://github.com/fleetyards/fleetyards/commit/dd4bebfa51d5c2704040b1b8a459943caaeded25))
* roadmap and update shop_commodities on new prices ([ee07b0b](https://github.com/fleetyards/fleetyards/commit/ee07b0badccabfefdcfcd9e1b356a4b852b2f5da))
* roadmaps ([8f33d66](https://github.com/fleetyards/fleetyards/commit/8f33d669bdcc092a9a1d2c95d7b404dcece1fe2e))
* seeds ([a3a76db](https://github.com/fleetyards/fleetyards/commit/a3a76db050e06e30fe14d2fc3626b3fe09157805))
* seeds ([cf9f111](https://github.com/fleetyards/fleetyards/commit/cf9f11133f0fc7d41c85af89db4394c854f17111))
* spec seeds ([2ec0494](https://github.com/fleetyards/fleetyards/commit/2ec0494e9ed4fd6df1fa58486c7e99a50cb66f29))
* specs and linting ([f9d3d8e](https://github.com/fleetyards/fleetyards/commit/f9d3d8e8c7214b82ae9bb9a94498cc256214145c))
* support button ([d3ed74d](https://github.com/fleetyards/fleetyards/commit/d3ed74d3300df2d854f6d7ea0cd3d5b60012fe9a))
* tradeRoutes ([5ef4a3f](https://github.com/fleetyards/fleetyards/commit/5ef4a3fab786311ef6d7706a975631c6878b3dc9))

### [3.82.12](https://github.com/fleetyards/fleetyards/compare/v3.82.11...v3.82.12) (2020-10-23)


### Bug Fixes

* session logout ([5828e85](https://github.com/fleetyards/fleetyards/commit/5828e853b802da52307c5cfc3d5ee8723e8db803))

### [3.82.11](https://github.com/fleetyards/fleetyards/compare/v3.82.10...v3.82.11) (2020-10-23)


### Bug Fixes

* local session store ([e4398f9](https://github.com/fleetyards/fleetyards/commit/e4398f9a77798245a8e513a3dfa994c7e4c1108b))
* session_storage ([21bc631](https://github.com/fleetyards/fleetyards/commit/21bc63196d0edd8192a930d54ec11767fbaca020))
* session-store ([1b10025](https://github.com/fleetyards/fleetyards/commit/1b10025015a6b9c784bf748363591808f9f84cdc))

### [3.82.10](https://github.com/fleetyards/fleetyards/compare/v3.82.9...v3.82.10) (2020-10-22)

### [3.82.9](https://github.com/fleetyards/fleetyards/compare/v3.82.8...v3.82.9) (2020-10-22)

### [3.82.8](https://github.com/fleetyards/fleetyards/compare/v3.82.7...v3.82.8) (2020-10-21)


### Bug Fixes

* e2e specs ([0619aa1](https://github.com/fleetyards/fleetyards/commit/0619aa1555a94a33a5e5e616dd5062ffed90ab78))

### [3.82.7](https://github.com/fleetyards/fleetyards/compare/v3.82.6...v3.82.7) (2020-10-19)


### Bug Fixes

* admin users ([b75800f](https://github.com/fleetyards/fleetyards/commit/b75800f6a25033aad9ae744861efbc66a95bb5ce))

### [3.82.6](https://github.com/fleetyards/fleetyards/compare/v3.82.5...v3.82.6) (2020-10-19)

### [3.82.5](https://github.com/fleetyards/fleetyards/compare/v3.82.4...v3.82.5) (2020-10-18)


### Bug Fixes

* admin nav ([cdd4059](https://github.com/fleetyards/fleetyards/commit/cdd405927e34c3057d2de6757cf176c8334da94f))

### [3.82.4](https://github.com/fleetyards/fleetyards/compare/v3.82.3...v3.82.4) (2020-10-18)


### Bug Fixes

* admin funktions ([53a4aa5](https://github.com/fleetyards/fleetyards/commit/53a4aa5266e121bb7b79d91ff6b34d5c95a63e8e))

### [3.82.3](https://github.com/fleetyards/fleetyards/compare/v3.82.2...v3.82.3) (2020-10-18)

### [3.82.2](https://github.com/fleetyards/fleetyards/compare/v3.82.1...v3.82.2) (2020-10-17)

### [3.82.1](https://github.com/fleetyards/fleetyards/compare/v3.82.0...v3.82.1) (2020-10-17)


### Bug Fixes

* admin search params ([d18fe14](https://github.com/fleetyards/fleetyards/commit/d18fe148a3f19686d4140dfe12cf71f959077762))
* fleetchart slider ([5f2200f](https://github.com/fleetyards/fleetyards/commit/5f2200f72166dfd7048dcc0d735d89142cd0b59f))

## [3.82.0](https://github.com/fleetyards/fleetyards/compare/v3.81.3...v3.82.0) (2020-10-17)


### Features

* add status color for fleetcharts ([17643ef](https://github.com/fleetyards/fleetyards/commit/17643ef20002a73e77dd2a1190f563aeed452c8d))


### Bug Fixes

* images ([9d61818](https://github.com/fleetyards/fleetyards/commit/9d61818c16c451ee37cce020118986927aacdc5b))

### [3.81.3](https://github.com/fleetyards/fleetyards/compare/v3.81.2...v3.81.3) (2020-10-16)


### Bug Fixes

* embed api client ([638417d](https://github.com/fleetyards/fleetyards/commit/638417d6ccb07eb1923176ba0386a669fe4d4e7a))

### [3.81.2](https://github.com/fleetyards/fleetyards/compare/v3.81.1...v3.81.2) (2020-10-16)

### [3.81.1](https://github.com/fleetyards/fleetyards/compare/v3.81.0...v3.81.1) (2020-10-15)


### Bug Fixes

* modal animations ([30f38b5](https://github.com/fleetyards/fleetyards/commit/30f38b50e5e09726e6adefc7e82020020f0b179b))

## [3.81.0](https://github.com/fleetyards/fleetyards/compare/v3.80.16...v3.81.0) (2020-10-14)


### Features

* rework Modals and update AddToHangar Workflow ([#1266](https://github.com/fleetyards/fleetyards/issues/1266)) ([572e91d](https://github.com/fleetyards/fleetyards/commit/572e91d8143c96f8237c6a619e333d82d9a8a130))


### Bug Fixes

* addToHangar on mobile ([261bf6c](https://github.com/fleetyards/fleetyards/commit/261bf6c38b310e6676c115a8d9841c667ac8aca1))

### [3.80.16](https://github.com/fleetyards/fleetyards/compare/v3.80.15...v3.80.16) (2020-10-12)


### Bug Fixes

* trade routes quick filter ([839f50c](https://github.com/fleetyards/fleetyards/commit/839f50cf178bf22483031fee4efcc90c6836781d))

### [3.80.15](https://github.com/fleetyards/fleetyards/compare/v3.80.14...v3.80.15) (2020-10-11)


### Bug Fixes

* roadmap responsive classes ([73b8f67](https://github.com/fleetyards/fleetyards/commit/73b8f67488270edf82f839a1d6c277597f782c08))

### [3.80.14](https://github.com/fleetyards/fleetyards/compare/v3.80.13...v3.80.14) (2020-10-10)


### Bug Fixes

* fade-list transitions ([8f278c2](https://github.com/fleetyards/fleetyards/commit/8f278c2690321aabfb0e4a9d955ad2dc7a8eec35))

### [3.80.13](https://github.com/fleetyards/fleetyards/compare/v3.80.12...v3.80.13) (2020-10-08)


### Bug Fixes

* images ([9a5fc9b](https://github.com/fleetyards/fleetyards/commit/9a5fc9b03bdaa819d9893db0bb2a8f11e0114e72))

### [3.80.12](https://github.com/fleetyards/fleetyards/compare/v3.80.11...v3.80.12) (2020-10-08)


### Bug Fixes

* images ([f60d118](https://github.com/fleetyards/fleetyards/commit/f60d118b9e6d382f3fb1fa71d9fce0ae7abb65d7))

### [3.80.11](https://github.com/fleetyards/fleetyards/compare/v3.80.10...v3.80.11) (2020-10-08)


### Bug Fixes

* page actions ([6d24620](https://github.com/fleetyards/fleetyards/commit/6d246202c1ccf3285776081283ad6a9032356c05))

### [3.80.10](https://github.com/fleetyards/fleetyards/compare/v3.80.9...v3.80.10) (2020-10-08)


### Bug Fixes

* admin image row ([132ffaa](https://github.com/fleetyards/fleetyards/commit/132ffaa301f935123867f77fb9865e769e835b3b))

### [3.80.9](https://github.com/fleetyards/fleetyards/compare/v3.80.8...v3.80.9) (2020-10-07)


### Bug Fixes

* sidekiq admin dashboard ([a60338a](https://github.com/fleetyards/fleetyards/commit/a60338ab24d0c5ec19503d254022cd4d87e515b0))

### [3.80.8](https://github.com/fleetyards/fleetyards/compare/v3.80.7...v3.80.8) (2020-09-25)


### Bug Fixes

* filtergroup ([7c20b09](https://github.com/fleetyards/fleetyards/commit/7c20b094a10272d3c18608145569a79ac6be78f3))
* specs ([708ff4f](https://github.com/fleetyards/fleetyards/commit/708ff4ff6907d867ae0cb2a62eb3599a1149d131))
* stations detail ([35a16af](https://github.com/fleetyards/fleetyards/commit/35a16afcc07bab0648b0d7b677eaeb0ad9a66527))
* traderoutes filters ([750f899](https://github.com/fleetyards/fleetyards/commit/750f8990090190be5bfce444da2787a5790d3952))

### [3.80.7](https://github.com/fleetyards/fleetyards/compare/v3.80.6...v3.80.7) (2020-09-24)


### Bug Fixes

* fleetchart ([1527205](https://github.com/fleetyards/fleetyards/commit/1527205d6eec47c6a87ee2c2034dad8a60e6eaa7))

### [3.80.6](https://github.com/fleetyards/fleetyards/compare/v3.80.5...v3.80.6) (2020-09-24)


### Bug Fixes

* filtergroup ([be15aec](https://github.com/fleetyards/fleetyards/commit/be15aec953396c743024d4e3f8060559f03348f4))
* scrollToAnchor ([ba66e20](https://github.com/fleetyards/fleetyards/commit/ba66e20eeb67b8ce9383f69f3d174756b689b6cc))

### [3.80.5](https://github.com/fleetyards/fleetyards/compare/v3.80.4...v3.80.5) (2020-09-24)


### Bug Fixes

* filters ([37973fc](https://github.com/fleetyards/fleetyards/commit/37973fca96889bc8af92321a7c8fcb1e3452c03a))

### [3.80.4](https://github.com/fleetyards/fleetyards/compare/v3.80.3...v3.80.4) (2020-09-24)


### Bug Fixes

* subscriptions ([5fccd18](https://github.com/fleetyards/fleetyards/commit/5fccd18cc5db3d1603e317f68706dab589feee01))

### [3.80.3](https://github.com/fleetyards/fleetyards/compare/v3.80.2...v3.80.3) (2020-09-21)


### Bug Fixes

* asset host ([a21af0d](https://github.com/fleetyards/fleetyards/commit/a21af0d589315a6e09df70da9de81a2d85cc9251))

### [3.80.2](https://github.com/fleetyards/fleetyards/compare/v3.80.1...v3.80.2) (2020-09-20)


### Bug Fixes

* pagination for fleet vehicles ([5c1fe3c](https://github.com/fleetyards/fleetyards/commit/5c1fe3c4ae72b9cfbbd858af6b797aafc9533af7))

### [3.80.1](https://github.com/fleetyards/fleetyards/compare/v3.80.0...v3.80.1) (2020-09-11)


### Bug Fixes

* e2e specs for images ([ce2274e](https://github.com/fleetyards/fleetyards/commit/ce2274e14d635af8eb24fa2b09725d622160a640))
* node-fetch ([6ff0ba9](https://github.com/fleetyards/fleetyards/commit/6ff0ba9570f81a67c26078bbf0ffed22a1a39217))

## [3.80.0](https://github.com/fleetyards/fleetyards/compare/v3.79.7...v3.80.0) (2020-09-11)


### Features

* owner label adjustments ([47a21d7](https://github.com/fleetyards/fleetyards/commit/47a21d7894fc7c12553a1ef5e871babdc2339336))
* show owner on fleets page ([6911d6c](https://github.com/fleetyards/fleetyards/commit/6911d6c429f948197fc491e4a0c60480321faa92))


### Bug Fixes

* bootstrap 4 alignment ([ef83885](https://github.com/fleetyards/fleetyards/commit/ef838850b441c16bd561c23798f8e3cca55f37f1))
* ci ([6109f44](https://github.com/fleetyards/fleetyards/commit/6109f442718194e1a6af3ea15f62501113025d52))
* cookie samesite setting ([65fde1a](https://github.com/fleetyards/fleetyards/commit/65fde1a7f246fce1d07dbb26cb60645a2465e331))
* e2e cookies ([b1514f9](https://github.com/fleetyards/fleetyards/commit/b1514f92ccbab704723abcf208a39ab7fe28a2aa))
* e2e specs ([4ba491d](https://github.com/fleetyards/fleetyards/commit/4ba491d0c803775f984bd5951d3330061c396c0b))
* e2e specs ([0625abb](https://github.com/fleetyards/fleetyards/commit/0625abbea3f191d4182d9c66129cbe7b9890a4dc))
* e2e tests for signup ([2e66b04](https://github.com/fleetyards/fleetyards/commit/2e66b04571b979603771a04b5b905a48366af156))
* filtered header and background animation ([b0c414a](https://github.com/fleetyards/fleetyards/commit/b0c414ac0f5f8915206e4871073668e243b98299))
* fleets reload after grouped change ([887ff39](https://github.com/fleetyards/fleetyards/commit/887ff39f8ead8e17fc1a43b20758fe03686c3994))
* form input padding ([62d53b2](https://github.com/fleetyards/fleetyards/commit/62d53b24e1413d9156805ea6fb91a17acdf0cbba))
* form input type check ([36d3bdb](https://github.com/fleetyards/fleetyards/commit/36d3bdb0f46c3540a89c4914bb4be917fc16d6d3))
* image galleries ([774a4ff](https://github.com/fleetyards/fleetyards/commit/774a4ff600f3cc920f524549a1f01db13d3b4e22))
* iphone camera bump margin ([414c4db](https://github.com/fleetyards/fleetyards/commit/414c4dbe551fa290197dbf46f9eab11765fdb66e))
* linting ([dcbbd0e](https://github.com/fleetyards/fleetyards/commit/dcbbd0e6b0ced092444d9fe7a115d92f892d72c5))
* mailer preview class ([143eaa0](https://github.com/fleetyards/fleetyards/commit/143eaa0740203acad6e96a63f1e376d56c436512))
* model panel subline ([71ef060](https://github.com/fleetyards/fleetyards/commit/71ef0602b5ae6cba66680004032f9a0787dbd42f))
* remove unused require ([6a0e93a](https://github.com/fleetyards/fleetyards/commit/6a0e93ac9f37ff1356ff54c19f81594ede5b12a0))
* service-worker ([338c03d](https://github.com/fleetyards/fleetyards/commit/338c03de572c70bf91540ae99319fded092f51e3))
* service-worker ([edecf83](https://github.com/fleetyards/fleetyards/commit/edecf83cccae74bdba2b810af956c454ea0be567))
* service-worker scope ([7b8ae95](https://github.com/fleetyards/fleetyards/commit/7b8ae95cd649d8da8899f84607ecf3cd4acb2d96))
* specs ([2ef9b23](https://github.com/fleetyards/fleetyards/commit/2ef9b23c745802b805e12eb0c28fc185c909e6e9))
* specs ([a00bc52](https://github.com/fleetyards/fleetyards/commit/a00bc52892f04b97d4e3fb940f560034c5ad1b0e))
* specs ([4d60e89](https://github.com/fleetyards/fleetyards/commit/4d60e89cc96b00f82deae83ea1b671103000b0ec))
* webpacker config ([e342321](https://github.com/fleetyards/fleetyards/commit/e342321f5445d23b46d3a9999bfb038cd216b2f2))
* **fleet:** hide deeplinks and load statistics after fleet is loaded ([a5c2cc7](https://github.com/fleetyards/fleetyards/commit/a5c2cc7ba939a2a1bde5a90e87512609c86ca044))


### Refactorings

* hangar and migrate components to typescript ([#1225](https://github.com/fleetyards/fleetyards/issues/1225)) ([8ac9a72](https://github.com/fleetyards/fleetyards/commit/8ac9a72e5c12cdfcb631b42ba40e42a7f0fe7bef))

### [3.79.7](https://github.com/fleetyards/fleetyards/compare/v3.79.6...v3.79.7) (2020-06-06)


### Bug Fixes

* fleetchart screenshot ([7035250](https://github.com/fleetyards/fleetyards/commit/70352506edac7e4ad0bbb1b58d3f867fc7e86ced))

### [3.79.6](https://github.com/fleetyards/fleetyards/compare/v3.79.5...v3.79.6) (2020-06-03)

### [3.79.5](https://github.com/fleetyards/fleetyards/compare/v3.79.4...v3.79.5) (2020-06-02)

### [3.79.4](https://github.com/fleetyards/fleetyards/compare/v3.79.3...v3.79.4) (2020-06-02)


### Bug Fixes

* **fleet:** model count ([4d4e5c1](https://github.com/fleetyards/fleetyards/commit/4d4e5c13f26794ca4b1e5d06f0b5faa642343377))

### [3.79.3](https://github.com/fleetyards/fleetyards/compare/v3.79.2...v3.79.3) (2020-06-01)


### Bug Fixes

* fleet manufacturers ([9e1302d](https://github.com/fleetyards/fleetyards/commit/9e1302db960b598fd71f5f420a18b346d888bb47))

### [3.79.2](https://github.com/fleetyards/fleetyards/compare/v3.79.1...v3.79.2) (2020-05-31)

### [3.79.1](https://github.com/fleetyards/fleetyards/compare/v3.79.0...v3.79.1) (2020-05-31)

## [3.79.0](https://github.com/fleetyards/fleetyards/compare/v3.78.2...v3.79.0) (2020-05-31)


### Features

* loaners display for fix ([479b62f](https://github.com/fleetyards/fleetyards/commit/479b62f5e6ab5f405667b4d0eca7a9d5ce768d0e))
* loaners display for fix ([55ab119](https://github.com/fleetyards/fleetyards/commit/55ab1192d0e6abcf98d82b8d3bcf2503d50f56b6))


### Bug Fixes

* default for ships filter on fleet membership ([03247c5](https://github.com/fleetyards/fleetyards/commit/03247c505fc1328229d891b8e66e5b9af8984715))
* **fleets:** hide loaners in ship list ([686f904](https://github.com/fleetyards/fleetyards/commit/686f90412102e7b6f146b53475044469afadadf1))
* has_many for model_paints to nullify vehicles model_paint_id ([5bc0fd1](https://github.com/fleetyards/fleetyards/commit/5bc0fd1852184548c5451f0e41cf3e1b8fa12cc4))

### [3.78.2](https://github.com/fleetyards/fleetyards/compare/v3.78.1...v3.78.2) (2020-05-28)


### Bug Fixes

* dependabot bundle install ([a20f37f](https://github.com/fleetyards/fleetyards/commit/a20f37fb21e1ca0cce220ac8d42e11e5877c78db))
* **embed:** update grouping for fleetview by usernames ([e75e066](https://github.com/fleetyards/fleetyards/commit/e75e06691aa1caf68253bf1ea2d8c1f47679c1dc))

### [3.78.1](https://github.com/fleetyards/fleetyards/compare/v3.78.0...v3.78.1) (2020-05-28)


### Bug Fixes

* embed fleetview ([1f398a4](https://github.com/fleetyards/fleetyards/commit/1f398a49223766c9ca448e3ff08b2c6c5d36b2d8))

## [3.78.0](https://github.com/fleetyards/fleetyards/compare/v3.77.2...v3.78.0) (2020-05-28)


### Features

* allow fleetchart image override by paint ([f93650e](https://github.com/fleetyards/fleetyards/commit/f93650e892c672c29af82d13e4fb58f3b56161ba))

### [3.77.2](https://github.com/fleetyards/fleetyards/compare/v3.77.1...v3.77.2) (2020-05-28)

### [3.77.1](https://github.com/fleetyards/fleetyards/compare/v3.77.0...v3.77.1) (2020-05-28)


### Bug Fixes

* initialize users array for embed ([39b3560](https://github.com/fleetyards/fleetyards/commit/39b3560a51fae3df1da635c1e95e7426be2ea32a))

## [3.77.0](https://github.com/fleetyards/fleetyards/compare/v3.76.10...v3.77.0) (2020-05-26)


### Features

* **fleets:** give members more control over what ships to add to a fleet ([d055007](https://github.com/fleetyards/fleetyards/commit/d0550071cadc1def5a6dc76f9fa76c55cef66c51))


### Bug Fixes

* fleet membership enum ([c1ce9b2](https://github.com/fleetyards/fleetyards/commit/c1ce9b21ed6c296ddd30b6c20a5b06a784e4686b))
* puma upgrade ([b64ec24](https://github.com/fleetyards/fleetyards/commit/b64ec240f4c8eaeec501f9d95ce814e15d359a8c))

### [3.76.10](https://github.com/fleetyards/fleetyards/compare/v3.76.9...v3.76.10) (2020-05-22)


### Bug Fixes

* partials.scss ([f3448d6](https://github.com/fleetyards/fleetyards/commit/f3448d6e01cfc897e7bd044f8fee0182ff93400f))

### [3.76.9](https://github.com/fleetyards/fleetyards/compare/v3.76.8...v3.76.9) (2020-05-22)

### [3.76.8](https://github.com/fleetyards/fleetyards/compare/v3.76.7...v3.76.8) (2020-05-22)


### Bug Fixes

* export should concider applied filters ([0ab191c](https://github.com/fleetyards/fleetyards/commit/0ab191c33f1760cd05e1e7fba9ff93c2bea8d4d0))

### [3.76.7](https://github.com/fleetyards/fleetyards/compare/v3.76.6...v3.76.7) (2020-05-21)


### Bug Fixes

* public hangar ([9c07d53](https://github.com/fleetyards/fleetyards/commit/9c07d536e87d822e20b46b6b5c8d95badd82ce24))
* starship42 links for paints ([e249043](https://github.com/fleetyards/fleetyards/commit/e249043aedbb1001eb478b02c10fe2133335683c))

### [3.76.6](https://github.com/fleetyards/fleetyards/compare/v3.76.5...v3.76.6) (2020-05-21)


### Bug Fixes

* keep more releases to prevent missing assets ([5480254](https://github.com/fleetyards/fleetyards/commit/54802549b880e45584e849a4aced0dbadc830a47))

### [3.76.5](https://github.com/fleetyards/fleetyards/compare/v3.76.4...v3.76.5) (2020-05-21)


### Bug Fixes

* filters ([e01f00c](https://github.com/fleetyards/fleetyards/commit/e01f00c7214ee9da131b0fd60906ddc3b6810d74))
* hangar settings validation and add more guards ([32f6276](https://github.com/fleetyards/fleetyards/commit/32f6276028a634fd236e9c18826e817525e2e0d5))
* mailer queue ([b8573fe](https://github.com/fleetyards/fleetyards/commit/b8573fe56cd928aec476486b32805ea2197fddd9))
* rubocoptering ([f1b0d07](https://github.com/fleetyards/fleetyards/commit/f1b0d07524262ae9d00ddf4612b74c869bb1e48a))
* send devise mails async ([9b2c534](https://github.com/fleetyards/fleetyards/commit/9b2c53405da062e3983d8cee099ca03b4e8f5787))

### [3.76.4](https://github.com/fleetyards/fleetyards/compare/v3.76.3...v3.76.4) (2020-05-21)


### Bug Fixes

* disable saved filter navigation and harden webp check ([db72540](https://github.com/fleetyards/fleetyards/commit/db7254053b132ee9f09a4b1db7e51d823692ad26))
* news worker ([91e369b](https://github.com/fleetyards/fleetyards/commit/91e369b43a6cf9011467c448e75ca6db995f87b1))

### [3.76.3](https://github.com/fleetyards/fleetyards/compare/v3.76.2...v3.76.3) (2020-05-21)


### Bug Fixes

* trade routes filter reset ([21968d5](https://github.com/fleetyards/fleetyards/commit/21968d5880d9b0b14ec2ba7e098d307d196da812))

### [3.76.2](https://github.com/fleetyards/fleetyards/compare/v3.76.1...v3.76.2) (2020-05-20)

### [3.76.1](https://github.com/fleetyards/fleetyards/compare/v3.76.0...v3.76.1) (2020-05-20)

## [3.76.0](https://github.com/fleetyards/fleetyards/compare/v3.75.0...v3.76.0) (2020-05-20)


### Features

* add export and import to hangar ([#1207](https://github.com/fleetyards/fleetyards/issues/1207)) ([e1f4c18](https://github.com/fleetyards/fleetyards/commit/e1f4c185b4e1d9ba5b916fde7e0019857e29a505))

## [3.75.0](https://github.com/fleetyards/fleetyards/compare/v3.74.3...v3.75.0) (2020-05-18)


### Features

* add stats page for fleets ([#1201](https://github.com/fleetyards/fleetyards/issues/1201)) ([fc061b3](https://github.com/fleetyards/fleetyards/commit/fc061b3c69713d138429316e732950cbaaee2420))
* starship42 export link for fleets ([#1202](https://github.com/fleetyards/fleetyards/issues/1202)) ([7187814](https://github.com/fleetyards/fleetyards/commit/718781421563168c85b6c83e81dc75abf6c9463c))


### Bug Fixes

* sentry config ([ab901fc](https://github.com/fleetyards/fleetyards/commit/ab901fc7bbe0c254b31871fa492a8ca2700ba8ce))

### [3.74.3](https://github.com/fleetyards/fleetyards/compare/v3.74.2...v3.74.3) (2020-05-17)

### [3.74.2](https://github.com/fleetyards/fleetyards/compare/v3.74.1...v3.74.2) (2020-05-17)


### Bug Fixes

* update flagship for vehicles ([bbb21f3](https://github.com/fleetyards/fleetyards/commit/bbb21f30340e97a247474559092ab29bc4ddf033))

### [3.74.1](https://github.com/fleetyards/fleetyards/compare/v3.74.0...v3.74.1) (2020-05-17)


### Bug Fixes

* skin cleanup ([a77b114](https://github.com/fleetyards/fleetyards/commit/a77b1147467472fb71b3f824347239f75d305a14))

## [3.74.0](https://github.com/fleetyards/fleetyards/compare/v3.73.2...v3.74.0) (2020-05-17)


### Features

* update skin display and also switch image for upgrades ([e5ac092](https://github.com/fleetyards/fleetyards/commit/e5ac0925a809cba54667496e5cd644c7da62cf9d))
* update skin display and also switch image for upgrades ([30f1f62](https://github.com/fleetyards/fleetyards/commit/30f1f622083727e591427102281467c764be6cc4))

### [3.73.2](https://github.com/fleetyards/fleetyards/compare/v3.73.1...v3.73.2) (2020-05-17)

### [3.73.1](https://github.com/fleetyards/fleetyards/compare/v3.73.0...v3.73.1) (2020-05-16)

## [3.73.0](https://github.com/fleetyards/fleetyards/compare/v3.72.2...v3.73.0) (2020-05-15)


### Features

* fetch news from rsi and post to discord ([#1197](https://github.com/fleetyards/fleetyards/issues/1197)) ([e59e118](https://github.com/fleetyards/fleetyards/commit/e59e118bb7b533a9762303ad5c873a54ca170168))

### [3.72.2](https://github.com/fleetyards/fleetyards/compare/v3.72.1...v3.72.2) (2020-05-15)


### Bug Fixes

* discord message ([a15f1ad](https://github.com/fleetyards/fleetyards/commit/a15f1ad328b431593c900f482d819b83b3fde825))

### [3.72.1](https://github.com/fleetyards/fleetyards/compare/v3.72.0...v3.72.1) (2020-05-15)

## [3.72.0](https://github.com/fleetyards/fleetyards/compare/v3.71.6...v3.72.0) (2020-05-15)


### Features

* add youtube notifier for discord ([0a003cb](https://github.com/fleetyards/fleetyards/commit/0a003cbe6b3c97057fafeaed6463b15cef9ed2f5))


### Bug Fixes

* discord message ([b4a5961](https://github.com/fleetyards/fleetyards/commit/b4a596121d5209048bc1ef2385a7db1aea2ff8c3))

### [3.71.6](https://github.com/fleetyards/fleetyards/compare/v3.71.5...v3.71.6) (2020-05-15)

### [3.71.5](https://github.com/fleetyards/fleetyards/compare/v3.71.4...v3.71.5) (2020-05-15)

### [3.71.4](https://github.com/fleetyards/fleetyards/compare/v3.71.3...v3.71.4) (2020-05-15)

### [3.71.3](https://github.com/fleetyards/fleetyards/compare/v3.71.2...v3.71.3) (2020-05-15)


### Bug Fixes

* images pagination ([42be854](https://github.com/fleetyards/fleetyards/commit/42be854006616fee48ffdd064b86c101e3557d5d))
* shop_commodities search ([6a67d37](https://github.com/fleetyards/fleetyards/commit/6a67d37458154446bace4a6db3e2c3b94ffa42ab))

### [3.71.2](https://github.com/fleetyards/fleetyards/compare/v3.71.1...v3.71.2) (2020-05-14)


### Bug Fixes

* actions on filtered list ([322b555](https://github.com/fleetyards/fleetyards/commit/322b555ede7d89955825bb370b024233ad4e8063))

### [3.71.1](https://github.com/fleetyards/fleetyards/compare/v3.71.0...v3.71.1) (2020-05-14)


### Bug Fixes

* ci smoketest ([069ac03](https://github.com/fleetyards/fleetyards/commit/069ac0362b6edc68a95c9e555c0a8aa03967e172))

## [3.71.0](https://github.com/fleetyards/fleetyards/compare/v3.70.3...v3.71.0) (2020-05-14)


### Features

* add guilded to profile and fleets ([#1194](https://github.com/fleetyards/fleetyards/issues/1194)) ([fe459c2](https://github.com/fleetyards/fleetyards/commit/fe459c24370e03b303e74d26facdb1f182ce7658))

### [3.70.3](https://github.com/fleetyards/fleetyards/compare/v3.70.2...v3.70.3) (2020-05-14)


### Bug Fixes

* model loader ([074cfc3](https://github.com/fleetyards/fleetyards/commit/074cfc38cd3f3d2f27a3d48cb31ebe36fe936428))

### [3.70.2](https://github.com/fleetyards/fleetyards/compare/v3.70.1...v3.70.2) (2020-05-13)


### Bug Fixes

* chunk name for home page ([dc3dcfc](https://github.com/fleetyards/fleetyards/commit/dc3dcfc09f331cd725b9a0ddac8ccae6b37e598c))
* model worker for blocked ships ([310502a](https://github.com/fleetyards/fleetyards/commit/310502a12bfaab4154b17adfcc379705385aca24))
* touch model on model skin update ([0f328a0](https://github.com/fleetyards/fleetyards/commit/0f328a0a8c70a30cae74e82d39f2fe5d1383602a))

### [3.70.1](https://github.com/fleetyards/fleetyards/compare/v3.70.0...v3.70.1) (2020-05-13)


### Bug Fixes

* ci config ([5c7b5ca](https://github.com/fleetyards/fleetyards/commit/5c7b5ca6380d96df58323ffc2fb5197b61be00da))
* pry ([b980fdc](https://github.com/fleetyards/fleetyards/commit/b980fdc0fa16f1a12e3859ec2ac3aa139e430c39))
* rake test task ([8cfe2d2](https://github.com/fleetyards/fleetyards/commit/8cfe2d2de098fedb2965e7739a6b3debf776f23c))
* ruby specs ([71c7302](https://github.com/fleetyards/fleetyards/commit/71c73024166275e25f17aa5cafb28bf8d04af91b))
* specs ([0d6a3c0](https://github.com/fleetyards/fleetyards/commit/0d6a3c07a26a54c023c5fdfcf42985770b403481))
* specs ([c8ced56](https://github.com/fleetyards/fleetyards/commit/c8ced56be2edb740f4853b9dffc88d1fa48f4907))
* specs ([4fec686](https://github.com/fleetyards/fleetyards/commit/4fec68669483e77987f48bc80db00b4004d194a0))

## [3.70.0](https://github.com/fleetyards/fleetyards/compare/v3.69.0...v3.70.0) (2020-05-12)


### Features

* model skins vs variants ([#1187](https://github.com/fleetyards/fleetyards/issues/1187)) ([a8cdd89](https://github.com/fleetyards/fleetyards/commit/a8cdd89e4996c087f2e41b9801bcc92bd8d61390))


### Bug Fixes

* context menu for model list ([10721b8](https://github.com/fleetyards/fleetyards/commit/10721b83befe31683217bad29d664c21d0443298))
* update github actions for ruby ([fb892be](https://github.com/fleetyards/fleetyards/commit/fb892be82054ba91fa2bfa6358de93fea48ab6da))

### [3.69.1](https://github.com/fleetyards/fleetyards/compare/v3.69.0...v3.69.1) (2020-05-04)

## [3.69.0](https://github.com/fleetyards/app/compare/v3.68.19...v3.69.0) (2020-05-01)


### Features

* add resend confirmation button to admin ([5d20600](https://github.com/fleetyards/app/commit/5d206005aa9b2a7d38a1787bf427069c991339bf))


### Bug Fixes

* audit issue ([1445e97](https://github.com/fleetyards/app/commit/1445e97597e7122a8c7e098efcbb3aabffee1964))
* specs ([83dd6e1](https://github.com/fleetyards/app/commit/83dd6e1de46d10c7d3ab6358907dec4d3450ccda))


### Refactorings

* move support styles to global styles ([c77aeff](https://github.com/fleetyards/app/commit/c77aeff0f65003434e6561a21e6a74d26515fa54))
* styles for pages ([a5d4033](https://github.com/fleetyards/app/commit/a5d4033a7582e66e8d85ea08d25ca7ad2ca0b43b))

### [3.68.19](https://github.com/fleetyards/app/compare/v3.68.18...v3.68.19) (2020-03-23)

### [3.68.18](https://github.com/fleetyards/app/compare/v3.68.17...v3.68.18) (2020-03-20)


### Bug Fixes

* acorn deps ([8120cea](https://github.com/fleetyards/app/commit/8120ceaca84c5bfb1f7d145a4f79000ceb5ad8b5))
* nav visible and modal scroll ([083eb87](https://github.com/fleetyards/app/commit/083eb87cd0b92e88b31b02aaa672d2c8e3551103))

### [3.68.17](https://github.com/fleetyards/app/compare/v3.68.16...v3.68.17) (2020-03-07)


### Bug Fixes

* **roadmap:** filter readds on new item ([91ae95a](https://github.com/fleetyards/app/commit/91ae95a19f734718dd6f2a705a23c600b3ac412a))

### [3.68.16](https://github.com/fleetyards/app/compare/v3.68.15...v3.68.16) (2020-03-06)


### Bug Fixes

* roadmap release parsing ([ef543ea](https://github.com/fleetyards/app/commit/ef543ea2bbf04f4da0c8ebaa25ea473da537e6bc))

### [3.68.15](https://github.com/fleetyards/app/compare/v3.68.14...v3.68.15) (2020-03-06)


### Bug Fixes

* roadmap last change at ([8b46c22](https://github.com/fleetyards/app/commit/8b46c22cb632a23f8aff03b57bb749c3a3378cad))

### [3.68.14](https://github.com/fleetyards/app/compare/v3.68.13...v3.68.14) (2020-03-06)


### Bug Fixes

* roadmap item caching ([f7da100](https://github.com/fleetyards/app/commit/f7da1007d0ca4701b1721dc98b709bcff49668e6))

### [3.68.13](https://github.com/fleetyards/app/compare/v3.68.12...v3.68.13) (2020-03-06)


### Bug Fixes

* roadmap release parsing ([6638673](https://github.com/fleetyards/app/commit/6638673ef286c25ad6840897aa6fc210047475b3))

### [3.68.12](https://github.com/fleetyards/app/compare/v3.68.11...v3.68.12) (2020-03-06)


### Bug Fixes

* hangar groups ([62fdffb](https://github.com/fleetyards/app/commit/62fdffbed43a6cfadca123bb99b27c4f06446c51))

### [3.68.11](https://github.com/fleetyards/app/compare/v3.68.10...v3.68.11) (2020-03-06)


### Bug Fixes

* hangar group caches ([b29d9e3](https://github.com/fleetyards/app/commit/b29d9e3fb77a1e6b1c089db12a73395fae89b747))

### [3.68.10](https://github.com/fleetyards/app/compare/v3.68.9...v3.68.10) (2020-03-05)

### [3.68.9](https://github.com/fleetyards/app/compare/v3.68.8...v3.68.9) (2020-03-04)

### [3.68.8](https://github.com/fleetyards/app/compare/v3.68.7...v3.68.8) (2020-03-04)


### Bug Fixes

* admin session ([0d9d1db](https://github.com/fleetyards/app/commit/0d9d1db9ee8b4acfe344da12a10452c3cafc8856))

### [3.68.7](https://github.com/fleetyards/app/compare/v3.68.6...v3.68.7) (2020-03-01)


### Bug Fixes

* try to resolve forbidden error on sidekiq cron tab ([6a04057](https://github.com/fleetyards/app/commit/6a04057071bda0813b4049798835cb1d72955197))

### [3.68.6](https://github.com/fleetyards/app/compare/v3.68.5...v3.68.6) (2020-03-01)


### Bug Fixes

* loaner admin mail ([20d7f7a](https://github.com/fleetyards/app/commit/20d7f7a9b8a8f028e6b0ba0f642441b2e404d988))
* loaner admin mail ([eb2e66a](https://github.com/fleetyards/app/commit/eb2e66a7652e5e948fddbacb01a802f62610c62c))

### [3.68.5](https://github.com/fleetyards/app/compare/v3.68.4...v3.68.5) (2020-02-28)

### [3.68.4](https://github.com/fleetyards/app/compare/v3.68.3...v3.68.4) (2020-02-28)

### [3.68.3](https://github.com/fleetyards/app/compare/v3.68.2...v3.68.3) (2020-02-28)

### [3.68.2](https://github.com/fleetyards/app/compare/v3.68.1...v3.68.2) (2020-02-26)


### Bug Fixes

* hangar groups cache invalidation ([bf8db23](https://github.com/fleetyards/app/commit/bf8db23535adca4ff84665efbee1e396632dd69e))
* toggle button width ([e8c2ac0](https://github.com/fleetyards/app/commit/e8c2ac0b2aa3a4c85d6e615de70c622992b500f8))

### [3.68.1](https://github.com/fleetyards/app/compare/v3.68.0...v3.68.1) (2020-02-26)


### Bug Fixes

* toggle button ([addf605](https://github.com/fleetyards/app/commit/addf60589d932756d6b0dfafc59920380d2f8bfc))

## [3.68.0](https://github.com/fleetyards/app/compare/v3.67.4...v3.68.0) (2020-02-25)


### Features

* load equipment and components from spreadsheet ([#1166](https://github.com/fleetyards/app/issues/1166)) ([05e992e](https://github.com/fleetyards/app/commit/05e992e07a220899df090690e32b2c65b2e1a417))


### Bug Fixes

* flex-list col sizes should fix [#1161](https://github.com/fleetyards/app/issues/1161) ([2f733f3](https://github.com/fleetyards/app/commit/2f733f3a9170a37364ba3075e515b8154fe1bb31))
* remove label from search page form ([c047445](https://github.com/fleetyards/app/commit/c047445ec6e12c1c1836c924da5db11444453a07))

### [3.67.4](https://github.com/fleetyards/app/compare/v3.67.3...v3.67.4) (2020-02-16)


### Bug Fixes

* refresh subscriptions only on authentication change ([8924c6e](https://github.com/fleetyards/app/commit/8924c6e161b42dac719ea7d113e328b612682c12))

### [3.67.3](https://github.com/fleetyards/app/compare/v3.67.2...v3.67.3) (2020-02-15)


### Bug Fixes

* specs ([db851dc](https://github.com/fleetyards/app/commit/db851dce05e1ce59767cc2340ec38ef2090acc67))

### [3.67.2](https://github.com/fleetyards/app/compare/v3.67.1...v3.67.2) (2020-02-08)


### Bug Fixes

* **loaner:** hide loaners from hangar-items ([6eb26dd](https://github.com/fleetyards/app/commit/6eb26dd13dbed9437e7b0182935993629acf4136))

### [3.67.1](https://github.com/fleetyards/app/compare/v3.67.0...v3.67.1) (2020-02-07)


### Bug Fixes

* **network-status:** disable component for now ([50fd8db](https://github.com/fleetyards/app/commit/50fd8dbcdaeba97da1a5d0f039e1b8241efeb2a0))

## [3.67.0](https://github.com/fleetyards/app/compare/v3.66.2...v3.67.0) (2020-02-07)


### Features

* **loaner:** allow to show only loaners ([a5b11e7](https://github.com/fleetyards/app/commit/a5b11e723e0ab21f36eae59005d99c014883e561))


### Bug Fixes

* **loaner:** update worker ([6d3e800](https://github.com/fleetyards/app/commit/6d3e8005cd8b2fe7157e25679ab48fda74ae4e35))

### [3.66.2](https://github.com/fleetyards/app/compare/v3.66.1...v3.66.2) (2020-02-07)


### Bug Fixes

* **loaner:** reload loaners ([4e115e4](https://github.com/fleetyards/app/commit/4e115e41264047de296c848b309808ec78feb578))

### [3.66.1](https://github.com/fleetyards/app/compare/v3.66.0...v3.66.1) (2020-02-06)


### Bug Fixes

* **specs:** update for new field ([e27d05e](https://github.com/fleetyards/app/commit/e27d05e4b24ef0950744d79ac8d2d9add7c0c164))

## [3.66.0](https://github.com/fleetyards/app/compare/v3.65.0...v3.66.0) (2020-02-06)


### Features

* **loaner:** add filter for hangar ([10592d2](https://github.com/fleetyards/app/commit/10592d2bcec453f4a57efef5bcf3c7e3694700d4))
* **loaner:** add label to identify loaners ([fb6d2fe](https://github.com/fleetyards/app/commit/fb6d2fe1156aa8bb0c53135de98cae1427e6baa7))

## [3.65.0](https://github.com/fleetyards/app/compare/v3.64.1...v3.65.0) (2020-02-06)


### Features

* **loaner:** add loaner to hangar ([8a08f68](https://github.com/fleetyards/app/commit/8a08f6818d4f85359c325b1e621342313e2eae95))

### [3.64.1](https://github.com/fleetyards/app/compare/v3.64.0...v3.64.1) (2020-02-05)


### Bug Fixes

* **loaner-loader:** add queue to sidekiq config ([e9a2b2a](https://github.com/fleetyards/app/commit/e9a2b2a46334528e44c8ce0fd6a1c6c9073c231e))

## [3.64.0](https://github.com/fleetyards/app/compare/v3.63.8...v3.64.0) (2020-02-05)


### Features

* **loaners:** fetch and display loaners for each model ([#1151](https://github.com/fleetyards/app/issues/1151)) ([89cc675](https://github.com/fleetyards/app/commit/89cc67522d1385307d9d425b32e437c44b8e7271))

### [3.63.8](https://github.com/fleetyards/app/compare/v3.63.7...v3.63.8) (2020-02-03)


### Bug Fixes

* **youtube:** update store reference ([6db6260](https://github.com/fleetyards/app/commit/6db62602b3cb45f17fcc3c878181e9f8905299ce))

### [3.63.7](https://github.com/fleetyards/app/compare/v3.63.6...v3.63.7) (2020-01-29)


### Bug Fixes

* **fleets:** hide invite button on members list for normal members ([f9cbf52](https://github.com/fleetyards/app/commit/f9cbf52e13cfe148167d7c04f13fc2d87a1e9d58))
* **images:** update require import ([ec9a925](https://github.com/fleetyards/app/commit/ec9a92517d6dec05e92cfe848fd683c6a6e78a2d))


### Refactorings

* **ts:** rewrite prop validation of panel component ([f5c1f0f](https://github.com/fleetyards/app/commit/f5c1f0f643c05faf18f2918e251a628ac53d9694))
* **ts:** update Modal component ([5f852ff](https://github.com/fleetyards/app/commit/5f852ff1223f51d4b3c404e839072820aaed508c))

### [3.63.6](https://github.com/fleetyards/app/compare/v3.63.5...v3.63.6) (2020-01-23)


### Bug Fixes

* **modal:** update item align ([d867a39](https://github.com/fleetyards/app/commit/d867a39ec7448494340745e0d44fea1d19226bc6))
* **modal:** update position on desktop ([37d4f71](https://github.com/fleetyards/app/commit/37d4f71056977fa386ba0e655f70074759512993))

### [3.63.5](https://github.com/fleetyards/app/compare/v3.63.4...v3.63.5) (2020-01-20)

### [3.63.4](https://github.com/fleetyards/app/compare/v3.63.3...v3.63.4) (2020-01-20)

### [3.63.3](https://github.com/fleetyards/app/compare/v3.63.2...v3.63.3) (2020-01-20)


### Bug Fixes

* **e2e:** update cookies helper ([b9ec852](https://github.com/fleetyards/app/commit/b9ec852fcd5932a38d9e50c2eb9b73a95b49962a))

### [3.63.2](https://github.com/fleetyards/app/compare/v3.63.1...v3.63.2) (2020-01-20)


### Bug Fixes

* **fleets:** update rsi icon ([7963b1f](https://github.com/fleetyards/app/commit/7963b1f10fb2801f637d57099d41162dae68bf4c))

### [3.63.1](https://github.com/fleetyards/app/compare/v3.63.0...v3.63.1) (2020-01-20)


### Bug Fixes

* **fleets:** update memberships on user update ([0ef29b1](https://github.com/fleetyards/app/commit/0ef29b16b858710f6f0f712aa80635ddd609d0ab))

## [3.63.0](https://github.com/fleetyards/app/compare/v3.62.0...v3.63.0) (2020-01-19)


### Features

* **cookies:** update e2e specs ([0bc32c4](https://github.com/fleetyards/app/commit/0bc32c4f7ddf31ec19a857cda3f977be8f43277b))


### Bug Fixes

* **specs:** update ships spec ([9a244f3](https://github.com/fleetyards/app/commit/9a244f342de890efda5aa4fc1ffa0eb261f8d644))
* **specs:** update test labels ([20140e0](https://github.com/fleetyards/app/commit/20140e0a1c9922fd4d52448251c133a52e5d2312))
* **specs:** update test labels ([0f85538](https://github.com/fleetyards/app/commit/0f85538a8b952faaf813ff727bd5cb193024c07d))

## [3.62.0](https://github.com/fleetyards/app/compare/v3.61.0...v3.62.0) (2020-01-18)


### Features

* **fleets:** add additional info fields ([8eec64e](https://github.com/fleetyards/app/commit/8eec64ec25ec648abf3d212d80a03b9d9c1a4fe7))


### Bug Fixes

* **fleet:** update label ([56be5e9](https://github.com/fleetyards/app/commit/56be5e90d923cf04f7651f6a5ce580cd53f4e90a))

## [3.61.0](https://github.com/fleetyards/app/compare/v3.60.0...v3.61.0) (2020-01-16)


### Features

* **fleet:** allow dots in fleet name ([24f8b69](https://github.com/fleetyards/app/commit/24f8b697551f2dba877cf98163f934e92e533973))
* **fleet:** update settings page ([68fc1f5](https://github.com/fleetyards/app/commit/68fc1f54f54a493ae253614d861b4a5c6a79bc49))

## [3.60.0](https://github.com/fleetyards/app/compare/v3.59.0...v3.60.0) (2020-01-15)


### Features

* **fleets:** generate slugs from fid ([0f2dae7](https://github.com/fleetyards/app/commit/0f2dae7a2156d92648bfc7ea80c9c8041e472f3f))


### Bug Fixes

* **fleets:** update regex ([785b573](https://github.com/fleetyards/app/commit/785b5732022a71b7a96dd893986f7ec220b9f07b))
* **specs:** update e2e test for fleets ([b8ebc35](https://github.com/fleetyards/app/commit/b8ebc35df15a1d32f325db57ea664e911b80b819))

## [3.59.0](https://github.com/fleetyards/app/compare/v3.58.5...v3.59.0) (2020-01-14)


### Features

* **fleets:** add fid and update validations ([2044232](https://github.com/fleetyards/app/commit/204423227fc1f90211a934c463cc7f52ca82e3e4))

### [3.58.5](https://github.com/fleetyards/app/compare/v3.58.4...v3.58.5) (2020-01-14)


### Bug Fixes

* **avatar:** update width ([dc26b3e](https://github.com/fleetyards/app/commit/dc26b3e75164eabe5f2415879bcd6e4fe1b2174c))

### [3.58.4](https://github.com/fleetyards/app/compare/v3.58.3...v3.58.4) (2020-01-10)


### Bug Fixes

* **signup:** add uniqness validation for email ([29e467a](https://github.com/fleetyards/app/commit/29e467a68d0b16dfc4e7e0482569b4205733a884))

### [3.58.3](https://github.com/fleetyards/app/compare/v3.58.2...v3.58.3) (2020-01-08)


### Bug Fixes

* **fleets:** update template ([f51195a](https://github.com/fleetyards/app/commit/f51195a9e1520cc4be122f6931a0115b5a25d4ae))

### [3.58.2](https://github.com/fleetyards/app/compare/v3.58.1...v3.58.2) (2020-01-08)


### Bug Fixes

* **hangar:** update addons/modules update ([87c7ab4](https://github.com/fleetyards/app/commit/87c7ab4f91f48d25727fc9ccb60fb0ca912e45d0))

### [3.58.1](https://github.com/fleetyards/app/compare/v3.58.0...v3.58.1) (2020-01-08)


### Bug Fixes

* **vehicles:** update parent on upgrade/module change ([c592074](https://github.com/fleetyards/app/commit/c59207454df92d28076a10569138bc7886d2fdcd))

## [3.58.0](https://github.com/fleetyards/app/compare/v3.57.1...v3.58.0) (2020-01-07)


### Features

* **fleets:** dont cache model counts ([791499d](https://github.com/fleetyards/app/commit/791499d7081b222ba9496c3e322045aec4cc4c28))


### Bug Fixes

* **fleets:** fetch fleetchart ([0f65ff9](https://github.com/fleetyards/app/commit/0f65ff9a263318a67e285e1512b000dea96e4e18))

### [3.57.1](https://github.com/fleetyards/app/compare/v3.57.0...v3.57.1) (2020-01-07)


### Bug Fixes

* **csp:** update manifest_src ([3fe4d5f](https://github.com/fleetyards/app/commit/3fe4d5f766b76ccb4bbfa7695cf5842b43db095b))

## [3.57.0](https://github.com/fleetyards/app/compare/v3.56.0...v3.57.0) (2020-01-07)


### Features

* **fleets:** update members list ([2f490ce](https://github.com/fleetyards/app/commit/2f490cee9f3f6fbf31cab5fa1d43b0d5f9c89994))

## [3.56.0](https://github.com/fleetyards/app/compare/v3.55.1...v3.56.0) (2020-01-07)


### Features

* **fleets:** update member list on mobile ([dbdb293](https://github.com/fleetyards/app/commit/dbdb293edc264642136eb69473b6f9d4167f1c2d))


### Bug Fixes

* **e2e:** update data test selector ([5baba4b](https://github.com/fleetyards/app/commit/5baba4be63df5a13eaec9b4d574828af7501674a))
* **e2e:** update data test selector ([075e333](https://github.com/fleetyards/app/commit/075e3332dd1aeb228cfc001d238d0db751714dcb))

### [3.55.1](https://github.com/fleetyards/app/compare/v3.55.0...v3.55.1) (2020-01-07)


### Bug Fixes

* **fleets:** member list ([4d3c3c1](https://github.com/fleetyards/app/commit/4d3c3c107847d46a895934cc25ae6eb4e45d1171))

## [3.55.0](https://github.com/fleetyards/app/compare/v3.54.1...v3.55.0) (2020-01-07)


### Features

* **fleet:** update nav ([47aee64](https://github.com/fleetyards/app/commit/47aee64a61ce33635d00f2ae736273b161803eb7))

### [3.54.1](https://github.com/fleetyards/app/compare/v3.54.0...v3.54.1) (2020-01-07)


### Bug Fixes

* **fleets:** update invite template and fix member list abilities ([445cb1e](https://github.com/fleetyards/app/commit/445cb1e47defb255a47e1097ba39800f48029278))

## [3.54.0](https://github.com/fleetyards/app/compare/v3.53.0...v3.54.0) (2020-01-06)


### Features

* **fleet:** dont allow leaving of guild as admin ([605ff83](https://github.com/fleetyards/app/commit/605ff8352c1229af15dc41d73bf7124a054ed9bb))

## [3.53.0](https://github.com/fleetyards/app/compare/v3.52.1...v3.53.0) (2020-01-06)


### Features

* **fleets:** add stats to dashboard ([65638ae](https://github.com/fleetyards/app/commit/65638ae6f6648fd384dcde113240ce519704ebda))
* **fleets:** hide leave button for non members ([6ff5c86](https://github.com/fleetyards/app/commit/6ff5c869f481cf1e790b58fe8ca96f2275e80346))

### [3.52.1](https://github.com/fleetyards/app/compare/v3.52.0...v3.52.1) (2020-01-06)

## [3.52.0](https://github.com/fleetyards/app/compare/v3.51.0...v3.52.0) (2020-01-06)


### Features

* **fleets:** prevent people from viewing internal links ([464c8db](https://github.com/fleetyards/app/commit/464c8db9b556c169ed8438e8f5825ac6588515c7))

## [3.51.0](https://github.com/fleetyards/app/compare/v3.50.0...v3.51.0) (2020-01-06)


### Features

* **fleets:** update invites call ([6288676](https://github.com/fleetyards/app/commit/6288676589d7fb03f6a19662faa71d4bb12e6b2f))

## [3.50.0](https://github.com/fleetyards/app/compare/v3.48.0...v3.50.0) (2020-01-06)


### Features

* **fleet:** add e2e tests and rework FormInput ([02a5919](https://github.com/fleetyards/app/commit/02a5919d6590cb98f16b042c116daafa37cf513e))


### Bug Fixes

* **add-to-hangar:** update jbuilder views for action cable ([f071052](https://github.com/fleetyards/app/commit/f071052bbe1f44de8ff46209e006482b3ccbdfbf))
* **e2e:** update hangar nav ([8762da1](https://github.com/fleetyards/app/commit/8762da1237e36eeb00d006b5f35ed072b41b02bd))
* **e2e:** update helper usage ([023e366](https://github.com/fleetyards/app/commit/023e366a0f59c22992a87e8c7b74e60e00fef710))
* **e2e:** update keys ([d3251ad](https://github.com/fleetyards/app/commit/d3251ad1007d1d7c4c9d01f431e1ac4570628d73))
* **e2e:** update test labels ([120f51b](https://github.com/fleetyards/app/commit/120f51be036b513d0f81d580e86456fa598e827d))
* **e2e-specs:** use correct data-test label ([c2464e1](https://github.com/fleetyards/app/commit/c2464e1097aaa70e99c4063cd7f52d3d0cb6e7fc))
* **specs:** update default name for quicksearch ([ceb3c9a](https://github.com/fleetyards/app/commit/ceb3c9a1bc8149a18f4694a16c15a044d57f6716))

## [3.49.0](https://github.com/fleetyards/app/compare/v3.48.0...v3.49.0) (2020-01-06)


### Features

* **fleet:** add e2e tests and rework FormInput ([02a5919](https://github.com/fleetyards/app/commit/02a5919d6590cb98f16b042c116daafa37cf513e))


### Bug Fixes

* **add-to-hangar:** update jbuilder views for action cable ([f071052](https://github.com/fleetyards/app/commit/f071052bbe1f44de8ff46209e006482b3ccbdfbf))
* **e2e:** update hangar nav ([8762da1](https://github.com/fleetyards/app/commit/8762da1237e36eeb00d006b5f35ed072b41b02bd))
* **e2e:** update helper usage ([023e366](https://github.com/fleetyards/app/commit/023e366a0f59c22992a87e8c7b74e60e00fef710))
* **e2e:** update keys ([d3251ad](https://github.com/fleetyards/app/commit/d3251ad1007d1d7c4c9d01f431e1ac4570628d73))
* **e2e:** update test labels ([120f51b](https://github.com/fleetyards/app/commit/120f51be036b513d0f81d580e86456fa598e827d))
* **e2e-specs:** use correct data-test label ([c2464e1](https://github.com/fleetyards/app/commit/c2464e1097aaa70e99c4063cd7f52d3d0cb6e7fc))
* **specs:** update default name for quicksearch ([ceb3c9a](https://github.com/fleetyards/app/commit/ceb3c9a1bc8149a18f4694a16c15a044d57f6716))

## [3.48.0](https://github.com/fleetyards/app/compare/v3.47.0...v3.48.0) (2019-12-29)


### Features

* **navigation:** linting ([240fc9a](https://github.com/fleetyards/app/commit/240fc9a4a1e0bc38afd0507023dd2bdaa4e83384))
* **navigation:** new fixed navbar ([c129099](https://github.com/fleetyards/app/commit/c129099946a3c2b5d24d94cf33487d3a5ccbbee2))
* **navigation:** update e2e ([00437ef](https://github.com/fleetyards/app/commit/00437ef09032d73e4f5b342272d1d3183a3d5725))
* **navigation:** update e2e ([852cf42](https://github.com/fleetyards/app/commit/852cf4257167493d70c1272edaa75f777c8b3f32))
* **navigation:** update e2e ([2007884](https://github.com/fleetyards/app/commit/200788410041326309b4bdd85f8bffa0d7af8f0e))
* **navigation:** update e2e ([53debbe](https://github.com/fleetyards/app/commit/53debbe20c85220b0cb30f1c359001113daae818))
* **navigation:** update e2e ([10b9e4a](https://github.com/fleetyards/app/commit/10b9e4a9e68fa04fe5922e4c33554299d9c75f47))
* **navigation:** update hangar icons ([1651ad3](https://github.com/fleetyards/app/commit/1651ad33936fdc1c64a29233a35133840d5445e5))

## [3.47.0](https://github.com/fleetyards/app/compare/v3.46.5...v3.47.0) (2019-12-28)


### Features

* **embed:** add option to use usernames for fleetview ([58618b7](https://github.com/fleetyards/app/commit/58618b7864cc93808822a93913fc6d2953676a7e))
* **embed:** remove on sale sign ([9ec3c51](https://github.com/fleetyards/app/commit/9ec3c51245c448322e1c930b8c33d14b60e4692f))

### [3.46.5](https://github.com/fleetyards/app/compare/v3.46.4...v3.46.5) (2019-12-27)


### Bug Fixes

* **home:** update autofocus on mobile ([a062ddc](https://github.com/fleetyards/app/commit/a062ddcbeba3f1a2ced7f92d4ecb8b864e6f1f9c))
* **no-scroll:** update height ([49c0b19](https://github.com/fleetyards/app/commit/49c0b195beb692f71044aab93cf252b4ff4c3689))
* **no-scroll:** update metrics ([5349aad](https://github.com/fleetyards/app/commit/5349aad5aa4a3ac7905f881b35a043ad0b7b4b20))

### [3.46.4](https://github.com/fleetyards/app/compare/v3.46.3...v3.46.4) (2019-12-25)


### Bug Fixes

* **no-scroll:** update css for mobile ([1af3320](https://github.com/fleetyards/app/commit/1af3320b3b326fb246d77d0b4f98eea11ae1863c))
* **no-scroll:** update mobile ([c3c899c](https://github.com/fleetyards/app/commit/c3c899c8e35c1b1a796f989b0e6fc86e26d94480))

### [3.46.3](https://github.com/fleetyards/app/compare/v3.46.2...v3.46.3) (2019-12-24)

### [3.46.2](https://github.com/fleetyards/app/compare/v3.46.1...v3.46.2) (2019-12-24)

### [3.46.1](https://github.com/fleetyards/app/compare/v3.46.0...v3.46.1) (2019-12-24)


### Bug Fixes

* **holoviewer:** update iframe url ([d96eafa](https://github.com/fleetyards/app/commit/d96eafaf1881931f8b56d01103a3d53f6b064ebc))

## [3.46.0](https://github.com/fleetyards/app/compare/v3.45.0...v3.46.0) (2019-12-24)


### Features

* **holoviewer:** update size on mobile ([2457f03](https://github.com/fleetyards/app/commit/2457f034f7a18c8178bbbcabd4b070b28acf464d))

## [3.45.0](https://github.com/fleetyards/app/compare/v3.44.2...v3.45.0) (2019-12-24)


### Features

* **3dview:** add new holoviewer from starship42 ([b25431f](https://github.com/fleetyards/app/commit/b25431f284632e0429aec6f227f6c8400472b2c2))
* **3dview:** update starship42 link ([7d4fc6b](https://github.com/fleetyards/app/commit/7d4fc6b54c69d82ea148e7ddc576197225c9096e))
* **breadcrumbs:** add crumbs to compare page ([1ccba1c](https://github.com/fleetyards/app/commit/1ccba1c30e0bcbb3d1fc7b6ccc89e8f493b3a080))
* **holoviewer:** update mobile size ([d3f0b3e](https://github.com/fleetyards/app/commit/d3f0b3ea313c6c7ac01ccc553ffcedc1f5d4d174))
* **holoviewer:** update size ([63de855](https://github.com/fleetyards/app/commit/63de8558bce8b2eafe694446f6ca63e4dc965e9b))
* **holoviewer:** update size ([d9f2d7e](https://github.com/fleetyards/app/commit/d9f2d7e1a6c7fbb0b757495ea399869389a217d4))
* **holoviewer:** update z-index ([34da30f](https://github.com/fleetyards/app/commit/34da30fac0e26b1ff3749e219d113e5950e39492))

### [3.44.2](https://github.com/fleetyards/app/compare/v3.44.1...v3.44.2) (2019-12-23)


### Refactorings

* **breadcrumbs:** update crumbs ([4e2b0e7](https://github.com/fleetyards/app/commit/4e2b0e7911ffe435affdc386c8e2568c9b6dca7b))

### [3.44.1](https://github.com/fleetyards/app/compare/v3.44.0...v3.44.1) (2019-12-23)


### Bug Fixes

* missing import ans breadcrumb ([1888813](https://github.com/fleetyards/app/commit/1888813bbed6c654d6757ea4108769e6f10dca7b))

## [3.44.0](https://github.com/fleetyards/app/compare/v3.43.1...v3.44.0) (2019-12-23)


### Features

* **breadcrumbs:** add breadcrumbs to all required pages ([158abea](https://github.com/fleetyards/app/commit/158abea20c825a0fe0b2ce24d6bef6e8f6d64baf))


### Bug Fixes

* specs ([07bbe0d](https://github.com/fleetyards/app/commit/07bbe0d63c5b2c57193fc8bb25edf4b857802790))

### [3.43.1](https://github.com/fleetyards/app/compare/v3.43.0...v3.43.1) (2019-12-21)

## [3.43.0](https://github.com/fleetyards/app/compare/v3.42.4...v3.43.0) (2019-12-21)


### Features

* **hangar:** add filter for public ([3fc4060](https://github.com/fleetyards/app/commit/3fc4060da1a81fa734cf8c6e2cc49cf8d8189bf5))

### [3.42.4](https://github.com/fleetyards/app/compare/v3.42.3...v3.42.4) (2019-12-21)

### [3.42.3](https://github.com/fleetyards/app/compare/v3.42.2...v3.42.3) (2019-12-18)

### [3.42.2](https://github.com/fleetyards/app/compare/v3.42.1...v3.42.2) (2019-12-16)


### Bug Fixes

* **seeds:** update index ([50930eb](https://github.com/fleetyards/app/commit/50930eb19380ba536d9cb28a98bb2e5a2fdda6cb))

### [3.42.1](https://github.com/fleetyards/app/compare/v3.42.0...v3.42.1) (2019-12-16)

## [3.42.0](https://github.com/fleetyards/app/compare/v3.41.0...v3.42.0) (2019-12-16)


### Features

* **stations:** add quick search ([6dc19f2](https://github.com/fleetyards/app/commit/6dc19f2c45d86e5c886ad8f9c08438bd794b5ab9))

## [3.41.0](https://github.com/fleetyards/app/compare/v3.40.7...v3.41.0) (2019-12-15)


### Features

* **stations:** add shadow for info texts and headlines ([a2db28b](https://github.com/fleetyards/app/commit/a2db28b0d45b6be341ea42256aab504de731b0f4))

### [3.40.7](https://github.com/fleetyards/app/compare/v3.40.6...v3.40.7) (2019-12-13)

### [3.40.6](https://github.com/fleetyards/app/compare/v3.40.5...v3.40.6) (2019-12-13)

### [3.40.5](https://github.com/fleetyards/app/compare/v3.40.4...v3.40.5) (2019-12-11)


### Bug Fixes

* **cors:** add production s3 url ([a3b3189](https://github.com/fleetyards/app/commit/a3b31897b8fd80decccb9689d359dcf812f4fdb9))

### [3.40.4](https://github.com/fleetyards/app/compare/v3.40.3...v3.40.4) (2019-12-11)

### [3.40.3](https://github.com/fleetyards/app/compare/v3.40.2...v3.40.3) (2019-12-08)

### [3.40.2](https://github.com/fleetyards/app/compare/v3.40.1...v3.40.2) (2019-12-07)

### [3.40.1](https://github.com/fleetyards/app/compare/v3.40.0...v3.40.1) (2019-12-07)


### Bug Fixes

* **rsi:** cache bust api requests ([c6176f4](https://github.com/fleetyards/app/commit/c6176f47669d3a5bf903d81f2b325476b6c790ca))

## [3.40.0](https://github.com/fleetyards/app/compare/v3.39.0...v3.40.0) (2019-12-03)


### Features

* **hangar:** update gold for flagship ([85bc3bc](https://github.com/fleetyards/app/commit/85bc3bcfcad33245708aab9e7d6d86fc8e0a182d))

## [3.39.0](https://github.com/fleetyards/app/compare/v3.38.11...v3.39.0) (2019-12-03)


### Features

* **hangar:** add flagship highlight ([54050dd](https://github.com/fleetyards/app/commit/54050dd7031dd2e2b64a01b3b903f765a06aa86b))


### Bug Fixes

* **model:** add missing check for vehicle ([0f80c47](https://github.com/fleetyards/app/commit/0f80c47f9b225476545b763869f03319c10d93db))

### [3.38.11](https://github.com/fleetyards/app/compare/v3.38.10...v3.38.11) (2019-12-01)


### Bug Fixes

* **file-loader:** downgrade to 4.x ([30997d0](https://github.com/fleetyards/app/commit/30997d04c816a730d967737c93516a91cf74e3db))

### [3.38.10](https://github.com/fleetyards/app/compare/v3.38.9...v3.38.10) (2019-12-01)


### Bug Fixes

* **hangar:** show vehicle name when allowed ([692bdfc](https://github.com/fleetyards/app/commit/692bdfc))
* **workers:** update schedule ([3d6c40e](https://github.com/fleetyards/app/commit/3d6c40e))

### [3.38.9](https://github.com/fleetyards/app/compare/v3.38.8...v3.38.9) (2019-11-26)

### [3.38.8](https://github.com/fleetyards/app/compare/v3.38.7...v3.38.8) (2019-11-25)

### [3.38.7](https://github.com/fleetyards/app/compare/v3.38.6...v3.38.7) (2019-11-25)


### Bug Fixes

* **mailer:** remove debugging code ([ae37683](https://github.com/fleetyards/app/commit/ae37683))

### [3.38.6](https://github.com/fleetyards/app/compare/v3.38.5...v3.38.6) (2019-11-25)

### [3.38.5](https://github.com/fleetyards/app/compare/v3.38.4...v3.38.5) (2019-11-25)

### [3.38.4](https://github.com/fleetyards/app/compare/v3.38.3...v3.38.4) (2019-11-25)

### [3.38.3](https://github.com/fleetyards/app/compare/v3.38.2...v3.38.3) (2019-11-25)

### [3.38.2](https://github.com/fleetyards/app/compare/v3.38.1...v3.38.2) (2019-11-24)


### Bug Fixes

* **loaders:** update models loader ([c549993](https://github.com/fleetyards/app/commit/c549993))

### [3.38.1](https://github.com/fleetyards/app/compare/v3.38.0...v3.38.1) (2019-11-17)

## [3.38.0](https://github.com/fleetyards/app/compare/v3.37.3...v3.38.0) (2019-11-17)


### Features

* **rsi:** readd orgs and citizen endpoints ([49775ea](https://github.com/fleetyards/app/commit/49775ea))

### [3.37.3](https://github.com/fleetyards/app/compare/v3.37.2...v3.37.3) (2019-11-16)

### [3.37.2](https://github.com/fleetyards/app/compare/v3.37.1...v3.37.2) (2019-11-15)


### Bug Fixes

* **roadmap:** add roadmap updates for friday ([a8907a7](https://github.com/fleetyards/app/commit/a8907a7))

### [3.37.1](https://github.com/fleetyards/app/compare/v3.37.0...v3.37.1) (2019-11-08)


### Bug Fixes

* **weekly:** remove fleets from mailer ([686824a](https://github.com/fleetyards/app/commit/686824a))

## [3.37.0](https://github.com/fleetyards/app/compare/v3.36.1...v3.37.0) (2019-11-03)


### Features

* **roadmap:** add more roadmap updates to select from ([404eaf9](https://github.com/fleetyards/app/commit/404eaf9))
* **roadmap:** rubocoptering ([224bb73](https://github.com/fleetyards/app/commit/224bb73))

### [3.36.1](https://github.com/fleetyards/app/compare/v3.36.0...v3.36.1) (2019-11-03)


### Bug Fixes

* roadmap specs ([4b6918c](https://github.com/fleetyards/app/commit/4b6918c))

## [3.36.0](https://github.com/fleetyards/app/compare/v3.35.1...v3.36.0) (2019-11-02)


### Features

* **roadmap:** update last versions for older weeks ([9c173e0](https://github.com/fleetyards/app/commit/9c173e0))

### [3.35.1](https://github.com/fleetyards/app/compare/v3.35.0...v3.35.1) (2019-11-02)


### Bug Fixes

* **search:** add missing word_start settings for remaining models ([88926b0](https://github.com/fleetyards/app/commit/88926b0))

## [3.35.0](https://github.com/fleetyards/app/compare/v3.34.3...v3.35.0) (2019-11-02)


### Features

* **search:** update name matching ([150c982](https://github.com/fleetyards/app/commit/150c982))

### [3.34.3](https://github.com/fleetyards/app/compare/v3.34.2...v3.34.3) (2019-11-01)

### [3.34.2](https://github.com/fleetyards/app/compare/v3.34.1...v3.34.2) (2019-11-01)


### Bug Fixes

* group labels alignment ([90719a7](https://github.com/fleetyards/app/commit/90719a7))

### [3.34.1](https://github.com/fleetyards/app/compare/v3.34.0...v3.34.1) (2019-10-31)


### Bug Fixes

* specs ([5a5d508](https://github.com/fleetyards/app/commit/5a5d508))

## [3.34.0](https://github.com/fleetyards/app/compare/v3.32.0...v3.34.0) (2019-10-31)


### Bug Fixes

* **search:** update route ([0ae0acc](https://github.com/fleetyards/app/commit/0ae0acc))
* **search:** update route ([caeeab5](https://github.com/fleetyards/app/commit/caeeab5))


### Features

* **advanced-search:** global single field search for the home page ([#942](https://github.com/fleetyards/app/issues/942)) ([853c2c0](https://github.com/fleetyards/app/commit/853c2c0))
* **hangar-preview:** add page and basic layout ([#935](https://github.com/fleetyards/app/issues/935)) ([9525a9b](https://github.com/fleetyards/app/commit/9525a9b))
* **search:** update history list ([d3c5e2f](https://github.com/fleetyards/app/commit/d3c5e2f))
* **shops:** update page cols ([50eba24](https://github.com/fleetyards/app/commit/50eba24))

## [3.33.0](https://github.com/fleetyards/app/compare/v3.32.0...v3.33.0) (2019-10-31)


### Bug Fixes

* **search:** update route ([0ae0acc](https://github.com/fleetyards/app/commit/0ae0acc))
* **search:** update route ([caeeab5](https://github.com/fleetyards/app/commit/caeeab5))


### Features

* **advanced-search:** global single field search for the home page ([#942](https://github.com/fleetyards/app/issues/942)) ([853c2c0](https://github.com/fleetyards/app/commit/853c2c0))
* **hangar-preview:** add page and basic layout ([#935](https://github.com/fleetyards/app/issues/935)) ([9525a9b](https://github.com/fleetyards/app/commit/9525a9b))
* **search:** update history list ([d3c5e2f](https://github.com/fleetyards/app/commit/d3c5e2f))
* **shops:** update page cols ([50eba24](https://github.com/fleetyards/app/commit/50eba24))

## [3.32.0](https://github.com/fleetyards/app/compare/v3.31.1...v3.32.0) (2019-10-25)


### Features

* **rentals:** add 3 days rental prices ([ea3fa38](https://github.com/fleetyards/app/commit/ea3fa38))
* **rentals:** update admin tools ([15d27f5](https://github.com/fleetyards/app/commit/15d27f5))

### [3.31.1](https://github.com/fleetyards/app/compare/v3.31.0...v3.31.1) (2019-10-25)

## [3.31.0](https://github.com/fleetyards/app/compare/v3.30.0...v3.31.0) (2019-10-25)


### Bug Fixes

* **shops:** update rental_at check ([48b0a97](https://github.com/fleetyards/app/commit/48b0a97))


### Features

* **shops:** add rental prices ([c0a9b43](https://github.com/fleetyards/app/commit/c0a9b43))
* **shops:** update specs ([f560eb2](https://github.com/fleetyards/app/commit/f560eb2))


### Refactorings

* move style files ([0f68650](https://github.com/fleetyards/app/commit/0f68650))

## [3.30.0](https://github.com/fleetyards/app/compare/v3.29.0...v3.30.0) (2019-10-24)


### Bug Fixes

* **search:** update placeholder ([08f0f9e](https://github.com/fleetyards/app/commit/08f0f9e))


### Features

* **roadmap:** update e2e tests ([404c020](https://github.com/fleetyards/app/commit/404c020))

## [3.29.0](https://github.com/fleetyards/app/compare/v3.28.0...v3.29.0) (2019-10-24)


### Features

* **roadmap:** update navigation ([553672e](https://github.com/fleetyards/app/commit/553672e))
* **roadmap:** update navigation ([4615b2a](https://github.com/fleetyards/app/commit/4615b2a))

## [3.28.0](https://github.com/fleetyards/app/compare/v3.27.1...v3.28.0) (2019-10-22)


### Features

* **compare:** update scrolling ([87ab830](https://github.com/fleetyards/app/commit/87ab830))
* **compare:** update scrolling ([e232bcb](https://github.com/fleetyards/app/commit/e232bcb))

### [3.27.1](https://github.com/fleetyards/app/compare/v3.27.0...v3.27.1) (2019-10-15)


### Bug Fixes

* **fleet:** update specs ([336d8c3](https://github.com/fleetyards/app/commit/336d8c3))
* **fleets:** save and validate sid for upcase ([1aae94a](https://github.com/fleetyards/app/commit/1aae94a))

## [3.27.0](https://github.com/fleetyards/app/compare/v3.26.0...v3.27.0) (2019-10-06)


### Bug Fixes

* **specs:** add new date fields ([4f58b28](https://github.com/fleetyards/app/commit/4f58b28))


### Features

* **rentals:** add rental information to ship detail page ([0e32a5b](https://github.com/fleetyards/app/commit/0e32a5b))
* **shops:** add rental shops ([25cd1ac](https://github.com/fleetyards/app/commit/25cd1ac))

## [3.26.0](https://github.com/fleetyards/app/compare/v3.25.3...v3.26.0) (2019-09-15)


### Features

* **shop:** add quick filter for sub categories ([b36e576](https://github.com/fleetyards/app/commit/b36e576))

### [3.25.3](https://github.com/fleetyards/app/compare/v3.25.2...v3.25.3) (2019-09-13)

### [3.25.2](https://github.com/fleetyards/app/compare/v3.25.1...v3.25.2) (2019-09-13)


### Bug Fixes

* **roadmap:** update date format ([e308dc7](https://github.com/fleetyards/app/commit/e308dc7))

### [3.25.1](https://github.com/fleetyards/app/compare/v3.25.0...v3.25.1) (2019-09-13)


### Bug Fixes

* **roadmap:** use correct format for dates ([57de7c0](https://github.com/fleetyards/app/commit/57de7c0))

## [3.25.0](https://github.com/fleetyards/app/compare/v3.24.1...v3.25.0) (2019-09-13)


### Features

* **hangar:** show addons on public hangar ([b92cc6e](https://github.com/fleetyards/app/commit/b92cc6e))

### [3.24.1](https://github.com/fleetyards/app/compare/v3.24.0...v3.24.1) (2019-09-12)


### Bug Fixes

* **test:** update times ([c019b27](https://github.com/fleetyards/app/commit/c019b27))

## [3.24.0](https://github.com/fleetyards/app/compare/v3.23.1...v3.24.0) (2019-09-11)


### Bug Fixes

* **dateFormat:** update key ([65dff18](https://github.com/fleetyards/app/commit/65dff18))


### Features

* **models:** add last updated at date and direct link to compare from detail ([aa20c7b](https://github.com/fleetyards/app/commit/aa20c7b))
* **models:** add last updated at date and direct link to compare from detail ([1412029](https://github.com/fleetyards/app/commit/1412029))

### [3.23.1](https://github.com/fleetyards/app/compare/v3.23.0...v3.23.1) (2019-09-01)


### Bug Fixes

* **roadmap:** use correct label for changes page ([fc2b2aa](https://github.com/fleetyards/app/commit/fc2b2aa))

## [3.23.0](https://github.com/fleetyards/app/compare/v3.22.1...v3.23.0) (2019-08-31)


### Features

* **roadmap:** group changes by release ([4dde3d4](https://github.com/fleetyards/app/commit/4dde3d4))

### [3.22.1](https://github.com/fleetyards/app/compare/v3.22.0...v3.22.1) (2019-08-31)


### Bug Fixes

* **models:** strip rsi name of whitespace ([b9f39b6](https://github.com/fleetyards/app/commit/b9f39b6))

## [3.22.0](https://github.com/fleetyards/app/compare/v3.21.6...v3.22.0) (2019-08-31)


### Features

* **roadmap:** add removals and fix empty labels ([92048f0](https://github.com/fleetyards/app/commit/92048f0))

### [3.21.6](https://github.com/fleetyards/app/compare/v3.21.5...v3.21.6) (2019-08-30)


### Bug Fixes

* **support:** update specs ([779e0e1](https://github.com/fleetyards/app/commit/779e0e1))

### [3.21.5](https://github.com/fleetyards/app/compare/v3.21.4...v3.21.5) (2019-08-30)

### [3.21.4](https://github.com/fleetyards/app/compare/v3.21.3...v3.21.4) (2019-08-25)


### Bug Fixes

* **store-image:** add background color ([95fede9](https://github.com/fleetyards/app/commit/95fede9))

### [3.21.3](https://github.com/fleetyards/app/compare/v3.21.2...v3.21.3) (2019-08-25)


### Bug Fixes

* **admin:** update for latest carrierwave changes ([d858d9d](https://github.com/fleetyards/app/commit/d858d9d))

### [3.21.2](https://github.com/fleetyards/app/compare/v3.21.1...v3.21.2) (2019-08-24)


### Bug Fixes

* **stations:** update dock sorting ([84ed699](https://github.com/fleetyards/app/commit/84ed699))

### [3.21.1](https://github.com/fleetyards/app/compare/v3.21.0...v3.21.1) (2019-08-24)

## [3.21.0](https://github.com/fleetyards/app/compare/v3.20.3...v3.21.0) (2019-08-23)


### Features

* **roadmap:** remove inprogress for now ([32eebbb](https://github.com/fleetyards/app/commit/32eebbb))

### [3.20.3](https://github.com/fleetyards/app/compare/v3.20.2...v3.20.3) (2019-08-16)


### Bug Fixes

* **verification:** update e2e tests ([bb059e4](https://github.com/fleetyards/app/commit/bb059e4))

### [3.20.2](https://github.com/fleetyards/app/compare/v3.20.1...v3.20.2) (2019-08-16)


### Bug Fixes

* **verification:** update process for rsi verification ([355bbc6](https://github.com/fleetyards/app/commit/355bbc6))
* **verification:** update workflow ([fbf3eac](https://github.com/fleetyards/app/commit/fbf3eac))

### [3.20.1](https://github.com/fleetyards/app/compare/v3.20.0...v3.20.1) (2019-08-15)


### Bug Fixes

* **modal:** update mobile styles ([ca2c529](https://github.com/fleetyards/app/commit/ca2c529))

## [3.20.0](https://github.com/fleetyards/app/compare/v3.19.0...v3.20.0) (2019-08-15)


### Features

* **hangar:** fix stats loading ([2703e11](https://github.com/fleetyards/app/commit/2703e11))

## [3.19.0](https://github.com/fleetyards/app/compare/v3.18.2...v3.19.0) (2019-08-15)


### Bug Fixes

* **router:** replace flat() with concat spread ([5218890](https://github.com/fleetyards/app/commit/5218890))
* **routes:** for child routes ([383aabf](https://github.com/fleetyards/app/commit/383aabf))
* **routes:** update settings child routes ([4d7c44e](https://github.com/fleetyards/app/commit/4d7c44e))


### Features

* **filter:** add searchable to will it fit ([98a3b87](https://github.com/fleetyards/app/commit/98a3b87))
* **shops:** update labels ([e44a10b](https://github.com/fleetyards/app/commit/e44a10b))

### [3.18.2](https://github.com/fleetyards/app/compare/v3.18.1...v3.18.2) (2019-08-14)


### Bug Fixes

* **admin:** prefill selectize inputs ([1fdbacc](https://github.com/fleetyards/app/commit/1fdbacc))

### [3.18.1](https://github.com/fleetyards/app/compare/v3.18.0...v3.18.1) (2019-08-14)


### Bug Fixes

* **seeds:** update image paths ([64dbde6](https://github.com/fleetyards/app/commit/64dbde6))

## [3.18.0](https://github.com/fleetyards/app/compare/v3.17.8...v3.18.0) (2019-08-13)


### Features

* **public-hangar:** add avatar and link to rsi profile ([#772](https://github.com/fleetyards/app/issues/772)) ([31aec7d](https://github.com/fleetyards/app/commit/31aec7d))

### [3.17.8](https://github.com/fleetyards/app/compare/v3.17.7...v3.17.8) (2019-08-13)


### Bug Fixes

* **specs:** update footer specs ([64e1d55](https://github.com/fleetyards/app/commit/64e1d55))

### [3.17.7](https://github.com/fleetyards/app/compare/v3.17.6...v3.17.7) (2019-08-12)


### Bug Fixes

* **filter-group:** linting ([80e5422](https://github.com/fleetyards/app/commit/80e5422))

### [3.17.6](https://github.com/fleetyards/app/compare/v3.17.5...v3.17.6) (2019-08-12)


### Bug Fixes

* **filter-group:** update find missing ([6c8a288](https://github.com/fleetyards/app/commit/6c8a288))

### [3.17.5](https://github.com/fleetyards/app/compare/v3.17.4...v3.17.5) (2019-08-12)


### Bug Fixes

* **modals:** update scrolling ([7e873e6](https://github.com/fleetyards/app/commit/7e873e6))

### [3.17.4](https://github.com/fleetyards/app/compare/v3.17.3...v3.17.4) (2019-08-11)


### Bug Fixes

* **addons:** remove unused component ([2c8f5db](https://github.com/fleetyards/app/commit/2c8f5db))

### [3.17.3](https://github.com/fleetyards/app/compare/v3.17.2...v3.17.3) (2019-08-11)


### Bug Fixes

* **filter-group:** update selection styles ([e168a6a](https://github.com/fleetyards/app/commit/e168a6a))

### [3.17.2](https://github.com/fleetyards/app/compare/v3.17.1...v3.17.2) (2019-08-11)


### Bug Fixes

* **addons:** update modal and use filterGroup ([1729425](https://github.com/fleetyards/app/commit/1729425))

### [3.17.1](https://github.com/fleetyards/app/compare/v3.17.0...v3.17.1) (2019-08-11)


### Refactorings

* **click-handler:** update global document click ([308b045](https://github.com/fleetyards/app/commit/308b045))

## [3.17.0](https://github.com/fleetyards/app/compare/v3.16.2...v3.17.0) (2019-08-11)


### Features

* **trade-routes:** update filters ([7a2493a](https://github.com/fleetyards/app/commit/7a2493a))

### [3.16.2](https://github.com/fleetyards/app/compare/v3.16.1...v3.16.2) (2019-08-11)


### Bug Fixes

* **trade-routes:** allow search of cargo ships ([43d8be9](https://github.com/fleetyards/app/commit/43d8be9))

### [3.16.1](https://github.com/fleetyards/app/compare/v3.16.0...v3.16.1) (2019-08-11)


### Bug Fixes

* **trade-routes:** update pagination ([3bc8be2](https://github.com/fleetyards/app/commit/3bc8be2))

## [3.16.0](https://github.com/fleetyards/app/compare/v3.15.6...v3.16.0) (2019-08-10)


### Features

* **trade-routes:** add filter for origin and destination ([8f0937b](https://github.com/fleetyards/app/commit/8f0937b))

### [3.15.6](https://github.com/fleetyards/app/compare/v3.15.5...v3.15.6) (2019-08-10)


### Bug Fixes

* **toggle:** update mobile styles ([1ac198f](https://github.com/fleetyards/app/commit/1ac198f))

### [3.15.5](https://github.com/fleetyards/app/compare/v3.15.4...v3.15.5) (2019-08-09)

### [3.15.4](https://github.com/fleetyards/app/compare/v3.15.3...v3.15.4) (2019-08-09)


### Bug Fixes

* **model:** dont lazy load fleetchart images ([917eced](https://github.com/fleetyards/app/commit/917eced))

### [3.15.3](https://github.com/fleetyards/app/compare/v3.15.2...v3.15.3) (2019-08-08)


### Bug Fixes

* **models:** update admin form ([87473c2](https://github.com/fleetyards/app/commit/87473c2))

### [3.15.2](https://github.com/fleetyards/app/compare/v3.15.1...v3.15.2) (2019-08-08)


### Refactorings

* **toggle:** reuse structure from btn component ([6d4e8fd](https://github.com/fleetyards/app/commit/6d4e8fd))

### [3.15.1](https://github.com/fleetyards/app/compare/v3.15.0...v3.15.1) (2019-08-08)


### Bug Fixes

* **fleets:** search for lowercase fleet sids ([e328df9](https://github.com/fleetyards/app/commit/e328df9))

## [3.15.0](https://github.com/fleetyards/app/compare/v3.14.1...v3.15.0) (2019-08-08)


### Features

* **trade-routes:** paginate cargo ship filter ([712e9cd](https://github.com/fleetyards/app/commit/712e9cd))

### [3.14.1](https://github.com/fleetyards/app/compare/v3.14.0...v3.14.1) (2019-08-08)


### Bug Fixes

* **trade-routes:** add missing labels ([3e52a7e](https://github.com/fleetyards/app/commit/3e52a7e))

## [3.14.0](https://github.com/fleetyards/app/compare/v3.13.2...v3.14.0) (2019-08-07)


### Features

* **trade-routes:** add button for sorting ([9bbdb8c](https://github.com/fleetyards/app/commit/9bbdb8c))

### [3.13.2](https://github.com/fleetyards/app/compare/v3.13.1...v3.13.2) (2019-08-07)


### Bug Fixes

* **trade-routes:** auto delete when shop commodity is deleted ([5d51a99](https://github.com/fleetyards/app/commit/5d51a99))

### [3.13.1](https://github.com/fleetyards/app/compare/v3.13.0...v3.13.1) (2019-08-07)

## [3.13.0](https://github.com/fleetyards/app/compare/v3.12.2...v3.13.0) (2019-08-07)


### Features

* **stations:** update docks ([2cf0525](https://github.com/fleetyards/app/commit/2cf0525))

### [3.12.2](https://github.com/fleetyards/app/compare/v3.12.1...v3.12.2) (2019-08-07)


### Bug Fixes

* **trade-routes:** update worker ([fa028d1](https://github.com/fleetyards/app/commit/fa028d1))

### [3.12.1](https://github.com/fleetyards/app/compare/v3.12.0...v3.12.1) (2019-08-07)

## [3.12.0](https://github.com/fleetyards/app/compare/v3.11.0...v3.12.0) (2019-08-07)


### Features

* **components:** add item class to shop list ([4efccf3](https://github.com/fleetyards/app/commit/4efccf3))

## [3.11.0](https://github.com/fleetyards/app/compare/v3.10.2...v3.11.0) (2019-08-07)


### Bug Fixes

* **pagination:** remove check for page where it didn't belong ([b82efbf](https://github.com/fleetyards/app/commit/b82efbf))


### Features

* **erkul:** add links to Erkuls DPS Calculator ([#745](https://github.com/fleetyards/app/issues/745)) ([6df6d09](https://github.com/fleetyards/app/commit/6df6d09))

### [3.10.2](https://github.com/fleetyards/app/compare/v3.10.1...v3.10.2) (2019-08-07)


### Bug Fixes

* **shop:** resolve server error on invalid form submit ([ef94b3a](https://github.com/fleetyards/app/commit/ef94b3a))
* **trade-routes:** only calculate routes for visible shops ([75379d4](https://github.com/fleetyards/app/commit/75379d4))

### [3.10.1](https://github.com/fleetyards/app/compare/v3.10.0...v3.10.1) (2019-08-06)


### Bug Fixes

* **admin:** update select ([3e04eea](https://github.com/fleetyards/app/commit/3e04eea))

## [3.10.0](https://github.com/fleetyards/app/compare/v3.9.0...v3.10.0) (2019-08-06)


### Bug Fixes

* **admin:** update components form ([373fc21](https://github.com/fleetyards/app/commit/373fc21))
* **filters:** update components and equipment ([4b29624](https://github.com/fleetyards/app/commit/4b29624))


### Features

* **trade-routes:** add links to stations ([b92e692](https://github.com/fleetyards/app/commit/b92e692))

## [3.9.0](https://github.com/fleetyards/app/compare/v3.8.1...v3.9.0) (2019-08-05)


### Features

* **trade-routes:** update cargoship selection ([c74f8eb](https://github.com/fleetyards/app/commit/c74f8eb))

### [3.8.1](https://github.com/fleetyards/app/compare/v3.8.0...v3.8.1) (2019-08-05)


### Bug Fixes

* **trade-routes:** show correct prices ([913be3c](https://github.com/fleetyards/app/commit/913be3c))

## [3.8.0](https://github.com/fleetyards/app/compare/v3.7.4...v3.8.0) (2019-08-05)


### Bug Fixes

* **roadmap:** add released to versioning ([499e373](https://github.com/fleetyards/app/commit/499e373))


### Features

* **trade-routes:** add shop based commodity trade routes ([#746](https://github.com/fleetyards/app/issues/746)) ([eb27f7d](https://github.com/fleetyards/app/commit/eb27f7d))

### [3.7.4](https://github.com/fleetyards/app/compare/v3.7.3...v3.7.4) (2019-08-03)


### Bug Fixes

* **roadmap:** show inprogress changes ([f0c6229](https://github.com/fleetyards/app/commit/f0c6229))

### [3.7.3](https://github.com/fleetyards/app/compare/v3.7.2...v3.7.3) (2019-08-03)


### Bug Fixes

* **roadmap:** filter by last version created_at ([fe5e5d2](https://github.com/fleetyards/app/commit/fe5e5d2))
* **ships-compare:** download s3 image before composing compare image ([55d6c6e](https://github.com/fleetyards/app/commit/55d6c6e))

### [3.7.2](https://github.com/fleetyards/app/compare/v3.7.1...v3.7.2) (2019-08-03)


### Bug Fixes

* **model:** update price field after shop item is updated ([92edc2f](https://github.com/fleetyards/app/commit/92edc2f))

### [3.7.1](https://github.com/fleetyards/app/compare/v3.7.0...v3.7.1) (2019-08-03)


### Bug Fixes

* **location-worker:** add missing attribute ([d106d8e](https://github.com/fleetyards/app/commit/d106d8e))

## [3.7.0](https://github.com/fleetyards/app/compare/v3.6.1...v3.7.0) (2019-08-03)


### Bug Fixes

* **roadmap:** update specs ([ee61155](https://github.com/fleetyards/app/commit/ee61155))
* **roadmap:** update specs ([274ce39](https://github.com/fleetyards/app/commit/274ce39))
* **stations:** rubocoptering and update specs ([2126af1](https://github.com/fleetyards/app/commit/2126af1))


### Features

* **station:** add images and fix location worker ([e6d4c53](https://github.com/fleetyards/app/commit/e6d4c53))

### [3.6.1](https://github.com/fleetyards/app/compare/v3.6.0...v3.6.1) (2019-08-02)

## [3.6.0](https://github.com/fleetyards/app/compare/v3.5.21...v3.6.0) (2019-08-02)


### Bug Fixes

* **stations:** reorder partials and fix stations list ([0804e3d](https://github.com/fleetyards/app/commit/0804e3d))


### Features

* **stations:** remove empty info ([22c3fce](https://github.com/fleetyards/app/commit/22c3fce))

### [3.5.21](https://github.com/fleetyards/app/compare/v3.5.20...v3.5.21) (2019-08-02)

### [3.5.20](https://github.com/fleetyards/app/compare/v3.5.19...v3.5.20) (2019-08-01)


### Bug Fixes

* **stations:** add missing label ([0225a92](https://github.com/fleetyards/app/commit/0225a92))

### [3.5.19](https://github.com/fleetyards/app/compare/v3.5.18...v3.5.19) (2019-08-01)

### [3.5.18](https://github.com/fleetyards/app/compare/v3.5.17...v3.5.18) (2019-07-31)

### [3.5.17](https://github.com/fleetyards/app/compare/v3.5.16...v3.5.17) (2019-07-31)


### Bug Fixes

* **uploader:** update dropzone color ([c678afe](https://github.com/fleetyards/app/commit/c678afe))

### [3.5.16](https://github.com/fleetyards/app/compare/v3.5.15...v3.5.16) (2019-07-31)

### [3.5.15](https://github.com/fleetyards/app/compare/v3.5.14...v3.5.15) (2019-07-31)

### [3.5.14](https://github.com/fleetyards/app/compare/v3.5.13...v3.5.14) (2019-07-31)



### [3.5.13](https://github.com/fleetyards/app/compare/v3.5.12...v3.5.13) (2019-07-31)



### [3.5.12](https://github.com/fleetyards/app/compare/v3.5.11...v3.5.12) (2019-07-30)



### [3.5.11](https://github.com/fleetyards/app/compare/v3.5.10...v3.5.11) (2019-07-29)



### [3.5.10](https://github.com/fleetyards/app/compare/v3.5.9...v3.5.10) (2019-07-28)



### [3.5.9](https://github.com/fleetyards/app/compare/v3.5.8...v3.5.9) (2019-07-27)



### [3.5.8](https://github.com/fleetyards/app/compare/v3.5.7...v3.5.8) (2019-07-27)


### Bug Fixes

* **equipment:** rename scopes ([b681d50](https://github.com/fleetyards/app/commit/b681d50))



### [3.5.7](https://github.com/fleetyards/app/compare/v3.5.6...v3.5.7) (2019-07-26)


### Bug Fixes

* **equipment:** update translations ([19f90ff](https://github.com/fleetyards/app/commit/19f90ff))



### [3.5.6](https://github.com/fleetyards/app/compare/v3.5.5...v3.5.6) (2019-07-26)



### [3.5.5](https://github.com/fleetyards/app/compare/v3.5.4...v3.5.5) (2019-07-26)


### Bug Fixes

* **equipment:** add missing slots ([b3f04f2](https://github.com/fleetyards/app/commit/b3f04f2))
* **seeds:** disable unfinished entry ([c1d46f8](https://github.com/fleetyards/app/commit/c1d46f8))


### Refactorings

* **image-upload:** update dropbox ([92ca80c](https://github.com/fleetyards/app/commit/92ca80c))



### [3.5.4](https://github.com/fleetyards/app/compare/v3.5.3...v3.5.4) (2019-07-26)


### Bug Fixes

* **shop-commodities:** update filter ([#725](https://github.com/fleetyards/app/issues/725)) ([7619cd3](https://github.com/fleetyards/app/commit/7619cd3))



### [3.5.3](https://github.com/fleetyards/app/compare/v3.5.2...v3.5.3) (2019-07-22)



### [3.5.2](https://github.com/fleetyards/app/compare/v3.5.1...v3.5.2) (2019-07-22)


### Bug Fixes

* **service-worker:** correct controller name ([5ba576e](https://github.com/fleetyards/app/commit/5ba576e))



### [3.5.1](https://github.com/fleetyards/app/compare/v3.5.0...v3.5.1) (2019-07-21)


### Bug Fixes

* **hangar:** use correct counts for manufacture pie chart ([16d07a2](https://github.com/fleetyards/app/commit/16d07a2))



## [3.5.0](https://github.com/fleetyards/app/compare/v3.4.2...v3.5.0) (2019-07-21)


### Features

* **hangar:** add stats page ([#718](https://github.com/fleetyards/app/issues/718)) ([ebbcff6](https://github.com/fleetyards/app/commit/ebbcff6))



### [3.4.2](https://github.com/fleetyards/app/compare/v3.4.1...v3.4.2) (2019-07-21)



### [3.4.1](https://github.com/fleetyards/app/compare/v3.4.0...v3.4.1) (2019-07-21)


### Bug Fixes

* **models:** update last_updated_at ([5aa133b](https://github.com/fleetyards/app/commit/5aa133b))


### Refactorings

* **models:** remove fallback fields and update admin form ([54965c2](https://github.com/fleetyards/app/commit/54965c2))



## [3.4.0](https://github.com/fleetyards/app/compare/v3.3.1...v3.4.0) (2019-07-20)


### Bug Fixes

* **model-import:** allow override of multiple fields ([0058adf](https://github.com/fleetyards/app/commit/0058adf))


### Features

* **embed:** reuse LazyImage component and add sales icon ([bba9ae1](https://github.com/fleetyards/app/commit/bba9ae1))
* **hangar-export:** add csv export for hangar data ([#699](https://github.com/fleetyards/app/issues/699)) ([e04e3be](https://github.com/fleetyards/app/commit/e04e3be))


### Refactorings

* **settings:** seperate hangar settings from profile ([73a14a1](https://github.com/fleetyards/app/commit/73a14a1))



### [3.3.1](https://github.com/fleetyards/app/compare/v3.3.0...v3.3.1) (2019-07-15)



## [3.3.0](https://github.com/fleetyards/app/compare/v3.2.58...v3.3.0) (2019-07-14)


### Features

* **noty:** update notification styling ([8ee320f](https://github.com/fleetyards/app/commit/8ee320f))
