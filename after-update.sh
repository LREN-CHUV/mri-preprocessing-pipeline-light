#!/bin/sh

cd Pipelines/NeuroMorphometric_Pipeline/NeuroMorphometric_tbx

xz -k -d *.nii.xz

cd label

tar -Jxvf training_data.tar.xz


