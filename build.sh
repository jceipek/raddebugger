#!/bin/bash
# set -x # uncomment to debug shell script
set -e

# --- Usage Notes (2024/1/10) ------------------------------------------------
#
# This is a central build script for the RAD Debugger project. It takes a list
# of simple alphanumeric-only arguments which control (a) what is built, (b)
# which compiler & linker are used, and (c) extra high-level build options. By
# default, if no options are passed, then the main "raddbg" graphical debugger
# is built.
#
# Below is a non-exhaustive list of possible ways to use the script:
# `./build raddbg`
# `./build raddbg clang`
# `./build raddbg release`
# `./build raddbg asan telemetry`
# `./build raddbg_from_pdb`
#
# For a full list of possible build targets and their build command lines,
# search for @build_targets in this file.
#
# Below is a list of all possible non-target command line options:
#
# - `asan`: enable address sanitizer
# - `telemetry`: enable RAD telemetry profiling support

# --- Unpack Arguments -------------------------------------------------------
argcount=$#
while [ $# -gt 0 ]; do arg="$1"; declare $arg=1; shift; done

if [ "$clang" != "1" ]; then clang=1; fi
if [ "$release" != "1" ]; then debug=1; fi
if [ "$debug" = "1" ]; then release=0; echo "[debug mode]"; fi
if [ "$release" = "1" ]; then debug=0; echo "[release mode]"; fi
if [ "$clang" = "1" ]; then echo "[clang compile]"; fi
if [ "$argcount" -eq 0 ]; then echo "default mode, assuming 'raddbg' build"; raddbg=1; fi

# --- Unpack Command Line Build Arguments ------------------------------------
auto_compile_flags=""
if [ "$telemetry" = "1" ]; then auto_compile_flags+=" -DPROFILE_TELEMETRY=1"; echo "[telemetry profiling enabled]"; fi
if [ "$asan" = "1" ]     ; then auto_compile_flags+=" -fsanitize=address"; echo "[asan enabled]"; fi

# --- Compile/Link Line Definitions ------------------------------------------
clang_common="-I../src/ -I../local/ -maes -mssse3 -msse4 -gcodeview -fdiagnostics-absolute-paths -Wall -Wno-missing-braces -Wno-unused-function -Wno-writable-strings -Wno-unused-value -Wno-unused-variable -Wno-unused-local-typedef -Wno-deprecated-register -Wno-deprecated-declarations -Wno-unused-but-set-variable -Wno-single-bit-bitfield-constant-conversion -Xclang -flto-visibility-public-std -D_USE_MATH_DEFINES -Dstrdup=_strdup -Dgnu_printf=printf"
clang_debug="clang -g -O0 -D_DEBUG $clang_common"
clang_release="clang -g -O3 -DNDEBUG $clang_common"
# set clang_link=    -Xlinker /natvis:"%~dp0\src\natvis\base.natvis"
clang_link=""
clang_out="-o"

# --- Choose Compile/Link Lines ----------------------------------------------
if [ "$clang" = "1" ]     ; then compile_debug=$clang_debug; fi
if [ "$clang" = "1" ]     ; then compile_release=$clang_release; fi
if [ "$clang" = "1" ]     ; then compile_link=$clang_link; fi
if [ "$clang" = "1" ]     ; then out=$clang_out; fi
if [ "$debug" = "1" ]     ; then compile=$compile_debug; fi
if [ "$release" = "1" ]   ; then compile=$compile_release; fi
compile="$compile $auto_compile_flags"

# --- Prep Directories -------------------------------------------------------
mkdir -p build
mkdir -p local

# --- Build & Run Metaprogram ------------------------------------------------
if [ "$no_meta" = "1" ]; then 
    echo "[skipping metagen]"
else
  pushd build
  $compile_debug "../src/metagen/metagen_main.c" $compile_link $out "metagen"
  ./metagen
  popd
fi

# --- Build Everything (@build_targets) --------------------------------------
pushd build
if [ "$raddbg" = "1" ];            then $compile $gfx "../src/raddbg/raddbg.cpp"                         $compile_link $out "raddbg"; fi
if [ "$raddbg_from_pdb" = "1" ];   then $compile      "../src/raddbg_convert/pdb/raddbg_from_pdb_main.c" $compile_link $out "raddbg_from_pdb"; fi
if [ "$raddbg_from_dwarf" = "1" ]; then $compile      "../src/raddbg_convert/dwarf/raddbg_from_dwarf.c"  $compile_link $out "raddbg_from_dwarf"; fi
if [ "$raddbg_dump" = "1" ];       then $compile      "../src/raddbg_dump/raddbg_dump.c"                 $compile_link $out "raddbg_dump"; fi
if [ "$ryan_scratch" = "1" ];      then $compile      "../src/scratch/ryan_scratch.c"                    $compile_link $out "ryan_scratch"; fi
if [ "$look_at_raddbg" = "1" ];    then $compile      "../src/scratch/look_at_raddbg.c"                  $compile_link $out "look_at_raddbg"; fi
# if "%mule_main%"=="1"          del vc*.pdb mule*.pdb && %cl_release% /c ..\src\mule\mule_inline.cpp && %cl_release% /c ..\src\mule\mule_o2.cpp && %cl_debug% /EHsc ..\src\mule\mule_main.cpp ..\src\mule\mule_c.c mule_inline.obj mule_o2.obj
# if "%mule_module%"=="1"        %compile%             ..\src\mule\mule_module.cpp                                  %compile_link% %link_dll% %out%mule_module.dll
popd
