FROM nvidia/cuda:12.0.1-devel-ubuntu22.04
ENV CUDA_VISIBLE_DEVICES=0  
ENV CUDA_DEVICE_MAX_CONNECTIONS=8
ENV NVIDIA_DRIVER_CAPABILITIES=compute,video
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DISPLAY=:1
ENV GST_DEBUG=2
ENV GST_DEBUG_DUMP_DOT_DIR=/tmp
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64/
ENV TF_FORCE_GPU_ALLOW_GROWTH=true
ENV TF_ENABLE_GPU_GARBAGE_COLLECTION=false
ENV FFmpeg_TAG=n8.0


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
    python3-pip nasm yasm \
    python-is-python3 yasm libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev vim

RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
cd nv-codec-headers && sed -i 's|PREFIX = /usr/local|PREFIX = /usr|' Makefile && git checkout n12.2.72.0 && make && make install && ldconfig && cd ..
#RUN apt-get install build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev

COPY ./Video_Codec_SDK_13.0.19.zip .
RUN unzip Video_Codec_SDK_13.0.19.zip

RUN cp Video_Codec_SDK_13.0.19/Interface/* /usr/include/
RUN cp Video_Codec_SDK_13.0.19/Lib/linux/stubs/x86_64/libnv* /usr/lib/x86_64-linux-gnu/

COPY ./Video_Codec_Interface_13.0.19.zip .
RUN unzip Video_Codec_Interface_13.0.19.zip
RUN cp Video_Codec_Interface_13.0.19/Interface/* /usr/include/

RUN apt install -y libx264-dev libx265-dev libvpx-dev libfdk-aac-dev \
  libmp3lame-dev libopus-dev


# RUN git clone https://github.com/FFmpeg/FFmpeg.git && \
#     cd FFmpeg && \
#     git checkout tags/$FFmpeg_TAG && \
#     ./configure \
#         --prefix="/usr/" \
#         --enable-nonfree  \
#         --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 \
#         --disable-static --enable-shared --enable-hwaccels \
#         --enable-cuda-nvcc \
#             --enable-libnpp \
#         --enable-v4l2-m2m --enable-v4l2-m2m --enable-v4l2-m2m --enable-vulkan && \        
#     make -j$(nproc) && \
#     make install && ldconfig && cd ....
#           --enable-ffnvcodec --enable-cuvid \

RUN git clone https://github.com/FFmpeg/FFmpeg.git && \
    cd FFmpeg && \
    git checkout tags/$FFmpeg_TAG && \
    ./configure \
        --prefix="/usr/" \
        --enable-gpl \
  --enable-nonfree \
  --enable-ffnvcodec \
  --enable-cuvid \
  --enable-nvdec \
  --enable-nvenc \
  --enable-cuda-nvcc \
  --enable-libnpp \
  --extra-cflags=-I/usr/local/cuda/include \
  --extra-ldflags=-L/usr/local/cuda/lib64 \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libfdk-aac \
  --enable-libmp3lame \
  --enable-libopus && \        
    make -j$(nproc) && \
    make install && ldconfig && cd ..


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


