Git: Combine Repositories
=========================

Combines multiple git repositories as subdirectories into a new repository.
This script performs a full migration, including all branches and tags.

Licensing
---------
Copyright (C) 2013 Stefan Rotman - Puzzle ITC GmbH <rotman@puzzle.ch>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Usage
-----
To use this script, change the required variable descriptions at the start of the `git-combine-repos.bash`:

* `TARGET_REPO`
    + The name of the new target repository to create
* `WORKSPACE`
    + The directory where the 'old' repositories will be cloned into and the new repository will be created. Provides a default option.
* `PROJECTS`
    + For every repository to migrate a `[CODE]=repository_name` line.
* `REPOSITORIES`
    + For every repository to migrate a `[CODE]=repository_url` line.
* `MERGE_PROJECTS`
    + Lists the project codes for all repositories to migrate.

When all these are set correct, the
script can simply be started by executing the `git-combine-repos.bash` script.

Example
-------

### The Situation ###
We have the repositories **foo**, **bar** and **baz**, that we wist to lay together in a new repository **qux**.

* **foo** is only a local repository, living under `/home/user/foo`
    + foo has 3 existing branches: `master`, `development` and `dev/fixes`
    + foo has 2 tags: `0.1` and `1.0`
* **bar** is a remote repository, living under https://example.com/git/bar.git 
    + bar has 2 existing branches: `master`, `development`
    + bar has 3 tags: `1.0` , `2.0` and `2.1`
* **baz** is a remote repository, living under https://example.com/git/baz.git 
    + baz has 3 existing branches: `master`, `dev/fixes`, `baz-reworked`
    + baz has 4 tags: `baz-1` , `baz-2`, `baz-reworked-1` and `reviewed`

### Configuration ###

Before combining these, we modify the `git-combine-repos.bash` script as follows:

    ####
    # The name of the target
    TARGET_REPO=qux
    
    ####
    # The working directory
    WORKSPACE="${HOME}/gitmerge/${TARGET_REPO}_$(date +%Y%m%d_%H%M)"
    # No need to change, the default will do just fine.
    
    ####
    # Definition of project codes and projects
    declare -A PROJECTS
    PROJECTS=( [F]=foo
             [B]=bar
             [BZ]=baz )
    
    ####
    # Definition of project codes and repositories
    declare -A REPOSITORIES
    REPOSITORIES=( [F]=/home/user/foo
             [B]=https://example.com/git/bar.git
             [BZ]=https://example.com/git/baz.git )
    
    ####
    # The project codes of the projects to combine.
    MERGE_PROJECTS="F B BZ"

### Combining the stuff ###

With the config above, all we now need to do to start the migration, is executing

    <path>/git-combine-repos.bash

### Result ###

In the directory `/home/user/gitmerge/qux_YYYYmmDD_HH:MM` there will be 4 repositories present:
* foo.git -  was used as the working directory to migrate the foo repos
* bar.git - was used as the working directory to migrate the bar repos
* baz.git - was used as the working directory to migrate the baz repos
* qux - houses the new repository

**qux** has 7 branches:
* foo-master (was master of foo)
* foo-development (was development of foo)
* dev/foo-fixes (was dev/fixes of foo)
* bar-master (was master of bar)
* bar-development (was development of bar)
* baz-master (was master of baz)
* dev/baz-fixes (was dev/fixes of baz)
* baz-baz-reworked (was baz-reworked of baz)

**qux** has 9 branches:
* foo-0.1 (was 0.1 of foo)
* foo-1.0 (was 1.0 of foo)
* bar-1.0 (was 1.0 of bar)
* bar-2.0 (was 2.0 of bar)
* bar-2.1 (was 2.1 of bar)
* baz-baz-1 (was baz-1 of baz)
* baz-baz-2 (was baz-2 of baz)
* baz-baz-reworked-1 (was baz-reworked-1 of baz)
* baz-reviewed (was reviewed of baz)

The final steps of creating a new `master` branch and laying together some of the migrated branches where needed is left for manual labor.
