#!/bin/bash

# Terminate on error
set -e

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/nethserver}"
# Configure the image name
reponame="nextcloud"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-nextcloud container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-nextcloud; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-nextcloud -v "${PWD}:/usr/src:Z" docker.io/node:lts
fi

echo "Build static UI files with node..."
buildah run --env="NODE_OPTIONS=--openssl-legacy-provider" nodebuilder-nextcloud sh -c "cd /usr/src/ui && yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@any:routeadm cluster:accountconsumer" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.min-from=1.4.3" \
    --label="org.nethserver.images=docker.io/redis:7.4.4-alpine docker.io/mariadb:10.6.22 docker.io/nginx:1.28.0-alpine ghcr.io/nethserver/nextcloud-app:${IMAGETAG} ghcr.io/nethserver/nextcloud-notify_push:${IMAGETAG}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

# Build nextcloud-app image
pushd nextcloud
buildah build -t ${repobase}/nextcloud-app
popd

# Append the image URL to the images array
images+=("${repobase}/nextcloud-app")

# Build notify_push image (Files High Performance Backend)
pushd notify_push
buildah build -t ${repobase}/nextcloud-notify_push
popd

# Append the image URL to the images array
images+=("${repobase}/nextcloud-notify_push")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github.
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
