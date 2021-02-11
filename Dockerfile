FROM klakegg/hugo:0.80.0-ext-pandoc AS builder

ARG HUGO_ENV=default

COPY . /src

RUN hugo --environment ${HUGO_ENV} --minify

FROM nginxinc/nginx-unprivileged:alpine

EXPOSE 8080

COPY --from=builder /src/public /usr/share/nginx/html
