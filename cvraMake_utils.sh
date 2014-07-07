######################################
# Function Definitions
######################################

# use case: fillArray my_$arrayName "myValues 1 2 3"
fillArray() {
    local _c=0
    for _i in ${@:2}
    do
        eval $1[$_c]="'$_i'"
        ((_c++))
    done
}

# use case: unionArray myArray myNewDataArray
unionArray() {
    local _dst="$1[@]"
    local _src="$2[@]"
    fillArray $1 "${!_dst}" "${!_src}"
}

# use case: makeUniqueArray myArray [myDestination]
makeUniqueArray() {
    local _array="$1[@]"
    local _destArray="$1"
    if [[ $# == 2 ]]; then
        _destArray="$2"
    fi

    # myDestination=( print myArray | sort & unique )
    eval "$_destArray=($(printf -- '%s\n' "${!_array}" | sort -u ))"
}

# use case: elementInArray "$element" "${myArray[@]}"
elementInArray() {
    local _e
    for _e in "${@:2}"; do [[ "$_e" == "$1" ]] && return 0; done
    return 1
}

# use case: associativeHasKey hashName keyName
associativeHasKey() {
    local _arr=$1
    local _key=$2
    local _tmp="$_arr[$_key]+_"
    if [ ${!_tmp} ]; then
        return 0;
    else
        return 1;
    fi
}

# use case: grepSanitize "$myVariable"
grepSanitize() {
    echo $@ | sed -e 's/[\/&]/\\&/g'
}

# use case: isWebAddress https://example.com
isWebAddress() {
    if [[ $1 == https://* ]] || [[ $1 == http://* ]]; then
        return 0;
    else
        return 1;
    fi
}

# use case: isGitAddress git://example.com
isGitAddress() {
    if [[ $1 == git://* ]]; then
        return 0;
    else
        return 1;
    fi
}

# use case: isValidDirectory /home/pierluca
isValidDirectory() {
    if [ ! -d "$1" ] ; then
        return 1;
    else
        return 0;
    fi
}

# use case: getModuleFromLink module link
getModuleFromLink() {
    local _link=$1
    git clone $_link .
}

# use case: getModuleFromPath module dirPath
getModuleFromPath() {
    local _modPath=$1
    cp -r "$_modPath/." .
}

# use case: retrieveModule module
retrieveModule() {
    if [ -v "modules_sources" ] && associativeHasKey "modules_sources" "$_mod" ; then
        local _src=${modules_sources[$_mod]}
        if isWebAddress $_src  || isGitAddress $_src  ; then
            echo "-- from link: $_src"
            getModuleFromLink $_src
        elif isValidDirectory $_src ; then
            echo "-- from path: $_src"
            getModuleFromPath $_src
        else
            echo "Loading module $_mod failed. Invalid source or source could not be interpreted"
            echo "Source: $_src"
            exit 1
        fi
    else
        echo "-- from CVRA github"
        git clone https://github.com/cvra/$_mod .
    fi
}

# use case: loadModule myModuleName
# myModuleName will be fetched on github/cvra or from identified source
# side effect: modifies global variable modules
loadModule() {
    local _mod=$1
    echo "Load module: $_mod"
    if [[ ! -d "../$_mod" ]]; then
        mkdir ../$_mod
        pushd ../$_mod > /dev/null
        retrieveModule $_mod
        popd > /dev/null
    fi

    pushd ../$_mod > /dev/null
    source ./cvraModuleMake.sh
    for _dep in "${depends_on[@]}"
    do
        if ! elementInArray "$dep" "${modules[@]}" ; then
            modules=(${modules[@]} $_dep)
            loadModule $_dep
        fi
    done
    popd > /dev/null
}

# use case: validateBuildType validBuildTypes currentBuildType
# side effect: sets build_type globally
validateBuildType() {
    local _req="$2"
    local _valid="$1[@]"
    if ! elementInArray "$_req" "${!_valid}"; then
        echo "Build type $_req not recognized - aborting ..."
        return 1;
    else
        build_type=${_req,,} # RELEASE -> release
        build_type=${build_type^} # release -> Release
        return 0
    fi
}
