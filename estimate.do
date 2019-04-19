clear
cd "~/Dropbox/research/gender_vote"
import delimited "data/cjps_replication_2018-04-25.csv"	

* Settings
encode province_riding_party, gen(unit_id)
encode date, gen(date_fe)
encode province, gen(province_fct)
gen date_id = date(date, "YMD")
xtset unit_id date_id
label variable woman "Woman"
label variable contention_lag "Distance from contention"
label variable party_province_date_vote_share "Party performance"
label variable incumbent_party "Incumbent"
label variable vote_share_lag "Vote share lag"

* Baseline models
eststo clear

quietly reg vote_share woman, robust
estadd local FE_PR "No"
estadd local FE_E "No"
est store m1

quietly reg vote_share woman i.date_fe, robust
estadd local FE_PR "No"
estadd local FE_E "Yes"
est store m2

quietly xtreg vote_share woman i.date_fe, fe robust
estadd local FE_PR "Yes"
estadd local FE_E "Yes"
est store m3

quietly reg vote_share woman vote_share_lag party_province_date_vote_share, robust
estadd local FE_PR "No"
estadd local FE_E "No"
est store m4

quietly reg vote_share woman vote_share_lag party_province_date_vote_share incumbent_party contention_lag, robust
estadd local FE_PR "No"
estadd local FE_E "No"
est store m5

esttab m1 m2 m3 m4 m5 ///
	    using "txt/fig/tab_main.tex" , replace booktabs ///
        drop(*date_fe) se pr2 b(1) se(1) stats(vce r2 r2_o FE_PR FE_E N, fmt(%9.2f) ) ///
        title(The gender gap in Canadian federal general elections. Ordinary Least Squares regression models with party vote share as dependent variable.\label{tab:simple}) ///
        nomtitles label nogap compress
*		substitute({table} {sidewaystable})

* Time interaction
quietly reg vote_share c.woman##c.year vote_share_lag party_province_date_vote_share, robust
quietly margins, dydx(woman) at(year = (1921(1)2015))
matrix K = r(table)'
mat2txt , matrix(K) saving(data/mfx_ols.csv) replace

* Time interaction -- Logit
quietly logit elected c.woman##c.year incumbent_party party_province_date_vote_share, robust
quietly margins, dydx(woman) at(year = (1921(1)2015))
matrix K = r(table)'
mat2txt , matrix(K) saving(data/mfx_logit.csv) replace

* Provinces
quietly reg vote_share c.woman#i.province_fct vote_share_lag party_province_date_vote_share, robust
matrix K = r(table)'
mat2txt , matrix(K) saving(data/provinces.csv) replace

eststo clear
eststo: quietly logit elected c.woman##c.year incumbent_party party_province_date_vote_share if year > 1920, robust
eststo: quietly reg elected c.woman##c.year incumbent_party party_province_date_vote_share if year > 1920, robust
esttab
quietly margins, dydx(woman) at(year = (1921(1)2015))
