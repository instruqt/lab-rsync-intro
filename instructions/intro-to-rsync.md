[Rsync](https://rsync.samba.org/) is an open source utility that provides
fast incremental file transfer. Rsync is efficient because you can have it
transfer only the files which do not exist, or have changed, rather than
re-transfering every file. It works locally as well as remotely.

In this track, you will be working on a local workstation, and have access
to a remote fileserver. In this challenge we're going to copy our source data
from the fileserver to our local directory. In later challenges we'll explore
various options of `rsync`, before finally uploading the data back up to the
fileserver.

If at any point you are curious, you can check out the [rsync man page](tab-1)
tab to see the full list of `rsync` options.

We're going to run this command. Don't worry about what the options mean for
now, let's just get the files locally so we can work with them.

```bash,run
rsync -av --progress --stats fileserver:/opt/data/vosp_1000/ vosp_1000/
```

You can either click on the "copy" link in the upper right corner of the
command window above, or you can click on "run". Run it in the [Workstation](tab-0)
tab.

When you have finished, run the check below:

<instruqt-task id="intro-to-rsync"></instruqt-task>
