module gather::ASTs

import ParseTree;
import IO;
import String;
import util::FileSystem;
import Set;
import List;
import String;
import util::Math;
import ValueIO;
import Exception;
import lang::csv::IO;
import util::Benchmark;

import lang::java::m3::AST;

anno loc node@src;

Declaration fixLoc(Declaration d, str name, int depth) 
	= visit(d) {
		case node n => n[@src = fixLoc(n@src, name, depth)]
			when (n@src?) && n@src.scheme == "cwd"
	};


@memo
str fixPath(str path, int depth) 
	= intercalate("/", split("/", path)[depth..]);

loc fixLoc(loc l, str name, int depth) {
	if (l.scheme == "cwd" && startsWith(l.path, "/Corpus")) {
		return l
			[scheme="corpus+<name>"]
			[authority = ""]
			[path = fixPath(l.path, depth)];
	}
	else {
		return l;	
	}
}

Declaration getDeclaration(loc f) {
	try {
		return createAstFromFile(f, false, javaVersion = "1.6");
	}
	catch RuntimeException e: {
		return createAstFromFile(f, false, javaVersion = "1.4");
	}
}

set[loc] findFiles(set[str] extensions,  loc root) 
	= {l | /file(l) <- crawl(root), !startsWith(l.file, "."), toLowerCase(l.extension) in extensionsLower}
	when set[str] extensionsLower := { toLowerCase(e) | e <- extensions};

private int reportTime =(2000 * 1000 * 1000); 

tuple[list[str] errors, list[Declaration] result] gatherMethods(loc source, str name, int depth) {
	list[str] errors = [];
	set[loc] files = findFiles({"java"}, source);
	si = size(files);
	stepSize = max(1,si / 4);
	println("Size: <si>");
	offset = 0.0;
	result = result: for (f <- files) {
		try {
			time = cpuTime(() { append result: fixLoc(getDeclaration(f), name, depth);});
			if (time > reportTime) {
				println("<f> took <time / (1000*1000)>ms");	
			}
		}
		catch RuntimeException e: {
			errors += ["Exception: <f> =\> <e>"];	
		}
		offset = offset + 1;
		if (toInt(offset) % stepSize == 0) 
			println("<100*(offset/si)>%");
	}
	return <errors, result>;
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

int main(str input = "", int split = 0, str name = "sourcerer", int depth = 2) {
	if (split > 0) {
		projSize = readCSV(#rel[str, int], |cwd:///sizes.csv|,("separator": "\t", "header": "false"));
		sizes = projSize<1,0>;
		totalSize = ( 0 | it + s | <s,_> <- sizes);
		projectsSorted = reverse([ *sizes[s] | s <- sort([*sizes<0>]), s > 100]);
		list[list[str]] splitted = [ [] | i <- [0..split]];
		list[int] splitSize = [0 | i <- [0..split]];
		int currentSplit = 0;
		for (i <- [0..size(projectsSorted)]) {
			smallest = 0;
			for (j <- [0..split]) {
				if (splitSize[j] < splitSize[smallest]) {
					smallest = j;	
				}	
			}
			splitted[smallest] += [projectsSorted[i]];
			splitSize[smallest] += getOneFrom(projSize[projectsSorted[i]]);
		}	
		for (i <- [0..split]) {
			println("<i> \t<splitSize[i]>");
			writeFile(|cwd:///list<"<i>">.txt|, intercalate("\n", splitted[i]));
		}
	}
	else {
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
			println("Gathering ASTs in <proj> (<projectName>)");
			<errors, methods> = gatherMethods(|cwd:///Corpus/<proj>|, name, depth);
			println("Found <size(methods)> methods");
			println("Had <size(errors)> errors");
			println("Saving method found in <proj> (<projectName>)");
			writeBinaryValueFile(|cwd:///Results/<validFileName(proj, projectName)>.asts|, methods);
			if (errors != []) {
				writeFile(|cwd:///Results/<validFileName(proj, projectName)>.errors|, intercalate("\n",errors));
			}
		}
	}
	return 0;
}