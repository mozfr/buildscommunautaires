#!/bin/sh



set -e



GIT_ROOT="https://git.mozilla.org/releases/l10n/"

GIT_PROJ="/gaia.git"



LANGS=$(json_pp < languages_all.json | grep ':' | cut -d':' -f1 | cut -d'"' -f2)



for lang in ${LANGS}; do

    echo "Syncing $lang"

    if [ ! -d ${lang}/.git/ ]; then

        echo "No repo for ${lang}, cloning new one"

        git clone ${GIT_ROOT}${lang}${GIT_PROJ} $lang || true
        cd ${lang} && git checkout v2.1 || true && cd ..
        

    else

        echo "Updating close for ${lang}"
#Change checkout to your branch
        cd ${lang} && (git pull && git checkout v2.1) || true && cd ..

    fi;

done;
