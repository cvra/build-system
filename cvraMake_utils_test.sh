######################################
# Functions under test
######################################

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/cvraMake_utils.sh"

######################################
# Testing Helper Function
######################################

allTestsOkay=0

testEquals() {
    if [[ "$1" != "$2" ]]; then
        echo "FAILED TEST: $3"
        allTestsOkay=1
    fi
}

testTrue() {
    if [[ $1 == 1 ]]; then
        echo "FAILED TEST: $2"
        allTestsOkay=1
    fi
}

testFalse() {
    # if input != false
    if [[ $1 != 1 ]] ; then
        echo "FAILED TEST: $2"
        allTestsOkay=1
    fi
}

######################################
# Function Tests
######################################

#
# use case: fillArray my_$arrayName "myValues 1 2 3"
#

# fillArray : TEST 1
declare -a testArray=(1 2 3)
declare -a addArray=(4 5 6)
fillArray testArray "${testArray[@]}  ${addArray[@]}"
declare -a expected=(1 2 3 4 5 6)
testEquals "${testArray[*]}" "${expected[*]}" "fillArray()-test-1"

# fillArray : TEST 2
declare -a testArray=(1 2 3)
fillArray testArray "${testArray[@]} 0"
declare -a expected=(1 2 3 0)
testEquals "${testArray[*]}" "${expected[*]}" "fillArray()-test-2"

# fillArray : TEST 3
declare -a testArray=()
fillArray testArray "1 2 3 0"
declare -a expected=(1 2 3 0)
testEquals "${testArray[*]}" "${expected[*]}" "fillArray()-test-3"

#
# use case: unionArray myArray myNewDataArray
#

# unionArray: TEST 1
declare -a testArray=(1 2 3)
declare -a addArray=(4 5 6)
unionArray testArray addArray
declare -a expected=(1 2 3 4 5 6)
testEquals "${testArray[*]}" "${expected[*]}" "unionArray()-test-1"

# use case: makeUniqueArray myArray [myDestination]

# makeUniqueArray: TEST 1
declare -a dstArray=()
declare -a testArray=(1 2 4 4 6 1 2 4 5 6)
makeUniqueArray testArray dstArray
declare -a expected=(1 2 4 5 6)
testEquals "${dstArray[*]}" "${expected[*]}" "makeUniqueArray()-test-1"

# makeUniqueArray: TEST 2
declare -a testArray=(1 2 3 4 4 4 1 2 2 2 5 6 6 3)
makeUniqueArray testArray 
declare -a expected=(1 2 3 4 5 6)
testEquals "${testArray[*]}" "${expected[*]}" "makeUniqueArray()-test-2"

# use case: elementInArray "element" "${myArray[@]}"

# elementInArray: TEST 1
target='asd'
declare -a testArray=(1 2 4 4 6 1 2 4 5 6 'asd')
elementInArray $target "${testArray[@]}"
testTrue $? "elementInArray-test-1"

# elementInArray: TEST 2
target=9
declare -a testArray=(1 2 4 4 6 1 2 4 5 6 "asd")
elementInArray $target "${testArray[@]}"
testFalse $? "elementInArray-test-2"

# use case: associativeHasKey hash key

declare -A assArr=( [pippo]=lol [pappa]=eccome )

# associativeHasKey: TEST 1
associativeHasKey assArr "pippo"
testTrue $? "associativeHasKey-test-1"

# associativeHasKey: TEST 2
associativeHasKey assArr "franco"
testFalse $? "associativeHasKey-test-2"

# use case: grepSanitize "$myVariable"
# NOT IMPLEMENTED, NO NEED TO

# use case: isWebAddress https://example.com

isWebAddress "http://github.com"
testTrue $? "isWebAddress-test-http-github"

isWebAddress "https://github.com"
testTrue $? "isWebAddress-test-https-github"

isWebAddress "someRandomText"
testFalse $? "isWebAddress-test-random"

# use case: isGitAddress git://example.com

isGitAddress "git://github.com/some/repo"
testTrue $? "isGitAddress-test-github"

isGitAddress "someRandomText"
testFalse $? "isGitAddress-test-random"

# use case: isValidDirectory /home/pierluca

isValidDirectory "/etc"
testTrue $? "isValidDirectory-test-etc"

isValidDirectory "/tmp/no/way/you/have/this/dir"
testFalse $? "isValidDirectory-test-unlikely"

# use case: validateBuildType validBuildTypes currentBuildType

declare -a buildTypes=("foo" "bar" "test")

# validateBuildType: TEST 1
validateBuildType buildTypes "test" > /dev/null 2>&1
testTrue $? "validateBuildType-test-1"

# validateBuildType: TEST 2
validateBuildType buildTypes "argh" > /dev/null 2>&1
testFalse $? "validateBuildType-test-2"


######################################
# FINAL REPORT
######################################

echo "---"
if [[ $allTestsOkay == 0 ]] ; then
    echo "All tests passed. Congrats!"
else
    echo ""
    echo " ATTENTION ! "
    echo ""
    echo " BUILD SYSTEM TESTS FAILED "
    echo ""
    echo " Build results could be unreliable or wrong "
    echo ""
fi
echo "---"
