#!/bin/sh


declare -A programs

#for program in nemo xios
#do
#  programs[$program]=1
#done


## check if the first argument is a valid program to run
#if ! [[ ${programs[$1]} ]]

if ! [ $1 = "nemo" -o $1 = "xios" ] 
#if [ $1 == "nemo" ] 
then
  echo "not valid"
  exit 1
fi

results_dir=$2 

if [ -z $2 ]
then
  results_dir=$UGG_TEST
fi

if [ -z $results_dir ]
then
    echo "Please supply an output directory"
    exit 1
fi

if [ ! -d $results_dir ]
then
    mkdir $results_dir
    chdir $results_dir 
    echo $results_dir

#    for file in /nemo/nemo/cfgs/GYRE_PISCES/EXP00/*
#    do
#        ln -s $file
#    done
else
    cd $2
fi

if [ $1 = 'nemo' ]
then
    echo "nemo"
    #/opt/nemo/nemo
else
    echo "xios"
    #/opt/xios/xios
fi
