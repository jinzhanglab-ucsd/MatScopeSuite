#!/bin/bash
####################################
#
# Scripts to find all Datasets and prepare a csv file with all the information needed for Report table
#
#
#

# get current list of all datasets
find /synology/data/Images/ -maxdepth 3 -mindepth 3 -type d > UnsortedNewDatasetList
find /data2/Images/ -maxdepth 3 -mindepth 3 -type d >> UnsortedNewDatasetList
find /data3/Images/ -maxdepth 3 -mindepth 3 -type d >> UnsortedNewDatasetList
sort UnsortedNewDatasetList > DatasetList

# remove things that already exist in file OldDatasetList to create list of datasets to add
# comm -2 -3 NewDatasetList OldDatasetList > DatasetsListToAdd

# 
#while read in; 	do
#	echo $in #>> OldDatasetList;
#	#echo $in | mail -s "dataset" pi.wollmanlab@gmail.com;
#done < DatasetsListToAdd 

# similar thing for Results.mat
find /synology/data/Images/ -maxdepth 4 -mindepth 4 -name Results.mat > UnsortedDatasetsWithResults
find /data2/Images/ -maxdepth 4 -mindepth 4 -name Results.mat >> UnsortedDatasetsWithResults
find /data3/Images/ -maxdepth 4 -mindepth 4 -name Results.mat >> UnsortedDatasetsWithResults
sort UnsortedDatasetsWithResults | sed s:Results.mat:: > DatasetsWithResults

# create a list of reports
find /home/rwollman/Reports/ -maxdepth 1 -mindepth 1 -name "_*" -type d | sed s:/home/rwollman/Reports/:: > ReportList

find /synology/data/Images/ -maxdepth 4 -mindepth 4 -name Conclusions.txt > UnsortedDatasetsWithConclusions
find /data2/Images/ -maxdepth 4 -mindepth 4 -name Conclusions.txt >> UnsortedDatasetsWithConclusions
find /data3/Images/ -maxdepth 4 -mindepth 4 -name Conclusions.txt >> UnsortedDatasetsWithConclusions
sort UnsortedDatasetsWithConclusions | sed s:Conclusions.txt:: > DatasetsWithConclusions

# remove any , and change / to , for the csv in the entire file. and change to csv format while at it. 
rm DataSetsListWithResults.csv
touch DataSetsListWithResults.csv
while read line; do
	# create a copy of the line with # instead of /
	pth=$line; 	
	
	# get the date
	Date=${pth##*_};
	Date="${Date:7:2}-${Date:4:3}-${Date:0:4}";	


	# create conclusion variable
	if grep -q "$line" DatasetsWithConclusions
	then
	    conclusions=`cat "$line/Conclusions.txt"`; 
	else
	    conclusions="missing";		
	fi
	conclusions=$(echo $conclusions|tr -d '\n')
	conclusions=${conclusions/"No conclusion drawn yet"/missing};


	# figure out if Results.mat exist
	if grep -q "$line" DatasetsWithResults
	then
	    line="$line/1";
	else
	    line="$line/0";
	fi

	
 	# replace / with # to later conver those to ,
	line=${line//\//\#};

	# get rid of base path
	line="${line/\#synology\#data\#Images\#/}"; 
	line="${line/\#data2\#Images\#/}"; 
	line="${line/\#data3\#Images\#/}"; 
	
	# figure out if html exist
	html="${pth//\//_}";
	if grep -Fxq "$html" ReportList
	then
	    html="http://wollmanlabserver.ucsd.edu/$html/Report.html";
	else
	    html="none"; 
	fi

	echo "$line#$Date#$pth#$html#$conclusions" | tr , _ | tr \# , >> DataSetsListWithResults.csv
done < DatasetList

cp DataSetsListWithResults.csv /home/rwollman/Reports/DatasetList.csv

#TODO Conclusions.txt find all the Conclusions.mat files and transform them to Conclusion.txt
