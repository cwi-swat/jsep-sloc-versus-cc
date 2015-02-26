module analyse::GenerateSLRPage

import lang::csv::IO;
import List;
import Set;
import IO;

alias DataRow = tuple[int occurance, str title, str link, str pdfLink, str fulltextLink, str abstract, str source, int cites, int year];

bool rowLessThen(DataRow a, DataRow b) {
	if (a.cites == b.cites) {
		return a.title > b.title;
	}
	return a.cites > b.cites;
}

void main(loc csvFile = |compressed+file:///Users/davy/PhD/papers/sloc-versus-cc/systematic-literature-review/results/queries-joined-filtered.csv.xz|, int limit = -1) {
	dt = readCSV(#list[DataRow], csvFile);
	if (limit <= 0) {
		limit = dt[-1].occurance;
	}
	titleUsage = toMap({<dt[i].title, i> | i <- [0..size(dt)]});
	str hasDup(str title, int i) {
		links = titleUsage[title];
		if (size(links) > 1 && min(links) < i) {
			return "\<br\>\<strong\>Possible\</strong\> duplicate of: <sort([l +1 | l <- (links - i)])>";
		}
		return "";
	}
	//dt = sort(dt, rowLessThen);
	targetFile = csvFile[scheme = replace(csvFile.scheme, "compressed+", "")];
	
	writeFile(targetFile[file = targetFile[extension=""][extension=""].file + "<limit>"][extension = "html"], 
		"\<!html\>\<head\>\<meta charset=\"utf-8\"\>\</head\>\<body\>\<ol\>\n
		'<for (i <- [0..size(dt)], DataRow d := dt[i], d.occurance <= limit ) {>
			'\<li\>\<a href=\"<d.link>\"\><d.title>\</a\>(<d.cites>, #<d.occurance>)\<br\><d.source>
			'<hasDup(d.title, i)>
			'<if (d.pdfLink != "") {>
				'\<br\>&nbsp;&nbsp;- \<a href=\"<d.pdfLink>\"\>Free PDF: <d.pdfLink>\</a\>
			'<}>
			'\<br\>&nbsp;&nbsp;- \<a href=\"<d.fulltextLink>\"\>Full text: <d.fulltextLink>\</a\>
		'<}>
		'\</ol\>\</body\>\</html\>"
	);
}
