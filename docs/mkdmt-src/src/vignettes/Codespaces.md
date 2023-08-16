
## r2u for Codespaces

The [`.devcontainer` directory](https://github.com/eddelbuettel/r2u/tree/master/.devcontainer) provides a small self-containted file `devcontainer.json` to
launch an executable environment R using r2u. It is based on the example in
[Grant McDermott's
codespaces-r2u](https://github.com/grantmcdermott/codespaces-r2u) repo and
reuses its documentation. It is driven by the [Rocker Project's Devcontainer
Features](https://rocker-project.org/images/devcontainer/features.html) repo
creating a fully functioning R environment for cloud use in a few minutes.
And thanks to [r2u][r2u] you can add easily to this environment by installing
new R packages in a fast and failsafe way.

### Try it out

To get started, simply click on the green "Code" button at the top right. Then
select the "Codespaces" tab and click the "+" symbol to start a new Codespace.

<img src="https://eddelbuettel.github.io/r2u/assets/codespaces.png" width="90%">

The first time you do this, it will open up a new browser tab where your Codespace
is being instantiated. This *first-time instantiation will take a few minutes*
(feel free to click "View logs" to see how things are progressing) so please be patient. 
Once built, your Codespace will deploy almost immediately when you use it again in the future.

<img src="https://eddelbuettel.github.io/r2u/assets/instantiate.png" width="90%">

After the VS Code editor opens up in your browser, feel free to open up the
[`examples/sfExample.R`](https://github.com/eddelbuettel/r2u/tree/master/.devcontainer/examples/sfExamples.R) file. It demonstrates how
[r2u][r2u] enables us install packages _and their system-dependencies_ with
ease, here installing packages [sf][sf] (including all its geospatial
dependencies) and [ggplot2][ggplot2] (including all its dependencies). You
can run the code easily in the browser environment: Highlight or hover over
line(s) and execute them by hitting `Cmd`+`Return` (Mac) / `Ctrl`+`Return`
(Linux / Windows).

<img src="https://eddelbuettel.github.io/r2u/assets/sfExample.png" width="90%">

Do not forget to close your Codespace once you have finished using it. Click
the "Codespaces" tab at the very bottom left of your code editor / browser
and select "Close Current Codespace" in the resulting pop-up box. You can
restart it at any time, for example by going to https://github.com/codespaces
and clicking on your instance. 

### Extend r2u with r-universe

[r2u][r2u] offers _"fast, easy, reliable"_ access to all of CRAN via binaries
for Ubuntu focal and jammy.  When using the latter (as is the default), it
can be combined with [r-universe][r-universe] and its Ubuntu jammy binaries.
We demontrates this in a second example file
[`examples/censusExample.R`](https://github.com/eddelbuettel/r2u/tree/master/.devcontainer/examples/censusExample.R)
which install both the
[cellxgene-census](https://github.com/chanzuckerberg/cellxgene-census) and
[tiledbsoma](https://github.com/single-cell-data/TileDB-SOMA) R packages as
binaries from [r-universe][r-universe] (along with about 100 dependencies),
downloads single-cell data from Census and uses
[Seurat](https://github.com/satijalab/seurat) to create PCA and UMAP
decomposition plots. _Note that in order run this you have to change the
Codespaces default instance from 'small' (4gb ram) to 'large' (16gb ram)._

<img src="https://eddelbuettel.github.io/r2u/assets/censusExample.png" width="90%">


### Local DevContainer build

Codespaces are DevContainers running in the cloud (where DevContainers are
themselves just Docker images running with some VS Code sugar on top). This
gives you the very powerful ability to 'edit locally' but 'run remotely' in
the hosted codespace. To test this setup locally, simply clone the repo and
open it up in VS Code. You will need to have Docker installed and running on
your system (see [here](https://docs.docker.com/engine/install/)). You will
also need the [Remote Development extension][remote dev extension]
(you will probably be prompted to install it automatically if you do not have
it yet). Select "Reopen in Container" when prompted. Otherwise, click the
`><` tab at the very bottom left of your VS Code editor and select this
option. To shut down the container, simply click the same button and choose
"Reopen Folder Locally". You can always search for these commands via the
command palette too (`Cmd+Shift+p` / `Ctrl+Shift+p`).

### Use in Your Repo

To add this ability of launching Codespaces in the browser (or editor) to a repo of yours, create a
directory `.devcontainers` in your selected repo, and add the file
[`.devcontainers/devcontainer.json`](https://github.com/eddelbuettel/r2u/blob/master/.devcontainer/devcontainer.json). You can customize it by
enabling other feature, or use the `postCreateCommand` field to install packages (while taking full
advantage of [r2u][r2u]).

### Acknowledgments

There are a few key "plumbing" pieces that make everything work here. Thanks to:

- My [Rocker Project](https://rocker-project.org/) colleague @eitsupi for maintaining the [R DevContainer Features](https://rocker-project.org/images/devcontainer/features.html).
- [@renkun-ken](https://github.com/renkun-ken) and the rest of the [VS Code R extension](https://code.visualstudio.com/docs/languages/r) team.
- [@Enchufa2](https://github.com/Enchufa2) for [`bspm`](https://enchufa2.github.io/bspm/) making package installation to the sysstem so seamless.
- [@grantmcdermott](https://github.com/grantmcdermott) for the initial [codespaces-r2u](https://github.com/grantmcdermott/codespaces-r2u) setup from which we derived this.
- Last but not least everybody who helped me make [r2u][r2u] possible, tested it, or sent hints for improvement.

[r2u]: https://eddelbuettel.github.io/r2u/
[sf]: https://cran.r-project.org/package=sf
[ggplot2]: https://cran.r-project.org/package=ggplot2
[remote dev extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack
[codespaces-r2u]: https://github.com/grantmcdermott/codespaces-r2u
[r-universe]: https://r-universe.dev/
