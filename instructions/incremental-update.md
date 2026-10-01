![rsync logo](/assets/rsync-logo.png)


One of the features of `rsync` is effecient, incremental file transfer.
Rather than blindly transferring every file, `rsync` will look at what
is at the source and the destination, and determine what actions it
needs to do.

To demonstate that, we have removed every file ending in `.cat` from
anywhere under the `{{WORKSTATION_DST_DIR}}` directory. If you were to fix
this manually, you would have to find every file ending in `.cat` on the
fileserver and transfer it manually. However, you know that `rsync` can
fix this for you automatically.

Run the following command in the workstation terminal:

```bash,run
rsync -av --stats fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

Notice that the list of files you see on the screen is short, and the
only files being transferred are files ending in `.cat`. Also take a look
at these lines in the statistics printed at the end:

```nocopy
Number of files: 180 (reg: 163, dir: 17)
Number of created files: 10 (reg: 10)
Number of deleted files: 0
Number of regular files transferred: 10
Total file size: 107,969,117 bytes
Total transferred file size: 74,162 bytes
Literal data: 74,162 bytes
[...]
```

This is `rsync` telling you that while there are 163 regular files at
the source, it only sent 10, the 10 that were missing. And while there
are over 107 million bytes of data at the source, only a bit over
74 thousand bytes were transferred. So, only the data which *needed* to be
transferred was.

When you are ready, run this check to continue:

<instruqt-task id="incremental-update"></instruqt-task>
