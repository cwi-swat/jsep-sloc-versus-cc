module gather::SLOCs

import util::Math;
import List;
import Set;
import metric::SLOC;
import util::FileSystem;
import util::Benchmark;
import IO;
import ValueIO;
import String;
import Exception;
import gather::ASTs;

set[loc] findFiles(set[str] extensions,  loc root = |project://dexter/src/|) 
	= {l | /file(l) <- crawl(root), !startsWith(l.file, "."), toLowerCase(l.extension) in extensionsLower}
	when set[str] extensionsLower := { toLowerCase(e) | e <- extensions};

private int reportTime =(2000 * 1000 * 1000); 

rel[loc, list[int]] gatherSLOCs(loc source, str name, int depth) {
	rel[loc, list[int]] result = {};
	_files = findFiles({"java"}, root = source);
	si = size(_files);
	println("Size: <si>");
	stepSize = max(1, si / 4);
	offset = 0.0;
	for (f <- _files) {
		try {
			time = cpuTime(() { result += {<f, getSLOCLines(f)>};});
			if (time > reportTime) {
				println("<f> took <time / (1000*1000)>ms");	
			}
		}
		catch ParseError(el) : {
			println("ParseError: <el>");
		}
		catch RuntimeException e: {
			println("Exception: <f> =\> <e>");
		}
		offset = offset + 1;
		if (toInt(offset) % stepSize == 0) 
			println("<100*(offset/si)>%");
	}
	
	return { <fixLoc(l, name, depth), b> | <l,b> <- result};
}

int replaceIfInvalid(int c) {
	if (48 <= c && c <= 57) {
		return c; // digits	
	}
	if (97 <= c && c <= 122) {
		return c; // a-z
	}
	if (65 <= c && c <= 90) {
		return c; // A-Z
	}
	if (c == 46) {
		return c; // .	
	}
	return 95; // _
}

str removeInvalidChars(str s) = stringChars([ replaceIfInvalid(charAt(s,i)) | i <- [0..size(s)]]);

str getProjectName(loc l) {
	propL = l + "/project.properties";
	if (!exists(propL)) {
		return "";	
	}
	str contents = readFile(propL);
	if (/name[^=]*=<n:.*>/ := contents) {
		return trim(n);
	}
	return "";
}

str validFileName(str projectDir, str projectName) 
	= "<removeInvalidChars(projectDir)>-<removeInvalidChars(projectName)>";

public void main(str input, str name = "sourcerer", int depth = 2) {
	if (!exists(|cwd:///<input>|)) {
		println("E: <input> does not exist");
		return;	
	}
	if (!exists(|cwd:///Corpus/|)) {
		println("E: Corpus/ does not exist");
		return;	
	}
	if (!exists(|cwd:///Results/|)) {
		println("E: Results/ does not exist");
		return;	
	}
	list[str] projects = readFileLines(|cwd:///<input>|);
	for (str proj <- projects) {
		projectName = getProjectName(|cwd:///Corpus/<proj>|);
		println("Gathering slocs in <proj> (<projectName>)");
		slocs = gatherSLOCs(|cwd:///Corpus/<proj>|, name, depth);
		println("Found <size(slocs)> methods");
		println("Saving slocs found in <proj> (<projectName>)");
		writeBinaryValueFile(|cwd:///Results/<validFileName(proj, projectName)>.slocs|, slocs);
	}
}