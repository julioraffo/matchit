*! 0.6 J.D. Raffo September 2014

/* 2DO
-----------
- orblock
- cite reclink

Coding style
-------------
ALLCAPS = Mata elements
	IDM = Vector of masterfile ids
	TXTM = Vector of masterfile txts
	IDU = Vector of usingfile ids
	TXTU = Vector of usingfile txts
    INDEXU = Array of Indexed Grams for usingfile
    INDEXM = Array of Indexed Grams for masterfile
	WGTINDEX = Array of weights for Grams in INDEXU (i.e. usingfile)
	WGTU = Array of total module (weights) for strings in TXTU, keys match those from IDU.
	WGTM = Array of total module (weights) for strings in TXTM, keys match those from IDM.
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
			[OVERride] ///
			[Generate(string)]

	// setup //////////////////////////////////////
	tokenize `varlist'
	local idmaster `1'
	local txtmaster `2'
	tokenize `similmethod'
	if ("`1'"!="") {
		local similfunc `1'
		macro shift
		local similargs `*'
	}
	else local similfunc "bigram"
	if ("`score'"=="") local score "jaccard"

	// checks master vars
	confirm numeric variable `idmaster'
	confirm string variable `txtmaster'
	confirm file "`using'"
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
	if ("`weights'"=="") local weights "noweights"
	if ("`weights'"!="noweights") {
		capture mata: weightfunc_p=&weight_`weights'()
		if (_rc!=0) {
			di "`weights' not found as a weights function. Check spelling."
			error _rc
		}
	}
	capture mata: scorefunc_p=&score_`score'()
	if (_rc!=0) {
		di "`score' not found as a score computing function. Check spelling."
		error _rc
	}
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
	use "`using'", clear
	confirm numeric variable `idusing'
    confirm string variable `txtusing'
	mata: IDU=st_data(.,"`idusing'"); TXTU=st_sdata(.,"`txtusing'")
	clear

	// Creating indexes
	di "Indexing USING file. Method: `similfunc'"
	mata: INDEXU=index_array(IDU, TXTU,similfunc_p`args_plugin')
	di "Indexing USING file. Method: `similfunc'"
	mata: INDEXM=index_array(IDM, TXTM,similfunc_p`args_plugin')

	// Computing index weights
	if ("`weights'"!="noweights") {
	 di "Computing weights using: `weights'"
	 mata: WGTINDEX=index_weights(INDEXU, INDEXM, weightfunc_p)
	}
	else {
	 di "No weights computed"
	 mata: WGTINDEX=asarray_create()
	}
	// intersection
	di "Intersecting indexes"
	mata: INDEXNUM=asarray_index_intersect(INDEXM,INDEXU,WGTINDEX)

	// Computing weights for intersection
	mata: asarray_notfound(WGTINDEX,1)
	di "Computing scales for USING file"
	mata: WGTU=array_weights(asarray_keys(INDEXNUM)[.,2], TXTU, WGTINDEX,similfunc_p`args_plugin')
	di "Computing scale for MASTER file"
	mata: WGTM=array_weights(asarray_keys(INDEXNUM)[.,1], TXTM, WGTINDEX,similfunc_p`args_plugin')


	di "Computing results"
	mata: RESNUM=J(0,3,.); RESTXT=J(0,2,"")
	mata: core_computing(RESNUM,RESTXT,THRESHOLD,IDM,TXTM,IDU,TXTU,INDEXNUM,WGTM,WGTU,scorefunc_p)

    di "Saving results"
	// checks vars naming
	if ("`generate'"=="") local similscore "similscore"
	else local similscore "`generate'"

	local i = 1
	local vartemp "`idusing'"
	while ("`idmaster'"=="`vartemp'" | "`txtmaster'"=="`vartemp'") {
	 local i = `i'+1
	 local vartemp "`idusing'_`i'"
	}
	local idusing "`vartemp'"
	local i = 1
	local vartemp "`txtusing'"
	while ("`txtmaster'"=="`vartemp'" | "`idmaster'"=="`vartemp'" | "`idusing'"=="`vartemp'" ) {
	 local i = `i'+1
	 local vartemp "`txtusing'_`i'"
	}
	local txtusing "`vartemp'"
	local i = 1
	local vartemp "`similscore'"
	while ("`txtmaster'"=="`vartemp'" | "`idmaster'"=="`vartemp'" | "`idusing'"=="`vartemp'" | "`txtusing'"=="`vartemp'") {
	 local i = `i'+1
	 local vartemp "`similscore'_`i'"
	}
	local similscore "`vartemp'"


	if ("`idmaster'"=="`idusing'" | "`txtmaster'"=="`idusing'"){
		di "Using idvar `idusing' renamed to u_`idusing'"
		local idusing "u_`idusing'"
	}
	if ("`txtmaster'"=="`txtusing'" | "`idmaster'"=="`txtusing'"){
		di "Using textvar `txtusing' renamed to u_`txtusing'"
		local txtusing "u_`txtusing'"
	}
	if ("`similscore'"=="`idusing'" |"`similscore'"=="`idusing'" | "`txtmaster'"=="`idusing'"){
		di "Using idvar `idusing' renamed to u_`idusing'"
		local idusing "u_`idusing'"
	}
	mata: newvars=st_addvar(("double","str244","double","str244","double"),("`idmaster'", "`txtmaster'", "`idusing'", "`txtusing'", "`similscore'"))
	mata: st_addobs(rows(RESNUM)); st_store(.,("`idmaster'","`idusing'","`similscore'"), RESNUM); st_sstore(.,("`txtmaster'", "`txtusing'"), RESTXT)
	di "Done!"
	qui compress
	restore, not
end

// computing scores
capture mata: mata drop core_computing()
mata:
void core_computing(resultsnum, resultstxt, Threshold, idvar, textvar, usingidvar, usingtextvar, intersectarray, weightmaster, weightusing, pointer(function) scalar score_func)
{
 NumeratorIndex=asarray_keys(intersectarray)
 Qrows=rows(NumeratorIndex); flag=0
 for (i=1; i<=Qrows; i++)
 {
  Similscore=(*score_func)(asarray(intersectarray, (NumeratorIndex[i,1],NumeratorIndex[i,2])),asarray(weightmaster, NumeratorIndex[i,1]),asarray(weightusing, NumeratorIndex[i,2]))
  if (Similscore>=Threshold)
  {
   resultsnum = resultsnum \ (idvar[NumeratorIndex[i,1],1], usingidvar[NumeratorIndex[i,2],1], Similscore)
   resultstxt = resultstxt \ (textvar[NumeratorIndex[i,1],1], usingtextvar[NumeratorIndex[i,2],1])
  }
  counter=i*100/Qrows
  if (counter>flag)
  {
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
function index_weights(longindex, shortindex, pointer(function) scalar weight_func)
 {
  R=asarray_create()

  for (loc=asarray_first(longindex); loc!=NULL; loc=asarray_next(longindex,loc))
   asarray(R,asarray_key(longindex,loc),rows(asarray_contents(longindex,loc)))

  for (loc=asarray_first(shortindex); loc!=NULL; loc=asarray_next(shortindex,loc))
   if (asarray_contains(R, asarray_key(shortindex,loc))==1)
    asarray(R,asarray_key(shortindex,loc), asarray(R, asarray_key(shortindex,loc))+rows(asarray_contents(shortindex,loc)))
   else
    asarray(R,asarray_key(shortindex,loc),rows(asarray_contents(shortindex,loc)))

  for (loc=asarray_first(R); loc!=NULL; loc=asarray_next(R,loc))
  {
	T=(*weight_func)(asarray_contents(R,loc))
	asarray(R,asarray_key(R,loc),T)
  }

  return (R)
  }
  end

capture mata: mata drop array_weights()
mata:
function array_weights(colvector rawidvar, colvector textvar, weights, pointer(function) scalar token_func, | arg_token_func)
 {
  R=asarray_create("real")
  Qrows=rows(rawidvar); flag=0
  for (i=1; i<=Qrows; i++)
  {
   if (asarray_contains(R,rawidvar[i])!=1)
   {
    if (args()>=5) T=(*token_func)(textvar[rawidvar[i],1], arg_token_func); else T=(*token_func)(textvar[rawidvar[i],1])
    Sumw=asarray_sumw(T,weights)
    asarray(R,rawidvar[i],Sumw)
   }
   counter=i*100/Qrows
   if (counter>flag)
   {
	stata(`"di ""'+strofreal(flag)+`"%..." _continue"');
	flag=flag+20
   }
  }
  stata(`"di "100%."')
  return (R)
  }
  end

capture mata: mata drop asarray_index_intersect()
mata:
  function asarray_index_intersect(shortindex, longindex, | weights)
  {
   Qrows=asarray_elements(shortindex); flag=0; c = 0
   if (weights==J(0, 0, .))
    weights=asarray_create("string")
   asarray_notfound(weights,1)
   Matched=asarray_create("real",2)

   for (loc=asarray_first(shortindex); loc!=NULL; loc=asarray_next(shortindex,loc))
   {
	shortkey=asarray_key(shortindex,loc)
	if (asarray_contains(longindex,shortkey)==1)
	{
	 A=asarray(shortindex,shortkey)
	 B=asarray(longindex,shortkey)
	 for (i=1; i<=rows(A); i++)
	  for (j=1; j<=rows(B); j++)
	  {
	   if (asarray_contains(Matched, (A[i,1],B[j,1])))
	    asarray(Matched, (A[i,1],B[j,1]), asarray(Matched, (A[i,1],B[j,1]))+(A[i,2]*B[j,2]*(asarray(weights,shortkey)^2)))
	   else
	    asarray(Matched, (A[i,1],B[j,1]), (A[i,2]*B[j,2]*(asarray(weights,shortkey)^2)))
	  }
	}
    c = c + 1
	counter=c*100/Qrows
    if (counter>flag)
	{
	 stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
	 flag=flag+20
    }
   }
   stata(`"di "100%."')
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
    if (asarray_contains(A, T[1,i])!=1) asarray(A, T[1,i], 1)
	else asarray(A, T[1,i], asarray(A, T[1,i])+1)
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
	  if (asarray_contains(T, gram)!=1) asarray(T, gram, 1)
	  else asarray(T, gram, asarray(T, gram)+1)
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
	  if (asarray_contains(T, gram)!=1) asarray(T, gram, 1)
	  else asarray(T, gram, asarray(T, gram)+1)
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

capture mata: mata drop simf_ngram_circ()
mata:
function simf_ngram_circ(string scalar parse_string, real scalar nsize)
 {
	T=asarray_create()
	Tlen=strlen(parse_string)-(nsize-1)
	if (Tlen>1)
	{
	 firstgram=substr(parse_string,1,nsize)
	 new_parse_string = parse_string+" "+firstgram
	 Tlen=Tlen+nsize+1

	 for (j=1; j<=Tlen; j++)
	 {
	  gram=substr(new_parse_string,j,nsize)
	  if (asarray_contains(T, gram)!=1) asarray(T, gram, 1)
	  else asarray(T, gram, asarray(T, gram)+1)
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

capture mata: mata drop simf_token_soundex()
mata:
function simf_token_soundex(string scalar parse_string)
 {
   A=asarray_create()
   T=soundex(tokens(parse_string))
   for (i=1; i<=cols(T); i++)
   {
	if (asarray_contains(A, T[1,i])!=1) asarray(A, T[1,i], 1)
	else asarray(A, T[1,i], asarray(A, T[1,i])+1)
   }
   return (A)
 }
end

capture mata: mata drop simf_soundex()
mata:
function simf_soundex(string scalar parse_string)
 {
   A=asarray_create()
   T=soundex(parse_string)
   asarray(A, T[1,1], 1)
   return (A)
 }
end


// Score functions
// score_* = functions to compute similarity score

capture mata: mata drop score_jaccard()
mata:
function score_jaccard(real scalar numerator, real scalar denom1, real scalar denom2)
 {
  denom=denom1*denom2
  if (denom<=0) return (0)
  else return (numerator/sqrt(denom))
 }
end

capture mata: mata drop score_simple()
mata:
function score_simple(real scalar numerator, real scalar denom1, real scalar denom2)
 {
  denom=denom1+denom2
  if (denom<=0) return (0)
  else return (2*numerator/denom)
 }
end

capture mata: mata drop score_minsimple()
mata:
function score_minsimple(real scalar numerator, real scalar denom1, real scalar denom2)
 {
  denom=denom1*denom2
  vecdenom = denom1, denom2
  if (denom<=0) return (0)
  else if (numerator>min(vecdenom)) return (1)
  else return (numerator/min(vecdenom))
 }
end
