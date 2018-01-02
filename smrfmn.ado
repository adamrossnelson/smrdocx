*! X.X.1 Adam Ross Nelson 01jan2018 // Added error checing for desc optoin.....
*! X.X.1 Adam Ross Nelson 20nov2017 // Merged smrfmn, smrcol, and smrtbl to same package.
*! X.X.X Adam Ross Nelson 19nov2017 // Original version
*! Original author : Adam Ross Nelson
*! Description     : Produces table of means filtered by list of indicators (through putdocx).
*! Maintained at   : https://github.com/adamrossnelson/smrput

capture program drop smrfmn
program smrfmn
	
	version 15
	local opts [, DESCription(string asis)]
	syntax anything(id="arglist") `opts'

	capture putdocx describe
	if _rc {
		di in smcl as error "ERROR: No active docx."
		exit = 119
	}
	qui sum `1'
	if _rc {
		di in smcl as error "ERROR: First argument must be numeric variable."
		exit = 452
	}
	
	local argcnt : word count `anything'
	
	if `argcnt' < 2 {
		di in smcl as error "ERROR: Argumnets incorrectly specified (too few)."
		di in smcl as error "Must specify one variable to summarize in addition to at least one indicator."
		exit = 102
	}

	forvalues cntr = 2/`argcnt' {
		local cntr = subinstr("``cntr''",",","",.)
		qui sum `cntr'
		capture assert `cntr' == 1 | `cntr' == 0 | `cntr' == .
		if _rc {
			di in smcl as error "ERROR: Inidcator variables must be numberic & binary."
			exit = 452
		}
	}
	
	preserve
	putdocx paragraph
	putdocx text ("Table title: ")
	putdocx text ("filtered_means_of_`1'_table"), italic linebreak
	putdocx text ("Description: ")
	if "`description'" == "" {
		local description = "smrfmn generated _`1'_tbl"
	}
	putdocx text (`description')
	local totrows = `argcnt'
	putdocx table filt_means_`1'_tbl = (`totrows',6)
	putdocx table filt_means_`1'_tbl(1,2) = ("Ind = 1"), halign(center)
	putdocx table filt_means_`1'_tbl(1,3) = ("Mean, Median, S.D."), halign(center)
	putdocx table filt_means_`1'_tbl(1,4) = ("25pctl, 75pctl"), halign(center)
	putdocx table filt_means_`1'_tbl(1,5) = ("Trimmed Mean, Median, S.D."), halign(center)
	putdocx table filt_means_`1'_tbl(1,6) = ("Min, Max"), halign(center)
	local cntrow = 2
	forvalues cntr = 2/`argcnt' {
		local cntr = subinstr("``cntr''",",","",.)
		local vardesc: variable label `cntr'
		// Handle variables with empty variable label.  If no label, provide generic.
		if "`vardesc'" == "" {
			local vardesc = "Varname: `cntr'"
		}
		qui {
			putdocx table filt_means_`1'_tbl(`cntrow',1) = ("`vardesc'"), halign(center)
			count if `cntr' == 1
			putdocx table filt_means_`1'_tbl(`cntrow',2) = (`r(N)'), halign(center)
			sum `1' if `cntr' == 1, detail
			putdocx table filt_means_`1'_tbl(`cntrow',3) = ( ///
			string(r(mean),"%-10.2f") +  ///
			string(r(p50),"%-10.2f") + ///
			string(r(sd),"%-10.2f")), halign(center)
			putdocx table filt_means_`1'_tbl(`cntrow',4) = ( ///
			string(r(p25),"%-10.2f") + ///
			string(r(p75),"%-10.2f")), halign(center)
			sum `1' if `cntr' == 1 & (`1' >= r(p25) & `1' <= r(p75)), detail
			putdocx table filt_means_`1'_tbl(`cntrow',5) = ( ///
			string(r(mean),"%-10.2f") + ///
			string(r(p50),"%-10.2f") + ///
			string(r(sd),"%-10.2f")), halign(center)
			sum `1' if `cntr' == 1
			putdocx table filt_means_`1'_tbl(`cntrow',6) = ( ///
			string(r(min),"%-10.2f") + ///
			string(r(max),"%-10.2f")), halign(center)
			local cntrow = `cntrow' + 1
		}
	}
	
	restore
	
	di "smrfmn Table production successful. Table named: filtered_means_of_`1'_table"

end

