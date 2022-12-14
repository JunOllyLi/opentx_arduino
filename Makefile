TOP_DIR := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
OPENTX_SRCDIR = ${TOP_DIR}/edgetx

BSP ?= ESP32V2

BUILD_DIR = ${TOP_DIR}/build
OPENTX_BUILD_DIR = ${BUILD_DIR}/opentx
OPENTX_LIB_DIR = ${OPENTX_BUILD_DIR}/radio/src
OPENTX_LIB = ${OPENTX_LIB_DIR}/libfirmware.a
BSP_BUILD_DIR = ${BUILD_DIR}/arduino_freertos_bsp

ifeq ($(BSP),ESP32V2)
  BSP_DIR = ${TOP_DIR}/boards/feather_esp32v2
  BSP_LIB = ${BSP_BUILD_DIR}/arduino.ar
else
  BSP_DIR = ${TOP_DIR}/boards/feather_stm32f405
  BSP_LIB = ${BSP_BUILD_DIR}/libcore.a
endif

.PHONY: firmware flash clean bsp_lib
firmware: ${OPENTX_BUILD_DIR}/CMakeCache.txt ${BSP_LIB}
	cd ${OPENTX_BUILD_DIR} && make tx_firmware
	make -C ${BSP_DIR} BUILD_DIR=${BSP_BUILD_DIR} firmware

${BSP_LIB}: ${BUILD_DIR}/toolchain.cmake
	mkdir -p ${BSP_BUILD_DIR}
	make -C ${BSP_DIR} BUILD_DIR=${BSP_BUILD_DIR} all

bsp_lib: ${BSP_LIB}

${BUILD_DIR}/toolchain.cmake:
	mkdir -p ${BUILD_DIR}
	make -C ${BSP_DIR} BUILD_DIR=${BSP_BUILD_DIR} TOOLCHAIN_FILE=$@ generate_toolchain_file

${OPENTX_BUILD_DIR}/CMakeCache.txt: ${BSP_LIB}
	@mkdir -p ${OPENTX_BUILD_DIR}
	cd ${OPENTX_BUILD_DIR} && cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=${BUILD_DIR}/toolchain.cmake -DDISABLE_COMPANION=YES -DGVARS=YES -DLUA=YES -DDEBUG=YES -DCMAKE_BUILD_TYPE=Debug ${OPENTX_SRCDIR}
	touch $@

flash:
	make -C ${BSP_DIR} BUILD_DIR=${BSP_BUILD_DIR} flash_firmware

clean:
	@rm -rf ${TOP_DIR}/build