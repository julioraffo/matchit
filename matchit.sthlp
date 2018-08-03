{smcl}
{smcl}
{* *! version 1.0  sep2014}{...}
{vieweralsosee "[D] merge" "mansection D merge"}{...}
{vieweralsosee "[D] append" "help append"}{...}
{vieweralsosee "[D] joinby" "help joinby"}{...}
{viewerjumpto "Top" "matchit##Top"}{...}
{viewerjumpto "Syntax" "matchit##syntax"}{...}
{viewerjumpto "Description" "matchit##description"}{...}
{viewerjumpto "Options" "matchit##options"}{...}
{viewerjumpto "Examples" "matchit##examples"}{...}
{viewerjumpto "Remarks" "matchit##remarks"}{...}
{viewerjumpto "Tips" "matchit##tips"}{...}
{viewerjumpto "References" "matchit##references"}{...}
{marker Top}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :Matchit {hline 2}}Matches two datasets based on similar text patterns{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 5 15}
{cmd:matchit} {it:idmaster txtmaster}
{cmd:using} {it:{help filename}.dta} {cmd:,} {opth idu:sing(varname)} {opth txtu:sing(varname)} [{it:advanced_options}]

{marker reqopt}{...}
{synoptset 18 tabbed}{...}
{synoptline}
{syntab :{it:Required}}
{synopthdr}
{synoptline}
{synopt :{it:idmaster}}Numeric {varname} from current file ({it:masterfile}).
Needs not to uniquely identify observations from {it:masterfile} (although recommended).
{p_end}

{synopt :{it:txtmaster}}String {varname} from current file ({it:masterfile}) which will be matched to {it:txtusing}.
{p_end}

{synopt :{it:{help filename}}}Name (and path) of the Stata file to be matched ({it:usingfile}).
{p_end}

{synopt :{opth idu:sing(varname)}}Numeric {varname} from {it:usingfile}.
Needs not to uniquely identify observations from {it:usingfile} (although recommended).
{p_end}

{synopt :{opth txtu:sing(varname)}}String {varname} from {it:usingfile} which will be matched to {it:txtmaster}.
{p_end}
{synoptline}
{marker advopt}{...}
{synoptset 24 tabbed}{...}
{syntab :{it:Advanced}}
{synopthdr}
{synoptline}
{synopt :{opt sim:ilmethod(simfcn)}}
String matching method. Default is {it:bigram}. Other built-in {it:simfcn} are:
{it:ngram, ngram_circ, token, soundex} and {it:token_soundex}.
{p_end}

{synopt :{opt w:eights(wgtfcn)}}
Weighting transformation. Default is {it:noweights}. Built-in options are {it:simple, log} and {it:root}.
{p_end}

{synopt :{opt s:core(scrfcn)}}
Specifies similarity score. Default is {it:jaccard}. Other built-in options are {it:simple} and {it:minsimple}.
{p_end}

{synopt :{opt t:hreshold(num)}}
Similarity scores to be kept in final results. Default is {it:num} = .5
{p_end}

{synopt :{opt g:enerate(varname)}}
Specifies the name for the similarity score variable.
Default is {it:similscore}.
{p_end}

{synopt :{opt over:ride}}
Ignores unsaved data warning.
{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:matchit} is a tool to join observations from the dataset currently in memory (called the {it:master} dataset)
with those from {it:{help filename}}{it:.dta} (called the {it:using} dataset).
The special treat of {cmd:matchit} is that datasets are joined based on string variables
which do not necessarily need to be exactly the same.
In more precise terms, {cmd:matchit} can perform many different string-based matching techniques,
allowing for a {it:fuzzy} similarity between the two different text variables.
For more information on these techniques refer to Raffo & Lhuillery (2009).
{p_end}

{pstd}
As a result, {cmd:matchit} returns a new dataset containing five variables: two from the {it:master} dataset
({it:idmaster} and {it:txtmaster}), two from the {it:using} dataset ({it:idusing} and {it:txtusing})
and a new numeric variable containing the similarity score ({it:similscore}).
{it:similscore} ranges from 0 to 1, reflecting how similar {it:txtmaster} and {it:txtusing} are.
A {it:similscore} of 1 implies a perfect similarity according to the string matching technique chosen
and decreases when the match is less similar.
This also means that it is a relative measure which can (and often do) change depending on the technique chosen.
{p_end}

{pstd}
{cmd:matchit} is particularly useful in two cases:
(1) when the two datasets have different patterns for the same string data (e.g. individual or firm names, addresses, etc.); and,
(2) when one of the datasets is considerably large and it was {it:feeded} by different sources,
making it not uniformly formatted (e.g. names or addresses in different orders).
Joining data in cases like these may lead to several false negatives when using {help merge} or similar commands.
{p_end}

{pstd}
{cmd:matchit} is a convenient tool to overcome this kind of problems
without engaging into extensive data cleaning or correction efforts.
Take, for instance, a case like (1) where one dataset contains first and last names in separated fields,
while the other one has just a fullname field.
The use of {cmd:matchit} allows to join the two datasets by simply combining the two fields of the first dataset
without caring about the order of first and last names or about missing middle names.
Similarly, a typical example of (2) is a large dataset containing addresses entered as free-text by different people.
Using {cmd:matchit} you can join them with a more standardized source without caring
if the zip or state codes were added systematically or not.
{p_end}

{pstd}
Please, note that {cmd:matchit} is case-sensitive.
It also takes into account all other symbols.
While data cleaning is not needed for using {cmd:matchit},
it often implies an improvement of the similarity scores and,
in consequence, the overall quality of the matching exercise.
However, too much data cleaning might remove relevant information,
inducing a negative effect on quality due to false positives.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required Options}

{phang}
{opt idmaster}
is a numeric {varname} from the current file ({it:masterfile}) identifying its observations.
{cmd: matchit} will stop if it is not numeric.
It does not need to uniquely identify observations, although this is recommended.
A practical reason to avoid this suggestion is the case where there are alternative spellings for observations.

{phang}
{opt txtmaster}
is a string {varname} from the current file ({it:masterfile}) which will be matched to the string variable from the {it:usingfile} declared in {it:txtusing()}.
Duplicated values are allowed, although at the cost of losing some computational efficiency.

{phang}
{opt {help filename}.dta}
is the name (and path) of the Stata file to be matched ({it:usingfile}).

{phang}
{opth idu:sing(varname)}
declares the numeric {varname} from the {it:usingfile} identifying its observations.
It does not need to uniquely identify observations, although this is recommended.
A practical reason to avoid this suggestion is the case where there are alternative spellings for observations.

{phang}
{opth txtu:sing(varname)}
declares the string {varname} from the {it:usingfile} which will be matched to {it:txtmaster}.
Duplicated values are allowed, although at the cost of losing some computational efficiency.

{marker advoptions}{...}
{dlgtab:Advanced Options}

{phang}
{opt sim:ilmethod(simfcn)}
explicitly declares the method to parse {it:txtmaster} and {it:txtusing} into {it:Grams}.
Default is {it:bigram}. Other built-in {it:simfcn} are: {it:token, soundex} and {it:token_soundex}.
{p_end}

{phang}
{opt sim:ilmethod(simfcn,arg)}
is the alternative syntax when {it:simfcn} requires an argument.
This is the case of {it:ngram} and {it:ngram_circ},
which allows computing 1-gram, 2-gram, 3-gram, etc. by passing {it:n} as an argument.
For instance, {cmd:sim}({it:ngram,2}) is equivalent to {cmd: sim}({it:bigram}).
{p_end}

{phang}See an example for each built-in {it:simfcn} at the end of this help file. {p_end}

{phang}
{opt w:eights(wgtfcn)}
specifies an specific weighting transformation for {it:Grams}.
Default is no weights ({it:i.e.} each one weights 1).
Built-in options are {it:simple, log} and {it:root}.
Using weights is particularly recommended for large datasets where some {it:Grams} like {it:"Inc", "Jr", "Av"}
are frequently found, because if not they increase the false positive matches.

{phang}
{opt s:core(scrfcn)}
specifies the way to compute the similarity score.
Default is {it:jaccard}. Other builtin options are {it:simple} and {it:minsimple}.

{phang}
{opt t:hreshold(num)}
sets the limit of similarity score to keep in the final results.
Final results will have a score greater or equal to {it:num}.
Default is .5.
Note that: (1) this value relates to the chosen options for {it:similmethod}, {it:weights} and
{it:score};
 (2) even if 0 is specified, returned results are based on at least one matched term ({it:Gram}).

{phang}
{opt g:enerate(varname)}
Specifies the name for the similarity score variable.
Default is {it:similscore}.
Please note that {cmd: matchit} renames variables for the final dataset
if there is any conflict.

{phang}
{opt over:ride}
makes {cmd: matchit} ignore unsaved data warning. This is to be used with caution as {cmd:matchit} destroys the current data to return the matched combination of {it:masterfile} and {it:usingfile}.

{synoptline}

{marker examples}{...}
{title:Examples:}

{pstd}Simple syntax{p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:)}

{pstd}Setting matching method{p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) sim(token)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) sim(ngram,3)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) sim(ngram,1)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) sim(soundex)} {p_end}

{pstd}Setting weighting method{p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) w(simple)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) w(log)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) w(root)} {p_end}

{pstd}Setting score function{p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) s(simple)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) s(jaccard)} {p_end}
{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta} {bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:) s(minsimple)} {p_end}

{synoptline}

{marker remarks}{...}
{title:Remarks:}

{pstd}{bf:Notes on the different matching algorithms}{p_end}

{pstd}Matching algorithms can be categorized in three main families: Vectorial decomposition, Phonetic and Edit-distance algorithms.{p_end}

{pstd} {it:Vectorial decomposition algorithms} (such as N-Gram, Token, etc) basically compares the elements of two strings.
The N-gram algorithm decomposes the text string into elements of N characters ({it:grams}) using a moving-window
basis. As depicted as follows, a 3-gram decomposition of �Smith, John� and �Smit, John� have nine and eight 3-grams, respectively,
 but they share six of them: {p_end}

{phang2} {it: Smith, John} : {bf:�Smi� �mit�} {it:�ith� �th,� �h, �} {bf:�, J� � Jo� �Joh� �ohn�} {p_end}
{phang2} {it: Smit, John} : {bf:�Smi� �mit�} {it: �it,� �t, �} {bf:�, J� � Jo� �Joh� �ohn�}{p_end}

{pstd}Similarly,  a 3-gram decomposition of �John Smith� has eight 3-grams and shares five of them with �Smith, John�
({it:John Smith} : {bf:�Joh� �ohn�} {it:�hn � �n S� � Sm�} {bf:�Smi� �mit� �ith�}). This exemplifies how
{it:vectorial decomposition algorithms} are particularly suitable when facing permutation problems in the data. {p_end}

{pstd}However, {it:vectorial decomposition algorithms} do not need to have a moving-window strucutre. For instance,
the {it:token} algorithm splits a text string simply by its blank spaces.
In �John Smith� there are only two elements (or {it:grams}): �John� and �Smith�.
These match perfectly those {it:grams} from �Smith John�, but only one from either �Smith, John� or �Smit John�. {p_end}

{pstd} {it:Phonetic algorithms} (such as Soundex, Daitch-Mokotoff Soundex, NYSIIS, Double Metaphone, Caverphone, Phonix, Onca,
Fuzzy Soundex, etc) regroup by sound proximity the substrings ({it:phonemes}) of a given string.
For instance, the {it:soundex} algorithm converts both the strings �Smith, John� and �Smit, John� into �S532�,
but �Smith, Peter� into �S531�. {p_end}

{pstd} Finally, {it: Edit-distance algorithms} (such as Levenshtein, Damerau�Levenshtein, Bitap, Hamming, Boyer-Moore, etc)
are based on the simple precept that any text string can be transformed into another by applying a given number of plain operations.
Transforming �Smith, John� into �Smit, John� requires one deletion and the reciproque one insertion.
While transforming �Smith, John� into �Smith, Peter� requires nine operations (four deletions and five insertions). {p_end}

{pstd}As today, {cmd:matchit} performs {it:Vectorial decomposition} and {it:phonetic algorithms}
but does not perform {it:edit-distance} ones as they are not indexable.{p_end}

{pstd}Each algorithm has its own merits.
For example, phonetic based algorithms are more efficient at managing similar sounds based on misspellings.
The Edit distance algorithm family manages typing or spelling errors effectively.
The N-gram algorithms work effectively on misspellings as well as large string permutations.
Several rankings of matching algorithms are already available in the literature on name matching
(See Pfeifer et al., 1996; Zobel and Dart, 1995; Phua et al., 2007).
Even though a clear hierarchy is hard to achieve for several reasons,
Phonex or 2-gram are found to be better performers than 3-gram, 4-gram, or Damerau-Levenshtein algorithms
(Pfeifer et al., 1996; Phua et al., 2007; Christen, 2006).
According to the surveyed literature, hybrid matching algorithms have even better results
(e.g. Zobel and Dart, 1995; Pfeifer et al., 1996; Hodge and Austin, 2003; Phua et al., 2007).
{p_end}


{pstd}{bf:Notes on the different weighting options}{p_end}

{pstd}
The different algorithms can be customized to improve their performance.
For example, a weighting procedure can be added to the Edit transformations
or to the N-grams and Token vector elements in order to give more relevance to
less likely pieces of information in a text string.
In N-gram or Token algorithms, some {it:grams} - e.g. �street� or �road� - may provide less useful
information than rare ones simply because they are too common.
{p_end}

{pstd}
The typical approach is just to weight {it:grams} according to their inverse number of occurrences
in the data.
Hence, based on the frequency of each {it:gram} ({it:f}),
{cmd:matchit} can compute weights in the following ways:
{p_end}

{phang2}{it:simple = 1/f}{p_end}
{phang2}{it:root = 1/sqrt(f)}{p_end}
{phang2}{it:log = 1/log(f)}{p_end}

{pstd}
As aparent from the formulas, all these assign less importance to those more frequent {it:grams}.
The main difference is how fast they "punish" high frequencies,
where {it:simple} does it faster than {it:root}, which does it faster than {it:log}.
However, in practice, there are more differences between using or not weights
than among the three computation strategies.
Note that {cmd:matchit} computes the weights based on frequencies found
in both the {it:masterfile} and {it:usingfile}.
{p_end}


{pstd}{bf:Notes on the different scoring options}{p_end}

{pstd}
Text similarity is typically computed using variations of the Jaccard index, which basically means the intersection
between the two strings over the union of them.
Taking {it:m} as the amount of {it:grams} matched and {it:s1} and {it:s2} as the amount of {it:grams}
in the first and second string, respectively, {cmd:matchit} computes three scoring variations:
{p_end}

{phang2}{it:jaccard = m/sqrt(s1*s2)} {p_end}
{phang2}{it:simple = 2*m/(s1+s2)} {p_end}
{phang2}{it:minsimple = m/min(s1,s2)} {p_end}

{pstd}
All these should range between 0 and 1, reflecting none to perfect similarity
(always relative to the similarity function chosen).
As apparent from the formulas, all these are exactly the same if {it:s1} and {it:s2} are equal.
In simple terms, the major difference among these is how they treat the dissimilar part of the longer string.
{it:Jaccard} and {it:simple} basically take a geometric and arimethic mean, respectively;
while {it:minsimple} considers only the shorter string.
If one of the two sources has unuseful information in the string,
{it:minsimple} might be preferred at the expense of increasing the false positive results.
{p_end}

{pstd}
In the case of using any weighting option,
the previous formulas still hold but {it:m}, {it:s1} and {it:s2} are weighted
instead of just counts of {it:grams}.
{p_end}

{marker tips}{...}
{title:Some useful tips when using matchit:}

{phang}1) While {cmd:matchit} replicates the most standard use of {help merge} command
(i.e. intersection _merge = 3),
it does it less efficiently when there is no risk of false negatives. {p_end}

{phang}2) After using {cmd:matchit}, the resulting dataset can be easily merged with
either the {it:master} or {it:using} datasets using the {help merge} command.{p_end}

{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta}
{bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:)} {p_end}
{phang2}{cmd:. merge} {it:myidvar} {bf: using} {it:mymasterfile.dta} {p_end}
{phang2}{cmd:. merge} {it:usingidvar} {bf: using} {it:myusingfile.dta} {p_end}

{phang}3)It does not matter in substance which file
is used as {it:master} or {it:using} file.
It just matters in the order of the columns in the resulting dataset.
{p_end}

{phang}4)Observations in the resulting dataset are not sorted.
This can be easily done by making use of sorting commands such as
{cmd:sort} or {cmd:gsort} after running {cmd:matchit}.
Often, it is useful to sort the resulting dataset from the higher similarity score
to the lower one in order to establish the best threshold.
{p_end}

{phang2}{cmd:. matchit} {it:myidvar mytextvar} {bf: using} {it:myusingfile.dta}
{bf:, idu(}{it:usingidvar}{bf:) txtu(}{it:usingtextvar}{bf:)} {p_end}
{phang2}{cmd:. gsort} {bf:-}{it:similscore}{p_end}

{phang}5)You can customize {cmd:matchit} by adding your own similarity, weighting or scoring functions
and benefit from its indexing and other features.
All these are coded in Mata as functions with relatively simple structure and naming conventions, which are described as follows:
{p_end}

{phang2} {it:Similarity functions} just receive a string scalar, parses it into {it:grams} and return them in an associative array.
Optionally, you can have an argument passed to the custom function (like {it:simf_ngram} does),
which has to be passed after the string and it is used only within your function.
The naming convention is to have {it:simf_} before the name of your function.{p_end}

{phang2} {it:Weighting functions} just receive a numeric scalar with the {it:gram} frequency
and return a numeric scalar transformation of it.
The naming convention is to have {it:weight_} before the name of your function.{p_end}

{phang2} {it:Scoring functions} receive three numeric scalars and return a single numeric scalar transformation of them.
The three numeric scalars are passed in the following order:
First, the amount of {it:grams} matched;
second, the amount of {it:grams} from the string in the master file;
and, third, the amount of {it:grams} from the string in the using file.
The naming convention is to have {it:score_} before the name of your function.{p_end}


{marker references}{...}
{title:References}

{pstd}
Christen, P., 2006.
A comparison of personal name matching: techniques and practical issues.
Proceedings of the Workshop on Mining Complex Data (MCD).
IEEE International Conference on Data Mining (ICDM), Hong Kong, December.
{p_end}

{pstd}
Hodge, V.J., Austin, J., 2003.
A comparison of standard spell checking algorithms and a novel binary neural approach.
IEEE Transactions on Knowledge and Data Engineering 15 (5), 1073�1081.
{p_end}

{pstd}
Pfeifer, U., Poersch, T., Fuhr, N., 1996.
Retrieval effectiveness of proper name search methods.
Information Processing & Management 32 (6), 667�679.
{p_end}

{pstd}
Phua, C., Lee, V., Smith-Miles, K., 2007.
The personal name problem and a recommended data mining solution.
Encyclopedia of Data Warehousing and Mining, 2nd ed. IDEA Group Publishing.
{p_end}

{pstd}
Raffo, J., & Lhuillery, S. (2009).
How to play the �Names Game�: Patent retrieval comparing different heuristics.
Research Policy, 38(10), 1617�1627. doi:10.1016/j.respol.2009.08.001
{p_end}

{pstd}
Zobel, J., Dart, P., 1995.
Finding approximate matches in large lexicons.
Software�Practice and Experience 25 (3), 331�345.
{p_end}



{marker table_examples}{...}
{title:Examples for "John Smith":}
{asis}
----------------------------------------------------------------
#                          token_                  ngram_ ngram_
grams bigram token soundex soundex ngram,1 ngram,3 circ,2 circ,3
----------------------------------------------------------------
 1    Jo     John  J525    J500    J       Joh     Jo     Joh
 2    oh     Smith         S530    o       ohn     oh     ohn
 3    hn                           h       hn_     hn     hn_
 4    n_                           n       n_S     n_     n_S
 5    _S                           _       _Sm     _S     _Sm
 6    Sm                           S       Smi     Sm     Smi
 7    mi                           m       mit     mi     mit
 8    it                           i       ith     it     ith
 9    th                           t               th     th_
10                                 h               h_     h_J
11                                                 _J     _Jo
----------------------------------------------------------------
Notes: "_" = a blank space.
       ngram, 2 is equivalent to bigram.
