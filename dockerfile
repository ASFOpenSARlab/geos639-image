FROM jupyter/base-notebook:lab-4.0.1 as release

# Base Stage ****************************************************************
USER root
WORKDIR /

RUN set -ve

RUN apt update --fix-missing
RUN apt install --no-install-recommends -y \
        software-properties-common \
        command-not-found \
        git && \
    apt-get install -y gpg-agent && \
    add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && \
    apt autoremove --purge snapd &&\
    apt update && \
    apt upgrade -y

# APT installs
RUN apt install --no-install-recommends --fix-missing -y \
    ### GENERAL
    zip \
    unzip \
    wget \
    vim \
    rsync \
    less \
    snaphu \
    curl \
    openssh-client \
    libgl1-mesa-glx \
    emacs \
    gnupg2 \
    jq \
    gfortran \
    make \
    gv \
    gedit \
    ### SNAP
    default-jdk-headless \
    ### Install texlive for PDF exporting of notebooks containing LaTex
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    ### PyGMTSAR
    tcsh \
    autoconf \
    libtiff5-dev \ 
    liblapack-dev \
    libgmt-dev \
    gmt-dcw \
    gmt-gshhg \
    gmt
    ### Jupyter Desktop not installed

# MAMBA installs
RUN mamba install -c conda-forge -y \
    ### Install plotting and general
    awscli \
    boto3 \
    pyyaml \
    bokeh \
    plotly \
    'pyopenssl>=23.0.0' \
    ### Install jupyter libaries
    kernda \
    # This is not compatible with JL 4: jupyter_contrib_nbextensions \ 
    jupyter-resource-usage \
    nb_conda_kernels \
    jupyterlab-spellchecker \
    jupyterlab-git \
    panel \
    ipympl \
    jupyterlab_widgets \
    ipywidgets \
    ### Dask
    dask-gateway \
    dask \
    distributed \
    zstd==1.5.5 \
    zstandard==0.21.0 \
    --

# PIP and other PACKAGES
RUN python3 -m pip install \
        ### For ASF
        url-widget \
        opensarlab-frontend==1.5.1 \
        jupyterlab-jupyterbook-navigation==0.1.4 \
        ### For pyGMTSAR
        pygmtsar &&\
    cd /tmp &&\
        mkdir -p /tmp/build/GMTSAR /usr/local/GMTSAR &&\
        git clone --branch master https://github.com/gmtsar/gmtsar /tmp/build/GMTSAR/ &&\
        cd /tmp/build/GMTSAR &&\
        autoconf &&\
        ./configure --with-orbits-dir=/tmp CFLAGS='-z muldefs' LDFLAGS='-z muldefs' &&\
        make &&\
        make install &&\
        mv -v /tmp/build/GMTSAR/bin /usr/local/GMTSAR/bin &&\
        rm -rf /tmp/build &&\
    cd /tmp &&\
    cd /tmp &&\
        ### Extra stuff
        # Make sure that any files in the home directory are jovyan permission
        chown -R jovyan:users $HOME/ &&\
        # Make sure mamba (within conda) has write access
        chmod -R 777 /opt/conda/pkgs/ &&\
        # Make sure JupyterLab settings is writable
        mkdir -p /opt/conda/share/jupyter/lab/settings/ &&\
        chown jovyan:users /opt/conda/share/jupyter/lab/settings/ &&\
        chmod -R 775 /opt/conda/share/jupyter/lab/settings/ &&\
        # Add sudo group user 599 elevation
        addgroup -gid 599 elevation &&\
        echo '%elevation ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers &&\
        # Use the kernel display name `base` for the base conda environment
        mamba run -n base kernda --display-name base -o /opt/conda/share/jupyter/kernels/python3/kernel.json &&\
        mamba clean -y --all &&\
        mamba init &&\
        rm -rf /home/jovyan/..?* /home/jovyan/.[!.]* /home/jovyan/* &&\
    rm -rf /tmp/* &&\
    cd /tmp

### GMTSAR
ENV PATH=/usr/local/GMTSAR/bin:$PATH

RUN chmod -R 775 /home/jovyan &&\
    chown -R jovyan:users /home/jovyan

WORKDIR /home/jovyan
USER jovyan

RUN mkdir /tmp/helper_scripts
COPY helper_scripts/* /tmp/helper_scripts
RUN bash /tmp/helper_scripts/post_hook.sh
