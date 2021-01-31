#!/bin/sh

export JAVA_HOME=/usr/lib/jvm/java-6-sun-1.6.0.07/jre
export MINORTHIRD=/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611
export CLASSPATH=$MINORTHIRD/class:$MINORTHIRD/lib/*

# java edu.cmu.minorthird.ui.TrainExtractor -help

java edu.cmu.minorthird.ui.TrainExtractor -labels /var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs -spanType area -gui
# java edu.cmu.minorthird.ui.TestExtractor -mixup -labels /var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-testing-small -spanType area -loadFrom jobs-area.ann -saveAs results.txt
# java edu.cmu.minorthird.ui.TestExtractor -mixup -labels /var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-small -spanType area -loadFrom jobs-area.ann -saveAs results.txt
# java edu.cmu.minorthird.ui.TrainExtractor -labels /var/lib/myfrdcsa/datasets/resume300/data -spanType system -saveAs resume.ann


