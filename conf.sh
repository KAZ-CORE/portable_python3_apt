
# seting (for normal user)

# example arch i386 amd64 amhf 
arch="amd64"

# example compiler i686-linux-gnu-gcc-13 aarch64-linux-gnu-gcc arm-linux-gnueabihf-gcc
CC="gcc"

# example https://example.com/debian
address_mirror="https://deb.debian.org/debian"






# Advance Seting (for developer)
version_python=3.13
CC_FLAGS="-shared -O3 -fPIC -I./include -I./include/python${version_python} -L./lib -lpython${version_python} -Wl,-rpath,\$ORIGIN/lib"
path_origin="$(pwd)"
build="build"
extracted_libs=".extracted_libs"
path_temp_deb=".tmp_deb"
path_target="build/${arch}"
path_target_lib="${path_target}/lib"
path_lib_apt="${path_target}/apt"
