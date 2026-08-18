#!/bin/bash
 
# use or learn more -> https://github.com/KAZ-CORE/libnew_shell  
source libnew_shell

#for public varaible for example (path_temp_deb and path_target and ...)
source conf.sh 



get_deb() {
	
	
	color:start ${blue}
	
	local url="${address_mirror}/pool/main/${1}_${2}_${arch}.deb"
	
	printf "${url}\n"
	
	if ! curl -# -w "Downloaded: %{size_download} bytes, Speed: %{speed_download} B/s, Time: %{time_total} seconds\n" -O  "${url}"; then
		color:end
		
		log:failure "get_deb" "not can download ${url}" 
		exit 1
	fi

	color:end
	
	printf "\n" 

	
}

mkdir -p ${build}/ ${extracted_libs}/ ${path_temp_deb}/ ${path_target}/ ${path_target_lib}/
cd ${path_temp_deb}


				  				#path				 							#version
get_deb  "p/python${version_python}/libpython${version_python}"		 "${version_python}.5-2+deb13u3"
get_deb	 "p/python${version_python}/libpython${version_python}-dev"	 "${version_python}.5-2+deb13u3"
get_deb  "p/python-apt/python3-apt"	  								 "3.0.0"
get_deb  "g/glibc/libc6"		  	  								 "2.41-12+deb13u3" 
get_deb  "g/gcc-14/libstdc++6"	  	  								 "14.2.0-19"
get_deb  "g/gcc-14/libgcc-s1"	  	  								 "14.2.0-19"	
get_deb  "a/apt/libapt-pkg7.0"  	  								 "3.0.3"
get_deb  "b/bzip2/libbz2-1.0"	  	  								 "1.0.8-6"
get_deb  "x/xz-utils/liblzma5"  	  								 "5.8.1-1+deb13u1"
get_deb  "l/lz4/liblz4-1"	      	  								 "1.10.0-4"
get_deb  "libz/libzstd/libzstd1" 	  								 "1.5.7+dfsg-1"
get_deb  "s/systemd/libudev1"         								 "257.13-1~deb13u1"
get_deb  "s/systemd/libsystemd0"	  								 "257.13-1~deb13u1"
get_deb  "o/openssl/libssl3t64"	  	  								 "3.5.6-1~deb13u2"
get_deb  "x/xxhash/libxxhash0"	  	  								 "0.8.3-2"
get_deb  "e/expat/libexpat1"	  	  								 "2.7.1-2"
get_deb  "libc/libcap2/libcap2"		  								 "2.75-10+deb13u1+b1"
get_deb  "z/zlib/zlib1g"		  	  								 "1.3.dfsg+really1.3.1-1+b1"

cd ..


for deb in ${path_temp_deb}/*.deb; do
    if [ -f "${deb}" ]; then
    	if dpkg-deb -x "${deb}" .extracted_libs/; then 
    		color:print "Extracted ${deb}" ${green}
		else 
			color:print "not can extract ${deb}" ${red}
			exit 1
		fi		
	else
		color:print "not found ${deb}" ${red}
		exit 1
	fi

done


declare -A lib_used=(
    ["libapt-pkg.so.7.0"]=1
    ["libbz2.so.1.0"]=1
    ["libcap.so.2"]=1
    ["libcrypto.so.3"]=1
    ["libexpat.so.1"]=1
    ["libexpat.so"]=1
    ["libgcc_s.so.1"]=1
    ["liblz4.so.1"]=1
    ["liblzma.so.5"]=1
    ["libm.so.6"]=1
    ["libpython3.13.so.1.0"]=1
    ["libstdc++.so.6"]=1
    ["libsystemd.so.0"]=1
    ["libudev.so.1"]=1
    ["libxxhash.so.0"]=1
    ["libz.so.1"]=1
    ["libz.so"]=1
    ["libzstd.so.1"]=1
    ["libpython3.13.so"]=1
    ["libpython3.13.so.1"]=1
)


color:print "Retrieving required dependencies from extracted packages..." ${yellow}


find .extracted_libs | while read -r so_file; do
    filename=$(basename "${so_file}")
    base_name=$(echo "${filename}" | sed -E 's/\.[0-9]+.*$//')
    
    for needed in "${!lib_used[@]}"; do
        if [[ "${filename}" == "${needed}" ]] || [[ "${base_name}" == "${needed}"* ]]; then
            cp -d "${so_file}" ${path_target_lib}/
            break
        fi
    done
done


if [ -d ".extracted_libs/usr/lib/python3/dist-packages/apt" ]; then
    cp -r .extracted_libs/usr/lib/python3/dist-packages/apt 		   ${path_target}/
    cp    .extracted_libs/usr/lib/python3/dist-packages/apt_pkg*.so    ${path_lib_apt}/
    cp    .extracted_libs/usr/lib/python3/dist-packages/apt_inst*.so   ${path_lib_apt}/
fi

if [ -d ".extracted_libs/usr/include" ]; then
	cp -r .extracted_libs/usr/include 	${path_target}/
fi

rm -rf ${path_temp_deb} .extracted_libs


cd ${path_target_lib}

for lib in *.so*; do
    if [ -f "$lib" ] && [ ! -L "$lib" ]; then
        patchelf --force-rpath --set-rpath '$ORIGIN' "$lib"
    	color:print "repath elf ${lib}" ${blue}
    fi
done


cd ..

patchelf --force-rpath --set-rpath '$ORIGIN/../lib' apt/apt_pkg.cpython-313-*.so
patchelf --force-rpath --set-rpath '$ORIGIN/../lib' apt/apt_inst.cpython-313-*.so

color:print "repathed! elfs apt/apt_inst.cpython-313-*.so and apt/apt_pkg.cpython-313-*.so" ${blue}


for pyfile in apt/*.py apt/progress/*.py; do
    
    if cython -3 -o "${pyfile%.py}.c" "$pyfile"; then
    	color:print "CYHTON		${pyfile%.py}.c" ${blue}
    else
    	exit 1
    fi  
    
    if ${CC} ${CC_FLAGS} -o "${pyfile%.py}.so" "${pyfile%.py}.c"; then
    	color:print "CC    		${pyfile%.py}.so" ${purple}	
    else
        exit 1
	fi
	
done


rm -rf apt/*.c apt/progress/*.c


color:print "Operation completed successfully. Output is available at: ${path_target}" ${green}

exit 0



