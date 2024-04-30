FROM nvcr.io/nvidia/tensorrt:22.12-py3 as final
ENV	DEBIAN_FRONTEND=noninteractive
ENV CMAKE_VERSION=3.26.0
ENV ORT_VERSION=1.17.1
RUN apt-get update  \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git cmake ccache sudo pkg-config zip g++ zlib1g-dev unzip libyaml-cpp-dev nlohmann-json3-dev \
    libgrpc-dev curl autotools-dev autoconf automake libasio-dev libtinyxml2-dev \
    wget htop vim git libboost-all-dev libeigen3-dev libopencv-dev  uuid-dev libncurses5-dev clang\
    sshpass openssh-server git-lfs iproute2 libopencv-dev\
    && apt-get clean && rm -rf /var/lib/apt/lists/* && rm /usr/local/bin/cmake

# upgrade cmake for x86_64 and aarch64, and copy cmake config files
RUN wget -O /tmp/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    && tar -zxf /tmp/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz --strip=1 -C /usr \
    && tar -zxf /tmp/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz --strip=1 -C /opt/bstos/2.3.1.5/sysroots/x86_64-bstsdk-linux/usr/ \
    && cp /opt/bstos/2.3.1.5/sysroots/x86_64-bstsdk-linux/usr/share/cmake-3.14/Modules/CMakeDetermineSystem.cmake /usr/share/cmake-3.26/Modules/ \
    && cp /opt/bstos/2.3.1.5/sysroots/x86_64-bstsdk-linux/usr/share/cmake-3.14/Modules/CMakeDetermineSystem.cmake /opt/bstos/2.3.1.5/sysroots/x86_64-bstsdk-linux/usr/share/cmake-3.26/Modules/CMakeDetermineSystem.cmake

RUN wget https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/onnxruntime-linux-x64-gpu-${ORT_VERSION}.tgz -O /tmp/onnxruntime-linux-x64-gpu-${ORT_VERSION}.tgz \
    && tar -xf /tmp/onnxruntime-linux-x64-gpu-${ORT_VERSION}.tgz --strip-components=1 -C /usr/local \
    && rm -rf /tmp/onnxruntime-linux-x64-gpu-${ORT_VERSION}.tgz


# Clone the repository and build
RUN git clone https://github.com/nndeploy/nndeploy.git --single-branch --depth 1  \
    && cd nndeploy \
    && mkdir -p build \
    && cp cmake/config.cmake build \
    && cd build \
    && cmake ..  \
      -DENABLE_NNDEPLOY_DEVICE_CPU=ON \
      -DENABLE_NNDEPLOY_DEVICE_X86=ON \
      -DENABLE_NNDEPLOY_DEVICE_CUDA=ON \
      -DENABLE_NNDEPLOY_DEVICE_CUDNN=ON \
      -DENABLE_NNDEPLOY_INFERENCE_TENSORRT=ON \
      -DENABLE_NNDEPLOY_MODEL_DETECT=ON \
    && make -j$(nproc) \
    && make install


WORKDIR /nndeploy

