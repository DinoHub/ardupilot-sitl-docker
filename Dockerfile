FROM ardupilot/ardupilot-dev-base

ARG COPTER_TAG=Copter-4.5.5

# install git 
RUN apt-get update && apt-get install -y git; git config --global url."https://github.com/".insteadOf git://github.com/

# Now grab ArduPilot from GitHub
RUN git clone https://github.com/ArduPilot/ardupilot.git ardupilot
WORKDIR /ardupilot

# Checkout the latest Copter...
RUN git checkout ${COPTER_TAG}

# Now start build instructions from http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html
RUN git submodule update --init --recursive

# Trick to get apt-get to not prompt for timezone in tzdata
ENV DEBIAN_FRONTEND=noninteractive

# Need sudo and lsb-release for the installation prerequisites
RUN apt-get install -y sudo lsb-release tzdata

# Continue build instructions from https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md
RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf copter

# TCP 5760 is what the sim exposes by default
EXPOSE 5760/tcp
EXPOSE 14550/udp

# Variables for simulator
ENV INSTANCE=0
ENV LAT=42.3898
ENV LON=-71.1476
ENV ALT=14
ENV DIR=270
ENV MODEL=+
ENV SPEEDUP=1
ENV VEHICLE=ArduCopter
ENV PATH="/usr/local/bin:/root/.local/bin:${PATH}"

RUN pip3 install --no-cache-dir MAVProxy pymavlink # Install MAVProxy

# Inject default param values to enable MavLink on other ports
RUN echo "SR1_EXTRA1 \t 4 \nSR1_EXTRA2 \t 4 \nSR1_EXTRA3 \t 4 \nSR1_EXT_STAT \t 4 \nSR1_PARAMS \t 4 \nSR1_POSITION \t 4 \nSR1_RAW_CTRL \t 0 \nSR1_RAW_SENS \t 4 \nSR1_RC_CHAN \t 0 \nSR2_ADSB \t 0 \nSR2_EXTRA1 \t 4 \nSR2_EXTRA2 \t 4 \nSR2_EXTRA3 \t 4 \nSR2_EXT_STAT \t 4 \nSR2_PARAMS \t 4 \nSR2_POSITION \t 4 \nSR2_RAW_CTRL \t 0 \nSR2_RAW_SENS \t 4 \nSR2_RC_CHAN \t 0 \n" >> /ardupilot/Tools/autotest/default_params/copter.parm

# Finally the command
ENV SITL_UDP_OUTPUT_ADDRESS=udp:127.0.0.1:14550
SHELL ["/bin/bash", "-c"]
ENTRYPOINT /ardupilot/Tools/autotest/sim_vehicle.py --vehicle ${VEHICLE} -I${INSTANCE} --custom-location=${LAT},${LON},${ALT},${DIR} -w --frame ${MODEL} --no-rebuild --speedup ${SPEEDUP} --out ${SITL_UDP_OUTPUT_ADDRESS}
