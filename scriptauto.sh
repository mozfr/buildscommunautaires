#!/bin/bash
echo -------irc init---------
ii -s irc.mozilla.org -n buildbot-zteopenc  &

echo -----prebuild-----
make -C gaia/ clean really-clean ||{ echo "/PRIVMSG dattaz nightly : erreur lors du make gaia clean" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }

git pull || { echo "/PRIVMSG dattaz nightly : erreur lors du git pull" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  
./repo sync || { echo "/PRIVMSG dattaz nightly : erreur lors de la syncro des repo" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  
cd gaia/locales/ && ./langs.sh && cd ../../ || { echo "/PRIVMSG dattaz nightly : erreur lors du langs.sh" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  

echo -------build----------
./build.sh || { echo "/PRIVMSG dattaz nightly : erreur lors de la build " > /home/ad/irc/irc.mozilla.org/in  ; exit 1; }  
./build.sh gecko-update-fota || { echo "/PRIVMSG dattaz nightly : erreur lors de la build FOTA" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  

echo ---------update part--------
rm -r /var/www/nightly/
mkdir /var/www/nightly/
BUILDID=$(grep 'BuildID=' objdir-gecko/dist/bin/application.ini | cut -d'=' -f2) || { echo "/PRIVMSG dattaz get buildid fail" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }
VERSION=$(grep '\nVersion=' objdir-gecko/dist/bin/application.ini | cut -d'=' -f2) || { echo "/PRIVMSG dattaz get version fail" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }
ANDROID_TOOLCHAIN=prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.7/bin python tools/update-tools/build-update-xml.py -c out/target/product/flame/fota-flame-update.mar -O -u http://builds.firefoxos.mozfr.org/openc/nightly/fota-flame-$BUILDID.mar -i $BUILDID -v $VERSION -V $VERSION | tee /var/www/nightly/update.xml || { echo "/PRIVMSG dattaz nightly : erreur lors de la génération du xml" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  
cp out/target/product/flame/fota-flame-update.mar /var/www/nightly/fota-flame-$BUILDID.mar || { echo "/PRIVMSG dattaz nightly : erreur lors du CP du mar vers le dossier du serveur" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  
cp out/target/product/flame/fota/partial/update.zip /var/www/nightly/update-$BUILDID.zip || { echo "/PRIVMSG dattaz nightly : erreur lors du CP du zip vers le dossier du serveur" > /home/ad/irc/irc.mozilla.org/in ; exit 1; }  
pushd /var/www/nightly/
sha1sum $(ls) | tee sha1.checksums || { echo "/PRIVMSG dattaz nightly : erreur lors de la génération du fichier signature" > /home/ad/irc/irc.mozilla.org/in ; exit 1; } 
echo Options +Indexes >> .htaccess 
echo Redirect /openc/nightly/update-latest.zip  /openc/nightly/update-$BUILDID.zip >> .htaccess
popd
echo "/PRIVMSG dattaz nightly : Génération OK ! Nouvelle update disponible ! " > /home/ad/irc/irc.mozilla.org/in ; exit 0
