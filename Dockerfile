########
# base #
########

# なぜかbuster以外だと、WASMビルドで真っ白表示になってしまう
FROM golang:1.24-bullseye AS base
RUN apt update
RUN apt install -y \
    gcc \
    libc6-dev \
    libgl1-mesa-dev \
    libxcursor-dev \
    libxi-dev \
    libxinerama-dev \
    libxrandr-dev \
    libxxf86vm-dev \
    libasound2-dev \
    pkg-config \
    xorg-dev \
    libx11-dev \
    libopenal-dev \
    upx-ucl

###########
# builder #
###########

FROM base AS builder

WORKDIR /build
COPY go.mod ./
COPY go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

#######
# app #
#######

FROM builder AS app

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GO111MODULE=on \
    go build -o ./bin/na2me .
RUN upx-ucl --best --ultra-brute ./bin/na2me

###########
# release #
###########

FROM gcr.io/distroless/base-debian11:latest AS release

COPY --from=app /build/bin/na2me /bin/
WORKDIR /work
ENTRYPOINT ["na2me"]

########
# node #
########

FROM node:25 as releaser
RUN yarn install

##########
# filter #
##########

FROM python:3.14.3-slim-bookworm as filter
RUN apt update -y
RUN apt install python3-opencv -y
COPY ./scripts/filter/requirements.txt .
RUN pip install -r requirements.txt
