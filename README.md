# Jasig svn2git Utilities

## Author Mapping
To better preserve commit history it is good to map Jasig SVN usernames to Git identies. Git uses
email address for identity mapping (not your GitHub username) so a mapping entry looks like:
```edalquist = Eric Dalquist <eric.dalquist@example.com>```

Author mappings are maintained in **mappedAuthors.txt** and as developers that have commits in the
Jasig SVN repository move to Git they should add an appropriate mapping in the file.

Since svn2git requires ALL authors be mapped the file **resolvedAuthors.txt** has been generated
from a list of all SVN committers with name and email information resolved from the Jasig Crowd
server using the **resolveJasigAuthors.groovy** script. **MOST USERS CAN IGNORE THIS FILE**

## SVN to GIT Migration
Install the svn2git tool available here: https://github.com/nirvdrum/svn2git

#### Generate Authors File
    groovy mergeAuthors.groovy

#### Create a directory for the new git repository
    mkdir /path/to/project_git
    cd /path/to/project_git

#### Run svn2git
    svn2git https://source.jasig.org/project \
        --verbose \
        --authors /path/to/jasig-svn2git-migration/target/mergedAuthors.txt \
        --metadata

#### Push the changes to GitHub
    git remote add origin git@github.com:jasig/project.git
    git push -u --mirror

    
## Read Only SVN Mirror
A read only mirror of the new git repository can be maintained by using the included gitToSvnSync.sh
script. Unlike git-svn dcommit the method used by gitToSvnSync.sh works with git merges, though merge
information is lost and multiple commits as part of a merge are flattened into a single svn change set.
The script uses the svn remote information in the git repository's config file to determine where to
commit to.

### Configuration
After following the above instructions to migrate the project take a copy of the local git repository
that was created and modify the **.git/config** file. Find the **[remote "origin"]** section and change
the **url** attribute to a read-only url like: **git://github.com/Jasig/uPortal.git**

Place the gitToSvnSync.sh and the modify repository on a server that can either run the script on schedule
or use a GitHub commit hook to trigger its execution. For Jasig projects contact the infrastructure team
as Bamboo is used to trigger the sync.

In this example the **/opt/git/repositories/uPortal** git repository is being synced back to SVN with 
**infrastructure@lists.ja-sig.org** being the SVN user that makes the commits and the **master**, **umobile-trunk**, 
and **rel-3-2-patches** branches being synced. 
    /opt/git/repositories/gitToSvnSync.sh \
        -g /opt/git/repositories/uPortal \
        -w /opt/git/repositories/ \
        -u infrastructure@lists.ja-sig.org \
        -b master -b umobile-trunk -b rel-3-2-patches

