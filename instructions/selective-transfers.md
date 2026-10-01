![rsync logo](/assets/rsync-logo.png)

You can also tell `rsync` to only transfer certain files. But how it does
it is a bit unusual, so we're going to work through a few examples. Let's
say you want to copy every file ending in `.lbl` from the fileserver to
your local workstation.

By default, `rsync` considers every file and directory for transfer.
However, `rsync` has both `--include` and `--exclude` options, so you
might think the correct way to do this is to run the following in the
Workstation tab:

```bash,run
rsync -av --stats --include '*.lbl' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

But you can see all kinds of files transferred, and if you look at the
statistics, you see:

```nocopy
Number of files: 180 (reg: 163, dir: 17)
Number of created files: 180 (reg: 163, dir: 17)
Number of deleted files: 0
Number of regular files transferred: 163
```

It created 180 files, 163 of them regular files, and 17 of them directories.
And it transferred all 163 files, not just the ones ending in `.lbl`. So
that didn't work. Why?

It's because `rsync` needs you to tell it which files to exclude, and then
which files to include. Let's see what happens if we run `rsync` with only
the `--exclude` option in the Workstation tab:

```bash,run
rm -rf {{WORKSTATION_DST_DIR}}
rsync -av --stats --exclude '*' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

Here you can see that it only created your destination directory, but did
not transfer any other files. Good, you might think, so now I just need
to add an `--include` option to include just the `.lbl` files, correct?
Let's try that in the Workstation tab:

```bash,run
rsync -av --stats --exclude '*' --include '*.lbl' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

But wait, why did it still not include any `.lbl` files? That's because
the `--exclude` and `--include` options add *rules* to the list of files
and directories that `rsync` considers for transfer, and **the first rule
to match wins**. So in our example, `--exclude '*'` is the first rule on
the command line, and it *always* matches, and finding a rule match `rsync`
goes to consider the next file.

So the order of your `--include` and `--exclude` options matters. Let's
try this in the Workstation tab:

```bash,run
rsync -av --stats --include '*.lbl' --exclude '*' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

You'll see that it transferred one file, `aareadme.lbl`. But you know there
are more, what's happening?

The last piece of the puzzle is that you must also tell `rsync` which
*directories* to consider. Otherwise it just sees the file which is in
the top level of the source directory. But we can do the following in the
Workstation tab:

```bash,run
rsync -av --stats --include '*.lbl' --include '*/' --exclude '*' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

By adding the `--include '*/'` command-line option, you've told
`rsync` to also consider all *directories*. And when it considers
a directory, it also considers everything in that directory, both files,
and any sub-directories.

A bit confusing, but with a little practice you can build the correct
options to have `rsync` transfer only the files you need.

> [!NOTE]
> **Helpful hint**: use the `--dry-run` option to `rsync` to see what files and directories would be transferred without actually doing the transfer.

When you have finished, click on the **Check** button o verify
you have completed this challenge successfully:

<instruqt-task id="selective-transfers"></instruqt-task>

<instruqt-completion text="And now you know very little about the rsync file transfer tool!"></instruqt-completion>
