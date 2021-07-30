# pages-redirects

[![CircleCI](https://circleci.com/gh/18F/pages-redirects.svg?style=svg)](https://circleci.com/gh/18F/pages-redirects)

This app redirects traffic from previous `pages.18f.gov` sites to their new URLs,
which are usually a subdomain of `18f.gov` (eg `pages.18f.gov/boop` → `boop.18f.gov`).

This app also contains a number of non-pages.18f.gov-related redirects that were
previously handled by [federalist-redirects](https://github.com/18F/federalist-redirects).
These redirect rules can be found in [`templates/_federalist-redirects.njk`](./templates/_federalist-redirects.njk).

## Adding a new redirect

### pages.18f.gov redirects
To add a new redirect from a retired pages.18f.gov to its new 18f.gov-subdomain home,
you will need to edit [`pages.yml`](/pages.yml). Please open a [Pull Request](https://github.com/18F/pages-redirects/pull/new/main)
with your modifications.

If you need to add a simple redirect of `pages.18f.gov/site-name` to `site-name.18f.gov`,
simply add a new line to the `pages.yml` that looks like:

```yml
- site-name
```

If you need to change the name of the old page to something new, like
`pages.18f.gov/old-name` to `new-name.18f.gov`,
add lines of the following form to `pages.yml`:

```yml
- from: old-name
  to: new-name
```

If you need to redirect to a _different domain_ from `18f.gov`, like
`pages.18f.gov/old-name` to `new-name.new-domain.gov`,
add lines of the following form to `pages.yml`:

```yml
- from: old-name
  to: new-name
  toDomain: new-domain.gov
```

Additionally you can redirect to a _custom path_ on that domain, like
`pages.18f.gov/old-name` to `new-name.new-domain.gov/custom-path`,
add lines of the following form to `pages.yml`:

```yml
- from: old-name
  to: new-name
  toDomain: new-domain.gov
  toPath: custom-path
```

### Domain redirects
To create a redirect for yourOrigDomain.gov to yourNewDomain.gov, perform the following steps:
1. Add a route for yourOrigDomain.gov in [`manifest-prod.yml.njk`](/templates/manifest-prod.yml.njk)
```
route: yourOrigDomain.gov
```
2. Add a redirect configuration in [`_federalist-redirects.njk`](/templates/_federalist-redirects.njk):
```
server {
  listen {{ PORT }};
  set $target_domain yourNewDomain.gov;
  server_name yourOrigDomain.gov;
  return 301 https://$target_domain;
}
```
3. Add yourdOldDomain.gov as an external link to [`docker-compose.yml`](/docker-compose.yml)
```
app:yourOrigDomain.gov
```
4. Test this app as described below in the `Testing` section
5. Ask an administrator to create a [`custom-domain`](https://cloud.gov/docs/apps/custom-domains/) for `yourOrigDomain.gov` and to provide you the generated CNAME and TXT record
```
cf create-service cdn-route cdn-route yourOrigDomain.gov -c '{"domain": "yourOrigDomain.gov"}'
```
6. Update the DNS settings (CNAME and TXT record) for yourOrigDomain.gov with the details specified by your custom-domain

Once your changes are merged into `main` by an administrator,
the `pages-redirects` app will be redeployed by CircleCI and your redirects
should start working within a few minutes.

## Developing

This is a NodeJS-based project that uses [`yarn`](https://yarnpkg.com/) for managing node dependencies.
After making sure you have it installed, run `yarn` to install dependencies.

The NodeJS code (called from [`build.js`](/build.js)) reads an array of sites to
redirect from the [`pages.yml`](/pages.yml) file and inserts new NGINX rewrite rules
into the [`nginx.conf.njk`](/templates/nginx.conf.njk) template in [`templates/`](/templates).
The resulting `nginx.conf` files (one for testing in [Docker](#local-docker) and one
for the production site) are written to the `out/` directory.
The build script also produces a CloudFoundry manifest file at `out/manifest-prod.yml` for deploying this app to cloud.gov.

## Testing

To run unit tests, run `yarn test`.

### Integration Tests

#### Local Docker

You can run integration tests locally against a Docker container.
First make sure you have [Docker][] and [Docker Compose][] installed, and maybe
give the [18F Docker guide][] a read.

Then build and run tests in the docker-compose network:

```sh
yarn build-docker && yarn test-docker
```

#### Real server

To run integration tests against a real server:

```sh
TARGET_HOST=<FULL_URL_TOSERVER> yarn test-integration
```

For example:

```sh
TARGET_HOST=https://pages-redirects.app.cloud.gov yarn test-integration
```

## Deploying

This is deployed in GovCloud cloud.gov:

- org: `gsa-18f-federalist`
- space: `redirects`

### Automated Deployments

This app is automatically deployed by CircleCI when commits are pushed to the
`main` branch (such as from a merged Pull Request). Deployments are done with
the [cf-autopilot][] plugin so that there will be no downtime.

See [`circle.yml`](/circle.yml) and [`deploy-ci.sh`](/deploy-ci.sh) for details.

### Manual Deployments

To manually deploy (this should not be necessary):

```sh
yarn build
cf push -f out/manifest-prod.yml`
```

[18F Docker guide]: https://pages.18f.gov/dev-environment-standardization/virtualization/docker/
[Docker]: https://www.docker.com/
[Docker Compose]: https://docs.docker.com/compose/
[cf-autopilot]: https://github.com/contraband/autopilot
