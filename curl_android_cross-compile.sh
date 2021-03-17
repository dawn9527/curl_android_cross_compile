#!/bin/bash

# 创建编译目录
if [ -d "curl_android_cross-compile" ]; then
  rm -rf curl_android_cross-compile 
  echo 清空编译目录  curl_android_cross-compile 
fi

mkdir  curl_android_cross-compile
cd curl_android_cross-compile
ROOT_DIR=`pwd -P`
echo 创建Android交叉编译根目录 $ROOT_DIR

OUTPUT_DIR=$ROOT_DIR/output
mkdir $OUTPUT_DIR



# NDK 配置
export NDK_ROOT=/home/dawn9527/android/ndk-r13b/android-ndk-r13b
export PATH=$PATH:$NDK_ROOT

# 创建交叉编译标准工具链
$NDK_ROOT/build/tools/make_standalone_toolchain.py --arch arm --api 16 --install-dir ndk-standalone-toolchain
TOOLCHAIN=$ROOT_DIR/ndk-standalone-toolchain

# 设置交叉编译环境
export PATH=$PATH:$TOOLCHAIN/bin
export SYSROOT=$TOOLCHAIN/sysroot
export ARCH=armv7
export CC=arm-linux-androideabi-gcc
export CXX=arm-linux-androideabi-g++
export AR=arm-linux-androideabi-ar
export AS=arm-linux-androideabi-as
export LD=arm-linux-androideabi-ld
export RANLIB=arm-linux-androideabi-ranlib
export NM=arm-linux-androideabi-nm
export STRIP=arm-linux-androideabi-strip
export CHOST=arm-linux-androideabi
export CFLAGS=-Wall

OUTPUT_DIR=$ROOT_DIR/libcurl-android
mkdir $OUTPUT_DIR

# 下载编译zlib
mkdir -p $OUTPUT_DIR/zlib/lib/armeabi-v7a
mkdir $OUTPUT_DIR/zlib/include
ZLIB_DIR=$ROOT_DIR/zlib-1.2.8
wget https://zlib.net/fossils/zlib-1.2.8.tar.gz
tar -xvzf zlib-1.2.8.tar.gz
cd $ZLIB_DIR
# 解决 Compiler error reporting is too harsh for ./configure (perhaps remove -Werror)
cp $ROOT_DIR/../configure ./
./configure --static
make

# 拷贝静态库和头文件到 输出目录
cp libz.a $OUTPUT_DIR/zlib/lib/armeabi-v7a/
cp zconf.h $OUTPUT_DIR/zlib/include/ 
cp zlib.h $OUTPUT_DIR/zlib/include/
cd ..

# 下载编译 openssl
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2d.tar.gz
tar -xvf openssl-1.0.2d.tar.gz 
cd openssl-1.0.2d/
export CPPFLAGS="-mthumb -mfloat-abi=softfp -mfpu=vfp -march=${ARCH}  -DANDROID"
./Configure android-armv7 no-asm no-shared --static --with-zlib-include=${ZLIB_DIR}/include --with-zlib-lib=${ZLIB_DIR}/lib
make build_crypto build_ssl

# 拷贝静态库和头文件到 输出目录
mkdir -p $OUTPUT_DIR/openssl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/openssl/include
cp libssl.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp libcrypto.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp -LR include/openssl $OUTPUT_DIR/openssl/include
cd ..
OPENSSL_DIR=$ROOT_DIR/openssl-1.0.2d

# 下载编译 libcurl
wget http://curl.haxx.se/download/curl-7.45.0.tar.gz
tar -xvf curl-7.45.0.tar.gz 
cd curl-7.45.0
export CFLAGS="-v --sysroot=$SYSROOT -mandroid -march=$ARCH -mfloat-abi=softfp -mfpu=vfp -mthumb"
export CPPFLAGS="$CFLAGS -DANDROID -DCURL_STATICLIB -mthumb -mfloat-abi=softfp -mfpu=vfp -march=$ARCH -I${OPENSSL_DIR}/include/ -I${TOOLCHAIN}/include"
export LDFLAGS="-march=$ARCH -Wl,--fix-cortex-a8 -L${OPENSSL_DIR}"
./configure --host=arm-linux-androideabi --disable-shared --enable-static --disable-dependency-tracking --with-zlib=${ZLIB_DIR} --with-ssl=${OPENSSL_DIR} --without-ca-bundle --without-ca-path --enable-ipv6 --enable-http --enable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-manual --target=arm-linux-androideabi --prefix=/opt/curlssl 
make

# 拷贝静态库和头文件到 输出目录
mkdir -p $OUTPUT_DIR/curl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/curl/include
cp lib/.libs/libcurl.a $OUTPUT_DIR/curl/lib/armeabi-v7a
cp -LR include/curl $OUTPUT_DIR/curl/include
cd ..

echo Build result saved to $ROOT_DIR/$OUTPUT_FILE
