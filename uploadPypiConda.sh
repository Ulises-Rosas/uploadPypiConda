#!/bin/bash

# This program is free software; you can redistribute it and/or modify
# it under the terms of the MIT Public License. This program comes as-is 
# and without warranty. 

# Originally written by Ulises Rosas <ulisesfrosasp@gmail.com>.

alias grep='grep --color=never'

LGREEN='\033[1;32m'
NC='\033[0m'

function seddy {
    fmt="s#$1#"$2"#g"

    if [[ `uname` == 'Linux' ]]; then
        sed -re "${fmt[@]}" 
    else
        sed -Ee "${fmt[@]}"
    fi
}

function urlsed {

    fmt="s#$1#"$2"#g"
    if [[ `uname` == 'Linux' ]]; then
        sed -ibakPCU -re "${fmt[@]}" $3
    else
        sed -ibakPCU -Ee "${fmt[@]}" $3
    fi
}

echo
echo -e "${LGREEN}Building and Uploading for PyPI...${NC}"
python3 setup.py sdist bdist_wheel
twine upload dist/*

pkg_name=$(python3 setup.py --name | awk '{print tolower($0)}')
pkg_ver=$(python3 setup.py --version | awk '{print tolower($0)}')

if [[ ! -z $(ls $pkg_name'_PCU') ]]; then
    rm -rf $pkg_name'_PCU'
fi

echo
echo -e "${LGREEN}Building and Uploading for ANACONDA...${NC}"
conda skeleton pypi $pkg_name --output-dir $pkg_name'_PCU' > log'_PCU'

url=$(cat log'_PCU' |\
       grep "PyPI URL:[ ]*" |\
        seddy  "PyPI URL:[ ]*(http.*)" "\1" )

file=$pkg_name'_PCU'/$pkg_name/meta.yaml

urlsed "(^[ ]*url:[ ]*)http.*" "\1"$url $file
rm $file'bakPCU'


conda config --set anaconda_upload no
conda build $pkg_name'_PCU'/$pkg_name
bldd=$(conda-build $pkg_name'_PCU'/$pkg_name --output)

anaconda upload $bldd

for p in win-64 linux-64 osx-64; do
    conda convert --platform $p $bldd -o $pkg_name'_PCU'
    anaconda upload $(find $pkg_name'_PCU/'$p -name *.tar.bz2)
done

rm -rf $pkg_name'_PCU'
rm log'_PCU'
