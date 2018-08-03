{smcl}
{smcl}
{* *! version 1.0  9jul2014}{...}
{vieweralsosee "[D] merge" "mansection D merge"}{...}
{vieweralsosee "[D] append" "help append"}{...}
{vieweralsosee "[D] joinby" "help joinby"}{...}
{viewerjumpto "Top" "matchit##Top"}{...}
{viewerjumpto "Syntax" "matchit##syntax"}{...}
{viewerjumpto "Description" "matchit##description"}{...}
{viewerjumpto "References" "matchit##references"}{...}
{viewerjumpto "Options" "matchit##options"}{...}
{viewerjumpto "Examples" "matchit##examples"}{...}
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
{synopt :{it:idmaster}}Numeric {varname} from current file ({it:masterfile}). Needs not to uniquely identify observations from {it:masterfile}.
{p_end}

{synopt :{it:txtmaster}}String {varname} from current file ({it:masterfile}) which will be matched to {it:txtusing}.
{p_end}

{synopt :{it:{help filename}}}Name (and path) of the Stata file to be matched ({it:usingfile}).
{p_end}

{synopt :{opth idu:sing(varname)}}Numeric {varname} from {it:usingfile}. Needs not to uniquely identify observations from {it:usingfile}.
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
String matching method. Default is {it:bigram}. Other built-in {it:simfcn} are: {it:token, soundex} and {it:ngram}.
{p_end}

{synopt :{opt w:eights(wgtfcn)}}
Weighting transformation. Default is no weights. Built-in options are {it:simple, log} and {it:root}.
{p_end}

{synopt :{opt s:core(scrfcn)}}
Specifies similarity score. Default is {it:jaccard}. Other built-in option are {it:simple} and {it:minsimple}.
{p_end}

{synopt :{opt t:hreshold(num)}}
Similarity scores to be kept in final results. Default is .5.
{p_end}

{synopt :{opt over:ride}}
Ignores unsaved data warning.
{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:matchit} joins corresponding observations from the dataset currently in memory (called the master dataset) with those from
{it:{help filename}}{cmd:.dta}
(called the using dataset), matching them on one string variable from each dataset which do not need to be exactly the same. In more precise terms,
{cmd:matchit} can perform different string-based matching techniques, allowing for {it:fuzzy} similarity between the two different texts.
For more information on these refer to Raffo & Lhuillery (2009).

{pstd}
{cmd:matchit} is particularly useful in two cases. First, when the two datasets have different patterns for the same string data (e.g. individual or firm names, addresses, etc.). The second case concerns large datasets which are feeded by
different sources, making it not uniformly formatted (e.g. names or addresses in different orders). Matching data in these two cases may lead to several false negatives when using {help merge} or similar commands.

{pstd}
{cmd:matchit} is a useful tool to overcome these two cases without engaging into extensive data cleaning or correction efforts. For instance, one dataset contains first names and surnames in separated fields while the other one has a fullname
field.
The combined fields of the first one can be matched against the second one. Similarly, addresses as free-text fields in a large dataset can be matched without major correction.
While {cmd:matchit} replicates the most standard use of {help merge} command, it will do it less efficiently when there is no risk of false negatives.

{pstd}
{cmd:matchit} creates a new dataset containing five variables: two from the master dataset ({it:idmaster} and {it:txtmaster}), two from the using dataset ({it:idusing} and {it:txtusing}) and a new variable containing the similarity score
({it:similscore}).

{pstd}
{cmd:matchit} is case-sensitive.

{marker references}{...}
{title:References}

{pstd}
Raffo, J., & Lhuillery, S. (2009). How to play the �Names Game�: Patent retrieval comparing different heuristics. Research Policy, 38(10), 1617�1627. doi:10.1016/j.respol.2009.08.001


{marker options}{...}
{title:Options}

{dlgtab:Required Options}

{phang}
{opt idmaster}
is a numeric {varname} from the current file ({it:masterfile}), which identifies observations from it.
{cmd: matchit} will stop if it is not numeric.
It does not need to uniquely identify observations, although this is recommended.
A practical reason to avoid this suggestion is the case where there are alternative spellings for observations.
{cmd: matchit} will produce similarity scores for each line of your {it:masterfile}.

{phang}
{opt txtmaster}
is a string {varname} from the current file ({it:masterfile}) which will be matched to the string variable from the {it:usingfile} declared in {it:txtusing()}.
Duplicated values are allowed, although at the cost of losing some computing efficiency.

{phang}
{opt {help filename}.dta}
is the name (and path) of the Stata file to be matched ({it:usingfile}).

{phang}
{opth idu:sing(varname)}
declares the numeric {varname} from the {it:usingfile} which identifies its observations.
{cmd: matchit} will stop if it does not.
It does not need to uniquely identify observations, although this is recommended.
A practical reason to avoid this suggestion is the case where there are alternative spellings for observations.
{cmd: matchit} will produce similarity scores for each line of your {it:usingfile}.

{phang}
{opth txtu:sing(varname)}
declares the string {varname} from the {it:usingfile} which will be matched to {it:txtmaster}.
Duplicated values are allowed, although at the cost of losing some computing efficiency.

{marker advoptions}{...}
{dlgtab:Advanced Options}

{phang}
{opt sim:ilmethod(simfcn)}
explicitly declares the method to parse {it:txtmaster} and {it:txtusing} into {it:Grams}. Default is {it:bigram}. Other built-in {it:simfcn} are: {it:token, soundex} and {it:ngram}.
You can also customize it by adding your own parsing functions, benefiting from the indexing and other features from {cmd: matchit}.

{phang}
{opt sim:ilmethod(simfcn,arg)}
is the alternative syntax when {it:simfcn} requires an argument. This is the case of {it:ngram}, which allows computing 1-gram, 2-gram, 3-gram, etc. by passing {it:n} as an argument. For instance, {cmd:sim}({it:ngram,2})
is equivalent to
{cmd: sim}({it:bigram}).
You can also use this syntax when passing one or more arguments to your custom
{it:simfcn}.

{phang}
{opt w:eights(wgtfcn)}
specifies an specific weighting transformation for {it:Grams}. Default is no weights ({it:i.e.} each one weights 1). Built-in options are {it:simple, log} and {it:root}. This is particularly recommended for large datasets where some terms
({it:Grams}) are
frequently found ({it:e.g. "Inc", "Jr", "Av"},...etc.)
increasing the false positive matches. You can also customize it by adding your own weighting function, benefiting from the indexing and other features from {cmd: matchit}.

{phang}
{opt s:core(scrfcn)}
specifies the way to compute the similarity score. Default is {it:jaccard}. Other builtin option is {it:simple}. You can also customize it by adding your own scoring function, benefiting from the indexing and other features from {cmd: matchit}.

{phang}
{opt t:hreshold(num)}
sets the limit of similarity score to keep in the final results. Final results will have a score greater or equal to {it:num}. Default is .5. Note that: (1) this value relates to the chosen options for {it:similmethod}, {it:weights} and
{it:score};
 (2) even if 0 is specified, returned results are based on at least one matched term ({it:Gram}).

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
