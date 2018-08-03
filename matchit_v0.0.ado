clear mata
/*
2DO
-----------
- generate long weights while creating index
- add threshold
- initial_values functionality to improve code quality

*/

capture program drop matchit
program matchit
	version 12
	syntax varlist(min=2 max=2) using/ ///
			, IDUsing(name) TXTUsing(name) ///
			[SIMilmethod(string)] ///
			[Weights(string)] ///
			[OVERride] 

	tokenize `varlist'
	local idmaster `1'
	local txtmaster `2'
	
	tokenize `similmethod'
	local similfunc `1'
	local similarg `2'
	
	if ("`similarg'"=="") local similtxt "&`similfunc'()"
	else local similtxt "&`similfunc'(),`similarg'"
	
	di "`similtxt'" 
	
	confirm numeric variable `idmaster'
	isid(`idmaster')
	confirm string variable `txtmaster'
	confirm file `using'
	
	qui describe
	if (r(changed)>0 & "`override'"=="") {
		di " "
		di "(!) Your unsaved changes will be destroyed after running this procedure."
		di "    (note: use OVERRIDE option to bypass this warning)"
		exit
	}			
	preserve
	
	mata: IDM=st_data(.,"`idmaster'"); TXTM=st_sdata(.,"`txtmaster'")
	
	di "Loading USING file: `using'"
	use `using', clear
	confirm numeric variable `idusing'
    isid(`idusing')
	confirm string variable `txtusing'
	mata: IDU=st_data(.,"`idusing'"); TXTU=st_sdata(.,"`txtusing'")
	clear
	
	di "Indexing USING file. Method: `similfunc'"
	mata: INDEXU=index_array(IDU, TXTU,`similtxt')
	
	if ("`weights'"!="") {
	 di "Computing weights using: `weights'"
	 local weightstxt "&`weights'()" 
	 mata: W=index_weights(INDEXU, `weightstxt'); asarray_keys(W)
	 mata: LW=long_weights(IDU, TXTU, W, `similtxt')
	 mata: core_routine(IDM, TXTM, TXTU, INDEXU, W, LW, `similtxt')
	 }
	else {
	 di "No weights computed"
	 mata: LW=long_weights(IDM, TXTM, 0, `similtxt')
	 mata: core_routine(IDM, TXTM, TXTU, INDEXU, 0, LW, `similtxt')
	}
	qui compress
	restore, not 
	
end

capture mata: mata drop core_routine()
mata:
void function core_routine(colvector Masterid, colvector Mastertxt, colvector Usingtxt, IndexArray, W, Longweights, pointer(function) scalar token_func, | arg_token_func)
  {
	if (W==0) Weights=asarray_create(); else Weights=W
	
	asarray_notfound(Weights,1)
	
	real matrix ResultsNUM
	string matrix ResultsTXT 
	ResultsNUM=J(0,3,.)
	ResultsTXT=J(0,2,"")
	
	"Computing results"
	
	for (i=1; i<=rows(Masterid); i++)
	{
	 if (args()>=7) Curgrams=(*token_func)(Mastertxt[i,1], arg_token_func); else Curgrams=(*token_func)(Mastertxt[i,1])
	 Sumw=sqrt(asarray_sumw(Curgrams,Weights))
	 Numerator=asarray_index_intersect(Curgrams,IndexArray,Weights)
	 CurResults=calc_simil(Numerator, Sumw, Longweights)
	 for (loc=asarray_first(CurResults); loc!=NULL; loc=asarray_next(CurResults, loc))
	 {
	  ResultsNUM = ResultsNUM \ (Masterid[i,1], asarray_key(CurResults, loc), asarray_contents(CurResults, loc))
	  ResultsTXT = ResultsTXT \ (Mastertxt[i,1], Usingtxt[asarray_key(CurResults, loc),1])
	 }
	}
	"saving results"
	newvars=st_addvar(("int", "str244","double", "str244","double"),("masterid", "mastertext", "usingid", "usingtext", "similscore"))
	st_addobs(rows(ResultsNUM))
	st_store(.,("masterid", "usingid", "similscore"), ResultsNUM)
	st_sstore(.,("mastertext", "usingtext"), ResultsTXT)
	"Done!"
  }
end
 
capture mata: mata drop index_array()
mata: 
function index_array(colvector idvar, colvector textvar, pointer(function) scalar token_func, | arg_token_func)
 {
  T=asarray_create()
  R=asarray_create()
  
  for (i=1; i<=rows(idvar); i++) 
  {
   if (args()>=4) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
   
   for (loc=asarray_first(T); loc!=NULL; loc=asarray_next(T,loc))
   {
    if (asarray_contains(R, asarray_key(T,loc))==1)
	{
	 A=asarray(R, asarray_key(T,loc))\(idvar[i,1], asarray_contents(T, loc))
	 asarray(R, asarray_key(T,loc), A)
	}
	else 
	 asarray(R, asarray_key(T,loc), (idvar[i,1], asarray_contents(T, loc)))	 
   }
  }
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
function long_weights(colvector idvar, colvector textvar, W, pointer(function) scalar token_func, | arg_token_func)
 {
  if (W==0) Weights=asarray_create("string"); else Weights=W
  asarray_notfound(Weights,1)
  R=asarray_create("real")
  for (i=1; i<=rows(idvar); i++) 
  {
   if (args()>=5) T=(*token_func)(textvar[i,1], arg_token_func); else T=(*token_func)(textvar[i,1])
   Sumw=sqrt(asarray_sumw(T,Weights))
   asarray(R,idvar[i,1],Sumw)
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
	   asarray(Matched, A[j,1], (asarray(Matched, A[j,1]) + asarray(shortarray, shortkeys[i,1])*A[j,2]*asarray(weights,shortkeys[i,1])))
	  else
	   asarray(Matched, A[j,1],asarray(shortarray, shortkeys[i,1])*A[j,2]*asarray(weights,shortkeys[i,1]))
	}
   return (Matched)
  }
end  

capture mata: mata drop asarray_sumw()
mata:
  function asarray_sumw(shortarray, weights)
  { 
   asarray_notfound(weights,1)
   Sumw=0
   for (loc=asarray_first(shortarray); loc!=NULL; loc=asarray_next(shortarray,loc))
    Sumw = Sumw + (asarray_contents(shortarray,loc)^2) * asarray(weights,asarray_key(shortarray,loc))
   return (Sumw)
  }
end  

capture mata: mata drop calc_simil()
mata:
  function calc_simil(Matched, Shortmodw, Longmodw, |Threshold)
  {
   Threshold=0
   Simil=asarray_create("real")
   for (loc=asarray_first(Matched); loc!=NULL; loc=asarray_next(Matched,loc))
   {
    Similscore=sqrt(asarray_contents(Matched,loc)) / (Shortmodw * asarray(Longmodw, asarray_key(Matched,loc)))
	if (Similscore>Threshold) 
		asarray(Simil, asarray_key(Matched,loc),Similscore)
   }
    
   return (Simil)
  }
end
mata:
function token_array(string scalar parse_string)
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

mata:
function bigram_array(string scalar parse_string)
 {
   Tlen=strlen(parse_string)-1
    if (Tlen>1) 
	{
	 T=asarray_create()
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
	 T=parse_string
	 return (T)
	}
 }
end  

mata:
function ngram_array(string scalar parse_string, real scalar nsize)
 {
   Tlen=strlen(parse_string)-(nsize-1)
    if (Tlen>1) 
	{
	 T=asarray_create()
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
	 T=parse_string
	 return (T)
	}
 }
end

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

  
  