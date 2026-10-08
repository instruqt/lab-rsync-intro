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

## Annotated Lab Guide

### Background

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

### Code Conventions

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

### Sandbox Resources

[Sandbox Resources](https://docs.labs.instruqt.com/reference/sandbox/) are the infrastructure
within a Lab sandbox: the VMs, containers, networks, cloud accounts, etc. These create the
environment in which your Learner operates and the ways that they access them, like a
terminal, service, or editor, etc. In this lab they are primarily defined in the file
[sandbox.hcl](sandbox.hcl)

This sandbox is pretty simple: a couple secrets, a shared network, and two virtual machines.

#### Secrets

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

#### Networks

A virtual machine without a network isn't all that useful, so we've created a
[network](https://docs.labs.instruqt.com/reference/sandbox/networking/network/).
You can have an arbitrary number of networks in a Lab; so while in this case we
only have one network, you could mirror common setups by having a public network,
an API network, a database network, etc.

This Lab has one network, called `main`, with one required attribute set, `subnet`.
This defines the [CIDR block](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) of
addresses we want on this network. We do not use IPv6 in this Lab, so we leave out
the optional `enable_ipv6` attribute, which defaults to `false`.

#### Virtual Machines

We have two [virtual machines](https://docs.labs.instruqt.com/reference/sandbox/compute/vm/)
in this Lab, a `workstation` and a `fileserver`. They're very similar, so let's walk
through the `workstation` VM.

The `config` and `resources` blocks define basic settings for the VM: what CPU architecture
it is, and the number of CPUs and the amount of memory to give this VM. We also define
the `image` the VM boots from. In this case, we use a custom image hosted in a private
repository. More details on that can be found in the [README file](vm-images/README.md)
in the `vm-images` directory. This VM is attached to the `main` network, so we only
have one `network` block.

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

##### Functions

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

##### Local Resources
A [_Local Resource_](https://docs.labs.instruqt.com/reference/types/local/) is a computed
value in your HCL configuration. Here we use it for some simple configuration, which
we put in the [`conf.hcl`](conf.hcl) file (remember, of course, that this is a convention,
and you could put it anywhere valid for an HCL configuration). There are many other
use cases, which the documentation covers, and they help with reducing duplication if you
need to use the same value many times, as well as allowing you to turn a large and hard
to understand expression into a series of more understandable intermediate values.


### Content Resources

