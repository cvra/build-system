### DO NOT EDIT BELOW THIS LINE ###

# use case: fillArray my_$arrayName "myValues 1 2 3"
fillArray() {
    c=0
    for i in ${@:2}
    do
        eval $1[$c]="'$i'"
        ((c++))
    done
}

# test function for fillArray:
#declare -a testArray=(1 2 3)
#declare -a addArray=(4 5 6)
#fillArray testArray "${testArray[@]}  ${addArray[@]}"
#echo ${testArray[@]}
#return 0

elementInArray() {
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

sanitizeVar() {
    echo $@ | sed -e 's/[\/&]/\\&/g'
}

loadModule() {
    local mod=$1
    echo "Load module: $mod"
    if [[ ! -d "../$mod" ]]; then
        pushd ..
        git clone https://github.com/cvra/$mod
        popd
    fi

    pushd ../$mod > /dev/null
    source ./cvraModuleMake.sh
    for dep in "${depends_on[@]}"
    do
        if ! elementInArray "$dep" "${modules[@]}" ; then
            modules=(${modules[@]} $dep)
            loadModule $dep
        fi
    done
    popd > /dev/null
}

loadModules() {
    for aModule in "${modules[@]}"
    do
        loadModule $aModule
    done
}

### DO NOT EDIT BELOW THIS LINE EITHER ###

build_type=$1
if [[ "${build_type,,}" != "debug" && "${build_type,,}" != "release" ]] ; then
    echo "BUILD TYPE NOT RECOGNIZED"
    exit 1;
else
    build_type=${build_type,,} # RELEASE -> release
    build_type=${build_type^} # release -> Release
fi


if [[ -d "$build_dir" ]]; then
    rm -rf $build_dir
fi
mkdir -p $build_dir/build

build_dir=$(readlink -e $build_dir)

# consider all build configs
all_includes=(/usr/local/include)
all_linkpaths=(/usr/local/lib)
for cfg in "${build_configs[@]}"
do
    declare -a all_$cfg
    declare -a all_${cfg}_linklibs
done

# preload all modules and dependencies
loadModules

# combine all the modules happily
echo "Combining modules... overwrites could cause bugs"

for m in "${modules[@]}"
do
    echo "Processing module: $m"
    pushd ../$m > /dev/null
    source ./cvraModuleMake.sh
    all_includes=( ${all_includes[@]} ${includes[@]} )
    all_linkpaths=( ${all_linkpaths[@]} ${linkpaths[@]} )
    for cfg in "${configs[@]}"
    do
        if elementInArray "$cfg" "${build_configs[@]}" ; then
            echo "-- cfg: $cfg "

            # WARNING: dont do this at home kids, we're trained bash professionals here!
            # rationale: bash doesn't support most operations involving dynamically
            # named arrays... so inefficient this crap is needed to work around that
            eval fillArray all_${cfg} \"\${all_${cfg}[@]}\" \"\${${cfg}[@]}\"
            eval fillArray all_${cfg}_linklibs \"\${all_${cfg}_linklibs[@]} \${${cfg}_linklibs[@]}\"
        fi
    done
    popd > /dev/null
    rsync -a --include '*.cpp' --include '*.c' --include '*.h' --exclude '.git' --include '*/' --exclude '*' ../$m/ $build_dir
done

# make array values unique
all_includes=$(printf "%s\n" "${all_includes[@]}" | sort -u)
all_linkpaths=$(printf "%s\n" "${all_linkpaths[@]}" | sort -u)

# output make file
touch $build_dir/CMakeLists.txt

echo "Preparing CMakeLists project data"

OLDIFS=$IFS
IFS=$'\n'

sed -e "s/<CVRA-PROJECT-NAME>/$(sanitizeVar $project)/g" \
    -e "s/<CVRA-BUILD-TYPE>/$(sanitizeVar $build_type)/g" \
    -e "s/<CVRA-INCLUDES>/$(sanitizeVar ${all_includes[*]})/g" \
    -e "s/<CVRA-LINKPATHS>/$(sanitizeVar ${all_linkpaths[*]})/g" \
    CMakeProtoProject.txt >> $build_dir/CMakeLists.txt 

echo "Preparing CMakeLists configs data"
for cfg in "${build_configs[@]}"
do
    echo "-- Config: $cfg "
    # avoid repetitions
    eval "curcfg_files=( \$(echo \"\${all_${cfg}[*]}\" | sort -u) )"
    eval "curcfg_linklibs=( \$(printf -- '%s\n' \"\${all_${cfg}_linklibs[@]}\" | sort -u) )"

    sed -e "s/<CVRA-TARGET>/$(sanitizeVar $cfg)/g" \
        -e "s/<CVRA-TARGET-FILES>/$(sanitizeVar ${curcfg_files[*]})/g" \
        -e "s/<CVRA-TARGET-LINKLIBS>/$(sanitizeVar ${curcfg_linklibs[*]})/g" \
        CMakeProtoTarget.txt >> $build_dir/CMakeLists.txt
done
IFS=$OLDIFS
echo ""

# start building process
cd $build_dir/build
echo "Starting the build process..."
cmake ..
make
