module metric::SLOC

import IO;
import Exception;
import ParseTree;
import List;

layout Layout = LayoutElement* !>> [\u0009-\u000D \u0020 \u00A0 \u1680 \u180E \u2000-\u200A \u202F \u205F \u3000 \u000A \u000B-\u000D \u0085 \u2028 \u2029] !>> "/*" !>> "//";

lexical LayoutElement = Comment | Whitespace;

lexical Whitespace = [\u0009-\u000D \u0020 \u00A0 \u1680 \u180E \u2000-\u200A \u202F \u205F \u3000 \u000A \u000B-\u000D \u0085 \u2028 \u2029]+ !>> [\u0009-\u000D \u0020 \u00A0 \u1680 \u180E \u2000-\u200A \u202F \u205F \u3000 \u000A \u000B-\u000D \u0085 \u2028 \u2029];

lexical Comment 
	= "//" (![\r\n] || [\a00])* !>> (![\r\n] || [\a00])
	| "/*" ((![*] || [\a00])+!>> (![*]|| [\a00])| "*" !>> "/")* "*/"
	;

start syntax Lines = Statement*;

lexical Statement
	=  [\"] ((![\"\\]|| [\a00])+ !>> (![\"\\]|| [\a00]) | Escape)* [\"]
	|  [\'] (![\'\\] | Escape) [\']
	| NonStringNonComment
	;

lexical NonStringNonComment
	= ![\"\'/ \u0009-\u000D \u000B-\u000D \u0085 \u2028 \u2029]+ !>> ![\"\'/ \u0009-\u000D \u000B-\u000D \u0085 \u2028 \u2029]
	| "/" !>> [*/]
	;

lexical Escape
	= [\\][btnfr\"\'\\]
	| [\\][0-7] !>> [0-7]  
	| [\\][4-7][0-7]
	| [\\][0-3][0-7] !>> [0-7]
	| [\\][0-3][0-7][0-7] 
	| [\\][u]+[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]
	;
	

list[int] getSLOCLines(loc l) {
	bool subpart = l.length?;
	Tree t;
	try {
		if (subpart) 
			t = parse(#start[Lines], readFile(l));
		else
			t = parse(#start[Lines], l);
	}
	catch ParseError(e): {
		println("Caught <l>: <e> lets try a different charset");
		t = parse(#start[Lines], readFileEnc(l, "windows-1252"));	
	}
	if ((Lines)`<Statement* st>` := t.top) {
		return sort([ *{ s@\loc.begin.line | Statement s <- st}]);
	}
	println("Unexpected file <l>");
	return [];
}
