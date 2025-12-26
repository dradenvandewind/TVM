FROM nvidia/cuda:12.0.1-devel-ubuntu22.04

ENV NVIDIA_DRIVER_CAPABILITIES=compute,video

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get -y install \
    libavfilter-dev \
    libavformat-dev \
    libavcodec-dev \
    libswresample-dev \
    libavutil-dev\
    wget \
    build-essential \
    ninja-build \
    cmake \
    git \
    python3 \
    python3-pip \
    python-is-python3



ARG PIP_INSTALL_EXTRAS=""



RUN git clone https://github.com/NVIDIA/VideoProcessingFramework && \
    cd VideoProcessingFramework && \
    python3 -m pip install --no-cache-dir setuptools wheel && cd .. 
    #python3 -m pip install --no-cache-dir .[$PIP_INSTALL_EXTRAS] && cd ..







COPY . .
RUN pip install -r requirements.txt

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=user

RUN groupadd -g $GROUP_ID $USERNAME && \
    useradd -u $USER_ID -g $GROUP_ID -m -s /bin/bash $USERNAME

RUN usermod -aG video,audio $USERNAME
RUN groupadd -g 109 render
#getent group render

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
CMD date || exit 1


CMD ["/bin/bash"]


