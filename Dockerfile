# Bittensor Dockerfile for Anaconda
# Copyright (C) 2020-2022  Chelsea E. Manning
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM xychelsea/anaconda3:v0.5.1
LABEL description="Bittensor Vanilla Container"

# $ docker build --network=host -t xychelsea/bittensor:latest -f Dockerfile .
# $ docker run --rm -it -p 8091:8091 xychelsea/bittensor:latest /bin/bash
# $ docker push xychelsea/bittensor:latest

ENV ANACONDA_ENV=bittensor
ENV BITTENSOR_PATH=/usr/local/bittensor
ENV BITTENSOR_WORKSPACE=${BITTENSOR_PATH}/workspace
ENV PATH=${PATH}:${BITTENSOR_PATH}/bin

# Start as root
USER root

# Update packages
RUN apt-get update --fix-missing \
    && apt-get -y upgrade \
    && apt-get -y dist-upgrade

# Install dependencies
RUN apt-get install --no-install-recommends --no-install-suggests -y \
    apt-utils \
    build-essential \
    cmake \
    curl \
    git \
    iproute2 \
    python3-dev \
    software-properties-common \
    unzip \
    wget

# Create DeepFaceLab directory
RUN mkdir -p ${BITTENSOR_PATH} \
    && fix-permissions ${BITTENSOR_PATH}

# Switch to user "anaconda"
USER ${ANACONDA_UID}
WORKDIR ${HOME}

# Update Anaconda
RUN conda update -c defaults conda

# add Bittensor code to docker image
RUN git clone https://github.com/xychelsea/bittensor ${BITTENSOR_PATH} \
    && mkdir -p ${BITTENSOR_WORKSPACE} \
    && rm -rvf ${BITTENSOR_PATH}/share/jupyter/lab/staging

# Create environment and install dependencies
RUN conda create -n ${ANACONDA_ENV} -c conda-forge \
    numpy=1.22.4 \
    pip=22.1.2 \
    python=3.10.5 \
    python-devtools=0.8.0

WORKDIR ${BITTENSOR_PATH}

RUN conda run -n ${ANACONDA_ENV} pip install --upgrade numpy pandas pip setuptools "tqdm>=4.27,<4.50.0" wheel
RUN conda run -n ${ANACONDA_ENV} pip install -r requirements.txt
RUN conda run -n ${ANACONDA_ENV} pip install .

# Switch back to root
USER root

RUN fix-permissions ${BITTENSOR_WORKSPACE} \
    && ln -s ${BITTENSOR_WORKSPACE} ${HOME}/.bittensor \
    && ln -s ${BITTENSOR_WORKSPACE} ${HOME}/data \
    && ln -s ${BITTENSOR_PATH} ${HOME}/bittensor

# Clean up anaconda
RUN conda clean -afy

# Clean packages and caches
RUN apt-get --purge -y autoremove git \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && rm -rvf /home/${ANACONDA_PATH}/.cache/yarn \
    && fix-permissions ${HOME} \
    && fix-permissions ${ANACONDA_PATH}

EXPOSE 8091

# Re-activate user "anaconda"
USER $ANACONDA_UID
WORKDIR $HOME
