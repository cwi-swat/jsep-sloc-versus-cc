module analyse::JSEP

import IO;
import String;
import util::FileSystem;
import Map;
import Set;
import List;
import util::Math;
import ValueIO;
import Exception;
import lang::csv::IO;
import util::Benchmark;
import metric::SLOC;

import lang::java::m3::AST;

int slocStrangeFile(loc target, loc corpus)  {
	loc newl = (corpus + target.path)[offset=target.offset][length=target.length];
	return size(getSLOCLines(newl));
}

bool shouldFilter(loc l)
	= /(third|3rd)[-_]?party|examples\/?|[-_\/]tests?\// := l.path;

int mainEverything(loc dir = |cwd:///|, loc corpus= |cwd:///../Corpus|) {
	list[loc] files = sort({l | /file(l) := crawl(dir), l.extension == "ccm3"});
	lrel[str project, loc file, str name, int cc, int ccWrong, int sloc] result = [];
	set[loc] errors = {};
	int progress = 0;
	set[loc] strangeNewlines = readTextValueFile(#set[loc], dir + "strange-double-newlines.txt");
	result = result: for (f <- files) {
		project = f[extension = ""].file;
		slocs = toMapUnique(readBinaryValueFile(#rel[loc, list[int]], f[extension="slocs"]));
		names = toMapUnique(readBinaryValueFile(#lrel[loc, str], f[extension="names"]));
		ccs = readBinaryValueFile(#lrel[loc ml, int cc, int brokencc], f);
		for (<l, cc, ccw> <- ccs, !shouldFilter(l)) {
			ltop = l.top;
			if (ltop in slocs && !(l.length == 0 || ltop in strangeNewlines || l.end.line == 0)) {
				append result: <project, l, names[l]?"", cc, ccw, size({*slocs[l.top]} & {*[l.begin.line..l.end.line + 1]})>;
			}
			else if (l.length == 0) {
				errors += l;	
			}
			else {
				try {
					append result: <project, l, names[l]?"", cc, ccw, slocStrangeFile(l, corpus)>;
				} 
				catch RuntimeException e: {
					errors += l;	
				}
			}
		}
		progress += 1;
		if (progress % 100 == 0) {
			println(round(100 * (toReal(progress) / size(files))));	
		}
	};
	writeBinaryValueFile(makeCompressed(dir) + "Full-method.ccsloc.xz", result);
	writeCSV(result, makeCompressed(dir) + "method-cc-sloc.csv.xz");
	writeTextValueFile(dir+"Full-method-missing.txt", errors);
	println("Errors<size(errors)>");
	return 0;
}


loc makeCompressed(loc l)
	= l[scheme = "compressed+" + l.scheme]
when !startsWith(l.scheme, "compressed");

default loc makeCompressed(loc l)
	= l;


int countOverlappingLines(set[loc] offsets) {
	result = 0;
	map[int, set[loc]] endLines = toMap({<l.end.line, l> | l <- offsets, l.begin?});
	for (l <- offsets, l.begin?) {
			if (l.begin.line in endLines) {
				if ((endLines[l.begin.line] - l) != {}) {
					result += 1;	
				}
			}
	}
	return result;
}

int mainEverythingFile(loc dir = |cwd:///|) {
	dt = readBinaryValueFile(#lrel[str project, loc locs, str names,  int cc, int ccw, int sloc], makeCompressed(dir) + "Full-method.ccsloc.xz");
	slocs = toMapUnique(readCSV(#lrel[str,loc,int,int], makeCompressed(dir) + "file-slocs.csv.xz")<1,2>);
	slocsUnits = toMapUnique(readCSV(#lrel[str,loc,int,int], makeCompressed(dir) + "file-slocs.csv.xz")<1,3>);
	println("Joining");
	projectLookup = toMapUnique({<l.top, pr> | <pr, l,_, _,_,_> <- dt});
	dt2 = toMap([<l.top, <l, cc, ccw,sloc>> | <_,l, _, cc, ccw, sloc> <- dt]);
	println("Calculating results");
	lrel[str project, loc file, int cc, int ccw, int sloc, int unitCount, int slocUnits, int slocUnitAggregate] result =
		[<projectLookup[l], l, 
			(0 | it + cc | <_,cc,_,_> <- dt2[l]),
			(0 | it + ccw | <_,_,ccw,_> <- dt2[l]),
			(l in slocs) ? slocs[l] : 0,
			size(dt2[l]),
			(l in slocsUnits) ? slocsUnits[l] : 0,
			(0 | it + sloc | <_,_,_,sloc> <- dt2[l])
		 > |  l <- dt2, !shouldFilter(l)];
	println("Writing results");
	println(size(result));
	writeBinaryValueFile(makeCompressed(dir) + "Full-file.ccsloc.xz", result);
	writeCSV(result, makeCompressed(dir) + "file-cc-sloc.csv.xz");
	return 0;
}

int mainSLOC(loc dir=|cwd:///|) {
	set[loc] files = {l | /file(l) := crawl(dir), l.extension == "slocs"};
	int progress = 0;
	lrel[str project, int sloc] result1 =[];
	lrel[str project, loc file, int sloc, int slocUnits] result = [];
	result = result:for(f <- files) {
		slocs = readBinaryValueFile(#rel[loc, list[int]], f);
		ccs = readBinaryValueFile(#lrel[loc ml, int cc, int brokencc], f[extension="ccm3"]);
		map[loc l, set[int] linesInFunc] linesFunction = ();
		for (<l, _,_> <- ccs, l.begin?) {
			ltop = l.top;
			if (!(ltop in linesFunction)) {
				linesFunction[ltop] = {};
			}
			linesFunction[ltop] += {*[l.begin.line..l.end.line + 1]};
		}
		project = f[extension=""].file;
		int tot = 0;
		for (<fp,ll> <- slocs, !shouldFilter(fp)) {
			tot += size(ll);
			if (fp in linesFunction) {
				append result: <project, fp, size(ll), size({*ll} & linesFunction[fp])>;	
			}
			else {
				append result: <project, fp, size(ll), 0>;	
			}
		}
		result1 += <project, tot>;
		progress += 1;
		if (progress % 100 == 0) {
			println(round(100 * (toReal(progress) / size(files))));	
		}
	};
	writeCSV(result, makeCompressed(dir) + "file-slocs.csv.xz");
	writeCSV(result1, makeCompressed(dir) + "project-slocs.csv.xz");
	return 0;
}

int mainFileCount(loc dir = |cwd:///|) {
	set[loc] files = {l | /file(l) := crawl(dir), l.extension == "asts"};
	int progress = 0;
	int filesWithFunctions = 0;
	int otherFiles = 0;
	for (f <- files) {
	try {
		//println("Reading ast: <f>");
		asts = readBinaryValueFile(#list[Declaration], f);
		for (a <- asts) {
			switch (a) {
				case /initializer(_): filesWithFunctions += 1;
				case /method(_,_,_,_,_): filesWithFunctions += 1;
				case /constructor(_,_,_,_): filesWithFunctions += 1;
				default: otherFiles += 1;
			}
		}
		progress += 1;
		if (progress % 100 == 0) {
			println(round(100* (progress / toReal(size(files)))));
		}
		}
	catch RuntimeException e: {
		println("something failed with<f>");	
	}
	}
	println("Java files with methods: <filesWithFunctions>");
	println("Java files without methods: <otherFiles>");
	return 0;
}