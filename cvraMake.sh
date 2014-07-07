######################################
# Include function definitions (this_script_dir/cvraMake_utils.sh)
######################################
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/cvraMake_utils.sh"

######################################
# Validate build type
######################################

valid_builds=("debug" "release")
if ! validateBuildType valid_builds $* ; then
    exit 1
else
    echo "Starting build configuration process for $project : $build_type ..."
fi

######################################
# Prepare build directory
######################################

if [[ -d "$build_dir" ]]; then
    rm -rf $build_dir
fi
mkdir -p $build_dir/build
build_dir=$(readlink -e $build_dir)

######################################
# set all desired build configs
######################################

all_includes=(/usr/local/include)
all_linkpaths=(/usr/local/lib)
for cfg in "${build_configs[@]}"
do
    declare -a all_$cfg
    declare -a all_${cfg}_linklibs
done

######################################
# preload all modules and dependencies
######################################

for aModule in "${modules[@]}"
do
    loadModule $aModule
done

######################################
# combine all the modules happily
######################################
echo "----"
echo "Combining modules.. overwrites could cause bugs"

# for each loaded module
for m in "${modules[@]}"
do
    echo "Processing module: $m"
    pushd ../$m > /dev/null
    source ./cvraModuleMake.sh
    unionArray all_includes includes
    unionArray all_linkpaths linkpaths
    for cfg in "${configs[@]}"
    do
        if elementInArray "$cfg" "${build_configs[@]}" ; then
            echo "-- cfg: $cfg "
            unionArray all_${cfg} ${cfg}
            unionArray all_${cfg}_linklibs ${cfg}_linklibs
        fi
    done
    popd > /dev/null
    rsync -a --include '*.cpp' --include '*.c' --include '*.h' --exclude '.git' --include '*/' --exclude '*' ../$m/ $build_dir
done
echo "----"
echo ""

######################################
# make array values unique
######################################

makeUniqueArray all_includes
makeUniqueArray all_linkpaths

######################################
# output project config
######################################

echo "Preparing CMakeLists project data"
touch $build_dir/CMakeLists.txt

OLDIFS="$IFS"
IFS=$'\n'

sed -e "s/<CVRA-PROJECT-NAME>/$(grepSanitize $project)/g" \
    -e "s/<CVRA-BUILD-TYPE>/$(grepSanitize $build_type)/g" \
    -e "s/<CVRA-INCLUDES>/$(grepSanitize ${all_includes[*]})/g" \
    -e "s/<CVRA-LINKPATHS>/$(grepSanitize ${all_linkpaths[*]})/g" \
    CMakeProtoProject.txt >> $build_dir/CMakeLists.txt 

echo "Preparing CMakeLists configs data"
for cfg in "${build_configs[@]}"
do
    echo "-- Config: $cfg "

    # output variables
    declare -a curcfg_files
    declare -a curcfg_linklibs

    # save unique'd files to output variables
    makeUniqueArray all_${cfg} curcfg_files
    makeUniqueArray all_${cfg}_linklibs curcfg_linklibs

    # output target config
    sed -e "s/<CVRA-TARGET>/$(grepSanitize $cfg)/g" \
        -e "s/<CVRA-TARGET-FILES>/$(grepSanitize ${curcfg_files[*]})/g" \
        -e "s/<CVRA-TARGET-LINKLIBS>/$(grepSanitize ${curcfg_linklibs[*]})/g" \
        CMakeProtoTarget.txt >> $build_dir/CMakeLists.txt
done
IFS="$OLDIFS"
echo ""

######################################
# start building process
######################################

cd $build_dir/build
echo "Starting the build process..."
cmake ..
make
