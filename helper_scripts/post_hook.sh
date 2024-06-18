#!/bin/bash
set -ve

PYTHON_VER=$(python -c "import sys; print(f\"python{sys.version_info.major}.{sys.version_info.minor}\")")

export PATH=$HOME/.local/bin:$PATH

python /tmp/helper_scripts/pkg_clean.py

python -m pip install --user nbgitpuller

# copy over our version of pull.py
cp /tmp/helper_scripts/pull.py /home/jovyan/.local/lib/$PYTHON_VER/site-packages/nbgitpuller/pull.py

# Copy over extension override
cp /tmp/helper_scripts/default.json /opt/conda/share/jupyter/lab/settings/overrides.json

# Disable the extension manager in Jupyterlab since server extensions are uninstallable
# by users and non-server extension installs do not persist over server restarts
jupyter labextension disable @jupyterlab/extensionmanager-extension

gitpuller https://github.com/uafgeoteach/GEOS639-InSARGeoImaging main $HOME/GEOS639_Labs

gitpuller https://github.com/ASFOpenSARlab/opensarlab-notebooks.git master $HOME/notebooks

gitpuller https://github.com/ASFOpenSARlab/opensarlab-envs.git main $HOME/conda_environments

gitpuller https://github.com/uafgeoteach/GEOS657_MRS main $HOME/GEOS_657_Labs

# Update page and tree
mv /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/tree.html /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/original_tree.html
cp /tmp/helper_scripts/tree.html /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/tree.html

mv /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/page.html /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/original_page.html
cp /tmp/helper_scripts/page.html /opt/conda/lib/$PYTHON_VER/site-packages/notebook/templates/page.html

CONDARC=$HOME/.condarc
if ! test -f "$CONDARC"; then
cat <<EOT >> $CONDARC
channels:
  - conda-forge
  - defaults

channel_priority: strict

envs_dirs:
  - /home/jovyan/.local/envs
  - /opt/conda/envs
EOT
fi

KERNELS=$HOME/.local/share/jupyter/kernels
OLD_KERNELS=$HOME/.local/share/jupyter/kernels_old
FLAG=$HOME/.jupyter/old_kernels_flag.txt
if ! test -f "$FLAG" && test -d "$KERNELS"; then
cp /etc/singleuser/etc/old_kernels_flag.txt $HOME/.jupyter/old_kernels_flag.txt
mv $KERNELS $OLD_KERNELS
cp /etc/singleuser/etc/kernels_rename_README $OLD_KERNELS/kernels_rename_README
fi

# Remove CondaKernelSpecManager section from jupyter_notebook_config.json to display full kernel names
# We can do this now since jlab4 dynamically expands launcher buttons to fit
JN_CONFIG=$HOME/.jupyter/jupyter_notebook_config.json
if test -f "$JN_CONFIG" && jq -e '.CondaKernelSpecManager' "$JN_CONFIG" &>/dev/null; then
    jq 'del(.CondaKernelSpecManager)' "$JN_CONFIG" > temp && mv temp "$JN_CONFIG"
fi

conda init

BASH_PROFILE=$HOME/.bash_profile
if ! test -f "$BASH_PROFILE"; then
cat <<EOT>> $BASH_PROFILE
if [ -s ~/.bashrc ]; then
    source ~/.bashrc;
fi
EOT
fi
