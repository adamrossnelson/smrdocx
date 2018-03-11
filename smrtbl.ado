*! 2.0.0 Adam Ross Nelson 10mar2018 // Made ifable, inable, and byable.
*! 1.0.1 Adam Ross Nelson 20nov2017 // Merged smrfmn, smrcol, and smrtbl to same package.
*! 1.0.0 Adam Ross Nelson 01nov2017 // Original version
*! Original author : Adam Ross Nelson
*! Description     : Produces one- or two-way tables (through putdocx).
*! Maintained at   : https://github.com/adamrossnelson/smrput

capture program drop smrtbl
program smrtbl
	
	version 15
	syntax varlist(min=1 max=2) [if] [in] [, NUMLab]
	
	// Test for an active putdocx.
	capture putdocx describe
	if _rc {
		di as error "ERROR: No active docx."
		exit = 119
	}

	// Test that subsample with temp var touse is not empty.
	marksample touse
	quietly count if `touse'
	if `r(N)' == 0 {
		di as error "ERROR: No observations after if or in qualifier."
		error 2000
	}

	preserve
	qui keep if `touse'	
	local argcnt : word count `varlist'
	
	if "`numlab'" == "numlab" {
		numlabel, add
	}

	/* Produce a two way table */
	if `argcnt' == 2 {
		capture decode `1', gen(dec`1')
		if _rc {
			capture confirm numeric variable `1'
			if !_rc {
				di "tostring `1', gen(dec`1')"
				tostring `1', gen(dec`1')
			}
			else if _rc {
				gen dec`1' = `1'
			}
		}
		
		capture decode `2', gen(dec`2')
		if _rc {
			capture confirm numeric variable `2'
			if !_rc {
				tostring `2', gen(dec`2')
			}
			else if _rc {
				gen dec`2' = `2'
			}
		}
		
		tab dec`1' dec`2'
		local totrows = `r(r)' + 1
		local totcols = `r(c)' + 1
		if `totrows' > 55 | `totcols' > 20 {
			di as error "ERROR: smrtble supports a maximum of 55 rows and 20 columns."
			di as error "Reduce the number of categories before proceeding."
			exit = 452
		}
		local rowtitle: variable label `1'
		local coltitle: variable label `2'
		putdocx paragraph
		putdocx text ("Table title: ")
		putdocx text ("_`1'_`2'_table"), italic linebreak 
		putdocx text ("Row variable label: ")
		putdocx text ("`rowtitle'."), italic linebreak 
		putdocx text ("Column variable label: ")
		putdocx text ("`coltitle'."), italic
		putdocx table _`1'_`2'_table = (`totrows',`totcols')
		qui levelsof dec`1', local(row_names)
		qui levelsof dec`2', local(col_names)
		local count = 2
		qui foreach lev in `row_names' {
			putdocx table _`1'_`2'_table(`count',1) = ("`lev'")
			local ++count
		}
		local count = 2
		qui foreach lev in `col_names' {
			putdocx table _`1'_`2'_table(1,`count') = ("`lev'")
			local ++count
		}
		local rowstep = 2
		local colstep = 2
		qui foreach rlev in `row_names' {
			foreach clev in `col_names' {
				count if dec`1' == "`rlev'" & dec`2' == "`clev'"
				local curcnt = `r(N)'
				putdocx table _`1'_`2'_table(`rowstep',`colstep') = ("`curcnt'")
				local ++colstep
			}
			local colstep = 2
			local ++rowstep
		}
		di "smrtbl Two-way table production successful. Table named: _`1'_`2'_table"
	}
	/* Produce a one way table */
	else if `argcnt' == 1 {
		capture decode `1', gen(dec`1')
		if _rc {
			capture confirm numeric variable `1'
			if !_rc {
				tostring `1', gen(dec`1')
			}
			else if _rc {
				gen dec`1' = `1'
			}
		}
		tab dec`1'
		local rowtitle: variable label `1'
		putdocx paragraph
		putdocx text ("Table title: ")
		putdocx text ("_`1'_table"), italic linebreak 
		putdocx text ("Row variable label: ")
		putdocx text ("`rowtitle'."), italic
		local totrows = `r(r)' + 1
		if `totrows' > 55 {
			di in smcl as error "ERROR: smrtble supports a maximum of 55 rows and 20 columns. Reduce"
			di in smcl as error "the number of categories before proceeding."
			exit = 452
		}
		putdocx table _`1'_table = (`totrows',2)
		qui levelsof dec`1', local(row_names)
		local count = 2
		putdocx table _`1'_table(1,2) = ("Counts")
		qui foreach lev in `row_names' {
			putdocx table _`1'_table(`count',1) = ("`lev'")
			count if dec`1' == "`lev'"
			local curcnt = `r(N)'
			putdocx table _`1'_table(`count',2) = ("`curcnt'")
			local ++count
		}
		di "smrtbl One-way table production successful. Table named: _`1'_table"
	}

	restore

end
