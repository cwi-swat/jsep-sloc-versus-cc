module calculate::CCs


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
import metric::CC;

lrel[loc, Statement] findMethods(list[Declaration] d) 
	= [<b@src, b> | /initializer(b) := d]
	+ [<b@src, b> | /method(_,_,_,_,b) := d]
	+ [<b@src, b> | /constructor(_,_,_,b) := d]
	;
	
list[Declaration] unnestAnonymousClasses(list[Declaration] decls) {
	list[Declaration] result = [];
	decls = visit(decls) {
    		case newObject(_, _, _, Declaration cl): {
    			result += cl;
    			insert null();	
    		}
    		case newObject(_, _, Declaration cl): {
    			result += cl;
    			insert null();	
    		}
    		case declarationStatement(Declaration cl): {
    			if (cl is class) {
    				result += cl;
    				insert empty();	
    			}
    		}
	};
	return result + decls;
}

int main(loc dir = |cwd:///|, bool replace = false) {
	set[loc] files = {l | /file(l) := crawl(dir), l.extension == "asts"};
	int progress = 0;
	for (f <- files) {
	try {
		if(!replace && exists(f[extension="ccm3"])) {
			progress += 1;
			continue;	
		}
		//println("Reading ast: <f>");
		asts = unnestAnonymousClasses(readBinaryValueFile(#list[Declaration], f));
		//println("Locating method bodies");
		methods = findMethods(asts);
		//println("Methods found: <size(methods)>");
		//println("Calculating CC");
		methodsCC = [<src, cc, cc - calcInfix(b)> | <src, b> <- methods, int cc := calcCC(b)];
		//println("Done calculating, storing result");
		writeBinaryValueFile(f[extension = "ccm3"], methodsCC);
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