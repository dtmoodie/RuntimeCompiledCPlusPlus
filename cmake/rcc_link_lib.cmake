# This macro is used for linking libs to a target, but also adding the correct directories to the RCC config
MACRO(RCC_LINK_LIB TARGET)
  SET(PREFIX "")
  set(LINK_LIBS_RELEASE "")
  set(LINK_DIRS_RELEASE "")
  set(LINK_LIBS_DEBUG "")
  set(LINK_DIRS_DEBUG "")
  if(RCC_VERBOSE_CONFIG)
    message(STATUS "===================================================================
             RCC config information for ${TARGET}")
  endif(RCC_VERBOSE_CONFIG)
  FOREACH(lib ${ARGN})
    SET(SKIP "0")
    SET(IS_DEBUG "2") # default to a release library
    IF(${lib} STREQUAL "optimized")
      SET(PREFIX "optimized;")
      SET(SKIP "1")
      SET(IS_DEBUG "0")
    ENDIF(${lib} STREQUAL "optimized")

    IF(${lib} STREQUAL "debug")
      SET(PREFIX "debug;")
      SET(SKIP "1")
      SET(IS_DEBUG "1")
    ENDIF(${lib} STREQUAL "debug")

    IF(${SKIP} STREQUAL "0")
      IF(TARGET ${lib})
        get_target_property(rel ${lib} IMPORTED_IMPLIB_RELEASE)
        get_target_property(_rel ${lib} IMPORTED_LOCATION_RELEASE)
        get_target_property(deb ${lib} IMPORTED_IMPLIB_DEBUG)
        get_target_property(_deb ${lib} IMPORTED_LOCATION_DEBUG)

        if(NOT rel AND _rel)
          set(rel ${_rel})
        endif(NOT rel AND _rel)
        if(NOT deb AND _deb)
          set(deb ${_deb})
        endif(NOT deb AND _deb)

        if(NOT rel AND deb)
          set(rel ${deb})
        endif(NOT rel AND deb)

        if(NOT deb AND rel)
          set(deb ${rel})
        endif(NOT deb AND rel)

        IF(NOT rel AND NOT deb AND RCC_VERBOSE_CONFIG)
          message("Target ${lib} does not contain IMPORTED_IMPLIB_RELEASE or IMPORTED_IMPLIB_DEBUG")
        endif(NOT rel AND NOT deb AND RCC_VERBOSE_CONFIG)

        GET_FILENAME_COMPONENT(rel_ ${rel} DIRECTORY)
        GET_FILENAME_COMPONENT(deb_ ${deb} DIRECTORY)
        get_filename_component(rel__ ${rel} NAME)
        get_filename_component(deb__ ${deb} NAME)

        LIST(APPEND LINK_DIRS_DEBUG "${deb_}")
        LIST(APPEND LINK_DIRS_RELEASE "${rel_}")
        LIST(APPEND LINK_FILE_DEBUG "${deb__}")
        LIST(APPEND LINK_FILE_RELEASE "${rel__}")

        if(RCC_VERBOSE_CONFIG AND deb_)
          message(STATUS "  Link dir: [${lib}] (debug): ${deb_} - ${deb__}")
        endif(RCC_VERBOSE_CONFIG AND deb_)
        if(RCC_VERBOSE_CONFIG AND rel_)
          message(STATUS "  Link dir: [${lib}] (release): ${rel_} - ${rel__}")
        endif(RCC_VERBOSE_CONFIG AND rel_)

        if(rel__)
          #get_filename_component(rel__ "${rel__}" NAME_WE)
          rcc_strip_extension(rel__ rel__)
          string(SUBSTRING "${rel__}" 0 3 sub)
          if(${sub} STREQUAL lib)
            string(SUBSTRING "${rel__}" 3 -1 rel__)
          endif()
        #STRING(REPLACE "lib" "" rel__ "${rel__}")

          LIST(APPEND LINK_LIBS_RELEASE ${rel__})
        endif()

        if(deb__)
          #get_filename_component(deb__ "${deb__}" NAME_WE)
          rcc_strip_extension(deb__ deb__)
          string(SUBSTRING "${rel__}" 0 3 sub)
          if(${sub} STREQUAL lib)
            string(SUBSTRING "${rel__}" 3 -1 rel__)
          endif()

          #STRING(REPLACE "lib" "" deb__ "${deb__}")
          LIST(APPEND LINK_LIBS_DEBUG ${deb__})
        endif()

        GET_TARGET_PROPERTY(imp_libs_rel_with_deb ${lib} IMPORTED_LINK_INTERFACE_LIBRARIES_RELWITHDEBINFO)
        GET_TARGET_PROPERTY(imp_libs_rel ${lib} IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE)
        GET_TARGET_PROPERTY(imp_libs_deb ${lib} IMPORTED_LINK_INTERFACE_LIBRARIES_DEBUG)

        foreach(imp_lib ${imp_libs_rel})
          if(EXISTS ${imp_lib})
            GET_FILENAME_COMPONENT(dir ${imp_lib} DIRECTORY)
            LIST(APPEND LINK_DIRS_RELEASE "${dir}")
            #get_filename_component(name ${imp_lib} NAME_WE)
            rcc_strip_extension(imp_lib name)
            if(RCC_VERBOSE_CONFIG)
              message(STATUS "  Link dir: [${name}] ${dir}")
            endif(RCC_VERBOSE_CONFIG)
            string(SUBSTRING "${name}" 0 3 sub)
      string(LENGTH "${sub}" len_)
      if(${len_} GREATER 3)
              if(${sub} STREQUAL lib)
                string(SUBSTRING "${name}" 3 -1 name)
              endif()
      endif()
            LIST(APPEND LINK_LIBS_RELEASE ${name})
          endif()
        endforeach()

        foreach(imp_lib ${imp_libs_rel_with_deb})
          if(EXISTS ${imp_lib})
            GET_FILENAME_COMPONENT(dir ${imp_lib} DIRECTORY)
            LIST(APPEND LINK_DIRS_RELEASE "${dir}")
            #get_filename_component(name ${imp_lib} NAME_WE)
            rcc_strip_extension(imp_lib name)
            if(RCC_VERBOSE_CONFIG)
              message(STATUS "  Link dir: [${name}] ${dir}")
            endif(RCC_VERBOSE_CONFIG)
            list(APPEND LINK_LIBS_RELEASE ${name})
          endif()
        endforeach()

        foreach(imp_lib ${imp_libs_deb})
          if(EXISTS ${imp_lib})
            GET_FILENAME_COMPONENT(dir ${imp_lib} DIRECTORY)
            LIST(APPEND LINK_DIRS_DEBUG "${dir}")
            #get_filename_component(name ${imp_lib} NAME_WE)
            rcc_strip_extension(imp_lib name)
            if(RCC_VERBOSE_CONFIG)
              message(STATUS "  Link dir: [${name}] ${dir}")
            endif(RCC_VERBOSE_CONFIG)
            list(APPEND LINK_LIBS_DEBUG ${name})
          endif()
        endforeach()
      else(TARGET ${lib})
        IF(EXISTS ${lib})
        # if it's a file on disk
          TARGET_LINK_LIBRARIES(${TARGET} ${lib})
          GET_FILENAME_COMPONENT(DIR ${lib} DIRECTORY)
          LIST(APPEND LINK_DIRS_DEBUG "${DIR}")
          LIST(APPEND LINK_DIRS_RELEASE "${DIR}")
          #get_filename_component(name ${lib} NAME_WE)
          rcc_strip_extension(lib name)
          if(name)
            if(RCC_VERBOSE_CONFIG AND DIR)
              message(STATUS "  Link dir: [${name}] ${dir}")
            endif(RCC_VERBOSE_CONFIG AND DIR)
            string(SUBSTRING "${name}" 0 3 sub)
            if(${sub} STREQUAL lib)
              string(SUBSTRING "${name}" 3 -1 name)
            endif()
          #string(REPLACE "lib" "" name "${name}")
            if(${IS_DEBUG} STREQUAL "0")
              list(APPEND LINK_LIBS_RELEASE "${name}")
            elseif(${IS_DEBUG} STREQUAL "1")
              list(APPEND LINK_LIBS_DEBUG "${name}")
            else() # IS_DEBUG == 2  thus debug / optimized was not specified
              list(APPEND LINK_LIBS_DEBUG "${name}")
              list(APPEND LINK_LIBS_RELEASE "${name}")
            endif()
          endif(name)
        endif(EXISTS ${lib})
      endif(TARGET ${lib})
      TARGET_LINK_LIBRARIES(${TARGET} ${PREFIX}${lib})
    ENDIF(${SKIP} STREQUAL "0")
  ENDFOREACH(lib)
  LIST(REMOVE_DUPLICATES LINK_DIRS_DEBUG)
  LIST(REMOVE_DUPLICATES LINK_DIRS_RELEASE)

ENDMACRO(RCC_LINK_LIB TARGET)
