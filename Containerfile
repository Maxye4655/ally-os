# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY config /config
COPY scripts /scripts
COPY services /services
COPY hyprland.conf /hyprland.conf

# Base Image
# Bazzite deck image: Steam Gaming Mode + the full controller stack
# (gamescope-session, steamos-compositor, handheld-daemon, asusctl,
# supergfxctl, power-profiles-daemon). Only the deck's *desktop session*
# is swapped for Hyprland — the gaming mode is left untouched.
FROM ghcr.io/ublue-os/bazzite-deck:stable
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite-deck:testing
# FROM ghcr.io/ublue-os/bazzite:stable
# For reproducibility, pin a digest, e.g.:
# FROM ghcr.io/ublue-os/bazzite-deck:stable@sha256:...

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
