module gather::SLRResults

import lang::csv::IO;
import String;
import IO;
import List;

alias InputData = lrel[str title, str link, str pdfLink, str fulltextLink, str abstract, str source, str cites];
alias OutputData = lrel[int occurance, str title, str link, str pdfLink, str fulltextLink, str abstract, str source, str cites, int year];

void main(loc resultsDir = |file:///Users/davy/PhD/papers/sloc-versus-cc/systematic-literature-review/results/|) {
	queries = [ readCSV(#InputData, f) | f <- resultsDir.ls, f.extension == "csv", startsWith(f.file, "query-")];
	set[str] seen = {};
	OutputData result = [];
	result = result: for (i <- [0..max([size(q) | q <- queries])]) {
		for (q <- queries) {
			if (i < size(q)) {
				d = q[i];
				key = d.link + d.title;
				if (!(key in seen)) {
					seen += key;
					if (/^[0-9]*$/ !:= d.cites) {
						d.cites = "0";
					}
					int year = 0;
					if (/<y:(19|20)[0-9][0-9]>/ := d.source) {
						year= toInt(y);
					}
					tuple[int occurance] ti = <i + 1>;
					tuple[int year] yy = <year>;
					append result: ti + d + yy;
				}
			}
		}	
	}
	writeCSV(result, resultsDir[scheme = "compressed+" + resultsDir.scheme] + "queries-joined-filtered.csv.xz");
	
}