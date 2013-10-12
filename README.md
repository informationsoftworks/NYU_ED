NYU\_ED
======

Implementation of the [NYU ED Algorithm](http://wagner.nyu.edu/faculty/billings/nyued-background) in SQL


Instructions
------------

1. Use `ddl.sql` to create tables in your target database (methods vary,
   depending on database)

2. Import the `recode.csv`, `special.csv`, and `xacs.csv` data in to the
   respective tables created in step 1

3. Open the `nyu_ed_query.sql`, and modify line 27 to replace `my_source_data`
   with the name of the table containing the source data intended as input.

4. Execute the query. The resulting table will have the NYU ED scores attached.
   The query may be embeded anywhere in the database, instantiated as a view,
   or cast into a table with an `CREATE TABLE output as ...`.

Note: The lines in `nyu_ed_query.sql` containing `-- redundant, but helps with
performance` can be safely removed without changing the results of the query,
but resulted in a 5x performance increase in the PostgreSQL 9.1 implementation.


Validation
----------

The results were validated (to within 5e-11 for numeric fields) 
using [PostgreSQL](http://www.postgresql.org/)version 9.1 on x86\_64 hardware,
as compared to results from the "NYU ED Algorithm, ACCESS version 21.zip" 
(`md5sum c6cd04502cf64a8b596377320afad855`)  downloaded from
[http://wagner.nyu.edu/faculty/billings/nyued-download](http://wagner.nyu.edu/faculty/billings/nyued-download).

**Note:** The SAS version posted on the NYU website will produce slightly
different results from those produced by the MS/Access version (and, by
extension, this SQL version) in at least that:

* The xacs coefficients are truncated (not rounded) to 1e-2
* Does not include the patches to the '786%' and '789%' mappings


Contact
-------

* For information on the **NYU ED Algorithm** itself:
	* see [http://wagner.nyu.edu/faculty/billings/nyued-background](http://wagner.nyu.edu/faculty/billings/nyued-background)
	* or contact: John C. Billings (`john.billings` (at) `nyu.edu`)

* For information regarding the **MS/Access, SAS and SPSS** versions:
	* contact Tod Mijanovich (`tm11` (at) `nyu.edu`)

* For questions or patches on the **SQL** version:
	* contact Paul Wehr (`sf_nyu_ed` (at) `informationsoftworks.com`)

