
******************************
***Postnatal Care************* 
****************************** 

    *c_pnc_skill: m52,m72 by var label text. (m52 is added in Recode VI.
	gen m52_skill = 0 if !inlist(m50,0,1) 
	gen m72_skill = 0 if !inlist(m70,0,1) 
	
	foreach var of varlist m52 m72 {
    decode `var', gen(`var'_lab)
	replace `var'_lab = lower(`var'_lab )
	replace  `var'_skill= 1 if ///
	(regexm(`var'_lab,"doctor|nurse|midwife|aide soignante|assistante accoucheuse|clinical officer|mch aide|trained|auxiliary birth attendant|physician assistant|professional|ferdsher|skilled|community health care provider|birth attendant|hospital/health center worker|hew|auxiliary|icds|feldsher|mch|vhw|village health team|health personnel|gynecolog(ist|y)|obstetrician|internist|pediatrician|family welfare visitor|medical assistant|health assistant") ///
	|!regexm(`var'_lab,"na^|-na|traditional birth attendant|untrained|unquallified|empirical midwife")) 
	replace `var'_skill = . if mi(`var') | `var' == 99
	}
	/* consider as skilled if contain words in 
	   the first group but don't contain any words in the second group */
	
	
	*c_pnc_any : mother OR child receive PNC in first six weeks by skilled health worker
    gen c_pnc_any = 0 if !mi(m70) & !mi(m50) 
    replace c_pnc_any = 1 if (m71 <= 306 & m72_skill == 1 ) | (m51 <= 306 & m52_skill == 1)
    replace c_pnc_any = . if inlist(m71,199,299,399,998)| inlist(m51,998)| m72_skill == . | m52_skill == .

	
	*c_pnc_eff: mother AND child in first 24h by skilled health worker	
	gen c_pnc_eff = .
	replace c_pnc_eff = 0 if m51 != . | m52_skill != . | m71 != . | m72_skill != .   
    replace c_pnc_eff = 1 if ((inrange(m51,100,124) | m51 == 201 ) & m52_skill == 1) & ((inrange(m71,100,124) | m71 == 201) & m72_skill == 1 )
    replace c_pnc_eff = . if inlist(m51,199,299,399,998) | m52_skill == . | inlist(m71,199,299,399,998) | m72_skill == . 
                     
    /*     
	replace c_pnc_eff = 0 if m62 != . | m66 != . | m70 != . | m74 != .   //m64 doesn't exist in Recodee VI 
    replace c_pnc_eff = 1 if (((inrange(m63,100,124) | m63 == 201 ) & inrange(m64,11,13)) | ((inrange(m67,100,124) | m67 == 201) & inrange(m68,11,13))) & (((inrange(m71,100,124) | m71 == 201) & inrange(m72,11,13)) | ((inrange(m75,100,124) | m75 == 201) & inrange(m76,11,13)))
    replace c_pnc_eff = . if inlist(m63,199,299,399,998) | inlist(m67,199,299,399,998) | inlist(m71,199,299,399,998) | inlist(m75,199,299,399,998) | m62 == 8 | m66 == 8 | m70 == 8 | m74 == 8
    */
	
	*c_pnc_eff_q: mother AND child in first 24h by skilled health worker among those with any PNC
	gen c_pnc_eff_q = c_pnc_eff
	replace c_pnc_eff_q = . if c_pnc_any == 0
	replace c_pnc_eff_q = . if c_pnc_any == . | c_pnc_eff == .
	
	*c_pnc_eff2: mother AND child in first 24h by skilled health worker and cord check, temperature check and breastfeeding counselling within first two days	
	gen c_pnc_eff2 = . 
	
	capture confirm variable m78a m78b m78d                            //m78* only available for Recode VII
	if _rc == 0 {
	egen check = rowtotal(m78a m78b m78d),mi
	replace c_pnc_eff2 = c_pnc_eff
	replace c_pnc_eff2 = 0 if check != 3
	replace c_pnc_eff2 = . if c_pnc_eff == . 
	}
	
	*c_pnc_eff2_q: mother AND child in first 24h weeks by skilled health worker and cord check, temperature check and breastfeeding counselling within first two days among those with any PNC
	gen c_pnc_eff2_q = c_pnc_eff2
	replace c_pnc_eff2_q = . if c_pnc_any == 0
	replace c_pnc_eff2_q = . if c_pnc_any == . | c_pnc_eff2 == .					  


