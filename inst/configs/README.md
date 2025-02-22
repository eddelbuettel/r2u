
These are sample files. The package expects them in 

    tools::R_user_dir(packageName())
    
which on my Linux system amounts to 

     ~/.local/share/R/r2u/

There is now also a helper function `.createDefaultConfiguration()` which
dynamically builds the file `config.dcf`.
