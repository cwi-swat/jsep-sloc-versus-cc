module calculate::Names


import IO;
import String;
import util::FileSystem;
import Set;
import List;
import util::Math;
import ValueIO;
import Exception;
import lang::csv::IO;
import util::Benchmark;

import lang::java::m3::AST;

lrel[loc, str] findNames(list[Declaration] d) 
	= [<b@src, n> | /method(_,str n,_,_,b) := d]
	+ [<b@src, n> | /constructor(str n,_,_,b) := d]
	;
	
int main(loc dir = |cwd:///|, bool replace = false) {
	set[loc] files = {l | /file(l) := crawl(dir), l.extension == "asts"};
	int progress = 0;
	for (f <- files) {
	try {
		if(!replace && exists(f[extension="names"])) {
			progress += 1;
			continue;	
		}
		asts = readBinaryValueFile(#list[Declaration], f);
		//println("Locating method bodies");
		names = findNames(asts);
		writeBinaryValueFile(f[extension = "names"], names);
		progress += 1;
		if (progress % 100 == 0) {
			println(round(100* (progress / toReal(size(files)))));
		}
		}
	catch RuntimeException e: {
		println("something failed with<f>");	
	}
	}
	return 0;
}