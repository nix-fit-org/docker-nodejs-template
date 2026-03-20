FROM --platform=${BUILDPLATFORM} nix-docker.registry.twcstorage.ru/ci/build/nodejs-build:22.20.0003 AS builder

WORKDIR /src

COPY --chown=1000:1000 package.json package-lock.json ./

RUN npm ci

COPY --chown=1000:1000 . .

RUN npm run build:prod

FROM nix-docker.registry.twcstorage.ru/base/redhat/ubi10-minimal:10.1002-1766033715

ARG NODEJS_MAJOR_VERSION=22
ARG NODEJS_VERSION=22.20.0

RUN curl -kLso nodejs_${NODEJS_MAJOR_VERSION}.sh "https://rpm.nodesource.com/setup_${NODEJS_MAJOR_VERSION}.x" \
    && chmod +x nodejs_${NODEJS_MAJOR_VERSION}.sh \
    && ./nodejs_${NODEJS_MAJOR_VERSION}.sh \
    && microdnf -y --refresh \
                --setopt=install_weak_deps=0 \
                --setopt=tsflags=nodocs \
                --disablerepo=nodesource-nsolid install nodejs-${NODEJS_VERSION} \
    && node --version \
    && microdnf clean all \
    && rm -rf /var/cache/dnf /var/cache/yum

WORKDIR /app

COPY --from=builder /src/package.json /src/package-lock.json ./

RUN npm ci --omit=dev

COPY --from=builder /src/build .

EXPOSE 3000

ENTRYPOINT ["node", "/app/index.js"]
