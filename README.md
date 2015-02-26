This archive contains a [Rascal-MPL](http://www.rascal-mpl.org/) Eclipse project used to parse and calculate the metrics for the [Java corpus ![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.208213.svg)](https://doi.org/10.5281/zenodo.208213) and analyze the metrics from the Java and the [C corpus ![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.208215.svg)](https://doi.org/10.5281/zenodo.208215) for the JSEP paper. 

Next to it is the data of the CC and SLOC values for the Java and C corpora.

It contains the following files:

- `src\\gather\\ASTs.rsc`: The rascal script that gathers all ASTs using the m3 framework and stores it into a Rascal data file per project. 
- `src\\gather\\SLOCs.rsc`: The rascal script that tokenizes all files in the Corpus and stores which lines contain Java statements to count for SLOC. 
- `src\\metric\\SLOC.rsc`: The Java tokenized as discussed in Section III.B
- `src\\metric\\CC.rsc`: The Rascal code (depicted in Figure 1) which calculates CC.
- `src\\calculate\\CCs.rsc`: The rascal script that calculates the CC per method.
- `src\\analyse\\JSEP2015.rsc`: The calculations to combine the data used in the paper.
- `data-java\\method-cc-sloc.csv.gz` : Method level CC and SLOC metric values.
- `data-java\\file-cc-sloc.csv.gz` : File level aggregated CC and SLOC metric values.
- `data-c\\method-cc-sloc.csv.gz` : Function level CC and SLOC metric values.
- `data-c\\file-cc-sloc.csv.gz` : File level aggregated CC and SLOC metric values.
