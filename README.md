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
