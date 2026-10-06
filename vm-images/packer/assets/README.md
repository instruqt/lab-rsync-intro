# Sample data for an rsync track

We need a moderately sized amount of data, with some complexity and
a variety of file types, as an example set of files for use in a
tutorial on rsync. This tutorial is used as an example track by
[Instruqt](https://instruqt.com) and is maintained by the Instruqt
Value Engineering group.

The Packer configuration in this repository expects there to be
a file `vosp_1000.tgz` in this directory, but we do not include
it in the repo due to its size. You can create it by doing the following

```
wget -m -nH --cut-dirs=5 -e robots=off \
     --trust-server-names -R 'index.html*' \
     -I 'pub/naif/pds/data/vo1_vo2-m-spice-6-v1.0/vosp_1000/' \
     -nv https://naif.jpl.nasa.gov/pub/naif/pds/data/vo1_vo2-m-spice-6-v1.0/vosp_1000/
tar -zcvf vosp_1000.tgz vosp_1000/
```

and placing the resultant file here.

See the JPL [PDS SPICE Archives](https://naif.jpl.nasa.gov/naif/data_archived.html) for other similar data sets.

[Data Credit](https://naif.jpl.nasa.gov/naif/credit.html)
