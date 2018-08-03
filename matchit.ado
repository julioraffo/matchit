/*
ver 0.2

2DO
-----------
- saving partial results to disk? (check after testing against large datasets)
- saving weights & index to disk

Coding style
-------------
ALLCAPS = Mata elements
	IDM = Vector of masterfile ids
	TXTM = Vector of masterfile txts
	IDU = Vector of usingfile ids
	TXTU = Vector of usingfile txts
    INDEXU = Array of Indexed Grams for usingfile
	WGTINDEX = Array of weights for Grams in INDEXU (i.e. usingfile)
	WGTU = Array of total module (weights) for strings in TXTU, keys match those from IDU.
	       (to be used when computing scores)
	RESNUM = Matrix[.,3] with resulting idmaster, idusing & score
	RESTXT = Matrix[.,2] with resulting txtmaster & txtusing
	THRESHOLD = scalar with similarity threshold

simf_* = similarity Gram pattern function (e.g. simf_bigram, simf_token)
         Takes a string (and optional arguments) and returns an array of Grams with their frequencies.

weight_* = weighting function (e.g. simf_bigram, simf_token)
           takes a frequency (real) returns the desired weight (real)

*_p = pointer to *
	similfunc_p = pointer to similarity Gram pattern mata function
	weightfunc_p = pointer to weighting mata function
	scorefunc_p = pointer to score computing function

*/

capture program drop matchit
program matchit
	version 12
	syntax varlist(min=2 max=2) using/ ///
			, IDUsing(name) TXTUsing(name) ///
			[SIMilmethod(string)] ///
			[Weights(string)] ///
			[Score(string)] ///
			[Threshold(real .5)] ///
			[OVERride]

	// setup //////////////////////////////////////
	// checks master vars
	tokenize `varlist'
	local idmaster `1'
	local txtmaster `2'
	confirm numeric variable `idmaster'
	confirm string variable `txtmaster'

	// checks using file (variables checked when using it)
	confirm file `using'

	// checks similarity function
	tokenize `similmethod'
	if ("`1'"!="") {
		local similfunc `1'
		macro shift
		local similargs `*'
	}
	else local similfunc "bigram"
	capture mata: similfunc_p=&simf_`similfunc'()
	if (_rc!=0) {
		di "`similfunc' not found as a similarity function. Check spelling."
		error _rc
	}
	if ("`similargs'"!="") {
		local args_plugin ",`similargs'"
		local testtxt "This is just a test"
		capture mata: TEST=(*similfunc_p)("`testtxt'"`args_plugin')
		if (_rc!=0) {
			di "There seems to be an error with the chosen optional argument(s): `similargs'"
			di "(note: break is recommended. Press any key to ignore this and continue ."
			set more on
			more
			set more off
		}
	}
	// checks weigths function
	if ("`weights'"!="") {
		capture mata: weightfunc_p=&weight_`weights'()
		if (_rc!=0) {
			di "`weights' not found as a weights function. Check spelling."
			error _rc
		}
	}
	// checks score function
	if ("`score'"=="") {
		local score "jaccard"
	}
	capture mata: scorefunc_p=&score_`score'()
	if (_rc!=0) {
		di "`score' not found as a score computing function. Check spelling."
		error _rc
	}
	// threshold
	capture mata: THRESHOLD=`threshold'
	if (_rc!=0) {
		di "`threshold' does not seem a valid threshold."
		error _rc
	}


	// checks if ok to wipe master dataset
	qui describe
	if (r(changed)>0 & "`override'"=="") {
		di " "
		di "(!) Unsaved changes will be destroyed after running matching procedure."
		di "    (note: use OVERRIDE option to bypass warning)"
		exit
	}
	// setup ends ///////////////

	// Loading data to mata
	preserve
	mata: IDM=st_data(.,"`idmaster'"); TXTM=st_sdata(.,"`txtmaster'")
	di "Loading USING file: `using'"
	use `using', clear
	confirm numeric variable `idusing'
    confirm string variable `txtusing'
	mata: IDU=st_data(.,"`idusing'"); TXTU=st_sdata(.,"`txtusing'")
	clear

	// Creating index for USING
	di "Indexing USING file. Method: `similfunc'"
	mata: INDEXU=index_array(IDU, TXTU,similfunc_p`args_plugin')

	// Defining Computing weights from USING index
	if ("`weights'"!="") {
	 di "Computing weights using: `weights'"
	 mata: WGTINDEX=index_weights(INDEXU, weightfunc_p)
	 }
	else {
	 di "No weights computed"
	 mata: WGTINDEX=asarray_create()
	}
	mata: asarray_notfound(WGTINDEX,1)
	di "Computing scale for USING file"
	mata: WGTU=long_weights(IDU, TXTU, WGTINDEX,similfunc_p`args_plugin')

	di "Computing results"
	mata: RESNUM=J(0,3,.); RESTXT=J(0,2,"")

	mata: core_computing(RESNUM,RESTXT,THRESHOLD,IDM,TXTM,IDU,TXTU,INDEXU,WGTU,WGTINDEX,scorefunc_p, similfunc_p`args_plugin')

	di "Saving results"
	// checks vars naming
	if ("`idmaster'"=="`idusing'"){
		di "Using idvar `idusing' renamed to u_`idusing'"
		local idusing "u_`idusing'"
	}
	if ("`txtmaster'"=="`txtusing'"){
		di "Using textvar `txtusing' renamed to u_`txtusing'"
		local txtusing "u_`txtusing'"
	}
	mata: newvars=st_addvar(("double", "str244","double", "str244","double"),("`idmaster'", "`txtmaster'", "`idusing'", "`txtusing'", "similscore"))
	mata: st_addobs(rows(RESNUM)); st_store(.,("`idmaster'","`idusing'","similscore"), RESNUM); st_sstore(.,("`txtmaster'", "`txtusing'"), RESTXT)
	di "Done!"
	qui compress
	restore, not
end

// computing scores
capture mata: mata drop core_computing()
mata:
void core_computing(resultsnum, resultstxt, Threshold,idvar, textvar, usingidvar, usingtextvar, indexarray, weightusing, weightarray, pointer(function) scalar score_func, pointer(function) scalar token_func, | arg_token_func)
{
		Qrows=rows(idvar); flag=0
		for (i=1; i<=Qrows; i++) {
		 if (args()>=13) Curgrams=(*token_func)(textvar[i,1], arg_token_func); else Curgrams=(*token_func)(textvar[i,1])
		 Sumw=asarray_sumw(Curgrams,weightarray)
		 Numerator=asarray_index_intersect(Curgrams,indexarray,weightarray)

		 CurResults=asarray_create("real")
		 for (loc=asarray_first(Numerator); loc!=NULL; loc=asarray_next(Numerator,loc)) {
		  Similscore=(*score_func)(asarray_contents(Numerator,loc), Sumw, asarray(weightusing, asarray_key(Numerator,loc)))
		  if (Similscore>=Threshold) asarray(CurResults, asarray_key(Numerator,loc),Similscore)
		 }

		 for (loc=asarray_first(CurResults); loc!=NULL; loc=asarray_next(CurResults, loc)) {
		  resultsnum = resultsnum \ (idvar[i,1], usingidvar[asarray_key(CurResults, loc),1], asarray_contents(CurResults, loc))
		  resultstxt = resultstxt \ (textvar[i,1], usingtextvar[asarray_key(CurResults, loc),1])
		 }
		counter=i*100/Qrows
		 if (counter>flag){
			stata(`"di ""'+strofreal(flag)+`"%..." _continue"');
			flag=flag+20
		   }
		}
		stata(`"di "100%."')
}
end

capture mata: mata drop index_array()
mata:
function index_array(colvector idvar, colvector textvar, pointer(function) scalar token_func, | arg_token_func)
 {
  R=asarray_create()
  Qrows=rows(idvar); flag=0
  for (i=1; i<=Qrows; i++)
  {
   counter=i*100/Qrows
   if (counter>flag)
   {
	stata(`"di ""'+strofreal(flag)+`"%..." _continue"');
	flag=flag+20
   }
   T=asarray_create()
   if (args()>=4) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
   for (loc=asarray_first(T); loc!=NULL; loc=asarray_next(T,loc))
   {
    /* Wrong??
	if (asarray_contains(R, asarray_key(T,loc))==1)
	{
	 A=asarray(R, asarray_key(T,loc))\(idvar[i,1], asarray_contents(T, loc))
	 asarray(R, asarray_key(T,loc), A)
	}
	else
	 asarray(R, asarray_key(T,loc), (idvar[i,1], asarray_contents(T, loc)))
	 */
	if (asarray_contains(R, asarray_key(T,loc))==1)
	{
	 A=asarray(R, asarray_key(T,loc))\(i, asarray_contents(T, loc))
	 asarray(R, asarray_key(T,loc), A)
	}
	else
	 asarray(R, asarray_key(T,loc), (i, asarray_contents(T, loc)))

   }
  }
  stata(`"di "100%."')
  return (R)
  }
  end

capture mata: mata drop index_weights()
mata:
function index_weights(longindex, pointer(function) scalar weight_func)
 {
  R=asarray_create()

  for (loc=asarray_first(longindex); loc!=NULL; loc=asarray_next(longindex,loc))
  {
	T=(*weight_func)(rows(asarray_contents(longindex,loc)))
	asarray(R,asarray_key(longindex,loc),T)
  }
  return (R)
  }
  end

capture mata: mata drop long_weights()
mata:
function long_weights(colvector idvar, colvector textvar, weights, pointer(function) scalar token_func, | arg_token_func)
 {
  R=asarray_create("real")
  for (i=1; i<=rows(idvar); i++)
  {
   if (args()>=5) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
   Sumw=asarray_sumw(T,weights)
   asarray(R,i,Sumw)
  }
  return (R)
  }
  end

capture mata: mata drop asarray_index_intersect()
mata:
  function asarray_index_intersect(shortarray, longindex, | weights)
  {
   if (weights==J(0, 0, .))
    weights=asarray_create("string")

   asarray_notfound(weights,1)
   Matched=asarray_create("real")
   shortkeys=asarray_keys(shortarray)
   for (i=1; i<=rows(shortkeys); i++)
    if (asarray_contains(longindex, shortkeys[i,1]))
	{
	 A=asarray(longindex, shortkeys[i,1])
	 for (j=1; j<=rows(A); j++)
	  if (asarray_contains(Matched, A[j,1]))
	   asarray(Matched, A[j,1], (asarray(Matched, A[j,1]) + asarray(shortarray, shortkeys[i,1])*A[j,2]*(asarray(weights,shortkeys[i,1])^2)))
	  else
	   asarray(Matched, A[j,1],asarray(shortarray, shortkeys[i,1])*A[j,2]*(asarray(weights,shortkeys[i,1])^2))
	}
   return (Matched)
  }
end


capture mata: mata drop asarray_sumw()
mata:
  function asarray_sumw(shortarray, weights)
  {
   Sumw=0
   for (loc=asarray_first(shortarray); loc!=NULL; loc=asarray_next(shortarray,loc))
    Sumw = Sumw + (asarray_contents(shortarray,loc) * asarray(weights,asarray_key(shortarray,loc))^2)
   return (Sumw)
  }
end



/*
// GRAM weighting functions

weight_* = weighting function (e.g. simf_bigram, simf_token)
           takes a frequency (real) returns the desired weight (real)
*/


capture mata: mata drop weight_simple()
mata:
function weight_simple(real scalar gramfreq)
 {
  return (1/gramfreq)
 }
  end

capture mata: mata drop weight_root()
mata:
function weight_root(real scalar gramfreq)
 {
  return (1/sqrt(gramfreq))
 }
  end

capture mata: mata drop weight_log()
mata:
function weight_log(real scalar gramfreq)
 {
  return (1/(log(gramfreq)+1))
 }
  end

// Similarity functions
// simf_* = similarity function (e.g. simf_bigram, simf_token)

capture mata: mata drop simf_token()
mata:
function simf_token(string scalar parse_string)
 {
   A=asarray_create()
   T=tokens(parse_string)
   for (i=1; i<=cols(T); i++)
   {
    if (asarray_contains(A, T[1,i])!=1)
		asarray(A, T[1,i], 1)
	else
		asarray(A, T[1,i], asarray(A, T[1,i])+1)
   }
   return (A)
 }
end

capture mata: mata drop simf_bigram()
mata:
function simf_bigram(string scalar parse_string)
 {
   T=asarray_create()
   Tlen=strlen(parse_string)-1
    if (Tlen>1)
	{
	 for (j=1; j<=Tlen; j++)
	 {
	  gram=substr(parse_string,j,2)
	  if (asarray_contains(T, gram)!=1)
		asarray(T, gram, 1)
	  else
		asarray(T, gram, asarray(T, gram)+1)
	 }
	 return(T)
	}
	else
	{
	 asarray(T, parse_string, 1)
	 return (T)
	}
 }
end

capture mata: mata drop simf_ngram()
mata:
function simf_ngram(string scalar parse_string, real scalar nsize)
 {
	T=asarray_create()
	Tlen=strlen(parse_string)-(nsize-1)
    if (Tlen>1)
	{
	 for (j=1; j<=Tlen; j++)
	 {
	  gram=substr(parse_string,j,nsize)
	  if (asarray_contains(T, gram)!=1)
		asarray(T, gram, 1)
	  else
		asarray(T, gram, asarray(T, gram)+1)
	 }
	 return(T)
	}
	else
	{
	 asarray(T, parse_string, 1)
	 return (T)
	}
 }
end

// Score functions
// score_* = functions to compute similarity score

capture mata: mata drop score_jaccard()
mata:
function score_jaccard(real scalar numerator, real scalar denom1, real scalar denom2)
 {
  denom=denom1*denom2
  if (denom<=0)
    return (0)
  else
    return (numerator/sqrt(denom))
 }
end

capture mata: mata drop score_simple()
mata:
function score_simple(real scalar numerator, real scalar denom1, real scalar denom2)
 {
  denom=denom1+denom2
  if (denom<=0)
    return (0)
  else
    return (2*numerator/denom)
 }
end
