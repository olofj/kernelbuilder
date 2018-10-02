FROM gentoo/portage:latest as portage

# image is based on stage3-amd64
FROM gentoo/stage3-amd64:latest

# copy the entire portage volume in
COPY --from=portage /usr/portage /usr/portage

COPY make.conf /etc/portage

# Need to disable sandboxes due to lack of elevated privileges during build
RUN FEATURES="-sandbox -usersandbox"  emerge -e world

# continue with image build ...
