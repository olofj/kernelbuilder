FROM gentoo/portage:latest as portage
FROM gentoo/stage3:x32-openrc as toolchains

# Slightly slimmer Gentoo
ENV FEATURE="buildpkg nodoc noinfo noman -ipc-sandbox -network-sandbox -pid-sandbox"

# copy the entire portage volume in
COPY --from=portage /var/db/repos /var/db/repos

RUN groupadd -g 1001 build
RUN useradd -m -u 1001 -g 1001 -s /bin/bash build

# Let's do a 1000 too
RUN groupadd -g 1000 user
RUN useradd -m -u 1000 -g 1000 -s /bin/bash user

USER build
WORKDIR /src
ENTRYPOINT ["/bin/bash"]
CMD "."
ENV PATH=${PATH}:/home/build/.local/bin:/home/user/.local/bin
