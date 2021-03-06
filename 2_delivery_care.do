******************************
*** Delivery Care************* 
******************************
gen DHS_phase=substr(v000, 3, 1)
destring DHS_phase, replace

gen country_year="`name'"
gen year = regexs(1) if regexm(country_year, "([0-9][0-9][0-9][0-9])[\-]*[0-9]*[ a-zA-Z]*$")
destring year, replace
gen country = regexs(1) if regexm(country_year, "([a-zA-Z]+)")

rename *,lower   //make lables all lowercase. 
order *,sequential  //make sure variables are in order. 

    *sba_skill (not nailed down yet, need check the result)
	foreach var of varlist m3a-m3n {
	local lab: variable label `var' 
    replace `var' = . if ///
	!regexm("`lab'","doctor|nurse|midwife|aide soignante|assistante accoucheuse|clinical officer|mch aide|trained|auxiliary birth attendant|physician assistant|professional|ferdsher|skilled|community health care provider|birth attendant|hospital/health center worker|hew|auxiliary|icds|feldsher|mch|vhw|village health team|health personnel|gynecolog(ist|y)|obstetrician|internist|pediatrician|family welfare visitor|medical assistant|health assistant") ///
	|regexm("`lab'","na^|-na|traditional birth attendant|untrained|unquallified|empirical midwife")  
	replace `var' = . if !inlist(`var',0,1)
	 }
	/* do consider as skilled if contain words in 
	   the first group but don't contain any words in the second group */
    egen sba_skill = rowtotal(m3a-m3n),mi

	*c_hospdel: child born in hospital of births in last 2 years
	gen c_hospdel= ( inlist(m15,21 ,41) ) if   !mi(m15)        
	
	*c_facdel: child born in formal health facility of births in last 2 years
	gen c_facdel = ( !inlist(m15,11,12,46,96) ) if   !mi(m15)   
	
	*c_earlybreast: child breastfed within 1 hours of birth of births in last 2 years

	gen c_earlybreast = .
	
	replace c_earlybreast = 0 if m4 != .    //  based on Last born children who were ever breastfed
	replace c_earlybreast = 1 if inlist(m34,0,100)
	replace c_earlybreast = . if inlist(m34,199,299)
	
    *c_skin2skin: child placed on mother's bare skin immediately after birth of births in last 2 years
	capture confirm variable m77
	if _rc == 0{
	gen c_skin2skin = (m77 == 1) if    !mi(m77)               //though missing but still a place holder.(the code might change depends on how missing represented in surveys)
	}
	gen c_skin2skin = .
	
	*c_sba: Skilled birth attendance of births in last 2 years: go to report to verify how "skilled is defined"
	gen c_sba = . 
	replace c_sba = 1 if sba_skill>=1 
	replace c_sba = 0 if sba_skill==0 
	  
/* 	   * Chad2014 has different definition of sba (see report)
	if country_year == "Chad2014" {
	drop c_sba 
	gen c_sba = . 
	replace c_sba = 1 if (m3a ==1 | m3b ==1 | m3c ==1 | m3e ==1 | m3f ==1)
	replace c_sba = 0 if c_sba==. & ((DHS_phase>=6 & DHS_phase!=.) 
	replace c_sba = . if m3a ==. & m3b ==. & m3c ==. & m3e ==. & m3f ==. 
	}
					
	    * Tanzania2015 has different definition of sba (see report)
	if country_year == "Tanzania2015" {
	drop c_sba 
	gen c_sba = . 
	replace c_sba = 1 if (m3a ==1 | m3b ==1 | m3c ==1 | m3g ==1 | m3h ==1 | m3i ==1) 
	replace c_sba = 0 if c_sba==.  
	replace c_sba = . if m3a ==. & m3b ==. & m3c ==. & m3g ==. & m3h ==. & m3i ==. 
	}	
 
	    * Senegal2014 has different definition of sba (see report)
	if inlist(country_year,"Senegal2014","Senegal2015","Senegal2010","Senegal2012" ) {	
    drop c_sba 
	gen c_sba = . 
	replace c_sba = 1 if (m3a==1 | m3b==1 | m3c==1) 
	replace c_sba = 0 if c_sba==. 
	replace c_sba = . if m3a==. & m3b==. & m3c==.  
	}
	    * Cambodia2014 has different definition of sba (see report)
	if inlist(country_year, "Cambodia2014" ) {	
	replace c_sba = 1 if (m3a==1 | m3b==1 | m3c==1 | m3d==1 | m3e==1 | m3f==1) 
	replace c_sba = 0 if c_sba==. 
	replace c_sba = . if m3a==. & m3b==. & m3c==. & m3d==. & m3e==. & m3f==.
	} 
	
	    * Burkina Faso 2010 has different definition of sba (see report)
	if country_year == "BurkinaFaso2010" {	
	replace c_sba = 1 if (m3a==1 | m3b==1 | m3c==1 | m3d==1 | m3e==1 ) 
	replace c_sba = 0 if c_sba==. 
	replace c_sba = . if m3a==. & m3b==. & m3c==. & m3d==. & m3e==.
	}  */

	*c_sba_q: child placed on mother's bare skin and breastfeeding initiated immediately after birth among children with sba of births in last 2 years
	gen c_sba_q = (c_skin2skin == 1 & c_earlybreast == 1) if c_sba == 1
	replace c_sba_q = . if c_skin2skin == . | c_earlybreast == .
	
	*c_caesarean: Last birth in last 2 years delivered through caesarean                    
	clonevar c_caesarean = m17
	
    *c_sba_eff1: Effective delivery care (baby delivered in facility, by skilled provider, mother and child stay in facility for min. 24h, breastfeeding initiated in first 1h after birth)
	gen stay = (inrange(m61,124,198)|inrange(m61,201,298)|inrange(m61,301,398))
	replace stay = . if mi(m61) | inlist(m61,199,299,998)
	gen c_sba_eff1 = (c_facdel == 1 & c_sba == 1 & stay == 1 & c_earlybreast == 1) 
	replace c_sba_eff1 = . if c_facdel == . | c_sba == . | stay == . | c_earlybreast == . 
	
	*c_sba_eff1_q: Effective delivery care (baby delivered in facility, by skilled provider, mother and child stay in facility for min. 24h, breastfeeding initiated in first 1h after birth) among those with any SBA
	gen c_sba_eff1_q = (c_facdel==1 & c_sba == 1 & stay==1 & c_earlybreast == 1) if c_sba == 1	
	replace c_sba_eff1_q = . if c_facdel == . | c_sba == . | stay == . | c_earlybreast == . 
	
	*c_sba_eff2: Effective delivery care (baby delivered in facility, by skilled provider, mother and child stay in facility for min. 24h, breastfeeding initiated in first 1h after birth, skin2skin contact)
	gen c_sba_eff2 = (c_facdel == 1 & c_sba == 1 & stay == 1 & c_earlybreast == 1 & c_skin2skin == 1) 
	replace c_sba_eff2 = . if c_facdel == . | c_sba == . | stay == . | c_earlybreast == . | c_skin2skin == .
	
	*c_sba_eff2_q: Effective delivery care (baby delivered in facility, by skilled provider, mother and child stay in facility for min. 24h, breastfeeding initiated in first 1h after birth, skin2skin contact) among those with any SBA
	gen c_sba_eff2_q = (c_facdel == 1 & c_sba == 1 & stay == 1 & c_earlybreast == 1 & c_skin2skin == 1) if c_sba == 1	
	replace c_sba_eff2_q = . if c_facdel == . | c_sba == . | stay == . | c_earlybreast == . | c_skin2skin == .
	



	