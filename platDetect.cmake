if(MSVC)
	if (CMAKE_VS_PLATFORM_NAME STREQUAL "Win32")
		option(BUILD_32_BITS "build for 32 bit" ON)
		#set(PLATFORM_NAME "Win32")
	else()
		option(BUILD_32_BITS "build for 32 bit" OFF)
		#set(PLATFORM_NAME "x64")
	endif()

	if( ${CMAKE_SYSTEM_VERSION} LESS_EQUAL 6.0)
		set(PLATFORM_NAME "${CMAKE_VS_PLATFORM_NAME}_XP")
	else()
		set(PLATFORM_NAME "${CMAKE_VS_PLATFORM_NAME}")
	endif()

	if(BUILD_32_BITS)
		set(PLATFORM_BITS 32)
	else()
		set(PLATFORM_BITS 64)
	endif()

	set(PTHREAD_LIBS "")
elseif(ANDROID)
	set(PLATFORM_NAME "android-${ANDROID_ABI}")
	set(PTHREAD_LIBS "")
else()
	#PLATFORM_BITS
	#PLATFORM_VERSION
	#PLATFORM_ARCH
	find_program(CMAKE_UNAME uname /bin /usr/bin /usr/local/bin)
	if(CMAKE_UNAME)
		execute_process(COMMAND ${CMAKE_UNAME} "-m"
				OUTPUT_VARIABLE OS_MACHINE)
		#delete tailing \n
		string(REGEX REPLACE "(.*)\n" "\\1" OS_MACHINE ${OS_MACHINE})
		message(OS_MACHINE " = ${OS_MACHINE}")
		string(REGEX MATCH ".*64.*" OS_64BITS ${OS_MACHINE})
		message(OS_64BITS " = ${OS_64BITS}")
		if(OS_64BITS)
			message("build 64 bits")
			option(BUILD_32_BITS "build for 32 bit" OFF)
		else(OS_64BITS)
			message("build 32 bits")
			option(BUILD_32_BITS "build for 32 bit" ON)
		endif(OS_64BITS)

		set(PLATFORM_ARCH ${OS_MACHINE})
		message(PLATFORM_ARCH " = ${PLATFORM_ARCH}")

		execute_process(COMMAND ${CMAKE_UNAME} "-r"
				OUTPUT_VARIABLE OS_KRELEASE)
		#delete tailing \n
		string(REGEX REPLACE "(.*)\n" "\\1" OS_KRELEASE ${OS_KRELEASE})
		message(OS_KRELEASE " = ${OS_KRELEASE}")
		string(REGEX MATCH "^[0-9]*\.[0-9]*\.[0-9]*" PLATFORM_VERSION ${OS_KRELEASE})
		message(PLATFORM_VERSION " = ${PLATFORM_VERSION}")
	else(CMAKE_UNAME)
                message(FATAL_ERROR  "Can't find command uname")
	endif(CMAKE_UNAME)
	if(BUILD_32_BITS)
		set(PLATFORM_BITS 32)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
	else()
		set(PLATFORM_BITS 64)
	endif()

	#PLATFORM_NAME
	file(STRINGS /etc/issue OS_ISSUE)
	if (OS_ISSUE)
		string(REGEX MATCH "[^ ]*" OS_ISSUE_NAME ${OS_ISSUE})
		message(OS_ISSUE_NAME " = ${OS_ISSUE_NAME}")
		if(OS_ISSUE_NAME STREQUAL "NeoKylin")
			if(PLATFORM_VERSION STREQUAL "3.10.0")
				set(PLATFORM_NAME "neokylin-${PLATFORM_BITS}")
			else()
				set(PLATFORM_NAME "neokylin-${PLATFORM_ARCH}-${PLATFORM_BITS}")
			endif()
		elseif(OS_ISSUE_NAME STREQUAL "CentOS")
			if(PLATFORM_VERSION STREQUAL "2.6.32")
				set(PLATFORM_NAME "centos-${PLATFORM_BITS}")
			else()
				set(PLATFORM_NAME "centos-${PLATFORM_VERSION}-${PLATFORM_BITS}")
			endif()
		elseif(OS_ISSUE_NAME STREQUAL "Kylin")
			if(PLATFORM_VERSION STREQUAL "4.4.58")
				set(PLATFORM_NAME "kylin-${PLATFORM_BITS}")
			else()
				set(PLATFORM_NAME "kylin-${PLATFORM_VERSION}-${PLATFORM_BITS}")
			endif()
		elseif(OS_ISSUE_NAME STREQUAL "Ubuntu")
			if(PLATFORM_VERSION STREQUAL "4.15.0")
				set(PLATFORM_NAME "ubuntu-18.04-${PLATFORM_BITS}")
			else()
				set(PLATFORM_NAME "ubuntu-${PLATFORM_VERSION}-${PLATFORM_BITS}")
			endif()
		elseif(OS_ISSUE_NAME STREQUAL "uos")
			set(PLATFORM_NAME "uos-${PLATFORM_ARCH}-${PLATFORM_BITS}")
		elseif(OS_ISSUE_NAME STREQUAL "iSoft")
			set(PLATFORM_NAME "iSoft-${PLATFORM_ARCH}-${PLATFORM_BITS}")
		elseif(OS_ISSUE_NAME STREQUAL "macOS")
			set(PLATFORM_NAME "macOS-${PLATFORM_ARCH}-${PLATFORM_BITS}")
        else()
			message(FATAL_ERROR  "Unknown platform ${OS_ISSUE_NAME}")
		endif()
	else(OS_ISSUE)
		message(FATAL_ERROR  "Can't find file: /etc/issue")
	endif(OS_ISSUE)
	message(PLATFORM_NAME " = ${PLATFORM_NAME}")

	set(PTHREAD_LIBS "pthread")
endif()

if(MSVC)
	set(LOCAL_DEFINITIONS "")
else()
	set(LOCAL_DEFINITIONS "-fPIC")
endif()
option(BUILD_DEBUG "build debug" OFF)
if(BUILD_DEBUG)
	set(LOCAL_DEFINITIONS "${LOCAL_DEFINITIONS} -g")
endif()
add_definitions("${LOCAL_DEFINITIONS}")

# Use the static C library for all build types to a target, https://blog.csdn.net/10km/article/details/79973750
function (with_mt_if_msvc target)
	if(MSVC)
		# Generator expression
		set(_mt "$<$<CONFIG:DEBUG>:/MDd>$<$<NOT:$<CONFIG:DEBUG>>:/MT>")

		get_target_property(_options ${target} COMPILE_OPTIONS)
		if(_options)
			#message(STATUS "${target} COMPILE_OPTIONS=${_options}")
			if(${_options} MATCHES "/MD")
				string(REGEX REPLACE "/MD" "/MT" _options "${_options}")
			else()
				set(_options "${_options} ${_mt}")
			endif()
		else()
			set(_options "${_mt}")
		endif()

		#message("target=${target} _options = ${_options}")

		get_target_property(_type ${target} TYPE)
		# 判断 ${target}是否为静态库
		if(_type STREQUAL "STATIC_LIBRARY")
			# 静态库将/MT选项加入INTERFACE_COMPILE_OPTIONS
			target_compile_options( ${target} PUBLIC "${_options}")
		else()
			target_compile_options( ${target} PUBLIC "${_options}")
			#target_compile_options( ${target} PRIVATE "${_options}")
		endif()

		# Cleanup temporary variables.
		unset(_mt)
		unset(_options)

		#message(STATUS "target ${target} use static runtime /MT")
	endif(MSVC)
endfunction()
