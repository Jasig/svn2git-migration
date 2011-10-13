def allAuthors = new File("resolvedAuthors.txt");
def mappedAuthors = new File("mappedAuthors.txt");
def mergedAuthors = new File("target/mergedAuthors.txt");

def authorsMap = new TreeMap(String.CASE_INSENSITIVE_ORDER);

def loadAuthors(authorsFile, authorsMap) {
    def lineNum = 0;
    authorsFile.eachLine { line ->
        lineNum++;
        line = line.trim();
        if (line.length() == 0 || line.startsWith("#")) {
            return;
        }
        
        def lineParts = line.split("=");
        if (lineParts.length != 2) {
            throw new Exception(authorsFile.toString() + " - Failed to parse line " + lineNum + ", it did not have two parts: " + line);
        }
        
        authorsMap.put(lineParts[0].trim(), lineParts[1].trim());
    }
}

//Load list of all authors
loadAuthors(allAuthors, authorsMap);

//Load mapped authors (those with known github accounts)
loadAuthors(mappedAuthors, authorsMap);

//Write out merged authors file
mergedAuthors.getParentFile().mkdirs();
mergedAuthors.withWriter { writer ->
    authorsMap.each() {svnAuth, gitAuth ->
        writer.writeLine(svnAuth + " = " + gitAuth);
    }
}
