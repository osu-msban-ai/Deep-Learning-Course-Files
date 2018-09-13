FROM debian:jessie

MAINTAINER Kamil Kwiek <kamil.kwiek@continuum.io>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-4.3.1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p $CONDA_DIR && \
    rm ~/anaconda.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy

RUN conda create --yes -p $CONDA_DIR/envs/python2 python=2.7

RUN bash -c '. activate python2 && \
	conda install ipykernel && \
    python -m ipykernel.kernelspec --prefix=$CONDA_DIR && \
    conda clean -tipsy && \
    . deactivate'

RUN apt-get update --fix-missing && apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean


ENV PATH $CONDA_DIR/bin:$PATH

RUN bash -c '. activate python2 && \
    apt-get update && apt-get install -y \
    python-dev libxml2-dev libxslt1-dev antiword poppler-utils \
    python-pip zlib1g-dev && \ 
    apt-get install -y python python-dev python-pip build-essential swig git libpulse-dev && \
    . deactivate'


RUN mv /bin/sh /tmp/shnew && \
    ln -s /bin/bash /bin/sh

RUN yes | conda create -n tensorflow
RUN source activate tensorflow
RUN pip install --ignore-installed --upgrade \
    https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.10.0-cp36-cp36m-linux_x86_64.whl

RUN rm /bin/sh && \
    mv /tmp/shnew /bin/sh

RUN pip install keras && \
    pip install -U kaggle-cli
RUN conda install -c conda-forge bcolz
RUN yes | conda install pandas
RUN yes | conda install -c conda-forge tqdm
RUN pip install --upgrade dask


RUN bash -c '. activate python2 && \
    pip install --upgrade tensorflow && \
    pip install keras && \
    pip install -U bcolz && \
    pip install -U kaggle-cli && \
    y | conda install pandas && \
    . deactivate'


RUN mkdir /notebooks
RUN mkdir /tf_tmp
WORKDIR /notebooks

EXPOSE 6006 8888

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]