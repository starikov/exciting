#! /bin/sh


mkdir -p ./debian/usr/share/doc/exciting/
mkdir -p ./debian/usr/bin/

cp ../docs/exciting/excitinginput.pdf 	\
../docs/spacegroup/spacegroup.pdf \
../docs/exciting/excitingsubroutines.pdf \
../docs/Brillouin/* \
./debian/usr/share/doc/exciting/

cp ../bin/* ./debian/usr/bin/
rm ./debian/usr/bin/exciting
ln -s ./debian/usr/bin/excitingser ./debian/usr/bin/exciting
cp ../COPYING ./debian/usr/share/doc/exciting/copyright

chmod a-s -R debian/
dpkg-deb --build debian exciting.deb
