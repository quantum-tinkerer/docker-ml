conda config --system --add envs_dirs ~/.conda/envs
source deactivate
conda env remove --yes --name dev
CONDA_ALWAYS_COPY=true conda env create --file /environments/dev.yml
