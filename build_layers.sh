#!/bin/bash

set -euo pipefail

#retrieve the current list of layers.. to make sure you're logged in to AWS, before you spend a lot of time building stuff
aws lambda list-layers

#Download the R source code
wget https://cran.r-project.org/src/base/R-3/R-$R_VERSION.tar.gz
mkdir -p /opt/R/
chown $(whoami) /opt/R/
tar -xf R-$R_VERSION.tar.gz
mv R-$R_VERSION/* /opt/R/
cd /opt/R/

#Build R
./configure --prefix=/opt/R/ --exec-prefix=/opt/R/ --with-libpth-prefix=/opt/
make

#Copy some lib64 files to the lib folder
cp /usr/lib64/libgfortran.so.3 lib/
cp /usr/lib64/libgomp.so.1 lib/
cp /usr/lib64/libquadmath.so.0 lib/
cp /usr/lib64/libstdc++.so.6 lib/

#Install some R packages needed by the runtime, so they should become part of the "base" R package
./bin/Rscript -e 'chooseCRANmirror(graphics=FALSE, ind=34); install.packages("httr")'
./bin/Rscript -e 'chooseCRANmirror(graphics=FALSE, ind=34); install.packages("aws.s3")'

#Install extra packages, defined in the Dockerfile
cd library
pre_installed_packages=(`ls`)
packages=(${PACKAGES//,/ })
for package in "${packages[@]}"; do
   ../bin/Rscript -e 'chooseCRANmirror(graphics=FALSE, ind=34); install.packages("'$package'")'
done

#cleanup the installed packages, to save space
strip --strip-debug */libs/*so
rm -rf `find -type d -name doc`
rm -rf `find -type d -name help`

#Move some "recommended" packages, plus the newly installed packages (plus their dependencies) to another folder, so they can be put in a separate ZIP file
move_packages=(boot class cluster codetools foreign KernSmooth lattice MASS Matrix mgcv nlme nnet rpart spatial survival)
for f in *; do
    skip=
    for package in "${pre_installed_packages[@]}"; do
        [[ $package == $f ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || move_packages+=("$f")
done

#move the extra libraries to the seperate modules folder
cd ..
mkdir packages
for package in "${move_packages[@]}"; do
   mv library/$package packages
done

#Build and publish the runtime layer
rm -rf build
mkdir -p /build/runtime/R
cd /build/runtime
cp /src/* .
cp -r /opt/R/bin /opt/R/lib /opt/R/etc /opt/R/library /opt/R/modules /opt/R/share R/ || :
chmod -R 755 bootstrap runtime.R R/
zip -r -q runtime.zip runtime.R bootstrap R/
response=$(aws lambda publish-layer-version --layer-name r-runtime-${R_VERSION//./_} --zip-file fileb://runtime.zip)
runtime_arn=$(jq -r '.LayerVersionArn' <<< "$response")

#Build and publish the packages layer
mkdir -p /build/packages/R/library
cd /build/packages
cp -r /opt/R/packages/* R/library
zip -r -q packages.zip R/
response=$(aws lambda publish-layer-version --layer-name r-packages-${R_VERSION//./_} --zip-file fileb://packages.zip)
package_arn=$(jq -r '.LayerVersionArn' <<< "$response")

echo "============================================================================="
echo "              All done building layers for R version $R_VERSION"
echo "============================================================================="
echo " - Runtime layer: "$runtime_arn
echo " - Package layer: "$package_arn
