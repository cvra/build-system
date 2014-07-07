# Build System

This module implements a build system based on bash and CMake.

It has the following features:
* One-command compilation
* Support for multiple targets.
* Support for module-defined dependencies.
* Automatic retrieval of github repositories.
* Choice of module sources (directory, personal github, cvra github)

Planned features:
* Report of module versions (git hashes) that go into a build

For a demo of the system, feel free to checkout:
https://github.com/pierluca/build-system-demo

The build system is organized as such:
```build-system/
|-- cvraMake.sh
|-- cvraMake_utils.sh
|-- cvraMake_utils_test.sh
module-A/
|-- cvraModuleMake.sh
module-N/
|-- cvraModuleMake.sh
|-- make.sh
project/
|-- make.sh
```

## make.sh
This file defines the compilation project. It must define 4 variables:
- project : the name of the build project
- modules [bash array] : the modules that are needed (dependencies will be automatically added later)
- build_configs [bash array] : the list of build configurations / targets
- build_dir : the location in which the build will be prepared and executed

Optionally, the variable modules_sources can be defined (bash associative array).
Key are module names and values are local or remote locations where the module can be retrieved.
E.g.
```
modules_sources=([platform-abstraction]='https://github.com/pierluca/platform-abstraction')
```

It is recommended to creae make.sh files based on the example provided in:
https://github.com/pierluca/build-system-demo

## cvraMake.sh
This file and the associated script (cvraMake_utils.sh) contain the build system logic.
It is not necessary to alter them in any way over the course of the development.
The proper functioning of cvraMake_utils.sh can be tested with cvraMake_utils_test.sh

## cvraModuleMake.sh
This file contains all the necessary information on a module.
It contains the following basic variables:
- module_name : the name of the module (identical to repository name)
- module_version : it is recommended to use `git rev-parse --short=8 HEAD` as value
- depends_on [bash array] : this contains the list of modules on which it depends
- includes [bash array] : the include paths specific to and needed by this module
- linkpaths [bash array] : the linker paths specific to and needed by this module
- configs [bash array] : the build configs (or targets) supported by the module

In addition, for each target named in the `configs` bash array, the following two variables exist:
- target [bash array] : points to the .c files that are compiled for the given target
- target_linklibs [bash array] : points to the libraries against which the target has to be linked

A typical module will almost certainly include 
```
configs=(
    x86
    embedded
    tests
) 

x86=(
    moduleCode.c
    mocks/myMock.c
)

embedded=(
    moduleCode.c
    myEmbeddedImpl.c
)

[...]

tests=(
    ${x86[@]}
    tests/main.cpp
    tests/codeUnderTest_tests.c
)

tests_linklibs=(
    CppUTest
    CppUTestExt
)
```

It is worth noting that tests almost certainly include the application code compiled
for the x86 platform, repetitions can thus be avoided by expanding the x86 array in
the tests array ( `${myArray[@]}` )
