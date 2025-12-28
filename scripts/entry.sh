#!/bin/bash

cd ${STEAMAPPDIR}

#####################################
#                                   #
# Force an update if the env is set #
#                                   #
#####################################

if [ "${FORCESTEAMCLIENTSOUPDATE}" == "1" ]; then
  echo "FORCESTEAMCLIENTSOUPDATE variable is set, updating steamclient.so in Zomboid's server"
  cp "${STEAMCMDDIR}/linux64/steamclient.so" "${STEAMAPPDIR}/linux64/steamclient.so"
  cp "${STEAMCMDDIR}/linux32/steamclient.so" "${STEAMAPPDIR}/steamclient.so"
fi

if [ "${FORCEUPDATE}" == "1" ]; then
  echo "FORCEUPDATE variable is set, so the server will be updated right now"
  bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" +login anonymous +app_update "${STEAMAPPID}" ${STEAMAPPBRANCH:+-beta "$STEAMAPPBRANCH"} validate +quit
fi


######################################
#                                    #
# Process the arguments in variables #
#                                    #
######################################
ARGS=""

# Set the server memory. Units are accepted (1024m=1Gig, 2048m=2Gig, 4096m=4Gig): Example: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Option to perform a Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# End of Java arguments
ARGS="${ARGS} -- "

# Runs a coop server instead of a dedicated server. Disables the default admin from being accessible.
# - Default: Disabled
if [ "${COOP}" == "1" ] || [ "${COOP,,}" == "true" ]; then
  ARGS="${ARGS} -coop"
fi

# Disables Steam integration on server.
# - Default: Enabled
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Sets the path for the game data cache dir.
# - Default: ~/Zomboid
# - Example: /server/Zomboid/data
if [ -n "${CACHEDIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHEDIR}"
fi

# Option to control where mods are loaded from and the order. Any of the 3 keywords may be left out and may appear in any order.
# - Default: workshop,steam,mods
# - Example: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Launches the game in debug mode.
# - Default: Disabled
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Option to set the admin username. Current admins will not be changed.
if [ -n "${ADMINUSERNAME}" ]; then
  ARGS="${ARGS} -adminusername ${ADMINUSERNAME}"
fi

# Option to bypasses the enter-a-password prompt when creating a server.
# This option is mandatory the first startup or will be asked in console and startup will fail.
# Once is launched and data is created, then can be removed without problem.
# Is recommended to remove it, because the server logs the arguments in clear text, so Admin password will be sent to log in every startup.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# Server password (Doesn't work)
#if [ -n "${PASSWORD}" ]; then
#  ARGS="${ARGS} -password ${PASSWORD}"
#fi

# You can choose a different servername by using this option when starting the server.
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername \"${SERVERNAME}\""
else
  # If not servername is set, use the default name in the next step
  SERVERNAME="servertest"
fi

# If preset is set, then the config file is generated when it doesn't exists or SERVERPRESETREPLACE is set to True.
if [ -n "${SERVERPRESET}" ]; then
  # If preset file doesn't exists then show an error and exit
  if [ ! -f "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" ]; then
    echo "*** ERROR: the preset ${SERVERPRESET} doesn't exists. Please fix the configuration before start the server ***"
    exit 1
  # If SandboxVars files doesn't exists or replace is true, copy the file
  elif [ ! -f "/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua" ] || [ "${SERVERPRESETREPLACE,,}" == "true" ]; then
    echo "*** INFO: New server will be created using the preset ${SERVERPRESET} ***"
    echo "*** Copying preset file from \"${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua\" to \"/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua\" ***"
    mkdir -p "/root/Zomboid/Server/"
    cp -nf "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" "/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    sed -i "1s/return.*/SandboxVars = \{/" "/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # Remove carriage return
    dos2unix "/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # I have seen that the file is created in execution mode (755). Change the file mode for security reasons.
    chmod 644 "/root/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
  fi
fi

# Option to handle multiple network cards. Example: 127.0.0.1
if [ -n "${IP}" ]; then
  ARGS="${ARGS} ${IP} -ip ${IP}"
fi

# Set the DefaultPort for the server. Example: 16261
if [ -n "${PORT}" ]; then
  ARGS="${ARGS} -port ${PORT}"
fi

# Option to enable/disable VAC on Steam servers. On the server command-line use -steamvac true/false. In the server's INI file, use STEAMVAC=true/false.
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

# Steam servers require two additional ports to function (I'm guessing they are both UDP ports, but you may need TCP as well).
# These are in addition to the DefaultPort= setting. These can be specified in two ways:
#  - In the server's INI file as SteamPort1= and SteamPort2=.
#  - Using STEAMPORT1 and STEAMPORT2 variables.
if [ -n "${STEAMPORT1}" ]; then
  ARGS="${ARGS} -steamport1 ${STEAMPORT1}"
fi
if [ -n "${STEAMPORT2}" ]; then
  ARGS="${ARGS} -steamport2 ${STEAMPORT2}"
fi

if [ -n "${PASSWORD}" ]; then
  # Changed delimiter to | to handle passwords with special chars
  sed -i "s|Password=.*|Password=${PASSWORD}|" "/root/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${MOD_IDS}" ]; then
  echo "*** INFO: Found Mods including ${MOD_IDS} ***"
  # Changed delimiter to |
  sed -i "s|Mods=.*|Mods=${MOD_IDS}|" "/root/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${WORKSHOP_IDS}" ]; then
  echo "*** INFO: Found Workshop IDs including ${WORKSHOP_IDS} ***"
  # Changed delimiter to |
  sed -i "s|WorkshopItems=.*|WorkshopItems=${WORKSHOP_IDS}|" "/root/Zomboid/Server/${SERVERNAME}.ini"
else
  echo "*** INFO: Workshop IDs is empty, clearing configuration ***"
  sed -i 's|WorkshopItems=.*$|WorkshopItems=|' "/root/Zomboid/Server/${SERVERNAME}.ini"
fi

# Fixes EOL in script file for good measure
sed -i 's/\r$//' /server/scripts/search_folder.sh
# Check 'search_folder.sh' script for details
if [ -e "/root/pz-dedicated/steamapps/workshop/content/108600" ]; then

  map_list=""
  source /server/scripts/search_folder.sh "/root/pz-dedicated/steamapps/workshop/content/108600"
  map_list=$(<"/root/maps.txt")  
  rm "/root/maps.txt"

  if [ -n "${map_list}" ]; then
    echo "*** INFO: Added maps including ${map_list} ***"
    sed -i "s|Map=.*|Map=${map_list}Muldraugh, KY|" "/root/Zomboid/Server/${SERVERNAME}.ini"

    # Checks which added maps have spawnpoints.lua files and adds them to the spawnregions file if they aren't already added
    IFS=";" read -ra strings <<< "$map_list"
    for string in "${strings[@]}"; do
        if ! grep -q "$string" "/root/Zomboid/Server/${SERVERNAME}_spawnregions.lua"; then
          if [ -e "/root/pz-dedicated/media/maps/$string/spawnpoints.lua" ]; then
            result="{ name = \"$string\", file = \"media/maps/$string/spawnpoints.lua\" },"
            sed -i "/function SpawnRegions()/,/return {/ {    /return {/ a\
            \\\t\t$result
            }" "/root/Zomboid/Server/${SERVERNAME}_spawnregions.lua"
          fi
        fi
    done
  fi 
fi

# Fix to a bug in start-server.sh that causes to no preload a library:
# ERROR: ld.so: object 'libjsig.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
export LD_LIBRARY_PATH="${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}"

export LANG=${LANG} && export LD_LIBRARY_PATH="${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}" && cd ${STEAMAPPDIR} && pwd && ./start-server.sh ${ARGS}
