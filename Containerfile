###########################################################
# Dockerfile that builds a Project Zomboid Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="daniel.carrasco@electrosoftcloud.com"

ENV STEAMAPPID=380870
ENV STEAMAPPDIR="/root/pz-dedicated"
ARG STEAMAPPBRANCH=""
ENV STEAMAPPBRANCH=$STEAMAPPBRANCH

RUN chown root:root /home/steam -R

RUN apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  dos2unix \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *\(es_ES.UTF-8\)/\1/' /etc/locale.gen \
  && locale-gen

RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
  +login anonymous \
  +app_update "${STEAMAPPID}" ${STEAMAPPBRANCH:+-beta "$STEAMAPPBRANCH"} validate \
  +quit

COPY scripts/entry.sh /server/scripts/entry.sh
RUN chmod 550 /server/scripts/entry.sh

COPY scripts/search_folder.sh /server/scripts/search_folder.sh
RUN chmod 550 /server/scripts/search_folder.sh

RUN mkdir -p "/root/Zomboid"

WORKDIR "/root"

EXPOSE 16261-16262/udp \
  27015/tcp

ENTRYPOINT ["/server/scripts/entry.sh"]
