# matchit

Stata ADO that matches two columns or two datasets based on similar text patterns

## Syntax

  Data in two columns in the same dataset

     matchit varname1 varname2 [, options]


  Data in two different datasets (with indexation)

     matchit idmaster txtmaster using filename.dta , idusing(varname) txtusing(varname) [options]

## Options

### similmethod(simfcn)  

String matching method. Default is bigram. 
Other typical built-in simfcn are:ngram, ngram_circ, token, soundex and token_soundex.

### score(scrfcn)

Specifies similarity score. Default is jaccard. 
Other built-in options are simple and minsimple.

### weights(wgtfcn)

Weighting transformation. Default is noweights. 
Other built-in options are simple, log and root.

### generate(varname)    

Specifies the name for the similarity score variable.  Default is similscore.

## Required options 

### Two datasets setup:

#### idmaster

Numeric varname from current file (masterfile).  
Needs not to uniquely identify observations from masterfile (although recommended).

#### txtmaster           
String varname from current file (masterfile) which will be matched to txtusing.

#### using filename      
Name (and path) of the Stata file to be matched (usingfile).

#### idusing(varname)    
Numeric varname from usingfile.  
Needs not to uniquely identify observations from usingfile (although recommended).

#### txtusing(varname)   
String varname from usingfile which will be matched to txtmaster.

## Advanced options

### wgtfile(filename)    
Allows loading weights from a Stata file, instead of computing it from the
current dataset (and using dataset, in the case of two-dataset setup).
Default is not to load weights.

### time                 
Outputs time stamps during the execution.  To be used for benchmarking
purposes.

### flag(step)           
Controls how often matchit reports back to the output screen.  
Only really useful for optimizing indexation by trying different simfcn.  
Default is step = 20 (percent).

## Advanced options only for two datasets syntax:

### threshold(num)       
Lowest similarity scores to be kept in final results.  Default is num = .5.

### override
Ignores unsaved data warning.

### diagnose
Reports a preliminary analysis about indexation.  
To be used for optimizing indexation by cleaning original data and trying different simfcn.

### stopwordsauto
Generates list of stopwords automatically.  
It improves indexation speed but ignores potential matches.

### swthreshold(grams-per-observation)
Only valid with stopwordsauto.  
It sets the threshold of grams per observation to be included in the stopwords list.  
Default is grams-per-observation = .2.

# Description

    matchit provides a similarity score between two different text strings by performing many different
    string-based matching techniques.  It returns a new numeric variable (similscore) containing the
    similarity score, which ranges from 0 to 1.  A similscore of 1 implies a perfect similarity according
    to the string matching technique chosen and decreases when the match is less similar.  similscore is
    a relative measure which can (and often do) change depending on the technique chosen.  For more
    information on these techniques refer to Raffo & Lhuillery (2009).

    These two variables can be from the same dataset or from two different ones.  This latter option
    makes matchit a convenient tool to join observations when the string variables are not necessarily
    exactly the same.  In other terms, it allows for the dataset currently in memory (called the master
    dataset) to be matched with filename.dta (called the using dataset) by means of a fuzzy similarity
    between string variables of each dataset.  In this case, matchit returns a new dataset containing
    five variables: two from the master dataset (idmaster and txtmaster), two from the using dataset
    (idusing and txtusing) and the already mentioned similarity score (similscore).

    matchit is particularly useful in two cases:  (1) when the two columns/datasets have different
    patterns for the same string data (e.g. individual or firm names, addresses, etc.); and, (2) when one
    of the datasets is considerably large and it was feeded by different sources, making it not uniformly
    formatted (e.g. names or addresses in different orders).  Joining data in cases like these may lead
    to several false negatives when using merge or similar commands.

    matchit is intended for overcoming this kind of problems without engaging into extensive data
    cleaning or correction efforts.  Take, for instance, a case like (1) where one dataset contains first
    and last names in separated fields, while the other one has just a fullname field.  The use of
    matchit allows to join the two datasets by simply combining the two fields of the first dataset
    without caring about the order of first and last names or about missing middle names.  Similarly, a
    typical example of (2) is a large dataset containing addresses entered as free-text by different
    people.  Using matchit you can join them with a more standardized source without caring if the zip or
    state codes were added systematically or not.

    Please, note that matchit is case-sensitive.  It also takes into account all other symbols (as far as
    Stata does).  While data cleaning is not needed for using matchit, it often implies an improvement of
    the similarity scores and, in consequence, the overall quality of the matching exercise.  However,
    too much data cleaning might remove relevant information, inducing a negative effect on quality due
    to false positives.

    matchit requires freqindex to be installed when computing weights.
