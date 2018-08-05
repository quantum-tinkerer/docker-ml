FROM jupyter/base-notebook:latest

USER root
WORKDIR /

# Debian packages
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        autossh \
        bash-completion \
        tree \
        curl \
        git \
        tig \
        htop \
        imagemagick \
        jq \
        keychain \
        less \
        man \
        nano \
        rsync \
        tmux \
        vim \
        openssh-server \
        apt-transport-https \
        gnupg \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

# Add global bash profile
COPY profile.sh /etc/profile.d/

# Add environment files
RUN mkdir /environments
COPY machine-learning.yml /environments/

# Update the root environment and clean all downloaded conda files
RUN conda env update -n root -f /environments/machine-learning.yml && \
    conda clean --yes --all

# Enable `jupyter nbextension`s
RUN jupyter nbextension enable --py --sys-prefix ipyparallel && \
    jupyter nbextension enable --py --sys-prefix jupyter_cms && \
    jupyter nbextension enable --py --sys-prefix jupyter_dashboards && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager \
            @jupyterlab/katex-extension \
            jupyterlab_bokeh @pyviz/jupyterlab_holoviews \
            @jupyterlab/plotly-extension

# prevent nb_conda_kernels from overriding our custom kernel manager
RUN rm /opt/conda/etc/jupyter/jupyter_notebook_config.json

# Add notebook config
COPY jupyter_notebook_config.py /opt/conda/etc/jupyter

# Register nbdime as a git diff and merge tool
COPY git* /etc/

# Create parallel profiles and copy the correct config
RUN ipython profile create --parallel --profile python3 --ipython-dir /opt/conda/etc/ipython
COPY ipcluster_config_python3.py /opt/conda/etc/ipython/profile_python3/ipcluster_config.py

# setting openblas and mkl variables
ENV OPENBLAS_NUM_THREADS=1\
    OMP_NUM_THREADS=1\
    MKL_DYNAMIC=FALSE\
    MKL_NUM_THREADS=1\
    CONDA_ALWAYS_COPY=true

# Fix permissions (required when following the base image)
RUN fix-permissions /opt/conda

# copy startup.sh script and set start-up command
COPY startup.sh /usr/local/bin
CMD ["startup.sh"]
EXPOSE 22

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
