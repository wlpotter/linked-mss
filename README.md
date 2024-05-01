# Linked Manuscripts

This is a research repository for creating a linked data dataset for Syriac manuscript descriptions. It was originally created as part of a course project for the University of Illinois IS 547: Foundations of Data Curation course in the Spring 2024 semester.

# Workflow Execution Instructions

## Installation and Pre-Requisites

Please install the required software:

1. Snakemake. Use the instructions provided at https://snakemake.readthedocs.io/en/stable/getting_started/installation.html
    - please install the full, recommended installation via [Conda/Mamba](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html#installation-via-conda-mamba), including setting up environment for snakemake
2. Basex. Please install the Basex XQuery processor and XML database: https://basex.org/download/
    - Note, for some Linux distributions Basex is available via package manager, e.g. `apt install basex`

## Preparing Data

Download and extract the Syriac Manuscripts in the British Library (SMBL) dataset.

N.B.: A copy of this data is included already at `workflow/data/smbl`; however, the updated dataset may be downloaded using the following steps:

1. Clone or download the SMBL data repository: https://github.com/srophe/britishLibrary-data
    - Clone via git: `git clone https://github.com/srophe/britishLibrary-data.git`
    - Download as a .zip file
2. (Optional) Extract the compressed .zip file
3. Copy TEI XML documents from the SMBL repository at `data/tei/` to the workflow repository at `workflow/data/smbl`

## Execute the Workflow

Use the following steps to run the workflow:

1. Open a terminal and cd into this repository
2. Change directories into the workflow directory: `cd workflow`
3. Activate the Mamba environment for Snakemake: `mamba activate snakemake`
    - Refer to the [Installation Instructions](#installation-and-pre-requisites) for more details
    - Confirm that the environment is active: `snakemake --help`
4. Run the snakemake workflow, specifying the number of cores snakemake can use, e.g. `snakemake --cores 8`
    - For re-running the workflow without having modified the source data, you may need to delete output files to force a re-run of the workflow: `snakemake --cores 1 --delete-all-output`. Then execute the above command.

The workflow will transform the TEI XML files into JSON records, then aggregate them into a JSON-LD graph with associated context file. The result will be the smbl.json file at `workflow/results/smbl.json` containing the knowledge graph and ontology.