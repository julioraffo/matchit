*! 0.8 J.D. Raffo March 2015
mata:
mata clear
end

capture program drop matchit
program matchit
 version 12
 syntax varlist(min=2 max=2) ///
  [using/] ///
   [, IDUsing(name) TXTUsing(name)] ///
   [SIMilmethod(string)] ///
   [Weights(string)] [WGTFile(string)] ///
   [Score(string)] ///
   [Threshold(real .5)] ///
   [OVERride] ///
   [Generate(string)]

 // setup //////////////////////////////////////
 if ("`using'"=="") {
  local match "columns"
  tokenize `varlist'
  local str1 `1'
  local str2 `2'
  di "matching columns `str1' and `str2'"
  confirm string variable `str1'
  confirm string variable `str2'
 }
 else {
  local match "index"
  tokenize `varlist'
  local idmaster `1'
  local txtmaster `2'
  di "Matching current dataset with `using'"
  confirm numeric variable `idmaster'
  confirm string variable `txtmaster'
  confirm file "`using'"

  // checks if ok to wipe master dataset
  qui describe
  if (r(changed)>0 & "`override'"=="") {
   di " "
   di "(!) Unsaved changes will be destroyed after running matching procedure."
   di "    (note: use OVERRIDE option to bypass warning)"
   exit
  }
  capture mata: THRESHOLD=`threshold'
  if (_rc!=0) {
   di "`threshold' does not seem a valid threshold."
   error _rc
  }
 }
 local wgtloaded=0
 if ("`weights'"=="") local weights "noweights"
 if ("`weights'"!="noweights") {
   capture mata: weightfunc_p=&weight_`weights'()
   if (_rc!=0) {
    di "`weights' not found as a weights function. Check spelling."
    error _rc
   }
   if ("`wgtfile'"!=""){
    confirm file "`wgtfile'"
	preserve
	use "`wgtfile'", clear
	mata: WFREQ=st_data(.,"freq"); WGRAM=st_sdata(.,"grams"); WGTARRAY=asarray_create()
	mata: load_weights_to_array(WGTARRAY, WGRAM, WFREQ)
	local wgtloaded=1
	restore
   }
 }
 //
 tokenize "`similmethod'" , parse(",")
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
  local args_plugin "`similargs'"
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
 if ("`score'"=="") local score "jaccard"
 capture mata: scorefunc_p=&score_`score'()
 if (_rc!=0) {
  di "`score' not found as a score computing function. Check spelling."
  error _rc
 }
  // setup ends ///////////////
 // matching columns
 if ("`match'"=="columns") {
  preserve
  if ("`generate'"=="") local similscore "similscore"
 else local similscore "`generate'"
 cap gen double `similscore'=.
  if (_rc!=0) {
   di "`similscore' does not seem a valid name for the score variable."
  error _rc
  }
  if ("`weights'"!="noweights") {
   if (`wgtloaded'==0){
    tempvar myvar
	gen `myvar'=1
	mata: WGTARRAY=asarray_create()
	freqindex `myvar' `str1', keepm incm(WGTARRAY) sim(`similmethod') nost
	freqindex `myvar' `str2', keepm incm(WGTARRAY) sim(`similmethod') nost
	drop `myvar'
   }
   mata: col_core_computing_wgt("`str1' `str2'","`similscore'",scorefunc_p, weightfunc_p, WGTARRAY, similfunc_p`args_plugin')
  }
  else {
   mata: col_core_computing("`str1' `str2'","`similscore'",scorefunc_p, similfunc_p`args_plugin')
  }
  restore, not
  exit
 }
 // Matching datasets
 // Loading data to mata
 preserve
 if ("`weights'"!="noweights" & `wgtloaded'==0){
   capture mata: WGTARRAY=asarray_create()
   freqindex `idmaster' `txtmaster', keepm incm(WGTARRAY) sim(`similmethod') nost
   mata: IDM=IDW; TXTM=TXTW
   mata: mata drop IDW TXTW
  }
 else {
  mata: IDM=st_data(.,"`idmaster'"); TXTM=st_sdata(.,"`txtmaster'")
 }
 di "Loading USING file: `using'"
 use "`using'", clear
 confirm numeric variable `idusing'
 confirm string variable `txtusing'
 if ("`weights'"!="noweights" & `wgtloaded'==0) {
  freqindex `idusing' `txtusing', keepm incm(WGTARRAY) sim(`similmethod') nost
  mata: IDU=IDW; TXTU=TXTW
  mata: mata drop IDW TXTW
 }
 else {
  mata: IDU=st_data(.,"`idusing'"); TXTU=st_sdata(.,"`txtusing'")
 }
 clear

// Creating index for USING
 di "Indexing USING file. Method: `similfunc'"
 mata: INDEXU=asarray_create()
 mata: WGTU=asarray_create("real")
 if ("`weights'"!="noweights") mata: index_array_wgt(INDEXU, IDU, TXTU, WGTU, weightfunc_p, WGTARRAY, similfunc_p`args_plugin')
 else mata: index_array(INDEXU, IDU, TXTU, WGTU, similfunc_p`args_plugin')

 di "Computing results"
 mata: RESNUM=J(0,3,.); RESTXT=J(0,2,"")
 if ("`weights'"!="noweights")  mata: core_computing_wgt(RESNUM,RESTXT,THRESHOLD,IDM,TXTM,IDU,TXTU,INDEXU,WGTU,WGTARRAY,scorefunc_p, weightfunc_p, similfunc_p`args_plugin')
 else  mata: core_computing(RESNUM,RESTXT,THRESHOLD,IDM,TXTM,IDU,TXTU,INDEXU,WGTU,scorefunc_p, similfunc_p`args_plugin')


 di "Saving results"
// checks vars naming
if ("`generate'"=="") local similscore "similscore"
 else local similscore "`generate'"

local i =1
local vartemp = "`idusing'"
while ("`vartemp'"=="`idmaster'"| "`vartemp'"=="`txtmaster'"){
 local vartemp "`idusing'`i'"
 local i = `i'+1
 }
local idusing = "`vartemp'"
local i =1
local vartemp = "`txtusing'"
while ("`vartemp'"=="`idmaster'"| "`vartemp'"=="`txtmaster'" | "`vartemp'"=="`idusing'"){
 local vartemp "`txtusing'`i'"
 local i = `i'+1
 }
local txtusing = "`vartemp'"
local i =1
local vartemp = "`similscore'"
while ("`vartemp'"=="`idmaster'"| "`vartemp'"=="`txtmaster'" | "`vartemp'"=="`idusing'" | "`similscore'"=="`txtusing'"  ){
 local vartemp "`similscore'`i'"
 local i = `i'+1
 }
local similscore = "`vartemp'"

 mata: newvars=st_addvar(("double", "str244","double", "str244","double"),("`idmaster'", "`txtmaster'", "`idusing'", "`txtusing'", "`similscore'"))
 mata: st_addobs(rows(RESNUM)); st_store(.,("`idmaster'","`idusing'","similscore"), RESNUM); st_sstore(.,("`txtmaster'", "`txtusing'"), RESTXT)
 di "Done!"
 qui compress
 restore, not
end

// computing scores columns
capture mata: mata drop col_core_computing_wgt()
mata:
void col_core_computing_wgt(string scalar textvars, string scalar scorevar, pointer(function) scalar score_func, pointer(function) scalar wgt_func, weightarray, pointer(function) scalar token_func, | arg_token_func)
{
 st_sview(TXT=.,.,textvars)
 st_view(RESNUM=.,.,scorevar)
 Qrows=rows(TXT); flag=0;
 for (i=1; i<=Qrows; i++)
 {
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
  T1=asarray_create()
  if (args()>=7) T1=(*token_func)(TXT[i,1], arg_token_func); else T1=(*token_func)(TXT[i,1])
  D1=asarray_sumw(T1, weightarray, wgt_func)
  T2=asarray_create()
  if (args()>=7) T2=(*token_func)(TXT[i,2], arg_token_func); else T2=(*token_func)(TXT[i,2])
  D2=asarray_sumw(T2, weightarray, wgt_func)
  Num=asarray_vecprod_wgt(T1,T2, weightarray, wgt_func)
  RESNUM[i,1]= (*score_func)(Num,D1,D2)
 }
 stata(`"di "100%."')
}
end

capture mata: mata drop col_core_computing()
mata:
void col_core_computing(string scalar textvars, string scalar scorevar, pointer(function) scalar score_func, pointer(function) scalar token_func, | arg_token_func)
{
 st_sview(TXT=.,.,textvars)
 st_view(RESNUM=.,.,scorevar)
 Qrows=rows(TXT); flag=0;
 for (i=1; i<=Qrows; i++)
 {
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
  T1=asarray_create()
  if (args()>=5) T1=(*token_func)(TXT[i,1], arg_token_func); else T1=(*token_func)(TXT[i,1])
  D1=asarray_sumsq(T1)
  T2=asarray_create()
  if (args()>=5) T2=(*token_func)(TXT[i,2], arg_token_func); else T2=(*token_func)(TXT[i,2])
  D2=asarray_sumsq(T2)
  Num=asarray_vecprod(T1,T2)
  RESNUM[i,1]= (*score_func)(Num,D1,D2)
 }
 stata(`"di "100%."')
}
end

capture mata: mata drop asarray_sumsq()
mata:
function asarray_sumsq(myarray)
{
 myscore=0
 for (loc=asarray_first(myarray); loc!=NULL; loc=asarray_next(myarray,loc)) myscore=myscore+asarray_contents(myarray,loc)^2
 return (myscore)
}
end

capture mata: mata drop asarray_sumw()
mata:
  function asarray_sumw(shortarray, weights, pointer(function) scalar wgt_func)
  {
   asarray_notfound(weights,1)
   Sumw=0
   for (loc=asarray_first(shortarray); loc!=NULL; loc=asarray_next(shortarray,loc))
   {
    A = asarray_contents(shortarray,loc) * ((*wgt_func)(asarray(weights,asarray_key(shortarray,loc))))
	Sumw = Sumw + A^2
   }
   return (Sumw)
  }
end

capture mata: mata drop asarray_vecprod_wgt()
mata:
function asarray_vecprod_wgt(myarray1, myarray2, weights, pointer(function) scalar wgt_func)
{
 curscore=0
 for (loc=asarray_first(myarray1); loc!=NULL; loc=asarray_next(myarray1,loc))
  {
   mykey=asarray_key(myarray1,loc)
   if (asarray_contains(myarray2,mykey)==1)
   {
    w = ((*wgt_func)(asarray(weights, mykey)))^2
	curscore = curscore + asarray(myarray1,mykey)*asarray(myarray2,mykey)*w
   }
  }
 return (curscore)
}
end

capture mata: mata drop asarray_vecprod()
mata:
function asarray_vecprod(myarray1, myarray2)
{
 curscore=0
 for (loc=asarray_first(myarray1); loc!=NULL; loc=asarray_next(myarray1,loc))
  {
   mykey=asarray_key(myarray1,loc)
   if (asarray_contains(myarray2,mykey)==1) curscore = curscore + asarray(myarray1,mykey)*asarray(myarray2,mykey)
  }
 return (curscore)
}
end


// computing scores index

capture mata: mata drop core_computing()
mata:
void core_computing(resultsnum, resultstxt, threshold, idvar, textvar, usingidvar, usingtextvar, indexarray, weightusing, pointer(function) scalar score_func, pointer(function) scalar token_func, | arg_token_func)
{
 Qrows=rows(idvar); flag=0
 for (i=1; i<=Qrows; i++)
 {
  if (args()>=12) Curgrams=(*token_func)(textvar[i,1], arg_token_func); else Curgrams=(*token_func)(textvar[i,1])
  Curdenom=asarray_sumsq(Curgrams)
  Numerator=asarray_index_intersect(Curgrams,indexarray)

  CurResults=asarray_create("real")
  for (loc=asarray_first(Numerator); loc!=NULL; loc=asarray_next(Numerator,loc))
  {
   Similscore=(*score_func)(asarray_contents(Numerator,loc), Curdenom, asarray(weightusing, asarray_key(Numerator,loc)))
   if (Similscore>=threshold) asarray(CurResults, asarray_key(Numerator,loc),Similscore)
  }
  for (loc=asarray_first(CurResults); loc!=NULL; loc=asarray_next(CurResults, loc))
  {
   resultsnum = resultsnum \ (idvar[i,1], usingidvar[asarray_key(CurResults, loc),1], asarray_contents(CurResults, loc))
   resultstxt = resultstxt \ (textvar[i,1], usingtextvar[asarray_key(CurResults, loc),1])
  }
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
 }
 stata(`"di "100%.""')
}
end

capture mata: mata drop core_computing_wgt()
mata:
void core_computing_wgt(resultsnum, resultstxt, Threshold, idvar, textvar, usingidvar, usingtextvar, indexarray, weightusing, weightarray, pointer(function) scalar score_func, pointer(function) scalar wgt_func, pointer(function) scalar token_func, | arg_token_func)
{
 Qrows=rows(idvar); flag=0
 for (i=1; i<=Qrows; i++)
 {
  if (args()>=14) Curgrams=(*token_func)(textvar[i,1], arg_token_func); else Curgrams=(*token_func)(textvar[i,1])
  Curdenom=asarray_sumw(Curgrams,weightarray, wgt_func)
  Numerator=asarray_index_intersect_wgt(Curgrams,indexarray,weightarray,wgt_func)
  CurResults=asarray_create("real")
  for (loc=asarray_first(Numerator); loc!=NULL; loc=asarray_next(Numerator,loc))
  {
   Similscore=(*score_func)(asarray_contents(Numerator,loc), Curdenom, asarray(weightusing, asarray_key(Numerator,loc)))
   if (Similscore>=Threshold) asarray(CurResults, asarray_key(Numerator,loc),Similscore)
  }
  for (loc=asarray_first(CurResults); loc!=NULL; loc=asarray_next(CurResults, loc))
  {
   resultsnum = resultsnum \ (idvar[i,1], usingidvar[asarray_key(CurResults, loc),1], asarray_contents(CurResults, loc))
   resultstxt = resultstxt \ (textvar[i,1], usingtextvar[asarray_key(CurResults, loc),1])
  }
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
 }
 stata(`"di "100%."')
}
end

capture mata: mata drop index_array()
mata:
void index_array(myindex, colvector idvar, colvector textvar, wgtusing, pointer(function) scalar token_func, | arg_token_func)
{
 Qrows=rows(idvar); flag=0;
 for (i=1; i<=Qrows; i++)
 {
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
  T=asarray_create()
  if (args()>=6) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
  array_to_index_vecadd(T, myindex, i)
  asarray(wgtusing,i,asarray_sumsq(T))
 }
 stata(`"di "100%."')
}
end

capture mata: mata drop array_to_index_vecadd()
mata:
void array_to_index_vecadd (myarray, myindex, mynum)
{
 for (loc=asarray_first(myarray); loc!=NULL; loc=asarray_next(myarray,loc))
 {
  if (asarray_contains(myindex, asarray_key(myarray,loc))==1)
  {
   A=asarray(myindex, asarray_key(myarray,loc))\(mynum, asarray_contents(myarray, loc))
   asarray(myindex, asarray_key(myarray,loc), A)
  }
  else
   asarray(myindex, asarray_key(myarray,loc), (mynum, asarray_contents(myarray, loc)))
 }
}
end

capture mata: mata drop index_array_wgt()
mata:
void index_array_wgt(myindex, colvector idvar, colvector textvar, wgtusing, pointer(function) scalar weight_func, weights, pointer(function) scalar token_func, | arg_token_func)
{
 Qrows=rows(idvar); flag=0;
 for (i=1; i<=Qrows; i++)
 {
  counter=i*100/Qrows
  if (counter>flag)
  {
   stata(`"di ""'+strofreal(flag)+`"%..." _continue"')
   flag=flag+20
  }
  T=asarray_create()
  if (args()>=8) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
  array_to_index_vecadd_wgt(T, myindex, i, wgtusing, weight_func, weights)
 }
 stata(`"di "100%."')
}
end

capture mata: mata drop array_to_index_vecadd_wgt()
mata:
void array_to_index_vecadd_wgt(myarray, myindex, mynum, wgtusing, pointer(function) scalar weight_func, weights)
{
 W=0
 for (loc=asarray_first(myarray); loc!=NULL; loc=asarray_next(myarray,loc))
 {
  curkey = asarray_key(myarray,loc)
  curvalue = asarray_contents(myarray, loc)
  if (asarray_contains(myindex, curkey)==1)
  {
   A=asarray(myindex, curkey)\(mynum, curvalue)
   asarray(myindex, curkey, A)
  }
  else
   asarray(myindex, curkey, (mynum, curvalue))

  W=W+(curvalue * ((*weight_func)(asarray(weights, curkey))))^2
 }
 asarray(wgtusing,mynum,W)
}
end

capture mata: mata drop asarray_index_intersect()
mata:
  function asarray_index_intersect(shortarray, longindex)
  {
   Matched=asarray_create("real")
   shortkeys=asarray_keys(shortarray)
   for (i=1; i<=rows(shortkeys); i++)
    curkey=shortkeys[i,1]
	if (asarray_contains(longindex, curkey))
	{
	 A=asarray(longindex, curkey)
	 for (j=1; j<=rows(A); j++)
	  if (asarray_contains(Matched, A[j,1]))
	   asarray(Matched, A[j,1], (asarray(Matched, A[j,1]) + asarray(shortarray, curkey)*A[j,2]))
	  else
	   asarray(Matched, A[j,1],asarray(shortarray, curkey)*A[j,2])
	}
   return (Matched)
  }
end

capture mata: mata drop asarray_index_intersect_wgt()
mata:
function asarray_index_intersect_wgt(shortarray, longindex, weights, pointer(function) scalar weight_func)
  {
   asarray_notfound(weights,1)
   Matched=asarray_create("real")
   shortkeys=asarray_keys(shortarray)
   for (i=1; i<=rows(shortkeys); i++)
   {
    curkey=shortkeys[i,1]
	if (asarray_contains(longindex, curkey))
	{
	 A=asarray(longindex, curkey)
	 for (j=1; j<=rows(A); j++)
	 {
	  curwgt=(*weight_func)(asarray(weights,curkey))
	  curnum = asarray(shortarray, curkey) * A[j,2] * (curwgt^2)
	  if (asarray_contains(Matched, A[j,1]))
	   asarray(Matched, A[j,1], (asarray(Matched, A[j,1]) + curnum))
	  else
	   asarray(Matched, A[j,1],curnum)
	 }
	}
   }
   return (Matched)
  }
end

// GRAM weighting functions
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


capture program drop freqindex
program freqindex
 version 12
 syntax varlist(min=2 max=2) ///
   [, SIMilmethod(string)] ///
   [INCMata(string)] ///
   [KEEPMata] [NOSTata]

// setup //////////////////////////////////////
 tokenize `varlist'
 local idvar `1'
 local txtvar `2'
 confirm numeric variable `idvar'
 confirm string variable `txtvar'
 if ("`incmata'"=="") {
  local incmata WGTARRAY
  mata: WGTARRAY=asarray_create(); P_WGTARRAY=&`incmata'
 }
 else {
  capture mata: P_WGTARRAY=&`incmata'
  if (_rc!=0) {
   di "`incmata' not found in MATA. Check spelling."
   error _rc
  }
 }
 if ("`keepmata'"=="") local clearmata=1
 else local clearmata=0

 tokenize "`similmethod'" , parse(",")
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
  local args_plugin "`similargs'"
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
 // programs starts
 preserve
 mata: IDW=st_data(.,"`idvar'"); TXTW=st_sdata(.,"`txtvar'")
 mata: *P_WGTARRAY = compute_freq(TXTW, *P_WGTARRAY, similfunc_p`args_plugin')
 if ("`nostata'"==""){
  clear
  mata: dump_wgtarray(*P_WGTARRAY)
 }
 if ("`keepmata'"=="") mata: mata drop `incmata' IDW TXTW P_WGTARRAY
 restore, not
end

capture mata: mata drop dump_wgtarray()
mata:
void dump_wgtarray(myarray)
{
 RESNUM=J(0,1,.)
 RESTXT=J(0,1,"")
 for (loc=asarray_first(myarray); loc!=NULL; loc=asarray_next(myarray,loc))
 {
  RESNUM = RESNUM \ asarray_contents(myarray, loc)
  RESTXT = RESTXT \ asarray_key(myarray, loc)
 }
 (void) st_addvar(("str244","int"),("grams", "freq"))
 st_addobs(rows(RESNUM))
 st_store(.,("freq"), RESNUM)
 st_sstore(.,("grams"), RESTXT)
}
end

capture mata: mata drop compute_freq()
mata:
function compute_freq(colvector textvar, freqindex, pointer(function) scalar token_func, | arg_token_func)
 {
  for (i=1; i<=rows(textvar); i++)
  {
   if (args()>=5) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
   array_to_index_sum(T, freqindex)
  }
 return (freqindex)
 }
end

capture mata: mata drop array_to_index_sum()
mata:
void array_to_index_sum (myarray, myindex)
{
 for (loc=asarray_first(myarray); loc!=NULL; loc=asarray_next(myarray,loc))
 {
  if (asarray_contains(myindex, asarray_key(myarray,loc))==1)
  {
   A=asarray(myindex, asarray_key(myarray,loc))+asarray_contents(myarray, loc)
   asarray(myindex, asarray_key(myarray,loc), A)
  }
  else
   asarray(myindex, asarray_key(myarray,loc), asarray_contents(myarray, loc))
 }
}
end


capture mata: mata drop load_weights_to_array()
mata:
void load_weights_to_array(myarray,mygram, myfreq )
{
 for (i=1; i<=rows(mygram); i++)
  asarray(myarray,mygram[i,1], myfreq[i,1])
}
end
