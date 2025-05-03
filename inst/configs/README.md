
These are sample files. The package expects them in 

    tools::R_user_dir(packageName())
    
which on my Linux system amounts to 

     ~/.local/share/R/r2u/

There is also a helper function `.createDefaultConfiguration()` which
dynamically builds the file `config.dcf`.

There is also a public repo https://github.com/eddelbuettel/r2u-config whose
files now take precedence.
