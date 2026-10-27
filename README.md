# Rsync Intro --- An Instruqt Example Lab

This is an example three page Instruqt Lab, designed to show off the basics
of how a Lab works and how it is organized. It's a conversion of the
[Rsync Intro Track](https://github.com/instruqt/track-rsync-intro/) into an
[Instruqt Lab](https://docs.labs.instruqt.com/).

## Requirements

You must have a [Team Secret](https://docs.instruqt.com/sandboxes/runtime/secrets) called
`IGGYS_SSH_PRIVATE_KEY_BASE64` which was created from the output of running

```
TMP=$(mktemp -d); ssh-keygen -t ed25519 -f "${TMP}/id_ed25519" -N "" >/dev/null; base64 -b 0 < "${TMP}/id_ed25519"; rm -rf "${TMP}"
```

**NOTE**: Your variant of `base64` or equivalent may have different command-line flags,
the output must have no line breaks.

# Annotated Lab Guide

## Background

The *Lab* is a basic unit of content on Instruqt, and what a learner interacts with.
Every time a learner starts a Lab, they get a unique, isolated instance of that Lab,
which is called a *sandbox*. You can think of this code as the "template" used to
create those sandboxes.

Lab sandboxes are ephemeral, once the Lab is finished --- by either a learner finishing
or exiting the Lab, or a timeout reached, the sandbox is deprovisioned and any resources
within it go away.

Labs are written in [HCL](https://github.com/hashicorp/hcl), which allows you to define
_resources_ and the relationships between them logically. So, rather than having to
procedurally say "Create `resource A`, and then and only then create `resource B` which
depends on it", you define both `resource A` and `resource B`, and the fact that
`resource B` depends on something from `resource A` means `A` will be created before
`B`. In short, you declare the state you want and the relationships between the
resources within, and the Instruqt platform takes care of determining in which order
they need to be created.

Resources are defined in blocks which look like this:

```
resource "<type>" "<name>" {
  [attribute and blocks]
}
```

Each resource has a _type_, which defines what kind of resource this is, and a
_name_, which is how you distinguish between multiple copies of the same resource
type. Within each resource are _attributes_, which allow you to configure that
resource. There may also be _blocks_, which are collections of attributes. You'll
see examples of those when we talk about creating virtual machines later. Some
attributes and blocks are _required_, which means you must set them or you
will get an error; others are _optional_. Some blocks may also be _repeatable_,
for example you may attach a container or VM to multiple networks. Not all
blocks are repeatable, and an attribute is never repeatable. The [reference
documentation](https://docs.labs.instruqt.com/reference/) will tell you
if something is required or optional, and if optional what the default is
if you do not define it. It will also document if a given block is repeatable.

however, but the documentation will tell you if a particular
one is. Attributes, however, are never repeatable.

Resources may also have _computed attributes_. Think of these as output from the
resource. For example:

```
resource "random_password" "dbadmin_password" {
  length = 16
}
```

This is a `random_password` resource with the name `dbadmin_password`, and
by setting the attribute `length` to `16` we've defined that we want that
random password to be 16 characters in length. If we wanted to actually use
that random password somewhere, we could be using
`resource.random_password.dbadmin_password.value` --- we cannot _set_ that
attribute, but we can _use_ the value elsewhere.

There are two major components of an Instruqt Lab: _Content Resources_, and _Sandbox
Resources_.

## Code Conventions

There are only two strict requirements for your HCL code:

1. Every file (and you may and should have more than one) must end in `.hcl`
2. Every `.hcl` file must live at the top level of the directory defining
   a given lab

So while if you create a lab using `instruqt lab init`, or using the platform
webUI, you'll get `main.hcl`, `content.hcl`, `layouts.hcl`, `sandbox.hcl`, etc.,
but that is just a convention. You're free to organize your lab HCL configuration
any way which makes sense to you, as long as they follow the two rules above.

Note that while every `.hcl` file must live at the top level, you _may_ have
sub-directories for other things which are referenced in your HCL files. For
example, a page's instructions might live in `instructions/intro-to-rsync.md`,
or that page's instructions might reference an image in `assets/rsync-logo.png`.
In fact, it is encouraged that you do so, to help organize files in a way
which is tidy and makes sense.

## Sandbox Resources

[Sandbox Resources](https://docs.labs.instruqt.com/reference/sandbox/) are the infrastructure
within a Lab sandbox: the VMs, containers, networks, cloud accounts, etc. These create the
environment in which your Learner operates and the ways that they access them, like a
terminal, service, or editor, etc. In this lab they are primarily defined in the file
[sandbox.hcl](sandbox.hcl)

This sandbox is pretty simple: a variable, a couple secrets, a shared network, and two virtual machines.

### Variables
[Variables](https://docs.labs.instruqt.com/reference/types/variable/) define input parameters
which can be used throughout your lab configuration, and provide a way to parameterize lab
configuration. With this, you can allow values to be customized without having to modify
the core configuration.

In this lab, we only use a single [System Variable](https://docs.labs.instruqt.com/reference/types/variable/#system-variables), one which is supplied automatically by the Instruqt platform. We use that and
will talk about it in the section about creating our lab virtual machines.

You can also [set variables at launch](https://docs.labs.instruqt.com/reference/types/variable/#setting-variables-at-launch) which can be a useful way to customize a lab.

### Secrets

[Secrets](https://docs.labs.instruqt.com/reference/sandbox/secrets/secret/) are a resource
which fetches a secret defined in your Instruqt team and makes it available for use within
this sandbox. These are good for storing API keys, tokens, passwords, and things of that
nature. They allow those secrets to be used within your Lab without putting the actual
value of that secret in your code. It also allows you to centralize commonly used secrets:
define a secret once in your Instruqt team, use it in multiple places, and when you need
to rotate or update that secret, it happens in one place and every Lab which uses it will
use the new value the next time it is launched.

In this Lab we define two secrets, `ssh_key` and `lab_images_reader_b64`.
We'll show you how you use them when we talk about creating VMs later.

### Networks

A virtual machine without a network isn't all that useful, so we've created a
[network](https://docs.labs.instruqt.com/reference/sandbox/networking/network/).
You can have an arbitrary number of networks in a Lab; so while in this case we
only have one network, you could mirror common setups by having a public network,
an API network, a database network, etc.

This Lab has one network, called `main`, with one required attribute set, `subnet`.
This defines the [CIDR block](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) of
addresses we want on this network. We do not use IPv6 in this Lab, so we leave out
the optional `enable_ipv6` attribute, which defaults to `false`.

### Virtual Machines

We have two [virtual machines](https://docs.labs.instruqt.com/reference/sandbox/compute/vm/)
in this Lab, a `workstation` and a `fileserver`. They're very similar, so let's walk
through the `workstation` VM.

The `config` and `resources` blocks define basic settings for the VM: what CPU architecture
it is, and the number of CPUs and the amount of memory to give this VM. We also define
the `image` the VM boots from. In this case, we use a custom image hosted in the platform
repository. More details on that can be found in the [README file](vm-images/README.md)
in the `vm-images` directory. Note that the `name` parameter in the `image` block
uses `${variable.instruqt_team_slug}` instead of a hardcoded team slug. It is replaced at
runtime with the "slug" of whatever team has this lab, so instead of hardcoding `test-drive`
we use a variable. This allows customers who have multiple teams to use a lab definition in
multiple teams.

This VM is attached to the `main` network, so we only have one `network` block.
Note the way we put this VM in the `main` network:

```
  network {
    id = resource.network.main.meta.id
  }
```

This is a _resource reference_, and is the key to one of the most powerful capabilities
of HCL. Above we created the `main` network by doing

```
resource "network" "main" {
  subnet = "172.20.0.0/25"
}
```

By setting `id = resource.network.main.meta.id` we connect those two resources in a logical
fashion. When the Instruqt platform creates the Lab sandbox, it sees that the `workstation`
VM requires the `main` network, so it knows it must create the network *before* the virtual
machine. You could move the lines defining the network to the end of the `sandbox.hcl` file,
or put it in an entirely different HCL file, and it would still work. There is no need for
explicit ordering, by defining resources and the logical relations between them, the Instruqt
platform can determine the order in which it must create resources --- and the order in which
it must destroy them when the Lab completes.

Finally we have an optional attribute, `startup_script`, which will run when the VM is
created. Here we use it to do some configuration of the VM at the start of the lab. There
are two interesting things here, which we'll conver in turn.

#### Functions

[_Functions_](https://docs.labs.instruqt.com/reference/functions/) allow you to manipulate
HCL expressions. The VM `startup_script` only accepts a string. You could pass it a string
which contains your entire startup script, but that is kind of messy if that file is long.
Here we use the function [`template_file`](https://docs.labs.instruqt.com/reference/functions/filesystem/#template_file),
which not only allows us to store the startup script in a separate file, but allows us to
pass in variables which will be rendered at run time.

For example, we set the variable `IGGYS_SSH_PRIVATE_KEY_BASE64 = resource.secret.ssh_key.value`.
This means that the variable `IGGYS_SSH_PRIVATE_KEY_BASE64` is set to the value of the
secret `ssh_key`. Inside the [setup-workstation.tmpl](scripts/setup-workstation.tmpl) file
is the line `echo "{{IGGYS_SSH_PRIVATE_KEY_BASE64}}" | base64 -d > id_ed25519`. The
`template_file` function when it renders that template, replaces `{{IGGYS_SSH_PRIVATE_KEY_BASE64}}`
with the value we set that variable in the function call.

This allows us to pass in information at runtime. Since we store `IGGYS_SSH_PRIVATE_KEY_BASE64`
as a secret (as we went over above), and that could be updated any time, the effect here is
that when the Lab sandbox is created it will fetch the current value of the secret, render it
in the startup file, and pass that to the VM to run.

#### Local Resources

A [_Local Resource_](https://docs.labs.instruqt.com/reference/types/local/) is a computed
value in your HCL configuration. Here we use it for some simple configuration, which
we put in the [`conf.hcl`](conf.hcl) file (remember, of course, that this is a convention,
and you could put it anywhere valid for an HCL configuration). There are many other
use cases, which the documentation covers, and they help with reducing duplication if you
need to use the same value many times, as well as allowing you to turn a large and hard
to understand expression into a series of more understandable intermediate values.

### Other Resources

There are many other resources available on the Instruqt platform which are not used in
this lab, including things like containers and cloud accounts. Check out the
[overview](https://docs.labs.instruqt.com/reference/content/) for the full list.

## Content Resources

[Content Resources](https://docs.labs.instruqt.com/reference/content/) are the material
and interactive elements the learner experiences during a Lab. Think of it as the user
interface of Labs.

Every Lab contains one and only one top-level resource, a [`lab`](https://docs.labs.instruqt.com/reference/content/lab/).
A `lab` contains some metadata and [`settings`](https://docs.labs.instruqt.com/reference/content/lab/#settings),
and also has [`content`](https://docs.labs.instruqt.com/reference/content/lab/#content). Within
the `content` is one or more [`chapter`s](https://docs.labs.instruqt.com/reference/content/lab/#content-chapter),
which in turn contain one or more [`page`s](https://docs.labs.instruqt.com/reference/content/lab/#content-chapter-page). You control the appearance of `page`s with [`layout`s](https://docs.labs.instruqt.com/reference/content/layout/), which can be set generically at the `lab` level and then overridden at the `chapter` and `page` level.
The following diagram gives a feel for the hierarchy of resources:

```
lab
├─ title, description (metadata)
├─ layout (reference to default layout)
├─ settings
│  ├─ theme
│  ├─ timelimit
│  │  ├─ duration, extend, show_timer
│  ├─ idle
│  │  ├─ enabled, timeout, show_warning
│  └─ controls
│     └─ show_stop
└─ content
   ├─ title
   └─ chapters[]
      ├─ title, layout (optional override)
      └─ pages[]
         ├─ title (optional override), layout (optional override)
         └─ reference (to page resource)
```

Finally, pages can (and should!) include [`task`s](https://docs.labs.instruqt.com/reference/content/task/),
interactive activities that your learners complete during the lab. Tasks are what turn passive observation
into active learning.

Let's examine each layer in turn.

### Lab

This Lab defines its single `lab` resource in [main.hcl](main.hcl). As noted above, this is
a convention; you could place the `lab` resource in any valid HCL file.

Our `lab` sets the `title` and `description`, and configures some [`settings`](https://docs.labs.instruqt.com/reference/content/lab/#settings), controlling the lab time limit and idle time configuration.
A Lab requires a maximum duration, which can be optionally extended, and optionally 
can be configured for how long it can sit idle before it goes away. A Lab, once started,
lasts until one of the following things happens:

1. A learner completes the lab
2. A learner stops the lab
3. A configured idle time has expired
4. The configured maximum duration has expired

In this Lab we configure the `timelimit` to be 15 minutes, and the `idle` timeout
to be 5 minutes.

Next our Lab configures a `layout` --- this required setting configures the page layout
that should be default for the Lab, which can be overridden at both the `chapter` and
`page` layers. This Lab is fairly simple, so it has only one default layout.

Finally, the `lab` configures the `content`. Before we get to that, let's look at
the Lab layout.

### Layout

In this Lab the [layout](https://docs.labs.instruqt.com/reference/content/layout/) is
defined in [`layouts.hcl`](layouts.hcl). A `layout` has one or more `column`s, which
contains either one or more `row`s or one or more `tabs`. A `row` then contains one
or more `tabs`. With this you could have a simple layout, like this lab has:

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                                  Lab                                           │
│  ┌─────────────────────────────────────────────────────┐ ┌───────────────────┐ │
│  │ ┌──────┐ ┌──────┐                                   │ │     Assignment    │ │
│  │ │ Tab  │ │ Tab  │                                   │ │                   │ │
│  │ ├──────┤ └──────┘                                   │ │                   │ │
│  │ │      └─────────────────────────────────────────┐  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ └────────────────────────────────────────────────┘  │ │                   │ │
│  │                                                     │ │                   │ │
│  └─────────────────────────────────────────────────────┘ └───────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────┘
```

Or something more complex:

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                                  Lab                                           │
│  ┌─────────────────────────────────────────────────────┐ ┌───────────────────┐ │
│  │ ┌──────┐ ┌──────┐                                   │ │     Assignment    │ │
│  │ │ Tab  │ │ Tab  │                                   │ │                   │ │
│  │ ├──────┤ └──────┘                                   │ │                   │ │
│  │ │      └─────────────────────────────────────────┐  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ │                                                │  │ │                   │ │
│  │ └────────────────────────────────────────────────┘  │ │                   │ │
│  └─────────────────────────────────────────────────────┘ │                   │ │
│  ┌─────────────────────────────────────────────────────┐ │                   │ │
│  │  Tab                                                │ │                   │ │
│  │                                                     │ │                   │ │
│  │                                                     │ │                   │ │
│  │                                                     │ │                   │ │
│  └─────────────────────────────────────────────────────┘ └───────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────┘
```

This Lab has two rows. The one on the left, which has a `width` of `70%` (so it
will take 70% of the screen), has two tabs.

One or more tabs can exist in a column or row, with one being active at any time.
This Lab has a [`terminal`](https://docs.labs.instruqt.com/reference/sandbox/ui/terminal/)
tab, and a [`virtual_browser`](https://docs.labs.instruqt.com/reference/sandbox/ui/virtualbrowser/)
tab. Other tabs can include exposing a [`service`](https://docs.labs.instruqt.com/reference/sandbox/ui/service/),
a browser-based text [`editor`](https://docs.labs.instruqt.com/reference/sandbox/ui/editor/),
or [`cloud_credentials`](https://docs.labs.instruqt.com/reference/sandbox/ui/cloud-credentials/).

Along with optional settings like the tab `title`, each `tab` requires a `target`,
which references the resource which is in that `tab`.

### Terminal

A `terminal` resource is just that, a terminal on either a VM or a container in
the sandbox, which you specify by configuring the `target` --- in this Lab,
the `target` is `resource.vm.workstation`, one of the VMs that is in the Lab
sandbox. You can also define the `user` and `group` this terminal runs as,
the `shell` being used, and the `working_directory` the terminal starts in.
All of those must exist on the `target` resource.

### Virtual Browser

A `virtual_browser` embeds a virtual web browser in a tab. This allows you to
display a web page within a tab without having to make your learner open up a
browser tab or window outside of the Lab window. Here we use it to display
the webpage for the `rsync` documentation.

### Instructions

Of course, a Lab with resources isn't that useful to your learner if you don't
provide them guidance on what to do. This is where the `instructions` comes in.
This is where in the `layout` you expose the `chapter`s and `page`s to your
learner.

In this Lab, we put the `instructions` in the second column.

### Chapters and Pages

Chapters and pages are how you break up your instructions to manageable, consumable
content for your learners. How you break that up depends on the complexity of your
instructions. A simple Lab, like this one, just has three pages. But a more complex
Lab may have multple chapters, each with multiple pages. Ultimately, though, you
have a series of pages; chapters are ways of logically grouping them together so they
are coherent for your learners.

When deciding how to break up a Lab into chapters and pages, some criteria should
be used:

1. Each `page` should have a single, concrete concept you are trying to convey to
   your learners. It should include a `task` to ensure the learner understands
   that concrete concept before moving on
2. Group together related `page`s by putting them in a chapter. For example,
   you may have a Lab where you configure a service, and then use it. If configuring
   the service requires, say, three distinct steps, then it makes sense to have
   a "configuration" chapter with a page for each step. This could then be followed
   by a chapter where you use the configuration your learner just configured.

#### Chapter

This Lab is fairly simple, and doesn't even really need a `chapter`. As you can see
in [`main.hcl`](main.hcl), you can create a special `chapter "__default"` resource
to do that.

#### Pages

In that default `chapter`, this Lab has three pages. Each of those is a separate
`page` resource, and each of those `page`s has a `task` for the user to complete.

The default convention is to define all pages in a `content.hcl` file, and all tasks
in a `tasks.hcl` file, but that is just content. In this Lab, we group a page and
its task in separate HCL files, one per page. Let's look at the page for
"Selective Transfers", located in [`selective-transfers.hcl`](selective-transfers.hcl).

The `selective-transfers` `page` must have a `title` and a `file` configured, and
then optionally may define `variables` and `activities`. We set the title with
`title = "Selective Transfers"`, and then point to the file containing the actual
content with `file = "instructions/selective-transfers.md"`

Content is defined with [Markdown syntax](https://docs.labs.instruqt.com/ui-overview/adding-content/markdown-editor/#markdown-syntax-reference). You can write the Markdown manually, or use the
in-platform [Content Editor](https://docs.labs.instruqt.com/ui-overview/adding-content/markdown-editor/).

There are a few useful things you can include in the Markdown.

##### Variable Substitution

Note that in [`selective-transfers.hcl`](selective-transfers.hcl) we have this
in our `page` resource:

```
  variables = {
    WORKSTATION_DST_DIR = local.workstation_dst_dir
    FILESERVER_SRC_DIR  = local.fileserver_src_dir
  }
```

These set [variables](https://docs.labs.instruqt.com/reference/content/page/#variable-substitution) which
may be substituted in the Markdown text. So, with the above `variables` set, the lines in
[`instructions/selective-transfers.md`](instructions/selective-transfers.md) like this:

```
rsync -av --stats --exclude '*' --include '*.lbl' fileserver:{{FILESERVER_SRC_DIR}} {{WORKSTATION_DST_DIR}}
```

Will have `{{FILESERVER_SRC_DIR}}` and `{{WORKSTATION_DST_DIR}` set to the runtime
values of those two variables, allowing your instructions to be dynamic. Here we use it
to allow us to configure those two variables as locals in [`conf.hcl`](conf.hcl), making
it easy to change the configuration of the Lab by changing it in `conf.hcl` and then
referencing it everywhere else within the Lab. But, you might also use it to, say, create
dynamic credentials for a service running in a Lab and then instructing the learner to
log in with those specific credentials in the instructions.

##### Interactive Activities

Note at the bottom of [`instructions/selective-transfers.md`](instructions/selective-transfers.md)
the following two lines:

```
<instruqt-task id="selective-transfers"></instruqt-task>

<instruqt-completion text="And now you know very little about the rsync file transfer tool!"></instruqt-completion>
```

The first line includes the `selective-transfers` task at that point in the instructions.
We'll talk about that next. The final line provides a [completion component]
(https://docs.labs.instruqt.com/ui-overview/adding-content/completion/), which will show
the learner's progress throughout the Lab, and gives them a "Finish & Exit" button when they
have completed every task. Without this, the learner has no clean way to exit the Lab;
they could just close the window, but that leaves the Lab sandbox running until a timeout
happens.

### Tasks

A [`task`](https://docs.labs.instruqt.com/reference/content/task/) resource defines an interactive
activity a learner must complete to finish the Lab. Each task can have one or more
conditions, each of which can have its own `setup`, `check`, `solve`, and `cleanup` scripts.
Let's look again at [`instructions/selective-transfers.md`](instructions/selective-transfers.md),
and notice at the bottom where you see the line:

```
<instruqt-task id="selective-transfers"></instruqt-task>
```

This attaches a Task to this Page in the Lab, the configuration of which is defined by the
`resource "task" "selective-transfers"` stanza in the [`selective-transfers.hcl`](selective-transfers.hcl)
file.

A `task` resource must have a `description`, which gives a short explanation of what you are
asking the learner to do. This task also sets the optional `success_message`, which is displayed
to the user when the successfully complete the task.

A `task` can also include an optional `config`, which becomes the default configuration for
each `condition` in this `task`. You can override that at both the `condition` level, as well
as at the `setup`, `check`, `solve`, and `cleanup` levels.

Here the `config` section sets the `target`, where you actually want the `task` to run, as
well as the `user`, `group`, `working_directory` where it should run. It also defines a
`timeout` for how long we allow the task to run, and defines both which exit codes from
the tasks scripts are considered a successful completion with `success_exit_codes` as well
as defining which exit codes are considered `failure_exit_codes`. Finally, it configures
an `environment`, defining environment variables which will be available to the task scripts.

When a page is reached which has one or more Tasks, the following happens:

1. When the page is first reached, any Tasks which have a `setup` script defined are ran
2. Any task which has `check` scripts defined runs them when the learner clicks on the
   check button in the assignment. If all of them exit with one of the defined
   `success_exit_codes` then the check is considered successful. If any of them fail with
   a `failure_exit_codes` then the check is failed, and the `failure_message` is returned.
3. When the learner completes the page and moves to the next, any Tasks with `cleanup`
   scripts are ran before moving on to the next page.
4. Any tasks with solve scripts are used to enable both [automated testing](https://docs.labs.instruqt.com/development/automated-testing/) and page skipping

See [Script Execution Flow](https://docs.labs.instruqt.com/reference/content/task/#script-execution-flow) for the full details.

#### Conditions

This task contains a single `condition`, which is a collection of validations which must
all happen for the task to complete. Multiple `conditions` are supported. The `condition`
has a `description`, which explains to the learner what the condition is doing.

##### Checks

A `check` is ran when the learner clicks on the button to run the task. It configures
a `script` which is ran, as well as a `failure_message` to display if the script returns any of
the `failure_exit_codes`.

A `check` script should check for one and only one thing, and simply return one of the
configured exit codes to indicate success or failure. No output is returned to the user;
if the script returns one of the `failure_exit_codes` the `failure_message` is what
is displayed to the learner.

The `check` script can be written in any language, but the interpreter for that script
must already be installed on the `target`.

#### Solve

A `solve` script is ran if the learner skips that particular `task`. It should perform
the same actions you asked the learner to do.

#### Setup

A `setup` script runs when the page with this `task` embedded in it is displayed.
It can be used to ensure the Lab is ready for that particular page, and an example
of one can be found in [`incremental-update.hcl`](incremental-update.hcl)

#### Cleanup

Conversely, a `cleanup` script runs when a page is exited, and can be used to clean up
anything done by this page before moving to the next.

### Testing

Task scripts are also used in [Automated Testing](https://docs.labs.instruqt.com/development/automated-testing/).
