# NAME

Tran::Manual - manual of tran

# DESCRIPTION

I've translated some modules and perl core documentation.
But recent years, I translated only a few modules.

The translation of Perl modules is somewhat dull and hard work.
Because ...

1. Modules will be updated.

    Of course, modules will be released new version since you translated it.
    It means that translators need to manage modules' code by something like version control system.
    Many module has its own repository, but their places is different by each module.
    Don't you want to control them in one place?

2. Hard to find difference from previous version and hard to merge it.

    Even if translators manage modules' code, translator need to find difference and merge it.
    diff3 is not useful in this case and I don't know translators can be good at using such tools.

3. Don't Repeat Yourself

    We should do DRY. I won't repeat same thing.
    I did perldoc -u ModuleName many times. I'm bored.

So, I wrote this tool, "tran".
It helps translators. Let's start tran.

# Terms using in tran

Befor staring translation, I explain some terms.

## Resource

A resource which contains target to be translated.
For example, CPAN is resource.

## Target

A target to be translated.
For example, CPAN Module is target.

## Repository

A place to store files.

## Original Repository

A place to store original files to be translated.

## Translation Repository

A place to store translated files.

# Prepare tran.

Before starting translation, you have to prepare tran.
type the command.

    % tran init

It ask you some questions. Answer them.

After the command is done, it creates the configuration file in the directory,
".tran" under your home directory.
You can confirm contents of the configuration by the command:

    % tran config

It show the file content of ~/.tran/config.yml

    ---
    log:
      class: Stderr
      level: info
    notify: {}
    repository:
      original:
        directory: /home/user/.tran/original/
      translation:
        jpa:
          directory: /home/user/git/github/jpa-translation/
          vcs:
            user: ktat
            wd: /home/user/git/github/jpa-translation/
        jprp-core:
          directory: /home/user/cvs/perldocjp/docs/perl/
          vcs:
            wd: /home/user/cvs/perldocjp/docs/perl/
        jprp-modules:
          directory: /home/user/cvs/perldocjp/docs/modules/
          vcs:
            wd: /home/user/cvs/perldocjp/docs/perl/
        merge_method: cmpmerge
    resource:
      cpan:
        metafile: /home/user/.cpan/Metadata
        target_only:
        - '*.pm'
        - '*.pod'
        targets:
          Moose:
            translation: jpa
          MooseX::Getopt:
            translation: jpa
          perl:
            translation: jprp-core
        translation: jprp-modules

I'll explain about configuration at ["Configuration File"](#Configuration File).
Now, at first, try to start translation.

# The flow of translation

After this section, I'll explain how to use tran,
before this, I show my assuming translation flow.

## (A) Start new translation

1. Start to translate Module::Name
2. Start to translate the latest Module::Name

## (B) Start new translation, but you've already had the translated file.

1. Rearrange directory structure and file name of the translated file
2. Get the original source of the translated version
3. Start to translate latest Module::Name.
4. Start to translate the latest Module::Name

# (A) Start new translation

## 1\. Start translation with "start" command

Use start command. Its arguments are resource name and target name(in this case, module name).
You can pass version as optional.

    % tran start -r cpan -t jprp-modules Module::Name

It means that you start to translate Module::Name in the resource cpan with translation repository `jprp-modules`.

tran get Module::Name's tar.gz file from CPAN, and extract it under the directory,
"~/.tran/original/cpan". If the latest version of Module::Name is 0.1,
Actually, it put in the following directory.

    ~/.tran/original/cpan/Module-Name/0.1/

## 2\. Translate the latest Module::Name.

Time passed, and new version of Module::Name was released.
You can use same command "start".

    % tran start -r cpan Module::Name

Almost same command I showed then. After first time, `-t` option is not required.
In this time, You have previous version of original and previous version of the translated.
tran can merge the difference between older and newer original to the previous translated.
The merged file is put in translation repository. 

# (B) Start new translation, but you've already had the translated file.

In this case, you need to do the following steps before starting translation.

## 1\. Rearrange directory structure and file name of the translated file

If the translated file is different from translation repository assuming structure,
rearrange its directory/file structure.

## 2\. Get the original source of the translated version

    tran get -r cpan Module::Name 0.01

Like this, get target from resource with version.
If resource is cpan, module author is different, it doesn't work well.
In such case, use URL instead.

    tran get -r cpan http://..../Module-Name-0.01.tar.gz

Then, you can get original source.

## 3\. Start to translate latest Module::Name.

After that, the following steps are as same as (A).

    tran start -r cpan Module::Name

## 4\. Start to translate the latest Module::Name

    tran start -r cpan Module::Name

# Default Resource

If you translate only CPAN, you may want to omit -r option.
You can set default resource in configuration file.

    default_resorce cpan

# Configuration File

## log

Setting for log.

    log:
      class: Stderr
      level: info

If you want more detail information, set "debug" as level.

## notify

Setting for notification.

    notify:
      perldocjp:
       class: Email
       from: from@example.com
       to: to@example.com
       template_directory: /home/user/.tran/template/perldocjp/

The name of template file put under the template\_directory,
is as same as command name.

For example:

"/home/user/.tran/template/perldocjp/start"

    Subject: [RFC]Start translation of %n %v 
    charset: ascii
    

    Hello
    

    I started to translate %n version %v.
    

    -- 
    Your Name
    mailto: from@example.com

%n will be replaced as target name.
%v will be replaced as version number.

## repository/original

Setting for original repository.

    original:
      directory: /home/user/.tran/original/

No need to change this.

## repository/translation

Setting for translation repository.

    translation:
      jpa:
        directory: /home/user/git/github/jpa-translation/
        vcs:
          user: ktat
          wd: /home/user/git/github/jpa-translation/
      merge_method: cmpmerge_least

## resource

Setting for resource.

    resource:
      cpan:
        metafile: /home/user/.cpan/Metadata
        target_only:
        - '*.pm'
        - '*.pod'
        translation: jprp-modules
        targets:
          Moose:
            translation: jpa
          MooseX::Getopt:
            translation: jpa
          perl:
            translation: jprp-core

# Commands

## init

Do initialize setting for tran.

    tran init [-f|--force]

If configuration file exists, do nothing.
But, if you use -f option, force recreate configuration file.

## start

The command when you want to start new translation.

    tran start -r RESOURCE TARGET [VERSION]

start command will do the following:

1. get source.

    Get source from resource.

2. Merge the difference between older and newer original if exists

    If the previous version of original and the previous version of translation are found,
    merge the difference between original latest version and previous version to the translated.
    The merged is put in translation repository as new translation.

3. copy files(with modification if needed).

    For example, abstract document part from module,
    rename .pm to .pod, change path structure for the translation repository. etc.

## get

To get original files from resource.

    tran get -r RESOURCE TARGET [VERSION]

## config

Show config.

    tran config [ITEM]

If no item is given, all content is shown.

For example:

    tran config resource

show only setting of resource.

    tran config repository

show only setting of repository.

## reconfigure

Reconfigure setting.

    tran reconfigure [item [sub item]]

You can pass the part you want to reconfigure.

## diff

get difference between target versions.
If you set your favorite pager in TRAN\_PAGER environmental variable,
display output with pager.

    tran diff [-v version/-o/-t] -r RESOURCE TARGET [files ...]

- no option

    `diff` between original and translation. if you don't give version,
    `diff` between the original latest and the translation latest.

- `-o/--original`

    `diff` between originals. if you don't give version.
    `diff` between the previous latest original and the latest original.

- `-t/--translation`

    `diff` between translations. if you don't give version.
    `diff` between the previous latest translation and the latest translation.

- `-v/--version`

    specify version like this.

        -v 0.01:0.02
        -v 0.01

If the version of the target is not found, it fails.
If the name of files allow to be put after target name,
only show the files which is matched with them.

## merge

Merge manually.

    tran merge TRANSLATION_REPOSITORY OLDER_ORIGINAL_FILE NEWER_ORIGINAL_FILE OLDER_TRANSLATION_FILE NEWER_TRANSLATION_FILE

Normally start command does merge automatically. But, in some case, it cannot do merge.
For example, directory structure is difference between older and newer.

VCS::Lite 0.04's directory structure.

    VCS-Lite/0.04/Lite.pod
    VCS-Lite/0.04/lib/VCS/Lite/Delta.pod

But, 0.09 is

    VCS-Lite/0.09/lib/VCS/Lite.pod
    VCS-Lite/0.09/lib/VCS/Lite/Delta.pod

In this case, cannot merge Lite.pod.
You can merge manually using this command.

    tran merge jprp-modules cpan/VCS-Lite/0.04/Lite.pod cpan/VCS-Lite/0.09/lib/VCS/Lite.pod \
                                 VCS-Lite-0.04/Lite.pod      VCS-Lite-0.09/lib/VCS/Lite.pod

The merged result is written to VCS-Lite-0.09/lib/VCS/Lite.pod.
If you don't pass newer translation file as last argument,
The merged result is outputted to STDOUT.

You can use absolute path or relative path.
Relative paths are from original repository's directory for original,
from translation repository's directory for translation.

## ls

show list of files.

    tran ls -r RESOURCE TARGET [VERSION] path/to/anywhere
    tran ls --tr translation-repository

- no option

    show list of files in original repository.

- `-t/--translation`

    show list of files in translation repository.

- `--tr/--translation_repository`

    As an argument, the name of translation repository(e.g. `jprp-modules`)
    If TARGET is not given, show directories in translation repository.

## cat

display content of file

    tran cat -r RESOURCE TARGET [VERSION] path/to/anywhere

- `-t/--translation`

    show file content which is in translation repository.

- `-n/--number`

    show file content with line number.

# SEE ALSO

- [Tran::Manual::Extend](http://search.cpan.org/perldoc?Tran::Manual::Extend)

    How to create sub class for other resources and other translation repositories.

# AUTHOR

Ktat, `<ktat at cpan.org>`

# COPYRIGHT & LICENCE

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
